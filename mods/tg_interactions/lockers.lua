-- handle all locker functionality

local modname = core.get_current_modname()

------------------------------------------------------------
-- creating events correlated to lockers
------------------------------------------------------------

local events = {}
for _,ename in ipairs({ -- event names
    "locker_opening_step",
    "locker_opening_failed",
    "locker_opened",
}) do
    -- name, automatic setup definition: add register function to `tg_interactions`
    -- return will be data of this event
    events[ename] = events_api.create(ename, {global = tg_interactions})
end
--]]



------------------------------------------------------------
-- locker check function mechanics
------------------------------------------------------------

-- list of functions that'll be ran before a locker is opened (has been clicked on)
-- used to verify whether or not player can open this locker (true for yes, false/nil for no)
local lockerfuncs = {}

-- have an ID
-- func will be ran with the same parameters as `player_held_success`
function tg_interactions.register_unique_locker_check(name, func)
    if type(name) ~= "string" then
        error(modname..".register_unique_locker_check: 'name' is not string, got type '"..type(name)..
          "'. Error with mod '"..core.get_current_modname().."'")
    end
    if type(func) ~= "function" then
        error(modname..".register_unique_locker_check: provided 'func' is not a function! Got type '"..
          type(func).."'. Error with mod '"..core.get_current_modname().."'")
    end
    -- check if in list
    if lockerfuncs[name] then
        error(modname..".register_unique_locker_check: a locker 'function_id' named '"..
          name.."' already exists! Error with mod '"..core.get_current_modname().."'")
    end
    -- add to list
    lockerfuncs[name] = func
end



------------------------------------------------------------
-- generating acceptable lockers
------------------------------------------------------------

-- stores each registered locker area to this
local areas = {}

-- permit registering areas for generation (requires locker nodes)
function tg_interactions.register_locker_area(def)
    -- do errors
    if type(def) ~= "table" then
        error(modname..".register_locker_area: provided 'def' is not a table, got type '"..
          type(def).."'. Error with mod '"..core.get_current_modname().."'")
    end
    -- needs function for starting
    if type(def.generate) ~= "function" then
        error(modname..".register_locker_area: 'generate' function non-existent or invalid type in def, got type '"..
          type(def.generate).."'. Error with mod '"..core.get_current_modname().."'")
    end
    -- require a table of positions
    if type(def.positions) ~= "table" then
        error(modname..".register_locker_area: 'positions' table non-existent or invalid type in def, got type '"..
          type(def.positions).."' Error with mod '"..core.get_current_modname().."'")
    end
    -- ensure positions are vectors
    local startp, endp = def.positions.start, def.positions.finish
    startp = not vector.check(startp) and (type(startp) == "table" and
      vector.new(startp.x or startp[1], startp.y or startp[2], startp.z or startp[3]))
      or startp
    endp = not vector.check(endp) and (type(endp) == "table" and
      vector.new(endp.x or endp[1], endp.y or endp[2], endp.z or endp[3])) or endp
    -- errors!
    if not startp then
        error(modname..".register_locker_area: positions.start vector malformed or not specified. Error with mod '"..
          core.get_current_modname().."'")
    end
    if not endp then
        error(modname..".register_locker_area: positions.finish vector malformed or not specified. Error with mod '"..
          core.get_current_modname().."'")
    end
    -- ensure fixed
    def.positions.start = startp
    def.positions.finish = endp
    -- get mod_origin
    def.mod_origin = core.get_current_modname()
    -- add to areas
    table.insert(areas, def)
end

-- clear decimal from vector
local function CDFV(vect)
    vect = core.pos_to_string(vect) -- turn into string
    -- remove any decimal places (e.g. 5.49985198 --> 5)
    -- %. looks for the dot, %d+ looks for a number and any more numbers after that
    vect = vect:gsub("%.%d+","")
    -- convert back into vector for usage
    return vector.from_string(vect)
end

-- number from 0 to 3
local function get_facing(param2)
    return param2 == 3 and "+X" or param2 == 1 and "-X" or
      param2 == 2 and "+Z" or param2 == 0 and "-Z" or
      "unknown"
end

-- Register Timed From WorldCreate error text
local RTFWC_errtext = modname.." lockers: had an issue with generating an area."

-- run functionality for locker loot areas
tg_time.register_timed_from_worldcreate(4, function(time)
    for _,area in ipairs(areas) do
        local poss = area.positions
        -- looks for "tg_nodes:locker" between start and end, grouped `true` returns list
        -- of positions associated to node name
        local nodesraw = core.find_nodes_in_area(poss.start, poss.finish,
          {"tg_nodes:locker"}, true)
        -- ensure always a table
        nodesraw = nodesraw["tg_nodes:locker"] or {}
        -- get and check length of found nodes
        local len = #nodesraw
        if len == 0 then
            error(RTFWC_errtext.." Could not find any 'tg_nodes:locker' nodes in area between ( "..
              core.pos_to_string(poss.start).." - "..core.pos_to_string(poss.finish)..
              " ). You should check if there are locker nodes in this area before registering a locker area"..
              ". Error with mod '"..area.mod_origin.."'")
        end
        -- refined nodes
        local nodes = {}
        -- add additional information to each detected node
        for ind,pos in ipairs(nodesraw) do -- index, position
            local node = core.get_node(pos)
            -- shouldn't be unknown, but we'll add it anyways
            local facing = get_facing(node.param2)
            -- entity position (for indicator)
            -- ensure infront of locker (use param2)
            local epos = pos:add(
              vector.new(
                -- X
                facing=="+X" and 0.6 or facing=="-X" and -0.6 or 0,
                -- Y
                1,
                -- Z
                facing=="+Z" and 0.6 or facing=="-Z" and -0.6 or 0
              )
            )
            -- check for conflicts
            -- remove decimals due to annoying rounding
            local checkpos = CDFV(epos)
            local conflict = core.get_node(checkpos)
            checkpos.y = checkpos.y - 1 -- go down 1 first
            -- ok, bottom area is ALRIGHT (not a locker)
            if conflict.name ~= "tg_nodes:locker" then
                -- check above now
                checkpos.y = checkpos.y + 1
                conflict = core.get_node(epos)
                conflict = core.registered_nodes[conflict.name] or {name="ignore"}
                -- can place an entity here!
                if conflict.drawtype == "airlike" or conflict.name == "ignore" then
                    -- add to refined
                    table.insert(nodes, {pos = pos, node = node, epos = epos, face=facing})
                end
            end
        end
        -- check length again after filtering
        len = #nodes
        if len == 0 then
            error(RTFWC_errtext.." Could not find valid lockers in area between ( "..
              core.pos_to_string(poss.start).." - "..core.pos_to_string(poss.finish)..
              " ). Please check that the node's param2 is correctly rotated and that there is not a non-air "..
              "node blocking, so that entity indicators can be appropriately placed. "..
              "Error with mod '"..area.mod_origin.."'")
        end
        -- run generate function
        -- table of positions, "bounds", total number of found lockers
        area.generate(nodes, area.positions, len)
    end
end)



------------------------------------------------------------
-- misc locker functions
------------------------------------------------------------

--- generates the locker indicator entities for a list of provided nodes
--- @param lockerlist table MUST BE the "nodes" parameter of a locker area's 'generate()' return
--- returns a table of entities, of which will have `node` (in memory) associated to their respective node
function tg_interactions.generate_locker_interactables_for(lockerlist)
    local ents = {} -- entities
    -- iterate over list
    for ind, data in ipairs(lockerlist) do
        -- gets object, but let's get the entity!
        local ent = core.add_entity(data.epos, "tg_interactions:locker_interactable")
        ent = ent and ent:get_luaentity()
        -- add locker node info and add to list
        if ent then
            ent:remember("node", data)
            table.insert(ents, ent)
        end
    end
    -- return list of entities, some indexes can be `false` if failed to generate
    return ents
end



------------------------------------------------------------
-- actual locker entities and their functionality
------------------------------------------------------------

local shapes = tg_nodes.shapes

local function locker_stop_sound(self)
    -- uses saved id to stop sound, remove
    local id = self._sound_locker_open
    if id then
        core.sound_fade(id, 5, 0)
        self._sound_locker_open = nil
    end
end

-- when locker is clicked on
local function locker_interact(self, clicker)
    local opening = self._holding_data
    -- if currently opening, then return!
    if opening then return end
    -- check function
    local check = self:recall("check")
    local checkfunc = lockerfuncs[check]
    if checkfunc then
        check = checkfunc(self, clicker)
        if not check then return end -- can't open
    end
    -- create new opening
    -- holder (player), total time (0sec)
    self._holding_data = {holder = clicker, ttime = 0}
    self._sound_locker_open = core.sound_play("tg_interactions_locker",
    {
        obj = self.object,
        gain = 2,
        pitch = math.random(85, 110)/100
    })

    if clicker:get_player_control().sneak == true then
      if tg_main.dev_mode == true then
        self.object:remove()
      end
    end
end

tg_interactions.register_interactable("locker_interactable", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.centerd_box,
{
    _not_loggable = true,
    _popup_msg = "[ search locker ]",
    _holding_functionality = 1, -- quicker to type than true!
    _holding_time = 1.5, -- in seconds
    -- memory functions
    -- store data into memory
    remember = function(self, name, value)
        self.memory[name] = value
        return self.memory[name]
    end,
    -- retrieve data
    recall = function(self, name)
        return self.memory[name]
    end,
    -- held interactable functions
    player_held_success = function(self, clicker, holddata)
        locker_stop_sound(self)
        --[[ local playing_sound = ]]
        core.sound_play({ name = "tg_paper_footstep" }, {
            gain = 1,   -- default
            --fade = 100.0, -- default
            pitch = 1.8,  -- 1.0, -- default
        })
        -- run event
        -- opener, ent, holddata, entity memory
        events.locker_opened(clicker, self, holddata, self.memory)
        if tg_main.dev_mode == false then
            self.object:remove()
            --else
            -- core.log("after first interaction this will be removed in normal gameplay.")
        end
    end,
    -- when player stops opening the locker
    player_held_failed = function(self, clicker, holddata, ttime, rqtime, reason)
        events.locker_opening_failed(clicker, self, holddata, ttime, rqtime, reason)
        locker_stop_sound(self)
    end,
    -- step functionality
    -- rqtime is "required time" - what time is needed to be reached for success
    player_held_step = function(self, clicker, holddata, dtime, elapsed, rqtime)
        -- opener, ent(ity), hold data, required time, delta time
        events.locker_opening_step(clicker, self, holddata, elapsed, rqtime, dtime)
    end,
    -- interacting
    on_rightclick = locker_interact,
    on_punch = locker_interact,
    -- loading
    on_activate = function(self, staticdata, dtime_s)
        self.memory = {} -- store to a "memory"
        if staticdata == "" then return end -- nothing
        local data = core.deserialize(staticdata)
        -- load into memory
        for name, value in pairs(data) do
            name = name == "locker_function_id" and "id" or
              name == "locker_node" and "node" or name
            self.memory[name] = value
        end
        -- check if we don't have a `node` in memory
        -- compatibility with old locker indicators
        core.after(1.5, function()
            if self:recall("node") then return end -- already got one
            local pos = self.object and self.object:get_pos()
            if not pos then return end -- huh how
            local npos = pos:new() -- node pos, copy object pos for checking
            npos.y = npos.y - 1 -- because pos:subtract(vector.new(0,-1,0)) made it GO UP INSTEAD!!!! ARRRHAUAURHG
            -- declare
            local node
            -- look around to find our damn LOCKER
            for _,addby in ipairs({
                -- checking 4 directions, too lazy to specify a stoopid ungrateful vector
                {x=1}, {x=-1}, {z=1}, {z=-1}
            }) do
                local nnpos = npos:new() -- new node pos
                -- lookie lookie here
                if addby.x then
                    nnpos.x = nnpos.x + addby.x
                end
                -- lookie lookie there
                if addby.z then
                    nnpos.z = nnpos.z + addby.z
                end
                node = core.get_node(nnpos)
                -- OH MY GOD WE FOUND IT
                if node.name == "tg_nodes:locker" then
                    npos = nnpos -- yeah we're FIXING THIS
                    break
                end
            end
            -- oh hell nah we gave you so many chances, GOODBYE!
            if node.name ~= "tg_nodes:locker" then
                return self.object:remove()
            end
            -- I'm not even going to try to calculate the proper face direction (if param2 is wrong)
            self:remember("node", {pos = npos, node = node, epos = pos, face = get_facing(node.param2)})
        end)
    end,
    -- saving
    get_staticdata = function(self)
        return core.serialize(self.memory)
    end,
})

-- functionality for empty locker
events.locker_opened.register(function(opener, ent, holddata, memory)
    if memory.id then return end
    -- no special function, assume empty
    tg_dialog.dialog(opener,"..this locker is empty",true)
end)



------------------------------------------------------------
-- generate specific locker areas
------------------------------------------------------------

-- starting locker room
tg_interactions.register_locker_area({
    positions = {
        start = {-8, 2, -18},
        finish = {9, 2, -11}
    },
    -- list of lockers (with pos, node, and entity pos), bounds, total lockers found
    generate = function(nodes, bounds, total)
        local togen = {} -- table of positions to generate locker entity indicators at
        -- to generate amount
        local togenamt = math.ceil(total * 0.33) -- need to generate a third of the found
        -- keep going until we've got it all done
        while togenamt ~= 0 do
            local rind = math.random(1, #nodes) -- random index
            -- add to the new hat
            table.insert(togen, nodes[rind])
            -- and remove from the old hat
            table.remove(nodes, rind)
            togenamt = togenamt - 1 -- lower by 1
        end
        -- finished getting randomized nodes
        -- generate locker interactables
        local ents = tg_interactions.generate_locker_interactables_for(togen)
        -- figure out which one to be special
        local suit = ents[math.random(1, #ents)]
        -- ensure we have the right function id
        suit:remember("id", "radiation_suit")
    end
})
-- radiation suit functionality
events.locker_opened.register(function(opener, self, holddata, memory)
    if memory.id ~= "radiation_suit" then return end
    tg_dialog.dialog(opener,"hmm, a radiation suit. i should slip this on.",true)
    core.after(3, function()
        tg_interactions.addToPlayerCollection(opener:get_player_name(), "tg_interactions:radiation_suit")
        tg_cut_scenes.run(opener, { [[slipping into suit]] })
    end)
    if tg_main.dev_mode == true then
        core.log("some zipper sounds should also be added to this. maybe even some skin slapping, because why not.")
    end
end)



------------------------------------------------------------
-- compatibility
------------------------------------------------------------

-- replace these with the new system
core.register_entity("tg_interactions:locker_empty", {
    on_activate = function(self, staticdata, dtime_s)
        local obj = self.object
        if obj then
            core.add_entity(obj:get_pos(), "tg_interactions:locker_interactable")
        end
        obj:remove()
    end
})
-- ditto
core.register_entity("tg_interactions:locker_suit", {
    on_activate = function(self, staticdata, dtime_s)
        local obj = self.object
        if obj then
            local unique = core.add_entity(obj:get_pos(), "tg_interactions:locker_interactable")
            unique = unique and unique:get_luaentity()
            if unique then
                unique:remember("id", "radiation_suit")
            end
        end
        obj:remove()
    end
})
