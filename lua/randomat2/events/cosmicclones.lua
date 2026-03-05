local engine = engine
local ents = ents
local ipairs = ipairs
local math = math
local pairs = pairs
local player = player
local table = table
local util = util

local EntsCreate = ents.Create
local EntsFindByClass = ents.FindByClass
local MathRound = math.Round
local PlayerIterator = player.Iterator
local TableInsert = table.insert
local TableRemove = table.remove

util.AddNetworkString("RdmtCosmicCloneDeath")
util.AddNetworkString("RdmtCosmicCloneRespawn")

local EVENT = {}

EVENT.Title = "Cosmic Clones"
EVENT.id = "cosmicclones"
EVENT.Description = "Shadowy duplicates follow every living player, killing anyone they touch"
EVENT.Categories = {"biased_traitor", "moderateimpact"}

CreateConVar("randomat_cosmicclones_delay", 5, FCVAR_NONE, "How long (in seconds) the delay should be between a user moving and their clone doing the same movement", 1, 60)

local tickRate
local moveStart = {}
local moveLast = {}

local function CreateClone(ply, pos, ang, delay)
    local clone = EntsCreate("ttt_randomat_cosmicclones_clone")
    clone:SetPos(pos)
    clone:SetAngles(ang)
    clone:SetModel(ply:GetModel())
    clone:SetSkin(ply:GetSkin())
    for _, value in pairs(ply:GetBodyGroups()) do
        clone:SetBodygroup(value.id, ply:GetBodygroup(value.id))
    end
    clone:SetCloneOf(ply:SteamID64())
    clone:SetDelay(delay)
    clone:Spawn()
    clone:Activate()

    return clone
end

local function OnPlayerDeath(ply)
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

    net.Start("RdmtCosmicCloneDeath")
        net.WritePlayer(ply)
    net.Broadcast()
end

function EVENT:Begin()
    local delay = GetConVar("randomat_cosmicclones_delay"):GetInt()
    local count = GetConVar("randomat_cosmicclones_count"):GetInt()
    tickRate = MathRound(engine.TickInterval(), 3)
    moveStart = {}
    moveLast = {}

    self:AddHook("PostPlayerDeath", OnPlayerDeath)
    self:AddHook("PlayerDisconnected", OnPlayerDeath)
    self:AddHook("PlayerSpawn", function(ply, transition)
        -- Wait a frame for roles that get moved immediately after spawning
        timer.Simple(0, function()
            if not IsPlayer(ply) then return end
            net.Start("RdmtCosmicCloneRespawn")
                net.WriteString(ply:SteamID64())
                net.WriteVector(ply:GetPos())
            net.Broadcast()
        end)
    end)

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

            if not ply:Alive() or ply:IsSpec() then continue end

            if moveLast[sid64] then
                local diff = MathRound(curTime - moveLast[sid64], 3)
                if diff < tickRate then continue end
            end

            moveLast[sid64] = curTime

            local mvData = {
                pos = ply:GetPos(),
                ang = ply:GetAngles(),
                time = curTime
            }

            local activeWep = ply:GetActiveWeapon()
            if IsValid(activeWep) and activeWep ~= NULL then
                mvData.wep = activeWep.WorldModel
            end

            -- Start waiting to create the clone
            if not moveStart[sid64] then
                moveStart[sid64] = {
                    count = count,
                    pos = ply:GetPos(),
                    ang = ply:GetAngles(),
                    moves = {
                        [1] = mvData
                    }
                }

                timer.Create("RdmtCosmicCloneCreate_" .. sid64, delay, count, function()
                    if not IsValid(ply) then return end

                    -- Create the clone and pass any move history that we have
                    -- Each successive clone should get another stack of delay
                    -- We track this by comparing how many clones we've created
                    -- versus the total, and adding 1 to make the baseline 1x
                    -- For 2 clones, the 1st clone would be:
                    --    delayMult = 1 + (2 - 2) = 1
                    -- And the second clone would be
                    --    delayMult = 1 + (2 - 1) = 2
                    local delayMult = 1 + (count - moveStart[sid64].count)
                    local clone = CreateClone(ply, moveStart[sid64].pos, moveStart[sid64].ang, delay * delayMult)
                    for _, d in ipairs(moveStart[sid64].moves) do
                        clone:AddMoveData(d)
                    end

                    moveStart[sid64].count = moveStart[sid64].count - 1

                    if not ply.RdmtCosmicClones then
                        ply.RdmtCosmicClones = {}
                    end
                    TableInsert(ply.RdmtCosmicClones, clone)
                end)
            else
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

    moveStart = {}
    moveLast = {}
end

function EVENT:Condition()
    return navmesh.IsLoaded() and navmesh.GetNavAreaCount() > 0
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"count", "delay"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
            })
        end
    end
    return sliders
end

Randomat:register(EVENT)