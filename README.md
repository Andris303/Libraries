All libraries I've made currently are in this repository.\n
Guide to using them:\n

Highlighter.lua\n
Includes 1 function:\n
Highlight(Instance: instance, Color: Color3, FillOpacity: Number, OutlineOpacity: Number, OutlineThickness: Number)\n


Text.lua\n
Includes 2 functions:\n
Add(ID: string, Text: string, Color: Color3)\n
Remove(ID: string)\n


ESP.lua\n
Includes 3 functions:\n
AddPlayer(CharacterInstance: instance, IsLocalPlayer: bool, Username: string, Displayname: string, UserId: number, TeamName: string, ToolName: string), returns: (ID: string)\n
RemovePlayer(ID: string)\n
EditHealth(ID: string, Health: number)\n

Example for ESP.lua:\n
```lua
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ListPlayers = {}
local ListHealths = {}
local Timer = 0

local function PreLocal()
    if not workspace then return end
    if type(workspace:GetChildren()) ~= "table" then return end

    if os.clock() < Timer then return end
    Timer = os.clock() + 0.1

    for ID, inst in ListPlayers do
        if not inst or not inst.Parent then
            ListPlayers[ID] = nil
            ListHealths[ID] = nil
            Lib.RemovePlayer(ID)
        elseif ListHealths[ID] ~= math.floor(inst.Humanoid.Health) then
            ListHealths[ID] = math.floor(inst.Humanoid.Health)
            Lib.EditHealth(ID, math.floor(inst.Humanoid.Health))
        end
    end

    if not Players then return end
    if type(Players:GetChildren()) ~= "table" then return end

    for _, inst in Players:GetChildren() do
        if not inst or not inst.Parent then continue end

        local Char = inst.Character
        if not Char then continue end

        local team = nil
        if inst.Team then
            team = inst.Team.Name
        end

        local ID = Lib.AddPlayer(Char, LocalPlayer == inst, inst.Name, inst.DisplayName, inst.UserId, team)
        if ID then
            ListPlayers[ID] = Char
            ListHealths[ID] = math.floor(Char.Humanoid.Health)
        end
    end
end

RunService.PreLocal:Connect(PreLocal)
```
