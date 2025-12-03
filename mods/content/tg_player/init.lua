local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

tg_player = {}

dofile(mod_path .. "/scripts" .. "/helpers.lua")

tg_player._pl = {}
---Gets the transient player information table
---@param player table
---@return table|nil
function tg_player.pi(player)
	if not core.is_player(player) then return end
	local pi = tg_player._pl[player]
	if not pi then
		pi = {
			tasks = {},
		}
		tg_player._pl[player] = pi
	end
	return pi
end

core.register_on_joinplayer(function(player, last_login)
	player:set_sky({
		base_color = "#777",
		-- base_color = "#681c0e",
		type = "plain",
		clouds = false,
	})
	player:set_camera({
		mode = "first",
	})
	-- if tg_main.dev_mode == true then
	-- else
	-- end
	local props = player:get_properties()
	props.textures = { "player.png" }
	player:set_properties(props)
	player:set_lighting({
		shadows = { intensity = 0.33 },
		volumetric_light = { strength = 0.45 },
		exposure = {
			luminance_min = -3.5,
			luminance_max = -2.5,
			exposure_correction = 0.35,
			speed_dark_bright = 1500,
			speed_bright_dark = 700,
		},
		boom = {
			intensity = 0.05,
			radius = 0.1,
		},
		saturation = 1.0,
	})
end)
