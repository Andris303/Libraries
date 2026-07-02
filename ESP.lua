local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local BodyParts = {"LowerTorso", "Right Arm", "Right Leg", "Left Arm", "Left Leg", "LeftLowerLeg", "LeftUpperLeg", "RightLowerLeg", "RightUpperLeg", "LeftLowerArm", "LeftUpperArm", "RightLowerArm", "RightUpperArm", "LeftHand", "RightHand"}
local FullParts = {"Head", "Torso", "Right Arm", "Right Leg", "Left Arm", "Left Leg", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
local R6Check = {"Head", "Torso", "Right Arm", "Right Leg", "Left Arm", "Left Leg"}
local R15Check = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
local ListCounter = 0
local ESPQueue = {}
local LocalId

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

    if inst:FindFirstChild("Torso") then
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
            RigType = Char:FindFirstChild("RightUpperArm") and 1 or 0,
            Teamname = TeamName,
            Toolname = ToolName,
            Head = Char.Head,
            RootPart = Char.HumanoidRootPart,
            LowerTorso = Char:FindFirstChild("LowerTorso") or Char.Torso,
            UpperTorso = Char:FindFirstChild("UpperTorso") or Char.Torso,
            LeftArm = Char:FindFirstChild("Left Arm") or Char.LeftUpperArm,
            RightArm = Char:FindFirstChild("Right Arm") or Char.RightUpperArm,
            LeftLeg = Char:FindFirstChild("Left Leg") or Char.LeftUpperLeg,
            RightLeg = Char:FindFirstChild("Right Leg") or Char.RightUpperLeg,
            LeftFoot = Char:FindFirstChild("LeftFoot") or Char["Left Leg"],
        }

        return Data, InstId(Char)
    end

    local Parts = {
        Head = Char:FindFirstChild("Head"),
        HumanoidRootPart = Char:FindFirstChild("HumanoidRootPart"),
        Torso = Char:FindFirstChild("Torso"),
        UpperTorso = Char:FindFirstChild("UpperTorso"),
        LowerTorso = Char:FindFirstChild("LowerTorso"),
        LeftUpperArm = Char:FindFirstChild("LeftUpperArm"),
        LeftLowerArm = Char:FindFirstChild("LeftLowerArm"),
        LeftHand = Char:FindFirstChild("LeftHand"),
        RightUpperArm = Char:FindFirstChild("RightUpperArm"),
        RightLowerArm = Char:FindFirstChild("RightLowerArm"),
        RightHand = Char:FindFirstChild("RightHand"),
        LeftUpperLeg = Char:FindFirstChild("LeftUpperLeg"),
        LeftLowerLeg = Char:FindFirstChild("LeftLowerLeg"),
        LeftFoot = Char:FindFirstChild("LeftFoot"),
        RightUpperLeg = Char:FindFirstChild("RightUpperLeg"),
        RightLowerLeg = Char:FindFirstChild("RightLowerLeg"),
        RightFoot = Char:FindFirstChild("RightFoot"),
    }

    local Body, Full = {}, {}
    for _, Name in BodyParts do
        if Parts[Name] then Body[#Body + 1] = {name = Name, part = Parts[Name]} end
    end
    for _, Name in FullParts do
        if Parts[Name] then Full[#Full + 1] = {name = Name, part = Parts[Name]} end
    end

    local Data = {
        Username = Username,
        Displayname = DisplayName,
        Userid = UserId,
        Character = Char,
        PrimaryPart = Char.HumanoidRootPart,
        Humanoid = Char.Humanoid,
        Head = Char.Head,
        Torso = Char:FindFirstChild("Torso") or Char.UpperTorso,
        LeftLeg = Char:FindFirstChild("Left Leg") or Char.LeftUpperLeg,
        LeftArm = Char:FindFirstChild("Left Arm") or Char.LeftUpperArm,
        RightLeg = Char:FindFirstChild("Right Leg") or Char.RightUpperLeg,
        RightArm = Char:FindFirstChild("Right Arm") or Char.RightUpperArm,
        LeftUpperLeg = Char:FindFirstChild("LeftUpperLeg"),
        LeftLowerLeg = Char:FindFirstChild("LeftLowerLeg"),
        LeftFoot = Char:FindFirstChild("LeftFoot"),
        LeftLowerArm = Char:FindFirstChild("LeftLowerArm"),
        LeftUpperArm = Char:FindFirstChild("LeftUpperArm"),
        LeftHand = Char:FindFirstChild("LeftHand"),
        RightUpperLeg = Char:FindFirstChild("RightUpperLeg"),
        RightLowerLeg = Char:FindFirstChild("RightLowerLeg"),
        RightFoot = Char:FindFirstChild("RightFoot"),
        RightLowerArm = Char:FindFirstChild("RightLowerArm"),
        RightUpperArm = Char:FindFirstChild("RightUpperArm"),
        RightHand = Char:FindFirstChild("RightHand"),
        UpperTorso = Char:FindFirstChild("UpperTorso"),
        LowerTorso = Char:FindFirstChild("LowerTorso"),
        BodyHeightScale = 1,
        RigType = Char:FindFirstChild("RightUpperArm") and 1 or 0,
        Whitelisted = false,
        Archenemies = false,
        Aimbot_Part = Char.Head,
        Aimbot_TP_Part = Char.Head,
        Triggerbot_Part = Char.Head,
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
                        print("Added: " .. Data["Username"])
                        add_model_data(Data, InstID)
                    else
                        print("Added local: " .. Data["Username"])
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
