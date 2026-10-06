local function spoil(name)
  local item = data.raw.item and data.raw.item[name]
  if (not item) then
    return "missing"
  end
  return tostring(item.spoil_result) .. "@" .. tostring(item.spoil_ticks)
end

log("E2E_CHECK::spoil.e2e-spoil-a=" .. spoil("e2e-spoil-a"))
log("E2E_CHECK::spoil.e2e-spoil-b=" .. spoil("e2e-spoil-b"))
log("E2E_CHECK::spoil.e2e-spoil-c=" .. spoil("e2e-spoil-c"))
log("E2E_CHECK::spoil.e2e-spoil-d=" .. spoil("e2e-spoil-d"))
