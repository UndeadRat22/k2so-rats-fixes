-- k2-greenhouse-plus vs Krastorio 2: duplicate sand/glass chains.
--
-- With its own glass setting at "default" (k2gp-provide-glass-for-greenhouses)
-- k2-greenhouse-plus ships a private sand/glass chain: k2gp-sand (from stone)
-- smelts into k2gp-glass, every greenhouse building recipe consumes 24x
-- k2gp-glass, and the recipes are meant to unlock from the greenhouse
-- technology. With Krastorio 2 installed that duplicates K2's identical
-- kr-sand -> kr-glass chain: two sands and two glasses with one purpose each.
-- (In the K2SO stack the duplicates are even dead content: k2gp's data.lua
-- hooks the K2 unlock onto the kr-greenhouse technology, which K2SO only
-- creates in data-final-fixes - after k2gp has already given up on it.)
--
-- This fix unifies the chains into K2's, mirroring what the mod itself does
-- when its glass setting is "other" and K2 provides glass:
--   * greenhouse building recipes take 20x kr-glass (the author's own K2
--     rate) instead of 24x k2gp-glass;
--   * the k2gp-sand / k2gp-glass recipes and their technology unlocks are
--     removed, along with generated wrappers of the dead chain (item
--     recycling, K2SO kr-crush-*): with the chain gone its items are
--     unobtainable, so a recipe consuming them is junk, and swapping the
--     wrappers instead would just duplicate the existing kr-* variants;
--   * recipes that only (re)yield the items - e.g. greenhouse recycling -
--     point at kr-sand/kr-glass;
--   * the orphaned k2gp items are hidden (like K2SO's own enforce-k2-items
--     pass does for other mods' duplicate sand/glass) instead of deleted, so
--     items already crafted on existing saves survive.
--
-- Controlled by the k2so-rats-fixes-greenhouse-plus-k2-glass startup setting
-- (on by default). No-op when the other mod's glass source is not "default"
-- (its "other"/"disabled" modes already avoid the duplicate chain) or when
-- K2's kr-sand/kr-glass items are missing.

local SETTING = "k2so-rats-fixes-greenhouse-plus-k2-glass"
local K2GP_GLASS_SOURCE_SETTING = "k2gp-provide-glass-for-greenhouses"

local K2GP_SAND, K2GP_GLASS = "k2gp-sand", "k2gp-glass"
local K2_SAND, K2_GLASS = "kr-sand", "kr-glass"
local K2GP_ITEMS = { [K2GP_SAND] = K2_SAND, [K2GP_GLASS] = K2_GLASS }

if not mods["k2-greenhouse-plus"] then
  return
end

local enabled = settings.startup[SETTING]
if not (enabled and enabled.value) then
  return
end

local glass_source = settings.startup[K2GP_GLASS_SOURCE_SETTING]
if glass_source and glass_source.value ~= "default" then
  return
end

if not (data.raw.item and data.raw.item[K2_SAND] and data.raw.item[K2_GLASS]) then
  return
end
if not data.raw.item[K2GP_GLASS] then
  return
end

-- The rate the greenhouse-plus author uses when K2 provides the glass
-- (kr-glass is 125% glass : stone, i.e. their 24x k2gp-glass becomes 20x).
local K2_GLASS_PER_GREENHOUSE = 20

-- Set of recipe names this pass removes: their technology unlocks (if any)
-- must go too, or the dangling unlock is a startup error.
local removed_recipes = {}

local function remove_recipe(name)
  if data.raw.recipe[name] then
    data.raw.recipe[name] = nil
    table.insert(removed_recipes, name)
  end
end

-- 1) The duplicate chain itself.
remove_recipe(K2GP_SAND)
remove_recipe(K2GP_GLASS)

-- 2) Greenhouse building recipes move to kr-glass at the author's K2 rate.
local swapped_greenhouses = 0
for _, recipe in pairs(data.raw.recipe) do
  if recipe.name:find("^k2gp%-greenhouse%-for%-") then
    for _, ingredient in ipairs(recipe.ingredients or {}) do
      if ingredient.name == K2GP_GLASS then
        ingredient.name = K2_GLASS
        ingredient.amount = K2_GLASS_PER_GREENHOUSE
        swapped_greenhouses = swapped_greenhouses + 1
      end
    end
  end
end

-- 3) Every other recipe still touching the items: consuming the dead chain's
--    items means an auto-generated wrapper (recycling-of-item, kr-crush-*),
--    so the recipe is deleted; merely yielding them means a rebate side
--    effect (recycling returns), where the K2 equivalent is correct.
local swapped_results = 0
for _, recipe in pairs(data.raw.recipe) do
  local consumes_k2gp = false
  for _, ingredient in ipairs(recipe.ingredients or {}) do
    if K2GP_ITEMS[ingredient.name] then
      consumes_k2gp = true
      break
    end
  end
  if consumes_k2gp then
    remove_recipe(recipe.name)
  else
    for _, result in ipairs(recipe.results or {}) do
      local replacement = K2GP_ITEMS[result.name]
      if replacement then
        result.name = replacement
        swapped_results = swapped_results + 1
      end
    end
  end
end

-- 4) Purge unlock-recipe effects for exactly the recipes removed above.
local removed_unlocks = 0
for _, technology in pairs(data.raw.technology) do
  local effects = technology.effects
  if effects then
    for i = #effects, 1, -1 do
      local effect = effects[i]
      if effect.type == "unlock-recipe" then
        for _, removed in ipairs(removed_recipes) do
          if effect.recipe == removed then
            table.remove(effects, i)
            removed_unlocks = removed_unlocks + 1
            break
          end
        end
      end
    end
  end
end

-- 5) Hide the orphaned items rather than deleting them, so existing saves
--    keep anything already crafted.
for _, name in ipairs({ K2GP_SAND, K2GP_GLASS }) do
  local item = data.raw.item[name]
  if item then
    item.hidden = true
    item.hidden_in_factoriopedia = true
  end
end

log(("[k2so-rats-fixes] greenhouse-plus: unified k2gp sand/glass into K2's chain "
  .. "(%d greenhouse recipes at %dx kr-glass, %d recycling results swapped, "
  .. "%d recipes removed with %d tech unlocks)")
  :format(swapped_greenhouses, K2_GLASS_PER_GREENHOUSE, swapped_results, #removed_recipes, removed_unlocks))
