local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

tg_main = {}

dofile(mod_path .. "/scripts" .. "/math.lua")
dofile(mod_path .. "/scripts" .. "/debug.lua")
dofile(mod_path .. "/scripts" .. "/utils.lua")
-- spawn objects
dofile(mod_path .. "/objects.lua")

-- Either "flat" or "singlenode".
tg_main.mg_name = core.get_mapgen_setting("mg_name") or "singlenode"
-- Enter dev mode if mapgen "flat" or creative setting is `true`.
-- This stops normal gameplay functions from running.
tg_main.dev_mode = core.is_creative_enabled() --creative mode is toggled by game build mode settings
-- Skip intro if on mapgen "flat".
tg_main.skip_intro = false                    --(tg_main.mg_name == "flat")

-- the player's defualt reach
tg_main.reach = 1.8

-- extend the reach
if core.is_creative_enabled() == true then
  tg_main.reach = 5.0
end

-- fog colors
tg_main.fog_color = {
  white = "#ffffff",
  gray = "#111111",
  black = "#000000",
}

core.override_item("", {
  range = tg_main.reach,
  wield_image = "player.png^[sheet:16x13:4,8^[opacity:0",
  wield_scale = {x = 0.5, y = 0.5, z = 0.5},
  use_texture_alpha = true,
  -- color = "#fcdca4",
})

-- core.register_chatcommand(mod_name .. ":" .. "resetobjects", {
core.register_chatcommand("basepower", {
  params = "basepower <privilege>",
  description = "toggle the power on/off",
  privs = { privs = true }, -- Require the "privs" privilege to run
  func = function(name, param)
    tg_power.togglePower()
  end,
})
