AddCSLuaFile()

local ents = ents
local math = math
local pairs = pairs
local table = table

local EntsCreate = ents.Create
local MathRound = math.Round
local TableCount = table.Count
local TableInsert = table.insert
local TableRemove = table.remove

ENT.FakeWep              = nil
ENT.MoveData             = {}

ENT.Base                 = "base_anim"

if CLIENT then
    ENT.PrintName        = "Cosmic Clone"
    ENT.PositionCallback = nil
end

ENT.CloneColor           = Color(136, 0, 0)
ENT.CloneMaterial        = "!RdmtCosmicCloneMaterial"
ENT.DeadColor            = Color(255, 255, 255, 0)
ENT.DeadMaterial         = ""
ENT.TickRate             = 0.1
ENT.IsDead               = false

function ENT:Initialize()
    self:SetMoveType(SOLID_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 84))
    if SERVER then
        self:SetTrigger(true)
        self:SetColor(self.CloneColor)
        self:SetMaterial(self.CloneMaterial)
    end

    self.TickRate = MathRound(engine.TickInterval(), 3)
end

function ENT:SetupDataTables()
 	self:NetworkVar("String", "CloneOf")
 	self:NetworkVar("Int", "Delay")
end

function ENT:SetNextThink(curTime)
    if CLIENT then
        self:SetNextClientThink(curTime)
    end
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


    -- If we're less than 10 ticks from the correct delay then just wait longer =)
    if (curTime - mvData.time) < (self:GetDelay() - (self.TickRate * 10)) then
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
        self:SetDead(true)
        return self:SetNextThink(curTime)
    end

    self:SetDead(false)
    self:SetPos(mvData.pos)
    self:SetAngles(mvData.ang)
    if CLIENT then
        if self.PositionCallback then
            self.PositionCallback(self, mvData.pos)
        end
        self:SetCycle(mvData.cyc)
        self:SetSequence(mvData.seq)
        -- TODO: This doesn't handle weapon attacking like swinging the crowbar
        for pose, val in pairs(mvData.poses) do
            self:SetPoseParameter(pose, val)
        end
    else
        self:UpdateWeaponModel(mvData.wep)
    end

    return self:SetNextThink(curTime)
end

ENT.LastAdded = nil
function ENT:AddMoveData(mvData)
    mvData.added = (mvData.added or 0) + 1

    -- Don't allow duplicate values
    if self.LastAdded and not self.LastAdded.dead and not mvData.dead then
        local samePos = self.LastAdded.pos:IsEqualTol(mvData.pos, 0)

        -- Check the server and client properties differently
        if SERVER then
            if samePos and self.LastAdded.wep == mvData.wep then return end
        else
            if samePos and
                self.LastAdded.ang:IsEqualTol(mvData.ang, 0) and
                self.LastAdded.sec == mvData.sec and
                self.LastAdded.cyc == mvData.cyc and
                TableCount(self.LastAdded.poses) == TableCount(mvData.poses)
            then
                local allSame = true
                for pose, val in pairs(mvData.poses) do
                    if not self.LastAdded.poses[pose] then
                        allSame = false
                        break
                    end
                    if self.LastAdded.poses[pose] ~= val then
                        allSame = false
                        break
                    end
                end

                if allSame then return end
            end
        end
    end

    self.LastAdded = mvData
    TableInsert(self.MoveData, mvData)
end

function ENT:SetDead(dead)
    if self.IsDead == dead then return end
    self.IsDead = dead

    local clone = self
    local function SetVisible(ent, visible)
        ent:SetNoDraw(not visible)
        if visible then
            ent:SetColor(clone.CloneColor)
            ent:SetMaterial(clone.CloneMaterial)
            ent:SetRenderMode(RENDERMODE_NORMAL)
        else
            ent:SetColor(clone.DeadColor)
            ent:SetMaterial(clone.DeadMaterial)
            ent:SetRenderMode(RENDERMODE_TRANSALPHA)
        end
    end

    SetVisible(self, not dead)
    if SERVER and self.FakeWep then
        SetVisible(self.FakeWep, not dead)
    end
end

if SERVER then
    function ENT:OnRemove(fullUpdate)
        SafeRemoveEntity(self.FakeWep)
        self.FakeWep = nil
    end

    function ENT:UpdateWeaponModel(model)
        if not model then return end

        if not self.FakeWep then
            local attachment
            local lookup = self:LookupAttachment("anim_attachment_RH")
            if lookup == 0 then
                attachment = { Pos = self:GetPos() + self:OBBCenter() + Vector(0, 0, 5), Ang = self:GetForward():Angle() + Angle(20, 0, 0) }
            else
                attachment = self:GetAttachment(lookup)
            end

            -- Create the Fake weapon
            self.FakeWep = EntsCreate("base_anim")
            self.FakeWep:SetOwner(self)
            self.FakeWep:AddEffects(EF_BONEMERGE)
            self.FakeWep:SetMoveType(MOVETYPE_NONE)
            self.FakeWep:SetPos(attachment.Pos)
            self.FakeWep:SetAngles(attachment.Ang)
            self.FakeWep:SetParent(self)
        end

        if not util.IsValidModel(model) then
            self.FakeWep:SetNoDraw(true)
        else
            if self.FakeWep:GetNoDraw() then
                self.FakeWep:SetNoDraw(false)
            end

            if self.FakeWep:GetModel() ~= model then
                self.FakeWep:SetModel(model)
            end

            if self.FakeWep:GetColor() ~= self.CloneColor then
                self.FakeWep:SetColor(self.CloneColor)
            end

            if self.FakeWep:GetMaterial() ~= self.CloneMaterial then
                self.FakeWep:SetMaterial(self.CloneMaterial)
            end
        end
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
end