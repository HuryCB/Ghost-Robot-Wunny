--[[
	Ícone de mapa das tocas — cópia do "globalmapiconseeable" vanilla com UMA diferença:
	o RegisterGlobalMapIcon aqui usa o nome "wunny_burrow_network".

	POR QUE ESTE ARQUIVO EXISTE
	FindClosestMapIconInRange (simutil.lua:920) não faz busca espacial nenhuma pelo mundo:
	ela varre GlobalMapIconsDB.prefabs[name], uma tabela Lua COMUM, preenchida por
	RegisterGlobalMapIcon. Tabela Lua comum quer dizer uma por VM — o servidor tem a
	dele, cada cliente tem o seu, e nada disso é replicado.

	Só que quem chama maponly_checkvalidpos_fn primeiro é o CLIENTE: PlayerController:
	RemapMapAction (playercontroller.lua:5127) roda a checagem e, se ela falhar,

		if not valid then return nil end

	devolve nil como ação de botão direito. Sem RMBaction, MapScreen:OnControl
	(mapscreen.lua:1365) nem chega a chamar OnMapAction — o clique não vira RPC nenhum e
	o jogo não dá erro: o botão direito simplesmente não faz nada.

	Antes as tocas se registravam com RegisterGlobalMapIcon(inst, "wunny_burrow_network")
	DEPOIS do `if not TheWorld.ismastersim then return end`, ou seja, só no servidor. Na
	máquina do host isso passava despercebido (é a mesma VM: o "cliente" ali enxerga a
	tabela do servidor), mas em servidor dedicado — ou pra qualquer outro jogador — a
	tabela do cliente ficava vazia e a viagem pelo mapa não funcionava nunca, nem numa
	toca colada no jogador.

	A CORREÇÃO, QUE É O PADRÃO VANILLA
	Repare em globalmapicon.lua: o RegisterGlobalMapIcon está ANTES do SetPristine, ou
	seja, roda nos dois lados. E quem se registra não é a estrutura do mundo, é a
	entidade-ícone — de propósito: a estrutura só existe no cliente quando está perto o
	bastante para estar simulada, enquanto o ícone (CLASSIFIED, SetCanSleep(false)) chega
	ao cliente esteja onde estiver. É isso que faz "wx78_drone_scout" funcionar em
	MAPSCOUTSELECT_MAP a qualquer distância.

	Não dá pra reaproveitar o globalmapiconseeable e só registrá-lo de novo com o nosso
	nome: RegisterGlobalMapIcon recusa a segunda chamada para a mesma entidade
	("called for a second time for inst") e o nome dele já está gasto. Daí a cópia.

	Consequência: quem manda no lookup é o ÍCONE, não a toca. Portanto a toca (tanto
	wunny_burrow quanto o rabbithole em modmain.lua) não se registra mais — senão o
	servidor teria duas entradas na mesma posição e poderia escolher uma entidade
	diferente da que o cliente escolheu. O `mapent` devolvido é usado só pelo
	Transform:GetWorldPosition() em ACTIONS.WUNNY_BURROWTRAVEL_MAP.fn, e o ícone segue a
	posição da toca pelo updatelooper abaixo.
]]

local function UpdatePosition(inst)
	local x, y, z = inst._target.Transform:GetWorldPosition()
	if inst._x ~= x or inst._z ~= z then
		inst._x = x
		inst._z = z
		inst.Transform:SetPosition(x, 0, z)
	end
end

-- Mesma assinatura do TrackEntity de globalmapicon.lua, pra os pontos de uso poderem
-- trocar de prefab sem mudar a chamada.
local function TrackEntity(inst, target, restriction, icon, noupdate)
	inst._target = target

	if restriction ~= nil then
		inst.MiniMapEntity:SetRestriction(restriction)
	end

	if icon ~= nil then
		inst.MiniMapEntity:SetIcon(icon)
	elseif target.MiniMapEntity ~= nil then
		inst.MiniMapEntity:CopyIcon(target.MiniMapEntity)
	else
		inst.MiniMapEntity:SetIcon(target.prefab .. ".png")
	end

	inst:ListenForEvent("onremove", function() inst:Remove() end, target)

	if not noupdate then
		inst:AddComponent("updatelooper")
		inst.components.updatelooper:AddOnUpdateFn(UpdatePosition)
	end

	UpdatePosition(inst)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	inst:AddTag("globalmapicon")
	inst:AddTag("CLASSIFIED")

	inst.MiniMapEntity:SetCanUseCache(false)
	inst.MiniMapEntity:SetIsProxy(true)
	-- Dois argumentos = variante "seeable" (o que o globalmapiconseeable faz).
	inst.MiniMapEntity:SetDrawOverFogOfWar(true, true)
	-- Prioridade que os dois pontos de uso já pediam no SpawnPrefab.
	inst.MiniMapEntity:SetPriority(5)

	inst.entity:SetCanSleep(false)

	-- A LINHA QUE É O MOTIVO DESTE ARQUIVO: antes do SetPristine, logo roda no cliente
	-- também, que é quem valida a ação de mapa primeiro.
	RegisterGlobalMapIcon(inst, "wunny_burrow_network")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst._target = nil
	inst.TrackEntity = TrackEntity
	inst.persists = false

	return inst
end

return Prefab("wunny_burrow_mapicon", fn)
