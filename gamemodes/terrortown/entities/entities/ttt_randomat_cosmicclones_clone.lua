local math = math
local table = table

local MathRound = math.Round
local TableInsert = table.insert
local TableRemove = table.remove

ENT.Base                 = "base_anim"
if CLIENT then
    ENT.PrintName        = "Cosmic Clone"
end

ENT.MoveData             = {}

ENT.TickRate             = 0.1
ENT.MaxTicks             = 10

ENT.IsDead               = false

function ENT:Initialize()
    self.TickRate = MathRound(engine.TickInterval(), 3)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 84))
    self:SetNoDraw(true)
    if SERVER then
        self:SetTrigger(true)
    end
end

function ENT:SetupDataTables()
 	self:NetworkVar("String", "CloneOf")
 	self:NetworkVar("Int", "Delay")
end

function ENT:SetNextThink(curTime)
    self:NextThink(curTime)
    return true
end

function ENT:Think()
    local curTime = CurTime()
    local idx, mvData = next(self.MoveData)
    -- Sanity check
    if not mvData then
        return self:SetNextThink(curTime)
    end

    -- If we're less than the maximum ticks from the correct delay then just wait longer =)
    if (self:GetDelay() - (curTime - mvData.time)) > (self.TickRate * self.MaxTicks) then
        return self:SetNextThink(curTime)
    end

    local synchronized = false
    while not synchronized do
        TableRemove(self.MoveData, idx)
        local nextIdx, nextMvData = next(self.MoveData)
        -- Sanity check for when someone in fullscreen tabs out and the client stops tracking
        if not nextMvData then break end

        -- If the next move happened too long ago then skip it and try again
        -- Don't ever skip a death data point
        if mvData.dead or (curTime - mvData.time <= self:GetDelay()) then
            synchronized = true
        else
            idx = nextIdx
            mvData = nextMvData
        end
    end

    if mvData.dead then
        self.IsDead = true
        return self:SetNextThink(curTime)
    end

    self.IsDead = false
    self:SetPos(mvData.pos)

    return self:SetNextThink(curTime)
end

ENT.LastAdded = nil
function ENT:AddMoveData(mvData)
    mvData.added = (mvData.added or 0) + 1

    if self.LastAdded and not self.LastAdded.dead and not mvData.dead then
        if self.LastAdded.pos:IsEqualTol(mvData.pos, 0) then return end
    end

    self.LastAdded = mvData
    TableInsert(self.MoveData, mvData)
end

function ENT:StartTouch(ent)
    if self.IsDead then return end

    local damage = ent:Health()
    local att = player.GetBySteamID64(self:GetCloneOf())
    if not IsValid(att) or Randomat:ShouldActLikeJester(att) then
        att = game.GetWorld()
    else
        -- Boost this enough to compensate for the attacker's karma
        damage = damage * (1 + (1 - att:GetDamageFactor()))
    end

    -- Kill whoever touches the clone
    local dmginfo = DamageInfo()
    dmginfo:SetAttacker(att)
    dmginfo:SetInflictor(self)
    dmginfo:SetDamagePosition(self:GetPos())
    dmginfo:SetDamageType(DMG_DIRECT)
    dmginfo:SetDamage(math.ceil(damage))
    dmginfo:SetDamageForce(Vector(0, 0, 1))
    ent:TakeDamageInfo(dmginfo)
end