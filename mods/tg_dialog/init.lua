local mod_name = core.get_current_modname()

tg_dialog = {}

---@class dialog
---@field msg string
---@field id number
local dialog = {}              -- stores player's dialog to display

tg_dialog.sound_enabled = true -- maybe someone does not want the sound to play?

---dialog to display to the player
---@param player any
---@param msg string
---@param override nil|boolean skip the prev dialog
function tg_dialog.dialog(player, msg, override)
  if dialog[player:get_player_name()] == nil then
    dialog[player:get_player_name()] = { msgs = {} }
  end
  if override == true then
    local id = dialog[player:get_player_name()].id
    if id ~= nil then
      player:hud_remove(id)
    end
    dialog[player:get_player_name()] = { msgs = { msg } }
    return
  end
  table.insert(dialog[player:get_player_name()].msgs, msg)
end

local tick = 0 -- someone has to like ticks
core.register_globalstep(function(dtime)
  tick = tick + 1
  if tick <= 1 then
    return
  end
  tick = 0
  local players = core.get_connected_players()
  if #players < 0 then return end -- don't do anything below until there's a player
  for _, player in ipairs(players) do
    for pname, msgs in pairs(dialog) do
      if pname == player:get_player_name() then
        -- need hud
        local hud = {
          type = "text",
          precision = 0,
          scale = { x = 10, y = 10 },
          alignment = { x = 0, y = 0 },
          position = { x = 0.5, y = 0.8 },
          number = 0xFFFFFF,
          z_index = -300,
          text = "",
        }
        if #msgs.msgs <= 0 then
          return -- i do not like this patch
        end

        local msg_length = #msgs.msgs[1]
        if msgs.id == nil then -- lets go ahead and get this all started. this gets reset after cleartime reaches zero
          local hud_id = player:hud_add(hud)
          msgs.id = hud_id
          msgs.text_index = 1
          msgs.cleartime = 0
          msgs.sound_tick = msg_length
          -- spaces make the message stay on screen longer, giving the player time to read it all.
          for i = 1, msg_length, 1 do
            if msgs.msgs[1]:sub(i, i) == " " then
              msgs.cleartime = msgs.cleartime + 1
            end
          end
          msgs.cleartime = msgs.cleartime +
          (20 * 4)                                                                 -- double it and give it to the next guy
        else
          player:hud_change(msgs.id, "text", msgs.msgs[1]:sub(1, msgs.text_index)) -- this should advance the msg example: (your moms a h[.].)
          if msgs.sound_tick >= 1 then                                             -- lets play some fancy sound
            msgs.sound_tick = msgs.sound_tick - 1
            if tg_dialog.sound_enabled == true then
              core.sound_play({ name = "tg_paper_footstep" }, {
                gain = 0.3,   -- default
                fade = 100.0, -- default
                pitch = 2.0,  -- 1.0, -- default
              })
            end
          end
          -- once cleartime reaches zero remove msg.
          if msgs.text_index >= msg_length then
            msgs.cleartime = msgs.cleartime - 1
            if msgs.cleartime == 0 then
              player:hud_remove(msgs.id)
              msgs.id = nil
              table.remove(msgs.msgs, 1)
              if #msgs.msgs <= 1 then
                local dialog_index = 0
                for f_pname, value in pairs(dialog) do
                  if f_pname ~= pname then
                    dialog_index = dialog_index + 1
                  end
                end
                if dialog_index > 0 then
                  table.remove(dialog, dialog_index - 1)
                end
              end
            end
          else
            msgs.text_index = msgs.text_index + 1
          end
        end
      end
    end
  end
end)
