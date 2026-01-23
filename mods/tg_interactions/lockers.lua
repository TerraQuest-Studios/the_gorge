-- handle all locker functionality

------------------------------------------------------------
-- `function_id` and generating acceptable lockers
------------------------------------------------------------

-- list of functions that'll be ran when a locker has a corresponding "function_id" on successful activation
local interactions = {}

-- have an ID
-- func will be ran with the same parameters as `player_held_success`
function tg_interactions.register_unique_locker_interaction(name, func)
    if type(name) ~= "string" then return end -- error
    if type(func) ~= "function" then return end -- error
    -- check if in list
    if interactions[name] then
        error("tg_interactions.register_unique_interaction: a locker 'function_id' named '"..
          name.."' already exists! Error with mod '"..core.get_current_modname().."'")
    end
    -- add to list
    interactions[name] = func
end

-- stores each registered locker area to this
local areas = {}

-- permit registering areas for generation (requires locker nodes)
function tg_interactions.register_locker_area(def)
    -- do errors
    if type(def) ~= "table" then return end
    -- needs function for starting
    if type(def.generate) ~= "function" then return end
    -- require a table of positions
    if type(def.positions) ~= "table" then return end
    -- ensure positions are vectors
    local startp, endp = def.positions.start, def.positions.finish
    startp = not vector.check(startp) and (type(startp) == "table" and
      vector.new(startp.x or startp[1], startp.y or startp[2], startp.z or startp[3]))
      or startp
    endp = not vector.check(endp) and (type(endp) == "table" and
      vector.new(endp.x or endp[1], endp.y or endp[2], endp.z or endp[3])) or endp
    if not (startp and endp) then return end -- oops!
    -- ensure fixed
    def.positions.start = startp
    def.positions.finish = endp
    -- get mod_origin
    def.mod_origin = core.get_current_modname()
    -- add to areas
    table.insert(areas, def)
end

local errtext = "tg_interacts lockers: had an issue with generating an area."

-- run functionality for locker loot areas
tg_time.register_timed_from_worldcreate(4, function(time)
    core.log("GEN LOCKERS "..time)
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
            error(errtext.." Could not find any 'tg_nodes:locker' nodes in area between ( "..
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
            local facing = (
                node.param2 == 3 and "+X" or node.param2 == 1 and "-X" or
                node.param2 == 2 and "+Z" or node.param2 == 0 and "-Z" or "unknown"
            )
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
            -- create a checkpos due to annoying rounding
            local checkpos = epos:add(
              vector.new(
                -- X
                facing=="+X" and 0.4 or facing=="-X" and -0.4 or 0,
                -- Y (subtract 1 from entity)
                -1,
                -- Z
                facing=="+Z" and 0.4 or facing=="-Z" and -0.4 or 0
              )
            )
            local conflict = core.get_node(checkpos)
            -- ok, bottom area is ALRIGHT (not a locker)
            if conflict.name ~= "tg_nodes:locker" then
                -- check above
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
            error(errtext.." Could not find valid lockers in area between ( "..
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
--- returns a table of entities, of which will have `locker_node` associated to their respective node
function tg_interactions.generate_locker_interactables_for(lockerlist)
    local ents = {} -- entities
    -- iterate over list
    for ind, data in ipairs(lockerlist) do
        -- gets object, but let's get the entity!
        local ent = core.add_entity(data.epos, "tg_interactions:locker_interactable")
        ent = ent and ent:get_luaentity()
        -- add locker node info and add to list
        if ent then
            ent.locker_node = data
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
    -- create new opening
    -- holder (player), total time (0sec)
    self._holding_data = {holder = clicker, ttime = 0}
    self._sound_locker_open = core.sound_play("tg_interactions_locker",
    {
        obj = self.object,
        gain = 2,
        pitch = math.random(85, 110)/100
    })
end

tg_interactions.register_interactable("locker_interactable", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.centerd_box,
{
    _popup_msg = "[ search locker ]",
    _holding_functionality = 1, -- quicker to type than true!
    _holding_time = 1.5, -- in seconds
    player_held_success = function(self, clicker, holddata)
        locker_stop_sound(self)
        --[[ local playing_sound = ]]
        core.sound_play({ name = "tg_paper_footstep" }, {
            gain = 1,   -- default
            --fade = 100.0, -- default
            pitch = 1.8,  -- 1.0, -- default
        })
        -- run provided function if exists
        local specialfunc = interactions[self.locker_function_id]
        if specialfunc then
            return specialfunc(self, clicker, holddata)
        end
        -- no special function, assume empty
        tg_dialog.dialog(clicker,"..this locker is empty",true)
        if tg_main.dev_mode == false then
            self.object:remove()
            --else
            -- core.log("after first interaction this will be removed in normal gameplay.")
        end
    end,
    -- when player stops opening the locker
    player_held_failed = function(self, clicker, holddata, ttime, reason)
        locker_stop_sound(self)
    end,
    -- interacting
    on_rightclick = locker_interact,
    on_punch = locker_interact,
    -- loading
    on_activate = function(self, staticdata, dtime_s)
        if staticdata == "" then return end -- nothing
        local data = core.deserialize(staticdata)
        -- load into self
        for name, value in pairs(data) do
            self[name] = value
        end
    end,
    -- saving
    get_staticdata = function(self)
        return core.serialize({
            locker_function_id = self.locker_function_id,
            locker_node = self.locker_node
        })
    end,
})



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
        suit.locker_function_id = "radiation_suit"
    end
})
tg_interactions.register_unique_locker_interaction("radiation_suit",
function(self, clicker, holddata)
    tg_dialog.dialog(clicker,"hmm, a radiation suit. i should slip this on.",true)
    core.after(3, function()
        tg_cut_scenes.run(clicker, { [[slipping into suit]] })
    end)
    if tg_main.dev_mode == false then
        core.log("some zipper sounds should also be added to this. maybe even some skin slapping, because why not.")
        self.object:remove()
        --else
        -- core.log("after first interaction this will be removed in normal gameplay.")
    end
end)