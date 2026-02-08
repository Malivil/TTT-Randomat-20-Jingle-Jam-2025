if SERVER then
    AddCSLuaFile()
end

ENT.Type = "anim"

function ENT:Initialize()
    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
    end
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    if SERVER then
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end

    if CLIENT then
        local GetPTranslation = LANG.GetParamTranslation
        LANG.AddToLanguage("english", "rdmt_jinglejam2025_name", "\"Ammunition\"")
        LANG.AddToLanguage("english", "rdmt_jinglejam2025_hint", "Press '{reloadkey}' to jam it in your gun as ammo")
        self.TargetIDHint = function()
            return {
                name = "rdmt_jinglejam2025_name",
                hint = "rdmt_jinglejam2025_hint",
                fmt  = function(ent, txt)
                    return GetPTranslation(txt, { reloadkey = Key("+reload", "R") } )
                end
            };
        end
    end
end