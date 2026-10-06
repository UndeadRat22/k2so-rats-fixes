-- Assert: with eRisel-k2-arsenal installed, the auto asteroid immunity
-- default must resolve to 50% (K2SO's 100% is kept without the arsenal).
local at_target, off_target, total, no_entry = 0, 0, 0, 0

for name, asteroid in pairs(data.raw.asteroid or {}) do
  total = total + 1
  local worst = nil
  for _, r in ipairs(asteroid.resistances or {}) do
    if r.type == "kr-radioactive" then
      if (not worst) or r.percent < worst then worst = r.percent end
    end
  end
  if worst == nil then
    no_entry = no_entry + 1
    log("E2E_CHECK::arsenal.no-entry " .. name)
  elseif worst == 50 then
    at_target = at_target + 1
  else
    off_target = off_target + 1
    log(("E2E_CHECK::arsenal.off-entry %s=%s"):format(name, tostring(worst)))
  end
end

log(("E2E_CHECK::arsenal.total=%d"):format(total))
log(("E2E_CHECK::arsenal.at50=%d"):format(at_target))
log(("E2E_CHECK::arsenal.off50=%d"):format(off_target + no_entry))
