--[[
	Walter: roda de comandos montada, dash e correio do Woby (porte de walter.lua).

	POR QUE ISTO É UM ARQUIVO SEPARADO: mesma razão de wunny_wormwood_bloom.lua —
	o chunk principal de prefabs/wunny.lua bateu no limite rígido do Lua 5.1 de
	200 variáveis locais por função. Este bloco sozinho eram ~25 locais de topo.
]]

local WobyCommon = require("prefabs/wobycommon")

--------------------------------------------------------------------------------------
-- Walter: roda de comandos montada, dash e correio do Woby.
--
-- Ao contrário do Wilson/Willow/Winona, aqui a whitelist NÃO basta. A Wunny já
-- ganha a Woby (SpawnWoby mais acima + tag "dogrider") e a Woby é o prefab
-- vanilla sem alteração, então a roda de comandos que abre ao clicar NELA já
-- funciona: wobycommon.lua:RefreshCommands lê o skilltreeupdater do jogador e
-- wobybig/wobysmall criam o woby_commands_classified e o pluga no dono sozinhos.
--
-- O que falta é a metade que mora no PERSONAGEM, e que o walter.lua monta por
-- conta própria:
--   1. a roda de comandos MONTADA (spellbook no próprio jogador, usada enquanto
--      cavalga a Woby) — é por onde passam os toggles de corrida e dash sombrio;
--   2. ACTIONS.DASH via duplo-clique (skill walter_woby_dash);
--   3. ACTIONS.WHISTLE pra chamar a Woby de volta;
--   4. o componente "wobycourier" e o marcador de minimapa do baú lembrado.
--
-- Sem esse bloco as seis skills que só se manifestam por essas interfaces
-- (woby_sprint, woby_dash, woby_shadow, woby_foraging/itemfetcher/taskaid pela
-- roda montada, camp_wobycourier) ficariam "ativas" e inalcançáveis.
--
-- Porte de walter.lua. O rastro de poeira da corrida (has_sprint_trail /
-- EnableWobySprintTrail / OnUpdateSprintTrail) ficou DE FORA: são ~200 linhas de
-- FX com pool de entidades e de sons, puramente cosmético, e todos os pontos que
-- chamam isso em SGwilson.lua/SGwilson_client.lua estão guardados por
-- "if inst.EnableWobySprintTrail then" — a corrida funciona igual, só não deixa
-- rastro.
--------------------------------------------------------------------------------------

local WALTER_EMPTY_TABLE = {}

local WOBY_ICON_SCALE = 0.6
local WOBY_SPELLBOOK_RADIUS = 120
local WOBY_SPELLBOOK_FOCUS_RADIUS = WOBY_SPELLBOOK_RADIUS

local function Walter_DoSpellAction(inst)
	local inventory = ThePlayer.replica.inventory
	if inventory then
		inventory:CastSpellBookFromInv(inst)
	end
end

local WOBY_BLANK_SPELL = {
	label = "",
	bank = "spell_icons_woby",
	build = "spell_icons_woby",
	anims = {
		disabled = { anim = "empty" },
	},
	widget_scale = WOBY_ICON_SCALE,
	checkenabled = function() return false end,
	noselect = true,
}

local WOBY_SPACER_SPELL = shallowcopy(WOBY_BLANK_SPELL)
WOBY_SPACER_SPELL.spacer = true

local WOBY_SPELLBOOK_BG = {
	bank = "spell_icons_woby",
	build = "spell_icons_woby",
	anim = "bg",
	widget_scale = WOBY_ICON_SCALE,
}

local WOBY_MOUNTED_SPELLS_RIGHT = {
	{
		label = STRINGS.ACTIONS.DISMOUNT,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ACTIONS.DISMOUNT)
			inst.components.spellbook:SetSpellAction(ACTIONS.DISMOUNT)
			inst.components.spellbook.closeonexecute = true
		end,
		execute = Walter_DoSpellAction,
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims = {
			idle = { anim = "dismount" },
			focus = { anim = "dismount_focus" },
			down = { anim = "dismount_pressed" },
		},
		widget_scale = WOBY_ICON_SCALE,
		postinit = WobyCommon.SetupMouseOver,
		default_focus = true,
	},
	{
		label = STRINGS.ACTIONS.RUMMAGE.GENERIC,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ACTIONS.RUMMAGE.GENERIC)
			inst.components.spellbook:SetSpellAction(ACTIONS.RUMMAGE)
			inst.components.spellbook.closeonexecute = true
		end,
		execute = Walter_DoSpellAction,
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims = {
			idle = { anim = "opencontainer" },
			focus = { anim = "opencontainer_focus" },
			down = { anim = "opencontainer_pressed" },
		},
		widget_scale = WOBY_ICON_SCALE,
		postinit = WobyCommon.SetupMouseOver,
	},
	WOBY_BLANK_SPELL,
	{
		label = STRINGS.WOBY_COMMANDS.SHRINK,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.WOBY_COMMANDS.SHRINK)
			inst.components.spellbook:SetSpellAction(nil)
			inst.components.spellbook.closeonexecute = true
		end,
		execute = WobyCommon.MakeWobyCommand(WobyCommon.COMMANDS.SHRINK),
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims = {
			idle = { anim = "forcetransform" },
			focus = { anim = "forcetransform_focus" },
			down = { anim = "forcetransform_pressed" },
		},
		widget_scale = WOBY_ICON_SCALE,
		postinit = WobyCommon.SetupMouseOver,
	},
}

local WOBY_MOUNTED_SPELLS_LEFT = {
	{
		label = STRINGS.WOBY_COMMANDS.SPRINTING,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.WOBY_COMMANDS.SPRINTING)
			inst.components.spellbook:SetSpellAction(nil)
			inst.components.spellbook.closeonexecute = false
		end,
		execute = WobyCommon.MakeWobyCommand(WobyCommon.COMMANDS.SPRINTING),
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims = {
			idle = { anim = "sprinting" },
			focus = { anim = "sprinting_focus" },
			down = { anim = "sprinting_pressed" },
		},
		widget_scale = WOBY_ICON_SCALE,
		postinit = WobyCommon.MakeAutocastToggle("sprinting"),
		skill = "walter_woby_sprint",
	},
	{
		label = STRINGS.WOBY_COMMANDS.SHADOWDASH,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.WOBY_COMMANDS.SHADOWDASH)
			inst.components.spellbook:SetSpellAction(nil)
			inst.components.spellbook.closeonexecute = false
		end,
		execute = WobyCommon.MakeWobyCommand(WobyCommon.COMMANDS.SHADOWDASH),
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims = {
			idle = { anim = "shadowdash" },
			focus = { anim = "shadowdash_focus" },
			down = { anim = "shadowdash_pressed" },
		},
		widget_scale = WOBY_ICON_SCALE,
		postinit = WobyCommon.MakeAutocastToggle("shadowdash"),
		skill = "walter_woby_shadow",
	},
}

--Monta inst._spells no layout de 10 posições que a roda espera (duas colunas de
--5, com espaçadores nas pontas). Mesmo algoritmo de walter.lua:RefreshSpells.
local function Walter_RefreshSpells(inst)
	local skilltreeupdater = inst.components.skilltreeupdater
	local j = 1

	inst._spells[1] = WOBY_SPACER_SPELL
	j = j + 1

	for i, v in ipairs(WOBY_MOUNTED_SPELLS_RIGHT) do
		if v.skill == nil or skilltreeupdater:IsActivated(v.skill) then
			inst._spells[j] = v
		else
			inst._spells[j] = WOBY_BLANK_SPELL
		end
		j = j + 1
	end

	for i = j, 5 do
		inst._spells[j] = WOBY_BLANK_SPELL
		j = j + 1
	end

	inst._spells[j] = WOBY_SPACER_SPELL
	j = j + 1

	for i, v in ipairs(WOBY_MOUNTED_SPELLS_LEFT) do
		if v.skill == nil or skilltreeupdater:IsActivated(v.skill) then
			inst._spells[j] = v
			j = j + 1
		end
	end

	if j <= 10 then
		local shift = 11 - j
		for i = j - 1, 7, -1 do
			inst._spells[i + shift] = inst._spells[i]
		end
		for i = 7, 7 + shift - 1 do
			inst._spells[i] = WOBY_BLANK_SPELL
		end
	end
end

--A lista só fica ativa enquanto cavalga a Woby, senão o spellbook do jogador
--responderia a clique fora do contexto. Precisa rodar nos DOIS lados: o cliente
--usa pra abrir a roda, e o servidor pra validar o SelectSpell que vem por RPC
--(components/inventory.lua:2442 indexa spellbook.items[spell_id]).
local function Walter_EnableMountedCommands(inst, enable)
	if enable then
		inst.components.spellbook:SetItems(inst._spells)
	else
		if inst.HUD and inst.HUD:GetCurrentOpenSpellBook() == inst then
			inst.HUD:CloseSpellWheel()
		end
		inst.components.spellbook:SetItems(WALTER_EMPTY_TABLE)
	end
end

local function Walter_DoUpdateMountCommandsTask(inst)
	inst._updatemountcommandstask = nil
	local rider = inst.replica.rider
	local mount = rider and rider:GetMount() or nil
	Walter_EnableMountedCommands(inst, mount ~= nil and mount:HasTag("woby"))
end

local function Walter_OnIsRiding_Client(inst)
	--o mount é classificado e o isriding não, então os dois não sincronizam no
	--mesmo tick — daí a espera de um frame antes de olhar a montaria.
	if inst._updatemountcommandstask then
		inst._updatemountcommandstask:Cancel()
		inst._updatemountcommandstask = nil
	end
	if inst.replica.rider:IsRiding() then
		inst._updatemountcommandstask = inst:DoStaticTaskInTime(0, Walter_DoUpdateMountCommandsTask)
	else
		Walter_EnableMountedCommands(inst, false)
	end
end

--Lado servidor: walter.lua liga/desliga a lista nos eventos de montar/desmontar.
local function Walter_OnMounted(inst, data)
	Walter_EnableMountedCommands(inst, data.target ~= nil and data.target:HasTag("woby"))
end

local function Walter_OnDismounted(inst, data)
	Walter_EnableMountedCommands(inst, false)
end

--A roda que a tecla de spellbook abre quando não está montada é a da própria Woby
--(o spellbook mora nela, criado por wobycommon.lua:SetupCommandWheel).
local function Walter_GetLinkedSpellBook(inst)
	local woby = inst.woby_commands_classified and inst.woby_commands_classified:GetWoby() or nil
	return woby and not woby:HasTag("INLIMBO") and woby or nil
end

local function Walter_ShouldOpenWobyCommands(inst, user)
	return user.woby_commands_classified and not user.woby_commands_classified:IsBusy()
end

local function Walter_OnSkillTreeInitialized_RefreshSpells(inst)
	inst:RemoveEventCallback(TheWorld.ismastersim and "ms_skilltreeinitialized" or "skilltreeinitialized_client", Walter_OnSkillTreeInitialized_RefreshSpells)
	Walter_RefreshSpells(inst)
end

local function Walter_SetupMountedCommandWheel(inst)
	inst._spells = {}

	inst:AddComponent("spellbook")
	inst.components.spellbook:SetRadius(WOBY_SPELLBOOK_RADIUS)
	inst.components.spellbook:SetFocusRadius(WOBY_SPELLBOOK_FOCUS_RADIUS)
	inst.components.spellbook:SetShouldOpenFn(Walter_ShouldOpenWobyCommands)
	inst.components.spellbook:SetItems(WALTER_EMPTY_TABLE)
	inst.components.spellbook:SetBgData(WOBY_SPELLBOOK_BG)
	inst.components.spellbook.opensound = "meta5/woby/bigwoby_actionwheel_UI"

	if TheWorld.ismastersim then
		inst:ListenForEvent("onactivateskill_server", Walter_RefreshSpells)
		inst:ListenForEvent("ondeactivateskill_server", Walter_RefreshSpells)
		if inst._PostActivateHandshakeState_Server == POSTACTIVATEHANDSHAKE.READY then
			Walter_RefreshSpells(inst)
		else
			inst:ListenForEvent("ms_skilltreeinitialized", Walter_OnSkillTreeInitialized_RefreshSpells)
		end
	else
		inst:ListenForEvent("isridingdirty", Walter_OnIsRiding_Client)
		inst:ListenForEvent("onactivateskill_client", Walter_RefreshSpells)
		inst:ListenForEvent("ondeactivateskill_client", Walter_RefreshSpells)
		if inst._PostActivateHandshakeState_Client == POSTACTIVATEHANDSHAKE.READY then
			Walter_RefreshSpells(inst)
		else
			inst:ListenForEvent("skilltreeinitialized_client", Walter_OnSkillTreeInitialized_RefreshSpells)
		end
	end
end

--Walter (skill "walter_woby_dash"): duplo-clique enquanto cavalga a Woby dá o
--avanço. Porte de walter.lua:GetDoubleClickActions.
--
--Ao contrário do pointspecialactionsfn (que a Wunny já usa pro Wortox/wx78/tocha/
--óculos rosados e por isso vive numa função só), o doubleclickactionsfn estava
--livre — nenhuma outra habilidade da Wunny usa esse slot.
local function Walter_GetDoubleClickActions(inst, pos, dir, target)
	if not inst.components.skilltreeupdater:IsActivated("walter_woby_dash") then
		return WALTER_EMPTY_TABLE
	end
	local rider = inst.replica.rider
	local mount = rider and rider:GetMount() or nil
	if mount and mount:HasTag("woby") then
		local pos2
		if dir then
			pos2 = inst:GetPosition()
			pos2.x = pos2.x + dir.x * 10
			pos2.y = 0
			pos2.z = pos2.z + dir.z * 10
		elseif target then
			pos2 = target:GetPosition()
			pos2.y = 0
		end
		return { ACTIONS.DASH }, pos2
	end
	return WALTER_EMPTY_TABLE
end

--Chamar a Woby de volta. Usada em dois caminhos vanilla, os dois já preparados
--pra personagens que não tenham o método: componentactions.lua:988 (mouse, pelo
--componente wobycourier) e o pointspecialactionsfn (controle).
local function Walter_HasWhistleAction(inst)
	if inst.woby_commands_classified then
		if inst.woby_commands_classified:IsOutForDelivery() then
			--indo pro destino ou guardando itens: a roda está bloqueada, então a
			--ação de chamar de volta não tem limite de distância
			return true
		end
		local woby = inst.woby_commands_classified:GetWoby()
		if TheWorld.ismastersim then
			if woby and not (inst.HUD and not woby:IsInLimbo() and woby:IsNear(inst, 16)) then
				return true
			end
		elseif inst.HUD and (woby == nil or woby:HasTag("INLIMBO") or not woby:IsNear(inst, 16)) then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------------
-- Walter (skill "walter_camp_wobycourier"): marcador do baú lembrado no minimapa e
-- a bandeira + "ping" que aparecem no destino quando a entrega é agendada.
--
-- É tudo visual do lado do dono, mas não é opcional: woby_commands_classified.lua
-- chama inst._parent:TempFocusRememberChest(x, z) em quatro pontos (linhas 393,
-- 816 e a limpeza em 869) — guardado por "and inst._parent.TempFocusRememberChest",
-- então sem estas funções o comando "lembrar baú" funciona e não dá retorno
-- nenhum na tela.
--------------------------------------------------------------------------------------

local function Walter_CreateWobyCourierBanner()
	local inst = CreateEntity()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	--[[entidade não-networkada]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

	inst.AnimState:SetBank("wobycourier_marker")
	inst.AnimState:SetBuild("wobycourier_marker")
	inst.AnimState:PlayAnimation("place")

	return inst
end

local function Walter_FadeOutBanner(inst, dt)
	if inst.delay > dt then
		inst.delay = inst.delay - dt
	elseif inst.fadetime > dt then
		if inst.delay >= 0 then
			TheFocalPoint.components.focalpoint:StopFocusSource(inst)
			inst.delay = -1
		end
		inst.fadetime = inst.fadetime - dt
		local k = 1 - inst.fadetime / 0.5
		k = 1 - k * k
		inst.AnimState:SetMultColour(1, 1, 1, k)
	else
		inst:Remove()
	end
end

local function Walter_DoBannerSound(inst, sound)
	inst.SoundEmitter:PlaySound(sound)
end

local function Walter_CancelTempFocusRememberChest(inst)
	inst.showchestbanner = nil
	if inst._tempfocus then
		inst._tempfocus.task:Cancel()
		inst._tempfocus:Remove()
		inst._tempfocus = nil
	end
end

local function Walter_TempFocusRememberChest(inst, x, z)
	inst.showchestbanner = true

	if not TheWorld.ismastersim then
		if inst._tempfocus == nil then
			inst._tempfocus = CreateEntity()
			inst._tempfocus:AddTag("CLASSIFIED")
			--[[entidade não-networkada]]
			inst._tempfocus.persists = false
			inst._tempfocus.entity:AddTransform()
			TheFocalPoint.components.focalpoint:StartFocusSource(inst._tempfocus, nil, nil, math.huge, math.huge, 10)
			inst._tempfocus:ListenForEvent("onremove", Walter_CancelTempFocusRememberChest, inst)
		else
			inst._tempfocus.task:Cancel()
		end
		inst._tempfocus.Transform:SetPosition(x, 0, z)
		inst._tempfocus.task = inst:DoTaskInTime(2, Walter_CancelTempFocusRememberChest)
	end
end

local function Walter_OnUpdateWobyCourierChestIcon(inst)
	local x, z = GetWobyCourierChestPosition(inst)
	if not x then
		if inst.wobycourier_chesticon_CLIENT then
			if inst.wobycourier_chesticon_CLIENT:IsValid() then
				inst.wobycourier_chesticon_CLIENT:Remove()
			end
			inst.wobycourier_chesticon_CLIENT = nil
		end
		return
	end

	if inst.wobycourier_chesticon_CLIENT == nil or not inst.wobycourier_chesticon_CLIENT:IsValid() then
		inst.wobycourier_chesticon_CLIENT = SpawnPrefab("wobycourier_marker")
		inst.wobycourier_chesticon_CLIENT:ListenForEvent("onremove", function()
			inst.wobycourier_chesticon_CLIENT:Remove()
			inst.wobycourier_chesticon_CLIENT = nil
		end, inst)
	end

	inst.wobycourier_chesticon_CLIENT.Transform:SetPosition(x, 0, z)

	if inst.showchestbanner then
		inst.showchestbanner = nil
		if inst._tempfocus then
			inst._tempfocus:Remove()
			inst._tempfocus = nil
		end

		local ping = SpawnPrefab("reticuleaoeping_1d2_12")
		ping.Transform:SetPosition(x, 0, z)

		local banner = Walter_CreateWobyCourierBanner()
		banner.Transform:SetPosition(x, 0, z)
		banner.AnimState:SetSortOrder(1)
		banner.AnimState:Hide("shadow")

		local bshadow = Walter_CreateWobyCourierBanner()
		bshadow.entity:SetParent(banner.entity)
		bshadow.AnimState:Hide("flag_parts")
		bshadow.AnimState:Hide("smoke")

		Walter_DoBannerSound(banner, "dontstarve/common/deathpoof")
		TheFocalPoint.components.focalpoint:StartFocusSource(banner, nil, nil, math.huge, math.huge, 10)
		banner:DoTaskInTime(26 * FRAMES, Walter_DoBannerSound, "dontstarve/common/plant")

		banner:AddComponent("updatelooper")
		banner.components.updatelooper:AddOnUpdateFn(Walter_FadeOutBanner)
		banner.delay = banner.AnimState:GetCurrentAnimationLength() + 0.25
		banner.fadetime = 0.5
	end
end

return {
	GetDoubleClickActions        = Walter_GetDoubleClickActions,
	SetupMountedCommandWheel     = Walter_SetupMountedCommandWheel,
	HasWhistleAction             = Walter_HasWhistleAction,
	TempFocusRememberChest       = Walter_TempFocusRememberChest,
	CancelTempFocusRememberChest = Walter_CancelTempFocusRememberChest,
	OnUpdateWobyCourierChestIcon = Walter_OnUpdateWobyCourierChestIcon,
	GetLinkedSpellBook           = Walter_GetLinkedSpellBook,
	OnMounted                    = Walter_OnMounted,
	OnDismounted                 = Walter_OnDismounted,
}
