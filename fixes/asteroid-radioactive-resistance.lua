-- K2SO vs nulls-k2so-tweaks: radioactive asteroid immunity clash.
--
-- Krastorio2-spaced-out (prototypes/final-fixes/asteroids.lua) grants every
-- asteroid 100% kr-radioactive immunity so radiation weapons stay useless
-- against asteroids. nulls-k2so-tweaks (standardize_asteroid_resistances)
-- runs later and overwrites that entry with a copy of the physical
-- resistance (or removes it when the asteroid has no physical resistance).
-- With both mods installed no asteroid ends up radiation-immune, silently
-- discarding K2SO's design.
--
-- This fix re-asserts K2SO's intent after both mods have run: exactly one
-- kr-radioactive entry per asteroid, at a configurable target percent.
-- The startup setting k2so-rats-fixes-asteroid-radiation-immunity selects
-- the target: "auto" (default) keeps K2SO's 100%, or 50% when
-- eRisel-k2-arsenal is installed, because its late-game weapons deal
-- kr-radioactive damage and full immunity would invalidate that whole
-- weapon class against asteroids again. Explicit values (100/75/50/25/0)
-- always win.

local SETTING_NAME = "k2so-rats-fixes-asteroid-radiation-immunity"
local ARSENAL_MOD = "eRisel-k2-arsenal"

if not (mods["Krastorio2-spaced-out"] and data.raw["damage-type"] and data.raw["damage-type"]["kr-radioactive"]) then
  return
end

-- Resolve the target immunity percent from the startup setting.
local function target_percent()
  local setting = settings.startup[SETTING_NAME]
  local value = setting and setting.value or "auto"
  if value == "auto" then
    return mods[ARSENAL_MOD] and 50 or 100
  end
  local explicit = tonumber(value)
  if explicit then
    return explicit
  end
  return mods[ARSENAL_MOD] and 50 or 100
end

local target = target_percent()

local merged = 0
local removed_duplicates = 0
for _, asteroid in pairs(data.raw.asteroid or {}) do
  local resistances = asteroid.resistances
  if resistances then
    local first_radio = nil
    -- Iterate backwards: dedupe duplicates created when K2SO's blind
    -- table.insert appended a second kr-radioactive entry on top of a
    -- mod-provided one.
    for i = #resistances, 1, -1 do
      if resistances[i].type == "kr-radioactive" then
        if first_radio and i ~= first_radio then
          table.remove(resistances, i)
          removed_duplicates = removed_duplicates + 1
        else
          first_radio = i
        end
      end
    end
    if first_radio then
      resistances[first_radio].percent = target
      resistances[first_radio].decrease = nil
    else
      table.insert(resistances, { type = "kr-radioactive", percent = target })
      merged = merged + 1
    end
  end
end
log(("[k2so-rats-fixes] restored kr-radioactive immunity on asteroids at %d%% (inserted %d, deduplicated %d)")
  :format(target, merged, removed_duplicates))
