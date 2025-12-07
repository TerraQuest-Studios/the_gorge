local startpos = vector.new(-43, 1.5, -18.5) -- position for player to spawn at

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
  tg_cut_scenes.hud(player,messages)
  --reset the player incase they did dumb things
  player:set_pos(startpos)
  player:set_look_vertical(0)
end)
