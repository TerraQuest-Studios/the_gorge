local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

core.register_node("tg_main:placeholder", {
	description = S("Placeholder Node"),
	groups = { solid = 1, unbreakable = 1, },
	tiles = {
		{
			name = "tg_main_placeholder.png^[multiply:#888",
			align_style = "world", scale = 16,
		},
	},
})
