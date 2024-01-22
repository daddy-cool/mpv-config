msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local options = {
    enabled = false,
    timeout = 10
}

local timer

local function isEnabled()
    read_options(options, "hang_detect")
    return options.enabled
end

local function reload()
    msg.warn("Playback timeout, quitting")
    mp.set_property("save-position-on-quit", "no")
    mp.command("quit")
end

local function startTimer()
    if isEnabled() == false then
        do return end
    end

    timer = mp.add_timeout(options.timeout, reload)
end

local function endTimer()
    if timer ~= nil then
        timer:kill()
    end
end

mp.register_event("file-loaded", startTimer)
mp.register_event("playback-restart", endTimer)