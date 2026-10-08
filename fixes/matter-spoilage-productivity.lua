-- Krastorio2-spaced-out-tweaks: spoilage <-> matter productivity loop.
--
-- The tweaks mod adds a spoilage sink (kr-spoilage-to-matter: 100 spoilage
-- -> 5.2 matter) with allow_productivity = true, while its exact quantity
-- mirror (kr-matter-to-spoilage: 5.2 matter -> 100 spoilage) disallows
-- productivity. Both run in the matter plant / matter associator, which
-- accept productivity modules (matter plant: 4 slots, productivity in
-- allowed_effects). Because the pair is a closed quantity mirror, every
-- round trip multiplies the stock by (1 + productivity bonus): with four
-- productivity module 3s that is x1.4 per cycle, compounding forever.
-- Matter converts into essentially every resource K2(SO) knows, so a seed
-- stock of spoilage becomes free exponential everything.
--
-- K2's own matter library deliberately leaves allow_productivity unset
-- (default false) on every conversion/deconversion recipe it creates; the
-- tweaks pair is the only exception in the stack. This fix re-aligns it
-- with the library's convention. The recipes themselves are untouched
-- otherwise, and the sink still works - it just cannot be amplified into a
-- matter printer by productivity modules anymore.

local recipe = data.raw.recipe["kr-spoilage-to-matter"]
if not recipe then
  return
end

recipe.allow_productivity = false
log("[k2so-rats-fixes] disabled productivity on kr-spoilage-to-matter (matter <-> spoilage amplification loop)")
