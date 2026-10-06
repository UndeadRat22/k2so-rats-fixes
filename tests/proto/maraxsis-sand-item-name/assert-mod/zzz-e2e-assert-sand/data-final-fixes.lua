-- nulls-k2so-tweaks writes maraxsis-constants.SAND_ITEM_NAME on the
-- prototype root (junk field); the fix writes .data.SAND_ITEM_NAME and
-- removes the root key.
local constants = data.raw["mod-data"] and data.raw["mod-data"]["maraxsis-constants"]
if (not constants) then
  log("E2E_CHECK::maraxsis-constants.root_key=missing_mod_data")
  log("E2E_CHECK::maraxsis-constants.data_key=missing_mod_data")
  return
end
log("E2E_CHECK::maraxsis-constants.root_key=" .. tostring(constants.SAND_ITEM_NAME))
log("E2E_CHECK::maraxsis-constants.data_key=" .. tostring(constants.data and constants.data.SAND_ITEM_NAME))
