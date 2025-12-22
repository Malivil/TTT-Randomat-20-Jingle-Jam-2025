local EVENT = {}

EVENT.Title = "Scavenger Hunt"
EVENT.Description = ""
EVENT.id = "scavengerhunt"
EVENT.Categories = {"gamemode", "largeimpact"}

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

        SCAVENGER_HUNT:Collect(ply, self, entModel)
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

    -- TODO: Choose random props per alive player and send them to their client-side
    -- TODO: Spawn chosen props around the map
    -- TODO: Handle a player collecting everything
end

function EVENT:End()
    for _, p in PlayerIterator() do
        p.RdmtScavengerHuntTargets = nil
        p.RdmtScavengerHuntCollected = nil
    end
end

Randomat:register(EVENT)