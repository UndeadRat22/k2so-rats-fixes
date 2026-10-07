-- Without the fix, k2-greenhouse-plus' default config builds greenhouses
-- from 24x k2gp-glass and unlocks its private k2gp-sand/k2gp-glass chain
-- from the greenhouse technology. With the fix, greenhouses take 20x
-- kr-glass, the duplicate recipes and tech unlocks are gone and the
-- orphaned items are hidden.

local function glass_ingredient(recipe_name)
  local recipe = data.raw.recipe[recipe_name]
  if not recipe then
    return "missing_recipe"
  end
  for _, ingredient in ipairs(recipe.ingredients or {}) do
    if ingredient.name == "k2gp-glass" or ingredient.name == "kr-glass" or ingredient.name == "iron-plate" then
      return ingredient.name .. "/" .. tostring(ingredient.amount)
    end
  end
  return "no_glass_ingredient"
end
log("E2E_CHECK::greenhouse-for-tree.glass=" .. glass_ingredient("k2gp-greenhouse-for-tree"))
log("E2E_CHECK::greenhouse-for-yumako-tree.glass=" .. glass_ingredient("k2gp-greenhouse-for-yumako-tree"))

-- Global invariant: after unification no recipe references the duplicate
-- chain's items at all (wrappers like recycling and kr-crush-* are removed
-- rather than left pointing at unobtainable hidden items).
local referencing = 0
for _, recipe in pairs(data.raw.recipe) do
  local touches = false
  for _, ingredient in ipairs(recipe.ingredients or {}) do
    if ingredient.name == "k2gp-sand" or ingredient.name == "k2gp-glass" then
      touches = true
    end
  end
  for _, result in ipairs(recipe.results or {}) do
    if result.name == "k2gp-sand" or result.name == "k2gp-glass" then
      touches = true
    end
  end
  if touches then
    referencing = referencing + 1
  end
end
log("E2E_CHECK::recipes-referencing-k2gp-items=" .. referencing)

local function prototype_exists(kind, name)
  local group = data.raw[kind]
  return (group and group[name]) and "exists" or "missing"
end
log("E2E_CHECK::recipe.k2gp-sand=" .. prototype_exists("recipe", "k2gp-sand"))
log("E2E_CHECK::recipe.k2gp-glass=" .. prototype_exists("recipe", "k2gp-glass"))

local unlocks = { ["k2gp-sand"] = 0, ["k2gp-glass"] = 0 }
for _, technology in pairs(data.raw.technology) do
  for _, effect in ipairs(technology.effects or {}) do
    if effect.type == "unlock-recipe" and unlocks[effect.recipe] ~= nil then
      unlocks[effect.recipe] = unlocks[effect.recipe] + 1
    end
  end
end
log("E2E_CHECK::tech-unlocks.k2gp-sand=" .. unlocks["k2gp-sand"])
log("E2E_CHECK::tech-unlocks.k2gp-glass=" .. unlocks["k2gp-glass"])

local function item_hidden(name)
  local item = data.raw.item[name]
  if not item then
    return "missing"
  end
  return tostring(item.hidden == true)
end
log("E2E_CHECK::item.k2gp-sand.hidden=" .. item_hidden("k2gp-sand"))
log("E2E_CHECK::item.k2gp-glass.hidden=" .. item_hidden("k2gp-glass"))
