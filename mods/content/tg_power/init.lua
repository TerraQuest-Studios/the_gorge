local mod_name = core.get_current_modname()
local S = core.get_translator(mod_name)

tg_power = {}

local power = false -- should be default off
tg_power.power = power

-- can;t have power without a power_source


function tg_power.togglePower()
  power = not power
end

function tg_power.getPower()
  return power
end


-- what was this for?
-- core.register_globalstep(function(dtime)
-- end)
