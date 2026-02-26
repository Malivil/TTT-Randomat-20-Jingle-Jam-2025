AddCSLuaFile()

local coroutine = coroutine
local math = math

local MathRand = math.Rand

ENT.Base             = "base_nextbot"
ENT.Spawnable        = true

ENT.FakeWep  = nil
ENT.HoldType = "melee"

local IdleActIndex = {
    ["pistol"]      = ACT_HL2MP_IDLE_PISTOL,
    ["smg"]         = ACT_HL2MP_IDLE_SMG1,
    ["grenade"]     = ACT_HL2MP_IDLE_GRENADE,
    ["ar2"]         = ACT_HL2MP_IDLE_AR2,
    ["shotgun"]     = ACT_HL2MP_IDLE_SHOTGUN,
    ["rpg"]         = ACT_HL2MP_IDLE_RPG,
    ["physgun"]     = ACT_HL2MP_IDLE_PHYSGUN,
    ["crossbow"]    = ACT_HL2MP_IDLE_CROSSBOW,
    ["melee"]       = ACT_HL2MP_IDLE_MELEE,
    ["slam"]        = ACT_HL2MP_IDLE_SLAM,
    ["fist"]        = ACT_HL2MP_IDLE_FIST,
    ["melee2"]      = ACT_HL2MP_IDLE_MELEE2,
    ["passive"]     = ACT_HL2MP_IDLE_PASSIVE,
    ["knife"]       = ACT_HL2MP_IDLE_KNIFE,
    ["duel"]        = ACT_HL2MP_IDLE_DUEL,
    ["camera"]      = ACT_HL2MP_IDLE_CAMERA,
    ["magic"]       = ACT_HL2MP_IDLE_MAGIC,
    ["revolver"]    = ACT_HL2MP_IDLE_REVOLVER
 }

function ENT:SetupDataTables()
   self:NetworkVar("String", "HoldType")
end

function ENT:Initialize()
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 84))
end

function ENT:OnRemove(fullUpdate)
    SafeRemoveEntity(self.FakeWep)
    self.FakeWep = nil
end

function ENT:RunBehaviour()
    -- TODO
    --self:StartActivity(ACT_HL2MP_IDLE_MELEE)

    --while (true) do
    --    self:StartActivity(ACT_HL2MP_IDLE_MELEE)
    --    coroutine.wait(MathRand(2, 4))
    --    coroutine.yield()
    --end

    ---- Find which data to use with delay
    --local targetSid64 = ply.RdmtCosmicCloneTarget
    ---- Sanity check
    --if not mv_data[targetSid64] then
    --    SafeRemoveEntity(ply)
    --    return
    --end
--
    --local time, mvData = next(mv_data[targetSid64])
    --if (curTime - time) < delay then return end
--
    ---- TODO: Does "next" skip nil keys?
    --print("Clearing", targetSid64, time)
    --mv_data[targetSid64][time] = nil
--
    --if not ply.FakeWep then
    --    local attachment
    --    local lookup = ply:LookupAttachment("anim_attachment_RH")
    --    if lookup == 0 then
    --        attachment = { Pos = ply:GetPos() + ply:OBBCenter() + Vector(0, 0, 5), Ang = ply:GetForward():Angle() + Angle(20, 0, 0) }
    --    else
    --        attachment = ply:GetAttachment(lookup)
    --    end
--
    --    -- Create the Fake weapon
    --    ply.FakeWep = ents.Create("base_anim")
    --    ply.FakeWep:SetOwner(ply)
    --    ply.FakeWep:AddEffects(EF_BONEMERGE)
    --    ply.FakeWep:SetMoveType(MOVETYPE_NONE)
    --    ply.FakeWep:SetPos(attachment.Pos)
    --    ply.FakeWep:SetAngles(attachment.Ang)
    --    ply.FakeWep:SetParent(ply)
    --end
--
    --if ply.FakeWep:GetModel() ~= mvData.weapon.model then
    --    ply.FakeWep:SetModel(mvData.weapon.model)
    --    ply:UpdateHoldType(mvData.weapon.holdType)
    --end
end

function ENT:UpdateMoveType(holdType)
    if holdType == self.HoldType then return end

    self.HoldType = holdType
    self:StartActivity(IdleActIndex[holdType])
end

function ENT:AddMoveData(curTime, mvData)
    -- TODO
end