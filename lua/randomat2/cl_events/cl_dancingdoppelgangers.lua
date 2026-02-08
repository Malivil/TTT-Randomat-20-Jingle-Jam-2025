local net = net
local util = util

local EVENT = {}

EVENT.id = "dancingdoppelgangers"

function EVENT:Begin()
    net.Receive("RdmtDancingDoppelgangersCreated", function()
        local ent = net.ReadEntity()
        if not IsValid(ent) then return end

        local name = net.ReadString()
        ent.TargetIDHint = {
            entname = name,
            name = EVENT.id,
            hint = EVENT.id
        }
    end)

    self:AddHook("TTTTargetIDEntityHintLabel", function(ent, cli, text, col)
        if text == EVENT.id then
            local healthText, healthCol = util.HealthToString(1, 1)
            return LANG.GetTranslation(healthText), healthCol
        end
    end)

    self:AddHook("TTTTargetIDPlayerHintText", function(ent, cli, text, col)
        if not KARMA.IsEnabled() then return end

        if text == EVENT.id then
            local karmaText, karmaCol = util.KarmaToString(1000)
            return LANG.GetTranslation(karmaText), karmaCol
        end
    end)
end

Randomat:register(EVENT)