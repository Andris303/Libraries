local games = {}
games["6331902150"] = "Forsaken"
games["8307114974"] = "OperationOne"
games["3913007563"] = "BattleBricks"
games["7344582593"] = "DieOfDeath"
games["6170143659"] = "Demonology"
games["7326934954"] = "99Nights"

local gamescript = "loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Andris303/Games/refs/heads/main/" .. games[tostring(game.GameId)] .. ".lua\"))()"
local loaderscript = "loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Loader.lua\"))()"

queue_on_teleport(loaderscript)
loadstring(gamescript)()
