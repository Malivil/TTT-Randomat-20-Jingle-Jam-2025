local pairs = pairs
local table = table

local TableHasValue = table.HasValue
local TableInsert = table.insert

SCAVENGER_HUNT = {
    props = {
        ballon_dog = "models/balloons/balloon_dog.mdl",
        binder = { "models/props_lab/binderblue.mdl", "models/props_lab/binderbluelabel.mdl", "models/props_lab/bindergraylabel01a.mdl", "models/props_lab/bindergraylabel01b.mdl", "models/props_lab/bindergreen.mdl", "models/props_lab/bindergreenlabel.mdl", "models/props_lab/binderredlabel.mdl" },
        Bucket = "models/props_junk/metalgascan.mdl",
        burger = "models/food/burger.mdl",
        cash_register = "models/props_c17/cashregister01a.mdl",
        clipboard = "models/props_lab/clipboard.mdl",
        clock = "models/props_c17/clock01.mdl",
        crate = "models/props_junk/PlasticCrate01a.mdl",
        doll = "models/props_c17/doll01.mdl",
        gas = { "models/props_junk/gascan001a.mdl", "models/props_junk/metalgascan.mdl" },
        hot_dog = "models/food/hotdog.mdl",
        metal_can = { "models/props_junk/garbage_metalcan001a.mdl", "models/props_junk/garbage_metalcan002a.mdl", "models/props_junk/PopCan01a.mdl" },
        milk = { "models/props_junk/garbage_milkcarton001a.mdl", "models/props_junk/garbage_milkcarton002a.mdl" },
        paint = { "models/props_junk/metal_paintcan001a.mdl", "models/props_junk/metal_paintcan001b.mdl" },
        picture = "models/props_lab/frame002a.mdl",
        plastic_bottle = { "models/props_junk/garbage_milkcarton001a.mdl", "models/props_junk/garbage_plasticbottle001a.mdl", "models/props_junk/garbage_plasticbottle002a.mdl", "models/props_junk/garbage_plasticbottle003a.mdl" },
        plastic_jar = { "models/props_lab/jar01a.mdl", "models/props_lab/jar01b.mdl" },
        pot = "models/props_interiors/pot02a.mdl",
        receiver = { "models/props_lab/reciever01a.mdl", "models/props_lab/reciever01b.mdl", "models/props_lab/reciever01c.mdl", "models/props_lab/reciever01d.mdl" },
        shoe = "models/props_junk/Shoe001a.mdl",
        skull = "models/Gibs/HGIBS.mdl",
        teapot = "models/props_interiors/pot01a.mdl",
        top_hat = "models/player/items/humans/top_hat.mdl",
        traffic_cone = "models/props_junk/TrafficCone001a.mdl",
        wrench = "models/props_c17/tools_wrench01a.mdl"
    },
    models = {}
}

local function FlattenTableValues(src, dst)
    for _, m in pairs(src) do
        if type(m) == "table" then
            FlattenTableValues(m, dst)
        elseif not TableHasValue(dst, m) then
            TableInsert(dst, m)
        end
    end
end
FlattenTableValues(SCAVENGER_HUNT.props, SCAVENGER_HUNT.models)

function SCAVENGER_HUNT:IsPossibleModel(model)
    return TableHasValue(self.models, model)
end

function SCAVENGER_HUNT:GetModelName(model)
    for k, m in pairs(self.props) do
        if type(m) == "table" then
            if TableHasValue(m, model) then
                return k
            end
        elseif m == model then
            return k
        end
    end
end

function SCAVENGER_HUNT:IsHuntTarget(ply, model)
    if not ply.RdmtScavengerHuntTargets then return false end
    return TableHasValue(ply.RdmtScavengerHuntTargets, model)
end

function SCAVENGER_HUNT:IsCollected(ply, model)
    if not ply.RdmtScavengerHuntCollected then return false end
    return TableHasValue(ply.RdmtScavengerHuntCollected, model)
end

function SCAVENGER_HUNT:Collect(ply, ent, model)
    if not self:IsHuntTarget(ply, model) then return end

    if not ply.RdmtScavengerHuntCollected then
        ply.RdmtScavengerHuntCollected = {}
    end
    TableInsert(ply.RdmtScavengerHuntCollected, model)
    if SERVER then
        SafeRemoveEntity(ent)
    else
        Randomat:PrintMessage(ply, MSG_PRINTBOTH, "You collected the '" .. LANG.GetTranslation("scavengerhunt_prop_" .. self:GetModelName(model)) .. "'!")
    end
end