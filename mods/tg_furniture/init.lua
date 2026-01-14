-- global
tg_furniture = {

shapes = {
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
--
}
local shapes = tg_furniture.shapes

function tg_furniture.register_furniture(name, def)
    local defs = {} -- return all together
    -- iterate over furniture
    -- box name, box
    for bname, box in pairs(shapes) do
        local fdef = table.copy(def) -- furniture def
        -- description
        def.description = def.description or name
        def.description = def.description.." "..bname
        -- create groups
        fdef.groups = fdef.groups or {}
        fdef.groups.furniture = 1
        fdef.groups[bname] = 1
        -- set shape and register
        fdef.shape = box
        defs[bname] = tg_nodes.register_node_complex(bname.."_"..name, fdef)
    end
    -- return definitions
    return defs
end

-- metal furniture
tg_furniture.register_furniture("metal", {sounds=tg_sound.metal_defaults(), node_texture="steel_enclosure"})
-- convert to better system
core.register_alias_force("tg_furniture:oak_chair", "tg_furniture:chair_metal")
core.register_alias_force("tg_furniture:oak_table", "tg_furniture:table_metal")
core.register_alias_force("tg_furniture:oak_bench", "tg_furniture:bench_metal")