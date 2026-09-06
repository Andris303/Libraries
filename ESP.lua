--!optimize 2
--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local BodyParts = {"LowerTorso", "LeftLowerLeg", "LeftUpperLeg", "RightLowerLeg", "RightUpperLeg", "LeftLowerArm", "LeftUpperArm", "RightLowerArm", "RightUpperArm", "LeftHand", "RightHand"}
local FullBodyParts = {"Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
local R6Check = {"Head", "HumanoidRootPart", "Torso", "Right Arm", "Right Leg", "Left Arm", "Left Leg"}
local R15Check = {
    "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot"
}

local ESPQueue = {}
local TrackedPlayers = {}
local LocalId
local Enabled = true

_G.ESPList = _G.ESPList or {}
_G.ESPHealths = _G.ESPHealths or {}
_G.ESPData = _G.ESPData or {}

local WaitTime = _G.WaitTime or .01

local function InstId(inst)
    if not inst or not inst.Parent then
        return nil
    end

    local s, data = pcall(function()
        return inst.Data
    end)

    if not s or data == nil then
        return nil
    end

    local id = tonumber(data)
    if not id then return nil end
    return tostring(id)
end

local ListCounter = 0
local AutoEnemyIdentity = {}

local function GetAutoEnemyIdentity(model)
    local id = InstId(model)
    if not id then return nil end

    local identity = AutoEnemyIdentity[id]
    if identity then return identity end

    ListCounter += 1
    identity = {Username = "Enemy" .. tostring(ListCounter), DisplayName = "Enemy" .. tostring(ListCounter), UserId = 10000 + ListCounter}

    AutoEnemyIdentity[id] = identity
    return identity
end

local function CheckValidity(inst, NoHuman, CustomParts)
    if not inst or not inst.Parent then
        return false
    end

    if not inst:FindFirstChildOfClass("Humanoid")
    or not inst:FindFirstChild("HumanoidRootPart") then
        if not NoHuman then
            return false
        end
    end

    local parts = _G.CustomParts or CustomParts

    if parts then
        for name, part in parts do
            if name ~= "RigType" and not inst:FindFirstChild(part) then
                if inst:FindFirstChild("LeftArm") and inst.LeftArm:FindFirstChild(part) then
                    continue
                end

                if inst:FindFirstChild("RightArm") and inst.RightArm:FindFirstChild(part) then
                    continue
                end

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

local function ResolveData(Char, BoolLocalPlayer, Health, MaxHealth, Username, DisplayName, UserId, TeamName, ToolName, NoHuman, Humanoid, CustomParts)
    if not CheckValidity(Char, NoHuman, CustomParts) then return nil end

    local autoIdentity
    if Username == "_Enemy" or DisplayName == "_Enemy" or UserId == 10000 then autoIdentity = GetAutoEnemyIdentity(Char) end

    if Username == "_Enemy" and autoIdentity then Username = autoIdentity.Username end
    if DisplayName == "_Enemy" and autoIdentity then DisplayName = autoIdentity.DisplayName end
    if UserId == 10000 and autoIdentity then UserId = autoIdentity.UserId end

    local Human = Humanoid or Char:FindFirstChildOfClass("Humanoid")

    local Parts = {}
    local Body = {}
    local Full = {}
    local RigType = 0

    if Char:FindFirstChild("UpperTorso") then
        RigType = 1
    end

    local custom = _G.CustomParts or CustomParts
    if custom then
        if custom.RigType == "R6" then
            RigType = 0
        elseif custom.RigType == "R15" then
            RigType = 1
        end

        for name, part in custom do
            if name ~= "RigType" then
                Parts[name] =
                    Char:FindFirstChild(part)
                    or (Char:FindFirstChild("LeftArm") and Char.LeftArm:FindFirstChild(part))
                    or (Char:FindFirstChild("RightArm") and Char.RightArm:FindFirstChild(part))
            end
        end
    elseif RigType == 0 then
        for _, part in R6Check do
            Parts[part] = Char:FindFirstChild(part)
        end
    else
        for _, part in R15Check do
            Parts[part] = Char:FindFirstChild(part)
        end
    end

    for _, part in BodyParts do
        if Parts[part] then
            Body[#Body + 1] = {
                name = part,
                part = Parts[part],
            }
        end
    end

    for _, part in FullBodyParts do
        if Parts[part] then
            Full[#Full + 1] = {
                name = part,
                part = Parts[part],
            }
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
            Humanoid = Human,
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
            LeftFoot = Parts["LeftFoot"] or Parts["Left Leg"] or Parts["LeftLeg"],
        }

        return Data, InstId(Char)
    end

    local Data = {
        Username = Username,
        Displayname = DisplayName,
        Userid = UserId,
        Character = Char,
        Humanoid = Human,
        PrimaryPart = Parts["HumanoidRootPart"],
        Head = Parts["Head"],
        Torso = Parts["Torso"] or Parts["UpperTorso"],
        LeftLeg = Parts["Left Leg"] or Parts["LeftLeg"] or Parts["LeftUpperLeg"],
        LeftArm = Parts["Left Arm"] or Parts["LeftArm"] or Parts["LeftUpperArm"],
        RightLeg = Parts["Right Leg"] or Parts["RightLeg"] or Parts["RightUpperLeg"],
        RightArm = Parts["Right Arm"] or Parts["RightArm"] or Parts["RightUpperArm"],
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
        Aimbot_Part = Parts["Head"],
        Aimbot_TP_Part = Parts["Head"],
        Triggerbot_Part = Parts["Head"],
        Health = Health,
        MaxHealth = MaxHealth,
        Toolname = ToolName,
        Teamname = TeamName,
        body_parts_data = Body,
        full_body_data = Full,
    }

    return Data, InstId(Char)
end

local function FloorHealth(health)
    health = tonumber(health)

    if not health then
        return nil
    end

    if health <= 0 then
        return 0
    end

    local floored = math.floor(health)
    if floored == 0 then
        floored = 1
    end

    return floored
end

local function ReadNumber(source)
    if source == nil then
        return nil
    end

    if type(source) == "number" then
        return source
    end

    if type(source) == "function" then
        local s, value = pcall(source)

        if s then
            return tonumber(value)
        end

        return nil
    end

    local s, value = pcall(function()
        return source.Value
    end)

    if s then
        return tonumber(value)
    end

    return nil
end

local function GetHealth(data)
    if data.GetHealth then
        local s, health, maxHealth = pcall(data.GetHealth, data)

        if s then
            return tonumber(health), tonumber(maxHealth)
        end
    end

    local source = data.HealthSource

    if not source and data.SourceCharacter then
        source = data.SourceCharacter:FindFirstChildOfClass("Humanoid")
    end

    if not source then
        source = data.Character:FindFirstChildOfClass("Humanoid")
    end

    if source then
        local s, health = pcall(function()
            return source.Health
        end)

        if s and tonumber(health) then
            local s2, maxHealth = pcall(function()
                return source.MaxHealth
            end)

            if s2 then
                return tonumber(health), tonumber(maxHealth)
            end

            return tonumber(health), nil
        end

        local value = ReadNumber(source)

        if value ~= nil then
            local maxHealth

            if data.MaxHealthSource ~= nil then
                maxHealth = ReadNumber(data.MaxHealthSource)
            end

            if maxHealth == nil then
                maxHealth = tonumber(data.MaxHealth)
            end

            return value, maxHealth
        end
    end

    return tonumber(data.Health), tonumber(data.MaxHealth)
end

local function GetTeam(data)
    if data.GetTeam then
        local s, team = pcall(data.GetTeam, data)

        if s and team ~= nil then
            return tostring(team)
        end
    end

    if data.TeamType == "Player" then
        local player = data.Player

        if player then
            local s, team = pcall(function()
                return player.Team
            end)

            if s and team then
                return team.Name
            end
        end

        return "Spectator"
    end

    if data.TeamType == "Parent" then
        local source = data.TeamSource or data.SourceCharacter or data.Character

        if source and source.Parent then
            return source.Parent.Name
        end

        return "Spectator"
    end

    return data.TeamName or "_Enemies"
end

local function GetLocalTeam(data)
    if data.GetLocalTeam then
        local s, team = pcall(data.GetLocalTeam, data)

        if s and team ~= nil then
            return tostring(team)
        end
    end

    if data.TeamType == "Player" then
        if LocalPlayer.Team then
            return LocalPlayer.Team.Name
        end

        return "Spectator"
    end

    if data.TeamType == "Parent" then
        local char = LocalPlayer.Character

        if char and char.Parent then
            return char.Parent.Name
        end

        return "Spectator"
    end

    return data.LocalTeamName
end

local function GetTool(data)
    if data.GetTool then
        local s, tool = pcall(data.GetTool, data)

        if s then
            if tool == nil then
                return ""
            end

            return tostring(tool)
        end
    end

    return tostring(data.ToolName or "")
end

local function TeamCheckActive()
    if type(is_team_check_active) ~= "function" then
        return false
    end

    local s, result = pcall(is_team_check_active)
    return s and result == true
end

local function ExtraVisibleCheck(data)
    if not data.ShouldShow then
        return true
    end

    local s, result = pcall(data.ShouldShow, data)

    if not s then
        return true
    end

    return result ~= false
end

local function ResolveID(target)
    if type(target) == "string" then
        return target
    end

    return InstId(target)
end

local function QueueAdd(data)
    local ID = data.ID

    if ESPQueue[ID] or _G.ESPList[ID] then
        return
    end

    ESPQueue[ID] = {
        Action = "Add",
        Data = data,
    }
end

local function QueueRemove(ID)
    if not ID then return end
    local queued = ESPQueue[ID]

    if queued then
        if queued.Action == "Add" then
            ESPQueue[ID] = nil
            return
        elseif queued.Action == "Remove" then
            return
        end
    end

    if not _G.ESPList[ID] then return end

    ESPQueue[ID] = {
        Action = "Remove",
        ID = ID
    }
end

local function QueueEdit(ID, edits)
    if not ID or not edits then return end
    local queued = ESPQueue[ID]

    if queued then
        if queued.Action == "Edit" then
            for name, value in edits do
                queued.Edits[name] = value
            end
        end

        return
    end

    if not _G.ESPList[ID] then
        return
    end

    ESPQueue[ID] = {
        Action = "Edit",
        ID = ID,
        Edits = edits,
    }
end

local function AddVisual(data)
    local human

    if data.HealthSource then
        pcall(function()
            if data.HealthSource.ClassName == "Humanoid" then
                human = data.HealthSource
            end
        end)
    end

    if not human and data.SourceCharacter then
        human = data.SourceCharacter:FindFirstChildOfClass("Humanoid")
    end

    if not human then
        human = data.Character:FindFirstChildOfClass("Humanoid")
    end

    local Data, ID = ResolveData(
        data.Character,
        data.IsLocal,
        data.DisplayHealth,
        data.DisplayMaxHealth,
        data.Username,
        data.DisplayName,
        data.UserId,
        data.CurrentTeam,
        data.CurrentTool,
        data.NoHuman,
        human,
        data.CustomParts
    )

    if not Data or not ID then
        return
    end

    _G.ESPList[ID] = Data.Character
    _G.ESPHealths[ID] = Data.Health
    _G.ESPData[ID] = Data

    if Data.PrimaryPart then
        add_model_data(Data, ID)
    else
        LocalId = ID
        override_local_data(Data)
    end
end

local function RemoveVisual(ID)
    if not _G.ESPList[ID] then
        return
    end

    local isLocal = ID == LocalId or (_G.ESPData[ID] and _G.ESPData[ID].LocalPlayer)

    _G.ESPList[ID] = nil
    _G.ESPHealths[ID] = nil
    _G.ESPData[ID] = nil

    if isLocal then
        clear_local_data()
    else
        remove_model_data(ID)
    end
end

local function EditVisual(ID, edits)
    local data = _G.ESPData[ID]
    if not data then return end

    for name, value in edits do
        data[name] = value
    end

    if edits.Health ~= nil then
        _G.ESPHealths[ID] = edits.Health
    end

    if ID == LocalId or data.LocalPlayer then
        override_local_data(data)
    else
        edit_model_data(edits, ID)
    end
end

task.spawn(function()
    while true do
        local didWork = false

        for ID, action in ESPQueue do
            didWork = true
            task.wait(WaitTime)
            if ESPQueue[ID] ~= action then
                continue
            end
            ESPQueue[ID] = nil
            if action.Action == "Add" then
                local data = action.Data
                if data and TrackedPlayers[ID] == data and data.WantsVisible then
                    AddVisual(data)
                end
            elseif action.Action == "Remove" then
                RemoveVisual(ID)
            elseif action.Action == "Edit" then
                EditVisual(ID, action.Edits)
            end
        end

        if not didWork then
            task.wait(WaitTime)
        end
    end
end)

local function BuildLegacyOptions(Char, BoolLocalPlayer, Health, MaxHealth, Username, DisplayName, UserId, TeamName, ToolName, NoHuman, Humanoid, CustomParts)
    local player

    if Username then
        player = Players:FindFirstChild(Username)
    end

    return {
        Player = player,
        IsLocal = BoolLocalPlayer,
        Health = Health,
        MaxHealth = MaxHealth,
        Username = Username,
        DisplayName = DisplayName,
        UserId = UserId,
        TeamType = "Manual",
        TeamName = TeamName,
        ToolName = ToolName,
        NoHuman = NoHuman,
        HealthSource = Humanoid,
        CustomParts = CustomParts,
    }
end

local function ConfigureTracked(data, options)
    local player = options.Player

    data.Player = player
    data.SourceCharacter = options.SourceCharacter or (player and player.Character) or data.SourceCharacter or data.Character
    data.IsLocal = options.IsLocal == true or player == LocalPlayer
    data.HealthSource = options.HealthSource or data.HealthSource
    data.MaxHealthSource = options.MaxHealthSource or data.MaxHealthSource
    data.GetHealth = options.GetHealth or data.GetHealth
    data.Health = options.Health or data.Health or 100
    data.MaxHealth = options.MaxHealth or data.MaxHealth or data.Health
    data.TeamType = options.TeamType or data.TeamType or "Parent"
    data.TeamSource = options.TeamSource or data.TeamSource
    data.TeamName = options.TeamName or data.TeamName
    data.LocalTeamName = options.LocalTeamName or data.LocalTeamName
    data.GetTeam = options.GetTeam or data.GetTeam
    data.GetLocalTeam = options.GetLocalTeam or data.GetLocalTeam
    data.ToolName = options.ToolName or data.ToolName or ""
    data.GetTool = options.GetTool or data.GetTool
    data.ShouldShow = options.ShouldShow or data.ShouldShow
    data.NoHuman = options.NoHuman == true or data.NoHuman == true
    data.CustomParts = options.CustomParts or data.CustomParts
    local autoIdentity
    if not player and (not options.Username or not options.DisplayName or not options.UserId) then autoIdentity = GetAutoEnemyIdentity(data.Character) end

    data.Username = options.Username or (player and player.Name) or (data.Username ~= "_Enemy" and data.Username) or (autoIdentity and autoIdentity.Username) or "_Enemy"
    data.DisplayName = options.DisplayName or (player and player.DisplayName) or (data.DisplayName ~= "_Enemy" and data.DisplayName) or (autoIdentity and autoIdentity.DisplayName) or data.Username or "_Enemy"
    data.UserId = options.UserId or (player and player.UserId) or (data.UserId ~= 10000 and data.UserId) or (autoIdentity and autoIdentity.UserId) or 10000
end

local function AddPlayer(Char, OptionsOrLocal, Health, MaxHealth, Username, DisplayName, UserId, TeamName, ToolName, NoHuman, Humanoid, CustomParts)
    if not Char or not Char.Parent then
        return nil
    end

    local ID = InstId(Char)
    if not ID then
        return nil
    end

    local options

    if type(OptionsOrLocal) == "table" then
        options = OptionsOrLocal
    else
        options = BuildLegacyOptions(Char, OptionsOrLocal, Health, MaxHealth, Username, DisplayName, UserId, TeamName, ToolName, NoHuman, Humanoid, CustomParts)
    end

    local data = TrackedPlayers[ID]
    if not data then
        data = {
            ID = ID,
            Character = Char,
            WantsVisible = false,
        }

        TrackedPlayers[ID] = data
    end

    data.Character = Char
    ConfigureTracked(data, options)

    return ID
end

local function RemovePlayer(target)
    local ID = ResolveID(target)
    if not ID then
        return false
    end

    TrackedPlayers[ID] = nil
    QueueRemove(ID)

    return true
end

local function IsTracked(target)
    local ID = ResolveID(target)
    return ID ~= nil and TrackedPlayers[ID] ~= nil
end

local function GetTracked(target)
    local ID = ResolveID(target)
    if not ID then
        return nil
    end

    return TrackedPlayers[ID]
end

local function EditHealth(target, health)
    local ID = ResolveID(target)
    if not ID then return false end

    local data = TrackedPlayers[ID]
    if not data then return false end

    local fixed = FloorHealth(health)
    if not fixed or fixed <= 0 then return false end

    data.Health = fixed
    data.DisplayHealth = fixed
    QueueEdit(ID, {Health = fixed})

    return true
end

local function SetEnabled(value)
    Enabled = value == true
end

local function Clear()
    for ID in TrackedPlayers do
        QueueRemove(ID)
    end

    TrackedPlayers = {}
end

local function UpdateTrackedPlayers()
    local removeTracked = {}

    for ID, data in TrackedPlayers do
        local char = data.Character

        if not char or not char.Parent then
            QueueRemove(ID)
            removeTracked[#removeTracked + 1] = ID
            continue
        end

        local rawHealth, rawMaxHealth = GetHealth(data)

        if rawHealth == nil then
            rawHealth = data.Health or 100
        end

        if rawMaxHealth == nil then
            rawMaxHealth = data.MaxHealth or rawHealth or 100
        end

        local displayHealth = FloorHealth(rawHealth)
        local displayMaxHealth = FloorHealth(rawMaxHealth)

        if displayMaxHealth == 0 then
            displayMaxHealth = 1
        end

        data.DisplayHealth = displayHealth and math.max(displayHealth, 1) or 100
        data.DisplayMaxHealth = displayMaxHealth or data.DisplayHealth

        local team = GetTeam(data)
        local tool = GetTool(data)
        data.CurrentTeam = team
        data.CurrentTool = tool

        local alive = rawHealth == nil or rawHealth > 0
        local teamBlocked = false

        if TeamCheckActive() then
            local localTeam = GetLocalTeam(data)

            if localTeam ~= nil and team ~= nil and tostring(localTeam) == tostring(team) then
                teamBlocked = true
            end
        end

        local wantsVisible = Enabled and alive and not teamBlocked and ExtraVisibleCheck(data)
        data.WantsVisible = wantsVisible

        if wantsVisible then
            if not _G.ESPList[ID] then
                QueueAdd(data)
            else
                local espData = _G.ESPData[ID]

                if espData then
                    local rebuild = espData.MaxHealth ~= data.DisplayMaxHealth or espData.Teamname ~= team or espData.Toolname ~= tool

                    if rebuild then
                        QueueRemove(ID)
                    elseif espData.Health ~= data.DisplayHealth then
                        QueueEdit(
                            ID,
                            {Health = data.DisplayHealth,}
                        )
                    end
                end
            end
        else
            QueueRemove(ID)
        end
    end

    for _, ID in removeTracked do
        TrackedPlayers[ID] = nil
    end
end

task.spawn(function()
    while true do
        UpdateTrackedPlayers()
        task.wait(.05)
    end
end)

return {
    AddPlayer = AddPlayer,
    RemovePlayer = RemovePlayer,
    EditHealth = EditHealth,
    IsTracked = IsTracked,
    GetTracked = GetTracked,
    SetEnabled = SetEnabled,
    Clear = Clear,
}
