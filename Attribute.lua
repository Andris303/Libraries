local ATTRIBUTE_ROOT_OFFSET = 0x38
local ATTRIBUTE_STRIDE = 0x58
local ATTRIBUTE_VALUE_OFFSET = 0x18
local ATTRIBUTE_TYPES = {
    [0x8947CD0] = "boolean",
    [0x8947E10] = "number",
    [0x8947E60] = "string"
}

local AttributeNodeCache = {}

local function IsHeapPointer(v)
    return v and v >= 0x10000000000 and v < 0x70000000000
end

local function ReadStdString(addr)
    if not addr or addr == 0 then return "" end

    local okSize, size = pcall(memory.readu64, addr, 0x10)
    local okCapacity, capacity = pcall(memory.readu64, addr, 0x18)
    if not okSize or not okCapacity or not size or not capacity or size > 0x10000 then return "" end

    local strAddr = addr
    if capacity >= 16 then
        local okPtr, ptr = pcall(memory.readu64, addr)
        if not okPtr or not IsHeapPointer(ptr) then return "" end
        strAddr = ptr
    end

    local ok, value = pcall(memory.readstring, strAddr, 0)
    return ok and value or ""
end

local function GetInstanceAddress(instance)
    local ok, addr = pcall(function()
        return tonumber(instance.Data)
    end)

    return ok and addr or nil
end

local function SearchAttributeNode(node, wantedName)
    local function SearchVector(first, packed)
        if not IsHeapPointer(first) or not packed then return nil, false end

        local count = packed % 0x100000000
        local capacity = math.floor(packed / 0x100000000)

        if count <= 0 or count > capacity or capacity > 256 then
            return nil, false
        end

        local valid = false

        for i = 0, count - 1 do
            local entry = first + i * ATTRIBUTE_STRIDE
            local ok, namePtr = pcall(memory.readu64, entry)

            if ok and IsHeapPointer(namePtr) then
                local name = ReadStdString(namePtr + 0x8)

                if name ~= "" and #name < 100 then
                    valid = true
                    if name == wantedName then return entry, true end
                end
            end
        end

        return nil, valid
    end

    -- 1-7 attributes
    local ok1, first1 = pcall(memory.readu64, node, 0x8)
    local ok2, packed1 = pcall(memory.readu64, node, 0x10)

    if ok1 and ok2 then
        local entry, valid = SearchVector(first1, packed1)
        if entry or valid then return entry, valid end
    end

    -- 8+ attributes
    local ok3, packed2 = pcall(memory.readu64, node, 0x8)
    local ok4, first2 = pcall(memory.readu64, node, 0x18)

    if ok3 and ok4 then
        local entry, valid = SearchVector(first2, packed2)
        if entry or valid then return entry, valid end
    end

    return nil, false
end

local function FindAttributeEntry(instance, wantedName)
    local address = GetInstanceAddress(instance)
    if not address then return nil end

    local okRoot, root = pcall(memory.readu64, address, ATTRIBUTE_ROOT_OFFSET)
    if not okRoot or not IsHeapPointer(root) then
        AttributeNodeCache[address] = nil
        return nil
    end

    -- Fast path: normally used every frame.
    local cached = AttributeNodeCache[address]

    if cached and cached.Root == root then
        local entry, valid = SearchAttributeNode(cached.Node, wantedName)

        if valid then
            return entry
        end

        AttributeNodeCache[address] = nil
    end

    -- Slow path: only needed once or after the structure changes.
    local queue = {root}
    local visited = {}
    local qi = 1
    local nodes = 0

    while qi <= #queue and nodes < 64 do
        local node = queue[qi]
        qi += 1

        if not visited[node] then
            visited[node] = true
            nodes += 1

            local entry = SearchAttributeNode(node, wantedName)

            if entry then
                AttributeNodeCache[address] = {
                    Root = root,
                    Node = node
                }

                return entry
            end

            -- These are the tree links we actually observed.
            for _, off in {0x0, 0x10} do
                local ok, ptr = pcall(memory.readu64, node, off)

                if ok and IsHeapPointer(ptr) and not visited[ptr] then
                    queue[#queue + 1] = ptr
                end
            end
        end
    end

    return nil
end

local function GetAttribute(instance, name)
    local entry = FindAttributeEntry(instance, name)
    if not entry then return nil end

    local okType, typePtr = pcall(memory.readu64, entry, 0x8)
    if not okType or not typePtr then return nil end

    local valueType = ATTRIBUTE_TYPES[typePtr - tonumber(memory.base)]
    local value = entry + ATTRIBUTE_VALUE_OFFSET

    if valueType == "boolean" then
        local ok, result = pcall(memory.readbool, value)
        return ok and result or nil
    elseif valueType == "number" then
        local ok, result = pcall(memory.readf64, value)
        return ok and result or nil
    elseif valueType == "string" then
        return ReadStdString(value)
    end

    return nil
end

return {
  GetAttribute = GetAttribute
}
