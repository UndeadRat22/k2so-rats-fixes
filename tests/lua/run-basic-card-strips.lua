-- Regression pin for audit finding #6 (re-analyzed: not a bug).
--
-- xy's tech_remove_cards / tech_remove_preqs remove entries via
-- table.remove inside a forward pairs scan - the pattern the audit flagged
-- as "skips adjacent entries". Re-analysis: the scan RESTARTS for every
-- target value, so distinct entries are all visited; the skip can only
-- occur when the same value appears twice, which technology ingredients /
-- prerequisite lists cannot contain. This test executes the fork's real
-- util/util.lua against the exact shape from the audit
-- ({logistic, military, automation} adjacent) and pins the correct result.
--
-- Usage: lua tests/lua/run-basic-card-strips.lua [path-to-xy-zip]

local script_dir = arg[0]:gsub("[^%/]*$", "")
package.path = script_dir .. "?.lua;" .. package.path
local env_mod = require("xy-env")

local zip = arg[1]
  or (os.getenv("HOME") .. "/Library/Application Support/factorio/mods/xy-k2so-enhancements-nulls-fork_0.8.5.zip")

local function fail(msg)
  print("E2E_CHECK::fail " .. msg)
  os.exit(1)
end

-- Shape from the audit: all three target cards adjacent, one late card at
-- the end that must survive.
local tech = {
  ["craptonite-productivity"] = {
    unit = {
      ingredients = {
        { "logistic-science-pack", 1 },
        { "military-science-pack", 1 },
        { "automation-science-pack", 1 },
        { "space-science-pack", 1 },
      },
    },
  },
}

local utils = env_mod.load_xy_util(zip, tech)
utils.tech_remove_cards("craptonite-productivity", {
  "logistic-science-pack",
  "military-science-pack",
  "automation-science-pack",
  "chemical-science-pack",
})

local remaining = {}
for _, card in ipairs(tech["craptonite-productivity"].unit.ingredients) do
  remaining[#remaining + 1] = card[1]
end
local joined = table.concat(remaining, ",")
print("E2E_CHECK::strips.remaining=" .. joined)
if joined ~= "space-science-pack" then
  fail("expected only space-science-pack left, got: " .. joined)
end

-- Same shape for prerequisites.
local tech2 = {
  ["x"] = { prerequisites = { "a", "b", "c", "keep-me" } },
}
local utils2 = env_mod.load_xy_util(zip, tech2)
utils2.tech_remove_preqs("x", { "a", "b", "c" })
local remaining2 = {}
for _, pre in ipairs(tech2["x"].prerequisites) do
  remaining2[#remaining2 + 1] = pre
end
local joined2 = table.concat(remaining2, ",")
print("E2E_CHECK::preq-strips.remaining=" .. joined2)
if joined2 ~= "keep-me" then
  fail("expected only keep-me left, got: " .. joined2)
end

print("E2E_CHECK::verdict=PASS")
