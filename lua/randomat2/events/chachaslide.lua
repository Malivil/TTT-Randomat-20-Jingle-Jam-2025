local ipairs = ipairs
local player = player
local timer = timer

local PlayerIterator = player.Iterator

local EVENT = {}

EVENT.Title = "This is something new..."
EVENT.AltTitle = "Cha-Cha Slide"
EVENT.Description = "Forces all players to dance to the Cha-Cha Slide"
EVENT.id = "chachaslide"
EVENT.IsEnabled = false

CreateConVar("randomat_chachaslide_music", "1", FCVAR_NONE, "Whether to play the music", 0, 1)
CreateConVar("randomat_chachaslide_text", "1", FCVAR_NONE, "Whether to show the lyrics on screen", 0, 1)
CreateConVar("randomat_chachaslide_endround", "0", FCVAR_NONE, "Whether to end the round when the song ends", 0, 1)
CreateConVar("randomat_chachaslide_endround_kill", "0", FCVAR_NONE, "Whether to kill everyone when the song ends", 0, 1)

local beatLength = 60/125
local timerCount = 0

local function CreateTimer(len, func)
    timerCount = timerCount + 1
    timer.Create("ChaChaSlide" .. timerCount, len * beatLength, 1, func)
end

local function Clap(owner)
    for _, ply in ipairs(owner:GetAlivePlayers()) do
        if not ply.GetActiveWeapon then continue end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or not wep.PrimaryAttack then continue end

        wep:PrimaryAttack()
    end
end

local function Hop(owner)
    local plys = owner:GetAlivePlayers()
    for _, ply in ipairs(plys) do
        ply:SetGravity(1.3)
        ply:ConCommand("+jump")
    end

    timer.Simple(0.2, function()
        for _, ply in ipairs(plys) do
            ply:SetGravity(1)
            ply:ConCommand("-jump")
        end
    end)
end

local function Left(owner, length)
    local plys = owner:GetAlivePlayers()
    for _, ply in ipairs(plys) do
        ply:ConCommand("+moveleft")
    end

    CreateTimer(length, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveleft")
        end
    end)
end

local function Right(owner, length)
    local plys = owner:GetAlivePlayers()
    for _, ply in ipairs(plys) do
        ply:ConCommand("+moveright")
    end

    CreateTimer(length, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveright")
        end
    end)
end

local function Back(owner, length)
    local plys = owner:GetAlivePlayers()
    for _, ply in ipairs(plys) do
        ply:ConCommand("+back")
    end

    CreateTimer(length, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-back")
        end
    end)
end

local function Freeze(owner, length)
    local plys = owner:GetAlivePlayers()
    for _, ply in ipairs(plys) do
        ply:Freeze(true)
    end

    CreateTimer(length, function()
        for _, ply in ipairs(plys) do
            ply:Freeze(false)
        end
    end)
end

local function Crouch(owner, length)
    local plys = owner:GetAlivePlayers()
    for _, ply in ipairs(plys) do
        ply:ConCommand("+duck")
    end

    CreateTimer(length, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-duck")
        end
    end)
end

local function Grow(owner, length)
    local plys = owner:GetAlivePlayers()
    for _, ply in ipairs(plys) do
        ply:SetViewOffset(Vector(0, 0, 96))
        ply:SetViewOffsetDucked(Vector(0, 0, 48))
    end

    CreateTimer(length, function()
        for _, ply in ipairs(plys) do
            ply:SetViewOffset(Vector(0, 0, 64))
            ply:SetViewOffsetDucked(Vector(0, 0, 32))
        end
    end)
end

local function CrossLeft(owner)
    local plys = owner:GetAlivePlayers()
    for _, ply in ipairs(plys) do
        ply:ConCommand("+moveleft")
        ply:ConCommand("+forward")
    end

    CreateTimer(0.5, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveleft")
            ply:ConCommand("-forward")
            ply:ConCommand("+moveright")
            ply:ConCommand("+back")
        end
    end)

    CreateTimer(1.5, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveright")
            ply:ConCommand("-back")
            ply:ConCommand("+moveleft")
            ply:ConCommand("+forward")
        end
    end)

    CreateTimer(2, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveleft")
            ply:ConCommand("-forward")
        end
    end)
end

local function CrossRight(owner)
    local plys = owner:GetAlivePlayers()
    for _, ply in ipairs(plys) do
        ply:ConCommand("+moveright")
        ply:ConCommand("+forward")
    end

    CreateTimer(0.5, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveright")
            ply:ConCommand("-forward")
            ply:ConCommand("+moveleft")
            ply:ConCommand("+back")
        end
    end)

    CreateTimer(1.5, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveleft")
            ply:ConCommand("-back")
            ply:ConCommand("+moveright")
            ply:ConCommand("+forward")
        end
    end)

    CreateTimer(2, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveright")
            ply:ConCommand("-forward")
        end
    end)
end

local function Dance(owner)
    for _, ply in ipairs(owner:GetAlivePlayers()) do
        ply:SendLua("RunConsoleCommand(\"act\", \"dance\")")
    end
end

local function Reverse(owner)
    for _, ply in ipairs(owner:GetAlivePlayers()) do
        local eyeang = ply:EyeAngles()
        eyeang.yaw = eyeang.yaw + 180
        if eyeang.yaw > 180 then
            eyeang.yaw = eyeang.yaw - 360
        end
        ply:SetEyeAngles(eyeang)
    end
end

local function End(owner)
    if not GetConVar("randomat_chachaslide_endround"):GetBool() then return end

    -- Stop the win checks so someone else doesn't steal this player's win
    StopWinChecks()
    -- Delay the actual end for a second so the state has a chance to propagate
    timer.Simple(1, function() EndRound(WIN_JESTER) end)

    if not GetConVar("randomat_chachaslide_endround_kill"):GetBool() then return end

    for _, ply in ipairs(owner:GetAlivePlayers()) do
        ply:Kill()
    end
end

function EVENT:Begin()
    if GetConVar("randomat_chachaslide_music"):GetBool() then
        for _, ply in PlayerIterator() do
            ply:SendLua("surface.PlaySound(\"chachaslide.wav\")")
        end
    end

    -- This is something new,
    -- The casper slide part two,
    -- Featuring the platinum band,
    -- And this time were gonna get funky (funky funky)

    -- Everybody clap your hands
    CreateTimer(36, function() Clap(self) end)
    -- Clap, clap, clap
    CreateTimer(37.5, function() Clap(self) end)
    CreateTimer(38.5, function() Clap(self) end)
    CreateTimer(39.5, function() Clap(self) end)
    -- Clap your hands
    CreateTimer(44, function() Clap(self) end)
    -- Clap, clap, clap
    CreateTimer(45.5, function() Clap(self) end)
    CreateTimer(46.5, function() Clap(self) end)
    CreateTimer(47.5, function() Clap(self) end)
    -- Clap your hands

    -- Alright we gonna do the basic steps

    -- To the left
    CreateTimer(56, function() Left(self, 2) end)
    -- Take it back now y'all
    CreateTimer(60, function() Back(self, 2) end)
    -- One hop this time
    CreateTimer(64, function() Hop(self) end)
    -- Right foot lets stomp
    CreateTimer(68, function() Right(self, 0.25) end)
    -- Left foot lets stomp
    CreateTimer(72, function() Left(self, 0.25) end)
    -- Cha cha real smooth
    CreateTimer(76, function() Dance(self) end)

    -- Turn it out

    -- To the left
    CreateTimer(88, function() Left(self, 2) end)
    -- Take it back now y'all
    CreateTimer(92, function() Back(self, 2) end)
    -- One hop this time
    CreateTimer(96, function() Hop(self) end)
    -- Right foot let's stomp
    CreateTimer(100, function() Right(self, 0.25) end)
    -- Left foot let's stomp
    CreateTimer(104, function() Left(self, 0.25) end)
    -- Cha cha real smooth
    CreateTimer(108, function() Dance(self) end)

    -- Now its time to get funky

    -- To the right now
    CreateTimer(116, function() Right(self, 2) end)
    -- To the left now
    CreateTimer(120, function() Left(self, 2) end)
    -- Take it back now y'all
    CreateTimer(124, function() Back(self, 2) end)
    -- One hop this time
    CreateTimer(128, function() Hop(self) end)
    -- One hop this time
    CreateTimer(132, function() Hop(self) end)
    -- Right foot two stomps
    CreateTimer(136, function() Right(self, 0.25) end)
    CreateTimer(137, function() Right(self, 0.25) end)
    -- Left foot two stomps
    CreateTimer(140, function() Left(self, 0.25) end)
    CreateTimer(141, function() Left(self, 0.25) end)
    -- Slide to the left
    CreateTimer(144, function() Left(self, 2) end)
    -- Slide to the right
    CreateTimer(148, function() Right(self, 2) end)
    -- Criss Cross
    CreateTimer(152, function() CrossLeft(self) end)
    -- Criss Cross
    CreateTimer(156, function() CrossRight(self) end)
    -- Cha cha real smooth
    CreateTimer(160, function() Dance(self) end)

    -- Let's go to work

    -- To the left
    CreateTimer(172, function() Left(self, 2) end)
    -- Take it back now y'all
    CreateTimer(176, function() Back(self, 2) end)
    -- Two hops this time
    CreateTimer(180, function() Hop(self) end)
    CreateTimer(181, function() Hop(self) end)
    -- Two hops this time
    CreateTimer(184, function() Hop(self) end)
    CreateTimer(185, function() Hop(self) end)
    -- Right foot two stomps
    CreateTimer(188, function() Right(self, 0.25) end)
    CreateTimer(189, function() Right(self, 0.25) end)
    -- Left foot two stomps
    CreateTimer(192, function() Left(self, 0.25) end)
    CreateTimer(193, function() Left(self, 0.25) end)

    -- Hands on your knees
    CreateTimer(196, function() Crouch(self, 0.5) end)
    CreateTimer(197, function() Crouch(self, 0.5) end)
    CreateTimer(198, function() Crouch(self, 0.5) end)
    CreateTimer(299, function() Crouch(self, 0.5) end)
    CreateTimer(200, function() Crouch(self, 0.5) end)
    -- Hands on your knees
    CreateTimer(201, function() Crouch(self, 0.5) end)
    CreateTimer(202, function() Crouch(self, 0.5) end)
    CreateTimer(203, function() Crouch(self, 0.5) end)
    CreateTimer(204, function() Crouch(self, 0.5) end)
    CreateTimer(205, function() Crouch(self, 0.5) end)
    -- Get funky with it
    CreateTimer(206, function() Crouch(self, 0.5) end)
    CreateTimer(207, function() Crouch(self, 0.5) end)
    CreateTimer(208, function() Crouch(self, 0.5) end)
    CreateTimer(209, function() Crouch(self, 0.5) end)
    CreateTimer(210, function() Crouch(self, 0.5) end)
    -- Oooooooh yea
    CreateTimer(211, function() Crouch(self, 0.5) end)
    CreateTimer(212, function() Crouch(self, 0.5) end)
    CreateTimer(213, function() Crouch(self, 0.5) end)
    CreateTimer(214, function() Crouch(self, 0.5) end)
    CreateTimer(215, function() Crouch(self, 0.5) end)

    -- Come on

    -- Cha cha now y'all
    CreateTimer(216, function() Dance(self) end)

    -- Turn it out
    -- TODO: Something for this?

    -- To the left
    CreateTimer(228, function() Left(self, 2) end)
    -- Take it back now y'all
    CreateTimer(232, function() Back(self, 2) end)
    -- Five hops this time
    CreateTimer(236, function() Hop(self) end)
    CreateTimer(237, function() Hop(self) end)
    CreateTimer(238, function() Hop(self) end)
    CreateTimer(239, function() Hop(self) end)
    CreateTimer(240, function() Hop(self) end)

    -- Right foot let's stomp
    CreateTimer(244, function() Right(self, 0.25) end)
    -- Left foot let's stomp
    CreateTimer(248, function() Left(self, 0.25) end)
    -- Right foot again
    CreateTimer(252, function() Right(self, 0.25) end)
    -- Left foot again
    CreateTimer(256, function() Left(self, 0.25) end)
    -- Right foot let's stomp
    CreateTimer(260, function() Right(self, 0.25) end)
    -- Left foot let's stomp
    CreateTimer(264, function() Left(self, 0.25) end)
    -- Freeze!
    CreateTimer(265.5, function() Freeze(self, 6.5) end)
    -- EVERYBODY CLAP YOUR HANDS!
    CreateTimer(272, function() Clap(self) end)
    CreateTimer(272.5, function() Clap(self) end)
    CreateTimer(273, function() Clap(self) end)
    CreateTimer(273.5, function() Clap(self) end)
    CreateTimer(274, function() Clap(self) end)
    CreateTimer(274.5, function() Clap(self) end)
    CreateTimer(275, function() Clap(self) end)
    CreateTimer(275.5, function() Clap(self) end)
    CreateTimer(276, function() Clap(self) end)
    CreateTimer(276.5, function() Clap(self) end)
    CreateTimer(277, function() Clap(self) end)
    CreateTimer(277.5, function() Clap(self) end)
    CreateTimer(278, function() Clap(self) end)
    CreateTimer(278.5, function() Clap(self) end)
    CreateTimer(279, function() Clap(self) end)
    CreateTimer(279.5, function() Clap(self) end)
    CreateTimer(280, function() Clap(self) end)
    CreateTimer(280.5, function() Clap(self) end)
    CreateTimer(281, function() Clap(self) end)
    CreateTimer(281.5, function() Clap(self) end)
    CreateTimer(282, function() Clap(self) end)
    CreateTimer(282.5, function() Clap(self) end)
    CreateTimer(283, function() Clap(self) end)
    CreateTimer(283.5, function() Clap(self) end)
    CreateTimer(284, function() Clap(self) end)
    CreateTimer(284.5, function() Clap(self) end)
    CreateTimer(285, function() Clap(self) end)
    CreateTimer(285.5, function() Clap(self) end)
    CreateTimer(286, function() Clap(self) end)
    CreateTimer(286.5, function() Clap(self) end)
    CreateTimer(287, function() Clap(self) end)
    CreateTimer(287.5, function() Clap(self) end)

    -- Come on y'all
    -- Check it out y'all

    -- How low can you go
    -- Can you go down low
    -- All the way to the floor
    -- How low can you go
    CreateTimer(288, function() Crouch(self, 16) end)
    -- Can you bring it to the top
    -- Like you never never stop
    -- Can you bring it to the top
    CreateTimer(304, function() Grow(self, 12) end)
    -- One hop
    CreateTimer(316, function() Hop(self) end)
    -- Right foot now
    CreateTimer(320, function() Right(self, 0.25) end)
    -- Left foot now y'all
    CreateTimer(324, function() Left(self, 0.25) end)
    -- Cha cha real smooth
    CreateTimer(328, function() Dance(self) end)

    -- Turn it out
    -- TODO: Something for this?

    -- To the left
    CreateTimer(340, function() Left(self, 2) end)
    -- Take it back now y'all
    CreateTimer(344, function() Back(self, 2) end)
    -- One hop this time
    CreateTimer(348, function() Hop(self) end)
    -- One hop this time
    CreateTimer(352, function() Hop(self) end)
    -- Reverse
    CreateTimer(356, function() Reverse(self) end)
    -- Reverse
    CreateTimer(360, function() Reverse(self) end)
    -- Slide to the left
    CreateTimer(364, function() Left(self, 2) end)
    -- Slide to the right
    CreateTimer(368, function() Right(self, 2) end)
    -- Reverse
    CreateTimer(372, function() Reverse(self) end)
    -- Reverse
    CreateTimer(373, function() Reverse(self) end)
    -- Reverse
    CreateTimer(376, function() Reverse(self) end)
    -- Reverse
    CreateTimer(377, function() Reverse(self) end)
    -- Cha cha now y'all
    -- Cha cha again
    -- Cha cha now y'all
    -- Cha cha again
    CreateTimer(380, function() Dance(self) end)

    -- Turn it out

    -- To the left
    CreateTimer(400, function() Left(self, 2) end)
    -- Take it back now y'all
    CreateTimer(404, function() Back(self, 2) end)
    -- Two hops two hops
    CreateTimer(408, function() Hop(self) end)
    CreateTimer(409, function() Hop(self) end)
    -- Two hops two hops
    CreateTimer(412, function() Hop(self) end)
    CreateTimer(413, function() Hop(self) end)
    -- Right foot let's stomp
    CreateTimer(416, function() Right(self, 0.25) end)
    -- Left foot let's stomp
    CreateTimer(420, function() Left(self, 0.25) end)
    -- Charlie brown
    -- Hop it out
    CreateTimer(424, function() Hop(self) end)
    CreateTimer(425, function() Hop(self) end)
    CreateTimer(426, function() Hop(self) end)
    CreateTimer(427, function() Hop(self) end)
    CreateTimer(428, function() Hop(self) end)
    -- Slide to the right
    CreateTimer(432, function() Right(self, 2) end)
    -- Slide to the left
    CreateTimer(436, function() Left(self, 2) end)
    -- Take it back now y'all
    CreateTimer(440, function() Back(self, 2) end)
    -- Cha cha now y'all
    CreateTimer(444, function() Dance(self) end)
    -- Oh yeah
    -- Yeah yeah
    -- Do that stuff
    -- Oh yeah
    -- I'm outta here y'all
    -- Peace
    CreateTimer(475.2, function() End(self) end)
end

function EVENT:End()
    for i = 1, timerCount do
        if timer.Exists("ChaChaSlide" .. i) then
            timer.Remove("ChaChaSlide" .. i)
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        ply:ConCommand("-jump")
        ply:ConCommand("-duck")
        ply:ConCommand("-moveleft")
        ply:ConCommand("-moveright")
        ply:ConCommand("-forward")
        ply:ConCommand("-back")
        ply:SetViewOffset(Vector(0, 0, 64))
        ply:SetViewOffsetDucked(Vector(0, 0, 32))
    end
end

function EVENT:Condition()
    if not ROLE_JESTER or ROLE_JESTER == Randomat.MISSING_ROLE then return true end

    -- Don't run this event if we have a jester
    for _, v in player.Iterator() do
        if v:GetRole() == ROLE_JESTER then
            return false
        end
    end

    return true
end

function EVENT:GetConVars()
    local checks = {}
    for _, v in ipairs({"music", "text", "endround", "endround_kill"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end
    return {}, checks
end

Randomat:register(EVENT)