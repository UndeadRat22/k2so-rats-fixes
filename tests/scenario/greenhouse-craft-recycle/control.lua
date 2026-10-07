-- E2E test: k2-greenhouse-plus sand/glass unification (physical flow).
--
-- Run via the harness in tests/run-e2e-greenhouse.sh:
--   1. factorio --scenario2map greenhouse-craft-recycle
--   2. factorio --benchmark <save> --benchmark-ticks N (drives the test)
--
-- The test:
--   * places a powered assembling machine and sets k2gp-greenhouse-for-tree,
--   * reads the recipe's glass ingredient at runtime (k2gp-glass 24x or
--     kr-glass 20x) and feeds in enough ingredients for 2 crafts,
--   * measures which glass item is physically consumed,
--   * recycles both crafted greenhouses and tallies the output items,
--   * writes e2e-greenhouse/result.json with measurements + verdict.
--
-- Expected verdicts:
--   BUG_REPRODUCED (no fix mod): the recipe demands k2gp-glass and recycling
--     returns k2gp-glass - the duplicate private chain is live.
--   FIXED (with k2so-rats-fixes): the recipe demands kr-glass, recycling
--     returns kr-glass, and no k2gp-sand/k2gp-glass leak anywhere.

local RESULT_FILE = "e2e-greenhouse/result.json"
local TIMEOUT_TICK = 7800
local BUILDING_RECIPE = "k2gp-greenhouse-for-tree"
local BUILDING_ITEM = "k2gp-greenhouse-for-tree"
local CRAFTS = 2

-- Minimal JSON serializer (Factorio 2.1 scenarios have no write_json helper).
local function to_json(v)
  local t = type(v)
  if v == nil then
    return "null"
  elseif t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return "null" end
    return string.format("%.14g", v)
  elseif t == "boolean" then
    return tostring(v)
  elseif t == "string" then
    return '"' .. v:gsub('[%c"\\]', function(c)
      return string.format("\\u%04x", c:byte())
    end) .. '"'
  elseif t == "table" then
    local n = #v
    if n > 0 then
      local parts = {}
      for i = 1, n do parts[i] = to_json(v[i]) end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      local parts = {}
      for k, val in pairs(v) do
        if type(k) == "string" then
          parts[#parts + 1] = to_json(k) .. ":" .. to_json(val)
        end
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  else
    return '"' .. tostring(v) .. '"'
  end
end

local function safe(fn, ...)
  local ok, res = pcall(fn, ...)
  if ok then return res end
  return "__error__:" .. tostring(res)
end

local function finish(g, verdict, message)
  local result = {
    verdict = verdict,
    message = message,
    fix_mod_present = (script.active_mods["k2so-rats-fixes"] ~= nil),
    tick = game.tick,
    glass_ingredient = g.glass,
    glass_inserted = g.glass_inserted,
    glass_leftover = g.glass_leftover,
    glass_consumed = g.glass_consumed,
    crafted = g.crafted,
    recycler_outputs = g.recycler_outputs,
    k2gp_leak = g.k2gp_leak,
    inventory_errors = g.inventory_errors,
    recycler_diag = g.recycler_diag,
  }
  helpers.write_file(RESULT_FILE, to_json(result))
  print("[e2e-greenhouse] " .. tostring(verdict) .. ": " .. tostring(message))
end

local function setup(g)
  local force = game.forces["player"]
  local surface = game.surfaces["nauvis"] or game.surfaces[1]

  force.recipes[BUILDING_RECIPE].enabled = true
  -- Recycling recipes are gated behind research in a real game; enable the
  -- building's one explicitly so the physical flow can be measured.
  local recycling_recipe = force.recipes[BUILDING_RECIPE .. "-recycling"]
  if recycling_recipe then
    recycling_recipe.enabled = true
  end

  -- Power: substation + electric-energy-interface as an infinite source.
  local pole_pos = surface.find_non_colliding_position("substation", { 4, 4 }, 32, 1) or { 4, 4 }
  local pole = surface.create_entity { name = "substation", position = pole_pos, force = force }
  if not (pole and pole.valid) then error("failed to create substation") end

  local eei_pos = surface.find_non_colliding_position("electric-energy-interface",
    { pole_pos.x + 2, pole_pos.y + 2 }, 16, 1) or { x = pole_pos.x + 2, y = pole_pos.y + 2 }
  local eei = surface.create_entity { name = "electric-energy-interface", position = eei_pos, force = force }
  if not (eei and eei.valid) then error("failed to create electric-energy-interface") end
  safe(function() eei.power_production = 100000000 end)
  safe(function() eei.power_usage = 0 end)
  safe(function() eei.energy = 1000000000 end)

  -- Assembler for the building recipe (category "crafting").
  local asm_pos = surface.find_non_colliding_position("assembling-machine-3", { 0, 0 }, 32, 1)
  if not asm_pos then error("no free position for assembling-machine-3") end
  local asm = surface.create_entity { name = "assembling-machine-3", position = asm_pos, force = force }
  if not (asm and asm.valid) then error("failed to create assembling-machine-3") end

  -- Recycler next to it.
  local rec_pos = surface.find_non_colliding_position("recycler",
    { asm_pos.x + 4, asm_pos.y }, 16, 1) or { x = asm_pos.x + 4, y = asm_pos.y }
  local rec = surface.create_entity { name = "recycler", position = rec_pos, force = force }
  if not (rec and rec.valid) then error("failed to create recycler") end

  g.assembler = asm
  g.recycler = rec

  -- Which glass does the recipe actually demand? (24x k2gp-glass in the bug
  -- state, 20x kr-glass once unified.)
  g.glass = safe(function()
    for _, ingredient in pairs(prototypes.recipe[BUILDING_RECIPE].ingredients) do
      if ingredient.name == "k2gp-glass" or ingredient.name == "kr-glass" or ingredient.name == "iron-plate" then
        return { name = ingredient.name, amount = ingredient.amount }
      end
    end
    return nil
  end)
  if type(g.glass) == "string" then error("reading ingredients failed: " .. g.glass) end
  if not g.glass then error("no glass ingredient in " .. BUILDING_RECIPE) end

  -- Feed exactly CRAFTS batches of every ingredient.
  asm.set_recipe(BUILDING_RECIPE)
  local input = asm.get_inventory(defines.inventory.crafter_input)
  for _, ingredient in pairs(prototypes.recipe[BUILDING_RECIPE].ingredients) do
    if ingredient.type == "item" then
      input.insert({ name = ingredient.name, count = ingredient.amount * CRAFTS })
    end
  end
  g.glass_inserted = g.glass.amount * CRAFTS
end

local function inventory_counts(inv)
  local counts = {}
  for i = 1, #inv do
    local s = inv[i]
    if s.valid_for_read then
      counts[s.name] = (counts[s.name] or 0) + s.count
    end
  end
  return counts
end

local function on_tick(_)
  local g = storage
  if g.done then return end
  local tick = game.tick

  if tick > TIMEOUT_TICK then
    g.done = true
    local rec = g.recycler
    g.recycler_diag = (rec and rec.valid) and {
      status = safe(function() return tostring(rec.status) end),
      is_crafting = safe(function() return rec.is_crafting() end),
      queued = safe(function()
        return rec.get_inventory(defines.inventory.crafter_input).get_item_count(BUILDING_ITEM)
      end),
      outputs = safe(function()
        return inventory_counts(rec.get_inventory(defines.inventory.crafter_output))
      end),
    } or nil
    finish(g, "ERROR", "timeout in phase " .. tostring(g.phase))
    return
  end

  if not g.setup_done then
    local surface = game.surfaces["nauvis"] or game.surfaces[1]
    -- Stage 1: request origin chunks, then wait until they are generated.
    if not g.chunks_requested then
      surface.request_to_generate_chunks({ 0, 0 }, 3)
      g.chunks_requested = true
      return
    end
    if not surface.is_chunk_generated({ 0, 0 }) then
      return
    end
    local ok, err = pcall(setup, g)
    if not ok then
      g.done = true
      finish(g, "ERROR", "setup failed: " .. tostring(err))
      return
    end
    g.setup_done = true
    g.phase = "craft"
    return
  end

  local asm = g.assembler
  local rec = g.recycler
  if not (asm and asm.valid and rec and rec.valid) then
    g.done = true
    finish(g, "ERROR", "machine lost")
    return
  end

  if g.phase == "craft" then
    local out = asm.get_inventory(defines.inventory.crafter_output)
    local built = out.get_item_count(BUILDING_ITEM)
    if built >= CRAFTS then
      -- Measure the glass that was consumed.
      local input = asm.get_inventory(defines.inventory.crafter_input)
      g.glass_leftover = input.get_item_count(g.glass.name)
      g.glass_consumed = g.glass_inserted - g.glass_leftover

      -- Move the buildings into the recycler.
      g.inventory_errors = {}
      local rec_in
      local rec_out
      local ok_in, res_in = pcall(function() return rec.get_inventory(defines.inventory.crafter_input) end)
      local ok_out, res_out = pcall(function() return rec.get_inventory(defines.inventory.crafter_output) end)
      if ok_in and res_in then
        rec_in = res_in
      else
        table.insert(g.inventory_errors, "recycler input: " .. tostring(res_in))
      end
      if ok_out and res_out then
        rec_out = res_out
      else
        table.insert(g.inventory_errors, "recycler output: " .. tostring(res_out))
      end
      if not (rec_in and rec_out) then
        g.done = true
        finish(g, "ERROR", "recycler inventory access failed: " .. table.concat(g.inventory_errors, "; "))
        return
      end
      rec_in.insert({ name = BUILDING_ITEM, count = built })
      out.remove({ name = BUILDING_ITEM, count = built })
      g.crafted = built
      g.phase = "recycle"
    end
    return
  end

  if g.phase == "recycle" then
    local rec_in = rec.get_inventory(defines.inventory.crafter_input)
    local rec_out = rec.get_inventory(defines.inventory.crafter_output)
    local still_queued = rec_in.get_item_count(BUILDING_ITEM)
    local outputs = inventory_counts(rec_out)
    local total = 0
    for _, count in pairs(outputs) do total = total + count end
    -- Done when the recycler consumed everything, finished its current
    -- craft and dropped output.
    if still_queued == 0 and total > 0 and rec.is_crafting() ~= true then
      g.recycler_outputs = outputs
      g.k2gp_leak = (outputs["k2gp-glass"] or 0) + (outputs["k2gp-sand"] or 0)

      local unified = g.glass.name == "kr-glass" and g.glass.amount == 20
        and g.glass_consumed == 40 and (outputs["kr-glass"] or 0) > 0 and g.k2gp_leak == 0
      local broken = g.glass.name == "k2gp-glass" and g.glass_consumed == 48
        and (outputs["k2gp-glass"] or 0) > 0

      local verdict
      if unified then
        verdict = "FIXED"
      elseif broken then
        verdict = "BUG_REPRODUCED"
      else
        verdict = "INCONCLUSIVE"
      end
      g.done = true
      finish(g, verdict, string.format(
        "glass %s x%d (consumed %d), recycler yielded kr-glass=%d k2gp-glass=%d",
        g.glass.name, g.glass.amount, g.glass_consumed,
        outputs["kr-glass"] or 0, outputs["k2gp-glass"] or 0))
    end
  end
end

script.on_init(function()
  -- Factorio 2.1: mod storage is `storage` (formerly `global`).
  storage = storage or {}
  -- Setup deliberately does not run here: it runs on the first tick of the
  -- benchmark so that everything is created live, not baked into the map.
end)

script.on_load(function()
  -- nothing to restore; handlers below are registered either way
end)

script.on_event(defines.events.on_tick, on_tick)
