# K2SO Rat's Fixes

A collection of fixes for [Krastorio 2](https://mods.factorio.com/mod/Krastorio2) +
Space Age with [Krastorio 2 Spaced Out](https://mods.factorio.com/mod/Krastorio2-spaced-out),
its [tweaks mod](https://mods.factorio.com/mod/Krastorio2-spaced-out-tweaks) and
the nulls-k2so-tweaks / xy-k2so-enhancements-nulls-fork patch mods found
bugged by a stack audit (see the changelog and `patches/upstream/README.md`).
The headline fix remains: crafted biomass no longer inherits parent spoilage,
so the recursive biomass loop in the bioprocessing facility keeps itself
fresh instead of rotting the whole bio pipeline at once.

## The problem

With the tweaks mod, `kr-biomass` spoils (1 hour into spoilage). The
bioprocessing facility's `kr-biomass` recipe is **recursive** (2 biomass +
petroleum gas + oxygen → 5 biomass), and Factorio makes crafted items
**inherit the parent spoilage**. Measured end-to-end on Factorio 2.1.20 with
the real mods (see `tests/`):

- seed the loop with 90 % spoiled biomass → the crafted output comes out at
  **91.7 % spoiled**, the next loop cycle at **93.3 %** — freshness can only
  go down;
- the inherited `spoil_tick` is absolute, so the whole stock expires at the
  same moment and the loop eventually consumes only-almost-dead biomass.

Since military science needs biomass (`kr-biter-research-data`), the bio
pipeline stalls.

The tweaks mod already tries to fix this by setting
`reset_freshness_on_craft = true` on the biomass *item*, but in Factorio 2.1
that property belongs to the recipe *product* (`ItemProductPrototype`), so it
is a silent no-op.

## What it changes

`data-final-fixes.lua` sets `always_fresh = true` (+ `percent_spoiled = 0`) on
every recipe product that is biomass or fertilizer crafted from spoiling
inputs:

| Recipe | Product | Before | After |
|---|---|---|---|
| `kr-biomass` (recursive, bioprocessing facility) | biomass | inherits parent spoilage | full 1 h timer |
| `kr-biter-biomass`, `kr-pentapod-biomass` (egg crushing) | biomass | inherits egg spoilage | full 1 h timer |
| `kr-fertilizer` (crafted from biomass) | fertilizer | inherits biomass spoilage | full 5 h timer |
| `kr-biomass-from-spoilage` (biochamber: jelly + spoilage) | biomass | inherits jelly spoilage | full 1 h timer |
| `kr-jellynut`, `kr-yumako` (K2SO greenhouses, from fertilizer) | jellynut / yumako | inherits fertilizer spoilage | full 1 h timer |

Verified end-to-end: with the fix, crafting from 90 % spoiled seed biomass
produces output with `spoil_tick = craft_tick + 216000` (a full 1 h timer),
on every loop cycle.

`fixes/` additionally compensates, at data-final-fixes time, audit findings in
the surrounding mods (each with an e2e under `tests/proto/` or `tests/lua/`):

- **asteroid-radioactive-resistance** — keeps K2SO's 100% `kr-radioactive`
  asteroid immunity from being silently erased by nulls-k2so-tweaks'
  standardize pass; duplicate entries are merged. The target percent is
  configurable via the `k2so-rats-fixes-asteroid-radiation-immunity`
  startup setting; `auto` (default) keeps 100% and uses 50% when
  eRisel-k2-arsenal (kr-radioactive weapons) is installed.
- **maraxsis-sand-item-name** — writes maraxsis' `SAND_ITEM_NAME` into the
  mod-data `.data` table it is actually read from, instead of the prototype
  root nulls writes it to; removes the stray root key.
- **lab-icons-positioning** — applies K2SO's own (shadowed, never active)
  widened lab icon layout once more than 24 science packs are in play.
- **spoil-migration-cycles** — breaks two-item spoil cycles that nulls'
  always-true replace_all guard would create when a replacement item
  spoils back into the old one.
- **advanced-centrifuge-atom-forge** — applies xy's computed-but-unused
  `ingred1` (2x atan-atom-forge) so recipe and tech tree agree.
- **cerys-transceiver-restrictions** — removes accumulator-type blanket
  surface restrictions (e.g. Cerys' ambient radiation) from the K2
  intergalactic transceiver, mirroring nulls' teleporter unrestrict; keeps
  K2SO's own gravity rule. No-op without such conditions.
- **greenhouse-plus-k2-glass** — unifies k2-greenhouse-plus' private
  `k2gp-sand`/`k2gp-glass` chain into K2's identical `kr-sand`/`kr-glass`
  when the mod provides its own glass (its default): greenhouse building
  recipes take 20x `kr-glass` (the rate the greenhouse-plus author sets for
  K2 glass), the duplicate sand/glass recipes and their technology unlocks
  are removed, and the orphaned k2gp items are hidden rather than deleted so
  existing saves keep anything already crafted. Configurable via the
  `k2so-rats-fixes-greenhouse-plus-k2-glass` startup setting (on by
  default); respects the other mod's own glass-source setting when set to
  "other"/"disabled".
- **greenhouse-plus-tech-unlocks** — re-attaches k2-greenhouse-plus' tree
  greenhouse unlock to the surviving `kr-greenhouse` technology: k2gp hooks
  it onto K2's technology, which K2SO replaces in its final fixes,
  discarding the hook - measured on the real stack, no technology unlocked
  the greenhouse, leaving it uncraftable. The Gleba greenhouse variants
  hook onto base Space Age technologies and are unaffected.
- **matter-spoilage-productivity** — disables productivity on the tweaks
  mod's `kr-spoilage-to-matter` (100 spoilage → 5.2 matter). Its exact
  quantity mirror `kr-matter-to-spoilage` already disallows productivity,
  so with productivity modules in the matter plant (4 slots, productivity
  allowed) every round trip multiplies the stock: ×1.4 per cycle with four
  module 3s, compounding - a closed amplification loop turning a seed of
  spoilage into free exponential matter (and matter converts into
  everything). K2's own matter library never enables productivity on
  conversion recipes; the sink itself keeps working, it just cannot be
  amplified into a matter printer anymore.

`patches/upstream/` carries ready-to-apply patches for the same issues in
the original mods, where forensics credits belong.

Without the K2SO stack installed this mod does nothing.

## Installation

`make install` packages the mod and copies the zip into your Factorio mods
directory, or copy `releases/k2so-rats-fixes_*.zip` there manually.

## Testing

```
make test-e2e
```

```
make test-e2e              # gameplay benchmark (biomass pipeline)
make test-e2e-greenhouse   # gameplay benchmark (greenhouse crafting + recycling)
make test-proto            # data-stage checks for every fixes/* entry
make test-lua      # lua-level checks against the real xy fork zip
make test-patches  # patches/upstream apply-check against installed zips
make lint          # luacheck (needs the lua@5.4 build, see .luacheckrc)
```

Runs the real game headless (no window) against the full K2SO mod stack
from your mods directory (both tweaks mods, the nulls fork enhancements
and PlanetsLib included), fully isolated in a temp work dir:

- **Phase A** (no fix): places a powered bioprocessing facility, seeds it
  with 90 % spoiled biomass, crafts, measures the output — expects the
  inheritance to reproduce (`BUG_REPRODUCED`);
- **Phase B** (with fix): same setup — expects fully fresh output (`FIXED`).

The test uses `--scenario2map` + `--benchmark`, writes a JSON report and
exits non-zero on any mismatch.

## Notes

- Safe to add or remove on existing saves: the biomass part only changes
  recipe product properties; the greenhouse-plus unification hides its two
  duplicate items (already-crafted ones survive) and removes only the
  duplicate recipes, so toggling it mid-save is also safe.
- Biomass already sitting on belts or in chests keeps its current age; only
  newly crafted biomass spawns fresh. The loop flushes itself out after a
  few cycles.
- If biomass spoilage is disabled in the tweaks mod's startup settings, this
  mod is simply a no-op.
