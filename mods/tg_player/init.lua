local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

tg_player = {}

tg_player.eye_height = 1.625
tg_player.eye_height_sneak = 1.3
tg_player.eye_height_prone = 0.5

dofile(mod_path .. "/scripts" .. "/helpers.lua")

tg_player._pl = {}
---Gets the transient player information table
---@param player table
---@return table|nil
function tg_player.pi(player)
	if not core.is_player(player) then return end
	local pi = tg_player._pl[player]
	if not pi then
		pi = {
			tasks = {},
		}
		tg_player._pl[player] = pi
	end
	return pi
end

core.register_on_joinplayer(function(player, last_login)
	player:set_sky({
		base_color = "#777",
		-- base_color = "#681c0e",
		type = "plain",
		clouds = false,
	})
	player:set_camera({
		mode = "first",
	})
	-- if tg_main.dev_mode == true then
	-- else
	-- end
	local props = player:get_properties()
	props.textures = { "player.png" }
	player:set_properties(props)
	player:set_lighting({
		shadows = { intensity = 0.33 },
		volumetric_light = { strength = 0.45 },
		exposure = {
			luminance_min = -3.5,
			luminance_max = -2.5,
			exposure_correction = 0.35,
			speed_dark_bright = 1500,
			speed_bright_dark = 700,
		},
		boom = {
			intensity = 0.05,
			radius = 0.1,
		},
		saturation = 1.0,
	})
end)

-- create events for player handling
local events = {}
for _, ename in ipairs({ -- for _, event name
    -- basic
    "join",
    "leave",
    -- on step
    "step",
    -- player pressing keys
    "keypress_start",
    "keypress_step", -- step is ran on start as well, however will have a time of 0
    "keypress_end",
    -- wielded item (ran if item name changed or index changed)
    "wieldchange",
    -- individual stats
    -- player's pos changed
    "change_pos",
    -- player's lookdir changed
    "change_lookdir",
    -- either player's eye pos or lookdir changed
    "change_eyepos_or_lookdir",
}) do
    -- name, automatic setup definition: add register function to `tg_interactions`
    -- return will be data of this event
    events[ename] = events_api.create(ename, {global = tg_player})
end


-- array of data of players
local pdatas = {}
-- create data
core.register_on_joinplayer(function(plr)
    local pdata = {
        obj = plr,
        name = plr:get_player_name(),
        time = 0, -- total time
        held_keys = {} -- data on each key pressed (time)
    }
    pdatas[#pdatas + 1] = pdata
    -- event
    events.join(plr, pdata)
end)
-- remove data (index required for actually removing the data
local function on_leave(plr, pdata, index)
    -- event
    events.leave(plr, pdata)
    -- destroy
    table.remove(pdatas, index)
end
-- player leaving
core.register_on_leaveplayer(function(plr)
    for ind,pdata in ipairs(pdatas) do
        -- found! remove
        if pdata.obj == plr then
            return on_leave(plr, pdata, ind)
        end
    end
end)
-- server shutdown
core.register_on_shutdown(function()
    -- destroy ALL player datas
    for ind,pdata in ipairs(pdatas) do
        on_leave(pdata.obj, pdata, ind)
    end
end)

-- run each globalstep for more complex interactions
-- runs player step functionality
core.register_globalstep(function(dtime)
    for _,pdata in ipairs(pdatas) do
        -- update time
        pdata.time = pdata.time + dtime
        pdata.dtime = dtime
        -- get player object for ease
        local plr = pdata.obj
        -- properties
        pdata.props = plr:get_properties()
        -- run overall step event
        events.step(plr, pdata)
    end
end)

-- ran each globalstep
-- handle player controls functionality
events.step.register(function(plr, pdata)
    local dtime = pdata.dtime
    local hkeys = pdata.held_keys -- held keys
    local SPK -- stopped pressing keys
    -- now to get into the meat of this code
    local ctrlkeys = plr:get_player_control() -- control keys
    -- check if any keys are being pressed
    for key, pressed in pairs(ctrlkeys) do
        local okey = hkeys[key] -- old key (data)
        if okey then
            -- still pressing, increase time
            if pressed then
                okey.time = okey.time + dtime
            -- no longer pressing, add to list of keys no longer pressing
            else
                SPK = SPK or {}
                SPK[key] = okey
                -- remove data
                hkeys[key] = nil
            end
        end
        -- create new held key
        if pressed then
            hkeys[key] = {time = 0}
        end
    end
    -- iterate over currently held keys
    for key, data in pairs(hkeys) do
        -- newcomer
        if data.time == 0 then
            events.keypress_start(plr, pdata, key)
            events.keypress_step(plr, pdata, key, 0)
        -- still being pressed
        else
            events.keypress_step(plr, pdata, key, data.time)
        end
    end
    -- keys that have ceased to be pressed
    if SPK then -- stopped pressing keys
        for key, data in pairs(SPK) do
            events.keypress_end(plr, pdata, key, data.time)
        end
    end
end)

-- ran each globalstep
-- updates information on certain player attributes and runs relevant events
events.step.register(function(plr, pdata)
    -- position
    local oldpos = pdata.pos
    local pos = plr:get_pos()
    pdata.pos = pos
    -- lookdir
    local oldlookdir = pdata.lookdir
    pdata.lookdir = plr:get_look_dir()
    -- player's wielded item
    local oldwield = pdata.wielded
    local wielded = plr:get_wielded_item()
    wielded = {stack = wielded, index = plr:get_wield_index(),
      def = wielded:get_definition() or
      -- create a "ghost" definition in failure
      {name = wielded:get_name()} }
    pdata.wielded = wielded
    -- events!!!
    -- run pos change event
    if oldpos == nil or not vector.equals(pos, oldpos) then
        -- create eyepos
        pdata.eyepos = vector.new(pos.x, pos.y + pdata.props.eye_height, pos.z)
        -- in event of a nil oldpos, default to current player's position
        events.change_pos(plr, pdata, pos, oldpos or pos)
    end
    -- run lookdir change event
    if oldlookdir == nil or not vector.equals(pdata.lookdir, oldlookdir) then
        -- ditto to pos change
        events.change_lookdir(plr, pdata, pdata.lookdir, oldlookdir or pdata.lookdir)
    end
    -- run wielded item change
    -- "wielded change reason"
    local WCR = oldwield and oldwield.def and (
        oldwield.def.name ~= wielded.def.name and "name change" or
          oldwield.index ~= wielded.index and "index changed" or
          "unknown"
    ) or "null"
    if not (oldwield and oldwield.def) or
      (oldwield.def.name ~= wielded.name or oldwield.index ~= wielded.index) then
        events.wieldchange(plr, pdata, wielded.stack, wielded.def, WCR)
    end
end)

-- RUN `player_change_eyepos_or_lookdir` EVENT!
-- ran each pos change
events.change_pos.register(function(plr, pdata, pos, oldpos)
    pdata.eyepos = vector.new(pos.x, pos.y + pdata.props.eye_height, pos.z)
    events.change_eyepos_or_lookdir(plr, pdata, pdata.eyepos, pdata.lookdir)
end)
-- ran each lookdir change
events.change_lookdir.register(function(plr, pdata, lookdir, oldlookdir)
    events.change_eyepos_or_lookdir(plr, pdata, pdata.eyepos, lookdir)
end)

-- ran each lookdir or eyepos (or pos) change
-- handle creating lookpos and lookatpos
events.change_eyepos_or_lookdir.register(function(plr, pdata, eyepos, lookdir)
    -- forwards our view
    pdata.lookpos = eyepos:add(lookdir)
    -- what position we're looking at plus reach range
    pdata.lookatpos = lookdir:multiply(tg_main.reach - 1):add(pdata.lookpos)
end)

-- ran each keypress step
-- handle player crouching + proning (and gradual decreasing of eye height)
events.keypress_step.register(function(plr, pdata, key, time)
    if key ~= "sneak" then return end -- not pressing sneak
    if pdata.held_keys.jump then return end -- JUMPING, AAAH!!!
    -- sneaky time
    local props = pdata.props -- player's properties
    local eheight = props.eye_height
    -- ideal eye height
    local IEH = pdata.proning and tg_player.eye_height_prone or
      tg_player.eye_height_sneak
    -- slowly transitioning down
    if eheight ~= IEH then
        local dtimeperc = pdata.dtime/0.025 -- delta time percentage (every 25ms)
        -- subtract by 0.06 per dtimeperc, clamp to IEH if below
        props.eye_height = math.max(eheight - (0.06*dtimeperc), IEH)
        -- update player properties
        plr:set_properties(props)
        -- gradually change proning player's look
        if pdata.proning then
            local clook = math.deg(plr:get_look_vertical()) -- current look
            if clook > 10 then
                -- subtract by 6 per dtimeperc
                clook = math.max(clook - (8*dtimeperc), 10) -- clamp above 10
                plr:set_look_vertical(math.rad(clook))
            end
        end
    end
    -- set boolean
    if not pdata.sneaking then
        -- sneak is active!
        pdata.sneaking = true -- we're sneaking, we're sneaking!
        pdata.getting_up = nil -- stop trying to get up
    end
end)

-- ran each keypress start
-- set player proning (if pressed down, looking at floor, and already sneaking)
events.keypress_start.register(function(plr, pdata, key)
    if key ~= "down" then return end
    -- don't do anything if we're already proning or aren't sneaking
    if pdata.proning or not pdata.sneaking then return end
    -- figure out if we're looking at the floor
    local look = math.floor(math.deg(plr:get_look_vertical()))
    if look < 65 then return end -- not looking at floor
    --core.log("do proning")
    -- proning is active!
    pdata.proning = true
end)

-- ran each keypress end
-- tell ourselves that we're getting up (stopped pressing sneak)
events.keypress_end.register(function(plr, pdata, key, time)
    if key ~= "sneak" then return end -- not sneaking
    if pdata.getting_up then return end -- we're already getting up!
    -- we're getting up!
    pdata.getting_up = true
    -- no longer sneaking or proning
    pdata.sneaking = nil
    pdata.proning = nil
end)

-- ran each globalstep
-- handle getting up from sneaking/proning
events.step.register(function(plr, pdata)
    if not pdata.getting_up then return end
    local props = pdata.props -- player properties
    local eheight = props.eye_height
    -- ideal eye height
    local IEH = tg_player.eye_height
    -- transitioning back up
    if eheight ~= IEH then
        -- add by 0.15, clamp to IEH if above
        props.eye_height = math.min(eheight + 0.15, IEH)
        -- update player properties
        plr:set_properties(props)
    end
    -- completed!
    if eheight == IEH then
        pdata.getting_up = nil
    end
end)

-- ran each keypress step
-- can't crouch if we're jumping!
events.keypress_step.register(function(plr, pdata, key, time)
    if key == "jump" then
        pdata.sneaking = nil
        pdata.proning = nil
        pdata.getting_up = true
    end
end)
