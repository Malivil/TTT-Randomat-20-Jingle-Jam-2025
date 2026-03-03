AddCSLuaFile()

local ents = ents
local pairs = pairs
local table = table

local EntsCreate = ents.Create
local TableCount = table.Count
local TableInsert = table.insert
local TableRemove = table.remove

ENT.FakeWep        = nil
ENT.MoveData       = {}

ENT.Base           = "base_anim"

if CLIENT then
    ENT.PrintName  = "Cosmic Clone"
    CreateMaterial("RdmtCosmicCloneMaterial", "VertexLitGeneric", {
        ["$basetexture"] = "vgui/white",
        ["$model"] = 1,
        ["$translucent"] = 1,
        ["$vertexalpha"] = 1,
        ["$vertexcolor"] = 1,
        ["$cloakpassenabled"] = 1,
        ["$cloakfactor"] = 0.31,
        ["$cloakcolortint"] = 0
    })
end

function ENT:Initialize()
    self:SetMoveType(SOLID_NONE)
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

ENT.LastThink = nil
function ENT:Think()
    local idx, mvData = next(self.MoveData)
    -- Sanity check
    if not mvData then return end

    local curTime = CurTime()
    print(curTime, mvData.time, curTime - mvData.time, self:GetDelay(), #self.MoveData, curTime - (self.LastThink or 0))
    self.LastThink = curTime

    local synchronized = false
    while not synchronized do
        TableRemove(self.MoveData, idx)
        local nextIdx, nextMvData = next(self.MoveData)

        -- If the next move happened too long ago then skip it and try again
        if curTime - mvData.time <= self:GetDelay() then
            synchronized = true
        else
            idx = nextIdx
            mvData = nextMvData
        end
    end

    self:SetPos(mvData.pos)
    if CLIENT then
        self:SetNoDraw(false)
        self:SetAngles(mvData.ang)
        self:SetCycle(mvData.cyc)
        self:SetSequence(mvData.seq)
        -- TODO: This doesn't handle weapon attacking like swinging the crowbar
        for pose, val in pairs(mvData.poses) do
            self:SetPoseParameter(pose, val)
        end

        self:SetNextClientThink(curTime)
    else
        self:UpdateWeaponModel(mvData.wep)
    end

    self:NextThink(curTime)
    return true
end

ENT.LastAdded = nil
function ENT:AddMoveData(mvData)
    if CLIENT then
        print(self, "AMD")
    end
    -- Don't allow duplicate values
    if self.LastAdded then
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

if SERVER then
    function ENT:OnRemove(fullUpdate)
        SafeRemoveEntity(self.FakeWep)
        self.FakeWep = nil
    end

    local darkRed = Color(136, 0, 0)
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

            if self.FakeWep:GetColor() ~= darkRed then
                self.FakeWep:SetColor(darkRed)
            end

            if self.FakeWep:GetMaterial() ~= "!RdmtCosmicCloneMaterial" then
                self.FakeWep:SetMaterial("!RdmtCosmicCloneMaterial")
            end
        end
    end

    function ENT:StartTouch(ent)
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