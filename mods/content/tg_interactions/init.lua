local mod_name = core.get_current_modname()
local S = core.get_translator(mod_name)

tg_interactions = {}

core.log("yes this is loading")

core.register_entity(mod_name .. ":" .. "draggable", {
  initial_properties = {
    visual = "mesh",
    mesh = "tubes.glb",
    textures = { "tubes.png" },
    visual_size = {x = 10, y = 10, z = 10},
    physical = true,
  },
  _being_dragged = false,

  on_step = function(self, dtime, moveresult)
    if self.object:get_luaentity()._being_dragged == false then
      core.log("no drag on me")
    end
    core.log("I do be stepping")
  end,
  on_rightclick = function(self, clicker)
    -- self.object:get_luaentity()._being_dragged == 
  end,
})
