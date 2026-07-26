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
	-- Desenhado NA FRENTE da Wunny, não atrás: assim a borda do buraco cobre a
	-- parte de baixo dela e a leitura é de que ela está afundando dentro dele.
	-- Atrás só funcionava com ela de costas — de frente o buraco aparecia
	-- inteiro flutuando acima dos pés dela.
	inst.AnimState:SetFinalOffset(1)

	inst.persists = false

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	return inst
end

return Prefab("wunny_burrowdash_fx", fn, assets)
