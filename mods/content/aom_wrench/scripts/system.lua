
aom_wrench.pl = {}
local pl = aom_wrench.pl

function aom_wrench.check_player(player)
    local pi = pl[player]
    if not pi then pi = aom_wrench.get_shell(player); pl[player] = pi end
    return pi
end

local has_compatlib = core.get_modpath("compatlib") ~= nil
local function hud_add(player, def)
    if has_compatlib then
        return _G.COMPAT.hud_add(player, def)
    else return player:hud_add(def) end
end

function aom_wrench.sort_positions(v, b)
    return vector.new(
        ((v.x <= b.x) and v.x) or b.x,
        ((v.y <= b.y) and v.y) or b.y,
        ((v.z <= b.z) and v.z) or b.z
    ),
    vector.new(
        ((v.x >= b.x) and v.x) or b.x,
        ((v.y >= b.y) and v.y) or b.y,
        ((v.z >= b.z) and v.z) or b.z
    )
end

-- returns an index list of vectors within a cube defined buy two points
function aom_wrench.all_nodes_in(v, b)
    local list = {}
    for z=v.z, b.z do
        for y=v.y, b.y do
            for x=v.x, b.x do
                list[#list+1] = vector.new(x,y,z)
            end
        end
    end
    return list
end

function aom_wrench.get_eyepos(player)
    local eyepos = vector.add(player:get_pos(), vector.multiply(player:get_eye_offset(), 0.1))
    eyepos.y = eyepos.y + player:get_properties().eye_height
    return eyepos
end

function aom_wrench.get_shell(player)
    local creative = (player and core.is_creative_enabled(player:get_player_name()) or false)
    if (not creative) and core.get_modpath("aom_gamemodes") then
        local aom_gamemodes = _G["aom_gamemodes"]
        creative = aom_gamemodes.player_has_tag(player, "creative")
    end
    return {
        name = "",
        node = {name="air"},
        build_list = nil,
        ent = {},
        creative = creative
    }
end

function aom_wrench.remove_all_ents(player)
    local pi = aom_wrench.check_player(player)
    for i=1, 2 do
        if pi.ent[i] then
            pi.ent[i].object:remove()
            pi.ent[i] = nil
        end
    end
    aom_wrench.update_measurement_hud(player)
end

function aom_wrench.get_tool_range(player)
    local hand = core.registered_items[""]
    local wield = player:get_wielded_item():get_definition()
    return math.max(wield.range or 4, hand.range or 4)
end

function aom_wrench.get_pointed_thing(player, eyepos, liquids)
    if not eyepos then eyepos = aom_wrench.get_eyepos(player) end
    local range = aom_wrench.get_tool_range(player)
    local target_pos = vector.add(eyepos, vector.multiply(player:get_look_dir(), range))
    local ray = core.raycast(eyepos, target_pos, false, (liquids == true))
    for pointed_thing in ray do
        if pointed_thing.type == "node" then
            return pointed_thing
        end
    end
    return nil
end

local function tex(name)
    return {name,name,name,name,name,name}
end

local textures = {
    tex("aom_wrench_wrench_ENTITY.png^[multiply:#8df"),
    tex("aom_wrench_wrench_ENTITY.png^[multiply:#ed8"),
}

function aom_wrench.get_entity_texture(num)
    return textures[num]
end


local entity = {
    initial_properties = {
        physical = false,
        textures = textures[1],
        visual = "cube",
        visual_size = {x=1.01, y=1.01},
        collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2,},
        use_texture_alpha = true,
        pointable = false,
        glow = 14,
        static_save = false,
    },
    _parent = false,
    _timer = 1,
    _type = 1,
    on_step = function(self, dtime, moveresult)
        if self._timer < 0 then self._timer = 1
        else self._timer = self._timer - dtime return end

        if (not self._parent) or (not aom_wrench.pl[self._parent]) then
            self.object:remove()
            return
        end
    end,
}
core.register_entity("aom_wrench:wrench_ENTITY", entity)


function aom_wrench.chat_send_player(player, text)
    core.chat_send_player(player:get_player_name(), core.colorize("#fea", "[wrench] ") .. text)
end


function aom_wrench.add_entity(pos, ent_type, player)
    local pi = aom_wrench.check_player(player)
    local existing_ent = pi.ent[ent_type]
    if existing_ent and existing_ent.object and existing_ent.object:get_pos() then
        return
    end
    local object = core.add_entity(pos, "aom_wrench:wrench_ENTITY")
    local _tex = aom_wrench.get_entity_texture(ent_type)
    object:set_properties({
        textures = _tex
    })
	if object.set_observers then
		object:set_observers({
			[player:get_player_name()] = true,
		})
	end
    local self = object:get_luaentity()
    if not self then object:remove() return end
    self._parent = player
    pi.ent[ent_type] = self
end


function aom_wrench.hide_entity(player, n)
    if not pl[player] then return end
    local pi = aom_wrench.check_player(player)
    if not pi.ent[n] then return end
    local props = pi.ent[n].object:get_properties()
    if not props then return end
    if props.is_visible then
        pi.ent[n].object:set_properties({
            is_visible = false,
        })
    end
end


function aom_wrench.show_entity(player, n)
    local pi = aom_wrench.check_player(player)
    local props = pi.ent[n] and pi.ent[n].object and pi.ent[n].object:get_properties()
    if props and (not props.is_visible) then
        pi.ent[n].object:set_properties({
            is_visible = true,
        })
    end
end

-- it's like a magic
function aom_wrench.escape_texture(texture)
	return texture:gsub(".", {["\\"] = "\\\\", ["^"] = "\\^", [":"] = "\\:"})
end


function aom_wrench.get_node_image(name)
    local def = core.registered_nodes[name]
    if not def then return "blank.png" end

    if def.inventory_image ~= "" and def.name ~= "air" then
        return def.inventory_image
    end
    if def.wield_image ~= "" and def.name ~= "air" then
        return def.wield_image
    end

    local tiles = def.tiles
    if type(tiles) == "string" then return tiles end
    for i, tile in pairs(tiles or {}) do
        if type(tile) == "string" then
            return tile
        elseif type(tile) == "table" then
            return tile.name
        end
    end

    return "blank.png"
end


function aom_wrench.update_hud(player)
    local pi = aom_wrench.check_player(player)
    local imagename = aom_wrench.get_node_image(pi.node.name)
    imagename = aom_wrench.escape_texture(imagename)
    -- cram it into a 16x16, so it doesn't overflow or look bad
    imagename = "[combine:16x16:0,0=\\("..imagename.."\\)"
    if pi.node_hud then
        player:hud_change(pi.node_hud, "text", imagename)
    else
        pi.node_hud = hud_add(player, {
            type = "image",
            alignment = {x=0.5, y=0.5},
            position = {x=0.5, y=0.8},
            name = "aom_wrench_node",
            text = imagename,
            z_index = 800,
            scale = {x = 8, y = 8},
            offset = {x = 0, y = 0},
        })
    end
    -- this is the layer on top / frame
    local imagename2 = "aom_wrench_hud_bg.png^[opacity:170"
    if pi.node_hud2 then
        player:hud_change(pi.node_hud2, "text", imagename2)
    else
        pi.node_hud2 = hud_add(player, {
            type = "image",
            alignment = {x=0.5, y=0.5},
            position = {x=0.5, y=0.8},
            name = "aom_wrench_node2",
            text = imagename2,
            z_index = 801,
            scale = {x = 2, y = 2},
            offset = {x = -4, y = -4},
        })
    end
end


function aom_wrench.do_building_creative(player, dtime, itemstack)
    local pi = aom_wrench.check_player(player)
    if pi.build_list then
        core.bulk_set_node(pi.build_list, pi.node)
        aom_wrench.chat_send_player(player, core.colorize("#aaa", "Finished building!"))
        pi.build_list = nil
    end
end


---@diagnostic disable-next-line: duplicate-set-field
function aom_wrench.take_item(player, itemname, count)
    local pi = aom_wrench.check_player(player)
    local inv = player:get_inventory()
    for i=0, inv:get_size("main") do
        local stack = inv:get_stack("main", i)
        if stack:get_name() == itemname and stack:get_count() >= (count or 1) then
            if (count == nil) or pi.creative then return true end -- don't use items if in creative
            stack:take_item(count)
            inv:set_stack("main", i, stack)
            return true
        end
    end
    return false
end


function aom_wrench.do_building(player, dtime, itemstack)
    local pi = aom_wrench.check_player(player)
    while pi.build_list do
        local creative = pi.creative
        if creative then return aom_wrench.do_building_creative(player, dtime, itemstack) end

        -- only at start of build, after releasing click
        if not pi.build_index then
            pi.build_index = 0
            pi._timer = 0.6
            core.sound_play(("aom_wrench_clicks"), {
                gain = 0.8,
                pitch = 1,
                object = player,
            })
            return
        end

        -- only place nodes every n seconds
        pi._timer = (pi._timer or 0) - dtime
        if (not creative) and pi._timer > 0 then break end
        pi._timer = 0.05

        pi.build_index = (pi.build_index or 0) + 1
        local build_pos = pi.build_list[pi.build_index]
        -- if you reach the end of the stack, quit
        if not build_pos then
            pi.build_list = nil
            pi.build_index = nil
            aom_wrench.chat_send_player(player, core.colorize("#aaa", "Finished building!"))
            core.sound_play(("aom_wrench_plip"), {
                gain = 0.2,
                pitch = 0.4,
                object = player,
            })
            break
        end

        -- don't overwrite existing nodes, but you are allowed to dig buildable_to nodes
        local node = core.get_node(build_pos)
        local nd = core.registered_nodes[node.name]
        if (not creative) and not (nd and nd.buildable_to) then
            break
        end

        -- go through inventory and subtract an item
        local found_item = creative or aom_wrench.take_item(player, pi.node.name, 1)

        if found_item then
            -- don't dig buildable_to node unless in creative
            if (not creative) and (node.name ~= "air") then
                core.dig_node(build_pos)
            end
            -- actually place the node
            core.set_node(build_pos, pi.node)

            -- don't oom
            if (not creative) and core.get_modpath("node_updates") then
                local node_updates = _G["node_updates"]
                node_updates.cause_adjacent_update(build_pos, "place", player)
                core.sound_play(("aom_wrench_plip"), {
                    gain = 0.1,
                    pitch = 0.5,
                    max_hear_distance = 30,
                    pos = build_pos,
                })
            end
        else
            core.sound_play(("aom_wrench_not_allowed"), {
                gain = 0.4,
                pitch = 0.95,
                object = player,
            })
            -- reset and give up building this shape
            pi.build_list = nil
            pi.build_index = nil
        end

        if not creative then
            break
        end
    end
end


function aom_wrench.squaredist(p1, p2)
    return (((p1.x - p2.x) ^ 2) + ((p1.y - p2.y) ^ 2) + ((p1.z - p2.z) ^ 2))
end


function aom_wrench.get_pointed_position(player)
    local eyepos = aom_wrench.get_eyepos(player)
    local pointed_thing = aom_wrench.get_pointed_thing(player, eyepos)
    local ret
    local ctrl = player:get_player_control()
    -- allow player to wrench solid blocks too when pressing aux1
    if pointed_thing and ctrl and ctrl.aux1 then
        ret = vector.copy(pointed_thing.under)
    elseif pointed_thing then
        ret = vector.copy(pointed_thing.above)
    end
    -- if not pointing at a node, just use the eyepos
    if not ret then
        local range = (ctrl.aux1 and 4) or aom_wrench.get_tool_range(player)
        ret = eyepos + (player:get_look_dir() * range)
        return ret, false
    end

    return ret, true
end

function aom_wrench.update_measurement_hud(player)
    local pi = aom_wrench.check_player(player)
    local text1 = ""
    if pi.pos1 and pi.pos2 then
        local diff = pi.pos2 - pi.pos1
        local sign = vector.copy(diff)
        for i, a in ipairs({"x", "y", "z"}) do
            if sign[a] >= 0 then sign[a] = 1
            else sign[a] = -1 end
        end
        local size = vector.multiply(vector.abs(diff) + vector.new(1,1,1), sign)
        text1 = core.colorize("#fea", string.format("%d  %d  %d", size.x, size.y, size.z))
    end
    if pi.node_hud_measure then
        player:hud_change(pi.node_hud_measure, "text", text1)
    else
        pi.node_hud_measure = hud_add(player, {
            type = "text",
            style = 0,
            size = {x=2, y=1},
            alignment = {x=0.5, y=1.0},
            -- direction = 0,
            position = {x=0.5, y=0.8},
            name = "aom_wrench_node_measure",
            text = text1,
            z_index = 806,
            scale = {x=100, y=100},
            offset = {x=0, y=-200},
        })
    end
end

function aom_wrench.update_position(player, n)
    -- move the end marker
    local pi = aom_wrench.check_player(player)
    local pos = pi["pos"..n]
    if pi.ent[n] then
        pi.ent[n].object:set_pos(pos)
    else
        aom_wrench.add_entity(pos, n, player)
    end
    aom_wrench.update_measurement_hud(player)
end
