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
