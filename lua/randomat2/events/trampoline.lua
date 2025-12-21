local player = player

local PlayerIterator = player.Iterator

local EVENT = {}

CreateConVar("randomat_trampoline_stomp", 1, FCVAR_NONE, "Whether to allow stomp damage during the event", 0, 1)
CreateConVar("randomat_trampoline_radius", 100, FCVAR_NONE, "The radius around a landing player to launch others", 1, 100)
CreateConVar("randomat_trampoline_min_speed", 200, FCVAR_NONE, "The minimum fall speed a player must land with to launch others", 1, 100)

EVENT.Title = "Trampoline"
EVENT.Description = "Hitting the ground near other players causes them to launch into the air"
EVENT.id = "trampoline"
EVENT.Categories = {"fun", "moderateimpact"}

function EVENT:Begin()
    for _, ply in pairs(self:GetAlivePlayers()) do
        Randomat:RemovePhdFlopper(ply)
    end

    local trampoline_stomp = GetConVar("randomat_trampoline_stomp")
    self:AddHook("EntityTakeDamage", function(ent, dmginfo)
        if not IsPlayer(ent) then return end

        local att = dmginfo:GetAttacker()
        -- Disable goomba stomping other players (if convar says so)
        if not trampoline_stomp:GetBool() and IsPlayer(att) and dmginfo:IsDamageType(DMG_CRUSH) then
            dmginfo:SetDamage(0)
        end
    end)

    local trampoline_radius = GetConVar("randomat_trampoline_radius")
    local trampoline_min_speed = GetConVar("randomat_trampoline_min_speed")
    self:AddHook("OnPlayerHitGround", function(ply, in_water, on_floater, speed)
        if in_water or on_floater then return end
        if speed < trampoline_min_speed:GetInt() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsOnGround() then return end

        local underEnt = ply:GetGroundEntity()
        if IsPlayer(underEnt) then return end
        if underEnt:IsNPC() or underEnt:IsNextBot() then return end

        local plyPos = ply:GetPos()
        local radius = trampoline_radius:GetInt()
        local radiusSqr = radius * radius
        local launchVector = Vector(0, 0, speed)
        for _, p in PlayerIterator() do
            if p == ply then continue end

            if p:GetPos():DistToSqr(plyPos) <= radiusSqr then
                p:SetGroundEntity(nil)
                p:SetVelocity(launchVector)
            end
        end
    end)

    self:AddHook("TTTCanOrderEquipment", function(ply, id, is_item)
        if not IsValid(ply) then return end
        if id == "hoff_perk_phd" or (is_item and is_item == EQUIP_PHD) then
            ply:ChatPrint("PHD Floppers are disabled while '" .. Randomat:GetEventTitle(EVENT) .. "' is active!\nYour purchase has been refunded.")
            return false
        end
    end)
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"min_speed", "radius"}) do
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

    local checks = {}
    for _, v in ipairs({"stomp"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end
    return sliders, checks
end

Randomat:register(EVENT)