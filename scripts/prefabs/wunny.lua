local MakePlayerCharacter = require("prefabs/player_common")
local WX78Common = require("prefabs/wx78_common")
local WortoxSoulCommon = require("prefabs/wortox_soul_common")
local WillowEmberCommon = require("prefabs/willow_ember_common")
local WX78MoistureMeter = require("widgets/wx78moisturemeter")
local WendyFlowerOver = require("widgets/wendyflowerover")
local easing = require("easing")
local WunnySkillTree = require("wunnyskilltree")

local assets = {
	Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
	Asset("ANIM", "anim/rabbit_hole.zip"),
	Asset("ANIM", "anim/bunnybeard.zip"),
	Asset("SCRIPT", "scripts/prefabs/skilltree_willow.lua"),
	--Wortox (soul hop / almas)
	Asset("ANIM", "anim/wortox_portal.zip"),
	Asset("ANIM", "anim/wortox_soul_ball.zip"),
	Asset("SOUND", "sound/wortox.fsb"),
	--Wilson (skill "wilson_beard_7"): banks da UI do container da barba-mochila
	--(containers.lua params.beard_sack_N.widget.animbank). O beard_sack.lua não
	--declara estes zips — quem os carrega é o wilson.lua, então a Wunny precisa
	--declarar por conta própria ou o container abre sem arte.
	Asset("ANIM", "anim/ui_beard_1x1.zip"),
	Asset("ANIM", "anim/ui_beard_2x1.zip"),
	Asset("ANIM", "anim/ui_beard_3x1.zip"),
	--Willow (skill "willow_embers"): animação de conjuração das magias de brasa.
	--O estado "castspellmind" de SGwilson.lua toca "pyrocast_pre"/"pyrocast", que
	--só existem neste build — sem o AddOverrideBuild em common_postinit a Wunny
	--conjuraria sem animação nenhuma.
	Asset("ANIM", "anim/willow_pyrocast.zip"),
	Asset("ANIM", "anim/willow_mount_pyrocast.zip"),

	--Winona (skill "winona_charlie_1"): marcador de minimapa usado pelo componente
	--roseinspectableuser. É carregado pelo winona.lua com este mesmo comentário.
	Asset("ANIM", "anim/roseglasses_minimap_indicator.zip"),
}

local prefabsItens = {
	"carrot",
}

-- Forward declaration: usada em onload() (definida antes do bloco do Wortox mais
-- abaixo no arquivo), atribuída de fato junto com o resto do sistema de almas.
local Wortox_SetNetvar

-- Forward declaration: onbecameghost() usa KillPet, mas a definição dela fica
-- junto do resto do bloco de pets (petleash/shadowminion), bem mais abaixo. Sem
-- esta linha as chamadas em onbecameghost resolveriam pro global KillPet (nil),
-- porque um "local function" só entra em escopo a partir da linha dele.
local KillPet

TUNING.WUNNY_HEALTH = 65
TUNING.WUNNY_HUNGER = 140
TUNING.WUNNY_SANITY = 140

PrefabFiles = {
	-- "smallmeat",
	-- "cookedsmallmeat",
	-- "cookedmonstermeat",
	-- "beardhair",
	-- "monstermeat",
	-- "nightmarefuel",
	-- "carrot",
	-- "boards",
	-- "manrabbit_tail",
	-- "carrot_cooked",
	-- "wunnyslingshot",
}

local BEARDLORD_SKINS = {
	"beardlord_skin",
}

local NORMAL_SKINS = {
	"normal_skin",
}

-- Custom starting inventory
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WUNNY = {
	-- "wunnyslingshot",
	"dwarfbunnyman",
	"strawhat",
	-- "rabbit",
	-- "rabbit",
	-- "armorwood",
	-- "purplegem",
	-- "purplegem",
	-- "purplegem",
	-- "purplegem",
	-- "purplegem",
	-- "purplegem",
	-- "purplegem",
	-- "purplegem",
	-- "purplegem",
	-- "purplegem",
	-- "redgem",
	-- "redgem",
	-- "redgem",
	-- "redgem",
	-- "redgem",
	-- "redgem",
	-- "redgem",
	-- "pondeel",
	-- "pondeel",
	-- "pondeel",
	-- "hammer",
	-- "rabbit",
	-- "rabbit",
	-- "boards",
	-- "boards",
	-- "boards",
	-- "boards",
	-- "boards",
	-- "boards",
	-- "boards",
	-- "tophat",
	-- "tophat",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "nightmarefuel",
	-- "silk",
	-- "waxwelljournal",
	-- "cane",

	-- "monstermeat",
	-- "monstermeat",
	-- "monstermeat",
	-- "wunnyslingshot",
	-- "slingshotammo_rock",
	-- "shovel",

	-- "carrot",
	-- "carrot",
	-- "manrabbit_tail",
	-- "armorwood",

	-- "tophat_magician",

	-- "bookstation",
	-- "book_birds",
	-- "book_horticulture",
	-- "book_silviculture",
	-- "book_sleep",
	-- "book_brimstone",
	-- "book_tentacles",

	-- "book_fish",
	-- "book_fire",
	-- "book_web",
	-- "book_temperature",
	-- "book_light",
	-- "book_rain",
	-- "book_moon",
	-- "book_bees",
	-- "book_research_station",

	-- "book_horticulture_upgraded",
	-- "book_light_upgraded",

	-- "monstermeat",
	-- "monstermeat",
	-- "monstermeat",
	-- "manrabbit_tail",
	-- "manrabbit_tail",
	-- "manrabbit_tail",
	-- "manrabbit_tail",

	-- "boards",
	-- "boards",
	-- "boards",
	-- "boards",
	-- "bernie_inactive",
	-- "lucy",
	-- "spidereggsack",
	-- "pigskin",
	-- "meat",
	-- "meat",

	-- "abigail_flower",
}

local prefabs = {
	"wobybig",
	"wobysmall",
	--Wortox (soul hop / almas)
	"wortox_soul_spawn",
	"wortox_portal_jumpin_fx",
	"wortox_portal_jumpout_fx",
	"wortox_soul_heal_fx",
	--Burrow dash (mole, terra se movendo)
	"mole_move_fx",
	--Wilson (skill "wilson_beard_7"): mochilas de barba equipadas em
	--EQUIPSLOTS.BEARD conforme o tamanho da barba (ver Wilson_UpdateBeardInventory).
	"beard_sack_1",
	"beard_sack_2",
	"beard_sack_3",
	--Willow (skill "willow_embers"): brasas que caem de criaturas queimadas.
	--"willow_ember" é quem carrega o spellbook (fire throw/burst/ball/frenzy),
	--o debuff buff_firefrenzy e a maioria dos FX das magias na própria tabela
	--`prefabs` dele. "emberlight" (a bola de fogo) é a exceção que ficou de fora
	--dela — por isso o willow.lua também declara essa à parte, e nós também.
	"willow_ember",
	"emberlight",
	--Winona: "inspectaclesbox"/"inspectaclesbox2" saem do componente
	--inspectaclesparticipant (skill wagstaff_1/2); os outros três saem do
	--roseinspectableuser (skill charlie_1).
	"inspectaclesbox",
	"inspectaclesbox2",
	"charlieresidue",
	"flower_rose",
	"rose_petals_fx",
}

local WX78ModuleDefinitionFile = require("wx78_moduledefs")
local GetWX78ModuleByNetID = WX78ModuleDefinitionFile.GetModuleDefinitionFromNetID

local WX78ModuleDefinitions = WX78ModuleDefinitionFile.module_definitions

local CHARGEREGEN_TIMERNAME = "chargeregenupdate"
local MOISTURETRACK_TIMERNAME = "moisturetrackingupdate"
local HUNGERDRAIN_TIMERNAME = "hungerdraintick"
local HEATSTEAM_TIMERNAME = "heatsteam_tick"

-- wx78_circuitry_bettercharge é permanente na Wunny (todas as skills do
-- WunnySkillTree são concedidas de uma vez, sem tela de skill tree), então a
-- recarga já vem sempre no ritmo acelerado, em vez de checar
-- skilltreeupdater:IsActivated a cada vez.
local function Wunny_GetChargeRegenTime()
	return TUNING.WX78_CHARGE_REGENTIME / TUNING.SKILLS.WX78.FASTER_CHARGE_MULTIPLIER
end
for mdindex, module_def in ipairs(WX78ModuleDefinitions) do
	table.insert(prefabs, "wx78module_" .. module_def.name)
end

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WUNNY
end

prefabs = FlattenTree({ prefabs, start_inv }, true)

local function OnBondLevelDirty(inst)
	if inst.HUD ~= nil then
		local bond_level = inst._bondlevel:value()
		for i = 0, 3 do
			if i ~= 1 then
				inst:SetClientSideInventoryImageOverrideFlag("bondlevel" .. i, i == bond_level)
			end
		end
		if not inst:HasTag("playerghost") then
			if bond_level > 1 then
				if inst.HUD.wendyflowerover ~= nil then
					inst.HUD.wendyflowerover:Play(bond_level)
				end
			end
		end
	end
end

-- Wetness/Moisture/Rain ---------------------------------------------------------------
local function initiate_moisture_update(inst)
	if not inst.components.timer:TimerExists(MOISTURETRACK_TIMERNAME) then
		inst.components.timer:StartTimer(MOISTURETRACK_TIMERNAME, TUNING.WX78_MOISTUREUPDATERATE * FRAMES)
	end
end

local function stop_moisturetracking(inst)
	inst.components.timer:StopTimer(MOISTURETRACK_TIMERNAME)

	inst._moisture_steps = 0
end

local function moisturetrack_update(inst)
	local current_moisture = inst.components.moisture:GetMoisture()
	if current_moisture > TUNING.WX78_MINACCEPTABLEMOISTURE then
		-- The update will loop until it is stopped by going under the acceptable moisture level.
		initiate_moisture_update(inst)
	end

	if inst:HasTag("moistureimmunity") then
		return
	end

	inst._moisture_steps = inst._moisture_steps + 1

	local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("sparks").Transform:SetPosition(x, y + 1 + math.random() * 1.5, z)

	if inst._moisture_steps >= TUNING.WX78_MOISTURESTEPTRIGGER then
		local damage_per_second = easing.inSine(
			current_moisture - TUNING.WX78_MINACCEPTABLEMOISTURE,
			TUNING.WX78_MIN_MOISTURE_DAMAGE,
			TUNING.WX78_PERCENT_MOISTURE_DAMAGE,
			inst.components.moisture:GetMaxMoisture() - TUNING.WX78_MINACCEPTABLEMOISTURE
		)
		local seconds_per_update = TUNING.WX78_MOISTUREUPDATERATE / 30

		inst.components.health:DoDelta(inst._moisture_steps * seconds_per_update * damage_per_second, false, "water")
		inst.components.upgrademoduleowner:AddCharge(-1)
		inst._moisture_steps = 0

		SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

		inst.sg:GoToState("hit")
	end

	-- Send a message for the UI.
	inst:PushEvent("do_robot_spark")
	if inst.player_classified ~= nil then
		inst.player_classified.uirobotsparksevent:push()
	end
end

local function OnWetnessChanged(inst, data)
	if not (inst.components.health ~= nil and inst.components.health:IsDead()) then
		if
			data.new >= TUNING.WX78_COLD_ICEMOISTURE
			and inst.components.upgrademoduleowner:GetModuleTypeCount("cold") > 0
		then
			inst.components.moisture:SetMoistureLevel(0)

			local x, y, z = inst.Transform:GetWorldPosition()
			for i = 1, TUNING.WX78_COLD_ICECOUNT do
				local ice = SpawnPrefab("ice")
				ice.Transform:SetPosition(x, y, z)
				Launch(ice, inst)
			end

			stop_moisturetracking(inst)
		elseif data.new > TUNING.WX78_MINACCEPTABLEMOISTURE and data.old <= TUNING.WX78_MINACCEPTABLEMOISTURE then
			initiate_moisture_update(inst)
		elseif data.new <= TUNING.WX78_MINACCEPTABLEMOISTURE and data.old > TUNING.WX78_MINACCEPTABLEMOISTURE then
			stop_moisturetracking(inst)
		end
	end
end

local function OnClientPetSkinChanged(inst)
	if inst.HUD ~= nil and inst.HUD.wendyflowerover ~= nil then
		local skinname = TheInventory:LookupSkinname(inst.components.pethealthbar._petskin:value())
		inst.HUD.wendyflowerover:SetSkin(skinname)
	end
end

local function RefreshFlowerTooltip(inst)
	if inst == ThePlayer then
		inst:PushEvent("inventoryitem_updatespecifictooltip", { prefab = "abigail_flower" })
	end
end

local function ghostlybond_onlevelchange(inst, ghost, level, prev_level, isloading)
	inst._bondlevel:set(level)

	if not isloading and inst.components.talker ~= nil and level > 1 then
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_GHOSTLYBOND_LEVELUP", "LEVEL" .. tostring(level)))
		OnBondLevelDirty(inst)
	end
end

local function ghostlybond_onsummon(inst, ghost)
	if inst.components.sanity ~= nil and inst.migration == nil then
		inst.components.sanity:DoDelta(TUNING.SANITY_MED)
	end
end

local function ghostlybond_onrecall(inst, ghost, was_killed)
	if inst.migration == nil then
		if inst.components.sanity ~= nil then
			inst.components.sanity:DoDelta(was_killed and (-TUNING.SANITY_MED * 2) or -TUNING.SANITY_MED)
		end

		if inst.components.talker ~= nil then
			inst.components.talker:Say(
				GetString(inst, was_killed and "ANNOUNCE_ABIGAIL_DEATH" or "ANNOUNCE_ABIGAIL_RETRIEVE")
			)
		end
	end

	inst.components.ghostlybond.ghost.sg:GoToState("dissipate")
end

local function ghostlybond_onsummoncomplete(inst, ghost)
	inst.refreshflowertooltip:push()
end

local function ghostlybond_changebehaviour(inst, ghost)
	-- todo: toggle abigail between defensive and offensive
	if ghost.is_defensive then
		ghost:BecomeAggressive()
	else
		ghost:BecomeDefensive()
	end
	inst.refreshflowertooltip:push()

	return true
end

local function update_sisturn_state(inst, is_active)
	if inst.components.ghostlybond ~= nil then
		if is_active == nil then
			is_active = TheWorld.components.sisturnregistry ~= nil and TheWorld.components.sisturnregistry:IsActive()
		end
		inst.components.ghostlybond:SetBondTimeMultiplier(
			"sisturn",
			is_active and TUNING.ABIGAIL_BOND_LEVELUP_TIME_MULT or nil
		)
	end
end

local function SpawnWoby(inst)
	local player_check_distance = 40
	local attempts = 0

	local max_attempts = 30
	local x, y, z = inst.Transform:GetWorldPosition()

	local woby = SpawnPrefab(TUNING.WALTER_STARTING_WOBY)
	inst.woby = woby
	woby:LinkToPlayer(inst)
	inst:ListenForEvent("onremove", inst._woby_onremove, woby)

	while true do
		local offset = FindWalkableOffset(inst:GetPosition(), math.random() * PI, player_check_distance + 1, 10)

		if offset then
			local spawn_x = x + offset.x
			local spawn_z = z + offset.z

			if attempts >= max_attempts then
				woby.Transform:SetPosition(spawn_x, y, spawn_z)
				break
			elseif not IsAnyPlayerInRange(spawn_x, 0, spawn_z, player_check_distance) then
				woby.Transform:SetPosition(spawn_x, y, spawn_z)
				break
			else
				attempts = attempts + 1
			end
		elseif attempts >= max_attempts then
			woby.Transform:SetPosition(x, y, z)
			break
		else
			attempts = attempts + 1
		end
	end

	return woby
end

----------------------------------------------------------------------------------------
-- Nota: GetMaxEnergy/GetEnergyLevel/GetModulesData/CanUpgradeWithModule já são
-- fornecidas por WX78Common.SetupUpgradeModuleOwnerInstanceFunctions (ver
-- common_postinit). Havia aqui uma reimplementação própria (CLIENT_*) que
-- duplicava essa lógica e tinha um bug (usava upgrademoduleowner.modules, que
-- não existe — o campo certo é module_bars), causando um crash no HUD
-- (upgrademodulesdisplay.lua). Removida em vez de corrigida para não manter
-- duas fontes de verdade divergentes.
----------------------------------------------------------------------------------------
local function OnForcedNightVisionDirty(inst)
	if inst.components.playervision ~= nil then
		inst.components.playervision:ForceNightVision(inst._forced_nightvision:value())
	end
end

local NIGHTVISIONMODULE_GRUEIMMUNITY_NAME = "wxnightvisioncircuit"
local function SetForcedNightVision(inst, nightvision_on)
	inst._forced_nightvision:set(nightvision_on)
	if inst.components.playervision ~= nil then
		inst.components.playervision:ForceNightVision(nightvision_on)
	end

	-- The nightvision event might get consumed during save/loading,
	-- so push an extra custom immunity into the table.
	if nightvision_on then
		inst.components.grue:AddImmunity(NIGHTVISIONMODULE_GRUEIMMUNITY_NAME)
	else
		inst.components.grue:RemoveImmunity(NIGHTVISIONMODULE_GRUEIMMUNITY_NAME)
	end
end

local function OnPlayerDeactivated(inst)
	inst:RemoveEventCallback("onremove", OnPlayerDeactivated)
	if not TheNet:IsDedicated() then
		inst:RemoveEventCallback("forced_nightvision_dirty", OnForcedNightVisionDirty)
	end

	if not TheWorld.ismastersim then
		inst:RemoveEventCallback("_bondleveldirty", OnBondLevelDirty)
	end
end

local function OnPlayerActivated(inst)
	inst:ListenForEvent("onremove", OnPlayerDeactivated)
	if not TheNet:IsDedicated() then
		inst:ListenForEvent("forced_nightvision_dirty", OnForcedNightVisionDirty)
		OnForcedNightVisionDirty(inst)
	end

	if inst == ThePlayer then
		if inst.HUD.wendyflowerover == nil and inst.components.pethealthbar ~= nil then
			inst.HUD.wendyflowerover = inst.HUD.overlayroot:AddChild(WendyFlowerOver(inst))
			inst.HUD.wendyflowerover:MoveToBack()
			OnClientPetSkinChanged(inst)
		end
		inst:ListenForEvent("onremove", OnPlayerDeactivated)
		if not TheWorld.ismastersim then
			inst:ListenForEvent("_bondleveldirty", OnBondLevelDirty)
		end
		OnBondLevelDirty(inst)
	end
end

----------------------------------------------------------------------------------------

local function do_chargeregen_update(inst)
	if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
		inst.components.upgrademoduleowner:AddCharge(1)
	end
end

local function OnUpgradeModuleChargeChanged(inst, data)
	-- The regen timer gets reset every time the energy level changes, whether it was by the regen timer or not.
	inst.components.timer:StopTimer(CHARGEREGEN_TIMERNAME)

	if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
		inst.components.timer:StartTimer(CHARGEREGEN_TIMERNAME, Wunny_GetChargeRegenTime())

		-- If we just got put to 0 from a non-0 value, tell the player.
		if data.old_level ~= 0 and data.new_level == 0 then
			inst.components.talker:Say(GetString(inst, "ANNOUNCE_DISCHARGE"))
		end
	else
		-- If our charge is maxed (this is a post-assignment callback), and our previous charge was not,
		-- we just hit the max, so tell the player.
		if data.old_level ~= inst.components.upgrademoduleowner.max_charge then
			inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARGE"))
		end
	end
end

local function ResetOrStartWobyBuckTimer(inst)
	if inst.components.timer:TimerExists("wobybuck") then
		inst.components.timer:SetTimeLeft("wobybuck", TUNING.WALTER_WOBYBUCK_DECAY_TIME)
	else
		inst.components.timer:StartTimer("wobybuck", TUNING.WALTER_WOBYBUCK_DECAY_TIME)
	end
end

local function on_show_warp_marker(inst)
	inst.components.positionalwarp:EnableMarker(true)
end

local function on_hide_warp_marker(inst)
	inst.components.positionalwarp:EnableMarker(false)
end

local function DelayedWarpBackTalker(inst)
	-- if the player starts moving right away then we can skip this
	if inst.sg == nil or inst.sg:HasStateTag("idle") then
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_POCKETWATCH_RECALL"))
	end
end

local function OnWarpBack(inst, data)
	if inst.components.positionalwarp ~= nil then
		if data ~= nil and data.reset_warp then
			inst.components.positionalwarp:Reset()
			inst:DoTaskInTime(15 * FRAMES, DelayedWarpBackTalker)
		else
			inst.components.positionalwarp:GetHistoryPosition(true)
		end
	end
end

local function OnTimerDone(inst, data)
	if data and data.name == "wobybuck" then
		inst._wobybuck_damage = 0
	end
end

local function OnAttacked(inst, data)
	if inst.components.rider:IsRiding() then
		local mount = inst.components.rider:GetMount()
		if mount:HasTag("woby") then
			local damage = data and data.damage or TUNING.WALTER_WOBYBUCK_DAMAGE_MAX * 0.5 -- Fallback in case of mods.
			inst._wobybuck_damage = inst._wobybuck_damage + damage
			if inst._wobybuck_damage >= TUNING.WALTER_WOBYBUCK_DAMAGE_MAX then
				inst.components.timer:StopTimer("wobybuck")
				inst._wobybuck_damage = 0
				mount.components.rideable:Buck()
			else
				ResetOrStartWobyBuckTimer(inst)
			end
		end
	end
end

local function OnWobyTransformed(inst, woby)
	if inst.woby ~= nil then
		inst:RemoveEventCallback("onremove", inst._woby_onremove, inst.woby)
	end

	inst.woby = woby
	inst:ListenForEvent("onremove", inst._woby_onremove, woby)
end

local function OnWobyRemoved(inst)
	inst.woby = nil
	inst._replacewobytask = inst:DoTaskInTime(1, function(i)
		i._replacewobytask = nil
		if i.woby == nil then
			SpawnWoby(i)
		end
	end)
end

local function OnRemoveEntity(inst)
	-- hack to remove pets when spawned due to session state reconstruction for autosave snapshots
	if inst.woby ~= nil and inst.woby.spawntime == GetTime() then
		inst:RemoveEventCallback("onremove", inst._woby_onremove, inst.woby)
		inst.woby:Remove()
	end

	if inst._story_proxy ~= nil and inst._story_proxy:IsValid() then
		inst._story_proxy:Remove()
	end
end

local function ForceDespawnShadowMinions(inst)
	local todespawn = {}
	for k, v in pairs(inst.components.petleash:GetPets()) do
		if v:HasTag("shadowminion") then
			table.insert(todespawn, v)
		end
	end
	for i, v in ipairs(todespawn) do
		inst.components.petleash:DespawnPet(v)
	end
end

local function OnDespawn(inst, migrationdata)
	if inst.woby ~= nil then
		inst.woby:OnPlayerLinkDespawn()
		inst.woby:PushEvent("player_despawn")
	end

	if migrationdata ~= nil then
		ForceDespawnShadowMinions(inst)
	end
end

-- When the character is revived from human
local function onbecamehuman(inst, data, isloading)
	-- Set speed when not a ghost (optional)
	--resistencia da willow
	inst.components.freezable:SetResistance(3)
	-- inst.components.locomotor.runspeed = 7.2
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunnySpeed", 1.25)

	inst.components.locomotor.walkspeed = 6
	inst.runningSpeed = 1.2

	--Wanda
	if inst.components.positionalwarp ~= nil then
		if not isloading then
			inst.components.positionalwarp:Reset()
		end
		if inst.components.inventory:HasItemWithTag("pocketwatch_warp", 1) then
			inst.components.positionalwarp:EnableMarker(true)
		end
	end
	-- inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunny_speed_mod", 1)

	inst.Light:Enable(false)
	inst.Light:SetRadius(2)
	inst.Light:SetFalloff(0.75)
	inst.Light:SetIntensity(0.9)
	inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)

	if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
		inst.components.timer:StartTimer(CHARGEREGEN_TIMERNAME, Wunny_GetChargeRegenTime())
	end
	inst.components.ghostlybond:SetBondLevel(1)
	inst.components.ghostlybond:ResumeBonding()
end

local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
	-- inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wunny_speed_mod")
	for k, v in pairs(inst.components.petleash:GetPets()) do
		if v:HasTag("shadowminion") then
			inst:RemoveEventCallback("onremove", inst._onpetlost, v)
			inst.components.sanity:RemoveSanityPenalty(v)
			if v._killtask == nil then
				v._killtask = v:DoTaskInTime(math.random(), KillPet)
			end
		end
	end
	if not GetGameModeProperty("no_sanity") then
		inst.components.sanity.ignore = false
		inst.components.sanity:SetPercent(0.5, true)
		inst.components.sanity.ignore = true
	end

	--Wanda
	if inst.components.positionalwarp ~= nil then
		inst.components.positionalwarp:EnableMarker(false)
	end

	stop_moisturetracking(inst)
	inst.components.timer:StopTimer(HUNGERDRAIN_TIMERNAME)
	inst.components.timer:StopTimer(CHARGEREGEN_TIMERNAME)

	inst.components.ghostlybond:Recall()
	inst.components.ghostlybond:PauseBonding()
	for k, v in pairs(inst.components.petleash:GetPets()) do
		if v:HasTag("shadowminion") and v._killtask == nil then
			v._killtask = v:DoTaskInTime(math.random(), KillPet)
		end
	end

	-- wx78 (Chassis): se um corpo reserva está prestes a ser criado (setado por
	-- player_common_extensions.lua:OnPlayerDeath ao ativar wx78_ghostrevive_2),
	-- não descarta os módulos/carga aqui — TryToSpawnBackupBody cuida disso.
	if not inst.wx78_backupbody_save then
		inst.components.upgrademoduleowner:PopAllModules()
		inst.components.upgrademoduleowner:SetChargeLevel(0)
	end

	stop_moisturetracking(inst)
	inst.components.timer:StopTimer(HUNGERDRAIN_TIMERNAME)
	inst.components.timer:StopTimer(CHARGEREGEN_TIMERNAME)

	if inst._gears_eaten > 0 then
		local dropgears = math.random(math.floor(inst._gears_eaten / 3), math.ceil(inst._gears_eaten / 2))
		local x, y, z = inst.Transform:GetWorldPosition()
		for i = 1, dropgears do
			local gear = SpawnPrefab("gears")
			if gear ~= nil then
				if gear.Physics ~= nil then
					local speed = 2 + math.random()
					local angle = math.random() * 2 * PI
					gear.Physics:Teleport(x, y + 1, z)
					gear.Physics:SetVel(speed * math.cos(angle), speed * 3, speed * math.sin(angle))
				else
					gear.Transform:SetPosition(x, y, z)
				end

				if gear.components.propagator ~= nil then
					gear.components.propagator:Delay(5)
				end
			end
		end

		inst._gears_eaten = 0
	end
end

-- When loading or spawning the character
local function onload(inst, data)
	inst.components.magician:StopUsing()
	-- OnSkinsChanged(inst, {nofx = true})

	inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
	inst:ListenForEvent("ms_becameghost", onbecameghost)

	if inst:HasTag("playerghost") then
		onbecameghost(inst)
	else
		onbecamehuman(inst)
	end

	if data ~= nil then
		if data.king ~= nil then
			inst.king = data.king
			TheWorld:AddTag("hasbunnyking")
			TheWorld:PushEvent("upgradeBunnys")
		end
		-- restaura o guard de "já recebi o bônus" antes de qualquer
		-- onbunnykingcreated poder chegar de novo (ver RoyalUpgrade)
		inst._has_royal_buff = data.has_royal_buff or nil
		if data.woby ~= nil then
			inst._woby_spawntask:Cancel()
			inst._woby_spawntask = nil

			local woby = SpawnSaveRecord(data.woby)
			inst.woby = woby
			if woby ~= nil then
				if inst.migrationpets ~= nil then
					table.insert(inst.migrationpets, woby)
				end
				woby:LinkToPlayer(inst)

				woby.AnimState:SetMultColour(0, 0, 0, 1)
				woby.components.colourtweener:StartTween({ 1, 1, 1, 1 }, 19 * FRAMES)
				local fx = SpawnPrefab(woby.spawnfx)
				fx.entity:SetParent(woby.entity)

				inst:ListenForEvent("onremove", inst._woby_onremove, woby)
			end
		end
		inst._wobybuck_damage = data.buckdamage or 0

		if data.science_bonus then
			inst.components.builder.science_bonus = data.science_bonus
		end
		if data.magic_bonus then
			inst.components.builder.magic_bonus = data.magic_bonus
		end
		if data.seafaring_bonus then
			inst.components.builder.seafaring_bonus = data.seafaring_bonus
		end
		if data.bookcraft_bonus then
			inst.components.builder.bookcraft_bonus = data.bookcraft_bonus
		end
		if data.fishing_bonus then
			inst.components.builder.fishing_bonus = data.fishing_bonus
		end

		if data.nivelDaBarba then
			inst.nivelDaBarba = data.nivelDaBarba
		end
		if data.sanityPercent then
			inst.components.sanity:SetPercent(data.sanityPercent)
		end

		if data.wortox_freehops ~= nil then
			inst._wortox_freesoulhop_counter = data.wortox_freehops
		end
		if data.wortox_soulhopcost ~= nil then
			inst._wortox_soulhop_cost = data.wortox_soulhopcost
		end
		inst:DoTaskInTime(0, Wortox_SetNetvar)
	end
	if data ~= nil then
		if data.gears_eaten ~= nil then
			inst._gears_eaten = data.gears_eaten
		end

		-- Compatability with pre-refresh WX saves
		if data.level ~= nil then
			inst._gears_eaten = (inst._gears_eaten or 0) + data.level
		end

		if data.maxHealth ~= nil then
			inst.components.health:SetMaxHealth(data.maxHealth)
		end
		if data.maxHunger ~= nil then
			inst.components.hunger:SetMax(data.maxHunger)
		end
		if data.maxSanity ~= nil then
			inst.components.sanity:SetMax(data.maxSanity)
		end

		--WURT
		if data.health_percent then
			inst.health_percent = data.health_percent
		end

		if data.sanity_percent then
			inst.sanity_percent = data.sanity_percent
		end

		if data.hunger_percent then
			inst.hunger_percent = data.hunger_percent
		end
		-- WX-78 needs to manually save/load health, hunger, and sanity, in case their maxes
		-- were modified by upgrade circuits, because those components only save current,
		-- and that gets overridden by the default max values during construction.
		-- So, if we wait to re-apply them in our OnLoad, we will have them properly
		-- (as entity OnLoad runs after component OnLoads)
		if data._wx78_health then
			inst.components.health:SetCurrentHealth(data._wx78_health)
		end

		if data._wx78_sanity then
			inst.components.sanity.current = data._wx78_sanity
		end

		if data._wx78_hunger then
			inst.components.hunger.current = data._wx78_hunger
		end
	end

	if data ~= nil then
		if data.abigail ~= nil then -- retrofitting
			inst.components.inventory:GiveItem(SpawnPrefab("abigail_flower"))
		end

		if data.questghost ~= nil and inst.questghost == nil then
			local questghost = SpawnSaveRecord(data.questghost)
			if questghost ~= nil then
				if inst.migrationpets ~= nil then
					table.insert(inst.migrationpets, questghost)
				end
				questghost.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")
				questghost:LinkToPlayer(inst)
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- Wortox: sistema de almas (núcleo apenas — sem reviver jogadores, souljar,
-- moral nice/naughty, decoy ou flauta de pã). Baseado em prefabs/wortox.lua e
-- prefabs/wortox_soul_common.lua. A cura de vida em si acontece sozinha,
-- embutida no item "wortox_soul" (ele cura ao ficar um tempo no bolso sem ser
-- comido) — nada disso precisa de código extra aqui.
--------------------------------------------------------------------------------------

local function Wortox_IsSoul(item)
	return item.prefab == "wortox_soul"
end

local function Wortox_PutSoulOnCooldown(item, cooldowntime, overridepercent)
	if not Wortox_IsSoul(item) then
		return
	end
	if item.components.rechargeable ~= nil then
		item.components.rechargeable:Discharge(cooldowntime)
		if overridepercent then
			item.components.rechargeable:SetPercent(overridepercent)
		end
	end
end

local function Wortox_RemoveSoulCooldown(item)
	if not Wortox_IsSoul(item) then
		return
	end
	if item.components.rechargeable ~= nil then
		item.components.rechargeable:SetPercent(1)
	end
end

local function Wortox_GetSouls(inst)
	local souls = inst.components.inventory:FindItems(Wortox_IsSoul)
	local count = 0
	for i, v in ipairs(souls) do
		count = count + GetStackSize(v)
	end
	return souls, count
end

local function Wortox_ClearNoSoulTask(victim)
	victim.nosoultask = nil
end

--Alma cai perto de uma morte (mob morrendo perto da Wunny), ou ela mesma mata algo.
local function Wortox_OnEntityDropLoot(inst, data)
	local victim = data.inst
	if not victim or victim.nosoultask or not victim:IsValid() then
		return
	end
	local shouldspawn = victim == inst
	if shouldspawn or (
		not inst.components.health:IsDead() and
		WortoxSoulCommon.HasSoul(victim) and (victim.components.health:IsDead() or data.explosive)
	) then
		if not shouldspawn then
			shouldspawn = inst:IsNear(victim, TUNING.WORTOX_SOULEXTRACT_RANGE)
		end
		if shouldspawn then
			--Evita múltiplas almas do mesmo cadáver se mais de uma Wunny/Wortox estiver por perto
			victim.nosoultask = victim:DoTaskInTime(5, Wortox_ClearNoSoulTask)
			WortoxSoulCommon.SpawnSoulsAt(victim, WortoxSoulCommon.GetNumSouls(victim))
		end
	end
end

local function Wortox_OnEntityDeath(inst, data)
	if data.inst ~= nil
		and (data.inst.components.lootdropper == nil or data.inst.components.lootdropper.forcewortoxsouls or data.explosive or data.corpsing) then
		Wortox_OnEntityDropLoot(inst, data)
	end
end

--Alma direto no bolso ao matar outro jogador em PVP
local function Wortox_OnMurdered(inst, data)
	if data.incinerated then
		return
	end
	local victim = data.victim
	if victim ~= nil and
		victim.nosoultask == nil and
		victim:IsValid() and
		not inst.components.health:IsDead() and
		WortoxSoulCommon.HasSoul(victim) then
		victim.nosoultask = victim:DoTaskInTime(5, Wortox_ClearNoSoulTask)
		WortoxSoulCommon.GiveSouls(inst, WortoxSoulCommon.GetNumSouls(victim) * (data.stackmult or 1), inst:GetPosition())
	end
end

local function Wortox_OnRespawnedFromGhost(inst)
	if inst._wortox_onentitydroplootfn == nil then
		inst._wortox_onentitydroplootfn = function(src, data) Wortox_OnEntityDropLoot(inst, data) end
		inst:ListenForEvent("entity_droploot", inst._wortox_onentitydroplootfn, TheWorld)
	end
	if inst._wortox_onentitydeathfn == nil then
		inst._wortox_onentitydeathfn = function(src, data) Wortox_OnEntityDeath(inst, data) end
		inst:ListenForEvent("entity_death", inst._wortox_onentitydeathfn, TheWorld)
	end
end

local function Wortox_OnBecameGhost(inst)
	if inst._wortox_onentitydroplootfn ~= nil then
		inst:RemoveEventCallback("entity_droploot", inst._wortox_onentitydroplootfn, TheWorld)
		inst._wortox_onentitydroplootfn = nil
	end
	if inst._wortox_onentitydeathfn ~= nil then
		inst:RemoveEventCallback("entity_death", inst._wortox_onentitydeathfn, TheWorld)
		inst._wortox_onentitydeathfn = nil
	end
end

--Comer uma alma manualmente (ação normal de "comer" via souleater): satisfação de
--fome + pequeno custo de sanidade. A cura por almas acontece sozinha (ver nota acima).
local function Wortox_OnEatSoul(inst, soul)
	inst.components.hunger:DoDelta(TUNING.CALORIES_MED)
	inst.components.sanity:DoDelta(-TUNING.SANITY_TINY)
end

--------------------------------------------------------------------------------------
-- Wortox: teleporte "Soul Hop" (clique direito no chão consome uma alma e
-- teleporta a Wunny até lá). Os estados de animação (portal_jumpin_pre/
-- portal_jumpin/portal_jumpout) já existem prontos em SGwilson.lua,
-- condicionados a inst:HasTag("soulstealer") — não precisamos portar stategraph.
--------------------------------------------------------------------------------------

local function Wortox_IsNotBlocked(pt)
	return TheWorld.Map:IsPassableAtPoint(pt:Get()) and not TheWorld.Map:IsGroundTargetBlocked(pt)
end

local function Wortox_CanBlinkTo(inst, pt)
	local x, y, z = inst.Transform:GetWorldPosition()
	return Wortox_IsNotBlocked(pt) and IsTeleportingPermittedFromPointToPoint(x, y, z, pt.x, pt.y, pt.z)
end

local function Wortox_CanBlinkFromWithMap(inst, pt)
	local x, y, z = inst.Transform:GetWorldPosition()
	return IsTeleportingPermittedFromPointToPoint(x, y, z, pt.x, pt.y, pt.z)
end

----------------------------------------------------------------------------------------
-- Winona (skill "winona_charlie_1"): mira do close-inspect dos óculos rosados.
--
-- Porte de winona.lua:ReticuleTargetFn. Procura, de fora pra dentro, o ponto mais
-- distante à frente da Wunny que ainda seja inspecionável; se nenhum servir,
-- devolve a posição dela mesma (é o que o vanilla faz).
----------------------------------------------------------------------------------------
local function Winona_ReticuleTargetFn(inst)
	local pos = Vector3()
	for r = 2.5, 1, -.25 do
		pos.x, pos.y, pos.z = inst.entity:LocalToWorldSpace(r, 0, 0)
		if CLOSEINSPECTORUTIL.IsValidPos(inst, pos) then
			return pos
		end
	end
	pos.x, pos.y, pos.z = inst.Transform:GetWorldPosition()
	return pos
end

--Wunny está usando os óculos rosados no modo close-inspect? Nesse caso a mira
--tem que ser a da Winona, não a de teleporte do Wortox — o componente reticule
--do jogador só tem UM targetfn.
local function Winona_IsCloseInspecting(inst)
	local inventory = inst.replica.inventory
	local hat = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
	return hat ~= nil and hat.prefab == "roseglasseshat" and hat:HasTag("closeinspector")
end

local function Wortox_ReticuleTargetFn(inst)
	if Winona_IsCloseInspecting(inst) then
		return Winona_ReticuleTargetFn(inst)
	end
	return ControllerReticle_Blink_GetPosition(inst, Wortox_IsNotBlocked)
end

local function Wortox_CanSoulhop(inst, souls)
	if inst.replica.inventory:Has("wortox_soul", souls or 1) then
		local rider = inst.replica.rider
		if rider == nil or not rider:IsRiding() then
			return true
		end
	end
	return false
end

local function Wortox_GetPointSpecialActions(inst, pos, useitem, right, usereticulepos)
	local actions = {}
	-- O bloco da tocha do Wilson mais abaixo sobrescreve `useitem` com o item da
	-- mão quando ele vem nil; o bloco dos óculos rosados da Winona (depois dele)
	-- precisa do valor ORIGINAL pra decidir se pode olhar o slot da cabeça.
	local orig_useitem = useitem
	if right and useitem == nil then
		if inst.checkingmapactions then
			local canblink = inst:CanBlinkFromWithMap(inst.checkingmapactions_pos or inst:GetPosition())
			if canblink and inst.CanSoulhop and inst:CanSoulhop() then
				table.insert(actions, ACTIONS.BLINK)
			end

			-- wx78 (Chassis/Drones): ações de mapa "trocar de corpo remotamente"
			-- e "escolher drone de escaneamento" — mesma checagem vanilla de
			-- wx78.lua:GetPointSpecialActions.
			if inst.components.skilltreeupdater then
				if inst.components.skilltreeupdater:IsActivated("wx78_remotebodyswap") then
					table.insert(actions, ACTIONS.SWAPBODIES_MAP)
				end
				if inst.components.skilltreeupdater:IsActivated("wx78_scoutdrone_1") then
					table.insert(actions, ACTIONS.MAPSCOUTSELECT_MAP)
				end
			end

			-- Rede de tocas (fast-travel): habilidade original da Wunny, sem
			-- gate de skill tree. A validade real (existe uma toca perto do
			-- clique?) é resolvida em ACTIONS.WUNNY_BURROWTRAVEL_MAP.maponly_checkvalidpos_fn.
			table.insert(actions, ACTIONS.WUNNY_BURROWTRAVEL_MAP)
		else
			local canblink = inst:CanBlinkTo(pos)
			if canblink and inst.CanSoulhop and inst:CanSoulhop() then
				table.insert(actions, ACTIONS.BLINK)
			end

			if inst.components.playercontroller ~= nil and inst.components.playercontroller.isclientcontrollerattached then
				if inst.CollectUpgradeModuleActions then
					inst:CollectUpgradeModuleActions(actions)
				end
			end
		end
	end

	-- Wilson (skill "wilson_torch_7"): arremessar a tocha acesa. Porte de
	-- wilson.lua:GetPointSpecialActions.
	--
	-- Fica FORA do "if right and useitem == nil" acima de propósito: o toss
	-- exige justamente um useitem (a tocha equipada na mão), enquanto todas as
	-- ações do Wortox/wx78 acima exigem useitem == nil. Como o
	-- playeractionpicker só aceita UM pointspecialactionsfn, e a Wunny já usa
	-- esse slot pro Wortox (ver Wortox_OnSetOwner), as duas famílias de ação
	-- têm que conviver na mesma função em vez de ter uma fn própria.
	if right then
		if useitem == nil then
			local inventory = inst.replica.inventory
			if inventory ~= nil then
				useitem = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			end
		end
		if useitem ~= nil and
			useitem.prefab == "torch" and
			inst.components.skilltreeupdater ~= nil and
			inst.components.skilltreeupdater:IsActivated("wilson_torch_7") and
			useitem:HasTag("special_action_toss")
		then
			table.insert(actions, ACTIONS.TOSS)
		end
	end

	-- Winona (skill "winona_charlie_1"): inspecionar um ponto do chão com os óculos
	-- rosados. Porte de winona.lua:GetPointSpecialActions.
	--
	-- Mesmo motivo do toss da tocha acima pra estar aqui dentro: só existe um
	-- pointspecialactionsfn por jogador. Este é o único caso que devolve o segundo
	-- retorno (pos2) — playeractionpicker.lua:230 já aceita, e as famílias
	-- anteriores continuam devolvendo só a lista.
	if right then
		local hat = orig_useitem
		if hat == nil then
			local inventory = inst.replica.inventory
			if inventory ~= nil then
				hat = inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
			end
		end
		if hat ~= nil and hat.prefab == "roseglasseshat" and hat:HasTag("closeinspector") then
			--tem que casar com Winona_ReticuleTargetFn acima
			if usereticulepos then
				local pos2 = Vector3()
				for r = 2.5, 1, -.25 do
					pos2.x, pos2.y, pos2.z = inst.entity:LocalToWorldSpace(r, 0, 0)
					if CLOSEINSPECTORUTIL.IsValidPos(inst, pos2) then
						table.insert(actions, ACTIONS.LOOKAT)
						return actions, pos2
					end
				end
			end

			if CLOSEINSPECTORUTIL.IsValidPos(inst, pos) then
				table.insert(actions, ACTIONS.LOOKAT)
			end
		end
	end

	return actions
end

local function Wortox_OnSetOwner(inst)
	if inst.components.playeractionpicker ~= nil then
		inst.components.playeractionpicker.pointspecialactionsfn = Wortox_GetPointSpecialActions
	end
end

----------------------------------------------------------------------------------------
-- wx78 (Chassis / Drones): entidade "classificada" (wx78_classified) que carrega os
-- netvars de corpos reserva e drones de escaneamento. Sem ela, as receitas vanilla que
-- checam "builder.wx78_classified:GetNumFreeBackupBodies()/GetNumFreeScoutingDrones()"
-- (wx78_backupbody, wx78_drone_scout etc.) nunca liberam pra Wunny, mesmo com as skills
-- de Chassis/Drones "ativadas" via IsActivated.
----------------------------------------------------------------------------------------

local function Wunny_AttachClassified_wx78(inst, classified)
	inst.wx78_classified = classified
	inst.ondetach_wx78_classified = function() inst:DetachClassified_wx78() end
	inst:ListenForEvent("onremove", inst.ondetach_wx78_classified, classified)
end

local function Wunny_DetachClassified_wx78(inst)
	inst.wx78_classified = nil
	inst.ondetach_wx78_classified = nil
end

local function Wunny_OnSetOwner_wx78Classified(inst)
	if TheWorld.ismastersim and inst.wx78_classified ~= nil then
		inst.wx78_classified.Network:SetClassifiedTarget(inst)
	end
end

local function Wunny_OnRemoveEntity_wx78Classified(inst)
	if inst.wx78_classified ~= nil then
		if TheWorld.ismastersim then
			inst.wx78_classified:Remove()
			inst.wx78_classified = nil
		else
			inst.wx78_classified._parent = nil
			inst:RemoveEventCallback("onremove", inst.ondetach_wx78_classified, inst.wx78_classified)
			inst:DetachClassified_wx78()
		end
	end
end

-- Corpo reserva (Chassis): mesma lógica de wx78.lua CanSpawnBackupBody/TryToSpawnBackupBody.
-- Chamada pelo stategraph genérico do jogador (SGwilson.lua) quando
-- inst.wx78_backupbody_save foi setado (feito automaticamente por
-- player_common_extensions.lua:OnPlayerDeath ao checar IsActivated("wx78_ghostrevive_2")).
local function Wunny_CanSpawnBackupBody(inst)
	return (inst.wx78_classified and inst.wx78_classified:GetNumFreeBackupBodies() or 0) > 0
end

local function Wunny_TryToSpawnBackupBody(inst)
	inst.wx78_backupbody_save = nil
	if Wunny_CanSpawnBackupBody(inst) then
		local x, y, z = inst.Transform:GetWorldPosition()
		local body = SpawnPrefab("wx78_backupbody")
		body._hide_body_skinfx = true
		body.components.upgrademoduleowner:SetChargeLevel(0)
		if inst.components.upgrademoduleowner then
			inst.components.upgrademoduleowner:SetChargeLevel(0)
		end
		body.Transform:SetPosition(x, y, z)
		if not body.components.activatable:CanActivate(inst) then
			body:Remove()
			return false
		end
		if not body.components.activatable:DoActivate(inst) then
			body:Remove()
			return false
		end
		inst.wx78_backupbody_save_inst = body
		body._Light_value = body.Light:IsEnabled()
		body:RemoveFromScene()
		return true
	end
	inst.components.upgrademoduleowner:PopAllModules()
	inst.components.upgrademoduleowner:SetChargeLevel(0)
	return false
end

-- Drones (escaneamento): atualiza o contador de rede usado pela receita do
-- wx78_drone_scout (getlimitedrecipecount -> GetNumFreeScoutingDrones).
local function Wunny_OnDroneStartTracking(inst, drone)
	if inst.wx78_classified then
		inst.wx78_classified.numdronescouts:set(inst.wx78_classified.numdronescouts:value() + 1)
		if inst.HUD then
			inst:PushEvent("refreshcrafting")
		end
	end
end

local function Wunny_OnDroneStopTracking(inst, drone)
	if inst.wx78_classified then
		inst.wx78_classified.numdronescouts:set(inst.wx78_classified.numdronescouts:value() - 1)
		if inst.HUD then
			inst:PushEvent("refreshcrafting")
		end
	end
end

Wortox_SetNetvar = function(inst)
	if inst.player_classified ~= nil then
		inst.player_classified.freesoulhops:set(inst._wortox_freesoulhop_counter)
	end
end

local function Wortox_ClearSoulhopCounter(inst)
	inst._wortox_freesoulhop_counter = 0
	inst._wortox_soulhop_cost = 0
	Wortox_SetNetvar(inst)
end

local function Wortox_FinishPortalHop(inst)
	if inst._wortox_finishportalhoptask ~= nil then
		inst._wortox_finishportalhoptask:Cancel()
		inst._wortox_finishportalhoptask = nil
	end
	if inst._wortox_freesoulhop_counter > 0 then
		if inst.components.inventory ~= nil then
			inst.components.inventory:ConsumeByName("wortox_soul", math.max(math.ceil(inst._wortox_soulhop_cost), 1))
		end
		Wortox_ClearSoulhopCounter(inst)
	end
end

local function Wortox_GetHopsPerSoul(inst)
	return TUNING.WORTOX_FREEHOP_HOPSPERSOUL
end

local function Wortox_GetSoulEchoCooldownTime(inst)
	return TUNING.WORTOX_FREEHOP_TIMELIMIT
end

local function Wortox_TryToPortalHop(inst, souls, consumeall)
	local invcmp = inst.components.inventory
	if invcmp == nil then
		return false
	end

	souls = souls or 1
	local _, soulscount = inst:GetSouls()
	if soulscount < souls then
		return false
	end

	inst._wortox_freesoulhop_counter = inst._wortox_freesoulhop_counter + souls
	inst._wortox_soulhop_cost = inst._wortox_soulhop_cost + souls

	if not consumeall and inst._wortox_freesoulhop_counter < inst:GetHopsPerSoul() then
		inst._wortox_soulhop_cost = inst._wortox_soulhop_cost - souls -- Grátis (combo de soul echo).
		local cooldowntime = inst:GetSoulEchoCooldownTime()
		invcmp:ForEachItem(Wortox_PutSoulOnCooldown, cooldowntime)
		if inst._wortox_finishportalhoptask ~= nil then
			inst._wortox_finishportalhoptask:Cancel()
		end
		inst._wortox_finishportalhoptask = inst:DoTaskInTime(cooldowntime, inst.FinishPortalHop)
	else
		invcmp:ForEachItem(Wortox_RemoveSoulCooldown)
		inst:FinishPortalHop()
	end
	Wortox_SetNetvar(inst)

	return true
end

--Wolfgang (mightiness / disposição física) — só o núcleo mecânico: ganha/perde
--"mightiness" batalhando e trabalhando, com efeitos de dano/eficiência/fome por
--estado. Sem academia, coach ou bônus de dano planar (ligados a skilltree/gym
--do Wolfgang). A parte visual usa só ApplyAnimScale (a Wunny não tem builds
--alternativos tipo "wolfgang_skinny"/"wolfgang_mighty"), então BecomeState é
--sobrescrito por instância (abaixo, no master_postinit) para não chamar
--skinner:SetSkinMode com nomes de build do Wolfgang.
local function Wunny_MightinessScale(state)
	return state == "wimpy" and 0.9 or state == "mighty" and 1.2 or 1
end

local function Wunny_MightinessBecomeState(self, state)
	if not self:CanTransform(state) then
		return
	end

	local damagemult = state == "wimpy" and 0.75 or state == "mighty" and 2 or nil
	local work_eff = state == "wimpy" and TUNING.WIMPY_WORK_EFFECTIVENESS or state == "mighty" and TUNING.MIGHTY_WORK_EFFECTIVENESS or nil
	local hunger_mult = state == "wimpy" and TUNING.WIMPY_HUNGER_RATE_MULT or nil

	if damagemult ~= nil then
		self.inst.components.combat.externaldamagemultipliers:SetModifier(self.inst, damagemult)
	else
		self.inst.components.combat.externaldamagemultipliers:RemoveModifier(self.inst)
	end

	self.inst.components.hunger.burnrate = hunger_mult or 1

	if work_eff ~= nil then
		self.inst.components.workmultiplier:AddMultiplier(ACTIONS.CHOP, work_eff, self.inst)
		self.inst.components.workmultiplier:AddMultiplier(ACTIONS.MINE, work_eff, self.inst)
		self.inst.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER, work_eff, self.inst)
		self.inst.components.efficientuser:AddMultiplier(ACTIONS.CHOP, work_eff, self.inst)
		self.inst.components.efficientuser:AddMultiplier(ACTIONS.MINE, work_eff, self.inst)
		self.inst.components.efficientuser:AddMultiplier(ACTIONS.HAMMER, work_eff, self.inst)
	else
		self.inst.components.workmultiplier:RemoveMultiplier(ACTIONS.CHOP, self.inst)
		self.inst.components.workmultiplier:RemoveMultiplier(ACTIONS.MINE, self.inst)
		self.inst.components.workmultiplier:RemoveMultiplier(ACTIONS.HAMMER, self.inst)
		self.inst.components.efficientuser:RemoveMultiplier(ACTIONS.CHOP, self.inst)
		self.inst.components.efficientuser:RemoveMultiplier(ACTIONS.MINE, self.inst)
		self.inst.components.efficientuser:RemoveMultiplier(ACTIONS.HAMMER, self.inst)
	end

	if not self.inst:HasTag("ingym") and not self.inst.components.rider:IsRiding() then
		self.inst:ApplyAnimScale("mightiness", Wunny_MightinessScale(state))
	end

	self.inst:RemoveTag("mightiness_" .. self.state)
	self.inst:AddTag("mightiness_" .. state)

	local previous_state = self.state
	self.state = state

	self.inst:PushEvent("mightiness_statechange", { previous_state = previous_state, state = state })
end

local function Wunny_MightinessGetScale(self)
	return Wunny_MightinessScale(self.state)
end

local function Wolfgang_OnHitOther(inst, data)
	local target = data.target
	if target ~= nil and (
			data.weapon == nil or (
				(data.weapon.components.inventoryitem ~= nil and data.weapon.components.inventoryitem:IsHeldBy(inst)) and
				(data.weapon.components.weapon == nil or data.weapon.components.weapon.projectile == nil)
			)) then
		local delta = target:HasTag("epic") and TUNING.WOLFGANG_MIGHTINESS_ATTACK_GAIN_GIANT
			or target:HasTag("smallcreature") and TUNING.WOLFGANG_MIGHTINESS_ATTACK_GAIN_SMALLCREATURE
			or TUNING.WOLFGANG_MIGHTINESS_ATTACK_GAIN_DEFAULT

		inst.components.mightiness:DoDelta(delta)
	end
end

local function Wolfgang_OnDoingWork(inst, data)
	if data ~= nil and data.target ~= nil then
		local workable = data.target.components.workable
		if workable ~= nil then
			local work_action = workable:GetWorkAction()
			if work_action ~= nil then
				local gains = TUNING.WOLFGANG_MIGHTINESS_WORK_GAIN[work_action.id]
				if gains ~= nil then
					inst.components.mightiness:DoDelta(gains)
				end
			end
		end
	end
end

local function Wolfgang_OnTilling(inst)
	inst.components.mightiness:DoDelta(TUNING.WOLFGANG_MIGHTINESS_WORK_GAIN.TILL)
end

-- Precisam existir tanto no client quanto no server (por isso são atribuídas em
-- common_postinit) pois o widget da UI (StatusDisplays:AddMightiness) chama
-- owner:GetMightiness() direto, sem checar nil antes.
local function Wolfgang_GetMightiness(inst)
	if inst.components.mightiness ~= nil then
		return inst.components.mightiness:GetPercent()
	elseif inst.player_classified ~= nil then
		return inst.player_classified.currentmightiness:value() / TUNING.MIGHTINESS_MAX
	else
		return 0
	end
end

local function Wolfgang_GetMightinessRateScale(inst)
	if inst.components.mightiness ~= nil then
		return inst.components.mightiness:GetRateScale()
	elseif inst.player_classified ~= nil then
		return inst.player_classified.mightinessratescale:value()
	else
		return RATE_SCALE.NEUTRAL
	end
end

local function Wolfgang_GetCurrentMightinessState(inst)
	if inst.components.mightiness ~= nil then
		return inst.components.mightiness:GetState()
	elseif inst.player_classified ~= nil then
		local value = inst.player_classified.currentmightiness:value()
		if value >= TUNING.MIGHTY_THRESHOLD then
			return "mighty"
		elseif value >= TUNING.WIMPY_THRESHOLD then
			return "normal"
		else
			return "wimpy"
		end
	else
		return "wimpy"
	end
end

----------------------------------------------------------------------------------------
-- Wilson: skills concedidas de forma permanente.
--
-- Nenhuma destas skills tem `onactivate` (só as duas de allegiance e a beard_7
-- têm), então WunnySkillTree.ApplyAllSkillTreeEffects não faz nada por elas — o
-- efeito inteiro vive em checagens de IsActivated espalhadas pelo jogo, que é
-- justamente o que esta whitelist atende:
--   torch_1..3    -> prefabs/torch.lua getskillfueleffectmodifier (tocha dura mais)
--   torch_4..6    -> prefabs/torch.lua getskillbrightnesseffectmodifier (raio de luz)
--   torch_7       -> ação TOSS (ver Wortox_GetPointSpecialActions)
--   beard_1..3    -> components/beard.lua GetInsulation (isolamento térmico)
--   beard_4..6    -> components/beard.lua OnDayComplete (barba cresce mais rápido)
--   beard_7       -> components/beard.lua UpdateBeardInventory (barba-mochila)
--   alchemy_1..10 -> components/builder.lua (builder_skill das receitas transmute_*)
--
-- As duas de allegiance liberam transmute_horrorfuel/dreadstone/nightmarefuel
-- (shadow) e transmute_purebrilliance/moonglass_charged (lunar). Ficam as duas
-- ligadas, seguindo o que o mod já faz com wx78_allegiance_lunar/shadow: no
-- vanilla elas são exclusivas, aqui a Wunny acumula as duas de propósito.
--
-- Ao contrário da whitelist do wx78 (instalada no master_postinit), esta é
-- instalada no common_postinit porque o menu de crafting é filtrado NO CLIENTE:
-- builder_replica.lua:312 também chama skilltreeupdater:IsActivated(builder_skill).
-- Sem o override no cliente, as ~24 receitas transmute_* simplesmente não
-- apareceriam na aba da Wunny, mesmo o servidor aceitando construí-las.
----------------------------------------------------------------------------------------

local WILSON_SKILLS_ALWAYSON = {
	-- Torch
	wilson_torch_1 = true,
	wilson_torch_2 = true,
	wilson_torch_3 = true,
	wilson_torch_4 = true,
	wilson_torch_5 = true,
	wilson_torch_6 = true,
	wilson_torch_7 = true,
	-- Beard
	wilson_beard_1 = true,
	wilson_beard_2 = true,
	wilson_beard_3 = true,
	wilson_beard_4 = true,
	wilson_beard_5 = true,
	wilson_beard_6 = true,
	wilson_beard_7 = true,
	-- Alchemy (transmutação)
	wilson_alchemy_1 = true,
	wilson_alchemy_2 = true,
	wilson_alchemy_3 = true,
	wilson_alchemy_4 = true,
	wilson_alchemy_5 = true,
	wilson_alchemy_6 = true,
	wilson_alchemy_7 = true,
	wilson_alchemy_8 = true,
	wilson_alchemy_9 = true,
	wilson_alchemy_10 = true,
	-- Allegiance
	wilson_allegiance_shadow = true,
	wilson_allegiance_lunar = true,
}

----------------------------------------------------------------------------------------
-- Willow: skills concedidas de forma permanente.
--
-- Mesma situação do Wilson: das 19 skills abaixo, só willow_controlled_burn_1
-- (tag "controlled_burner") e willow_embers (tag "ember_master") têm onactivate
-- — e essas duas tags já vêm de WunnySkillTree.ApplyAllSkillTreeEffects, que já
-- inclui "willow" na lista de personagens. Todo o resto do efeito vive em
-- checagens de IsActivated dentro dos arquivos do isqueiro/Bernie/brasas:
--   controlled_burn_1  -> prefabs/lighter.lua onattack e prefabs/torch.lua
--                         (ataque com fogo sempre incendeia, sem rolar sorte)
--   controlled_burn_2/3-> components/burnable.lua (duração/dano do fogo controlado)
--   attuned_lighter    -> prefabs/lighter.lua RefreshAttunedSkills (channelcastable)
--   lightradius_1/2    -> prefabs/lighter.lua applyskillbrightness (raio de luz)
--   embers             -> prefabs/willow_ember.lua updatespells (magia Fire Throw)
--                         + queda de brasas (ver Willow_OnEntityDropLoot abaixo)
--   fire_burst/ball/frenzy -> prefabs/willow_ember.lua updatespells (demais magias)
--   bernieregen_1/2    -> prefabs/bernie_big.lua onLeaderChanged (regeneração)
--   berniehealth_1/2   -> prefabs/bernie_big.lua onLeaderChanged (vida máxima)
--   berniespeed_1/2    -> prefabs/bernie_big.lua onLeaderChanged (velocidade)
--   burnignbernie      -> prefabs/bernie_big.lua onLeaderChanged (Bernie flamejante)
--                         [o nome é um typo do vanilla, mantido de propósito]
--   bernieai           -> prefabs/bernie_common.lua hotheaded (acorda perto de
--                         inimigos, sem depender da sanidade) + bernie_big.lua
--   berniesanity_1/2   -> prefabs/bernie_common.lua isleadercrazy (Bernie acorda
--                         com sanidade mais alta)
--
-- As skills de allegiance (shadow/lunar) ficam de FORA a pedido: sem elas o
-- Bernie não vira aliado lunar/sombrio e as duas magias de brasa de aliança não
-- aparecem no spellbook. Os nós "lock" (willow_bernie_lock, willow_allegiance_
-- lock_N) também não entram: são só travas da UI da árvore, ninguém consulta
-- IsActivated neles em tempo de execução.
--
-- Os nós de Bernie exigem a tag "bernieowner" (já adicionada em common_postinit)
-- pra Wunny poder equipar o bernie_inactive; quem popula inst.bigbernies é o
-- próprio bernie_active.lua/berniebigbrain.lua, não o personagem.
----------------------------------------------------------------------------------------

local WILLOW_SKILLS_ALWAYSON = {
	-- Isqueiro / fogo controlado
	willow_controlled_burn_1 = true,
	willow_controlled_burn_2 = true,
	willow_controlled_burn_3 = true,
	willow_attuned_lighter = true,
	willow_lightradius_1 = true,
	willow_lightradius_2 = true,
	-- Brasas (magias do spellbook de willow_ember)
	willow_embers = true,
	willow_fire_burst = true,
	willow_fire_ball = true,
	willow_fire_frenzy = true,
	-- Bernie
	willow_bernieregen_1 = true,
	willow_bernieregen_2 = true,
	willow_berniesanity_1 = true,
	willow_berniesanity_2 = true,
	willow_berniespeed_1 = true,
	willow_berniespeed_2 = true,
	willow_berniehealth_1 = true,
	willow_berniehealth_2 = true,
	willow_bernieai = true,
	willow_burnignbernie = true,
}

----------------------------------------------------------------------------------------
-- Winona: mesma ideia das duas tabelas acima. As skills dela quase todas leem
-- skilltreeupdater DO CONSTRUTOR de uma estrutura de engenharia, não do próprio
-- jogador — cada estrutura chama ConfigureSkillTreeUpgrades(inst, builder) na
-- hora em que é montada e guarda o nível resultante em campos próprios.
--
-- Onde o vanilla lê cada uma:
--   spotlight_heated   -> prefabs/winona_spotlight.lua ConfigureSkillTreeUpgrades
--                         (holofote aquece quem está no facho no inverno)
--   spotlight_range    -> idem (raio/alcance maiores: SPOTLIGHT_*2 em TUNING)
--   portable_structures-> tag "portableengineer" (onactivate; JÁ aplicada por
--                         WunnySkillTree.ApplyAllSkillTreeEffects) -> libera as
--                         receitas winona_*_item e o winona_remote em recipes.lua
--   gadget_recharge    -> prefabs/winona_remote.lua / winona_storage_robot.lua /
--                         winona_telebrella.lua (recarrega mais rápido)
--   battery_idledrain  -> prefabs/winona_battery_low|high.lua UpdateCircuitPower
--                         (baterias não gastam combustível com carga ociosa)
--   battery_efficiency_1/2/3 -> idem + CalcActualFuel (combustível dura +25/50/100%)
--   catapult_speed_1/2/3     -> prefabs/winona_catapult.lua RefreshAttackPeriod
--   catapult_aoe_1/2/3       -> idem (AOE_RADIUS) + SGwinona_catapult.lua
--   catapult_volley_1  -> prefabs/winona_remote.lua (magia de salva pelo controle)
--   catapult_boost_1   -> idem (magia de acelerar catapultas)
--   charlie_1          -> receita roseglasseshat (builder_skill) + prefabs/hats.lua
--                         roseglasses_refreshattunedskills (componente closeinspector)
--   charlie_2          -> imunidade a escuridão (onactivate, JÁ aplicada) +
--                         wormhole.lua / tentacle_pillar_hole.lua / flower.lua
--                         (rastrear buracos de verme, colher flores rosadas)
--   shadow_1/2         -> prefabs/winona_battery_low.lua (abastecer com nightmarefuel
--                         e horrorfuel)
--   shadow_3           -> prefabs/winona_catapult.lua / winona_remote.lua
--                         (munição de sombra e salva elemental)
--   lunar_1/2          -> prefabs/winona_battery_high.lua (abastecer com
--                         purebrilliance / lunarplant_husk)
--   lunar_3            -> munição lunar, mesmos arquivos do shadow_3
--   wagstaff_1         -> tag "inspectacleshatuser" (onactivate, JÁ aplicada) +
--                         receitas inspectacleshat e winona_storage_robot
--   wagstaff_2         -> receitas winona_telebrella e winona_teleport_pad_item +
--                         components/inspectaclesparticipant.lua (caixa melhorada)
--
-- Os nós "lock" (winona_lowshelf_lock, winona_midshelf_lock, winona_portable_
-- structures_lock, winona_charlie_2_lock, winona_wagstaff_2_lock, winona_shadow_3_
-- lock, winona_lunar_3_lock) não entram: são só travas da UI da árvore.
--
-- Ao contrário da Willow, aqui as skills de aliança ENTRAM — segue o mesmo
-- critério já usado pra WX78 em master_postinit, que também libera as duas
-- alianças de uma vez. No vanilla charlie_2 e wagstaff_2 se travam mutuamente
-- (ver lock_open em skilltree_winona.lua); a Wunny fica com as duas.
--
-- A tag "handyperson" continua comentada em common_postinit de propósito (a Wunny
-- tem as cópias wunny_* das estruturas, com tag de construtor "wunny"). O efeito
-- colateral é que `_engineerid` fica nil nas estruturas vanilla: elas funcionam e
-- recebem os bônus de skill normalmente, só não creditam abates à Wunny nem usam
-- o tempo de "sono" mais longo reservado à engenheira. Os NÍVEIS de skill vêm do
-- construtor independentemente dessa tag.
----------------------------------------------------------------------------------------

local WINONA_SKILLS_ALWAYSON = {
	-- Prateleira de baixo
	winona_spotlight_heated = true,
	winona_spotlight_range = true,
	winona_portable_structures = true,
	winona_gadget_recharge = true,
	winona_battery_idledrain = true,
	-- Prateleira do meio: catapulta
	winona_catapult_speed_1 = true,
	winona_catapult_speed_2 = true,
	winona_catapult_speed_3 = true,
	winona_catapult_aoe_1 = true,
	winona_catapult_aoe_2 = true,
	winona_catapult_aoe_3 = true,
	winona_catapult_volley_1 = true,
	winona_catapult_boost_1 = true,
	-- Prateleira do meio: baterias
	winona_battery_efficiency_1 = true,
	winona_battery_efficiency_2 = true,
	winona_battery_efficiency_3 = true,
	-- Aliança sombria (Charlie)
	winona_charlie_1 = true,
	winona_charlie_2 = true,
	winona_shadow_1 = true,
	winona_shadow_2 = true,
	winona_shadow_3 = true,
	-- Aliança lunar (Wagstaff)
	winona_wagstaff_1 = true,
	winona_wagstaff_2 = true,
	winona_lunar_1 = true,
	winona_lunar_2 = true,
	winona_lunar_3 = true,
}

local function Wunny_InstallSkillWhitelist(inst, skills)
	local skilltreeupdater = inst.components.skilltreeupdater
	if skilltreeupdater == nil then
		return
	end
	local IsActivated_prev = skilltreeupdater.IsActivated
	function skilltreeupdater:IsActivated(skill, ...)
		if skills[skill] then
			return true
		end
		return IsActivated_prev(self, skill, ...)
	end
end

--------------------------------------------------------------------------------------
-- Willow: queda de brasas (skill "willow_embers").
--
-- A whitelist acima só faz as MAGIAS aparecerem no spellbook — quem cria as
-- brasas que servem de munição é este bloco, portado de willow.lua. Sem ele a
-- Wunny teria as quatro magias e nunca teria com que pagá-las.
--
-- Estrutura idêntica à do Wortox mais acima no arquivo (Wortox_OnEntityDropLoot /
-- OnEntityDeath / OnRespawnedFromGhost / OnBecameGhost): os dois sistemas ouvem
-- os mesmos eventos globais "entity_droploot"/"entity_death" em TheWorld, cada um
-- com o seu próprio par de callbacks guardado numa variável distinta
-- (inst._willow_* aqui, inst._wortox_* lá) porque RemoveEventCallback casa por
-- função — reaproveitar o mesmo campo desligaria o listener do outro.
--------------------------------------------------------------------------------------

local function Willow_ClearNoEmberTask(victim)
	victim.noembertask = nil
end

local function Willow_IsValidVictim(victim, explosive)
	return WillowEmberCommon.HasEmbers(victim) and (victim.components.health:IsDead() or explosive)
end

local function Willow_OnEntityDropLoot(inst, data)
	local victim = data.inst
	if inst.components.skilltreeupdater:IsActivated("willow_embers") and
		victim ~= nil and
		victim.noembertask == nil and
		victim:IsValid() and
		(victim == inst or
			(not inst.components.health:IsDead() and
				Willow_IsValidVictim(victim) and
				inst:IsNear(victim, TUNING.WILLOW_EMBERDROP_RANGE)
			)
		) then
		--Evita várias Wunnys/Willows por perto gerando brasas do mesmo cadáver
		victim.noembertask = victim:DoTaskInTime(5, Willow_ClearNoEmberTask)
		WillowEmberCommon.SpawnEmbersAt(victim, WillowEmberCommon.GetNumEmbers(victim))
	end
end

local function Willow_OnEntityDeath(inst, data)
	if data.inst ~= nil then
		data.inst._embersource = data.afflicter -- marca quem causou, pra atribuição da brasa
		--Entidades sem lootdropper (ou explosivas) não disparam "entity_droploot",
		--então a morte é o único gancho que sobra pra elas.
		if data.inst.components.lootdropper == nil or data.explosive then
			Willow_OnEntityDropLoot(inst, data)
		end
	end
end

local function Willow_OnRespawnedFromGhost(inst)
	if inst._willow_onentitydroplootfn == nil then
		inst._willow_onentitydroplootfn = function(src, data) Willow_OnEntityDropLoot(inst, data) end
		inst:ListenForEvent("entity_droploot", inst._willow_onentitydroplootfn, TheWorld)
	end
	if inst._willow_onentitydeathfn == nil then
		inst._willow_onentitydeathfn = function(src, data) Willow_OnEntityDeath(inst, data) end
		inst:ListenForEvent("entity_death", inst._willow_onentitydeathfn, TheWorld)
	end
end

local function Willow_OnBecameGhost(inst)
	if inst._willow_onentitydroplootfn ~= nil then
		inst:RemoveEventCallback("entity_droploot", inst._willow_onentitydroplootfn, TheWorld)
		inst._willow_onentitydroplootfn = nil
	end
	if inst._willow_onentitydeathfn ~= nil then
		inst:RemoveEventCallback("entity_death", inst._willow_onentitydeathfn, TheWorld)
		inst._willow_onentitydeathfn = nil
	end
end

--Bônus de dano da magia Fire Frenzy (skill "willow_fire_frenzy"): a tag
--"firefrenzy" é aplicada pelo debuff buff_firefrenzy, mas o multiplicador em si
--mora no customdamagemultfn do personagem — sem isto a magia daria a tag e
--nenhum dano extra.
local function Willow_CustomCombatDamage(inst, target, weapon, multiplier, mount)
	if target.components.burnable and target.components.burnable:IsBurning() and inst:HasTag("firefrenzy") then
		return TUNING.WILLOW_FIREFRENZY_MULT
	end
end

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst)
	-- Minimap icon
	inst.MiniMapEntity:SetIcon("wunny.tex")

	--Webber
	inst:AddTag("spiderwhisperer")
	inst:AddTag(UPGRADETYPES.SPIDER .. "_upgradeuser")

	--Wendy
	-- inst:AddTag("ghostlyfriend")
	-- inst:AddTag("elixirbrewer")

	--Wes
	-- inst:AddTag("mime")
	-- inst:AddTag("balloonomancer")

	--wickerbottom
	inst:AddTag("bookbuilder")

	--willow
	-- inst:AddTag("pyromaniac")
	inst:AddTag("expertchef")
	inst:AddTag("bernieowner")
	-- inst.components.sanity.custom_rate_fn = sanityfn

	--winona
	-- inst:AddTag("handyperson")

	--wolfgang
	-- "strongman" é o que faz a UI da barra de mightiness (StatusDisplays:AddMightiness)
	-- aparecer — não precisa do componente "strongman" (esse é só do gym) nem
	-- habilita o gym em si, só libera a UI e receitas/checagens de dumbbell
	inst:AddTag("strongman")
	-- mightiness_normal (do componente mightiness) adicionada no estado
	-- pristine por otimização, igual o Wolfgang faz
	inst:AddTag("mightiness_normal")
	inst.GetMightiness = Wolfgang_GetMightiness
	inst.GetMightinessRateScale = Wolfgang_GetMightinessRateScale
	inst.GetCurrentMightinessState = Wolfgang_GetCurrentMightinessState

	--Woodie
	inst:AddTag("woodcutter")
	-- inst:AddTag("werehuman")

	--Wormwood
	inst:AddTag("plantkin")
	-- inst:AddTag("self_fertilizable")

	--Wurt
	-- inst:AddTag("merm_builder")

	--Wortox (soul hop / almas) — implementado abaixo. "monster"/"playermonster" ficam de
	--fora de propósito (não combina com o tema da Wunny); "souleater" é adicionada
	--automaticamente pelo próprio componente.
	inst:AddTag("soulstealer")
	inst._wortox_freesoulhop_counter = 0
	inst._wortox_soulhop_cost = 0
	inst.CanSoulhop = Wortox_CanSoulhop
	inst.CanBlinkTo = Wortox_CanBlinkTo
	inst.CanBlinkFromWithMap = Wortox_CanBlinkFromWithMap
	inst:ListenForEvent("setowner", Wortox_OnSetOwner)

	inst:AddComponent("reticule")
	inst.components.reticule.targetfn = Wortox_ReticuleTargetFn
	inst.components.reticule.ease = true
	inst.components.reticule.twinstickcheckscheme = true
	inst.components.reticule.twinstickmode = 1
	inst.components.reticule.twinstickrange = 15

	--wx78
	-- inst:AddTag("batteryuser")          -- from batteryuser component
	-- inst:AddTag("chessfriend")
	-- inst:AddTag("HASHEATER")            -- from heater component
	-- inst:AddTag("soulless")
	-- inst:AddTag("upgrademoduleowner")

	--Warly
	inst:AddTag("masterchef")
	inst:AddTag("professionalchef")

	--WoodLegs
	-- inst:AddTag("woodlegs")
	-- inst:AddTag("piratecaptain")

	--Walter
	inst:AddTag("pebblemaker")
	-- inst:AddTag("pinetreepioneer")
	-- inst:AddTag("allergictobees")
	inst:AddTag("slingshot_sharpshooter")
	-- inst:AddTag("efficient_sleeper")
	inst:AddTag("dogrider")
	-- inst:AddTag("nowormholesanityloss") -- talvez tirar para balancear
	-- inst:AddTag("storyteller") -- for storyteller component

	--Wanda
	-- inst:AddTag("clockmaker")
	-- inst:AddTag("pocketwatchcaster")

	--Wigfrid
	-- inst:AddTag("valkyrie")
	-- inst:AddTag("battlesinger")

	--Wilson
	inst:AddTag("bearded")

	--Maxwell/Waxwell
	inst:AddTag("shadowmagic")
	inst:AddTag("magician")
	inst:AddTag("reader")

	inst:AddTag("ghostlyfriend")
	inst:AddTag("elixirbrewer")

	--wx78
	inst:AddTag("batteryuser")
	inst:AddTag("HASHEATER")
	inst:AddTag("upgrademoduleowner")

	-- Netvars dos chips plugados (substitui player_classified.upgrademodules,
	-- que nunca existiu de fato pro player_classified vanilla — ver 12slots.lua,
	-- que tentava criar esses netvars mas ficou todo comentado e nem está no
	-- PrefabFiles). Tamanho = WX78_MAXCHARGELEVEL_SKILL pra já cobrir o slot
	-- extra da skill wx78_circuitry_slot_1.
	inst._upgrademodules = {}
	for i = 1, TUNING.WX78_MAXCHARGELEVEL_SKILL do
		inst._upgrademodules[i] = net_smallbyte(inst.GUID, "wunny.upgrademodules"..i, "upgrademoduleslistdirty")
	end

	-- wx78 (Chassis/Drones): precisa existir tanto no client quanto no server pois
	-- é isso que o wx78_classified chama (via OnEntityReplicated) do lado do
	-- cliente quando a entidade classificada é replicada.
	inst.AttachClassified_wx78 = Wunny_AttachClassified_wx78
	inst.DetachClassified_wx78 = Wunny_DetachClassified_wx78
	inst:ListenForEvent("setowner", Wunny_OnSetOwner_wx78Classified)
	inst:ListenForEvent("onremove", Wunny_OnRemoveEntity_wx78Classified)

	-- precisa rodar em common_postinit (server + client) pois é o que
	-- popula inst.GetMaxEnergy/GetEnergyLevel/GetModulesData usados pelo
	-- widget de status secundário (upgrademodulesdisplay.lua) no cliente
	WX78Common.SetupUpgradeModuleOwnerInstanceFunctions(inst)
	-- o mesmo widget também acessa inst.components.wx78_abilitycooldowns
	-- direto (sem checagem de nil), então precisa existir mesmo sem Wunny
	-- ter nenhuma habilidade com cooldown própria ainda
	inst:AddComponent("wx78_abilitycooldowns")

	-- Wilson: server + client (ver comentário em WILSON_SKILLS_ALWAYSON — o
	-- filtro do menu de crafting roda no cliente).
	Wunny_InstallSkillWhitelist(inst, WILSON_SKILLS_ALWAYSON)
	-- Willow: também precisa rodar no cliente. willow_ember.lua monta a lista de
	-- magias do spellbook nos DOIS lados (updatespells é chamada tanto por
	-- topocket no servidor quanto por DoClientUpdateSpells no cliente), então sem
	-- o override no cliente a roda de magias abriria vazia.
	Wunny_InstallSkillWhitelist(inst, WILLOW_SKILLS_ALWAYSON)
	-- Winona: cliente também. As estruturas de engenharia guardam os níveis de
	-- skill em net_vars e reaplicam os bônus visuais no cliente (ex.:
	-- winona_spotlight.lua ApplySkillBonuses ajusta o raio da luz nos dois lados),
	-- e o filtro de receitas por builder_skill (roseglasseshat, inspectacleshat,
	-- winona_telebrella...) roda em builder_replica.lua.
	Wunny_InstallSkillWhitelist(inst, WINONA_SKILLS_ALWAYSON)

	-- Winona (skills "winona_wagstaff_1"/"winona_wagstaff_2"): o inspectacleshat
	-- depende deste componente no dono pra criar/melhorar a caixa de peças. Vem em
	-- common_postinit igual no winona.lua — hats.lua consulta
	-- owner.components.inspectaclesparticipant no cliente também (refreshicon).
	inst:AddComponent("inspectaclesparticipant")

	--double loot
	inst:ListenForEvent("killed", function(inst, data)
		if data.victim.components.lootdropper then
			if data.victim.components.freezable or data.victim:HasTag("monster") then
				data.victim.components.lootdropper:DropLoot()
				inst.components.hunger:DoDelta(-5) --te
				-- inst.components.health:DoDelta(-5) --te
				inst.components.sanity:DoDelta(-5) --te
			end
		end
	end)

	if TheNet:GetServerGameMode() == "quagmire" then
		inst:AddTag("quagmire_grillmaster")
		inst:AddTag("quagmire_shopper")
	else
		if not TheNet:IsDedicated() then
			inst.CreateMoistureMeter = WX78MoistureMeter
		end

		inst._forced_nightvision = net_bool(inst.GUID, "wx78.forced_nightvision", "forced_nightvision_dirty")
		-- Os listeners de playeractivated/playerdeactivated/clientpetskindirty NÃO
		-- entram aqui: eles já são registrados incondicionalmente mais abaixo (junto
		-- do bloco da Wendy). Registrar nos dois lugares fazia OnPlayerActivated
		-- rodar duas vezes por ativação em qualquer modo que não fosse quagmire,
		-- porque ListenForEvent só faz table.insert, sem deduplicar.

		inst:AddComponent("pethealthbar")
	end

	inst.AnimState:AddOverrideBuild("wendy_channel")
	inst.AnimState:AddOverrideBuild("player_idles_wendy")
	inst._bondlevel = net_tinybyte(inst.GUID, "wendy._bondlevel", "_bondleveldirty")
	inst.refreshflowertooltip = net_event(inst.GUID, "refreshflowertooltip")
	inst:ListenForEvent("playeractivated", OnPlayerActivated)
	inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
	inst:ListenForEvent("clientpetskindirty", OnClientPetSkinChanged)
	inst:ListenForEvent("refreshflowertooltip", RefreshFlowerTooltip)

	inst.AnimState:AddOverrideBuild("wx_upgrade")

	--Willow (magias de brasa): símbolos de "pyrocast_pre"/"pyrocast", tocados pelo
	--estado castspellmind de SGwilson.lua.
	inst.AnimState:AddOverrideBuild("willow_pyrocast")

	inst.components.talker.mod_str_fn = string.utf8upper

	inst.foleysound = "dontstarve/movement/foley/wx78"
end

local function OnSave(inst, data)
	if inst.king then
		data.king = true
	end
	-- guarda separado do "quem é o rei atual" (inst.king): controla só se o
	-- bônus de +50/+50/+50 já foi aplicado, pra RoyalUpgrade/RoyalDowngrade
	-- nunca ficarem dependendo de timing de load/migração pra saber se já
	-- rodaram (ver comentário em RoyalUpgrade)
	if inst._has_royal_buff then
		data.has_royal_buff = true
	end
	if inst.woby then
		data.woby = inst.woby:GetSaveRecord()
	else
		data.baglock = inst.baglock
	end
	data.buckdamage = inst._wobybuck_damage > 0 and inst._wobybuck_damage or nil
	data.science_bonus = inst.components.builder.science_bonus
	data.magic_bonus = inst.components.builder.magic_bonus
	data.seafaring_bonus = inst.components.builder.seafaring_bonus
	data.bookcraft_bonus = inst.components.builder.bookcraft_bonus
	data.fishing_bonus = inst.components.builder.fishing_bonus
	data.nivelDaBarba = inst.nivelDaBarba
	data.sanityPercent = inst.components.sanity:GetPercent()

	data.gears_eaten = inst._gears_eaten

	-- WX-78 needs to manually save/load health, hunger, and sanity, in case their maxes
	-- were modified by upgrade circuits, because those components only save current,
	-- and that gets overridden by the default max values during construction.
	-- So, if we wait to re-apply them in our OnLoad, we will have them properly
	-- (as entity OnLoad runs after component OnLoads)

	data.health_percent = inst.health_percent or inst.components.health:GetPercent()
	data.sanity_percent = inst.sanity_percent or inst.components.sanity:GetPercent()
	data.hunger_percent = inst.hunger_percent or inst.components.hunger:GetPercent()

	data._wx78_health = inst.components.health.currenthealth
	data._wx78_sanity = inst.components.sanity.current
	data._wx78_hunger = inst.components.hunger.current

	data.maxHealth = inst.components.health.maxhealth
	data.maxSanity = inst.components.sanity.max
	data.maxHunger = inst.components.hunger.max
	if inst.questghost ~= nil then
		data.questghost = inst.questghost:GetSaveRecord()
	end

	data.wortox_freehops = inst._wortox_freesoulhop_counter
	data.wortox_soulhopcost = inst._wortox_soulhop_cost
end

local function OnLightningStrike(inst)
	if
		inst.components.health ~= nil and not (inst.components.health:IsDead() or inst.components.health:IsInvincible())
	then
		if inst.components.inventory:IsInsulated() then
			inst:PushEvent("lightningdamageavoided")
		else
			inst.components.health:DoDelta(TUNING.HEALING_SUPERHUGE, false, "lightning")
			inst.components.sanity:DoDelta(-TUNING.SANITY_LARGE)

			inst.components.upgrademoduleowner:AddCharge(1)
		end
	end
end

local HEATSTEAM_TICKRATE = 5
local function do_steam_fx(inst)
	local steam_fx = SpawnPrefab("wx78_heat_steam")
	steam_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	steam_fx.Transform:SetRotation(inst.Transform:GetRotation())

	inst.components.timer:StartTimer(HEATSTEAM_TIMERNAME, HEATSTEAM_TICKRATE)
end

-- Negative is colder, positive is warmer
local function AddTemperatureModuleLeaning(inst, leaning_change)
	inst._temperature_modulelean = inst._temperature_modulelean + leaning_change

	if inst._temperature_modulelean > 0 then
		inst.components.heater:SetThermics(true, false)

		if not inst.components.timer:TimerExists(HEATSTEAM_TIMERNAME) then
			inst.components.timer:StartTimer(HEATSTEAM_TIMERNAME, HEATSTEAM_TICKRATE, false, 0.5)
		end

		inst.components.frostybreather:ForceBreathOff()
	elseif inst._temperature_modulelean == 0 then
		inst.components.heater:SetThermics(false, false)

		inst.components.timer:StopTimer(HEATSTEAM_TIMERNAME)

		inst.components.frostybreather:ForceBreathOff()
	else
		inst.components.heater:SetThermics(false, true)

		inst.components.timer:StopTimer(HEATSTEAM_TIMERNAME)

		inst.components.frostybreather:ForceBreathOn()
	end
end

local function SetSkin(inst)
	if inst.sg:HasStateTag("nomorph") or inst:HasTag("playerghost") or inst.components.health:IsDead() then
		return
	end

	-- Set skin
	-- local s = inst.fluffstage + 1
	-- inst.components.skinner:SetSkinMode(inst.isbeardlord and BEARDLORD_SKINS[0] or NORMAL_SKINS[1], "wilson")
	inst.components.skinner:SetSkinMode("normal_skin", "wilson")
end

local BEARDLORD_SANITY_THRESOLD = 0.4 -- 50 sanity
local function OnSanityDelta(inst, data)
	-- local BEARD_BITS = { 1, 3, 9 }

	if not inst.isbeardlord and data.newpercent < BEARDLORD_SANITY_THRESOLD then
		-- Becoming beardlord
		-- inst.components.sanity.current = 0
		inst.isbeardlord = true
		-- print("barba do beard")
		-- print(inst.nivelDaBarba)
		-- inst.components.sanity.dapperness = -TUNING.DAPPERNESS_TINY

		inst.components.combat:SetAttackPeriod(0.5)
		-- inst.components.sanity:DoDelta(-TUNING.WUNNY_SANITY)
		inst.components.sanity:SetPercent(0)
		-- inst.components.combat.damagemultiplier = 0.81
		-- inst.components.combat.damagemultiplier = 0.81
		inst.components.combat.externaldamagemultipliers:SetModifier("wunnyDamageMultiplier", 1.2)
		inst.components.health:SetAbsorptionAmount(-0.3)

		inst.components.beard.prize = "beardhair"
		-- inst:AddTag("playermonster")
		-- inst:AddTag("monster")
		inst.components.skinner:SetSkinMode("beardlord_skin", "wilson")
		if inst.components.eater ~= nil then
			-- inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODTYPE.MEAT, FOODTYPE.GOODIES })
			inst.components.eater:SetStrongStomach(true)
			inst.components.eater:SetCanEatRawMeat(true)
		end
		-- inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
		-- SetSkin(inst)
		-- print("monster de barba")
		-- print(inst.nivelDaBarba)
		-- if inst.nivelDaBarba == 1
		-- then
		-- 	inst.AnimState:OverrideSymbol("beard", "beard", "beard_short")

		-- elseif inst.nivelDaBarba == 2
		-- then

		-- elseif inst.nivelDaBarba == 3
		-- then
		print("nivel da barba: ", inst.nivelDaBarba)
		if inst.nivelDaBarba == 1 then
			inst.AnimState:OverrideSymbol("beard", "beard", "beard_short")
		elseif inst.nivelDaBarba == 2 then
			inst.AnimState:OverrideSymbol("beard", "beard", "beard_medium")
		elseif inst.nivelDaBarba == 3 then
			inst.AnimState:OverrideSymbol("beard", "beard", "beard_long")
		end
		-- end
	elseif inst.isbeardlord and data.newpercent >= BEARDLORD_SANITY_THRESOLD then
		-- Becoming bunny
		inst.isbeardlord = false

		-- inst.components.sanity.dapperness = 0
		inst.components.sanity:DoDelta(TUNING.WUNNY_SANITY * BEARDLORD_SANITY_THRESOLD / 2)

		inst.components.health:SetAbsorptionAmount(-0.6)
		inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
		-- if TheWorld:HasTag("cave") then
		-- 	inst.components.combat.damagemultiplier = 0.4
		-- else
		-- inst.components.combat.damagemultiplier = 0.28
		inst.components.combat.externaldamagemultipliers:SetModifier("wunnyDamageMultiplier", 1)
		-- end
		inst.components.beard.prize = "manrabbit_tail"
		-- inst:RemoveTag("playermonster")
		-- inst:RemoveTag("monster")

		-- inst.components.sanityaura.aura = 0
		inst.components.skinner:SetSkinMode("normal_skin", "wilson")
		if inst.components.eater ~= nil then
			-- inst.components.eater:SetDiet({ FOODGROUP.VEGETARIAN }, { FOODGROUP.VEGETARIAN, FOODTYPE.GOODIES })
			inst.components.eater:SetStrongStomach(false)
			inst.components.eater:SetCanEatRawMeat(false)
		end
		-- SetSkin(inst)
		-- Adjust stats
		-- AdjustLowSanityStats(inst, 0)
		print("nivel da barba: ", inst.nivelDaBarba)
		if inst.nivelDaBarba == 1 then
			inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_short")
		elseif inst.nivelDaBarba == 2 then
			inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_medium")
		elseif inst.nivelDaBarba == 3 then
			inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_long")
		end
		-- inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_long")
	end

	-- Adjust stats
	if inst.isbeardlord then
		-- local bonus = LOW_SANITY_BONUS_THRESHOLD - inst.components.sanity.current
		-- AdjustLowSanityStats(inst, bonus > 0 and bonus or 0)
	end
	-- print("barba sã")
	-- print(inst.nivelDaBarba)
	-- if inst.nivelDaBarba == 1
	-- then

	-- inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_short")
	-- elseif inst.nivelDaBarba == 2
	-- then
	-- inst.AnimState:OverrideSymbol("beard", "beard_silk", "beardsilk_medium")
	-- elseif inst.nivelDaBarba == 3
	-- then
	-- 	inst.AnimState:OverrideSymbol("beard", "beard_silk", "beardsilk_long")
	-- end
end

--is incave
-- local isInCave = function(inst)
-- 	if TheWorld:HasTag("cave")
-- 	then return true
-- 	end
-- 	return false
-- end

local caveSanityfn = function(inst)
	local delta = 0
	if TheWorld.state.iscaveday then
		delta = -10 / 60
	end
	return delta
end

local surfaceSanityfn = function(inst)
	local delta = 0
	if TheWorld.state.isdusk then
		delta = -2.5 / 60
	elseif TheWorld.state.isnight then
		delta = -7.5 / 60
	end
	return delta
end

local caveDay = function(inst)
	-- inst.components.locomotor.runspeed = 7.8
	-- inst.components.locomotor.walkspeed = 7.8
	inst.runningSpeed = 1.4
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunnySpeed", 1.4)
	-- print("print caveday")
end

local caveDusk = function(inst)
	-- inst.components.locomotor.runspeed = 7.5
	-- inst.components.locomotor.walkspeed = 7.5
	inst.runningSpeed = 1.35
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunnySpeed", 1.35)
	-- print("print cavedusk")
end

local caveNight = function(inst)
	if TheWorld.state.iscavenight then
		-- inst.components.locomotor.runspeed = 7.2
		-- inst.components.locomotor.walkspeed = 7.2
		inst.runningSpeed = 1.3
		inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunnySpeed", 1.3)
		-- print("print cavenight")
	end
end

local caveBehaviour = function(inst)
	-- inst.components.sanity.night_drain_mult = 0
	inst.components.sanity.dapperness = TUNING.DAPPERNESS_MED_LARGE
	-- if not inst.isbearlord then
	-- 	-- inst.components.combat.damagemultiplier = 0.28
	-- 	inst.components.combat.externaldamagemultipliers:SetModifier("wunnyDamageMultiplier", 1)
	-- end
	-- inst.components.sanity.custom_rate_fn = caveSanityfn
	if TheWorld.state.iscaveday then
		caveDay(inst)
	elseif TheWorld.state.iscavedusk then
		caveDusk(inst)
	else
		caveNight(inst)
	end

	inst:WatchWorldState("iscaveday", caveDay)
	inst:WatchWorldState("iscavedusk", caveDusk)
	inst:WatchWorldState("iscavenight", caveNight)
end

local surfaceDay = function(inst)
	-- inst.components.locomotor.runspeed = 7.8
	-- inst.components.locomotor.walkspeed = 7.8
	inst.runningSpeed = 1.4
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunnySpeed", 1.4)
end

local surfaceDusk = function(inst)
	-- inst.components.locomotor.runspeed = 7.5
	-- inst.components.locomotor.walkspeed = 7.5
	inst.runningSpeed = 1.35
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunnySpeed", 1.35)
end

local surfaceNight = function(inst)
	-- inst.components.locomotor.runspeed = 7.2
	-- inst.components.locomotor.walkspeed = 7.2
	inst.runningSpeed = 1.3
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunnySpeed", 1.3)
end

local surfaceBehaviour = function(inst)
	inst.components.sanity.dapperness = 0
	-- if not inst.isbearlord then
	-- 	-- inst.components.combat.damagemultiplier = 0.28
	-- 	inst.components.combat.externaldamagemultipliers:SetModifier("wunnyDamageMultiplier", 0.28)
	-- end

	-- inst.components.sanity.custom_rate_fn = surfaceSanityfn

	if TheWorld.state.isday then
		surfaceDay(inst)
	elseif TheWorld.state.isdusk then
		surfaceDusk(inst)
	else
		surfaceNight(inst)
	end

	inst:WatchWorldState("isday", surfaceDay)
	inst:WatchWorldState("isdusk", surfaceDusk)
	inst:WatchWorldState("isnight", surfaceNight)
end

local function CarrotPreserverRate(inst, item)
	return (item ~= nil and item == "carrot" or item == "carrot_cooked") and TUNING.WURT_FISH_PRESERVER_RATE or nil
end

local function OnResetBeard(inst)
	inst.nivelDaBarba = 0

	inst.AnimState:ClearOverrideSymbol("beard")
end

local BEARD_DAYS = { 4, 8, 12 } --mudar depois para 4, 8 ,16
local BEARD_BITS = { 1, 3, 6 }

local function OnGrowShortBeard(inst, skinname)
	inst.nivelDaBarba = 1
	-- print("teste barba short")
	-- print(inst.nivelDaBarba)

	-- if inst.isbeardlord then
	-- 	if skinname == nil then
	-- 		inst.AnimState:OverrideSymbol("beard", "beard_silk", "beard_short")
	-- 	else
	-- 		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_short")
	-- 	end
	-- end
	-- if not inst.isbeardlord then
	if skinname == nil then
		inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_short")
		-- inst.AnimState:OverrideSymbol("beard", "wilson_beard_ice", "beard_short")
		-- ThePlayer.components.beard.daysgrowth = 16ThePlayer.components.beard.bits = 9ThePlayer.AnimState:OverrideSymbol("beard", "wilson_beard_ice", "beard_long")
	else
		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_short")
	end
	-- end
	inst.components.beard.bits = BEARD_BITS[1]
end

local function OnGrowMediumBeard(inst, skinname)
	inst.nivelDaBarba = 2
	-- print("teste barba medi")
	-- print(inst.nivelDaBarba)
	if skinname == nil then
		inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_medium")
		-- inst.AnimState:OverrideSymbol("beard", "wilson_beard_ice", "beard_medium")
	else
		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_medium")
	end
	inst.components.beard.bits = BEARD_BITS[2]
end

local function OnGrowLongBeard(inst, skinname)
	inst.nivelDaBarba = 3
	-- print("teste barba long")
	-- print(inst.nivelDaBarba)
	if skinname == nil then
		inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_long")
		-- inst.AnimState:OverrideSymbol("beard", "wilson_beard_ice", "beard_long")
	else
		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_long")
	end
	inst.components.beard.bits = BEARD_BITS[3]
end

----------------------------------------------------------------------------------------
-- Wilson (skill "wilson_beard_7"): a barba vira mochila (EQUIPSLOTS.BEARD).
----------------------------------------------------------------------------------------

-- Substitui Beard:UpdateBeardInventory (components/beard.lua). O original
-- compara self.bits contra TUNING.WILSON_BEARD_BITS = {1, 3, 9}, mas a barba da
-- Wunny usa BEARD_BITS = {1, 3, 6} — no talo ela tem 6 bits, que é >= 3 e < 9,
-- então a versão vanilla travaria a Wunny na beard_sack_2 e a beard_sack_3
-- ficaria inalcançável. Aqui os cortes seguem os bits da própria Wunny.
-- O resto (transferir itens ao trocar de nível, dropar tudo ao perder a barba) é
-- igual ao vanilla.
local function Wilson_UpdateBeardInventory(self)
	local level = nil

	if self.inst.components.skilltreeupdater ~= nil and
		self.inst.components.skilltreeupdater:IsActivated("wilson_beard_7")
	then
		if self.bits >= BEARD_BITS[3] then
			level = "beard_sack_3"
		elseif self.bits >= BEARD_BITS[2] then
			level = "beard_sack_2"
		elseif self.bits >= BEARD_BITS[1] then
			level = "beard_sack_1"
		end
	end

	local inventory = self.inst.components.inventory
	local beardsack = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.BEARD) or nil

	if level ~= nil then
		if beardsack == nil then
			inventory:Equip(SpawnPrefab(level))
		elseif not beardsack:HasTag(level) then
			-- Nível mudou: move os itens da mochila antiga pra nova.
			local bearditems = beardsack.components.container:RemoveAllItems()
			beardsack.components.container:Close(self.inst)
			beardsack:Remove()
			local newsack = SpawnPrefab(level)
			inventory:Equip(newsack)
			for slot, item in ipairs(bearditems) do
				newsack.components.container:GiveItem(item, slot, nil, true)
			end
		end
	elseif beardsack ~= nil then
		beardsack.components.container:DropEverything()
		beardsack:Remove()
	end
end

-- Sem isto os itens guardados na barba somem junto com a mochila ao morrer
-- (a barba é resetada em "ms_respawnedfromghost"). Mesmo listener do
-- wilson.lua:EmptyBeard.
local function Wilson_EmptyBeard(inst)
	local beard_sack = inst.components.inventory ~= nil
		and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BEARD)
		or nil
	if beard_sack ~= nil then
		beard_sack.components.container:DropEverything()
		beard_sack:Remove()
	end
end

local SANITYFN_FIRE_TAGS = { "fire" }
local function sanityfn(inst) --, dt)
	local delta = inst.components.temperature:IsFreezing() and -TUNING.SANITYAURA_LARGE or 0
	local x, y, z = inst.Transform:GetWorldPosition()
	local max_rad = 10
	local ents = TheSim:FindEntities(x, y, z, max_rad, SANITYFN_FIRE_TAGS)
	for i, v in ipairs(ents) do
		if v.components.burnable ~= nil and v.components.burnable:IsBurning() then
			local rad = v.components.burnable:GetLargestLightRadius() or 1
			local sz = TUNING.SANITYAURA_TINY * math.min(max_rad, rad) / max_rad
			local distsq = inst:GetDistanceSqToInst(v) - 9
			-- shift the value so that a distance of 3 is the minimum
			delta = delta + sz / math.max(1, distsq)
		end
	end
	return delta
end

local SHADOWCREATURE_MUST_TAGS = { "shadowcreature", "_combat", "locomotor" }
local SHADOWCREATURE_CANT_TAGS = { "INLIMBO", "notaunt" }
local function OnReadFn(inst, book)
	if inst.components.sanity:IsInsane() then
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 16, SHADOWCREATURE_MUST_TAGS, SHADOWCREATURE_CANT_TAGS)

		if #ents < TUNING.BOOK_MAX_SHADOWCREATURES then
			TheWorld.components.shadowcreaturespawner:SpawnShadowCreature(inst)
		end
	end
end

-- local function OnDeath(inst)
-- 	--transferido para onbecameghost

-- end

local function OnEat(inst, food)
	if food ~= nil and food.components.edible ~= nil then
		if food.components.edible.foodtype == FOODTYPE.GEARS then
			inst._gears_eaten = inst._gears_eaten + 1

			inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/levelup")
		end
	end

	local charge_amount = TUNING.WX78_CHARGING_FOODS[food.prefab]
	if charge_amount ~= nil then
		inst.components.upgrademoduleowner:AddCharge(charge_amount)
	end
end

local function OnFrozen(inst)
	if inst.components.freezable == nil or not inst.components.freezable:IsFrozen() then
		SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

		if not inst.components.upgrademoduleowner:IsChargeEmpty() then
			inst.components.upgrademoduleowner:AddCharge(-TUNING.WX78_FROZEN_CHARGELOSS)
		end
	end
end

local function OnUpgradeModuleAdded(inst, moduleent)
	local slots_for_module = moduleent.components.upgrademodule.slots
	inst._chip_inuse = inst._chip_inuse + slots_for_module

	local upgrademodule_defindexes = get_plugged_module_indexes(inst)

	inst:PushEvent("upgrademodulesdirty", upgrademodule_defindexes)
	local newmodule_index = inst.components.upgrademoduleowner:NumModules()
	if inst._upgrademodules[newmodule_index] ~= nil then
		inst._upgrademodules[newmodule_index]:set(moduleent._netid or 0)
	end
end

local function OnUpgradeModuleRemoved(inst, moduleent)
	inst._chip_inuse = inst._chip_inuse - moduleent.components.upgrademodule.slots

	-- If the module has 1 use left, it's about to be destroyed, so don't return it to the inventory.
	if moduleent.components.finiteuses == nil or moduleent.components.finiteuses:GetUses() > 1 then
		if moduleent.components.inventoryitem ~= nil and inst.components.inventory ~= nil then
			inst.components.inventory:GiveItem(moduleent, nil, inst:GetPosition())
		end
	end
end

local function OnOneUpgradeModulePopped(inst, moduleent)
	inst:PushEvent("upgrademodulesdirty", get_plugged_module_indexes(inst))
	-- This is a callback of the remove, so our current NumModules should be
	-- 1 lower than the index of the module that was just removed.
	local top_module_index = inst.components.upgrademoduleowner:NumModules() + 1
	if inst._upgrademodules[top_module_index] ~= nil then
		inst._upgrademodules[top_module_index]:set(0)
	end
end

local function OnAllUpgradeModulesRemoved(inst)
	SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

	inst:PushEvent("upgrademoduleowner_popallmodules")

	for i = 1, #inst._upgrademodules do
		inst._upgrademodules[i]:set(0)
	end
end

local function CanUseUpgradeModule(inst, moduleent)
	-- GetMaxChargeLevel() em vez de TUNING.WX78_MAXELECTRICCHARGE fixo: assim a
	-- skill wx78_circuitry_slot_1 (que dá +1 de carga máxima via SetMaxCharge)
	-- realmente libera mais um slot de chip utilizável.
	if (inst.components.upgrademoduleowner:GetMaxChargeLevel() - inst._chip_inuse) < moduleent.components.upgrademodule.slots then
		return false, "NOTENOUGHSLOTS"
	else
		return true
	end
end

----------------------------------------------------------------------------------------

local function OnChargeFromBattery(inst, battery)
	if inst.components.upgrademoduleowner:ChargeIsMaxed() then
		return false, "CHARGE_FULL"
	end

	inst.components.health:DoDelta(TUNING.HEALING_SMALL, false, "lightning")
	inst.components.sanity:DoDelta(-TUNING.SANITY_SMALL)

	inst.components.upgrademoduleowner:AddCharge(1)

	if not inst.components.inventory:IsInsulated() then
		inst.sg:GoToState("electrocute")
	end

	return true
end

----------------------------------------------------------------------------------------

local function ModuleBasedPreserverRateFn(inst, item)
	return (inst._temperature_modulelean > 0 and TUNING.WX78_PERISH_HOTRATE)
		or (inst._temperature_modulelean < 0 and TUNING.WX78_PERISH_COLDRATE)
		or 1
end

----------------------------------------------------------------------------------------

local function GetThermicTemperatureFn(inst, observer)
	return inst._temperature_modulelean * TUNING.WX78_HEATERTEMPPERMODULE
end

----------------------------------------------------------------------------------------

local function CanSleepInBagFn(wx, bed)
	if wx._light_modules == nil or wx._light_modules == 0 then
		return true
	else
		return false, "ANNOUNCE_NOSLEEPHASPERMANENTLIGHT"
	end
end

----------------------------------------------------------------------------------------
local function OnStartStarving(inst)
	inst.components.timer:StartTimer(HUNGERDRAIN_TIMERNAME, TUNING.WX78_HUNGRYCHARGEDRAIN_TICKTIME)
end

local function OnStopStarving(inst)
	inst.components.timer:StopTimer(HUNGERDRAIN_TIMERNAME)
end

local function on_hunger_drain_tick(inst)
	if
		inst.components.health ~= nil and not (inst.components.health:IsDead() or inst.components.health:IsInvincible())
	then
		inst.components.upgrademoduleowner:AddCharge(-1)

		SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

		inst.sg:GoToState("hit")
	end
	inst.components.timer:StartTimer(HUNGERDRAIN_TIMERNAME, TUNING.WX78_HUNGRYCHARGEDRAIN_TICKTIME)
end

----------------------------------------------------------------------------------------

local function OnTimerFinished(inst, data)
	if data.name == HUNGERDRAIN_TIMERNAME then
		on_hunger_drain_tick(inst)
	elseif data.name == MOISTURETRACK_TIMERNAME then
		moisturetrack_update(inst)
	elseif data.name == CHARGEREGEN_TIMERNAME then
		do_chargeregen_update(inst)
	elseif data.name == HEATSTEAM_TIMERNAME then
		do_steam_fx(inst)
	end
end

-- Sem "local": preenche a forward declaration do topo do arquivo (ver o comentário
-- lá). Trocar por "local function" aqui reintroduziria o nil em onbecameghost.
function KillPet(pet)
	if pet.components.health:IsInvincible() then
		--reschedule
		pet._killtask = pet:DoTaskInTime(0.5, KillPet)
	else
		pet.components.health:Kill()
	end
end

local function OnSpawnPet(inst, pet)
	if pet:HasTag("shadowminion") then
		if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
			--if not inst.components.builder.freebuildmode then
			inst.components.sanity:AddSanityPenalty(pet, TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(pet.prefab)])
			--end
			inst:ListenForEvent("onremove", inst._onpetlost, pet)
			pet.components.skinner:CopySkinsFromPlayer(inst)
		elseif pet._killtask == nil then
			pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
		end
	elseif inst._OnSpawnPet ~= nil then
		inst:_OnSpawnPet(pet)
	end
end

local function OnDespawnPet(inst, pet)
	if pet:HasTag("shadowminion") then
		if not inst.is_snapshot_user_session and pet.sg ~= nil then
			pet.sg:GoToState("quickdespawn")
		else
			pet:Remove()
		end
	elseif inst._OnDespawnPet ~= nil then
		inst:_OnDespawnPet(pet)
	end

	local abigail = inst.components.ghostlybond.ghost
	if abigail ~= nil and abigail.sg ~= nil and not abigail.inlimbo then
		if not abigail.sg:HasStateTag("dissipate") then
			abigail.sg:GoToState("dissipate")
		end
		abigail:DoTaskInTime(25 * FRAMES, abigail.Remove)
	end
end

local function OnReroll(inst)
	-- This is its own function in case OnDespawn above changes that requires workarounds for seamlessswap to not interfere.
	if inst.woby ~= nil then
		inst.woby:OnPlayerLinkDespawn(true)
	end
	OnDespawn(inst)
end

local function currentspeedup(self, speedupamount)
	self.inst.currentspeedup:set(speedupamount)
end

local function OnEquip(inst, data)
	if data.item and data.item.prefab == "greenamulet" then
		inst.components.builder.ingredientmod = 0.25
	end
	print(data)
	local hasWeapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	-- local weaponDamage = 0
	if hasWeapon then
		hasWeapon:RemoveComponent("tradable")
		hasWeapon:AddComponent("tradable")
		-- weaponDamage = hasWeapon.components.weapon.damage
		-- hasWeapon.components.weapon:SetDamage((TUNING.BUNNYMAN_DAMAGE + beardLordDamage) * multiplier + weaponDamage/2)
	end

	local hasArmor = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
	-- local weaponDamage = 0
	if hasArmor then
		hasArmor:RemoveComponent("tradable")
		hasArmor:AddComponent("tradable")
		-- weaponDamage = hasWeapon.components.weapon.damage
		-- hasWeapon.components.weapon:SetDamage((TUNING.BUNNYMAN_DAMAGE + beardLordDamage) * multiplier + weaponDamage/2)
	end
	-- print("equipou e ", inst.components.locomotor:GetSpeedMultiplier())
	-- _G.speedMultiplier = inst.components.locomotor:GetSpeedMultiplier()
	-- if data.eslot == EQUIPSLOTS.HEAD and not data.item:HasTag("open_top_hat") then
	--     --V2C: HAH! There's no "beard" in "player_wormwood" build.
	--     --     This hides the flower, which uses the beard symbol.
	--     inst.AnimState:OverrideSymbol("beard", "player_wormwood", "beard")
	-- end

	--fishinrod
	if
		inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).components
		and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).components.fishingrod
	then
		local fishingrod = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).components.fishingrod
		-- self.fishtimemin = fishingrod.minwaittime
		-- self.fishtimemax = fishingrod.maxwaittime
		fishingrod:SetWaitTimes(1, 1)
	end
end

local function OnUnequip(inst, data)
	-- print("desequipou e ", inst.components.locomotor:GetSpeedMultiplier())
	-- _G.speedMultiplier = inst.components.locomotor:GetSpeedMultiplier()
	-- if data.eslot == EQUIPSLOTS.HEAD then
	--     inst.AnimState:ClearOverrideSymbol("beard")
	-- end
	if data.item and data.item.prefab == "greenamulet" then
		inst.components.builder.ingredientmod = 0.5
	end
end

local function OnHealthDelta(inst, data)
	local overtime = data ~= nil and data.overtime or nil
	if data.amount < 0 then
		if not inst.isbeardlord then
			inst.components.sanity:DoDelta(
				data.amount
					* (overtime and TUNING.WALTER_SANITY_DAMAGE_OVERTIME_RATE or TUNING.WALTER_SANITY_DAMAGE_RATE)
					* inst._sanity_damage_protection:Get()
					/ 2,
				overtime
			)
		end
	elseif data.amount > 0 then
		if not inst.isbeardlord then
			inst.components.sanity:DoDelta(data.amount / 2, overtime)
		end
	end
end

local function UpdateStats(inst, healthAmount, hungerAmount, sanityAmount)
	print("antes do updatestats")
	-- print(inst == nil)
	-- print(inst.components == nil)
	-- print(inst.components.health == nil)
	-- print(inst.components.health:IsDead())
	-- print(inst:HasTag("playerghost"))
	if
		inst == nil
		or inst.components == nil
		or inst.components.health == nil
		or inst.components.health:IsDead()
		or inst:HasTag("playerghost")
	then
		return
	end

	print("dps do if do update stats")
	print(inst.components.health.maxhealth)
	print(healthAmount)
	print(inst.components.health.maxhealth + healthAmount)

	local current_health = inst.health_percent or inst.components.health:GetPercent()
	inst.health_percent = nil

	local current_hunger = inst.hunger_percent or inst.components.hunger:GetPercent()
	inst.hunger_percent = nil

	local current_sanity = inst.sanity_percent or inst.components.sanity:GetPercent()
	inst.sanity_percent = nil

	inst.components.health:SetMaxHealth(inst.components.health.maxhealth + healthAmount)
	print("nova vida ", inst.components.health.maxhealth)
	inst.components.hunger:SetMax(inst.components.hunger.max + hungerAmount)
	inst.components.sanity:SetMax(inst.components.sanity.max + sanityAmount)

	inst.components.health:SetPercent(current_health)
	inst.components.hunger:SetPercent(current_hunger)
	inst.components.sanity:SetPercent(current_sanity)
end

local function RoyalUpgrade(inst)
	-- idempotente por design: "onbunnykingcreated" é reemitido toda vez que a
	-- fome do rei muda (ver bunnyking.lua:AnnounceKingAlive) e de novo ao
	-- carregar o save (bunnykingmanager:LoadPostPass), então este guard não
	-- pode depender só de "inst.king ~= nil" no listener (essa checagem já
	-- existe lá, mas fica sujeita a timing de load/migração entre shards).
	-- Checando aqui, na própria função, garante que o +50/+50/+50 nunca é
	-- aplicado duas vezes nem que timing algum consiga furar o guard.
	if inst._has_royal_buff then
		return
	end
	inst._has_royal_buff = true
	UpdateStats(inst, 50, 50, 50)

	-- if inst == nil or inst.components == nil or inst.components.health == nil or inst.components.health:IsDead() or inst:HasTag("playerghost")
	-- then
	-- 	return
	-- end
	-- print(inst.components.health:IsDead() or inst:HasTag("playerghost"))
	-- inst.components.health:SetMaxHealth(inst.components.health.maxhealth + 50)
	-- inst.components.hunger:SetMax(inst.components.hunger.max + 50)
	-- inst.components.sanity:SetMax(inst.components.sanity.max + 50)

	-- local current_health = inst.health_percent or inst.components.health:GetPercent()
	-- inst.health_percent = nil

	-- local current_hunger = inst.hunger_percent or inst.components.hunger:GetPercent()
	-- inst.hunger_percent = nil

	-- local current_sanity = inst.sanity_percent or inst.components.sanity:GetPercent()
	-- inst.sanity_percent = nil

	-- inst.components.health:SetPercent(current_health)
	-- inst.components.hunger:SetPercent(current_hunger)
	-- inst.components.sanity:SetPercent(current_sanity)
end

local function RoyalDowngrade(inst)
	if not inst._has_royal_buff then
		return
	end
	inst._has_royal_buff = false
	UpdateStats(inst, -50, -50, -50)
end

local master_postinit = function(inst)
	-- print("speed ", GLOBAL.net_shortint(inst.GUID,"currentspeedup"))
	-- print("speed ", currentspeedup)
	-- print("speed ",  inst.components.equippable.walkspeedmult)
	-- print("Runspeed ", inst.components.locomotor:GetRunSpeed())
	-- print("Multspeed ", inst.components.locomotor:GetSpeedMultiplier())
	-- print("Walkspeed ", inst.components.locomotor:GetWalkSpeed())
	inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	--Wanda
	inst:AddComponent("positionalwarp")
	inst:DoTaskInTime(0, function()
		inst.components.positionalwarp:SetMarker("pocketwatch_warp_marker")
	end)
	inst:ListenForEvent("show_warp_marker", on_show_warp_marker)
	inst:ListenForEvent("hide_warp_marker", on_hide_warp_marker)
	inst:ListenForEvent("onwarpback", OnWarpBack)
	inst.components.positionalwarp:SetWarpBackDist(TUNING.WANDA_WARP_DIST_YOUNG)

	inst:ListenForEvent("equip", OnEquip)
	inst:ListenForEvent("unequip", OnUnequip)

	inst.components.temperature.inherentinsulation = -TUNING.INSULATION_TINY
	inst.components.temperature.inherentsummerinsulation = -TUNING.INSULATION_TINY
	inst.components.temperature:SetFreezingHurtRate(TUNING.WILSON_HEALTH / TUNING.WILLOW_FREEZING_KILL_TIME)
	inst.components.temperature:SetOverheatHurtRate(TUNING.WILSON_HEALTH / TUNING.WILLOW_FREEZING_KILL_TIME)

	inst:AddComponent("reader")

	inst.runningSpeed = 1

	-- inst.nivelDaBarba = 0

	-- inst.components.builder.science_bonus = 1 --voltar, mudar para este depois
	-- inst.components.builder.magic_bonus = 2
	inst.components.builder.science_bonus = 2
	inst.components.builder.ancient_bonus = 4

	inst.components.builder.ingredientmod = 0.25
	--beard
	inst:AddComponent("beard")
	inst.components.beard.insulation_factor = TUNING.WEBBER_BEARD_INSULATION_FACTOR
	inst.components.beard.onreset = OnResetBeard
	inst.components.beard.prize = "manrabbit_tail"
	inst.components.beard.is_skinnable = true
	inst.components.beard:AddCallback(BEARD_DAYS[1], OnGrowShortBeard)
	inst.components.beard:AddCallback(BEARD_DAYS[2], OnGrowMediumBeard)
	inst.components.beard:AddCallback(BEARD_DAYS[3], OnGrowLongBeard)

	-- Wilson (skill "wilson_beard_7"): barba-mochila. O método é trocado na
	-- instância (não na classe Beard) pra não afetar o Wilson/Webber de verdade
	-- num servidor com vários personagens.
	inst.components.beard.UpdateBeardInventory = Wilson_UpdateBeardInventory
	inst.EmptyBeard = Wilson_EmptyBeard
	inst:ListenForEvent("death", Wilson_EmptyBeard)

	inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
	inst.soundsname = "willow"
	inst:AddTag("wunny")

	--teste
	-- inst:AddTag("shadow")
	--Waxwell

	inst:AddComponent("magician")

	inst.components.reader:SetSanityPenaltyMultiplier(TUNING.MAXWELL_READING_SANITY_MULT)
	inst.components.reader:SetOnReadFn(OnReadFn)

	if inst.components.petleash ~= nil then
		inst._OnSpawnPet = inst.components.petleash.onspawnfn
		inst._OnDespawnPet = inst.components.petleash.ondespawnfn
		inst.components.petleash:SetMaxPets(inst.components.petleash:GetMaxPets() + 12)
	else
		inst:AddComponent("petleash")
		inst.components.petleash:SetMaxPets(12)
	end

	inst.components.petleash:SetOnSpawnFn(OnSpawnPet)
	inst.components.petleash:SetOnDespawnFn(OnDespawnPet)

	inst._onpetlost = function(pet)
		inst.components.sanity:RemoveSanityPenalty(pet)
	end

	-- O listener de "death" -> onbecameghost fica só no bloco do wx78 mais abaixo.
	-- Estava registrado nos dois lugares, e como ListenForEvent não deduplica,
	-- onbecameghost rodava duas vezes por morte (uma terceira vez ainda vem do
	-- "ms_becameghost" registrado em onload).

	inst.components.foodaffinity:AddFoodtypeAffinity(FOODTYPE.VEGGIE, 0.5)
	inst.components.foodaffinity:AddFoodtypeAffinity(FOODTYPE.MEAT, 0.5)
	-- inst.components.foodaffinity:AddFoodtypeAffinity(FOODTYPE.OMNI, 0.8)
	inst.components.foodaffinity:AddPrefabAffinity("carrot", 1.5)
	inst.components.foodaffinity:AddPrefabAffinity("carrot_cooked", 1.5)

	-- inst:AddComponent("itemaffinity")
	-- inst.components.itemaffinity:AddAffinity("rabbit", nil, TUNING.DAPPERNESS_MED, 1)
	-- inst.components.itemaffinity:AddAffinity("dwarfbunnyman", nil, TUNING.DAPPERNESS_MED, 1)
	-- inst.components.itemaffinity:AddAffinity(nil, "manrabbit", TUNING.DAPPERNESS_MED, 1)

	inst:AddComponent("preserver")
	-- inst.components.preserver:SetPerishRateMultiplier(CarrotPreserverRate)

	-- if inst.components.eater ~= nil then
	-- 	inst.components.eater:SetDiet({ FOODGROUP.VEGETARIAN }, { FOODGROUP.VEGETARIAN, FOODTYPE.GOODIES })
	-- end

	inst.components.locomotor:SetFasterOnGroundTile(WORLD_TILES.SAVANNA, true)
	inst.components.locomotor:SetFasterOnGroundTile(WORLD_TILES.SINKHOLE, true)

	inst:ListenForEvent("locomote", function()
		if inst.is_burrowdashing then
			-- fome consumida proporcionalmente ao ganho de velocidade da toca
			inst.components.hunger.hungerrate = TUNING.WUNNY_HUNGER_RATE * TUNING.WUNNY_BURROWDASH_SPEED_MULT
		elseif inst.sg ~= nil and inst.sg:HasStateTag("moving") then
			-- inst.components.hunger:SetRate(
			-- 	inst.runningSpeed
			-- -- * TUNING.WUNNY_HUNGER_RATE *
			-- --  TUNING.WUNNY_HUNGER_RATE
			-- ) --1.20
			inst.components.hunger.hungerrate = inst.runningSpeed * TUNING.WUNNY_HUNGER_RATE
			-- print("Runspeed ", inst.components.locomotor:GetRunSpeed())
			-- print("Multspeed ", inst.components.locomotor:GetSpeedMultiplier())
			-- print("Walkspeed ", inst.components.locomotor:GetWalkSpeed())
			-- print("TUNING SPEED", _G.speedMultiplier)
		else
			-- 	inst.components.hunger:SetRate(
			-- 		-- 1
			-- 	-- *
			-- 	TUNING.WUNNY_HUNGER_RATE
			-- 	-- * TUNING.WUNNY_HUNGER_RATE
			-- )
			inst.components.hunger.hungerrate = TUNING.WUNNY_HUNGER_RATE
		end
	end)

	-- Toca-relâmpago: a Wunny cava e se move por baixo da terra, bem mais
	-- rápido, mas não pode ser usada em combate (nem pra fugir de um ataque
	-- em andamento nem pra golpear enquanto ativa). Visual reaproveitado do
	-- "mole_move_fx" vanilla (o montinho de terra se deslocando do mole),
	-- reespawnado periodicamente na posição da Wunny enquanto ela se move.
	inst.is_burrowdashing = false

	-- Tempo que a Wunny fica visível "entrando" no buraco antes de desaparecer,
	-- e a pausa entre ela desaparecer e o buraco sumir dando lugar aos
	-- montinhos de terra.
	local WUNNY_BURROWDASH_ENTER_TIME = 0.5
	local WUNNY_BURROWDASH_HOLE_FADE_TIME = 0.2
	-- Quanto do tempo de entrada ela passa já como coelho, no fim: ela encolhe
	-- como Wunny até sobrar isso e então o coelho assume o resto da descida.
	local WUNNY_BURROWDASH_RABBIT_TIME = 0.3
	-- Tamanho em que ela desaparece dentro do buraco, mais ou menos o de um
	-- rabbit.
	local WUNNY_BURROWDASH_MIN_SCALE = 0.5
	-- Sobra do tempo de entrada em que quem aparece é a própria Wunny (o resto é
	-- o coelho). Usado nas duas pontas: encolhendo na entrada, crescendo na saída.
	local WUNNY_BURROWDASH_WUNNY_TIME = math.max(FRAMES, WUNNY_BURROWDASH_ENTER_TIME - WUNNY_BURROWDASH_RABBIT_TIME)

	local BURROWDASH_TASKS =
	{
		"burrowdash_task",
		"burrowdash_enter_task",
		"burrowdash_swap_task",
		"burrowdash_hidehole_task",
		"burrowdash_shrink_task",
	}

	local function RemoveBurrowDashHoleFX(inst)
		if inst.burrowdash_holefx ~= nil then
			if inst.burrowdash_holefx:IsValid() then
				inst.burrowdash_holefx:Remove()
			end
			inst.burrowdash_holefx = nil
		end
	end

	local function RemoveBurrowDashRabbitFX(inst)
		if inst.burrowdash_rabbitfx ~= nil then
			if inst.burrowdash_rabbitfx:IsValid() then
				inst.burrowdash_rabbitfx:Remove()
			end
			inst.burrowdash_rabbitfx = nil
		end
	end

	-- Alcance da varredura que tira a Wunny da mira de quem já a perseguia. Bem
	-- maior que o raio de agressão típico porque um hound em perseguição pode
	-- estar longe e ainda vindo.
	local WUNNY_BURROWDASH_DROP_AGGRO_DIST = 30

	-- A tag "notarget" sozinha NÃO resolve: ela só bloqueia mira nova (o
	-- Combat:SetTarget a checa, e as brains a usam como exclude tag no
	-- FindEntities), mas Combat:IsValidTarget não olha pra ela, então quem já
	-- estava perseguindo continua perseguindo e acertando uma tela vazia. Por isso
	-- a varredura com DropTarget, que é como a vanilla faz nesses casos (ver
	-- components/repellent.lua e prefabs/spider_buffs.lua).
	local function DropBurrowDashAggro(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, WUNNY_BURROWDASH_DROP_AGGRO_DIST, { "_combat" }, { "INLIMBO", "player" })
		for _, ent in ipairs(ents) do
			if ent.components.combat ~= nil and ent.components.combat.target == inst then
				ent.components.combat:DropTarget()
			end
		end
	end

	-- Enquanto está invisível debaixo da terra ela não pode ser alvo: sem isso um
	-- hound persegue e acerta uma tela vazia, e o golpe (que o jogador não tinha
	-- como ver chegando) a ejetava da toca.
	--
	-- Só remove a tag se foi esta skill que a colocou — outra fonte (godmode,
	-- console) pode ter adicionado antes, e apagar a dela seria um efeito
	-- colateral silencioso.
	local function SetBurrowDashNoTarget(inst, hidden)
		if hidden then
			if not inst:HasTag("notarget") then
				inst:AddTag("notarget")
				inst.burrowdash_notarget = true
			end
			DropBurrowDashAggro(inst)
		elseif inst.burrowdash_notarget then
			inst:RemoveTag("notarget")
			inst.burrowdash_notarget = nil
		end
	end

	local function ClearBurrowDashTasks(inst)
		for _, name in ipairs(BURROWDASH_TASKS) do
			if inst[name] ~= nil then
				inst[name]:Cancel()
				inst[name] = nil
			end
		end
	end

	-- Trava o controle durante as animações de entrada e saída, senão ela sai
	-- andando (e o coelho visual, que fica parado na posição de spawn, se descola
	-- dela) no meio da transformação.
	local function SetBurrowDashLocked(inst, locked)
		-- classified pode já ter sido destruído se a Wunny estiver sendo removida
		-- no meio da animação (AbortBurrowDash também roda no "onremove").
		if inst.components.playercontroller ~= nil and inst.components.playercontroller.classified ~= nil then
			inst.components.playercontroller:Enable(not locked)
		end
		if locked then
			inst.components.locomotor:Stop()
		end
		inst.burrowdash_locked = locked or nil
	end

	-- Encerramento seco, sem animação. Serve tanto pra interrupção à força (dano,
	-- morte, remoção) quanto como último passo da saída animada, que chega aqui já
	-- com a Wunny visível e no tamanho certo.
	local function AbortBurrowDash(inst)
		if not inst.is_burrowdashing then
			return
		end
		inst.is_burrowdashing = false
		inst.burrowdash_exiting = nil
		ClearBurrowDashTasks(inst)
		RemoveBurrowDashHoleFX(inst)
		RemoveBurrowDashRabbitFX(inst)
		SetBurrowDashNoTarget(inst, false)
		if inst.burrowdash_locked then
			SetBurrowDashLocked(inst, false)
		end
		inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wunny_burrowdash")
		if inst.components.combat ~= nil then
			inst.components.combat.canattack = true
		end
		inst.Transform:SetScale(1, 1, 1)
		inst.AnimState:SetMultColour(1, 1, 1, 1)
		inst:PushEvent("locomote")
	end

	-- Saída da toca: a coreografia da entrada ao contrário. O buraco reaparece, o
	-- coelho emerge do fundo crescendo, dá lugar à Wunny (que termina de crescer
	-- até o tamanho normal) e só então o buraco some. Mesma duração da entrada.
	local function StartBurrowDashExit(inst)
		if not inst.is_burrowdashing or inst.burrowdash_exiting then
			return
		end
		inst.burrowdash_exiting = true

		-- Para os montinhos de terra e prega a Wunny no ponto onde ela vai emergir.
		ClearBurrowDashTasks(inst)
		inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wunny_burrowdash")
		SetBurrowDashLocked(inst, true)
		inst:PushEvent("locomote")

		-- Normaliza o ponto de partida: se o jogador apertou R no meio da animação
		-- de entrada ela pode ainda estar visível e/ou encolhida, e a saída
		-- assumiria o contrário.
		inst.AnimState:SetMultColour(1, 1, 1, 0)
		inst.Transform:SetScale(1, 1, 1)

		local x, y, z = inst.Transform:GetWorldPosition()
		inst.burrowdash_holefx = SpawnPrefab("wunny_burrowdash_fx")
		inst.burrowdash_holefx.Transform:SetPosition(x, y, z)
		inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge")

		-- Fase 1: o coelho sobe do fundo do buraco, crescendo.
		inst.burrowdash_rabbitfx = SpawnPrefab("wunny_burrowdash_rabbit_fx")
		inst.burrowdash_rabbitfx.Transform:SetPosition(x, y, z)
		inst.burrowdash_rabbitfx.Transform:SetRotation(inst.Transform:GetRotation())
		inst.burrowdash_rabbitfx.Transform:SetScale(WUNNY_BURROWDASH_MIN_SCALE, WUNNY_BURROWDASH_MIN_SCALE, WUNNY_BURROWDASH_MIN_SCALE)

		local grow_start = GetTime()
		inst.burrowdash_shrink_task = inst:DoPeriodicTask(FRAMES, function(inst)
			local elapsed = GetTime() - grow_start
			local k, target
			if inst.burrowdash_rabbitfx ~= nil then
				k = math.min(1, elapsed / WUNNY_BURROWDASH_RABBIT_TIME)
				target = inst.burrowdash_rabbitfx
			else
				-- Fase 2: a Wunny retoma de onde o coelho parou.
				k = math.min(1, (elapsed - WUNNY_BURROWDASH_RABBIT_TIME) / WUNNY_BURROWDASH_WUNNY_TIME)
				target = inst
			end
			local scale = WUNNY_BURROWDASH_MIN_SCALE + k * (1 - WUNNY_BURROWDASH_MIN_SCALE)
			target.Transform:SetScale(scale, scale, scale)
		end)

		-- Troca de volta: o coelho sai de cena e a Wunny reaparece no tamanho dele.
		inst.burrowdash_swap_task = inst:DoTaskInTime(WUNNY_BURROWDASH_RABBIT_TIME, function(inst)
			inst.burrowdash_swap_task = nil
			RemoveBurrowDashRabbitFX(inst)
			inst.Transform:SetScale(WUNNY_BURROWDASH_MIN_SCALE, WUNNY_BURROWDASH_MIN_SCALE, WUNNY_BURROWDASH_MIN_SCALE)
			inst.AnimState:SetMultColour(1, 1, 1, 1)
			-- Visível de novo, então volta a ser alvo válido.
			SetBurrowDashNoTarget(inst, false)
		end)

		inst.burrowdash_enter_task = inst:DoTaskInTime(WUNNY_BURROWDASH_RABBIT_TIME + WUNNY_BURROWDASH_WUNNY_TIME, function(inst)
			inst.burrowdash_enter_task = nil
			if inst.burrowdash_shrink_task ~= nil then
				inst.burrowdash_shrink_task:Cancel()
				inst.burrowdash_shrink_task = nil
			end
			inst.Transform:SetScale(1, 1, 1)

			-- O buraco fica um instante a mais sozinho, espelhando a pausa da
			-- entrada, e aí a skill encerra de fato (destravando o controle).
			inst.burrowdash_hidehole_task = inst:DoTaskInTime(WUNNY_BURROWDASH_HOLE_FADE_TIME, function(inst)
				inst.burrowdash_hidehole_task = nil
				AbortBurrowDash(inst)
			end)
		end)
	end

	local function StartBurrowDash(inst)
		if inst.is_burrowdashing then
			return
		end
		-- não pode ativar em combate: nem com um alvo hostil travado, nem
		-- durante uma animação de ataque/dano em andamento
		if (inst.components.combat ~= nil and inst.components.combat.target ~= nil)
			or (inst.sg ~= nil and (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("hit"))) then
			return
		end

		inst.is_burrowdashing = true
		inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunny_burrowdash", TUNING.WUNNY_BURROWDASH_SPEED_MULT)
		if inst.components.combat ~= nil then
			inst.components.combat.canattack = false
		end
		SetBurrowDashLocked(inst, true)
		inst:PushEvent("locomote")

		-- Encadeamento visual da entrada na toca: o buraco aparece sob a Wunny,
		-- que encolhe afundando nele; nos últimos 0.3s ela dá lugar a um coelho
		-- (a "transformação"), que continua a descida até desaparecer. Logo
		-- depois o buraco some e os montinhos de terra começam. O total continua
		-- sendo ENTER_TIME + HOLE_FADE_TIME.
		local x, y, z = inst.Transform:GetWorldPosition()
		inst.burrowdash_holefx = SpawnPrefab("wunny_burrowdash_fx")
		inst.burrowdash_holefx.Transform:SetPosition(x, y, z)
		inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge")

		-- Fase 1: a Wunny encolhe do tamanho normal até o de coelho.
		local shrink_start = GetTime()
		local function ShrinkTick(inst)
			local elapsed = GetTime() - shrink_start
			local k, target
			if inst.burrowdash_rabbitfx ~= nil then
				-- Fase 2: o coelho começa no tamanho natural dele e afunda.
				k = math.min(1, (elapsed - WUNNY_BURROWDASH_WUNNY_TIME) / WUNNY_BURROWDASH_RABBIT_TIME)
				target = inst.burrowdash_rabbitfx
			else
				k = math.min(1, elapsed / WUNNY_BURROWDASH_WUNNY_TIME)
				target = inst
			end
			local scale = 1 - k * (1 - WUNNY_BURROWDASH_MIN_SCALE)
			target.Transform:SetScale(scale, scale, scale)
		end
		inst.burrowdash_shrink_task = inst:DoPeriodicTask(FRAMES, ShrinkTick)

		-- Troca da aparência: a Wunny some e o coelho aparece no lugar dela,
		-- virado pro mesmo lado.
		inst.burrowdash_swap_task = inst:DoTaskInTime(WUNNY_BURROWDASH_WUNNY_TIME, function(inst)
			inst.burrowdash_swap_task = nil
			inst.AnimState:SetMultColour(1, 1, 1, 0)
			-- Sumiu da tela, então sai da mira dos bichos.
			SetBurrowDashNoTarget(inst, true)
			-- Volta ao tamanho normal já invisível, pra ela não reaparecer
			-- encolhida quando a toca for desligada.
			inst.Transform:SetScale(1, 1, 1)

			inst.burrowdash_rabbitfx = SpawnPrefab("wunny_burrowdash_rabbit_fx")
			inst.burrowdash_rabbitfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst.burrowdash_rabbitfx.Transform:SetRotation(inst.Transform:GetRotation())
		end)

		inst.burrowdash_enter_task = inst:DoTaskInTime(WUNNY_BURROWDASH_ENTER_TIME, function(inst)
			inst.burrowdash_enter_task = nil
			if inst.burrowdash_shrink_task ~= nil then
				inst.burrowdash_shrink_task:Cancel()
				inst.burrowdash_shrink_task = nil
			end
			RemoveBurrowDashRabbitFX(inst)

			inst.burrowdash_hidehole_task = inst:DoTaskInTime(WUNNY_BURROWDASH_HOLE_FADE_TIME, function(inst)
				inst.burrowdash_hidehole_task = nil
				RemoveBurrowDashHoleFX(inst)
				-- Animação concluída: devolve o controle.
				SetBurrowDashLocked(inst, false)

				inst.burrowdash_task = inst:DoPeriodicTask(0.3, function()
					local x, y, z = inst.Transform:GetWorldPosition()
					SpawnPrefab("mole_move_fx").Transform:SetPosition(x, y, z)
				end, 0)
			end)
		end)
	end

	inst.ToggleBurrowDash = function(inst)
		if inst.burrowdash_exiting then
			-- Já está saindo: ignora o toggle pra não reiniciar a coreografia.
			return
		elseif inst.is_burrowdashing then
			StartBurrowDashExit(inst)
		else
			StartBurrowDash(inst)
		end
	end

	-- Interrupções à força cortam a animação: não faz sentido gastar 0.7s de saída
	-- coreografada com ela tomando dano ou morrendo.
	inst:ListenForEvent("attacked", function(inst) AbortBurrowDash(inst) end)
	inst:ListenForEvent("death", function(inst) AbortBurrowDash(inst) end)
	inst:ListenForEvent("onremove", function(inst) AbortBurrowDash(inst) end)

	-- Stats
	inst.components.health:SetMaxHealth(TUNING.WUNNY_HEALTH)
	inst.components.hunger:SetMax(TUNING.WUNNY_HUNGER)
	inst.components.sanity:SetMax(TUNING.WUNNY_SANITY)

	inst:AddComponent("periodicspawner")
	inst.components.periodicspawner:SetPrefab("poop")
	inst.components.periodicspawner:SetRandomTimes(TUNING.TOTAL_DAY_TIME * 2.45, TUNING.SEG_TIME * 2.2)
	inst.components.periodicspawner:SetDensityInRange(20, 2)
	inst.components.periodicspawner:SetMinimumSpacing(8)
	inst.components.periodicspawner:Start()

	-- Sanity rate
	-- inst.components.sanity.night_drain_mult = 0

	function AwardPlayerAchievement(name, player)
		if IsConsole() then
			if player ~= nil and player:HasTag("player") then
				TheGameService:AwardAchievement(name, tostring(player.userid))
			else
				print("AwardPlayerAchievement Error:", name, "to", tostring(player))
			end
		end
	end

	inst:DoPeriodicTask(0.2, function()
		if inst.components.inventory == nil then
			return
		end
		local pos = Vector3(inst.Transform:GetWorldPosition())
		local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 6)
		-- local isNearbyRabbit = false
		for k, v in pairs(ents) do
			if v.prefab then
				-- if
				-- then
				-- 	if v.components.follower.leader == nil
				-- 	then
				-- 		if v.components.combat:TargetIs(inst) then
				-- 			v.components.combat:SetTarget(nil)
				-- 		end
				-- 		inst.components.leader:AddFollower(v)
				-- 		--lose hunger on befriending
				-- 		inst.components.hunger:DoDelta(-12.5)
				-- 	end
				-- end
				if
					v.prefab == "bunnyman"
					or v.prefab == "newbunnyman"
					or v.prefab == "everythingbunnyman"
					or v.prefab == "daybunnyman"
					or v.prefab == "ultrabunnyman"
					or v.prefab == "shadowbunnyman"
					or v.prefab == "dwarfbunnyman"
					or v.prefab == "wunnywalrus"
				then
					local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
					if item and item.prefab == "strawhat" then
						-- print("o item na cabeça é strawhat")
						if v.components.inventoryitem ~= nil then
							v.components.inventoryitem.canbepickedup = true
						end
					else
						-- print("n tem item ou diferente de straw")
						if v.components.inventoryitem ~= nil then
							v.components.inventoryitem.canbepickedup = false
						end
					end
					--beardlordhat
					if item and item.prefab == "beardlordhat" then
						print("o item na cabeça é beardlordhat")
						print("tentando adicionar a tag crazy")
						if not v:HasTag("crazy") then
							print("adicionando tag crazy")
							v:AddTag("crazy")
						end
					else
						if v.prefab ~= "shadowbunnyman" and v:HasTag("crazy") then
							print("tirando tag crazy")
							v:RemoveTag("crazy")
						end
					end
					--end of beardlordhat
					if v.components.follower.leader == nil then
						if v.components.combat:TargetIs(inst) then
							v.components.combat:SetTarget(nil)
						end
						inst.components.leader:AddFollower(v)
						--lose hunger on befriending
						inst.components.hunger:DoDelta(-12.5)
					end
					-- if v.prefab == "dwarfbunnyman" then
					-- 	v.components.inventoryitem.canbepickedup = true
					-- end
				elseif v.prefab == "rabbit" then
					v.components.inventoryitem.canbepickedup = true
				elseif v.prefab == "researchlab" and inst.components.builder.science_bonus < 1 then
					inst.components.builder.science_bonus = 1
				elseif v.prefab == "researchlab2" and inst.components.builder.science_bonus < 2 then
					inst.components.builder.science_bonus = 2
				elseif v.prefab == "researchlab4" and inst.components.builder.magic_bonus < 2 then
					inst.components.builder.magic_bonus = 2
				-- researchlab3 é o Shadow Manipulator (tier 3 de MAGIA), então o guard
				-- tem que olhar magic_bonus. Estava checando science_bonus < 3 — e
				-- como nada nunca sobe science_bonus acima de 2, o guard era sempre
				-- verdadeiro e reatribuía magic_bonus a cada tick de 0.2s.
				elseif v.prefab == "researchlab3" and inst.components.builder.magic_bonus < 3 then
					inst.components.builder.magic_bonus = 3
				elseif v.prefab == "seafaring_prototyper" and inst.components.builder.seafaring_bonus < 2 then
					inst.components.builder.seafaring_bonus = 2
				elseif
					v.prefab == "bookstation"
					-- and inst.components.builder.bookcraft_bonus < 1
				then
					inst.components.builder.bookcraft_bonus = 1
				elseif
					v.prefab == "tacklestation"
					-- and inst.components.builder.fishing_bonus < 1
				then
					inst.components.builder.fishing_bonus = 1
				elseif v.prefab == "butterflywings" and v.components.edible.foodtype ~= FOODTYPE.GOODIES then
					v.components.edible.foodtype = FOODTYPE.GOODIES
				end
				-- elseif v.prefab == "turfcraftingstation"
				-- 	and inst.components.builder.fishing_bonus < 2
				-- then
				-- 	inst.components.builder.fishing_bonus = 2
				-- end
			end
		end

		-- local pos = Vector3(inst.Transform:GetWorldPosition())
		-- local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 24)
		-- for k, v in pairs(ents) do
		-- 	if v.prefab == "rabbit" then
		-- 		-- if isNearbyRabbit == false thenw
		-- 			v.components.inventoryitem.canbepickedup = false
		-- 		-- end
		-- 	end
		-- end
	end)

	--Woodlegs-style treasure sense: periodically pings nearby buried treasure (graves, pirate stashes)
	inst._wunny_treasuresense_marked = {}

	inst:DoPeriodicTask(10, function()
		if inst.components.health == nil or inst.components.health:IsDead() then
			return
		end
		local pos = Vector3(inst.Transform:GetWorldPosition())
		local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 30, { "buried" })
		for k, v in pairs(ents) do
			if v:IsValid() and not inst._wunny_treasuresense_marked[v.GUID] then
				inst._wunny_treasuresense_marked[v.GUID] = true

				local marker = SpawnPrefab("messagebottletreasure_marker")
				if marker ~= nil then
					marker.entity:SetParent(v.entity)
					marker:DoTaskInTime(45, function()
						if marker:IsValid() then
							marker:Remove()
						end
					end)
				end

				inst:DoTaskInTime(60, function()
					inst._wunny_treasuresense_marked[v.GUID] = nil
				end)
			end
		end
	end)

	inst:RemoveTag("scarytoprey")

	if TheWorld:HasTag("cave") then
		caveBehaviour(inst)
	else
		surfaceBehaviour(inst)
	end

	local function OnKill(victim, inst)
		if victim and victim.prefab then
			if victim.prefab == "rabbit" then
				inst.components.sanity:DoDelta(-10)
				local dropChance = math.random(0, 1)
				if dropChance == 1 then
					local item = SpawnPrefab("carrot")
					inst.components.inventory:GiveItem(item, nil, inst:GetPosition())
				end
			elseif
				victim.prefab == "bunnyman"
				or victim.prefab == "newbunnyman"
				or victim.prefab == "everythingbunnyman"
				or victim.prefab == "daybunnyman"
				or victim.prefab == "ultrabunnyman"
				or victim.prefab == "shadowbunnyman"
				or victim.prefab == "dwarfbunnyman"
			then
				inst.components.sanity:DoDelta(-10)
				local dropChance = math.random(0, 2)
				if dropChance == 1 then
					local item = SpawnPrefab("manrabbit_tail")
					inst.components.inventory:GiveItem(item, nil, inst:GetPosition())
				end
			end
		end
	end

	inst:ListenForEvent("killed", function(inst, data)
		OnKill(data.victim, inst)
	end)

	-- local function OnInsane(inst)
	-- 	-- inst.components.locomotor.runspeed = 6
	-- end

	-- inst:DoPeriodicTask(1, function()
	-- 	if inst.components.sanity.current < 60 and inst.components.health.currenthealth > 0 then

	-- 		OnInsane(inst)
	-- 	end
	-- end)
	-- inst.components.petleash:SetMaxPets(0) -- walter can only have Woby as a pet

	inst._wobybuck_damage = 0
	inst:ListenForEvent("timerdone", OnTimerDone)

	inst._woby_spawntask = inst:DoTaskInTime(0, function(i)
		i._woby_spawntask = nil
		SpawnWoby(i)
	end)
	inst._woby_onremove = function(woby)
		OnWobyRemoved(inst)
	end

	inst.OnWobyTransformed = OnWobyTransformed

	inst.OnSave = OnSave
	inst.OnLoad = onload
	inst.OnNewSpawn = onload
	inst.OnDespawn = OnDespawn
	inst:ListenForEvent("ms_playerreroll", OnReroll)
	inst:ListenForEvent("sanitydelta", OnSanityDelta)

	inst:ListenForEvent("onremove", OnRemoveEntity)

	inst:ListenForEvent("healthdelta", OnHealthDelta)
	inst:ListenForEvent("attacked", OnAttacked)

	inst._sanity_damage_protection = SourceModifierList(inst)

	local moisture = inst.components.moisture
	local GetDryingRate_prev = moisture.GetDryingRate
	function moisture:GetDryingRate(moisturerate, ...)
		local rate = GetDryingRate_prev(self, moisturerate, ...)
		rate = rate * (1 - (1 * 0.20))
		return rate
	end

	inst._gears_eaten = 0
	inst._chip_inuse = 0
	inst._moisture_steps = 0
	inst._temperature_modulelean = 0 -- Positive if "hot", negative if "cold"; see wx78_moduledefs
	inst._num_frostybreath_modules = 0 -- So modules can activate WX's frostybreath outside of winter/low worldstate temperature

	if inst.components.eater ~= nil then
		inst.components.eater:SetCanEatGears()
		inst.components.eater:SetOnEatFn(OnEat)
	end

	----------------------------------------------------------------
	if inst.components.freezable ~= nil then
		inst.components.freezable.onfreezefn = OnFrozen
	end

	inst:AddComponent("upgrademoduleowner")
	inst.components.upgrademoduleowner.onmoduleadded = OnUpgradeModuleAdded
	inst.components.upgrademoduleowner.onmoduleremoved = OnUpgradeModuleRemoved
	inst.components.upgrademoduleowner.ononemodulepopped = OnOneUpgradeModulePopped
	inst.components.upgrademoduleowner.onallmodulespopped = OnAllUpgradeModulesRemoved
	inst.components.upgrademoduleowner.canupgradefn = CanUseUpgradeModule
	inst.components.upgrademoduleowner:SetChargeLevel(3)

	----------------------------------------------------------------
	-- wx78 (Chassis/Drones): entidade classificada (corpos reserva + drones de
	-- escaneamento). Só existe no servidor aqui; do lado do cliente ela chega
	-- via replicação de rede e se auto-anexa (ver Wunny_AttachClassified_wx78).
	inst.wx78_classified = SpawnPrefab("wx78_classified")
	inst.wx78_classified.entity:SetParent(inst.entity)

	inst.CanSpawnBackupBody = Wunny_CanSpawnBackupBody
	inst.TryToSpawnBackupBody = Wunny_TryToSpawnBackupBody

	inst:AddComponent("wx78_dronescouttracker")
	inst.components.wx78_dronescouttracker:SetOnStartTrackingFn(Wunny_OnDroneStartTracking)
	inst.components.wx78_dronescouttracker:SetOnStopTrackingFn(Wunny_OnDroneStopTracking)

	inst:ListenForEvent("energylevelupdate", OnUpgradeModuleChargeChanged)

	----------------------------------------------------------------
	inst:AddComponent("dataanalyzer")
	inst.components.dataanalyzer:StartDataRegen(TUNING.SEG_TIME)

	----------------------------------------------------------------
	inst:AddComponent("batteryuser")
	inst.components.batteryuser.onbatteryused = OnChargeFromBattery

	----------------------------------------------------------------
	-- inst:AddComponent("preserver")
	inst.components.preserver:SetPerishRateMultiplier(ModuleBasedPreserverRateFn)

	----------------------------------------------------------------
	inst:AddComponent("heater")
	inst.components.heater:SetThermics(false, false)
	inst.components.heater.heatfn = GetThermicTemperatureFn

	inst:ListenForEvent("death", onbecameghost)
	inst:ListenForEvent("ms_playerreroll", onbecameghost)
	inst:ListenForEvent("moisturedelta", OnWetnessChanged)
	inst:ListenForEvent("startstarving", OnStartStarving)
	inst:ListenForEvent("stopstarving", OnStopStarving)
	inst:ListenForEvent("timerdone", OnTimerFinished)

	inst.components.playerlightningtarget:SetHitChance(TUNING.WX78_LIGHTNING_TARGET_CHANCE)
	inst.components.playerlightningtarget:SetOnStrikeFn(OnLightningStrike)

	inst.AddTemperatureModuleLeaning = AddTemperatureModuleLeaning
	inst.SetForcedNightVision = SetForcedNightVision

	inst:AddComponent("ghostlybond")
	inst.components.ghostlybond.onbondlevelchangefn = ghostlybond_onlevelchange
	inst.components.ghostlybond.onsummonfn = ghostlybond_onsummon
	inst.components.ghostlybond.onrecallfn = ghostlybond_onrecall
	inst.components.ghostlybond.onsummoncompletefn = ghostlybond_onsummoncomplete
	inst.components.ghostlybond.changebehaviourfn = ghostlybond_changebehaviour

	inst.components.ghostlybond:Init("abigail", TUNING.ABIGAIL_BOND_LEVELUP_TIME)

	inst:ListenForEvent("onsisturnstatechanged", function(world, data)
		update_sisturn_state(inst, data.is_active)
	end, TheWorld)
	update_sisturn_state(inst)

	local wunny = inst
	-- inst:ListenForEvent("onbunnykingcreated", function()  end, TheWorld)
	inst:ListenForEvent("onbunnykingcreated", function(inst, data)
		print("onbunnykingcreated")
		if wunny.king ~= nil or data == nil or data.king == nil then
			return
		end

		RoyalUpgrade(wunny)
		TheWorld:AddTag("hasbunnyking")
		wunny.king = data.king
		TheWorld:PushEvent("upgradeBunnys")
	end, TheWorld)
	inst:ListenForEvent("onbunnykingdestroyed", function(inst)
		print("onbunnykingdestroyed")
		if wunny.king == nil then
			return
		end

		wunny.king = nil
		RoyalDowngrade(wunny)
		TheWorld:RemoveTag("hasbunnyking")
		TheWorld:PushEvent("downgradeBunnys")
	end, TheWorld)

	--Wortox (soul hop / almas)
	Wortox_ClearSoulhopCounter(inst)
	inst.TryToPortalHop = Wortox_TryToPortalHop
	inst.FinishPortalHop = Wortox_FinishPortalHop
	inst.GetHopsPerSoul = Wortox_GetHopsPerSoul
	inst.GetSoulEchoCooldownTime = Wortox_GetSoulEchoCooldownTime
	inst.GetSouls = Wortox_GetSouls

	inst:AddComponent("souleater")
	inst.components.souleater:SetOnEatSoulFn(Wortox_OnEatSoul)

	inst:ListenForEvent("murdered", Wortox_OnMurdered)
	inst:ListenForEvent("ms_respawnedfromghost", Wortox_OnRespawnedFromGhost)
	inst:ListenForEvent("ms_becameghost", Wortox_OnBecameGhost)
	Wortox_OnRespawnedFromGhost(inst) -- liga os listeners de morte próxima já no spawn

	--Willow (brasas): mesmo esquema do Wortox acima, com callbacks próprios.
	inst:ListenForEvent("ms_respawnedfromghost", Willow_OnRespawnedFromGhost)
	inst:ListenForEvent("ms_becameghost", Willow_OnBecameGhost)
	Willow_OnRespawnedFromGhost(inst)

	inst.components.combat.customdamagemultfn = Willow_CustomCombatDamage

	--Wolfgang (mightiness / disposição física)
	if inst.components.efficientuser == nil then
		inst:AddComponent("efficientuser")
	end
	inst:AddComponent("mightiness")
	inst.components.mightiness.BecomeState = Wunny_MightinessBecomeState
	inst.components.mightiness.GetScale = Wunny_MightinessGetScale
	inst:ListenForEvent("onhitother", Wolfgang_OnHitOther)
	inst:ListenForEvent("working", Wolfgang_OnDoingWork)
	inst:ListenForEvent("tilling", Wolfgang_OnTilling)

	-- wx78_moduledefs.lua (o arquivo vanilla dos módulos de upgrade, reaproveitado
	-- via require("wx78_moduledefs") lá em cima) checa
	-- inst.components.skilltreeupdater:IsActivated("wx78_circuitry_xxxbuffs_n")
	-- pra decidir se um módulo alpha/beta/gama plugado ganha o bônus de tier
	-- (calor, frio, taser, luz, música, xadrez, radar, digestão, blindagem...).
	-- A Wunny já tem um componente skilltreeupdater real (adicionado por
	-- player_common.lua pra todo personagem), só que nunca fica com nada
	-- "ativado" de verdade porque ApplyAllSkillTreeEffects chama onactivate
	-- direto, sem passar pelo fluxo normal de ActivateSkill. Como todas as
	-- skills da Wunny são permanentes por design, sobrescrevemos só o
	-- IsActivated (igual ao padrão já usado no mightiness com BecomeState) pra
	-- devolver true nas tags de circuito da Wunny, sem afetar as checagens de
	-- IsActivated de nenhuma outra skill/personagem.
	-- Chassis (corpos reserva/revive fantasma), Drones (scout/delivery/zap) e
	-- Allegiance (lunar/sombrio) usam exatamente o mesmo mecanismo: recipes.lua
	-- (builder_skill=...), wx78_classified.lua (GetMaxBackupBodies,
	-- GetNumFreeScoutingDrones) e skilltree_wx78.lua (onactivate dos módulos de
	-- aliança/drone) só fazem sentido pra Wunny se essas tags também
	-- devolverem true no IsActivated.
	local WX78_CIRCUITRY_SKILLS_ALWAYSON = {
		-- Circuitry
		wx78_circuitry_betterunplug = true,
		wx78_circuitry_bettercharge = true,
		wx78_circuitry_alphabuffs_1 = true,
		wx78_circuitry_alphabuffs_2 = true,
		wx78_circuitry_betabuffs_1 = true,
		wx78_circuitry_betabuffs_2 = true,
		wx78_circuitry_gammabuffs_1 = true,
		wx78_circuitry_gammabuffs_2 = true,
		wx78_circuitry_slot_1 = true,
		-- Chassis
		wx78_extrabody_1 = true,
		wx78_extrabody_2 = true,
		wx78_extrabody_3 = true,
		wx78_ghostrevive_1 = true,
		wx78_ghostrevive_2 = true,
		wx78_ghostrevive_3 = true,
		wx78_remotebodyswap = true,
		wx78_bodycircuits = true,
		-- Drones
		wx78_scoutdrone_1 = true,
		wx78_extradronerange = true,
		wx78_deliverydrone_1 = true,
		wx78_deliverydrone_2 = true,
		wx78_zapdrone_1 = true,
		wx78_zapdrone_2 = true,
		-- Allegiance
		wx78_allegiance_lunar = true,
		wx78_allegiance_shadow = true,
	}
	local skilltreeupdater_IsActivated_prev = inst.components.skilltreeupdater.IsActivated
	function inst.components.skilltreeupdater:IsActivated(skill, ...)
		if WX78_CIRCUITRY_SKILLS_ALWAYSON[skill] then
			return true
		end
		return skilltreeupdater_IsActivated_prev(self, skill, ...)
	end

	--Winona (skill "winona_charlie_1"): os óculos rosados delegam a inspeção pra
	--este componente do dono (hats.lua roseglasses_inspectpoint/inspecttarget).
	--Sem ele o item equipa mas não inspeciona nada.
	inst:AddComponent("roseinspectableuser")

	WunnySkillTree.ApplyAllSkillTreeEffects(inst)

	--Winona: as estruturas de engenharia só releem as skills do construtor quando
	--são montadas ou quando um destes eventos passa pelo mundo (ver os
	--ListenForEvent em winona_catapult.lua / winona_spotlight.lua /
	--winona_battery_*.lua, e as cópias wunny_* deste mod). Como as skills da Wunny
	--são concedidas aqui, de uma vez, e não pela UI da árvore, ninguém dispara
	--"onactivateskill_server" por ela — sem estes pushes as estruturas que já
	--existiam num save antigo continuariam sem bônus até serem reconstruídas.
	--
	--Em DoTaskInTime(0) porque o skilltreeupdater da Wunny ainda não terminou de
	--carregar neste ponto do master_postinit; é o mesmo instante em que
	--winona.lua faz isso, só que lá pelo evento "ms_skilltreeinitialized".
	inst:DoTaskInTime(0, function(inst)
		if inst:IsValid() then
			TheWorld:PushEvent("winona_catapultskillchanged", inst)
			TheWorld:PushEvent("winona_spotlightskillchanged", inst)
			TheWorld:PushEvent("winona_batteryskillchanged", inst)
		end
	end)
end

return MakePlayerCharacter("wunny", prefabs, assets, common_postinit, master_postinit, prefabs, prefabsItens)
-- ,MakePlacer("common/rabbithole_placer", "rabbithole", "rabbit_hole", "anim")
