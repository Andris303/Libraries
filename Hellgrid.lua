--!optimize 2

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local runId = (_G.HellgridRun or 0) + 1
_G.HellgridRun = runId

local Engine = {
    Blocks = {},
    Camera = {X = 0, Y = .5, Z = 0, Yaw = 0, Pitch = 0, Fov = math.rad(100)},
    NearPlane = .05,
    FogDistance = 22,
    Ambient = .35,
    LightDirection = vector.normalize(vector.create(.4, .8, .3)),
    SkyColor = {22, 20, 26},
    GroundColor = {70, 55, 45},
    Floor = 0,
    Player = {Position = vector.zero, Velocity = vector.zero, OnGround = false},
    WalkSpeed = 3.4,
    SprintSpeed = 5.6,
    FlySpeed = 4,
    GroundAcceleration = 14,
    AirAcceleration = 3,
    Gravity = 20,
    JumpPower = 6.2,
    StepHeight = .4,
    CoyoteTime = .1,
    JumpBuffer = .12,
    EyeHeight = .45,
    HeadBob = .025,
    Flying = false,
    Debug = false,
    TurnSpeed = 2.2,
    PitchSpeed = 1.6,
    MouseSensitivity = .0015,
    Outlines = true,
    BuildBudget = .002,
    TurnMargin = 0,
    PlayerRadius = .2,
    PlayerHeight = .55,
    OutlineDistance = math.huge,
    Collision = true,
    MouseLook = true,
    BlockRobloxInput = true,
    Active = true,
    OnUpdate = nil,
}

local maxPitch = math.rad(85)
local maxFrameTime = .05
local moveSubstep = .05
local groundProbe = .03
local groundBands = 16
local cullMargin = math.rad(20)
local toggleReleaseTime = .2
local cylinderSides = 16
local sphereRings = 6
local sphereSegments = 12

local Keys = {}
local DrawList = {}
local lastUpdate = os.clock()
local tickStart = os.clock()
local tickLength = 1 / 60
local PreviousCamera = {}
local bToggleHeld = false
local lastToggleSeen = 0
local bSpaceHeld = false
local bFlyHeld = false
local coyoteTimer = 0
local jumpBufferTimer = 0
local stepOffset = 0
local bobPhase = 0
local renderCount = 0
local renderTime = 0
local prepareCount = 0
local prepareTime = 0
local lastBuildSeconds = 0
local mouseSettleTicks = 3
local turnRate = 0
local colorCache = {}
local colorCacheFog = nil
local updateCount = 0
local lastDebugPrint = os.clock()
local viewportWidth, viewportHeight = 1920, 1080

local function Running()
    return _G.HellgridRun == runId
end

local function Rgb(color, shade)
    return Color3.fromRGB(math.floor(math.clamp(color[1] * shade, 0, 255)), math.floor(math.clamp(color[2] * shade, 0, 255)), math.floor(math.clamp(color[3] * shade, 0, 255)))
end

local function Fogged(color, shade, fogColor, amount)
    local keep = 1 - amount
    return Color3.fromRGB(
        math.floor(math.clamp(color[1] * shade * keep + fogColor[1] * amount, 0, 255)),
        math.floor(math.clamp(color[2] * shade * keep + fogColor[2] * amount, 0, 255)),
        math.floor(math.clamp(color[3] * shade * keep + fogColor[3] * amount, 0, 255))
    )
end

local function CachedColor(color, light, amount)
    local fogColor = Engine.FogColor
    if fogColor ~= colorCacheFog then
        table.clear(colorCache)
        colorCacheFog = fogColor
    end
    local level = math.floor(light * 64 + .5)
    local step = math.floor(amount * 256 + .5)
    local byColor = colorCache[color]
    if not byColor then
        byColor = {}
        colorCache[color] = byColor
    end
    local key = level * 257 + step
    local cached = byColor[key]
    if not cached then
        cached = fogColor and Fogged(color, level / 64, fogColor, step / 256) or Rgb(color, level / 64)
        byColor[key] = cached
    end
    return cached
end

local function Outward(points, shapeCenter)
    local center = vector.zero
    for _, point in points do
        center += point
    end
    center /= #points
    local normal = vector.cross(points[2] - points[1], points[3] - points[1])
    if vector.dot(normal, center - (shapeCenter or vector.zero)) < 0 then
        local reversed = {}
        for index = #points, 1, -1 do
            reversed[#reversed + 1] = points[index]
        end
        return reversed
    end
    return points
end

local function V(x, y, z)
    return vector.create(x, y, z)
end

local function BuildShapes()
    local shapes = {}

    local corners = {V(-.5, -.5, -.5), V(.5, -.5, -.5), V(.5, .5, -.5), V(-.5, .5, -.5), V(-.5, -.5, .5), V(.5, -.5, .5), V(.5, .5, .5), V(-.5, .5, .5)}
    shapes.Block = {}
    local blockFaces = {North = {1, 2, 3, 4}, South = {5, 6, 7, 8}, West = {1, 5, 8, 4}, East = {2, 6, 7, 3}, Top = {4, 3, 7, 8}, Bottom = {1, 2, 6, 5}}
    for name, quad in blockFaces do
        local face = Outward({corners[quad[1]], corners[quad[2]], corners[quad[3]], corners[quad[4]]})
        face.Name = name
        shapes.Block[#shapes.Block + 1] = face
    end

    local wedgeCenter = V(0, -1 / 6, 1 / 6)
    shapes.Wedge = {
        Outward({V(-.5, -.5, -.5), V(.5, -.5, -.5), V(.5, -.5, .5), V(-.5, -.5, .5)}, wedgeCenter),
        Outward({V(-.5, -.5, .5), V(.5, -.5, .5), V(.5, .5, .5), V(-.5, .5, .5)}, wedgeCenter),
        Outward({V(-.5, -.5, -.5), V(.5, -.5, -.5), V(.5, .5, .5), V(-.5, .5, .5)}, wedgeCenter),
        Outward({V(-.5, -.5, -.5), V(-.5, -.5, .5), V(-.5, .5, .5)}, wedgeCenter),
        Outward({V(.5, -.5, -.5), V(.5, -.5, .5), V(.5, .5, .5)}, wedgeCenter),
    }

    local apex = V(0, .5, 0)
    local base = {V(-.5, -.5, -.5), V(.5, -.5, -.5), V(.5, -.5, .5), V(-.5, -.5, .5)}
    shapes.Pyramid = {Outward(base)}
    for index = 1, 4 do
        shapes.Pyramid[#shapes.Pyramid + 1] = Outward({base[index], base[index % 4 + 1], apex})
    end

    shapes.Cylinder = {}
    local top, bottom = {}, {}
    for side = 1, cylinderSides do
        local angle = (side - 1) / cylinderSides * math.pi * 2
        top[side] = V(math.cos(angle) * .5, .5, math.sin(angle) * .5)
        bottom[side] = V(math.cos(angle) * .5, -.5, math.sin(angle) * .5)
    end
    for side = 1, cylinderSides do
        local nextSide = side % cylinderSides + 1
        shapes.Cylinder[#shapes.Cylinder + 1] = Outward({bottom[side], bottom[nextSide], top[nextSide], top[side]})
    end
    shapes.Cylinder[#shapes.Cylinder + 1] = Outward(top)
    shapes.Cylinder[#shapes.Cylinder + 1] = Outward(bottom)

    shapes.Sphere = {}
    local rings = {}
    for ring = 0, sphereRings do
        local latitude = ring / sphereRings * math.pi
        rings[ring] = {}
        for segment = 1, sphereSegments do
            local longitude = (segment - 1) / sphereSegments * math.pi * 2
            rings[ring][segment] = V(math.sin(latitude) * math.cos(longitude) * .5, math.cos(latitude) * .5, math.sin(latitude) * math.sin(longitude) * .5)
        end
    end
    for ring = 0, sphereRings - 1 do
        for segment = 1, sphereSegments do
            local nextSegment = segment % sphereSegments + 1
            local a, b = rings[ring][segment], rings[ring][nextSegment]
            local c, d = rings[ring + 1][nextSegment], rings[ring + 1][segment]
            if ring == 0 then
                shapes.Sphere[#shapes.Sphere + 1] = Outward({a, c, d})
            elseif ring == sphereRings - 1 then
                shapes.Sphere[#shapes.Sphere + 1] = Outward({a, b, d})
            else
                shapes.Sphere[#shapes.Sphere + 1] = Outward({a, b, c, d})
            end
        end
    end

    shapes.Plane = {{V(-.5, 0, -.5), V(-.5, 0, .5), V(.5, 0, .5), V(.5, 0, -.5)}}
    return shapes
end

local Shapes = BuildShapes()

local BlockMethods = {}
BlockMethods.__index = BlockMethods

function BlockMethods:Destroy()
    local index = table.find(Engine.Blocks, self)
    if index then table.remove(Engine.Blocks, index) end
end

function Engine.new(shape, position, size, color)
    if not Shapes[shape] then
        error("Unknown shape: " .. tostring(shape) .. " (Block, Wedge, Pyramid, Cylinder, Sphere, Plane)")
    end
    local block = setmetatable({
        Shape = shape,
        Position = position or vector.zero,
        Size = size or V(1, 1, 1),
        Color = color or {160, 160, 170},
        Yaw = 0,
        Visible = true,
        CanCollide = true,
    }, BlockMethods)
    Engine.Blocks[#Engine.Blocks + 1] = block
    return block
end

function Engine.Clear()
    table.clear(Engine.Blocks)
end

function Engine.Stop()
    if Running() then
        _G.HellgridRun = runId + 1
        block_roblox_window(false)
    end
end

local function IsDown(...)
    for _, name in {...} do
        if Keys[name] then return true end
    end
    return false
end

local function IsNameDown(...)
    for key in Keys do
        local lowered = string.lower(key)
        for _, fragment in {...} do
            if string.find(lowered, fragment, 1, true) then return true end
        end
    end
    return false
end

local function BlockBounds(block)
    local half = block.Size / 2
    local low, high = block.Position - half, block.Position + half
    if block.Shape == "Plane" then
        low, high = V(low.x, block.Position.y, low.z), V(high.x, block.Position.y, high.z)
    end
    return low, high
end

local function Collides(position)
    if not Engine.Collision then return false end
    local radius, height = Engine.PlayerRadius, Engine.PlayerHeight
    local minX, minY, minZ = position.x - radius, position.y, position.z - radius
    local maxX, maxY, maxZ = position.x + radius, position.y + height, position.z + radius
    if Engine.Floor and minY < Engine.Floor - 1e-4 then return true end
    for _, block in Engine.Blocks do
        if block.CanCollide then
            local low, high = BlockBounds(block)
            if minX < high.x and maxX > low.x and minY < high.y and maxY > low.y and minZ < high.z and maxZ > low.z then
                return true
            end
        end
    end
    return false
end

local function Depenetrate(player)
    if not Engine.Collision then return end
    for _ = 1, 4 do
        local position = player.Position
        if Engine.Floor and position.y < Engine.Floor then
            player.Position = V(position.x, Engine.Floor, position.z)
            position = player.Position
        end
        local radius, height = Engine.PlayerRadius, Engine.PlayerHeight
        local minimum = V(position.x - radius, position.y, position.z - radius)
        local maximum = V(position.x + radius, position.y + height, position.z + radius)
        local push = nil
        for _, block in Engine.Blocks do
            if block.CanCollide then
                local low, high = BlockBounds(block)
                if minimum.x < high.x and maximum.x > low.x and minimum.y < high.y and maximum.y > low.y and minimum.z < high.z and maximum.z > low.z then
                    local options = {
                        V(high.x - minimum.x, 0, 0), V(low.x - maximum.x, 0, 0),
                        V(0, high.y - minimum.y, 0), V(0, low.y - maximum.y, 0),
                        V(0, 0, high.z - minimum.z), V(0, 0, low.z - maximum.z),
                    }
                    push = options[1]
                    for _, option in options do
                        if vector.magnitude(option) < vector.magnitude(push) then push = option end
                    end
                    break
                end
            end
        end
        if not push then return end
        player.Position += push
        if push.y > 0 then
            player.Velocity = V(player.Velocity.x, math.max(player.Velocity.y, 0), player.Velocity.z)
        elseif push.y < 0 then
            player.Velocity = V(player.Velocity.x, math.min(player.Velocity.y, 0), player.Velocity.z)
        end
    end
end

local function LowestFreeLift(position, maxLift)
    local low, high = 0, maxLift
    for _ = 1, 6 do
        local middle = (low + high) / 2
        if Collides(position + V(0, middle, 0)) then low = middle else high = middle end
    end
    return high
end

local function MoveAxis(player, delta, bAllowStep)
    local distance = vector.magnitude(delta)
    if distance == 0 then return true end
    local steps = math.ceil(distance / moveSubstep)
    local stepDelta = delta / steps
    for _ = 1, steps do
        local target = player.Position + stepDelta
        if not Collides(target) then
            player.Position = target
        elseif bAllowStep and not Collides(target + V(0, Engine.StepHeight, 0)) and not Collides(player.Position + V(0, Engine.StepHeight, 0)) then
            local lift = LowestFreeLift(target, Engine.StepHeight)
            player.Position = target + V(0, lift, 0)
            stepOffset -= lift
        else
            return false
        end
    end
    return true
end

local function SnapToGround(player)
    local probe = player.Position - V(0, Engine.StepHeight, 0)
    if not Collides(probe) then return false end
    local low, high = 0, Engine.StepHeight
    for _ = 1, 6 do
        local middle = (low + high) / 2
        if Collides(player.Position - V(0, middle, 0)) then high = middle else low = middle end
    end
    player.Position -= V(0, low, 0)
    stepOffset += low
    return true
end

local function WishDirection(yaw)
    local forward, strafe = 0, 0
    if IsDown("W") then forward += 1 end
    if IsDown("S") then forward -= 1 end
    if IsDown("D") then strafe += 1 end
    if IsDown("A") then strafe -= 1 end
    if forward == 0 and strafe == 0 then return vector.zero end
    local cosYaw, sinYaw = math.cos(yaw), math.sin(yaw)
    return vector.normalize(V(cosYaw * forward - sinYaw * strafe, 0, sinYaw * forward + cosYaw * strafe))
end

local function Approach(current, target, rate, dt)
    return current + (target - current) * math.min(1, rate * dt)
end

local function UpdateFlying(player, dt)
    local wish = WishDirection(Engine.Camera.Yaw)
    local rise = 0
    if IsDown("Space") then rise += 1 end
    if IsDown("C") or IsNameDown("ctrl", "control") then rise -= 1 end
    local speed = Engine.FlySpeed * (IsNameDown("shift") and 2 or 1)
    player.Velocity = Approach(player.Velocity, (wish + V(0, rise, 0)) * speed, Engine.GroundAcceleration, dt)
    local move = player.Velocity * dt
    if not MoveAxis(player, V(move.x, 0, 0), false) then player.Velocity = V(0, player.Velocity.y, player.Velocity.z) end
    if not MoveAxis(player, V(0, 0, move.z), false) then player.Velocity = V(player.Velocity.x, player.Velocity.y, 0) end
    if not MoveAxis(player, V(0, move.y, 0), false) then player.Velocity = V(player.Velocity.x, 0, player.Velocity.z) end
    player.OnGround = false
end

local function UpdateWalking(player, dt)
    local bSpaceDown = IsDown("Space")
    if bSpaceDown and not bSpaceHeld then
        jumpBufferTimer = Engine.JumpBuffer
    end
    bSpaceHeld = bSpaceDown
    jumpBufferTimer = math.max(0, jumpBufferTimer - dt)
    coyoteTimer = player.OnGround and Engine.CoyoteTime or math.max(0, coyoteTimer - dt)

    local wish = WishDirection(Engine.Camera.Yaw)
    local speed = IsNameDown("shift") and Engine.SprintSpeed or Engine.WalkSpeed
    local horizontal = V(player.Velocity.x, 0, player.Velocity.z)
    local rate = player.OnGround and Engine.GroundAcceleration or Engine.AirAcceleration
    horizontal = Approach(horizontal, wish * speed, rate, dt)

    local verticalSpeed = player.Velocity.y - Engine.Gravity * dt
    if jumpBufferTimer > 0 and coyoteTimer > 0 then
        verticalSpeed = Engine.JumpPower
        jumpBufferTimer, coyoteTimer = 0, 0
        player.OnGround = false
    end

    local wasOnGround = player.OnGround
    if not MoveAxis(player, V(horizontal.x * dt, 0, 0), wasOnGround) then horizontal = V(0, 0, horizontal.z) end
    if not MoveAxis(player, V(0, 0, horizontal.z * dt), wasOnGround) then horizontal = V(horizontal.x, 0, 0) end
    if not MoveAxis(player, V(0, verticalSpeed * dt, 0), false) then verticalSpeed = 0 end

    player.OnGround = verticalSpeed <= 0 and Collides(player.Position - V(0, groundProbe, 0))
    if not player.OnGround and wasOnGround and verticalSpeed <= 0 and SnapToGround(player) then
        player.OnGround = true
        verticalSpeed = 0
    end
    if player.OnGround then verticalSpeed = math.max(verticalSpeed, 0) end
    player.Velocity = V(horizontal.x, verticalSpeed, horizontal.z)

    local groundSpeed = vector.magnitude(horizontal)
    if player.OnGround and groundSpeed > .3 then
        bobPhase += dt * groundSpeed * 2.4
    end
end

function Engine.Teleport(position)
    Engine.Player.Position = position
    Engine.Player.Velocity = vector.zero
    stepOffset = 0
    table.clear(PreviousCamera)
end

local function UpdateCamera(dt)
    local camera = Engine.Camera
    local turn, pitch = 0, 0
    if IsDown("Q", "Left", "LeftArrow", "ArrowLeft") then turn -= 1 end
    if IsDown("E", "Right", "RightArrow", "ArrowRight") then turn += 1 end
    if IsDown("Up", "UpArrow", "ArrowUp") then pitch += 1 end
    if IsDown("Down", "DownArrow", "ArrowDown") then pitch -= 1 end
    camera.Yaw += turn * Engine.TurnSpeed * dt
    camera.Pitch += pitch * Engine.PitchSpeed * dt

    if Engine.MouseLook and isrbxactive() then
        local mouse = getmouseposition()
        local centerX, centerY = math.floor(viewportWidth / 2), math.floor(viewportHeight / 2)
        if mouseSettleTicks > 0 then
            mouseSettleTicks -= 1
        else
            camera.Yaw += (mouse.x - centerX) * Engine.MouseSensitivity
            camera.Pitch -= (mouse.y - centerY) * Engine.MouseSensitivity
        end
        local backX, backY = math.floor(centerX - mouse.x + .5), math.floor(centerY - mouse.y + .5)
        if backX ~= 0 or backY ~= 0 then
            mousemoverel(backX, backY)
        end
    else
        mouseSettleTicks = 3
    end
    camera.Pitch = math.clamp(camera.Pitch, -maxPitch, maxPitch)

    local turned = math.abs(camera.Yaw - (PreviousCamera.Yaw or camera.Yaw)) + math.abs(camera.Pitch - (PreviousCamera.Pitch or camera.Pitch))
    turnRate = math.max(turned / math.max(dt, 1e-3), turnRate * math.exp(-dt * 4))
    Engine.TurnMargin = math.min(math.rad(50), turnRate * (lastBuildSeconds + 1 / 60) * 1.5)

    local bFlyDown = IsDown("F")
    if bFlyDown and not bFlyHeld then
        Engine.Flying = not Engine.Flying
        Engine.Player.Velocity = vector.zero
    end
    bFlyHeld = bFlyDown

    local player = Engine.Player
    Depenetrate(player)
    if Engine.Flying then
        UpdateFlying(player, dt)
    else
        UpdateWalking(player, dt)
    end

    stepOffset *= math.exp(-dt * 14)
    local bob = 0
    if player.OnGround and not Engine.Flying then
        local groundSpeed = vector.magnitude(V(player.Velocity.x, 0, player.Velocity.z))
        bob = math.sin(bobPhase) * Engine.HeadBob * math.min(1, groundSpeed / Engine.WalkSpeed)
    end
    camera.X, camera.Z = player.Position.x, player.Position.z
    camera.Y = player.Position.y + Engine.EyeHeight + stepOffset + bob
end

local function Update()
    if not Running() then return end
    local now = os.clock()
    local rawDt = now - lastUpdate
    local dt = math.min(rawDt, maxFrameTime)
    lastUpdate = now

    Keys = {}
    if isrbxactive() then
        for _, key in getpressedkeys() do
            Keys[key] = true
        end
    end

    if Keys["L"] then
        if not bToggleHeld then
            Engine.Active = not Engine.Active
        end
        bToggleHeld = true
        lastToggleSeen = now
    elseif now - lastToggleSeen > toggleReleaseTime then
        bToggleHeld = false
    end
    block_roblox_window(Engine.Active and Engine.BlockRobloxInput)
    if not Engine.Active then return end

    viewportWidth, viewportHeight = Camera.ViewportSize.X, Camera.ViewportSize.Y
    local camera = Engine.Camera
    PreviousCamera.X, PreviousCamera.Y, PreviousCamera.Z = camera.X, camera.Y, camera.Z
    PreviousCamera.Yaw, PreviousCamera.Pitch = camera.Yaw, camera.Pitch
    tickStart = now
    tickLength = math.clamp(rawDt, 1 / 240, .1)
    updateCount += 1
    if Engine.Debug and now - lastDebugPrint >= 5 then
        local elapsed = now - lastDebugPrint
        print(string.format("Hellgrid: Render %.1f/s %.2fms avg, draw list %.1f/s %.2fms per build, PreLocal %.1f/s, %d faces, overlay fps %s", renderCount / elapsed, renderCount > 0 and renderTime / renderCount * 1000 or 0, prepareCount / elapsed, prepareCount > 0 and prepareTime / prepareCount * 1000 or 0, updateCount / elapsed, #DrawList, tostring(get_overlay_fps())))
        renderCount, updateCount, lastDebugPrint = 0, 0, now
        renderTime, prepareCount, prepareTime = 0, 0, 0
    end
    UpdateCamera(dt)
    if Engine.OnUpdate then
        Engine.OnUpdate(dt)
    end
end

local View = {}
local scratchCamera = {}

local function ToCamera(point)
    local dx, dy, dz = point.x - View.X, point.y - View.Y, point.z - View.Z
    local right = -dx * View.SinYaw + dz * View.CosYaw
    local ahead = dx * View.CosYaw + dz * View.SinYaw
    return right, dy * View.CosPitch - ahead * View.SinPitch, dy * View.SinPitch + ahead * View.CosPitch
end

local function ClipNear(points, count)
    local near = Engine.NearPlane
    local result = {}
    for index = 1, count do
        local a = points[index]
        local b = points[index % count + 1]
        local aInside, bInside = a[3] >= near, b[3] >= near
        if aInside then result[#result + 1] = a end
        if aInside ~= bInside then
            local t = (near - a[3]) / (b[3] - a[3])
            result[#result + 1] = {a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, near}
        end
    end
    return result
end

local function BlockFaces(block)
    local cache = block.FaceCache
    if cache and cache.Position == block.Position and cache.Size == block.Size and cache.Yaw == block.Yaw and cache.Shape == block.Shape then
        return cache.Faces
    end

    local cosYaw, sinYaw = math.cos(block.Yaw), math.sin(block.Yaw)
    local faces = {}
    for _, template in Shapes[block.Shape] do
        local points = {}
        local center = vector.zero
        for index = 1, #template do
            local scaled = template[index] * block.Size
            local world = V(scaled.x * cosYaw - scaled.z * sinYaw, scaled.y, scaled.x * sinYaw + scaled.z * cosYaw) + block.Position
            points[index] = world
            center += world
        end
        center /= #points
        local radius = 0
        for _, point in points do
            radius = math.max(radius, vector.magnitude(point - center))
        end
        faces[#faces + 1] = {
            Name = template.Name,
            Points = points,
            Center = center,
            Radius = radius,
            Normal = vector.normalize(vector.cross(points[2] - points[1], points[3] - points[1])),
        }
    end
    block.FaceCache = {Position = block.Position, Size = block.Size, Yaw = block.Yaw, Shape = block.Shape, Faces = faces}
    return faces
end

local function PrepareFrame()
    local buildStart = os.clock()
    local sliceStart = buildStart
    local camera = Engine.Camera
    local cameraPosition = V(camera.X, camera.Y, camera.Z)
    local cosYaw, sinYaw = math.cos(camera.Yaw), math.sin(camera.Yaw)
    local cosPitch, sinPitch = math.cos(camera.Pitch), math.sin(camera.Pitch)
    local halfFov = camera.Fov / 2
    local margin = cullMargin + Engine.TurnMargin
    local tanX = math.tan(math.min(halfFov + margin, math.rad(89)))
    local tanY = math.tan(math.min(math.atan(math.tan(halfFov) * viewportHeight / viewportWidth) + margin, math.rad(89)))
    local near = Engine.NearPlane
    local blocks = table.clone(Engine.Blocks)
    local ground = {}
    local groups = {}

    for index, block in blocks do
        if index % 64 == 0 and os.clock() - sliceStart >= Engine.BuildBudget then
            prepareTime += os.clock() - sliceStart
            task.wait()
            if not Running() then return end
            sliceStart = os.clock()
        end
        if block.Visible then
            local isPlane = block.Shape == "Plane"
            local hidden = block.HiddenFaces
            local items = {}
            for _, face in BlockFaces(block) do
                if not (hidden and face.Name and hidden[face.Name]) then
                    local toCamera = cameraPosition - face.Center
                    local facing = vector.dot(face.Normal, toCamera)
                    local inView = false
                    if facing > 0 or isPlane then
                        local dx, dy, dz = -toCamera.x, -toCamera.y, -toCamera.z
                        local ahead = dx * cosYaw + dz * sinYaw
                        local reach = dy * sinPitch + ahead * cosPitch + face.Radius
                        inView = reach > near
                            and math.abs(-dx * sinYaw + dz * cosYaw) - face.Radius <= reach * tanX
                            and math.abs(dy * cosPitch - ahead * sinPitch) - face.Radius <= reach * tanY
                    end
                    local depth = inView and vector.magnitude(toCamera) or 0
                    local amount = 0
                    if inView and Engine.FogColor and not block.NoFog then
                        amount = math.clamp(depth / Engine.FogDistance, 0, 1)
                    end
                    if inView and amount < .97 then
                        if face.LightDirection ~= Engine.LightDirection or face.LightAmbient ~= Engine.Ambient then
                            face.LightDirection, face.LightAmbient = Engine.LightDirection, Engine.Ambient
                            face.Light = Engine.Ambient + (1 - Engine.Ambient) * math.max(0, vector.dot(face.Normal, Engine.LightDirection))
                            face.BackLight = Engine.Ambient + (1 - Engine.Ambient) * math.max(0, vector.dot(-face.Normal, Engine.LightDirection))
                        end
                        local light = block.Unlit and 1 or (facing < 0 and face.BackLight or face.Light)
                        local color = block.FaceColors and face.Name and block.FaceColors[face.Name] or block.Color
                        local bOutline = not isPlane and depth <= Engine.OutlineDistance
                        local fill, outline
                        if Engine.FogColor then
                            fill = CachedColor(color, light, amount)
                            outline = bOutline and CachedColor(color, light * .45, amount) or nil
                        else
                            local shade = light * (block.NoFog and 1 or math.clamp(1 - depth / Engine.FogDistance, .1, 1))
                            fill = CachedColor(color, shade, 0)
                            outline = bOutline and CachedColor(color, shade * .45, 0) or nil
                        end
                        local item = {Points = face.Points, Color = fill, Outline = outline}
                        if isPlane then
                            ground[#ground + 1] = item
                        else
                            items[#items + 1] = item
                        end
                    end
                end
            end
            if #items > 0 then
                local half = block.Size / 2
                local nearest = vector.clamp(cameraPosition, block.Position - half, block.Position + half)
                groups[#groups + 1] = {Depth = vector.magnitude(cameraPosition - nearest) - (block.DepthBias or 0), Items = items}
            end
        end
    end

    table.sort(groups, function(a, b) return a.Depth > b.Depth end)
    for _, group in groups do
        for _, item in group.Items do
            ground[#ground + 1] = item
        end
    end
    DrawList = ground
    prepareTime += os.clock() - sliceStart
    prepareCount += 1
    lastBuildSeconds = os.clock() - buildStart
end

local function Project(point)
    local dx, dy, dz = point.x - View.X, point.y - View.Y, point.z - View.Z
    local ahead = dx * View.CosYaw + dz * View.SinYaw
    local depth = dy * View.SinPitch + ahead * View.CosPitch
    local scale = View.Focal / depth
    return View.HalfWidth + (-dx * View.SinYaw + dz * View.CosYaw) * scale, View.HalfHeight - (dy * View.CosPitch - ahead * View.SinPitch) * scale, depth
end

local function DrawItem(item)
    local near = Engine.NearPlane
    local points = item.Points
    local count = #points

    if count == 4 then
        local x1, y1, z1 = Project(points[1])
        local x2, y2, z2 = Project(points[2])
        local x3, y3, z3 = Project(points[3])
        local x4, y4, z4 = Project(points[4])
        if z1 >= near and z2 >= near and z3 >= near and z4 >= near then
            if math.max(x1, x2, x3, x4) < 0 or math.min(x1, x2, x3, x4) > viewportWidth or math.max(y1, y2, y3, y4) < 0 or math.min(y1, y2, y3, y4) > viewportHeight then return end
            local a, b, c, d = vector.create(x1, y1, 0), vector.create(x2, y2, 0), vector.create(x3, y3, 0), vector.create(x4, y4, 0)
            DrawingImmediate.FilledQuad(a, b, c, d, item.Color, 1)
            if Engine.Outlines and item.Outline then
                DrawingImmediate.Quad(a, b, c, d, item.Outline, .8, 1)
            end
            return
        end
    end

    local cameraPoints = scratchCamera
    local bClip = false
    for index = 1, count do
        local slot = cameraPoints[index]
        if not slot then
            slot = {0, 0, 0}
            cameraPoints[index] = slot
        end
        local cx, cy, cz = ToCamera(points[index])
        slot[1], slot[2], slot[3] = cx, cy, cz
        if cz < near then bClip = true end
    end
    if bClip then
        cameraPoints = ClipNear(cameraPoints, count)
        count = #cameraPoints
        if count < 3 then return end
    end

    local screen = table.create(count + 1)
    local left, right, top, bottom = math.huge, -math.huge, math.huge, -math.huge
    for index = 1, count do
        local point = cameraPoints[index]
        local sx = View.HalfWidth + point[1] / point[3] * View.Focal
        local sy = View.HalfHeight - point[2] / point[3] * View.Focal
        screen[index] = vector.create(sx, sy, 0)
        left, right = math.min(left, sx), math.max(right, sx)
        top, bottom = math.min(top, sy), math.max(bottom, sy)
    end
    if right < 0 or left > viewportWidth or bottom < 0 or top > viewportHeight then return end

    if #screen == 4 then
        DrawingImmediate.FilledQuad(screen[1], screen[2], screen[3], screen[4], item.Color, 1)
    else
        for index = 2, #screen - 1 do
            DrawingImmediate.FilledTriangle(screen[1], screen[index], screen[index + 1], item.Color, 1)
        end
    end
    if Engine.Outlines and item.Outline then
        screen[#screen + 1] = screen[1]
        DrawingImmediate.Polyline(screen, item.Outline, .8, 1)
    end
end

local function DrawBackground()
    local horizon = math.clamp(View.HalfHeight + math.tan(View.Pitch) * View.Focal, 0, viewportHeight)
    if not Engine.GroundColor then
        DrawingImmediate.FilledRectangle(Vector2.new(0, 0), Vector2.new(viewportWidth, viewportHeight), Rgb(Engine.SkyColor, 1), 1, 0)
        return
    end
    DrawingImmediate.FilledRectangle(Vector2.new(0, 0), Vector2.new(viewportWidth, horizon), Rgb(Engine.SkyColor, 1), 1, 0)
    local groundHeight = viewportHeight - horizon
    if groundHeight <= 0 then return end
    for band = 0, groundBands - 1 do
        DrawingImmediate.FilledRectangle(Vector2.new(0, horizon + band * groundHeight / groundBands), Vector2.new(viewportWidth, groundHeight / groundBands + 1), Rgb(Engine.GroundColor, .25 + band / groundBands * .55), 1, 0)
    end
end

local function Render()
    if not Running() or not Engine.Active then return end
    local started = os.clock()
    renderCount += 1
    local camera = Engine.Camera
    local alpha = math.clamp((os.clock() - tickStart) / tickLength, 0, 1)
    local function Blend(previous, current)
        if previous == nil then return current end
        return previous + (current - previous) * alpha
    end

    View.X, View.Y, View.Z = Blend(PreviousCamera.X, camera.X), Blend(PreviousCamera.Y, camera.Y), Blend(PreviousCamera.Z, camera.Z)
    local yaw = Blend(PreviousCamera.Yaw, camera.Yaw)
    View.Pitch = Blend(PreviousCamera.Pitch, camera.Pitch)
    View.CosYaw, View.SinYaw = math.cos(yaw), math.sin(yaw)
    View.CosPitch, View.SinPitch = math.cos(View.Pitch), math.sin(View.Pitch)
    View.HalfWidth, View.HalfHeight = viewportWidth / 2, viewportHeight / 2
    View.Focal = View.HalfWidth / math.tan(camera.Fov / 2)

    DrawBackground()
    for _, item in DrawList do
        DrawItem(item)
    end
    renderTime += os.clock() - started
end

RunService.PreLocal:Connect(Update)

task.spawn(function()
    while Running() do
        if Engine.Active then
            PrepareFrame()
        end
        task.wait()
    end
end)
RunService.Render:Connect(Render)

return Engine
