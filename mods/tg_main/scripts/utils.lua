---@class vector3
---@field x number
---@field y number
---@field z number

---comment
---@param pos1 vector3
---@param pos2 vector3
---@return number
function tg_main.distance(pos1, pos2)
  local dx = pos2.x - pos1.x
  local dy = pos2.y - pos1.y
  local dz = pos2.z - pos1.z
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function tg_main.calculateMidpoint(pos1, pos2)
  local midpoint = {
    x = (pos1.x + pos2.x) / 2,
    y = pos1.y + 0.5,
    z = (pos1.z + pos2.z) / 2
  }
  return midpoint
end

--- Function for linear interpolation between two Vector3 positions
---@param startPos vector3
---@param endPos vector3
---@param s number the speed
---@return vector3
function tg_main.lerp(startPos, endPos, s)
  return {
    x = startPos.x + (endPos.x - startPos.x) * s,
    y = startPos.y + (endPos.y - startPos.y) * s,
    z = startPos.z + (endPos.z - startPos.z) * s
  }
end

--- rounding with saving decimal options
--- @param num number number to be special-case rounded (saving decimal places)
--- @param decimal number integer > 0, determining how many decimal places to save (1 = 5.141 --> 5.1)
function tg_main.round(num, decimal)
    if type(num) ~= "number" then return end -- oopsie daisy
    -- purify decimal parameter (must be integer)
    if type(decimal) == "number" then
        -- clamp to 0 if below
        decimal = math.max( math.ceil(decimal), 0) -- and ceil to make sure it's not double
    else
        decimal = 2 -- default to saving 2 decimal places
    end
    -- why, why did you call this function?
    if decimal == 0 then
        return math.round(num)
    end
    -- exponent'ify the decimal for easier calculation
    decimal = 10 ^ decimal
    -- multiply num by exponent'ified decimal, to save the number of specified decimal places for later division
    num = num * decimal
    -- round that number the old way
    -- add a half as if it's underneath 0.5, it'll floor to the number below, otherwise be the
    -- greater number
    num = math.floor(num + .5)
    -- now to divide and return, preserving the wanting decimal places
    return (num / decimal)
end

--- rounding a vector with saving decimal options
--- @param vec vector3 vector to be special-case rounded (saving decimal places)
--- @param decimal number integer > 0, determining how many decimal places to save (1 = 5.141 --> 5.1)
function tg_main.vector_round(vec, decimal)
    -- clone vector!
    if vector.check(vec) then
        vec = vec:new()
    -- create new vector!
    else
        -- create a vector!
        if type(vec) == "table" then
            if #vec > 0 then
                vec = {x=vec[1], y=vec[2], z=vec[3]}
            end
            -- empty spaces be 0
            vec = vector.new(vec.x or 0, vec.y or 0, vec.z or 0)
        -- failed to create vector
        else
            return
        end
    end
    -- now for the actual goodies
    for coord, num in pairs(vec) do
        vec[coord] = tg_main.round(num, decimal)
    end
    -- return purified vector
    return vec
end

-- number from 0 to 3
function tg_main.get_facing(param2)
    return param2 == 3 and "+X" or param2 == 1 and "-X" or
      param2 == 2 and "+Z" or param2 == 0 and "-Z" or
      "unknown"
end
