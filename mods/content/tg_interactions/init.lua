local mod_name = core.get_current_modname()
local S = core.get_translator(mod_name)

tg_interactions = {}

local gravity = -9.8

local function debug(msg)
  core.log("[entity]: " .. msg)
end

---comment
---@param name string
---@param model_type string "mesh"|"node"
---@param model string model_name or mod_name:node
---@param texture string
---@param shape shape
---@param weight number
function tg_interactions.register_entity(name, model_type, model, texture, shape, weight)
  local function drop(self)
    self.object:get_luaentity().physical = true
    self.object:get_luaentity()._being_dragged = false
    self.object:get_luaentity()._dragged_by = ""
  end
  local def = {
    _being_dragged = false,
    _dragged_by = "",

    _acc = 0,
    _weight = weight,
    _speed = 3, -- speed should change depending on how far the player is
    _popup_msg = "drag\nx",
    _prev_sound = nil,
    _sound_tick = 0,

    on_step = function(self, dtime, moveresult)
      debug("I do be stepping")
      if self.object:get_luaentity()._being_dragged == false then
        debug("no drag on me")
      else
        -- if _being_dragged get all objects within radius, if player
        -- and player name is equal to dragger.. get closer
        -- if no players are around then no drag.
        debug("i am getting dragged")
        local cur_pos = self.object:get_pos()
        local max_distance = 2
        local entites = core.get_objects_inside_radius(cur_pos, max_distance)
        local found_player = false
        for index, value in ipairs(entites) do
          if value:is_player() then
            debug("we have found a player")
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

                local mid_point = tg_main.calculateMidpoint(player_pos, cur_pos)
                local obj_speed = self.object:get_luaentity()._speed
                -- local speed = (self.object:get_luaentity()._speed * player_distance) * dtime
                local speed = math.min(obj_speed * dtime, 1)
                self.object:move_to(tg_main.lerp(cur_pos, mid_point, speed), true)
                self.object:set_yaw(angle)

                -- play sound while being dragged
                local tick = self.object:get_luaentity()._sound_tick
                tick = tick + 1
                self.object:get_luaentity()._sound_tick = tick
                if tick >= 15 then
                  self.object:get_luaentity()._sound_tick = 0
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
                    gain = 1.0,     -- default
                    fade = 0.0,     -- default
                    pitch = pitch,  -- 1.0, -- default
                  })
                  self.object:get_luaentity()._prev_sound = playing_sound
                end
              end
            else
            end
          end
        end
        if #entites <= 1 or found_player == false then
          debug("dragger is gone")
          drop(self)
        end

        -- local player =

        -- if player is at least .5m away from the object move closer to player
        -- tg_main.distance(cur_pos,)
      end
      debug("dragger: " .. self.object:get_luaentity()._dragged_by)
    end,
    on_rightclick = function(self, clicker)
      local cur_value = self._being_dragged
      self.object:get_luaentity()._being_dragged = not cur_value
      self.object:get_luaentity()._dragged_by = clicker:get_player_name()
      local obj_weight = self.object:get_luaentity()._weight
      clicker:set_physics_override({ speed = 1.1 / obj_weight, jump = 0.5, speed_fast = 2.1 / obj_weight })
      if cur_value == true then
        drop(self)
        clicker:set_physics_override({ speed = 1, jump = 1, speed_fast = 1 })
      end
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
  end
  core.register_entity(mod_name .. ":draggable_" .. name, def)
end

tg_interactions.register_entity("chair", "node", "tg_furniture:oak_chair", "tg_ndoes_steel_enclosure.png",
  tg_nodes["shapes"].slim_box, 2)
tg_interactions.register_entity("pipes", "mesh", "tubes.glb", "tubes.png", tg_nodes["shapes"].slab, 4)

-- player hover over interactables
core.register_globalstep(function(dtime)
  local players = core.get_connected_players()
  if #players > 0 then
    for _, player in ipairs(players) do
      local eye_height = player:get_properties().eye_height
      local player_look_dir = player:get_look_dir()
      local pos = player:get_pos():add(player_look_dir)
      local player_pos = { x = pos.x, y = pos.y + eye_height, z = pos.z }
      local new_pos = player:get_look_dir():multiply(4):add(player_pos)
      local raycast_result = core.raycast(player_pos, new_pos, true, false):next()

      core.log("so what is this: " .. dump(raycast_result))
      if raycast_result == nil then
        return
      end
      if raycast_result.type == "object" then
        -- core.log("who dis: "..dump(raycast_result.ref:get_luaentity()))
        -- core.log("who dis: "..dump(raycast_result.ref:get_luaentity()))
        -- local hover_popup = raycast_result.ref:get_luaentity()._popup_msg
        -- core.log("who dis: " .. hover_popup)
      end


      -- local text_message = player:hud_add({
      --   hud_elem_type = "text",
      --   -- position = { x = 0.43, y = 0.5 }, -- 0.42 seems to center the text better.
      --   text = messages[current_message],
      --   alignment = { x = 0, y = 0 },
      --   scale = { x = 100, y = 100 },
      --   number = 0xFFFFFF,
      --   size = { x = 4, y = 4 },
      -- })
    end
  end
end)
