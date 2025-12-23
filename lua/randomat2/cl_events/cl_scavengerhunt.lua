local draw = draw
local ents = ents
local player = player
local string = string
local surface = surface
local table = table
local timer = timer

local DrawRoundedBox = draw.RoundedBox
local GetAllEnts = ents.GetAll
local PlayerIterator = player.Iterator
local StringStartsWith = string.StartsWith
local StringUpper = string.upper
local SurfaceDrawText = surface.DrawText
local SurfaceGetTextSize = surface.GetTextSize
local SurfaceSetFont = surface.SetFont
local SurfaceSetTextColor = surface.SetTextColor
local SurfaceSetTextPos = surface.SetTextPos
local TableHasValue = table.HasValue
local TableInsert = table.insert

local EVENT = {}

EVENT.id = "scavengerhunt"

surface.CreateFont("RdmtScavengerHuntTitle", {
    font = "Tahoma",
    size = 22,
    weight = 750,
    underline = true
})
surface.CreateFont("RdmtScavengerHuntList", {
    font = "Tahoma",
    size = 18,
    weight = 750
})
surface.CreateFont("RdmtScavengerHuntListComplete", {
    font = "Tahoma",
    size = 18,
    weight = 750,
    italic = true
})

net.Receive("RdmtScavengerHuntProps", function()
    local client = LocalPlayer()
    if not IsPlayer(client) then return end

    local props = net.ReadTable(true)
    client.RdmtScavengerHuntTargets = props
end)

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
        return { hint = "scavengerhunt_hint_duplicate" }
    end

    return
    {
        hint = "scavengerhunt_hint_collect",
        fmt = function(e, lbl)
            return LANG.GetParamTranslation(lbl, { usekey = Key("+use", "USE") })
        end
    }
end

local function GetWinner()
    for _, p in PlayerIterator() do
        if p:GetNWBool("RdmtScavengerHuntWinner", false) then
            return p
        end
    end
end

function EVENT:Begin()
    LANG.AddToLanguage("english", "hilite_win_scavenger_hunt", "{name} WINS")
    LANG.AddToLanguage("english", "win_scavenger_hunt", "{name} won the scavenger hunt!")
    LANG.AddToLanguage("english", "ev_win_scavenger_hunt", "{name} won the scavenger hunt!")
    LANG.AddToLanguage("english", "scavengerhunt_title", "Scavenger Hunt")
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

    ----------------
    -- WIN CHECKS --
    ----------------

    self:AddHook("TTTScoringWinTitle", function(wintype, wintitle, title)
        local winner = GetWinner()
        if not IsPlayer(winner) then return end

        return { txt = "hilite_win_scavenger_hunt", params = { name =  StringUpper(winner:Nick()) }, c = ROLE_COLORS[winner:GetRole()] }
    end)

    ------------
    -- EVENTS --
    ------------

    self:AddHook("TTTEventFinishText", function(e)
        local winner = GetWinner()
        if not IsPlayer(winner) then return end

        return LANG.GetParamTranslation("ev_win_scavenger_hunt", { name = winner:Nick() })
    end)

    self:AddHook("TTTEventFinishIconText", function(e, win_string, role_string)
        local winner = GetWinner()
        if not IsPlayer(winner) then return end

        return win_string, winner:Nick()
    end)

    -----------------
    -- EVENT LOGIC --
    -----------------

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

    local client = LocalPlayer()

    net.Receive("RdmtScavengerHuntCollected", function()
        if not IsPlayer(client) then return end

        local model = net.ReadString()

        -- Sanity check
        if not SCAVENGER_HUNT:IsHuntTarget(client, model) then return end

        if not client.RdmtScavengerHuntCollected then
            client.RdmtScavengerHuntCollected = {}
        end

        local name = SCAVENGER_HUNT:GetModelName(model)
        TableInsert(client.RdmtScavengerHuntCollected, name)
        Randomat:PrintMessage(client, MSG_PRINTBOTH, "You collected the '" .. LANG.GetTranslation("scavengerhunt_prop_" .. name) .. "'!")
    end)

    -- Checklist of props to find
    self:AddHook("HUDPaint", function()
        if not IsPlayer(client) then return end
        if not client.RdmtScavengerHuntTargets then return end
        if not client:Alive() or client:IsSpec() then return end

        local lineHeight = 20
        local margin = 8
        local height = (#client.RdmtScavengerHuntTargets * lineHeight) + (margin * 3)
        local topPos = (ScrH() / 2) - (height / 2)
        local leftPos = margin

        -- Calculate title size so we know how big to make the background
        local text = LANG.GetTranslation("scavengerhunt_title")
        SurfaceSetFont("RdmtScavengerHuntTitle")
        local width, titleHeight = SurfaceGetTextSize(text)

        -- Background
        width = width + (margin * 2)
        DrawRoundedBox(8, leftPos, topPos, width, height + titleHeight, Color(0, 0, 10, 200))

        -- Title
        SurfaceSetTextColor(COLOR_WHITE)
        SurfaceSetTextPos(leftPos + margin, topPos + margin)
        SurfaceDrawText(text)

        -- Lines
        for i, p in ipairs(client.RdmtScavengerHuntTargets) do
            if client.RdmtScavengerHuntCollected and TableHasValue(client.RdmtScavengerHuntCollected, p) then
                SurfaceSetTextColor(COLOR_GREEN)
                SurfaceSetFont("RdmtScavengerHuntListComplete")
            else
                SurfaceSetTextColor(COLOR_WHITE)
                SurfaceSetFont("RdmtScavengerHuntList")
            end
            SurfaceSetTextPos(leftPos + margin, topPos + margin + titleHeight + margin + ((i - 1) * lineHeight))

            text = LANG.GetTranslation("scavengerhunt_prop_" .. p)
            SurfaceDrawText(text)
        end
    end)
end

function EVENT:End()
    for _, p in PlayerIterator() do
        p.RdmtScavengerHuntTargets = nil
        p.RdmtScavengerHuntCollected = nil
    end
end

Randomat:register(EVENT)