-- Report the input row layout of the four K2SO-managed labs. The compact
-- layout (max_icons_per_row=6) is K2SO's outer, always-applied config; the
-- widened layout (10) is the dead >24-branch fallback the fix restores.
local function report(name)
  local lab = data.raw.lab and data.raw.lab[name]
  if (not lab) then
    log(("E2E_CHECK::%s=missing"):format(name))
    return
  end
  local row = lab.icons_positioning and lab.icons_positioning[2]
  log(("E2E_CHECK::%s.count=%d"):format(name, #(lab.inputs or {})))
  log(("E2E_CHECK::%s.max_icons_per_row=%s"):format(name, tostring(row and row.max_icons_per_row)))
  log(("E2E_CHECK::%s.scale=%s"):format(name, tostring(row and row.scale)))
end

report("lab")
report("kr-advanced-lab")
report("biolab")
report("kr-singularity-lab")
