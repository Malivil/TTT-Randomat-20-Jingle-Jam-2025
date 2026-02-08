AddCSLuaFile()

local coroutine = coroutine
local math = math
local timer = timer

local MathAbs = math.abs
local MathApproachAngle = math.ApproachAngle
local MathAcos = math.acos
local MathRandom = math.random
local MathRand = math.Rand

ENT.Base             = "base_nextbot"
ENT.Spawnable        = true

local danceTime = 9
local danceMusic = {
    "music/HL1_song10.mp3",
    "music/HL1_song17.mp3",
    "music/HL1_song25_REMIX3.mp3",
    "music/HL2_song12_long.mp3",
    "music/HL2_song15.mp3",
    "music/HL2_song20_submix0.mp3",
    "music/HL2_song20_submix4.mp3",
    "music/HL2_song31.mp3",
    "music/HL2_song4.mp3",
}

ENT.FakeWep = nil

function ENT:Initialize()
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 84))
end

function ENT:OnRemove(fullUpdate)
    timer.Remove("RdmtCloneLook" .. self:EntIndex())
    SafeRemoveEntity(self.FakeWep)
    self.FakeWep = nil
end

local function AngleBetween(ang1, ang2)
    local vec1 = ang1:Forward()
    local vec2 = ang2:Forward()
    vec1:Normalize()
    vec2:Normalize()
    return MathAcos(vec1:Dot(vec2))
end

function ENT:Look(newYaw, newPitch, speed)
    local yaw = self:GetPoseParameter("aim_yaw") or 0
    local pitch = self:GetPoseParameter("aim_pitch") or 0

    local lookAng = AngleBetween(Angle(newPitch, newYaw, 0), Angle(pitch, yaw, 0))
    if lookAng < 0.01 then return end

    local yawScale = AngleBetween(Angle(0, newYaw, 0), Angle(0, yaw, 0)) / lookAng
    local pitchScale = AngleBetween(Angle(newPitch, 0, 0), Angle(pitch, 0, 0)) / lookAng
    local timeout = CurTime() + 5

    timer.Create("RdmtCloneLook" .. self:EntIndex(), 0, 0, function()
        if CurTime() > timeout then return end
        if not IsValid(self) then return end

        if MathAbs(yaw - newYaw) < 0.01 and MathAbs(pitch - newPitch) < 0.1 then
            return
        end

        yaw = MathApproachAngle(yaw or 0, newYaw, speed * yawScale)
        pitch = MathApproachAngle(pitch or 0, newPitch, speed * pitchScale)

        self:SetPoseParameter("aim_yaw", yaw)
        self:SetPoseParameter("aim_pitch", pitch)
    end)
end

function ENT:RunBehaviour()
    self:StartActivity(ACT_HL2MP_IDLE_MELEE)

    while (true) do
        -- Nod
        if MathRandom(10) <= 3 then
            local pitch
            for i = 1, MathRandom(9, 17) do
                coroutine.wait(0.2)
                if i % 2 == 1 then
                    pitch = 15
                else
                    pitch = -12
                end
                self:Look(0, pitch, 0.5)
            end
            self:Look(0, 0, 2)
            coroutine.wait(1)
            timer.Remove("RdmtCloneLook" .. self:EntIndex())
        -- Dance
        else
            local soundPath = danceMusic[MathRandom(#danceMusic)]
            self:EmitSound(soundPath, 75, 100, 1, CHAN_BODY)
            if IsValid(self.FakeWep) then
                self.FakeWep:SetNoDraw(true)
            end

            self:StartActivity(ACT_GMOD_TAUNT_DANCE)
            coroutine.wait(danceTime)

            if IsValid(self.FakeWep) then
                self.FakeWep:SetNoDraw(false)
            end
            self:StopSound(soundPath)
        end

        self:StartActivity(ACT_HL2MP_IDLE_MELEE)
        coroutine.wait(MathRand(2, 4))
        coroutine.yield()
    end
end