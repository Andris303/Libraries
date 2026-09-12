local ATTRIBUTE_ROOT_OFFSET = 0x38
local ATTRIBUTE_STRIDE = 0x58
local ATTRIBUTE_VALUE_OFFSET = 0x18
local ATTRIBUTE_TYPES = {
    [0x8947CD0] = "boolean",
    [0x8947E10] = "number",
    [0x8947E60] = "string",
    [0x89474E0] = "BrickColor",
    [0x8948470] = "CFrame",
    [0x8948130] = "Color3",
    [0x89470A0] = "ColorSequence",
    [0x893CB30] = "Font",
    [0x8947250] = "NumberRange",
    [0x89472A0] = "NumberSequence",
    [0x89480E0] = "Rect",
    [0x89475D0] = "UDim",
    [0x8947620] = "UDim2",
    [0x8947F00] = "Vector2",
    [0x8947EB0] = "Vector3"
}

local AttributeNodeCache = {}
local AttributeSetCache = {}

local function ReadU32(addr)
    return memory.readu32(addr)
end

local function ReadI32(addr)
    local value = memory.readu32(addr)
    if value >= 0x80000000 then value -= 0x100000000 end
    return value
end

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

local function ReadSequenceInfo(value)
    local data = memory.readu64(value)
    local packed = memory.readu64(value + 0x8)
    local low = packed % 0x100000000
    local high = math.floor(packed / 0x100000000)
    local count

    if high >= 0x80000000 then
        count = high - 0x80000000
    elseif low > 0 and low <= 256 then
        count = low
    elseif high > 0 and high <= 256 then
        count = high
    end

    if not count or count <= 0 or count > 256 then return nil end
    return data, count
end

local function PackU32(str, startIndex)
    local b1 = string.byte(str, startIndex) or 0
    local b2 = string.byte(str, startIndex + 1) or 0
    local b3 = string.byte(str, startIndex + 2) or 0
    local b4 = string.byte(str, startIndex + 3) or 0
    return b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000
end

local function WriteStdString(addr, newValue)
    if type(newValue) ~= "string" then return false, "expected string" end

    local capacity = memory.readu64(addr + 0x18)
    if not capacity then return false, "failed to read string capacity" end
    if #newValue > capacity then return false, "string exceeds capacity (" .. #newValue .. " > " .. capacity .. ")" end

    local dataAddress = addr
    if capacity >= 16 then
        dataAddress = memory.readu64(addr)
        if not IsHeapPointer(dataAddress) then return false, "invalid string pointer" end
    end

    local ok, err = pcall(function()
        local i = 1
        while i + 3 <= #newValue do
            memory.writeu32(dataAddress, i - 1, PackU32(newValue, i))
            i += 4
        end
        while i <= #newValue do
            memory.writeu8(dataAddress, i - 1, string.byte(newValue, i))
            i += 1
        end
        memory.writeu8(dataAddress, #newValue, 0)
        memory.writeu64(addr, 0x10, #newValue)
    end)

    if not ok then return false, err end
    return true
end

local function ReadAttributeValue(entry)
    local okType, typePtr = pcall(memory.readu64, entry, 0x8)
    if not okType or not typePtr then return nil end

    local valueType = ATTRIBUTE_TYPES[typePtr - tonumber(memory.base)]
    local value = entry + ATTRIBUTE_VALUE_OFFSET

    if valueType == "boolean" then
        local ok, result = pcall(memory.readbool, value)
        if ok then return result end
        return nil
    elseif valueType == "number" then
        local ok, result = pcall(memory.readf64, value)
        return ok and result or nil
    elseif valueType == "string" then
        return ReadStdString(value)
    elseif valueType == "BrickColor" then
        return {Number = ReadU32(value)}
    elseif valueType == "Vector2" then
        return Vector2.new(memory.readf32(value), memory.readf32(value + 0x4))
    elseif valueType == "Vector3" then
        return Vector3.new(memory.readf32(value), memory.readf32(value + 0x4), memory.readf32(value + 0x8))
    elseif valueType == "Color3" then
        return {R = memory.readf32(value), G = memory.readf32(value + 0x4), B = memory.readf32(value + 0x8)}
    elseif valueType == "UDim" then
        return {Scale = memory.readf32(value), Offset = ReadI32(value + 0x4)}
    elseif valueType == "UDim2" then
        return {X = {Scale = memory.readf32(value), Offset = ReadI32(value + 0x4)}, Y = {Scale = memory.readf32(value + 0x8), Offset = ReadI32(value + 0xC)}}
    elseif valueType == "NumberRange" then
        return {Min = memory.readf32(value), Max = memory.readf32(value + 0x4)}
    elseif valueType == "Rect" then
        return {Min = {X = memory.readf32(value), Y = memory.readf32(value + 0x4)}, Max = {X = memory.readf32(value + 0x8), Y = memory.readf32(value + 0xC)}}
    elseif valueType == "NumberSequence" then
        local ok, result = pcall(function()
            local data, count = ReadSequenceInfo(value)
            if not data then return nil end
            local points = {}
            for i = 0, count - 1 do
                local kp = data + i * 0xC
                points[i + 1] = {Time = i == 0 and 0 or memory.readf32(kp), Value = memory.readf32(kp + 0x4), Envelope = memory.readf32(kp + 0x8)}
            end
            return points
        end)
        return ok and result or nil
    elseif valueType == "ColorSequence" then
        local ok, result = pcall(function()
            local data, count = ReadSequenceInfo(value)
            if not data then return nil end
            local points = {}
            for i = 0, count - 1 do
                local kp = data + i * 0x14
                points[i + 1] = {Time = memory.readf32(kp), R = memory.readf32(kp + 0x4), G = memory.readf32(kp + 0x8), B = memory.readf32(kp + 0xC)}
            end
            return points
        end)
        return ok and result or nil
    elseif valueType == "CFrame" then
        local r00 = memory.readf32(value)
        local r01 = memory.readf32(value + 0x4)
        local r02 = memory.readf32(value + 0x8)
        local r10 = memory.readf32(value + 0xC)
        local r11 = memory.readf32(value + 0x10)
        local r12 = memory.readf32(value + 0x14)
        local r20 = memory.readf32(value + 0x18)
        local r21 = memory.readf32(value + 0x1C)
        local r22 = memory.readf32(value + 0x20)
        local x = memory.readf32(value + 0x24)
        local y = memory.readf32(value + 0x28)
        local z = memory.readf32(value + 0x2C)
        return CFrame.new(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
    end
end

local function GetInstanceAddress(instance)
    local ok, addr = pcall(function() return tonumber(instance.Data) end)
    return ok and addr or nil
end

local function SearchAttributeNode(node, wantedName)
    local function SearchVector(first, packed)
        if not IsHeapPointer(first) or not packed then return nil, false end

        local count = packed % 0x100000000
        local capacity = math.floor(packed / 0x100000000)
        if count <= 0 or count > capacity or capacity > 256 then return nil, false end

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

    local ok1, first1 = pcall(memory.readu64, node, 0x8)
    local ok2, packed1 = pcall(memory.readu64, node, 0x10)
    if ok1 and ok2 then
        local entry, valid = SearchVector(first1, packed1)
        if entry or valid then return entry, valid end
    end

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

    local cached = AttributeNodeCache[address]
    if cached and cached.Root == root then
        local entry, valid = SearchAttributeNode(cached.Node, wantedName)
        if valid then return entry end
        AttributeNodeCache[address] = nil
    end

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
                AttributeNodeCache[address] = {Root = root, Node = node}
                return entry
            end

            for _, off in {0x0, 0x10} do
                local ok, ptr = pcall(memory.readu64, node, off)
                if ok and IsHeapPointer(ptr) and not visited[ptr] then queue[#queue + 1] = ptr end
            end
        end
    end

    return nil
end

local function GetCachedAttributeEntry(instance, name)
    local address = GetInstanceAddress(instance)
    if not address then return nil end

    local okRoot, root = pcall(memory.readu64, address, ATTRIBUTE_ROOT_OFFSET)
    if not okRoot or not IsHeapPointer(root) then
        AttributeSetCache[address] = nil
        return nil
    end

    local instanceCache = AttributeSetCache[address]
    if instanceCache and instanceCache.Root == root then
        local cached = instanceCache.Attributes[name]
        if cached then return cached.Entry, cached.Type end
    else
        instanceCache = {Root = root, Attributes = {}}
        AttributeSetCache[address] = instanceCache
    end

    local entry = FindAttributeEntry(instance, name)
    if not entry then return nil end

    local okType, typePtr = pcall(memory.readu64, entry, 0x8)
    if not okType or not typePtr then return nil end

    local valueType = ATTRIBUTE_TYPES[typePtr - tonumber(memory.base)]
    if not valueType then return nil end

    instanceCache.Attributes[name] = {Entry = entry, Type = valueType}
    return entry, valueType
end

local function PrepareAttributeSetter(instance, name)
    local entry, valueType = GetCachedAttributeEntry(instance, name)
    if not entry then return nil end

    if valueType == "number" then
        return function(value)
            memory.writef64(entry, ATTRIBUTE_VALUE_OFFSET, value)
        end
    elseif valueType == "boolean" then
        return function(value)
            memory.writebool(entry, ATTRIBUTE_VALUE_OFFSET, value)
        end
    elseif valueType == "Vector3" then
        return function(value)
            memory.writef32(entry, ATTRIBUTE_VALUE_OFFSET, value.X)
            memory.writef32(entry, ATTRIBUTE_VALUE_OFFSET + 0x4, value.Y)
            memory.writef32(entry, ATTRIBUTE_VALUE_OFFSET + 0x8, value.Z)
        end
    end

    return nil
end

local function GetAttribute(instance, name)
    local entry = FindAttributeEntry(instance, name)
    if not entry then return nil end
    return ReadAttributeValue(entry)
end

local function GetAttributes(instance)
    local address = GetInstanceAddress(instance)
    if not address then return {} end

    local okRoot, root = pcall(memory.readu64, address, ATTRIBUTE_ROOT_OFFSET)
    if not okRoot or not IsHeapPointer(root) then
        AttributeNodeCache[address] = nil
        return {}
    end

    local function ReadVector(first, packed)
        if not IsHeapPointer(first) or not packed then return nil, false end

        local count = packed % 0x100000000
        local capacity = math.floor(packed / 0x100000000)
        if count <= 0 or count > capacity or capacity > 256 then return nil, false end

        local attributes = {}
        local valid = false

        for i = 0, count - 1 do
            local entry = first + i * ATTRIBUTE_STRIDE
            local ok, namePtr = pcall(memory.readu64, entry)
            if ok and IsHeapPointer(namePtr) then
                local name = ReadStdString(namePtr + 0x8)
                if name ~= "" and #name < 100 then
                    valid = true
                    local value = ReadAttributeValue(entry)
                    if value ~= nil then attributes[name] = value end
                end
            end
        end

        return attributes, valid
    end

    local function ReadNode(node)
        local ok1, first1 = pcall(memory.readu64, node, 0x8)
        local ok2, packed1 = pcall(memory.readu64, node, 0x10)
        if ok1 and ok2 then
            local attributes, valid = ReadVector(first1, packed1)
            if valid then return attributes, true end
        end

        local ok3, packed2 = pcall(memory.readu64, node, 0x8)
        local ok4, first2 = pcall(memory.readu64, node, 0x18)
        if ok3 and ok4 then
            local attributes, valid = ReadVector(first2, packed2)
            if valid then return attributes, true end
        end

        return nil, false
    end

    local cached = AttributeNodeCache[address]
    if cached and cached.Root == root then
        local attributes, valid = ReadNode(cached.Node)
        if valid then return attributes end
        AttributeNodeCache[address] = nil
    end

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

            local attributes, valid = ReadNode(node)
            if valid then
                AttributeNodeCache[address] = {Root = root, Node = node}
                return attributes
            end

            for _, off in {0x0, 0x10} do
                local ok, ptr = pcall(memory.readu64, node, off)
                if ok and IsHeapPointer(ptr) and not visited[ptr] then queue[#queue + 1] = ptr end
            end
        end
    end

    return {}
end

local function SetAttribute(instance, name, newValue)
    local entry, valueType = GetCachedAttributeEntry(instance, name)
    if not entry then return false, "attribute not found" end

    local valueOffset = ATTRIBUTE_VALUE_OFFSET

    local ok, err = pcall(function()
        if valueType == "number" then
            if type(newValue) ~= "number" then error("expected number") end
            memory.writef64(entry, valueOffset, newValue)
        elseif valueType == "string" then
            local success, reason = WriteStdString(entry + valueOffset, newValue)
            if not success then error(reason) end
        elseif valueType == "boolean" then
            if type(newValue) ~= "boolean" then error("expected boolean") end
            memory.writebool(entry, valueOffset, newValue)
        elseif valueType == "Vector2" then
            memory.writef32(entry, valueOffset, newValue.X)
            memory.writef32(entry, valueOffset + 0x4, newValue.Y)
        elseif valueType == "Vector3" then
            memory.writef32(entry, valueOffset, newValue.X)
            memory.writef32(entry, valueOffset + 0x4, newValue.Y)
            memory.writef32(entry, valueOffset + 0x8, newValue.Z)
        elseif valueType == "Color3" then
            memory.writef32(entry, valueOffset, newValue.R)
            memory.writef32(entry, valueOffset + 0x4, newValue.G)
            memory.writef32(entry, valueOffset + 0x8, newValue.B)
        elseif valueType == "BrickColor" then
            local number = type(newValue) == "table" and newValue.Number or newValue
            memory.writeu32(entry, valueOffset, number)
        elseif valueType == "UDim" then
            memory.writef32(entry, valueOffset, newValue.Scale)
            memory.writeu32(entry, valueOffset + 0x4, newValue.Offset % 0x100000000)
        elseif valueType == "UDim2" then
            memory.writef32(entry, valueOffset, newValue.X.Scale)
            memory.writeu32(entry, valueOffset + 0x4, newValue.X.Offset % 0x100000000)
            memory.writef32(entry, valueOffset + 0x8, newValue.Y.Scale)
            memory.writeu32(entry, valueOffset + 0xC, newValue.Y.Offset % 0x100000000)
        elseif valueType == "NumberRange" then
            memory.writef32(entry, valueOffset, newValue.Min)
            memory.writef32(entry, valueOffset + 0x4, newValue.Max)
        elseif valueType == "Rect" then
            memory.writef32(entry, valueOffset, newValue.Min.X)
            memory.writef32(entry, valueOffset + 0x4, newValue.Min.Y)
            memory.writef32(entry, valueOffset + 0x8, newValue.Max.X)
            memory.writef32(entry, valueOffset + 0xC, newValue.Max.Y)
        elseif valueType == "NumberSequence" then
            if type(newValue) ~= "table" then error("expected NumberSequence table") end

            local data, count = ReadSequenceInfo(entry + valueOffset)
            if not data then error("failed to read NumberSequence") end
            if #newValue ~= count then error("NumberSequence keypoint count must remain " .. count) end

            local dataOffset = data - entry
            for i = 0, count - 1 do
                local point = newValue[i + 1]
                local kpOffset = dataOffset + i * 0xC
                if i > 0 then memory.writef32(entry, kpOffset, point.Time) end
                memory.writef32(entry, kpOffset + 0x4, point.Value)
                memory.writef32(entry, kpOffset + 0x8, point.Envelope or 0)
            end
        elseif valueType == "ColorSequence" then
            if type(newValue) ~= "table" then error("expected ColorSequence table") end

            local data, count = ReadSequenceInfo(entry + valueOffset)
            if not data then error("failed to read ColorSequence") end
            if #newValue ~= count then error("ColorSequence keypoint count must remain " .. count) end

            local dataOffset = data - entry
            for i = 0, count - 1 do
                local point = newValue[i + 1]
                local kpOffset = dataOffset + i * 0x14
                if i > 0 and i < count - 1 then memory.writef32(entry, kpOffset, point.Time) end
                memory.writef32(entry, kpOffset + 0x4, point.R)
                memory.writef32(entry, kpOffset + 0x8, point.G)
                memory.writef32(entry, kpOffset + 0xC, point.B)
            end
        elseif valueType == "CFrame" then
            memory.writef32(entry, valueOffset, newValue.R00)
            memory.writef32(entry, valueOffset + 0x4, newValue.R01)
            memory.writef32(entry, valueOffset + 0x8, newValue.R02)
            memory.writef32(entry, valueOffset + 0xC, newValue.R10)
            memory.writef32(entry, valueOffset + 0x10, newValue.R11)
            memory.writef32(entry, valueOffset + 0x14, newValue.R12)
            memory.writef32(entry, valueOffset + 0x18, newValue.R20)
            memory.writef32(entry, valueOffset + 0x1C, newValue.R21)
            memory.writef32(entry, valueOffset + 0x20, newValue.R22)
            memory.writef32(entry, valueOffset + 0x24, newValue.X)
            memory.writef32(entry, valueOffset + 0x28, newValue.Y)
            memory.writef32(entry, valueOffset + 0x2C, newValue.Z)
        else
            error("unsupported type: " .. tostring(valueType))
        end
    end)

    return ok, err
end

Instance.declare({
    class = "Instance",
    name = "FixedGetAttribute",
    callback = {
        method = function(self, name)
            return GetAttribute(self, name)
        end
    }
})

Instance.declare({
    class = "Instance",
    name = "FixedGetAttributes",
    callback = {
        method = function(self)
            return GetAttributes(self)
        end
    }
})

Instance.declare({
    class = "Instance",
    name = "FixedSetAttribute",
    callback = {
        method = function(self, name, value)
            return SetAttribute(self, name, value)
        end
    }
})

Instance.declare({
    class = "Instance",
    name = "PrepareAttributeSetter",
    callback = {
        method = function(self, name)
            return PrepareAttributeSetter(self, name)
        end
    }
})
