local ents = ents
local ipairs = ipairs
local pairs = pairs
local player = player
local table = table

local EntsCreate = ents.Create
local EntsFindByClass = ents.FindByClass
local PlayerIterator = player.Iterator
local TableHasValue = table.HasValue
local TableInsert = table.insert

-- Defined in BaseAnimatingOverlay.h#L132
MAX_OVERLAYS = MAX_OVERLAYS or 15

local EVENT = {}

EVENT.Title = "Cosmic Clones"
EVENT.id = "cosmicclones"

CreateConVar("randomat_cosmicclones_delay", 5, FCVAR_NONE, "How long (in seconds) the delay should be between a user moving and their clone doing the same movement", 1, 60)
CreateConVar("randomat_cosmicclones_rate", 1, FCVAR_NONE, "How often (in seconds) the player's data should be recorded. Lower number is more accurate, but higher compute requirements")

-- Ignore jump_land because the timing doesn't work out
local ignoredSequences = {"jump_land"}

local dark_red = Color(136, 0, 0)
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
    clone.CloneOf = ply
    clone:Spawn()
    clone:Activate()

    return clone
end

local mv_start = {}
local mv_last = {}
function EVENT:Begin()
    local delay = GetConVar("randomat_cosmicclones_delay"):GetInt()
    local rate = GetConVar("randomat_cosmicclones_rate"):GetInt()

    -- The clones are invincible
    self:AddHook("EntityTakeDamage", function(target, dmginfo)
        if not IsValid(target) then return end
        if target:GetClass() == "ttt_randomat_cosmicclones_clone" then
            dmginfo:SetDamage(0)
            return true
        end
    end)

    -- Destroy clones and reset state when a player dies
    -- This means clones will be recreated automatically if
    -- a player is respawned
    self:AddHook("PostPlayerDeath", function(ply)
        if not ply.RdmtCosmicClones then return end

        for _, c in ipairs(ply.RdmtCosmicClones) do
            SafeRemoveEntity(c)
        end
        ply.RdmtCosmicClones = nil

        local sid64 = ply:SteamID64()
        mv_start[sid64] = nil
        timer.Remove("RdmtCosmicCloneCreate_" .. sid64)
    end)

    self:AddHook("SetupMove", function(ply, mv, cmd)
        -- TODO: Remove
        if ply:Nick() ~= "Malivil" then return end
        if not ply:Alive() or ply:IsSpec() then return end

        local curTime = CurTime()
        local sid64 = ply:SteamID64()
        -- Don't update too often
        if mv_last[sid64] and (curTime - mv_last[sid64]) < rate then return end

        local sprinting = cvars.Bool("ttt_sprint_enabled") and ply.GetSprinting and ply:GetSprinting()
        local crouching = ply:Crouching()
        local walking = not sprinting and ply:IsWalking()
        local speed = ply:GetWalkSpeed()
        if walking then
            speed = ply:GetSlowWalkSpeed()
        end
        if crouching then
            speed = speed * ply:GetCrouchedWalkSpeed()
        end
        if sprinting then
            speed = speed * GetSprintMultiplier(ply, true)
        end

        local jumpPower = ply:GetJumpPower()
        if ply.GetExtraJumpPower then
            jumpPower = jumpPower * ply:GetExtraJumpPower()
        end

        local layers = {}
        -- Overlay index starts from 0 up to 15
        for i = 0, MAX_OVERLAYS do
            if not ply:IsValidLayer(i) then continue end

            local seq = ply:GetLayerSequence(i)
            local seqName = ply:GetSequenceName(seq)
            if TableHasValue(ignoredSequences, seqName) then continue end

            TableInsert(layers, {
                id = seq,
                dur = ply:GetLayerDuration(i),
                rate = ply:GetLayerPlaybackRate(i),
                weight = ply:GetLayerWeight(i)
            })
        end

        local mvData = {
            time = curTime,
            pos = ply:GetPos(),
            ang = ply:GetAngles(),
            view = ply:EyeAngles(),
            crouching = crouching,
            walking = walking,
            jumping = mv:KeyWasDown(IN_JUMP) and not ply:OnGround(),
            jumpPower = jumpPower,
            speed = speed,
            seq = layers,
            weapon = {}
        }
        mv_last[sid64] = curTime

        local activeWep = ply:GetActiveWeapon()
        if IsValid(activeWep) and activeWep ~= NULL then
            mvData.weapon.model = activeWep:GetModel()
            mvData.weapon.holdType = activeWep:GetHoldType()
        end

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