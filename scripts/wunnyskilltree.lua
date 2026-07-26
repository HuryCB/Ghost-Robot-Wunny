--[[
	Aplica os efeitos de "ativação única" (onactivate) de TODAS as skill trees
	vanilla na Wunny, sem passar pela tela de skill tree normal (que tem um
	limite de rede de 32 nós por personagem e não comportaria as ~369
	habilidades somadas dos personagens abaixo).

	Isto cobre apenas as habilidades que definem uma função `onactivate` —
	cerca de 85 das ~369 existentes. As demais só existem como uma `tag`
	checada em tempo de execução dentro do próprio arquivo de cada
	personagem original (ex.: wilson.lua checando HasSkillTag("alchemy") na
	hora de pegar uma gema) e precisam ser portadas manualmente para
	wunny.lua, personagem por personagem, em uma etapa futura.

	Bloqueios de progresso (matar um chefe, ter lunar_favor/shadow_favor
	etc.) são ignorados de propósito: chamamos onactivate diretamente,
	sem consultar lock_open.
]]

local skilltreedefs = require("prefabs/skilltree_defs")

local SKILL_SOURCE_CHARACTERS = {
	"walter",
	"wathgrithr",
	"wendy",
	"willow",
	"wilson",
	"winona",
	"wolfgang",
	"woodie",
	"wormwood",
	"wortox",
	"wurt",
	"wx78",
}

-- Skills cujo onactivate faz alguma coisa "permanente" (WatchWorldState,
-- ListenForEvent, AddComponent...) ANTES de chamar um método específico do
-- personagem original que a Wunny não tem. Quando isso acontece, o pcall
-- abaixo captura o erro e loga a falha normalmente, mas o efeito colateral
-- que já rodou (ex.: um watcher de worldstate.lua com uma função nil) fica
-- pendurado na Wunny pra sempre — e explode depois, na próxima vez que esse
-- worldstate mudar (crash em worldstate.lua:32 "attempt to call field '?'").
-- Caso confirmado: wormwood_blooming_photosynthesis registra
-- WatchWorldState("isday", inst.UpdatePhotosynthesisState) e só then chama
-- inst:UpdatePhotosynthesisState(...), que não existe na Wunny.
local SKIPPED_ONACTIVATE_SKILLS = {
	wormwood_blooming_photosynthesis = true,
}

local function ApplyAllSkillTreeEffects(inst)
	if not TheWorld.ismastersim then
		return
	end

	local applied, failed = 0, 0

	for _, character in ipairs(SKILL_SOURCE_CHARACTERS) do
		local skills = skilltreedefs.SKILLTREE_DEFS[character]
		if skills then
			for skill_name, skill in pairs(skills) do
				if skill.onactivate and not SKIPPED_ONACTIVATE_SKILLS[skill_name] then
					-- fromload = true: mesma semântica que o jogo usa ao
					-- reaplicar skills já concedidas (ex.: ao carregar um
					-- save), em vez de uma ativação "ao vivo" pela UI.
					local ok, err = pcall(skill.onactivate, inst, true)
					if ok then
						applied = applied + 1
					else
						failed = failed + 1
						print(string.format(
							"[WunnySkillTree] Falha ao aplicar %s.%s: %s",
							character, skill_name, tostring(err)
						))
					end
				end
			end
		else
			print(string.format(
				"[WunnySkillTree] Personagem \"%s\" sem SKILLTREE_DEFS (build do jogo desatualizada?)",
				character
			))
		end
	end

	print(string.format("[WunnySkillTree] %d habilidades aplicadas, %d falharam.", applied, failed))
end

return {
	SKILL_SOURCE_CHARACTERS = SKILL_SOURCE_CHARACTERS,
	ApplyAllSkillTreeEffects = ApplyAllSkillTreeEffects,
}
