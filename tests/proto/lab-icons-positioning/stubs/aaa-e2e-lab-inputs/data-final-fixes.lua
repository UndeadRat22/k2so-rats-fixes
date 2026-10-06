-- Fabricate enough extra science packs to push #lab.inputs past 24 BEFORE
-- Krastorio2-spaced-out's labs-fixes runs (this stub sorts first, being
-- "aaa-*"). K2SO then re-syncs biolab/advanced lab inputs by alias and
-- deep-copies into the singularity lab, so the dummies propagate exactly
-- the way real packs do.
local packs = {}
for i = 1, 12 do
  table.insert(packs, {
    type = "tool",
    name = "aaa-e2e-dummy-pack-" .. i,
    icon = "__base__/graphics/icons/copper-plate.png",
    icon_size = 64,
    subgroup = "science-pack",
    stack_size = 200,
    durability = 1,
  })
end
data:extend(packs)

for i = 1, 12 do
  table.insert(data.raw.lab["lab"].inputs, "aaa-e2e-dummy-pack-" .. i)
end
