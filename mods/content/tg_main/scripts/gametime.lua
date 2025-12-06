-- provides appropriate timing and a revisioned primitive `core.after`

-- for `core.after` like functionality
local funclist = {}

-- current game time, starts ticking upon world start
tg_main.gametime = 0

-- permits "since" argument for getting `gametime - since`
--- provides `tg_main.gametime`, or a number subtracted by gametime if provided a `since`
---@param? since number
---@return number
function tg_main.get_time(since)
    return type(since) == "number" and tg_main.gametime - since or tg_main.gametime
end

-- do counting
core.register_globalstep(function(dtime)
    tg_main.gametime = tg_main.gametime + dtime
    -- run `core.after` esque stuff
    for ind,data in ipairs(funclist) do
        local elapsed = tg_main.get_time(data.start)
        -- has been past the delay!
        if elapsed > data.delay then
            data.func(elapsed, unpack(data.args))
            -- remove from list
            table.remove(funclist, ind)
        end
    end
end)

-- `core.after` function
function tg_main.after(delay, func, ...)
    if not tonumber(delay) or core.is_nan(delay) then
        error("tg_main.after: invalid invocation - provided delay argument is not number or is an impossible number")
    end
    if type(func) ~= "function" then
        error("tg_main.after: invalid invocation - provided func argument is not a function. Got "..type(func))
    end
    -- add to list
    funclist[#funclist + 1] = {
        delay = delay,
        func = func,
        start = tg_main.gametime,
        args = {...}
    }
end