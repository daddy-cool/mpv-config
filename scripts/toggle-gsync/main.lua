-- Toggle GSYNC
--
-- Auto-disable GSync on first file played, auto-reenable GSync on mpv shutdown
--


msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local exePath = mp.get_script_directory() .. "/GsyncSwitch/GsyncSwitchCli.exe"

local state = {
    wasDisabled = false
}

local options = {
    enabled = false
}

local function isEnabled()
    read_options(options, "toggle_gsync")
    return options.enabled
end

local function disableGsync()
    if isEnabled() == false or state.wasDisabled == true then
        do return end
    end

    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            exePath,
            "disable-gsync"
        }
    })

    if process.status >= 0 then
        state.wasDisabled = true
    else
        --local error = process.error_string
        msg.error('Error disabling GSYNC')
    end
end

local function enableGsync()
    if isEnabled() == false or state.wasDisabled == false then
        do return end
    end

    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            exePath,
            "enable-gsync"
        }
    })

    if process.status >= 0 then
        state.wasDisabled = false
    else
        --local error = process.error_string
        msg.error('Error enabling GSYNC')
    end
end

local function disable()
    mp.unregister_event(enableGsync)
    mp.unregister_event(disableGsync)
    mp.unregister_event(verifyGsync)
    mp.unregister_event(disable)
end

local function verifyGsync()
    if isEnabled() == false and state.wasDisabled == true then
        enableGsync()
    elseif isEnabled() == true and state.wasDisabled == false then
        disableGsync()
    end
end

-- disable Gsync on first file played
mp.register_event("start-file", disableGsync)

-- enable Gsync on mpv shutdown
mp.register_event("shutdown", enableGsync)

--disables this script
mp.register_script_message("disable", disable)

-- adjust gsync state when script-opts changes
mp.observe_property("script-opts", "string", verifyGsync)