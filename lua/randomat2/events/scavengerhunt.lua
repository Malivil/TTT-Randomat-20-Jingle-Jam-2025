local ents = ents
local ipairs = ipairs
local player = player
local string = string
local table = table
local timer = timer

local CreateEntity = ents.Create
local EntsFindByClass = ents.FindByClass
local GetAllEnts = ents.GetAll
local PlayerIterator = player.Iterator
local StringStartsWith = string.StartsWith
local TableAdd = table.Add
local TableCopy = table.Copy
local TableHasValue = table.HasValue
local TableInsert = table.insert
local TableRandom = table.Random
local TableRemove = table.remove

util.AddNetworkString("RdmtScavengerHuntProps")
util.AddNetworkString("RdmtScavengerHuntCollected")

local EVENT = {}

EVENT.Title = "Scavenger Hunt"
EVENT.Description = "Find the props scattered around the map, first to get them all wins!"
EVENT.id = "scavengerhunt"
EVENT.Categories = {"gamemode", "largeimpact"}

CreateConVar("randomat_scavengerhunt_count", 10, FCVAR_NONE, "The number of props a player has to find to win", 1, 25)

local winnerFound = nil
local function Collect(ply, ent, model)
    if winnerFound then return end

    -- Sanity check
    if not SCAVENGER_HUNT:IsHuntTarget(ply, model) then return end

    if not ply.RdmtScavengerHuntCollected then
        ply.RdmtScavengerHuntCollected = {}
    end

    local name = SCAVENGER_HUNT:GetModelName(model)
    TableInsert(ply.RdmtScavengerHuntCollected, name)
    SafeRemoveEntity(ent)

    -- Handle a player collecting everything
    if #ply.RdmtScavengerHuntCollected == #ply.RdmtScavengerHuntTargets then
        winnerFound = ply
        ply:SetNWBool("RdmtScavengerHuntWinner", true)

        -- Stop the win checks so someone else doesn't steal this player's win
        StopWinChecks()
        -- Delay the actual end for a second so the state has a chance to propagate
        timer.Simple(1, function() EndRound(WIN_INNOCENT) end)
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
    winnerFound = nil

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

    self:AddHook("TTTPrintResultMessage", function(win_type)
        if not winnerFound then return end

        LANG.Msg("win_scavenger_hunt", { name = winnerFound:Nick() })
        ServerLog("Result: " .. winnerFound:Nick() .. " wins.\n")
        return true
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

    local entsPos = {}
    for _, ent in ipairs(EntsFindByClass("item_*")) do
        if IsValid(ent:GetParent()) then continue end
        TableInsert(entsPos, ent:GetPos())
    end
    for _, ent in ipairs(EntsFindByClass("weapon_*")) do
        if IsValid(ent:GetParent()) then continue end
        TableInsert(entsPos, ent:GetPos())
    end

    -- Make sure we have enough positions
    while #entsPos < #chosenProps do
        TableAdd(entsPos, TableCopy(entsPos))
    end

    -- Spawn chosen props around the map
    for _, p in ipairs(chosenProps) do
        local model = SCAVENGER_HUNT.props[p]
        if type(model) == "table" then
            model = TableRandom(model)
        end

        local prop = CreateEntity("prop_physics")
        prop:SetModel(model)
        prop:PhysicsInit(SOLID_VPHYSICS)
        prop:SetModelScale(1)
        local pos, posKey = TableRandom(entsPos)
        TableRemove(entsPos, posKey)
        -- Bump it up a bit to avoid overlapping, just in case
        pos.z = pos.z + 15
        prop:SetPos(FindRespawnLocation(pos) or pos)
        prop:Spawn()
        prop:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)

        local phys = prop:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end
end

function EVENT:End()
    for _, p in PlayerIterator() do
        p.RdmtScavengerHuntTargets = nil
        p.RdmtScavengerHuntCollected = nil
        p:SetNWBool("RdmtScavengerHuntWinner", false)
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