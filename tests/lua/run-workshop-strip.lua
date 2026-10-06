-- E2E for audit finding #7: xy's workshop-science strip loop.
--
-- xy's patches/technology.lua is executed UNCHANGED (read straight out of
-- the installed zip) against mock technologies, then PATCHED (via
-- patches/upstream/xy-k2so-enhancements-nulls-fork/workshop-strip.patch
-- applied to a temp copy of the zip) and executed again. The original must demonstrate the over-strip
-- (workshop card removed from a tech that contains automation-science-pack
-- not in first position); the patched run must keep it.
--
-- Usage: lua tests/lua/run-workshop-strip.lua [path-to-xy-zip]

local script_dir = arg[0]:gsub("[^%/]*$", "")
package.path = script_dir .. "?.lua;" .. package.path
local env_mod = require("xy-env")

local MODS_DIR = os.getenv("HOME") .. "/Library/Application Support/factorio/mods"
local zip = arg[1] or (MODS_DIR .. "/xy-k2so-enhancements-nulls-fork_0.8.5.zip")
local patch_file = script_dir:gsub("tests/lua/$",
  "patches/upstream/xy-k2so-enhancements-nulls-fork/workshop-strip.patch")
if patch_file:sub(1, 1) ~= "/" then
  local pwd = assert(io.popen("pwd")):read("l")
  patch_file = pwd .. "/" .. patch_file
end

local function fail(msg)
  print("E2E_CHECK::fail " .. msg)
  os.exit(1)
end

local function make_techs()
  return {
    ["e2e-basic"] = {
      name = "e2e-basic",
      unit = { ingredients = { { "workshop-science-pack", 1 }, { "logistic-science-pack", 1 } } },
    },
    ["e2e-auto-first"] = {
      name = "e2e-auto-first",
      unit = { ingredients = { { "automation-science-pack", 1 }, { "workshop-science-pack", 1 } } },
    },
    ["e2e-auto-second"] = {
      name = "e2e-auto-second",
      unit = { ingredients = { { "workshop-science-pack", 1 }, { "automation-science-pack", 1 } } },
    },
    ["e2e-no-unit"] = { name = "e2e-no-unit", hidden = false },
  }
end

local function has_card(unit, name)
  for _, card in ipairs(unit.ingredients) do
    if card[1] == name then return true end
  end
  return false
end

--- Executes xy's technology.lua against a fresh mock world.
--- @param tech_source string  full lua source of patches/technology.lua
--- @return table techs
local function run_xy_technology_lua(tech_source)
  local techs = make_techs()
  local data = { raw = { technology = techs } }

  local env
  local fake_settings = { value = false }
  env = setmetatable({
    data = data,
    mods = { ["workshop-science"] = "1.0.0" },
    settings = {
      startup = setmetatable({}, {
        __index = function()
          -- every startup setting reads as { value = false }
          return fake_settings
        end,
      }),
    },
    log = function() end,
    require = function(name)
      assert(name == "util.util", "unexpected require: " .. tostring(name))
      local util_source = env_mod.read_zip_member(zip, "util/util.lua")
      return env_mod.load_env(util_source, env, "@xy/util/util.lua")()
    end,
  }, { __index = _G })

  env_mod.load_env(tech_source, env, "@xy/patches/technology.lua")()
  return techs
end

local function report(tag, tech)
  print(("E2E_CHECK::%s=%s"):format(tag, has_card(tech.unit, "workshop-science-pack") and "kept" or "stripped"))
end

-- Original, straight from the installed zip.
local orig = run_xy_technology_lua(env_mod.read_zip_member(zip, "patches/technology.lua"))
report("orig.t1_basic", orig["e2e-basic"])
report("orig.t2_auto_first", orig["e2e-auto-first"])
report("orig.t3_auto_second", orig["e2e-auto-second"])

-- Intended strips must already work, and the over-strip must be present.
if has_card(orig["e2e-basic"].unit, "workshop-science-pack") then
  fail("original did not strip workshop from an automation-free tech (intent)")
end
if not has_card(orig["e2e-auto-first"].unit, "workshop-science-pack") then
  fail("original stripped workshop when automation is first ingredient")
end
if has_card(orig["e2e-auto-second"].unit, "workshop-science-pack") then
  fail("NO BUG: original kept workshop for automation-not-first; patch would be a no-op")
end
print("E2E_CHECK::orig.bug=demonstrated")

-- Patched: apply the upstream patch to a temp copy of the zip.
local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute(string.format("mkdir -p %q && unzip -q %q -d %q", tmp, zip, tmp)))
local mod_root = tmp .. "/xy-k2so-enhancements-nulls-fork_0.8.5"
local ok = os.execute(string.format("cd %q && patch -s -p1 < %q", mod_root, patch_file))
if not ok then fail("patch does not apply cleanly against the installed zip") end
local top = mod_root .. "/patches/technology.lua"
local fh = assert(io.open(top, "r"))
local patched_source = assert(fh:read("a"))
fh:close()

local patched = run_xy_technology_lua(patched_source)
report("patched.t1_basic", patched["e2e-basic"])
report("patched.t2_auto_first", patched["e2e-auto-first"])
report("patched.t3_auto_second", patched["e2e-auto-second"])

if has_card(patched["e2e-basic"].unit, "workshop-science-pack") then
  fail("patched version no longer strips workshop from automation-free techs")
end
if not has_card(patched["e2e-auto-first"].unit, "workshop-science-pack") then
  fail("patched version regressed automation-first case")
end
if not has_card(patched["e2e-auto-second"].unit, "workshop-science-pack") then
  fail("patched version still over-strips automation-not-first techs")
end

os.execute(string.format("rm -rf %q", tmp))
print("E2E_CHECK::verdict=PASS")
