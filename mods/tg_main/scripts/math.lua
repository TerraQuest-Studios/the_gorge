
function tg_main.angle_difference(a0, a1)
    local max = math.pi * 2
    local da = (a1 - a0) % max
    return 2 * da % max - da
end

function tg_main.angle_lerp(a0, a1, t)
    return a0 + tg_main.angle_difference(a0, a1) * t
end
