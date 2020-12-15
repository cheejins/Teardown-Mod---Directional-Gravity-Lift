-- Gravlift


local _gv = {}
    -- object
    _gv.body = FindBody("gravlift", true)
    _gv.transform = GetBodyTransform(_gv.body)
    -- dimensions
    _gv.radius = 1
    _gv.bottom = Vec(5,0,5)
    _gv.top = VecAdd(_gv.bottom, Vec(0,10,0))
    -- player
    _gv.playerIsInBounds = false
    _gv.playerjustEnteredBounds = false
    
    
    -- Returns the gravlift's transform.
    _gv.getTransform = function()
        return GetBodyTransform(_gv.body)
    end
    
    --- set player transform to bump up transform.
    _gv.playerbumpUp = function()
        local bumpUpTransform = Transform(
            VecAdd(GetPlayerPos(), Vec(0, 0.2, 0)), 
            GetCameraTransform().rot)

            SetPlayerTransform(bumpUpTransform)
            SetCameraTransform(bumpUpTransform)
        end
        
    --- Returns the xz position of the gravlift at the player's height. Used for checking if player is between the top and bottom of the gravlift.
    _gv.centerPosPlayerHeight = function()
        return VecAdd(_gv.bottom, Vec(0,GetPlayerPos()[2],0))
    end
        
    
    -- draw wireframe



    
function runGravlift(gv)

    if CalcDistance(gv.centerPosPlayerHeight(), GetPlayerPos()) < gv.radius then -- check if the player xyz is in the bounds of the gravlift.

        gv.playerIsInBounds = true -- true while player is in gv bounds

        if gv.playerIsInBounds -- player is in the xy bounds
        and (gv.bottom[2] + GetPlayerPos()[2]) < gv.top[2] then -- player is in the y bounds

            if gv.playerjustEnteredBounds == false then 
                gv.playerjustEnteredBounds = true -- trigger for player bump up
                gv.playerbumpUp() -- move the player 0.1 voxel up to make SetVelocity() work
            end

            SetPlayerVelocity(Vec(0, 10, 0)) -- updaward velocity now works
        end
    else -- player is not in bounds, reset bounds values
        gv.playerIsInBounds = false
        gv.playerjustEnteredBounds = false
    end

    DebugLine(gv.top, gv.bottom, 0.5,1,0.5)
end


function drawGvOutline()
end


function tick()
    runGravlift(_gv)
end






function CalcDistance(vec1, vec2)
    return VecLength(VecSub(vec1, vec2))
end
function raycastFromTransform(tr)
    local plyTransform = tr
    local fwdPos = TransformToParentPoint(plyTransform, Vec(0, 0, -3000))
    local direction = VecSub(fwdPos, plyTransform.pos)
    local dist = VecLength(direction)
    direction = VecNormalize(direction)
    local hit, dist = QueryRaycast(tr.pos, direction, dist)
    if hit then
        local hitPos = TransformToParentPoint(plyTransform, Vec(0, 0, dist * -1))
        return hitPos
    end
    return TransformToParentPoint(tr, Vec(0, 0, -1000))
end
local debugSounds = {
    beep = LoadSound("warning-beep"),
    buzz = LoadSound("light/spark0"),
    chime = LoadSound("elevator-chime"),
}
function beep(vol) PlaySound(debugSounds.beep, GetPlayerPos(), vol or 0.3) end
function buzz(vol) PlaySound(debugSounds.buzz, GetPlayerPos(), vol or 0.3) end
function chime(vol) PlaySound(debugSounds.chime, GetPlayerPos(), vol or 0.3) end