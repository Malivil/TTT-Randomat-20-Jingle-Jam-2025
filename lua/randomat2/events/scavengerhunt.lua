local ents = ents
local ipairs = ipairs
local player = player
local string = string
local table = table
local timer = timer

local GetAllEnts = ents.GetAll
local PlayerIterator = player.Iterator
local StringStartsWith = string.StartsWith
local TableHasValue = table.HasValue
local TableInsert = table.insert
local TableRandom = table.Random

util.AddNetworkString("RdmtScavengerHuntProps")
util.AddNetworkString("RdmtScavengerHuntCollected")

local EVENT = {}

EVENT.Title = "Scavenger Hunt"
EVENT.Description = "Find the props scattered around the map, first to get them all wins!"
EVENT.id = "scavengerhunt"
EVENT.Categories = {"gamemode", "largeimpact"}

CreateConVar("randomat_scavengerhunt_count", 10, FCVAR_NONE, "The number of props a player has to find to win", 1, 25)

local function Collect(ply, ent, model)
    -- Sanity check
    if not SCAVENGER_HUNT:IsHuntTarget(ply, model) then return end

    if not ply.RdmtScavengerHuntCollected then
        ply.RdmtScavengerHuntCollected = {}
    end

    local name = SCAVENGER_HUNT:GetModelName(model)
    TableInsert(ply.RdmtScavengerHuntCollected, name)
    SafeRemoveEntity(ent)

    if #ply.RdmtScavengerHuntCollected == #ply.RdmtScavengerHuntTargets then
        -- TODO: Handle a player collecting everything
    end

    net.Start("RdmtScavengerHuntCollected")
        net.WriteString(model)
    net.Send(ply)
end

local function SetupEntity(ent)
    ent.RdmtScavengerHuntPossible = true
    ent.CanUseKey = true
    function ent:UseOverride(ply)
        if not IsValid(self) then return end
        if not IsPlayer(ply) then return end
        if not ply:Alive() or ply:IsSpec() then return end

        local entModel = self:GetModel()
        -- Sanity checks
        if not self.RdmtScavengerHuntPossible or not SCAVENGER_HUNT:IsPossibleModel(entModel) then
            self.CanUseKey = false
            self.UseOverride = nil
            return
        end

        if not SCAVENGER_HUNT:IsHuntTarget(ply, entModel) then return end
        if SCAVENGER_HUNT:IsCollected(ply, entModel) then return end

        Collect(ply, self, entModel)
    end
end

function EVENT:Begin()
    for _, ent in ipairs(GetAllEnts()) do
        local entClass = ent:GetClass()
        if not StringStartsWith(entClass, "prop_physics") and entClass ~= "prop_dynamic" then continue end

        -- Track this as a possible prop for later
        -- Doing it this way allows props already on the map to count as well, instead of just the ones we spawn
        if SCAVENGER_HUNT:IsPossibleModel(ent:GetModel()) then
            SetupEntity(ent)
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
                SetupEntity(ent)
            end
        end)
    end)

    local chosenProps = {}
    local count = GetConVar("randomat_scavengerhunt_count"):GetInt()
    -- Choose random props per alive player and send them to their client-side
    for _, p in ipairs(self:GetAlivePlayers()) do
        local props = {}
        while #props < count do
            local _, prop = TableRandom(SCAVENGER_HUNT.props)
            if not TableHasValue(props, prop) then
                TableInsert(props, prop)
                TableInsert(chosenProps, prop)
            end
        end
        p.RdmtScavengerHuntTargets = props
        net.Start("RdmtScavengerHuntProps")
            net.WriteTable(props, true)
        net.Send(p)
    end

    -- TODO: Spawn chosen props around the map
end

function EVENT:End()
    for _, p in PlayerIterator() do
        p.RdmtScavengerHuntTargets = nil
        p.RdmtScavengerHuntCollected = nil
    end
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"count"}) do
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