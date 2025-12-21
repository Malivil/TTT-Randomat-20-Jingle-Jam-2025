local ipairs = ipairs
local player = player
local table = table

local PlayerIterator = player.Iterator
local TableHasValue = table.HasValue

local EVENT = {}

EVENT.Title = "Just One More Thing..."
EVENT.AltTitle = "Columbo"
EVENT.Description = "...and I'll get out of your hair"
EVENT.ExtDescription = "The detective can no longer take or deal damage, but traitors win when all non-detective innocents are dead"
EVENT.id = "columbo"
EVENT.Categories = {"biased_traitor", "moderateimpact"}

function EVENT:GetAliveDetective()
    -- Find the first detective in a randomized list of alive players
    for _, p in ipairs(self:GetAlivePlayers(true)) do
        if Randomat:IsDetectiveTeam(p) then
            return p
        end
    end
end

function EVENT:Begin()
    local columbo = self:GetAliveDetective()

    timer.Simple(0.1, function()
        Randomat:PrintMessage(columbo, MSG_PRINTBOTH, "You are now Columbo, the shrewd and exceptionally observant homicide detective")
        Randomat:PrintMessage(columbo, MSG_PRINTBOTH, "You cannot take or deal damage and must instead use your detective skills to help your team prevail")
    end)

    -- Columbo cannot take or deal damage
    self:AddHook("EntityTakeDamage", function(target, dmginfo)
        if IsPlayer(target) and target == columbo then return true end

        local att = dmginfo:GetAttacker()
        if IsPlayer(att) and att == columbo then return true end
    end)

    -- Nearly identical from the base hook, just with the columbo exclusion
    self:AddHook("TTTCheckForWin", function()
        local traitor_alive = false
        local innocent_alive = false
        local monster_alive = false

        for _, v in PlayerIterator() do
            if v:IsActive() then
                if v:IsTraitorTeam() then
                    traitor_alive = true
                elseif v:IsMonsterTeam() then
                    monster_alive = true
                -- Columbo is essentially passive for win checks
                elseif v:IsInnocentTeam() and v ~= columbo then
                    innocent_alive = true
                end
            end
        end

        if traitor_alive and innocent_alive then
            return WIN_NONE --early out
        end

        -- If everyone is dead the traitors win
        if not innocent_alive and not monster_alive then
            return WIN_TRAITOR
        -- If all the "bad" people are dead, innocents win
        elseif not traitor_alive and not monster_alive then
            return WIN_INNOCENT
        -- If the monsters are the only ones left, they win
        elseif not innocent_alive and not traitor_alive then
            return WIN_MONSTER
        end

        return WIN_NONE
    end)
end

function EVENT:Condition()
    local detective = self:GetAliveDetective()
    if not IsPlayer(detective) then return false end

    -- Explicitly ban any role that we know requires killing everyone but isn't independent
    local banned_roles = {ROLE_CLOWN, ROLE_DETECTOCLOWN}
    for _, p in PlayerIterator() do
        local role = p:GetRole()
        if TableHasValue(banned_roles, p) then return false end

        -- Independent roles that don't have passive wins and Monsters (e.g. anyone who needs to kill all players)
        -- are blocked because they can't win with the invincible Columbo around
        if MONSTER_ROLES[role] or (INDEPENDENT_ROLES[role] and not ROLE_HAS_PASSIVE_WIN[role]) then
            return false
        end
    end
end

Randomat:register(EVENT)