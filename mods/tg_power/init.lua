tg_power = {}

local modstor = core.get_mod_storage()

-- does luanti have a little helper/ converter like this?
local stringtoboolean={ ["true"]=true, ["false"]=false }

tg_power.power = stringtoboolean[modstor:get_string("tg_power_power")] or false -- should be default offr
tg_power.power_core = stringtoboolean[modstor:get_string("tg_power_power")] or false -- should be default offr

-- can;t have power without a power_source

function tg_power.getPower()
  return tg_power.power
end

---comment
---@param powered boolean
function tg_power.setPowerCore(powered)
  if tg_power.power_core == powered then
    return
  end
  if powered == true then
    tg_power.power_core = true
  else
    tg_power.power_core = false
    tg_power.power = false
  end
  modstor:set_string("tg_power_power",tostring(tg_power.power))
end

function tg_power.togglePower()
  if tg_power.power_core == false then
    core.chat_send_all("needs power core")
  else
    tg_power.power = not tg_power.power
  end
  -- core.log("power toggled")
  modstor:set_string("tg_power_power",tostring(tg_power.power))
end

-- what was this for?
-- core.register_globalstep(function(dtime)
-- end)
