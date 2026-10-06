# Upstream patches

Patch files intended for the respective mod repositories, produced during
the k2so-rats-fixes audit (see root README / audit notes). Each applies
against the version of the mod pinned in `mod-list.json` development set;
`tests/check-upstream-patches.sh` dry-runs all of them.

## nulls-k2so-tweaks

- `maraxsis-sand-item-name.patch` — `SAND_ITEM_NAME` was assigned to the
  mod-data prototype root; maraxsis reads `constants.data.SAND_ITEM_NAME`.
  Latent no-op today (maraxsis' default is already `"sand"`). Runtime
  compensation ships in `fixes/maraxsis-sand-item-name.lua`.
- `item-util-spoil-guard-and-log-spam.patch` — `replace_all` compared a
  spoil_result string to a prototype table (always true); compare against
  `old` (the old item name) instead. Also stops logging "does not exist"
  for every stack-size entry of uninstalled mods (hundreds of lines per
  load; real messages get buried).
- `copy-resistance-nil-guard.patch` — `copy_resistance_type` crashed on
  asteroid prototypes with no `resistances` table.

## Krastorio2-spaced-out

- `labs-icons-positioning.patch` — the `> 24 packs` widened icon layout was
  shadowed by block-local `size3/5/8` declarations and never applied.
  Runtime compensation ships in `fixes/lab-icons-positioning.lua`.
- `asteroid-resistances-robustness.patch` — guards asteroids without a
  `resistances` table (latent loader crash with some planet mods) and
  stops inserting into `resistances` while iterating it.

## Krastorio2-spaced-out-tweaks

- `item-lua-duplicates.patch` — drops the duplicated
  `kr-fertilizer.spoil_result` assignment and the dead
  `kr-advanced-assembling-machine` weight entry (0.25 was always
  overwritten by the 0.2 twin entry two lines down). Behavior unchanged;
  this also keeps the file's `reset_freshness_on_craft` item-level no-op
  documented by k2so-rats-fixes' data-final-fixes comment.
  NOTE: the actual freshness fix (`reset_freshness_on_craft` belongs on
  recipe *products* in 2.1) lives in k2so-rats-fixes, not in this patch.

## xy-k2so-enhancements-nulls-fork

- `centrifuge-ingred1.patch` — use the computed `ingred1` in the
  advanced-centrifuge ingredients table instead of the hardcoded 4x
  centrifuge (dead variable; atan-atom-forge path never applied). Runtime
  compensation ships in `fixes/advanced-centrifuge-atom-forge.lua`.
- `tech-cards-recipe-guard.patch` — `reformat()` crashed with an opaque
  "index local 'r'" when a `tech_cards_list` entry's recipe is missing
  (e.g. pack item without recipe); now logs and skips.
- `workshop-strip.patch` — the workshop-science strip loop called
  `remove_cards` inside the ingredients scan, stripping workshop cards
  from techs that contain automation-science-pack not in first position.
  (`tests/lua/run-workshop-strip.lua` demonstrates on real code.)

## Verified non-issues (no patch needed)

- `fixes/item.lua` is empty **upstream** as well (checked raw GitHub);
  the fork deliberately gutted it. Nothing is missing.
- "remove while iterating skips adjacent entries" in xy's
  `tech_remove_cards`/`tech_remove_preqs`: retracted — the scan restarts
  per target, pinned by `tests/lua/run-basic-card-strips.lua`.
