-- Without the fix, no technology unlocks the k2gp tree greenhouse recipes in
-- the K2SO stack: k2gp's hook onto K2's kr-greenhouse technology is discarded
-- when K2SO replaces that technology in its final fixes, and the recipes are
-- enabled = false. With the fix, the unlock effects are re-attached to the
-- surviving technology. The Gleba greenhouse variants hook onto base Space
-- Age technologies and must keep their unlocks in both phases.

local function unlockers(recipe_name)
  local found = {}
  for tech_name, tech in pairs(data.raw.technology) do
    for _, effect in ipairs(tech.effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
        found[#found + 1] = tech_name
      end
    end
  end
  table.sort(found)
  return table.concat(found, ",")
end

log("E2E_CHECK::unlockers.k2gp-greenhouse-for-tree=" .. unlockers("k2gp-greenhouse-for-tree"))
log("E2E_CHECK::unlockers.k2gp-greenhouse-tree-growth=" .. unlockers("k2gp-greenhouse-tree-growth"))
log("E2E_CHECK::unlockers.k2gp-greenhouse-for-yumako-tree=" .. unlockers("k2gp-greenhouse-for-yumako-tree"))
log("E2E_CHECK::unlockers.k2gp-greenhouse-for-sunnycomb=" .. unlockers("k2gp-greenhouse-for-sunnycomb"))
