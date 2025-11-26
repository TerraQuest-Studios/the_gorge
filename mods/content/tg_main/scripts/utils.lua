---@class vector
---@field x number
---@field y number
---@field z number

---comment
---@param pos1 vector
---@param pos2 vector
---@return number
function tg_main.distance(pos1,pos2)
  local dx = pos2.x - pos1.x
  local dy = pos2.y - pos1.y
  local dz = pos2.z - pos1.z
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function tg_main.calculateMidpoint(pos1, pos2)
    local midpoint = {
        x = (pos1.x + pos2.x) / 2,
        y = pos1.y+0.5,
        z = (pos1.z + pos2.z) / 2
    }
    return midpoint
end
