msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local options = {
    enabled = true
}

local function isEnabled()
    read_options(options, "eof")
    return options.enabled
end

local function on_unload()
    if isEnabled() == false then
        do return end
    end

    local percent_pos = mp.get_property_number("percent-pos")
    if percent_pos < 95 then
        do return end
    end

    mp.command("delete-watch-later-config")
end

mp.add_hook("on_unload", 50, on_unload)