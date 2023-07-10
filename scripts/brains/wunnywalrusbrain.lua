require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/follow"
require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/leash"
local BrainCommon = require("brains/braincommon")

local RUN_START_DIST = 5
local RUN_STOP_DIST = 15

local SEE_FOOD_DIST = 10
local MAX_WANDER_DIST = 40
local MAX_CHASE_TIME = 10

local MIN_FOLLOW_DIST = 8
local MAX_FOLLOW_DIST = 15
local TARGET_FOLLOW_DIST = (MAX_FOLLOW_DIST + MIN_FOLLOW_DIST) / 2
local MAX_PLAYER_STALK_DISTANCE = 40

local LEASH_RETURN_DIST = 40
local LEASH_MAX_DIST = 80

local MIN_FOLLOW_LEADER = 2
local MAX_FOLLOW_LEADER = 4
local TARGET_FOLLOW_LEADER = (MAX_FOLLOW_LEADER + MIN_FOLLOW_LEADER) / 2

local START_FACE_DIST = MAX_FOLLOW_DIST
local KEEP_FACE_DIST = MAX_FOLLOW_DIST


local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 5
local MAX_FOLLOW_DIST = 9
local MAX_WANDER_DIST = 20

local LEASH_RETURN_DIST = 10
local LEASH_MAX_DIST = 30

local START_FACE_DIST = 6
local KEEP_FACE_DIST = 8
local START_RUN_DIST = 3
local STOP_RUN_DIST = 30
local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30
local SEE_LIGHT_DIST = 20
local TRADE_DIST = 20
local SEE_TREE_DIST = 15
local SEE_TARGET_DIST = 20
local SEE_FOOD_DIST = 10

local SEE_BURNING_HOME_DIST_SQ = 20 * 20

local KEEP_CHOPPING_DIST = 10

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 15
local SEE_PLAYER_DIST = 6

local GETTRADER_MUST_TAGS = { "player" }
local FINDFOOD_CANT_TAGS = { "outofreach" }

local CHOP_MUST_TAGS = { "CHOP_workable" }

local function IsDeciduousTreeMonster(guy)
    return guy.monster and guy.prefab == "deciduoustree"
end

local function FindDeciduousTreeMonster(inst)
    return FindEntity(inst, SEE_TREE_DIST / 3, IsDeciduousTreeMonster, CHOP_MUST_TAGS)
end

local function KeepChoppingAction(inst)
    return inst.tree_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, KEEP_CHOPPING_DIST))
        or FindDeciduousTreeMonster(inst) ~= nil
end

local function StartChoppingCondition(inst)
    return inst.tree_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst.components.follower.leader.sg ~= nil and
            inst.components.follower.leader.sg:HasStateTag("chopping"))
        or FindDeciduousTreeMonster(inst) ~= nil
end

local function FindTreeToChopAction(inst)
    local target = FindEntity(inst, SEE_TREE_DIST, nil, CHOP_MUST_TAGS)
    if target ~= nil then
        if inst.tree_target ~= nil then
            target = inst.tree_target
            inst.tree_target = nil
        else
            target = FindDeciduousTreeMonster(inst) or target
        end
        return BufferedAction(inst, target, ACTIONS.CHOP)
    end
end

function FindEntity(inst, radius, fn, musttags, canttags, mustoneoftags)
    if inst ~= nil and inst:IsValid() then
        local x, y, z = inst.Transform:GetWorldPosition()
        --print("FIND", inst, radius, musttags and #musttags or 0, canttags and #canttags or 0, mustoneoftags and #mustoneoftags or 0)
        local ents = TheSim:FindEntities(x, y, z, radius, musttags, canttags, mustoneoftags) -- or we could include a flag to the search?
        for i, v in ipairs(ents) do
            if v ~= inst and v.entity:IsVisible() and (fn == nil or fn(v, inst)) then
                return v
            end
        end
    end
end

------MINING-----

local function KeepMiningAction(inst)
    return inst.tree_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, KEEP_CHOPPING_DIST))
        or FindDeciduousTreeMonster(inst) ~= nil
end

local function StartMiningCondition(inst)
    return inst.tree_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst.components.follower.leader.sg ~= nil and
            inst.components.follower.leader.sg:HasStateTag("mining"))
        or FindDeciduousTreeMonster(inst) ~= nil
end

local function FindRockToMineAction(inst)
    local target = FindEntity(inst, SEE_TREE_DIST, nil, { "MINE_workable" })
    if target ~= nil then
        if inst.tree_target ~= nil then
            target = inst.tree_target
            inst.tree_target = nil
        else
            target = FindDeciduousTreeMonster(inst) or target
        end
        return BufferedAction(inst, target, ACTIONS.MINE)
    end
end

------END MINING-----

local function GetTraderFn(inst)
    return FindEntity(inst, TRADE_DIST, function(target) return inst.components.trader:IsTryingToTradeWithMe(target) end
    , GETTRADER_MUST_TAGS)
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end

local function FindFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    local target =
        inst.components.inventory ~= nil and
        inst.components.eater ~= nil and
        inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end) or
        nil

    if target == nil then
        local time_since_eat = inst.components.eater:TimeSinceLastEating()
        if time_since_eat == nil or time_since_eat > TUNING.PIG_MIN_POOP_PERIOD * 2 then
            local noveggie = time_since_eat ~= nil and time_since_eat < TUNING.PIG_MIN_POOP_PERIOD * 4
            target = FindEntity(inst,
                SEE_FOOD_DIST,
                function(item)
                    return item:GetTimeAlive() >= 8
                        and item.prefab ~= "mandrake"
                        and item.components.edible ~= nil
                        and (not noveggie or item.components.edible.foodtype == FOODTYPE.MEAT)
                        and inst.components.eater:CanEat(item)
                        and item:IsOnPassablePoint()
                end,
                nil,
                FINDFOOD_CANT_TAGS
            )
        end
    end

    return target ~= nil and BufferedAction(inst, target, ACTIONS.EAT) or nil
end

local function HasValidHome(inst)
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    return home ~= nil
        and home:IsValid()
        and not (home.components.burnable ~= nil and home.components.burnable:IsBurning())
        and not home:HasTag("burnt")
end

local function GoHomeAction(inst)
    if not inst.components.follower.leader and
        HasValidHome(inst) and
        not inst.components.combat.target then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

local function IsHomeOnFire(inst)
    return inst.components.homeseeker
        and inst.components.homeseeker.home
        and inst.components.homeseeker.home.components.burnable
        and inst.components.homeseeker.home.components.burnable:IsBurning()
        and inst:GetDistanceSqToInst(inst.components.homeseeker.home) < SEE_BURNING_HOME_DIST_SQ
end

local function GetNoLeaderLeashPos(inst)
    if not inst:HasTag("flare_summoned") then
        return GetLeader(inst) == nil and GetHomeLocation(inst) or nil
    end
end

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetHomePos(inst)
    return HasValidHome(inst) and inst.components.homeseeker:GetHomePos()
end

local function GetNoLeaderHomePos(inst)
    if GetLeader(inst) then
        return nil
    end
    return GetHomePos(inst)
end

local function CanAttackNow(inst)
    return inst.components.combat.target == nil or not inst.components.combat:InCooldown()
end


local RUN_START_DIST = 5
local RUN_STOP_DIST = 15

local SEE_FOOD_DIST = 10
local MAX_WANDER_DIST = 40
local MAX_CHASE_TIME = 10

local MIN_FOLLOW_DIST = 8
local MAX_FOLLOW_DIST = 15
local TARGET_FOLLOW_DIST = (MAX_FOLLOW_DIST+MIN_FOLLOW_DIST)/2
local MAX_PLAYER_STALK_DISTANCE = 40

local LEASH_RETURN_DIST = 40
local LEASH_MAX_DIST = 80

local MIN_FOLLOW_LEADER = 2
local MAX_FOLLOW_LEADER = 4
local TARGET_FOLLOW_LEADER = (MAX_FOLLOW_LEADER+MIN_FOLLOW_LEADER)/2

local START_FACE_DIST = MAX_FOLLOW_DIST
local KEEP_FACE_DIST = MAX_FOLLOW_DIST

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

local function GetLeader(inst)
    return inst.components.follower ~= nil and inst.components.follower.leader or nil
end

local function GetNoLeaderFollowTarget(inst)
    return GetLeader(inst) == nil
        and FindClosestPlayerToInst(inst, MAX_PLAYER_STALK_DISTANCE, true)
        or nil
end

local function GetHome(inst)
    return inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
end

local function ShouldRunAway(guy)
    return not (guy:HasTag("walrus") or
                guy:HasTag("hound") or
                guy:HasTag("notarget"))
        and (guy:HasTag("character") or
            guy:HasTag("monster"))
end

local EATFOOD_MUST_TAGS = { "edible_MEAT" }
local CHARACTER_TAGS = {"character"}
local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, nil, EATFOOD_MUST_TAGS)
    --check for scary things near the food, or if it's in the water
    if target ~= nil and (not target:IsOnValidGround() or GetClosestInstWithTag(CHARACTER_TAGS, target, RUN_START_DIST) ~= nil) then
        target = nil
    end
    if target ~= nil then
        local act = BufferedAction(inst, target, ACTIONS.EAT)
        act.validfn = function() return target.components.inventoryitem == nil or target.components.inventoryitem.owner == nil or target.components.inventoryitem.owner == inst end
        return act
    end
end

local function ShouldGoHomeAtNight(inst)
    return TheWorld.state.isnight
        and GetLeader(inst) == nil
        and GetHome(inst) ~= nil
        and inst.components.combat.target == nil
end

local function ShouldGoHomeScared(inst)
    if not inst:HasTag("taunt_attack") or inst.components.leader:CountFollowers() ~= 0 then
        return false
    end
    local leader = GetLeader(inst)
    return leader == nil or not leader:IsValid()
end

local function GoHomeAction(inst)
    local home = GetHome(inst)
    return home ~= nil
        and home:IsValid()
        and BufferedAction(inst, home, ACTIONS.GOHOME, nil, home:GetPosition())
        or nil
end

local function GetHomeLocation(inst)
    local home = GetHome(inst)
    return home ~= nil and home:GetPosition() or nil
end

local function GetNoLeaderLeashPos(inst)
    if not inst:HasTag("flare_summoned") then
        return GetLeader(inst) == nil and GetHomeLocation(inst) or nil
    end
end

local function CanAttackNow(inst)
    return inst.components.combat.target == nil or not inst.components.combat:InCooldown()
end


local WunnyWalrusBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function WunnyWalrusBrain:OnStart()
    local root =
        PriorityNode(
            {
                BrainCommon.PanicTrigger(self.inst),
                Leash(self.inst, GetNoLeaderLeashPos, LEASH_MAX_DIST, LEASH_RETURN_DIST),
                RunAway(self.inst, ShouldRunAway, RUN_START_DIST, RUN_STOP_DIST),
                WhileNode(function() return ShouldGoHomeScared(self.inst) end, "ShouldGoHomeScared",
                    DoAction(self.inst, GoHomeAction, "Go Home Scared", true)),
                Follow(self.inst, GetLeader, MIN_FOLLOW_LEADER, TARGET_FOLLOW_LEADER, MAX_FOLLOW_LEADER, false),
                WhileNode(function() return CanAttackNow(self.inst) end, "AttackMomentarily",
                    ChaseAndAttack(self.inst, MAX_CHASE_TIME)),
                Follow(self.inst, function() return self.inst.components.combat.target end, MIN_FOLLOW_DIST,
                    TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true),
                WhileNode(function() return ShouldGoHomeAtNight(self.inst) end, "ShouldGoHomeAtNight",
                    DoAction(self.inst, GoHomeAction, "Go Home Night")),
                Follow(self.inst, GetNoLeaderFollowTarget, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, false),
                DoAction(self.inst, EatFoodAction, "Eat Food"),

                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
                FaceEntity(self.inst, GetLeader, GetLeader),

                Wander(self.inst, GetHomeLocation, MAX_WANDER_DIST),
            }, .5)


    self.bt = BT(self.inst, root)
end

return WunnyWalrusBrain
