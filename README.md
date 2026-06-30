# All libraries I've made currently are in this repository.\
---
## Guide to using them:\
\
### Highlighter.lua\
> Includes "1 function:"\
1. > Highlight("Instance:" instance, "Color:" color3, "FillOpacity:" number, "OutlineOpacity:" number, "OutlineThickness:" number)\
---
### Text.lua\
Includes 2 functions:\
1. > Add("ID:" string, "Text:" string, "Color:" color3)\
2. > Remove("ID:" string)\
---
### ESP.lua\
> Includes "3 functions:"\
1. > AddPlayer("CharacterInstance:" instance, "IsLocalPlayer:" bool, "Username:" string, "Displayname:" string, "UserId:" number, "TeamName:" string, "ToolName:" string), "returns:" ("ID:" string)\
2. > RemovePlayer("ID:" string)\
3. > EditHealth("ID:" string, "Health:" number)\
---
> Example for "ESP.lua:"\
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
