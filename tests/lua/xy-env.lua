-- Shared environment loader for lua-level e2e checks against the *actual*
-- files shipped inside the installed xy-k2so-enhancements-nulls-fork zip.
-- The fork's data-stage files run against a mocked `data` global shaped
-- like the Factorio data stage plus seeded mock technologies.
--
-- Lua 5.3+/5.4 (stock homebrew lua) only.

local M = {}

--- @param zip_path string
--- @param inner string  inner file path inside the zip
--- @return string
function M.read_zip_member(zip_path, inner)
  -- Match by suffix so we don't depend on the top-level folder name.
  local list = assert(io.popen(string.format("unzip -Z1 %q '%s'", zip_path, "*")))
  local found = nil
  for line in list:lines() do
    if line:sub(- #inner) == inner then
      found = line
      break
    end
  end
  list:close()
  assert(found, "zip member not found: " .. inner)
  local fh = assert(io.popen(string.format("unzip -p %q %q", zip_path, found)))
  local content = assert(fh:read("a"))
  fh:close()
  return content
end

--- @param source string
--- @param env table
--- @param chunkname string
--- @return function
function M.load_env(source, env, chunkname)
  local fn, err = load(source, chunkname, "t", env)
  assert(fn, err)
  return fn
end

--- Loads xy's util/util.lua against a seeded data.raw.technology table;
--- returns (utils_module, env).
--- @param zip_path string
--- @param technologies table  content for data.raw.technology
function M.load_xy_util(zip_path, technologies)
  local data = { raw = { technology = technologies } }
  local env = setmetatable({
    data = data,
    mods = {},
    settings = { startup = {} },
    log = function(msg) print("[mock-log] " .. tostring(msg)) end,
  }, { __index = _G })
  local source = M.read_zip_member(zip_path, "util/util.lua")
  local utils = M.load_env(source, env, "@xy/util/util.lua")()
  return utils, env
end

return M
