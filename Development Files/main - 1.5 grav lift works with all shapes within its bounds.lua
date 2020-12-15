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
    _gv.radius = 3
    _gv.distance = 10
    _gv.startPos = _gv.transform.pos
    _gv.endPos = TransformToParentPoint(_gv.transform, Vec(0,_gv.distance,0))

    -- physics
    _gv.velocity = 25
    _gv.direction = VecNormalize(VecSub(_gv.startPos, _gv.endPos))

    -- player
    _gv.objectIsInBounds = false
    _gv.objectJustEnteredBounds = false


    -- Returns the gravlift's transform. Can return with added vectors to pos and rot.
    _gv.getBaseTransform = function(addPos, addRot)
        local pos = VecAdd(GetBodyTransform(_gv.body).pos, addPos or Vec(0,0,0))
        local rot = QuatLookAt(_gv.startPos, _gv.endPos)
        return Transform(pos, rot)
    end

    --- Moves player off of the ground by 1 vox. Needed to make SetPlayerVelocity() work.
    _gv.objectBumpUp = function()
        local bumpUpTransform = Transform(
            VecAdd(GetPlayerTransform().pos, Vec(0, 0.2, 0)), GetCameraTransform().rot)
            SetPlayerTransform(bumpUpTransform)
            SetCameraTransform(bumpUpTransform)
        end

    --- Returns the push direction of the gravlift scaled to 
    _gv.getDirectionalVelocity = function()
        return VecScale(VecNormalize(VecSub(_gv.startPos, _gv.endPos)), -_gv.velocity)
    end


    -- big thanks to "Thomasims" for this function.
    function withinCylinder(cstart, cend, radius, pos)
        local cdiff = VecSub(cend, cstart)
        local clen = VecLength(cdiff)
        local cdir = VecScale(cdiff, 1 / clen)
        local pdiff = VecSub(pos, cstart)
        local pdot = VecDot(cdir, pdiff)
        if pdot < 0 or pdot > clen then return false end
        return VecLength(VecSub(pdiff, VecScale(cdir, pdot))) < radius
    end

    
function runGravlift(gv)

    -- local hit = QueryRaycast(Vec(0, 100, 0), Vec(0, -1, 0), 100)


    if withinCylinder(gv.startPos, gv.endPos, gv.radius, GetPlayerTransform().pos) then

        gv.objectIsInBounds = true -- true while player is in gv bounds

        if gv.objectIsInBounds then -- player is in the y bounds

            if gv.objectJustEnteredBounds == false then 
                gv.objectJustEnteredBounds = true -- trigger for player bump up
                gv.objectBumpUp() -- move the player 0.1 voxel up to make SetVelocity() work
            end

            SetPlayerVelocity(gv.getDirectionalVelocity())-- updaward velocity now works
        end
    else -- player is not in bounds, reset bounds values
        gv.objectIsInBounds = false
        gv.objectJustEnteredBounds = false
    end

    local outerRadius = {
        left    = TransformToParentPoint(gv.getBaseTransform(), Vec(0,gv.radius,0)),
        right   =  TransformToParentPoint(gv.getBaseTransform(), Vec(gv.radius,0,0)),
        top     =  TransformToParentPoint(gv.getBaseTransform(), Vec(-gv.radius,0,0)),
        bottom  =  TransformToParentPoint(gv.getBaseTransform(), Vec(0,-gv.radius,0)),
    }

    local outerRadiusEnd = {
        left    = TransformToParentPoint(gv.getBaseTransform(), Vec(0,gv.radius,-gv.distance)),
        right   =  TransformToParentPoint(gv.getBaseTransform(), Vec(gv.radius,0,-gv.distance)),
        top     =  TransformToParentPoint(gv.getBaseTransform(), Vec(-gv.radius,0,-gv.distance)),
        bottom  =  TransformToParentPoint(gv.getBaseTransform(), Vec(0,-gv.radius,-gv.distance)),
    }

    db.l(outerRadius.left, outerRadiusEnd.left, colors.yellow)
    db.l(outerRadius.right, outerRadiusEnd.right, colors.yellow)
    db.l(outerRadius.top, outerRadiusEnd.top, colors.yellow)
    db.l(outerRadius.bottom, outerRadiusEnd.bottom, colors.red)
    
    db.l(gv.startPos, outerRadius.left, colors.yellow)
    db.l(gv.startPos, outerRadius.right, colors.yellow)
    db.l(gv.startPos, outerRadius.top, colors.yellow)
    db.l(gv.startPos, outerRadius.bottom, colors.red) -- fwd

    db.l(gv.startPos, gv.endPos, colors.green)
    db.l(gv.startPos, GetPlayerPos(), colors.white)


    -- db.l(result, GetPlayerPos(), colors.blue)
    -- db.l(point1, GetPlayerPos(), colors.black)
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