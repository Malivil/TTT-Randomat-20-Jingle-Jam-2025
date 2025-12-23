local ents = ents
local player = player
local string = string
local timer = timer

local GetAllEnts = ents.GetAll
local PlayerIterator = player.Iterator
local StringStartsWith = string.StartsWith

local EVENT = {}

EVENT.id = "scavengerhunt"

local function HandleEntityHint(ent)
    if not IsValid(ent) then return end

    local entModel = ent:GetModel()
    -- Sanity checks
    if not ent.RdmtScavengerHuntPossible or not SCAVENGER_HUNT:IsPossibleModel(entModel) then
        ent.TargetIDHint = nil
        return
    end

    local client = LocalPlayer()
    if not IsPlayer(client) then return end
    if not client:Alive() or client:IsSpec() then return end
    if not SCAVENGER_HUNT:IsHuntTarget(client, entModel) then return end

    if SCAVENGER_HUNT:IsCollected(client, entModel) then
        return { hint = "scavengerhunt_hint_duplicate", }
    end

    return
    {
        hint = "scavengerhunt_hint_collect",
        fmt = function(e, lbl)
            return LANG.GetParamTranslation(lbl, { usekey = Key("+use", "USE") })
        end
    }
end

function EVENT:Begin()
    LANG.AddToLanguage("english", "scavengerhunt_hint_collect", "Press '{usekey}' to collect")
    LANG.AddToLanguage("english", "scavengerhunt_hint_duplicate", "You already have this")
    LANG.AddToLanguage("english", "scavengerhunt_prop_ballon_dog", "Ballon Dog")
    LANG.AddToLanguage("english", "scavengerhunt_prop_binder", "Binder")
    LANG.AddToLanguage("english", "scavengerhunt_prop_bucket", "Bucket")
    LANG.AddToLanguage("english", "scavengerhunt_prop_burger", "Burger")
    LANG.AddToLanguage("english", "scavengerhunt_prop_cash_register", "Cash Register")
    LANG.AddToLanguage("english", "scavengerhunt_prop_clipboard", "Clipboard")
    LANG.AddToLanguage("english", "scavengerhunt_prop_clock", "Wall Clock")
    LANG.AddToLanguage("english", "scavengerhunt_prop_crate", "Plastic Crate")
    LANG.AddToLanguage("english", "scavengerhunt_prop_doll", "Doll")
    LANG.AddToLanguage("english", "scavengerhunt_prop_gas", "Gas Can")
    LANG.AddToLanguage("english", "scavengerhunt_prop_hot_dog", "Hot Dog")
    LANG.AddToLanguage("english", "scavengerhunt_prop_metal_can", "Metal Can")
    LANG.AddToLanguage("english", "scavengerhunt_prop_milk", "Milk Carton")
    LANG.AddToLanguage("english", "scavengerhunt_prop_paint", "Paint Can")
    LANG.AddToLanguage("english", "scavengerhunt_prop_picture", "Picture in Frame")
    LANG.AddToLanguage("english", "scavengerhunt_prop_plastic_bottle", "Plastic Bottle")
    LANG.AddToLanguage("english", "scavengerhunt_prop_plastic_jar", "Plastic Jar")
    LANG.AddToLanguage("english", "scavengerhunt_prop_pot", "Pot")
    LANG.AddToLanguage("english", "scavengerhunt_prop_receiver", "Audio Receiver")
    LANG.AddToLanguage("english", "scavengerhunt_prop_shoe", "Shoe")
    LANG.AddToLanguage("english", "scavengerhunt_prop_skull", "Skull")
    LANG.AddToLanguage("english", "scavengerhunt_prop_teapot", "Teapot")
    LANG.AddToLanguage("english", "scavengerhunt_prop_top_hat", "Top Hat")
    LANG.AddToLanguage("english", "scavengerhunt_prop_traffic_cone", "Traffic Cone")
    LANG.AddToLanguage("english", "scavengerhunt_prop_wrench", "Wrench")

    for _, ent in ipairs(GetAllEnts()) do
        local entClass = ent:GetClass()
        if not StringStartsWith(entClass, "prop_physics") and entClass ~= "prop_dynamic" then continue end

        -- Track this as a possible prop for later
        -- Doing it this way allows props already on the map to count as well, instead of just the ones we spawn
        if SCAVENGER_HUNT:IsPossibleModel(ent:GetModel()) then
            ent.RdmtScavengerHuntPossible = true
            ent.TargetIDHint = HandleEntityHint
        end
    end

    self:AddHook("OnEntityCreated", function(ent)
        local entClass = ent:GetClass()
        if not StringStartsWith(entClass, "prop_physics") and entClass ~= "prop_dynamic" then return end

        -- Delay this because model is not yet set
        timer.Simple(0.25, function()
            if not IsValid(ent) then return end

            -- Track this as a possible prop for later
            -- Doing it this way allows props spawned by the map to count as well, instead of just the ones we spawn
            if SCAVENGER_HUNT:IsPossibleModel(ent:GetModel()) then
                ent.RdmtScavengerHuntPossible = true
                ent.TargetIDHint = HandleEntityHint
            end
        end)
    end)

    -- TODO: Checklist of props to find
end

function EVENT:End()
    for _, p in PlayerIterator() do
        p.RdmtScavengerHuntTargets = nil
        p.RdmtScavengerHuntCollected = nil
    end
end

Randomat:register(EVENT)