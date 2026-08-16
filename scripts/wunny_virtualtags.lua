--[[
	TAGS VIRTUAIS — contorno para o teto de 63 tags por entidade da engine.

	O PROBLEMA
	A engine serializa a lista de tags de cada entidade com um contador de 6 bits,
	ou seja, no máximo 63 tags. A Wunny reimplementa o kit de quase todo o elenco e
	chegava a 91-93 tags, o que produzia no servidor:

		Error serializing tags for entity wunny[...] - 91 tags; exceeds maximum size of 63
		Net partial byte (91) out of range [0, 63]

	Quando a serialização das tags estoura, o stream de netvars daquela entidade fica
	desalinhado e TUDO que vem depois falha a leitura no cliente ("Error deserializing
	lua state for entity wunny"). Como o inventory_classified nunca chega, o cliente
	crasha em inventorybar.lua:435 com "attempt to index local 'inventory' (a nil value)".
	O crash aparece no inventário, mas a causa é o excesso de tags.

	A SOLUÇÃO
	Em todo o scripts.zip há exatamente 6 chamadas a `entity:HasTag` (C++ direto) — e a
	única fora do próprio entityscript.lua testa "player". As outras ~5000 consultas
	passam por `EntityScript:HasTag`, que é um método Lua e portanto pode ser
	sobrescrito por instância (a __newindex de class.lua faz rawset, então a função na
	instância eclipsa a da classe).

	Então, para as tags listadas em VIRTUAL abaixo, a Wunny não gasta um slot de rede:
	elas viram uma entrada numa tabela Lua e os shims de HasTag/HasAllTags/HasAnyTag
	respondem por elas. Nenhuma habilidade é perdida e o custo de rede é zero.

	POR QUE ISSO É SEGURO — E QUANDO NÃO É
	Uma tag virtual é invisível para o filtro de tags de `TheSim:FindEntities` /
	`FindEntity`, que roda em C++ sobre as tags reais. Logo, só pode virar virtual a
	tag que NUNCA aparece numa lista de must/cant/oneof-tags de uma busca por
	entidades. Cada tag abaixo foi conferida contra o scripts.zip antes de entrar aqui.
	Ao adicionar uma tag nova à Wunny, faça a mesma checagem:

		grep -rn '"minhatag"' scripts/ | grep -vE 'HasTag|AddTag|RemoveTag'

	Se o resultado tiver `FindEntities`, `FindEntity` ou uma tabela `*_TAGS = {...}`
	usada numa dessas buscas, a tag TEM de continuar real (deixe-a fora daqui).
]]

local VirtualTags = {}

local function ToSet(list)
	local set = {}
	for _, tag in ipairs(list) do
		set[tag] = true
	end
	return set
end

--------------------------------------------------------------------------------
-- Tags descartadas de vez: o vanilla as aplica mas nada nunca as consulta.
--------------------------------------------------------------------------------
local IGNORED = ToSet({
	-- widgets/mightybadge.lua é o único consumidor e testa numa cadeia
	-- if/elseif começando por wolfgang_overbuff_5. Como a Wunny recebe TODAS as
	-- skills, _5 está sempre presente e os outros ramos são inalcançáveis.
	-- wolfgang_overbuff_5 continua (virtual) porque é o que o badge lê.
	"wolfgang_overbuff_1",
	"wolfgang_overbuff_2",
	"wolfgang_overbuff_3",
	"wolfgang_overbuff_4",
})

--------------------------------------------------------------------------------
-- Tags virtuais: consultadas só via `:HasTag` em Lua, nunca em busca por entidades.
--
-- NÃO ENTRAM AQUI (precisam continuar reais, com o motivo):
--   spiderwhisperer  prefabs/spider.lua TARGET_CANT_TAGS + GetOtherSpiders — sem a
--                    tag real as aranhas voltam a atacar a Wunny
--   plantkin         prefabs/bee.lua e prefabs/eyeplant.lua RETARGET_CANT_TAGS
--   HASHEATER        components/temperature.lua e components/inventoryitemtemperature.lua
--                    fazem FindEntities atrás de fontes de calor
--   lunar_aligned    brains/buzzardbrain.lua, brains/bird_mutant_rift_brain.lua e
--                    components/lunarhailmanager.lua usam em canttags
--   shadow_aligned   prefabs/fused_shadeling*.lua e shadowthrall_projectile_fx.lua
--                    usam em canttags
--   mightiness_*     é dinâmica (alterna normal/mighty/wimpy pelo componente)
--   wunny            identidade do personagem; outros mods e o debug procuram por ela
--------------------------------------------------------------------------------
local VIRTUAL = ToSet({
	-- Webber
	"spider_upgradeuser",
	-- Wickerbottom
	"bookbuilder",
	-- Willow
	"expertchef",
	"bernieowner",
	"ember_master",
	"controlled_burner",
	-- Wolfgang
	"strongman",
	"wolfgang_coach",
	"wolfgang_overbuff_5",
	-- Woodie
	"woodcutter",
	"toughworker",
	"weremoosecombo",
	-- Wormwood
	"self_fertilizable",
	"farmplantidentifier",
	"farmplantfastpicker",
	-- Wortox
	"soulstealer",
	"souleater", -- vem do componente souleater
	"nabbaguser",
	-- Warly
	"masterchef",
	"professionalchef",
	-- Walter
	"pebblemaker",
	"slingshot_sharpshooter",
	"dogrider",
	"fasthealer",
	-- Wilson
	"bearded", -- vem do componente beard
	-- Maxwell/Waxwell
	"shadowmagic",
	"magician", -- vem do componente magician
	"reader",   -- vem do componente reader
	-- Wendy
	"ghostlyfriend",
	"elixirbrewer",
	"elixircontaineruser",
	"gravedigger_user",
	"player_damagescale",
	-- WX-78
	"batteryuser",         -- vem do componente batteryuser
	"upgrademoduleowner",  -- vem do componente upgrademoduleowner
	"drone_zap_user",
	-- Winona
	"portableengineer",
	"inspectacleshatuser",
	-- Wurt
	"mosquitograbber",
	-- Alinhamento (as variantes player_* só são lidas via HasTag; as sem prefixo,
	-- que aparecem em canttags de busca, continuam reais)
	"player_lunar_aligned",
	"player_shadow_aligned",
})

--------------------------------------------------------------------------------
-- Shims
--------------------------------------------------------------------------------

local function HasTag(self, tag)
	return self._wunny_vtags[tag] == true or self.entity:HasTag(tag)
end

local function HasAllTags(self, ...)
	local vtags = self._wunny_vtags
	local entity = self.entity
	local first = ...
	if type(first) == "table" then
		for i = 1, #first do
			local tag = first[i]
			if not (vtags[tag] or entity:HasTag(tag)) then
				return false
			end
		end
		return true
	end
	for i = 1, select("#", ...) do
		local tag = select(i, ...)
		if not (vtags[tag] or entity:HasTag(tag)) then
			return false
		end
	end
	return true
end

local function HasAnyTag(self, ...)
	local vtags = self._wunny_vtags
	local entity = self.entity
	local first = ...
	if type(first) == "table" then
		for i = 1, #first do
			local tag = first[i]
			if vtags[tag] or entity:HasTag(tag) then
				return true
			end
		end
		return false
	end
	for i = 1, select("#", ...) do
		local tag = select(i, ...)
		if vtags[tag] or entity:HasTag(tag) then
			return true
		end
	end
	return false
end

local function AddTag(self, tag)
	if IGNORED[tag] then
		return
	elseif VIRTUAL[tag] then
		self._wunny_vtags[tag] = true
		-- Se alguma coisa já tinha gravado a versão real (ordem de carregamento de
		-- outro mod, por exemplo), devolve o slot.
		self.entity:RemoveTag(tag)
		return
	end
	self.entity:AddTag(tag)
end

local function RemoveTag(self, tag)
	self._wunny_vtags[tag] = nil
	self.entity:RemoveTag(tag)
end

-- O AddOrRemoveTag do entityscript.lua chama self.entity:AddTag direto, sem passar
-- pelo EntityScript:AddTag — sem este shim os componentes que usam essa forma
-- (beard, reader, batteryuser...) furariam o esquema e voltariam a gastar slots.
local function AddOrRemoveTag(self, tag, condition)
	if condition then
		AddTag(self, tag)
	else
		RemoveTag(self, tag)
	end
end

--------------------------------------------------------------------------------

-- Deve ser chamada em common_postinit, ANTES de qualquer AddTag: os shims precisam
-- estar de pé para interceptar as tags do próprio common_postinit, dos componentes
-- adicionados no master_postinit e das skills aplicadas por wunnyskilltree.lua.
--
-- Rodar nos dois lados é obrigatório, não é otimização: o cliente nunca executa o
-- master_postinit nem a skilltree, então sem o preset abaixo ele não saberia que a
-- Wunny tem essas tags e o filtro de receitas (builder_replica.lua) esconderia
-- metade do menu de criação. É exatamente o papel que a replicação da tag fazia.
function VirtualTags.Install(inst)
	if inst._wunny_vtags ~= nil then
		return
	end
	inst._wunny_vtags = {}

	inst.AddTag = AddTag
	inst.RemoveTag = RemoveTag
	inst.AddOrRemoveTag = AddOrRemoveTag
	inst.HasTag = HasTag
	inst.HasTags = HasAllTags
	inst.HasAllTags = HasAllTags
	inst.HasOneOfTags = HasAnyTag
	inst.HasAnyTag = HasAnyTag

	for tag in pairs(VIRTUAL) do
		inst._wunny_vtags[tag] = true
	end
end

VirtualTags.VIRTUAL = VIRTUAL
VirtualTags.IGNORED = IGNORED

return VirtualTags
