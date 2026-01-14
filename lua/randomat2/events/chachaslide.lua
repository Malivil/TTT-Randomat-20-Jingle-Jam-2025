local ipairs = ipairs
local player = player
local timer = timer

local PlayerIterator = player.Iterator

local EVENT = {}

EVENT.Title = "This is something new..."
EVENT.Description = "Forces all players to dance to the Cha-Cha Slide"
EVENT.id = "chachaslide"
EVENT.IsEnabled = false

local beatLength = 60/125

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

    timer.Simple(length * beatLength, function()
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

    timer.Simple(length * beatLength, function()
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

    timer.Simple(length * beatLength, function()
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

    timer.Simple(length * beatLength, function()
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

    timer.Simple(length * beatLength, function()
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

    timer.Simple(length * beatLength, function()
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

    timer.Simple(0.5 * beatLength, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveleft")
            ply:ConCommand("-forward")
            ply:ConCommand("+moveright")
            ply:ConCommand("+back")
        end
    end)

    timer.Simple(1.5 * beatLength, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveright")
            ply:ConCommand("-back")
            ply:ConCommand("+moveleft")
            ply:ConCommand("+forward")
        end
    end)

    timer.Simple(2 * beatLength, function()
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

    timer.Simple(0.5 * beatLength, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveright")
            ply:ConCommand("-forward")
            ply:ConCommand("+moveleft")
            ply:ConCommand("+back")
        end
    end)

    timer.Simple(1.5 * beatLength, function()
        for _, ply in ipairs(plys) do
            ply:ConCommand("-moveleft")
            ply:ConCommand("-back")
            ply:ConCommand("+moveright")
            ply:ConCommand("+forward")
        end
    end)

    timer.Simple(2 * beatLength, function()
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

local function Kill(owner)
    -- Stop the win checks so someone else doesn't steal this player's win
    StopWinChecks()
    -- Delay the actual end for a second so the state has a chance to propagate
    timer.Simple(1, function() EndRound(WIN_JESTER) end)

    for _, ply in ipairs(owner:GetAlivePlayers()) do
        ply:Kill()
    end
end

function EVENT:Begin()
    for _, ply in PlayerIterator() do
        ply:SendLua("surface.PlaySound(\"chachaslide.wav\")")
    end

    -- This is something new,
    -- The casper slide part two,
    -- Featuring the platinum band,
    -- And this time were gonna get funky (funky funky)

    -- Everybody clap your hands
    timer.Create("ChaChaSlide1", 36 * beatLength, 1, function() Clap(self) end)
    -- Clap, clap, clap
    timer.Create("ChaChaSlide2", 37.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide3", 38.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide4", 39.5 * beatLength, 1, function() Clap(self) end)
    -- Clap your hands
    timer.Create("ChaChaSlide5", 44 * beatLength, 1, function() Clap(self) end)
    -- Clap, clap, clap
    timer.Create("ChaChaSlide6", 45.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide7", 46.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide8", 47.5 * beatLength, 1, function() Clap(self) end)
    -- Clap your hands

    -- Alright we gonna do the basic steps

    -- To the left
    timer.Create("ChaChaSlide9", 56 * beatLength, 1, function() Left(self, 2) end)
    -- Take it back now y'all
    timer.Create("ChaChaSlide10", 60 * beatLength, 1, function() Back(self, 2) end)
    -- One hop this time
    timer.Create("ChaChaSlide11", 64 * beatLength, 1, function() Hop(self) end)
    -- Right foot lets stomp
    timer.Create("ChaChaSlide12", 68 * beatLength, 1, function() Right(self, 0.25) end)
    -- Left foot lets stomp
    timer.Create("ChaChaSlide13", 72 * beatLength, 1, function() Left(self, 0.25) end)
    -- Cha cha real smooth
    timer.Create("ChaChaSlide14", 76 * beatLength, 1, function() Dance(self) end)

    -- Turn it out

    -- To the left
    timer.Create("ChaChaSlide15", 88 * beatLength, 1, function() Left(self, 2) end)
    -- Take it back now y'all
    timer.Create("ChaChaSlide16", 92 * beatLength, 1, function() Back(self, 2) end)
    -- One hop this time
    timer.Create("ChaChaSlide17", 96 * beatLength, 1, function() Hop(self) end)
    -- Right foot let's stomp
    timer.Create("ChaChaSlide18", 100 * beatLength, 1, function() Right(self, 0.25) end)
    -- Left foot let's stomp
    timer.Create("ChaChaSlide19", 104 * beatLength, 1, function() Left(self, 0.25) end)
    -- Cha cha real smooth
    timer.Create("ChaChaSlide20", 108 * beatLength, 1, function() Dance(self) end)

    -- Now its time to get funky

    -- To the right now
    timer.Create("ChaChaSlide21", 116 * beatLength, 1, function() Right(self, 2) end)
    -- To the left now
    timer.Create("ChaChaSlide22", 120 * beatLength, 1, function() Left(self, 2) end)
    -- Take it back now y'all
    timer.Create("ChaChaSlide23", 124 * beatLength, 1, function() Back(self, 2) end)
    -- One hop this time
    timer.Create("ChaChaSlide24", 128 * beatLength, 1, function() Hop(self) end)
    -- One hop this time
    timer.Create("ChaChaSlide25", 132 * beatLength, 1, function() Hop(self) end)
    -- Right foot two stomps
    timer.Create("ChaChaSlide26", 136 * beatLength, 1, function() Right(self, 0.25) end)
    timer.Create("ChaChaSlide27", 137 * beatLength, 1, function() Right(self, 0.25) end)
    -- Left foot two stomps
    timer.Create("ChaChaSlide28", 140 * beatLength, 1, function() Left(self, 0.25) end)
    timer.Create("ChaChaSlide29", 141 * beatLength, 1, function() Left(self, 0.25) end)
    -- Slide to the left
    timer.Create("ChaChaSlide30", 144 * beatLength, 1, function() Left(self, 2) end)
    -- Slide to the right
    timer.Create("ChaChaSlide31", 148 * beatLength, 1, function() Right(self, 2) end)
    -- Criss Cross
    timer.Create("ChaChaSlide32", 152 * beatLength, 1, function() CrossLeft(self) end)
    -- Criss Cross
    timer.Create("ChaChaSlide33", 156 * beatLength, 1, function() CrossRight(self) end)
    -- Cha cha real smooth
    timer.Create("ChaChaSlide34", 160 * beatLength, 1, function() Dance(self) end)

    -- Let's go to work

    -- To the left
    timer.Create("ChaChaSlide35", 172 * beatLength, 1, function() Left(self, 2) end)
    -- Take it back now y'all
    timer.Create("ChaChaSlide36", 176 * beatLength, 1, function() Back(self, 2) end)
    -- Two hops this time
    timer.Create("ChaChaSlide37", 180 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide38", 181 * beatLength, 1, function() Hop(self) end)
    -- Two hops this time
    timer.Create("ChaChaSlide39", 184 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide40", 185 * beatLength, 1, function() Hop(self) end)
    -- Right foot two stomps
    timer.Create("ChaChaSlide41", 188 * beatLength, 1, function() Right(self, 0.25) end)
    timer.Create("ChaChaSlide42", 189 * beatLength, 1, function() Right(self, 0.25) end)
    -- Left foot two stomps
    timer.Create("ChaChaSlide43", 192 * beatLength, 1, function() Left(self, 0.25) end)
    timer.Create("ChaChaSlide44", 193 * beatLength, 1, function() Left(self, 0.25) end)

    -- Hands on your knees
    timer.Create("ChaChaSlide45", 196 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide46", 197 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide47", 198 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide48", 299 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide49", 200 * beatLength, 1, function() Crouch(self, 0.5) end)
    -- Hands on your knees
    timer.Create("ChaChaSlide50", 201 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide51", 202 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide52", 203 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide53", 204 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide54", 205 * beatLength, 1, function() Crouch(self, 0.5) end)
    -- Get funky with it
    timer.Create("ChaChaSlide55", 206 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide56", 207 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide57", 208 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide58", 209 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide59", 210 * beatLength, 1, function() Crouch(self, 0.5) end)
    -- Oooooooh yea
    timer.Create("ChaChaSlide60", 211 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide61", 212 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide62", 213 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide63", 214 * beatLength, 1, function() Crouch(self, 0.5) end)
    timer.Create("ChaChaSlide64", 215 * beatLength, 1, function() Crouch(self, 0.5) end)

    -- Come on

    -- Cha cha now y'all
    timer.Create("ChaChaSlide65", 216 * beatLength, 1, function() Dance(self) end)

    -- Turn it out

    -- To the left
    timer.Create("ChaChaSlide66", 228 * beatLength, 1, function() Left(self, 2) end)
    -- Take it back now y'all
    timer.Create("ChaChaSlide67", 232 * beatLength, 1, function() Back(self, 2) end)
    -- Five hops this time
    timer.Create("ChaChaSlide68", 236 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide69", 237 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide70", 238 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide71", 239 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide72", 240 * beatLength, 1, function() Hop(self) end)

    -- Right foot let's stomp
    timer.Create("ChaChaSlide73", 244 * beatLength, 1, function() Right(self, 0.25) end)
    -- Left foot let's stomp
    timer.Create("ChaChaSlide74", 248 * beatLength, 1, function() Left(self, 0.25) end)
    -- Right foot again
    timer.Create("ChaChaSlide75", 252 * beatLength, 1, function() Right(self, 0.25) end)
    -- Left foot again
    timer.Create("ChaChaSlide76", 256 * beatLength, 1, function() Left(self, 0.25) end)
    -- Right foot let's stomp
    timer.Create("ChaChaSlide77", 260 * beatLength, 1, function() Right(self, 0.25) end)
    -- Left foot let's stomp
    timer.Create("ChaChaSlide78", 264 * beatLength, 1, function() Left(self, 0.25) end)
    -- Freeze!
    timer.Create("ChaChaSlide79", 265.5 * beatLength, 1, function() Freeze(self, 6.5) end)
    -- EVERYBODY CLAP YOUR HANDS!
    timer.Create("ChaChaSlide80", 272 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide81", 272.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide82", 273 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide83", 273.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide84", 274 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide85", 274.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide86", 275 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide87", 275.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide88", 276 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide89", 276.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide90", 277 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide91", 277.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide92", 278 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide93", 278.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide94", 279 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide95", 279.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide96", 280 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide97", 280.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide98", 281 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide99", 281.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide100", 282 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide101", 282.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide102", 283 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide103", 283.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide104", 284 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide105", 284.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide106", 285 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide107", 285.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide108", 286 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide109", 286.5 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide110", 287 * beatLength, 1, function() Clap(self) end)
    timer.Create("ChaChaSlide111", 287.5 * beatLength, 1, function() Clap(self) end)

    -- Come on y'all
    -- Check it out y'all

    -- How low can you go
    -- Can you go down low
    -- All the way to the floor
    -- How low can you go
    timer.Create("ChaChaSlide112", 288 * beatLength, 1, function() Crouch(self, 16) end)
    -- Can you bring it to the top
    -- Like you never never stop
    -- Can you bring it to the top
    timer.Create("ChaChaSlide113", 304 * beatLength, 1, function() Grow(self, 12) end)
    -- One hop
    timer.Create("ChaChaSlide114", 316 * beatLength, 1, function() Hop(self) end)
    -- Right foot not
    timer.Create("ChaChaSlide115", 320 * beatLength, 1, function() Right(self, 0.25) end)
    -- Left foot now y'all
    timer.Create("ChaChaSlide116", 324 * beatLength, 1, function() Left(self, 0.25) end)
    -- Cha cha real smooth
    timer.Create("ChaChaSlide117", 328 * beatLength, 1, function() Dance(self) end)

    -- Turn it out

    -- To the left
    timer.Create("ChaChaSlide118", 340 * beatLength, 1, function() Left(self, 2) end)
    -- Take it back now y'all
    timer.Create("ChaChaSlide119", 344 * beatLength, 1, function() Back(self, 2) end)
    -- One hop this time
    timer.Create("ChaChaSlide120", 348 * beatLength, 1, function() Hop(self) end)
    -- One hop this time
    timer.Create("ChaChaSlide121", 352 * beatLength, 1, function() Hop(self) end)
    -- Reverse
    timer.Create("ChaChaSlide122", 356 * beatLength, 1, function() Reverse(self) end)
    -- Reverse
    timer.Create("ChaChaSlide123", 360 * beatLength, 1, function() Reverse(self) end)
    -- Slide to the left
    timer.Create("ChaChaSlide124", 364 * beatLength, 1, function() Left(self, 2) end)
    -- Slide to the right
    timer.Create("ChaChaSlide125", 368 * beatLength, 1, function() Right(self, 2) end)
    -- Reverse
    timer.Create("ChaChaSlide126", 372 * beatLength, 1, function() Reverse(self) end)
    -- Reverse
    timer.Create("ChaChaSlide127", 373 * beatLength, 1, function() Reverse(self) end)
    -- Reverse
    timer.Create("ChaChaSlide128", 376 * beatLength, 1, function() Reverse(self) end)
    -- Reverse
    timer.Create("ChaChaSlide129", 377 * beatLength, 1, function() Reverse(self) end)
    -- Cha cha now y'all
    -- Cha cha again
    -- Cha cha now y'all
    -- Cha cha again
    timer.Create("ChaChaSlide130", 380 * beatLength, 1, function() Dance(self) end)

    -- Turn it out

    -- To the left
    timer.Create("ChaChaSlide131", 400 * beatLength, 1, function() Left(self, 2) end)
    -- Take it back now y'all
    timer.Create("ChaChaSlide132", 404 * beatLength, 1, function() Back(self, 2) end)
    -- Two hops two hops
    timer.Create("ChaChaSlide133", 408 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide134", 409 * beatLength, 1, function() Hop(self) end)
    -- Two hops two hops
    timer.Create("ChaChaSlide135", 412 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide136", 413 * beatLength, 1, function() Hop(self) end)
    -- Right foot let's stomp
    timer.Create("ChaChaSlide137", 416 * beatLength, 1, function() Right(self, 0.25) end)
    -- Left foot let's stomp
    timer.Create("ChaChaSlide138", 420 * beatLength, 1, function() Left(self, 0.25) end)
    -- Charlie brown
    -- Hop it out
    timer.Create("ChaChaSlide139", 424 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide140", 425 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide141", 426 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide142", 427 * beatLength, 1, function() Hop(self) end)
    timer.Create("ChaChaSlide143", 428 * beatLength, 1, function() Hop(self) end)
    -- Slide to the right
    timer.Create("ChaChaSlide144", 432 * beatLength, 1, function() Right(self, 2) end)
    -- Slide to the left
    timer.Create("ChaChaSlide145", 436 * beatLength, 1, function() Left(self, 2) end)
    -- Take it back now y'all
    timer.Create("ChaChaSlide146", 440 * beatLength, 1, function() Back(self, 2) end)
    -- Cha cha now y'all
    timer.Create("ChaChaSlide147", 444 * beatLength, 1, function() Dance(self) end)
    -- Oh yeah
    -- Yeah yeah
    -- Do that stuff
    -- Oh yeah
    -- I'm outta here y'all
    -- Peace
    -- TODO: Wrap this behind a convar
    timer.Create("ChaChaSlide148", 475.2 * beatLength, 1, function() Kill(self) end)
end

function EVENT:End()
    for i = 1, 148 do
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

Randomat:register(EVENT)

if SERVER then resource.AddSingleFile("sound/chachaslide.wav") end