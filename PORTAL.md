# Mod portal page text

Paste into the description field on the Factorio mod portal. Markdown on
purpose — the portal documents its description field as markdown (see the
Mod details API on wiki.factorio.com). Kept conservative (headings, bold,
flat lists, links, code spans) since the portal's renderer is a partial
markdown implementation; nested structures and tables are avoided.

---

# K2SO Rat's Fixes

A stack-audit bugfix collection for [Krastorio 2](https://mods.factorio.com/mod/Krastorio2) + Space Age (K2SO): fixes for [Krastorio 2 Spaced Out](https://mods.factorio.com/mod/Krastorio2-spaced-out), its [tweaks mod](https://mods.factorio.com/mod/Krastorio2-spaced-out-tweaks), nulls-k2so-tweaks and the xy-k2so-enhancements fork playing together.

## The biomass stall (headline fix)

The tweaks mod makes biomass spoil, and the bioprocessing facility's biomass recipe is recursive (2 biomass + gases → 5 biomass). Crafted items **inherit the parent spoilage**, so loop freshness can only go down and the whole stock expires at the same moment — measured end-to-end, a 90% spoiled seed yields 91.7% spoiled output, then 93.3%, until military science (which needs biomass) starves. The tweaks mod's own fix attempt puts `reset_freshness_on_craft` on the item prototype, where it is a **silent no-op** in Factorio 2.1.

With this mod, crafted biomass always spawns with a **full spoil timer**:

- `kr-biomass` (recursive bioprocessing facility recipe)
- `kr-biter-biomass`, `kr-pentapod-biomass` (egg crushing)
- `kr-biomass-from-spoilage` (biochamber: jelly + spoilage)
- `kr-fertilizer` (crafted from biomass)
- `kr-jellynut`, `kr-yumako` (greenhouse crops grown from fertilizer)

## Other fixes

- **Asteroids keep their `kr-radioactive` immunity** — nulls-k2so-tweaks' resistance standardization pass silently erased it. Configurable via a startup setting: *auto* (default) keeps K2SO's 100% and drops to 50% when `eRisel-k2-arsenal` (kr-radioactive weapons) is installed; explicit 100/75/50/25/0 values are also available.
- **The K2 intergalactic transceiver can be built on Cerys again.** Cerys blanket-restricts accumulators on its surface and the transceiver is an accumulator; the ambient-radiation restriction is removed (K2SO's own gravity rule is kept). No-op on other surfaces / without such conditions.
- **Labs render correctly with more than 24 science packs.** K2SO ships a widened icon layout for this case, but it was shadowed by block-local declarations and never ran.
- **Maraxsis reads the intended sand item.** nulls-k2so-tweaks wrote its `SAND_ITEM_NAME` onto the mod-data prototype root instead of the `.data` table maraxsis actually reads.
- **Two-item spoil cycles from nulls' item migrations are broken.** Its replacement guard is always true, so a new item that spoils back into the old one loops forever; the migration side is now cleared when that happens.
- **The advanced centrifuge recipe consumes 2x atan-atom-forge** when atan-nuclear-science is present, matching the technology tree (the xy fork computed the ingredient but never used it).

## Quality

Every fix is verified against the real mod stack with a headless e2e suite: gameplay benchmark for the biomass pipeline, data-stage checks for every fix, lua-level checks against the installed xy fork, and an apply-checker for the bundled patches. `patches/upstream/` carries ready-to-apply patches for the same issues in the original mods, where the underlying bugs belong.

**Safe on existing saves.** Without the K2SO stack installed this mod does nothing.
