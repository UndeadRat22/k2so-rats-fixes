local function prod(recipe_name)
  local recipe = data.raw.recipe[recipe_name]
  if (not recipe) then
    return "missing"
  end
  return "allow=" .. tostring(recipe.allow_productivity)
end

log("E2E_CHECK::matter.kr-spoilage-to-matter=" .. prod("kr-spoilage-to-matter"))
log("E2E_CHECK::matter.kr-matter-to-spoilage=" .. prod("kr-matter-to-spoilage"))
