--[[
	Sistema de florescimento (bloom) da Wormwood, portado para a Wunny.

	POR QUE ISTO É UM ARQUIVO SEPARADO: o chunk principal de prefabs/wunny.lua
	bateu no limite RÍGIDO do Lua 5.1 de 200 variáveis locais por função
	("main function has more than 200 local variables" — erro de load, não de
	runtime). Cada bloco de habilidade portado adiciona ~25 locais de topo, então
	blocos autocontidos como este passaram a morar em módulos próprios: 23 locais
	viram 1 único `require` lá. Ao portar o próximo personagem, siga este padrão
	em vez de empilhar mais locais em wunny.lua.

	Ponto de entrada único: SetupBloom(inst), chamado no master_postinit ANTES de
	WunnySkillTree.ApplyAllSkillTreeEffects.
]]

--------------------------------------------------------------------------------------
-- Wormwood: florescimento (bloom).
--
-- Mesma situação do bloco da roda de comandos do Walter: a whitelist não basta.
-- Seis das skills de WORMWOOD_SKILLS_ALWAYSON (blooming_speed1, blooming_speed2,
-- blooming_max_upgrade, blooming_overheatprotection, blooming_photosynthesis e
-- blooming_trapbramble) são lidas EXCLUSIVAMENTE dentro de prefabs/wormwood.lua,
-- pelo sistema de florescimento — nenhum arquivo compartilhado do jogo as consulta.
-- Sem portar o sistema, essas seis ficariam ligadas e sem efeito nenhum.
--
-- O que este bloco reimplementa de wormwood.lua:
--   componente "bloomness"     -> o contador de estágios (0..3) em si
--   componente "fertilizable"  -> receber adubo (fórmula/composto/estrume)
--   EnableFullBloom            -> estágio 3: isolamento de verão + a tarefa de AOE
--   DoAOEeffect                -> cuida de plantações em volta, rearma armadilhas
--                                 de espinho (trapbramble) e alimenta a
--                                 fotossíntese (photosynthesis)
--   UpdatePhotosynthesisState  -> regeneração de vida de dia em pleno florescimento
--   SetStatsLevel              -> velocidade/fome por estágio (adaptado, ver abaixo)
--
-- DUAS DIFERENÇAS DELIBERADAS em relação ao vanilla:
--
-- 1. Nada de morfologia visual. O UpdateBloomStage original chama
--    SetSkinType(inst, "stage_2".."stage_4", "wilson"), que depende dos builds de
--    florescimento do player_wormwood — arte que a Wunny não tem (os skin_modes
--    dela são registrados no AddModCharacter do modmain). Aqui o florescimento é
--    só mecânico: os bônus valem, mas a Wunny não ganha flores no corpo. Pela
--    mesma razão ficaram de fora os FX de pólen e de plantinhas do rastro
--    (PollenTick/PlantTick), que precisariam de net_vars e listeners próprios só
--    pra efeito visual.
--
-- 2. A fome não passa por hunger:SetRate. A Wunny recalcula
--    `hunger.hungerrate` do zero a cada evento "locomote" (ver o ListenForEvent
--    em master_postinit), então um SetRate aqui seria sobrescrito no primeiro
--    passo que ela desse — o florescimento viraria velocidade de graça. Em vez
--    disso o multiplicador vai pra inst._bloom_hungermult, que aquele handler
--    multiplica nos três ramos.
--------------------------------------------------------------------------------------

local function Wormwood_EnableBeeBeacon(inst, enable)
	if enable then
		if not inst.beebeacon then
			inst.beebeacon = true
			inst:AddTag("beebeacon")
		end
	elseif inst.beebeacon then
		inst.beebeacon = nil
		inst:RemoveTag("beebeacon")
	end
end

local WORMWOOD_AOE_ONEOF_TAGS = { "tendable_farmplant", "trap_bramble" }
local WORMWOOD_AOE_CANT_TAGS = { "INLIMBO", "FX" }
local WORMWOOD_DAYLIGHT_MUST_TAGS = { "daylight" }
local WORMWOOD_DAYLIGHT_CANT_TAGS = { "INLIMBO" }

local function Wormwood_DoAOEeffect(inst)
	local x, y, z = inst.Transform:GetWorldPosition()

	local skilltreeupdater = inst.components.skilltreeupdater

	local reset_brambletraps, grow_in_daylight
	if skilltreeupdater ~= nil then
		reset_brambletraps = skilltreeupdater:IsActivated("wormwood_blooming_trapbramble")
		grow_in_daylight = skilltreeupdater:IsActivated("wormwood_blooming_photosynthesis")
	end

	local interact_range_multiplier = (
		skilltreeupdater ~= nil and skilltreeupdater:IsActivated("wormwood_blooming_farmrange1") and TUNING.WORMWOOD_TENDRANGE_MULT
		or 1
	)

	local interact_range = TUNING.WORMWOOD_BLOOM_FARM_PLANT_INTERACT_RANGE * interact_range_multiplier
	for _, v in pairs(TheSim:FindEntities(x, y, z, interact_range, nil, WORMWOOD_AOE_CANT_TAGS, WORMWOOD_AOE_ONEOF_TAGS)) do
		if v.components.farmplanttendable then
			v.components.farmplanttendable:TendTo(inst)

		elseif reset_brambletraps and v.components.mine ~= nil and v:HasTag("minesprung") then
			if v.last_reset == nil or v.last_reset + TUNING.WORMWOOD_TRAP_BRAMBLE_AUTO_RESET_COOLDOWN < GetTime() then
				v.components.mine:Reset()
			end
		end
	end

	--A fotossíntese conta luz artificial como "dia": em pleno florescimento, ficar
	--perto de uma fogueira à noite também regenera vida.
	local should_grow_in_daylight = TheWorld.state.isday
	if grow_in_daylight and not should_grow_in_daylight then
		local ents = TheSim:FindEntities(x, y, z, TUNING.DAYLIGHT_SEARCH_RANGE, WORMWOOD_DAYLIGHT_MUST_TAGS, WORMWOOD_DAYLIGHT_CANT_TAGS)
		for _, v in ipairs(ents) do
			local lightrad = v.Light:GetCalculatedRadius() * .7
			if v:GetDistanceSqToPoint(x, y, z) < lightrad * lightrad then
				should_grow_in_daylight = true
				break
			end
		end
	end

	inst:UpdatePhotosynthesisState(should_grow_in_daylight)
end

local function Wormwood_EnableFullBloom(inst, enable)
	if enable then
		if not inst.fullbloom then
			inst.fullbloom = true

			local skilltreeupdater = inst.components.skilltreeupdater
			local has_upgraded_overheat_protection = (skilltreeupdater ~= nil and skilltreeupdater:IsActivated("wormwood_blooming_overheatprotection"))
			inst.components.temperature.inherentsummerinsulation = (has_upgraded_overheat_protection and TUNING.INSULATION_MED_LARGE)
				or TUNING.INSULATION_SMALL

			if not inst.tendplanttask then
				inst.tendplanttask = inst:DoPeriodicTask(.5, Wormwood_DoAOEeffect)
			end

			inst:UpdatePhotosynthesisState(TheWorld.state.isday)
		end
	elseif inst.fullbloom then
		inst.fullbloom = nil
		inst.components.temperature.inherentsummerinsulation = 0
		if inst.tendplanttask then
			inst.tendplanttask:Cancel()
			inst.tendplanttask = nil
		end

		inst:UpdatePhotosynthesisState(TheWorld.state.isday)
	end
end

--Ver a diferença 2 do comentário do bloco: a fome vai por _bloom_hungermult em vez
--de hunger:SetRate, senão o handler de "locomote" da Wunny sobrescreveria.
local function Wormwood_SetStatsLevel(inst, level)
	local mult = Remap(level, 0, 3, 1, 1.2)
	--V2C: playerspeedmult does not stack with mount speed
	inst.components.playerspeedmult:SetSpeedMult("wormwood_bloom_level", mult)
	--Só guarda o multiplicador e reassenta a taxa parada; quem recalcula de fato é
	--o handler de "locomote". Multiplicar a hungerrate atual aqui acumularia a cada
	--troca de estágio (e a cada save/load, via bloomness:OnLoad).
	inst._bloom_hungermult = mult
	inst.components.hunger.hungerrate = TUNING.WUNNY_HUNGER_RATE * mult
end

local function Wormwood_SetUserFlagLevel(inst, level)
	--No bit ops support, but in this case, + results in same as |
	local flags = USERFLAGS.CHARACTER_STATE_1 + USERFLAGS.CHARACTER_STATE_2 + USERFLAGS.CHARACTER_STATE_3
	if level > 0 then
		local addflag = USERFLAGS["CHARACTER_STATE_" .. tostring(level)]
		--No bit ops support, but in this case, - results in same as &~
		inst.Network:RemoveUserFlag(flags - addflag)
		inst.Network:AddUserFlag(addflag)
	else
		inst.Network:RemoveUserFlag(flags)
	end
end

local Wormwood_UpdateBloomStage

local function Wormwood_OnNewSGState(inst)
	if not inst.sg:HasStateTag("nomorph") then
		Wormwood_UpdateBloomStage(inst)
	end
end

--Sem a parte visual (ver diferença 1 do comentário do bloco): o original troca o
--skin mode pra "stage_2".."stage_4" aqui. O adiamento por "nomorph" continua igual
--ao vanilla — os bônus não devem entrar no meio de um estado que não pode ser
--interrompido (o próprio estado "fertilize" é um deles).
function Wormwood_UpdateBloomStage(inst, stage)
	stage = stage or inst.components.bloomness:GetLevel()

	local isghost = inst:HasTag("playerghost") or inst.sg:HasStateTag("ghostbuild")

	if not isghost and inst.sg:HasStateTag("nomorph") then
		inst._queued_morph = true
		inst:ListenForEvent("newstate", Wormwood_OnNewSGState)
		return
	end

	Wormwood_EnableBeeBeacon(inst, stage > 0)
	Wormwood_EnableFullBloom(inst, stage >= 3)
	Wormwood_SetStatsLevel(inst, stage)
	Wormwood_SetUserFlagLevel(inst, stage)

	if inst._queued_morph then
		inst._queued_morph = false
		inst:RemoveEventCallback("newstate", Wormwood_OnNewSGState)
	end

	local silent = inst._bloom_loading or inst.components.health:IsDead()
		or not inst.entity:IsVisible() or inst.sg:HasStateTag("silentmorph")

	if stage > 0 and not inst._bloomed_announced and not silent and not isghost then
		inst._bloomed_announced = true
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_BLOOMING"))
	elseif stage <= 0 then
		inst._bloomed_announced = nil
	end
end

local function Wormwood_OnFertilizedWithFormula(inst, value)
	if value > 0 and inst.components.bloomness then
		if inst.components.skilltreeupdater:IsActivated("wormwood_blooming_max_upgrade") then
			value = value * TUNING.WORMWOOD_BLOOM_MAX_UPGRADE_MULT
		end
		inst.components.bloomness:Fertilize(value)
	end
end

local function Wormwood_OnFertilizedWithCompost(inst, value)
	if value > 0 and inst.components.health and not inst.components.health:IsDead() then
		local healing = TUNING.WORMWOOD_COMPOST_HEAL_VALUES[math.ceil(value / 8)] or TUNING.WORMWOOD_COMPOST_HEAL_VALUES[1]
		inst:AddDebuff("compostheal_buff", "compostheal_buff", { duration = healing * (TUNING.WORMWOOD_COMPOST_HEALOVERTIME_TICK / TUNING.WORMWOOD_COMPOST_HEALOVERTIME_HEALTH) })
	end
end

local function Wormwood_OnFertilizedWithManure(inst, value, src)
	if value > 0 and inst.components.bloomness then
		local healing = TUNING.WORMWOOD_MANURE_HEAL_VALUES[math.ceil(value / 8)] or TUNING.WORMWOOD_MANURE_HEAL_VALUES[1]
		inst.components.health:DoDelta(healing, false, src ~= nil and src.prefab or nil)
	end
end

local function Wormwood_OnFertilized(inst, fertilizer_obj)
	if inst.components.health and inst.components.health.canheal then
		local fertilizer = fertilizer_obj.components.fertilizer
		if fertilizer and fertilizer.nutrients then
			inst:OnFertilizedWithFormula(fertilizer.nutrients[TUNING.FORMULA_NUTRIENTS_INDEX], fertilizer_obj)
			inst:OnFertilizedWithCompost(fertilizer.nutrients[TUNING.COMPOST_NUTRIENTS_INDEX], fertilizer_obj)
			inst:OnFertilizedWithManure(fertilizer.nutrients[TUNING.MANURE_NUTRIENTS_INDEX], fertilizer_obj)
			return true
		end
	end
end

local function Wormwood_CalcBloomRateFn(inst, level, is_blooming, fertilizer)
	local season_mult = 1
	if TheWorld.state.season == "spring" then
		if is_blooming then
			season_mult = TUNING.WORMWOOD_SPRING_BLOOM_MOD
		else
			return TUNING.WORMWOOD_SPRING_BLOOMDRAIN_RATE
		end
	elseif TheWorld.state.season == "winter" then
		if is_blooming then
			season_mult = TUNING.WORMWOOD_WINTER_BLOOM_MOD
		else
			return TUNING.WORMWOOD_WINTER_BLOOMDRAIN_RATE
		end
	end

	local rate = (is_blooming and fertilizer > 0) and (season_mult * (1 + fertilizer * TUNING.WORMWOOD_FERTILIZER_RATE_MOD)) or 1
	return rate
end

local function Wormwood_CalcFullBloomDurationFn(inst, value, remaining, full_bloom_duration)
	value = value * TUNING.WORMWOOD_FERTILIZER_BLOOM_TIME_MOD

	local actual_maximum = (inst.components.skilltreeupdater and
			inst.components.skilltreeupdater:IsActivated("wormwood_blooming_max_upgrade") and
			TUNING.WORMWOOD_BLOOM_FULL_MAX_DURATION_UPGRADED)
		or TUNING.WORMWOOD_BLOOM_FULL_MAX_DURATION
	return math.min(remaining + value, actual_maximum)
end

local function Wormwood_OnSeasonChange(inst, season)
	if season == "spring" and not inst:HasTag("playerghost") then
		inst.components.bloomness:Fertilize()
	else
		inst.components.bloomness:UpdateRate()
	end
end

local function Wormwood_UpdatePhotosynthesisState(inst, isday)
	local should_photosynthesize = false
	if isday and inst.fullbloom and inst.components.skilltreeupdater
		and inst.components.skilltreeupdater:IsActivated("wormwood_blooming_photosynthesis")
		and not inst:HasTag("playerghost") then
		should_photosynthesize = true
	end
	if should_photosynthesize ~= inst.photosynthesizing then
		inst.photosynthesizing = should_photosynthesize
		if inst.components.health then
			if should_photosynthesize then
				local regen = TUNING.WORMWOOD_PHOTOSYNTHESIS_HEALTH_REGEN
				inst.components.health:AddRegenSource(inst, regen.amount, regen.period, "photosynthesis_skill")
			else
				inst.components.health:RemoveRegenSource(inst, "photosynthesis_skill")
			end
		end
	end
end

local function Wormwood_OnBecameGhost(inst)
	inst.components.bloomness:SetLevel(0)
	inst:UpdatePhotosynthesisState(TheWorld.state.isday)
end

local function Wormwood_OnRespawnedFromGhost(inst)
	if TheWorld.state.isspring then
		inst.components.bloomness:Fertilize()
	end
	inst:UpdatePhotosynthesisState(TheWorld.state.isday)
end

--Chamado no master_postinit ANTES de WunnySkillTree.ApplyAllSkillTreeEffects: o
--onactivate de wormwood_blooming_speed1/speed2 chama bloomness:SetDurations, então
--o componente já precisa existir naquele momento (com a whitelist ativa, speed1 vê
--speed2 como ligada e recua; speed2 aplica UPGRADED2, que é o tier mais rápido —
--"wormwood_blooming_speed3" não existe como skill, é só o nome do ícone de
--blooming_max_upgrade).
local function Wormwood_SetupBloom(inst)
	inst.fullbloom = nil
	inst.beebeacon = nil
	inst._bloom_hungermult = 1

	--bloomness:OnLoad chama onlevelchangedfn direto, então recarregar um mundo com a
	--Wunny já florida reentraria em UpdateBloomStage e ela anunciaria "estou
	--florescendo!" a cada load. O wormwood.lua resolve isso com _loading no
	--OnPreLoad/OnLoad dele; aqui basta soltar a flag no frame seguinte, já que o
	--OnLoad acontece de forma síncrona durante o spawn.
	inst._bloom_loading = true
	inst:DoTaskInTime(0, function(inst)
		inst._bloom_loading = nil
	end)

	local bloomness = inst:AddComponent("bloomness")
	bloomness:SetDurations(TUNING.WORMWOOD_BLOOM_STAGE_DURATION, TUNING.WORMWOOD_BLOOM_FULL_DURATION)
	bloomness.onlevelchangedfn = Wormwood_UpdateBloomStage
	bloomness.calcratefn = Wormwood_CalcBloomRateFn
	bloomness.calcfullbloomdurationfn = Wormwood_CalcFullBloomDurationFn

	local fertilizable = inst:AddComponent("fertilizable")
	--sic: o nome do campo tem esse typo no vanilla (components/fertilizable.lua)
	fertilizable.onfertlizedfn = Wormwood_OnFertilized

	inst.OnFertilizedWithFormula = Wormwood_OnFertilizedWithFormula
	inst.OnFertilizedWithCompost = Wormwood_OnFertilizedWithCompost
	inst.OnFertilizedWithManure = Wormwood_OnFertilizedWithManure
	inst.UpdateBloomStage = Wormwood_UpdateBloomStage
	inst.UpdatePhotosynthesisState = Wormwood_UpdatePhotosynthesisState

	if inst.components.acidlevel ~= nil then
		--chuva ácida aduba em vez de só machucar, igual no wormwood.lua
		inst.components.acidlevel:SetOverrideAcidRainTickFn(function(inst, damage)
			inst:OnFertilizedWithFormula(damage)
		end)
	end

	inst:ListenForEvent("ms_becameghost", Wormwood_OnBecameGhost)
	inst:ListenForEvent("ms_respawnedfromghost", Wormwood_OnRespawnedFromGhost)
	inst:WatchWorldState("season", Wormwood_OnSeasonChange)
end

return {
	SetupBloom = Wormwood_SetupBloom,
}
