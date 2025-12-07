local mod_name = core.get_current_modname()

-- tg_robot = {}

local gravity = -0.9

core.register_entity(mod_name .. ":" .. "robot", {
  initial_properties = {
    visual = "mesh",
    mesh = "tg_robot.glb",
    visual_size = { x = 1, y = 1, z = 1 },
    -- visual = "wielditem",
    -- wield_item = "tg_furniture:oak_chair",
    -- visual_size = { x = 0.65, y = 0.65, z = 0.65 }, -- i guess this is the size for drawtype node
    textures = { "tg_robot.png^(tg_overlay_dirt_0.png^[multiply:#112^[opacity:160)" },
    physical = true,
    -- collide_with_objects = true,
    collisionbox = { -0.8, -0.0, -0.7, 0.8, 2.8, 0.7 },
    -- selectionbox = shape,
  },
  _interactable = 1,
  _interactable_pos = vector.to_string(vector.new(0, 1.8, 0)), --shoud be at center of the collisionbox
  _popup_msg = "[ M2. Mechanoid ]",
  on_step = function(self, dtime, moveresult)
    local velocity = self.object:get_velocity()
    self.object:set_velocity(vector.add(velocity, vector.new(0, gravity, 0)))
  end,
  on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
    if puncher:get_player_control().sneak == true then
      if tg_main.dev_mode == true then
        self.object:remove()
      end
    end
  end,
  on_rightclick = function(self, clicker)
    -- local player_name = clicker:get_player_name()
    -- local walk_start = { x = 1.2, y = 3.25 }
    -- local walk_end = { x = 1.7, y = 3.29 }

    -- local walking = { x = 1.7, y = 3.29 } -- good
    -- local rummage = { x = 3.40, y = 4.95 } -- not perfect
    local cut = { x = 5, y = 6.5 }  -- good?

    -- local all = { x = 0, y = 7 }
    self.object:set_animation(cut, 0.2, 1, false)
  end,
})
