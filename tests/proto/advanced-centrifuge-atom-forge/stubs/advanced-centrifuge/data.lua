-- Minimal viable replicas of the real mod's prototypes, shaped exactly
-- like xy's patch expects them.
data:extend({
  {
    type = "item",
    name = "k11-advanced-centrifuge",
    icon = "__base__/graphics/icons/centrifuge.png",
    icon_size = 64,
    stack_size = 50,
    place_result = "k11-advanced-centrifuge",
  },
  {
    type = "assembling-machine",
    name = "k11-advanced-centrifuge",
    icon = "__base__/graphics/icons/centrifuge.png",
    icon_size = 64,
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = 0.5, result = "k11-advanced-centrifuge" },
    max_health = 350,
    collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    crafting_categories = { "centrifuging" },
    crafting_speed = 1,
    energy_source = { type = "electric", usage_priority = "secondary-input" },
    energy_usage = "100kW",
    module_slots = 2,
    allowed_effects = { "consumption", "speed", "productivity", "pollution", "quality" },
  },
  {
    type = "recipe",
    name = "k11-advanced-centrifuge",
    enabled = false,
    energy_required = 10,
    ingredients = {
      { type = "item", name = "centrifuge", amount = 4 },
      { type = "item", name = "iron-plate", amount = 10 },
    },
    results = {
      { type = "item", name = "k11-advanced-centrifuge", amount = 1 },
    },
  },
  {
    type = "technology",
    name = "k11-advanced-centrifuge",
    icon = "__base__/graphics/icons/centrifuge.png",
    icon_size = 64,
    prerequisites = { "nuclear-science-pack" },
    unit = {
      time = 30,
      count = 100,
      ingredients = {
        { "automation-science-pack", 1 },
        { "kr-matter-tech-card", 1 },
      },
    },
    effects = {
      { type = "unlock-recipe", recipe = "k11-advanced-centrifuge" },
    },
  },
})
