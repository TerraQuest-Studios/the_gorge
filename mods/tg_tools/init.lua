tg_nodes.register_node_complex("drill_press", {
    desc = "Drill Press",
    mesh = "tg_drillpress.obj",
    shape = "double",
    visual_scale = 1,
    tiles = { "tg_drillpress.png^(tg_overlay_dirt_0.png^[multiply:#112^[opacity:160)" },
    sounds = tg_sound.metal_defaults(),
    groups = {tooling=1}
})

tg_nodes.register_node_complex("lathe", {
    desc = "Lathe",
    mesh = "tg_lathe.obj",
    visual_scale = 1,
    tiles = { "tg_lathe.png^(tg_overlay_dirt_0.png^[multiply:#112^[opacity:160)" },
    sounds = tg_sound.metal_defaults(),
    groups = {tooling=1},
    -- sets collision and selection boxes
    shape = {
        -- tailstock
        {0.62, 1.35, 0.52, -0.62, -0.5, -0.62},
        -- bed
        {0.6, 0.75, 2, -0.6, 0.15, 0.52},
        -- headstock
        {0.62, 1.55, 3.4, -0.62, -0.5, 2},
    }
})

--[[
minetest.register_node("tg_tools:drill_press", {
    description = "Drill Press",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
        "tg_drillpress.png^(tg_overlay_dirt_0.png^[multiply:#112^[opacity:160)"
    },
    mesh = "tg_drillpress.obj",
    groups = {oddly_breakable_by_hand = 2},
})

minetest.register_node("tg_tools:lathe", {
    description = "Lathe",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
        "tg_lathe.png^(tg_overlay_dirt_0.png^[multiply:#112^[opacity:160)"
    },
    mesh = "tg_lathe.obj",
    groups = {oddly_breakable_by_hand = 2},
})
--]]
