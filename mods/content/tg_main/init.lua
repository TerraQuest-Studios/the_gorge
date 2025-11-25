local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

tg_main = {}

-- Either "flat" or "singlenode".
tg_main.mg_name = core.get_mapgen_setting("mg_name") or "singlenode"
-- Enter dev mode if mapgen "flat" or creative setting is `true`.
-- This stops normal gameplay functions from running.
tg_main.dev_mode = true -- (tg_main.mg_name == "flat") or core.is_creative_enabled()
-- Skip intro if on mapgen "flat".
tg_main.skip_intro = true --(tg_main.mg_name == "flat")

dofile(mod_path .. "/scripts" .. "/math.lua")
dofile(mod_path .. "/scripts" .. "/debug.lua")
