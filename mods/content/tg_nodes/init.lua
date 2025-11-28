local mod_name = core.get_current_modname()
local S = core.get_translator(mod_name)

tg_nodes = {}

-- define the sound/sound_group here
local sounds = {
	gravel = "tg_gravel_footstep",
	stone = "",
	concrete = "tg_concrete_footstep",
	paper = "tg_paper_footstep",
}
tg_nodes["sounds"] = sounds

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
	slab = { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
	stairs = {
		{ -0.5, -0.5, -0.5, 0.5, 0,   0.5 },
		{ -0.5, 0,    0,    0.5, 0.5, 0.5 },
	},
	tiny_box = { -0.2, -0.5, -0.2, 0.2, -0.1, 0.2 }, -- small box touching the ground (plant / anything small)
	slim_box = { -0.2, -0.5, -0.2, 0.2, 0.3, 0.2 }, -- same as tiny_box, just taller
	double = { -0.5, -0.5, -0.5, 0.5, 1.5, 0.5 },   -- a like a locker or pillar
	beam = { -0.2, -0.5, -0.2, 0.2, 0.5, 0.2 },     -- same as tiny_box, just taller
	sheet = { -0.5, -0.5, -0.5, 0.5, -0.49, 0.5 },
	panel = { -0.5, -0.5, -0.5, 0.5, -0.4, 0.5 },
	rails = {
		{ -0.4, -0.5, -0.5, -0.2, -0.4, 0.5 },
		{ 0.2,  -0.5, -0.5, 0.4,  -0.4, 0.5 },
	},
	half_slab = { -0.5, -0.5, -0.5, 0.5, 0.0, 0.0 },
}

tg_nodes["shapes"] = shapes

--- easily get going with nodes
---@param name string
---@param des string
---@param sound_spec table
---@param shape shape|nil
---@param texture string|nil : leave nil. the base node texture (name of a base node)
local function createNode(name, des, sound_spec, shape, texture)
	local node_groups = { full_solid = 1, solid = 1, }
	--- easy breaking when in dev_mode
	if tg_main.dev_mode == true then
		node_groups["dig_immediate"] = 3
	end
	local this_texture = "tg_nodes_" .. name .. ".png"
	if texture then
		this_texture = "tg_nodes_" .. texture .. ".png"
	end
	local param1 = "none"
	local param2 = "none"
	if shape ~= nil and shape ~= shapes.box then
		param1 = "light"
		param2 = "facedir"
	end
	core.register_node("tg_nodes:" .. name, {
		description = S(des),
		groups = node_groups,
		tiles = {
			{
				name = this_texture,
			},
		},
		sounds = {
			footstep = sound_spec,
		},
		paramtype = param1,
		paramtype2 = param2,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = shape or shapes.box
		},
	})
end


--- easily get going with nodes
---@param name string
---@param des string
---@param sound_spec table
---@param shape shape
---@param texture table : leave nil. the base node texture (name of a base node)
local function createMisc(name, des, sound_spec, shape, texture)
	local node_groups = { full_solid = 1, solid = 1, }
	--- easy breaking when in dev_mode
	local node_box = {
		type = "fixed",
		fixed = shape or shapes.box
	}
	local selectable = nil
	if tg_main.dev_mode == true then
		node_groups["dig_immediate"] = 3
	else
		selectable = {
			type = "fixed",
			fixed = { 0, 0, 0, 0, 0, 0 }
		}
	end
	local is_walkable = true
	if shape == shapes.panel or shape == shapes.sheet then
		is_walkable = false
	end
	core.register_node("tg_nodes:" .. name, {
		description = S(des),
		groups = node_groups,
		tiles = texture,
		sounds = {
			footstep = sound_spec,
		},
		paramtype2 = "facedir",
		paramtype = "light",
		drawtype = "nodebox",
		walkable = is_walkable,
		use_texture_alpha = "clip",
		sunlight_propagates = true,
		node_box = node_box,
		selection_box = selectable or node_box,
	})
end

--- same as createNodes but for plants
---@param name string
---@param des string
---@param shape shape|nil
local function createPlant(name, des, shape, texture)
	local node_groups = { full_solid = 1, solid = 1, }
	--- easy breaking when in dev_mode
	if tg_main.dev_mode == true then
		node_groups["dig_immediate"] = 3
	end
	local this_texture = "tg_nodes_" .. name .. ".png"
	if texture then
		this_texture = "tg_nodes_" .. texture
	end
	local scale = 1.0
	if string.find(texture, "8x8") then
		scale = 2.0
	end
	core.register_node("tg_nodes:" .. name, {
		description = S(des),
		groups = node_groups,
		tiles = {
			{
				name = this_texture
			},
		},
		visual_scale = scale,
		-- waving = 1, -- there is no wind down here
		buildable_to = true, -- If true, placed nodes can replace this node
		floodable = false,
		paramtype = "light",
		drawtype = "plantlike",
		sunlight_propagates = true,
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = shape or shapes.box
		},
	})
end

--- same as createNodes but for lights
---@param name string
---@param des string
---@param shape shape|nil
local function createWallLight(name, des, shape, light_level)
	local node_groups = { full_solid = 1, solid = 1, }
	--- easy breaking when in dev_mode
	if tg_main.dev_mode == true then
		node_groups["dig_immediate"] = 3
	end
	core.register_node("tg_nodes:" .. name, {
		description = S(des),
		groups = node_groups,
		tiles = {
			{
				name = "tg_nodes_" .. name .. ".png"
			},
		},
		drawtype = "signlike",
		paramtype = "light",
		paramtype2 = "wallmounted",
		light_source = light_level,
		walkable = false,
		sunlight_propagates = true,
		selection_box = {
			type = "fixed",
			fixed = shape or shapes.box
		},
		on_construct = function(pos)
			core.get_node_timer(pos):start(1.0)
		end,
		on_timer = function(pos, elapsed, node, timeout)
			local power = tg_power.getPower()
			if power == false then
				-- core.log("light should be off")
				if not string.find(node.name, "off") then
					-- local meta = core.get_meta(pos)
					local updated_node = node
					-- updated_node.light_source = 1
					-- core.set_node(pos, updated_node)
					core.swap_node(pos, { name = "tg_nodes:led_off", param2 = node.param2})
				end
			else
				if string.find(node.name, "off") then
				-- core.log("light should be on")
				core.swap_node(pos, { name = "tg_nodes:led_on", param2 = node.param2 })
				end
			end
			-- core.log("is the power on? " .. dump(power))
			core.get_node_timer(pos):start(1.0)
		end,
	})
end

core.register_node("tg_nodes:fog", {
	description = S("Fog, hard to look past."),
	groups = { full_solid = 1, solid = 1, },
	tiles = {
		{
			name = "tg_nodes_fog.png^[opacity:90",
		},
	},
	use_texture_alpha = "blend",
	-- backface_culling = false,
	paramtype = "light",
	drawtype = "glasslike",
	node_box = {
		type = "fixed",
		fixed = shapes.box
	},
	sunlight_propagates = false,
	walkable = false,
})

core.register_node("tg_nodes:fern", {
	description = S("fern, very lushes"),
	groups = { dig_immediate = 3 },
	waving = 0, -- there is no wind down here
	paramtype = "light",
	drawtype = "mesh",
	mesh = "fern.glb",
	visual_scale = 16.0,
	tiles = { "fern.png" },
	paramtype2 = "4dir",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = shapes.slim_box
	},
})

core.register_node("tg_nodes:king_trumpet", {
	description = S("king_trumpet, very lushes"),
	groups = { dig_immediate = 3 },
	waving = 0, -- there is no wind down here
	paramtype = "light",
	drawtype = "mesh",
	mesh = "king_trumpet.glb",
	visual_scale = 16.0,
	tiles = { "king_trumpet.png" },
	paramtype2 = "4dir",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = shapes.slim_box
	},
})

core.register_node("tg_nodes:beam", {
	description = S("beam, cold to the touch."),
	groups = { dig_immediate = 3 },
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
	groups = { dig_immediate = 3 },
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


core.register_node("tg_nodes:tubes", {
	description = S("tubes, for transfering liquids."),
	groups = { dig_immediate = 3 },
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
})
core.register_node("tg_nodes:tubes_left", {
	description = S("tubes_left, for transfering liquids."),
	groups = { dig_immediate = 3 },
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
})
core.register_node("tg_nodes:tubes_right", {
	description = S("tubes_right, for transfering liquids."),
	groups = { dig_immediate = 3 },
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
})
core.register_node("tg_nodes:tubes_down", {
	description = S("tubes_down, for transfering liquids."),
	groups = { dig_immediate = 3 },
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
})

function tg_nodes.defNode(name, sound_spec)
	local node_groups = { full_solid = 1, solid = 1, }
	--- easy breaking when in dev_mode
	if tg_main.dev_mode == true then
		node_groups["dig_immediate"] = 3
	end
	local nodes_to_register = { name, name .. "_stairs", name .. "_slab", name .. "_panel", name .. "_rails" }
	for index, value in ipairs(nodes_to_register) do
		local param1 = "none"
		local param2 = "none"
		local shape = shapes.box
		local sel_box = nil
		if string.find(value, "stairs") or string.find(value, "slab") or string.find(value, "panel") or string.find(value, "rails") then
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
			groups = node_groups,
			tiles = {
				{
					name = "tg_nodes_" .. name .. ".png",
				},
			},
			sounds = {
				footstep = sound_spec,
			},
			paramtype = param1,
			paramtype2 = param2,
			drawtype = "nodebox",
			node_box = nodebox,
			selection_box = sel_box or nodebox,
		})
	end
end

createNode("stone", "stone", { name = sounds.concrete, gain = 0.3 })
createNode("stone_slab", "stone slab", { name = sounds.concrete, gain = 0.3 }, shapes.slab, "stone")
createNode("stone_stairs", "stone stairs", { name = sounds.concrete, gain = 0.3 }, shapes.stairs, "stone")
createNode("cave_ground", "cave ground", { name = sounds.gravel, gain = 0.3 })
createNode("cave_ground_2", "cave ground, feels moist", { name = sounds.gravel, gain = 0.3 })
createNode("dirt", "dirt, cold", { name = sounds.gravel, gain = 0.3 })
createNode("dirt_slab", "dirt, cold", { name = sounds.gravel, gain = 0.3 }, shapes.slab, "dirt")
createNode("cave_ground_dirt", "cave ground, with dirt", { name = sounds.gravel, gain = 0.3, })
createNode("concrete", "concrete, no one is taking care of this.", { name = sounds.concrete, gain = 0.3, })
createNode("concrete_stair", "concrete, no one is taking care of this.", { name = sounds.concrete, gain = 0.3, },
	shapes.stairs, "concrete")
createNode("concrete_slab", "concrete, no one is taking care of this.", { name = sounds.concrete, gain = 0.3, },
	shapes.slab, "concrete")
createNode("concrete_floor", "concrete floor, almost like sand paper.", { name = sounds.concrete, gain = 0.3, })

createMisc("locker", "Locker, LET ME IN!!", { name = sounds.concrete, gain = 0.3, }, shapes.double,
	{ { name = "tg_nodes_misc.png^[sheet:16x16:3,0" }, { name = "tg_nodes_misc.png^[sheet:16x8:0,0" } })
createMisc("paper", "Paper", { name = sounds.paper, gain = 0.3, }, shapes.sheet,
	{ { name = "tg_nodes_misc.png^[sheet:16x16:0,3" } })
createMisc("paper_1", "Paper", { name = sounds.paper, gain = 0.3, }, shapes.sheet,
	{ { name = "tg_nodes_misc.png^[sheet:16x16:1,3" } })
-- sticky notes, 4 texture options.. the quickest implementation is multiple nodes
createMisc("stick_notes", "Sticky Note, one of these had gotta have something important on it.",
	{ name = sounds.paper, gain = 0.9, }, shapes.sheet, { { name = "tg_nodes_misc.png^[sheet:16x16:0,4" } })
createMisc("stick_notes_1", "Sticky Note, one of these had gotta have something important on it.",
	{ name = sounds.paper, gain = 0.9, }, shapes.sheet, { { name = "tg_nodes_misc.png^[sheet:16x16:1,4" } })
createMisc("stick_notes_2", "Sticky Note, one of these had gotta have something important on it.",
	{ name = sounds.paper, gain = 0.9, }, shapes.sheet, { { name = "tg_nodes_misc.png^[sheet:16x16:2,4" } })
createMisc("stick_notes_3", "Sticky Note, one of these had gotta have something important on it.",
	{ name = sounds.paper, gain = 0.9, }, shapes.sheet, { { name = "tg_nodes_misc.png^[sheet:16x16:3,4" } })

createPlant("short_grass", "Grass, they tickle", shapes.tiny_box, "plants.png^[sheet:16x16:7,0")
createPlant("plant", "Plant, they tickle", shapes.slim_box, "plants.png^[sheet:16x16:6,1")
createPlant("caladium", "Caladium, odd looking plants.", shapes.slim_box, "plants.png^[sheet:16x16:6,0")
createPlant("fungus", "Fungus, a King trumpet.", shapes.tiny_box, "plants.png^[sheet:16x16:9,0")
createPlant("fungus_small", "Fungus, a King trumpet.", shapes.tiny_box, "plants.png^[sheet:16x16:9,1")
createPlant("shrub", "Shrub, it' dry.", shapes.slim_box, "plants.png^[sheet:8x8:0,0")

createWallLight("led_on", "led, blinding.", shapes.panel, 10)
createWallLight("led_off", "led, blinding.", shapes.panel, 0)

tg_nodes.defNode("steel_enclosure", { name = sounds.concrete, gain = 0.3, })
tg_nodes.defNode("concrete_tiled", { name = sounds.concrete, gain = 0.3, })
