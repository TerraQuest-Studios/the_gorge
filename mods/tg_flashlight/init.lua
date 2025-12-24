local mod_name = core.get_current_modname()

---@ignore
tg_torch = {}

-- a lot happened with this ~mod.
-- when the player has the **torch** on, a "few" rays get shot
-- if the node that is hit is air or spot_light
-- then it gets add to the "now" var
-- every new tick recent becomes now and now get reset and new points are gotten
-- if the points are new then a new spot_light needs to be added in that new location
-- if any points in recent are not in now, then the spot_lights in that point get removed
-- the spot_lights also have a timer that checks if flash_active is false, if it is false they will remove themselves.

local now = {}
local recent = {}

local torch_active = false

core.register_entity(mod_name .. ":torch", {
  initial_properties = {
    visual = "mesh",
    mesh = "flash.glb",
    visual_size = { x = 100, y = 100, z = 100 },
    -- visual = "wielditem",
    -- wield_item = "tg_furniture:oak_chair",
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

core.register_node(mod_name .. ":" .. "torch_lit_spot", {
  description = "lit_spot, will remove it's self.",
  groups = { dig_immediate = 3 },
  tiles = { { name = "tg_nodes_fog.png^[opacity:0" }, }, -- can i just gen a nill texture?
  use_texture_alpha = "blend",
  paramtype = "light",
  pointable = false,
  drawtype = "glasslike",
  light_source = 7,
  walkable = false,
  sunlight_propagates = true,
  on_construct = function(pos)
    core.get_node_timer(pos):start(0.5)
  end,
  on_timer = function(pos, elapsed, node, timeout)
    -- node = node or core.get_node(pos)
    if torch_active == false then
      -- if recent[vector.to_string(pos)] ~= true then
        -- core.log("should remove")
        core.remove_node(pos)
      -- end
    end
    core.get_node_timer(pos):start(0.5)
  end,
})

local function toggleTorch(pos)
  core.sound_play({ name = "tg_paper_footstep" }, {
    gain = 1.0,   -- default
    fade = 100.0, -- default
    pitch = 1.8,  -- 1.0, -- default
    pos = { x = pos.x, y = pos.y, z = pos.z },
  })
  torch_active = not torch_active
  if torch_active == false then
    -- for index, value in pairs(recent) do
    --   if core.get_node(vector.from_string(index)).name == mod_name..":flashlight_lit_spot" then
    --     core.remove_node(vector.from_string(index))
    --     core.log("should remove")
    --   end
    -- end
    recent = {}
  end
end

core.register_node(mod_name .. ":" .. "torch", {
  description = "torch, i can see in the dark with this.",
  -- inventory_image = "flashlight.png",
  groups = { dig_immediate = 3 },
  drawtype = "mesh",
  mesh = "torch.glb",
  tiles = { { name = "torch.png" } },
  -- use_texture_alpha = "blend",
  visual_size = { x = 10, y = 10, z = 10 },
  visual_scale = 18.0,
  wield_scale = { x = 18, y = 18, z = 18 },
  node_placement_prediction = "",
  on_secondary_use = function(itemstack, user, pointed_thing)
    toggleTorch(user:get_pos())
  end,
  -- on_use = function(itemstack, user, pointed_thing)
  --   -- return -- lets just prevent breaking stuff with this
  --   toggleFlash(user:get_pos())
  -- end,

  on_place = function(itemstack, placer, pointed_thing)
    toggleTorch(placer:get_pos())
    return
  end,
  -- short_description = "",
})

core.register_globalstep(function(dtime)
  if not torch_active then return end
  local players = core.get_connected_players()
  if #players < 0 then return end -- don't do anything below until there's a player
  for _, player in ipairs(players) do
    if player:get_wielded_item() == nil then return end
    local item_name = player:get_wielded_item():get_name()
    -- core.log("holding: "..dump(item_name))
    if item_name ~= mod_name .. ":torch" then
      return
      -- core.log("mf is holding a damn flashlight")
    end
    local pos = player:get_pos()
    local eye_height = player:get_properties().eye_height
    pos.y = pos.y + eye_height -- add eye height
    -- looking direction
    local player_look_dir = player:get_look_dir()
    local lookpos = pos:add(player_look_dir) -- forwards our view
    -- core.log("what is this? "..dump(player:get_look_dir()))
    local node_at_player = core.get_node(lookpos)
    if node_at_player and node_at_player.name == "air" then
      -- core.log("we have air")
      core.set_node(lookpos, { name = mod_name .. ":torch_lit_spot" })

      -- core.log("node: ",dump(node))
    end
    local to_cast = {
      player_look_dir:add(vector.new(0.1, 0, 0)),
      player_look_dir:add(vector.new(0.05, 0, 0)),
      player_look_dir,
      player_look_dir:add(vector.new(-0.05, 0, 0)),
      player_look_dir:add(vector.new(-0.1, 0, 0)),

      player_look_dir:add(vector.new(0.1, 0.05, 0)),
      player_look_dir:add(vector.new(0.05, 0.05, 0)),
      player_look_dir:add(vector.new(0, 0.05, 0)),
      player_look_dir:add(vector.new(-0.05, 0.05, 0)),
      player_look_dir:add(vector.new(-0.1, 0.05, 0)),

      player_look_dir:add(vector.new(0.1, -0.05, 0)),
      player_look_dir:add(vector.new(0.05, -0.05, 0)),
      player_look_dir:add(vector.new(0, -0.05, 0)),
      player_look_dir:add(vector.new(-0.05, -0.05, 0)),
      player_look_dir:add(vector.new(-0.1, -0.05, 0)),
      -- vector.new(-6.5, 0, 0),
      -- vector.new(6.5, 0, 0),
    }
    for index, value in ipairs(to_cast) do
      -- what position we're looking at plus our wielded range
      -- local lookatpos = player_look_dir:multiply(40):add(lookpos)
      local lookatpos = value:multiply(40):add(lookpos)
      local raycast_result = core.raycast(pos, lookatpos, true, false)
      -- no raycast, no point!
      if raycast_result then
        -- iterate through raycast and find an interactable
        for thing in raycast_result do
          -- an entity!
          -- if thing and thing.type == "object" then
          --   ent = thing.ref:get_luaentity()
          --   -- found a proper entity with a popup message, break loop!
          --   if ent and ent._popup_msg then break end
          -- end
          if thing and thing.type == "node" then
            -- core.log("this: "..dump(thing))
            local pointed_under = thing.under
            local node_under = core.get_node(pointed_under)
            -- if node_under and node_under.name == mod_name .. ":flashlight_lit_spot" then
            --   return
            -- end
            local pointed = thing.above
            local node = core.get_node(pointed)
            if node and node.name == "air" then
              -- core.log("we have air")
              -- core.set_node(pointed, { name = mod_name .. ":flashlight_lit_spot" })
              -- table.insert(now,pointed)
              -- core.log("node: ",dump(node))
            end
            now[vector.to_string(pointed)] = true
          end
        end
      end
    end
    -- get now
    -- check if recent contains now
    -- if recent does not contain now then add a flash.
    -- clear recent and set recent to now
    local temp = {}
    for key, value in pairs(recent) do
      temp[key] = value
    end
    recent = {}
    for this_pos, value in pairs(now) do
      local this_pos_pos = vector.from_string(this_pos)
      if temp[this_pos] == true then
        -- core.log("lets do nothing")
      else
        -- core.log("need to add a NODE")
        local this_node = core.get_node(this_pos_pos)
        if this_node and this_node.name == "air" then
          core.set_node(this_pos_pos, { name = mod_name .. ":torch_lit_spot" })
        end
      end
      recent[this_pos] = true -- they need to be added to it no matter what
    end
    for key, value in pairs(temp) do
      if recent[key] == true then
        -- nothing
      else
        local found_node = core.get_node(vector.from_string(key))
        if found_node and found_node.name == mod_name..":torch_lit_spot" then
          core.remove_node(vector.from_string(key))
          -- core.log("this needs to be removed")
        else
          -- core.log("yes but lets not remove it")
        end
      end
    end
    now = {}
  end
end)
