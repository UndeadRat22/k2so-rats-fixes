-- K2SO Rat's Fixes (k2so-rats-fixes)
--
-- Problem (K2 + Spaced Out + K2SO-tweaks):
--   Krastorio2-spaced-out-tweaks makes kr-biomass spoil (1 hour into
--   spoilage). The recursive kr-biomass recipe in the bioprocessing
--   facility (2 biomass + gases -> 5 biomass) makes the crafted biomass
--   inherit the parent spoilage percentage, so loop freshness can only
--   go down: eventually everything spoils at once and the pipeline
--   stalls.
--
--   (The tweaks mod already tries to fix this by setting
--   data.raw.item["kr-biomass"].reset_freshness_on_craft = true, but in
--   Factorio 2.1 that property belongs to the recipe *product*
--   (ItemProductPrototype), not the item prototype - so it is a no-op.)
--
-- Fix:
--   Set always_fresh = true on every product that is biomass or
--   fertilizer made from spoiling inputs. always_fresh (Factorio 2.1+)
--   makes the item spawn fully fresh regardless of ingredient spoilage,
--   i.e. the spawned biomass time is maxed out.

local FRESHEN = {
  -- recursive bioprocessing facility recipe (the reported stall)
  { recipe = "kr-biomass",              product = "kr-biomass" },
  -- egg crushing (eggs spoil too)
  { recipe = "kr-biter-biomass",        product = "kr-biomass" },
  { recipe = "kr-pentapod-biomass",     product = "kr-biomass" },
  -- fertilizer is crafted from biomass and inherits its spoilage
  { recipe = "kr-fertilizer",           product = "kr-fertilizer" },
  -- biochamber entry point: jelly (4 min spoil) + spoilage -> biomass
  { recipe = "kr-biomass-from-spoilage", product = "kr-biomass" },
  -- K2SO greenhouses: the crops would inherit the (spoiling) fertilizer's
  -- age, but Gleba crops only last an hour
  { recipe = "kr-jellynut",             product = "jellynut" },
  { recipe = "kr-yumako",               product = "yumako" },
}

local patched = 0
for _, def in ipairs(FRESHEN) do
  local recipe = data.raw.recipe[def.recipe]
  if type(recipe) == "table" and type(recipe.results) == "table" then
    for _, result in ipairs(recipe.results) do
      if result.type == "item" and result.name == def.product then
        result.always_fresh = true
        result.percent_spoiled = 0
        patched = patched + 1
      end
    end
  end
end

log("[k2so-rats-fixes] freshened " .. patched .. " recipe products")
if patched == 0 then
  log("[k2so-rats-fixes] nothing to patch; are Krastorio2/Krastorio2-spaced-out enabled?")
end

require("fixes.asteroid-radioactive-resistance")
require("fixes.maraxsis-sand-item-name")
require("fixes.lab-icons-positioning")
require("fixes.spoil-migration-cycles")
require("fixes.advanced-centrifuge-atom-forge")
require("fixes.cerys-transceiver-restrictions")
