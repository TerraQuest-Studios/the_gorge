-- this code handles wielded events and item callbacks

-- create events for player handling
local events = {}
for _, ename in ipairs({ -- for _, event name
    -- wielded item changed somehow
    "wieldchange",
    -- uneqipped
    "wieldold",
    -- general step
    "wieldstep"
}) do
    -- name, automatic setup definition: add register function to `tg_interactions`
    -- return will be data of this event
    events[ename] = events_api.create(ename, {global = tg_player})
end

-- handle wield events
tg_player.register_on_step(function(plr, pdata)
    -- player's wielded item
    local oldwield = pdata.wielded
    local wielded = plr:get_wielded_item()
    wielded = {stack = wielded, index = plr:get_wield_index(),
      def = wielded:get_definition() or
      -- create a "ghost" definition in failure
      {name = wielded:get_name()} }
    pdata.wielded = wielded
    -- run wielded item change
    -- "wielded change reason"
    local WCR = oldwield and oldwield.def and (
        -- selecting a dif item
        oldwield.index ~= wielded.index and "index changed" or
        -- dropped? depleted?
        wielded.def.name == "" and "empty" or
        -- name change, so wielded changed somehow
        oldwield.def.name ~= wielded.def.name and "name change" or
        -- unchanged
        "unchanged"
    -- no wield yet
    ) or "null"
    -- general wielded change
    if WCR ~= "unchanged" then
        -- player, player's data, wielded data, reason
        events.wieldchange(plr, pdata, wielded, WCR)
        -- do event for old
        if oldwield and oldwield.def then
            -- player, player's data, old wielded data, reason
            events.wieldold(plr, pdata, oldwield, WCR)
        end
    -- run on step
    elseif wielded then
        local dtime = pdata.dtime or 0
        -- player, player's data, wielded data, delta time
        events.wieldstep(plr, pdata, wielded, dtime)
    end
end)

-- wielded item callbacks
-- equipped
events.wieldchange.register(function(plr, pdata, wdata, reason)
    local def = wdata.def
    if def.wield_equipped then
        -- player, wielded item, definition of said item, current selected index,
        -- reason for this change, player's data
        def.wield_equipped(plr, wdata.stack, def, wdata.index, reason, pdata)
    end
end)
-- unequipped (for any reason)
events.wieldold.register(function(plr, pdata, wdata, reason)
    local def = wdata.def
    if def.wield_unequipped then
        -- player, old item, definition of said old item, old selected index,
        -- reason for this change, player's data
        def.wield_unequipped(plr, wdata.stack, def, wdata.index, reason, pdata)
    end
end)
-- step
events.wieldstep.register(function(plr, pdata, wdata, dtime)
    local def = wdata.def
    if def.wield_step then
        -- player, wielded item, definition of said item, current selected index, delta time, player's data
        def.wield_step(plr, wdata.stack, def, wdata.index, dtime, pdata)
    end
end)
