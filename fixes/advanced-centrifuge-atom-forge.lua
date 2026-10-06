-- xy fork (patches/entity.lua): computed ingredient never applied.
--
-- With advanced-centrifuge + atan-nuclear-science installed, xy's
-- advanced-centrifuge rebalance computes
--     ingred1 = { type = 'item', name = 'atan-atom-forge', amount = 2 }
-- and moves the technology prerequisites to atan-atom-forge - but the
-- recipe's ingredients table is a literal that still eats 4x 'centrifuge'.
-- 'ingred1' is dead code. Enforce the computed intent so recipe and tech
-- tree agree.

if not (mods["advanced-centrifuge"] and mods["atan-nuclear-science"]) then
  return
end
local setting = settings.startup["xy-advanced-centrifuge-rebalance"]
if (not setting or not setting.value) then
  return
end

local recipe = data.raw.recipe and data.raw.recipe["k11-advanced-centrifuge"]
if (not recipe or not recipe.ingredients) then
  return
end

for _, ingredient in ipairs(recipe.ingredients) do
  if (ingredient.type == "item" and ingredient.name == "centrifuge") then
    ingredient.name = "atan-atom-forge"
    ingredient.amount = 2
    log("[k2so-rats-fixes] k11-advanced-centrifuge: applied xy's computed atan-atom-forge ingredient (was 4x centrifuge)")
  end
end
