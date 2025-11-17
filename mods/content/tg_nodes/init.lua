local mod_name = core.get_current_modname()
local S = core.get_translator(mod_name)

core.register_node("tg_nodes:placeholder", {
	description = S("Placeholder Node"),
	groups = { full_solid = 1, solid = 1, },
	tiles = {
		{
			name = "tg_nodes_placeholder.png^[multiply:#888",
			align_style = "world", scale = 16,
		},
	},
})

-- def node shapes
---@class shape
local shapes = {
	box = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	slab = { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
	stairs = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0.5, 0.5, 0.5},
	},
	tiny_box = { -0.2, -0.5, -0.2, 0.2, -0.1, 0.2 }, -- small box touching the ground (plant / anything small)
	slim_box = { -0.2, -0.5, -0.2, 0.2, 0.3, 0.2 }, -- same as tiny_box, just taller
}

--- easily get going with nodes
---@param name string
---@param des string
---@param shape shape|nil
---@param texture string|nil : leave nil. the base node texture (name of a base node)
local function createNode(name,des,shape,texture)
	local node_groups = { full_solid = 1, solid = 1, }
	--- easy breaking when in dev_mode
	if tg_main.dev_mode == true then
		node_groups["dig_immediate"] = 3
	end
	local this_texture = "tg_nodes_"..name..".png"
	if texture then
		this_texture = "tg_nodes_"..texture..".png"
	end
	local param1 = "none"
	local param2 = "none"
	if shape ~= nil and shape ~= shapes.box then
		param1 = "light"
		param2 = "facedir"
	end
	core.register_node("tg_nodes:"..name, {
		description = S(des),
		groups = node_groups,
		tiles = {
			{
				name = this_texture,
			},
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

--- same as createNodes but for plants
---@param name string
---@param des string
---@param shape shape|nil
local function createPlant(name, des,shape,texture)
	local node_groups = { full_solid = 1, solid = 1, }
	--- easy breaking when in dev_mode
	if tg_main.dev_mode == true then
		node_groups["dig_immediate"] = 3
	end
	local this_texture = "tg_nodes_"..name..".png"
	if texture then
		this_texture = "tg_nodes_"..texture
	end
	local scale = 1.0
	if string.find(texture,"8x8") then
		scale = 2.0
	end
	core.register_node("tg_nodes:"..name, {
		description = S(des),
		groups = node_groups,
		tiles = {
			{
				name = this_texture
			},
		},
    visual_scale = scale,
		-- waving = 1, -- there is no wind down here
		buildable_to = true,  -- If true, placed nodes can replace this node
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
local function createWallLight(name, des,shape,light_level)
	local node_groups = { full_solid = 1, solid = 1, }
	--- easy breaking when in dev_mode
	if tg_main.dev_mode == true then
		node_groups["dig_immediate"] = 3
	end
	core.register_node("tg_nodes:"..name, {
		description = S(des),
		groups = node_groups,
		tiles = {
			{
				name = "tg_nodes_"..name..".png"
			},
		},
		drawtype = "signlike",
		paramtype = "light",
		paramtype2 = "wallmounted",
		light_source = light_level,
		sunlight_propagates = true,
		selection_box = {
			type = "fixed",
			fixed = shape or shapes.box
		},
	})
end

createNode("stone","stone")
createNode("stone_slab","stone slab",shapes.slab,"stone")
createNode("stone_stairs","stone stairs",shapes.stairs,"stone")
createNode("cave_ground","cave ground")
createNode("cave_ground_2","cave ground, feels moist")
createNode("dirt","dirt, cold")
createNode("cave_ground_dirt","cave ground, with dirt")

createPlant("short_grass","Grass, they tickle",shapes.tiny_box,"plants.png^[sheet:16x16:7,0")
createPlant("plant","Plant, they tickle",shapes.slim_box,"plants.png^[sheet:16x16:6,1")
createPlant("caladium","Caladium, odd looking plants.",shapes.slim_box,"plants.png^[sheet:16x16:6,0")
createPlant("fungus","Fungus, a King trumpet.",shapes.tiny_box,"plants.png^[sheet:16x16:9,0")
createPlant("fungus_small","Fungus, a King trumpet.",shapes.tiny_box,"plants.png^[sheet:16x16:9,1")
createPlant("shrub","Shrub, it' dry.",shapes.slim_box,"plants.png^[sheet:8x8:0,0")

createWallLight("led","led, blinding.",shapes.box,9)

--- trying out higher res plants, for
core.register_node("tg_nodes:fern", {
		description = S("fern, very lushes"),
		groups = {dig_immediate = 3},
		waving = 0, -- there is no wind down here
		paramtype = "light",
		drawtype = "mesh",
  	mesh = "fern.glb",
    visual_scale = 16.0,
		tiles = {"fern.png"},
		paramtype2 = "4dir",
  	use_texture_alpha = "clip",
		sunlight_propagates = true,
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = shapes.slim_box
		},
})

