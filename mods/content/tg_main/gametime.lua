--[[

THIS IS PLANNED TO BE REMOVED, DO NOT DEPEND ON

purpose of this is to provide appropriate timing and a revisioned primitive `core.after`

--]]

-- current game time, starts ticking upon world start
local gametime = 0

-- for `core.after` like functionality
-- adds each dependent function to here
local funclist = {}

-- store each function into here :shrug:
local funcs = {
    -- permits "since" argument for getting `gametime - since`
    --- provides `gametime`, or a number subtracted by gametime if provided a `since`
    ---@param since? number
    ---@return number
    get_time = function(since)
        return type(since) == "number" and gametime - since or gametime
    end,

    -- `core.after` function
    --- similar to `core.after`, expect provides the amount of time it took for function to be ran as first argument
    after = function(delay, func, ...)
        if not tonumber(delay) or core.is_nan(delay) then
            error(
                "gametime.after: invalid invocation - provided delay argument is not number or is an impossible number"
            )
        end
        if type(func) ~= "function" then
            error("gametime.after: invalid invocation - provided func argument is not a function. Got "..type(func))
        end
        -- add to list
        funclist[#funclist + 1] = {
            delay = delay,
            func = func,
            start = gametime,
            args = {...}
        }
    end
}

-- do counting
core.register_globalstep(function(dtime)
    gametime = gametime + dtime
    -- run `core.after` esque stuff
    for ind,data in ipairs(funclist) do
        local elapsed = funcs.get_time(data.start)
        -- has been past the delay!
        if elapsed > data.delay then
            data.func(elapsed, unpack(data.args))
            -- remove from list
            table.remove(funclist, ind)
        end
    end
end)

return funcs