--[[
	BLINDAGEM CONTRA "Mod component actions are out of sync".

	O PROBLEMA
	Cada entidade em rede ganha UM netvar por mod de servidor para replicar quais
	componentes daquela entidade têm ação registrada por mod (entityscript.lua:189):

		for _, modname in pairs(ModManager:GetServerModsNames()) do
			inst.actionreplica.modactioncomponents[modname] = net_smallbytearray(...)
		end

	Netvar é casado entre cliente e servidor pela ORDEM DE CRIAÇÃO, não pelo nome. E as
	duas pontas montam essa lista de formas diferentes: o servidor usa
	ModWrangler:GetEnabledServerModNames() (todos os mods habilitados que não são
	client_only) e o cliente usa TheNet:GetServerModNames(). Quando as duas listas não
	batem em conteúdo/ordem, um :set() do servidor cai em outro slot no cliente, e a
	entidade fica com uma entrada em `inst.modactioncomponents` sob o nome de um mod que
	nunca chamou AddComponentAction.

	A partir daí, componentactions.lua faz:

		id = CheckModComponentIds(self, modname)[name]     -- linhas 3160 e 3243

	e CheckModComponentIds devolve `MOD_ACTION_COMPONENT_IDS[modname] or
	ModComponentWarning(...)` — ou seja, para um mod desconhecido ela IMPRIME o aviso e
	devolve nil, que é indexado na mesma linha. Crash:

		[string "scripts/componentactions.lua"]:3243: attempt to index a nil value
		 -> actions.lua:1187 ACTIONS.DROP.strfn -> HasActionComponent("deployable")
		 -> bufferedaction.lua:65 GetActionString -> widgets/hoverer.lua:71

	Foi o que derrubou o cliente ao arrastar um coelho do inventário sobre o chão: o
	hoverer recalcula a string de DROP todo frame. Note que CollectActions (3188) e
	IsActionValid (3216) chamam as mesmas funções mas TÊM guarda de nil — só não
	crasham, e em compensação cospem o dumptable do aviso a cada frame.

	POR QUE ISSO NÃO É BUG DE NENHUM MOD ESPECÍFICO
	O nome de mod que aparece no aviso é justamente o nome ERRADO: no caso investigado
	era o "Increase Storage" (workshop-728459184), cujo modmain.lua inteiro não tem uma
	única chamada a AddComponentAction — logo o nome dele jamais poderia ser chave
	legítima ali. Culpar o mod citado no aviso leva pro lugar errado.

	O QUE A WUNNY TEM A VER
	Nada no código dela produz o desalinhamento, mas ela é o gatilho mais fácil de
	encontrar: RecruitWunnyBunnyFollower (modmain.lua) dá AddComponent("inventory") e
	AddComponent("follower") num coelho JÁ EM REDE quando a Wunny lhe dá uma cenoura, e
	EntityScript:AddComponent chama RegisterComponentActions (entityscript.lua:643), que
	é quem faz o :set() nesses netvars no meio da partida.

	A SOLUÇÃO
	Antes de o vanilla iterar `self.modactioncomponents`, remover dali as chaves de mod
	que não existem em MOD_ACTION_COMPONENT_IDS desta ponta. Descartar é o
	comportamento correto no cliente: sem o registro local ele não teria como coletar
	essas ações de qualquer jeito, e a validação da ação acontece no servidor. No
	servidor nada é removido — lá as chaves só nascem de RegisterComponentActions, que
	lê o mesmo mapa.

	MOD_ACTION_COMPONENT_IDS é local de componentactions.lua, então a referência é
	pescada por upvalue. Guardamos a REFERÊNCIA da tabela (AddComponentAction só a
	muta, nunca a reatribui), de modo que mods carregados depois deste continuam
	visíveis normalmente.

	Se um dia a Klei renomear esses locais, o Install() não instala nada e avisa no log
	em vez de quebrar o mod — o jogo volta a ter o crash original, não um novo.
]]

local ModActionGuard = {}

local function FindUpvalue(fn, name)
	if type(fn) ~= "function" then
		return nil
	end
	local i = 1
	while true do
		local k, v = debug.getupvalue(fn, i)
		if k == nil then
			return nil
		elseif k == name then
			return v
		end
		i = i + 1
	end
end

function ModActionGuard.Install()
	-- Marca na CLASSE (e não numa instância): os wrappers abaixo substituem métodos de
	-- EntityScript, então instalar duas vezes empilharia wrapper sobre wrapper.
	if EntityScript._wunny_modactionguard then
		return
	end

	local CheckModComponentIds = FindUpvalue(EntityScript.HasActionComponent, "CheckModComponentIds")
	local MOD_ACTION_COMPONENT_IDS = FindUpvalue(CheckModComponentIds, "MOD_ACTION_COMPONENT_IDS")

	if type(MOD_ACTION_COMPONENT_IDS) ~= "table" then
		print("[wunny/modactionguard] NAO INSTALADO: nao consegui alcancar "
			.. "MOD_ACTION_COMPONENT_IDS em componentactions.lua (upvalue renomeado?). "
			.. "O crash de 'Mod component actions are out of sync' continua possivel.")
		return
	end

	EntityScript._wunny_modactionguard = true

	-- Um print por nome de mod, não por chamada: estas funções rodam em loop de frame.
	local reported = {}

	local function Prune(self)
		local t = self.modactioncomponents
		if t == nil then
			return
		end

		-- Coleta antes de remover: apagar chave durante o pairs é comportamento
		-- indefinido em Lua.
		local bogus
		for modname in pairs(t) do
			if MOD_ACTION_COMPONENT_IDS[modname] == nil then
				bogus = bogus or {}
				table.insert(bogus, modname)
			end
		end

		if bogus == nil then
			return
		end

		for _, modname in ipairs(bogus) do
			t[modname] = nil
			if not reported[modname] then
				reported[modname] = true
				print("[wunny/modactionguard] entrada de acao de mod sem registro nesta ponta, "
					.. "descartada: " .. tostring(modname)
					.. " (primeira vez em " .. tostring(self.prefab) .. ")")
			end
		end

		if next(t) == nil then
			-- O vanilla testa `self.modactioncomponents ~= nil` antes de iterar; deixar
			-- nil economiza o loop. OnModActionComponentsDirty recria a tabela se um
			-- netvar legítimo chegar depois.
			self.modactioncomponents = nil
		end
	end

	-- As duas que indexam o retorno de CheckModComponentIds sem guarda — as que crasham.
	local base_HasActionComponent = EntityScript.HasActionComponent
	function EntityScript:HasActionComponent(name)
		Prune(self)
		return base_HasActionComponent(self, name)
	end

	local base_UnregisterComponentActions = EntityScript.UnregisterComponentActions
	function EntityScript:UnregisterComponentActions(name)
		Prune(self)
		return base_UnregisterComponentActions(self, name)
	end

	-- Estas duas não crashariam, mas sem a limpeza aqui elas imprimem o dumptable do
	-- ModComponentWarning a cada frame em que o mouse passa pela entidade.
	local base_CollectActions = EntityScript.CollectActions
	function EntityScript:CollectActions(actiontype, ...)
		Prune(self)
		return base_CollectActions(self, actiontype, ...)
	end

	local base_IsActionValid = EntityScript.IsActionValid
	function EntityScript:IsActionValid(action, right)
		Prune(self)
		return base_IsActionValid(self, action, right)
	end

	print("[wunny/modactionguard] instalado")
end

return ModActionGuard
