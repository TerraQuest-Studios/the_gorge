local mod_name = core.get_current_modname()

local shapes = tg_nodes["shapes"]

tg_interactions = {}

-- NOTE: for something to get the "interactable" popup
-- it have "_interactable = 1"

-- local reach = 3.5 -- things within will show interacable/ popup on hover
tg_interactions.popup_radius = 3.5

local gravity = -0.9

local function on_activate(self, staticdata, dtime_s)
  local data = core.deserialize(staticdata)
  if data then
    for key, val in pairs(data) do
      self[key] = val
    end
  end
end

local function get_staticdata(self)
  local data = {}
  if self._the_static_data ~= nil then
    for i, key in pairs(self._the_static_data) do
      if key then
        if core.is_player(self[key]) or (type(self[key]) == "table" and self[key].object) then
          error("NO, YOU CANNOT SERIALIZE AN OBJECT!!! from: " .. key)
        end
        data[key] = self[key]
      end
    end
  end
  return core.serialize(data)
end


--[[ local function debug(msg)
  core.log("[entity]: " .. msg)
end
 ]]
---comment
---@param object table
---@param off_on boolean|nil
--[[ local function signalToggle(object, off_on)
  local cur_toggle = object:get_luaentity()._toggleable
  local toggle_on = off_on or not cur_toggle -- set or bit flip

  if object:get_luaentity()._toggleable ~= nil then
    if object:get_luaentity()._toggleable == 1 then
      if object:get_luaentity()._state == 1 then
        core.log("state set 0")
        object:get_luaentity()._state = 0
      end
    else
      if object:get_luaentity()._state == 0 then
        core.log("state set 1")
        object:get_luaentity()._state = 1
      end
    end
  end
  return object
end ]]

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
--[[ local function getPlayer(player_name)
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
end ]]

--local global_collected = {} -- keycode,visted_area etc..

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
  --[[ for key, value in ipairs(players_collections) do
    if value.player_name == player_c.player_name then
      value = player_c
    end
  end ]]
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
  --[[ for key, value in ipairs(players_collections) do
    if value.player_name == player_c.player_name then
      value = player_c
    end
  end ]]
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
  local popup_text = { "[ RMB: drag ]\n[ LMB: push ]", "[ RMB/LMB: let go ]" }
  local def = {
    _dragging = false,
    _dragger = "",

    _acc = 0,
    _weight = weight or 3,
    _speed = 3, -- speed should change depending on how far the player is
    _popup_msg = popup_text[1],
    _prev_sound = nil,
    _sound_tick = 0,
    _sound_duration = 0.81,
    _interactable = 1,
    _lossdistance = 2, -- distance between us and player needed to drop us
    on_step = function(self, dtime, moveresult)
      local cur_pos = self.object:get_pos()
      local velocity = self.object:get_velocity()
      self.object:set_velocity(vector.add(velocity, vector.new(0, gravity, 0)))
      velocity = self.object:get_velocity()

      -- usage in on_step
      self.object:set_velocity(apply_damping(velocity, 3.0, dtime))

      -- self.object:set_velocity(vector.subtract(velocity,gravity))
      -- debug("I do be stepping")

      -- not being dragged anymore
      if not self._dragging then return end

      -- play sound while being dragged
      local tick = self._sound_tick
      tick = tick + dtime
      if tick >= self._sound_duration then
        tick = 0
        local vel = self.object:get_velocity()
        if vel.x ~= 0 and vel.z ~= 0 then
          -- self.object:move_to(vector.new(player_pos.x,cur_pos.y,player_pos.z), true)
          -- self.object:move_to(tg_main.lerp(cur_pos, mid_point, speed), true)
          -- self.object:add_velocity(vector.subtract(vector.new(mid_point.x, cur_pos.y, mid_point.z), cur_pos))

          local dsound = self._prev_sound -- drag sound
          if dsound ~= nil then
            -- core.sound_stop(cur_sound)
            core.sound_fade(dsound, 120, 0)
          end
          self._prev_sound = core.sound_play("tg_interactions_drag", {
              pos = cur_pos,
              gain = 1,
              pitch = 1 * self._weightfluence
          })
        end
      end
      self._sound_tick = tick -- update sound tick
      -- if _dragging get all objects within radius, if player
      -- and player name is equal to dragger.. get closer
      -- if no players are around then no drag.
      -- debug("i am getting dragged")
      local max_distance = self._lossdistance
      local entities = core.get_objects_inside_radius(cur_pos, max_distance)
      if #entities < 2 then return self:_drop() end -- nothing around us (1 will be us)
      local found_player = false
      for _, obj in ipairs(entities) do
        local pname = core.is_player(obj) and obj:get_player_name()
        -- found a player! let's see if they're who's dragging us
        if pname then
          if pname == self._dragger then
            found_player = true
            self.physical = false
            local player_pos = obj:get_pos()
            local player_distance = tg_main.distance(player_pos, cur_pos)
            if player_distance > 1.2 then
              --local new_pos = vector.add(player_pos, vector.new(0, 1, 0))
              local dirX = player_pos.x - cur_pos.x
              local dirY = player_pos.y - cur_pos.y
              -- Calculate angle in radians
              local angle = math.atan2(dirY, dirX)
              self.object:set_yaw(angle)

              --local mid_point = tg_main.calculateMidpoint(player_pos, cur_pos)
              --local obj_speed = self._speed
              -- local speed = (self._speed * player_distance) * dtime
              --local speed = math.min(obj_speed * dtime, 1)
              -- self.object:move_to(tg_main.lerp(cur_pos, mid_point, speed), true)
              self.object:set_velocity(vector.subtract(vector.new(player_pos.x, cur_pos.y, player_pos.z), cur_pos))
            end
            --else
          end
        end
      end
      -- not being dragged by anything in range
      if not found_player then return self:_drop() end
      -- debug("dragger: " .. self._dragger)
    end,
    on_rightclick = function(self, clicker)
      if not core.is_player(clicker) then return end
      local pname = clicker:get_player_name() -- player name
      local dragger = self._dragger
      -- already holding, drop
      if players_dragging[pname] then return self:_drop() end

      -- prevent other player from interacting
      if pname ~= dragger and dragger ~= "" then return end

      -- TPH: commented out because I don't see the point of doing this?
      --local obj_pos = self.object:get_pos()
      --local player_pos = clicker:get_pos()
      --clicker:move_to(vector.new(obj_pos.x, player_pos.y, obj_pos.z), { continuous = true })

      local dragging = self._dragging
      -- never appears to be set to false, but don't wanna go against whatever SURV is doing here lol
      self._dragging = not dragging
      self._dragger = pname
      local obj_weight = self._weight
      clicker:set_physics_override({ speed = 1.1 / obj_weight, jump = 0.5, speed_fast = 2.1 / obj_weight })
      -- like never actually happens but sure
      if dragging then
        self._popup_msg = popup_text[1]
        self:_drop()
      -- now dragging
      else
        self._popup_msg = popup_text[2]
        players_dragging[pname] = true

        addToPlayerCollection(pname, self.name)
        -- affects sound pitch (recalculate in case of change to weight)
        self._weightfluence = 3/self._weight -- weight influence
        self._sound_duration = 0.81/self._weightfluence
      end
      -- core.log("collections" .. dump(players_collections))
    end,
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
      if not core.is_player(puncher) then return end
      local player_pos = puncher:get_pos()
      local cur_pos = self.object:get_pos()
      if puncher:get_player_control().sneak then
        if tg_main.dev_mode == true then
          self.object:remove()
          puncher:set_physics_override({ speed = 1, jump = 1, speed_fast = 1 })
        end
      -- punching away
      else
        if self._dragger then self:_drop() end -- drop when punched
        -- self.object:set_velocity(vector.add(cur_pos, vector.new(player_pos.x, cur_pos.y+0.5, player_pos.z)))
        local dirX = player_pos.x - cur_pos.x
        local dirY = player_pos.y - cur_pos.y
        -- Calculate angle in radians
        local angle = math.atan2(dirY, dirX)
        self.object:set_yaw(angle)
        local speed = 3 / (1 + weight)
        local vel = vector.multiply(vector.add(dir, vector.new(0, cur_pos.y + 0.1, 0)), speed)
        self.object:set_velocity(vel)
        -- do dragging sound
        local dsound = self._prev_sound -- drag sound
        if dsound ~= nil then
          -- core.sound_stop(cur_sound)
          core.sound_fade(dsound, 0.3, 0)
        end
        self._prev_sound = core.sound_play("tg_interactions_drag", {
          pos = cur_pos,
          gain = 1,
          pitch = 1 * self._weightfluence
        })
      end
    end,
    -- for when player stops dragging us
    _drop = function(self)
      self.physical = true
      self._dragging = false
      self._popup_msg = popup_text[1] -- reset message
      -- whom is dragging us
      local dragger = self._dragger
      restorePlayerMovement(dragger)
      removeFromPlayerCollection(dragger, self.name)

      self._dragger = ""
      players_dragging[dragger] = nil
    end
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
  -- affects sound pitch
  def._weightfluence = 3/def._weight -- weight influence
  def._sound_duration = 0.81/def._weightfluence
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

tg_interactions.register_interactable("power_switch", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.centerd_box,
  {
    _popup_msg = "[ switch on power ]",
    on_rightclick = function(self, clicker)
      --[[ local playing_sound = ]]
      core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      tg_power.togglePower()
      if tg_power.power == true then
        self.object:get_luaentity()._popup_msg = "[ switch on power ]"
      else
        self.object:get_luaentity()._popup_msg = "[ switch off power ]"
      end
    end,
  }
)

---comment
---@param pos any
---@param chain any
---@param distance any
---@param signal number|nil
local function sendSignal(pos, chain, distance, signal)
  local near_by = core.get_objects_inside_radius(pos, distance)
  for index, value in pairs(near_by) do
    local obj_pos = value:get_pos()
    if obj_pos ~= pos then
      -- core.log("we are not the same")
      if not value:is_player() then
        -- core.log("not the player")
        -- luacheck: ignore
        if chain[vector.to_string(obj_pos)] == true then
          -- do nothing
          -- core.log("already searched")
        else
          chain[vector.to_string(obj_pos)] = true
          if string.find(value:get_luaentity().name, "relay") then
            -- core.log("relay")
            sendSignal(obj_pos, chain, distance, signal)
            -- search again
          elseif string.find(value:get_luaentity().name, "sensor_power") then
            if value:get_luaentity()._state == 0 then
              -- core.log("power needed")
              return
            else
              -- core.log("we have power, continue")
              sendSignal(obj_pos, chain, distance, signal)
            end
          elseif string.find(value:get_luaentity().name, "nrelay") then
            core.log("n relay found")
            if signal ~= nil then
              sendSignal(obj_pos, chain, distance, (signal * -1))
            else
              sendSignal(obj_pos, chain, distance, signal)
            end
          elseif string.find(value:get_luaentity().name, "socket") then
            -- core.log("socket!!!!")
            local find_reciver = core.get_objects_inside_radius(obj_pos, distance * 2)
            for r_i, r_v in pairs(find_reciver) do
              local r_pos = r_v:get_pos()
              if r_pos ~= obj_pos then
                if not r_v:is_player() then
                  if r_v:get_luaentity()._toggleable ~= nil then
                    if signal ~= nil then
                      -- r_v:get_luaentity()._state = signal
                      -- core.log("should be sending: " .. signal)
                      r_v:get_luaentity()._toggle_state(r_v, signal)
                      -- return
                    else
                      r_v:get_luaentity()._toggle_state(r_v)
                    end
                    -- core.log("toggleable found")
                    -- core.log("toggle: " .. dump(r_v:get_luaentity()._toggleable))
                    -- local state = r_v:get_luaentity()._state
                    -- if state == 0 then
                    --   r_v:get_luaentity()._state = 1
                    -- else
                    --   r_v:get_luaentity()._state = 0
                    -- end
                    -- core.log("toggle: " .. dump(r_v:get_luaentity()._toggleable))
                  end
                end
              end
            end
          else
            -- core.log("wrong: " .. value:get_luaentity().name)
          end

          -- local toggleable = value:get_luaentity()._toggleable
          -- if toggleable ~= nil then
          --   core.log("ok found it")
          --   if toggleable == 1 then
          --     toggleable = 0
          --   else
          --     toggleable = 1
          --   end
          --   value:get_luaentity()._toggleable = toggleable
          -- else
          --   core.log("this cant be toggled")
          -- end
        end
      end
    end
  end
end

tg_interactions.register_interactable("button", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.centerd_box,
  {
    _popup_msg = "[ button ]",
    on_rightclick = function(self, clicker)
      --[[ local playing_sound =  ]]
      core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      local chain = {}
      local pos = self.object:get_pos()
      -- if tg_power.power == true then
      --   self.object:get_luaentity()._popup_msg = "[ switch on power ]"
      -- else
      --   self.object:get_luaentity()._popup_msg = "[ switch off power ]"
      -- end
      chain[vector.to_string(pos)] = true
      if tg_main.dev_mode == true then
        core.log("button pressed")
      end
      sendSignal(pos, chain, 1.2)
    end,
  }
)

tg_interactions.register_interactable("switch", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.centerd_box,
  {
    _popup_msg = "[ toggle switch ]",
    _state = 0,
    _the_static_data = {
      "_state"
    },
    get_staticdata = function(self)
      return get_staticdata(self)
    end,
    _updatePopup = function(self)
      local state = self.object:get_luaentity()._state
      if state == 1 then
        self.object:get_luaentity()._popup_msg = "[ switch on ]"
      else
        self.object:get_luaentity()._popup_msg = "[ switch off ]"
      end
    end,
    on_activate = function(self, staticdata, dtime_s)
      on_activate(self, staticdata, dtime_s)
      self.object:get_luaentity()._updatePopup(self)
    end,
    on_rightclick = function(self, clicker)
      --[[ local playing_sound =  ]]
      core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      local chain = {}
      local pos = self.object:get_pos()
      -- if tg_power.power == true then
      --   self.object:get_luaentity()._popup_msg = "[ switch on power ]"
      -- else
      --   self.object:get_luaentity()._popup_msg = "[ switch off power ]"
      -- end
      chain[vector.to_string(pos)] = true
      if tg_main.dev_mode == true then
        core.log("switch pressed")
      end
      local state = self.object:get_luaentity()._state
      if state == 0 then
        state = 1
      else
        state = 0
      end
      self.object:get_luaentity()._state = state
      self.object:get_luaentity()._updatePopup(self)
      sendSignal(pos, chain, 1.2, state)
    end,
  }
)

local player_end_disclaimer = false
local discalimer_messages = {
  [[Dev note: ]],
  [[This is all that we currently have.. ]],
  [[More is to come.]]
}

tg_interactions.register_interactable("sensor_disclaimer", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.centerd_box,
  {
    _popup_msg = "[ dev disclaimer ]",
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:0,7",
    _popup_hidden = true,
    pointable = false,
    on_step = function(self, dtime, moveresult)
      local cur_pos = self.object:get_pos()
      local max_distance = 6
      local near_by = core.get_objects_inside_radius(cur_pos, max_distance)
      if player_end_disclaimer == false then
        for index, player in ipairs(near_by) do
          if player:is_player() then
            player_end_disclaimer = true
            if tg_main.dev_mode == false then
              tg_cut_scenes.run(player, discalimer_messages)
            else
              core.log("showing disclaimer cut scene to player. (exluded in dev_mode/buildmode)\n" ..
                table.concat(discalimer_messages))
            end
          end
        end
      end
    end,
  }
)

tg_interactions.register_interactable("sensor", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.thicker_box,
  {
    pointable = false,
    _popup_msg = "[ player sensor ]",
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:4,5",
    _popup_hidden = true,
    _toggle = 0,
    _player_within = "false",
    on_step = function(self, dtime, moveresult)
      local pos = self.object:get_pos()
      local chain = {}
      local max_distance = 3.5
      local near_by = core.get_objects_inside_radius(pos, max_distance)
      local player_within = false --buffer to work when at least 1 player
      if tg_power.getPower() == false then
        return
      end
      for index, player in ipairs(near_by) do
        if player:is_player() then
          -- core.log("player found")
          player_within = true
          if self.object:get_luaentity()._player_within == "false" then
            core.sound_play({ name = "tg_sensor" }, {
              gain = 0.3,   -- default
              fade = 100.0, -- default
              pitch = 1.0,  -- 1.0, -- default
            })
            self.object:get_luaentity()._player_within = "true"
            -- core.log("found player, toggle on")
            sendSignal(pos, chain, 1.2, 1)
            -- self.object:get_luaentity()._player_within = "false"
            -- core.log("found player, toggle off")
            -- player_within = false
            -- find(pos, chain, 1.2)
          end
        end
      end
      if player_within == false then
        -- core.log("no player found")
        if self.object:get_luaentity()._player_within == "true" then
          -- core.sound_play({ name = "tg_sensor" }, {
          --   gain = 3.0,   -- default
          --   fade = 100.0, -- default
          --   pitch = 0.8,  -- 1.0, -- default
          -- })
          self.object:get_luaentity()._player_within = "false"
          -- core.log("found player, toggle on")
          -- player_within = false
          sendSignal(pos, chain, 1.2, 0)
        end
      end
    end,
  }
)


tg_interactions.register_interactable("sensor_power", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.thicker_box,
  {
    pointable = false,
    _popup_msg = "[ power sensor ]",
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:1,7",
    _popup_hidden = true,
    _toggle = 0,
    _state = 0,
    _opposite = false,
    _the_static_data = {
      "_toggle",
      "_state",
      "_opposite",
    },
    get_staticdata = function(self)
      return get_staticdata(self)
    end,
    on_activate = function(self, staticdata, dtime_s)
      on_activate(self, staticdata, dtime_s)
    end,

    on_step = function(self, dtime, moveresult)
      local pos = self.object:get_pos()
      local chain = {}
      local opposite = self.object:get_luaentity()._opposite
      if tg_power.getPower() == opposite then
        -- core.log("power is [OFF]")
        -- set the state
        if self.object:get_luaentity()._toggle == 0 then
          if self.object:get_luaentity()._state == 1 then
            self.object:get_luaentity()._toggle = 1
            self.object:get_luaentity()._state = 0
            local signal = 0
            if opposite == false then
              signal = 1
            end
            sendSignal(pos, chain, 1.2, signal)
          end
          -- or kill the find signal
        end
      else
        -- core.log("power is [ON]")
        if self.object:get_luaentity()._toggle == 1 then
          self.object:get_luaentity()._toggle = 0
          if self.object:get_luaentity()._state == 0 then
            self.object:get_luaentity()._toggle = 1
            self.object:get_luaentity()._state = 1
          end
        end
        -- do nothing
      end
    end,
    on_rightclick = function(self, clicker)
      if core.is_creative_enabled() then
        if clicker:get_player_control().sneak == true then
          local opposite = not self.object:get_luaentity()._opposite
          self.object:get_luaentity()._opposite = opposite
          if opposite == true then
            core.log("will detect when power is ON")
          else
            core.log("will detect when power is OFF")
          end
        else
          core.log("[buildmode]: sneak click to switch activation state")
        end
      end
    end,
  })

tg_interactions.register_interactable("relay", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.thicker_box,
  {
    _popup_msg = "[ relay ]",
    -- _toggleable = 0, -- default state 0
    -- _state = 0,      -- default state 0
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:3,5",
    _popup_hidden = true,
    pointable = false,
  }
)

tg_interactions.register_interactable("nrelay", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.thicker_box,
  {
    _popup_msg = "[ n-relay ]",
    -- _toggleable = 0, -- default state 0
    -- _state = 0,      -- default state 0
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:3,7",
    _popup_hidden = true,
    pointable = false,
  }
)

tg_interactions.register_interactable("socket", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.thicker_box,
  {
    _popup_msg = "[ socket ]",
    -- _toggleable = 0, -- default state 0
    -- _state = 0,      -- default state 0
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:2,5",
    _popup_hidden = true,
    pointable = false,
    -- on_step = function(self, dtime, moveresult)
    --   if self.object:get_luaentity()._toggleable == 1 then
    --     if self.object:get_luaentity()._state == 1 then
    --       self.object:get_luaentity()._state = 0
    --     end
    --   else
    --     if self.object:get_luaentity()._state == 0 then
    --       self.object:get_luaentity()._state = 1
    --     end
    --   end
    -- end,
  }
)

tg_interactions.register_interactable("random_note", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes
  .centerd_box,
  {
    _popup_msg = "[ note ]",
    on_rightclick = function(self, clicker)
      core.chat_send_all("NOTE READS: \"took me a few attemps to get this note up here..\"")
    end,
  })
tg_interactions.register_interactable("locker_empty", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.centerd_box,
  {
    _popup_msg = "[ search locker ]",
    on_rightclick = function(self, clicker)
      core.chat_send_all("..this locker is empty")
      --[[ local playing_sound = ]]
      core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      if tg_main.dev_mode == false then
        self.object:remove()
        --else
        -- core.log("after first interaction this will be removed in normal gameplay.")
      end
    end,
  })
tg_interactions.register_interactable("locker_suit", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes
  .centerd_box,
  {
    _popup_msg = "[ search locker ]",
    on_rightclick = function(self, clicker)
      core.chat_send_all("hmm, a radiation suit. i should slip this on.")
      --[[ local playing_sound = ]]
      core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      core.after(1, function()
        tg_cut_scenes.run(clicker, { [[slipping into suit]] })
      end)
      if tg_main.dev_mode == false then
        core.log("some zipper sounds should also be added to this. maybe even some skin slapping, because why not.")
        self.object:remove()
        --else
        -- core.log("after first interaction this will be removed in normal gameplay.")
      end
    end,
  })
tg_interactions.register_interactable("tape", "mesh", "tape.glb", "tape.png", shapes.slab,
  {
    _popup_msg = "[ pickup tape ]",
    on_rightclick = function(self, clicker)
      core.chat_send_all("this should come in handy.")
      --[[ local playing_sound = ]]
      core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      if tg_main.dev_mode == false then
        self.object:remove()
        --else
        -- core.log("after first interaction this will be removed in normal gameplay.")
      end
    end,
  })

tg_interactions.register_interactable("door", "mesh", "door.glb", "door.png", shapes.door,
  {
    _interactable = 0,
    _toggleable = 0, -- default state 0
    _state = 0,      -- default state 0
    -- _popup_msg = "[ open door ]",
    -- pointable = false,

    _the_static_data = {
      "_toggleable",
      "_state"
    },
    get_staticdata = function(self)
      return get_staticdata(self)
    end,

    on_activate = function(self, staticdata, dtime_s)
      on_activate(self, staticdata, dtime_s)
      -- core.log("static: "..dump(staticdata))
      -- to make sure the door gets centered

      -- local pos = self.object:get_pos()
      -- local x = math.floor(pos.x)
      -- if pos.x < 0 then
      --   -- for negatives, floor(-1.2) = -2, so use math.ceil to keep integer part consistent
      --   x = math.ceil(pos.x)
      -- end
      -- pos.x = x + 0.5
      -- local new_pos = vector.new(pos.x, pos.y, pos.z)
      -- -- core.log("pos: " .. dump(new_pos))
      -- if pos.x % 1 == 0.5 then
      --   -- core.log("has .5")
      --   self.object:set_pos(new_pos)
      --   --else
      --   -- core.log("does not")
      -- end
      -- -- end)
    end,
    _toggle_state = function(self, state)
      --velocity = self:get_velocity()
      local pos = self:get_pos()
      -- local yaw = math.floor(math.deg(self:get_yaw())/10) * 10
      local yaw = math.floor(math.deg(self:get_yaw()))
      -- core.log("yaw: "..dump(yaw))
      local move_amount = 1.9
      local cur_state = self:get_luaentity()._state
      if cur_state == state then
        -- core.log("no reason to toggle")
        return
      end
      -- core.log("sent state: " .. cur_state)
      if cur_state == 1 then
        self:get_luaentity()._state = 0
        local dir = vector.new(1.9, 0, 0)
        -- 90 and 270 need to move opoistte of eachother
        if yaw == 0 then
          dir = vector.new(move_amount, 0, 0)
        elseif yaw == 90 then
          dir = vector.new(0, 0, move_amount)
        elseif yaw == 180 then
          dir = vector.new((move_amount * -1), 0, 0)
        elseif yaw == 270 then
          dir = vector.new(0, 0, (move_amount * -1))
        end
        self:move_to(vector.add(pos, dir))
      else
        self:get_luaentity()._state = 1
        local dir = vector.new(-1.9, 0, 0)
        if yaw == 0 then
          dir = vector.new((move_amount * -1), 0, 0)
        elseif yaw == 90 then
          dir = vector.new(0, 0, (move_amount * -1))
        elseif yaw == 180 then
          dir = vector.new((move_amount), 0, 0)
        elseif yaw == 270 then
          dir = vector.new(0, 0, (move_amount))
        end
        self:move_to(vector.add(pos, dir))
      end
    end,
    on_step = function(self, dtime, moveresult)
      local velocity = self.object:get_velocity()
      self.object:set_velocity(vector.add(velocity, vector.new(0, gravity, 0)))
    end,

    on_rightclick = function(self, clicker)
      if core.is_creative_enabled() then
        if clicker:get_player_control().sneak == true then
          core.log("ok lets rotate this door")
          local yaw = self.object:get_yaw()
          yaw = math.rad(math.floor((math.deg(yaw) + 90) % 360))
          core.log("new yaw: " .. math.deg(yaw))
          -- self.object:set_yaw(math.rad(math.deg(yaw+math.rad(90))%360))
          self.object:set_yaw(yaw)
        else
          core.log("[buildmode]: sneak click to change the rotation")
        end
      end
    end,
  })

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
        --local found_player = false
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
      local new_pos = player:get_look_dir():multiply(tg_main.reach - 1):add(player_pos)
      local raycast_result = core.raycast(player_pos, new_pos, true, false):next()

      -- core.log("so what is this: " .. dump(raycast_result))
      --local hud_pos = nil
      -- local popup_msg = player:hud_add(msg)

      -- need to know to remove or change the current hud at all times
      local player_name = player:get_player_name()
      local players_hud = getPlayerHuds(player_name)
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
          if value:get_luaentity() ~= nil then
            if value:get_luaentity()._interactable == 1 then
              --luacheck: ignore
              if value:get_luaentity()._popup_hidden == true
                  and player:get_wielded_item():get_name() ~= mod_name .. ":wrench" then
              else
                local obj_pos = value:get_pos()
                interacble_indicator["world_pos"] = obj_pos
                local popup_texture = value:get_luaentity()._popup_texture
                if value:get_luaentity()._interactable_pos ~= nil then
                  local specefic_pos = vector.from_string(value:get_luaentity()._interactable_pos)
                  interacble_indicator["world_pos"] = vector.add(obj_pos, specefic_pos)
                end
                if popup_texture ~= nil then
                  interacble_indicator["text"] = popup_texture
                else
                  interacble_indicator["text"] = "tg_nodes_misc.png^[sheet:16x16:0,5"
                end
                local indicator = player:hud_add(interacble_indicator)
                table.insert(players_hud.huds, indicator)
                -- core.log("where am i? " .. dump())
              end
            end
          end
        end
      end
      --- in radius end ---

      if raycast_result ~= nil and raycast_result.type == "object" then
        -- core.log("who dis: "..dump(raycast_result.ref:get_luaentity()))
        if raycast_result.ref:get_luaentity() == nil then
          return
        end
        local hover_popup = raycast_result.ref:get_luaentity()._popup_msg
        hud_pos = vector.add(raycast_result.ref:get_pos(), vector.new(0, 0.1, 0))

        msg["name"] = hover_popup
        msg["world_pos"] = hud_pos
        if raycast_result.ref:get_luaentity()._interactable_pos ~= nil then
          local specefic_pos = vector.from_string(raycast_result.ref:get_luaentity()._interactable_pos)
          msg["world_pos"] = vector.add(hud_pos, specefic_pos)
        end
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


local all_objects = core.registered_entities

core.register_tool(mod_name .. ":" .. "wrench", {
  description = "Wrench, objects & wiring",
  inventory_image = "tg_interactions_tool.png",
  _to_player = nil,
  pointabilities = {
    -- nodes = {
    --   ["default:stone"] = "blocking",
    --   ["group:leaves"] = false,
    -- },
    objects = {
      [mod_name .. ":" .. "relay"] = true,
      [mod_name .. ":" .. "nrelay"] = true,
      [mod_name .. ":" .. "socket"] = true,
      [mod_name .. ":" .. "sensor"] = true,
      [mod_name .. ":" .. "sensor_disclaimer"] = true,
      [mod_name .. ":" .. "sensor_power"] = true,
      [mod_name .. ":" .. "door"] = true, -- because the door's hitbox keeps blocking player clicks
      -- ["group:ghosty"] = true,       -- (an armor group)
    },
  },

  -- on_use = function(itemstack, user, pointed_thing)
  --   -- return -- lets just prevent breaking stuff with this
  -- end,
  on_place = function(itemstack, placer, pointed_thing)
    --should instead raytrace what the player is looking at
    -- maybe if they are holding shift, so that it is more percise

    -- show list of objects
    -- name, model if any
    -- on click spawn object
    -- core.log("what to place: " .. dump(itemstack:get_meta():get_string("place")))
    if placer:get_player_control().sneak == false then
      local to_place = itemstack:get_meta():get_string("place")
      if to_place ~= "" then
        if placer:get_player_control().aux1 == true then
          core.add_entity(pointed_thing.under, to_place)
        else
          core.add_entity(pointed_thing.above, to_place)
        end
      end
    else
      local to_list = { "image[3,1;1,1;tg_interactions_tool.png;]" }
      local size = vector.new(2, 0, 2)
      local pos_x = 2
      local pos_y = 0
      local max_items = 9
      for value, _ in pairs(all_objects) do
        if string.find(value, mod_name) then
          table.insert(to_list,
            string.format("button[%s,%s;%s,%s;object;%s]", pos_x, pos_y, size.x, size.z,
              string.gsub(value, mod_name .. ":", "")))
          pos_x = pos_x + size.x
          if pos_x >= (max_items * size.z) then
            pos_y = pos_y + size.z
            pos_x = 0
          end
        end
      end
      -- core.log("so what do we have?"..dump(to_list))
      core.show_formspec(placer:get_player_name(), "tg_interactions_menu", table.concat({
        "formspec_version[10]",
        "size[" .. max_items * size.x .. "," .. "10" .. "]",
        -- "container[1,1]",
        "image[1,3;1,1;tg_interactions_tool.png;]",
        table.concat(to_list),
        "button[1,1;1,1;NAME?;ok ok]",
        -- "container_end[]",
        -- "list[current_player;main;0,0;8,4;]",
      }))
      return
    end
  end,


  -- short_description = "",
})

core.register_on_player_receive_fields(function(player, formname, fields)
  if formname == "tg_interactions_menu" then
    -- core.log("fields: " .. dump(fields))
    if fields["object"] == nil then
      return
    end
    -- core.log("what field?" .. dump(fields))
    -- local eye_height = player:get_properties().eye_height
    -- local player_look_dir = player:get_look_dir()
    -- local pos = player:get_pos():add(player_look_dir)
    -- local player_pos = { x = pos.x, y = pos.y + eye_height, z = pos.z }
    -- local new_pos = player:get_look_dir():multiply(tg_main.reach - 1):add(player_pos)
    -- local raycast_result = core.raycast(player_pos, new_pos, true, false):next()
    -- if player:get_player_control().sneak == true then
    --   core.add_entity(raycast_result.under, mod_name .. ":" .. fields["object"])
    -- else
    --   core.add_entity(raycast_result.above, mod_name .. ":" .. fields["object"])
    -- end
    local item = player:get_wielded_item()
    local item_meta = item:get_meta()
    local to_place = mod_name .. ":" .. fields["object"]
    -- item_meta:set_string("place",to_place)
    -- core.log("will place: "..to_place)
    item_meta:set_string("place", to_place)
    player:set_wielded_item(item)
    core.close_formspec(player:get_player_name(), formname)
    -- core.add_entity(raycast_result.above, fields["object"], [staticdata])
  end
end)
