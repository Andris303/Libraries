local RobloxVersion = _G.RobloxVersion or "version-c5aecda2245e4fae"
local O = crypt.json.decode(game:HttpGet("https://offsets.imtheo.lol/" .. RobloxVersion .. "/offsets.json")).Offsets

local ACTIVE_ANIMATIONS = O.Animator.ActiveAnimations
local TRACK_ANIMATION = O.AnimationTrack.Animation
local TRACK_ANIMATOR = O.AnimationTrack.Animator
local ANIMATION_ID = O.Misc.AnimationId

local function GetAnimTracks(animator)
    local tracks = {}
    local animatorPtr = tonumber(animator.Data)
    local head = memory.readu64(animator, ACTIVE_ANIMATIONS)
    local count = memory.readu64(animator, ACTIVE_ANIMATIONS + 0x8)

    if not head or head == 0 or not count or count == 0 then return tracks end
    local node = memory.readu64(head)

    for _ = 1, count do
        if not node or node == 0 or node == head then break end
        local track = memory.readu64(node + 0x10)
        if track and track > 0x100000000 then
            local s, trackAnimator = pcall(function()
                return memory.readu64(track + TRACK_ANIMATOR)
            end)
            if s and trackAnimator == animatorPtr then
                tracks[#tracks + 1] = track
            end
        end

        node = memory.readu64(node)
    end

    return tracks
end

Instance.declare({
    class = "Animator",
    name = "ActiveAnimations",

    callback = {
        get = function(self)
            return GetAnimTracks(self)
        end,
    }
})


Instance.declare({
    class = "Animator",
    name = "AnimationIds",

    callback = {
        get = function(self)
            return memory.readstring(self, ANIMATION_ID)
        end,
    }
})

return O
