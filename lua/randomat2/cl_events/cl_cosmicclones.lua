local ents = ents
local ipairs = ipairs
local math = math
local player = player
local table = table

local EntsFindByClass = ents.FindByClass
local EntsCreateClient = ents.CreateClientside
local MathRand = math.Rand
local MathRandom = math.random
local MathRound = math.Round
local MathRemap = math.Remap
local PlayerIterator = player.Iterator
local TableInsert = table.insert
local TableRemove = table.remove

local EVENT = {}
EVENT.id = "cosmicclones"

-- This is darker than the player color
local particleRed = Color(65, 0, 0)
local particleBaseVel = Vector(0, 0, 4)
local tickRate
local moveStart = {}
local moveLast = {}

function EVENT:Begin()
    local count = GetConVar("randomat_cosmicclones_count"):GetInt()
    tickRate = math.Round(engine.TickInterval(), 3)
    moveStart = {}
    moveLast = {}

    local client = LocalPlayer()

    CreateMaterial("RdmtCosmicCloneMaterial", "VertexLitGeneric", {
        ["$basetexture"] = "vgui/white",
        ["$model"] = 1,
        ["$translucent"] = 1,
        ["$vertexalpha"] = 1,
        ["$vertexcolor"] = 1,
        ["$cloakpassenabled"] = 1,
        ["$cloakfactor"] = 0.31,
        ["$cloakcolortint"] = 0
    })

    self:AddHook("Think", function()
        local curTime = CurTime()
        for _, ply in PlayerIterator() do
            if ply:IsBot() then continue end

            local sid64 = ply:SteamID64()
            if moveStart[sid64] then
                -- Trim all move data that has been sent to all of the clones
                for idx=#moveStart[sid64].moves, 1, -1 do
                    if moveStart[sid64].moves[idx].added == count then
                        TableRemove(moveStart[sid64].moves, idx)
                    end
                end
            end

            local mvData
            if not ply.RdmtCosmicCloneDead and ply:Alive() and not ply:IsSpec() then
                if moveLast[sid64] then
                    local diff = MathRound(curTime - moveLast[sid64], 3)
                    if diff < tickRate then continue end
                end

                moveLast[sid64] = curTime

                local poses = {}
                for i = 0, ply:GetNumPoseParameters() - 1 do
                    local poseMin, poseMax = ply:GetPoseParameterRange(i)
                    local poseValue = MathRemap(ply:GetPoseParameter(i), 0, 1, poseMin, poseMax)
                    poses[i] = poseValue
                end

                mvData = {
                    time = curTime,
                    pos = ply:GetPos(),
                    ang = ply:GetRenderAngles(),
                    seq = ply:GetSequence(),
                    cyc = ply:GetCycle(),
                    poses = poses
                }

                local activeWep = ply:GetActiveWeapon()
                if IsValid(activeWep) and activeWep ~= NULL then
                    mvData.wep = activeWep.WorldModel
                end
            end

            -- Start waiting to create the clone
            if not moveStart[sid64] then
                if mvData then
                    moveStart[sid64] = {
                        count = count,
                        moves = {
                            [1] = mvData
                        },
                        spawns = {
                            -- This structure seems overly complicated, but
                            -- each entry will have its own smoke emitter
                            -- added below so an object is necessary here
                            [1] = {
                                pos = mvData.pos
                            }
                        }
                    }
                end
            else
                if mvData then
                    -- This player already has one or more clones, update them
                    if ply.RdmtCosmicClones then
                        for _, c in ipairs(ply.RdmtCosmicClones) do
                            if not IsValid(c) then continue end
                            c:AddMoveData(mvData)
                        end
                    end

                    -- Keep track of any move data while clones are being created
                    if moveStart[sid64].count > 0 then
                        TableInsert(moveStart[sid64].moves, mvData)
                    end
                end
            end
        end

        -- Show smoke where a clone is going to spawn
        if not IsPlayer(client) then return end

        for sid64, mv in pairs(moveStart) do
            if #mv.spawns == 0 then continue end

            local ply = player.GetBySteamID64(sid64)
            if not IsPlayer(ply) then continue end

            for _, spawn in ipairs(mv.spawns) do
                local pos = spawn.pos
                if not spawn.SmokeEmitter then spawn.SmokeEmitter = ParticleEmitter(pos) end
                if not spawn.SmokeNextPart then spawn.SmokeNextPart = curTime end
                if spawn.SmokeNextPart < curTime and client:GetPos():Distance(pos) <= 3000 then
                    spawn.SmokeEmitter:SetPos(pos)
                    spawn.SmokeNextPart = curTime + MathRand(0.003, 0.01)
                    local vec = Vector(MathRand(-8, 8), MathRand(-8, 8), MathRand(10, 55))
                    local localVec, _ = LocalToWorld(pos, angle_zero, vec, angle_zero)
                    local particle = spawn.SmokeEmitter:Add("particle/snow.vmt", localVec)
                    particle:SetVelocity(particleBaseVel + VectorRand() * 3)
                    particle:SetDieTime(MathRand(0.75, 2.25))
                    local size = MathRandom(4, 7)
                    particle:SetStartSize(size)
                    particle:SetEndSize(size + 1)
                    particle:SetRoll(0)
                    particle:SetRollDelta(0)
                    local r, g, b, _ = particleRed:Unpack()
                    particle:SetColor(r, g, b)
                end
            end
        end
    end)

    net.Receive("RdmtCosmicCloneCreate", function()
        local ply = net.ReadPlayer()
        local pos = net.ReadVector()
        local ang = net.ReadAngle()
        local delay = net.ReadFloat()

        local clone = EntsCreateClient("cl_ttt_randomat_cosmicclones_clone")
        clone:SetPos(pos)
        clone:SetAngles(ang)
        clone:SetModel(ply:GetModel())
        clone:SetSkin(ply:GetSkin())
        for _, value in pairs(ply:GetBodyGroups()) do
            clone:SetBodygroup(value.id, ply:GetBodygroup(value.id))
        end
        clone:SetDelay(delay)
        clone:Spawn()
        clone:Activate()

        local sid64 = ply:SteamID64()
        if moveStart[sid64].count > 0 then
            moveStart[sid64].count = moveStart[sid64].count - 1

            clone.RdmtCosmicCloneKnown = true
            clone.RdmtCosmicCloneNum = count - moveStart[sid64].count
            clone.PositionCallback = function(c, p)
                if c.RdmtCosmicCloneNum ~= count then return end
                if not moveStart[sid64] then return end
                if #moveStart[sid64].spawns == 0 then return end
                if not p:IsEqualTol(moveStart[sid64].spawns[1].pos, 25) then return end

                local spawn = TableRemove(moveStart[sid64].spawns, 1)
                if spawn.SmokeEmitter then
                    spawn.SmokeEmitter:Finish()
                end
            end

            for _, d in ipairs(moveStart[sid64].moves) do
                clone:AddMoveData(d)
            end

            if not ply.RdmtCosmicClones then
                ply.RdmtCosmicClones = {}
            end
            TableInsert(ply.RdmtCosmicClones, clone)
        end
    end)

    net.Receive("RdmtCosmicCloneDeath", function()
        local ply = net.ReadPlayer()
        if not IsPlayer(ply) then return end

        ply.RdmtCosmicCloneDead = true

        local sid64 = ply:SteamID64()
        local mvData = {
            time = CurTime(),
            dead = true
        }
        if moveStart[sid64] then
            TableInsert(moveStart[sid64].moves, mvData)
        end

        if ply.RdmtCosmicClones then
            for _, c in ipairs(ply.RdmtCosmicClones) do
                if not IsValid(c) then continue end
                c:AddMoveData(mvData)
            end
        end
    end)

    net.Receive("RdmtCosmicCloneRespawn", function()
        local ply = net.ReadPlayer()
        local pos = net.ReadVector()
        if not IsPlayer(ply) then return end

        ply.RdmtCosmicCloneDead = false

        local sid64 = ply:SteamID64()
        if not moveStart[sid64] then return end
        TableInsert(moveStart[sid64].spawns, { pos = pos })
    end)
end

function EVENT:End()
    for _, e in ipairs(EntsFindByClass("cl_ttt_randomat_cosmicclones_clone")) do
        SafeRemoveEntity(e)
    end

    for _, p in PlayerIterator() do
        p.RdmtCosmicCloneDead = nil
        p.RdmtCosmicClones = nil
    end

    for _, mv in pairs(moveStart) do
        for _, spawn in ipairs(mv.spawns) do
            if spawn.SmokeEmitter then
                spawn.SmokeEmitter:Finish()
            end
        end
    end
    moveStart = {}
    moveLast = {}
end

Randomat:register(EVENT)