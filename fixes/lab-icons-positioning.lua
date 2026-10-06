-- K2SO: dead ">24 science packs" icons_positioning fallback.
--
-- Krastorio2-spaced-out/prototypes/final-fixes/labs-fixes.lua has a branch
-- for "#lab.inputs > 24" that is supposed to widen the science-pack icon
-- layout of all four labs. It redefines size3/size5/size8 as locals
-- *inside* the if-block, so they are discarded at `end` and the compact
-- outer values are always applied. With more than 24 packs the input row
-- overflows and packs are drawn outside the lab window.
--
-- Re-apply K2SO's own intended values from that dead branch.

local lab = data.raw.lab and data.raw.lab["lab"]
if (not lab or not lab.inputs or #lab.inputs <= 24) then
  return
end

local size3 = {
  {
    inventory_index = defines.inventory.lab_modules,
    shift = { 0, 0.9 },
  },
  {
    inventory_index = defines.inventory.lab_input,
    shift = { 0, -1.5 },
    max_icons_per_row = 10,
    separation_multiplier = 1 / 1.1,
    scale = 0.4,
  },
}
local size5 = {
  {
    inventory_index = defines.inventory.lab_modules,
    shift = { 0, 1.6 },
  },
  {
    inventory_index = defines.inventory.lab_input,
    shift = { 0, -1.3 },
    max_icons_per_row = 10,
    separation_multiplier = 1 / 1.1,
    scale = 0.5,
  },
}
local size8 = {
  {
    inventory_index = defines.inventory.lab_modules,
    shift = { 0, 1.6 },
  },
  {
    inventory_index = defines.inventory.lab_input,
    shift = { 0, -2.7 },
    max_icons_per_row = 10,
    separation_multiplier = 1 / 1.1,
    scale = 0.75,
  },
}

local applied = 0
local assignments = {
  ["lab"] = size3,
  ["kr-advanced-lab"] = size3,
  ["biolab"] = size5,
  ["kr-singularity-lab"] = size8,
}
for name, positioning in pairs(assignments) do
  if (data.raw.lab[name]) then
    data.raw.lab[name].icons_positioning = positioning
    applied = applied + 1
  end
end
log(("[k2so-rats-fixes] applied K2SO's >24-packs icons_positioning to %d labs (pack count %d)")
  :format(applied, #lab.inputs))
