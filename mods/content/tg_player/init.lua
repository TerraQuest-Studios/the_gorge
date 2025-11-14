local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

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
	if tg_player.dev_mode then
		player:set_sky({
			base_color = "#777",
			type = "plain",
			clouds = false,
		})
	else
		player:set_camera({
			mode = "first",
		})
	end
end)
