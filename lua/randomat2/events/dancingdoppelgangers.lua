local ents = ents
local math = math
local table = table

local CreateEnt = ents.Create
local EntsFindByClass = ents.FindByClass
local MathRandom = math.random
local TableInsert = table.insert

util.AddNetworkString("RdmtDancingDoppelgangersCreated")

local EVENT = {}

EVENT.Title = "Dancing Doppelgangers"
EVENT.Description = ""
EVENT.id = "dancingdoppelgangers"
EVENT.Categories = {}

CreateConVar("randomat_dancingdoppelgangers_count", 1, FCVAR_NONE, "How many clones should be spawned for each player", 1, 5)

local function CreateClone(ply, pos, ang)
    local clone = CreateEnt("ttt_randomat_jj2025_clone")
    clone:SetPos(pos)
    clone:SetAngles(ang)
    clone:SetModel(ply:GetModel())
    clone:SetSkin(ply:GetSkin())
    for _, value in pairs(ply:GetBodyGroups()) do
        clone:SetBodygroup(value.id, ply:GetBodygroup(value.id))
    end
    clone:SetColor(ply:GetColor())
    clone:Spawn()
    clone:Activate()

    timer.Simple(0.1, function()
        net.Start("RdmtDancingDoppelgangersCreated")
            net.WriteEntity(clone)
            net.WriteString(ply:Nick())
        net.Broadcast()
    end)

    local attachment
    local lookup = clone:LookupAttachment("anim_attachment_RH")
    if lookup == 0 then
        attachment = { Pos = clone:GetPos() + clone:OBBCenter() + Vector(0, 0, 5), Ang = clone:GetForward():Angle() + Angle(20, 0, 0) }
    else
        attachment = clone:GetAttachment(lookup)
    end

    clone.FakeWep = ents.Create("base_anim") -- Create the Fake weapon
    clone.FakeWep:SetOwner(clone)
    clone.FakeWep:AddEffects(EF_BONEMERGE)
    clone.FakeWep:SetMoveType(MOVETYPE_NONE)
    clone.FakeWep:SetPos(attachment.Pos)
    clone.FakeWep:SetAngles(attachment.Ang)
    clone.FakeWep:SetParent(clone)
    clone.FakeWep:SetModel("models/weapons/w_crowbar.mdl")
end

function EVENT:Begin()
    local count = GetConVar("randomat_dancingdoppelgangers_count"):GetInt()
    local spawnEnts = GetSpawnEnts(true)
    for _, p in ipairs(self:GetAlivePlayers()) do
        for i=1, count do
            -- Get a random spawn position
            local pos = spawnEnts[MathRandom(#spawnEnts)]:GetPos()
            pos = FindRespawnLocation(pos) or pos
            local ang = p:GetAngles()
            CreateClone(p, pos, ang)
        end
    end
end

function EVENT:End()
    for _, e in ipairs(EntsFindByClass("ttt_randomat_jj2025_clone")) do
        if not IsValid(e) then continue end
        e:Remove()
    end
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"count"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            TableInsert(sliders, {
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