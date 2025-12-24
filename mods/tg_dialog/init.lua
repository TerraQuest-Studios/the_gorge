local mod_name = core.get_current_modname()

tg_dialog = {}

-- implement something similar to TP's animated popup stuff

---@class dialog
---@field msg string
---@field id number
local dialog = {} -- stores message text and entity

function tg_dialog.dialog(player, msg)
  dialog[player:get_player_name()] = {msg = msg}
end

local tick = 0
core.register_globalstep(function(dtime)
  tick = tick + 1
  if tick <= 1 then
    return
  end
  tick = 0
  local players = core.get_connected_players()
  if #players < 0 then return end -- don't do anything below until there's a player
  for _, player in ipairs(players) do
    for pname, msg in pairs(dialog) do
      if pname == player:get_player_name() then
        -- need hud
        local hud = {
          type = "text",
          precision = 0,
          scale = { x = 10, y = 10 },
          alignment = { x = 0, y = 0 },
          position = { x = 0.5, y = 0.8 }, -- 0.42 seems to center the text better.
          number = 0xFFFFFF,
          z_index = -300,
          text = "",
          -- world_pos = { x = 0, y = 1, z = 0 },
        }
        -- core.chat_send_player(value.player_name, "from new dialog: " .. value.msg)
        local msg_length = #msg.msg
        if msg.id == nil then
          local hud_id = player:hud_add(hud)
          msg.id = hud_id
          msg.text_index = 1
          msg.cleartime = 0
          for i = 1, msg_length, 1 do
            -- core.log("yo: "..i)
            if msg.msg:sub(i,i) == " " then
              msg.cleartime = msg.cleartime + 1
              -- core.log("what are you on about?")
            end
          end
          msg.cleartime = msg.cleartime * 12
          core.log("cleartime: "..msg.cleartime)
        else
          player:hud_change(msg.id,"text",msg.msg:sub(1,msg.text_index)) -- this should advance the msg
          if msg.text_index >= msg_length then
            msg.cleartime = msg.cleartime - 1
            if msg.cleartime == 0 then
              -- rmeove when no more messages
              player:hud_remove(msg.id)
            end
          else
            msg.text_index = msg.text_index + 1
          end
        end
        -- if DONE do the rest
      end
    end
  end
end)
