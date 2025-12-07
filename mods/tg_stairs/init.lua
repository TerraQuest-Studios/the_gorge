tg_stairs = {}

local stairtable = {
    {
        "slab",
        {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    {
        "stair",
        {
            {-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
            {-0.5, 0.0, 0.0, 0.5, 0.5, 0.5},
        },
    },
    {
        "stair_inner",
        {
            {-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
            {-0.5, 0.0, 0.0, 0.5, 0.5, 0.5},
            {-0.5, 0.0, -0.5, 0.0, 0.5, 0.0},
        },
    },
    {
        "stair_outer",
        {
            {-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
            {-0.5, 0.0, 0.0, 0.0, 0.5, 0.5},
        },
    },
}

function tg_stairs.register(name, def)
    for _, sdef in pairs(stairtable) do
        local split = name:split(":")
        local ndef = table.copy(def)
        local item_name = ":" .. sdef[1] .. "_" .. split[2]

        ndef.description = def.description .. " " .. string.gsub(sdef[1], "_", " ")
        ndef.paramtype, ndef.paramtype2 = "light", "facedir"
        ndef.drawtype = "nodebox"
        ndef.node_box = {
            type = "fixed",
            fixed = sdef[2],
        }

        ndef.sounds = ndef.sounds or tg_sound.node_defaults()

        minetest.register_node(":" .. split[1] .. item_name, ndef)
    end
end