local recipe = data.raw.recipe and data.raw.recipe["k11-advanced-centrifuge"]

local function amount_of(name)
  if (not recipe) then
    return "missing_recipe"
  end
  for _, ingredient in ipairs(recipe.ingredients or {}) do
    if (ingredient.name == name) then
      return tostring(ingredient.amount)
    end
  end
  return "nil"
end

log("E2E_CHECK::advcent.ingredient.centrifuge=" .. amount_of("centrifuge"))
log("E2E_CHECK::advcent.ingredient.atan-atom-forge=" .. amount_of("atan-atom-forge"))
