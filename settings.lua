-- Startup settings for k2so-rats-fixes.
--
-- Asteroid radiation immunity: K2SO grants every asteroid 100% kr-radioactive
-- resistance so radiation weapons stay useless against asteroids. With weapon
-- mods that lean on kr-radioactive damage (eRisel-k2-arsenal) full immunity
-- removes a whole weapon class again, so the target value is configurable.
-- "auto" keeps K2SO's 100% and drops to 50% when eRisel-k2-arsenal is
-- installed; the explicit values always win over the automatic pick.
--
-- Greenhouse+ glass: k2-greenhouse-plus ships its own k2gp-sand/k2gp-glass
-- chain by default, duplicating K2's identical kr-sand/kr-glass chain when
-- both mods are installed. Enabled (default) unifies them into K2's.
data:extend({
  {
    type = "string-setting",
    name = "k2so-rats-fixes-asteroid-radiation-immunity",
    setting_type = "startup",
    default_value = "auto",
    allowed_values = { "auto", "100", "75", "50", "25", "0" },
    order = "aa-asteroid-radiation-immunity",
  },
  {
    type = "bool-setting",
    name = "k2so-rats-fixes-greenhouse-plus-k2-glass",
    setting_type = "startup",
    default_value = true,
    order = "ab-greenhouse-plus-k2-glass",
  },
})
