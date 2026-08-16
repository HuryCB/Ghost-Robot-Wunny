return {
    RoyalUpgrade = function(inst)
        if inst.components.health:IsDead() then
            return
        end
        if inst:HasTag("hasKing")
        then
            return
        end

        if not TheWorld:HasTag("hasbunnyking")
        then
            return
        end

        local current_health = inst.health_percent or inst.components.health:GetPercent()
        inst.health_percent = nil

        inst.components.health:SetMaxHealth(inst.components.health.maxhealth + 260)

        inst.components.health:SetPercent(current_health)

        inst.components.combat.externaldamagemultipliers:SetModifier("royalUpgrade", 1.4)
        inst:AddTag("hasKing")
        -- inst.Transform:SetScale(1.05, 1.05, 1.05)
    end,
    RoyalDowngrade = function(inst)
        if inst.components.health:IsDead() then
            return
        end

        if not inst:HasTag("hasKing")
        then
            return
        end
        inst:RemoveTag("hasKing")

        local current_health = inst.health_percent or inst.components.health:GetPercent()
        inst.health_percent = nil

        inst.components.health:SetMaxHealth(inst.components.health.maxhealth - 260)

        inst.components.health:SetPercent(current_health)

        inst.components.combat.externaldamagemultipliers:SetModifier("royalUpgrade", 1)
        inst.components.combat.externaldamagemultipliers:RemoveModifier("royalUpgrade")
        -- inst.Transform:SetScale(1.05, 1.05, 1.05)
    end,
    OnPickup = function(inst)

    end,
    PickUpRabbit = function(inst)
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.nobounce = true
        inst.components.inventoryitem.canbepickedup = false
        inst.components.inventoryitem.canbepickedupalive = true
        inst.components.inventoryitem:SetSinks(true)
        inst.components.inventoryitem.imagename = "bunny"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/bunny.xml"
        MakeFeedableSmallLivestock(inst, 9000000, nil, nil)
        -- inst:ListenForEvent("onpickup", function()
        --     local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        --     if item then
        --         inst.components.inventory:DropItem(item)
        --     end

        --     local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
        --     if item then
        --         inst.components.inventory:DropItem(item)
        --     end

        --     local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
        --     if item then
        --         inst.components.inventory:DropItem(item)
        --     end

        --     local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        --     if item then
        --         inst.components.inventory:DropItem(item)
        --     end
        -- end)
    end,
    --260 vida cada
    --20 atk cada
}
