local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

tg_player = {}

tg_player.eye_height = {
  stand = 1.625, -- up and about
  sneak = 1.3,   -- crouching
  crawl = 0.5    -- on the ground like a worm
}

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

core.register_on_player_receive_fields(function(player, formname, fields)
  -- core.log("formname: "..dump(formname))
  -- core.log("fields: "..dump(fields))
  if formname == "" then
    for key, label in pairs(fields) do
      -- core.log("key: "..dump(key))
      if key == "torch" then
        local has_torch = tg_interactions.playerHasCollection(player:get_player_name(),"tg_interactions:torch")
        if has_torch == true then
          tg_torch.toggle_torch_light(player)
        end
      end
    end
  end
end)

core.register_on_joinplayer(function(player, last_login)
  player:set_inventory_formspec(
    table.concat({
      "formspec_version[10]",
      "size[20,8]",
      "no_prepend[]",
      "position[1,1]",
      "anchor[1,1]",
      "button[2,2;2,2;howdy;the_button]",
      "button[8,2;2,2;torch;toggle torch]",
    })
  )
  player:set_sky({
    base_color = tg_main.fog_color.white,
    -- base_color = "#111",
    -- base_color = "#000",
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
  -- individual stats
  -- player's pos changed
  "change_pos",
  -- player's lookdir changed
  "change_lookdir",
  -- either player's eye pos or lookdir changed
  "change_eyepos_or_lookdir",
  -- additional player movements
  "crouch_success",
  "crawl_success",
  "gotup"
}) do
  -- name, automatic setup definition: add register function to `tg_interactions`
  -- return will be data of this event
  events[ename] = events_api.create(ename, { global = tg_player })
end


-- array of data of players
local pdatas = {}

-- player data related functions

--- function for returning data on select player
--- @param plr userdata select player
function tg_player.get_data(plr)
  -- iterate over player datas to compare object
  for ind, pdata in ipairs(pdatas) do
    -- permit the return of an index (ind) as 2nd return
    -- (index should NOT be used by external mods nor stored due to dynamicism)
    if plr == pdata.obj then
      return pdata, ind
    end
  end
end

--- function for changing player's eye height alongside their collision box
--- @param plr userdata player to change eye_height of
--- @param eye_height number
--- @param pdata? table data on current player, does not need to be specified
function tg_player.change_eye_height(plr, eye_height, pdata)
  if type(eye_height) ~= "number" then return end -- not a number
  pdata = pdata or tg_player.get_data(plr)
  if not pdata then return end                    -- how??? what did you do???
  pdata.props = pdata.props or plr:get_properties()
  local props = pdata.props
  -- now to change collisionbox
  local colbox = pdata.props.collisionbox
  -- colbox[2] SHOULD BE 0, but JUST in case, let's use it here!
  -- add bit of our head to the eye_height as well (0.145)
  colbox[5] = colbox[2] + (eye_height + 0.145)
  -- now set changed eye height
  props.eye_height = eye_height
  -- set
  plr:set_properties(pdata.props)
end

-- create data
core.register_on_joinplayer(function(plr)
  local pdata = {
    obj = plr,
    props = plr:get_properties(),
    name = plr:get_player_name(),
    time = 0,      -- total time
    held_keys = {} -- data on each key pressed (time)
  }
  pdatas[#pdatas + 1] = pdata
  -- change texture
  pdata.props.textures = { "player.png" }
  -- changes eye height + sets properties
  tg_player.change_eye_height(plr, tg_player.eye_height.stand, pdata)
  -- disabled the builtin sneak
  plr:set_physics_override({ sneak = false, })

  -- have the player start off on the floor (to prevent clipping)
  pdata.start_on_floor = true
  pdata.crawling = true      -- we're sneaking, we're sneaking!
  pdata.getting_up = nil     -- stop trying to get up
  tg_player.change_eye_height(plr, tg_player.eye_height.crawl, pdata)
  plr:set_look_vertical(math.rad(40))

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
  local pdata, ind = tg_player.get_data(plr)
  -- found! remove
  if pdata then
    return on_leave(plr, pdata, ind)
  end
end)
-- server shutdown
core.register_on_shutdown(function()
  -- destroy ALL player datas
  for ind, pdata in ipairs(pdatas) do
    on_leave(pdata.obj, pdata, ind)
  end
end)

-- run each globalstep for more complex interactions
-- runs player step functionality
core.register_globalstep(function(dtime)
  for _, pdata in ipairs(pdatas) do
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
  local hkeys = pdata.held_keys             -- held keys
  local SPK                                 -- stopped pressing keys
  -- now to get into the meat of this code
  local ctrlkeys = plr:get_player_control() -- control keys
  -- check if any keys are being pressed
  for key, pressed in pairs(ctrlkeys) do
    local okey = hkeys[key] -- old key (data)
    if okey then
      -- still pressing, increase time
      if pressed then
        okey.time = okey.time + dtime
        -- once the player starts moving unchain them from the floor
        for _, value in ipairs({"left","right","up","down","jump"}) do
          -- if the node below a player is the node "climbable_node" set them to crawl mode
          local pos_below = plr:get_pos()
          if string.find(core.get_node(pos_below).name,"climbable_node") then
            -- core.log("the node is in fact climbable_node")
            pdata.start_on_floor = true
            pdata.crawling = true      -- we're sneaking, we're sneaking!
            pdata.getting_up = nil     -- stop trying to get up
            -- tg_player.change_eye_height(plr, tg_player.eye_height.crawl, pdata)
          else
            if key == value then
              if pdata.start_on_floor == true then
              pdata.start_on_floor = false
              pdata.try_getting_up = true
              end
            end
          end
        end
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
      hkeys[key] = { time = 0 }
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
end)

-- run wielded events
dofile(mod_path .. "/scripts" .. "/wield.lua")

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
-- handle player crouching + crawling (and gradual decreasing of eye height)
events.keypress_step.register(function(plr, pdata, key, time)
  -- start on floor to prevent clipping through nodes
  if pdata.start_on_floor == false then
    if key ~= "sneak" then return end         -- not pressing sneak
    if pdata.held_keys.jump then return end   -- JUMPING, AAAH!!!
    if pdata.getting_up then return end       -- can't crouch if getting up
  end
  -- sneaky time
  local props = pdata.props               -- player's properties
  local eheight = props.eye_height
  -- ideal eye height
  local IEH = pdata.crawling and tg_player.eye_height.crawl or
      tg_player.eye_height.sneak
  -- slowly transitioning down
  -- value will not stay the same, check difference
  if math.abs(eheight - IEH) > 0.001 then
    local dtimeperc = pdata.dtime / 0.025 -- delta time percentage (every 25ms)
    -- subtract by 0.045 per dtimeperc, clamp to IEH if below
    eheight = math.max(eheight - (0.045 * dtimeperc), IEH)
    -- update player eye_height + set properties
    tg_player.change_eye_height(plr, eheight, pdata)
    -- gradually change crawling player's look
    if pdata.crawling then
      local clook = math.deg(plr:get_look_vertical()) -- current look
      if clook > 10 then
        -- subtract by 6 per dtimeperc
        clook = math.max(clook - (6 * dtimeperc), 10) -- clamp above 10
        plr:set_look_vertical(math.rad(clook))
      end
    end
    -- check if equal now
    if props.eye_height == IEH then
      -- run callbacks
      if pdata.crawling then
        events.crawl_success(plr, pdata)
      else
        events.crouch_success(plr, pdata)
      end
    end
  end
  -- set boolean
  if not pdata.sneaking and not pdata.start_on_floor then
    -- sneak is active!
    pdata.sneaking = true  -- we're sneaking, we're sneaking!
    pdata.getting_up = nil -- stop trying to get up
  end
end)

-- ran each keypress start
-- set player crawling (if pressed down, looking at floor, and already sneaking)
events.keypress_start.register(function(plr, pdata, key)
  if key ~= "down" then return end
  -- don't do anything if we're already crawling or aren't sneaking
  if pdata.crawling or not pdata.sneaking then return end
  -- figure out if we're looking at the floor
  local look = math.floor(math.deg(plr:get_look_vertical()))
  if look < 65 then return end -- not looking at floor
  --core.log("do crawling")
  -- crawling is active!
  pdata.crawling = true
end)

-- ran each keypress end
-- tell ourselves that we're getting up (stopped pressing sneak)
events.keypress_end.register(function(plr, pdata, key, time)
  if key ~= "sneak" then return end   -- not sneaking
  if pdata.getting_up then return end -- we're already getting up!
  -- we're gon try getting up!
  pdata.try_getting_up = true
end)

-- ran each globalstep
-- handle getting up from sneaking/crawling
events.step.register(function(plr, pdata)
  if pdata.try_getting_up then
    -- cast a ray and get at least 2 nodes above the player
    -- the player could be inside a node that is not walkable but then the one above may be walkable, cant allow that.
    local raycast = core.raycast(plr:get_pos():add(vector.new(0, 0.5, 0)), plr:get_pos():add(vector.new(0, 1.5, 0)),
      false, false)
    local can_get_up = true
    for ray in raycast do
      local node = core.get_node(ray.under)
      node = core.registered_nodes[node.name]
      if node then
        can_get_up = not node.walkable
      end
    end
    if can_get_up == false then return end

    -- definitely no longer sneaking or crawling
    pdata.sneaking = nil
    pdata.crawling = nil
    -- now getting up
    pdata.getting_up = true
    pdata.try_getting_up = nil -- we're already getting up now!
  end
  -- don't run rest of code til this is done
  if not pdata.getting_up then return end
  local props = pdata.props -- player properties
  local eheight = props.eye_height
  -- ideal eye height
  local IEH = tg_player.eye_height.stand
  -- transitioning back up
  if eheight ~= IEH then
    -- add by 0.15, clamp to IEH if above
    eheight = math.min(eheight + 0.15, IEH)
    -- update player properties
    tg_player.change_eye_height(plr, eheight, pdata)
  end
  -- completed!
  if props.eye_height == IEH then
    pdata.getting_up = nil
    events.gotup(plr, pdata)
  end
end)

-- ran each keypress step
-- can't crouch if we're jumping!
events.keypress_step.register(function(plr, pdata, key, time)
  if pdata.start_on_floor then return end
  if key ~= "jump" then return end
  -- only do stuff if crawling or sneaking
  if not (pdata.sneaking or pdata.crawling) then return end
  -- probably not healthy checking this each jump step, but eh
  -- add 1.5 +Y to check node above
  local anode = core.get_node(pdata.pos:add(vector.new(0, 1.5, 0)))
  anode = core.registered_nodes[anode.name]
  if anode and anode.walkable then return end -- can't crouch up from here
  pdata.sneaking = nil
  pdata.crawling = nil
  pdata.getting_up = true
end)

-- crawling extras
events.crawl_success.register(function(plr, pdata)
  -- hitting floor sound
  core.sound_play("tg_player_crawl", {
    obj = plr,
    pitch = math.random(95, 120) / 100
  })
  -- remove footstep sound
  local props = pdata.props
  if not props then return end
  props.makes_footstep_sound = false
  plr:set_properties(props)
end)

-- fix footstep sound
events.gotup.register(function(plr, pdata)
  local props = pdata.props
  if not props then return end
  if not props.makes_footstep_sound then
    props.makes_footstep_sound = true
    plr:set_properties(props)
  end
end)

-- crawl movement sounds
-- create crawlsound
events.crawl_success.register(function(plr, pdata)
  pdata.crawl_sound = { poscheck = 0 } -- start at 0 to prevent sound until moving
end)

-- update poscheck
events.change_pos.register(function(plr, pdata, pos, oldpos)
  local crawlsound = pdata.crawl_sound
  if not crawlsound then return end    -- no point!
  if pos.y ~= oldpos.y then return end -- falling or jumping!
  -- reset pos check
  crawlsound.poscheck = 0.2
end)

-- play or stop crawling sounds
events.step.register(function(plr, pdata)
  local crawlsound = pdata.crawl_sound
  local sound = crawlsound and crawlsound.id -- return of `core.sound_play`
  -- no longer crawling
  if not pdata.crawling then
    if sound then
      core.sound_fade(sound, 2, 0)
      pdata.crawl_sound = nil -- erase
    end
    return
  end
  if not crawlsound then return end -- can't do anything, man!
  -- don't play any sound if poscheck is 0
  if crawlsound.poscheck == 0 then
    if sound then
      core.sound_fade(sound, 0.4, 0)
      --pdata.crawl_sound = nil -- erase
    end
    return
  end
  -- get dtime, total time, length of sound
  local dtime = pdata.dtime or 0
  local ttime = pdata.time
  local len = pdata.playlength or 0.8
  -- and count down
  -- clamp above 0
  crawlsound.poscheck = math.max(crawlsound.poscheck - dtime, 0)
  -- check if should play sound again
  local lastplayed = crawlsound.playedat
  -- no playedat means haven't played, or time since is greater than playlength
  if not lastplayed or (ttime - lastplayed) > len then
    if sound then
      core.sound_fade(sound, 2, 0)
    end
    local pitch = math.random(60, 110) / 100
    crawlsound.id = core.sound_play("tg_player_crawl_move", {
      --obj = plr,
      pos = pdata.pos,
      pitch = pitch,
      gain = math.random(5, 10) / 100
    })
    -- set timing
    crawlsound.playedat = ttime
    -- expected length divided by pitch
    crawlsound.playlength = 1.6 / pitch
  end
end)
