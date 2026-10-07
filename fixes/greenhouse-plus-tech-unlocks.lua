-- k2-greenhouse-plus vs Krastorio2-spaced-out: discarded greenhouse unlocks.
--
-- k2gp hooks the tree greenhouse's unlock onto K2's kr-greenhouse technology
-- (prototypes/technology.lua): researching it unlocks k2gp-greenhouse-for-tree
-- and its crop-growth recipe. In the K2SO stack that hook dies: k2gp loads
-- after Krastorio2 (its "? Krastorio2" optional dependency) and inserts the
-- effects into K2's technology - then Krastorio2-spaced-out replaces the whole
-- kr-greenhouse prototype in its data-final-fixes (Factorio 2.x data:extend
-- overwrites same-named prototypes), discarding every effect k2gp added.
-- Measured on the real stack: no technology unlocks either recipe, and both
-- are enabled = false, so the tree greenhouse is uncraftable there.
--
-- (The Gleba greenhouse variants are unaffected: they hook onto the base
-- Space Age technologies artificial-soil and agriculture, which nothing in
-- this stack replaces. The sand/glass chain recipes are enabled from the
-- start and never needed the hook.)
--
-- This fix re-attaches the intended unlock effects to whatever kr-greenhouse
-- technology survives, mirroring k2gp's own hook. Recipes that are already
-- unlocked elsewhere are left alone (in stacks without the replacement,
-- k2gp's original hook is still in place), as are recipes the other mod did
-- not create (its tree-greenhouse setting off).

if not mods["k2-greenhouse-plus"] then
  return
end

local TECH = "kr-greenhouse"
local RECIPES = { "k2gp-greenhouse-for-tree", "k2gp-greenhouse-tree-growth" }

local tech = data.raw.technology and data.raw.technology[TECH]
if not tech then
  log("[k2so-rats-fixes] greenhouse-plus: no kr-greenhouse technology; unlock fix skipped")
  return
end

-- A recipe unlock may already exist somewhere (k2gp's own hook survives in
-- stacks without the technology replacement): never duplicate it.
local unlocked = {}
for _, t in pairs(data.raw.technology) do
  for _, effect in ipairs(t.effects or {}) do
    if effect.type == "unlock-recipe" then
      unlocked[effect.recipe] = true
    end
  end
end

tech.effects = tech.effects or {}
local added = 0
for _, recipe_name in ipairs(RECIPES) do
  if data.raw.recipe[recipe_name] and not unlocked[recipe_name] then
    table.insert(tech.effects, { type = "unlock-recipe", recipe = recipe_name })
    added = added + 1
  end
end

if added > 0 then
  log(("[k2so-rats-fixes] greenhouse-plus: re-attached %d tree greenhouse unlock(s) to %s")
    :format(added, TECH))
else
  log("[k2so-rats-fixes] greenhouse-plus: tree greenhouse unlocks already in place; nothing to do")
end
