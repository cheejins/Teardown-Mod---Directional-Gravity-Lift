--=========================================================================================================
-- Gravity Lift 1.0 - By: Cheejins
--=========================================================================================================

-- Halo 3
    -- center pull in

-- Ideas
    -- gravlift chain
    -- draw wireframe for setup
    -- sprite lerp animations rings

-- Implementation
    --X player area detection, needs to account for angles
    -- add vector velocity instead of setting it to a new one

-- User options
    -- pull in or edge
    -- add velocity direction to object direction
    -- set velocity direction to gravlift direction
    -- ignore: players, vehicles

--=========================================================================================================
-- "gv" refers to gravlift.
-----------------------------------------------------------------------------------------------------------

local gravliftObjectList = {}
local gravliftBodyList = nil
local gv_sounds = {
    gv_in = LoadSound("MOD/sounds/gv_in.ogg"),
    gv_loop = LoadLoop("MOD/sounds/gv_loop.ogg"),
}
local chainedGravlifts = {}


function init()

    gravliftBodyList = FindBodies("gravlift", true) -- find xml gravlift bodies
    for i=1, #gravliftBodyList do -- put them in a list
        gravliftObjectList[i] = buildDefaultGravliftObject(gravliftBodyList[i]) -- build each gravlift
    end

end

function tick()

    for i=1, #gravliftObjectList do -- run every gravlift each frame
        -- run selected gv
        runGravlift(gravliftObjectList[i])
        drawGravliftOutline(gravliftObjectList[i])
        DebugWatch("Gravlifts: ", i)
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

    -- get gv xml values
    -- HasTag(body, "gravlift")

    local _gv = {}
    -- object
    _gv.body = body
    _gv.transform = GetBodyTransform(_gv.body) -- used for setup only, use methods to get updated values.
    _gv.shapesList = nil
    -- dimensions
    _gv.length = GetTagValue(body, "length")
    -- _gv.length = 10
    _gv.radius = 1.5
    _gv.startPos = _gv.transform.pos
    _gv.endPos = TransformToParentPoint(_gv.transform, Vec(0,0,-_gv.length))
    -- physics
    -- _gv.velocity = GetTagValue(body, "velocity")
    _gv.velocity = 20
    _gv.direction = VecNormalize(VecSub(_gv.startPos, _gv.endPos))
    -- player
    _gv.objectIsInBounds = false
    _gv.objectJustEnteredBounds = false
    --animation
    _gv.animationTimerDefault = 1

    DebugPrint(_gv.radius)

    -- Big thanks to "Thomasims" for this function.
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
    
    --- Moves the player 0.3 voxel up to make SetPlayerVelocity() work
    _gv.playerbumpUp = function()
        local bumpUpTransform = Transform(
            VecAdd(GetPlayerPos(), Vec(0, 0.3, 0)), 
            GetCameraTransform().rot)
            SetPlayerTransform(bumpUpTransform)
            SetCameraTransform(bumpUpTransform)
        end

    return _gv
end


function getShapesList(gv)
    -- center of gv line
    local r = gv.radius
    local gvCenter = VecLerp(gv.startPos, gv.endPos, 0.5) -- center point of gv line
    local dist = CalcDistance(gv.startPos, gvCenter)

    local aabbStart = VecAdd(gvCenter, Vec(-dist-r, -dist-r, -dist-r)) -- aabb start corner vec
    local aabbEnd = VecAdd(gvCenter, Vec(dist+r, dist+r, dist+r)) -- aabb end corner vec
    local shapesList = QueryAabbShapes(aabbStart, aabbEnd)

    if db.onL then DebugLine(aabbStart, aabbEnd, 0,0,1) end -- aabb line

    return shapesList
end


function runGravlift(gv)
    local shapesList = getShapesList(gv)
    local player = GetPlayerTransform()

    for i=1, #shapesList do
        local shape = shapesList[i]
        local shapeTransform = GetShapeWorldTransform(shape)
        if withinCylinder(gv.startPos, gv.endPos, gv.radius, shapeTransform.pos) then
            SetBodyVelocity(GetShapeBody(shape), gv.getDirectionalVelocity()) -- directional velocity
            PlayLoop(gv_sounds.gv_loop, gv.startPos, 0.3)
            DebugWatch("Shapes in area: ", i .. " - " .. GetTime())
        end
    end

    if GetBool("game.player.usevehicle") == false then
        if withinCylinder(gv.startPos, gv.endPos, gv.radius, player.pos) then
            if gv.playerjustEnteredBounds == false then 
                gv.playerbumpUp()
                gv.playerjustEnteredBounds = true -- trigger for player bump up
                PlaySound(gv_sounds.gv_in)
            end

            -- center pull in
            if gv.centerPulledIn == false then

            else
                -- gv normal velocity
                SetPlayerVelocity(gv.getDirectionalVelocity())
                PlayLoop(gv_sounds.gv_loop, GetPlayerPos(), 0.3)
                DebugWatch("Player in area: ", GetTime())
            end
        else
            gv.playerIsInBounds = false
            gv.playerjustEnteredBounds = false
        end
    end

end


function gravliftAnimation()
end


--- Draws a wireframe of the gravlift bounds cylinder
function drawGravliftOutline(gv)

    local radius = gv.radius + 1
    local outerRadius = {
        left    =  TransformToParentPoint(gv.getBaseTransform(), Vec(0,radius,0)),
        right   =  TransformToParentPoint(gv.getBaseTransform(), Vec(radius,0,0)),
        top     =  TransformToParentPoint(gv.getBaseTransform(), Vec(-radius,0,0)),
        bottom  =  TransformToParentPoint(gv.getBaseTransform(), Vec(0,-radius,0)),
    }
    local outerRadiusEnd = {
        left    =  TransformToParentPoint(gv.getBaseTransform(), Vec(0,radius,-gv.length)),
        right   =  TransformToParentPoint(gv.getBaseTransform(), Vec(radius,0,-gv.length)),
        top     =  TransformToParentPoint(gv.getBaseTransform(), Vec(-radius,0,-gv.length)),
        bottom  =  TransformToParentPoint(gv.getBaseTransform(), Vec(0,-radius,-gv.length)),
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


    -- Big thanks to "Thomasims" for this block of code that helps get the outline of the cylinder.
        -- local tr = Transform(gv.startPos, QuatLookAt(gv.startPos, gv.endPos)) -- you might have to change this rotation
            -- for i = 0, 360, 10 do
            -- local ang = math.rad(i)
            -- local lpos = Vector(math.cos(ang), 0, math.sin(ang))
            -- local gpos = TransformToParentPoint(tr, lpos)
            -- DebugLine(gpos, tr.pos)
        -- end


    -- start circle and distance lines
    local tr_s = Transform(gv.startPos, QuatLookAt(gv.startPos, gv.endPos)) -- you might have to change this rotation
    for i = 0, 360, 24 do
        -- start to outer points
        local ang = math.rad(i)
        local lpos = VecScale(Vec(math.cos(ang),math.sin(ang), 0), gv.radius)
        local gpos = TransformToParentPoint(tr_s, lpos)
        DebugLine(gpos, tr_s.pos)

        -- outer points to end outer points
        local tr_g = Transform(gpos, tr_s.rot)
        local endPoint = TransformToParentPoint(tr_g, Vec(0,0,-gv.length))
        DebugLine(gpos, endPoint)
    end
    -- end circle and direction arrow
    local tr = Transform(gv.endPos, QuatLookAt(gv.endPos, gv.startPos)) -- you might have to change this rotation
    for i = 0, 360, 24 do
        local ang = math.rad(i)
        -- local lpos = Vec(math.cos(ang), 0, math.sin(ang))
        local lpos = VecScale(Vec(math.cos(ang),math.sin(ang), 0), gv.radius)
        -- local lpos = Vec(0, math.cos(ang), math.sin(ang))
        local gpos = TransformToParentPoint(tr, lpos)

        DebugLine(gpos, tr.pos) -- end circle
        DebugLine(gpos, TransformToParentPoint(tr, Vec(0,0,2)),0,0,0) -- direction arrow
    end
    
end


--[[UTILITY FUNCTIONS]]
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