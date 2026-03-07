local ipairs = ipairs
local player = player
local table = table

local PlayerIterator = player.Iterator
local TableHasValue = table.HasValue
local TableInsert = table.insert

local EVENT = {}

EVENT.Title = "Just One More Thing..."
EVENT.AltTitle = "Columbo"
EVENT.Description = "...and I'll get out of your hair"
EVENT.ExtDescription = "The Detective can no longer take or deal damage, but Traitors win when all non-Detective Innocents are dead"
EVENT.id = "columbo"
EVENT.Categories = {"biased_traitor", "moderateimpact"}

CreateConVar("randomat_columbo_multiple_mode", 1, FCVAR_NONE, "How to handle there being multiple living detectives. 0 - Don't allow this event to run. 1 - Choose one randomly. 2 - Make them all Columbo", 0, 2)

local COLUMBO_MULTIPLE_MODE_DISALLOW = 0
local COLUMBO_MULTIPLE_MODE_RANDOM_ONE = 1
local COLUMBO_MULTIPLE_MODE_ALL = 2

function EVENT:BeforeEventTrigger(ply, options, ...)
    -- Update this in case the role names have been changed
    local description
    local multiple_mode = GetConVar("randomat_columbo_multiple_mode"):GetInt()
    if multiple_mode == COLUMBO_MULTIPLE_MODE_ALL then
        description = "The " .. Randomat:GetRolePluralString(ROLE_DETECTIVE)
    else
        description = "The " .. Randomat:GetRoleString(ROLE_DETECTIVE)
    end
    self.Description = description .. " can no longer take or deal damage, but " .. Randomat:GetRolePluralString(ROLE_TRAITOR) .. " win when all non-" .. Randomat:GetRoleString(ROLE_DETECTIVE) .. " " .. Randomat:GetRolePluralString(ROLE_INNOCENT) .. " are dead"
end

function EVENT:GetAliveDetectives()
    -- Find the first detective in a randomized list of alive players
    local detectives = {}
    for _, p in ipairs(self:GetAlivePlayers(true)) do
        if Randomat:IsDetectiveTeam(p) then
            TableInsert(detectives, p)
        end
    end

    if #detectives == 0 then return nil end

    local multiple_mode = GetConVar("randomat_columbo_multiple_mode"):GetInt()
    if multiple_mode == COLUMBO_MULTIPLE_MODE_DISALLOW then
        if #detectives > 1 then
            return nil
        end
    elseif multiple_mode == COLUMBO_MULTIPLE_MODE_RANDOM_ONE then
        return {detectives[1]}
    end

    return detectives
end

function EVENT:MakeColumbo(ply)
    timer.Simple(0.1, function()
        -- Set player model if it exists
        if file.Exists("models/columbo/columbo.mdl", "GAME") then
            if not ply.RdmtColumboModel then
                ply.RdmtColumboModel = ply:GetModel()
            end
            local SetMDL = FindMetaTable("Entity").SetModel
            SetMDL(ply, "models/columbo/columbo.mdl")
        end
        ply.RdmtIsColumbo = true
        local detectiveStr = string.lower(Randomat:GetRoleString(ROLE_DETECTIVE))
        Randomat:PrintMessage(ply, MSG_PRINTBOTH, "You are now Columbo, the shrewd and exceptionally observant homicide " .. detectiveStr)
        Randomat:PrintMessage(ply, MSG_PRINTBOTH, "You cannot take or deal damage and must instead use your " .. detectiveStr.. " skills to help your team prevail")
    end)
end

function EVENT:Begin()
    local detectives = self:GetAliveDetectives()
    for _, detective in ipairs(detectives) do
        self:MakeColumbo(detective)
    end

    -- Columbo cannot take or deal damage
    self:AddHook("EntityTakeDamage", function(target, dmginfo)
        if IsPlayer(target) and target.RdmtIsColumbo then return true end

        local att = dmginfo:GetAttacker()
        if IsPlayer(att) and att.RdmtIsColumbo then return true end
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
                elseif v:IsInnocentTeam() and not v.RdmtIsColumbo then
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

function EVENT:End()
    local SetMDL = FindMetaTable("Entity").SetModel
    for _, p in PlayerIterator() do
        if p.RdmtColumboModel then
            SetMDL(p, p.RdmtColumboModel)
            p.RdmtColumboModel = nil
        end
        p.RdmtIsColumbo = nil
    end
end

function EVENT:Condition()
    local detectives = self:GetAliveDetectives()
    if not detectives then return false end

    -- Explicitly ban any role that we know requires killing everyone but isn't independent
    local banned_roles = {ROLE_DRUNK, ROLE_CLOWN, ROLE_DETECTOCLOWN}
    for _, p in PlayerIterator() do
        local role = p:GetRole()
        if TableHasValue(banned_roles, p) then return false end

        -- Independent roles that don't have passive wins and Monsters (e.g. anyone who needs to kill all players)
        -- are blocked because they can't win with the invincible Columbo around
        if MONSTER_ROLES[role] or (INDEPENDENT_ROLES[role] and not ROLE_HAS_PASSIVE_WIN[role]) then
            return false
        end
    end

    return true
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"multiple_mode"}) do
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