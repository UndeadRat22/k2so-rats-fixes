-- Counts asteroids whose kr-radioactive resistance deviates from K2SO's
-- intended 100% immunity, and counts duplicated kr-radioactive entries
-- (K2SO blindly appends; a mod asteroid that brought its own entry gets two).
local vulnerable = {}
local duplicates = 0
local total = 0

for name, asteroid in pairs(data.raw.asteroid or {}) do
  local resistances = asteroid.resistances or {}
  total = total + 1
  local entries = 0
  local worst = nil -- lowest percent seen; immunity uses the first entry during combat
  for _, r in ipairs(resistances) do
    if r.type == "kr-radioactive" then
      entries = entries + 1
      if (not worst) or r.percent < worst then worst = r.percent end
    end
  end
  if entries > 1 then duplicates = duplicates + entries - 1 end
  if (not worst) or worst < 100 then
    table.insert(vulnerable, ("%s=%s"):format(name, tostring(worst)))
  end
end

table.sort(vulnerable)
log(("E2E_CHECK::asteroids.total=%d"):format(total))
log(("E2E_CHECK::asteroids.vulnerable=%d"):format(#vulnerable))
log(("E2E_CHECK::asteroids.duplicate_radio=%d"):format(duplicates))
for _, v in ipairs(vulnerable) do
  log("E2E_CHECK::asteroids.vulnerable-entry " .. v)
end
