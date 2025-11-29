local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

tg_main = {}

-- Either "flat" or "singlenode".
tg_main.mg_name = core.get_mapgen_setting("mg_name") or "singlenode"
-- Enter dev mode if mapgen "flat" or creative setting is `true`.
-- This stops normal gameplay functions from running.
tg_main.dev_mode = core.is_creative_enabled() -- or (tg_main.mg_name == "flat")
-- Skip intro if on mapgen "flat".
tg_main.skip_intro = false --(tg_main.mg_name == "flat")

dofile(mod_path .. "/scripts" .. "/math.lua")
dofile(mod_path .. "/scripts" .. "/debug.lua")
dofile(mod_path .. "/scripts" .. "/utils.lua")

------
-- all the objects that should be in world
------


-- yes this is not the best way to go about it, but it is the quickest
local all_objects = {
  {
    name = "tg_interactions:locker_suit",
    pos = {
      x = 4.0139999389648438,
      y = 3,
      z = -15.535000801086426,
    }
  },
  {
    name = "tg_interactions:locker_empty",
    pos = {
      x = 7.0309996604919434,
      y = 3,
      z = -17.200000762939453,
    }
  },
  {
    name = "tg_interactions:locker_empty",
    pos = {
      x = 5.5169997215271,
      y = 3,
      z = -13.955999374389648,
    }
  },
  {
    name = "tg_interactions:locker_empty",
    pos = {
      x = 2.9938998222351074,
      y = 3,
      z = -11.566999435424805,
    }
  },
  {
    name = "tg_interactions:draggable_chair",
    pos = {
      x = 1.6128000020980835,
      y = 8,
      z = -33.389301300048828,
    }
  },
  {
    name = "tg_interactions:locker_empty",
    pos = {
      x = 0.015000000596046448,
      y = 3,
      z = -17.503000259399414,
    }
  },
  {
    name = "tg_interactions:locker_empty",
    pos = {
      x = 1.0369000434875488,
      y = 3,
      z = -13.399999618530273,
    }
  },
  {
    name = "tg_interactions:locker_empty",
    pos = {
      x = -7.4379997253417969,
      y = 3,
      z = -14.085000991821289,
    }
  },
  {
    name = "tg_interactions:tape",
    pos = {
      x = 1.9549999237060547,
      y = 8.8280000686645508,
      z = -31.96099853515625,
    }
  },
  {
    name = "tg_interactions:draggable_chair",
    pos = {
      x = -4.3278999328613281,
      y = 3,
      z = -31.876699447631836,
    }
  },
  {
    name = "tg_interactions:draggable_chair",
    pos = {
      x = -1.3517999649047852,
      y = 8,
      z = -33.845699310302734,
    }
  },
  {
    name = "tg_interactions:draggable_chair",
    pos = {
      x = -2.6198999881744385,
      y = 3,
      z = -32.778499603271484,
    }
  },
  {
    name = "tg_interactions:locker_empty",
    pos = {
      x = -4.9889998435974121,
      y = 3,
      z = -11.50100040435791,
    }
  },
  {
    name = "tg_interactions:locker_empty",
    pos = {
      x = -7.4769997596740723,
      y = 3,
      z = -15.991999626159668,
    }
  },
  {
    name = "tg_interactions:locker_empty",
    pos = {
      x = -1.0449999570846558,
      y = 3,
      z = -13.496000289916992,
    }
  },
  {
    name = "tg_interactions:draggable_pipes",
    pos = {
      x = -15.2,
      y = 3,
      z = -24.200799942016602,
    }
  },
  {
    name = "tg_interactions:power_switch",
    pos = {
      x = -12.55,
      y = 3,
      z = -43.017002105712891,
    }
  },
  {
    name = "tg_interactions:random_note",
    pos = {
      x = -12.982000350952148,
      y = 6.45,
      z = -24.991001129150391,
    }
  },
  {
    name = "tg_interactions:draggable_chair",
    pos = {
      x = -15.284399032592773,
      y = 2,
      z = -26.557300567626953,
    }
  },
  {
    name = "tg_interactions:draggable_power_core",
    pos = {
      x = -15.004300117492676,
      y = 2,
      z = -43.112098693847656,
    }
  },
  {
    name = "tg_interactions:draggable_chair",
    pos = {
      x = -8.6951999664306641,
      y = 2,
      z = -35.984298706054688,
    }
  },
  {
    name = "tg_interactions:draggable_chair",
    pos = {
      x = -8.6435995101928711,
      y = 2,
      z = -34.826400756835938,
    }
  },
  {
    name = "tg_interactions:draggable_chair",
    pos = {
      x = -17.130901336669922,
      y = 2,
      z = -24.030200958251953,
    }
  },
  {
    name = "tg_interactions:draggable_chair",
    pos = {
      x = -7.9124999046325684,
      y = 2,
      z = -36.799900054931641,
    }
  },
}

core.register_on_newplayer(function(player)
  -- [ ] TODO: should also take in to account the object's rotations

  core.after(4, function()
    for index, value in ipairs(all_objects) do
      core.add_entity(value.pos, value.name)
    end

    --log the entities
    -- local entites = core.get_objects_inside_radius(player:get_pos(), 200)
    -- local jsoned = {}
    -- for index, value in ipairs(entites) do
    -- 	if not value:is_player() then
    -- 		-- debug("we have found a player")
    -- 		-- local player_name = value:get_player_name()
    -- 		local obj_name = value.name
    -- 		local pos = value:get_pos()
    -- 		local json = { object = dump(value), pos = dump(pos) }
    -- 		table.insert(jsoned, json)
    -- 		core.log(string.format("[ %s ] pos:%s", dump(value), dump(pos)))
    -- 	end
    -- end
    -- local file, err = io.open("all_objects.json", "w")
    -- if err then return 0 end
    -- if file ~= nil then
    -- 	file:write(dump(jsoned))
    -- 	file:close()
    -- end
  end)
end)

-- core.register_chatcommand(mod_name .. ":" .. "resetobjects", {
core.register_chatcommand("resetobjects", {
  params = "resetobjects <privilege>",
  description = "reset's all objects",
  privs = { privs = true }, -- Require the "privs" privilege to run
  func = function(name, param)
    -- core.registered_chatcommands["clearobjects"].func()
    -- core.registered_chatcommands["clearobjects"].func("full")
    -- local what = core.registered_chatcommands["clearobjects"].func()
    -- core.log("so we got: "..dump(what))
    -- core.log(dump(core.registered_chatcommands["kick"]))
    core.clear_objects({mode = "full"})
    for index, value in ipairs(all_objects) do
    	core.add_entity(value.pos, value.name)
    end
    core.log("objects have been reset")
  end,
})

-- core.register_chatcommand(mod_name .. ":" .. "resetobjects", {
core.register_chatcommand("basepower", {
  params = "resetobjects <privilege>",
  description = "reset's all objects",
  privs = { privs = true }, -- Require the "privs" privilege to run
  func = function(name, param)
    tg_power.togglePower()
  end,
})
