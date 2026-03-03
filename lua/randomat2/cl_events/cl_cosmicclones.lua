local ents = ents
local ipairs = ipairs
local math = math
local player = player
local table = table

local EntsFindByClass = ents.FindByClass
local MathRound = math.Round
local MathRemap = math.Remap
local PlayerIterator = player.Iterator
local TableInsert = table.insert

local EVENT = {}
EVENT.id = "cosmicclones"

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
                    print(c)
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