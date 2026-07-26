--[[
	Brain do coelho selvagem domesticado pela Wunny (cenoura -> follower).
	Substitui inteiramente a brain vanilla do "rabbit" (que só foge e come),
	então tudo que ele deve fazer como follower está aqui: coletar
	graveto/grama perto, chegar perto da Wunny pra entregar, segui-la e, só na
	falta de recurso pra coletar durante um combate dela, brigar no estilo
	"bate e foge".

	A ENTREGA em si NÃO está aqui: ela roda num DoPeriodicTask no próprio
	coelho (ver SetUpWunnyBunnyFollower em modmain.lua). A brain só se
	encarrega de aproximá-lo da Wunny quando está carregando algo. Isso é
	deliberado — se a entrega dependesse de um nó da árvore, qualquer nó que
	falhasse ou fosse resetado deixaria o item preso no inventário do coelho
	pra sempre.
]]

require "behaviours/follow"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/runaway"

local GATHER_SEARCH_DIST = 20

-- Percepção de perigo. O coelho vanilla tem 25 de vida e nenhum estado de
-- ataque, então qualquer bicho hostil no caminho (um frog basta) o mata; ele
-- precisa desviar em vez de andar reto pro recurso ou pra Wunny.
local THREAT_SEE_DIST = 7
local THREAT_SAFE_DIST = 11
-- Recurso mais perto que isso de um bicho hostil é ignorado na coleta.
local THREAT_NEAR_TARGET_DIST = 6
-- Distância máxima da Wunny pra preferir se esconder atrás dela em vez de só
-- fugir na direção oposta ao bicho.
local HIDE_BEHIND_LEADER_DIST = 20

local HIDE_FOLLOW_MIN = 0
local HIDE_FOLLOW_TARGET = 1
local HIDE_FOLLOW_MAX = 2

-- Perseguir a Wunny pra entregar: precisa terminar mais perto que o alcance de
-- entrega do DoPeriodicTask (WUNNY_BUNNY_DELIVER_DIST em modmain.lua), senão
-- ele "chega" e a entrega nunca dispara.
local CARRY_FOLLOW_MIN = 0
local CARRY_FOLLOW_TARGET = 1.5
local CARRY_FOLLOW_MAX = 2

local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 4
local MAX_FOLLOW_DIST = 8
local MAX_WANDER_DIST = 6

local RETREAT_DIST = 4
local RETREAT_TIME = 1.5
local ATTACK_RANGE = 2
local ATTACK_COOLDOWN = 2

local GATHERABLE_PREFABS = { sapling = true, grass = true }

local function GetLeader(inst)
	return inst.components.follower ~= nil and inst.components.follower.leader or nil
end

local function GetLeaderPos(inst)
	local leader = GetLeader(inst)
	return leader ~= nil and leader:IsValid() and Point(leader.Transform:GetWorldPosition()) or nil
end

-- Não dá pra usar a tag "scarytoprey" da brain vanilla do rabbit aqui: o
-- jogador também é scarytoprey, e o coelho fugiria da própria Wunny. Filtra
-- por hostilidade real, ignorando o leader, outros jogadores e os aliados da
-- bunny army.
local function IsThreat(inst, ent)
	if ent == inst
		or ent == GetLeader(inst)
		or not ent:IsValid()
		or ent:HasTag("player")
		or ent:HasTag("wunnybunnyfollower")
		or ent:HasTag("bunnyman")
		or ent.components.combat == nil
		or (ent.components.health ~= nil and ent.components.health:IsDead()) then
		return false
	end
	return ent:HasTag("monster")
		or ent:HasTag("hostile")
		or ent.components.combat.target == inst
		or ent.components.combat.target == GetLeader(inst)
end

-- ignore_leader_target: o bicho que a Wunny já está enfrentando não conta como
-- perigo do qual fugir, senão o nó de fuga sempre venceria o de combate e o
-- coelho nunca ajudaria na briga (o "bate e foge" já cuida de recuar dele).
local function FindThreat(inst, dist, ignore_leader_target)
	local leader = GetLeader(inst)
	local leadertarget = leader ~= nil and leader.components.combat ~= nil
		and leader.components.combat.target or nil
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, dist or THREAT_SEE_DIST, { "_combat" }, { "INLIMBO", "wall", "structure" })
	for _, ent in ipairs(ents) do
		if IsThreat(inst, ent) and not (ignore_leader_target and ent == leadertarget) then
			return ent
		end
	end
	return nil
end

local function IsDangerNear(inst)
	return FindThreat(inst, THREAT_SEE_DIST, true) ~= nil
end

-- Mesma checagem, mas em volta de um ponto/entidade qualquer (usada pra
-- descartar recursos guardados por um bicho hostil).
local function IsThreatNearPoint(inst, ent)
	local x, y, z = ent.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, THREAT_NEAR_TARGET_DIST, { "_combat" }, { "INLIMBO", "wall", "structure" })
	for _, other in ipairs(ents) do
		if IsThreat(inst, other) then
			return true
		end
	end
	return false
end

local function LeaderIsCloseEnoughToHide(inst)
	local leader = GetLeader(inst)
	return leader ~= nil and leader:IsValid() and inst:IsNear(leader, HIDE_BEHIND_LEADER_DIST)
end

local function IsCarryingItem(inst)
	return inst.components.inventory ~= nil
		and inst.components.inventory:FindItem(function() return true end) ~= nil
end

local function FindGatherTarget(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, GATHER_SEARCH_DIST, { "pickable" }, { "INLIMBO", "fire", "burnt" })
	for _, ent in ipairs(ents) do
		if GATHERABLE_PREFABS[ent.prefab]
			and ent.components.pickable ~= nil
			and ent.components.pickable:CanBePicked()
			-- Recurso com bicho hostil em cima não vale a viagem.
			and not IsThreatNearPoint(inst, ent) then
			return ent
		end
	end
	return nil
end

local function GatherAction(inst)
	if IsCarryingItem(inst) then
		return nil
	end
	local target = FindGatherTarget(inst)
	return target ~= nil and BufferedAction(inst, target, ACTIONS.PICK) or nil
end

local function ShouldFight(inst)
	local leader = GetLeader(inst)
	return leader ~= nil
		and leader.components.combat ~= nil
		and leader.components.combat.target ~= nil
		and leader.components.combat.target:IsValid()
		and FindGatherTarget(inst) == nil
end

--------------------------------------------------------------------------
-- Estilo "bate e foge": se aproxima, dá 1 de dano direto e recua por um
-- tempo antes de tentar de novo. O dano é aplicado via Combat:GetAttacked
-- porque o stategraph do rabbit vanilla não tem nenhum estado de ataque.
--------------------------------------------------------------------------
local HitAndRunNode = Class(BehaviourNode, function(self, inst, getleaderfn)
	BehaviourNode._ctor(self, "WunnyBunnyHitAndRun")
	self.inst = inst
	self.getleaderfn = getleaderfn
	self.retreat_until = nil
	self.next_attack_time = nil
end)

function HitAndRunNode:Visit()
	local inst = self.inst

	if self.status == READY then
		self.status = RUNNING
		self.retreat_until = nil
		self.next_attack_time = nil
	end

	local leader = self.getleaderfn(inst)
	local target = leader ~= nil and leader.components.combat ~= nil and leader.components.combat.target or nil

	if target == nil or not target:IsValid()
		or (target.components.health ~= nil and target.components.health:IsDead()) then
		self.status = SUCCESS
		inst.components.locomotor:Stop()
		return
	end

	local ip = Point(inst.Transform:GetWorldPosition())
	local tp = Point(target.Transform:GetWorldPosition())

	if self.retreat_until ~= nil and self.retreat_until > GetTime() then
		local dx, dz = ip.x - tp.x, ip.z - tp.z
		local len = math.sqrt(dx * dx + dz * dz)
		if len > 0.001 then
			dx, dz = dx / len, dz / len
			inst.components.locomotor:GoToPoint(Point(ip.x + dx * RETREAT_DIST, ip.y, ip.z + dz * RETREAT_DIST), nil, true)
		end
		self:Sleep(.2)
		return
	end

	self.retreat_until = nil

	if distsq(tp, ip) > ATTACK_RANGE * ATTACK_RANGE then
		inst.components.locomotor:GoToPoint(tp, nil, true)
	else
		inst.components.locomotor:Stop()
		if self.next_attack_time == nil or self.next_attack_time <= GetTime() then
			if target.components.combat ~= nil then
				target.components.combat:GetAttacked(inst, TUNING.WUNNY_BUNNYFOLLOWER_DAMAGE or 1)
			end
			inst.SoundEmitter:PlaySound("dontstarve/rabbit/hop")
			self.next_attack_time = GetTime() + ATTACK_COOLDOWN
			self.retreat_until = GetTime() + RETREAT_TIME
		end
	end

	self:Sleep(.2)
end

--------------------------------------------------------------------------

local WunnyBunnyFollowerBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function WunnyBunnyFollowerBrain:OnStart()
	local root = PriorityNode(
	{
		-- Prioridade máxima: sair de perto de bicho hostil. Se a Wunny está
		-- por perto ele se esconde atrás dela (que resolve a ameaça e, de
		-- bônus, isso o coloca no alcance de entrega); senão foge na direção
		-- oposta ao bicho.
		WhileNode(function() return IsDangerNear(self.inst) end, "Danger",
			PriorityNode(
			{
				IfNode(function() return LeaderIsCloseEnoughToHide(self.inst) end, "HideBehindLeader",
					Follow(self.inst, GetLeader, HIDE_FOLLOW_MIN, HIDE_FOLLOW_TARGET, HIDE_FOLLOW_MAX)),
				-- O último argumento (safe_point_fn) desvia a fuga na direção
				-- da Wunny em vez de só na oposta ao bicho, pra ele não fugir
				-- pro mato e sumir com o item.
				RunAway(self.inst,
					{ fn = function(ent) return IsThreat(self.inst, ent) end, tags = { "_combat" }, notags = { "INLIMBO", "wall", "structure" } },
					THREAT_SEE_DIST, THREAT_SAFE_DIST, nil, nil, nil, nil, GetLeaderPos),
			}, .25)),

		-- Carregando algo: cola na Wunny até entrar no alcance de entrega.
		WhileNode(function() return IsCarryingItem(self.inst) end, "Carrying",
			Follow(self.inst, GetLeader, CARRY_FOLLOW_MIN, CARRY_FOLLOW_TARGET, CARRY_FOLLOW_MAX)),

		DoAction(self.inst, GatherAction, "gather", true),

		WhileNode(function() return ShouldFight(self.inst) end, "Fight",
			HitAndRunNode(self.inst, GetLeader)),

		Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
		Wander(self.inst, GetLeaderPos, MAX_WANDER_DIST),
	}, .25)

	self.bt = BT(self.inst, root)
end

return WunnyBunnyFollowerBrain
