-- Assert: every FRESHEN recipe product spawns fully fresh (always_fresh).
-- Phase A (no fix): the biomass-family recipes inherit ingredient spoilage.
-- Phase B (with fix): all products carry always_fresh.
local RECIPES = {
  { "kr-biomass", "kr-biomass" },
  { "kr-biter-biomass", "kr-biomass" },
  { "kr-pentapod-biomass", "kr-biomass" },
  { "kr-fertilizer", "kr-fertilizer" },
  { "kr-biomass-from-spoilage", "kr-biomass" },
  { "kr-jellynut", "jellynut" },
  { "kr-yumako", "yumako" },
}

local fresh, unfresh, missing = 0, 0, 0
for _, def in ipairs(RECIPES) do
  local recipe = data.raw.recipe[def[1]]
  if type(recipe) == "table" and type(recipe.results) == "table" then
    local found = false
    for _, result in ipairs(recipe.results) do
      if result.type == "item" and result.name == def[2] then
        found = true
        if result.always_fresh then
          fresh = fresh + 1
          log(("E2E_CHECK::freshness.fresh-entry %s -> %s"):format(def[1], def[2]))
        else
          unfresh = unfresh + 1
          log(("E2E_CHECK::freshness.unfresh-entry %s -> %s"):format(def[1], def[2]))
        end
      end
    end
    if not found then
      missing = missing + 1
      log(("E2E_CHECK::freshness.product-missing %s -> %s"):format(def[1], def[2]))
    end
  else
    missing = missing + 1
    log(("E2E_CHECK::freshness.recipe-missing %s"):format(def[1]))
  end
end

log(("E2E_CHECK::freshness.fresh=%d"):format(fresh))
log(("E2E_CHECK::freshness.unfresh=%d"):format(unfresh))
log(("E2E_CHECK::freshness.missing=%d"):format(missing))
