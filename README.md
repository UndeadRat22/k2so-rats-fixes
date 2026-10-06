# K2SO Rat's Fixes

A collection of fixes for [Krastorio 2](https://mods.factorio.com/mod/Krastorio2) +
Space Age with [Krastorio 2 Spaced Out](https://mods.factorio.com/mod/Krastorio2-spaced-out)
and its [tweaks mod](https://mods.factorio.com/mod/Krastorio2-spaced-out-tweaks).
Currently one fix: crafted biomass no longer inherits parent spoilage, so the
recursive biomass loop in the bioprocessing facility keeps itself fresh instead
of rotting the whole bio pipeline at once.

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

Verified end-to-end: with the fix, crafting from 90 % spoiled seed biomass
produces output with `spoil_tick = craft_tick + 216000` (a full 1 h timer),
on every loop cycle.

Without the K2SO stack installed this mod does nothing.

## Installation

`make install` packages the mod and copies the zip into your Factorio mods
directory, or copy `releases/k2so-rats-fixes_*.zip` there manually.

## Testing

```
make test-e2e
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

- Safe to add or remove on existing saves: it only changes recipe product
  properties, no prototypes are added, removed or renamed.
- Biomass already sitting on belts or in chests keeps its current age; only
  newly crafted biomass spawns fresh. The loop flushes itself out after a
  few cycles.
- If biomass spoilage is disabled in the tweaks mod's startup settings, this
  mod is simply a no-op.
