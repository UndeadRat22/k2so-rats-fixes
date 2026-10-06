-- nulls-k2so-tweaks: SAND_ITEM_NAME written to the wrong table.
--
-- nulls-k2so-tweaks/patches/planets/maraxsis.lua intends to point maraxsis'
-- standard sand item at "sand", but assigns
--     data.raw["mod-data"]["maraxsis-constants"].SAND_ITEM_NAME = "sand"
-- instead of writing to the prototype's .data table, which is the only
-- place maraxsis ever reads (everywhere else in nulls' own code uses
-- maraxsis-constants.data[...]). The root-level key is a junk field that
-- maraxsis ignores.
--
-- Today this happens to coincide with maraxsis' own default ("sand"), so
-- the damage is latent: any change of intent or default silently stops
-- applying. Write the value where it belongs and drop the stray key.

local constants = data.raw["mod-data"] and data.raw["mod-data"]["maraxsis-constants"]
if (not constants) then
  return
end

constants.data = constants.data or {}
constants.data.SAND_ITEM_NAME = "sand" --- @diagnostic disable-line
constants.SAND_ITEM_NAME = nil
log("[k2so-rats-fixes] maraxsis-constants: wrote SAND_ITEM_NAME='sand' to .data "
  .. "and removed the stray prototype-root key")
