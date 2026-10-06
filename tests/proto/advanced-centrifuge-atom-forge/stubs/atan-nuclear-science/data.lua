data:extend({
  {
    type = "tool",
    name = "nuclear-science-pack",
    icon = "__base__/graphics/icons/space-science-pack.png",
    icon_size = 64,
    stack_size = 200,
    durability = 1,
  },
  {
    type = "recipe",
    name = "nuclear-science-pack",
    enabled = false,
    energy_required = 15,
    ingredients = {
      { type = "item", name = "uranium-235", amount = 1 },
    },
    results = {
      { type = "item", name = "nuclear-science-pack", amount = 1 },
    },
  },
  {
    type = "item",
    name = "atan-atom-forge",
    icon = "__base__/graphics/icons/centrifuge.png",
    icon_size = 64,
    stack_size = 50,
  },
  {
    type = "technology",
    name = "nuclear-science-pack",
    icon = "__base__/graphics/icons/nuclear-reactor.png",
    icon_size = 64,
    unit = {
      time = 30,
      count = 100,
      ingredients = {
        { "automation-science-pack", 1 },
      },
    },
    effects = {},
  },
  {
    type = "technology",
    name = "atan-atom-forge",
    icon = "__base__/graphics/icons/centrifuge.png",
    icon_size = 64,
    prerequisites = { "nuclear-science-pack" },
    unit = {
      time = 30,
      count = 100,
      ingredients = {
        { "automation-science-pack", 1 },
      },
    },
    effects = {},
  },
})
