local net = net
local render = render

local EVENT = {}

EVENT.id = "heatingup"

local lavaMaterial = Material("heatingup.png", "nocull")
local lavaColor = Color(255, 100, 0, 175)
local lavaPos = Vector(0, 0, 0)
local vecNormal = Vector(0, 0, 1)

local lavaColorModifyTable = {
    ["$pp_colour_addr"] = 255 / 255 * 0.5,
    ["$pp_colour_addg"] = 100 / 255 * 0.5,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0,
    ["$pp_colour_contrast"] = 1,
    ["$pp_colour_colour"] = 1,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}

function EVENT:Begin()
    net.Receive("RdmtHeatingUpMove", function()
        lavaPos.z = net.ReadFloat()
    end)

    self:AddHook("PostDrawTranslucentRenderables", function(depth, skybox)
        render.SetMaterial(lavaMaterial)
        render.DrawQuadEasy(lavaPos, vecNormal, 10000, 10000, lavaColor)
    end)

    self:AddHook("RenderScreenspaceEffects", function()
        local client = LocalPlayer()
        if not IsPlayer(client) then return end
        if not client:Alive() then return end

        local playerPos = client:EyePos()
        if playerPos.z <= lavaPos.z then
            DrawColorModify(lavaColorModifyTable)
        end
    end)
end

Randomat:register(EVENT)