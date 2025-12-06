unused_args = false
allow_defined_top = true

exclude_files = {".luacheckrc", "mods/content/aom_wrench/**"}

globals = {
    "minetest", "core",

    --from external deps
    "mapsync",
	"worldedit",
	"travelnet",
	"advtrains",
	"serialize_lib",
	"elevator",
	"hyperloop",
    "mtt",
    "mtzip",

    --mod provided
}

read_globals = {
    string = {fields = {"split"}},
    table = {fields = {"copy", "getn"}},

    --luac
    "math", "table",

    -- Builtin
    "vector", "ItemStack", "dump", "DIR_DELIM", "VoxelArea", "Settings", "PcgRandom", "VoxelManip", "PseudoRandom",

    --from external deps
    "hyperloop",

    --mod produced
    "tg_main", "tg_mapgen", "aom_wrench", "tg_stairs", "tg_power", "tg_nodes",
}