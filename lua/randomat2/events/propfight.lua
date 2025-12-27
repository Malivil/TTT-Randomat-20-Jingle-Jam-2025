local ents = ents
local ipairs = ipairs
local player = player
local table = table

local CreateEntity = ents.Create
local EntsFindByClass = ents.FindByClass
local PlayerIterator = player.Iterator
local TableAdd = table.Add
local TableCopy = table.Copy
local TableInsert = table.insert
local TableRandom = table.Random
local TableRemove = table.remove

local EVENT = {}

EVENT.Title = "Prop Fight"
EVENT.Description = "The only way to damage other players is by throwing props... PROP FIGHT!"
EVENT.id = "propfight"
EVENT.Categories = {"gamemode", "largeimpact"}

CreateConVar("randomat_propfight_count", 10, FCVAR_NONE, "The number of props to spawn around the map", 1, 25)
CreateConVar("randomat_propfight_damage_mult", 1, FCVAR_NONE, "The damage multiplier for prop damage (1 = 1x = 100%, 1.25 = 1.25x = 125%)", 1, 5)
CreateConVar("randomat_propfight_damage_min", 15, FCVAR_NONE, "The minimum damage a prop impact can do", 1, 50)
CreateConVar("randomat_propfight_weight_mult", 10, FCVAR_NONE, "The multiplier to use on the magneto-stick's maximum carry weight", 1, 50)

local props = {
    "models/chairs/armchair.mdl",
    "models/nova/airboat_seat.mdl",
    "models/nova/chair_office02.mdl",
    "models/nova/jalopy_seat.mdl",
    "models/nova/jeep_seat.mdl",
    "models/props_c17/canister_propane01a.mdl",
    "models/props_c17/cashregister01a.mdl",
    "models/props_c17/chair_kleiner03a.mdl",
    "models/props_c17/FurnitureSink001a.mdl",
    "models/props_c17/gravestone002a.mdl",
    "models/props_c17/gravestone003a.mdl",
    "models/props_c17/TrapPropeller_Engine.mdl",
    "models/props_c17/tv_monitor01.mdl",
    "models/props_combine/breenglobe.mdl",
    "models/props_fortifications/fueldrum.mdl",
    "models/props_interiors/SinkKitchen01a.mdl",
    "models/props_junk/CinderBlock01a.mdl",
    "models/props_junk/TrashBin01a.mdl",
    "models/props_lab/monitor01a.mdl",
    "models/props_lab/monitor01b.mdl",
    "models/props_lab/monitor02.mdl",
    "models/props_wasteland/controlroom_filecabinet002a.mdl",
    "models/props_wasteland/laundry_dryer002.mdl",
    "models/props_wasteland/prison_heater001a.mdl",
    "models/props_wasteland/prison_shelf002a.mdl",
    "models/props_wasteland/wheel01.mdl"
}

local weightLimit = nil
function EVENT:Begin()
    local count = GetConVar("randomat_propfight_count"):GetInt()
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
    while #entsPos < count do
        TableAdd(entsPos, TableCopy(entsPos))
    end

    -- Spawn props around the map
    for i=0, count do
        local model = TableRandom(props)
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

    local traitors = 0
    local innocents = 0
    local others = {}
    for _, p in PlayerIterator() do
        if Randomat:IsInnocentTeam(p) then
            innocents = innocents + 1
        elseif Randomat:IsTraitorTeam(p) then
            traitors = traitors + 1
        else
            TableInsert(others, p)
        end
    end

    -- Convert all players to vanilla roles and replace all their weapons with the rifle
    local new_traitors = {}
    local updated = false
    for _, p in PlayerIterator() do
        if Randomat:IsInnocentTeam(p) then
            if p:GetRole() ~= ROLE_INNOCENT then
                Randomat:SetRole(p, ROLE_INNOCENT)
                updated = true
            end
        elseif Randomat:IsTraitorTeam(p) then
            if p:GetRole() ~= ROLE_TRAITOR then
                Randomat:SetRole(p, ROLE_TRAITOR)
                updated = true
            end
        else
            -- Keep the teams mostly even by moving any members of other teams to whichever has fewer members
            if innocents > traitors then
                Randomat:SetRole(p, ROLE_TRAITOR)
                TableInsert(new_traitors, p)
                traitors = traitors + 1
            else
                Randomat:SetRole(p, ROLE_INNOCENT)
                innocents = innocents + 1
            end
            updated = true
        end

        if p:Alive() and not p:IsSpec() then
            p:StripWeapons()
            p:Give("weapon_zm_carry")
        end
    end

    if updated then
        SendFullStateUpdate()
    end

    self:NotifyTeamChange(new_traitors, ROLE_TEAM_TRAITOR)

    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        return WEPS.GetClass(wep) == "weapon_zm_carry"
    end)

    self:AddHook("TTTCanOrderEquipment", function(ply, id, is_item)
        if not IsValid(ply) then return end
        if not is_item then
            ply:ChatPrint("You can only buy passive items during '" .. Randomat:GetEventTitle(EVENT) .. "'!\nYour purchase has been refunded.")
            return false
        end
    end)

    local damage_mult = GetConVar("randomat_propfight_damage_mult"):GetFloat()
    local damage_min = GetConVar("randomat_propfight_damage_min"):GetInt()
    self:AddHook("EntityTakeDamage", function(target, dmginfo)
        if not IsPlayer(target) then return end
        -- Non-crush damage is blocked so only prop throws can hurt
        if not dmginfo:IsDamageType(DMG_CRUSH) then return true end

        local att = dmginfo:GetAttacker()
        if not IsPlayer(att) then return end

        local infl = dmginfo:GetInflictor()
        -- No inflictor means no prop which means no damage
        if not IsValid(infl) then return true end

        dmginfo:ScaleDamage(damage_mult)
        local damage = dmginfo:GetDamage()
        if damage < damage_min then
            dmginfo:SetDamage(damage_min)
        end

        -- Multiply all damage by 4 after applying previous scaling and minimum because
        -- TTT base damage handling multiplies prop damage by 0.25 after all this is done
        dmginfo:ScaleDamage(4)
    end)

    if not weightLimit then
        weightLimit = CARRY_WEIGHT_LIMIT
        CARRY_WEIGHT_LIMIT = CARRY_WEIGHT_LIMIT * GetConVar("randomat_propfight_weight_mult"):GetFloat()
    end
end

function EVENT:End()
    if not weightLimit then return end
    CARRY_WEIGHT_LIMIT = weightLimit or 45
end

function EVENT:Condition()
    for _, p in PlayerIterator() do
        if Randomat:ShouldActLikeJester(p) then return false end
    end
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"count", "damage_min", "weight_mult"}) do
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
    for _, v in ipairs({"damage_mult"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 2
            })
        end
    end
    return sliders
end

Randomat:register(EVENT)