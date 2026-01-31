local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

------
-- all the objects that should be in world
------


-- yes this is not the best way to go about it, but it is the quickest
local all_objects = {
  {
		name = 'tg_interactions:draggable_pipes',
		pos = {
      x = -15.2,
      y = 3,
      z = -24.2,
    }
	},
	{
		name = 'tg_interactions:draggable_chair',
		pos = {
      x = -17.13,
      y = 2,
      z = -24.03,
    },
    rot = {
        y = 1.5707963267948966
    }
	},
	{
		name = 'tg_interactions:draggable_chair',
		pos = {
      x = -1.35,
      y = 8,
      z = -33.85,
    }
	},
	{
		name = 'tg_interactions:draggable_chair',
		pos = {
      x = 1.47,
      y = 8,
      z = -33.11,
    },
		rot = {
      y = -3.1415926535897931
    }
	},
	{
		name = 'tg_interactions:draggable_chair',
		pos = {
      x = -2.28,
      y = 3,
      z = -32.32,
    }
	},
	{
		name = 'tg_interactions:draggable_chair',
		pos = {
      x = -15.28,
      y = 2,
      z = -26.56,
    },
    rot = {
      y = -3.1415926535897931
    }
	},
	{
		name = 'tg_interactions:draggable_chair',
		pos = {
      x = -8.7,
      y = 2,
      z = -35.98,
    }
	},
	{
		name = 'tg_interactions:draggable_chair',
		pos = {
      x = -7.91,
      y = 2,
      z = -36.8,
    }
	},
	{
		name = 'tg_interactions:draggable_chair',
		pos = {
      x = -8.64,
      y = 2,
      z = -34.83,
    }
	},
	{
		name = 'tg_interactions:draggable_chair',
		pos = {
      x = -4.31,
      y = 3,
      z = -31.71,
    }
	},
	{
		name = 'tg_interactions:tape',
		pos = {
      x = 1.95,
      y = 8.83,
      z = -31.96,
    }
	},
	{
		name = 'tg_interactions:draggable_power_core',
		pos = {
      x = 8.64,
      y = 2,
      z = -46.17,
    }
	},
	{
		name = 'tg_interactions:random_note',
		pos = {
      x = -12.98,
      y = 6.45,
      z = -24.99,
    }
	},
	{
		name = 'tg_interactions:power_gen',
		pos = {
      x = -15.07,
      y = 3.25,
      z = -45.2,
    }
	},
	{
		name = 'tg_interactions:power_switch',
		pos = {
      x = -12.55,
      y = 3,
      z = -43.02,
    }
	}
}

-- spawn objects
local function dospawn()
    -- iterate over list
    for _, data in ipairs(all_objects) do
        local obj = core.add_entity(data.pos, data.name)
        local ent -- only get this if we're going to do memory mechanics
        -- additional stuff if successful
        if obj then
            -- rotation
            if data.rot then
                -- create vector'd rotation
                local rot = vector.new(data.rot.x or 0, data.rot.y or 0, data.rot.z or 0)
                obj:set_rotation(rot)
            end
            -- load in memory
            if data.memory then
                ent = ent or obj:get_luaentity()
                -- set the memory
                ent.memory = data.memory
            end
        end
    end
end

-- load list of objects
tg_time.register_timed_from_worldcreate(4, function(time)
    -- [ ] TODO: should also take in to account the object's rotations
    dospawn()
    -- local file, err = io.open("all_objects.json", "w")
    -- if err then return 0 end
    -- if file ~= nil then
    -- 	file:write(dump(jsoned))
    -- 	file:close()
    -- end
end)

-- reset objects (remove old and add new)
core.register_chatcommand("resetobjects", {
    params = "resetobjects",
    description = "resets all objects",
    privs = { privs = true }, -- Require the "privs" privilege to run
    func = function(name, param)
        core.log("resetting objects (deleting old objects)")
        core.clear_objects({ mode = "full" })
        core.log("respawning objects")
        dospawn()
        core.log("objects have been reset")
    end,
})

local emptyvec = vector.new(0,0,0) -- used for checking

-- log objects to chat / debug.txt
core.register_chatcommand("logobjects", {
    params = "logobjects [savingforfile]",
    description = table.concat({"logs position and rotation of every object (within 200 nodes of player), as well as",
      "entity's memory if found. If 'savingforfile' is specified ( 'true' ), then will save to a format that can ",
      "be copied from debug text and pasted into tg_main/objects.lua's 'all_objects' table"}),
    privs = { privs = true }, -- Require the "privs" privilege to run
    func = function(name, param)
        local plr = core.get_player_by_name(name)
        if not plr then return end -- huh how?
        -- lowercase!
        param = param:lower()
        param = param:split(" ") or {} -- split param string up
        -- saveforfile
        param[1] = (param[1] == "y" or param[1] == "true") and true or false

        core.log("logging entities")
        -- create 'count' for logging purposes
        local count = 0
        -- get entities
        local raw = core.get_objects_inside_radius(plr:get_pos(), 200)
        -- filter out players and create indexes by name
        -- save `get_luaentity` result as well
        local reformed = {}
        for _,obj in ipairs(raw) do
            if not core.is_player(obj) then
                local ent = obj:get_luaentity()
                -- need entity for name
                if ent then
                    local name = ent.name
                    -- create table to add ourselves to
                    if not reformed[name] then
                        reformed[name] = {}
                    end
                    -- add ourselves to that table with extras
                    table.insert(reformed[name], {obj = obj, ent = obj:get_luaentity()})
                    -- increase count
                    count = count + 1
                end
            end
        end
        core.log("got "..count.." entities!")
        -- now to print out
        local allprint = param[1] and {}
        for cname, cdata in pairs(reformed) do -- category name, category data
            local clen = #cdata -- category length
            for ind, data in ipairs(cdata) do
                -- don't get in our way!
                if not param[1] then
                    core.log("printing "..ind.."/"..clen.." of "..cname)
                end
                -- specify variables for easier typing
                local obj, ent = data.obj, data.ent
                -- if not supposed to be logged (if saving to file), then don't log!
                if not (param[1] and ent._no_log) then
                    -- rounds to the first 2 decimal places
                    local pos = tg_main.vector_round(obj:get_pos())
                    -- rounds to the first 6 decimal places (don't round rotation)
                    --local rot = tg_main.vector_round(obj:get_rotation(), 6)
                    -- if param[1], then print into a format that can be copied and pasted
                    local result = param[1] and {"\t{\n", "\t\tname = '", cname,"',\n\t\tpos = ", dump(pos)} or
                    -- doing regular print
                    {dump(obj), " | pos:", core.pos_to_string(pos)}
                    -- jot rotation down if not empty
                    if not emptyvec:equals(rot) then
                        if param[1] then
                            result[#result + 1] = ",\n\t\trot = "
                            result[#result + 1] = dump(rot)
                        -- regular chill print
                        else
                            result[#result + 1] = " | rot:"
                            result[#result + 1] = core.pos_to_string(rot)
                        end
                    end
                    -- jot memory if it exists and has stuff in it
                    if ent.memory and next(ent.memory) then
                        if param[1] then
                            result[#result + 1] = ",\n\t\tmemory = "
                            result[#result + 1] = dump(ent.memory)
                        else
                            result[#result + 1] = " | memory:{ "
                            for key, val in pairs(ent.memory) do
                                result[#result + 1] = tostring(key)
                                result[#result + 1] = ": "
                                result[#result + 1] = dump(val)
                                result[#result + 1] = ", "
                            end
                            -- close
                            result[#result + 1] = " }"
                        end
                    end
                    -- close
                    if param[1] then
                        result[#result + 1] = "\n\t},\n"
                    end
                    -- convert into string
                    result = table.concat(result)
                    -- store to a big table to print
                    if param[1] then
                        allprint[#allprint + 1] = result
                    -- and print!
                    else
                        core.log(result)
                    end
                end
            end
        end
        -- if param[1] then do a BIG print
        if param[1] then
            core.log(table.concat(allprint))
        end
        core.log("successfully logged all objects")
    end,
})
