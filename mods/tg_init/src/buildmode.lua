local buildmode = core.settings:get_bool("tg_build_mode", false)
if buildmode then
    core.settings:set_bool("creative_mode", true)
    function core.is_creative_enabled()
        return true
    end
else
    core.settings:set_bool("creative_mode", false)
    function core.is_creative_enabled()
        return false
    end
end