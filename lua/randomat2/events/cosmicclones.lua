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
    clone.RdmtCosmicCloneTarget = ply:SteamID64()
    clone:Spawn()
    clone:Activate()

    return clone
end

local mv_start = {}
function EVENT:Begin()
    local delay = GetConVar("randomat_cosmicclones_delay"):GetInt()

    self:AddHook("SetupMove", function(ply, mv, cmd)
        local curTime = CurTime()
        local sid64 = ply:SteamID64()

        -- TODO: What do we need from this?
        local activeWep = ply:GetActiveWeapon()
        local mvData = {
            btns = mv:GetButtons(),
            ang = mv:GetMoveAngles(),
            --fwd = mv:GetForwardSpeed(),
            --side = mv:GetSideSpeed(),
            --up = mv:GetUpSpeed(),
            view = cmd:GetViewAngles(),
            weapon = {
                model = activeWep:GetModel(),
                holdType = activeWep:GetHoldType()
            }
        }

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
        ply.RdmtCosmicClones = nil
    end

    mv_start = {}
end

Randomat:register(EVENT)