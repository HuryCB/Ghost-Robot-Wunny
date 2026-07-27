--[[
	Whitelists de skills concedidas permanentemente à Wunny, por personagem de
	origem, mais o instalador do override de skilltreeupdater:IsActivated.

	POR QUE ISTO É UM ARQUIVO SEPARADO: mesma razão de wunny_wormwood_bloom.lua —
	o chunk principal de prefabs/wunny.lua bateu no limite rígido do Lua 5.1 de
	200 variáveis locais por função. As 5 tabelas + o instalador viram um único
	`require` lá. Ao portar o próximo personagem, adicione a tabela dele AQUI.

	Install(inst, skills) é chamado no common_postinit (não no master_postinit)
	porque o menu de crafting é filtrado NO CLIENTE: builder_replica.lua:312
	também chama skilltreeupdater:IsActivated(builder_skill). Sem o override no
	cliente, as receitas travadas por builder_skill não apareceriam na aba da
	Wunny, mesmo o servidor aceitando construí-las.
]]

----------------------------------------------------------------------------------------
-- Wilson: skills concedidas de forma permanente.
--
-- Nenhuma destas skills tem `onactivate` (só as duas de allegiance e a beard_7
-- têm), então WunnySkillTree.ApplyAllSkillTreeEffects não faz nada por elas — o
-- efeito inteiro vive em checagens de IsActivated espalhadas pelo jogo, que é
-- justamente o que esta whitelist atende:
--   torch_1..3    -> prefabs/torch.lua getskillfueleffectmodifier (tocha dura mais)
--   torch_4..6    -> prefabs/torch.lua getskillbrightnesseffectmodifier (raio de luz)
--   torch_7       -> ação TOSS (ver Wortox_GetPointSpecialActions)
--   beard_1..3    -> components/beard.lua GetInsulation (isolamento térmico)
--   beard_4..6    -> components/beard.lua OnDayComplete (barba cresce mais rápido)
--   beard_7       -> components/beard.lua UpdateBeardInventory (barba-mochila)
--   alchemy_1..10 -> components/builder.lua (builder_skill das receitas transmute_*)
--
-- As duas de allegiance liberam transmute_horrorfuel/dreadstone/nightmarefuel
-- (shadow) e transmute_purebrilliance/moonglass_charged (lunar). Ficam as duas
-- ligadas, seguindo o que o mod já faz com wx78_allegiance_lunar/shadow: no
-- vanilla elas são exclusivas, aqui a Wunny acumula as duas de propósito.
--
-- Ao contrário da whitelist do wx78 (instalada no master_postinit), esta é
-- instalada no common_postinit porque o menu de crafting é filtrado NO CLIENTE:
-- builder_replica.lua:312 também chama skilltreeupdater:IsActivated(builder_skill).
-- Sem o override no cliente, as ~24 receitas transmute_* simplesmente não
-- apareceriam na aba da Wunny, mesmo o servidor aceitando construí-las.
----------------------------------------------------------------------------------------

local WILSON_SKILLS_ALWAYSON = {
	-- Torch
	wilson_torch_1 = true,
	wilson_torch_2 = true,
	wilson_torch_3 = true,
	wilson_torch_4 = true,
	wilson_torch_5 = true,
	wilson_torch_6 = true,
	wilson_torch_7 = true,
	-- Beard
	wilson_beard_1 = true,
	wilson_beard_2 = true,
	wilson_beard_3 = true,
	wilson_beard_4 = true,
	wilson_beard_5 = true,
	wilson_beard_6 = true,
	wilson_beard_7 = true,
	-- Alchemy (transmutação)
	wilson_alchemy_1 = true,
	wilson_alchemy_2 = true,
	wilson_alchemy_3 = true,
	wilson_alchemy_4 = true,
	wilson_alchemy_5 = true,
	wilson_alchemy_6 = true,
	wilson_alchemy_7 = true,
	wilson_alchemy_8 = true,
	wilson_alchemy_9 = true,
	wilson_alchemy_10 = true,
	-- Allegiance
	wilson_allegiance_shadow = true,
	wilson_allegiance_lunar = true,
}

----------------------------------------------------------------------------------------
-- Willow: skills concedidas de forma permanente.
--
-- Mesma situação do Wilson: das 19 skills abaixo, só willow_controlled_burn_1
-- (tag "controlled_burner") e willow_embers (tag "ember_master") têm onactivate
-- — e essas duas tags já vêm de WunnySkillTree.ApplyAllSkillTreeEffects, que já
-- inclui "willow" na lista de personagens. Todo o resto do efeito vive em
-- checagens de IsActivated dentro dos arquivos do isqueiro/Bernie/brasas:
--   controlled_burn_1  -> prefabs/lighter.lua onattack e prefabs/torch.lua
--                         (ataque com fogo sempre incendeia, sem rolar sorte)
--   controlled_burn_2/3-> components/burnable.lua (duração/dano do fogo controlado)
--   attuned_lighter    -> prefabs/lighter.lua RefreshAttunedSkills (channelcastable)
--   lightradius_1/2    -> prefabs/lighter.lua applyskillbrightness (raio de luz)
--   embers             -> prefabs/willow_ember.lua updatespells (magia Fire Throw)
--                         + queda de brasas (ver Willow_OnEntityDropLoot abaixo)
--   fire_burst/ball/frenzy -> prefabs/willow_ember.lua updatespells (demais magias)
--   bernieregen_1/2    -> prefabs/bernie_big.lua onLeaderChanged (regeneração)
--   berniehealth_1/2   -> prefabs/bernie_big.lua onLeaderChanged (vida máxima)
--   berniespeed_1/2    -> prefabs/bernie_big.lua onLeaderChanged (velocidade)
--   burnignbernie      -> prefabs/bernie_big.lua onLeaderChanged (Bernie flamejante)
--                         [o nome é um typo do vanilla, mantido de propósito]
--   bernieai           -> prefabs/bernie_common.lua hotheaded (acorda perto de
--                         inimigos, sem depender da sanidade) + bernie_big.lua
--   berniesanity_1/2   -> prefabs/bernie_common.lua isleadercrazy (Bernie acorda
--                         com sanidade mais alta)
--
-- As skills de allegiance (shadow/lunar) ficam de FORA a pedido: sem elas o
-- Bernie não vira aliado lunar/sombrio e as duas magias de brasa de aliança não
-- aparecem no spellbook. Os nós "lock" (willow_bernie_lock, willow_allegiance_
-- lock_N) também não entram: são só travas da UI da árvore, ninguém consulta
-- IsActivated neles em tempo de execução.
--
-- Os nós de Bernie exigem a tag "bernieowner" (já adicionada em common_postinit)
-- pra Wunny poder equipar o bernie_inactive; quem popula inst.bigbernies é o
-- próprio bernie_active.lua/berniebigbrain.lua, não o personagem.
----------------------------------------------------------------------------------------

local WILLOW_SKILLS_ALWAYSON = {
	-- Isqueiro / fogo controlado
	willow_controlled_burn_1 = true,
	willow_controlled_burn_2 = true,
	willow_controlled_burn_3 = true,
	willow_attuned_lighter = true,
	willow_lightradius_1 = true,
	willow_lightradius_2 = true,
	-- Brasas (magias do spellbook de willow_ember)
	willow_embers = true,
	willow_fire_burst = true,
	willow_fire_ball = true,
	willow_fire_frenzy = true,
	-- Bernie
	willow_bernieregen_1 = true,
	willow_bernieregen_2 = true,
	willow_berniesanity_1 = true,
	willow_berniesanity_2 = true,
	willow_berniespeed_1 = true,
	willow_berniespeed_2 = true,
	willow_berniehealth_1 = true,
	willow_berniehealth_2 = true,
	willow_bernieai = true,
	willow_burnignbernie = true,
}

----------------------------------------------------------------------------------------
-- Winona: mesma ideia das duas tabelas acima. As skills dela quase todas leem
-- skilltreeupdater DO CONSTRUTOR de uma estrutura de engenharia, não do próprio
-- jogador — cada estrutura chama ConfigureSkillTreeUpgrades(inst, builder) na
-- hora em que é montada e guarda o nível resultante em campos próprios.
--
-- Onde o vanilla lê cada uma:
--   spotlight_heated   -> prefabs/winona_spotlight.lua ConfigureSkillTreeUpgrades
--                         (holofote aquece quem está no facho no inverno)
--   spotlight_range    -> idem (raio/alcance maiores: SPOTLIGHT_*2 em TUNING)
--   portable_structures-> tag "portableengineer" (onactivate; JÁ aplicada por
--                         WunnySkillTree.ApplyAllSkillTreeEffects) -> libera as
--                         receitas winona_*_item e o winona_remote em recipes.lua
--   gadget_recharge    -> prefabs/winona_remote.lua / winona_storage_robot.lua /
--                         winona_telebrella.lua (recarrega mais rápido)
--   battery_idledrain  -> prefabs/winona_battery_low|high.lua UpdateCircuitPower
--                         (baterias não gastam combustível com carga ociosa)
--   battery_efficiency_1/2/3 -> idem + CalcActualFuel (combustível dura +25/50/100%)
--   catapult_speed_1/2/3     -> prefabs/winona_catapult.lua RefreshAttackPeriod
--   catapult_aoe_1/2/3       -> idem (AOE_RADIUS) + SGwinona_catapult.lua
--   catapult_volley_1  -> prefabs/winona_remote.lua (magia de salva pelo controle)
--   catapult_boost_1   -> idem (magia de acelerar catapultas)
--   charlie_1          -> receita roseglasseshat (builder_skill) + prefabs/hats.lua
--                         roseglasses_refreshattunedskills (componente closeinspector)
--   charlie_2          -> imunidade a escuridão (onactivate, JÁ aplicada) +
--                         wormhole.lua / tentacle_pillar_hole.lua / flower.lua
--                         (rastrear buracos de verme, colher flores rosadas)
--   shadow_1/2         -> prefabs/winona_battery_low.lua (abastecer com nightmarefuel
--                         e horrorfuel)
--   shadow_3           -> prefabs/winona_catapult.lua / winona_remote.lua
--                         (munição de sombra e salva elemental)
--   lunar_1/2          -> prefabs/winona_battery_high.lua (abastecer com
--                         purebrilliance / lunarplant_husk)
--   lunar_3            -> munição lunar, mesmos arquivos do shadow_3
--   wagstaff_1         -> tag "inspectacleshatuser" (onactivate, JÁ aplicada) +
--                         receitas inspectacleshat e winona_storage_robot
--   wagstaff_2         -> receitas winona_telebrella e winona_teleport_pad_item +
--                         components/inspectaclesparticipant.lua (caixa melhorada)
--
-- Os nós "lock" (winona_lowshelf_lock, winona_midshelf_lock, winona_portable_
-- structures_lock, winona_charlie_2_lock, winona_wagstaff_2_lock, winona_shadow_3_
-- lock, winona_lunar_3_lock) não entram: são só travas da UI da árvore.
--
-- Ao contrário da Willow, aqui as skills de aliança ENTRAM — segue o mesmo
-- critério já usado pra WX78 em master_postinit, que também libera as duas
-- alianças de uma vez. No vanilla charlie_2 e wagstaff_2 se travam mutuamente
-- (ver lock_open em skilltree_winona.lua); a Wunny fica com as duas.
--
-- A tag "handyperson" continua comentada em common_postinit de propósito (a Wunny
-- tem as cópias wunny_* das estruturas, com tag de construtor "wunny"). O efeito
-- colateral é que `_engineerid` fica nil nas estruturas vanilla: elas funcionam e
-- recebem os bônus de skill normalmente, só não creditam abates à Wunny nem usam
-- o tempo de "sono" mais longo reservado à engenheira. Os NÍVEIS de skill vêm do
-- construtor independentemente dessa tag.
----------------------------------------------------------------------------------------

local WINONA_SKILLS_ALWAYSON = {
	-- Prateleira de baixo
	winona_spotlight_heated = true,
	winona_spotlight_range = true,
	winona_portable_structures = true,
	winona_gadget_recharge = true,
	winona_battery_idledrain = true,
	-- Prateleira do meio: catapulta
	winona_catapult_speed_1 = true,
	winona_catapult_speed_2 = true,
	winona_catapult_speed_3 = true,
	winona_catapult_aoe_1 = true,
	winona_catapult_aoe_2 = true,
	winona_catapult_aoe_3 = true,
	winona_catapult_volley_1 = true,
	winona_catapult_boost_1 = true,
	-- Prateleira do meio: baterias
	winona_battery_efficiency_1 = true,
	winona_battery_efficiency_2 = true,
	winona_battery_efficiency_3 = true,
	-- Aliança sombria (Charlie)
	winona_charlie_1 = true,
	winona_charlie_2 = true,
	winona_shadow_1 = true,
	winona_shadow_2 = true,
	winona_shadow_3 = true,
	-- Aliança lunar (Wagstaff)
	winona_wagstaff_1 = true,
	winona_wagstaff_2 = true,
	winona_lunar_1 = true,
	winona_lunar_2 = true,
	winona_lunar_3 = true,
}

----------------------------------------------------------------------------------------
-- Walter: mesma ideia das tabelas acima. Das 26 skills, só quatro têm onactivate
-- (ammo_bag -> tag "slingshotammocontaineruser", camp_fire -> tag
-- "portable_campfire_user", camp_firstaid -> tag "fasthealer" + multiplicador de
-- ACTIONS.HEAL no efficientuser, e as quatro de aliança -> ONACTIVATE_FNS) — e
-- essas já vêm de WunnySkillTree.ApplyAllSkillTreeEffects, que já inclui "walter".
-- O resto do efeito vive em checagens de IsActivated espalhadas:
--   slingshot_modding    -> components/slingshotmods.lua (libera trocar peças do
--                           estilingue) + componentactions.lua (ação SLINGSHOTMODDING)
--   slingshot_bands/frames/handles -> prefabs/slingshotpart_defs.lua (cada peça
--                           declara a skill que a habilita) + receitas em recipes.lua
--   ammo_shattershots/lucky/utility -> prefabs/slingshotammo.lua (cada munição
--                           declara `skill`) + as receitas slingshotammo_* correspondentes
--   ammo_efficiency      -> recipes.lua calc_slingshotammo_numtogive (rende mais
--                           munição por craft)
--   ammo_shadow/lunar    -> munições de aliança (gelblob/horrorfuel, husk/purebrilliance)
--   woby_sprint          -> stategraphs/SGwilson.lua + SGwilson_client.lua (corrida
--                           do Woby) + comando "sprinting" na roda
--   woby_dash            -> GetDoubleClickActions (ACTIONS.DASH; ver abaixo) +
--                           SGwilson.lua estado "dash_woby"
--   woby_shadow/lunar    -> prefabs/wobybig.lua|wobysmall.lua RefreshAttunedSkills
--                           (build de aliança, dash sombrio, medidor lunar em
--                           widgets/statusdisplays.lua)
--   woby_endurance       -> wobybig/wobysmall (fome do Woby cai mais devagar,
--                           velocidade base maior) + badge em statusdisplays.lua
--   woby_itemfetcher     -> brains/wobycommon.lua (Woby cata itens do chão)
--   woby_foraging        -> brains/wobycommon.lua + wobybig/wobysmall (Woby colhe)
--   woby_taskaid         -> brains/wobybigbrain.lua (Woby ajuda a trabalhar)
--   camp_rope            -> receita "walter_rope" (corda por 2 gramas em vez de 3);
--                           a receita "rope" normal tem no_builder_skill e SAI do
--                           menu, substituída pela versão barata (forward_ingredients)
--   camp_walterhat       -> prefabs/hats.lua walter_refreshattunedskills (o
--                           walterhat isola mais e protege mais a sanidade)
--   camp_wobytreat       -> receita "woby_treat"
--   camp_firstaid        -> receita "bandage_butterflywings" + o próprio prefab dela
--   camp_fire            -> receita "portablefirepit_item" + SGwilson.lua e
--                           walter.lua (contar história na fogueira portátil)
--   camp_wobyholder      -> wobybig/wobysmall EnableRack (bagageiro nas costas)
--   camp_wobycourier     -> prefabs/wobycommon.lua (comandos "lembrar baú"/"entregar"),
--                           woby_commands_classified.lua e actions.lua:3461
--                           (DIRECTCOURIER_MAP)
--
-- Os nós "lock" (walter_ammo_lock, walter_ammo_shadow_lock, walter_ammo_lunar_lock,
-- walter_woby_lock, walter_woby_shadow_lock, walter_woby_lunar_lock,
-- walter_camp_lock) não entram: são só travas da UI da árvore.
--
-- As alianças ENTRAM, mesmo critério do wx78 e da Winona. Note que no vanilla o
-- Woby só pode ter UM alinhamento: wobybig.lua RefreshAttunedSkills testa lunar
-- ANTES de shadow, então com as duas ligadas a Wunny fica com a Woby lunar. As
-- munições de estilingue das duas alianças funcionam juntas, sem conflito.
--
-- Instalada em common_postinit igual às outras três: RefreshCommands (a roda de
-- comandos do Woby) roda NO CLIENTE, por "onactivateskill_client"/
-- "skilltreeinitialized_client", e o filtro das ~15 receitas de munição/peça por
-- builder_skill também (builder_replica.lua).
----------------------------------------------------------------------------------------

local WALTER_SKILLS_ALWAYSON = {
	-- Estilingue (peças)
	walter_slingshot_modding = true,
	walter_slingshot_handles = true,
	walter_slingshot_bands = true,
	walter_slingshot_frames = true,
	-- Munição
	walter_ammo_shattershots = true,
	walter_ammo_lucky = true,
	walter_ammo_utility = true,
	walter_ammo_efficiency = true,
	walter_ammo_bag = true,
	walter_ammo_shadow = true,
	walter_ammo_lunar = true,
	-- Woby
	walter_woby_sprint = true,
	walter_woby_dash = true,
	walter_woby_endurance = true,
	walter_woby_itemfetcher = true,
	walter_woby_foraging = true,
	walter_woby_taskaid = true,
	walter_woby_shadow = true,
	walter_woby_lunar = true,
	-- Acampamento
	walter_camp_fire = true,
	walter_camp_rope = true,
	walter_camp_firstaid = true,
	walter_camp_walterhat = true,
	walter_camp_wobytreat = true,
	walter_camp_wobyholder = true,
	walter_camp_wobycourier = true,
}

----------------------------------------------------------------------------------------
-- Wormwood: skills concedidas de forma permanente.
--
-- As quatro que têm onactivate (identify_plants2 -> tag "farmplantidentifier",
-- blooming_farmrange1 -> tag "farmplantfastpicker", e as duas de aliança lunar ->
-- tag "player_lunar_aligned" + resistências) já vêm de
-- WunnySkillTree.ApplyAllSkillTreeEffects, que já inclui "wormwood".
--
-- Onde o vanilla lê cada uma das outras:
--   saplingcrafting/berrybushcrafting/juicyberrybushcrafting/reedscrafting/
--   lureplantbulbcrafting  -> recipes.lua:343-348 (builder_skill das receitas
--                             wormwood_* que plantam por custo de vida)
--   syrupcrafting          -> recipes.lua:342 (receita "ipecacsyrup")
--   mushroomplanter_ratebonus1/2 -> prefabs/mushroom_farm.lua:59-61 (cogumelos
--                             crescem mais rápido; lê o skilltreeupdater de quem
--                             PLANTOU, não de quem colhe)
--   mushroomplanter_upgrade      -> mushroom_farm.lua:51 (planter melhorado)
--   moon_cap_eating        -> prefabs/moon_mushroom.lua:37 (moon cap não dá
--                             penalidade) + mushroom_farm.lua:257
--   bugs                   -> prefabs/bee.lua:119,131 + beebox.lua:137 +
--                             wasphive.lua:40 + brains/butterflybrain.lua e
--                             moonbutterflybrain.lua (abelhas/borboletas não
--                             fogem nem atacam)
--   quick_selffertilizer   -> stategraphs/SGwilson.lua:20941 (animação
--                             "shortest_fertilize" em vez de "fertilize")
--   armor_bramble          -> prefabs/armor_bramble.lua:39 +
--                             armor_lunarplant.lua:267 (espinhos revidam mais)
--   allegiance_lunar_plant_gear_1 -> armor_lunarplant.lua:38 + receitas
--                             armor_lunarplant_husk e cia.
--   allegiance_lunar_plant_gear_2 -> components/lunarplant_tentacle_weapon.lua:3
--   allegiance_lunar_mutations_1/2/3 -> recipes.lua:349-351 (os pets mutantes
--                             wormwood_carrat / lightflier / fruitdragon)
--
-- Os nós "lock" (wormwood_allegiance_lock_lunar_1/2 e
-- wormwood_allegiance_count_lock_1/2) não entram: são só travas da UI da árvore.
--
-- Ao contrário dos outros personagens, a Wormwood só tem UM ramo de aliança
-- (lunar), então não há o conflito shadow/lunar que existe no wx78 e no Walter —
-- as cinco skills de aliança entram todas juntas sem se anularem.
--
-- Instalada em common_postinit igual às outras: o filtro por builder_skill das
-- ~10 receitas acima roda no cliente (builder_replica.lua:312).
--
-- ATENÇÃO ao ramo "blooming": seis destas skills (speed1, speed2, max_upgrade,
-- overheatprotection, photosynthesis, trapbramble) só são lidas DENTRO de
-- prefabs/wormwood.lua, num sistema de florescimento que a Wunny não tinha. É por
-- isso que existe o bloco "Wormwood: florescimento" logo abaixo — sem ele a
-- whitelist deixaria essas seis ligadas e inertes.
----------------------------------------------------------------------------------------

local WORMWOOD_SKILLS_ALWAYSON = {
	-- Raiz (identificar plantas)
	wormwood_identify_plants2 = true,
	-- Plantio por custo de vida
	wormwood_saplingcrafting = true,
	wormwood_berrybushcrafting = true,
	wormwood_juicyberrybushcrafting = true,
	wormwood_reedscrafting = true,
	wormwood_lureplantbulbcrafting = true,
	-- Cogumelos / xarope
	wormwood_mushroomplanter_ratebonus1 = true,
	wormwood_mushroomplanter_ratebonus2 = true,
	wormwood_mushroomplanter_upgrade = true,
	wormwood_moon_cap_eating = true,
	wormwood_syrupcrafting = true,
	-- Florescimento
	wormwood_blooming_speed1 = true,
	wormwood_blooming_speed2 = true,
	wormwood_blooming_max_upgrade = true,
	wormwood_blooming_overheatprotection = true,
	wormwood_blooming_photosynthesis = true,
	wormwood_blooming_farmrange1 = true,
	wormwood_blooming_trapbramble = true,
	wormwood_quick_selffertilizer = true,
	wormwood_bugs = true,
	wormwood_armor_bramble = true,
	-- Aliança lunar
	wormwood_allegiance_lunar_plant_gear_1 = true,
	wormwood_allegiance_lunar_plant_gear_2 = true,
	wormwood_allegiance_lunar_mutations_1 = true,
	wormwood_allegiance_lunar_mutations_2 = true,
	wormwood_allegiance_lunar_mutations_3 = true,
}

local function Wunny_InstallSkillWhitelist(inst, skills)
	local skilltreeupdater = inst.components.skilltreeupdater
	if skilltreeupdater == nil then
		return
	end
	local IsActivated_prev = skilltreeupdater.IsActivated
	function skilltreeupdater:IsActivated(skill, ...)
		if skills[skill] then
			return true
		end
		return IsActivated_prev(self, skill, ...)
	end
end

return {
	WILSON   = WILSON_SKILLS_ALWAYSON,
	WILLOW   = WILLOW_SKILLS_ALWAYSON,
	WINONA   = WINONA_SKILLS_ALWAYSON,
	WALTER   = WALTER_SKILLS_ALWAYSON,
	WORMWOOD = WORMWOOD_SKILLS_ALWAYSON,
	Install  = Wunny_InstallSkillWhitelist,
}
