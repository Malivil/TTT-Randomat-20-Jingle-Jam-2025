local player = player

local PlayerIterator = player.Iterator

local EVENT = {}

local kevin_scale = CreateConVar("randomat_homealone_scale", 0.75, FCVAR_NONE, "The scale factor to use for Kevin", 0.5, 1)

EVENT.Title = "Home Alone"
EVENT.Description = "It's Kevin vs. the Wet Bandits in a deadly version of the beloved movie"
EVENT.id = "homealone"
EVENT.Categories = {"rolechange", "largeimpact"}

local defaultJumpPower = 160

function EVENT:Initialize()
    timer.Simple(1, function()
        HOMEALONE:RegisterRole()
    end)
end

function EVENT:Begin()
    local kevin_scale_val = kevin_scale:GetFloat()
    local innocents = {}
    local special = nil
    local indep = nil
    -- Collect the innocents to potentially turn into kevin
    for _, p in ipairs(self:GetAlivePlayers(true)) do
        if Randomat:IsInnocentTeam(p) and not Randomat:IsDetectiveTeam(p) then
            if p:GetRole() ~= ROLE_INNOCENT and special == nil then
                special = p
            end
            table.insert(innocents, p)
        elseif Randomat:IsIndependentTeam(p) then
            indep = p
        end
    end

    -- If we don't have a special innocent, choose a random player
    if special == nil then
        special = innocents[math.random(1, #innocents)]
    end

    -- Default kevin to the independent player, but if there isn't one then use the chosen innocent instead
    local kevin = indep
    if not IsValid(kevin) then
        kevin = special
    end

    local kevin_health = GetConVar("ttt_kevin_max_health"):GetInt()
    local max_hp = kevin:GetMaxHealth()
    Randomat:SetRole(kevin, ROLE_KEVIN, false)
    kevin:SetMaxHealth(kevin_health)
    kevin:SetHealth(kevin_health - (max_hp - kevin:Health()))
    self:StripRoleWeapons(kevin)

    Randomat:SetPlayerScale(kevin, kevin_scale_val, self.id)

    local jumpPower = defaultJumpPower
    -- Compensate the jump power of smaller players so they have roughly the same jump height as normal
    -- In testing, scales >= 1 all seem to work fine with the default jump power and that's not the intent of this role anyway
    if kevin_scale_val < 1 then
        -- Derived formula is y = -120x + 280
        -- We take the base jump power out of this as a known constant and then
        -- give a small jump boost of 5 extra power to "round up" the jump estimates
        -- so that smaller sizes can still clear jump+crouch blocks
        jumpPower = jumpPower + (-(120 * kevin_scale_val) + 125)
    end
    kevin:SetJumpPower(jumpPower)

    kevin:QueueMessage(MSG_PRINTBOTH, "You are Kevin! Use your trap shop to defend yourself against the Wet Bandits!")
    SendFullStateUpdate()

    self:AddHook("TTTPrintResultMessage", function(win_type)
        if win_type == WIN_KEVIN then
            LANG.Msg("win_kevin")
            ServerLog("Result: Kevin wins.\n")
            return true
        end
    end)

    self:AddHook("TTTCheckForWin", function()
        local kevin_alive = false
        local other_alive = false
        for _, p in ipairs(self:GetAlivePlayers()) do
            if p:IsActive() then
                if p:IsKevin() then
                    kevin_alive = true
                elseif not p:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[p:GetRole()] then
                    other_alive = true
                end
            end
        end

        if kevin_alive and not other_alive then
            return WIN_KEVIN
        elseif kevin_alive then
            return WIN_NONE
        end
    end)
end

function EVENT:End()
    self:ResetAllPlayerScales()
    for _, p in PlayerIterator() do
        p:SetJumpPower(defaultJumpPower)
    end
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"scale"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 1
            })
        end
    end
    return sliders
end

Randomat:register(EVENT)