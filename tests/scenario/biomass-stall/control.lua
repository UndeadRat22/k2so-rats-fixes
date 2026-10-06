-- E2E test: K2SO biomass spoilage inheritance in the bioprocessing facility.
--
-- Run via the harness in e2e/run-e2e.sh:
--   1. factorio --scenario2map biomass-stall   (creates a save at tick 0)
--   2. factorio --benchmark <save> --benchmark-ticks N (drives the test)
--
-- The test:
--   * places a kr-bio-lab, powers it, fills its input fluid boxes,
--   * seeds 2 kr-biomass aged to 90% spoiled into the input,
--   * lets the machine craft the recursive kr-biomass recipe (2 aged -> 5),
--   * measures the output freshness (inheritance => ~90% spoiled),
--   * recycles 2 of the outputs back into the input, crafts again,
--     and measures again (loop never recovers without a fix),
--   * writes e2e-biomass/result.json with measurements + verdict.
--
-- Expected verdicts:
--   BUG_REPRODUCED (no fix mod): outputs inherit parent spoilage and the
--     freshness never recovers through the loop -> pipeline stalls.
--   FIXED (with K2SO-Fixes): outputs are always fully fresh.

local RESULT_FILE = "e2e-biomass/result.json"
local TIMEOUT_TICK = 15000
local STALL_CHECK_TICK = 900 -- if craft 1 hasn't started by now, try fluid swap

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

local function stack_snapshot(s)
  if not (s and s.valid_for_read) then return nil end
  return {
    name = s.name,
    count = s.count,
    spoil_percent = s.spoil_percent,
    spoil_tick = s.spoil_tick,
    ticks_left = (s.spoil_tick ~= 0) and (s.spoil_tick - game.tick) or nil,
  }
end

local function inv_snapshot(lab, def_name)
  return safe(function()
    local inv = lab.get_inventory(defines.inventory[def_name])
    local out = {}
    for i = 1, #inv do
      local s = stack_snapshot(inv[i])
      if s then table.insert(out, s) end
    end
    return out
  end)
end

local function fluidbox_snapshot(lab)
  return safe(function()
    local out = {}
    for i = 1, 3 do
      local ok, f = pcall(function() return lab.get_fluid(i) end)
      out[i] = (ok and f) and { name = f.name, amount = f.amount } or nil
    end
    return out
  end)
end

local STATUS_NAMES = {}
for k, v in pairs(defines.entity_status) do STATUS_NAMES[v] = k end

local function machine_diag(lab)
  return {
    valid = lab and lab.valid or false,
    status = safe(function() return STATUS_NAMES[lab.status] or tostring(lab.status) end),
    is_crafting = safe(function() return lab.is_crafting() end),
    progress = safe(function() return lab.crafting_progress end),
    inventories = {
      input = inv_snapshot(lab, "crafter_input"),
      output = inv_snapshot(lab, "crafter_output"),
    },
    fluidboxes = fluidbox_snapshot(lab),
  }
end

local function output_biomass(lab)
  local out = lab.get_inventory(defines.inventory.crafter_output)
  for i = 1, #out do
    local s = out[i]
    if s.valid_for_read and s.name == "kr-biomass" then
      return s, out
    end
  end
  return nil, out
end

local function finish(g, verdict, message)
  local result = {
    verdict = verdict,
    message = message,
    fix_mod_present = (script.active_mods["K2SO-Fixes"] ~= nil),
    active_mods = script.active_mods,
    tick = game.tick,
    item_info = {
      spoil_ticks = safe(function() return prototypes.item["kr-biomass"].spoil_ticks end),
      spoil_result = safe(function() return prototypes.item["kr-biomass"].spoil_result.name end),
    },
    recipe_product = safe(function()
      for _, p in pairs(prototypes.recipe["kr-biomass"].products) do
        if p.type == "item" and p.name == "kr-biomass" then
          return { always_fresh = p.always_fresh, percent_spoiled = p.percent_spoiled }
        end
      end
      return nil
    end),
    seed = g.seed,
    craft1 = g.craft1,
    craft2 = g.craft2,
    fluid_swap_attempted = g.fluid_swap_attempted or false,
    machine_diag = g.lab and g.lab.valid and machine_diag(g.lab) or nil,
  }
  local json = to_json(result)
  helpers.write_file(RESULT_FILE, json)
  print("[e2e-biomass] " .. tostring(verdict) .. ": " .. tostring(message))
end

local function setup(g)
  local force = game.forces["player"]
  local surface = game.surfaces["nauvis"] or game.surfaces[1]

  force.recipes["kr-biomass"].enabled = true

  local pos = surface.find_non_colliding_position("kr-bio-lab", { 0, 0 }, 64, 1)
  if not pos then error("no free position for kr-bio-lab") end
  local lab = surface.create_entity { name = "kr-bio-lab", position = pos, force = force }
  if not (lab and lab.valid) then error("failed to create kr-bio-lab") end

  -- Power: substation + electric-energy-interface as an infinite source.
  local pole_pos = surface.find_non_colliding_position("substation", { pos.x + 5, pos.y + 5 }, 16, 1)
    or { x = pos.x + 5, y = pos.y + 5 }
  local pole = surface.create_entity { name = "substation", position = pole_pos, force = force }
  if not (pole and pole.valid) then error("failed to create substation") end

  local eei_pos = surface.find_non_colliding_position("electric-energy-interface",
    { pole_pos.x + 2, pole_pos.y + 2 }, 16, 1) or { x = pole_pos.x + 2, y = pole_pos.y + 2 }
  local eei = surface.create_entity { name = "electric-energy-interface", position = eei_pos, force = force }
  if not (eei and eei.valid) then error("failed to create electric-energy-interface") end
  safe(function() eei.power_production = 100000000 end) -- 100 MW
  safe(function() eei.power_usage = 0 end)
  safe(function() eei.energy = 1000000000 end)      -- pre-charge the buffer

  g.lab = lab
  g.positions = { lab = pos, pole = pole_pos, eei = eei_pos }

  -- Recipe + fluids. The recipe needs petroleum-gas (50) + kr-oxygen (50).
  -- After set_recipe the input fluid storages are locked to the recipe
  -- fluids (readable via get_fluid_filter); fill them accordingly.
  lab.set_recipe("kr-biomass")
  g.fluid_errors = {}
  local function wanted(index, fallback)
    local ok, filter = pcall(function() return lab.get_fluid_filter(index) end)
    return (ok and filter and filter.name) or fallback
  end
  local order = {
    wanted(1, "petroleum-gas"),
    wanted(2, "kr-oxygen"),
  }
  g.fluid_order = order
  for i = 1, 2 do
    local ok, err = pcall(function() lab.set_fluid(i, { name = order[i], amount = 500 }) end)
    if not ok then table.insert(g.fluid_errors, tostring(err)) end
  end

  -- Seed the loop with 2 biomass aged to 90% spoiled (1h spoil time, 10% left).
  local inv = lab.get_inventory(defines.inventory.crafter_input)
  inv.insert({ name = "kr-biomass", count = 2 })
  for i = 1, #inv do
    local s = inv[i]
    if s.valid_for_read and s.name == "kr-biomass" then
      s.spoil_tick = game.tick + 21600 -- 216000 * 0.1 remaining
    end
  end

  g.seed = {
    tick = game.tick,
    expected_spoil_percent = 0.9,
    input = inv_snapshot(lab, "crafter_input"),
    fluidboxes = fluidbox_snapshot(lab),
    fluid_errors = g.fluid_errors,
  }
end

local function try_fluid_swap(lab)
  return safe(function()
    local a = lab.get_fluid(1)
    local b = lab.get_fluid(2)
    local an = a and a.name or nil
    local bn = b and b.name or nil
    if an and bn then
      lab.set_fluid(1, { name = bn, amount = 500 })
      lab.set_fluid(2, { name = an, amount = 500 })
      return { swapped = { an, bn } }
    end
    return { swapped = nil, box1 = an, box2 = bn }
  end)
end

local function recycle_output_to_input(lab)
  local out_inv = lab.get_inventory(defines.inventory.crafter_output)
  local in_inv = lab.get_inventory(defines.inventory.crafter_input)
  local recycled = nil
  local method = nil

  for i = 1, #out_inv do
    local s = out_inv[i]
    if s.valid_for_read and s.name == "kr-biomass" then
      recycled = stack_snapshot(s)
      local ok = pcall(function() in_inv.transfer_from_stack(s, 2) end)
      if ok and in_inv.get_item_count("kr-biomass") >= 2 then
        method = "transfer_from_stack"
      else
        local target = in_inv.find_empty_stack("kr-biomass") or in_inv.find_empty_stack()
        if target and target.transfer_stack(s, 2) then
          method = "transfer_stack"
        end
      end
      break
    end
  end

  -- Ensure exactly 2 recycled items regardless of transfer API quirks.
  local excess = in_inv.get_item_count("kr-biomass") - 2
  if excess > 0 then
    in_inv.remove({ name = "kr-biomass", count = excess })
  end

  -- Remove leftovers so craft 2's output is a clean new stack.
  -- (remove() with a nil count removes nothing, so pass an explicit count.)
  local leftovers = out_inv.get_item_count("kr-biomass")
  if leftovers > 0 then
    out_inv.remove({ name = "kr-biomass", count = leftovers })
  end
  return recycled, method, in_inv.get_item_count("kr-biomass")
end

local function on_tick(_)
  local g = storage
  if g.done then return end
  local tick = game.tick

  if tick > TIMEOUT_TICK then
    g.done = true
    finish(g, "ERROR", "timeout in phase " .. tostring(g.phase))
    return
  end

  if not g.setup_done then
    local surface = game.surfaces["nauvis"] or game.surfaces[1]
    -- Stage 1: request origin chunks, then wait until they are generated
    -- (chunk generation happens asynchronously over the next few ticks).
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
    g.phase = "craft1"
    return
  end

  local lab = g.lab
  if not (lab and lab.valid) then
    g.done = true
    finish(g, "ERROR", "kr-bio-lab lost")
    return
  end

  -- Craft 1 hasn't started: probably wrong fluid -> box assignment. Swap once.
  if g.phase == "craft1" and not g.craft1_started and tick == STALL_CHECK_TICK then
    local out = lab.get_inventory(defines.inventory.crafter_output)
    if out.get_item_count("kr-biomass") == 0 and lab.is_crafting() ~= true then
      g.fluid_swap_attempted = true
      g.fluid_swap_result = try_fluid_swap(lab)
    end
  end

  if g.phase == "craft1" then
    local s = output_biomass(lab)
    if s then
      g.craft1_started = true
      g.craft1 = g.craft1 or {}
      g.craft1.output = stack_snapshot(s)
      g.craft1.done_tick = tick
      local recycled, method, moved = recycle_output_to_input(lab)
      g.craft1.recycled = recycled
      g.craft1.recycle_method = method
      g.craft1.recycled_into_input = moved
      g.phase = "craft2"
    end
    return
  end

  if g.phase == "craft2" then
    local s = output_biomass(lab)
    -- A completed craft adds a full stack of 5; ignore leftovers from craft 1.
    if s and s.count >= 5 then
      g.craft2 = { output = stack_snapshot(s), done_tick = tick }
      g.done = true

      local o1 = g.craft1.output
      local o2 = g.craft2.output
      local inherits = o1.spoil_percent > 0.5
      local never_recovers = (o2.spoil_percent + 0.01) >= o1.spoil_percent
      local fresh = o1.spoil_percent < 0.05 and o2.spoil_percent < 0.05

      local verdict
      if fresh then
        verdict = "FIXED"
      elseif inherits and never_recovers then
        verdict = "BUG_REPRODUCED"
      else
        verdict = "INCONCLUSIVE"
      end

      finish(g, verdict, string.format(
        "craft1 output %.1f%% spoiled, craft2 output %.1f%% spoiled (seed was 90%% spoiled)",
        o1.spoil_percent * 100, o2.spoil_percent * 100))
    end
  end
end

script.on_init(function()
  -- Factorio 2.1: mod storage is `storage` (formerly `global`).
  storage = storage or {}
  -- Setup deliberately does not run here: it runs on the first tick of the
  -- benchmark so that everything (entities, fluids, aged seed) is created
  -- live, not baked into the map.
end)

script.on_load(function()
  -- nothing to restore; handlers below are registered either way
end)

script.on_event(defines.events.on_tick, on_tick)
