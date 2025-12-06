local base_slide_duration = 5 -- in seconds (default is 5), what calculations for each slide should be based around

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

    local messageindex = 1 -- message index
    local fadestep = 70 -- units per second, becomes 100 after 1st message

    -- graphics
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
        text = messages[messageindex],
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

    -- fades in text
    local fade_in -- declare prior so that we can use ourselves
    fade_in = function(delay, opacity, afterfunc, ...)
        opacity = opacity - (fadestep * delay)
        if opacity < 0 then
            opacity = 0
            return afterfunc(...)
        end
        player:hud_change(fade_overlay_hud, "text", "[combine:16x16^[noalpha^[opacity:"..opacity)
        -- continue looping
        tg_main.after(0, fade_in, opacity, afterfunc, ...)
    end

    -- fades out text
    local fade_out -- ditto to `fade_in`
    fade_out = function(delay, opacity, afterfunc, ...)
        opacity = opacity + (fadestep * delay)
        if opacity > 255 then
            opacity = 255
            return afterfunc(...)
        end
        player:hud_change(fade_overlay_hud, "text", "[combine:16x16^[noalpha^[opacity:"..opacity)
        -- continue looping
        tg_main.after(0, fade_out, opacity, afterfunc, ...)
    end

    local message_start -- being declared so it can be used by the `on_message`
    -- after message has fully faded in, runs fade_out after a delay of the calculated length provided by `on_message`
    local function on_message(len)
        -- run an after for fadeout
        tg_main.after(len, function()
            -- run function on after finish so that delay isn't transferred to fade_out parameters
            fade_out(0, 0, message_start)
        end)
        messageindex = messageindex + 1 -- iterate through
        -- turn into 100 after first message has been produced
        if messageindex ~= 1 then fadestep = 100 end
    end

    -- change text, run fade_in
    -- if no message can be found, end the welcome intro
    message_start = function()
        local message = messages[messageindex]
        -- end of the line
        if not message then
            -- remove all graphics
            player:hud_remove(base_background)
            player:hud_remove(text_message)
            player:hud_remove(fade_overlay_hud)

            -- restore huds
            for id, hud in ipairs(current_huds) do
                if hud.type ~= "text" and hud.type ~= "image" then
                    player:hud_add(hud)
                end
            end

            --reset the player incase they did dumb things
            player:set_pos(startpos)
            player:set_look_vertical(0)
            return player:set_look_horizontal(0)
        end
        -- continue with the welcome intro
        local len = base_slide_duration * (#message/121) -- slide duration multiplied by amount of characters
        -- divided by 121 for a percentage
        player:hud_change(text_message, "text", message) -- modify text
        fade_in(0, 255, on_message, len)
    end

    -- start message after a second
    core.after(1, message_start)
end)
