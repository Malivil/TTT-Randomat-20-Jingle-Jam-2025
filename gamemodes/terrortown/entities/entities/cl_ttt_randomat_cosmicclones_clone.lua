if SERVER then
    AddCSLuaFile()
    return
end

local ents = ents
local math = math
local pairs = pairs
local table = table

local EntsCreateClient = ents.CreateClientside
local MathRound = math.Round
local TableCount = table.Count
local TableInsert = table.insert
local TableRemove = table.remove

ENT.Base                 = "base_anim"
ENT.PrintName            = "Cosmic Clone"

ENT.FakeWep              = nil

ENT.MoveData             = {}
ENT.PositionCallback     = nil

ENT.CloneColor           = Color(136, 0, 0)
ENT.CloneMaterial        = "!RdmtCosmicCloneMaterial"

ENT.TickRate             = 0.1
ENT.MaxTicks             = 10

ENT.IsDead               = false

function ENT:Initialize()
    self.TickRate = MathRound(engine.TickInterval(), 3)
    self:SetColor(self.CloneColor)
    self:SetMaterial(self.CloneMaterial)
end

function ENT:SetupDataTables()
 	self:NetworkVar("Int", "Delay")
end

function ENT:SetNextThink(curTime)
    self:SetNextClientThink(curTime)
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
    self:SetAngles(mvData.ang)
    if self.PositionCallback then
        self.PositionCallback(self, mvData.pos)
    end
    self:SetCycle(mvData.cyc)
    self:SetSequence(mvData.seq)
    for pose, val in pairs(mvData.poses) do
        self:SetPoseParameter(pose, val)
    end
    self:UpdateWeaponModel(mvData.wep)

    return self:SetNextThink(curTime)
end

ENT.LastAdded = nil
function ENT:AddMoveData(mvData)
    mvData.added = (mvData.added or 0) + 1

    -- Don't allow duplicate values
    if self.LastAdded and not self.LastAdded.dead and not mvData.dead then
        local samePos = self.LastAdded.pos:IsEqualTol(mvData.pos, 0)

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

    self.LastAdded = mvData
    TableInsert(self.MoveData, mvData)
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
        self.FakeWep = EntsCreateClient("base_anim")
        self.FakeWep:SetOwner(self)
        self.FakeWep:AddEffects(EF_BONEMERGE)
        self.FakeWep:SetMoveType(MOVETYPE_NONE)
        self.FakeWep:SetPos(attachment.Pos)
        self.FakeWep:SetAngles(attachment.Ang)
        self.FakeWep:SetParent(self)
        self.FakeWep:SetNoDraw(true)
    end

    if not util.IsValidModel(model) then
        self.ValidFakeWep = false
    else
        self.ValidFakeWep = true

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

function ENT:Draw(flags)
    if self.IsDead then return end

    self:DrawModel(flags)

    if self.ValidFakeWep then
        self.FakeWep:DrawModel(flags)
    end
end