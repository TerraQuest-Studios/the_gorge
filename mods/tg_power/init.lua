tg_power = {}

tg_power.power = false -- should be default offr
tg_power.power_core = false -- should be default offr

-- can;t have power without a power_source

---comment
---@param powered boolean
function tg_power.setPowerCore(powered)
  if powered == true then
    tg_power.power_core = true
  else
    tg_power.power_core = false
    tg_power.power = false
  end
end

function tg_power.togglePower()
  if tg_power.hasPowerCore == false then
    core.chat_send_all("needs power core")
  else
    tg_power.power = not tg_power.power
  end
end

function tg_power.getPower()
  return tg_power.power
end

-- what was this for?
-- core.register_globalstep(function(dtime)
-- end)
