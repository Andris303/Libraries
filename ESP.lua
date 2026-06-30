local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Counter = 0
local Timer = 0
local ESP = {}
local BodyParts = {"LowerTorso", "Right Arm", "Right Leg", "Left Arm", "Left Leg", "LeftLowerLeg", "LeftUpperLeg", "RightLowerLeg", "RightUpperLeg", "LeftLowerArm", "LeftUpperArm", "RightLowerArm", "RightUpperArm", "LeftHand", "RightHand"}
local FullParts = {"Head", "Torso", "Right Arm", "Right Leg", "Left Arm", "Left Leg", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
local R6Check = {"Head", "Torso", "Right Arm", "Right Leg", "Left Arm", "Left Leg"}
local R15Check = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
local LocalId

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

local function AddData(Char, BoolLocalPlayer, Username, DisplayName, UserId, TeamName, ToolName)
    if ESP[InstId(Char)] then return nil end
    if not CheckValidity(Char) then return nil end
    ESP[InstId(Char)] = Char

    Counter += 1
    local BoolLocalPlayer = BoolLocalPlayer or false
    local Username = Username or "Enemy" .. tostring(Counter)
    local DisplayName = DisplayName or "Enemy" .. tostring(Counter)
    local UserId = UserId or 10000 + Counter
    local ToolName = ToolName or "Gun"

    local TeamName = TeamName or "nmWRunDYxcqH"
    if BoolLocalPlayer and TeamName == "nmWRunDYxcqH" then TeamName = "LocalPlayer" end
    if TeamName == "nmWRunDYxcqH" then TeamName = "Enemies" end

    if BoolLocalPlayer then
        LocalId = InstId(Char)
        override_local_data({
            LocalPlayer = LocalPlayer,
            Character = Char,
            Username = Username,
            Displayname = DisplayName,
            Userid = UserId,
            Humanoid = Char.Humanoid,
            Health = Char.Humanoid.Health,
            MaxHealth = Char.Humanoid.MaxHealth,
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
        })

        return InstId(Char)
    end

    local Parts = {
        Head = Char:FindFirstChild("Head"),
        HumanoidRootPart = Char:FindFirstChild("HumanoidRootPart"),
        Torso = Char:FindFirstChild("Torso"),
        RightArm = Char:FindFirstChild("Right Arm"),
        RightLeg = Char:FindFirstChild("Right Leg"),
        LeftArm = Char:FindFirstChild("Left Arm"),
        LeftLeg = Char:FindFirstChild("Left Leg"),
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
        Health = math.floor(Char.Humanoid.Health),
        MaxHealth = Char.Humanoid.MaxHealth,
        Toolname = ToolName,
        Teamname = TeamName,
        body_parts_data = Body,
        full_body_data = Full,
    }

    add_model_data(Data, InstId(Char))

    return InstId(Char)
end

local function RemoveData(ID)
    if not ID then return false end

    ESP[ID] = nil
    remove_model_data(ID)

    return true
end

local function EditHealth(ID, Health)
    if not ID or not Health then return false end
    if not ESP[ID] then return false end
    if ID == LocalId then return false end

    edit_model_data({
        Health = Health
    }, ID)

    return true
end

return {
    AddPlayer = AddData,
    RemovePlayer = RemoveData,
    EditHealth = EditHealth,
}
