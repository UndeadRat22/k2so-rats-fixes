-- Assert: the intergalactic transceiver's accumulator-type blanket
-- restrictions are gone while K2SO's own rules survive.
local transceiver = data.raw.accumulator and data.raw.accumulator["kr-intergalactic-transceiver"]
if not transceiver then
  log("E2E_CHECK::transceiver.missing")
  return
end

local has = {}
local names = {}
for _, condition in ipairs(transceiver.surface_conditions or {}) do
  has[condition.property] = true
  names[#names + 1] = condition.property
end
table.sort(names)

log(("E2E_CHECK::transceiver.count=%d"):format(#names))
log(("E2E_CHECK::transceiver.cerys=%d"):format(has["cerys-ambient-radiation"] and 1 or 0))
log(("E2E_CHECK::transceiver.harenic=%d"):format(has["harenic-energy-signatures"] and 1 or 0))
log(("E2E_CHECK::transceiver.temperature=%d"):format(has["temperature-celcius"] and 1 or 0))
log(("E2E_CHECK::transceiver.gravity=%d"):format(has["gravity"] and 1 or 0))
for _, n in ipairs(names) do
  log("E2E_CHECK::transceiver.condition " .. n)
end
