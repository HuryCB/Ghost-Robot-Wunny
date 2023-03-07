return {
    RoyalUpgrade = function(inst)
        if inst.components.health:IsDead() then
            return
        end

        inst.components.health:SetMaxHealth(TUNING.MERM_HEALTH_KINGBONUS)
        inst.components.combat:SetDefaultDamage(TUNING.MERM_DAMAGE_KINGBONUS)
        inst.Transform:SetScale(1.05, 1.05, 1.05)
    end
}
