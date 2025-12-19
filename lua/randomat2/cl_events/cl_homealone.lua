local EVENT = {}
EVENT.id = "homealone"

function EVENT:Initialize()
    timer.Simple(1, function()
        HOMEALONE:RegisterRole()
    end)
end

function EVENT:Begin()

    self:AddHook("TTTSprintStaminaPost", function()
        -- Infinite sprint through fixed infinite stamina
        return 100
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    self:AddHook("TTTScoringWinTitle", function(wintype, wintitle, title)
        if wintype == WIN_KEVIN then
            return { txt = "hilite_win_kevin", c = ROLE_COLORS[ROLE_KEVIN] }
        end
    end)

    ------------
    -- EVENTS --
    ------------

    self:AddHook("TTTEventFinishText", function(e)
        if e.win == WIN_KEVIN then
            return LANG.GetTranslation("ev_win_kevin")
        end
    end)

    self:AddHook("TTTEventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_KEVIN then
            return win_string, ROLE_STRINGS[ROLE_KEVIN]
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    -- Enable the tutorial page for this role when the event is running
    self:AddHook("TTTTutorialRoleEnabled", function(role)
        if role == ROLE_KEVIN and Randomat:IsEventActive("kevin") then
            return true
        end
    end)

    self:AddHook("TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_KEVIN then return end

        local roleColor = ROLE_COLORS[ROLE_KEVIN]
        return ROLE_STRINGS[ROLE_KEVIN] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose job is to survive against the Wet Bandits (every other player) by using their trap shop."
    end)

    ---------------
    -- TARGET ID --
    ---------------

    self:AddHook("TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
        if ply:IsActiveKevin() and ply:Alive() then
            return ROLE_KEVIN, false
        end
    end)

    self:AddHook("TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
        if IsPlayer(ent) and ent:IsActiveKevin() and ent:Alive() then
            return true, ROLE_COLORS_RADAR[ROLE_KEVIN]
        end
    end)

    self:AddHook("TTTTargetIDPlayerText", function(ent, cli, text, clr, secondaryText)
        if IsPlayer(ent) and ent:IsActiveKevin() and ent:Alive() then
            return StringUpper(ROLE_STRINGS[ROLE_KEVIN]), ROLE_COLORS_RADAR[ROLE_KEVIN]
        end
    end)

    ROLE_IS_TARGETID_OVERRIDDEN[ROLE_KEVIN] = function(ply, target)
        if not IsPlayer(target) then return end
        if not target:IsActiveKevin() or not target:Alive() then return end

        ------ icon, ring, text
        return true, true, true
    end

    ----------------
    -- SCOREBOARD --
    ----------------

    self:AddHook("TTTScoreboardPlayerRole", "Kevin_TTTScoreboardPlayerRole", function(ply, cli, color, roleFileName)
        if ply:IsKevin() then
            return ROLE_COLORS_SCOREBOARD[ROLE_KEVIN], ROLE_STRINGS_SHORT[ROLE_KEVIN]
        end
    end)

    ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_KEVIN] = function(ply, target)
        if not IsPlayer(target) then return end
        if not target:IsKevin() then return end

        ------ name,  role
        return false, true
    end
end

Randomat:register(EVENT)