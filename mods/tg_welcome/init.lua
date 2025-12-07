-- position for player to spawn at
local startpos = vector.new(-43, 1.5, -18.5)

local messages = {
  [[
        Welcome to The Gorge
        Trapped deep within a shadowy ravine
        With a thin line of sight to the outside world
        Will you escape?
    ]],
  [[
        Survive the depths and corners
        Find hidden secrets
        Gather the pieces you need to escape
        Will you make it out in time?
    ]],
  [[
        Good luck, adventurer
        The Gorge awaits your courage and wit
    ]]
}

core.register_on_newplayer(function(player)
  player:set_pos(startpos)
  tg_cut_scenes.run(player, messages)
  --reset the player incase they did dumb things
  player:set_pos(startpos)
  player:set_look_vertical(0)
end)

core.register_on_joinplayer(function(player, last_login)
  if last_login==nil then
    return
  end

  core.after(0, function()
    for id, hud in ipairs(player:hud_get_all()) do
      if hud.type == "hotbar" and not core.is_creative_enabled() then
        player:hud_remove(id)
      end
    end
  end)
end)
