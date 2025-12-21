local ipairs = ipairs
local net = net
local player = player
local table = table
local timer = timer

local PlayerIterator = player.Iterator

util.AddNetworkString("RdmtHeatingUpMove")

local EVENT = {}

EVENT.Title = "Heating Up"
EVENT.Description = "Keep out of the rising lava or risk burns!"
EVENT.id = "heatingup"
EVENT.Categories = {"biased_traitor", "largeimpact"}

CreateConVar("randomat_heatingup_move_interval", 0.75, FCVAR_NONE, "How often the lava should move upwards", 0.1, 10)
CreateConVar("randomat_heatingup_move_amount", 0.25, FCVAR_NONE, "How much the lava should move upwards", 0.1, 10)
CreateConVar("randomat_heatingup_damage_interval", 1, FCVAR_NONE, "How often the lava should cause damage", 0.1, 10)
CreateConVar("randomat_heatingup_damage_amount", 1, FCVAR_NONE, "How much damage the lava should cause", 1, 10)

function EVENT:Begin()
    -- Find lowest weapon / ammo entity
    local lowestZ = nil
    for _, ent in ipairs(ents.FindByClass("item_*")) do
        local entPos = ent:GetPos()
        if not lowestZ or lowestZ > entPos.z then
            lowestZ = entPos.z
        end
    end
    for _, ent in ipairs(ents.FindByClass("weapon_*")) do
        local entPos = ent:GetPos()
        if not lowestZ or lowestZ > entPos.z then
            lowestZ = entPos.z
        end
    end
    -- and start slightly under that
    local lavaPos = Vector(0, 0, lowestZ - 5)

    -- Set timer for slowly moving the lava upward
    local move_interval = GetConVar("randomat_heatingup_move_interval")
    local move_amount = GetConVar("randomat_heatingup_move_amount")
    timer.Create("RdmtHeatingUpMoveTimer", move_interval:GetFloat(), 0, function()
        lavaPos.z = lavaPos.z + move_amount:GetFloat()
        net.Start("RdmtHeatingUpMove")
            net.WriteFloat(lavaPos.z)
        net.Broadcast()
    end)

    local damage_interval = GetConVar("randomat_heatingup_damage_interval")
    local damage_amount = GetConVar("randomat_heatingup_damage_amount")
    timer.Create("RdmtHeatingUpDamageTimer", damage_interval:GetFloat(), 0, function()
        local dmginfo = DamageInfo()
        dmginfo:SetDamage(damage_amount:GetInt())
        dmginfo:SetAttacker(game.GetWorld())
        dmginfo:SetInflictor(game.GetWorld())
        dmginfo:SetDamageType(DMG_BURN)
        dmginfo:SetDamagePosition(lavaPos)

        for _, p in PlayerIterator() do
            local playerPos = p:GetPos()
            if playerPos.z <= lavaPos.z then
                p:TakeDamageInfo(dmginfo)
            end
        end
    end)
end

function EVENT:End()
    timer.Remove("RdmtHeatingUpMoveTimer")
    timer.Remove("RdmtHeatingUpDamageTimer")
end

function EVENT:Condition()
    -- Find lowest and highest weapon / ammo entity
    local lowestZ = nil
    local highestZ = nil
    for _, ent in ipairs(ents.FindByClass("item_*")) do
        local entPos = ent:GetPos()
        if not lowestZ or lowestZ > entPos.z then
            lowestZ = entPos.z
        end

        if not highestZ or highestZ < entPos.z then
            highestZ = entPos.z
        end
    end
    for _, ent in ipairs(ents.FindByClass("weapon_*")) do
        local entPos = ent:GetPos()
        if not lowestZ or lowestZ > entPos.z then
            lowestZ = entPos.z
        end

        if not highestZ or highestZ < entPos.z then
            highestZ = entPos.z
        end
    end

    -- If there isn't enough difference in height, don't run this event on this map
    return (highestZ - lowestZ) >= 100
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"damage_amount"}) do
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
    for _, v in ipairs({"damage_interval", "move_interval", "move_amount"}) do
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