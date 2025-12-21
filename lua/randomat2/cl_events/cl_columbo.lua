local net = net
local surface = surface

local columbo_sound = "columbo.mp3"
net.Receive("RdmtColumboBegin", function()
    surface.PlaySound(columbo_sound)
end)