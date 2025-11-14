local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

aom_wrench = {}

dofile(mod_path .. "/scripts/system.lua")
dofile(mod_path .. "/items/wrench.lua")
dofile(mod_path .. "/compat.lua")
