# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Don't Starve Together (DST) character mod adding **Wunny**, a rabbit-like character whose kit deliberately
reimplements abilities from most of the vanilla DST cast (Wilson's beard, Wolfgang's mighty form, WX-78's
battery/charge system, Wickerbottom's books, Wortox's soul mechanics, Wormwood, Walter's slingshot/Woby,
Wurt's merm stuff, Warly's cooking, Winona's structures, etc.) plus an original "bunny army" companion
system (bunnyman variants, bunny houses, a bunny king). This is a data/script mod for the game, not a
standalone application — there is no build system, package manager, or test suite. Lua files are loaded
directly by the DST engine at runtime.

## Running / testing changes

There is no compiler or test runner for this project. To verify a change:
1. The mod folder must live under DST's `mods/` directory (it already does — this *is* that folder).
2. Launch Don't Starve Together, enable the mod, and load a save/host a server with Wunny as the character.
3. Watch the in-game console / `mods_log.txt` (or the client/server log) for Lua errors — this is the
   primary feedback loop, there's no static analysis step.
4. `print()` statements are used throughout the existing code (e.g. `wunny.lua`) as ad-hoc debug logging;
   follow that convention when adding temporary diagnostics rather than introducing a new logging system.

### Reference: vanilla game scripts

The mod frequently reimplements or calls into vanilla DST component/API behavior. When touching game logic,
verify method signatures, event names, and component semantics against the actual shipped game scripts
rather than assuming — DST's modding API has no official docs site. The vanilla scripts can be extracted
from the game install's data bundle:
`<DST install>/data/databundles/scripts.zip` → unzip to get `scripts/scripts/**/*.lua`
(components, prefabs for every vanilla character, stategraphs, brains, etc.). Comparing the mod's
reimplementation of a vanilla character's ability against that character's own vanilla prefab file
(e.g. `prefabs/walter.lua`, `prefabs/wx78.lua`, `prefabs/willow.lua`) is the fastest way to catch copy-paste
mistakes.

## Architecture

### Entry points
- **`modinfo.lua`** — mod metadata (name, version, API version, DST-only compatibility, server tags).
- **`modmain.lua`** (~1500 lines) — the mod's single entry point. Contains, in rough order:
  - `PrefabFiles` — the list of prefab script files (from `scripts/prefabs/`) the engine should load.
    A file must be listed here to be registered as a prefab, even if the `.lua` file exists.
  - `Assets` — global asset preloads (textures/atlases/anims) needed outside individual prefab files.
  - Recipe definitions (`AddRecipe` / `AddRecipe2`) for Wunny's custom items/structures/transmute recipes.
  - `AddPrefabPostInit`, `AddComponentPostInit`, `AddStategraphPostInit` hooks that patch vanilla
    prefabs/components/stategraphs (e.g. patching `world_network`, `rabbithole`, the `skinner` component,
    build-action speed for Wunny specifically via `inst:HasTag("wunny")` checks in stategraph action
    handlers).
  - `STRINGS.CHARACTERS.WUNNY = require "speech_wunny"` — wires up the character's speech strings.
  - `AddModCharacter("wunny", "MALE", skin_modes)` at the very end — registers Wunny as a playable character.

### Character logic
- **`scripts/prefabs/wunny.lua`** (~2300 lines) — the character itself. This is the most important and most
  frequently touched file. It composes ability blocks lifted from many vanilla characters (WX-78 charge
  system, Walter sanity-from-damage, Willow-style fire sanity aura, book/research bonuses, etc.) into one
  prefab. Because of this, bugs are often "leftover from the source character" — a variable, tag, or
  multiplier copied from the original ability that doesn't match Wunny's context. When editing behavior
  here, check whether the surrounding code is a near-verbatim port of a vanilla character function before
  assuming it's original.
  - A `DoPeriodicTask` in the character's fn (runs every 0.2s) scans nearby entities via
    `TheSim:FindEntities` to detect nearby bunny-army units, research/craft stations, etc., and mutate them
    (befriend, apply/remove tags, adjust builder bonuses). This loop uses `if/elseif` chains keyed on
    `v.prefab` — when adding a new case, add it as another `elseif` branch; do not `break` out of the
    `for k, v in pairs(ents)` loop from inside a single-entity branch, since that aborts the scan for every
    other entity found that tick, not just the current one.
  - Some behavior is deliberately intensified beyond vanilla tuning (e.g. `wunnypickaxecane.lua`'s
    `TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY * 20`) — don't "fix" these back to vanilla values without
    confirming with the user first, they can be intentional power budget choices for this character.

### The bunny army / companion system
`scripts/prefabs/` contains a large family of bunny-themed companion prefabs beyond Wunny itself:
bunnyman variants (`bunnyman`, `newbunnyman`, `daybunnyman`, `dwarfbunnyman`, `everythingbunnyman`,
`ultrabunnyman`, `shadowbunnyman`), their matching houses (`*bunnyhouse.lua`), a `bunnyking` +
`bunnykingmanager` + `bunnykinghouse` (a leader/upgrade system, parallel to vanilla's Pig King), and
`wunnywalrus` (a walrus-form companion with its own brain in `scripts/brains/wunnywalrusbrain.lua`).
Matching stategraphs live in `scripts/stategraphs/SG*.lua` and brains in `scripts/brains/`.
`scripts/globalFunctions/globalFunctions.lua` holds shared helper functions used across these prefabs.

### Custom gear
Wunny-specific tools/structures live alongside the character files in `scripts/prefabs/`:
`wunnyaxecane`, `wunnypickcane`, `wunnypickaxecane(lantern)` (multitools), `wunnyslingshot` (a Walter-style
slingshot; `wunnyslingshotcopy.lua` is an unfinished duplicate, not wired into `PrefabFiles` — leave it
alone unless asked to finish it), `wunnyicebox`, `wunnyrabbithouse`, and a set of Winona-styled structures
(`wunny_catapult`, `wunny_spotlight`, `wunny_battery_low`, `wunny_battery_high`). These structures'
**appearance is intentionally Winona's** (bank/build/atlas/icon reused from `winona_*` assets) — that's a
deliberate art choice, don't rename those to `wunny_*` assets. Their *recipe names* are still `wunny_*`
(registered via `AddRecipe` in `modmain.lua`), so any logic comparing against recipe/prefab names (deploy
helper filters, `recipename ==` checks) must use the `wunny_*` names, not the `winona_*` ones used for
assets.

### Speech
**`scripts/speech_wunny.lua`** (~3000 lines) — the full `STRINGS.CHARACTERS.WUNNY` speech table (examine
lines, action failure strings, etc.), required by every vanilla and modded action/item Wunny can interact
with. Missing keys here surface as nil-string errors at the point the game tries to display that specific
line, not at load time, so they're easy to miss without in-game testing of the specific action.
