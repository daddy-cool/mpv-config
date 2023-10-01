-- GSYNC SWITCH
--
-- Auto-disable GSync on first file played, auto-reenable GSync on mpv shutdown
--


msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local statePath = mp.command_native({"expand-path", "~~/script-opts" .. "/gsync-switch.json"})
local exePath = mp.get_script_directory() .. "/gsync-switch.exe"

local state = {
    gsync_active = true
}

local options = {
    enabled = false,
    pauseSeconds = 3
}

local function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and io.close(f)
 end
 

local function loadState()
    if not file_exists(statePath) then
        do return end
    end

    local file = assert(io.open(statePath))
    local json = file:read("*all")
    file:close()

    local newState = utils.parse_json(json)
    if newState then
        state = newState
    else
        msg.error("Invalid JSON format in gsync-switch.json")
    end
end

local function saveState()
    local file = io.open(statePath, "w+")
    local json, _ = utils.format_json(state)
    file:write(json)
    file:close()
end

local function toggleGsync()
    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            exePath
        }
    })

    if process.status >= 0 then
        state.gsync_active = not state.gsync_active
        saveState()
        -- msg.info("Switched GSYNC active state to " .. tostring(state.gsync_active))
    else
        local error = process.error_string
        msg.error('Error switching GSYNC active state')
    end
end

local function isEnabled()
    read_options(options, "gsync_switch")
    return options.enabled
end

local function disableGsync()
    if isEnabled() == false then
        do return end
    end

    loadState()
    if state.gsync_active == true then
        toggleGsync()

        if options.pauseSeconds > 0 and not mp.get_property_bool("pause") then
            mp.set_property_bool("pause", true)
            mp.add_timeout(options.pauseSeconds, function()
                mp.set_property_bool("pause", false)
                mp.commandv("seek", -1) -- workaround, somehow mpv gets stuck sometimes
            end)
        end
    end
end

local function enableGsync()
    if isEnabled() == false then
        do return end
    end

    loadState()
    if state.gsync_active == false then
        toggleGsync()
    end
end

mp.register_event("start-file", disableGsync)
mp.register_event("shutdown", enableGsync)
