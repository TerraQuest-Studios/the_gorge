
function tg_main.debug_particle(pos, color, time, vel, size)
    -- do return end -- for debug purposes
    core.add_particle({
        size = size or 2,
        pos = pos,
        texture = "[fill:1x1:"..(color or "#fff"),
        velocity = vel or vector.new(0, 0, 0),
        expirationtime = time,
        glow = 14,
    })
end
