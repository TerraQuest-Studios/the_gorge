local stallpos = vector.new(-50, 2, -13) -- inside a wall so we can't move
local startpos = vector.new(-43, 2, -18.5)

local messages = {
    -- empty message, for timing.
    [[
    ]],
    --
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
    player:set_pos(stallpos)

    local current_huds = {} --player:hud_get_all()

    --luanti is stupid, get huds next server step
    core.after(0, function()
        current_huds = player:hud_get_all()
        for id, hud in ipairs(current_huds) do
            --avoid screwing over our huds
            if hud.type ~= "text" and hud.type ~= "image" then
                player:hud_remove(id)
            end
        end
    end)

    local current_message = 1

    local base_background = player:hud_add({
        hud_elem_type = "image",
        position = { x = 0.5, y = 0.5 },
        scale = { x = -101, y = -101 },
        text = "[combine:16x16^[noalpha",
        alignment = { x = 0, y = 0 },
    })

    local text_message = player:hud_add({
        hud_elem_type = "text",
        position = { x = 0.43, y = 0.5 }, -- 0.42 seems to center the text better.
        text = messages[current_message],
        alignment = { x = 0, y = 0 },
        scale = { x = 100, y = 100 },
        number = 0xFFFFFF,
        size = { x = 4, y = 4 },
    })

    local fade_overlay_hud = player:hud_add({
        hud_elem_type = "image",
        position = { x = 0.5, y = 0.5 },
        scale = { x = -101, y = -101 },
        text = "[combine:16x16^[noalpha^[opacity:255",
        alignment = { x = 0, y = 0 },
    })

    local fade_in_opacity = 225
    local fade_out_opacity = 225
    local slide_duration = 10

    core.register_globalstep(function(dtime)
        if fade_in_opacity > 0 then
            player:hud_change(fade_overlay_hud, "text", "[combine:16x16^[noalpha^[opacity:" .. fade_in_opacity)
            fade_in_opacity = fade_in_opacity - 100 * dtime
            if fade_in_opacity < 0 then
                fade_in_opacity = 0
                --core.chat_send_all("fade in complete")

                core.after(slide_duration, function()
                    --core.chat_send_all("starting fade out")
                    fade_out_opacity = 0.01
                end)
            end
        end
    end)

    core.register_globalstep(function(dtime)
        --[[ if tg_main.skip_intro == true then
            player:hud_remove(base_background)
            player:hud_remove(text_message)
            player:hud_remove(fade_overlay_hud)
            for id, hud in ipairs(current_huds) do
                if hud.type ~= "text" and hud.type ~= "image" then
                    player:hud_add(hud)
                end
            end
        else ]]
            if fade_out_opacity > 0 and fade_out_opacity < 255 then
                player:hud_change(fade_overlay_hud, "text", "[combine:16x16^[noalpha^[opacity:" .. fade_out_opacity)
                fade_out_opacity = fade_out_opacity + 100 * dtime
                if fade_out_opacity > 255 then
                    fade_out_opacity = 255

                    core.after(2, function()
                        --core.chat_send_all("fade out complete")
                        current_message = current_message + 1
                        if current_message > #messages then
                            player:hud_remove(base_background)
                            player:hud_remove(text_message)
                            player:hud_remove(fade_overlay_hud)

                            for id, hud in ipairs(current_huds) do
                                if hud.type ~= "text" and hud.type ~= "image" then
                                    player:hud_add(hud)
                                end
                            end

                            --reset the player incase they did dumb things
                            player:set_pos(startpos)
                            player:set_look_vertical(0)
                            player:set_look_horizontal(0)
                        else
                            player:hud_change(text_message, "text", messages[current_message])
                            fade_in_opacity = 225
                        end
                    end)
                end
            end
        --[[ end ]]
    end)
end)
