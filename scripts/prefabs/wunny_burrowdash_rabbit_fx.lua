--[[
	Coelho puramente visual que substitui a Wunny no fim da animação de entrada
	na toca-relâmpago (ver StartBurrowDash em wunny.lua), pra leitura de que ela
	se transforma num coelho antes de afundar.

	É uma entidade separada em vez de trocar o bank/build da própria Wunny de
	propósito: o stategraph do player continua chamando PlayAnimation com nomes
	do bank "wilson" (idle_loop, run_loop...), que não existem no bank "rabbit" —
	trocar o bank da Wunny quebraria a animação dela.
]]

local assets =
{
	Asset("ANIM", "anim/ds_rabbit_basic.zip"),
	Asset("ANIM", "anim/rabbit_build.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("rabbit")
	inst.AnimState:SetBuild("rabbit_build")
	inst.AnimState:PlayAnimation("idle", true)

	inst.persists = false

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	return inst
end

return Prefab("wunny_burrowdash_rabbit_fx", fn, assets)
