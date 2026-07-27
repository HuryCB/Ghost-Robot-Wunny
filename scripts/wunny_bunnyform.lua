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
	ESTADO DESTE ARQUIVO: PILOTO
	--------------------------------------------------------------------------------
	Só a forma base ("bunnyman", build manrabbit_build). As outras seis variantes do
	mod entram como novas entradas em FORMS — a arquitetura já é por tabela. Note que
	existem só 4 builds distintos (manrabbit_build, daymanrabbit_build,
	everythingmanrabbit_build, shadowmanrabbit_build), então base/new/dwarf/ultra
	precisarão de escala/cor pra não ficarem visualmente idênticas.
]]

local FORMS = {
	bunnyman = {
		--visual
		bank = "manrabbit",
		build = "manrabbit_build",
		skinmode = "bunnyman_skin",
		shadow = { 1.5, .75 },

		--combate/movimento: valores do bunnyman base (tuning.lua:2362+ e
		--scripts/prefabs/bunnyman.lua:441-447)
		damage = TUNING.BUNNYMAN_DAMAGE,
		attackperiod = TUNING.BUNNYMAN_ATTACK_PERIOD,
		runspeed = TUNING.BUNNYMAN_RUN_SPEED,
		walkspeed = TUNING.BUNNYMAN_WALK_SPEED,

		--NÃO mexemos em health:SetMaxHealth: o bunnyman tem 200 de vida, mas
		--reescrever o máximo do jogador destruiria a pool dele na volta. O ganho de
		--resistência vem por absorção, que é o que o woodie.lua faz no beaver
		--(health:SetAbsorptionAmount).
		absorption = 0.2,
	},
}

--A ordem define o índice do netvar (0 = forma nenhuma). Ao adicionar forma nova,
--acrescente NO FIM: mudar a ordem invalida saves em andamento.
local FORM_ORDER = { "bunnyman" }

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
			if type(dest) == "string" and dest:sub(1, 10) == "bunnyform_" then
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
		end,

		timeline = {
			TimeEvent(13 * FRAMES, function(inst)
				inst:PerformBufferedAction()
				inst.sg:RemoveStateTag("abouttoattack")
			end),
		},

		ontimeout = function(inst)
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

	--Rede de segurança geral. Em vez de listar quais ações não têm animação — o que já
	--falhou três vezes, sempre sobrando uma (TOSS, os emotes, ações de outros mods) —
	--invertemos: NENHUM estado vanilla é seguro na forma, porque o bank manrabbit tem
	--~50 animações contra as centenas que o SGwilson usa. Então tudo que não for um
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
	--fallback nil: nenhuma predição. O servidor decide e a animação vem de lá.
	PatchAllActionHandlers(sg, nil)
	PatchEquipEvents(sg)
	PatchTalkAndIdle(sg, true)
end

return {
	FORMS           = FORMS,
	FORM_ORDER      = FORM_ORDER,
	SetupNetvars    = SetupNetvars,
	SetupServer     = SetupServer,
	PatchStategraph = PatchStategraph,
	PatchClientStategraph = PatchClientStategraph,
	Transform       = Transform,
	Revert          = Revert,
	IsInForm        = IsInForm,
}
