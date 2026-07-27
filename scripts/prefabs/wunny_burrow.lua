--[[
	Toca de fast-travel da Wunny. Reaproveita o visual do rabbithole vanilla,
	mas não gera coelhos: é um ponto fixo de uma rede de "buracos" que a Wunny
	pode escavar pelo mapa. Ao clicar com o botão direito num outro buraco já
	descoberto (tela do mapa), a Wunny cava até lá instantaneamente, pagando
	um custo de fome proporcional à distância percorrida (ver ACTIONS.WUNNY_BURROWTRAVEL_MAP
	em modmain.lua).
]]

local assets =
{
	Asset("ANIM", "anim/rabbit_hole.zip"),
	-- Ícone de mapa: arte do mod, não do jogo (não existe ícone de toca no atlas de
	-- minimapa vanilla). O AddMinimapAtlas correspondente está em modmain.lua.
	Asset("IMAGE", "images/rabbit_hole.tex"),
	Asset("ATLAS", "images/rabbit_hole.xml"),
}

local prefabs =
{
	"globalmapiconseeable",
}

-- Mesmo padrão do wormhole.lua vanilla: o MiniMapEntity direto na própria
-- estrutura não é suficiente pra garantir um ícone visível/persistente no
-- mapa (fica sujeito à resolução do snapshot de terreno). O "globalmapiconseeable"
-- é uma entidade de rastreamento dedicada, sempre desenhada por cima, que é
-- o mecanismo real usado por wormhole/wx78_backupbody/etc. pra aparecerem no mapa.
local function CreateHiddenGlobalIcon(inst)
	inst.hiddenglobalicon = SpawnPrefab("globalmapiconseeable")
	inst.hiddenglobalicon.MiniMapEntity:SetPriority(5)
	-- Ícone pelo 3º argumento, não por um SetIcon antes: TrackEntity sempre
	-- redefine o ícone (globalmapicon.lua:11). Aqui o CopyIcon do MiniMapEntity
	-- desta estrutura até funcionaria, mas passar explícito deixa as duas tocas
	-- (esta e o rabbithole vanilla em modmain.lua) idênticas, e o rabbithole
	-- DEPENDE disso — ele não tem MiniMapEntity para copiar.
	-- ".tex" = nome do elemento em images/rabbit_hole.xml (arte do mod).
	inst.hiddenglobalicon:TrackEntity(inst, nil, "rabbit_hole.tex")
end

local function OnRemoveEntity(inst)
	if inst.hiddenglobalicon ~= nil then
		inst.hiddenglobalicon:Remove()
	end
end

local function dig_up(inst)
	inst:Remove()
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	inst.MiniMapEntity:SetIcon("rabbit_hole.tex")
	inst.MiniMapEntity:SetPriority(5)

	inst.AnimState:SetBank("rabbithole")
	inst.AnimState:SetBuild("rabbit_hole")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst:AddTag("wunny_burrow")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetOnFinishCallback(dig_up)
	inst.components.workable:SetWorkLeft(3)

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)

	-- registra no lookup global usado por ACTIONS.WUNNY_BURROWTRAVEL_MAP
	-- (FindClosestMapIconInRange busca por esse nome; os rabbitholes vanilla
	-- também se registram aqui, ver AddPrefabPostInit("rabbithole") em
	-- modmain.lua, formando uma rede única de tocas).
	RegisterGlobalMapIcon(inst, "wunny_burrow_network")

	inst:DoTaskInTime(0, CreateHiddenGlobalIcon)
	inst.OnRemoveEntity = OnRemoveEntity

	return inst
end

return Prefab("wunny_burrow", fn, assets, prefabs)
