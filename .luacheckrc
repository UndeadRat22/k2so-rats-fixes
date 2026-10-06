-- Lint configuration for k2so-rats-fixes.
--
-- Factorio mods run on a modified Lua 5.2 (see
-- https://lua-api.factorio.com/latest/auxiliary/libraries.html): io, os,
-- coroutine and loadfile are unavailable at runtime, string.pack/unpack are
-- backported from Lua 5.4.6, and pairs() is deterministic. The default std
-- here is therefore lua52, NOT the host interpreter's version (the local
-- `lua` is 5.5, which luacheck only uses to run tests/lua harnesses).
--
-- Toolchain note: luacheck 1.2.0 crashes under real Lua 5.5 ("attempt to
-- assign to const variable" — 5.5 made for-loop control variables read-only;
-- fix exists on git master but is unreleased). `make lint` expects the
-- lua@5.4 build:
--   luarocks --lua-version=5.4 --lua-dir="$(brew --prefix lua@5.4)" \
--       --tree="$(brew --prefix)" install luacheck

std = "lua52"
max_line_length = 120

-- Data stage: mods run in dependency order with `data` (writable prototype
-- registry) and `mods` (enabled-mod table) as globals, plus log/serpent.
stds.factorio_data = {
   globals = {
      data = { other_fields = true },
      mods = { other_fields = true },
   },
   read_globals = {
      log = {},
      serpent = { other_fields = true },
      settings = { other_fields = true },
      defines = { other_fields = true }, -- available in the data stage too
      -- Factorio patches the table library (table.deepcopy, table_size, ...).
      table = { other_fields = true },
   },
}

-- Runtime stage: scenario control.lua files.
stds.factorio_runtime = {
   globals = {
      storage = { other_fields = true },
   },
   read_globals = {
      -- game is writable: scenarios legitimately mutate state (force
      -- recipes, cheat items) during setup.
      game = { other_fields = true, read_only = false },
      script = { other_fields = true },
      defines = { other_fields = true },
      prototypes = { other_fields = true },
      helpers = { other_fields = true },
      remote = { other_fields = true },
      rendering = { other_fields = true },
      commands = { other_fields = true },
      settings = { other_fields = true },
      log = {},
      serpent = { other_fields = true },
   },
}

files["data-final-fixes.lua"].std = "lua52+factorio_data"
files["settings.lua"].std = "lua52+factorio_data"
files["fixes/*.lua"].std = "lua52+factorio_data"
files["tests/proto/**/*.lua"].std = "lua52+factorio_data"
files["tests/scenario/**/*.lua"].std = "lua52+factorio_runtime"
-- tests/lua/*.lua run under the host interpreter (real Lua), so they may use
-- io/os freely; keep the plain lua52 std for them.
files["tests/lua/*.lua"].std = "lua52"
