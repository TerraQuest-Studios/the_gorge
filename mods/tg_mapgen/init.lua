local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

core.register_alias("placeholder", "tg_nodes:placeholder")
core.register_alias("mapgen_stone", "air")
core.register_alias("mapgen_water_source", "air")
core.register_alias("mapgen_river_water_source", "air")

core.set_mapgen_setting("mg_flags", "nocaves,nodungeons,light,decorations,nobiomes,ores", true)
if tg_main.mg_name == "flat" then
	core.register_ore({
		ore_type       = "stratum",
		ore            = "placeholder",
		wherein        = {"air", "group:liquid"},
		y_min = -32,
		y_max = 0,
	})
else
	core.register_mapgen_script(mod_path .. "/mapgen" .. "/mg_main.lua")
end
