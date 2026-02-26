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

-- TODO: Prevent this entity from being killed

if SERVER then
    local coroutine = coroutine
    local ents = ents
    local math = math
    local timer = timer

    local EntsCreate = ents.Create
    local MathCeil = math.ceil

    ENT.PositionTolerance = 0
    ENT.FakeWep           = nil
    ENT.MoveData          = {}
    ENT.CloneOf           = nil

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
    local IdleCrouchActIndex = {
        ["pistol"]      = ACT_HL2MP_IDLE_CROUCH_PISTOL,
        ["smg"]         = ACT_HL2MP_IDLE_CROUCH_SMG1,
        ["grenade"]     = ACT_HL2MP_IDLE_CROUCH_GRENADE,
        ["ar2"]         = ACT_HL2MP_IDLE_CROUCH_AR2,
        ["shotgun"]     = ACT_HL2MP_IDLE_CROUCH_SHOTGUN,
        ["rpg"]         = ACT_HL2MP_IDLE_CROUCH_RPG,
        ["physgun"]     = ACT_HL2MP_IDLE_CROUCH_PHYSGUN,
        ["crossbow"]    = ACT_HL2MP_IDLE_CROUCH_CROSSBOW,
        ["melee"]       = ACT_HL2MP_IDLE_CROUCH_MELEE,
        ["slam"]        = ACT_HL2MP_IDLE_CROUCH_SLAM,
        ["fist"]        = ACT_HL2MP_IDLE_CROUCH_FIST,
        ["melee2"]      = ACT_HL2MP_IDLE_CROUCH_MELEE2,
        ["passive"]     = ACT_HL2MP_IDLE_CROUCH_PASSIVE,
        ["knife"]       = ACT_HL2MP_IDLE_CROUCH_KNIFE,
        ["duel"]        = ACT_HL2MP_IDLE_CROUCH_DUEL,
        ["camera"]      = ACT_HL2MP_IDLE_CROUCH_CAMERA,
        ["magic"]       = ACT_HL2MP_IDLE_CROUCH_MAGIC,
        ["revolver"]    = ACT_HL2MP_IDLE_CROUCH_REVOLVER
    }
    local RunActIndex = {
        ["pistol"]      = ACT_HL2MP_RUN_PISTOL,
        ["smg"]         = ACT_HL2MP_RUN_SMG1,
        ["grenade"]     = ACT_HL2MP_RUN_GRENADE,
        ["ar2"]         = ACT_HL2MP_RUN_AR2,
        ["shotgun"]     = ACT_HL2MP_RUN_SHOTGUN,
        ["rpg"]         = ACT_HL2MP_RUN_RPG,
        ["physgun"]     = ACT_HL2MP_RUN_PHYSGUN,
        ["crossbow"]    = ACT_HL2MP_RUN_CROSSBOW,
        ["melee"]       = ACT_HL2MP_RUN_MELEE,
        ["slam"]        = ACT_HL2MP_RUN_SLAM,
        ["fist"]        = ACT_HL2MP_RUN_FIST,
        ["melee2"]      = ACT_HL2MP_RUN_MELEE2,
        ["passive"]     = ACT_HL2MP_RUN_PASSIVE,
        ["knife"]       = ACT_HL2MP_RUN_KNIFE,
        ["duel"]        = ACT_HL2MP_RUN_DUEL,
        ["camera"]      = ACT_HL2MP_RUN_CAMERA,
        ["magic"]       = ACT_HL2MP_RUN_MAGIC,
        ["revolver"]    = ACT_HL2MP_RUN_REVOLVER
    }
    local WalkActIndex = {
        ["pistol"]      = ACT_HL2MP_WALK_PISTOL,
        ["smg"]         = ACT_HL2MP_WALK_SMG1,
        ["grenade"]     = ACT_HL2MP_WALK_GRENADE,
        ["ar2"]         = ACT_HL2MP_WALK_AR2,
        ["shotgun"]     = ACT_HL2MP_WALK_SHOTGUN,
        ["rpg"]         = ACT_HL2MP_WALK_RPG,
        ["physgun"]     = ACT_HL2MP_WALK_PHYSGUN,
        ["crossbow"]    = ACT_HL2MP_WALK_CROSSBOW,
        ["melee"]       = ACT_HL2MP_WALK_MELEE,
        ["slam"]        = ACT_HL2MP_WALK_SLAM,
        ["fist"]        = ACT_HL2MP_WALK_FIST,
        ["melee2"]      = ACT_HL2MP_WALK_MELEE2,
        ["passive"]     = ACT_HL2MP_WALK_PASSIVE,
        ["knife"]       = ACT_HL2MP_WALK_KNIFE,
        ["duel"]        = ACT_HL2MP_WALK_DUEL,
        ["camera"]      = ACT_HL2MP_WALK_CAMERA,
        ["magic"]       = ACT_HL2MP_WALK_MAGIC,
        ["revolver"]    = ACT_HL2MP_WALK_REVOLVER
    }
    local WalkCrouchActIndex = {
        ["pistol"]      = ACT_HL2MP_WALK_CROUCH_PISTOL,
        ["smg"]         = ACT_HL2MP_WALK_CROUCH_SMG1,
        ["grenade"]     = ACT_HL2MP_WALK_CROUCH_GRENADE,
        ["ar2"]         = ACT_HL2MP_WALK_CROUCH_AR2,
        ["shotgun"]     = ACT_HL2MP_WALK_CROUCH_SHOTGUN,
        ["rpg"]         = ACT_HL2MP_WALK_CROUCH_RPG,
        ["physgun"]     = ACT_HL2MP_WALK_CROUCH_PHYSGUN,
        ["crossbow"]    = ACT_HL2MP_WALK_CROUCH_CROSSBOW,
        ["melee"]       = ACT_HL2MP_WALK_CROUCH_MELEE,
        ["slam"]        = ACT_HL2MP_WALK_CROUCH_SLAM,
        ["fist"]        = ACT_HL2MP_WALK_CROUCH_FIST,
        ["melee2"]      = ACT_HL2MP_WALK_CROUCH_MELEE2,
        ["passive"]     = ACT_HL2MP_WALK_CROUCH_PASSIVE,
        ["knife"]       = ACT_HL2MP_WALK_CROUCH_KNIFE,
        ["duel"]        = ACT_HL2MP_WALK_CROUCH_DUEL,
        ["camera"]      = ACT_HL2MP_WALK_CROUCH_CAMERA,
        ["magic"]       = ACT_HL2MP_WALK_CROUCH_MAGIC,
        ["revolver"]    = ACT_HL2MP_WALK_CROUCH_REVOLVER
    }

    function ENT:OnRemove(fullUpdate)
        timer.Remove("RdmtCosmicCloneLook" .. self:EntIndex())
        SafeRemoveEntity(self.FakeWep)
        self.FakeWep = nil
    end

    function ENT:RunBehaviour()
        local delay = GetConVar("randomat_cosmicclones_delay"):GetInt()
        while (true) do
            local time, mvData = next(self.MoveData)
            -- Sanity check
            if not time then
                coroutine.yield()
                continue
            end

            -- Only do the actions after the appropriate delay
            if (CurTime() - time) < delay then
                coroutine.yield()
                continue
            end

            self.loco:FaceTowards(mvData.pos)
            -- TODO: self.loco:SetAcceleration(???)

            self.MoveData[time] = nil

            if mvData.weapon.model then
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

                if self.FakeWep:GetModel() ~= mvData.weapon.model then
                    self.FakeWep:SetModel(mvData.weapon.model)
                end
            end

            -- TODO: Not sure this is right
            self:SetPoseParameter("aim_yaw", mvData.ang.yaw)
            self:SetPoseParameter("aim_pitch", mvData.ang.pitch)

            -- If we're close enough to the position, just idle for a bit
            if self:GetRangeSquaredTo(mvData.pos) < self.PositionTolerance then
                local act
                if mvData.crouching then
                    act = IdleCrouchActIndex[mvData.weapon.holdType]
                else
                    act = IdleActIndex[mvData.weapon.holdType]
                end
                self:StartActivity(act or ACT_RESET)
            else
                local act
                if mvData.crouching then
                    act = WalkCrouchActIndex[mvData.weapon.holdType]
                elseif mvData.walking then
                    act = WalkActIndex[mvData.weapon.holdType]
                else
                    act = RunActIndex[mvData.weapon.holdType]
                end

                self.loco:SetDesiredSpeed(mvData.speed)
                self:StartActivity(act or ACT_RESET)
                -- TODO: Don't know if this is right
                local result = self:MoveToPos(mvData.pos, {
                    lookahead = 100,
                    tolerance = 0,
                    draw = false,
                    maxage = 0.1,
                    repath = 0.1
                })

                -- If they are stuck, try teleporting them since these should be small increments anyway
                if result == "stuck" then
                    self:SetPos(mvData.pos)
                end
            end

            coroutine.yield()
        end
    end

    function ENT:AddMoveData(curTime, mvData)
        self.MoveData[curTime] = mvData
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
end