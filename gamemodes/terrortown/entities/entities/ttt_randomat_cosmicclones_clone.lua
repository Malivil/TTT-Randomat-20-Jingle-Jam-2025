AddCSLuaFile()

ENT.Base           = "base_nextbot"
ENT.Spawnable      = true

if CLIENT then
    ENT.PrintName = "Cosmic Clone"
end

function ENT:SetupDataTables()
   self:NetworkVar("String", "HoldType")
end

function ENT:Initialize()
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 84))
end

if SERVER then
    local coroutine = coroutine
    local ents = ents
    local math = math
    local table = table
    local timer = timer

    local EntsCreate = ents.Create
    local MathCeil = math.ceil
    local TableInsert = table.insert
    local TableRemove = table.remove

    ENT.PositionTolerance = 50
    ENT.FakeWep           = nil
    ENT.MoveData          = {}
    ENT.CloneOf           = nil

    function ENT:GetMovementSequence(idle, mvData)
        if not mvData.weapon.holdType then
            return self:SelectWeightedSequence(ACT_RESET)
        end

        local actType
        if mvData.jumping then
            actType = "JUMP"
        elseif idle then
            actType = "IDLE"
            if mvData.crouching then
                actType = actType .. "_CROUCH"
            end
        elseif mvData.crouching then
            actType = "WALK_CROUCH"
        elseif mvData.walking then
            actType = "WALK"
        else
            actType = "RUN"
        end

        local holdType = string.upper(mvData.weapon.holdType)
        if holdType == "SMG" then
            holdType = "SMG1"
        end
        return self:SelectWeightedSequence(_G["ACT_HL2MP_" .. actType .. "_" .. holdType] or ACT_RESET)
    end

    function ENT:OnRemove(fullUpdate)
        timer.Remove("RdmtCosmicCloneLook" .. self:EntIndex())
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

        if self.FakeWep:GetModel() ~= model then
            self.FakeWep:SetModel(model)
        end
    end

    function ENT:RunBehaviour()
        local delay = GetConVar("randomat_cosmicclones_delay"):GetInt()
        local rate = GetConVar("randomat_cosmicclones_rate"):GetInt()

        while (true) do
            local idx, mvData = next(self.MoveData)
            -- Sanity check
            if not mvData then
                coroutine.yield()
                continue
            end

            -- Only do the actions after the appropriate delay
            if (CurTime() - mvData.time) < delay then
                coroutine.yield()
                continue
            end

            -- Have to do it this way because setting the index to nil causes inserts
            -- to overwrite previously nil-ed values which causes the bot to move
            -- to the places in the wrong order
            TableRemove(self.MoveData, idx)

            self:UpdateWeaponModel(mvData.weapon.model)
            self:SetPoseParameter("aim_yaw", mvData.view.yaw)
            self:SetPoseParameter("aim_pitch", mvData.view.pitch)
            -- TODO: This gets overwritten by the movement logic. How do we make them move backwards?
            self:SetAngles(mvData.ang)

            -- If we're close enough to the position, just idle for a bit
            --print(self:GetRangeSquaredTo(mvData.pos))
            local idle = self:GetRangeSquaredTo(mvData.pos) < self.PositionTolerance

            -- Remove all the old layers
            for i = 0, MAX_OVERLAYS do
                self:RemoveLayer(i)
            end

            -- Play the movement sequence
            local seq = self:GetMovementSequence(idle, mvData)
            self:AddLayeredSequence(seq, 1)

            -- And any other layers below that
            for i, s in ipairs(mvData.seq) do
                self:AddLayeredSequence(s.id, 2 + i)
            end

            -- TODO: Make them move up like they are jumping
            if mvData.jumping then
                local vel = self.loco:GetVelocity()
                vel.z = mvData.jumpPower
                self.loco:SetVelocity(vel)

                vel = self:GetVelocity()
                vel.z = mvData.jumpPower
                self:SetVelocity(vel)
            end

            if not idle then
                self.loco:SetDesiredSpeed(mvData.speed)
                --[[local result = ]]self:MoveToPos(mvData.pos, {
                    lookahead = 100,
                    tolerance = 10,
                    draw = false,
                    -- Stop this a little early to try and blend into the next movement
                    maxage = rate * 0.8,
                    repath = 10000
                })

                -- TODO: If they are stuck, try teleporting them since these should be small increments anyway
                --if result == "stuck" or result == "failed" then
                --    self:SetPos(mvData.pos)
                --end
            end

            coroutine.yield()
        end
    end

    ENT.LastAdded = nil
    function ENT:AddMoveData(mvData)
        -- Ignore duplicates
        if self.LastAdded and
            self.LastAdded.pos:IsEqualTol(mvData.pos, 0) and
            self.LastAdded.ang:IsEqualTol(mvData.ang, 0) and
            (self.LastAdded.crouching == mvData.crouching) and
            (self.LastAdded.walking == mvData.walking) and
            (self.LastAdded.speed == mvData.speed) and
            (self.LastAdded.weapon.model == mvData.weapon.model) and
            (self.LastAdded.weapon.holdType == mvData.weapon.holdType) then
            return
        end

        -- If this is our first entry, set the initial weapon model
        if not self.LastAdded then
            self:UpdateWeaponModel(mvData.weapon.model)
        end

        self.LastAdded = mvData
        TableInsert(self.MoveData, mvData)
    end

    function ENT:OnContact(ent)
        if not IsPlayer(ent) then return end
        if not IsPlayer(self.CloneOf) then return end

        -- Kill whoever touches the clone
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker(self.CloneOf)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamagePosition(self:GetPos())
        dmginfo:SetDamageType(DMG_DIRECT)
        -- Boost this enough to compensate for the attacker's karma
        local damage = ent:Health() * (1 + (1 - self.CloneOf:GetDamageFactor()))
        dmginfo:SetDamage(MathCeil(damage))
        dmginfo:SetDamageForce(Vector(0, 0, 1))
        ent:TakeDamageInfo(dmginfo)
    end

    function ENT:BodyUpdate()
        self:BodyMoveXY()
    end
end