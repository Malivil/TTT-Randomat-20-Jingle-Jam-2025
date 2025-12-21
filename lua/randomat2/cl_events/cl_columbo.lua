local surface = surface

local EVENT = {}

EVENT.id = "columbo"

local columbo_sound = "columbo.mp3"
function EVENT:Begin()
    surface.PlaySound(columbo_sound)
end

Randomat:register(EVENT)