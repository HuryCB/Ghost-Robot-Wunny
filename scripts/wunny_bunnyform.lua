--[[
	Transformação da Wunny em bunnyman.

	POR QUE ISTO É UM ARQUIVO SEPARADO: mesma razão de wunny_wormwood_bloom.lua e
	wunny_walter_woby.lua — o chunk principal de prefabs/wunny.lua bateu no limite
	rígido do Lua 5.1 de 200 variáveis locais por função.

	--------------------------------------------------------------------------------
	COMO FUNCIONA (padrão werebeaver do woodie.lua)
	--------------------------------------------------------------------------------
	Transformar = trocar o BANK de animação do jogador. O rig do jogador é o bank
	"wilson"; os bunnyman deste mod todos usam o bank "manrabbit" (conferido: os
	dez SetBank de scripts/prefabs/*bunnyman*.lua). A troca sai por
	skinner:SetSkinMode(modo, build), igual ao CustomSetSkinMode do woodie.lua — a
	linha que importa em components/skinner.lua:467 é

		base_skin = self.skin_data[skintype] or default_build or self.inst.prefab

	ou seja, o parâmetro `default_build` é a saída para personagens modados: não
	precisamos de skin registrada na loja, só passar "manrabbit_build" na mão.

	--------------------------------------------------------------------------------
	A RESTRIÇÃO NÃO É ESCOLHA DE DESIGN, É O BANK
	--------------------------------------------------------------------------------
	O bank "manrabbit" tem ~50 animações reais (lidas de data/anim/manrabbit_*.zip);
	o SGwilson toca centenas. Estado que manda tocar animação inexistente NUNCA
	recebe o "animover"/"animqueueover" que o devolveria pro idle, então o jogador
	trava em "busy" pra sempre. É por isso que as ações de trabalho ficam
	bloqueadas na forma — não por balanceamento, e sim porque chop/mine/dig/build
	não têm animação nesse bank.

	O bank tem exatamente 64 animações — a lista fica em BANK_ANIMS, extraída dos
	anim.bin e não de suposição. As que importam:
	  idle_loop, walk_pre/loop/pst, run_pre/loop/pst   -> os mesmos nomes do wilson
	  sleep_pre/loop/pst, hit, hit_big, death, eat     -> idem
	  frozen, frozen_loop_pst, shock_loop/pst          -> congelar e choque
	  atk, atk_object, atk_object_pre                  -> atacar, com ou sem arma
	  swap_object, swap_hat (símbolos)                 -> empunhar arma e usar chapéu
	  walk_overhead_*, idle_loop_overhead              -> carregar coisa pesada
	  pig_pickup, pig_take, pig_reject                 -> pegar/recusar objeto
	  boat_jump*                                       -> navegar
	  trans_beard_pre, trans_rabbit_pst                -> a própria transformação
	  dance, disgust, idle_angry/creepy/happy/earrub   -> emotes

	NÃO existem "carry" nem "swap_frozen", apesar de versões anteriores deste
	comentário afirmarem que sim.

	A convenção de nomes dos bancos de NPC do DST coincidir com a do wilson em
	locomoção/sono/dano é o que torna isto viável sem arte nova.

	--------------------------------------------------------------------------------
	ESTADO DESTE ARQUIVO
	--------------------------------------------------------------------------------
	Quatro formas jogáveis, uma por build de arte existente: bunnyman (manrabbit_build),
	daybunnyman, everythingbunnyman e shadowbunnyman. new/dwarf/ultra ficam de FORA por
	reusarem manrabbit_build — seriam desbloqueios visualmente idênticos ao base. Ver o
	comentário sobre isso logo acima de FORMS.

	Acesso: a casa da variante destrava a forma e define qual delas a tecla B ativa
	(ação WUNNY_BUNNYFORM_ATTUNE em modmain.lua); a tecla entra e sai. Ver o bloco
	"DESBLOQUEIO E SELEÇÃO".
]]

--------------------------------------------------------------------------------------
-- QUAIS VARIANTES VIRAM FORMA JOGÁVEL, E POR QUÊ SÓ ESTAS QUATRO
--
-- O mod tem sete bunnymen, mas só QUATRO builds de arte distintos:
--     manrabbit_build, daymanrabbit_build, everythingmanrabbit_build, shadowmanrabbit_build
-- "newbunnyman", "dwarfbunnyman" e "ultrabunnyman" reusam manrabbit_build, ou seja, são
-- visualmente idênticos ao bunnyman base. Expor os sete daria ao jogador três
-- desbloqueios que não mudam nada na tela — pior do que não existirem. Eles continuam
-- como tropa do exército, que é onde a diferença deles (brain/comportamento) aparece.
--
-- Os NÚMEROS abaixo NÃO são os dos prefabs de NPC. Lá as variantes são quase idênticas
-- em combate (todas ~110/100 de dano, 120/100 de velocidade) porque se diferenciam pelo
-- brain, que o jogador não usa. Como forma jogável isso deixaria os quatro tiers com a
-- mesma sensação, então aqui existe uma escada deliberada, exposta em TUNING pra ser
-- ajustada sem mexer neste arquivo.
--------------------------------------------------------------------------------------
local LADDER = TUNING.WUNNY_BUNNYFORM_LADDER or {}

local function MakeForm(build, tier, extra)
	local t = LADDER[tier] or {}
	local form = {
		--visual
		bank = "manrabbit",
		build = build,
		skinmode = "bunnyman_skin",
		shadow = { 1.5, .75 },

		--combate/movimento: base do bunnyman (tuning.lua:2362+ e
		--scripts/prefabs/bunnyman.lua:441-447) multiplicada pela escada do tier.
		damage = TUNING.BUNNYMAN_DAMAGE * (t.damage or 1),
		runspeed = TUNING.BUNNYMAN_RUN_SPEED * (t.speed or 1),
		walkspeed = TUNING.BUNNYMAN_WALK_SPEED * (t.speed or 1),

		--NÃO mexemos em health:SetMaxHealth: o bunnyman tem 200 de vida, mas
		--reescrever o máximo do jogador destruiria a pool dele na volta. O ganho de
		--resistência vem por absorção, que é o que o woodie.lua faz no beaver
		--(health:SetAbsorptionAmount).
		absorption = t.absorption or 0.2,

		--Aceleração do ataque. O estado "bunnyform_attack" é NOSSO, então dá para encurtar
		--o timeout dele e acelerar a animação junto — que é o único jeito de o jogador
		--realmente bater mais rápido. min_attack_period é só um piso anti-spam; baixamos
		--junto para ele não anular a aceleração nos tiers altos.
		attackrate = t.attackrate or 1,
		attackperiod = TUNING.WILSON_ATTACK_PERIOD / (t.attackrate or 1),

		--Eficiências de trabalho sem ferramenta (component "worker"). Ver o comentário do
		--LADDER em modmain.lua.
		work = t.work,

		--Dreno de sanidade por segundo enquanto a forma está ativa (0 = nenhum).
		--Só a shadow usa; ver o comentário em ApplyFormEffects.
		sanitydrain = t.sanitydrain or 0,

		--Teleporte de fuga ao levar dano (só a shadow, tier 4).
		blink = tier == 4,
	}
	if extra ~= nil then
		for k, v in pairs(extra) do
			form[k] = v
		end
	end
	return form
end

local FORMS = {
	bunnyman           = MakeForm("manrabbit_build", 1),
	daybunnyman        = MakeForm("daymanrabbit_build", 2),
	everythingbunnyman = MakeForm("everythingmanrabbit_build", 3),
	shadowbunnyman     = MakeForm("shadowmanrabbit_build", 4),
}

--A ordem define o índice do netvar (0 = forma nenhuma). Ao adicionar forma nova,
--acrescente NO FIM: mudar a ordem invalida saves em andamento.
--
--_bunnyform é um net_tinybyte (3 bits): o teto real aqui é SETE formas. Passar disso
--exige trocar o netvar por net_smallbyte em SetupNetvars, não só acrescentar na lista.
local FORM_ORDER = { "bunnyman", "daybunnyman", "everythingbunnyman", "shadowbunnyman" }

--------------------------------------------------------------------------------------
-- Casa -> forma que ela sintoniza. É a ÚNICA fonte de verdade do vínculo; a ação em
-- modmain.lua consulta esta tabela pra saber se a estrutura clicada vale alguma coisa.
--
-- As casas das três variantes não-jogáveis (new/dwarf/ultra) ficam de fora de propósito:
-- clicar nelas não oferece a ação, em vez de oferecer e falhar.
--------------------------------------------------------------------------------------
--
-- "newbunnyhouse" e não "bunnyhouse" para a forma base: bunnyhouse.lua existe no disco
-- mas NÃO está em PrefabFiles (modmain.lua:16-24), então não é uma entidade registrada.
-- A casa base craftável é a newbunnyhouse — a receita mais barata, cuja própria função
-- em modmain.lua ainda se chama bunnyhouse_recipe. Ela solta um "newbunnyman", que
-- compartilha manrabbit_build com o bunnyman: a casa do coelho comum destrava a forma
-- de cara comum, o que fecha certo.
local HOUSE_TO_FORM = {
	newbunnyhouse        = "bunnyman",
	daybunnyhouse        = "daybunnyman",
	everythingbunnyhouse = "everythingbunnyman",
	shadowbunnyhouse     = "shadowbunnyman",
}

local FORM_INDEX = {}
for i, name in ipairs(FORM_ORDER) do
	FORM_INDEX[name] = i
end

--------------------------------------------------------------------------------------
-- Ações sem animação própria no bank "manrabbit".
--
-- Cada uma destas levaria o SGwilson a um estado cuja animação não existe no bank
-- (build_pre/build_loop, chop_pre, mine_pre, pickup, ...). Quando o AnimState recebe
-- uma animação que o bank não tem, o jogador some da tela — foi o bug reportado ao
-- examinar e ao colher twigs/grass. O vanilla resolve o caso do beaver mandando
-- CHOP/MINE/HAMMER/DIG todos pro estado "gnaw" (SGwilson.lua:854+); aqui o análogo é
-- "atk", a única animação de ação que o bank tem, via estado "bunnyform_action".
--------------------------------------------------------------------------------------
--Nenhum estado vanilla é seguro na forma, então não há lista de ações a redirecionar:
--PatchAllActionHandlers manda tudo pro "bunnyform_action". Esta lista é só das que nem
--isso resolve — máquinas de estado longas, com loop e transições próprias, que não
--sobrevivem a virar um único PerformBufferedAction.
local BLOCKED_ACTION_NAMES = {
	"FISH", "FISH_OCEAN", "OCEAN_FISHING_CAST", "OCEAN_FISHING_REEL",
	"ROW", "ROW_FAIL",
}

local function GetForm(inst)
	local idx = inst._bunnyform ~= nil and inst._bunnyform:value() or 0
	local name = FORM_ORDER[idx]
	return name ~= nil and FORMS[name] or nil, name
end

local function IsInForm(inst)
	return inst._bunnyform ~= nil and inst._bunnyform:value() > 0
end

--------------------------------------------------------------------------------------
-- REDE DE SEGURANÇA DE ANIMAÇÃO
--
-- Lista extraída dos próprios anim.bin (manrabbit_basic/actions/attacks/boat_jump/
-- beard_*/parasite_death), não do que a gente supunha. Duas correções que ela trouxe:
-- não existe "carry" nem "swap_frozen" (o comentário antigo do cabeçalho errava nos
-- dois), e existem pig_pickup/pig_take/pig_reject, que são animações de pegar coisa.
--
-- POR QUE ISTO EXISTE, se os actionhandlers já são redirecionados: porque handler de
-- ação não é o único caminho para um estado. Dos 439 estados do SGwilson, 363 tocam
-- pelo menos uma animação que este bank não tem, e boa parte deles é alcançada por
-- EVENTO, não por ação — knockback, afogar, cair no void, nocaute, bocejo, emote,
-- powerup do WX-78. Pior: os nomes nem sempre são literais. GetRunStateAnim
-- (SGwilson.lua:502) monta o nome de ANDAR conforme o contexto, e só "run_*" está no
-- bank; carregar peso vira "heavy_walk_*", tempestade de areia "sand_walk_*", ficar
-- grogue "idle_walk_*", gelo fino "careful_walk_*". Ou seja: andar grogue sumia.
--
-- Enumerar isso estado a estado é a mesma corrida perdida das ações. Então validamos no
-- último ponto possível — a própria chamada de animação — trocando o AnimState por um
-- proxy enquanto a forma está ativa. Fora da forma o objeto real volta e nada disto roda.
--------------------------------------------------------------------------------------
local BANK_ANIMS = {}
for _, a in ipairs({
	"abandon", "alert_loop", "alert_pre", "alert_pst", "atk", "atk_object",
	"atk_object_pre", "beard_atk", "beard_idle_loop", "beard_run_loop", "beard_run_pre",
	"beard_run_pst", "beard_taunt", "beard_walk_loop", "beard_walk_pre", "beard_walk_pst",
	"boat_jump", "boat_jump_loop", "boat_jump_pre", "boat_jump_pst", "corpse",
	"corpse_hit", "dance", "death", "despawn", "disgust", "eat", "frozen",
	"frozen_loop_pst", "hit", "hit_big", "hungry", "idle_angry", "idle_creepy",
	"idle_earrub", "idle_happy", "idle_loop", "idle_loop_overhead", "manrabbit",
	"parasite_death_pst", "pig_pickup", "pig_reject", "pig_take", "run_loop", "run_pre",
	"run_pst", "shock_loop", "shock_pst", "sleep_loop", "sleep_pre", "sleep_pst",
	"spawn_loop", "spawn_pre", "spawn_pst", "trans_beard_pre", "trans_beard_pst",
	"trans_rabbit_pre", "trans_rabbit_pst", "walk_loop", "walk_overhead_loop",
	"walk_overhead_pre", "walk_overhead_pst", "walk_pre", "walk_pst",
}) do
	BANK_ANIMS[a] = true
end

--Substituto para uma animação que o bank não tem. A regra preserva o SUFIXO, porque os
--estados encadeiam _pre -> _loop -> _pst via animover: trocar por algo de sufixo
--diferente quebraria a cadeia e travaria o estado.
local ANIM_SUFFIXES = { pre = true, loop = true, pst = true }

local function ResolveAnim(anim)
	if type(anim) ~= "string" or BANK_ANIMS[anim] then
		return anim
	end

	--Sem alternação: padrão de Lua não tem "|". "%a+" não casa "_", então o base
	--preguiçoso cresce até sobrar exatamente o sufixo ("heavy_walk_pre" -> heavy_walk/pre).
	local base, suffix = anim:match("^(.-)_(%a+)$")
	if suffix ~= nil and not ANIM_SUFFIXES[suffix] then
		base, suffix = nil, nil
	end
	if suffix ~= nil then
		--Carregar coisa pesada acima da cabeça: o coelho tem animação própria pra isso.
		if base:find("heavy", 1, true) or base:find("overhead", 1, true) then
			return "walk_overhead_" .. suffix
		end
		--Todas as variantes de locomoção do GetRunStateAnim caem no andar normal.
		if base:find("walk") or base:find("run") or base:find("teeter")
			or base:find("sand") or base:find("careful") then
			return "run_" .. suffix
		end
		if suffix == "loop" then
			return "idle_loop"
		end
		return "atk"
	end

	if anim:find("emote", 1, true) then
		return "dance"
	end
	if anim:find("pickup", 1, true) then
		return "pig_pickup"
	end
	--Sem sufixo e desconhecida: "atk" é curta e termina, então o animover vem e o
	--estado sai sozinho em vez de travar em "busy".
	return "atk"
end

--Proxy: só PlayAnimation/PushAnimation são interceptados. Todo o resto é repassado ao
--userdata real — com o self trocado, senão a função em C receberia a tabela do proxy.
local function InstallAnimGuard(inst)
	if inst._bunnyform_animguard ~= nil then
		return
	end
	local real = inst.AnimState
	local proxy = {}
	inst._bunnyform_animguard = real

	function proxy:PlayAnimation(anim, loop)
		return real:PlayAnimation(ResolveAnim(anim), loop)
	end
	function proxy:PushAnimation(anim, loop)
		return real:PushAnimation(ResolveAnim(anim), loop)
	end

	setmetatable(proxy, { __index = function(t, k)
		local v = real[k]
		if type(v) == "function" then
			local forwarded = function(_, ...) return v(real, ...) end
			rawset(t, k, forwarded) --memoiza: o __index só paga o custo uma vez por método
			return forwarded
		end
		return v
	end })

	inst.AnimState = proxy
end

local function RemoveAnimGuard(inst)
	if inst._bunnyform_animguard ~= nil then
		inst.AnimState = inst._bunnyform_animguard
		inst._bunnyform_animguard = nil
	end
end

--------------------------------------------------------------------------------------
-- Visual. Roda nos DOIS lados (servidor e cliente): o cliente precisa aplicar o
-- bank/build por conta própria, senão a Wunny continua parecendo a Wunny na tela de
-- quem não é o host.
--------------------------------------------------------------------------------------
-- Chapéus. O hats.lua tem dois caminhos: um só pra owner.isplayer, que troca HEAD por
-- HEAD_HAT (prefabs/hats.lua:68-73), e o de mob, que apenas mostra a camada HAT com o
-- símbolo swap_hat (prefabs/hats.lua:152-155). O build do manrabbit não tem HEAD_HAT,
-- mas TEM HAT/swap_hat — é assim que os bunnymen do jogo aparecem de chapéu. Então na
-- forma desfazemos só o ramo isplayer e deixamos o resto como o hats.lua montou, o que
-- faz chapéu comum, opentop, fullhelm e chapéus de outros mods funcionarem sozinhos.
--------------------------------------------------------------------------------------
local function ShowPlainHead(inst)
	inst.AnimState:Show("HEAD")
	inst.AnimState:Hide("HEAD_HAT")
	inst.AnimState:Hide("HEAD_HAT_NOHELM")
	inst.AnimState:Hide("HEAD_HAT_HELM")
end

local function RefreshHatSymbols(inst)
	if IsInForm(inst) then
		--Não tocamos em HAT/HAIR/HAIR_HAT: as orelhas ficarem escondidas sob o chapéu é
		--o comportamento de mob do próprio jogo, igual aos coelhos vanilla.
		ShowPlainHead(inst)
		return
	end

	--Voltando pro rig do jogador: em vez de adivinhar o layout (chapéu comum, opentop e
	--fullhelm usam combinações diferentes de HEAD_HAT/HAIR/HAT), deixamos o próprio
	--chapéu se remontar. onequipfn é idempotente pro que nos interessa — o
	--fueled:StartConsuming() de dentro dele já checa se a task existe (fueled.lua).
	local hat = inst.components.inventory ~= nil
		and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
		or nil
	local equippable = hat ~= nil and hat.components.equippable or nil
	if equippable ~= nil and equippable.onequipfn ~= nil then
		equippable.onequipfn(hat, inst)
	else
		--Sem chapéu (ou no cliente, que não tem components.inventory): o AnimState é
		--replicado do servidor, então aqui basta não deixar a cabeça escondida.
		ShowPlainHead(inst)
	end
end

--------------------------------------------------------------------------------------
local function ApplyVisual(inst)
	local form = GetForm(inst)

	if form == nil then
		--Solta o proxy ANTES de qualquer coisa: o bank wilson tem todas as animações, e
		--o "transform_pst" que o estado toca logo depois não está no bank do coelho.
		RemoveAnimGuard(inst)
		--volta pro rig do jogador. "normal_skin" é o modo padrão do skinner; sem
		--default_build ele cai em self.inst.prefab, que é exatamente o build da Wunny.
		inst.AnimState:SetBank("wilson")
		if inst.components.skinner ~= nil then
			inst.components.skinner:SetSkinMode("normal_skin")
		end
		inst.DynamicShadow:SetSize(1.3, .6)
		--Depois do SetSkinMode, senão o skinner remonta por cima do que arrumamos.
		RefreshHatSymbols(inst)
		return
	end

	InstallAnimGuard(inst)

	--HideAllClothing antes de trocar o bank: as roupas são riggadas pro esqueleto do
	--wilson e ficariam flutuando soltas em cima do coelho.
	if inst.components.skinner ~= nil then
		inst.components.skinner:HideAllClothing(inst.AnimState)
	end
	inst.AnimState:SetBank(form.bank)
	if inst.components.skinner ~= nil then
		inst.components.skinner:SetSkinMode(form.skinmode, form.build)
	else
		--cliente sem skinner replicado ainda: pelo menos o build certo
		inst.AnimState:SetBuild(form.build)
	end
	inst.DynamicShadow:SetSize(unpack(form.shadow))
	RefreshHatSymbols(inst)
end

local function OnBunnyFormDirty(inst)
	ApplyVisual(inst)
end

--------------------------------------------------------------------------------------
-- Efeitos de servidor (stats/tags). Guardamos os valores anteriores em inst._bunnyform_prev
-- pra devolver na volta: escrever o valor "de fábrica" na mão daria conflito com os
-- outros sistemas da Wunny que também mexem em velocidade (mightiness do Wolfgang,
-- florescimento do Wormwood, carga do WX-78).
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- TELEPORTE DE FUGA DA FORMA SHADOW
--
-- "Seguro" aqui é uma checagem explícita, não só terreno pisável: FindWalkableOffset
-- garante chão, mas nada impede que o chão escolhido esteja no meio de um ninho de
-- aranhas — o teleporte de fuga entregaria a Wunny pra outro mob no frame seguinte. Por
-- isso cada candidato é varrido por hostis antes de ser aceito, e só se nenhuma das
-- tentativas passar é que caímos no melhor candidato pisável que apareceu.
--------------------------------------------------------------------------------------
local BLINK_HOSTILE_TAGS = { "hostile", "monster" }
local BLINK_HOSTILE_NOTAGS = { "player", "companion", "INLIMBO", "notarget" }

local function CountHostilesNear(x, z, radius)
	local ents = TheSim:FindEntities(x, 0, z, radius, nil, BLINK_HOSTILE_NOTAGS, BLINK_HOSTILE_TAGS)
	return #ents
end

local function TryBlink(inst)
	local cfg = TUNING.WUNNY_BUNNYFORM_BLINK or {}
	local x, y, z = inst.Transform:GetWorldPosition()
	local fallback = nil

	for _ = 1, cfg.tries or 12 do
		local dist = GetRandomMinMax(cfg.mindist or 6, cfg.maxdist or 11)
		local offset = FindWalkableOffset(Vector3(x, y, z), math.random() * TWOPI, dist, 8, false, true)
		if offset ~= nil then
			local cx, cz = x + offset.x, z + offset.z
			local hostiles = CountHostilesNear(cx, cz, cfg.safe_radius or 8)
			if hostiles == 0 then
				fallback = { cx, cz }
				break
			elseif fallback == nil then
				--Guarda o primeiro pisável como plano B: teleportar pra perto de um
				--hostil ainda é melhor que ficar exatamente onde já se está apanhando.
				fallback = { cx, cz }
			end
		end
	end

	if fallback == nil then
		return false
	end

	if Prefabs["statue_transition_2"] ~= nil then
		SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
	end
	inst.Physics:Teleport(fallback[1], y, fallback[2])
	if Prefabs["statue_transition_2"] ~= nil then
		SpawnPrefab("statue_transition_2").Transform:SetPosition(fallback[1], y, fallback[2])
	end
	return true
end

local function OnFormAttacked(inst)
	local cfg = TUNING.WUNNY_BUNNYFORM_BLINK or {}
	local now = GetTime()
	if inst._bunnyform_blink_t ~= nil and now - inst._bunnyform_blink_t < (cfg.cooldown or 8) then
		return
	end
	if math.random() >= (cfg.chance or 0.25) then
		return
	end
	if TryBlink(inst) then
		inst._bunnyform_blink_t = now
	end
end

local function ApplyFormEffects(inst, form)
	local combat = inst.components.combat
	local loco = inst.components.locomotor

	inst._bunnyform_prev = {
		damage = combat ~= nil and combat.defaultdamage or nil,
		attackperiod = combat ~= nil and combat.min_attack_period or nil,
		runspeed = loco ~= nil and loco.runspeed or nil,
		walkspeed = loco ~= nil and loco.walkspeed or nil,
	}

	if combat ~= nil then
		combat:SetDefaultDamage(form.damage)
		combat:SetAttackPeriod(form.attackperiod)
	end
	if loco ~= nil then
		loco.runspeed = form.runspeed
		loco.walkspeed = form.walkspeed
	end
	if inst.components.health ~= nil and form.absorption ~= nil then
		inst.components.health:SetAbsorptionAmount(form.absorption)
	end

	--"bunnyman": faz o exército de coelhos do mod tratar a Wunny como um dos seus.
	--"bunnyform": é por esta tag que o SGwilson remendado decide os nomes de animação.
	inst:AddTag("bunnyform")
	inst:AddTag("bunnyman")

	--TRABALHO SEM FERRAMENTA. Mesmo mecanismo do werebeaver (woodie.lua:846): o component
	--"worker" é o que o workable:WorkedBy consulta quando o executor não tem ferramenta na
	--mão. Sem ele a ação chega ao servidor e trabalha ZERO, silenciosamente.
	--
	--A Wunny normal não tem "worker", então dá pra remover o component inteiro na volta em
	--vez de guardar estado anterior. A tag "bunnyform_worker" é o que o coletor de ações no
	--modmain lê pra oferecer o verbo no clique — o component em si é só de servidor e o
	--cliente não enxerga.
	if form.work ~= nil and inst.components.worker == nil then
		inst:AddComponent("worker")
		for actname, eff in pairs(form.work) do
			if ACTIONS[actname] ~= nil then
				inst.components.worker:SetAction(ACTIONS[actname], eff)
				inst:AddTag(actname .. "_bunnywork")
			end
		end
	end

	--Teleporte de fuga da shadow.
	if form.blink then
		inst:ListenForEvent("attacked", OnFormAttacked)
	end

	--Dreno de sanidade (só a shadow, por padrão). O custo geral da forma já é o bloqueio
	--de craft e pesca e o fato de não poder usar equipamento — não faz sentido empilhar
	--dreno em todas. A shadow é a exceção porque o tema pede.
	--
	--Tarefa periódica em vez de sanity.custom_rate_fn: aquele campo é único e a Wunny já
	--tem vários sistemas de sanidade concorrendo (aura de fogo da Willow, almas do
	--Wortox); sobrescrevê-lo apagaria silenciosamente o que estivesse lá.
	--
	--Não damos AddTag("shadow")/("crazy") aqui de propósito: elas mudariam quem ataca a
	--Wunny e a quem os shadows são hostis, o que é escopo bem maior que "virar coelho".
	if (form.sanitydrain or 0) > 0 and inst.components.sanity ~= nil then
		inst._bunnyform_sanitytask = inst:DoPeriodicTask(1, function(i)
			if i.components.sanity ~= nil then
				i.components.sanity:DoDelta(-form.sanitydrain, true)
			end
		end)
	end

	--Nada de fechar o menu de craft aqui: fechar é coisa de HUD (cliente,
	--controls.lua:1027 owner.HUD:CloseCrafting), não de componente de servidor.
	--Craftar simplesmente não surte efeito porque ACTIONS.BUILD está bloqueada.
end

local function ClearFormEffects(inst)
	local prev = inst._bunnyform_prev
	local combat = inst.components.combat
	local loco = inst.components.locomotor

	if prev ~= nil then
		if combat ~= nil then
			if prev.damage ~= nil then
				combat:SetDefaultDamage(prev.damage)
			end
			if prev.attackperiod ~= nil then
				combat:SetAttackPeriod(prev.attackperiod)
			end
		end
		if loco ~= nil then
			if prev.runspeed ~= nil then
				loco.runspeed = prev.runspeed
			end
			if prev.walkspeed ~= nil then
				loco.walkspeed = prev.walkspeed
			end
		end
		inst._bunnyform_prev = nil
	end

	if inst.components.health ~= nil then
		inst.components.health:SetAbsorptionAmount(0)
	end

	--Sem isto o dreno da shadow continua rodando depois de voltar ao normal (e um
	--segundo dreno se soma a cada nova transformação).
	if inst._bunnyform_sanitytask ~= nil then
		inst._bunnyform_sanitytask:Cancel()
		inst._bunnyform_sanitytask = nil
	end

	--Trabalho sem ferramenta: a Wunny fora da forma não tem "worker", então o component
	--sai inteiro em vez de ser restaurado. As tags têm de sair junto, senão o coletor de
	--ações continuaria oferecendo cortar/minerar de mão limpa fora da forma.
	if inst.components.worker ~= nil then
		inst:RemoveComponent("worker")
	end
	for _, actname in ipairs({ "CHOP", "MINE", "DIG", "HAMMER" }) do
		inst:RemoveTag(actname .. "_bunnywork")
	end

	inst:RemoveEventCallback("attacked", OnFormAttacked)
	inst._bunnyform_blink_t = nil

	inst:RemoveTag("bunnyform")
	inst:RemoveTag("bunnyman")
end

--------------------------------------------------------------------------------------
-- API de transformação (servidor).
--------------------------------------------------------------------------------------
local function CanTransform(inst)
	return not inst:HasTag("playerghost")
		and not (inst.components.health ~= nil and inst.components.health:IsDead())
		and inst.sg ~= nil
		and not inst.sg:HasStateTag("busy")
end

--A troca em si. Chamada NO MEIO do estado de transformação (entre as duas
--animações), não antes dele — ver o comentário grande em bunnyform_transform.
local function CommitForm(inst, formname)
	local idx = FORM_INDEX[formname]
	if idx == nil then
		return
	end
	inst._bunnyform:set(idx)
	ApplyVisual(inst)
	ApplyFormEffects(inst, FORMS[formname])
end

local function CommitRevert(inst)
	inst._bunnyform:set(0)
	ClearFormEffects(inst)
	ApplyVisual(inst)
end

--Diagnóstico das saídas silenciosas. Sem isto, chamar Transform pelo console no
--lado errado (ou com a Wunny ocupada) não dá erro nenhum e não faz nada — que foi
--exatamente o primeiro sintoma no teste em jogo. Segue a convenção de print() do
--resto do mod; pode sair quando a roda de comandos estiver ligada.
local function Transform(inst, formname)
	if not TheWorld.ismastersim then
		print("[wunny/bunnyform] ignorado: rodou no CLIENTE. No console use Ctrl+Enter (modo remoto).")
		return false
	end
	if not CanTransform(inst) then
		print(string.format(
			"[wunny/bunnyform] ignorado: nao pode transformar agora (fantasma=%s morta=%s sg=%s ocupada=%s)",
			tostring(inst:HasTag("playerghost")),
			tostring(inst.components.health ~= nil and inst.components.health:IsDead()),
			tostring(inst.sg ~= nil),
			tostring(inst.sg ~= nil and inst.sg:HasStateTag("busy"))))
		return false
	end
	local idx = FORM_INDEX[formname]
	if idx == nil then
		print("[wunny/bunnyform] forma desconhecida:", tostring(formname),
			"| disponiveis:", table.concat(FORM_ORDER, ", "))
		return false
	end
	if inst._bunnyform == nil then
		print("[wunny/bunnyform] netvar ausente: SetupNetvars nao rodou no common_postinit.")
		return false
	end
	if inst._bunnyform:value() == idx then
		print("[wunny/bunnyform] ja esta nessa forma:", formname)
		return false
	end
	inst.sg:GoToState("bunnyform_transform", formname)
	return true
end

--------------------------------------------------------------------------------------
-- DESBLOQUEIO E SELEÇÃO
--
-- Regra do sistema: a CASA destrava e escolhe; a TECLA transforma.
--
-- Por que a casa não é uma "estação de transformação" (ter de voltar nela toda vez):
-- a forma é ferramenta de combate, e obrigar uma viagem à base a cada uso a mataria. O
-- precedente vanilla é o Woodie — o gate é adquirir a maldição, uma vez, e depois o
-- castor é um toggle livre.
--
-- Mas a casa não vira conteúdo morto depois do desbloqueio: é ela que define QUAL forma
-- a tecla ativa. Com quatro formas, uma tecla que cicla erraria o alvo em combate; assim
-- a escolha é deliberada e feita fora de perigo, e o uso continua a um toque.
--
-- Tudo aqui é servidor: não há netvar de desbloqueio. A ação da casa é oferecida sempre
-- (o servidor decide se ela destrava ou seleciona) e a tecla passa por RPC, então o
-- cliente nunca precisa saber o estado — o que economiza dois netvars e o risco de eles
-- dessincronizarem.
--------------------------------------------------------------------------------------
local function IsUnlocked(inst, formname)
	return inst._bunnyform_unlocked ~= nil and inst._bunnyform_unlocked[formname] == true
end

local function Say(inst, msg)
	if inst.components.talker ~= nil then
		inst.components.talker:Say(msg)
	end
end

--Ponto de entrada da ação na casa. Um único verbo para os dois casos (destravar e
--selecionar) de propósito: assim a ação pode ser oferecida sem o cliente conhecer o
--estado de desbloqueio.
--
--As saídas daqui são MUDAS pro jogador (a ação não tem como falar sozinha), então cada
--uma imprime. Sem isso, sintonizar sem efeito é indistinguível de sintonizar com efeito —
--foi assim que o primeiro teste em jogo só revelou o sintoma lá na frente, na tecla B.
local function AttuneAtHouse(inst, house)
	if not TheWorld.ismastersim then
		print("[wunny/bunnyform] attune ignorado: rodou no CLIENTE.")
		return false
	end
	if house == nil then
		print("[wunny/bunnyform] attune ignorado: alvo nulo.")
		return false
	end
	local formname = HOUSE_TO_FORM[house.prefab]
	if formname == nil then
		print("[wunny/bunnyform] attune ignorado: casa sem forma associada:", tostring(house.prefab))
		return false
	end
	print("[wunny/bunnyform] attune em", tostring(house.prefab), "-> forma", formname)

	if inst._bunnyform_unlocked == nil then
		inst._bunnyform_unlocked = {}
	end

	if not IsUnlocked(inst, formname) then
		inst._bunnyform_unlocked[formname] = true
		inst._bunnyform_selected = formname
		Say(inst, STRINGS.WUNNY_BUNNYFORM_UNLOCKED or "Agora eu sei virar isso!")
		return true
	end

	if inst._bunnyform_selected == formname then
		Say(inst, STRINGS.WUNNY_BUNNYFORM_ALREADY or "Já é essa forma que eu visto.")
		return false
	end

	inst._bunnyform_selected = formname
	Say(inst, STRINGS.WUNNY_BUNNYFORM_SELECTED or "É essa forma que eu vou vestir.")
	return true
end

--A forma que a tecla ativa. Cai na primeira desbloqueada se a seleção sumiu (forma
--removida do mod numa atualização, save antigo).
local function GetSelected(inst)
	local sel = inst._bunnyform_selected
	if sel ~= nil and FORMS[sel] ~= nil and IsUnlocked(inst, sel) then
		return sel
	end
	for _, name in ipairs(FORM_ORDER) do
		if IsUnlocked(inst, name) then
			return name
		end
	end
	return nil
end

local function Revert(inst)
	if not TheWorld.ismastersim then
		print("[wunny/bunnyform] ignorado: rodou no CLIENTE. No console use Ctrl+Enter (modo remoto).")
		return false
	end
	if not IsInForm(inst) then
		print("[wunny/bunnyform] ignorado: nao esta em forma nenhuma.")
		return false
	end
	if not CanTransform(inst) then
		print("[wunny/bunnyform] ignorado: ocupada/morta, nao da pra reverter agora.")
		return false
	end
	inst.sg:GoToState("bunnyform_untransform")
	return true
end

--O que a tecla chama. Na forma -> volta ao normal; fora dela -> entra na selecionada.
--
--Definido DEPOIS de Revert de propósito: os dois são locais, e chamar Revert de um
--"local function" declarado antes dele o resolveria como global (nil) em tempo de
--execução, sem erro de carga.
--
--O desbloqueio é checado AQUI e não em Transform: Transform continua sendo a porta crua
--pra console e depuração ("c_select(ThePlayer):BunnyFormTransform('shadowbunnyman')"),
--enquanto este é o caminho do jogador. Como o RPC só chama este, um cliente adulterado
--não consegue pular o gate.
local function ToggleForm(inst)
	if not TheWorld.ismastersim then
		return false
	end
	if IsInForm(inst) then
		return Revert(inst)
	end

	local formname = GetSelected(inst)
	if formname == nil then
		--Imprime o conteúdo real da tabela: "nenhuma desbloqueada" pode significar tanto
		--que o jogador não sintonizou quanto que o attune rodou e não persistiu, e sem
		--isto os dois casos são a mesma mensagem na tela.
		local names = {}
		for name in pairs(inst._bunnyform_unlocked or {}) do
			table.insert(names, name)
		end
		print("[wunny/bunnyform] toggle sem forma. desbloqueadas={" .. table.concat(names, ",")
			.. "} selecionada=" .. tostring(inst._bunnyform_selected))
		Say(inst, STRINGS.WUNNY_BUNNYFORM_NONE or "Preciso visitar uma casa de coelho antes.")
		return false
	end
	return Transform(inst, formname)
end

--Morrer ou virar fantasma na forma tem de desfazer tudo, senão a Wunny renasce
--coelho e com os stats do coelho.
local function OnBecameGhost(inst)
	if IsInForm(inst) then
		inst._bunnyform:set(0)
		ClearFormEffects(inst)
		ApplyVisual(inst)
	end
end

--------------------------------------------------------------------------------------
-- Persistência (save/load). Chamado pelo OnSave/onload de prefabs/wunny.lua.
--------------------------------------------------------------------------------------
local function OnSave(inst, data)
	local _, formname = GetForm(inst)
	if formname ~= nil then
		--Grava o NOME e não o índice do netvar: o índice depende de FORM_ORDER, e a nota
		--lá em cima já avisa que mexer na ordem invalidaria saves. Com o nome, reordenar
		--FORM_ORDER deixa de ser problema.
		data.bunnyform = formname
	end

	--Desbloqueios: gravados como { nome = true }, pelo mesmo motivo do campo acima —
	--um bitmask ou uma lista de índices dependeria de FORM_ORDER, e reordenar a tabela
	--faria todo mundo acordar com a forma errada destravada.
	if inst._bunnyform_unlocked ~= nil and next(inst._bunnyform_unlocked) ~= nil then
		data.bunnyform_unlocked = inst._bunnyform_unlocked
		data.bunnyform_selected = inst._bunnyform_selected
	end
end

--------------------------------------------------------------------------------------
-- POR QUE O RESTORE É ADIADO UM FRAME (e não feito na hora)
--
-- Não é cautela genérica: três coisas rodam DEPOIS desta função e desfazem a forma se
-- ela já estiver aplicada.
--
-- 1) Skinner:OnLoad (components/skinner.lua:814) termina em SetSkinName -> SetSkinMode()
--    SEM o parâmetro default_build. A linha que decide o build é
--        base_skin = self.skin_data[skintype] or default_build or self.inst.prefab
--    e como a Wunny não tem skin registrada pra "bunnyman_skin", isso cai em
--    self.inst.prefab = "wunny": build do rig do wilson com o bank "manrabbit" ainda
--    posto. É a Wunny invisível — o próprio skinner.lua:587 imprime
--    "Invisible werebeaver is probably about to happen" prevendo esse caso.
--
-- 2) onbecamehuman (wunny.lua:729) escreve locomotor.walkspeed = 6 na mão, por cima da
--    velocidade da forma.
--
-- 3) o onload da Wunny restaura a sanidade com sanity:SetPercent, que empurra
--    "sanitydelta" -> OnSanityDelta -> SetSkinMode(..., "wilson"), clobber igual ao (1).
--
-- Adiar também evita corromper _bunnyform_prev: se chamássemos ApplyFormEffects agora e
-- de novo depois, a segunda captura leria os valores DA FORMA como se fossem os normais,
-- e reverter deixaria a Wunny com dano/velocidade de coelho pra sempre. Aplicando uma
-- única vez, no fim de tudo, a captura pega os valores certos.
--------------------------------------------------------------------------------------
local function DoLoadRestore(inst)
	local formname = inst._bunnyform_pendingload
	inst._bunnyform_pendingload = nil

	if formname == nil or FORMS[formname] == nil or inst._bunnyform == nil then
		return
	end
	--Um save feito morto/fantasma não pode ressuscitar coelho. O OnBecameGhost já zera a
	--forma antes de salvar, então isto é só a rede de segurança pra save antigo.
	if inst:HasTag("playerghost")
		or (inst.components.health ~= nil and inst.components.health:IsDead()) then
		return
	end

	--CommitForm e não o estado bunnyform_transform: carregar não deve tocar a animação de
	--transformação nem tirar o controle do jogador. Ele acorda já sendo coelho.
	CommitForm(inst, formname)

	--O sg ficou parado num estado do bank "wilson"; sem isto a Wunny fica travada numa
	--animação que o bank do coelho não tem. Mesma linha do onpreload do woodie
	--(woodie.lua:1610).
	if inst.sg ~= nil then
		inst.sg:GoToState("idle")
	end
end

local function OnLoad(inst, data)
	--Desbloqueios primeiro, e filtrando pelo que ainda existe: uma forma retirada do mod
	--não pode continuar destravada, senão GetSelected a devolve e Transform falha em
	--silêncio toda vez que a tecla é apertada.
	if data ~= nil and data.bunnyform_unlocked ~= nil then
		inst._bunnyform_unlocked = {}
		for name, v in pairs(data.bunnyform_unlocked) do
			if v == true and FORMS[name] ~= nil then
				inst._bunnyform_unlocked[name] = true
			end
		end
		local sel = data.bunnyform_selected
		if sel ~= nil and inst._bunnyform_unlocked[sel] then
			inst._bunnyform_selected = sel
		end
	end

	local formname = data ~= nil and data.bunnyform or nil
	if formname == nil then
		return
	end
	if FORMS[formname] == nil then
		--Forma que saiu do mod numa atualização: acorda como Wunny normal, em vez de
		--travar numa forma que não existe mais.
		print("[wunny/bunnyform] forma salva desconhecida, ignorando:", tostring(formname))
		return
	end
	inst._bunnyform_pendingload = formname
	inst:DoTaskInTime(0, DoLoadRestore)
end

--------------------------------------------------------------------------------------
-- Setup.
--------------------------------------------------------------------------------------
local function SetupNetvars(inst)
	inst._bunnyform = net_tinybyte(inst.GUID, "wunny._bunnyform", "bunnyformdirty")
	inst:ListenForEvent("bunnyformdirty", OnBunnyFormDirty)

	--Equipar um chapéu JÁ estando na forma refaz o Hide("HEAD") do hats.lua, então
	--reaplicamos depois. Fora da forma não mexemos: o hats.lua já deixou certo, e chamar
	--onequipfn de novo aqui seria trabalho à toa.
	local function OnEquipChanged(i)
		if IsInForm(i) then
			RefreshHatSymbols(i)
		end
	end
	inst:ListenForEvent("equip", OnEquipChanged)
	inst:ListenForEvent("unequip", OnEquipChanged)

	inst.IsInBunnyForm = IsInForm
end

local function SetupServer(inst)
	inst.BunnyFormTransform = Transform
	inst.BunnyFormRevert = Revert
	inst.BunnyFormToggle = ToggleForm
	inst.BunnyFormAttune = AttuneAtHouse
	inst:ListenForEvent("ms_becameghost", OnBecameGhost)
	inst:ListenForEvent("death", OnBecameGhost)
end

--------------------------------------------------------------------------------------
-- Remendo do SGwilson.
--
-- ADITIVO de propósito: adiciona estados novos e REDIRECIONA os handlers, em vez de
-- reescrever corpo de estado vanilla (o estado "attack" sozinho tem ~200 linhas e é
-- reescrito a cada patch do jogo).
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Estados de fala e de ocioso. Usado nos DOIS stategraphs (servidor e cliente), porque
-- ambos têm "idle" e "closeinspect" e ambos tocam a animação por conta própria.
--------------------------------------------------------------------------------------
local function PatchTalkAndIdle(sg, is_client)
	--"talk": noanim=true pula o PlayAnimation e preserva som/timeout.
	local talk = sg.states["talk"]
	if talk ~= nil and talk.onenter ~= nil then
		local old_onenter = talk.onenter
		talk.onenter = function(inst, noanim)
			return old_onenter(inst, inst:HasTag("bunnyform") or noanim)
		end
	end

	--"closeinspect" toca "pig_king_appraise", que o bank não tem. Vira fala normal.
	local closeinspect = sg.states["closeinspect"]
	if closeinspect ~= nil and closeinspect.onenter ~= nil then
		local old_onenter = closeinspect.onenter
		closeinspect.onenter = function(inst, ...)
			if inst:HasTag("bunnyform") then
				inst.sg:GoToState("talk", true)
				return
			end
			return old_onenter(inst, ...)
		end
	end

	--"idle": o vanilla escolhe entre idle_sanity_loop / idle_shiver_loop / idle_hot_loop
	--/ sand_idle_loop / idle_groggy conforme sanidade, temperatura e clima, e depois
	--agenda um SetTimeout que leva a "funnyidle" (SGwilson.lua:4301). Nenhuma dessas
	--existe no bank manrabbit — era o sumiço depois de alguns segundos parada. O vanilla
	--resolve o mesmo problema para o beaver/moose/goose pela tag "wereplayer", que força
	--"idle_loop" e desliga o funnyidle; aqui fazemos o equivalente sem herdar os outros
	--32 comportamentos que aquela tag arrasta junto.
	local idle = sg.states["idle"]
	if idle ~= nil and idle.onenter ~= nil then
		local old_onenter = idle.onenter
		idle.onenter = function(inst, pushanim, ...)
			--No SGwilson_client, pushanim é uma STRING sentinela ("cancel"/"noanim") que
			--sinaliza interrupção/confirmação da predição e tem tratamento próprio
			--(SGwilson_client.lua:1093). Nesses casos nunca assumimos o controle.
			if type(pushanim) ~= "string"
				and inst:HasTag("bunnyform")
				and (inst.components.rider == nil or not inst.components.rider:IsRiding()) then
				if is_client then
					--O idle do cliente faz isso na primeira linha; sem ele a predição de
					--movimento fica ligada dentro do idle.
					inst.entity:SetIsPredictingMovement(false)
				end
				inst.components.locomotor:Stop()
				inst:ClearBufferedAction()
				if pushanim then
					inst.AnimState:PushAnimation("idle_loop", true)
				else
					inst.AnimState:PlayAnimation("idle_loop", true)
				end
				--sem SetTimeout: sem funnyidle.
				return
			end
			return old_onenter(inst, pushanim, ...)
		end
	end
end

--------------------------------------------------------------------------------------
-- Rede de segurança dos actionhandlers.
--
-- fallback = nome do estado destino na forma, ou nil para desligar a ação (usado no
-- stategraph de cliente, onde só queremos suprimir a predição).
--
-- Preserva o handler vanilla intacto fora da forma. Estados que começam com
-- "bunnyform_" passam direto: são nossos, e as animações deles existem no bank.
--------------------------------------------------------------------------------------
--A exceção. O salto de parede (scripts/wunny_jumpwall.lua) é o único estado de ação de
--fora desta família que roda igual na forma, porque as animações que ele toca —
--boat_jump_pre/loop/pst — são das poucas que existem NOS DOIS banks: em
--anim/player_boat_jump.zip para o wilson e em anim/manrabbit_boat_jump.zip para o
--manrabbit. Desviá-lo para "bunnyform_action" só trocaria um pulo funcionando por um
--"atk" no lugar.
--Soul hop (Wortox): TryToSoulhop (scripts/actions.lua) só completa a ação se
--inst.sg.currentstate.name for LITERALMENTE "portal_jumpin_pre" — é uma checagem de
--string dentro do vanilla, não dá pra satisfazer com um estado "bunnyform_*"
--equivalente. Por isso os três precisam passar direto em vez de cair no fallback
--"bunnyform_action"; a troca de animação pra algo que existe no bank manrabbit é
--feita à parte, em PatchSoulhop.
local SAFE_STATES_IN_FORM = {
	wunny_jumpwall = true,
	portal_jumpin_pre = true,
	portal_jumpin = true,
	portal_jumpout = true,
}

--Registra o actionhandler da ação de sintonizar. Vale para o SGwilson e para o
--SGwilson_client: os dois têm "dostandingaction", e sem o do cliente a predição local não
--acompanha (a ação até acontece, mas só depois do servidor responder).
local function AddAttuneActionHandler(sg)
	local act = ACTIONS.WUNNY_BUNNYFORM_ATTUNE
	--Guarda contra ordem de carregamento: se a ação ainda não existisse, indexar
	--sg.actionhandlers com nil estouraria aqui em vez de no lugar do erro real.
	if act ~= nil and sg.states["dostandingaction"] ~= nil then
		sg.actionhandlers[act] = ActionHandler(act, "dostandingaction")
	end
end

local function PatchAllActionHandlers(sg, fallback)
	for act, handler in pairs(sg.actionhandlers) do
		local old = handler
		sg.actionhandlers[act] = ActionHandler(act, function(inst, action)
			local dest = old.deststate ~= nil and old.deststate(inst, action) or nil
			if not inst:HasTag("bunnyform") then
				return dest
			end
			if dest == nil then
				--O vanilla já decidiu que esta ação não entra em estado nenhum;
				--respeitar isso evita inventar animação onde não havia.
				return nil
			end
			--O sg.states[dest] no whitelist não é redundante: este mesmo patch roda no
			--SGwilson_client, que não tem os estados do salto. Sem a checagem, bastaria
			--alguém registrar o handler no cliente para o destino apontar para um estado
			--inexistente.
			if type(dest) == "string"
				and (dest:sub(1, 10) == "bunnyform_"
					or (SAFE_STATES_IN_FORM[dest] and sg.states[dest] ~= nil)) then
				return dest
			end
			return fallback
		end)
	end

	--Ações longas demais para virar um PerformBufferedAction único: pescar e remar têm
	--loop e transições próprias, e sairiam pior redirecionadas do que desligadas.
	for _, actname in ipairs(BLOCKED_ACTION_NAMES) do
		local act = ACTIONS[actname]
		if act ~= nil then
			local old = sg.actionhandlers[act]
			sg.actionhandlers[act] = ActionHandler(act, function(inst, action)
				if inst:HasTag("bunnyform") then
					return nil
				end
				return old ~= nil and old.deststate(inst, action) or nil
			end)
		end
	end
end

--------------------------------------------------------------------------------------
local function PatchEquipEvents(sg)
	for _, evname in ipairs({ "equip", "unequip" }) do
		local old = sg.events[evname]
		if old ~= nil then
			sg.events[evname] = EventHandler(evname, function(inst, data)
				if inst:HasTag("bunnyform") then
					return
				end
				return old.fn(inst, data)
			end)
		end
	end
end

--"portal_jumpin_pre" toca "wortox_portal_jumpin_pre" e só sai do estado quando o
--evento "animover" dispara com AnimDone() == true (SGwilson.lua:20669+). Essa anim não
--existe no bank manrabbit: o jogador some da tela (mesmo bug do comentário de
--BLOCKED_ACTION_NAMES acima) e, pior, se "animover" nunca disparar pra uma animação
--inexistente, o estado fica preso em "busy" pra sempre. Trocamos só a chamada de
--PlayAnimation por "atk" — a única anim de ação que o bank tem — mantendo o resto do
--estado (o ForceFacePoint e o evento animover) intacto, então o teleporte em si
--continua idêntico ao vanilla.
--
--"portal_jumpin"/"portal_jumpout" têm o mesmo problema de anim ausente, mas saem do
--estado por SetTimeout, não por animover: sem susbtituir a animação, o jogador fica
--invisível por ~0.4s/0.56s mas o teleporte, a invencibilidade e os FX continuam
--funcionando — não fizemos a troca aqui pra não duplicar toda aquela lógica (tints,
--skilltree, física) só por causa de um sumiço cosmético e breve.
local function PatchSoulhop(sg)
	local portal_jumpin_pre = sg.states["portal_jumpin_pre"]
	if portal_jumpin_pre ~= nil and portal_jumpin_pre.onenter ~= nil then
		local old_onenter = portal_jumpin_pre.onenter
		portal_jumpin_pre.onenter = function(inst)
			if inst:HasTag("bunnyform") then
				inst.components.locomotor:Stop()
				inst.AnimState:PlayAnimation("atk")
				local buffaction = inst:GetBufferedAction()
				if buffaction ~= nil and buffaction.pos ~= nil then
					inst:ForceFacePoint(buffaction:GetActionPoint():Get())
				end
				return
			end
			return old_onenter(inst)
		end
	end
end

local function PatchStategraph(sg)
	------------------------------------------------------------------
	-- Estados novos
	------------------------------------------------------------------
	--------------------------------------------------------------------------------
	-- Transformação em DUAS FASES, copiando transform_beaver_person /
	-- transform_werebeaver do SGwilson.lua (2887 e 2944).
	--
	-- A troca de bank acontece NO MEIO do estado, entre as duas animações, e não
	-- antes dele. É obrigatório ser assim: cada metade da animação só existe em UM
	-- dos dois banks.
	--   ida:   "transform_pre"    (bank wilson)   -> troca -> "trans_rabbit_pst" (manrabbit)
	--   volta: "trans_beard_pre"  (bank manrabbit)-> troca -> "transform_pst"    (wilson)
	--
	-- transform_pre/transform_pst são animações do bank "wilson", mas empacotadas em
	-- anim/player_woodie.zip (não nas anims compartilhadas do jogador) — por isso esse
	-- zip entra nos Assets de wunny.lua.
	--
	-- O par SetTimeout/ontimeout é a GUARDA ANTI-TRAVAMENTO, não enfeite: se a
	-- animação não completar, o estado volta pro idle em vez de deixar o jogador preso
	-- em "busy" pra sempre. O vanilla faz igual.
	--------------------------------------------------------------------------------
	sg.states["bunnyform_transform"] = State{
		name = "bunnyform_transform",
		tags = { "busy", "pausepredict", "nomorph", "transform" },

		onenter = function(inst, formname)
			inst.Physics:Stop()
			inst:SetCameraDistance(14)
			inst.sg.statemem.form = formname
			--fase 1: ainda no bank "wilson"
			inst.AnimState:PlayAnimation("transform_pre")
			inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/death_voice", nil, .5)
			if inst.components.playercontroller ~= nil then
				inst.components.playercontroller:RemotePausePrediction()
				inst.components.playercontroller:Enable(false)
				inst.components.playercontroller:EnableMapControls(false)
			end
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + 23 * FRAMES)
		end,

		events = {
			EventHandler("animover", function(inst)
				if not inst.AnimState:AnimDone() then
					return
				end
				if inst.sg.statemem.form ~= nil then
					--fase 2: troca de bank e toca a anim do bank NOVO
					CommitForm(inst, inst.sg.statemem.form)
					inst.sg.statemem.form = nil
					inst.AnimState:PlayAnimation("trans_rabbit_pst")
					SpawnPrefab("werebeaver_transform_fx").Transform:SetPosition(
						inst.Transform:GetWorldPosition())
					inst:SetCameraDistance()
					inst.sg:RemoveStateTag("transform")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},

		ontimeout = function(inst)
			if not inst.sg:HasStateTag("transform") then
				inst.sg:GoToState("idle", true)
			end
		end,

		onexit = function(inst)
			if inst.sg:HasStateTag("transform") then
				--interrompido antes da fase 2 (congelado, morto, empurrado...): comita a
				--forma de qualquer jeito, senão a Wunny fica com o corpo antigo e sem os
				--stats, num meio-estado que nada mais desfaz.
				inst:SetCameraDistance()
				if inst.sg.statemem.form ~= nil then
					CommitForm(inst, inst.sg.statemem.form)
				end
			end
			if inst.components.playercontroller ~= nil then
				inst.components.playercontroller:EnableMapControls(true)
				inst.components.playercontroller:Enable(true)
			end
		end,
	}

	sg.states["bunnyform_untransform"] = State{
		name = "bunnyform_untransform",
		tags = { "busy", "pausepredict", "nomorph", "transform" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst:SetCameraDistance(14)
			inst.sg.statemem.reverting = true
			--fase 1: ainda no bank "manrabbit"
			inst.AnimState:PlayAnimation("trans_beard_pre")
			if inst.components.playercontroller ~= nil then
				inst.components.playercontroller:RemotePausePrediction()
				inst.components.playercontroller:Enable(false)
				inst.components.playercontroller:EnableMapControls(false)
			end
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + 23 * FRAMES)
		end,

		events = {
			EventHandler("animover", function(inst)
				if not inst.AnimState:AnimDone() then
					return
				end
				if inst.sg.statemem.reverting then
					--fase 2: de volta pro bank "wilson"
					CommitRevert(inst)
					inst.sg.statemem.reverting = nil
					inst.AnimState:PlayAnimation("transform_pst")
					SpawnPrefab("werebeaver_transform_fx").Transform:SetPosition(
						inst.Transform:GetWorldPosition())
					inst:SetCameraDistance()
					inst.sg:RemoveStateTag("transform")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},

		ontimeout = function(inst)
			if not inst.sg:HasStateTag("transform") then
				inst.sg:GoToState("idle", true)
			end
		end,

		onexit = function(inst)
			if inst.sg:HasStateTag("transform") then
				--mesmo cuidado da ida: interrompido no meio, desfaz de qualquer jeito.
				inst:SetCameraDistance()
				if inst.sg.statemem.reverting then
					CommitRevert(inst)
				end
			end
			if inst.components.playercontroller ~= nil then
				inst.components.playercontroller:EnableMapControls(true)
				inst.components.playercontroller:Enable(true)
			end
		end,
	}

	--Ataque próprio da forma: o bank tem "atk" (soco) e "atk_object" (com objeto na
	--mão), mas não os atk_pre/punch/spearjab_pre que o estado "attack" do wilson usa.
	sg.states["bunnyform_attack"] = State{
		name = "bunnyform_attack",
		tags = { "attack", "notalking", "abouttoattack", "busy" },

		onenter = function(inst)
			local target = inst.components.combat.target
			if inst.components.combat:InCooldown() then
				inst.sg:RemoveStateTag("abouttoattack")
				inst:ClearBufferedAction()
				inst.sg:GoToState("idle", true)
				return
			end
			inst.components.combat:SetTarget(target)
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()

			local weapon = inst.components.combat:GetWeapon()
			inst.AnimState:PlayAnimation(weapon ~= nil and "atk_object" or "atk")
			inst.sg.statemem.target = target

			--ACELERAÇÃO DO ATAQUE (mesmo par de alavancas do salto, wunny_jumpwall.lua:291):
			--SetDeltaTimeMultiplier acelera a IMAGEM, SetTimeout acelera a LÓGICA. Os dois
			--têm de andar juntos, senão o golpe sai fora de sincronia com a animação.
			--
			--O golpe é dado no ontimeout, não num TimeEvent: TimeEvent é fixado quando o
			--estado é DEFINIDO, e a taxa depende do tier, que só se sabe aqui dentro.
			local form = GetForm(inst)
			local rate = form ~= nil and form.attackrate or 1
			inst.AnimState:SetDeltaTimeMultiplier(rate)
			inst.sg:SetTimeout(13 * FRAMES / rate)
		end,

		ontimeout = function(inst)
			inst:PerformBufferedAction()
			inst.sg:RemoveStateTag("abouttoattack")
		end,

		events = {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.AnimState:SetDeltaTimeMultiplier(1)
			inst.components.combat:SetTarget(nil)
			inst.sg:RemoveStateTag("abouttoattack")
		end,
	}

	--Comer: o bank tem "eat" mas não "eat_pre".
	sg.states["bunnyform_eat"] = State{
		name = "bunnyform_eat",
		tags = { "busy", "nodangle" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("eat")
		end,

		timeline = {
			TimeEvent(12 * FRAMES, function(inst)
				inst:PerformBufferedAction()
			end),
		},

		events = {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	}

	--Ação genérica: toca "atk" (sem nada de combate) e executa a ação bufferizada.
	--É o destino de tudo que não tem animação própria no bank.
	sg.states["bunnyform_action"] = State{
		name = "bunnyform_action",
		tags = { "doing", "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation(
				inst.components.combat:GetWeapon() ~= nil and "atk_object" or "atk")
		end,

		timeline = {
			TimeEvent(10 * FRAMES, function(inst)
				inst:PerformBufferedAction()
			end),
		},

		events = {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			--Se o estado for interrompido antes do timeline, a ação não fica pendurada.
			inst:ClearBufferedAction()
		end,
	}

	------------------------------------------------------------------
	-- Redirecionamento dos handlers
	------------------------------------------------------------------
	local old_doattack = sg.events["doattack"]
	sg.events["doattack"] = EventHandler("doattack", function(inst, data)
		if inst:HasTag("bunnyform") then
			if not inst.components.health:IsDead()
				and not inst.sg:HasStateTag("attack")
				and not inst.sg:HasStateTag("busy") then
				inst.sg:GoToState("bunnyform_attack", data)
			end
			return
		end
		return old_doattack.fn(inst, data)
	end)

	--Falar (examinar cai aqui): o estado "talk" toca "dial_loop", ausente no bank
	--manrabbit. O próprio estado já aceita um parâmetro noanim (SGwilson.lua:7514) que
	--pula a animação e mantém som e timeout — então basta forçá-lo na forma.
	PatchTalkAndIdle(sg)

	for _, actname in ipairs({ "EAT", "TAKEITEM" }) do
		local act = ACTIONS[actname]
		if act ~= nil and actname == "EAT" then
			local old = sg.actionhandlers[act]
			sg.actionhandlers[act] = ActionHandler(act, function(inst, action)
				if inst:HasTag("bunnyform") then
					return "bunnyform_eat"
				end
				return old ~= nil and old.deststate(inst, action) or nil
			end)
		end
	end

	--Equipar/desequipar: os handlers globais mandam pra "item_out"/"item_hat"
	--(SGwilson.lua:2016 e 2047), animações que o bank não tem. O próprio vanilla já
	--pula esse trecho para formas alternativas, testando not inst:HasTag("wereplayer")
	--na linha 2035 — fazemos o mesmo teste com a nossa tag. Trocar de item na forma
	--simplesmente não tem animação de troca, o que é o comportamento certo.
	PatchEquipEvents(sg)
	PatchSoulhop(sg)

	--Rede de segurança geral. Em vez de listar quais ações não têm animação — o que já
	--falhou três vezes, sempre sobrando uma (TOSS, os emotes, ações de outros mods) —
	--invertemos: NENHUM estado vanilla é seguro na forma, porque o bank manrabbit tem
	--~50 animações contra as centenas que o SGwilson usa. Então tudo que não for um
	--WUNNY_BUNNYFORM_ATTUNE é uma ação NOSSA: nenhum stategraph vanilla tem actionhandler
	--pra ela, e sem handler o stategraph descarta a ação bufferizada em silêncio — o verbo
	--"Sintonizar" aparece, clicar não faz nada e ACTIONS.WUNNY_BUNNYFORM_ATTUNE.fn nunca
	--roda (nenhum print sai; foi assim que o sintonizar pareceu "não existir"). Compare com
	--o salto, que só funciona porque wunny_jumpwall.lua:429 registra o dele.
	--
	--"dostandingaction" (SGwilson.lua:7838) é o estado curto que só faz
	--PerformBufferedAction. O registro vem ANTES do PatchAllActionHandlers de propósito:
	--assim ele também é embrulhado e, na forma, o destino vira "bunnyform_action" sozinho,
	--sem precisar de um if aqui.
	AddAttuneActionHandler(sg)

	--estado nosso vai pro "bunnyform_action", que toca "atk" e executa a ação.
	PatchAllActionHandlers(sg, "bunnyform_action")
end

--------------------------------------------------------------------------------------
-- SGwilson_client: a predição local do jogador toca as animações por conta própria,
-- antes de o servidor responder. Sem este patch, quem joga como cliente (ou o host com
-- predição ligada) vê o "pickup"/"dolongaction" localmente e some da tela mesmo com o
-- stategraph do servidor certo.
--
-- Aqui não recriamos estados: devolver nil só desliga a predição daquela ação. O
-- servidor continua executando normalmente, a ação acontece, apenas sem antecipação
-- visual — que é exatamente o que queremos, já que a animação prevista não existe.
--------------------------------------------------------------------------------------
local function PatchClientStategraph(sg)
	AddAttuneActionHandler(sg)
	--fallback nil: nenhuma predição. O servidor decide e a animação vem de lá.
	PatchAllActionHandlers(sg, nil)
	PatchEquipEvents(sg)
	PatchTalkAndIdle(sg, true)
end

return {
	FORMS           = FORMS,
	FORM_ORDER      = FORM_ORDER,
	HOUSE_TO_FORM   = HOUSE_TO_FORM,
	AttuneAtHouse   = AttuneAtHouse,
	ToggleForm      = ToggleForm,
	IsUnlocked      = IsUnlocked,
	GetSelected     = GetSelected,
	SetupNetvars    = SetupNetvars,
	SetupServer     = SetupServer,
	PatchStategraph = PatchStategraph,
	PatchClientStategraph = PatchClientStategraph,
	Transform       = Transform,
	Revert          = Revert,
	IsInForm        = IsInForm,
	OnSave          = OnSave,
	OnLoad          = OnLoad,
}
