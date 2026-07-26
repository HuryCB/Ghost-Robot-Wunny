--[[
	Buraco puramente visual que aparece sob a Wunny quando ela ativa a
	toca-relâmpago (ver StartBurrowDash em wunny.lua).

	Não usa o prefab "rabbithole" de verdade de propósito: aquele tem spawner,
	física de obstáculo e persiste no save — viraria uma toca funcional no
	mundo. Aqui só reaproveitamos a arte dele.
]]

local assets =
{
	Asset("ANIM", "anim/rabbit_hole.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.AnimState:SetBank("rabbithole")
	inst.AnimState:SetBuild("rabbit_hole")
	inst.AnimState:PlayAnimation("idle")
	-- Fica atrás da Wunny: ela ainda está visível cavando em cima do buraco.
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst.persists = false

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	return inst
end

return Prefab("wunny_burrowdash_fx", fn, assets)
