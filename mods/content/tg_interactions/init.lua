local mod_name = core.get_current_modname()
local S = core.get_translator(mod_name)

local shapes = tg_nodes["shapes"]

tg_interactions = {}

-- NOTE: for something to get the "interactable" popup
-- it have "_interactable = 1"

-- local reach = 3.5 -- things within will show interacable/ popup on hover
tg_interactions.popup_radius = 3.5

local gravity = -0.9

local function debug(msg)
  core.log("[entity]: " .. msg)
end

local players_dragging = {}

-- local function getDragging(player)
--   local players = core.get_connected_players()
--   if #players > 0 then
--     local found_player = false
--     for _, value in ipairs(players) do
--       local player_name = player:get_player_name()
--       if value == player_name then
--         found_player = true
--       end
--     end
--   end
-- end

-- v is {x,y,z}, damping in range (0,1): higher -> stops faster
local function apply_damping(v, damping, dt)
  local f = math.max(0, 1 - damping * dt) -- damping is e.g. 2.0 (per second)
  return { x = v.x * f, y = v.y * f, z = v.z * f }
end

local function restorePlayerMovement(dragged_by)
  local players = core.get_connected_players()
  if #players > 0 then
    for _, player in ipairs(players) do
      local player_name = player:get_player_name()
      if dragged_by == player_name then
        player:set_physics_override({ speed = 1, jump = 1, speed_fast = 1 })
        players_dragging[player_name] = false
      end
    end
  end
end

---get player from name
---@param player_name string
---@return table|nil
local function getPlayer(player_name)
  local players = core.get_connected_players()
  if #players > 0 then
    for _, player in pairs(players) do
      local p_name = player:get_player_name()
      if p_name == player_name then
        return player
      end
    end
  end
  return nil
end

local global_collected = {} -- keycode,visted_area etc..

---@class collection
---@field name string

---@class player_collection
---@field player_name string
---@field collection collection{}

---@type player_collection{}
local players_collections

---comment
---@param player_name string
---@return player_collection
local function getPlayerCollection(player_name)
  ---@type player_collection
  local p_c

  -- inti players_collections if needed
  if players_collections == nil then
    players_collections = {}
  end

  if #players_collections >= 1 then
    for index, value in ipairs(players_collections) do
      if value.player_name == player_name then
        p_c = value
      end
    end
  end
  if p_c == nil then
    p_c = { player_name = player_name, collection = {} }
    table.insert(players_collections, p_c)
  end
  return p_c
end

---comment
---@param player_name string
---@param item_name table
local function addToPlayerCollection(player_name, item_name)
  local player_c = getPlayerCollection(player_name)
  table.insert(player_c.collection, { name = item_name })
  for key, value in ipairs(players_collections) do
    if value.player_name == player_c.player_name then
      value = player_c
    end
  end
end

---comment
---@param player_name string
---@param item_name string
local function removeFromPlayerCollection(player_name, item_name)
  -- ---@type collection
  -- local new_collection = { name = item_name.name, id = 10 }

  local player_c = getPlayerCollection(player_name)
  for index, value in ipairs(player_c.collection) do
    if value.name == item_name then
      -- if value.id == collection.id then
      table.remove(player_c.collection, index)
      -- end
    end
  end
  for key, value in ipairs(players_collections) do
    if value.player_name == player_c.player_name then
      value = player_c
    end
  end
end

---comment
---@param player_name string
---@param name_of_collection string
local function playerHasCollection(player_name, name_of_collection)
  ---@type collection
  -- local new_collection = { name = name_of_collection.name, id = 10 }
  -- local player_c = getPlayerCollection(player_name)
  if players_collections == nil or #players_collections <= 0 then
    return
  end
  ---@param player_c player_collection
  for key, player_c in ipairs(players_collections) do
    if player_c.player_name == player_name then
      if player_c.collection == nil or #player_c.collection <= 0 then
        return false
      end
      ---@param coll collection
      for index, coll in ipairs(player_c.collection) do
        if coll.name == name_of_collection then
          -- core.log("pass?" .. coll.name)
          return true
        end
      end
    end
  end
  return false
end

---comment
---@param name string
---@param model_type string "mesh"|"node"
---@param model string model_name or mod_name:node
---@param texture string
---@param shape shape
---@param weight number
function tg_interactions.register_draggable(name, model_type, model, texture, shape, weight)
  local function drop(self)
    self.object:get_luaentity().physical = true
    self.object:get_luaentity()._being_dragged = false
    local dragged_by = self.object:get_luaentity()._dragged_by
    restorePlayerMovement(dragged_by)

    removeFromPlayerCollection(dragged_by, self.object:get_luaentity().name)

    -- core.log("wait is this not running??")
    -- local player = getPlayer(dragged_by)
    -- if player ~= nil then
    --   local object_name = self.object:get_luaentity().name
    --   -- player:get_properties()._dragging = object_name
    --   -- core.log("lua: "..dump(player:get_properties()))
    --   core.log("player dragging: "..dump(player._dragging))
    --   core.log("object name: "..object_name)
    --   core.log("object: "..dump(self.object:get_luaentity().id))
    -- end
    self.object:get_luaentity()._dragged_by = ""
    players_dragging[dragged_by] = false
  end
  local popup_text = { "[ drag ]", "[ let go ]" }
  local def = {
    _being_dragged = false,
    _dragged_by = "",

    _acc = 0,
    _weight = weight,
    _speed = 3, -- speed should change depending on how far the player is
    _popup_msg = popup_text[1],
    _prev_sound = nil,
    _sound_tick = 0,
    _interactable = 1,
    on_step = function(self, dtime, moveresult)
      local velocity = self.object:get_velocity()
      self.object:set_velocity(vector.add(velocity, vector.new(0, gravity, 0)))
      velocity = self.object:get_velocity()

      -- usage in on_step
      self.object:set_velocity(apply_damping(velocity, 3.0, dtime))

      -- self.object:set_velocity(vector.subtract(velocity,gravity))
      -- debug("I do be stepping")


      -- play sound while being dragged
      local tick = self.object:get_luaentity()._sound_tick
      tick = tick + 1
      self.object:get_luaentity()._sound_tick = tick
      if tick >= 35 then
        self.object:get_luaentity()._sound_tick = 0

        local vel = self.object:get_velocity()
        if vel.x ~= 0 and vel.z ~= 0 then
          -- self.object:move_to(vector.new(player_pos.x,cur_pos.y,player_pos.z), true)
          -- self.object:move_to(tg_main.lerp(cur_pos, mid_point, speed), true)
          -- self.object:add_velocity(vector.subtract(vector.new(mid_point.x, cur_pos.y, mid_point.z), cur_pos))

          local cur_sound = self.object:get_luaentity()._prev_sound
          if cur_sound ~= nil then
            -- core.sound_stop(cur_sound)
            core.sound_fade(cur_sound, 120, 0)
          end
          local pitch = 1
          if weight >= 3 then
            pitch = 0.8
          elseif weight <= 2 then
            pitch = 1.4
          end
          local playing_sound = core.sound_play({ name = "tg_interactions_drag" }, {
            gain = 1.0,    -- default
            fade = 0.0,    -- default
            pitch = pitch, -- 1.0, -- default
          })
          self.object:get_luaentity()._prev_sound = playing_sound
        end
      end

      local cur_pos = self.object:get_pos()
      if self.object:get_luaentity()._being_dragged == false then
        self.object:get_luaentity()._popup_msg = popup_text[1]
        -- self.object:set_velocity(vector.new(0, gravity, 0)) -- come to a complete stop when player lets go

        -- --push way
        -- local entites = core.get_objects_inside_radius(cur_pos, 0.9)
        -- local pushed = false
        -- for index, value in ipairs(entites) do
        --   local entity_pos = value:get_pos()
        --   if cur_pos ~= entity_pos then
        --     local dirX = entity_pos.x - cur_pos.x
        --     local dirY = entity_pos.y - cur_pos.y
        --     -- Calculate angle in radians
        --     local angle = math.atan2(dirY, dirX)
        --     self.object:set_yaw(angle)
        --     self.object:set_velocity(vector.subtract(cur_pos, vector.new(entity_pos.x, cur_pos.y, entity_pos.z)))
        --     pushed = true
        --   end
        -- end
        -- if pushed == false then
        -- end
      else
        -- if _being_dragged get all objects within radius, if player
        -- and player name is equal to dragger.. get closer
        -- if no players are around then no drag.
        -- debug("i am getting dragged")
        local max_distance = 2
        local entites = core.get_objects_inside_radius(cur_pos, max_distance)
        local found_player = false
        for index, value in ipairs(entites) do
          if value:is_player() then
            -- debug("we have found a player")
            local player_name = value:get_player_name()
            if player_name == self.object:get_luaentity()._dragged_by then
              found_player = true
              self.object:get_luaentity().physical = false
              local player_pos = value:get_pos()
              local player_distance = tg_main.distance(player_pos, cur_pos)
              if player_distance > 1.2 then
                local new_pos = vector.add(player_pos, vector.new(0, 1, 0))
                local dirX = player_pos.x - cur_pos.x
                local dirY = player_pos.y - cur_pos.y
                -- Calculate angle in radians
                local angle = math.atan2(dirY, dirX)
                self.object:set_yaw(angle)

                local mid_point = tg_main.calculateMidpoint(player_pos, cur_pos)
                local obj_speed = self.object:get_luaentity()._speed
                -- local speed = (self.object:get_luaentity()._speed * player_distance) * dtime
                local speed = math.min(obj_speed * dtime, 1)
                -- self.object:move_to(tg_main.lerp(cur_pos, mid_point, speed), true)
                self.object:set_velocity(vector.subtract(vector.new(player_pos.x, cur_pos.y, player_pos.z), cur_pos))
              end
            else
            end
          end
        end
        if #entites <= 1 or found_player == false then
          -- debug("dragger is gone")
          drop(self)
        end
      end
      -- debug("dragger: " .. self.object:get_luaentity()._dragged_by)
    end,
    on_rightclick = function(self, clicker)
      local player_name = clicker:get_player_name()
      local dragged_by = self.object:get_luaentity()._dragged_by

      -- already holding, drop.
      if players_dragging[player_name] == true then
        drop(self)
        return
      end

      -- prevent other player from interacting
      if player_name ~= dragged_by and dragged_by ~= "" then
        return
      end

      -- not sure what this is doing??
      if clicker._dragging == true then
        -- do nothing
        return
      end

      local cur_value = self._being_dragged
      self.object:get_luaentity()._being_dragged = not cur_value
      self.object:get_luaentity()._dragged_by = clicker:get_player_name()
      local obj_weight = self.object:get_luaentity()._weight
      clicker:set_physics_override({ speed = 1.1 / obj_weight, jump = 0.5, speed_fast = 2.1 / obj_weight })
      if cur_value == true then
        self.object:get_luaentity()._popup_msg = popup_text[1]
        drop(self)
        clicker:set_physics_override({ speed = 1, jump = 1, speed_fast = 1 })
        players_dragging[player_name] = false
      else
        self.object:get_luaentity()._popup_msg = popup_text[2]
        players_dragging[player_name] = true

        addToPlayerCollection(player_name, self.object:get_luaentity().name)
      end
      -- core.log("collections" .. dump(players_collections))
    end,
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
      local player_pos = puncher:get_pos()
      local cur_pos = self.object:get_pos()
      if puncher:get_player_control().sneak == true then
        if tg_main.dev_mode == true then
          self.object:remove()
          puncher:set_physics_override({ speed = 1, jump = 1, speed_fast = 1 })
        end
      else
        -- self.object:set_velocity(vector.add(cur_pos, vector.new(player_pos.x, cur_pos.y+0.5, player_pos.z)))
        local dirX = player_pos.x - cur_pos.x
        local dirY = player_pos.y - cur_pos.y
        -- Calculate angle in radians
        local angle = math.atan2(dirY, dirX)
        self.object:set_yaw(angle)
        local speed = 3/ (1+weight)
        local vel = vector.multiply(vector.add(dir,vector.new(0,cur_pos.y+0.1,0)),speed)
        self.object:set_velocity(vel)
      end
    end,
  }
  if model_type == "mesh" then
    def.initial_properties = {
      visual = "mesh",
      mesh = model,
      visual_size = { x = 10, y = 10, z = 10 },
      -- visual = "wielditem",
      -- wield_item = "tg_furniture:oak_chair",
      -- visual_size = { x = 0.65, y = 0.65, z = 0.65 }, -- i guess this is the size for drawtype node
      textures = { texture },
      physical = true,
      -- collide_with_objects = true,
      collisionbox = shape,
      selectionbox = shape,
      stepheight = 0.6, -- this is not working
    }
  elseif model_type == "node" then
    def.initial_properties = {
      visual = "wielditem",
      wield_item = model,
      visual_size = { x = 0.65, y = 0.65, z = 0.65 }, -- i guess this is the size for drawtype node
      textures = { texture },
      physical = true,
      -- collide_with_objects = true,
      collisionbox = shape,
      selectionbox = shape,
      stepheight = 0.6, -- this is not working
    }
  end
  core.register_entity(mod_name .. ":draggable_" .. name, def)
end

---comment
---@param name any
---@param model_type any
---@param model any
---@param texture any
---@param shape any
---@param popup_text table
---@param cmd table
-- function tg_interactions.register_interactable(name, model_type,model,texture,shape,popup_text)
function tg_interactions.register_interactable(name, model_type, model, texture, shape, params)
  local def = {
    _interactable = 1,
    on_step = function(self, dtime, moveresult)
    end,
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
      if puncher:get_player_control().sneak == true then
        if tg_main.dev_mode == true then
          self.object:remove()
        end
      end
    end,
  }
  if params ~= nil then
    if #params >= 0 then
      for index, value in pairs(params) do
        def[index] = value
      end
    end
  end
  if model_type == "mesh" then
    def.initial_properties = {
      visual = "mesh",
      mesh = model,
      visual_size = { x = 10, y = 10, z = 10 },
      -- visual = "wielditem",
      -- wield_item = "tg_furniture:oak_chair",
      -- visual_size = { x = 0.65, y = 0.65, z = 0.65 }, -- i guess this is the size for drawtype node
      textures = { texture },
      physical = true,
      -- collide_with_objects = true,
      collisionbox = shape,
      selectionbox = shape,
    }
  elseif model_type == "node" then
    def.initial_properties = {
      visual = "wielditem",
      wield_item = model,
      visual_size = { x = 0.65, y = 0.65, z = 0.65 }, -- i guess this is the size for drawtype node
      textures = { texture },
      physical = true,
      -- collide_with_objects = true,
      collisionbox = shape,
      selectionbox = shape,
    }
  elseif model_type == "none" then
    def.initial_properties = {
      visual = "sprite",
      textures = { texture },
      use_texture_alpha = true,
      physical = false,
      collisionbox = shape,
      selectionbox = shape,
    }
  end
  core.register_entity(mod_name .. ":" .. name, def)
end

tg_interactions.register_draggable("chair", "node", "tg_furniture:oak_chair", "tg_ndoes_steel_enclosure.png",
  tg_nodes["shapes"].slim_box, 2)
tg_interactions.register_draggable("pipes", "mesh", "tubes.glb", "tubes.png", tg_nodes["shapes"].slab, 4)
tg_interactions.register_draggable("power_core", "mesh", "power_core.glb", "power_core.png", tg_nodes["shapes"].slab, 4)

tg_interactions.register_interactable("power_switch", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.slim_box,
  {
    _popup_msg = "[ switch on power ]",
    on_rightclick = function(self, clicker)
      tg_power.togglePower()
      if tg_power.power == true then
        self.object:get_luaentity()._popup_msg = "[ switch on power ]"
      else
        self.object:get_luaentity()._popup_msg = "[ switch off power ]"
      end
    end,
  }
)

tg_interactions.register_interactable("random_note", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.slim_box,
  {
    _popup_msg = "[ note ]",
    on_rightclick = function(self, clicker)
      core.chat_send_all("NOTE READS: \"took me a few attemps to get this note up here..\"")
    end,
  })
tg_interactions.register_interactable("locker_empty", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.slim_box,
  {
    _popup_msg = "[ search locker ]",
    on_rightclick = function(self, clicker)
      core.chat_send_all("..this locker is empty")
      local playing_sound = core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      if tg_main.dev_mode == false then
        self.object:remove()
      else
        -- core.log("after first interaction this will be removed in normal gameplay.")
      end
    end,
  })
tg_interactions.register_interactable("locker_suit", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.slim_box,
  {
    _popup_msg = "[ search locker ]",
    on_rightclick = function(self, clicker)
      core.chat_send_all("hmm, a radiation suit. i should slip this on.")
      local playing_sound = core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      if tg_main.dev_mode == false then
        self.object:remove()
      else
        -- core.log("after first interaction this will be removed in normal gameplay.")
      end
    end,
  })
tg_interactions.register_interactable("tape", "mesh", "tape.glb", "tape.png", shapes.slab,
  {
    _popup_msg = "[ pickup tape ]",
    on_rightclick = function(self, clicker)
      core.chat_send_all("this should come in handy.")
      local playing_sound = core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      if tg_main.dev_mode == false then
        self.object:remove()
      else
        -- core.log("after first interaction this will be removed in normal gameplay.")
      end
    end,
  })

tg_interactions.register_interactable("door", "mesh", "door.glb", "door.png", shapes.door,
  {
    _interactable = 0,
    -- _popup_msg = "[ open door ]",
    on_step = function(self, dtime, moveresult)
      local velocity = self.object:get_velocity()
      self.object:set_velocity(vector.add(velocity, vector.new(0, gravity, 0)))
      velocity = self.object:get_velocity()
    end,
    -- on_rightclick = function(self, clicker)
    --   core.chat_send_all("this should be opening")
    --   local playing_sound = core.sound_play({ name = "tg_paper_footstep" }, {
    --     gain = 1.0,              -- default
    --     fade = 100.0,              -- default
    --     pitch = 1.8,             -- 1.0, -- default
    --   })
    -- end,
  })
-- tg_interactions.register_interactable("power_switch","none","","tg_nodes_misc.png^[sheet:16x16:0,6",shapes.slim_box,{"[ switch on power ]","[ switch off power ]"}, tg_power.power)

tg_interactions.register_interactable("power_gen", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.box,
  {
    _interactable = 1,
    -- _popup_msg = "[ open door ]",
    on_step = function(self, dtime, moveresult)
      local item_name = mod_name .. ":draggable_power_core"
      local cur_pos = self.object:get_pos()
      local max_distance = 2
      local near_by = core.get_objects_inside_radius(cur_pos, max_distance)
      local has_core = false
      for index, value in ipairs(near_by) do
        if value:is_player() then
          local player_name = value:get_player_name()
          local has_power_source = playerHasCollection(player_name, mod_name .. ":draggable_power_core")
          -- core.log("has source? " .. dump(has_power_source))
          if has_power_source == true then
            self.object:get_luaentity()._popup_msg = "[ insert power core ]"
          else
            self.object:get_luaentity()._popup_msg = "[ needs power core ]"
          end
        else
          if value:get_luaentity().name == item_name then
            has_core = true
          end
        end
      end
      if has_core == true then
        tg_power.setPowerCore(true)
        self.object:get_luaentity()._popup_msg = "[ remove power core ]"
      else
        tg_power.setPowerCore(false)
        self.object:get_luaentity()._popup_msg = "[ needs power core ]"
      end
    end,
    on_rightclick = function(self, clicker)
      local item_name = mod_name .. ":draggable_power_core"
      local player_name = clicker:get_player_name()
      local has_power_source = playerHasCollection(player_name, item_name)
      if has_power_source == true then
        removeFromPlayerCollection(player_name, item_name)
        local cur_pos = self.object:get_pos()
        local max_distance = 3
        local entites = core.get_objects_inside_radius(cur_pos, max_distance)
        local found_player = false
        for index, value in ipairs(entites) do
          if not value:is_player() then
            if value:get_luaentity().name == item_name then
              -- value:get_luaentity().drop()
              value:move_to(cur_pos)
              return
            end
          end
        end
      end
    end,
    --   core.chat_send_all("this should be opening")
    --   local playing_sound = core.sound_play({ name = "tg_paper_footstep" }, {
    --     gain = 1.0,              -- default
    --     fade = 100.0,              -- default
    --     pitch = 1.8,             -- 1.0, -- default
    --   })
    -- end,
  })




----------------
-- HUD POPUP
----------------

---@class player_huds
---@field player_name string
---@field huds table

---@class all_huds
---@field player_huds table

---@type table
local all_huds = {}

tg_interactions["huds"] = all_huds

local function getPlayerHuds(player_name)
  ---@type player_huds
  local players_hud
  if all_huds ~= nil then
    for _, value in ipairs(all_huds) do
      if value.player_name == player_name then
        players_hud = value
      end
    end
  end
  if players_hud == nil then
    -- core.log("player's huds not found")
    -- player does not have a hud
    -- need to create the hud element if the player needs it
    -- note that we cannot change the hud if there is no hud to start with
    players_hud = { player_name = player_name, huds = {} }
  end
  if all_huds == nil then
    all_huds = {}
  end
  table.insert(all_huds, players_hud)
  return players_hud
end

-- player hover over interactables
core.register_globalstep(function(dtime)
  local msg = {
    type = "waypoint",
    name = "",
    precision = 0,
    scale = { x = 80, y = 80 },
    number = 0xFFFFFF,
    z_index = -300,
    alignment = 0,
    -- text = "where are you? i do not see you..",
    world_pos = { x = 0, y = 1, z = 0 },
  }

  local players = core.get_connected_players()
  if #players > 0 then
    for _, player in ipairs(players) do
      local eye_height = player:get_properties().eye_height
      local player_look_dir = player:get_look_dir()
      local pos = player:get_pos():add(player_look_dir)
      local player_pos = { x = pos.x, y = pos.y + eye_height, z = pos.z }
      local new_pos = player:get_look_dir():multiply(tg_main.reach-1):add(player_pos)
      local raycast_result = core.raycast(player_pos, new_pos, true, false):next()

      -- core.log("so what is this: " .. dump(raycast_result))
      local hud_pos = nil
      -- local popup_msg = player:hud_add(msg)

      -- need to know to remove or change the current hud at all times
      local player_name = player:get_player_name()
      local players_hud = nil
      players_hud = getPlayerHuds(player_name)
      -- core.log("does the player have huds? "..dump(players_hud.huds))

      for index, value in pairs(players_hud.huds) do
        -- core.log("wtf is this:"..value)
        player:hud_remove(value)
      end
      players_hud.huds = {}
      --- in radius --
      local within_radius = core.get_objects_inside_radius(player_pos, tg_interactions.popup_radius)
      local interacble_indicator = {
        -- type = "waypoint",
        -- name = "o",
        type = "image_waypoint",
        text = "tg_nodes_misc.png^[sheet:16x16:0,5",
        -- precision = 0,
        scale = { x = 2, y = 2 },
        number = 0xFFFFFF,
        z_index = -300,
        alignment = 0,
        -- text = "where are you? i do not see you..",
        world_pos = { x = 0, y = 1, z = 0 },
      }
      for index, value in ipairs(within_radius) do
        -- TODO(): check if "interactable"
        if not value:is_player() then
          if value:get_luaentity()._interactable == 1 then
            local obj_pos = value:get_pos()
            interacble_indicator["world_pos"] = obj_pos
            local indicator = player:hud_add(interacble_indicator)
            table.insert(players_hud.huds, indicator)
            -- core.log("where am i? " .. dump())
          end
        end
      end
      --- in radius ---
      if raycast_result ~= nil and raycast_result.type == "object" then
        -- core.log("who dis: "..dump(raycast_result.ref:get_luaentity()))
        if raycast_result.ref:get_luaentity() == nil then
          return
        end
        local hover_popup = raycast_result.ref:get_luaentity()._popup_msg
        hud_pos = vector.add(raycast_result.ref:get_pos(), vector.new(0, 0.1, 0))

        -- msg["text"] = hover_popup
        -- msg["world_pos"] = hud_pos

        msg["name"] = hover_popup
        msg["world_pos"] = hud_pos
        local new_hud = player:hud_add(msg)
        table.insert(players_hud.huds, new_hud)
        -- tg_main.debug_particle(hud_pos, "#fff", 2, 0, 2)

        -- core.log("who dis: " .. hover_popup)
        -- core.log("what is the pos? "..dump(hud_pos))
      else
        -- player:hud_remove(popup_msg)
      end
    end
  end
end)
