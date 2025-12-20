local mod_name = core.get_current_modname()

tg_dialog = {}

-- implement something similar to TP's animated popup stuff

function tg_dialog.dialog(player,msg)
  core.chat_send_player(player:get_player_name(),"from new dialog: "..msg)
end
