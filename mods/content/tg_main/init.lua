local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

tg_main = {
	mg_name = nil,
    dev_mode = false,
}

tg_main.mg_name = core.get_mapgen_setting("mg_name") or "singlenode"
tg_main.dev_mode = (tg_main.mg_name == "flat") or core.is_creative_enabled()

dofile(mod_path .. "/scripts" .. "/math.lua")
dofile(mod_path .. "/scripts" .. "/debug.lua")
