local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local BodyParts = {"LowerTorso", "RightArm", "RightLeg", "LeftArm", "LeftLeg", "LeftLowerLeg", "LeftUpperLeg", "RightLowerLeg", "RightUpperLeg", "LeftLowerArm", "LeftUpperArm", "RightLowerArm", "RightUpperArm", "LeftHand", "RightHand"}
local FullBodyParts = {"Head", "Torso", "RightArm", "RightLeg", "LeftArm", "LeftLeg", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
local R6Check = {"Head", "HumanoidRootPart", "Torso", "Right Arm", "Right Leg", "Left Arm", "Left Leg"}
local R15Check = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
local ListCounter = 0
local ESPQueue = {}
local LocalId

--[[
_G.CustomParts = {
    RigType = "R6",
    HumanoidRootPart = "HumanoidRootPart",
    Head = "Head",
    Torso = "Torso",
    LeftArm = "Left Arm",
    RightArm = "Right Arm",
    LeftLeg = "Left Leg",
    RightLeg = "Right Leg",
}
]]

_G.ESPList = {}
_G.ESPHealths = {}
--_G.WaitTime = .01

local WaitTime = _G.WaitTime or .01

local function InstId(inst)
    if not inst or not inst.Parent then return nil end
    return tostring(tonumber(inst.Data))
end

local function CheckValidity(inst)
    if not inst or not inst.Parent then return false end

    if not inst:FindFirstChild("Humanoid") or not inst:FindFirstChild("HumanoidRootPart") then
        return false
    end

    if _G.CustomParts then
        for name, part in _G.CustomParts do
            if name ~= "RigType" and not inst:FindFirstChild(part) then
                return false
            end
        end
    elseif inst:FindFirstChild("Torso") then
        for _, part in R6Check do
            if not inst:FindFirstChild(part) then
                return false
            end
        end
    elseif inst:FindFirstChild("UpperTorso") then
        for _, part in R15Check do
            if not inst:FindFirstChild(part) then
                return false
            end
        end
    else
        return false
    end

    return true
end

local function ResolveData(Char, BoolLocalPlayer, Health, MaxHealth, Username, DisplayName, UserId, TeamName, ToolName)
    if ESPQueue[InstId(Char)] then return nil end
    if _G.ESPList[InstId(Char)] then return nil end
    if not CheckValidity(Char) then return nil end

    ListCounter += 1
    if Username == "_Enemy" then Username = "Enemy" .. tostring(ListCounter) end
    if DisplayName == "_Enemy" then DisplayName = "Enemy" .. tostring(ListCounter) end
    if UserId == 10000 then UserId = 10000 + ListCounter end

    local Parts = {}
    local Body = {}
    local Full = {}
    local RigType = 0

    if Char:FindFirstChild("UpperTorso") then
        RigType = 1
    end

    if _G.CustomParts then
        if _G.CustomParts.RigType == "R6" then
            RigType = 0
        elseif _G.CustomParts.RigType == "R15" then
            RigType = 1
        end

        for name, part in _G.CustomParts do
            if name ~= "RigType" then
                Parts[name] = Char:FindFirstChild(part)
            end
        end
    elseif RigType == 0 then
        for _, part in R6Check do
            Parts[part] = Char:FindFirstChild(part)
        end
    elseif RigType == 1 then
        for _, part in R15Check do
            Parts[part] = Char:FindFirstChild(part)
        end
    end

    for _, part in BodyParts do
        if Parts[part] then
            Body[#Body + 1] = {name = part, part = Char:FindFirstChild(part)}
        end
    end

    for _, part in FullBodyParts do
        if Parts[part] then
            Full[#Full + 1] = {name = part, part = Char:FindFirstChild(part)}
        end
    end

    if BoolLocalPlayer then
        LocalId = InstId(Char)
        local Data = {
            LocalPlayer = LocalPlayer,
            Character = Char,
            Username = Username,
            Displayname = DisplayName,
            Userid = UserId,
            Humanoid = Char.Humanoid,
            Health = Health,
            MaxHealth = MaxHealth,
            RigType = RigType,
            Teamname = TeamName,
            Toolname = ToolName,
            Head = Parts["Head"],
            RootPart = Parts["HumanoidRootPart"],
            LowerTorso = Parts["LowerTorso"] or Parts["Torso"],
            UpperTorso = Parts["UpperTorso"] or Parts["Torso"],
            LeftArm = Parts["Left Arm"] or Parts["LeftUpperArm"],
            RightArm = Parts["Right Arm"] or Parts["RightUpperArm"],
            LeftLeg = Parts["Left Leg"] or Parts["LeftUpperLeg"],
            RightLeg = Parts["Right Leg"] or Parts["RightUpperLeg"],
            LeftFoot = Parts["LeftFoot"] or Parts["Left Leg"],
        }

        return Data, InstId(Char)
    end

    local Data = {
        Username = Username,
        Displayname = DisplayName,
        Userid = UserId,
        Character = Char,
        PrimaryPart = Parts["HumanoidRootPart"],
        Humanoid = Char.Humanoid,
        Head = Parts["Head"],
        Torso = Parts["Torso"] or Parts["UpperTorso"],
        LeftLeg = Parts["Left Leg"] or Parts["LeftUpperLeg"],
        LeftArm = Parts["Left Arm"] or Parts["LeftUpperArm"],
        RightLeg = Parts["Right Leg"] or Parts["RightUpperLeg"],
        RightArm = Parts["Right Arm"] or Parts["RightUpperArm"],
        LeftUpperLeg = Parts["LeftUpperLeg"],
        LeftLowerLeg = Parts["LeftLowerLeg"],
        LeftFoot = Parts["LeftFoot"],
        LeftLowerArm = Parts["LeftLowerArm"],
        LeftUpperArm = Parts["LeftUpperArm"],
        LeftHand = Parts["LeftHand"],
        RightUpperLeg = Parts["RightUpperLeg"],
        RightLowerLeg = Parts["RightLowerLeg"],
        RightFoot = Parts["RightFoot"],
        RightLowerArm = Parts["RightLowerArm"],
        RightUpperArm = Parts["RightUpperArm"],
        RightHand = Parts["RightHand"],
        UpperTorso = Parts["UpperTorso"],
        LowerTorso = Parts["LowerTorso"],
        BodyHeightScale = 1,
        RigType = RigType,
        Whitelisted = false,
        Archenemies = false,
        Aimbot_Part = Char["Head"],
        Aimbot_TP_Part = Char["Head"],
        Triggerbot_Part = Char["Head"],
        Health = Health,
        MaxHealth = MaxHealth,
        Toolname = ToolName,
        Teamname = TeamName,
        body_parts_data = Body,
        full_body_data = Full,
    }

    return Data, InstId(Char)
end

local function AddPlayer(Char, BoolLocalPlayer, Health, MaxHealth, Username, DisplayName, UserId, TeamName, ToolName)
    if not CheckValidity(Char) then return nil end
    local ID = InstId(Char)
    if ESPQueue[ID] then return nil end
    if _G.ESPList[ID] then return nil end

    local BoolLocalPlayer = BoolLocalPlayer or false
    local Health = Health or 100
    local MaxHealth = MaxHealth or Health
    local Username = Username or "_Enemy"
    local DisplayName = DisplayName or "_Enemy"
    local UserId = UserId or 10000
    local ToolName = ToolName or "Gun"
    local TeamName = TeamName or "_Enemies"
    if BoolLocalPlayer and TeamName == "_Enemies" then TeamName = "LocalPlayer" end
    if TeamName == "_Enemies" then TeamName = "Enemies" end

    ESPQueue[InstId(Char)] = {{Char, BoolLocalPlayer, Health, MaxHealth, Username, DisplayName, UserId, TeamName, ToolName}, "Add"}
end

local function RemovePlayer(ID)
    if not ID then return false end
    if ESPQueue[ID] then return false end
    if not _G.ESPList[ID] then return false end

    ESPQueue[ID] = {{ID, "secret text"}, "Remove"}
end

local function EditHealth(ID, Health)
    if not ID or not Health then return false end
    if ESPQueue[ID] then return false end
    if not _G.ESPList[ID] then return false end
    if ID == LocalId then return false end

    ESPQueue[ID] = {{ID, Health}, "Edit"}
end

task.spawn(function()
    while true do
        local BoolESPQueue = false
        for i, v in ESPQueue do
            BoolESPQueue = true
        end
        if not BoolESPQueue then
            task.wait(WaitTime)
        else
            for ID, table in ESPQueue do
                local ActionType = table[2]
                local Table = table[1]
                if ActionType == "Add" then
                    task.wait(WaitTime)
                    ESPQueue[ID] = nil

                    local Data, InstID = ResolveData(Table[1], Table[2], Table[3], Table[4], Table[5], Table[6], Table[7], Table[8], Table[9])
                    if not Data or not InstID then continue end

                    _G.ESPList[InstID] = Data["Character"]
                    _G.ESPHealths[InstID] = Data["Health"]

                    if Data["PrimaryPart"] then
                        print("Added: " .. Data["Username"] .. ", " .. tostring(Data["RigType"]))
                        add_model_data(Data, InstID)
                    else
                        print("Added local: " .. Data["Username"] .. ", " .. tostring(Data["RigType"]))
                        override_local_data(Data)
                    end
                elseif ActionType == "Remove" then
                    task.wait(WaitTime)
                    ESPQueue[ID] = nil

                    local InstID = Table[1]
                    if not InstID then continue end

                    print("Removed: " .. InstID)
                    _G.ESPList[InstID] = nil
                    _G.ESPHealths[InstID] = nil
                    remove_model_data(InstID)
                elseif ActionType == "Edit" then
                    task.wait(WaitTime)
                    ESPQueue[ID] = nil

                    local InstID = Table[1]
                    local Health = Table[2]
                    if not InstID or not Health then continue end

                    _G.ESPHealths[InstID] = Health
                    edit_model_data({Health = Health}, InstID)
                end
            end
        end
    end
end)

return {
    AddPlayer = AddPlayer,
    RemovePlayer = RemovePlayer,
    EditHealth = EditHealth,
}
