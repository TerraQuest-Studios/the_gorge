unused_args = false
allow_defined_top = true

exclude_files = {".luacheckrc", "mods/content/aom_wrench/**"}

globals = {
    "minetest", "core",

    --mod provided
    "dungeon_loot", "fl_workshop", "fl_player", "fl_stone", "fl_trees", "fl_topsoil", "fl_plantlife"
}

read_globals = {
    string = {fields = {"split"}},
    table = {fields = {"copy", "getn"}},

    --luac
    "math", "table",

    -- Builtin
    "vector", "ItemStack", "dump", "DIR_DELIM", "VoxelArea", "Settings", "PcgRandom", "VoxelManip", "PseudoRandom",

    --mod produced
    "tg_main", "tg_mapgen", "aom_wrench",
}