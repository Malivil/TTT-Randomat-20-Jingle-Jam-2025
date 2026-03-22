local ipairs = ipairs
local math = math
local player = player
local timer = timer

local MathMin = math.min
local PlayerIterator = player.Iterator

local EVENT = {}

util.AddNetworkString("RdmtChaChaSlideDance")

EVENT.Title = "This is something new..."
EVENT.AltTitle = "Cha-Cha Slide"
EVENT.Description = "Forces all players to dance to the Cha-Cha Slide"
EVENT.id = "chachaslide"
EVENT.Type = EVENT_TYPE_MUSIC
EVENT.Categories = {"fun", "largeimpact"}

local chachaslide_text  = CreateConVar("randomat_chachaslide_text", "1", FCVAR_NONE, "Whether to show the lyrics on screen", 0, 1)
CreateConVar("randomat_chachaslide_endround", "0", FCVAR_NONE, "Whether to end the round when the song ends", 0, 1)
CreateConVar("randomat_chachaslide_endround_kill", "0", FCVAR_NONE, "Whether to kill everyone when the song ends", 0, 1)

local timerCount = 0

local CreateTextTimer
local function CreateTimer(len, func, text, moveDelay, repeats)
    moveDelay = moveDelay or 0
    repeats = repeats or 1
    timerCount = timerCount + 1
    local timerId = "ChaChaSlide" .. timerCount
    timer.Create(timerId, len + moveDelay, repeats, function()
        func(timerId)
    end)
    if text then
        CreateTextTimer(len, text)
    end
end

CreateTextTimer = function(len, text)
    if not chachaslide_text:GetBool() then return end

    CreateTimer(len, function()
        for _, ply in PlayerIterator() do
            if CR_VERSION then
                ply:ClearQueuedMessage("RdmtChaChaSlide")
            end
            Randomat:PrintMessage(ply, MSG_PRINTCENTER, text, nil, "RdmtChaChaSlide")
        end
    end)
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

local function Turn(owner, deg)
    deg = deg or 90
    for _, ply in ipairs(owner:GetAlivePlayers()) do
        local eyeang = ply:EyeAngles()
        eyeang.yaw = eyeang.yaw + deg
        if eyeang.yaw > 180 then
            eyeang.yaw = eyeang.yaw - 360
        end
        ply:SetEyeAngles(eyeang)
    end
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

local startingOffsets = {}
local minViewOffset = 5
local function Shrink(owner, length)
    for _, ply in ipairs(owner:GetAlivePlayers()) do
        startingOffsets[ply:SteamID64()] = {
            norm = ply:GetViewOffset().z,
            duck = ply:GetViewOffsetDucked().z
        }
    end

    local segments = 10
    local time = length / segments
    CreateTimer(time, function()
        for _, ply in ipairs(owner:GetAlivePlayers()) do
            local sid64 = ply:SteamID64()
            local amtNorm = (startingOffsets[sid64].norm - minViewOffset) / segments
            local amtDuck = (startingOffsets[sid64].duck - minViewOffset) / segments
            ply:SetViewOffset(Vector(0, 0, ply:GetViewOffset().z - amtNorm))
            ply:SetViewOffsetDucked(Vector(0, 0, ply:GetViewOffsetDucked().z - amtDuck))
        end
    end, nil, nil, segments)
end

local function Grow(owner, length)
    local segments = 10
    local time = length / segments
    CreateTimer(time, function(timerId)
        local theEnd = timer.RepsLeft(timerId) == 0
        for _, ply in ipairs(owner:GetAlivePlayers()) do
            local sid64 = ply:SteamID64()
            local norm, duck
            if theEnd then
                norm = startingOffsets[sid64].norm
                duck = startingOffsets[sid64].duck
            else
                local amtNorm = (startingOffsets[sid64].norm - minViewOffset) / segments
                local amtDuck = (startingOffsets[sid64].duck - minViewOffset) / segments
                norm = MathMin(startingOffsets[sid64].norm, ply:GetViewOffset().z + amtNorm)
                duck = MathMin(startingOffsets[sid64].duck, ply:GetViewOffsetDucked().z + amtDuck)
            end

            ply:SetViewOffset(Vector(0, 0, norm))
            ply:SetViewOffsetDucked(Vector(0, 0, duck))
        end

        if theEnd then
            startingOffsets = {}
        end
    end, nil, nil, segments)
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
            if ply:Alive() and not ply:IsSpec() then
                ply:ConCommand("+moveright")
                ply:ConCommand("+back")
            end
        end
    end)

    CreateTimer(1.5, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveright")
            ply:ConCommand("-back")
            if ply:Alive() and not ply:IsSpec() then
                ply:ConCommand("+moveleft")
                ply:ConCommand("+forward")
            end
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
            if ply:Alive() and not ply:IsSpec() then
                ply:ConCommand("+moveleft")
                ply:ConCommand("+back")
            end
        end
    end)

    CreateTimer(1.5, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveleft")
            ply:ConCommand("-back")
            if ply:Alive() and not ply:IsSpec() then
                ply:ConCommand("+moveright")
                ply:ConCommand("+forward")
            end
        end
    end)

    CreateTimer(2, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveright")
            ply:ConCommand("-forward")
        end
    end)
end

local function Dance(owner, len)
    -- Freeze while dancing
    Freeze(owner, len)

    for _, ply in ipairs(owner:GetAlivePlayers()) do
        local activeWep = ply:GetActiveWeapon()
        if IsValid(activeWep) then
            activeWep:SetNoDraw(true)
        end
        ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, ACT_GMOD_TAUNT_DANCE, true)
    end

    CreateTimer(len, function()
        for _, ply in ipairs(owner:GetAlivePlayers()) do
            local activeWep = ply:GetActiveWeapon()
            if IsValid(activeWep) then
                activeWep:SetNoDraw(false)
            end
            ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, ACT_IDLE, true)
        end
    end)

    net.Start("RdmtChaChaSlideDance")
        net.WriteUInt(len, 5)
    net.Broadcast()
end

local function Reverse(owner)
    Turn(owner, 180)
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
    CreateTextTimer(2, "This is something new")
    CreateTextTimer(3, "The casper slide part two")
    CreateTextTimer(5.1, "Featuring the platinum band")
    CreateTextTimer(6.8, "And this time were gonna get funky (funky funky)")
    CreateTextTimer(13.3, "Funky (funky funky)")

    CreateTextTimer(15.3, "Everybody clap your hands")
    CreateTextTimer(17.2, "Clap")
    CreateTimer(17.6, function() Clap(self) end)
    CreateTextTimer(17.8, "Clap")
    CreateTextTimer(18.4, "Clap")
    CreateTimer(18.6, function() Clap(self) end)
    CreateTextTimer(18.9, "Clap your hands")
    CreateTimer(19.6, function() Clap(self) end)
    CreateTimer(20.6, function() Clap(self) end)
    CreateTextTimer(21, "Clap")
    CreateTextTimer(21.6, "Clap")
    CreateTimer(21.6, function() Clap(self) end)
    CreateTextTimer(22.2, "Clap")
    CreateTimer(22.5, function() Clap(self) end)
    CreateTextTimer(22.7, "Clap your hands")

    CreateTextTimer(23.6, "Alright we gonna do the basic steps")

    CreateTimer(26, function() Left(self, 2) end, "To the left")
    CreateTimer(27.5, function() Back(self, 2) end, "Take it back now y'all")
    CreateTimer(29.4, function() Hop(self) end, "One hop this time", 1.3)
    CreateTimer(31.5, function() Right(self, 0.25) end, "Right foot, let's stomp", 1.1)
    CreateTimer(33.2, function() Left(self, 0.25) end, "Left foot, let's stomp", 1.1)
    CreateTimer(35.2, function() Dance(self, 3.4) end, "Cha-Cha real smooth", 1.3)

    CreateTimer(39.2, function() Turn(self) end, "Turn it out", 0.8)

    CreateTimer(41.5, function() Left(self, 2) end, "To the left")
    CreateTimer(43, function() Back(self, 2) end, "Take it back now y'all")
    CreateTimer(44.9, function() Hop(self) end, "One hop this time", 1.3)
    CreateTimer(46.9, function() Right(self, 0.25) end, "Right foot, let's stomp", 1.1)
    CreateTimer(48.7, function() Left(self, 0.25) end, "Left foot, let's stomp", 1.1)
    CreateTimer(50.7, function() Dance(self, 3.4) end, "Cha-Cha now ya'll", 1.3)

    CreateTextTimer(52.5, "Now its time to get funky")

    CreateTimer(54.9, function() Right(self, 2) end, "To the right now")
    CreateTimer(56.9, function() Left(self, 2) end, "To the left")
    CreateTimer(58.2, function() Back(self, 2) end, "Take it back now y'all")
    CreateTimer(60.2, function() Hop(self) end, "One hop this time", 1.3)
    CreateTimer(62.1, function() Hop(self) end, "One hop this time", 1.3)
    CreateTextTimer(63.9, "Right foot, two stomps")
    CreateTimer(65.3, function() Right(self, 0.25) end)
    CreateTimer(65.6, function() Right(self, 0.25) end)
    CreateTextTimer(66, "Left foot, two stomps")
    CreateTimer(67.2, function() Left(self, 0.25) end)
    CreateTimer(67.5, function() Left(self, 0.25) end)
    CreateTimer(67.9, function() Left(self, 2) end, "Slide to the left", 1.3)
    CreateTimer(69.8, function() Right(self, 2) end, "Slide to the right", 1.3)
    CreateTimer(71.8, function() CrossLeft(self) end, "Criss Cross!", 1.1)
    CreateTimer(73.6, function() CrossRight(self) end, "Criss Cross!", 1.1)
    CreateTimer(75.5, function() Dance(self, 3.4) end, "Cha-Cha real smooth", 1.3)

    CreateTextTimer(79.6, "Let's go to work")

    CreateTimer(81.9, function() Left(self, 2) end, "To the left")
    CreateTimer(83.2, function() Back(self, 2) end, "Take it back now y'all")
    CreateTimer(85, function() Hop(self) end, "Two hops this time", 1.3)
    CreateTimer(86.9, function() Hop(self) end)
    CreateTimer(87, function() Hop(self) end, "Two hops this time", 1.3)
    CreateTimer(88.9, function() Hop(self) end)
    CreateTimer(89, function() Right(self, 0.25) end, "Right foot, two stomps", 1.3)
    CreateTimer(90.9, function() Right(self, 0.25) end)
    CreateTimer(91, function() Left(self, 0.25) end, "Left foot, two stomps", 1.3)
    CreateTimer(92.9, function() Left(self, 0.25) end)

    -- This text actually starts before the last action completes
    CreateTextTimer(92.1, "Hands on your knees")
    CreateTextTimer(93.1, "Hands on your knees")
    CreateTimer(93.9, function() Crouch(self, 0.3) end)
    CreateTimer(94.3, function() Crouch(self, 0.3) end)
    CreateTimer(94.7, function() Crouch(self, 0.3) end)
    CreateTimer(95.1, function() Crouch(self, 0.3) end)
    CreateTimer(95.5, function() Crouch(self, 0.3) end, "Get funky with it")
    CreateTimer(95.9, function() Crouch(self, 0.3) end)
    CreateTimer(96.3, function() Crouch(self, 0.3) end)
    CreateTimer(96.7, function() Crouch(self, 0.3) end)
    CreateTimer(97.1, function() Crouch(self, 0.3) end)
    CreateTimer(97.3, function() Crouch(self, 0.3) end, "Oooooooh yea", 0.2)
    CreateTimer(97.9, function() Crouch(self, 0.3) end)
    CreateTimer(98.3, function() Crouch(self, 0.3) end)
    CreateTimer(98.7, function() Crouch(self, 0.3) end)
    CreateTimer(99.1, function() Crouch(self, 0.3) end)
    CreateTimer(99.5, function() Crouch(self, 0.3) end)
    CreateTimer(99.9, function() Crouch(self, 0.3) end)
    CreateTimer(100.3, function() Crouch(self, 0.3) end)
    CreateTimer(100.7, function() Crouch(self, 0.3) end)
    CreateTimer(101.1, function() Crouch(self, 0.3) end)
    CreateTimer(101.5, function() Crouch(self, 0.3) end, "Come on!")
    CreateTimer(101.9, function() Crouch(self, 0.3) end)
    CreateTimer(102.3, function() Crouch(self, 0.3) end)

    CreateTimer(102.5, function() Dance(self, 3.4) end, "Cha-Cha now y'all", 1.3)

    CreateTimer(106.5, function() Turn(self) end, "Turn it out", 0.8)

    CreateTimer(108.7, function() Left(self, 2) end, "To the left")
    CreateTimer(110.2, function() Back(self, 2) end, "Take it back now y'all")
    CreateTimer(112, function() Hop(self) end, "Five hops this time", 1.3)
    CreateTimer(113.8, function() Hop(self) end)
    CreateTimer(114.3, function() Hop(self) end)
    CreateTimer(114.6, function() Hop(self) end, "Hop it out now", 0.2)
    CreateTimer(115.3, function() Hop(self) end)

    CreateTimer(116, function() Right(self, 0.25) end, "Right foot, let's stomp", 1.1)
    CreateTimer(117.7, function() Left(self, 0.25) end, "Left foot, let's stomp", 1.1)
    CreateTimer(119.7, function() Right(self, 0.25) end, "Right foot again", 1.1)
    CreateTimer(121.7, function() Left(self, 0.25) end, "Left foot again", 1.1)
    CreateTimer(123.7, function() Right(self, 0.25) end, "Right foot, let's stomp", 1.1)
    CreateTimer(125.7, function() Left(self, 0.25) end, "Left foot, let's stomp", 1.1)

    CreateTimer(127.5, function() Freeze(self, 6.5) end, "Freeze!")

    CreateTextTimer(128.7, "EVERYBODY CLAP YOUR HANDS!")
    CreateTimer(130.5, function() Clap(self) end)
    CreateTimer(130.8, function() Clap(self) end)
    CreateTimer(131.1, function() Clap(self) end)
    CreateTimer(131.4, function() Clap(self) end)
    CreateTimer(131.7, function() Clap(self) end)
    CreateTimer(132, function() Clap(self) end)
    CreateTimer(132.3, function() Clap(self) end)
    CreateTimer(132.6, function() Clap(self) end)
    CreateTimer(132.9, function() Clap(self) end)
    CreateTimer(133.2, function() Clap(self) end)
    CreateTimer(133.5, function() Clap(self) end, "Come on y'all")
    CreateTimer(133.8, function() Clap(self) end)
    CreateTimer(134.1, function() Clap(self) end)
    CreateTimer(134.4, function() Clap(self) end)
    CreateTimer(134.7, function() Clap(self) end)
    CreateTimer(135, function() Clap(self) end)
    CreateTimer(135.3, function() Clap(self) end)
    CreateTimer(135.6, function() Clap(self) end)
    CreateTimer(135.9, function() Clap(self) end)
    CreateTimer(136.2, function() Clap(self) end)
    CreateTimer(136.5, function() Clap(self) end, "Check it out y'all")
    CreateTimer(136.8, function() Clap(self) end)
    CreateTimer(136.1, function() Clap(self) end)
    CreateTimer(136.4, function() Clap(self) end)
    CreateTimer(136.7, function() Clap(self) end)
    CreateTimer(137, function() Clap(self) end)
    CreateTimer(137.3, function() Clap(self) end)
    CreateTimer(137.6, function() Clap(self) end)
    CreateTimer(137.9, function() Clap(self) end)
    CreateTimer(138.2, function() Clap(self) end)

    CreateTimer(138.2, function() Shrink(self, 7) end, "How low can you go?")
    CreateTextTimer(139.9, "Can you go down low?")
    CreateTextTimer(141.7, "All the way to the floor?")
    CreateTextTimer(143.7, "How low can you go?")

    CreateTimer(145.9, function() Grow(self, 5) end, "Can you bring it to the top?")
    CreateTextTimer(147.5, "Like you never never stop?")
    CreateTextTimer(149.5, "Can you bring it to the top?")

    CreateTimer(151, function() Hop(self) end, "One hop!", 0.5)
    CreateTimer(152.8, function() Right(self, 0.25) end, "Right foot now", 1.1)
    CreateTimer(154.4, function() Left(self, 0.25) end, "Left foot now y'all", 1.1)
    CreateTimer(156.2, function() Dance(self, 3.4) end, "Cha-Cha real smooth", 1.3)

    CreateTimer(160, function() Turn(self) end, "Turn it out", 1)

    CreateTimer(162.4, function() Left(self, 2) end, "To the left")
    CreateTimer(164, function() Back(self, 2) end, "Take it back now y'all")
    CreateTimer(165.7, function() Hop(self) end, "One hop this time", 1.3)
    CreateTimer(167.7, function() Hop(self) end, "One hop this time", 1.3)
    CreateTimer(169.7, function() Reverse(self) end, "Reverse!", 1.3)
    CreateTimer(171.7, function() Reverse(self) end, "Reverse!", 1.3)
    CreateTimer(173.3, function() Left(self, 2) end, "Slide to the left", 1.3)
    CreateTimer(175.4, function() Right(self, 2) end, "Slide to the right", 1.3)
    CreateTimer(177.4, function() Reverse(self) end, "Reverse! Reverse!")
    CreateTimer(178, function() Reverse(self) end)
    CreateTimer(179.4, function() Reverse(self) end, "Reverse! Reverse!")
    CreateTimer(180, function() Reverse(self) end)

    CreateTimer(181, function() Dance(self, 6.7) end, "Cha-Cha now y'all", 1.3)
    CreateTextTimer(183, "Cha-Cha again")
    CreateTextTimer(185, "Cha-Cha now y'all")
    CreateTextTimer(187, "Cha-Cha again")

    CreateTimer(189, function() Turn(self) end, "Turn it out", 0.8)

    CreateTimer(191.3, function() Left(self, 2) end, "To the left")
    CreateTimer(192.6, function() Back(self, 2) end, "Take it back now y'all")
    CreateTimer(194.6, function() Hop(self) end, "Two hops, two hops", 1.3)
    CreateTimer(196.2, function() Hop(self) end)
    CreateTimer(196.6, function() Hop(self) end, "Two hops, two hops", 1.3)
    CreateTimer(198.2, function() Hop(self) end)
    CreateTimer(198.5, function() Right(self, 0.25) end, "Right foot, let's stomp", 1.3)
    CreateTimer(200.5, function() Left(self, 0.25) end, "Left foot, let's stomp", 1.3)

    CreateTextTimer(202.5, "Charlie Brown")
    CreateTimer(203.5, function() Hop(self) end)
    CreateTimer(204, function() Hop(self) end)
    CreateTimer(204.5, function() Hop(self) end, "Hop it out now")
    CreateTimer(205, function() Hop(self) end)
    CreateTimer(205.5, function() Hop(self) end)

    CreateTimer(206, function() Right(self, 2) end, "Slide to the right", 1.3)
    CreateTimer(208, function() Left(self, 2) end, "Slide to the left", 1.3)
    CreateTimer(210, function() Back(self, 2) end, "Take it back now y'all", 1.3)
    CreateTimer(212, function() Dance(self, 3.4) end, "Cha-Cha now y'all", 1.3)

    CreateTextTimer(214.3, "Oh yeah")
    CreateTextTimer(219.2, "Yeah (yeah)")
    CreateTextTimer(219.8, "Do that stuff (do that stuff)")
    CreateTextTimer(223.3, "Oh yeah")
    CreateTextTimer(226.7, "I'm outta here y'all")
    CreateTimer(228, function() End(self) end, "Peace")
end

function EVENT:End()
    for i = 1, timerCount do
        if timer.Exists("ChaChaSlide" .. i) then
            timer.Remove("ChaChaSlide" .. i)
        end
    end
    timerCount = 0

    for _, ply in ipairs(player.GetAll()) do
        local activeWep = ply:GetActiveWeapon()
        if IsValid(activeWep) then
            activeWep:SetNoDraw(false)
        end
        ply:Freeze(false)
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