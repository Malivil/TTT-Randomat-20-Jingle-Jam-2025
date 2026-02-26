local ents = ents
local ipairs = ipairs
local pairs = pairs
local player = player
local table = table

local EntsCreate = ents.Create
local EntsFindByClass = ents.FindByClass
local PlayerIterator = player.Iterator
local TableInsert = table.insert

local EVENT = {}

EVENT.Title = "Cosmic Clones"
EVENT.id = "cosmicclones"

CreateConVar("randomat_cosmicclones_delay", 5, FCVAR_NONE, "How long the delay should be between a user moving and their clone doing the same movement", 1, 60)

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
function EVENT:Begin()
    local delay = GetConVar("randomat_cosmicclones_delay"):GetInt()

    -- The clones are invincible
    self:AddHook("EntityTakeDamage", function(target, dmginfo)
        if not IsValid(target) then return end
        if target:GetClass() == "ttt_randomat_cosmicclones_clone" then
            dmginfo:SetDamage(0)
            return true
        end
    end)

    self:AddHook("SetupMove", function(ply, mv, cmd)
        local curTime = CurTime()
        local sid64 = ply:SteamID64()

        local speed = ply:GetWalkSpeed()
        if ply:IsWalking() then
            speed = ply:GetSlowWalkSpeed()
        end
        if ply:Crouching() then
            speed = speed * ply:GetCrouchedWalkSpeed()
        end

        -- TODO: What else do we need from this?
        -- TODO: Jumping?
        local mvData = {
            pos = ply:GetPos(),
            ang = ply:GetAngles(),
            crouching = ply:Crouching(),
            walking = ply:IsWalking(),
            speed = speed,
            weapon = {}
            --view = cmd:GetViewAngles(),
            --btns = mv:GetButtons(),
            --mvAng = mv:GetMoveAngles(),
            --fwd = mv:GetForwardSpeed(),
            --side = mv:GetSideSpeed(),
            --up = mv:GetUpSpeed(),
        }

        local activeWep = ply:GetActiveWeapon()
        if IsValid(activeWep) and activeWep ~= NULL then
            mvData.weapon.model = activeWep:GetModel()
            mvData.weapon.holdType = activeWep:GetHoldType()
        end

        -- This player already has one or more clones, update them
        if mv_start[sid64] == false then
            if ply.RdmtCosmicClones then
                for _, c in ipairs(ply.RdmtCosmicClones) do
                    c:AddMoveData(curTime, mvData)
                end
            else
                mv_start[sid64].moves[curTime] = mvData
            end
            return
        -- Start waiting to create the clone
        elseif not mv_start[sid64] then
            mv_start[sid64] = {
                pos = ply:GetPos(),
                ang = ply:GetAngles(),
                moves = {}
            }

            timer.Create("RdmtCosmicCloneCreate_" .. sid64, delay, 1, function()
                if not IsValid(ply) then return end
                local mvStart = mv_start[sid64]

                -- Create the clone and pass any move history that we have
                local clone = CreateClone(ply, mvStart.pos, mvStart.ang)
                for t, d in pairs(mv_start[sid64].moves) do
                    clone:AddMoveData(t, d)
                end

                mv_start[sid64] = false

                if not ply.RdmtCosmicClones then
                    ply.RdmtCosmicClones = {}
                end
                TableInsert(ply.RdmtCosmicClones, clone)
            end)
        -- Keep track of any move data while the clone is being created
        else
            mv_start[sid64].moves[curTime] = mvData
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