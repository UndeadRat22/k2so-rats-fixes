-- nulls-k2so-tweaks: spoil-migration guard is dead code.
--
-- nulls' util.item.replace_all migrates a replaced item by making the old
-- item spoil into the new one in 1 tick, guarded by:
--     if (new_entity.spoil_result ~= old_entity) then
-- But spoil_result is a string and old_entity is a table, so the condition
-- is always true and the migration spoil is always installed. The guard's
-- evident intent is to skip the migration when it would create a spoil
-- cycle (new item already spoils back into the old one).
--
-- nulls is another mod; this fix enforces the intent after the fact: any
-- two-item cycle where one side is a 1-tick migration spoil gets that
-- migration side cleared. Real spoil chains (cyclic on purpose or
-- longer-lived) are untouched.

local items = data.raw.item or {}
local broken = 0
for name, item in pairs(items) do
  local target_name = item.spoil_result
  if (type(target_name) == "string" and item.spoil_ticks == 1) then
    local target = items[target_name]
    if (target and target.spoil_result == name) then
      item.spoil_result = nil
      item.spoil_ticks = nil
      broken = broken + 1
      log(("[k2so-rats-fixes] broke spoil cycle %s <-> %s (cleared 1-tick migration spoil on %s)")
        :format(name, target_name, name))
    end
  end
end
if (broken == 0) then
  log("[k2so-rats-fixes] no 1-tick spoil migration cycles found")
end
