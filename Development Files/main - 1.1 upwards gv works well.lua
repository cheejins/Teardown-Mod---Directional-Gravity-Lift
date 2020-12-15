-- Gravlift

-- TODO
    -- raycast area
        -- check what's in it
    -- draw lines
    -- 


    local gvRadius = 2
    local gvliftBottom = Vec(5,0,5)
    local gvliftTop = VecAdd(gvliftBottom, Vec(0,10,0))
    local gvPlayer_InArea = false
    local gvPlayer_EnteredArea = false



function tick()

    local gvCenterPosPlayerHeight = VecAdd(gvliftBottom, Vec(0,GetPlayerPos()[2],0))

    if
        -- player xy in gv center
        CalcDistance(gvCenterPosPlayerHeight, GetPlayerPos()) < gvRadius
    then
        gvPlayer_InArea = true -- true while player is in gv area

        if gvPlayer_InArea -- player is in the xy area
        and (gvliftBottom[2] + GetPlayerPos()[2]) < gvliftTop[2] then -- player is in the y area

            if gvPlayer_EnteredArea == false then -- move the player 0.1 voxel up to make SetVelocity() work

                local gvPlayer_bumpUpTransform = Transform( -- bump up transform
                    VecAdd(GetCameraTransform().pos, Vec(0,0.1,0)), 
                    GetCameraTransform().rot)

                SetPlayerTransform(gvPlayer_bumpUpTransform)
                SetCameraTransform(gvPlayer_bumpUpTransform) -- set player transform to bump up transform
                gvPlayer_EnteredArea = true -- trigger for player bump up
            end

            SetPlayerVelocity(Vec(0, 4, 0)) -- updaward velocity now works
        end
    else -- player is not in area, reset area values
        gvPlayer_InArea = false
        gvPlayer_EnteredArea = false
    end

    DebugLine(gvliftTop, gvliftBottom, 0.5,1,0.5)
    -- DebugLine(gvCenterPosPlayerHeight, GetPlayerPos())
    
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
