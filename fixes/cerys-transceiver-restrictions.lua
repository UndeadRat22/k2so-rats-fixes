-- Cerys vs K2 intergalactic transceiver.
--
-- Cerys-Moon-of-Fulgora blanket-restricts every accumulator to its
-- ambient-radiation-free surfaces, exempting only cerys-charging-rod and
-- kr-planetary-teleporter. The K2 intergalactic transceiver is prototype
-- type "accumulator" (it charges up), so a Cerys-based base cannot build
-- its win-condition building. nulls' unrestrict_teleporter cleans only the
-- teleporter, and Cerys' own exemption list does not know about the
-- transceiver either.
--
-- This fix removes the same restriction set nulls uses from the
-- transceiver (cerys-ambient-radiation, harenic-energy-signatures,
-- temperature-celcius - other planet mods use the same blanket trick),
-- keeping K2SO's own gravity rule intact. Without Cerys-style conditions
-- present this is a no-op.

local REMOVE = {
  ["cerys-ambient-radiation"] = true,
  ["harenic-energy-signatures"] = true,
  ["temperature-celcius"] = true,
}

local transceiver = data.raw.accumulator and data.raw.accumulator["kr-intergalactic-transceiver"]
if (not transceiver) or (not transceiver.surface_conditions) then
  return
end

local removed = {}
for i = #transceiver.surface_conditions, 1, -1 do
  local property = transceiver.surface_conditions[i].property
  if REMOVE[property] then
    table.remove(transceiver.surface_conditions, i)
    removed[#removed + 1] = property
  end
end

if #removed > 0 then
  log(("[k2so-rats-fixes] kr-intergalactic-transceiver: removed surface conditions %s " ..
    "(accumulator-type blanket restrictions)"):format(table.concat(removed, ", ")))
else
  log("[k2so-rats-fixes] kr-intergalactic-transceiver: no accumulator-type blanket restrictions found")
end
