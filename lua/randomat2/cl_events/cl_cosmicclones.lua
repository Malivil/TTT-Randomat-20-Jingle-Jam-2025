local ents = ents
local ipairs = ipairs
local math = math
local player = player
local table = table

local EntsFindByClass = ents.FindByClass
local MathRemap = math.Remap
local PlayerIterator = player.Iterator
local TableInsert = table.insert

local EVENT = {}
EVENT.id = "cosmicclones"

local mv_start = {}

local function ClearClones(ply)
    local sid64 = ply:SteamID64()
    mv_start[sid64] = nil
    ply.RdmtCosmicClones = nil
end

function EVENT:Begin()
    self:AddHook("SetupMove", function(ply, mv, cmd)
        if not ply:Alive() or ply:IsSpec() then return end

        local poses = {}
        for i = 0, ply:GetNumPoseParameters() - 1 do
            local poseName = ply:GetPoseParameterName(i)
            local poseMin, poseMax = ply:GetPoseParameterRange(i)
            local poseValue = MathRemap(ply:GetPoseParameter(poseName), 0, 1, poseMin, poseMax)
            TableInsert(poses, {
                name = poseName,
                val = poseValue
            })
        end

        local mvData = {
            time = CurTime(),
            pos = ply:GetPos(),
            ang = ply:GetRenderAngles(),
            seq = ply:GetSequence(),
            cyc = ply:GetCycle(),
            poses = poses
        }

        local sid64 = ply:SteamID64()
        -- This player already has one or more clones, update them
        if mv_start[sid64] == false then
            if ply.RdmtCosmicClones then
                for _, c in ipairs(ply.RdmtCosmicClones) do
                    if not IsValid(c) then continue end
                    c:AddMoveData(mvData)
                end
            else
                TableInsert(mv_start[sid64].moves, mvData)
            end
        -- Start waiting to create the clone
        elseif not mv_start[sid64] then
            mv_start[sid64] = {
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
                for _, d in ipairs(mv_start[sid64].moves) do
                    clone:AddMoveData(d)
                end

                mv_start[sid64] = false

                if not ply.RdmtCosmicClones then
                    ply.RdmtCosmicClones = {}
                end
                TableInsert(ply.RdmtCosmicClones, clone)
            else
                TableInsert(mv_start[sid64].moves, mvData)
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

    mv_start = {}
end

Randomat:register(EVENT)