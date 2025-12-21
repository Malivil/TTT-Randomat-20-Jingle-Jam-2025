local ipairs = ipairs
local math = math
local table = table
local timer = timer

local MathRound = math.Round
local TableConcat = table.concat
local TableHasValue = table.HasValue
local TableInsert = table.insert
local TableRandom = table.Random

local EVENT = {}

EVENT.Title = "Cha-Cha Slide"
EVENT.Description = "Press the movement buttons in the order given before time runs out OR DIE!"
EVENT.id = "chachaslide"
EVENT.Categories = {"gamemode", "largeimpact"}

CreateConVar("randomat_chachaslide_timer", 15, FCVAR_NONE, "The amount of time players have to press each sequence", 5, 60)

local startingLength = 4
local currentLength = nil
local buttons = {
    ↑ = IN_FORWARD,
    ↓ = IN_BACK,
    ← = IN_MOVELEFT,
    → = IN_MOVERIGHT,
    CROUCH = IN_DUCK,
    JUMP = IN_JUMP
}

function EVENT:ChooseSequence(first, quiz_time)
    local chosen = {}
    local chosenText = {}

    for i=1, currentLength do
        local key, value = TableRandom(buttons)
        TableInsert(chosen, key)
        TableInsert(chosenText, value)
    end

    -- Let everyone know what the sequence is
    local message = "The " .. (first and "first" or "next") .. " sequence is: " .. TableConcat(chosenText, " ")
    local time = MathRound(quiz_time * 0.66)
    self:SmallNotify(message, time)

    currentLength = currentLength + 1

    return chosen
end

function EVENT:BeforeEventTrigger(ply, options, ...)
    local time = GetConVar("randomat_chachaslide_timer"):GetInt()
    local description = "Press the movement buttons in the order given within " .. time .. " seconds OR DIE!"
    self.Description = description
end

function EVENT:Begin()
    local safe = {}
    local plySequence = {}
    local chosen = nil

    currentLength = startingLength

    self:AddHook("KeyPress", function(ply, key)
        if not chosen then return end
        if not IsValid(ply) or ply:IsSpec() then return end

        local sid64 = ply:SteamID64()
        if safe[sid64] then return end

        -- If they pressed one of the right keys, add it to the sequence
        if TableHasValue(chosen, key) then
            if not plySequence[sid64] then
                plySequence[sid64] = {}
            end
            TableInsert(plySequence[sid64], key)
        -- If they pressed the wrong key, clear their sequence and stop checking
        else
            plySequence[sid64] = {}
            return
        end

        -- If we got this far, we know only the right keys have been pressed
        local plySequenceLength = #plySequence[sid64]
        local chosenLength = #chosen
        if plySequenceLength <= chosenLength then
            -- Time to check the order of them
            for i=1, plySequenceLength do
                -- If they got one wrong, reset the sequence so they have to start again
                if plySequence[sid64][i] ~= chosen[i] then
                    plySequence[sid64] = {}
                    return
                end
            end
        -- If they've pressed too many keys and haven't already completed the sequence (somehow), they messed up, reset them
        else
            plySequence[sid64] = {}
            return
        end

        local sequenceMatches = plySequenceLength == chosenLength
        if sequenceMatches then
            ply:PrintMessage(HUD_PRINTTALK, "You're safe!")
            Randomat:Notify("You're safe!", nil, ply)
            safe[sid64] = true
        end
    end)

    local time = GetConVar("randomat_chachaslide_timer"):GetInt()
    timer.Create("RdmtTypeRacerDelay", time, 1, function()
        chosen = self:ChooseSequence(true, time)

        timer.Create("RdmtTypeRacerTimer", time, 1, function()
            -- Kill everyone who hasn't answered the prompt correctly yet
            for _, p in ipairs(self:GetAlivePlayers()) do
                if not safe[p:SteamID64()] then
                    p:PrintMessage(HUD_PRINTTALK, "Time's up!")
                    Randomat:Notify("Time's up!", nil, p)
                    p:Kill()
                end
            end

            table.Empty(safe)
            chosen = self:ChooseSequence(false, time)
        end)
    end)
end

function EVENT:End()
    timer.Remove("RdmtChaChaSlideDelay")
    timer.Remove("RdmtChaChaSlideTimer")
end

-- "Secret" causes this event to essentially just kill everyone, since they can't see the prompts
function EVENT:Condition()
    return not Randomat:IsEventActive("secret")
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"timer"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
            })
        end
    end
    return sliders
end

Randomat:register(EVENT)