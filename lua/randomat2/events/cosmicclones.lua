local ents = ents
local ipairs = ipairs
local pairs = pairs
local player = player
local table = table
local util = util

local EntsCreate = ents.Create
local EntsFindByClass = ents.FindByClass
local PlayerIterator = player.Iterator
local TableInsert = table.insert

-- Defined in BaseAnimatingOverlay.h#L132
MAX_OVERLAYS = MAX_OVERLAYS or 15

util.AddNetworkString("RdmtCosmicCloneClear")

local EVENT = {}

EVENT.Title = "Cosmic Clones"
EVENT.id = "cosmicclones"

CreateConVar("randomat_cosmicclones_delay", 5, FCVAR_NONE, "How long (in seconds) the delay should be between a user moving and their clone doing the same movement", 1, 60)

local dark_red = Color(136, 0, 0)
local mv_start = {}

local function CreateClone(ply, pos, ang)
    local clone = EntsCreate("ttt_randomat_cosmicclones_clone")
    clone:SetPos(pos)
    clone:SetAngles(ang)
    clone:SetModel(ply:GetModel())
    clone:SetSkin(ply:GetSkin())
    for _, value in pairs(ply:GetBodyGroups()) do
        clone:SetBodygroup(value.id, ply:GetBodygroup(value.id))
    end
    clone:SetColor(dark_red)
    clone:SetMaterial("models/shiny")
    clone:SetCloneOf(ply:SteamID64())
    clone:Spawn()
    clone:Activate()

    return clone
end

local function ClearClones(ply)
    local sid64 = ply:SteamID64()
    mv_start[sid64] = nil
    timer.Remove("RdmtCosmicCloneCreate_" .. sid64)

    if not ply.RdmtCosmicClones then return end

    for _, c in ipairs(ply.RdmtCosmicClones) do
        SafeRemoveEntity(c)
    end
    ply.RdmtCosmicClones = nil

    net.Start("RdmtCosmicCloneClear")
        net.WritePlayer(ply)
    net.Broadcast()
end

function EVENT:Begin()
    local delay = GetConVar("randomat_cosmicclones_delay"):GetInt()

    -- Destroy clones and reset state when a player dies
    -- or disconnects. This means clones will be recreated
    -- automatically if a player is respawned
    self:AddHook("PostPlayerDeath", ClearClones)
    self:AddHook("PlayerDisconnected", ClearClones)

    self:AddHook("SetupMove", function(ply, mv, cmd)
        if not ply:Alive() or ply:IsSpec() then return end

        local mvData = {
            pos = ply:GetPos(),
            time = CurTime()
        }

        local activeWep = ply:GetActiveWeapon()
        if IsValid(activeWep) and activeWep ~= NULL then
            mvData.wep = activeWep.WorldModel
        end

        local sid64 = ply:SteamID64()
        -- This player already has one or more clones, update them
        if mv_start[sid64] == false then
            if ply.RdmtCosmicClones then
                for _, c in ipairs(ply.RdmtCosmicClones) do
                    c:AddMoveData(mvData)
                end
            else
                TableInsert(mv_start[sid64].moves, mvData)
            end
        -- Start waiting to create the clone
        elseif not mv_start[sid64] then
            mv_start[sid64] = {
                pos = ply:GetPos(),
                ang = ply:GetAngles(),
                moves = {
                    [1] = mvData
                }
            }

            timer.Create("RdmtCosmicCloneCreate_" .. sid64, delay, 1, function()
                if not IsValid(ply) then return end
                local mvStart = mv_start[sid64]

                -- Create the clone and pass any move history that we have
                local clone = CreateClone(ply, mvStart.pos, mvStart.ang)
                for _, d in ipairs(mv_start[sid64].moves) do
                    clone:AddMoveData(d)
                end

                mv_start[sid64] = false

                if not ply.RdmtCosmicClones then
                    ply.RdmtCosmicClones = {}
                end
                TableInsert(ply.RdmtCosmicClones, clone)
            end)
        -- Keep track of any move data while the clone is being created
        else
            TableInsert(mv_start[sid64].moves, mvData)
        end
    end)
end

function EVENT:End()
    for _, e in ipairs(EntsFindByClass("ttt_randomat_cosmicclones_clone")) do
        SafeRemoveEntity(e)
    end

    for _, p in PlayerIterator() do
        timer.Remove("RdmtCosmicCloneCreate_" .. p:SteamID64())
        p.RdmtCosmicClones = nil
    end

    mv_start = {}
end

function EVENT:Condition()
    return navmesh.IsLoaded() and navmesh.GetNavAreaCount() > 0
end

Randomat:register(EVENT)