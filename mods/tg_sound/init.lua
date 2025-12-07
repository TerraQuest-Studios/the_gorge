tg_sound = {}

-- lazy soundspec generation
local function LSSG(spec, name, gain, pitch)
    spec = spec or {}
    -- prefer spec's name, otherwise use provided "default" name, or default to a universal name in error
    spec.name = spec.name or name or "tg_concrete_footstep"
    -- prefer spec's gain, otherwise use provided "default" gain, or default to 0.3
    spec.gain = spec.gain or gain or 0.3
    -- prefer spec's pitch, otherwise use provided "default" pitch, or default to 1
    spec.pitch = spec.pitch or pitch or 1
    return spec
end

-- snd = soundspec
-- concrete
function tg_sound.node_defaults(snd)
    snd = snd or {}
    snd.footstep = LSSG(snd.footstep)
    return snd
end

-- stone
function tg_sound.stone_defaults(snd)
    snd = snd or {}
    snd.footstep = LSSG(snd.footstep, "tg_rock_footstep", 0.5)
    return snd
end

-- gravel
function tg_sound.gravel_defaults(snd)
    snd = snd or {}
    snd.footstep = LSSG(snd.footstep, "tg_gravel_footstep")
    return snd
end

-- dirt
function tg_sound.dirt_defaults(snd)
    snd = snd or {}
    snd.footstep = LSSG(snd.footstep, "tg_dirt_footstep")
    return snd
end

-- paper
function tg_sound.paper_defaults(snd)
    snd = snd or {}
    snd.footstep = LSSG(snd.footstep, "tg_paper_footstep", 0.9)
    return snd
end

-- wooden plank / hollow wood
function tg_sound.woodplank_defaults(snd)
    snd = snd or {}
    snd.footstep = LSSG(snd.footstep, "tg_plank_footstep")
    return snd
end

-- metal
function tg_sound.metal_defaults(snd)
    snd = snd or {}
    snd.footstep = LSSG(snd.footstep, "tg_metal_footstep", 0.55)
    return snd
end

-- plant
function tg_sound.plant_defaults(snd)
    snd = snd or {}
    snd.footstep = LSSG(snd.footstep, "tg_plant_footstep")
    snd.place = LSSG(snd.place, "tg_plant_footstep", 0.2, 1.25)
    snd.dug = LSSG(snd.dug, "tg_plant_footstep", 0.15, 0.7)
    --snd.rustling = LSSG(snd.rustling, "tg_plant_footstep", 0.6)
    return snd
end