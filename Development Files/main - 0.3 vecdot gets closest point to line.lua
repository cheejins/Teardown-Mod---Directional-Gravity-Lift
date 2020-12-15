-- Gravlift

-- Halo 3
    -- center pull in

-- Ideas
    -- gravlift chain
    -- draw wireframe

-- Implementation
    -- player area detection, needs to account for angles.

local colors = {
    yellow  = Vec(1,1,0.5),
    red     = Vec(1,0.5,0.5),
    green   = Vec(0.5,1,0.5),
    blue    = Vec(0.5,0.5,1),
    white   = Vec(1,1,1),
    black   = Vec(0,0,0),
}
local db = {}
db.l = function(vec1, vec2, color, a)
    DebugLine(vec1, vec2, color[1] or 255, color[2] or 255, color[3] or 255, a or 1)
end


local _gv = {}

    -- object
    _gv.body = FindBody("gravlift", true)
    _gv.transform = GetBodyTransform(_gv.body) -- used for setup only, use methods to get updated values.

    -- dimensions
    _gv.radius = 1
    _gv.distance = 10
    _gv.startPos = _gv.transform.pos
    _gv.endPos = TransformToParentPoint(_gv.transform, Vec(0,_gv.distance,0))

    -- physics
    _gv.velocity = 10
    _gv.direction = VecNormalize(VecSub(_gv.startPos, _gv.endPos))

    -- player
    _gv.playerIsInBounds = false
    _gv.playerjustEnteredBounds = false


    -- Returns the gravlift's transform. Can return with added vectors to pos and rot.
    _gv.getBaseTransform = function(addPos, addRot)
        
        local pos = VecAdd(GetBodyTransform(_gv.body).pos, addPos or Vec(0,0,0))
        -- local rot = VecAdd(GetBodyTransform(_gv.body).rot, addRot or Vec(0,0,0))
        local rot = QuatLookAt(_gv.startPos, _gv.endPos)

        return Transform(pos, rot)
    end

    --- Moves player off of the ground by 1 vox. Needed to make SetPlayerVelocity() work.
    _gv.playerbumpUp = function()
        local bumpUpTransform = Transform(
            VecAdd(GetPlayerPos(), Vec(0, 0.2, 0)), 
            GetCameraTransform().rot)

            SetPlayerTransform(bumpUpTransform)
            SetCameraTransform(bumpUpTransform)
        end

    --- Returns the push direction of the gravlift
    _gv.getDirection = function()
        -- return VecScale(VecNormalize(VecSub(_gv.startPos, _gv.endPos)), Vec(0,0,_gv.distance))
        return VecSub(_gv.endPos,_gv.startPos)
    end

    _gv.centerPosPlayerHeight = function()
        -- return VecAdd(_gv.startPos, TransformToParentPoint(_gv.getBaseTransform(), _gv.direction))
        return 
    end


    
function runGravlift(gv)

    local dir = VecNormalize(VecSub(_gv.startPos, _gv.endPos))
    local distToStart = VecSub(GetPlayerPos(), _gv.startPos)
    local result = VecAdd(VecScale(dir, VecDot(dir, distToStart)), _gv.startPos)



    db.l(gv.startPos, TransformToParentPoint(gv.getBaseTransform(), Vec(1,0,0)), colors.yellow)
    db.l(gv.startPos, TransformToParentPoint(gv.getBaseTransform(), Vec(-1,0,0)), colors.yellow)
    db.l(gv.startPos, TransformToParentPoint(gv.getBaseTransform(), Vec(0,1,0)), colors.red)
    db.l(gv.startPos, TransformToParentPoint(gv.getBaseTransform(), Vec(0,-1,0)), colors.yellow)

    db.l(gv.startPos, gv.endPos, colors.green)
    db.l(gv.startPos, GetPlayerPos(), colors.white)
    
    db.l(result, GetPlayerPos(), colors.blue)

end



-- function runGravlift(gv)

--     if CalcDistance(gv.centerPosPlayerHeight(), GetPlayerPos()) < gv.radius then -- check if the player xyz is in the bounds of the gravlift.
    
--     -- if 


--         gv.playerIsInBounds = true -- true while player is in gv bounds

--         if gv.playerIsInBounds -- player is in the xy bounds
--         and (gv.startPos[2] + GetPlayerPos()[2]) < gv.endPos[2] then -- player is in the y bounds

--             if gv.playerjustEnteredBounds == false then 
--                 gv.playerjustEnteredBounds = true -- trigger for player bump up
--                 gv.playerbumpUp() -- move the player 0.1 voxel up to make SetVelocity() work
--             end

--             -- SetPlayerVelocity(Vec(0, 10, 0)) -- updaward velocity now works
--             -- local gvdirection = VecSub()
--             SetPlayerVelocity(_gv.getDirection()) -- updaward velocity now works

--         end
--     else -- player is not in bounds, reset bounds values
--         gv.playerIsInBounds = false
--         gv.playerjustEnteredBounds = false
--     end

--     DebugLine(gv.endPos, gv.startPos, 0.5,1,0.5)
--     -- DebugLine(gv.getBaseTransform().pos, TransformToParentPoint(gv.getBaseTransform(), Vec(0,0,-10)), 0.5,1,0.5)


--     -- local outerPosStart = TransformToParentPoint(gv.getBaseTransform, Vec(5,0,0))
--     -- local outerPosEnd = TransformToParentPoint(gv.getBaseTransform, Vec(5,0,gv.distance))


--     -- DebugLine(outerPosStart, outerPosEnd, 0.5,1,0.5)
-- end


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
