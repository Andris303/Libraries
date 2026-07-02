# Guide to using libs in this repository
### Highlighter.lua  
Includes 1 function:  
1. `Highlight(Instance: instance, Color: color3, FillOpacity: number, OutlineOpacity: number, OutlineThickness: number)`  
---
### Text.lua  
Includes 2 functions:  
1. `Add(ID: string, Text: string, Color: color3)`  
2. `Remove(ID: string)`  
---
### ESP.lua  
Includes 3 functions:  
1. `AddPlayer(CharacterInstance: instance, IsLocalPlayer: bool, Health: number, MaxHealth: number, Username: string, Displayname: string, UserId: number, TeamName: string, ToolName: string), returns: (ID: string)`  
2. `RemovePlayer(ID: string)`  
3. `EditHealth(ID: string, Health: number)`
4. Also uses 3 global values: Read-only: `_G.ESPList`, `_G.ESPHealths` | Needs to be declared: `_G.WaitTime`
  
Example for ESP.lua on the game Notoriety:  
```lua
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()

local function PostLocal()
    if type(workspace:GetChildren()) ~= "table" then return end
    if type(Players:GetChildren()) ~= "table" then return end
    if not workspace:FindFirstChild("Police") then return end   
    if type(workspace.Police:GetChildren()) ~= "table" then return end

    local Char = LocalPlayer.Character
    if not Char then return end

    for ID, inst in _G.ESPList do
        if not inst or not inst.Parent then
            ESP.RemovePlayer(ID)
        else
            if not inst:FindFirstChild("Health") then continue end
            if _G.ESPHealths[ID] ~= math.floor(inst.Health.Value) then
                if inst.Health.Value <= 0 then
                    ESP.RemovePlayer(ID)
                    continue
                end
                ESP.EditHealth(ID, math.floor(inst.Health.Value))
            end
        end
    end

    if not workspace:FindFirstChild("Police") then return end   
    if type(workspace.Police:GetChildren()) ~= "table" then return end

    for _, inst in workspace.Police:GetChildren() do
        if not inst or not inst.Parent then continue end
        if not inst:FindFirstChild("Health") then continue end

        ESP.AddPlayer(inst, false, inst.Health.Value, inst.Health:GetAttribute("MaxHealth"))
    end

    if type(Players:GetChildren()) ~= "table" then return end

    for _, inst in Players:GetChildren() do
        if not inst or not inst.Parent then continue end
        if inst ~= LocalPlayer then continue end

        local Char = inst.Character
        if not Char then continue end

        if not Char:FindFirstChild("Health") then continue end

        ESP.AddPlayer(Char, true, Char.Health.Value, Char.Health:GetAttribute("MaxHealth"), inst.Name, inst.DisplayName, inst.UserId)
    end
end

clear_model_data()

print("Loaded")

RunService.PostLocal:Connect(PostLocal)
```
