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
