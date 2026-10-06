-- Mimics nulls' replace_all aftermath for a hypothetical pair where the
-- NEW item naturally spoils back into the OLD one:
--   e2e-spoil-a --(1 tick, migration)--> e2e-spoil-b --(42 ticks, natural)--> e2e-spoil-a
-- A control pair (c -> d, no cycle) must survive the cycle breaker.
data:extend({
  {
    type = "item",
    name = "e2e-spoil-a",
    icon = "__base__/graphics/icons/copper-plate.png",
    icon_size = 64,
    stack_size = 50,
    spoil_ticks = 1,
    spoil_result = "e2e-spoil-b",
  },
  {
    type = "item",
    name = "e2e-spoil-b",
    icon = "__base__/graphics/icons/iron-plate.png",
    icon_size = 64,
    stack_size = 50,
    spoil_ticks = 42,
    spoil_result = "e2e-spoil-a",
  },
  {
    type = "item",
    name = "e2e-spoil-c",
    icon = "__base__/graphics/icons/steel-plate.png",
    icon_size = 64,
    stack_size = 50,
    spoil_ticks = 1,
    spoil_result = "e2e-spoil-d",
  },
  {
    type = "item",
    name = "e2e-spoil-d",
    icon = "__base__/graphics/icons/plastic-bar.png",
    icon_size = 64,
    stack_size = 50,
  },
})
