local mod_name = core.get_current_modname()
local S = core.get_translator(mod_name)

tg_interactions = {}

local gravity = -9.8

function tg_interactions.register_entity()
  local function drop(self)
    self.object:get_luaentity().physical = true
    self.object:get_luaentity()._being_dragged = false
    self.object:get_luaentity()._dragged_by = ""
  end
  core.register_entity(mod_name .. ":" .. "draggable", {
    initial_properties = {
      -- visual = "mesh",
      -- mesh = "tubes.glb",
      -- visual_size = { x = 10, y = 10, z = 10 },
      visual = "wielditem",
      wield_item = "tg_furniture:oak_chair",
      visual_size = { x = 0.65, y = 0.65, z = 0.65 }, -- i guess this is the size for drawtype node
      textures = { "tubes.png" },
      physical = true,
      -- collide_with_objects = true,
      collisionbox = tg_nodes["shapes"].slim_box,
      selectionbox = tg_nodes["shapes"].slim_box,
    },
    _being_dragged = false,
    _dragged_by = "",

    on_step = function(self, dtime, moveresult)
      core.log("I do be stepping")
      if self.object:get_luaentity()._being_dragged == false then
        core.log("no drag on me")
      else
        -- if _being_dragged get all objects within radius, if player
        -- and player name is equal to dragger.. get closer
        -- if no players are around then no drag.
        core.log("i am getting dragged")
        local cur_pos = self.object:get_pos()
        local max_distance = 2
        local entites = core.get_objects_inside_radius(cur_pos, max_distance)
        local found_player = false
        for index, value in ipairs(entites) do
          if value:is_player() then
            core.log("we have found a player")
            local player_name = value:get_player_name()
            if player_name == self.object:get_luaentity()._dragged_by then
              found_player = true
              self.object:get_luaentity().physical = false
              local player_pos = value:get_pos()
              if tg_main.distance(player_pos, cur_pos) > 1.2 then
                local new_pos = vector.add(player_pos, vector.new(0, 1, 0))
                local dirX = player_pos.x - cur_pos.x
                local dirY = player_pos.y - cur_pos.y
                -- Calculate angle in radians
                local angle = math.atan2(dirY, dirX)

                self.object:move_to(tg_main.calculateMidpoint(player_pos, cur_pos), true)
                self.object:set_yaw(angle)
              end
            else
            end
          end
        end
        if #entites <= 1 or found_player == false then
          core.log("dragger is gone")
          drop(self)
        end

        -- local player =

        -- if player is at least .5m away from the object move closer to player
        -- tg_main.distance(cur_pos,)
      end
      core.log("dragger: " .. self.object:get_luaentity()._dragged_by)
    end,
    on_rightclick = function(self, clicker)
      local cur_value = self._being_dragged
      self.object:get_luaentity()._being_dragged = not cur_value
      self.object:get_luaentity()._dragged_by = clicker:get_player_name()
      if cur_value == true then
        drop(self)
      end
    end,
  })
end

tg_interactions.register_entity()
