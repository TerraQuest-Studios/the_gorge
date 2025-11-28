--paradise_sightseer.ogg

core.register_on_joinplayer(function(player)
    core.sound_play({
        name = "paradise_sightseer",
        gain = 1,
        to_player = player:get_player_name(),
        loop = true,
    })

    --spec simplesoundspec
    --params

    --core.sound_stop
end)