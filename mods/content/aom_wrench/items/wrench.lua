local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

local pl = aom_wrench.pl

aom_wrench.max_dist = 16

local function abandon_build(player)
    local pi = aom_wrench.check_player(player)
    pi.place_mode = 0
    aom_wrench.hide_entity(player, 1)
    aom_wrench.hide_entity(player, 2)
    pi.pos2 = nil
    pi.pos1 = nil
    pi.build_list = nil
    pi.build_index = nil
end

local function send_selection_message(player, pi)
    pi = pi or aom_wrench.check_player(player)
    aom_wrench.chat_send_player(player,
        -- TL: @1 is node name ("aom_stone:cobble")
        core.colorize("#aaa", S("Wrench set to @1", pi.node.name),
        core.colorize("#9df", pi.node.name or "air"))
    )
end

aom_wrench.prototype = {
    on_use = function (itemstack, player, pointed_thing)
	    if not core.is_player(player) then return end
        local pi = aom_wrench.check_player(player)
        core.sound_play(("aom_wrench_plip"), {
            gain = 0.1,
            pitch = 0.6,
            object = player,
        })

        pi.pos1 = aom_wrench.get_pointed_position(player)

        if pi.pos1 then
            pi.pos1 = vector.round(pi.pos1)
            pi.place_mode = 1
            pi.build_list = nil
            pi.build_index = nil
            aom_wrench.add_entity(pi.pos1, 1, player)
            aom_wrench.update_position(player, 1)
            aom_wrench.add_entity(pi.pos1, 2, player)
        end
    end,
    -- SELECT A NODE
    on_place = function(itemstack, player, pointed_thing)
        if not core.is_player(player) then return end
        local pi = aom_wrench.check_player(player)
        if pi.select_grace and pi.select_grace > 0 then return end
        core.sound_play(("aom_wrench_plip"), {
            gain = 0.1,
            pitch = 0.8,
            object = player,
        })
        if not pi then pi = aom_wrench.get_shell(player) end
        pi.node = core.get_node(pointed_thing.under)
        aom_wrench.update_hud(player)
        pi.build_list = nil
        pi.build_index = nil
        send_selection_message(player, pi)
    end,
    -- SELECT AIR
    on_secondary_use = function(itemstack, player)
	    if not core.is_player(player) then return end
        core.sound_play(("aom_wrench_plip"), {
            gain = 0.1,
            pitch = 0.8,
            object = player,
        })
        local pi = aom_wrench.check_player(player)
        local pt = aom_wrench.get_pointed_thing(player, nil, true)
        if pt then
            pi.node = core.get_node(pt.under)
            aom_wrench.update_hud(player)
            send_selection_message(player, pi)
            return itemstack
        end
        pi.node = {name="air"}
        aom_wrench.update_hud(player)
        send_selection_message(player, pi)
        return itemstack
    end,
    -- MAIN
    _on_step = function(itemstack, player, dtime)
        local pi = aom_wrench.check_player(player)
        local ctrl = player:get_player_control()
        local creative = pi.creative

        if pi.select_grace and pi.select_grace > 0 then
            pi.select_grace = pi.select_grace - dtime
        end

        if not pi.place_mode then pi.place_mode = 0 end

        local pointed, at_node = aom_wrench.get_pointed_position(player)
        pointed = pointed and vector.round(pointed)

        if pi.place_mode == 0 then
            if at_node or ctrl.sneak then
                pi.pos1 = pointed
                aom_wrench.update_position(player, 1)
                aom_wrench.show_entity(player, 1)
            else
                aom_wrench.hide_entity(player, 1)
            end
        end

        if pi.place_mode == 1 then
            if ctrl.place then
                if (not pi.select_grace) or pi.select_grace < 0 then
                    core.sound_play(("aom_wrench_not_allowed"), {
                        gain = 0.4,
                        pitch = 0.95,
                        object = player,
                    })
                    abandon_build(player)
                end
                pi.select_grace = 1
                return
            end

            aom_wrench.show_entity(player, 1)
            aom_wrench.show_entity(player, 2)

            pi.pos2 = aom_wrench.get_pointed_position(player)
            pi.pos2 = pi.pos2 and vector.round(pi.pos2)
            -- make sure you're not able to make giant server-crashing cubes:
            local dist = aom_wrench.squaredist(pi.pos1, pi.pos2)
            if (not creative) and (dist > aom_wrench.max_dist^2) or dist > 200^2 then
                local dir = vector.direction(pi.pos1, pi.pos2)
                pi.pos2 = vector.round(vector.add(vector.multiply(dir, aom_wrench.max_dist), pi.pos1))
            end
            aom_wrench.update_position(player, 2)

            if not ctrl.dig then
                pi.place_mode = 2
            end
        end

        if pi.place_mode == 2 then
            pi.pos1, pi.pos2 = aom_wrench.sort_positions(pi.pos1, pi.pos2)
            local nodelist = aom_wrench.all_nodes_in(pi.pos1, pi.pos2)
            -- set the list of node positions to place at
            pi.build_list = (pi.node.name ~= "air" or creative) and nodelist
            pi.pos1, pi.pos2 = nil, nil
            aom_wrench.hide_entity(player, 1)
            aom_wrench.hide_entity(player, 2)
            if (not creative) and not aom_wrench.take_item(player, pi.node.name, nil) then
                core.sound_play(("aom_wrench_not_allowed"), {
                    gain = 0.4,
                    pitch = 0.95,
                    object = player,
                })
                pi.build_list = nil
                pi.build_index = nil
            end
            pi.pos2 = nil
            pi.place_mode = 3
        end

        if pi.place_mode == 3 then
            if (not pi.build_list) or #pi.build_list == 0 then
                pi.place_mode = 0
            end
        end

        -- do the building tick
        aom_wrench.do_building(player, dtime, itemstack)
    end,
    _on_select = function(itemstack, player)
        local pi = aom_wrench.check_player(player)
        aom_wrench.update_hud(player)
    end,
    _on_deselect = function(itemstack, player)
        local pi = aom_wrench.check_player(player)
        abandon_build(player)
        aom_wrench.remove_all_ents(player)
        pi.select_grace = 0
        if pi.node_hud then
            player:hud_remove(pi.node_hud)
            player:hud_remove(pi.node_hud2)
            pi.node_hud = nil
            pi.node_hud2 = nil
        end
        pi.place_mode = 0
    end,
}

core.register_tool("aom_wrench:wrench", {
    description = S("Wrench"),
    _tt_color = 5,
    _tt_long_desc = S("Fill tool for faster and more convenient building"),
    _tt_how_to_use =(
        S("[place] to select a node").."\n"..
        S("[dig] and drag to wrench between points").."\n"..
        S("Hold [aux1] to select the \"under\" position").."\n"..
        S("Hold [sneak] to show where you're pointing in air")),
    inventory_image = "aom_wrench.png",
    wield_image = "aom_wrench.png",
    groups = { admin_tools = 1 },
    range = 6,
    on_use = aom_wrench.prototype.on_use,
    on_place = aom_wrench.prototype.on_place,
    on_secondary_use = aom_wrench.prototype.on_secondary_use,
    _on_step = aom_wrench.prototype._on_step,
    _on_select = aom_wrench.prototype._on_select,
    _on_deselect = aom_wrench.prototype._on_deselect,
})

if core.get_modpath("aom_tcraft") then
---@diagnostic disable: undefined-global
    aom_tcraft.register_craft({
        output = "aom_wrench:wrench",
        items = {
            ["aom_items:iron_bar"] = 10,
        },
    })
end
