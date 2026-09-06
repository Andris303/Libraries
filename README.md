# Libraries in this repo
### Highlighter.lua
Highlights parts in a block shape, supports baseparts, meshparts and union operations.
1. `Highlight(Instance: instance, Color: color3, FillOpacity: number, OutlineOpacity: number, OutlineThickness: number)`
2. `HighlightGroup(InstanceTable: table, Color: color3, FillOpacity: number, OutlineOpacity: number, OutlineThickness: number)`  
---
### Text.lua  
Renders text on the bottom left of the screen.
1. `Add(ID: string, Text: string, Color: color3)`  
2. `Remove(ID: string)`  
---
### ESP.lua  
An easy to use library to add ESP support to games. All model, health, team, rig tracking is done by the script.
1. `AddPlayer(Character: instance, Data: table)`
2. `IsTracked()`
3. `SetEnabled(Enable: bool)`
4. `Clear()`
+ 3 Misc. functions

AddPlayer data table formatting:
The data table isn't required, but it should be used to change how the library handles adding the character.

```lua
Player -- Instance: player associated with the character
IsLocal -- Boolean: is this the local player?
HealthSource -- Instance: object that health is read from (can be humanoid or numbervalue)
GetHealth -- Function: func that is used for getting the character's health (incase of special health tracking)
Health -- Number: Default health if health can't be tracked
MaxHealth -- Number: Default maxhealth if maxhealth can't be tracked
TeamType -- String: How the player's team should be read: types: "Player": .Team property of the player, "Parent" name of the parent of the instance, "Manual" set team manually
TeamName -- String: Default team if team can't be tracked
LocalTeamname -- String: Name of friendly team (IMPORTANT: this is required if you want to use severe's teamcheck)
GetTeam -- Function: func that is used for getting the character's team (incase of special team tracking)
ToolName -- Number: Default tool if tool can't be tracked
GetTool -- Function: func that is used for getting the character's tool (Tool tracking isn't default, so use this if want to show tools)
NoHuman -- Boolean: Whether or not the character has a humanoid
CustomParts -- Table: Custom rig table for custom player models
Username -- String: Username to use (MAKE SURE THIS IS DIFFERENT FOR ALL NPCS, useful for npcs without player instances)
DisplayName -- String: Displayname to use (useful for npcs without player instances)
UserId -- String: UserId to use

-- CustomParts formatting:
RigParts = {
    RigType = "R6",
    HumanoidRootPart = "HumanoidRootPart",
    Head = "Head",
    Torso = "Torso",
    RightLeg = "Right Leg",
    ...
}
```

Example script:
```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()

local function PreData()
    for _, inst in Players:GetChildren() do
        local Char = inst.Character
        if not Char then return end
        if not Char:FindFirstChild("Humanoid") then return end

        if not ESP.IsTracked(Char) then
            ESP.AddPlayer(Char, {
                Player = inst,
                TeamType = "Player",
            })
        end
    end
end

RunService.PreData:Connect(PreData)
```
