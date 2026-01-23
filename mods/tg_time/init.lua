--[[

purpose of this is to provide appropriate timing and a revisioned primitive `core.after`

provides functionality for on world start as well!

--]]

-- create global
tg_time = {}

-- active time, starts ticking upon world globalstep initiation
local activetime = 0

-- get mod storage for overall game time
local modstor = core.get_mod_storage()
-- total time world has been active (since freshly created)
local gametime = tonumber(modstor:get_float("gametime")) or activetime

-- store gametime to mod storage
local function store_gametime()
    modstor:set_float("gametime", gametime)
end

-- unique events
local funclist = {
    -- for `core.after` like functionality
    -- adds each dependent function to here
    after = {},
    -- for functionality of running a ONE-TIME function after a set time has elapsed
    -- since the world was created (e.g. spawning important entities, stuff to do on world creation)
    worldcreate = {},
}

-- start from when world was created
function tg_time.register_timed_from_worldcreate(time, func)
    if time < tg_time.get_overall_time() then return end -- no need, the time has already passed
    -- add to list
    table.insert(funclist.worldcreate, {
        func = func,
        time = time,
    })
end


funclist.after = {}

-- permits "since" argument for getting `activetime - since`
--- provides `activetime`, or a number subtracted by activetime if provided a `since`
---@param since? number if provided, subtracts activetime by said number
---@return number
function tg_time.get_time(since)
    return type(since) == "number" and activetime - since or activetime
end

--- provides `gametime`, or a number subtracted by gametime if provided a `since`
---@param since? number if provided, subtracts gaetime by said number
---@return number
function tg_time.get_overall_time(since)
    -- may as well store it here too
    store_gametime()
    return type(since) == "number" and gametime - since or gametime
end

-- `core.after` function
--- similar to `core.after`, expect provides the amount of time it took for function to be ran as first argument
function tg_time.after(delay, func, ...)
    if not tonumber(delay) or core.is_nan(delay) then
        error(
            "tg_time.after: invalid invocation - provided delay argument is not number or is an impossible number"
        )
    end
    if type(func) ~= "function" then
        error("tg_time.after: invalid invocation - provided func argument is not a function. Got "..type(func))
    end
    -- add to list
    table.insert(funclist.after, {
        delay = delay,
        func = func,
        start = activetime,
        args = {...}
    })
end

-- save gametime check
local SGC = 120 -- save every 2 minutes

-- do counting
core.register_globalstep(function(dtime)
    activetime = activetime + dtime
    gametime = gametime + dtime -- update as well
    -- update stored gametime every 2 minutes
    SGC = SGC - dtime
    if SGC < 0 then
        store_gametime()
        SGC = 120
    end
    -- run worldcreate stuff
    for ind,data in ipairs(funclist.worldcreate) do
        if gametime > data.time then
            -- provide time elapsed as argument
            data.func(gametime)
            -- remove
            table.remove(funclist.worldcreate, ind)
        end
    end
    -- run `core.after` esque stuff
    for ind,data in ipairs(funclist.after) do
        local elapsed = tg_time.get_time(data.start)
        -- has been past the delay!
        if elapsed > data.delay then
            data.func(elapsed, unpack(data.args))
            -- remove from list
            table.remove(funclist, ind)
        end
    end
end)

-- store gametime on world end
core.register_on_shutdown(function()
    store_gametime()
end)