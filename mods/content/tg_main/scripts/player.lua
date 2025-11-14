
core.register_on_joinplayer(function(player, last_login)
	if tg_main.dev_mode then
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

function tg_main.get_eyepos(player)
    local eyepos = vector.add(player:get_pos(), vector.multiply(player:get_eye_offset(), 0.1))
    eyepos.y = eyepos.y + player:get_properties().eye_height
    return eyepos
end

function tg_main.get_tool_range(itemstack)
    return ((itemstack and itemstack:get_definition().range)
	or core.registered_items[""].range or 4)
end
