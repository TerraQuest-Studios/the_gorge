local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

tg_nodes = {}

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
local function createPlant(name, des,shape)
	local node_groups = { full_solid = 1, solid = 1, }
	--- easy breaking when in dev_mode
	if tg_main.dev_mode == true then
		node_groups["dig_immediate"] = 3
	end
	local param1 = "none"
	local param2 = "none"
	core.register_node("tg_nodes:"..name, {
		description = S(des),
		groups = node_groups,
		tiles = {
			{
				name = "tg_nodes_"..name..".png"
			},
		},
		-- waving = 1, -- there is no wind down here
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


createNode("stone","stone")
createNode("stone_slab","stone slab",shapes.slab,"stone")
createNode("stone_stairs","stone stairs",shapes.stairs,"stone")
createNode("cave_ground","cave ground")
createNode("cave_ground_2","cave ground, feels moist")
createNode("dirt","dirt, cold")
createNode("cave_ground_dirt","cave ground, with dirt")

createPlant("short_grass","grass, they tickle",shapes.tiny_box)
createPlant("plant","grass, they tickle",shapes.slim_box)
