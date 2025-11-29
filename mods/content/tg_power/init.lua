local mod_name = core.get_current_modname()
local S = core.get_translator(mod_name)

tg_power = {}

local power = true -- should be default off
local power_core = false
tg_power.power = power

-- can;t have power without a power_source

---comment
---@param powered boolean
function tg_power.power_core(powered)
  if powered == true then
    power_core = true
  else
    power_core = false
    power = false
  end
end

function tg_power.togglePower()
  if power_core == false then
    core.chat_send_all("needs power core")
  else
    power = not power
  end
end

function tg_power.getPower()
  return power
end

-- what was this for?
-- core.register_globalstep(function(dtime)
-- end)
