--[[

purpose of this is to provide appropriate timing and a revisioned primitive `core.after`

provides functionality for on world start as well!

--]]

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

-- for `core.after` like functionality
-- adds each dependent function to here
local funclist = {}

-- store each function into here :shrug:
tg_time = {
    -- permits "since" argument for getting `activetime - since`
    --- provides `activetime`, or a number subtracted by activetime if provided a `since`
    ---@param since? number if provided, subtracts activetime by said number
    ---@return number
    get_time = function(since)
        return type(since) == "number" and activetime - since or activetime
    end,
    
    --- provides `gametime`, or a number subtracted by gametime if provided a `since`
    ---@param since? number if provided, subtracts gaetime by said number
    ---@return number
    get_overall_time = function(since)
        -- may as well store it here too
        store_gametime()
        return type(since) == "number" and gametime - since or gametime
    end,

    -- `core.after` function
    --- similar to `core.after`, expect provides the amount of time it took for function to be ran as first argument
    after = function(delay, func, ...)
        if not tonumber(delay) or core.is_nan(delay) then
            error(
                "tg_time.after: invalid invocation - provided delay argument is not number or is an impossible number"
            )
        end
        if type(func) ~= "function" then
            error("tg_time.after: invalid invocation - provided func argument is not a function. Got "..type(func))
        end
        -- add to list
        funclist[#funclist + 1] = {
            delay = delay,
            func = func,
            start = activetime,
            args = {...}
        }
    end
}

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
    -- run `core.after` esque stuff
    for ind,data in ipairs(funclist) do
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