PrefabFiles = {
    -- "bunnykingmanager",
    "wunny",
    "wunny_none",
    "rabbithole_placer",
    -- "everythingbunnyhouse_placer",
    "rabbithouse",
    "wunnyrabbithouse",
    "carrot",
    "birchnuthat",
    -- "bunnyback",
    "coolerpack",
    "beardlordpack",
    "beardlordhat",
    -- "batbunny",
    "newbunnyhouse",
    "daybunnyhouse",
    "dwarfbunnyhouse",
    "everythingbunnyhouse",
    "everythingbunnyman",
    "ultrabunnyhouse",
    "ultrabunnyman",
    "shadowbunnyman",
    "shadowbunnyhouse",
    "newbunnyman",
    "daybunnyman",
    "dwarfbunnyman",
    "rabbitamulet",
    "wunny_catapult",
    "bunnykinghouse",
    "bunnyking",
    "wunny_spotlight",
    "wunny_battery_low",
    "wunny_battery_high",
    "snakeking",
    "sewing_tape",
    "spiderbunny",
    "bunnybat",
    "containerbunnyman",
    "wunnypickcane",
    "wunnyaxecane",
    "wunnypickaxecane",
    "wunnypickaxecanelantern",
    "wunnywalrus",
    "hutch_fishbowl",
    "cinnabunnfarm",


    -- "wurt_turf_marsh",
    -- "modhats",

    "wunnyslingshot",
    "wunnyicebox",
    "wunny_burrow",
    "wunny_burrowdash_fx",
    "wunny_burrowdash_rabbit_fx",
    -- "beardlordback"
}

Assets = {
    Asset( "IMAGE", "images/map_icons/cinnabunnfarm.tex" ),
	Asset( "ATLAS", "images/map_icons/cinnabunnfarm.xml" ),

    Asset("IMAGE", "images/saveslot_portraits/wunny.tex"),
    Asset("ATLAS", "images/saveslot_portraits/wunny.xml"),

    Asset("IMAGE", "images/selectscreen_portraits/wunny.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/wunny.xml"),
    Asset("IMAGE", "images/selectscreen_portraits/wunny_silho.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/wunny_silho.xml"),

    Asset("IMAGE", "bigportraits/wunny.tex"),
    Asset("ATLAS", "bigportraits/wunny.xml"),

    Asset("IMAGE", "images/map_icons/wunny.tex"),
    Asset("ATLAS", "images/map_icons/wunny.xml"),

    Asset("IMAGE", "images/avatars/avatar_wunny.tex"),
    Asset("ATLAS", "images/avatars/avatar_wunny.xml"),

    Asset("IMAGE", "images/avatars/avatar_ghost_wunny.tex"),
    Asset("ATLAS", "images/avatars/avatar_ghost_wunny.xml"),

    Asset("IMAGE", "images/avatars/self_inspect_wunny.tex"),
    Asset("ATLAS", "images/avatars/self_inspect_wunny.xml"),

    Asset("IMAGE", "images/names_wunny.tex"),
    Asset("ATLAS", "images/names_wunny.xml"),

    Asset("IMAGE", "images/names_gold_wunny.tex"),
    Asset("ATLAS", "images/names_gold_wunny.xml"),

    Asset("ATLAS", "images/inventoryimages/rabbithole.xml"),
    Asset("IMAGE", "images/inventoryimages/rabbithole.tex"),

    Asset("IMAGE", "images/inventoryimages/rabbithole.tex"),

    -- Ícone de minimapa das tocas (rabbithole vanilla e wunny_burrow). NÃO existe
    -- ícone de toca no atlas de minimapa do jogo: data/minimap/minimap_data.xml só
    -- tem "rabbit_house.png" e "rabbittrap.png" — o rabbithole vanilla nem tem
    -- MiniMapEntity. Por isso o ícone é arte do mod, e um ícone de mod precisa das
    -- TRÊS coisas: IMAGE + ATLAS aqui, AddMinimapAtlas do .xml (logo abaixo), e o
    -- SetIcon usando o NOME DO ELEMENTO do xml, que é "rabbit_hole.tex".
    Asset("IMAGE", "images/rabbit_hole.tex"),
    Asset("ATLAS", "images/rabbit_hole.xml"),

    Asset("ATLAS", "images/inventoryimages/birchnuthat.xml"),

    -- Asset("ATLAS", "images/inventoryimages/cane.xml"),

    -- Asset("ATLAS", "images/inventoryimages/ham_bat.xml"),

    -- Asset("ATLAS", "images/inventoryimages/bat_bunny.xml"),

    Asset("ATLAS", "images/inventoryimages/beardlordhat.xml"),

    Asset("ATLAS", "images/inventoryimages/bunny.xml"),

    Asset("ATLAS", "images/inventoryimages/bunnyhouse.xml"),
    Asset("ATLAS", "images/inventoryimages/winona_catapult.xml"),
    Asset("ATLAS", "images/inventoryimages/wunny_spotlight.xml"),
    Asset("ATLAS", "images/inventoryimages/wunny_battery_low.xml"),
    Asset("ATLAS", "images/inventoryimages/wunny_battery_high.xml"),
    Asset("ATLAS", "images/inventoryimages/coolerpack.xml"),
    Asset("ATLAS", "images/inventoryimages/beardlordpack.xml"),
    -- Asset("IMAGE", "images/inventoryimages/coolerpack.tex"),


    Asset("ANIM", "anim/swap_coolerpack.zip"),

    Asset("ANIM", "anim/everythingmanrabbit_build.zip"),

    -- Asset("ANIM", "anim/bat_bunny.zip"),
    -- Asset("ANIM", "anim/swap_bat_bunny.zip"),

    Asset("ANIM", "anim/slingshot.zip"),
    Asset("ANIM", "anim/swap_slingshot.zip"),
    Asset("IMAGE", "images/inventoryimages/slingshot.tex"),


}
-- Sem esta linha o SetIcon("rabbit_hole.tex") não resolve para nada e a toca
-- simplesmente não desenha no mapa, sem erro no log.
AddMinimapAtlas("images/rabbit_hole.xml")
AddMinimapAtlas("images/map_icons/cinnabunnfarm.xml")
AddMinimapAtlas("images/map_icons/wunny.xml")
AddMinimapAtlas("images/map_icons/coolerpack.xml")
AddMinimapAtlas("images/map_icons/beardlordpack.xml")

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local RECIPETABS = GLOBAL.RECIPETABS
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH
local _G = GLOBAL
local ACTIONS = GLOBAL.ACTIONS
local ActionHandler = GLOBAL.ActionHandler
-- local BunnyKingManager = require("components/bunnykingmanager")
-- _G.speedMultiplier = 1

modimport("strings.lua")

local containers = require "containers"

local params = {}

local OVERRIDE_WIDGETSETUP = false
local containers_widgetsetup_base = containers.widgetsetup

function containers.widgetsetup(container, prefab)
    local t = params[prefab or container.inst.prefab]
    if t ~= nil then
        for k, v in pairs(t) do
            container[k] = v
        end
        container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
        if OVERRIDE_WIDGETSETUP then
            container.type = "coolerpack"
        end
    else
        containers_widgetsetup_base(container, prefab)
    end
end

params.coolerpack = {
    widget =
    {
        slotpos = {},
        animbank = "ui_piggyback_2x6",
        animbuild = "ui_piggyback_2x6",
        pos = GLOBAL.Vector3(-5, -50, 0),
    },
    issidewidget = true,
    type = "pack",
}

for y = 0, 5 do
    table.insert(params.coolerpack.widget.slotpos, GLOBAL.Vector3(-162, -75 * y + 170, 0))
    table.insert(params.coolerpack.widget.slotpos, GLOBAL.Vector3(-162 + 75, -75 * y + 170, 0))
end

function params.coolerpack.itemtestfn(container, item, slot)
    -- if item.prefab == "spoiled_food" then
    --     return true
    -- end

    -- --Perishable
    -- if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
    --     return false
    -- end

    -- --Edible
    -- for k, v in pairs(GLOBAL.FOODTYPE) do
    --     if item:HasTag("edible_" .. v) then
    --         return true
    --     end
    -- end

    return true
end

AddRecipe("coolerpack", {
        Ingredient("manrabbit_tail", 4) --4
        , Ingredient("silk", 6),
        Ingredient("rope", 2)
    },
    RECIPETABS.SURVIVAL
    , TECH.NONE, nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/coolerpack.xml",
    "coolerpack.tex")
--beardlordpack
AddRecipe("beardlordpack", {
        Ingredient("manrabbit_tail", 4) --4
        , Ingredient("silk", 6),
        Ingredient("rope", 2)
        , Ingredient("beardhair", 2)
    },
    RECIPETABS.SURVIVAL
    , TECH.NONE, nil,
    nil,
    nil,
    nil,
    "wunny", "images/inventoryimages/beardlordpack.xml",
    "beardlordpack.tex")
--end of beardlordpack

--hutch_fishbowl
AddRecipe("hutch_fishbowl", {
        Ingredient("pondeel", 1) --4
        , Ingredient("nightmarefuel", 1),
        -- Ingredient("rope", 2)
        -- , Ingredient("beardhair", 2)
    },
    RECIPETABS.MAGIC_ONE
    , TECH.NONE, nil,
    nil,
    nil,
    nil,
    "wunny")
--fim

AddRecipe("armor_bramble", { Ingredient("log", 6), Ingredient("stinger", 3) }, RECIPETABS.WAR
    , TECH.NONE, nil,
    nil,
    nil,
    nil,
    "wunny")

AddRecipe("trap_bramble", { Ingredient("log", 1), Ingredient("stinger", 1) },
    RECIPETABS.WAR
    , TECH.NONE, nil,
    nil,
    nil,
    nil,
    "wunny")

local containers_widgetsetup_custom = containers.widgetsetup
local MAXITEMSLOTS = containers.MAXITEMSLOTS

AddPrefabPostInit("world_network", function(inst)
    if containers.widgetsetup ~= containers_widgetsetup_custom then
        OVERRIDE_WIDGETSETUP = true
        local containers_widgetsetup_base2 = containers.widgetsetup
        function containers.widgetsetup(container, prefab)
            containers_widgetsetup_base2(container, prefab)
            if container.type == "coolerpack" then
                container.type = "pack"
            end
        end
    end
    if containers.MAXITEMSLOTS < MAXITEMSLOTS then
        containers.MAXITEMSLOTS = MAXITEMSLOTS
    end
end)

-- AddPrefabPostInit("cave", function(inst)
--     inst:AddComponent("bunnykingmanager")
-- end)

-- AddPrefabPostInit("forest", function(inst)
--     inst:AddComponent("bunnykingmanager")
-- end)

--------------------------------------------------------------------------
--[[ slingshot ]]
--------------------------------------------------------------------------

-- local params = {}
-- local containers = { MAXITEMSLOTS = 0 }

-- containers.params = params

-- function containers.widgetsetup(container, prefab, data)
--     local t = data or params[prefab or container.inst.prefab]
--     if t ~= nil then
--         for k, v in pairs(t) do
--             container[k] = v
--         end
--         container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
--     end
-- end

-- params.slingshot =
-- {
--     widget =
--     {
--         slotpos =
--         {
--             Vector3(0,   32 + 4,  0),
--         },
--         slotbg =
--         {
--             { image = "slingshot_ammo_slot.tex" },
--         },
--         animbank = "ui_cookpot_1x2",
--         animbuild = "ui_cookpot_1x2",
--         pos = Vector3(0, 15, 0),
--     },
--     usespecificslotsforitems = true,
--     type = "hand_inv",
--     excludefromcrafting = true,
-- }

-- function params.slingshot.itemtestfn(container, item, slot)
-- 	return item:HasTag("slingshotammo")
-- end


-- for k, v in pairs(params) do
--     containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
-- end
--------------------------------------------------------------------------

-- The character select screen lines
STRINGS.CHARACTER_TITLES.wunny = "The Bunnylord, 2026"
STRINGS.CHARACTER_NAMES.wunny = "Wunny MODED"
STRINGS.CHARACTER_DESCRIPTIONS.wunny =
"*Transforms into a beardlord\n*Befriends bunnyman\n*Is a Vegetarian\n*Has some perks of others survivors... you will have to find out"
-- STRINGS.CHARACTER_QUOTES.wunny = "\"Quote\""
STRINGS.CHARACTER_SURVIVABILITY.wunny = "Grim"

--variables
TUNING.WUNNY_HUNGER_RATE = TUNING.WILSON_HUNGER_RATE * 0.5
TUNING.WUNNY_SPEED = 6
TUNING.WUNNY_RUNNING_HUNGER_RATE = 1
TUNING.BUNNYPACK_HUNGER = 1.15      --mudar para 1.1
TUNING.BEARDLORDPACK_HUNGER = 1.175 --mudar para 1.1
TUNING.WUNNY_QUICK_ACTION_HUNGER = -0.3
TUNING.WUNNY_BURROW_HUNGER_PER_DIST = 0.03 -- fome perdida por unidade de distância cavada
TUNING.WUNNY_BURROW_MIN_TRAVEL_DIST = 3    -- distância mínima pra valer a viagem (evita "viajar" pra toca ao lado)
TUNING.WUNNY_BURROW_MAP_SELECT_RADIUS = 4  -- raio de tolerância do clique no mapa em torno do ícone da toca
TUNING.WUNNY_BURROWDASH_SPEED_MULT = 1.6   -- multiplicador de velocidade da toca-relâmpago (fome sobe na mesma proporção)
TUNING.WUNNY_JUMPWALL_LANDING_DIST = 1.3   -- distância do centro da parede até o ponto de aterrissagem do outro lado
TUNING.WUNNY_JUMPWALL_SPEED = 7            -- velocidade do voo do salto de parede, em unidades/s (tempo no ar = distância / isto)
TUNING.WUNNY_BUNNYFOLLOWER_DAMAGE = 1      -- dano do coelho selvagem domesticado (cenoura) no combate "bate e foge"
-- TUNING.WUNNY_KING_
-- TUNING.SHADOWBUNNYMAN_ATTACK_PERIOD =
-- WUNNY_RUNNING_HUNGER_RATETUNNIN.WUNNY_IDLE_HUNGER_RATE = 1

---CUSTOM TUNINGS

TUNING.SNAKE_SPEED = 3
TUNING.SNAKE_TARGET_DIST = 8
TUNING.SNAKE_KEEP_TARGET_DIST = 15
TUNING.SNAKE_HEALTH = 100
TUNING.SNAKE_DAMAGE = 10
TUNING.SNAKE_ATTACK_PERIOD = 3
TUNING.SNAKE_POISON_CHANCE = 0.25
TUNING.SNAKE_POISON_START_DAY = 3            -- the day that poison snakes have a chance to show up
TUNING.SNAKEDEN_RELEASE_TIME = 5
TUNING.SNAKE_JUNGLETREE_CHANCE = 0.5         -- chance of a normal snake
TUNING.SNAKE_JUNGLETREE_POISON_CHANCE = 0.25 -- chance of a poison snake
TUNING.SNAKE_JUNGLETREE_AMOUNT_TALL = 2      -- num of times to try and spawn a snake from a tall tree
TUNING.SNAKE_JUNGLETREE_AMOUNT_MED = 1       -- num of times to try and spawn a snake from a normal tree
TUNING.SNAKE_JUNGLETREE_AMOUNT_SMALL = 1     -- num of times to try and spawn a snake from a small tree
TUNING.SNAKEDEN_MAX_SNAKES = 3
-- Custom speech strings
STRINGS.CHARACTERS.WUNNY = require "speech_wunny"

-- The character's name as appears in-game
STRINGS.NAMES.WUNNY = "Wunny"
STRINGS.SKIN_NAMES.wunny_none = "Wunny"

-- The skins shown in the cycle view window on the character select screen.
-- A good place to see what you can put in here is in skinutils.lua, in the function GetSkinModes
local skin_modes = {
    {
        type = "ghost_skin",
        anim_bank = "ghost",
        idle_anim = "idle",
        scale = 0.75,
        offset = { 0, -25 }
    },
}

--idk
local spacing = 2

GLOBAL.teste = function()
    print("teste")
end
--function of rabbithole recipe
local function rabbithole_recipe(ingredients, level)
    AddRecipe("rabbithole", ingredients, RECIPETABS.SURVIVAL, level,
        "rabbit_placer", spacing, nil, nil, "wunny", "images/inventoryimages/rabbithole.xml")
end

rabbithole_recipe({ Ingredient("carrot", 2), Ingredient("rabbit", 2), Ingredient("shovel", 1) }, TECH.NONE)
STRINGS.RECIPE_DESC.RABBITHOLE = "A new home for the rabbits."

--------------------------------------------------------------------------
--[[ wunny_burrow: rede de tocas para fast-travel ]]
--------------------------------------------------------------------------
AddRecipe("wunny_burrow", { Ingredient("carrot", 3), Ingredient("boards", 2), Ingredient("shovel", 1) },
    RECIPETABS.SURVIVAL, TECH.NONE,
    "rabbit_placer", spacing, nil, nil, "wunny", "images/inventoryimages/rabbithole.xml")
STRINGS.NAMES.WUNNY_BURROW = "Bunny Burrow"
STRINGS.RECIPE_DESC.WUNNY_BURROW = "Digs a hole home."

-- Ação de mapa: clicar com botão direito num "wunny_burrow" já descoberto faz
-- a Wunny cavar até lá instantaneamente. Mesmo padrão de plumbing usado pelas
-- ações de mapa do WX-78 (SWAPBODIES_MAP / MAPSCOUTSELECT_MAP): a ação só
-- fica disponível quando checkingmapactions está true (ver Wortox_GetPointSpecialActions
-- em wunny.lua) e a validade real é resolvida em maponly_checkvalidpos_fn.
local burrowtravel_map = GLOBAL.Action({
    instant = true,
    mount_valid = true,
    rmb = true,
    map_only = true,
    map_works_on_unexplored = true,
    closes_map = true,
    -- ArriveAnywhere é local a actions.lua (não é global de verdade); como só
    -- retorna true, inlinamos o mesmo comportamento aqui.
    customarrivecheck = function() return true end,
})
burrowtravel_map.id = "WUNNY_BURROWTRAVEL_MAP"
burrowtravel_map.str = "Cavar até aqui"
AddAction(burrowtravel_map)

GLOBAL.ACTIONS.WUNNY_BURROWTRAVEL_MAP.maponly_checkvalidpos_fn = function(act)
    if act.doer == nil or not act.doer:HasTag("wunny") then
        return false
    end

    local act_pos = act:GetActionPoint()
    if act_pos == nil then
        return false
    end

    local x, y, z = act_pos:Get()
    local mapent = GLOBAL.FindClosestMapIconInRange("wunny_burrow_network", x, y, z, TUNING.WUNNY_BURROW_MAP_SELECT_RADIUS, nil)
    if mapent == nil then
        return false, "NOTARGET"
    end

    x, y, z = mapent.Transform:GetWorldPosition()
    local px, py, pz = act.doer.Transform:GetWorldPosition()
    if not GLOBAL.IsTeleportingPermittedFromPointToPoint(px, py, pz, x, y, z) then
        return false
    end

    return true, nil, x, z, mapent
end

-- Salto de coelho: clicar com o botão direito numa parede de tier 1 ou
-- inferior (madeira, palha, pedra básica, ruínas básicas) faz a Wunny saltar
-- pro outro lado, sem precisar quebrar/rodear. Paredes reforçadas
-- (stone_2, ruins_2, moonrock, dreadstone, scrap) ficam de fora de propósito.
local WUNNY_JUMPABLE_WALLS = {
    wall_wood = true,
    wall_hay = true,
    wall_stone = true,
    wall_ruins = true,
}

local jumpwall_action = GLOBAL.Action({ rmb = true })
jumpwall_action.id = "WUNNY_JUMPWALL"
jumpwall_action.str = "Saltar"
AddAction(jumpwall_action)

-- Carregar as mãos ou estar montado tira o salto da mesa: as animações desses casos são
-- boat_jumpheavy_* / player_mount_boat_jump, que existem no bank wilson mas NÃO no
-- manrabbit. Em vez de o salto ficar quebrado só dentro da forma bunnyman, ele fica
-- indisponível nas duas — o que também é o que a mão espera de quem está com um baú nos
-- braços.
local function WunnyCanJumpWall(doer)
    local inv = doer.replica.inventory
    local rider = doer.replica.rider
    return doer:HasTag("wunny")
        and not doer:HasTag("playerghost")
        and not (inv ~= nil and inv:IsHeavyLifting())
        and not (rider ~= nil and rider:IsRiding())
end

AddComponentAction("SCENE", "workable", function(inst, doer, actions, right)
    if right and inst:HasTag("wall") and WUNNY_JUMPABLE_WALLS[inst.prefab]
        and WunnyCanJumpWall(doer) then
        table.insert(actions, GLOBAL.ACTIONS.WUNNY_JUMPWALL)
    end
end)

-- O deslocamento NÃO acontece aqui. Antes esta função dava um Physics:Teleport, e era
-- isso que fazia o salto parecer teleporte — não havia animação nenhuma. Agora o estado
-- "wunny_jumpwall" (scripts/wunny_jumpwall.lua) voa com boat_jump_* e chama esta fn ao
-- pousar; aqui só resta a validação, feita com a MESMA função de geometria que o estado
-- usa, para as duas pontas não poderem discordar.
GLOBAL.ACTIONS.WUNNY_JUMPWALL.fn = function(act)
    local doer = act.doer
    if doer == nil or not doer:HasTag("wunny") then
        return false
    end
    if GLOBAL.require("wunny_jumpwall").GetLanding(doer, act.target) == nil then
        return false, "NOTARGET"
    end
    return true
end

GLOBAL.ACTIONS.WUNNY_BURROWTRAVEL_MAP.fn = function(act)
    local valid, reason, act_posx, act_posz, mapent = GLOBAL.ACTIONS.WUNNY_BURROWTRAVEL_MAP.maponly_checkvalidpos_fn(act)
    if not valid then
        return valid, reason
    end

    local doer = act.doer
    if doer.components.hunger == nil then
        return false
    end

    local px, py, pz = doer.Transform:GetWorldPosition()
    local tx, ty, tz = mapent.Transform:GetWorldPosition()
    local dist = math.sqrt((tx - px) * (tx - px) + (tz - pz) * (tz - pz))

    if dist < TUNING.WUNNY_BURROW_MIN_TRAVEL_DIST then
        return false, "NOTARGET"
    end

    local hungercost = dist * TUNING.WUNNY_BURROW_HUNGER_PER_DIST
    if doer.components.hunger.current <= hungercost then
        if doer.components.talker ~= nil then
            doer.components.talker:Say("Estou com muita fome pra cavar até tão longe.")
        end
        return false
    end

    doer.components.hunger:DoDelta(-hungercost)

    if doer.Physics ~= nil then
        doer.Physics:Teleport(tx, ty, tz)
    else
        doer.Transform:SetPosition(tx, ty, tz)
    end

    if doer.SoundEmitter ~= nil then
        doer.SoundEmitter:PlaySound("dontstarve/common/together/teleport_sand/out")
    end

    return true
end

local cinnabunnfarm_recipe = AddRecipe("cinnabunnfarm", { Ingredient("boards", 3), Ingredient("guano", 3)}, RECIPETABS.FARM, TECH.NONE, "cinnabunnfarm_placer", 2.5, nil, nil, "wunny", "images/inventoryimages/cinnabunnfarm.xml" )
cinnabunnfarm_recipe.sortkey = -8112 -- Put at top

STRINGS.NAMES.CINNABUNNFARM = "Carrot Planter"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CINNABUNNFARM = {
	STUFFED = "That's a lot of carrots!",
	SOME = "It should keep growing now.",
	EMPTY = "A carrot to grow carrots in.",
	ROTTEN = "It needs some guano.",
	BURNT = "The carrot planter's roasted.",
	SNOWCOVERED = "I don't think it can grow in this cold.",
}
STRINGS.RECIPE_DESC.CINNABUNNFARM = "Grow your own carrots!"

--newbunnymanhouse
local function bunnyhouse_recipe(ingredientes, level)
    AddRecipe("newbunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "rabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

bunnyhouse_recipe(
    {
        Ingredient("carrot", 5),
        Ingredient("manrabbit_tail", 2)
        , Ingredient("boards", 2)
    , Ingredient("axe", 1)
    }, TECH.NONE)

--end newbunnyhouse

--bunnykinghouse
local function bunnykinghouse_recipe(ingredientes, level)
    AddRecipe("bunnykinghouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "kingrabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

bunnykinghouse_recipe(
    {
        Ingredient("carrot", 10),
        Ingredient("manrabbit_tail", 4)
        , Ingredient("boards", 4)
    }, TECH.NONE)

--end bunnykinghouse

--dwarfunnymanhouse
local function dwarfbunnyhouse_recipe(ingredientes, level)
    AddRecipe("dwarfbunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "dwarfrabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

dwarfbunnyhouse_recipe(
    {
        Ingredient("carrot", 3),
        Ingredient("manrabbit_tail", 2)
        , Ingredient("boards", 1)
    , Ingredient("axe", 1)
    , Ingredient("pickaxe", 1)
    }, TECH.NONE)

--end dwarfunnymanhouse

--everythingbunnyman house
local function everythingbunnyhouse_recipe(ingredientes, level)
    AddRecipe("everythingbunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "rabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

everythingbunnyhouse_recipe(
    {
        Ingredient("carrot", 5),
        Ingredient("manrabbit_tail", 2)
        , Ingredient("boards", 2)
    , Ingredient("axe", 1)
    , Ingredient("pickaxe", 1)
    , Ingredient("spear", 1)
    }, TECH.NONE)
--end everything

--start daybunny
local function day_recipe(ingredientes, level)
    AddRecipe("daybunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "rabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

day_recipe(
    {
        Ingredient("carrot", 5),
        Ingredient("manrabbit_tail", 2)
        , Ingredient("boards", 2)
    , Ingredient("axe", 1)
    , Ingredient("pickaxe", 1)
    , Ingredient("spear", 1)
    }, TECH.NONE)
--end daybunny

--start ultrabunnyman house
local function ultrabunnyhouse_recipe(ingredientes, level)
    AddRecipe("ultrabunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "rabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

ultrabunnyhouse_recipe(
    {
        Ingredient("carrot", 5),
        Ingredient("manrabbit_tail", 2)
        , Ingredient("boards", 2)
    , Ingredient("axe", 1)
    , Ingredient("pickaxe", 1)
    , Ingredient("spear", 1)
    , Ingredient("livinglog", 1)
    }, TECH.NONE)
--end ultragbunnyman house

--start shadowbunnyman house
local function shadowbunnyhouse_recipe(ingredientes, level)
    AddRecipe("shadowbunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "rabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

shadowbunnyhouse_recipe(
    {
        Ingredient("carrot", 5),
        Ingredient("manrabbit_tail", 1)
        -- , Ingredient("boards", 2)
        -- , Ingredient("axe", 1)
        , Ingredient("spear", 1)
    , Ingredient("beardhair", 1)
    , Ingredient("livinglog", 1)
    , Ingredient("nightmarefuel", 1)
    }, TECH.NONE)
--end ultragbunnyman house


--DEFAULT RABBIT HOUSE for crafting options
-- local function rabbithouse_recipe(ingredientes, level)
--     AddRecipe("rabbithouse", ingredientes, RECIPETABS.SURVIVAL, level,
--         "rabbithouse_placer", nil, nil, nil, "wunny")
-- end

-- rabbithouse_recipe(
--     {
--         Ingredient("carrot", 5),
--         Ingredient("manrabbit_tail", 2)
--         , Ingredient("boards", 2)
--     }, TECH.NONE)



AddRecipe("wunnyslingshot",
    {
        -- Ingredient("twigs", 2)
        -- ,
        Ingredient("mosquitosack", 1)
        , Ingredient("slingshot", 1)
    , Ingredient("livinglog", 1)
    , Ingredient("silk", 1)

    }, RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    -- "images/inventoryimages/slingshot.xml",
    nil,
    "slingshot.tex"
)


AddRecipe("lucy",
    {
        Ingredient("axe", 1),
        Ingredient("goldenaxe", 1),
        Ingredient("moonglassaxe", 1),
        Ingredient("livinglog", 1),
        Ingredient("nightmarefuel", 1),
    },
    RECIPETABS.SURVIVAL,
    TECH.MAGIC_ONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    nil,
    "lucy.tex")

AddRecipe("spear_wathgrithr",
    { Ingredient("twigs", 2), Ingredient("flint", 2), Ingredient("goldnugget", 2) },
    RECIPETABS.SURVIVAL, TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny")
AddRecipe("wathgrithrhat", { Ingredient("goldnugget", 2), Ingredient("rocks", 2) }, RECIPETABS.SURVIVAL, TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny")
-- AddRecipe("batbunny",
--     {
--         Ingredient("manrabbit_tail", 1)
--         -- , Ingredient("twigs", 2)
--         -- , Ingredient("meat", 2)
--     },
--     RECIPETABS.WAR,
--     TECH.NONE,
--     nil,
--     nil,
--     nil,
--     nil,
--     "wunny"
--     ,
--     "images/inventoryimages/bat_bunny.xml",
--     "bat_bunny.tex"
-- )

-- AddRecipe("hambat",
--     {
--         Ingredient("manrabbit_tail", 1)
--         , Ingredient("twigs", 2)
--         , Ingredient("meat", 2)
--     },
--     RECIPETABS.WAR,
--     TECH.NONE,
--     nil,
--     nil,
--     nil,
--     nil,
--     "wunny"
--     ,
--     "images/inventoryimages/bat_bunny.xml",
--     "bat_bunny.tex"
-- )
--sweing-tape
AddRecipe("sewing_tape",
    { Ingredient("silk", 1), Ingredient("cutgrass", 3) },
    RECIPETABS.SURVIVAL,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    nil,
    nil
)
--end of sweing tape
--catapult
AddRecipe("wunny_catapult",
    { Ingredient("sewing_tape", 1)
    , Ingredient("twigs", 3)
    , Ingredient("rocks", 15)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/winona_catapult.xml",
    "winona_catapult.tex")
--end catapult
--wunny_battery_low
AddRecipe("wunny_battery_low",
    { Ingredient("sewing_tape", 1)
    , Ingredient("log", 2)
    , Ingredient("nitre", 2)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/wunny_battery_low.xml",
    "wunny_battery_low.tex")
--end wunny_battery_low
--wunny_battery_high
AddRecipe("wunny_battery_high",
    { Ingredient("sewing_tape", 1)
    , Ingredient("boards", 2)
    , Ingredient("transistor", 2)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/wunny_battery_high.xml",
    "wunny_battery_high.tex")
--end wunny_battery_high
--wunny_spotlight
AddRecipe("wunny_spotlight",
    { Ingredient("sewing_tape", 1)
    , Ingredient("goldnugget", 2)
    , Ingredient("fireflies", 2)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/wunny_spotlight.xml",
    "wunny_spotlight.tex")
--end wunny_spotlight

AddRecipe("birchnuthat",
    { Ingredient("manrabbit_tail", 1)
    , Ingredient("rope", 1)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/birchnuthat.xml",
    "birchnuthat.tex")

AddRecipe("beardlordhat",
    { Ingredient("manrabbit_tail", 1)
    , Ingredient("rope", 1)
    , Ingredient("beardhair", 1)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/beardlordhat.xml",
    "beardlordhat.tex")


-- Willow
AddRecipe("lighter", { Ingredient("rope", 1), Ingredient("goldnugget", 1), Ingredient("petals", 3) },
    RECIPETABS.SURVIVAL, TECH.NONE, nil,
    nil,
    nil,
    nil,
    "wunny")
AddRecipe("bernie_inactive", { Ingredient("beardhair", 2), Ingredient("beefalowool", 2), Ingredient("silk", 2) },
    RECIPETABS.SURVIVAL, TECH
    .NONE, nil,
    nil,
    nil,
    nil,
    "wunny")

-- Wurt
AddRecipe("mermhouse_crafted", { Ingredient("boards", 4), Ingredient("cutreeds", 3), Ingredient("pondfish", 2) },
    RECIPETABS.SURVIVAL,
    TECH.SCIENCE_ONE, nil,
    nil,
    nil,
    nil,
    "wunny")
AddRecipe("mermthrone_construction", { Ingredient("boards", 5), Ingredient("rope", 5) },
    RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE,
    nil,
    nil,
    nil,
    nil,
    "wunny")
AddRecipe("mermwatchtower", { Ingredient("boards", 5), Ingredient("tentaclespots", 1), Ingredient("spear", 2) },
    RECIPETABS.SURVIVAL,
    TECH.SCIENCE_ONE, nil,
    nil,
    nil,
    nil,
    "wunny")
-- AddRecipe2("wurt_turf_marsh", { Ingredient("cutreeds", 1), Ingredient("spoiled_food", 2) }, TECH.NONE,
--     { builder_tag = "merm_builder", product = "turf_marsh", numtogive = 4 })

AddRecipe("mermhat", { Ingredient("pondfish", 1), Ingredient("cutreeds", 1), Ingredient("twigs", 2) },
    RECIPETABS.SURVIVAL, TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny")


--rabbitamulet
-- AddRecipe("rabbitamulet",
--     { Ingredient("manrabbit_tail", 1)
--         -- , Ingredient("rope", 1)
--         -- , Ingredient("beardhair", 1)
--     },
--     RECIPETABS.WAR,
--     TECH.NONE,
--     nil,
--     nil,
--     nil,
--     nil,
--     "wunny",
--     "images/inventoryimages/beardlordhat.xml",
--     "beardlordhat.tex")
--end of rabbitamulet
-- AddRecipe("bunnyback", { Ingredient("pigskin", 4), Ingredient("silk", 6), Ingredient("rope", 2) }, TECH.NONE)

--"bunnybat"
-- AddRecipe("bunnybat",
--     { Ingredient("manrabbit_tail", 1), Ingredient("twigs", 2), Ingredient("meat", 2) },
--     RECIPETABS.WAR,
--     TECH.SCIENCE_TWO,
--     nil,
--     nil,
--     nil,
--     nil,
--     "wunny",
--     "images/inventoryimages/ham_bat.xml",
--     "ham_bat.tex"
-- )
--end "bunnybat"
-- AddRecipe("bunnyback", { Ingredient("manrabbit_tail", 4), Ingredient("silk", 6), Ingredient("rope", 2) },
--     RECIPETABS.SURVIVAL, TECH.NONE)

-- AddRecipe("bunnyback", { Ingredient("rabbit", 1) },
--     RECIPETABS.SURVIVAL, TECH.NONE, nil,
--     nil,
--     nil,
--     nil,
--     "wunny","images/inventoryimages/coolerpack.xml")
-- local containers_widgetsetup_custom = containers.widgetsetup

-- AddRecipe("bunnyback", { Ingredient("manrabbit_tail", 4), Ingredient("silk", 6), Ingredient("rope", 2) },
-- RECIPETABS.SURVIVAL, TECH.NONE, nil,
-- nil,
-- nil,
-- nil,
-- "wunny", "images/inventoryimages/birchnuthat.xml",
-- "birchnuthat.tex")
AddRecipe2("madscience_lab_perkWunny",                          -- name
    { Ingredient("transistor", 2), Ingredient("cutstone", 2) }, -- ingredients
    TECH.NONE,                                                  -- tech
    {
        product = "madscience_lab",
        builder_tag = "wunny",
        placer = "madscience_lab_placer",
        nounlock = false,
        image = "madscience_lab.tex"
    },            -- config
    { "REWARD", } -- filters
)

AddRecipe2("wunnyicebox",
    { Ingredient("goldnugget", 4), Ingredient("gears", 2), Ingredient("cutstone", 2), Ingredient("bluegem", 2) },
    TECH.SCIENCE_TWO,
    { placer = "icebox_placer", min_spacing = 1.5, image = "icebox.tex" })


AddRecipe2("madscience_lab_perkWunny",                          -- name
    { Ingredient("transistor", 2), Ingredient("cutstone", 2) }, -- ingredients
    TECH.NONE,                                                  -- tech
    {
        product = "madscience_lab",
        builder_tag = "wunny",
        placer = "madscience_lab_placer",
        nounlock = false,
        image = "madscience_lab.tex"
    },            -- config
    { "REWARD", } -- filters
)

AddRecipe2("wunnyhambatwunny", { Ingredient("manrabbit_tail", 1), Ingredient("twigs", 2), Ingredient("meat", 2) },
    TECH.SCIENCE_TWO, {
        product = "hambat",
        builder_tag = "wunny",
        nounlock = false,
        image = "hambat.tex"
    },
    { "CHARACTER" }
-- { "REWARD", } -- filters )
)

AddRecipe2("wunnyumbrellawunny", { Ingredient("manrabbit_tail", 1), Ingredient("twigs", 6), Ingredient("silk", 2) },
    TECH.SCIENCE_TWO, {
        product = "umbrella",
        builder_tag = "wunny",
        nounlock = false,
        image = "umbrella.tex"
    },
    { "CHARACTER" }
-- { "REWARD", } -- filters )
)

AddRecipe2("wunnypickcane", {
        Ingredient("cane", 1),
        Ingredient("pickaxe", 1),
        Ingredient("goldenpickaxe", 1),
    },
    TECH.SCIENCE_TWO, {
        product = "wunnypickcane",
        builder_tag = "wunny",
        nounlock = false,
        image = "cane.tex"
    },
    { "CHARACTER" }
-- { "REWARD", } -- filters )
)

AddRecipe2("wunnyaxecane", {
        Ingredient("cane", 1),
        Ingredient("axe", 1),
        Ingredient("goldenaxe", 1),
    },
    TECH.SCIENCE_TWO, {
        product = "wunnyaxecane",
        builder_tag = "wunny",
        nounlock = false,
        image = "cane.tex"
    },
    { "CHARACTER" }
-- { "REWARD", } -- filters )
)

AddRecipe2("wunnypickaxecane", {
        Ingredient("cane", 1),
        Ingredient("wunnyaxecane", 1),
        Ingredient("wunnypickcane", 1),
    },
    TECH.SCIENCE_TWO, {
        product = "wunnypickaxecane",
        builder_tag = "wunny",
        nounlock = false,
        image = "cane.tex"
    },
    { "CHARACTER" }
-- { "REWARD", } -- filters )
)

AddRecipe2("wunnypicklucycane", {
        Ingredient("cane", 1),
        Ingredient("lucy", 1),
        Ingredient("wunnypickcane", 1),
    },
    TECH.SCIENCE_TWO, {
        product = "wunnypickaxecane",
        builder_tag = "wunny",
        nounlock = false,
        image = "cane.tex"
    },
    { "CHARACTER" }
-- { "REWARD", } -- filters )
)

-- AddRecipe2("wunnylivinglog", { Ingredient(CHARACTER_INGREDIENT.HEALTH, 20) },
--     TECH.MAGIC_ONE, {
--         product = "rabbit",
--         builder_tag = "wunny",
--         nounlock = false,
--         image = "rabbit.tex"
--     },
--     { "CHARACTER" }
-- -- { "REWARD", } -- filters )
-- )

AddRecipe2("wunnyrabbit", { Ingredient("log", 1), Ingredient("nightmarefuel", 1) },
    TECH.MAGIC_ONE, {
        product = "livinglog",
        builder_tag = "wunny",
        nounlock = false,
        image = "livinglog.tex"
    },
    { "CHARACTER" }
-- { "REWARD", } -- filters )
)


--WILSON TRANSMUTATION
AddRecipe2("wunnytransmute_log",
    { Ingredient("twigs", 3) },
    TECH.NONE,
    {
        product = "log",
        builder_tag = "wunny",
        -- description = "transmute_log",
        image = "log.tex",
    },
    { "CHARACTER", } -- filters
)
AddRecipe2("wunnytransmute_twigs", { Ingredient("log", 1) }, TECH.NONE,
    { product = "twigs", image = "twigs.tex", builder_tag = "wunny", description = "transmute_twigs", numtogive = 2 },
    { "CHARACTER", })
--
AddRecipe2("wunnytransmute_bluegem", { Ingredient("redgem", 2) }, TECH.NONE,
    { product = "bluegem", image = "bluegem.tex", builder_tag = "wunny", description = "transmute_bluegem" }
    ,
    { "CHARACTER", })
AddRecipe2("wunnytransmute_redgem", { Ingredient("bluegem", 2) }, TECH.NONE,
    { product = "redgem", image = "redgem.tex", builder_tag = "wunny", description = "transmute_redgem" },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_purplegem", { Ingredient("bluegem", 1), Ingredient("redgem", 1) }, TECH.NONE,
    { product = "purplegem", image = "purplegem.tex", builder_tag = "wunny", description = "transmute_purplegem" },
    { "CHARACTER", })

AddRecipe2("wunnytransmute_orangegem", { Ingredient("purplegem", 3) }, TECH.NONE,
    {
        product = "orangegem",
        image = "orangegem.tex",
        builder_tag = "wunny",
        description = "transmute_orangegem"
    },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_yellowgem", { Ingredient("orangegem", 3) }, TECH.NONE,
    {
        product = "yellowgem",
        image = "yellowgem.tex",
        builder_tag = "wunny",
        description = "transmute_yellowgem"
    },
    { "CHARACTER", })

AddRecipe2("wunnytransmute_greengem", { Ingredient("yellowgem", 3) }, TECH.NONE,
    { product = "greengem", image = "greengem.tex", builder_tag = "wunny", description = "transmute_greengem" },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_opalpreciousgem",
    { Ingredient("yellowgem", 1), Ingredient("orangegem", 1), Ingredient("greengem", 1), Ingredient("purplegem", 1),
        Ingredient("redgem", 1), Ingredient("bluegem", 1) }, TECH.NONE,
    {
        product = "opalpreciousgem",
        image = "opalpreciousgem.tex",
        builder_tag = "wunny",
        description = "transmute_opalpreciousgem"
    },
    { "CHARACTER", })
--
AddRecipe2("wunnytransmute_flint", { Ingredient("rocks", 3) }, TECH.NONE,
    { product = "flint", image = "flint.tex", builder_tag = "wunny", description = "transmute_flint" },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_rocks", { Ingredient("flint", 2) }, TECH.NONE,
    { product = "rocks", image = "rocks.tex", builder_tag = "wunny", description = "transmute_rocks" },
    { "CHARACTER", })

AddRecipe2("wunnytransmute_goldnugget", { Ingredient("nitre", 3) }, TECH.NONE,
    {
        product = "goldnugget",
        image = "goldnugget.tex",
        builder_tag = "wunny",
        description = "transmute_goldnugget"
    },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_nitre", { Ingredient("goldnugget", 2) }, TECH.NONE,
    { product = "nitre", image = "nitre.tex", builder_tag = "wunny", description = "transmute_nitre" },
    { "CHARACTER", })

AddRecipe2("wunnytransmute_marble", { Ingredient("cutstone", 2) }, TECH.NONE,
    { product = "marble", image = "marble.tex", builder_tag = "wunny", description = "transmute_marble" },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_cutstone", { Ingredient("marble", 1) }, TECH.NONE,
    { product = "cutstone", image = "cutstone.tex", builder_tag = "wunny", description = "transmute_cutstone" },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_moonrocknugget", { Ingredient("marble", 2) }, TECH.NONE,
    {
        product = "moonrocknugget",
        image = "moonrocknugget.tex",
        builder_tag = "wunny",
        description = "transmute_moonrocknugget"
    },
    { "CHARACTER", })
--
AddRecipe2("wunnytransmute_meat", { Ingredient("smallmeat", 3) }, TECH.NONE,
    { product = "meat", image = "meat.tex", builder_tag = "wunny", description = "transmute_meat" },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_smallmeat", { Ingredient("meat", 1) }, TECH.NONE,
    {
        product = "smallmeat",
        image = "smallmeat.tex",
        builder_tag = "wunny",
        description = "transmute_smallmeat",
        numtogive = 2
    },
    { "CHARACTER", })

AddRecipe2("wunnytransmute_beardhair", { Ingredient("beefalowool", 2) }, TECH.NONE,
    {
        product = "beardhair",
        image = "beardhair.tex",
        builder_tag = "wunny",
        description = "transmute_beardhair"
    },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_beefalowool", { Ingredient("beardhair", 2) }, TECH.NONE,
    {
        product = "beefalowool",
        image = "beefalowool.tex",
        builder_tag = "wunny",
        description = "transmute_beefalowool"
    },
    { "CHARACTER", })

AddRecipe2("wunnytransmute_boneshard", { Ingredient("houndstooth", 2) }, TECH.NONE,
    {
        product = "boneshard",
        image = "boneshard.tex",
        builder_tag = "wunny",
        description = "transmute_boneshard"
    },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_houndstooth", { Ingredient("boneshard", 2) }, TECH.NONE,
    {
        product = "houndstooth",
        image = "houndstooth.tex",
        builder_tag = "wunny",
        description = "transmute_houndstooth"
    },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_poop", { Ingredient("spoiled_food", 6) }, TECH.NONE,
    { product = "poop", image = "poop.tex", builder_tag = "wunny", description = "transmute_poop" },
    { "CHARACTER", })

AddRecipe2("wunnytransmute_horrorfuel", { Ingredient("dreadstone", 1) }, TECH.NONE,
    {
        product = "horrorfuel",
        image = "horrorfuel.tex",
        builder_tag = "wunny",
        description = "transmute_horrorfuel",
        numtogive = 2
    },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_dreadstone", { Ingredient("horrorfuel", 3) }, TECH.NONE,
    {
        product = "dreadstone",
        image = "dreadstone.tex",
        builder_tag = "wunny",
        description = "transmute_dreadstone"
    },
    { "CHARACTER", })
AddRecipe2("wunnytransmute_nightmarefuel", { Ingredient("horrorfuel", 1) }, TECH.NONE,
    {
        product = "nightmarefuel",
        image = "nightmarefuel.tex",
        builder_tag = "wunny",
        description = "transmute_nightmarefuel",
        numtogive = 2
    },
    { "CHARACTER", })

AddRecipe2("wunnyreeds", { Ingredient("cutgrass", 3) }, TECH.NONE,
    {
        product = "cutreeds",
        image = "cutreeds.tex",
        builder_tag = "wunny",
        description = "cutreeds",
        numtogive = 1
    },
    { "CHARACTER", })

AddRecipe2("wunnygrass", { Ingredient("cutreeds", 1) }, TECH.NONE,
    {
        product = "cutgrass",
        image = "cutgrass.tex",
        builder_tag = "wunny",
        description = "cutgrass",
        numtogive = 3
    },
    { "CHARACTER", })

AddRecipe2("wunnypigskin", { Ingredient("manrabbit_tail", 1) }, TECH.NONE,
    {
        product = "pigskin",
        image = "pigskin.tex",
        builder_tag = "wunny",
        description = "pigskin",
        numtogive = 1
    },
    { "CHARACTER", })

AddRecipe2("wunnymanrabbit_tail", { Ingredient("pigskin", 1) }, TECH.NONE,
    {
        product = "manrabbit_tail",
        image = "manrabbit_tail.tex",
        builder_tag = "wunny",
        description = "manrabbit_tail",
        numtogive = 1
    },
    { "CHARACTER", })
--add carrot to rabbithole drop
AddPrefabPostInit("rabbithole", function(inst)
    GLOBAL.MakeInventoryPhysics(inst)

    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    local dig_up_old = inst.components.workable.onfinish
    local function dig_up(inst, chopper)
        local dropChance = math.random(0, 1)
        if dropChance == 1 then
            inst.components.lootdropper:SpawnLootPrefab("carrot")
        end
        if dig_up_old ~= nil then
            dig_up_old(inst, chopper)
        end
    end

    inst.components.workable:SetOnFinishCallback(dig_up)

    -- Rede de tocas (fast-travel): todo rabbithole do mundo (selvagem ou
    -- construído) entra na mesma rede que wunny_burrow.lua usa, registrado
    -- sob o mesmo nome lógico "wunny_burrow_network" (ver
    -- FindClosestMapIconInRange em ACTIONS.WUNNY_BURROWTRAVEL_MAP). O ícone
    -- no mapa usa o mesmo "globalmapiconseeable" que o wormhole vanilla usa,
    -- já que MiniMapEntity não pode ser adicionado depois de SetPristine
    -- (não temos MiniMapEntity próprio no rabbithole, só essa entidade de
    -- rastreamento separada).
    GLOBAL.RegisterGlobalMapIcon(inst, "wunny_burrow_network")

    inst:DoTaskInTime(0, function(inst)
        inst.hiddenglobalicon = GLOBAL.SpawnPrefab("globalmapiconseeable")
        inst.hiddenglobalicon.MiniMapEntity:SetPriority(5)
        -- O ícone TEM que ir como 3º argumento do TrackEntity, não num SetIcon
        -- antes: TrackEntity (globalmapicon.lua:11) sempre define o ícone dele
        -- mesmo, e sem esse argumento cai no ramo final
        --     inst.MiniMapEntity:SetIcon(target.prefab..".png")
        -- porque o rabbithole vanilla não tem MiniMapEntity para o CopyIcon
        -- copiar. Isso pedia "rabbithole.png", que não existe em atlas nenhum,
        -- e o motor desenhava o xadrez magenta/ciano de textura faltando — era
        -- esse o bug, não o registro do atlas.
        --
        -- ".tex" e não ".png" porque é o nome do elemento em
        -- images/rabbit_hole.xml (arte do mod). O wormhole vanilla não passa
        -- ícone justamente porque ele TEM MiniMapEntity próprio.
        inst.hiddenglobalicon:TrackEntity(inst, nil, "rabbit_hole.tex")
    end)

    inst.OnRemoveEntity = function(inst)
        if inst.hiddenglobalicon ~= nil then
            inst.hiddenglobalicon:Remove()
        end
    end
end)

--------------------------------------------------------------------------
-- Coelho selvagem domesticado: se a Wunny der uma cenoura pra um "rabbit"
-- selvagem, ele passa a segui-la. Como follower, ele coleta twigs/cutgrass
-- de sapling/grass tuft perto e leva pra Wunny (entrega no inventário dela
-- se tiver menos de um stack do item, senão só solta perto). Se a Wunny
-- entrar em combate e não houver nada pra coletar por perto, ele ajuda a
-- lutar no estilo "bate e foge" (ver wunnybunnyfollowerbrain.lua).
--------------------------------------------------------------------------
local wunnybunnyfollowerbrain = require("brains/wunnybunnyfollowerbrain")

-- Tem que ser >= CARRY_FOLLOW_MAX da brain, senão o coelho "chega" na Wunny
-- (Follow retorna SUCCESS) sem nunca entrar no alcance de entrega.
-- Folga generosa sobre o CARRY_FOLLOW_MAX (2) da brain: a colisão com a Wunny
-- e com bichos em volta empurra o coelho um pouco, e se o alcance fosse justo
-- ele podia ficar oscilando na borda sem a entrega nunca disparar.
local WUNNY_BUNNY_DELIVER_DIST = 4
local WUNNY_BUNNY_LEADER_SEARCH_DIST = 30
local WUNNY_BUNNY_DEFAULT_STACK = 40

-- Entrega o que o coelho coletou. Fica num DoPeriodicTask, e não num nó da
-- brain, de propósito: a brain do rabbit é substituída inteira e qualquer nó
-- que falhe/seja resetado deixaria o item preso no inventário do coelho pra
-- sempre. Aqui a entrega só depende da distância até a Wunny.
local function TryDeliverToLeader(inst)
    local inventory = inst.components.inventory
    local leader = inst.components.follower ~= nil and inst.components.follower.leader or nil

    if inventory == nil or leader == nil or not leader:IsValid()
        or leader.components.inventory == nil
        or not inst:IsNear(leader, WUNNY_BUNNY_DELIVER_DIST) then
        return
    end

    local item = inventory:FindItem(function() return true end)
    if item == nil then
        return
    end

    local stacksize = item.components.stackable ~= nil and item.components.stackable.maxsize
        or WUNNY_BUNNY_DEFAULT_STACK
    local _, num_held = leader.components.inventory:Has(item.prefab, 1)

    if (num_held or 0) < stacksize then
        inventory:RemoveItem(item, true)
        leader.components.inventory:GiveItem(item)
    else
        -- Wunny já tem um stack cheio: só solta no chão (o coelho já está
        -- colado nela nesse ponto, então cai perto dela).
        inventory:DropItem(item, true)
    end
end

-- Rede de segurança pro vínculo com a Wunny: o componente follower vanilla
-- perde o leader em vários casos (reload, leader saindo do mundo, dano
-- acidental) e sem leader a brain inteira não tem pra quem entregar nem quem
-- seguir, e o coelho fica vagando com o item preso. Se ele foi recrutado,
-- reencontra a Wunny mais próxima e refaz o vínculo.
local function TryReacquireLeader(inst)
    if inst.components.follower == nil or inst.components.follower.leader ~= nil then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = GLOBAL.TheSim:FindEntities(x, y, z, WUNNY_BUNNY_LEADER_SEARCH_DIST,
        { "wunny" }, { "playerghost", "INLIMBO" })

    for _, wunny in ipairs(ents) do
        if wunny.components.leader ~= nil then
            wunny.components.leader:AddFollower(inst)
            print("[wunny] coelho follower reencontrou a Wunny:", tostring(wunny))
            return
        end
    end
end

local function SetUpWunnyBunnyFollower(inst)
    if inst.components.follower == nil then
        inst:AddComponent("follower")
    end
    -- Sem lealdade por tempo: o vínculo é permanente até a morte de um dos
    -- dois. neverexpire bloqueia StopFollowing, e KeepLeaderOnAttacked evita
    -- que um golpe acidental da Wunny (AoE, tentando acertar outra coisa)
    -- desfaça o recrutamento.
    inst.components.follower.neverexpire = true
    inst.components.follower:KeepLeaderOnAttacked()

    if inst.components.inventory == nil then
        inst:AddComponent("inventory")
    end
    inst.components.inventory.maxslots = 2

    inst:AddTag("wunnybunnyfollower")
    inst:SetBrain(wunnybunnyfollowerbrain)
    inst._wunny_recruited = true

    if inst._wunny_follower_task == nil then
        inst._wunny_follower_task = inst:DoPeriodicTask(0.5, function(inst)
            TryReacquireLeader(inst)
            TryDeliverToLeader(inst)
        end)
    end
end

local function RecruitWunnyBunnyFollower(inst, giver)
    if inst._wunny_recruited or giver == nil or giver.components.leader == nil then
        return
    end

    SetUpWunnyBunnyFollower(inst)
    giver.components.leader:AddFollower(inst)
    print("[wunny] coelho recrutado com cenoura; leader:",
        tostring(inst.components.follower.leader))
end

-- O stategraph vanilla do rabbit só tem actionhandler pra EAT e GOHOME; sem
-- isso o BufferedAction(ACTIONS.PICK) nunca chega a chamar PerformBufferedAction
-- e o coelho follower fica em loop indo até o sapling/grass tuft e voltando
-- pra Wunny sem nunca coletar. Reaproveita o estado genérico "action" (o
-- mesmo que GOHOME usa) pra rodar o PICK.
AddStategraphPostInit("rabbit", function(sg)
    sg.actionhandlers[GLOBAL.ACTIONS.PICK] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.PICK, "action")
end)

AddPrefabPostInit("rabbit", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("oneat", function(inst, data)
        if data ~= nil and data.food ~= nil and data.food.prefab == "carrot"
            and data.feeder ~= nil and data.feeder:HasTag("wunny") then
            RecruitWunnyBunnyFollower(inst, data.feeder)
        end
    end)

    -- Diagnóstico: confirma se o loot do PICK realmente entra no inventário do
    -- coelho (é o que a brain usa pra decidir entre coletar e entregar).
    inst:ListenForEvent("picksomething", function(inst, data)
        if inst._wunny_recruited then
            print("[wunny] coelho coletou:", data ~= nil and tostring(data.loot) or "nil",
                "| no inventario:",
                tostring(inst.components.inventory ~= nil
                    and inst.components.inventory:FindItem(function() return true end)))
        end
    end)

    -- OnPreLoad roda antes dos dados dos componentes serem aplicados, então o
    -- componente follower já existe quando Follower:OnLoad restaura o vínculo
    -- em cache com a Wunny.
    local old_onpreload = inst.OnPreLoad
    inst.OnPreLoad = function(inst, data)
        if old_onpreload ~= nil then
            old_onpreload(inst, data)
        end
        if data ~= nil and data.wunny_recruited then
            SetUpWunnyBunnyFollower(inst)
            print("[wunny] coelho follower restaurado do save")
        end
    end

    local old_onsave = inst.OnSave
    inst.OnSave = function(inst, data)
        if old_onsave ~= nil then
            old_onsave(inst, data)
        end
        if inst._wunny_recruited then
            data.wunny_recruited = true
        end
    end
end)

-- Tecla R: liga/desliga a "toca-relâmpago" da Wunny (ver ToggleBurrowDash em
-- wunny.lua). HasInputFocus() evita disparar enquanto o jogador está
-- digitando no chat/console.
GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_R, function()
    local player = GLOBAL.ThePlayer
    if player == nil or (player.HUD ~= nil and player.HUD:HasInputFocus()) then
        return
    end
    if player:HasTag("wunny") and player.ToggleBurrowDash ~= nil then
        player:ToggleBurrowDash()
    end
end)

-- AddPrefabPostInit("butterflywings", function(inst)
--     inst:AddComponent("edible")
--     inst.components.edible.foodtype = FOODTYPE.GOODIES
--n funciona
-- end)

local DidSkinnerPostInit = false
AddComponentPostInit("skinner", function(self, inst)
    -- Only do this if we haven't done this
    if DidSkinnerPostInit then return end
    DidSkinnerPostInit = true

    -- Make sure skinner is loaded first before attempting this
    local SetSkinsOnAnim_prev = GLOBAL.SetSkinsOnAnim
    GLOBAL.SetSkinsOnAnim = function(anim_state, prefab, base_skin, clothing_names, skintype, ...)
        if prefab == "wunny" and skintype ~= "ghost_skin" then
            skintype = "normal_skin"
        end
        return SetSkinsOnAnim_prev(anim_state, prefab, base_skin, clothing_names, skintype, ...)
    end
end)

-- A Wunny herda tanto o "dogrider" (Walter/Woby, badge de fome do Woby) quanto
-- o "strongman" (Wolfgang, badge de mightiness). O jogo vanilla nunca espera os
-- dois badges no mesmo personagem, então ambos caem na mesma posição
-- (column5, 20, 0) e ficam sobrepostos. Reposiciona o badge do Woby pra baixo
-- do badge de mightiness só pra Wunny.
AddClassPostConstruct("widgets/statusdisplays", function(self)
    if self.owner ~= nil and self.owner.prefab == "wunny" and self.pethungerbadge ~= nil then
        self.pethungerbadge:SetPosition(self.column5, -20, 0)
    end
end)


-- local containers_widgetsetup_custom = containers.widgetsetup

-- AddPrefabPostInit("world_network", function(inst)
--     if containers.widgetsetup ~= containers_widgetsetup_custom then
--         OVERRIDE_WIDGETSETUP = true
--         local containers_widgetsetup_base2 = containers.widgetsetup
--         function containers.widgetsetup(container, prefab)
--             containers_widgetsetup_base2(container, prefab)
--             if container.type == "bunnypack" then
--                 container.type = "pack"
--             end
--         end
--     end

-- end)
-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
local function NewQuickAction(inst, action)
    -- if action.target ~= nil and action.target.prefab == "berrybush_juicy" then return "dojostleaction" end
    -- local quick = false
    -- if inst and inst:HasTag("wunny") then
    --     quick = true
    -- end
    -- if quick then
    --     return "doshortaction"
    -- else
    --     return "dolongaction"
    -- end

    if inst and inst:HasTag("wunny") then
        return "doshortaction"
    end

    return (inst.replica.rider ~= nil and inst.replica.rider:IsRiding() and "dolongaction")
        or (action.target:HasTag("jostlepick") and "dojostleaction")
        or (action.target:HasTag("quickpick") and "doshortaction")
        or (inst:HasTag("fastpicker") and "doshortaction")
        or (inst:HasTag("quagmire_fasthands") and "domediumaction")
        or "dolongaction"
end

-- AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.PICK, NewQuickAction))
-- AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TAKEITEM, NewQuickAction))
-- AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.HARVEST, NewQuickAction))
-- AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.PICK, NewQuickAction))
-- AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.TAKEITEM, NewQuickAction))
-- AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.HARVEST, NewQuickAction))

-- local function GetGameMode(game_mode)
--     return GAME_MODES[game_mode] or GameModeError(game_mode)
-- end

-- function IsRecipeValidInGameMode(game_mode, recipe_name)
--     local invalid_recipes = GetGameMode(game_mode).invalid_recipes
--     return not table.contains(invalid_recipes, recipe_name)
-- end

-- function GetValidRecipe(recname)
--     if not IsRecipeValidInGameMode(TheNet:GetServerGameMode(), recname) then
--         return
--     end
--     local rec = AllRecipes[recname]
--     return rec ~= nil and not rec.is_deconstruction_recipe and (rec.require_special_event == nil or IsSpecialEventActive(rec.require_special_event)) and rec or nil
-- end

--------------------------------------------------------------------------
--[[ Transformacao em bunnyman: estados e bloqueios no SGwilson ]]
--------------------------------------------------------------------------
-- O remendo e' ADITIVO de proposito: acrescenta estados novos e REDIRECIONA
-- handlers, em vez de reescrever corpo de estado vanilla (o "attack" do SGwilson
-- sozinho tem ~200 linhas e e' mexido a cada patch do jogo).
--
-- GLOBAL.require porque wunny_bunnyform.lua roda no ambiente global (e' required
-- por prefabs/wunny.lua), nao no ambiente do modmain.
AddStategraphPostInit("wilson", function(sg)
    -- local actionhandler = GLOBAL.ActionHandler(GLOBAL.ACTIONS.PICK, NewQuickAction)
    sg.actionhandlers[GLOBAL.ACTIONS.PICK] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.PICK, function(inst, action)
        if inst and inst:HasTag("wunny") then
            inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER) --testando issoo
            return "doshortaction"
        end

        return (inst.components.rider ~= nil and inst.components.rider:IsRiding() and "dolongaction")
            or (action.target ~= nil
                and action.target.components.pickable ~= nil
                and ((action.target.components.pickable.jostlepick and "dojostleaction") or
                    (action.target.components.pickable.quickpick and "doshortaction") or
                    (inst:HasTag("fastpicker") and "doshortaction") or
                    (inst:HasTag("quagmire_fasthands") and "domediumaction") or
                    "dolongaction"))
            or nil
    end)
    sg.actionhandlers[GLOBAL.ACTIONS.TAKEITEM] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.TAKEITEM, function(inst, action)
        if inst and inst:HasTag("wunny") and action.target ~= nil and action.target.takeitem ~= nil then
            inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER)
            return "doshortaction"
        end
        return action.target ~= nil
            and action.target.takeitem ~= nil --added for quagmire
            and "give"
            or "dolongaction"
    end)
    sg.actionhandlers[GLOBAL.ACTIONS.HARVEST] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.HARVEST, function(inst)
        if inst and inst:HasTag("wunny") then
            inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER)
            return "doshortaction"
        end
        return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
    end)
    sg.actionhandlers[GLOBAL.ACTIONS.COOK] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.COOK, function(inst, action)
        if inst:HasTag("wunny") then
            inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER)
            return "doshortaction"
        end
        return inst:HasTag("expertchef") and "domediumaction" or "dolongaction"
    end)
    sg.actionhandlers[GLOBAL.ACTIONS.REPAIR] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.REPAIR, function(inst, action)
        if inst:HasTag("wunny") then
            inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER)
            return "doshortaction"
        end
        return action.target:HasTag("repairshortaction") and "doshortaction" or "dolongaction"
    end)
    sg.actionhandlers[GLOBAL.ACTIONS.MANUALEXTINGUISH] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.MANUALEXTINGUISH,
        function(inst)
            if inst:HasTag("wunny") then
                inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER)
                return "doshortaction"
            end
            return inst:HasTag("pyromaniac") and "domediumaction" or "dolongaction"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.SHAVE] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.SHAVE, function(inst, action)
        if inst:HasTag("wunny") then
            inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER)
            return "doshortaction"
        end
        return "dolongaction"
    end)
    sg.actionhandlers[GLOBAL.ACTIONS.EAT] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.EAT,
        function(inst, action)
            if inst.sg:HasStateTag("busy") then
                return
            end
            local obj = action.target or action.invobject
            if obj == nil then
                return
            elseif obj.components.edible ~= nil then
                if not inst.components.eater:PrefersToEat(obj) then
                    inst:PushEvent("wonteatfood", { food = obj })
                    return
                end
            elseif obj.components.soul ~= nil then
                if inst.components.souleater == nil then
                    inst:PushEvent("wonteatfood", { food = obj })
                    return
                end
            else
                return
            end


            if inst:HasTag("wunny") then
                inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER)
                return "quickeat"
            end

            if obj.components.soul ~= nil
            then
                return "eat"
            end

            if FOODTYPE ~= nil and FOODTYPE.MEAT ~= nil and obj.components.edible.foodtype == FOODTYPE.MEAT
            then
                return "eat"
            end

            return "quickeat"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.HEAL] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.HEAL, function(inst, action)
        if inst:HasTag("wunny") then
            inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER)
            return "doshortaction"
        end
        return "dolongaction"
    end)
    sg.actionhandlers[GLOBAL.ACTIONS.FEED] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.FEED, function(inst, action)
        if inst:HasTag("wunny") then
            inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER)
            return "doshortaction"
        end
        return "dolongaction"
    end)
    sg.actionhandlers[GLOBAL.ACTIONS.BUILD] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.BUILD, function(inst, action)
        -- local rec = GetValidRecipe(action.recipe)
        if inst:HasTag("wunny") then
            inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER * 2)
            return "doshortaction"
        end
        return
        -- (rec ~= nil and rec.sg_state)
        -- or
            (inst:HasTag("wunny") and "doshortaction")
            or (inst:HasTag("hungrybuilder") and "dohungrybuild")
            or (inst:HasTag("fastbuilder") and "domediumaction")
            or (inst:HasTag("slowbuilder") and "dolongestaction")
            or "dolongaction"
    end)
    sg.actionhandlers[GLOBAL.ACTIONS.MURDER] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.MURDER,
        function(inst)
            if inst:HasTag("wunny") then
                inst.components.hunger:DoDelta(TUNING.WUNNY_QUICK_ACTION_HUNGER)
                return "doshortaction"
            end
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end)
    -- sg.actionhandlers[GLOBAL.ACTIONS.FERTILIZE] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.FERTILIZE, function(inst, action)
    --     return (action.target ~= nil and action.target ~= inst and "doshortaction")
    --         or (action.invobject ~= nil and action.invobject:HasTag("slowfertilize") and "fertilize")
    --         or "fertilize_short"
    -- end)
end)

-- Estados do salto de parede. Tem que vir DEPOIS do bloco acima (que reescreve
-- sg.actionhandlers sem encadear) e ANTES do bunnyform (que embrulha todos os handlers
-- para desviá-los na forma, e precisa achar este já registrado).
AddStategraphPostInit("wilson", function(sg)
    GLOBAL.require("wunny_jumpwall").PatchStategraph(sg)
end)

-- IMPORTANTE: o patch da forma bunnyman tem que vir DEPOIS do bloco acima. Aquele
-- bloco reescreve sg.actionhandlers[...] direto, sem encadear o handler anterior, então
-- se o bunnyform for aplicado antes ele é simplesmente apagado para PICK/HARVEST/
-- BUILD/COOK/etc. O bunnyform encadeia o handler antigo, então nesta ordem os dois
-- convivem: fora da forma vale o handler da Wunny normal, dentro vale o da forma.
AddStategraphPostInit("wilson", function(sg)
    GLOBAL.require("wunny_bunnyform").PatchStategraph(sg)
end)

AddStategraphPostInit("wilson_client", function(sg)
    GLOBAL.require("wunny_bunnyform").PatchClientStategraph(sg)
end)

-- AddStategraphPostInit("wilson", ActionHandler(ACTIONS.TAKEITEM, NewQuickAction))
-- AddStategraphPostInit("wilson", ActionHandler(ACTIONS.HARVEST, NewQuickAction))
-- AddStategraphPostInit("wilson_client", ActionHandler(ACTIONS.PICK, NewQuickAction))
-- AddStategraphPostInit("wilson_client", ActionHandler(ACTIONS.TAKEITEM, NewQuickAction))
-- AddStategraphPostInit("wilson_client", ActionHandler(ACTIONS.HARVEST, NewQuickAction))
GLOBAL.package.loaded["stategraphs/SGwilson"] = nil

AddModCharacter("wunny", "MALE", skin_modes)
