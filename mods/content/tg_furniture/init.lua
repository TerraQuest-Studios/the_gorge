local furnitures = {
	chair = {
        { -0.3, -0.5, 0.2, -0.2, 0.5, 0.3 }, -- foot 1
        { 0.2, -0.5, 0.2, 0.3, 0.5, 0.3 }, -- foot 2
        { 0.2, -0.5, -0.3, 0.3, -0.1, -0.2 }, -- foot 3
        { -0.3, -0.5, -0.3, -0.2, -0.1, -0.2 }, -- foot 4
        { -0.3, -0.1, -0.3, 0.3, 0, 0.2 }, -- seating
        { -0.2, 0.1, 0.25, 0.2, 0.4, 0.26 } -- conector 1-2
	},
	table = {
        { -0.4, -0.5, -0.4, -0.3, 0.4, -0.3 }, -- foot 1
        { 0.3, -0.5, -0.4, 0.4, 0.4, -0.3 }, -- foot 2
        { -0.4, -0.5, 0.3, -0.3, 0.4, 0.4 }, -- foot 3
        { 0.3, -0.5, 0.3, 0.4, 0.4, 0.4 }, -- foot 4
        { -0.5, 0.4, -0.5, 0.5, 0.5, 0.5 } -- table top
	},
	bench = {
        { -0.5, -0.1, 0, 0.5, 0, 0.5 }, -- seating
        { -0.4, -0.5, 0, -0.3, -0.1, 0.5 }, -- foot 1
        { 0.3, -0.5, 0, 0.4, -0.1, 0.5 } -- foot 2
	}
}

local wood_types = {
    {"oak", "[combine:16x16^[noalpha^[colorize:#563d2d"}
}

local node_groups = { full_solid = 1, solid = 1, }
--- easy breaking when in dev_mode
if tg_main.dev_mode == true then
    node_groups["dig_immediate"] = 3
end
for name, nodebox in pairs(furnitures) do
    for _, wood_type in pairs(wood_types) do
        minetest.register_node("tg_furniture:" .. wood_type[1] .. "_" .. name, {
            description = wood_type[1] .. " " .. name,
            drawtype = "nodebox",
            paramtype = "light",
            paramtype2 = "facedir",
            tiles = {
                {
                    -- name = wood_type[2],
                    -- align_style = "world",
                    name = "tg_nodes_steel_enclosure.png",
                }
            },
            node_box = {
                type = "fixed",
                fixed = nodebox
            },
            groups = node_groups
        })
    end
end
