local assets =
{
    Asset("ANIM", "anim/walrus_actions.zip"),
    Asset("ANIM", "anim/walrus_attacks.zip"),
    Asset("ANIM", "anim/walrus_basic.zip"),
    Asset("ANIM", "anim/walrus_build.zip"),
    Asset("ANIM", "anim/walrus_baby_build.zip"),
    Asset("SOUND", "sound/mctusky.fsb"),
}

local prefabs =
{
    "meat",
    "blowdart_walrus", -- creature weapon
    "blowdart_pipe",   -- player loot
    "walrushat",
    "walrus_tusk",
}

local brain = require "brains/wunnywalrusbrain"

SetSharedLootTable('walrus',
    {
        { 'meat',          1.00 },
        { 'blowdart_pipe', 1.00 },
        { 'walrushat',     0.25 },
        { 'walrus_tusk',   0.50 },
    })

SetSharedLootTable('walrus_wee_loot',
    {
        { 'meat', 1.0 },
    })

local SHARE_TARGET_DIST = 30
local MAX_TARGET_SHARES = 5

local function ShareTargetFn(dude)
    return dude:HasTag("walrus") and not dude.components.health:IsDead()
end


local function SuggestTreeTarget(inst, data)
    local ba = inst:GetBufferedAction()
    if data ~= nil and data.tree ~= nil and (ba == nil or ba.action ~= ACTIONS.CHOP) then
        inst.tree_target = data.tree
    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, ShareTargetFn, 5)
end

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "hound", "walrus" }
local RETARGET_ONEOF_TAGS = { "animal", "character", "monster" }
local function Retarget(inst)
    return nil
end

local function KeepTarget(inst, target)
    return inst:IsNear(target, TUNING.WALRUS_LOSETARGET_DIST)
end

local function DoReturn(inst)
    --print("DoReturn", inst)
    if inst.components.homeseeker and inst.components.homeseeker.home then
        inst.components.homeseeker.home:PushEvent("onwenthome", { doer = inst })
        inst:Remove()
    end
end

local function OnStopDay(inst)
    --print("OnStopDay", inst)
    if inst:IsAsleep() then
        DoReturn(inst)
    end
end

local function OnEntitySleep(inst)
    --print("OnEntitySleep", inst)
    if not TheWorld.state.isday then
        DoReturn(inst)
    end
end

local function ShouldSleep(inst)
    return not (inst.components.homeseeker and inst.components.homeseeker:HasHome()) and DefaultSleepTest(inst)
end

local function EquipBlowdart(inst)
    if inst.components.inventory and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local blowdart = CreateEntity()
        --[[Non-networked entity]]
        blowdart.entity:AddTransform()
        blowdart:AddComponent("weapon")
        blowdart:AddTag("sharp")
        blowdart.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        blowdart.components.weapon:SetRange(inst.components.combat.attackrange)
        blowdart.components.weapon:SetProjectile("blowdart_walrus")
        blowdart:AddComponent("inventoryitem")
        blowdart.persists = false
        blowdart.components.inventoryitem:SetOnDroppedFn(inst.Remove)
        blowdart:AddComponent("equippable")
        blowdart:AddTag("nosteal")

        inst.components.inventory:Equip(blowdart)
    end
end

local function OnSave(inst, data)
    data.flare_summoned = inst:HasTag("flare_summoned")
end

local function OnLoad(inst, data)
    if data then
        if data.flare_summoned then
            inst:AddTag("flare_summoned")
        end
    end
end

local function ShouldAcceptItem()
    return true
end

local function OnNewTarget(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST,
        function(dude) return dude.prefab == inst.prefab end, MAX_TARGET_SHARES)
end

local function OnGetItemFromPlayer(inst, giver, item)
    if inst.components.combat:TargetIs(giver) then
        inst.components.combat:SetTarget(nil)
    elseif giver.components.leader ~= nil then
        if giver.components.minigame_participator == nil then
            giver:PushEvent("makefriend")
            giver.components.leader:AddFollower(inst)
        end
        inst.components.follower:AddLoyaltyTime(
            giver:HasTag("polite")
            and TUNING.RABBIT_CARROT_LOYALTY + TUNING.RABBIT_POLITENESS_LOYALTY_BONUS
            or TUNING.RABBIT_CARROT_LOYALTY
        )
    end

    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function is_meat(item)
    -- return item.components.edible ~= nil and item.components.edible.foodtype == FOODTYPE.MEAT and not item:HasTag("smallcreature")
    return false
end

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_ONEOF_TAGS = { "monster", "player", "pirate" }
local function NormalRetargetFn(inst)
    return not inst:IsInLimbo()
        and FindEntity(
            inst,
            TUNING.PIG_TARGET_DIST,
            function(guy)
                return inst.components.combat:CanTarget(guy)
                    and
                    (
                    -- guy:HasTag("monster")--talvez tirando isso para de atacar spider
                    -- or
                    guy:HasTag("wonkey")
                    or guy:HasTag("pirate")
                    -- or (guy.components.inventory ~= nil and
                    --     guy:IsNear(inst, TUNING.BUNNYMAN_SEE_MEAT_DIST) and
                    --     guy.components.inventory:FindItem(is_meat) ~= nil)
                    -- or guy:HasTag("shadowcreature")
                    )
            end,
            RETARGET_MUST_TAGS, -- see entityreplica.lua
            nil,
            RETARGET_ONEOF_TAGS
        )
        or nil
end

local function create_common(build, scale, tag)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, .5)

    inst.DynamicShadow:SetSize(2.5, 1.5)
    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(scale, scale, scale)

    inst.AnimState:SetBank("walrus")
    inst.AnimState:SetBuild(build)
    --inst.AnimState:Hide("hat")

    inst:AddTag("character")
    inst:AddTag("pig")
    inst:AddTag("notraptrigger")
    -- inst:AddTag("walrus")
    -- inst:AddTag("houndfriend")
    if tag ~= nil then
        inst:AddTag(tag)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = 4
    inst.components.locomotor.walkspeed = 4

    inst:SetStateGraph("SGwalrus")
    inst.soundgroup = "mctusk"

    inst:SetBrain(brain)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(ShouldSleep)

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "pig_torso"
    inst.components.combat:SetRange(TUNING.WALRUS_ATTACK_DIST)
    inst.components.combat:SetDefaultDamage(TUNING.WALRUS_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.WALRUS_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, NormalRetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.WALRUS_HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('walrus')

    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.PIG_LOYALTY_MAXTIME

    --meu
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    -- inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader.deleteitemonaccept = false

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 24
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -500, 0)
    inst.components.talker:MakeChatter()

    inst:AddComponent("inventory")

    inst:AddComponent("inspectable")

    MakeMediumBurnableCharacter(inst, "pig_torso")
    MakeMediumFreezableCharacter(inst, "pig_torso")

    MakeHauntablePanic(inst)

    -- inst:AddComponent("leader")

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    inst:ListenForEvent("suggest_tree_target", SuggestTreeTarget)


    inst:WatchWorldState("stopday", OnStopDay)

    inst.OnEntitySleep = OnEntitySleep

    inst:DoTaskInTime(0.8, EquipBlowdart)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function create_normal()
    return create_common("walrus_build", 1.5)
end

return Prefab("wunnywalrus", create_normal, assets, prefabs)
