local ents = ents
local ipairs = ipairs
local math = math
local player = player
local table = table

local EntsFindByClass = ents.FindByClass
local MathRand = math.Rand
local MathRandom = math.random
local MathRound = math.Round
local MathRemap = math.Remap
local PlayerIterator = player.Iterator
local TableInsert = table.insert

local EVENT = {}
EVENT.id = "cosmicclones"

-- This is darker than the player color
local particleRed = Color(65, 0, 0)
local tickRate
local moveStart = {}
local moveLast = {}

local function ClearClones(ply)
    local sid64 = ply:SteamID64()
    moveStart[sid64] = nil
    moveLast[sid64] = nil
    ply.RdmtCosmicClones = nil
end

function EVENT:Begin()
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

    self:AddHook("SetupMove", function(ply, mv, cmd)
        -- TODO: Remove
        if ply:IsBot() then return end
        if not ply:Alive() or ply:IsSpec() then return end

        local curTime = CurTime()
        local sid64 = ply:SteamID64()
        if moveLast[sid64] then
            local diff = MathRound(curTime - moveLast[sid64], 3)
            if diff < tickRate then return end
        end

        moveLast[sid64] = curTime

        local poses = {}
        for i = 0, ply:GetNumPoseParameters() - 1 do
            local poseMin, poseMax = ply:GetPoseParameterRange(i)
            local poseValue = MathRemap(ply:GetPoseParameter(i), 0, 1, poseMin, poseMax)
            poses[i] = poseValue
        end

        local mvData = {
            time = curTime,
            pos = ply:GetPos(),
            ang = ply:GetRenderAngles(),
            seq = ply:GetSequence(),
            cyc = ply:GetCycle(),
            poses = poses
        }

        -- This player already has one or more clones, update them
        if moveStart[sid64] == false then
            if ply.RdmtCosmicClones then
                for _, c in ipairs(ply.RdmtCosmicClones) do
                    if not IsValid(c) then continue end
                    c:AddMoveData(mvData)
                end
            end
        -- Start waiting to create the clone
        elseif not moveStart[sid64] then
            moveStart[sid64] = {
                moves = {
                    [1] = mvData
                }
            }
        -- Keep track of any move data while the clone is being created
        else
            local clone
            for _, e in ipairs(EntsFindByClass("ttt_randomat_cosmicclones_clone")) do
                if e:GetCloneOf() ~= ply:SteamID64() then continue end
                clone = e
                break
            end

            if clone then
                for _, d in ipairs(moveStart[sid64].moves) do
                    clone:AddMoveData(d)
                end

                if moveStart[sid64].SmokeEmitter then
                    moveStart[sid64].SmokeEmitter:Finish()
                    moveStart[sid64].SmokeEmitter = nil
                end
                moveStart[sid64] = false
                moveLast[sid64] = nil

                if not ply.RdmtCosmicClones then
                    ply.RdmtCosmicClones = {}
                end
                TableInsert(ply.RdmtCosmicClones, clone)
            else
                TableInsert(moveStart[sid64].moves, mvData)
            end
        end
    end)

    -- Show smoke where a clone is going to spawn
    self:AddHook("Think", function()
        if not IsPlayer(client) then return end

        local curTime = CurTime()
        local baseVel = Vector(0, 0, 4)
        for sid64, mv in pairs(moveStart) do
            if mv == false then continue end

            local ply = player.GetBySteamID64(sid64)
            if not IsPlayer(ply) then continue end

            local pos = mv.moves[1].pos
            if not mv.SmokeEmitter then mv.SmokeEmitter = ParticleEmitter(pos) end
            if not mv.SmokeNextPart then mv.SmokeNextPart = curTime end
            if mv.SmokeNextPart < curTime and client:GetPos():Distance(pos) <= 3000 then
                mv.SmokeEmitter:SetPos(pos)
                mv.SmokeNextPart = curTime + MathRand(0.003, 0.01)
                local vec = Vector(MathRand(-8, 8), MathRand(-8, 8), MathRand(10, 55))
                local localVec, _ = LocalToWorld(pos, angle_zero, vec, angle_zero)
                local particle = mv.SmokeEmitter:Add("particle/snow.vmt", localVec)
                particle:SetVelocity(baseVel + VectorRand() * 3)
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
    end)

    net.Receive("RdmtCosmicCloneClear", function()
        local ply = net.ReadPlayer()
        if not IsPlayer(ply) then return end
        ClearClones(ply)
    end)
end

function EVENT:End()
    for _, p in PlayerIterator() do
        ClearClones(p)
    end

    moveStart = {}
    moveLast = {}
end

Randomat:register(EVENT)