local net = net
local player = player
local timer = timer

local PlayerIterator = player.Iterator

local EVENT = {}
EVENT.id = "chachaslide"

local function SetGesture(gest, noDraw)
    for _, p in PlayerIterator() do
        if not p:Alive() or p:IsSpec() then continue end
        local activeWep = p:GetActiveWeapon()
        if IsValid(activeWep) then
            activeWep:SetNoDraw(noDraw)
        end
        p:AnimRestartGesture(GESTURE_SLOT_CUSTOM, gest, true)
    end
end

function EVENT:Begin()
    if GetConVar("randomat_chachaslide_music"):GetBool() then
        surface.PlaySound("chachaslide.mp3")
    end

    local showThirdperson = false
    net.Receive("RdmtChaChaSlideDance", function()
        local len = net.ReadUInt(5)
        SetGesture(ACT_GMOD_TAUNT_DANCE, true)

        showThirdperson = true
        timer.Create("RdmtChaChaSlideDanceEnd", len, 1, function()
            SetGesture(ACT_IDLE, false)
            showThirdperson = false
        end)
    end)

    self:AddHook("CalcView", function(ply, pos, angles, fov, znear, zfar, drawviewer, ortho)
        if not showThirdperson then return end
        if ply ~= LocalPlayer() then return end

        local dist = 130
        local ang = Angle(0, angles.y, angles.r) + Angle(0, 180, 0)
        local view = {
            drawviewer = true,
            origin = pos - (ang:Forward() * dist),
            angles = ang,
            fov = fov
        }

        local tr = util.TraceLine({
            start = pos,
            endpos = view.origin,
            filter = ply
        });
        local hitDist = tr.HitPos:Distance(pos)
        if hitDist < dist - 10 then
            dist = hitDist - 10
            view.origin = pos - (ang:Forward() * dist)
        end

        return view
    end)
end

function EVENT:End()
    RunConsoleCommand("stopsound")
    if timer.Exists("RdmtChaChaSlideDanceEnd") then
        timer.Remove("RdmtChaChaSlideDanceEnd")
        SetGesture(ACT_IDLE, false)
    end
end

Randomat:register(EVENT)