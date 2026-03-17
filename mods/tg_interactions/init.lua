local mod_name = core.get_current_modname()

local shapes = tg_nodes["shapes"]

tg_interactions = {}

-- NOTE: for something to get the "interactable" popup
-- it have "_interactable = 1"

-- things within will show interacable/ popup on hover
tg_interactions.popup_radius = 4.5 -- default of 4.5

local gravity = -0.9

-- ALLSEEER mod compatibility
if core.get_modpath("allseer") and allseer then
  allseer.extra[mod_name] = function(raycast_result)
    if raycast_result.type == "object" then
      local formatted = ""
      for key, value in pairs(raycast_result.ref:get_luaentity()) do
        if string.find(string.sub(key, 1), "_") then
          formatted = string.format("%s%s: %s\n", formatted, key, value)
        end
      end
      return formatted
    end
    return ""
  end
end

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
        self._weightfluence = 3 / self._weight -- weight influence
        self._sound_duration = 0.81 / self._weightfluence
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
  def._weightfluence = 3 / def._weight -- weight influence
  def._sound_duration = 0.81 / def._weightfluence
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
  shapes.slim_box, 2)
tg_interactions.register_draggable("pipes", "mesh", "tubes.glb", "tubes.png", shapes.medium_object, 4)
tg_interactions.register_draggable("power_core", "mesh", "power_core.glb", "power_core.png", shapes.medium_object, 4)

tg_interactions.register_interactable("power_switch", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.centerd_box,
  {
    _popup_msg = "[ switch on power ]",
    on_rightclick = function(self, clicker)
      core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      tg_power.togglePower()
      if tg_power.power == true then
        self.object:get_luaentity()._popup_msg = "[ switch off power ]"
      else
        self.object:get_luaentity()._popup_msg = "[ switch on power ]"
      end
      if tg_power.power_core == false then
        tg_dialog.dialog(clicker, "hmm..", true) -- clear dialog
        tg_dialog.dialog(clicker, "the generator seems to be missing a power core")
        tg_dialog.dialog(clicker, "wont be able to power this place up without one")
      end
    end,
  }
)

---comment
---@param pos any
---@param chain any
---@param distance any
---@param signal number|nil
local function sendSignal(pos, chain, distance, signal, prev_pos)
  prev_pos = prev_pos or pos
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
          if core.is_creative_enabled() then
            tg_main.debug_particle(value:get_pos(), "#fff", 0.5, vector.subtract(obj_pos, pos), 1)
          end

          chain[vector.to_string(obj_pos)] = true
          if string.find(value:get_luaentity().name, "signal_flipper") then
            -- core.log("n relay found")
            if signal == 1 then
              signal = 0
            else
              signal = 1
            end
            if core.is_creative_enabled() then
              tg_main.debug_particle(value:get_pos(), "#fc4614", 0.5, vector.subtract(obj_pos, pos), 1)
            end
            sendSignal(obj_pos, chain, distance, signal, prev_pos)
          elseif string.find(value:get_luaentity().name, "relay") then
            -- core.log("relay")
            sendSignal(obj_pos, chain, distance, signal, prev_pos)
          elseif string.find(value:get_luaentity().name, "bit_bridge") then
            if value:get_luaentity()._state == 1 then
              core.sound_play(tg_sound.wield_toggle_off, { pos = obj_pos })
              sendSignal(obj_pos, chain, distance, signal, prev_pos)
            else
              core.sound_play(tg_sound.wield_toggle_on, { pos = obj_pos })
              local message = "this wont work without power"
              -- core.chat_send_all(message)
              for _, obj in ipairs(core.get_objects_inside_radius(pos, 5)) do
                if obj:is_player() then
                  tg_dialog.dialog(obj, message, true)
                end
              end
              -- do nothing
            end
            -- core.log("relay")
          elseif string.find(value:get_luaentity().name, "bit_toggler") then
            -- core.log("ok found this")
            local near = core.get_objects_inside_radius(obj_pos, distance)
            for i, v in pairs(near) do
              local bit_pos = v:get_pos()
              if bit_pos ~= pos then
                -- core.log("not pos")
                if not v:is_player() then
                  -- if chain[vector.to_string(bit_pos)] == true then
                  --   --do nothing
                  -- else
                  if core.is_creative_enabled() then
                    -- tg_main.debug_particle(value:get_pos(),"#fff",0.5,vector.subtract(obj_pos,pos),1)
                  end
                  chain[vector.to_string(bit_pos)] = true
                  if string.find(v:get_luaentity().name, "bit_bridge") then
                    v:get_luaentity()._toggle_state(v, signal)
                  end
                end
                -- end
              end
            end
          elseif string.find(value:get_luaentity().name, "sensor_id_cartridge") then
            local found = false
            if players_collections ~= nil then
              for i, v in ipairs(players_collections) do
                for _, coll in ipairs(v.collection) do
                  if string.find(coll.name, "id_cartridge") then
                    found = true
                    sendSignal(obj_pos, chain, distance, signal, prev_pos)
                  end
                  -- core.log(dump(coll.name))
                end
              end
            end
            if found == false then
              local message = "I need and ID to get this open"
              for _, obj in ipairs(core.get_objects_inside_radius(pos, 5)) do
                if obj:is_player() then
                  core.chat_send_player(obj:get_player_name(), message)
                  tg_dialog.dialog(obj, message, true)
                end
              end
            end
          elseif string.find(value:get_luaentity().name, "sensor_power") then
            -- core.log("the state is: " .. value:get_luaentity()._state)
            -- if value:get_luaentity()._state == 0 then
            --   -- core.log("power needed")
            --   return
            -- else
            -- core.log("we have power, continue")
            -- sendSignal(obj_pos, chain, distance, signal,prev_pos)
            -- end
          elseif string.find(value:get_luaentity().name, "socket") then
            -- core.log("socket!!!!")
            local find_reciver = core.get_objects_inside_radius(obj_pos, distance * 2.0)
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
      chain[vector.to_string(pos)] = true
      -- if tg_main.dev_mode == true then
      --   core.log("button pressed")
      -- end
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
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:0,7^[resize:42x42",
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
tg_interactions.register_interactable("sensor_id_cartridge", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.centerd_box,
  {
    _popup_msg = "[ sensor id cartridge ]",
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:2,7^[resize:42x42",
    _popup_hidden = true,
    pointable = false,
  }
)

--TODO: dialog needs to be part of some global thing, and needs to be persistant
local cave_passage = false
tg_interactions.register_interactable("cave_passage_dialog", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.centerd_box,
  {
    _popup_msg = "[ cave passage dialog ]",
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:0,7^[resize:42x42",
    _popup_hidden = true,
    pointable = false,
    on_step = function(self, dtime, moveresult)
      local cur_pos = self.object:get_pos()
      local max_distance = 4
      local near_by = core.get_objects_inside_radius(cur_pos, max_distance)
      if cave_passage == false then
        for index, player in ipairs(near_by) do
          if player:is_player() then
            cave_passage = true
            tg_dialog.dialog(player, "Hmm, That looks like an elevator.")
            tg_dialog.dialog(player,
              "That could be my way out of here! just need to find a way around.")
          end
        end
      end
    end,
  }
)

--TODO: dialog needs to be part of some global thing, and needs to be persistant
local crwaling_of_boarding = false
tg_interactions.register_interactable("crawling_off_boarding", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.centerd_box,
  {
    pointable = false,
    _popup_msg = "[ crawling ]",
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:0,7^[resize:42x42",
    _popup_hidden = true,
    on_step = function(self, dtime, moveresult)
      local cur_pos = self.object:get_pos()
      local max_distance = 4
      local near_by = core.get_objects_inside_radius(cur_pos, max_distance)
      if crwaling_of_boarding == false then
        for index, player in ipairs(near_by) do
          if player:is_player() then
            crwaling_of_boarding = true
            core.chat_send_all(table.concat({
              core.colorize("#f4e85f", "CRAWL; while crouching look down and walk backwards to start crawling\n"),
              core.colorize("#4392f9", "Reaching things may require crawling.\n"),
            }))
            tg_dialog.dialog(player, "Maybe I can [CRAWL] through this hole")
          end
        end
      end
    end,
  }
)

tg_interactions.register_interactable("gorge_corpse_dialog", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes
  .centerd_box,
  {
    _popup_msg = "[ corpse ]",
    on_rightclick = function(self, clicker)
      tg_dialog.dialog(clicker, "looks like this guy had a pretty bad fall.")
      tg_dialog.dialog(clicker, "...let's not do as he did.")
      tg_dialog.dialog(clicker, "there has to be another way out of here.")
      if tg_main.dev_mode == false then
        self.object:remove()
        --else
        -- core.log("after first interaction this will be removed in normal gameplay.")
      end
    end,
  })

tg_interactions.register_interactable("sensor", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.wiring,
  {
    pointable = false,
    _popup_msg = "[ player sensor ]",
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:4,5^[resize:42x42",
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
  shapes.wiring,
  {
    pointable = false,
    _popup_msg = "[ power sensor ]",
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:1,7^[resize:42x42",
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
    _toggle_state = function(self)
      local state = self.object:get_luaentity()._state
      state = state % 2
      self.object:get_luaentity()._state = state
      -- core.log("new state: " .. state)
    end,

    on_step = function(self, dtime, moveresult)
      local pos = self.object:get_pos()
      local chain = {}
      local opposite = self.object:get_luaentity()._opposite
      -- core.log("state: " .. self.object:get_luaentity()._state)

      local signal = 1
      -- if opposite == false then
      --   signal = 1
      -- end

      --TODO: implement function swap (would that break the current state toggle?)
      if opposite == true then
        if tg_power.getPower() == false then
          -- do not send power, but toggle 1 signal first
          if self.object:get_luaentity()._state == 0 then
            -- self.object:get_luaentity()._state = 1
            sendSignal(pos, chain, 1.2, signal)
            self.object:get_luaentity()._toggle = 1
          end
        else
          --check toggle
          if self.object:get_luaentity()._state == 1 then
            -- self.object:get_luaentity()._state = 1
            self.object:get_luaentity()._toggle = 1
          end
        end
      else
        if tg_power.getPower() == true then
          -- do not send power, but toggle 1 signal first
          if self.object:get_luaentity()._state == 0 then
            -- self.object:get_luaentity()._state = 1
            sendSignal(pos, chain, 1.2, signal)
            self.object:get_luaentity()._toggle = 1
          end
        else
          --check toggle
          if self.object:get_luaentity()._state == 1 then
            -- self.object:get_luaentity()._state = 1
            self.object:get_luaentity()._toggle = 1
          end
        end
      end




      if self.object:get_luaentity()._toggle == 1 then
        -- core.log("ok we should toggle back")
        if self.object:get_luaentity()._state == 0 then
          self.object:get_luaentity()._state = 1
        else
          self.object:get_luaentity()._state = 0
        end
        -- self.object:get_luaentity()._toggle_state(self)
        -- self.object:get_luaentity()._state = 1
        self.object:get_luaentity()._toggle = 0
      end
      -- if tg_power.getPower() == opposite then
      --   -- core.log("power is [OFF]")
      --   -- set the state
      --   if self.object:get_luaentity()._toggle == 0 then
      --     if self.object:get_luaentity()._state == 1 then
      --       self.object:get_luaentity()._toggle = 1
      --       self.object:get_luaentity()._state = 0
      --       local signal = 0
      --       if opposite == false then
      --         signal = 1
      --       end
      --       sendSignal(pos, chain, 1.2, signal)
      --     end
      --     -- or kill the find signal
      --   end
      -- else
      --   -- core.log("power is [ON]")
      --   if self.object:get_luaentity()._toggle == 1 then
      --     self.object:get_luaentity()._toggle = 0
      --     if self.object:get_luaentity()._state == 0 then
      --       self.object:get_luaentity()._toggle = 1
      --       self.object:get_luaentity()._state = 1
      --     end
      --   end
      --   -- do nothing
      -- end
    end,
    on_rightclick = function(self, clicker)
      if core.is_creative_enabled() then
        if clicker:get_player_control().sneak == true then
          local opposite = not self.object:get_luaentity()._opposite
          self.object:get_luaentity()._opposite = opposite
          if opposite == true then
            core.log("will detect when power is OFF")
          else
            core.log("will detect when power is ON")
          end
        else
          core.log("[buildmode]: sneak click to switch activation state")
        end
      end
      local chain = {}
      local pos = self.object:get_pos()
      local signal = 1
      sendSignal(pos, chain, 1.2, signal)
    end,
  })

tg_interactions.register_interactable("relay", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.wiring,
  {
    _popup_msg = "[ relay ]",
    -- _toggleable = 0, -- default state 0
    -- _state = 0,      -- default state 0
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:3,5^[resize:42x42",
    _popup_hidden = true,
    pointable = false,
  }
)

tg_interactions.register_interactable("signal_flipper", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.wiring,
  {
    _popup_msg = "[ signal_flipper ]",
    -- _toggleable = 0, -- default state 0
    -- _state = 0,      -- default state 0
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:3,7^[resize:42x42",
    _popup_hidden = true,
    pointable = false,
  }
)

tg_interactions.register_interactable("socket", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.wiring,
  {
    _popup_msg = "[ socket ]",
    -- _toggleable = 0, -- default state 0
    -- _state = 0,      -- default state 0
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:2,5^[resize:42x42",
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

-- TODO:
-- idea, something that will allow power through it,
-- another that will cut the link
-- bit_toggler -> bit_bridge
-- the reason for this is to not fuck with the "energy" flow
-- if the bit_toggler recives power it will toggle the bit_bridge

tg_interactions.register_interactable("bit_bridge", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.wiring,
  {
    pointable = false,
    _popup_msg = "[ bit_bridge ]",
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:6,5^[resize:42x42",
    _popup_hidden = true,
    _state = 0,
    _opposite = false,
    _the_static_data = {
      "_state",
      "_opposite",
    },
    get_staticdata = function(self)
      return get_staticdata(self)
    end,
    on_activate = function(self, staticdata, dtime_s)
      on_activate(self, staticdata, dtime_s)
    end,
    _toggle_state = function(self, state)
      if state == nil then
        state = self:get_luaentity()._state
        state = (state + 1) % 2
      end
      self:get_luaentity()._state = state
      -- core.log("new state: " .. state)
    end,
    -- on_step = function(self, dtime, moveresult)
    -- end,
  }
)

tg_interactions.register_interactable("bit_toggler", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6",
  shapes.wiring,
  {
    pointable = false,
    _popup_msg = "[ bit_toggler ]",
    _popup_texture = "tg_nodes_misc.png^[sheet:16x16:7,5^[resize:42x42",
    _popup_hidden = true,
    _state = 0,
    _opposite = false,
    _the_static_data = {
      "_state",
      "_opposite",
    },
    get_staticdata = function(self)
      return get_staticdata(self)
    end,
    on_activate = function(self, staticdata, dtime_s)
      on_activate(self, staticdata, dtime_s)
    end,
    _toggle_state = function(self)
      local state = self.object:get_luaentity()._state
      state = state % 2
      self.object:get_luaentity()._state = state
      -- core.log("new state: " .. state)
    end,
    -- on_step = function(self, dtime, moveresult)
    -- end,
  }
)

tg_interactions.register_interactable("random_note", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes
  .centerd_box,
  {
    _popup_msg = "[ sticky note ]",
    on_rightclick = function(self, clicker)
      local message = string.format("%s %s", core.colorize("#bab675", "NOTE READS:"),
        "\"took me a few attemps to get this note up here..\"")
      core.chat_send_player(clicker:get_player_name(), message)
      tg_dialog.dialog(clicker, message, true)
    end,
  })

tg_interactions.register_interactable("random_note_rocks", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes
  .centerd_box,
  {
    _popup_msg = "[ sticky note ]",
    on_rightclick = function(self, clicker)
      local message = string.format("%s %s", core.colorize("#bab675", "NOTE READS:"),
        "\"What is the purpose of this room..\"")
      core.chat_send_player(clicker:get_player_name(), message)
      tg_dialog.dialog(clicker, message, true)
    end,
  })

tg_interactions.register_interactable("random_note_rocks_2", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes
  .centerd_box,
  {
    _popup_msg = "[ sticky note ]",
    on_rightclick = function(self, clicker)
      local message = string.format("%s %s", core.colorize("#bab675", "NOTE READS:"), "\"I count 39827 rocks..\"")
      core.chat_send_player(clicker:get_player_name(), message)
      tg_dialog.dialog(clicker, message, true)
    end,
  })

tg_interactions.register_interactable("random_note_rocks_3", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes
  .centerd_box,
  {
    _popup_msg = "[ sticky note ]",
    on_rightclick = function(self, clicker)
      local message = string.format("%s %s", core.colorize("#bab675", "NOTE READS:"), "\"They wont let me leave..\"")
      core.chat_send_player(clicker:get_player_name(), message)
      tg_dialog.dialog(clicker, message, true)
    end,
  })


tg_interactions.register_interactable("random_note_rocks_4", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes
  .centerd_box,
  {
    _popup_msg = "[ sticky note ]",
    on_rightclick = function(self, clicker)
      local message = string.format("%s %s", core.colorize("#bab675", "NOTE READS:"),
        "\"sharp rocks, doll rocks, crumbly rocks, cracky rocks, snappy rocks, fleshy rocks... rocks..\"")
      core.chat_send_player(clicker:get_player_name(), message)
      tg_dialog.dialog(clicker, message, true)
    end,
  })


tg_interactions.register_interactable("tape", "mesh", "tape.glb", "tape.png", shapes.medium_object,
  {
    _popup_msg = "[ pick up tape ]",
    on_rightclick = function(self, clicker)
      --[[ local playing_sound = ]]
      local message = "this should come in handy."
      core.chat_send_player(clicker:get_player_name(), message)
      tg_dialog.dialog(clicker, message)
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
      addToPlayerCollection(clicker:get_player_name(), self.name)
    end,
  })


tg_interactions.register_interactable("id_cartridge", "mesh", "id_cartridge.glb", "id_cartridge.png",
  shapes.medium_object,
  {
    _popup_msg = "[ pick up id cartridge ]",
    on_rightclick = function(self, clicker)
      local message = "i should be able to enter the secuirty room with this"
      core.chat_send_player(clicker:get_player_name(), message)
      tg_dialog.dialog(clicker, message)
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
      addToPlayerCollection(clicker:get_player_name(), self.name)
    end,
  })

tg_interactions.register_interactable("torch", "mesh", "torch.glb", "torch.png", shapes.medium_object,
  {
    _popup_msg = "[ pick up torch ]",
    on_rightclick = function(self, clicker)
      core.chat_send_player(clicker:get_player_name(), "darkness be gone")
      tg_dialog.dialog(clicker, "I've heard that these torches can sometimes leak radiation")
      tg_dialog.dialog(clicker, "but I rather be able to see while im here, so..")
      tg_dialog.dialog(clicker, "...")
      core.sound_play({ name = "tg_paper_footstep" }, {
        gain = 1.0,   -- default
        fade = 100.0, -- default
        pitch = 1.8,  -- 1.0, -- default
      })
      if tg_main.dev_mode == false then
        self.object:remove()
      end
      addToPlayerCollection(clicker:get_player_name(), self.name)
      -- core.log("collections: "..dump(players_collections))
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
      "_state",
      -- "_collision_flipped",
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
      core.after(1, function()
        if self.object:get_attach() == nil then
          self.object:remove()
        end
      end)

      -- fix door collison; this is not a good fix
      local attached = self.object:get_attach()
      if attached == nil then return end -- skip the rest
      local yaw = attached:get_yaw()
      yaw = math.rad(math.floor((math.deg(yaw) + 90) % 360))
      if math.deg(yaw) % 180 == 0 then
        self.object:set_properties({
          collisionbox = shapes.door_flipped,
          selectionbox = tg_nodes
              ["shapes"].door_flipped
        })
      else
        self.object:set_properties({ collisionbox = shapes.door, selectionbox = shapes.door })
      end
    end,

    on_rightclick = function(self, clicker)
      if core.is_creative_enabled() then
        if clicker:get_player_control().sneak == true then
          -- get parent
          if self.object:get_attach() == nil then
            return
          end
          core.log("attached: " .. dump(self.object:get_attach():get_pos()))
          local attached = self.object:get_attach()
          core.log("ok lets rotate this door")
          -- local yaw = self.object:get_yaw()
          local yaw = attached:get_yaw()
          yaw = math.rad(math.floor((math.deg(yaw) + 90) % 360))
          core.log("new yaw: " .. math.deg(yaw))
          -- self.object:set_yaw(yaw)
          attached:set_yaw(yaw)
          if math.deg(yaw) % 180 == 90 then
            self.object:set_properties({
              collisionbox = shapes.door_flipped,
              selectionbox = tg_nodes
                  ["shapes"].door_flipped
            })
          else
            self.object:set_properties({ collisionbox = shapes.door, selectionbox = shapes.door })
          end
        else
          core.log("[buildmode]: sneak click to change the rotation")
        end
      end
    end,
  })

tg_interactions.register_interactable("door_hinge", "mesh", "radio.glb", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes
  .hinge,
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
      -- core.after(1, function()
      local pos = self.object:get_pos()
      local near_by = core.get_objects_inside_radius(pos, 2)
      local door = nil
      for index, value in pairs(near_by) do
        if value ~= self.object then
          if door == nil then
            if not value:is_player() then -- not player
              if string.find(value:get_luaentity().name, "door") then
                door = value
              end
            end
          end
        end
      end
      if door == nil then
        door = core.add_entity(self.object:get_pos(), mod_name .. ":door")
      end
      door:set_properties({ visual_size = vector.new(1, 1, 1) })
      door:set_attach(self.object, "", vector.new(0.5, 0, 0))
      -- end)
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
      -- core.log("attached: "..dump(self.object:get_attach()))
      -- local velocity = self.object:get_velocity()
      -- self.object:set_velocity(vector.add(velocity, vector.new(0, gravity, 0)))
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

tg_interactions.register_interactable("power_gen", "none", "", "tg_nodes_misc.png^[sheet:16x16:0,6", shapes.tiny_box,
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

-- create constant so that we're not constantly creating this
local PWN = mod_name .. ":wrench" -- potential wrench name

-- create events for player handling
local events = {}
for _, ename in ipairs({ -- for _, event name
  -- more specific
  -- interactable indicators refreshed
  "player_hud_interactables",
  -- player looking at an interactable indicator
  "player_looking_at_interactable",
  "player_looking_at_interactable_stopped", -- for when player has stopped looking
  -- player interacting with a held interactable
  "player_held_interactable_step",
  "player_held_interactable_failed",  -- didn't complete
  "player_held_interactable_success", -- succeeded
  -- events correlated to player's interactable indicator message hug
  "player_hud_message_typing",
  "player_hud_message_complete"
}) do
  -- name, automatic setup definition: add register function to `tg_interactions`
  -- return will be data of this event
  events[ename] = events_api.create(ename, { global = tg_interactions })
end



-- hud options
local huds = {
  -- hud to appear over each interactable entity
  indicator = {
    type = "image_waypoint",
    name = "interaction_indicator",
    text = "tg_nodes_misc.png^[sheet:16x16:0,5",
    scale = { x = 2, y = 2 },
    number = 0xFFFFFF,
    z_index = -300,
    alignment = 0,
    --world_pos = { x = 0, y = 1, z = 0 },
  },
  -- text that appears alongside an indicator if viewed upon directly
  msg = {
    type = "waypoint",
    text = "messagetext", -- don't ask me how, but the engine is using `name` as the text field
    precision = 0,
    scale = { x = 80, y = 80 },
    number = 0xFFFFFF,
    z_index = -300,
    alignment = 0,
    --world_pos = { x = 0, y = 1, z = 0 },
  },
  -- displays texture for 60 circle holding input visual
  circle60 = {
    type = "image_waypoint",
    name = "circle60",
    scale = { x = 0.13, y = 0.13 },
    z_index = -300,
  }
}

-- clear any interactable indicator huds for a player's data
local function clear_interactable_indicators(pdata, refresh)
  if not pdata.hud_interactables then return end -- none to speak of
  for _, data in ipairs(pdata.hud_interactables) do
    pdata.obj:hud_remove(data.icon)              -- icon is the hud return
  end
  -- remove data as a whole
  pdata.hud_interactables = nil
end

-- ran each player globalstep
-- handles creating interactable indicator HUDs (`pdata.hud_interactables`)
tg_player.register_on_step(function(plr, pdata)
  ---@class interactable
  ---@field pos vector3
  ---@field interactable_pos vector3
  ---@field popup_texture string
  ---@field ent nil|table

  local finteractables = {} -- found interactables

  -- interactable entities within radius (will include player)
  local within_radius = core.get_objects_inside_radius(pdata.pos, tg_interactions.popup_radius)
  -- player will be 1, odd if there is 0 but let's check for that
  -- if #within_radius < 2 then return clear_interactable_indicators(pdata) end
  for _, obj in ipairs(within_radius) do
    local ent = not core.is_player(obj) and obj:get_luaentity()
    if ent and ent._interactable == 1 then -- if interactable (was == 1)
      -- add popup if holding wrench or if popup isn't hidden
      if pdata.wielded.def.name == PWN or ent._popup_hidden ~= true then
        ---@type interactable
        local popup = {
          pos = ent.object:get_pos(),
          interactable_pos = ent._interactable_pos,
          popup_texture = ent._popup_texture,
          ent = ent,
        }
        finteractables[#finteractables + 1] = popup
      end
    end
  end

  -- interactable nodes
  local distance_vec = vector.new(tg_interactions.popup_radius - 1, tg_interactions.popup_radius - 1,
    tg_interactions.popup_radius - 1)
  local nodes_within_radius = core.find_nodes_in_area(pdata.pos:subtract(distance_vec), pdata.pos:add(distance_vec),
    { "group:interactable" })
  for _, pos in ipairs(nodes_within_radius) do
    ---@type interactable
    local popup = {
      pos = pos,
      interactable_pos = pos,
      popup_texture = "",
      ent = nil,
    }
    finteractables[#finteractables + 1] = popup
  end
  -- do not continue if no interactables found
  if #finteractables == 0 then return clear_interactable_indicators(pdata) end
  -- refresh interactables
  clear_interactable_indicators(pdata)
  pdata.hud_interactables = {}
  for _, popup in ipairs(finteractables) do -- ent is equal to found interactable entity
    -- set up interactable data (entity, icon, position)
    local idata = { ent = popup.ent, icon = table.copy(huds.indicator), pos = popup.pos }
    local icon = idata.icon
    icon.world_pos = idata.pos
    -- permit custom popup textures or else default
    if popup.ent ~= nil then
      icon.text = popup.ent._popup_texture or "tg_nodes_misc.png^[sheet:16x16:0,5"
    else
      icon.text = popup._popup_texture or "tg_nodes_misc.png^[sheet:16x16:0,5"
    end
    -- icon.text = popup._popup_texture or "tg_nodes_misc.png^[sheet:16x16:0,5"
    if popup.ent ~= nil then -- entity only
      -- permit custom addition to position
      if popup.ent._interactable_pos then
        local addpos = popup.ent._interactable_pos
        if addpos then
          idata.pos = idata.pos:add(vector.from_string(addpos))
        end
      end
    end
    -- finalize
    idata.icon.world_pos = idata.pos
    idata.icon = plr:hud_add(idata.icon)
    -- add to table
    table.insert(pdata.hud_interactables, idata)
  end
  -- run event for interactables successfully finished drawing
  events.player_hud_interactables(plr, pdata, pdata.hud_interactables)
end)

-- ran each lookdir or eyepos (or pos) change
-- handle creating lookpos and lookatpos
tg_player.register_on_change_eyepos_or_lookdir(function(plr, pdata, eyepos, lookdir)
  -- forwards our view
  pdata.lookpos = eyepos:add(lookdir)
  -- what position we're looking at plus reach range
  pdata.lookatpos = lookdir:multiply(tg_main.reach - 1):add(pdata.lookpos)
end)

-- destroys the floating text above an interactor indicator
-- if hudonly, destroys ONLY the hud, and not the information behind it
local function destroy_focused_interactable_hud(pdata, hudonly)
  local focus = pdata.focused_interactable
  local plr = pdata.obj
  if not (focus and plr) then return end -- nothing to do
  local hud = focus.msg_hud
  -- run event
  events.player_looking_at_interactable_stopped(plr, pdata, focus, focus.icon)
  -- run code
  if hud then
    plr:hud_remove(hud)
    if hudonly then
      focus.msg_hud = nil
      return
    end
  end
  pdata.focused_interactable = nil
end

-- create a message hud for pointed indicator
local function create_msg_hud(pdata)
  local focus, plr = pdata.focused_interactable, pdata.obj
  if not (focus and plr) then return end -- oops!
  -- delete any previous hud
  if focus.msg_hud then
    destroy_focused_interactable_hud(pdata, true)
  end
  -- create our hud
  local hud = table.copy(huds.msg)
  hud.name = focus.typing_text
  hud.world_pos = focus.mainpos:add(focus.addpos) -- adding!
  -- add hud, return ID
  focus.msg_hud = plr:hud_add(hud)
  return focus.msg_hud
end

-- ran each eye position or lookdir change
-- this runs pointed interactable indicator code
tg_interactions.register_on_player_hud_interactables(function(plr, pdata, interactables)
  if not (pdata.eyepos and pdata.lookatpos) then return end -- shouldn't happen, but just in case it does...
  local focus = pdata.focused_interactable                  -- for checking purposes
  -- now to actually do code
  local found                                               -- declare
  -- raycast time!
  local ray = core.raycast(pdata.eyepos, pdata.lookatpos)
  -- iterate through raycast and find an interactable
  for thing in ray do
    if thing and thing.type == "object" then
      local ent = thing.ref:get_luaentity()
      -- found a proper entity with a popup message
      if ent and ent._popup_msg then
        -- verify if it's an interactable we can look at
        for _, interactable in ipairs(interactables) do
          -- we GOT EM!
          if interactable.ent ~= nil then
            if ent.object == interactable.ent.object then
              found = { icon = interactable, ent = ent }
              break
            end
          end
        end
        -- break loop through pointed thing upon finding a found
        if found then break end
      end
    end
  end
  -- oh no we're not looking at anything
  if not found then
    return destroy_focused_interactable_hud(pdata, true) -- 2nd boolean says to only delete hud not info
  end
  -- now to do some stuff
  local ent = found.ent
  found.typeto_text = ent._popup_msg -- will NEVER be nil
  -- we're still looking at this indicator (and text is the same!)
  if focus and (focus.ent.object == found.ent.object and
        found.typeto_text == focus.typeto_text) then
    focus.icon = found.icon
    return events.player_looking_at_interactable(plr, pdata, focus, focus.icon)
    -- TIME TO CREATE A FOCUS !
  else
    destroy_focused_interactable_hud(pdata) -- time to start anew!
    pdata.focused_interactable = found
  end
  found.typing_length = #found.typeto_text
  found.typing_index = 1
  found.typing_text = found.typeto_text:sub(1, 1) -- START!
  -- where our text will float from the popup icon's pos
  found.addpos = vector.new(0, 0.12, 0)           -- will be added to popup icon position (mainpos)
  found.mainpos = found.icon.pos                  -- save to ourself for position checking
  -- create hud
  create_msg_hud(pdata)
end)

-- ran each step a player is pointing at an interactable (provided information from `pdata.focused_interactable` )
-- this types out focus' text
-- icon is data correlated to the interactable indicator icon
tg_interactions.register_on_player_looking_at_interactable(function(plr, pdata, focus, icon)
  -- if no hud, create one!
  local hud = focus.msg_hud or create_msg_hud(pdata)
  -- update text pos
  if not vector.equals(focus.mainpos, icon.pos) then
    focus.mainpos = icon.pos:new() -- clone for next check
    plr:hud_change(hud, "world_pos", icon.pos:add(focus.addpos))
  end
  -- return if complete or no hud (huh?)
  if focus.typing_complete or not hud then return end
  -- TYPING OUT TIME!
  local textdex = focus.typing_index + 1 -- text (typing) index, yeah
  -- grabbing from position of message, e.g. `:sub(1,1)`
  local char = focus.typeto_text:sub(textdex, textdex)
  -- newline found, update Y coord
  if char == "\n" then
    focus.addpos.y = focus.addpos.y + 0.08
    plr:hud_change(hud, "world_pos", focus.icon.pos:add(focus.addpos))
  end
  -- growing the text
  focus.typing_text = focus.typing_text .. char
  plr:hud_change(hud, "name", focus.typing_text) -- update!
  -- complete?
  if textdex >= focus.typing_length then
    focus.typing_complete = true
    -- run event of completion
    -- provides 5th parameter for total message length
    events.player_hud_message_complete(plr, pdata, focus, icon, focus.typing_length)
  end
  focus.typing_index = textdex
  -- run typing event
  -- textdex = current printing character index
  events.player_hud_message_typing(plr, pdata, focus, icon, textdex)
end)

local function create_circle_slice(iter)
  -- dir of 1 is top right, 2 is bottom right, 3 is bottom left, 4 is top left
  local dir = iter > 15 and (iter > 45 and 4 or iter > 30 and 3 or iter > 15 and 2) or 1
  local texmod = dir == 4 and "^[transformR90" or dir == 3 and "^[transformR180" or
      dir == 2 and "^[transformR270" or ""
  -- texture iteration (will be modulo 15, as there are 3 total texmods that can happen (with 4th being none) )
  local texiter = iter % 15                -- ensures it will be 1 to 15
  texiter = texiter == 0 and 15 or texiter -- will be 0 if reached 15, so correct it
  -- return concatenated texture string and texture modifier
  return table.concat({
    "60circle-15-",    -- base
    tostring(texiter), -- texiter (tostring needs to be ran as it won't like the number)
    ".png"             -- image file
  }), texmod
end

-- count must be 1 to 60
-- 1 will be first lil dash, 60 will be complete circle
local function create_circle_texture(count)
  -- integer'ify
  count = math.floor(count)
  -- clamp between 1 and 60
  count = math.max(math.min(count, 60), 1)
  -- create texture
  local texture = {}
  local texmod = ""
  for i = 1, count do
    local slice, ltexmod = create_circle_slice(i) -- slice, localized texture modifier
    -- we've gotta separate
    if texmod ~= ltexmod then
      -- close the previous!
      if texmod ~= "" then
        table.insert(texture, texmod)
        table.insert(texture, ")")
      end
      -- start of a new era
      if ltexmod ~= "" then
        table.insert(texture, "^(")
      end
      texmod = ltexmod -- update!
    end
    -- add
    table.insert(texture, slice)
    -- connector (only add if not reached limit)
    if i ~= count then
      table.insert(texture, "^")
    end
  end
  -- add closing parenthesis
  if count > 15 then
    table.insert(texture, texmod)
    table.insert(texture, ")")
  end
  -- return concatenated texture
  return table.concat(texture)
end

-- handles turning a percentage into relevant slice
local function create_60circle_texture(perc)
  perc = 60 * perc -- 60 slices
  return create_circle_texture(perc)
end

-- remove that hud!
local function remove_circle60_hud(pdata)
  local circle60 = pdata.circle60
  if not circle60 then return end
  -- and refresh too!
  pdata.obj:hud_remove(circle60)
  pdata.circle60 = nil
end

-- ran each step a player is pointing at an interactable (provided information from `pdata.focused_interactable` )
-- use register from event for ease of text length
-- handles functionality with holding down
events.player_looking_at_interactable.register(function(plr, pdata, focus, icon)
  local circle60 = pdata.circle60 -- get circle60
  -- get entity
  local ent = focus.ent or icon.ent
  if not ent then return end
  -- not meant for this world
  if not ent.player_held_success then return end
  -- alright, let's find our holding data functionality
  local hdata = ent._holding_data
  -- get required time
  -- default to 1 second on failure to retrieve
  local rqtime = hdata and hdata.required_time or
      ent._holding_time or 1
  -- set it!
  if hdata and not hdata.required_time then
    hdata.required_time = rqtime
  end
  -- oops! no one's home
  if not hdata then
    -- somehow circle60 still present ...
    if circle60 then
      hdata = { holder = plr, ttime = pdata.dtime } -- create a fake holddata
      -- entity (self), player, holding data, player's data, focus hud stuff, icon hud stuff, circle60 hud ID
      -- elapsed, required time, reason
      events.player_held_interactable_failed(ent, plr, hdata, pdata, focus, icon, circle60,
        hdata.ttime, rqtime, "revoked")
    end
    return
  end
  if hdata.holder ~= plr then return end -- not us! not us!
  -- told to stop
  if hdata.stop then
    -- entity (self), player, holding data, player's data, focus hud stuff,
    -- icon hud stuff, circle60 hud ID, elapsed, required time, reason
    return events.player_held_interactable_failed(ent, plr, hdata, pdata, focus,
      icon, circle60, hdata.ttime, rqtime, "stopped")
  end
  -- if not holding any mouse button, destroy holding data and return
  local hkeys = pdata.held_keys
  if not (hkeys.RMB or hkeys.LMB) then
    ent._holding_data = nil
    -- entity (self), player, holding data, player's data, focus hud stuff,
    -- icon hud stuff, circle60 hud ID, elapsed, required time, reason
    return events.player_held_interactable_failed(ent, plr, hdata, pdata,
      focus, icon, circle60, hdata.ttime, rqtime, "stopped action")
  end
  -- continue progress
  hdata.ttime = (hdata.ttime or 0) + pdata.dtime
  -- creating or updating 60 circle
  local circle60tex = create_60circle_texture(hdata.ttime / rqtime)
  if not circle60 then
    circle60 = table.copy(huds.circle60)
    circle60 = plr:hud_add(circle60)
    pdata.circle60 = circle60
  end
  -- update text and position
  plr:hud_change(circle60, "text", circle60tex)
  plr:hud_change(circle60, "world_pos", icon.pos) --focus.mainpos:add(focus.addpos))
  -- completed!
  if hdata.ttime > rqtime then
    -- etntiy, player, holding data, player's data, focus hud table, icon hud table,
    -- circle60 hud ID, total seconds taken
    events.player_held_interactable_success(ent, plr, hdata, pdata, focus, icon, circle60, hdata.ttime)
    -- run on step
  else
    -- entity, player, hold data, player's data, focus hud table, icon hud table, circle60 hud ID,
    -- elapsed time, needed time
    events.player_held_interactable_step(ent, plr, hdata, pdata, focus, icon, circle60, hdata.ttime, rqtime)
  end
end)

-- ran when player stops looking at interactable
-- use register from event for ease of text length
-- handles deleting "holding_data" functionality above, as well as removing 60circle
events.player_looking_at_interactable_stopped.register(function(plr, pdata, focus, icon)
  -- erase 60circle
  local circle60 = pdata.circle60
  if circle60 then
    remove_circle60_hud(pdata)
  end
  -- main code
  local ent = focus.ent or icon.ent
  if not ent then return end
  -- not meant for this world
  if not ent.player_held_success then return end
  -- alright, let's find our holding data functionality
  local hdata = ent._holding_data
  if not hdata then return end -- oops! no one's home
  -- run event
  -- entity, player, hold data, player's data, focus hud table, icon hud table, circle60 hud ID,
  -- elapsed time, needed (required) time, reason
  events.player_held_interactable_failed(ent, plr, hdata, pdata, focus, icon, pdata.circle60,
    hdata.ttime, hdata.required_time, "stopped looking")
end)

-- run potential functions for interactables

-- no "start" as that should be handled by the entity's builtin functionality

-- entity, player, holding data, player's data, focus hud table, icon hud table, circle60 hud ID,
-- elapsed time, required time
events.player_held_interactable_step.register(function(ent, plr, holddata, pdata, focus, icon,
                                                       circle60, elapsed, rqtime)
  if ent.player_held_step then
    ent.player_held_step(ent, plr, holddata, pdata.dtime, elapsed, rqtime)
  end
end)
-- success and failed have less parameters
-- elapsed becomes "ttime" - total time
events.player_held_interactable_success.register(function(ent, plr, holddata, pdata, focus, icon, circle60, ttime)
  ent.player_held_success(ent, plr, holddata)
  -- clear!
  if ent then
    ent._holding_data = nil
  end
  -- delete circle60
  remove_circle60_hud(pdata)
end)
-- reason is for how it failed
events.player_held_interactable_failed.register(function(ent, plr, holddata, pdata, focus, icon, circle60,
                                                         elapsed, rqtime, reason)
  if ent.player_held_failed then
    -- entity, player, self._holding_data, total time, reason
    ent.player_held_failed(ent, plr, holddata, holddata.ttime, rqtime, reason)
  end
  -- remove entity's holddata
  ent._holding_data = nil
  -- remove 60circle hud
  if circle60 then
    remove_circle60_hud(pdata)
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
      [mod_name .. ":" .. "signal_flipper"] = true,
      [mod_name .. ":" .. "bit_bridge"] = true,
      [mod_name .. ":" .. "bit_toggler"] = true,
      [mod_name .. ":" .. "socket"] = true,
      [mod_name .. ":" .. "sensor"] = true,
      [mod_name .. ":" .. "sensor_disclaimer"] = true,
      [mod_name .. ":" .. "cave_passage_dialog"] = true,
      [mod_name .. ":" .. "sensor_power"] = true,
      [mod_name .. ":" .. "sensor_id_cartridge"] = true,
      [mod_name .. ":" .. "crawling_off_boarding"] = true,
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
      local of_mod = {}
      for value, _ in pairs(all_objects) do
        if string.find(value, mod_name) then
          table.insert(of_mod, value)
        end
      end
      table.sort(of_mod)
      for i, value in pairs(of_mod) do
        table.insert(to_list,
          string.format("button[%s,%s;%s,%s;object;%s]", pos_x, pos_y, size.x, size.z,
            string.gsub(value, mod_name .. ":", "")))
        pos_x = pos_x + size.x
        if pos_x >= (max_items * size.z) then
          pos_y = pos_y + size.z
          pos_x = 0
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

-- run other files
local modpath = core.get_modpath(mod_name)
dofile(modpath .. "/lockers.lua")
