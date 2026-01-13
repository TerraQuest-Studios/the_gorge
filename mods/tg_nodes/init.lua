local mod_name = core.get_current_modname()
local S = core.get_translator(mod_name)

tg_nodes = {}

local defualt_groups = { full_solid = 1, solid = 1, }

--- easy breaking when in dev_mode, else no breaking
if tg_main.dev_mode == true then
	defualt_groups["dig_immediate"] = 3
end

-- define the sound/sound_group here
tg_nodes.sounds = {
	paper = "tg_paper_footstep"
}

core.register_node("tg_nodes:placeholder", {
	description = S("Placeholder Node"),
	groups = { full_solid = 1, solid = 1, },
	tiles = {
		{
			name = "tg_nodes_placeholder.png^[multiply:#888",
			align_style = "world",
			scale = 16,
		},
	},
})

-- def node shapes
---@class shape
local shapes = {
	box = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
	thicker_box = { -0.55, -0.55, -0.55, 0.55, 0.55, 0.55 },
	door = { -1.0, -0.5, -0.2, 1.0, 2.5, 0.2 },
	door_flipped = { -0.2, -0.5, -1.0, 0.2, 2.5, 1.0 },
	hinge = { -0.1, -0.5, -0.1, 0.1, 2.5, 0.1 },
	slab = { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
	medium_object = { -0.3, -0.5, -0.3, 0.3, 0.0, 0.3 },
	stairs = {
		{ -0.5, -0.5, -0.5, 0.5, 0,   0.5 },
		{ -0.5, 0,    0,    0.5, 0.5, 0.5 },
	},
	centerd_box = { -0.2, -0.2, -0.2, 0.2, 0.2, 0.2 }, -- small box touching the ground (plant / anything small)
	tiny_box = { -0.2, -0.5, -0.2, 0.2, -0.1, 0.2 },  -- small box touching the ground (plant / anything small)
	slim_box = { -0.2, -0.5, -0.2, 0.2, 0.3, 0.2 },   -- same as tiny_box, just taller
	double = { -0.5, -0.5, -0.5, 0.5, 1.5, 0.5 },     -- a like a locker or pillar
	beam = { -0.2, -0.5, -0.2, 0.2, 0.5, 0.2 },       -- same as tiny_box, just taller
	sheet = { -0.5, -0.5, -0.5, 0.5, -0.49, 0.5 },
	panel = { -0.5, -0.5, -0.5, 0.5, -0.4, 0.5 },
	rails = {
		{ -0.4, -0.5, -0.5, -0.2, -0.4, 0.5 },
		{ 0.2,  -0.5, -0.5, 0.4,  -0.4, 0.5 },
	},
	half_slab = { -0.5, -0.5, -0.5, 0.5, 0.0, 0.0 },
	decal = { -1.5, -0.5, -1.5, 0.5, -0.499, 0.5 },
	-- wiring = {
	-- 	{ -0.5, -0.2, -0.5, 0.5, 0.2, 0.5 },
	-- 	{ -0.5, -0.2, -0.5, 0.5, 0.2, 0.5 }
	-- },
	wiring = { -0.5, -0.2, -0.2, 0.5, 0.2, 0.2 },
}

tg_nodes.shapes = shapes

--- function for creating simple node definitions (without registering!)
--- def can accept "node_texture" for prefixing with texture "tg_nodes", "texture" for prefixing with own mod origin,
--- or can accept "raw_texture" for a specific texture string to use w/o automation. Otherwise uses own
--- name for texture if no tiles
--- shape is what will be used for the node_box (if drawtype is nodebox or otherwise not specified)
--- can be string to index `tg_nodes.shapes`, or a table, only if node_box type is fixed or otherwise unspecified
--- @param name string name of node to be registered (does not require mod_origin to be specified)
--- @param def? table can be nil but not recommended, definition of node
--- @param desc? string if provided, will override def description, and will translate according to tg_nodes files
function tg_nodes.create_node_def(name, def, desc)
    if type(name) ~= "string" then
        error("tg_nodes.register_node: given 'name' is not a string, got type '"..type(name).."'")
    end
    -- create def table as to permit unnecessary lazy streamlining
    def = type(def) == "table" and def or {}
    def.mod_origin = core.get_current_modname()
    -- create name if not properly set
    if not name:match(":") then
        name = def.mod_origin .. ":" .. name
    end
    -- override description!
    if type(desc) == "string" then
        def.description = S(desc)
    end
    if def.desc then
        def.description = def.desc
        def.desc = nil
    end
    -- give folk the freedom to do their own tiles if provided!!!
    -- otherwise let's make some
    if type(def.tiles) ~= "table" then
        -- figuring out what texture we wanna use
        local select_texture
        -- assumes you want to grab a texture from our textures file
        if def.node_texture then
            select_texture = "tg_nodes_" .. def.node_texture
            -- clear
            def.node_texture = nil
        -- will add modname and png file extension to
        elseif def.texture then
            select_texture = def.mod_origin .. "_" .. def.texture
            def.texture = nil
        -- assumes you don't wanna do any automatic modifications
        elseif def.raw_texture then
            select_texture = def.raw_texture
            def.raw_texture = nil
        end
        -- generate one with our name if could not find a suitable texture!
        -- replaces ":" with "_", appends file extension
        select_texture = select_texture or name:gsub(":", "_") .. ".png"
        -- add png if no file extension
        -- looks for dot with %., then any alphanumeric characters with %w+, with $ at the end to ensure it checks for
        -- at end of string
        -- otherwise adds .png
        select_texture = select_texture:find("%.%w+$") and select_texture or select_texture..".png"
        -- create!
        def.tiles = {
            {
                name = select_texture
            }
        }
    end
    -- now checking shape!
    -- permit indexing a shape with string, otherwise must be a table or else it defaults to box shape
    local shape = type(def.shape) == "string" and shapes[def.shape] or
      type(def.shape) == "table" and def.shape or shapes.box
    def.shape = nil -- clear!
    -- figure out drawtype
    def.drawtype = def.drawtype or "nodebox"
    -- only do shape stuff if a nodebox
    if def.drawtype == "nodebox" then
        local nodebox = def.node_box or {}
        nodebox.type = nodebox.type or "fixed"
        -- only bother with shaping if our type is fixed
        if nodebox.type == "fixed" then
            -- modify paramtype
            if shape and shape ~= shapes.box then
                def.paramtype = def.paramtype or "light"
                def.paramtype2 = def.paramtype2 or "facedir"
            end
            -- add to nodebox if successful!
            nodebox.fixed = shape or nodebox.fixed
        end
        -- set nodebox
        def.node_box = nodebox
    end
    -- sounds!
    def.sounds = tg_sound.node_defaults(def.sounds)
    -- groups!
    def.groups = def.groups or {}
    -- add default groups
    for grpname, grpval in pairs(defualt_groups) do
        -- add this group!
        if not def.groups[grpname] then
            def.groups[grpname] = grpval
        end
    end
    -- return reformed definition and name, as well as shape for specific stuff
    -- shape can be the fixed box of nodebox as well
    return def, name, (shape or (def.node_box and def.node_box.fixed) )
end

--- function for more simply registering nodes, see tg_nodes.create_node for more details
--- @param name string name of node to be registered (does not require mod_origin to be specified)
--- @param def? table can be nil but not recommended, definition of node
--- @param desc? string if provided, will override def description, and will translate according to tg_nodes files
function tg_nodes.register_node(name, def, desc)
    -- register!
    def, name = tg_nodes.create_node_def(name, def, desc)
    core.register_node(name, def)
    -- returns definition
    return core.registered_nodes[def.name]
end


--- same as tg_nodes.register_node, but for registering more misc stuff!
--- @param name string name of node to be registered (does not require mod_origin to be specified)
--- @param def? table can be nil but not recommended, definition of node
--- @param desc? string if provided, will override def description, and will translate according to tg_nodes files
function tg_nodes.register_misc(name, def, desc)
    -- create definition table
    def = type(def) == "table" and def or {}
    -- basics prior to registration
    -- whether or not to show a selection box!
    -- if dev_mode, always true, if not dev_mode, resort to specified boolean (default false)
    local selectable = tg_main.dev_mode == false or def.selectable == true
    def.selectable = nil -- remove!
    -- create a definition
    local shape -- will be filled out by create_node_def or will be box
    def, name, shape = tg_nodes.create_node_def(name, def, desc)
    -- automate whether or not to be walkable
    if type(def.walkable) ~= "boolean" then
        -- will be true unless one of these are true
        def.walkable = not (shape == shapes.panel or shape == shapes.sheet)
    end
    -- whether or not we're selectable!
    -- only need to change selection box if not selectable (as selection_box will be set by definition)
    if not selectable then
        def.selection_box = {
            type = "fixed",
            fixed = { 0, 0, 0, 0, 0, 0 }
        }
    end
    -- misc, well, misc stuff!
    def.use_texture_alpha = def.use_texture_alpha or "clip"
    -- whether or not sun light goes through (default true)
    def.sunlight_propagates = def.sunlight_propagates ~= false
    -- paramtypes
    def.paramtype = def.paramtype or "light"
    def.paramtype2 = def.paramtype2 or "facedir"
    -- register!
    core.register_node(name, def)
    -- returns definition
    return core.registered_nodes[def.name]
end

--- same as tg_nodes.register_node but for plants
--- @param name string name of node to be registered (does not require mod_origin to be specified)
--- @param def? table can be nil but not recommended, definition of node
--- @param desc? string if provided, will override def description, and will translate according to tg_nodes files
function tg_nodes.register_plant(name, def, desc)
    -- create definition table
    def = def or {}
    -- basics prior to registration
    def.drawtype = def.drawtype or "plantlike"
    def.sounds = tg_sound.plant_defaults(def.sounds)
    def.shape = def.shape or "tiny_box" -- add a shape into definition
    -- paramtype
    def.paramtype = "light" -- required
    -- create a definition
    local shape -- will be filled out by create_node_def or will be box
    def, name, shape = tg_nodes.create_node_def(name, def, desc)
    -- add a group
    def.groups.flora = def.groups.flora or 1
    -- do selection box
    def.selection_box = def.selection_box or {}
    local selcbox = def.selection_box -- grab it after above so that I can lazily have it be already added
    selcbox.type = "fixed"
    selcbox.fixed = shape
    -- modify visual scale accordingly
    local texture = def.tiles[1]
    texture = type(texture) == "string" and texture or type(texture) == "table" and (texture[1] or texture.name)
    texture = type(texture) == "table" and texture.name or texture
    -- figure out scale (if not provided)
    -- if mesh, default to 16
    -- if smaller texture, increase scale to 2
    -- default to 1
    def.visual_scale = def.visual_scale or (def.drawtype == "mesh" and 16) or
      texture and (texture:find("8x8") and 2) or 1
    -- IF MESH!
    if def.drawtype == "mesh" then
        def.paramtype2 = def.paramtype2 or "4dir"
        def.use_texture_alpha = def.use_texture_alpha or "clip"
    end
    -- misc plant stuff
    def.waving = nil -- no wind down here
    -- if true, placed nodes can replace this node (default true))
    def.buildable_to = def.buildable_to ~= false
    -- if true, sun light will go through (default true)
    def.sunlight_propagates = def.sunlight_propagates ~= false
    -- if true, can be flooded by water (default false)
    def.floodable = def.floodable == true
    -- if true, player collides with (default false)
    def.walkable = def.walkable == true
    -- register!
    core.register_node(name, def)
    -- returns definition
    return core.registered_nodes[def.name]
end


--- same as tg_nodes.create_node_def but for wall lights!
--- @param name string name of node to be registered (does not require mod_origin to be specified)
--- @param def? table can be nil but not recommended, definition of node
--- @param desc? string if provided, will override def description, and will translate according to tg_nodes files
function tg_nodes.create_wall_light_def(name, def, desc, light)
    -- create definition table
    def = def or {}
    -- basics prior to registration
    -- let there be LIGHT!
    if light then
        def.light_source = light
    elseif def.light then
        def.light_source = def.light
        def.light = nil
    end
    -- base shape
    def.shape = def.shape or "panel"
    -- required
    def.paramtype = "light"
    def.paramtype2 = "wallmounted"
    def.drawtype = "signlike"
    -- create a definition
    local shape
    def, name, shape = tg_nodes.create_node_def(name, def, desc)
    -- add group
    def.groups.wall_light = 1
    -- misc light stuff
    -- if true, player collides with (default false)
    def.walkable = def.walkable == true
    -- if true, sun light will go through (default true)
    def.sunlight_propagates = def.sunlight_propagates ~= false
    -- return reformed definition and name, as well as shape for specific stuff
    -- shape can be the fixed box of nodebox as well
    return def, name, (shape or (def.node_box and def.node_box.fixed) )
end

--- same as tg_nodes.register_node but for wall light type 1 (power not needed)
--- will be registered as "(name)_on"
--- @param name string name of node to be registered (does not require mod_origin to be specified)
--- @param def? table can be nil but not recommended, definition of node
--- @param desc? string if provided, will override def description, and will translate according to tg_nodes files
function tg_nodes.register_wall_light(name, def, desc, light)
    -- change name
    name = name.."_on"
    -- register!
    def, name = tg_nodes.create_wall_light_def(name, def, desc, light)
    -- register and return def
    core.register_node(name, def)
    return core.registered_nodes[def.name]
end

--- same as tg_nodes.register_wall_light but for wall light type 2 (power required)
--- registers BOTH alit and unlit variants (on and off)
--- @param name string name of node to be registered (does not require mod_origin to be specified)
--- @param def? table can be nil but not recommended, definition of node
--- @param desc? string if provided, will override def description, and will translate according to tg_nodes files
function tg_nodes.register_wall_light_powered(name, def, desc, light)
    local defs = {} -- stored alit and unlit definitions
    -- create def
    def = def or {}
    -- basics prior to definition
    -- add group
    def.groups = def.groups or {}
    def.groups.powerable = def.groups.powerable or 1 -- powerable!
    -- functions!
    -- start timer
    def.on_construct = def.on_construct or
    function(pos)
        core.get_node_timer(pos):start(1)
    end
    -- change name
    name = name.."_on"
    -- DO ALIT VARIANT
    local adef = table.copy(def)
    -- create the basics
    adef, name = tg_nodes.create_wall_light_def(name, adef, desc, light)
    -- permit specifying an on_timer for a light that is alit
    adef.on_timer = adef.alit_on_timer or
    function(pos, elapsed, node, timeout)
        local power = tg_power.getPower()
        if power then return true end -- already powered! check later
        -- turn off!
        node = node or core.get_node(pos)
        node.name = node.name:gsub("_on", "_off")
        -- swap switch
        core.swap_node(pos, node)
        -- play sound
        core.sound_play("tg_dirt_footstep", {gain = 0.15, pitch = math.random(60,85)/100, pos = pos})
        return true -- run check again
    end
    -- remove now unnecessary
    adef.alit_on_timer = nil
    def.alit_on_timer = nil
    adef.unlit_on_timer = nil
    -- register and add alit variant
    core.register_node(name, adef)
    defs.alit = core.registered_nodes[adef.name]
    -- DO UNLIT VARIANT
    name = name:gsub("_on", "_off") -- replace with "_off" for name
    def.light_source = nil -- not needed
    def.light = nil
    -- create the basics
    def, name = tg_nodes.create_wall_light_def(name, def, desc)
    -- unlit timer
    def.on_timer = def.unlit_on_timer or
    function(pos, elapsed, node, timeout)
        local power = tg_power.getPower()
        if not power then return true end -- already off! check later
        -- turn on!
        node = node or core.get_node(pos)
        node.name = node.name:gsub("_off", "_on")
        core.swap_node(pos, node)
        -- play sound
        core.sound_play("tg_paper_footstep", {gain = 0.05, pitch = math.random(60,85)/100, pos = pos})
        return true -- run check again
    end
    -- remove unnecessary
    def.unlit_on_timer = nil
    -- register and add unlit variant
    core.register_node(name, def)
    defs.unlit = core.registered_nodes[def.name]
    -- returns defs
    return defs
end





core.register_node("tg_nodes:beam", {
	description = S("beam, cold to the touch."),
	groups = defualt_groups,
	waving = 0, -- there is no wind down here
	paramtype = "light",
	drawtype = "mesh",
	mesh = "beam.glb",
	visual_scale = 10.0,
	tiles = { "beam.png" },
	paramtype2 = "facedir",
	use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	-- walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.beam
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.beam
	},
})

core.register_node("tg_nodes:cables", {
	description = S("cables, I don't don't trust these."),
	groups = defualt_groups,
	paramtype = "light",
	drawtype = "mesh",
	mesh = "cables.glb",
	visual_scale = 10.0,
	tiles = { "cables.png" },
	paramtype2 = "facedir",
	-- use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.panel
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.panel
	},
})

core.register_node("tg_nodes:cable", {
	description = S("cable, I don't don't trust these."),
	groups = defualt_groups,
	paramtype = "light",
	drawtype = "mesh",
	mesh = "cable.glb",
	visual_scale = 10.0,
	tiles = { "cables.png" },
	paramtype2 = "facedir",
	-- use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.panel
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.panel
	},
})

core.register_node("tg_nodes:cable_angle", {
	description = S("cable_angle, I don't don't trust these."),
	groups = defualt_groups,
	paramtype = "light",
	drawtype = "mesh",
	mesh = "cable_angle.glb",
	visual_scale = 10.0,
	tiles = { "cables.png" },
	paramtype2 = "facedir",
	-- use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.panel
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.panel
	},
})
core.register_node("tg_nodes:tubes", {
	description = S("tubes, for transfering liquids."),
	groups = defualt_groups,
	paramtype = "light",
	drawtype = "mesh",
	mesh = "tubes.glb",
	visual_scale = 10.0,
	tiles = { "tubes.png" },
	paramtype2 = "facedir",
	-- use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	-- walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.slab
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.slab
	},
	sounds = tg_sound.metal_defaults()
})
core.register_node("tg_nodes:tubes_left", {
	description = S("tubes_left, for transfering liquids."),
	groups = defualt_groups,
	paramtype = "light",
	drawtype = "mesh",
	mesh = "tubes_left.glb",
	visual_scale = 10.0,
	tiles = { "tubes.png" },
	paramtype2 = "facedir",
	-- use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	-- walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.slab
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.slab
	},
	sounds = tg_sound.metal_defaults()
})
core.register_node("tg_nodes:tubes_right", {
	description = S("tubes_right, for transfering liquids."),
	groups = defualt_groups,
	paramtype = "light",
	drawtype = "mesh",
	mesh = "tubes_right.glb",
	visual_scale = 10.0,
	tiles = { "tubes.png" },
	paramtype2 = "facedir",
	-- use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	-- walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.slab
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.slab
	},
	sounds = tg_sound.metal_defaults()
})
core.register_node("tg_nodes:tubes_down", {
	description = S("tubes_down, for transfering liquids."),
	groups = defualt_groups,
	paramtype = "light",
	drawtype = "mesh",
	mesh = "tubes_down.glb",
	visual_scale = 10.0,
	tiles = { "tubes.png" },
	paramtype2 = "facedir",
	-- use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	-- walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.half_slab
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.half_slab
	},
	sounds = tg_sound.metal_defaults()
})

core.register_node("tg_nodes:radio", {
	description = S("Radio, nice tunes."),
	groups = defualt_groups,
	paramtype = "light",
	drawtype = "mesh",
	mesh = "radio.glb",
	visual_scale = 10.0,
	tiles = { "radio.png" },
	paramtype2 = "facedir",
	-- use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	-- walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.tiny_box
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.tiny_box
	},
})

core.register_node("tg_nodes:dial_pad", {
	description = S("dial_pad, nice tunes."),
	groups = defualt_groups,
	paramtype = "light",
	drawtype = "mesh",
	mesh = "dial_pad.glb",
	visual_scale = 10.0,
	tiles = { "dial_pad.png" },
	paramtype2 = "facedir",
	-- use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	-- walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.panel
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.panel
	},
})

core.register_node("tg_nodes:blood_slatter", {
	description = S("blood_slatter, wow that is a lot of blood."),
	groups = defualt_groups,
	drawtype = "nodebox",
	-- mesh = "dial_pad.glb",
	visual_scale = 1,
	-- tiles = {
	-- 	name = "tg_nodes_misc.png^[sheet:8x8:3,0",
	-- 	align_style = "world",
	-- 	scale = 2,
	-- },
	tiles = {
		{
			name = "tg_nodes_misc.png^[sheet:8x8:5,0",
			align_style = "world",
			scale = 2,
		},
	},
	paramtype = "light",
	paramtype2 = "facedir",
	use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	-- walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.decal
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.decal
	},
})

core.register_node("tg_nodes:blood_slatter_creature", {
	description = S("blood_slatter_creature, looks dry."),
	groups = defualt_groups,
	drawtype = "nodebox",
	-- mesh = "dial_pad.glb",
	visual_scale = 1,
	-- tiles = {
	-- 	name = "tg_nodes_misc.png^[sheet:8x8:3,0",
	-- 	align_style = "world",
	-- 	scale = 2,
	-- },
	tiles = {
		{
			name = "tg_nodes_misc.png^[sheet:8x8:4,0",
			align_style = "world",
			scale = 2,
		},
	},
	paramtype = "light",
	paramtype2 = "facedir",
	use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	-- walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.decal
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.decal
	},
})

core.register_node("tg_nodes:sludge_slatter", {
	description = S("sludge_slatter, maybe i shouldn't touch that."),
	groups = defualt_groups,
	drawtype = "nodebox",
	-- mesh = "dial_pad.glb",
	visual_scale = 1,
	-- tiles = {
	-- 	name = "tg_nodes_misc.png^[sheet:8x8:3,0",
	-- 	align_style = "world",
	-- 	scale = 2,
	-- },
	tiles = {
		{
			name = "tg_nodes_misc.png^[sheet:8x8:3,0",
			align_style = "world",
			scale = 2,
		},
	},
	paramtype = "light",
	paramtype2 = "facedir",
	use_texture_alpha = "clip",
	-- sunlight_propagates = true,
	-- walkable = false,
	node_box = {
		type = "fixed",
		fixed = shapes.decal
	},
	selection_box = {
		type = "fixed",
		fixed = shapes.decal
	},
})

---will create multiple node shapes
---@param name any
---@param sounds any
function tg_nodes.defNode(name, sounds)
	local nodes_to_register = { name, name .. "_stairs", name .. "_slab", name .. "_panel", name .. "_rails" }
	for index, value in ipairs(nodes_to_register) do
		local param1 = "none"
		local param2 = "none"
		local shape = shapes.box
		local sel_box = nil
		if string.find(value, "stairs") or string.find(value, "slab") or string.find(value, "panel")
				or string.find(value, "rails") then
			param1 = "light"
			param2 = "facedir"
			if string.find(value, "stairs") then
				shape = shapes.stairs
			elseif string.find(value, "slab") then
				shape = shapes.slab
			elseif string.find(value, "panel") then
				shape = shapes.panel
			elseif string.find(value, "rails") then
				shape = shapes.rails
				sel_box = {
					type = "fixed",
					fixed = shapes.panel
				}
			end
		end
		local nodebox = {
			type = "fixed",
			fixed = shape
		}
		core.register_node("tg_nodes:" .. value, {
			description = S(value),
			groups = defualt_groups,
			tiles = {
				{
					name = "tg_nodes_" .. name .. ".png",
				},
			},
			sounds = tg_sound.node_defaults(sounds),
			paramtype = param1,
			paramtype2 = param2,
			drawtype = "nodebox",
			node_box = nodebox,
			selection_box = sel_box or nodebox,
		})
	end
end

-- nodes;
-- fog
tg_nodes.register_node("fog", { texture = "fog.png^[opacity:90", use_texture_alpha = "blend",
    paramtype = "light", drawtype = "glasslike", pointable = false
    -- sunlight propagates nor walkable need to be specified
}, "Fog, hard to look past.")
-- stone
tg_nodes.register_node("stone", {sounds=tg_sound.stone_defaults()}, "stone")
tg_nodes.register_node("stone_slab", {sounds=tg_sound.stone_defaults(), shape="slab", texture="stone"}, "stone")
tg_nodes.register_node("stone_stairs", {sounds=tg_sound.stone_defaults(), shape="stairs", texture="stone"}, "stone")
-- cave
tg_nodes.register_node("cave_ground", {sounds=tg_sound.gravel_defaults()}, "cave ground")
tg_nodes.register_node("cave_ground_2", {sounds=tg_sound.gravel_defaults()}, "cave ground, feels moist")
-- dirt
tg_nodes.register_node("dirt", {sounds=tg_sound.dirt_defaults()}, "dirt, cold")
tg_nodes.register_node("dirt_slab", {sounds=tg_sound.dirt_defaults(), texture="dirt"}, "dirt, cold")
tg_nodes.register_node("cave_ground_dirt", {sounds=tg_sound.gravel_defaults()}, "cave ground, with dirt")
-- concrete
tg_nodes.register_node("concrete", nil, "concrete, no one is taking care of this.")
tg_nodes.register_node("concrete_stair", {shape="stairs", texture="concrete"},
  "concrete, no one is taking care of this.")
tg_nodes.register_node("concrete_slab", {shape="slab", texture="concrete"},
  "concrete, no one is taking care of this.")
tg_nodes.register_node("concrete_floor", nil, "concrete floor, almost like sand paper.")
-- wooden crates
-- these two nodes need more work
tg_nodes.register_node("crate", {sounds=tg_sound.woodplank_defaults()}, "crate, looks heavy")
tg_nodes.register_node("crate2", {sounds=tg_sound.woodplank_defaults()}, "crate, looks heavy")

-- misc;
-- lockers
tg_nodes.register_misc("locker", {shape="double", sounds=tg_sound.metal_defaults(),
  tiles={ {name="tg_nodes_misc.png^[sheet:16x16:3,0"}, {name="tg_nodes_misc.png^[sheet:16x8:0,0"} },
  }, "Locker, LET ME IN!!")
-- paper
tg_nodes.register_misc("paper", {shape="sheet", texture="misc.png^[sheet:16x16:0,3",
  sounds=tg_sound.paper_defaults()}, "Paper")
tg_nodes.register_misc("paper_1", {shape="sheet", texture="misc.png^[sheet:16x16:1,3",
  sounds=tg_sound.paper_defaults()}, "Paper")
-- sticky notes
tg_nodes.register_misc("stick_notes", {shape="sheet", texture="misc.png^[sheet:16x16:0,4",
  sounds=tg_sound.paper_defaults()}, "Sticky Note; one of these had gotta have something important on it.")
tg_nodes.register_misc("stick_notes_1", {shape="sheet", texture="misc.png^[sheet:16x16:1,4",
  sounds=tg_sound.paper_defaults()}, "Sticky Note, one of these had gotta have something important on it.")
tg_nodes.register_misc("stick_notes_2", {shape="sheet", texture="misc.png^[sheet:16x16:2,4",
  sounds=tg_sound.paper_defaults()}, "Sticky Note, one of these had gotta have something important on it.")
tg_nodes.register_misc("stick_notes_3", {shape="sheet", texture="misc.png^[sheet:16x16:3,4",
  sounds=tg_sound.paper_defaults()}, "Sticky Note, one of these had gotta have something important on it.")

-- flora;
-- plants
tg_nodes.register_plant("short_grass", {texture="plants.png^[sheet:16x16:7,0"}, "Grass, they tickle")
tg_nodes.register_plant("plant", {shape="slim_box", texture="plants.png^[sheet:16x16:6,1"}, "Plant, they tickle")
tg_nodes.register_plant("caladium", {texture="plants.png^[sheet:16x16:6,0"}, "Caladium, odd looking plants.")
-- more complex def
tg_nodes.register_plant("fern", { tiles={"fern.png"}, drawtype = "mesh", mesh = "fern.glb",
  visual_scale = 16, selection_box = { type="fixed", fixed=shapes.slim_box } }, "fern, very lushes")

-- shrubs
tg_nodes.register_plant("shrub", {shape="slim_box", texture="plants.png^[sheet:8x8:0,0"}, "Shrub, it' dry.")
-- fungus
tg_nodes.register_plant("fungus", {texture="plants.png^[sheet:16x16:9,0"}, "Fungus, a King trumpet.")
tg_nodes.register_plant("fungus_small", {texture="plants.png^[sheet:16x16:9,1"}, "Fungus, a King trumpet.")
-- more complex def
tg_nodes.register_plant("king_trumpet", {tiles={"king_trumpet.png"}, drawtype="mesh", mesh="king_trumpet.glb",
  visual_scale = 16, selection_box = { type="fixed", fixed=shapes.slim_box } },
  "king trumpet, very lushes")

-- wall lights;
-- LEDs
tg_nodes.register_wall_light("led_red", nil, "led, blinding", 7)
core.register_alias_force("tg_nodes:led_on_red", "tg_nodes:led_red_on") -- convert to better system
-- powered LEDs
tg_nodes.register_wall_light_powered("led", nil, "led, blinding", 13)

tg_nodes.defNode("steel_enclosure", tg_sound.metal_defaults())
tg_nodes.defNode("concrete_tiled")
------
