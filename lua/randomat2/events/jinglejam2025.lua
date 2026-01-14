local ents = ents
local ipairs = ipairs
local table = table

local CreateEntity = ents.Create
local EntsFindByClass = ents.FindByClass
local EntsIterator = ents.Iterator

local EVENT = {}

EVENT.Title = "Jingle Jam 2025"
EVENT.Description = "All ammo on the map has disappeared! Try jamming trash in your gun to reload instead..."
EVENT.id = "jinglejam2025"
EVENT.Categories = {"largeimpact", "entityspawn"}

local propModels =
{
    -- Containers
    "models/props_interiors/pot01a.mdl",
    "models/props_interiors/pot02a.mdl",
    "models/props_junk/PopCan01a.mdl",
    "models/props_junk/metal_paintcan001a.mdl",
    "models/props_junk/MetalBucket01a.mdl",
    -- Food
    "models/food/burger.mdl",
    "models/food/hotdog.mdl",
    "models/props/de_inferno/goldfish.mdl",
    "models/props_junk/watermelon01.mdl",
    -- Office
    "models/props_lab/binderblue.mdl",
    "models/props_lab/binderbluelabel.mdl",
    "models/props_lab/bindergraylabel01a.mdl",
    "models/props_lab/bindergreen.mdl",
    "models/props_lab/bindergraylabel01b.mdl",
    "models/props_lab/bindergreenlabel.mdl",
    "models/props_lab/binderredlabel.mdl",
    -- Garbage
    "models/props_junk/garbage_bag001a.mdl",
    "models/props_junk/garbage_coffeemug001a.mdl",
    "models/props_junk/garbage_glassbottle001a.mdl",
    "models/props_junk/garbage_glassbottle003a.mdl",
    "models/props_junk/garbage_metalcan001a.mdl",
    "models/props_junk/garbage_metalcan002a.mdl",
    "models/props_junk/garbage_milkcarton001a.mdl",
    "models/props_junk/garbage_milkcarton002a.mdl",
    "models/props_junk/garbage_newspaper001a.mdl",
    "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_plasticbottle002a.mdl",
    "models/props_junk/garbage_plasticbottle003a.mdl",
    "models/props_junk/garbage_takeoutcarton001a.mdl",
    "models/props_junk/GlassBottle01a.mdl",
    "models/props_junk/glassjug01.mdl",
    "models/props_junk/Shoe001a.mdl",
    "models/props_lab/box01a.mdl",
    "models/props_lab/box01b.mdl",
    "models/props_trainstation/payphone_reciever001a.mdl",
    "models/props_lab/jar01b.mdl"
}

function EVENT:Begin()
    -- Randomize the model list to reduce clustering
    table.Shuffle(propModels)

    local modelIndex = 1
    for _, e in EntsIterator() do
        if not IsValid(e) then continue end
        -- Remove everyone's spare ammo
        if IsPlayer(e) then
            if e:Alive() and not e:IsSpec() then
                e:RemoveAllAmmo()
            end
            continue
        end
        if e.Base ~= "base_ammo_ttt" then continue end

        -- Replace all the ammo entities with a random custom prop
        local propModel = propModels[modelIndex]
        local entPos = e:GetPos()
        local entAngles = e:GetAngles()
        e:Remove()

        local prop = CreateEntity("randomat_jj2025_ammo")
        prop:SetModel(propModel)
        prop:SetPos(entPos)
        prop:SetAngles(entAngles)
        prop:Spawn()

        -- Iterate through each model so there is roughly an equal usage of each
        modelIndex = modelIndex + 1
        if modelIndex > #propModels then
            modelIndex = 1
        end
    end

    -- Intercept "R" key and see if they are looking at an ammo entity and reload to 1 full clip (NO EXTRA AMMO)
    self:AddHook("KeyPress", function(ply, key)
        if key ~= IN_RELOAD then return end
        if not IsPlayer(ply) then return end
        if not ply:Alive() or ply:IsSpec() then return end
        if not ply.GetActiveWeapon then return end

        local weap = ply:GetActiveWeapon()
        if not IsValid(weap) then return end
        -- Make sure we have a weapon that has ammo and has the methods to set it
        if not weap.Primary or not weap.Primary.ClipSize then return end
        if not weap.Primary.Ammo or weap.Primary.Ammo == "none" then return end
        if not weap.Clip1 or not weap.SetClip1 then return end

        local current = weap:Clip1()
        if current >= weap.Primary.ClipSize then return end

        local tr = ply:GetEyeTrace()
        local target = tr.Entity
        if not IsValid(target) then return end
        if target:GetClass() ~= "randomat_jj2025_ammo" then return end

        target:Remove()

        ply:GiveAmmo(weap.Primary.ClipSize - current, weap.Primary.Ammo)
        weap:Reload()
    end)

    -- Remove spare ammo from new weapons
    self:AddHook("WeaponEquip", function(weap, owner)
        -- Delay a tick so any equipped ammo has time to transfer before we clear it
        timer.Simple(0, function()
            if IsPlayer(owner) then
                owner:RemoveAllAmmo()
            end
        end)
    end)
end

function EVENT:End()
    for _, e in ipairs(EntsFindByClass("randomat_jj2025_ammo")) do
        if not IsValid(e) then continue end

        local entPos = e:GetPos()
        local entAngles = e:GetAngles()
        e:Remove()

        local prop = CreateEntity("ttt_random_ammo")
        prop:SetPos(entPos)
        prop:SetAngles(entAngles)
        prop:Spawn()
    end
end

Randomat:register(EVENT)