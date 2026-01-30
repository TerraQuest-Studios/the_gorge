local mod_name = core.get_current_modname()

-- NEW

local torchname = mod_name..":torch"

-- table of litspots indexed by position hash
local litspots = {}

-- destroy light spots correlated to a player data's torch_data
local function destroy_lit_spots(pdata)
    local tdata = pdata.torch_data
    local lit_tags = tdata and tdata.lit_tags
    -- has no light tags, can't destroy any subsequently
    if not lit_tags then return end
    -- value will be a position hash, can grab position from indexing litspots table
    for _,tag in ipairs(tdata.lit_tags) do
        local pos = litspots[tag]
        -- DESTROY!
        if pos then
            core.remove_node(pos)
            litspots[tag] = nil
        end
    end
    -- delete table
    tdata.lit_tags = nil
end

-- handle whether or not torch should be on (show lighting)
-- pdata and def are optional
local function toggle_torch(plr, pdata, def)
    pdata = pdata or tg_player.get_data(plr)
    -- if we're on or not
    local tdata = pdata.torch_data
    -- get definition
    local wielded = pdata.wielded
    def = def or wielded and wielded.def
    -- turn off!
    if tdata then
        -- run sound
        local sound = def and def.sounds and def.sounds.wield_toggle_off
        if sound then
            core.sound_play(sound, {obj=plr})
        end
        -- destroy
        destroy_lit_spots(pdata)
        pdata.torch_data = nil
        return
    end
    -- get necessary data
    local eyepos, lookpos = pdata.eyepos, pdata.lookpos
    -- do not do anything if can't
    if not (wielded and eyepos and lookpos) then return end
    -- can't update
    if not (def and def.flashlight_update) then return end
    -- let's turn on!
    -- play sound
    local sound = def.sounds and def.sounds.wield_toggle_on
    if sound then
        core.sound_play(sound, {obj=plr})
    end
    -- run our wielded update function (4th parameter is a new table for "torch data"
    def.flashlight_update(plr, pdata, wielded, {})
end

-- used by flashlight to light up a room
core.register_node(mod_name .. ":" .. "torch_lit_spot", {
  description = "lit_spot, will remove it's self.",
  groups = { dig_immediate = 3, light_node = 1 },
  tiles = { "blank.png" }, -- well now i know i can have no texture
  use_texture_alpha = "blend",
  paramtype = "light",
  pointable = false,
  drawtype = "glasslike",
  light_source = 7,
  walkable = false,
  sunlight_propagates = true,
  on_construct = function(pos)
      core.get_node_timer(pos):start(20) -- do checks every 20 seconds
  end,
  -- the CHECK, will delete node if can't find in table
  on_timer = function(pos, elapsed, node, timeout)
    local hash = core.hash_node_position(pos)
    -- not in activity, destroy
    if not litspots[hash] then
        core.remove_node(pos)
    end
    -- keep GOING
    return true
  end
})

-- torch (flashlight)
core.register_node(torchname, {
  description = "torch, i can see in the dark with this.",
  groups = { dig_immediate = 3, flashlight = 1 },
  drawtype = "mesh",
  mesh = "torch.glb",
  tiles = { { name = "torch.png" } },
  visual_size = { x = 10, y = 10, z = 10 },
  visual_scale = 18.0,
  wield_scale = { x = 18, y = 18, z = 18 },
  node_placement_prediction = "",
  stack_max = 1, -- can only have 1 torch
  sounds = {
      wield_toggle_on = {
          name = "tg_paper_footstep",
          gain = 1,
          pitch = 1.8
      },
      wield_toggle_off = {
          name = "tg_dirt_footstep",
          gain = 0.6,
          pitch = 0.6
      }
  },
  on_secondary_use = function(itemstack, user, pointed_thing)
      toggle_torch(user)
  end,
  -- on_use = function(itemstack, user, pointed_thing)
  --   -- return -- lets just prevent breaking stuff with this
  --   toggleFlash(user:get_pos())
  -- end,

  on_place = function(itemstack, placer, pointed_thing)
      toggle_torch(placer)
      return
  end,
  -- wielded item callbacks
  -- turn off when unequipped
  wield_unequipped = function(plr, itemstack, def, reason, pdata)
      if not pdata.torch_data then return end -- no torch data, already off
      -- turn off proper
      toggle_torch(plr, pdata, def)
  end,
  wield_equipped = function(plr, itemstack, def, reason, pdata)
      if not pdata.torch_data then return end -- wasn't on
      -- run update!
      if def.flashlight_update then
          def.flashlight_update(plr, pdata, pdata.wielded)
      end
  end,
  -- flashlight functionality
  --flashlight_range = 40, can be customized to be shorter
  -- update flashlight information
  flashlight_update = function(plr, pdata, wielded, tdata)
      tdata = tdata or pdata.torch_data -- grab if unspecified
      if not tdata then return end -- huh, how did this happen?
      -- get important variables
      local eyepos, lookpos, lookdir = pdata.eyepos, pdata.lookpos, pdata.lookdir
      if not lookpos then return end -- hmmmmmmmmmm how
      -- ok rest of stuff now!
      local range = tdata.range or wielded.def.flashlight_range or 40 -- default to 40
      -- update our variable
      if not tdata.range then
          tdata.range = range
      end
      -- iterate over any lit positions (to destroy)
      if tdata.lit_tags then
          destroy_lit_spots(pdata)
      end
      -- create new lit_tags data
      local lit_tagsraw = {
          {lookpos:round()} -- provide light on top of player
      }
      -- get lookat
      local lookatpos = lookdir:multiply(range):add(lookpos)
      local raycast_result = core.raycast(eyepos, lookatpos, true, false)
      -- looking at dis bs
      local looktarget = {type="null"}
      -- iterate over raycast stuff
      for thing in raycast_result do
          if thing then
              -- hit an object that can be indexed
              if thing.type == "object" then
                  local props = thing.ref and thing.ref:get_properties()
                  if props and props.physical then
                      looktarget = thing
                      break
                  end
              -- hit a node
              elseif thing.type == "node" then
                  looktarget = thing
                  break
              end
          end
      end
      -- calculating further stuff now
      -- figure out list of positions to check
      -- convert into table for list
      local targetpos = looktarget.type == "node" and
        -- get position in front of node (above)
        {looktarget.above, looktarget.under} or
        -- entity position (get position of object and round it)
        looktarget.type == "object" and {looktarget.ref:get_pos():round()} or
        -- default to lookatpos if too far
        looktarget.type == "null" and {lookatpos}
      -- add to list
      if targetpos then
          table.insert(lit_tagsraw, targetpos)
      end
      -- check and add lights, as well as replace with hash
      local endpoint -- figure out where we're ending
      local lit_tags = {}
      for ind,list in ipairs(lit_tagsraw) do
          for _,pos in ipairs(list) do
              local node = core.get_node(pos)
              node = core.registered_nodes[node.name]
              if node and node.name == "air" then
                  local tag = core.hash_node_position(pos) -- get hash
                  litspots[tag] = pos -- add to litspots
                  table.insert(lit_tags, tag) -- add to lit_tags table
                  -- set endpoint if not starting position
                  if not vector.equals(lookpos, pos) then
                      endpoint = pos
                  end
                  core.add_node(pos, {name = mod_name..":torch_lit_spot"})
                  break -- break list loop
              end
          end
      end
      -- figure out light in between start to end
      if endpoint then
          local amt = lookpos:distance(endpoint)
          amt = amt/4 -- produce a light node every 3 distances
          -- only do these calculations if we're producing an extra
          if amt > 1 then
              local startpos = lookpos
              for i=1, math.ceil(amt) do -- ceil to produce a light node closer to the end
                  startpos = lookdir:multiply(7):add(startpos) -- go forwards 7
                  -- round it
                  startpos = startpos:round()
                  -- node check
                  local node = core.get_node(startpos)
                  node = core.registered_nodes[node.name]
                  -- acceptable, add to list and create
                  if node and node.name == "air" then
                      local tag = core.hash_node_position(startpos) -- get hash
                      litspots[tag] = startpos -- add to litspots
                      table.insert(lit_tags, tag) -- add to lit_tags table
                      core.add_node(startpos, {name = mod_name..":torch_lit_spot"})
                  end
              end
          end
      end
      -- don't do anything else if we don't have any lit positions
      if #lit_tags == 0 then return end
      -- set lit positions
      tdata.lit_tags = lit_tags
      -- add torch data if not added already
      if not pdata.torch_data then
          pdata.torch_data = tdata
      end
  end,
})

-- update flashlight every time player moves or turns
tg_player.register_on_change_eyepos_or_lookdir(function(plr, pdata, eyepos, lookdir)
    local wielded = pdata.wielded
    local def = wielded and wielded.def
    -- not da flashlight
    if not (def and def.name == torchname) then return end
    -- IS the flashlight! :O
    -- only update flashlight if on
    local tdata = pdata.torch_data
    if not tdata then return end -- not on
    -- update the flashloot
    if def.flashlight_update then
        def.flashlight_update(plr, pdata, wielded, tdata)
    end
end)

-- delete light nodes on player leave
tg_player.register_on_leave(function(plr, pdata)
    local lit_tags = pdata.torch_data
    lit_tags = lit_tags and lit_tags.lit_tags
    -- only do stuff if there's lit nodes
    if not lit_tags then return end
    -- delete!!!
    destroy_lit_spots(pdata)
end)

core.register_entity(mod_name .. ":flash", {
  initial_properties = {
    visual = "mesh",
    mesh = "flash.glb",
    visual_size = { x = 100, y = 100, z = 100 },
    -- visual = "wielditem",
    -- visual_size = { x = 0.65, y = 0.65, z = 0.65 }, -- i guess this is the size for drawtype node
    use_texture_alpha = true,
    textures = { "flash.png^[colorize:#fc3c3c:125" },
    glow = 0,
    shaded = true,
    -- backface_culling = false,
    physical = false,
    -- collide_with_objects = true,
  },
  on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
    if puncher:get_player_control().sneak == true then
      if core.is_creative_enabled() == true then
        self.object:remove()
      end
    end
  end,
})