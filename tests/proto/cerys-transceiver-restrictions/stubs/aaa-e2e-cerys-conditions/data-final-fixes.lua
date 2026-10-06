-- Mimic of Cerys-Moon-of-Fulgora prototypes/override/entity.lua: it adds
-- surface_properties (declared in prototypes/planet/planet.lua) and then
-- restricts every accumulator to non-Cerys surfaces. Only the observable on
-- the transceiver matters here: the blanket conditions on it.
data:extend({
  { type = "surface-property", name = "cerys-ambient-radiation", default_value = 10 },
  { type = "surface-property", name = "harenic-energy-signatures", default_value = 10 },
  { type = "surface-property", name = "temperature-celcius", default_value = 25 },
})

local transceiver = data.raw.accumulator and data.raw.accumulator["kr-intergalactic-transceiver"]
if transceiver then
  transceiver.surface_conditions = transceiver.surface_conditions or {}
  table.insert(transceiver.surface_conditions, { property = "cerys-ambient-radiation", max = 0 })
  table.insert(transceiver.surface_conditions, { property = "harenic-energy-signatures", max = 0 })
  table.insert(transceiver.surface_conditions, { property = "temperature-celcius", max = 500 })
end
