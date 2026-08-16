--[[
	Salto de parede da Wunny — a parte de stategraph.

	POR QUE ISTO É UM ARQUIVO SEPARADO: mesma razão de wunny_bunnyform.lua e
	wunny_wormwood_bloom.lua — tanto o chunk de prefabs/wunny.lua quanto o de
	modmain.lua estão perto do limite rígido do Lua 5.1 de 200 variáveis locais por
	chunk/função, e este recurso precisa de um punhado de helpers.

	A definição da AÇÃO (Action, AddComponentAction, ACTIONS.WUNNY_JUMPWALL.fn) continua
	em modmain.lua; aqui ficam a geometria e os estados. modmain chama GetLanding para
	validar antes de bufferizar, e o estado chama de novo no onenter — a validação é a
	mesma função nas duas pontas de propósito, porque entre o clique e o começo do estado
	a parede pode ter sido destruída.

	--------------------------------------------------------------------------------
	POR QUE boat_jump E NÃO UM Teleport
	--------------------------------------------------------------------------------
	A versão anterior fazia Physics:Teleport direto no ACTIONS.fn: a Wunny simplesmente
	reaparecia do outro lado, sem animação nenhuma. Aqui o deslocamento acontece com
	SetMotorVel ao longo da animação, o que é o que dá a leitura de "pulo".

	As animações são boat_jump_pre / boat_jump_loop / boat_jump_pst, as mesmas do salto
	entre barcos (hop_anims em SGwilson.lua:28528). Elas servem por um motivo concreto,
	não por parecer: existem NOS DOIS banks que a Wunny usa —
	  bank "wilson":   anim/player_boat_jump.zip, pré-carregado para todo jogador
	                   (player_common.lua:2023), então não precisa entrar em Assets.
	  bank "manrabbit": anim/manrabbit_boat_jump.zip, já nos Assets de wunny.lua:53.
	É por isso que este é o único estado de ação do mod que roda igual dentro e fora da
	forma bunnyman, em vez de ser desviado para "bunnyform_action" — veja a nota em
	PatchAllActionHandlers (wunny_bunnyform.lua).

	--------------------------------------------------------------------------------
	COMO A PAREDE DEIXA DE BARRAR
	--------------------------------------------------------------------------------
	Trocar a máscara de colisão para COLLISION.GROUND durante o voo, restaurando no
	onexit. Não é invenção: é exatamente o que o hop_loop do vanilla faz para atravessar
	a água entre dois barcos (commonstates.lua:871 e 899).

	O par SetTimeout/ontimeout e o ClearBufferedAction no onexit são a GUARDA
	ANTI-TRAVAMENTO. Sem eles, um voo interrompido deixa o jogador em "busy" para sempre
	— o mesmo cuidado que os estados de transformação já tomam.
]]

--Distância a partir do CENTRO da parede até onde a Wunny pousa. Paredes têm raio de
--física .5 (MakeObstaclePhysics(inst, .5) em walls.lua:276), então o padrão de 1.3 põe
--o pouso .8 além da superfície.
local LANDING_DIST = TUNING.WUNNY_JUMPWALL_LANDING_DIST or 1.3

--Velocidade do voo, em unidades/segundo. O tempo no ar sai de distância/velocidade, com
--um piso para o salto não ficar mais curto que a animação.
--Note que ele é multiplicado pelo RATE abaixo: assim o RATE é o ÚNICO botão de "quão
--rápido é o salto", em vez de a aceleração ficar metade aqui e metade lá.
local JUMP_SPEED_BASE = TUNING.WUNNY_JUMPWALL_SPEED or 7

--Aceleração global do salto. Mexer só no JUMP_SPEED_BASE NÃO deixa o salto mais rápido de
--verdade: o voo em si já era a menor parte da duração. O que domina são o agachamento
--(LIFTOFF), o piso de tempo no ar (MIN_FLIGHT) e a animação de pouso (boat_jump_pst,
--que roda inteira antes de devolver o controle). Por isso este fator entra em QUATRO
--lugares — os três tempos abaixo e o SetDeltaTimeMultiplier das animações. Sem o
--multiplicador de animação os tempos encurtariam mas a arte continuaria no ritmo antigo,
--e o pouso ficaria cortado no meio.
local RATE = TUNING.WUNNY_JUMP_RATE or 1.5

local JUMP_SPEED = JUMP_SPEED_BASE * RATE

--A animação agacha antes de sair do chão; largar o movimento no frame 0 faz a Wunny
--deslizar durante o agachamento. O vanilla usa o mesmo atraso de 4 frames
--(start_embarking_pre_frame em SGwilson.lua:28557).
local LIFTOFF = 4 * FRAMES / RATE
local MIN_FLIGHT = 8 * FRAMES / RATE

--Salto livre (tecla de atalho): distância à frente, sem parede nenhuma envolvida.
local FREE_DIST = TUNING.WUNNY_JUMPFREE_DIST or 4.5
--Se o ponto cheio não serve (água, buraco, coisa no caminho), encurta o salto neste passo
--em vez de simplesmente cancelar. É o que faz a tecla responder perto de obstáculos em
--vez de parecer engasgada.
local FREE_STEP = .5

--Raio de busca por obstáculo no ponto de pouso. Um pouco maior que o raio de física do
--jogador (.5), para não pousar encostado.
local LANDING_CLEARANCE = .7

local BLOCKER_ONEOF_TAGS = { "wall", "blocker" }
local BLOCKER_CANT_TAGS = { "INLIMBO", "FX", "DECOR", "player" }

--------------------------------------------------------------------------------------
-- O ponto de pouso serve? Chão pisável e sem obstáculo em cima.
--
-- Extraído de GetLanding para o salto livre usar o MESMO critério: se os dois
-- divergissem, dá para acabar com uma tecla que atravessa parede em situação em que o
-- clique na parede se recusa a saltar.
--------------------------------------------------------------------------------------
local function IsLandingClear(landx, landz, ignore1, ignore2)
	if not TheWorld.Map:IsPassableAtPoint(landx, 0, landz, false) then
		return false
	end

	local blockers = TheSim:FindEntities(landx, 0, landz, LANDING_CLEARANCE,
		nil, BLOCKER_CANT_TAGS, BLOCKER_ONEOF_TAGS)
	for _, v in ipairs(blockers) do
		if v ~= ignore1 and v ~= ignore2 then
			return false
		end
	end

	return true
end

--------------------------------------------------------------------------------------
-- Geometria. Devolve landx, landz, ou nil se o salto não é possível.
--
-- A direção sai de doer -> parede e é projetada ADIANTE do centro da parede, e não de
-- normal de parede: o jogador salta na linha em que já está olhando, que é o que a mão
-- espera ao clicar.
--------------------------------------------------------------------------------------
local function GetLanding(doer, wall)
	if doer == nil or wall == nil or not wall:IsValid() then
		return nil
	end

	local dx, dy, dz = doer.Transform:GetWorldPosition()
	local wx, wy, wz = wall.Transform:GetWorldPosition()

	local dirx, dirz = wx - dx, wz - dz
	local len = math.sqrt(dirx * dirx + dirz * dirz)
	if len < .001 then
		--Em cima da parede: não há direção para saltar.
		return nil
	end
	dirx, dirz = dirx / len, dirz / len

	local landx = wx + dirx * LANDING_DIST
	local landz = wz + dirz * LANDING_DIST

	--Paredes se constroem em grade de 1 unidade, então numa parede DUPLA o pouso a 1.3
	--do centro da primeira cai dentro da segunda. Com o Teleport antigo isso já prendia
	--a Wunny; agora prenderia no momento em que a colisão voltasse. Barrar o salto é o
	--comportamento certo: parede grossa continua sendo parede.
	if not IsLandingClear(landx, landz, wall, doer) then
		return nil
	end

	return landx, landz
end

--------------------------------------------------------------------------------------
-- Geometria do SALTO LIVRE. Sem alvo: a direção é simplesmente para onde a Wunny está
-- virada, e a distância é fixa.
--
-- Diferente do salto de parede, aqui o ponto cheio falhando não cancela: encurta e tenta
-- de novo. O salto de parede tem um destino único e correto (o outro lado); o livre é um
-- deslocamento, e um deslocamento menor continua sendo uma resposta útil à tecla.
--
-- Só o DESTINO é validado, nunca o meio do caminho. Isso é intencional e é o que torna a
-- tecla capaz de pular por cima de água, buraco de riftlands ou parede — durante o voo a
-- máscara de colisão já é só COLLISION.GROUND, então não há nada para atravessar.
--------------------------------------------------------------------------------------
local function GetFreeLanding(doer)
	if doer == nil or not doer:IsValid() then
		return nil
	end

	local x, y, z = doer.Transform:GetWorldPosition()
	--Convenção do DST: a rotação do Transform é em graus e o eixo z é invertido em
	--relação ao seno (mesma conta de GetHopDistanceAndVel em SGwilson).
	local rot = doer.Transform:GetRotation() * DEGREES
	local dirx, dirz = math.cos(rot), -math.sin(rot)

	local dist = FREE_DIST
	while dist >= FREE_STEP do
		local landx, landz = x + dirx * dist, z + dirz * dist
		if IsLandingClear(landx, landz, doer, nil) then
			return landx, landz
		end
		dist = dist - FREE_STEP
	end

	return nil
end

--------------------------------------------------------------------------------------
-- Pode saltar livre AGORA? Roda no servidor, em cima do RPC — o cliente não é
-- autoridade nenhuma aqui.
--
-- As restrições de mãos ocupadas / montaria são as MESMAS do salto de parede, e pela
-- mesma razão de animação (ver o comentário de WunnyCanJumpWall em modmain.lua). A
-- diferença é que lá a checagem usa os replicas (código de cliente, para montar o menu
-- do clique direito) e aqui usa os componentes de verdade.
--------------------------------------------------------------------------------------
local function CanFreeJump(inst)
	if inst == nil or not inst:IsValid()
		or not inst:HasTag("wunny")
		or inst:HasTag("playerghost")
		or inst.sg == nil then
		return false
	end

	--"busy" cobre de uma vez ataque em curso, comer, construir, congelado, preso em teia,
	--nocauteado e o próprio salto — inclusive impede que a tecla martelada reinicie o voo
	--no meio dele. É também o motivo de NÃO haver cooldown próprio: a duração do estado
	--já é o limite natural de cadência.
	if inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("nopredict") then
		return false
	end

	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return false
	end

	local inv = inst.components.inventory
	if inv ~= nil and inv:IsHeavyLifting() then
		return false
	end

	local rider = inst.components.rider
	if rider ~= nil and rider:IsRiding() then
		return false
	end

	return true
end

--------------------------------------------------------------------------------------
local function TryFreeJump(inst)
	if not CanFreeJump(inst) then
		return false
	end

	local landx, landz = GetFreeLanding(inst)
	if landx == nil then
		return false
	end

	--O salto livre não executa ação nenhuma ao pousar, então uma ação bufferizada
	--pendente (um clique dado no mesmo instante) tem que sair da frente aqui, senão ela
	--dispararia sozinha ao fim do voo, longe do alvo original.
	inst:ClearBufferedAction()
	inst.sg:GoToState("wunny_jumpwall", { x = landx, z = landz })
	return true
end

--------------------------------------------------------------------------------------
local function PatchStategraph(sg)
	sg.states["wunny_jumpwall"] = State{
		name = "wunny_jumpwall",
		--"nointerrupt": no ar, a Wunny está com a colisão desligada e por cima de um
		--obstáculo. Deixar outro estado assumir no meio é o que produz jogador preso
		--dentro da parede.
		--
		--"pausepredict" + RemotePausePrediction: este estado existe só no SGwilson
		--(servidor). O cliente não tem estado equivalente, então se ele continuasse
		--prevendo ficaria preso na parede localmente e a posição divergiria até o servidor
		--corrigir num salto. É o mesmo par que os estados de transformação deste mod usam.
		--
		--"nopredict" resolve um problema DIFERENTE, e é ele que impede a Wunny de voltar
		--andando sozinha para o ponto de onde saltou. Num servidor dedicado o cliente manda
		--de tempos em tempos a POSIÇÃO que ele prevê ocupar (RPC.PredictWalking) e o
		--servidor a guarda em playercontroller.remote_vector. Enquanto o estado é "busy" o
		--servidor chama só ClearRemotePredictData (playercontroller.lua:3043), que NÃO mexe
		--nesse remote_vector — a última posição mandada antes do salto sobrevive ao voo
		--inteiro. No primeiro frame em que o estado deixa de ser "busy", DoPredictWalking
		--faz locomotor:RunInDirection() em direção a ela (playercontroller.lua:4036) e a
		--Wunny anda de volta. Como este estado TELEPORTA, aquela posição é lixo por
		--definição.
		--"nopredict" é exatamente o sinal de "descarte o que o cliente disse": com ele
		--presente, playercontroller.lua:3005 zera o remote_vector a cada tick do voo. É o
		--que todo estado vanilla que teleporta o jogador usa (death_vinesave_pst em
		--SGwilson.lua:3957, afogamento e queda em commonstates.lua).
		--Os dois convivem: nenhum é lido no lugar do outro (builder.lua:630 e
		--woby_rack.lua:78 checam os dois lado a lado).
		tags = { "busy", "nointerrupt", "pausepredict", "nopredict", "nomorph", "nosleep", "jumping" },

		--dest ~= nil => SALTO LIVRE (tecla), destino já calculado e validado por
		--TryFreeJump. dest == nil => salto de parede, destino vem da ação bufferizada.
		--O estado é um só de propósito: o voo, o desligamento de colisão, o Teleport de
		--correção e as guardas anti-travamento são idênticos nos dois casos, e a única
		--diferença real (executar ou não a ação no pouso) cabe num if.
		onenter = function(inst, dest)
			inst.components.locomotor:Stop()
			if inst.components.playercontroller ~= nil then
				inst.components.playercontroller:RemotePausePrediction()
			end

			local landx, landz
			if dest ~= nil then
				inst.sg.statemem.free = true
				landx, landz = dest.x, dest.z
			else
				local act = inst:GetBufferedAction()
				landx, landz = GetLanding(inst, act ~= nil and act.target or nil)
			end

			if landx == nil then
				--A parede caiu, ou o outro lado deixou de ser válido, entre o clique e
				--aqui. Nada de animação: só devolve o controle.
				inst:ClearBufferedAction()
				inst.sg:GoToState("idle")
				return
			end

			inst.sg.statemem.landx = landx
			inst.sg.statemem.landz = landz
			inst:ForceFacePoint(landx, 0, landz)

			--Os tempos deste estado já estão divididos por RATE; sem isto a arte ficaria
			--no ritmo antigo e o voo terminaria antes do agachamento acabar de tocar.
			inst.AnimState:SetDeltaTimeMultiplier(RATE)
			inst.AnimState:PlayAnimation("boat_jump_pre")
			--Em loop: quem termina o voo é o ontimeout, calculado pela distância. Assim a
			--duração da animação e a do deslocamento não precisam bater.
			inst.AnimState:PushAnimation("boat_jump_loop", true)

			local x, y, z = inst.Transform:GetWorldPosition()
			local ddx, ddz = landx - x, landz - z
			local dist = math.sqrt(ddx * ddx + ddz * ddz)
			local flight = math.max(MIN_FLIGHT, dist / JUMP_SPEED)

			inst.sg.statemem.speed = dist / flight
			inst.sg:SetTimeout(LIFTOFF + flight)
		end,

		timeline = {
			TimeEvent(LIFTOFF, function(inst)
				if inst.sg.statemem.landx == nil then
					return
				end
				--Só o chão: é isto que faz a parede deixar de existir para a física
				--durante o voo (commonstates.lua:871).
				inst.sg.statemem.collisionmask = inst.Physics:GetCollisionMask()
				inst.Physics:SetCollisionMask(COLLISION.GROUND)
				--SetMotorVel anda na direção que o Transform está olhando, e o onenter já
				--apontou para o ponto de pouso.
				inst.Physics:SetMotorVel(inst.sg.statemem.speed, 0, 0)
			end),
		},

		ontimeout = function(inst)
			inst.Physics:Stop()
			--O Teleport corrige a deriva: integrar SetMotorVel por N frames não cai
			--exatamente no ponto calculado, e errar para trás deixaria a Wunny em cima da
			--parede quando a colisão voltasse.
			inst.Physics:Teleport(inst.sg.statemem.landx, 0, inst.sg.statemem.landz)
			if not inst.sg.statemem.free then
				inst:PerformBufferedAction()
			end
			inst.sg.statemem.landed = true
			--A tag "jumping" faz o SGwilson ADIAR em vez de interromper: "knockedout"
			--(SGwilson.lua:2245) e a sobrecarga de almas (1965) guardam o destino em
			--queued_post_land_state em vez de trocar de estado no ar. Quem tem essa tag
			--tem que consumir isso no pouso, senão um dardo sonífero acertado no meio do
			--salto simplesmente não faz nada.
			inst.sg:GoToState("wunny_jumpwall_pst", inst.sg.statemem.queued_post_land_state)
		end,

		onexit = function(inst)
			inst.Physics:Stop()
			--Sempre, inclusive na saída antecipada em que nem PlayAnimation aconteceu:
			--deixar o multiplicador em RATE contaminaria TODA animação seguinte do
			--jogador. O onenter do _pst reaplica logo em seguida (o onexit do estado
			--antigo roda antes do onenter do novo).
			inst.AnimState:SetDeltaTimeMultiplier(1)
			if inst.sg.statemem.collisionmask ~= nil then
				inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
				if not inst.sg.statemem.landed and inst.sg.statemem.landx ~= nil then
					--Voo interrompido apesar do "nointerrupt" (morte, congelamento, um
					--knockback de outro mod). A colisão está voltando agora; parar onde
					--estava prenderia a Wunny dentro da parede, e o ponto de pouso já foi
					--validado como passável.
					inst.Physics:Teleport(inst.sg.statemem.landx, 0, inst.sg.statemem.landz)
				end
			end
			if not inst.sg.statemem.landed then
				inst:ClearBufferedAction()
			end
		end,
	}

	sg.states["wunny_jumpwall_pst"] = State{
		name = "wunny_jumpwall_pst",
		--SEM "busy", e com "autopredict". Era o "busy" o verdadeiro custo de "voltar a
		--andar depois do pulo": o locomote do jogador é DESCARTADO enquanto ele está
		--presente (SGwilson.lua:1751 sai na hora, e PlayerController:CanLocomote também
		--barra no cliente), então quem estava com a direção segurada ficava parado a
		--animação de pouso inteira e só então começava o run_start.
		--
		--Acelerar a animação não resolvia isso: encurtava a espera, não a eliminava.
		--
		--"autopredict" é o que a hop_pst vanilla usa (commonstates.lua:913) — deixa o
		--cliente voltar a prever movimento sozinho em vez de esperar o servidor, que é a
		--outra metade da latência percebida.
		--
		--Consequência aceita: o pouso agora é interrompível (um ataque, um susto). Para um
		--recurso de mobilidade de combate isso é o comportamento desejado, não um bug — e o
		--estado de VOO acima continua "busy" + "nointerrupt", que é onde a interrupção
		--realmente causaria dano (jogador preso dentro da parede).
		--"pausepredict" saiu junto: ele é o OPOSTO de "autopredict" (builder.lua:630 e
		--wortox_nabbag.lua:295 leem a tag de estado como "não deixe o cliente prever"), e
		--manter os dois seria pedir e negar previsão no mesmo estado. A hop_pst vanilla
		--também só tem "autopredict". Quem precisa de pausepredict é o estado de VOO, que
		--é server-only de verdade.
		--
		--"nopredict" também é do VOO e NÃO pode ser repetido aqui, por mais que pareça
		--coerente: lá ele manda o servidor jogar fora a posição VELHA que o cliente mandou
		--antes do teleporte; aqui ele faria o servidor ignorar as posições NOVAS, que são
		--justamente como o movimento volta a andar depois do salto. Seria desfazer no pouso
		--o que "autopredict" existe para garantir.
		tags = { "autopredict", "nomorph" },

		--Quem retoma a corrida é o PlayerController, não este estado: no primeiro tick em
		--que ele vê o jogador fora de "busy", DoDirectWalking (playercontroller.lua:3062)
		--reaplica a direção que continua pressionada e empurra o locomote sozinho, e o
		--handler global (SGwilson.lua:1747) leva para run_start.
		--
		--NÃO tente adiantar isso com um WantsToMoveForward() aqui no onenter: a flag é
		--falsa neste ponto, garantido. O onenter do voo chamou locomotor:Stop(), que zera
		--wantstomoveforward (locomotor.lua:1100), e enquanto o voo estava "busy" o próprio
		--PlayerController chamou DoDirectStopWalking a cada tick (playercontroller.lua:3044)
		--em vez de reaplicar a direção. Ou seja, um teste de intenção de movimento aqui é
		--sempre falso — seria código morto disfarçado de otimização.
		onenter = function(inst, queued_post_land_state)
			inst.sg.statemem.nextstate = queued_post_land_state or "idle"

			inst.AnimState:SetDeltaTimeMultiplier(RATE)
			inst.AnimState:PlayAnimation("boat_jump_pst")
			--Guarda anti-travamento, igual à dos estados de transformação: se o animover
			--não vier, o ontimeout devolve o controle.
			--
			--GetCurrentAnimationLength devolve a duração NOMINAL, sem o multiplicador —
			--dividir por RATE é o que mantém isto sendo uma guarda de segurança em vez de
			--virar o que realmente encerra o estado antes do animover chegar.
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() / RATE + 8 * FRAMES)
		end,

		events = {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState(inst.sg.statemem.nextstate)
				end
			end),
		},

		ontimeout = function(inst)
			inst.sg:GoToState(inst.sg.statemem.nextstate or "idle")
		end,

		onexit = function(inst)
			inst.AnimState:SetDeltaTimeMultiplier(1)
		end,
	}

	sg.actionhandlers[ACTIONS.WUNNY_JUMPWALL] =
		ActionHandler(ACTIONS.WUNNY_JUMPWALL, "wunny_jumpwall")
end

return {
	GetLanding      = GetLanding,
	GetFreeLanding  = GetFreeLanding,
	CanFreeJump     = CanFreeJump,
	TryFreeJump     = TryFreeJump,
	PatchStategraph = PatchStategraph,
}
