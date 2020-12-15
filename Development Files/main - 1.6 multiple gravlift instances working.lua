-- Gravlift

-- Halo 3
    -- center pull in

-- Ideas
    -- gravlift chain
    -- draw wireframe for setup
    -- sprite lerp animations rings

-- Implementation
    -- player area detection, needs to account for angles.
    -- add vector velocity instead of setting it to a new one



local gravlistObjectList = {}
local gravliftBodyList = nil

function init()
    gravliftBodyList = FindBodies("gravlift", true)

    for i=1, #gravliftBodyList do
        gravlistObjectList[i] = buildDefaultGravliftObject(gravliftBodyList[i])
        DebugPrint(i)
    end

end

function tick()
    for i=1, #gravlistObjectList do
        runGravlift(gravlistObjectList[i])
    end
end




--[[DEBUG]]
local db = {
    debugAll = false,
    debugLines = false,
    debugPrint = false,
}
db.l = function(vec1, vec2, color, a)
    if db.debugLines == false or db.all == true then
        DebugLine(vec1, vec2, color[1] or 0.5, color[2] or 0.5, color[3] or 0.5, a or 1)
    end
end
db.p = function(string)
    if db.debugPrints == false or db.all == true then
        db.p(string)
    end
end
local colors = {
    yellow  = Vec(1,1,0.5),
    red     = Vec(1,0.5,0.5),
    green   = Vec(0.5,1,0.5),
    blue    = Vec(0.5,0.5,1),
    white   = Vec(1,1,1),
    black   = Vec(0,0,0),
}
--[[DEBUG CONTROL]]
-- db.all = true   -- comment this line to enable all debugging
-- db.lines = true -- comment this line to enable vector line debugging
-- db.Print = true -- comment this line to enable debug prints



function buildDefaultGravliftObject(body)
    local _gv = {}

    -- object
    _gv.body = body
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


    -- Returns the gravlift's transform. Can return with vector added to pos.
    _gv.getBaseTransform = function(addPos)
            local pos = VecAdd(GetBodyTransform(_gv.body).pos, addPos or Vec(0,0,0))
            local rot = QuatLookAt(_gv.startPos, _gv.endPos)
            return Transform(pos, rot)
        end


    --- Returns the push direction of the gravlift scaled to 
    _gv.getDirectionalVelocity = function()
            return VecScale(VecNormalize(VecSub(_gv.startPos, _gv.endPos)), -_gv.velocity)
        end

        return _gv
end
function runGravlift(gv)

    local list = QueryAabbShapes(gv.startPos, Vec(20, 20, 20))
    for i=1, #list do

        local shape = list[i]
        local shapeTransform = GetShapeWorldTransform(shape)

        if withinCylinder(gv.startPos, gv.endPos, gv.radius, shapeTransform.pos) then
            DebugPrint("Shapes in area: " .. i .. " - " .. GetTime())
            SetBodyVelocity(GetShapeBody(shape), gv.getDirectionalVelocity()) -- directional velocity
        end
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
    db.l(outerRadius.top, outerRadiusEnd.top, colors.red)
    db.l(outerRadius.bottom, outerRadiusEnd.bottom, colors.yellow)
    
    db.l(gv.startPos, outerRadius.left, colors.yellow)
    db.l(gv.startPos, outerRadius.right, colors.yellow)
    db.l(gv.startPos, outerRadius.top, colors.red)
    db.l(gv.startPos, outerRadius.bottom, colors.yellow) -- fwd

    db.l(gv.startPos, gv.endPos, colors.green)
    db.l(gv.startPos, GetPlayerPos(), colors.white)
end
function drawGvOutline(gv)
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
    chime = LoadSound("elevator-chime"),}
function beep(vol) PlaySound(debugSounds.beep, GetPlayerPos(), vol or 0.3) end
function buzz(vol) PlaySound(debugSounds.buzz, GetPlayerPos(), vol or 0.3) end
function chime(vol) PlaySound(debugSounds.chime, GetPlayerPos(), vol or 0.3) end
