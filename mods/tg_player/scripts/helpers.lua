
function tg_player.get_eyepos(player)
    local eyepos = vector.add(player:get_pos(), vector.multiply(player:get_eye_offset(), 0.1))
    eyepos.y = eyepos.y + player:get_properties().eye_height
    return eyepos
end

function tg_player.get_tool_range(itemstack)
    return ((itemstack and itemstack:get_definition().range)
	or core.registered_items[""].range or 4)
end
