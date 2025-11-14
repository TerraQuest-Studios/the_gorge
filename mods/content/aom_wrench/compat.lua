
-- in case no itemextensions, imitate it loosely
if core.get_modpath("itemextensions") ~= nil then return end

local pl = {}

local function check_player(player)
    if not pl[player] then pl[player] = {} end
    return pl[player]
end

core.register_globalstep(function(dtime)
    for i, player in ipairs(core.get_connected_players()) do repeat
        local wstack = player:get_wielded_item()
        local wdef = wstack:get_definition()
        -- don't do anything more if no callbacks, but do one test after
        local has_callbacks = (wdef._on_step ~= nil) or (wdef._on_select ~= nil) or (wdef._on_deselect ~= nil)
        if not has_callbacks and (pl[player] == nil) then
            break
        end
        local pi = check_player(player)

        local diff_item = (pi.lstack == nil) or (not pi.lstack:equals(wstack))
        if diff_item and pi.ldef and pi.ldef.on_deselect then
            pi.ldef.on_deselect(pi.lstack, player)
        end

        if diff_item and wdef._on_select then
            wdef._on_select(wstack, player)
        end

        if wdef._on_step then
            wdef._on_step(wstack, player, dtime)
        end

        -- no need to keep track anymore
        if not has_callbacks then
            pl[player] = nil
        else
            pi.lstack = wstack
            pi.ldef = wdef
        end
    until true end
end)
