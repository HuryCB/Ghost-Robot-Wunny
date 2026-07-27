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
local JUMP_SPEED = TUNING.WUNNY_JUMPWALL_SPEED or 7

--A animação agacha antes de sair do chão; largar o movimento no frame 0 faz a Wunny
--deslizar durante o agachamento. O vanilla usa o mesmo atraso de 4 frames
--(start_embarking_pre_frame em SGwilson.lua:28557).
local LIFTOFF = 4 * FRAMES
local MIN_FLIGHT = 8 * FRAMES

--Raio de busca por obstáculo no ponto de pouso. Um pouco maior que o raio de física do
--jogador (.5), para não pousar encostado.
local LANDING_CLEARANCE = .7

local BLOCKER_ONEOF_TAGS = { "wall", "blocker" }
local BLOCKER_CANT_TAGS = { "INLIMBO", "FX", "DECOR", "player" }

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

	if not TheWorld.Map:IsPassableAtPoint(landx, 0, landz, false) then
		return nil
	end

	--Paredes se constroem em grade de 1 unidade, então numa parede DUPLA o pouso a 1.3
	--do centro da primeira cai dentro da segunda. Com o Teleport antigo isso já prendia
	--a Wunny; agora prenderia no momento em que a colisão voltasse. Barrar o salto é o
	--comportamento certo: parede grossa continua sendo parede.
	local blockers = TheSim:FindEntities(landx, 0, landz, LANDING_CLEARANCE,
		nil, BLOCKER_CANT_TAGS, BLOCKER_ONEOF_TAGS)
	for _, v in ipairs(blockers) do
		if v ~= wall and v ~= doer then
			return nil
		end
	end

	return landx, landz
end

--------------------------------------------------------------------------------------
local function PatchStategraph(sg)
	sg.states["wunny_jumpwall"] = State{
		name = "wunny_jumpwall",
		--"nointerrupt": no ar, a Wunny está com a colisão desligada e por cima de um
		--obstáculo. Deixar outro estado assumir no meio é o que produz jogador preso
		--dentro da parede.
		--
		--"pausepredict" + RemotePausePrediction, e NÃO "nopredict": este estado existe só
		--no SGwilson (servidor). O cliente não tem estado equivalente, então se ele
		--continuasse prevendo ficaria preso na parede localmente e a posição divergiria
		--até o servidor corrigir num salto. É o mesmo par que os estados de transformação
		--deste mod já usam, pela mesma razão.
		tags = { "busy", "nointerrupt", "pausepredict", "nomorph", "nosleep", "jumping" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			if inst.components.playercontroller ~= nil then
				inst.components.playercontroller:RemotePausePrediction()
			end

			local act = inst:GetBufferedAction()
			local landx, landz = GetLanding(inst, act ~= nil and act.target or nil)
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
			inst:PerformBufferedAction()
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
		tags = { "busy", "pausepredict", "nomorph" },

		onenter = function(inst, queued_post_land_state)
			inst.AnimState:PlayAnimation("boat_jump_pst")
			inst.sg.statemem.nextstate = queued_post_land_state or "idle"
			--Guarda anti-travamento, igual à dos estados de transformação: se o animover
			--não vier, o ontimeout devolve o controle.
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + 8 * FRAMES)
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
	}

	sg.actionhandlers[ACTIONS.WUNNY_JUMPWALL] =
		ActionHandler(ACTIONS.WUNNY_JUMPWALL, "wunny_jumpwall")
end

return {
	GetLanding      = GetLanding,
	PatchStategraph = PatchStategraph,
}
