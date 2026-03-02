AddCSLuaFile()

local ents = ents
local pairs = pairs
local table = table

local EntsCreate = ents.Create
local TableInsert = table.insert
local TableRemove = table.remove

ENT.FakeWep        = nil
ENT.MoveData       = {}

ENT.Base           = "base_anim"

if CLIENT then
    ENT.PrintName  = "Cosmic Clone"
end

function ENT:Initialize()
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 84))
    self:SetNoDraw(true)
end

function ENT:SetupDataTables()
 	self:NetworkVar("String", "CloneOf")
end

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
    end
end

function ENT:Think()
    local idx, mvData = next(self.MoveData)
    -- Sanity check
    if not mvData then return end

    -- Have to do it this way because setting the index to nil causes inserts
    -- to overwrite previously nil-ed values which causes the bot to move
    -- to the places in the wrong order
    TableRemove(self.MoveData, idx)

    if CLIENT then
        self:SetNoDraw(false)
        self:SetPos(mvData.pos)
        self:SetAngles(mvData.ang)
        self:SetCycle(mvData.cyc)
        self:SetSequence(mvData.seq)
        -- TODO: This doesn't handle weapon attacking like swinging the crowbar
        for pose, val in pairs(mvData.poses) do
            self:SetPoseParameter(pose, val)
        end

        self:SetNextClientThink(CurTime() + engine.TickInterval())
    else
        -- TODO: This doesn't work because the server position doesn't update. Updating the server position causes rubberbanding because it desyncs from the client
        --local distSqr = 32*32
        --for _, p in player.Iterator() do
        --    if p:GetPos():DistToSqr(mvData.pos) <= distSqr then
        --        local damage = p:Health()
        --        local att = player.GetBySteamID64(self:GetCloneOf())
        --        if not IsValid(att) or Randomat:ShouldActLikeJester(att) then
        --            att = game.GetWorld()
        --        else
        --            -- Boost this enough to compensate for the attacker's karma
        --            damage = damage * (1 + (1 - att:GetDamageFactor()))
        --        end
        --        -- Kill whoever touches the clone
        --        local dmginfo = DamageInfo()
        --        dmginfo:SetAttacker(att)
        --        dmginfo:SetInflictor(self)
        --        dmginfo:SetDamagePosition(self:GetPos())
        --        dmginfo:SetDamageType(DMG_DIRECT)
        --        dmginfo:SetDamage(math.ceil(damage))
        --        dmginfo:SetDamageForce(Vector(0, 0, 1))
        --        ent:TakeDamageInfo(dmginfo)
        --    end
        --end
        self:UpdateWeaponModel(mvData.wep)
    end
    self:NextThink(CurTime() + engine.TickInterval())

    return true
end

function ENT:AddMoveData(mvData)
    TableInsert(self.MoveData, mvData)
end