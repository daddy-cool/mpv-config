-- Toggle HDR
--
-- Apply HDR state on every file played, auto-restore HDR state on mpv shutdown
--


msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local exePath = mp.get_script_directory() .. "/HDRCmd.exe"

local options = {
    enabled = false,
    hdr_enabled_original = false
}

local function get_options()
    read_options(options, "toggle_hdr")
    return options
end

local function set_hdr(enabled)
    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            exePath,
            "status"
        },
        capture_stdout = true
    })

    if process.status < 0 then
        msg.error('Error reading HDR status')
        do end
    end

    local hdr_enabled = process.stdout == "HDR is on"

    if hdr_enabled == enabled then
        do end
    end

    local command = enabled and "on" or "off"

    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            exePath,
            command
        }
    })
end

local function apply_hdr()
    local options = get_options()
    if options.enabled ~= true then
        do end
    end

    local colormatrix = mp.get_property("colormatrix");

    if colormatrix == "bt.2020-ncl" or colormatrix == "dolbyvision" then
        set_hdr(true)
    else 
        if colormatrix ~= nil then
            set_hdr(false)
        end
    end
end

local function restore_hdr()
    local options = get_options()
    if options.enabled ~= true then
        do end
    end

    set_hdr(options.hdr_enabled_original)
end

local function disable()
    mp.unregister_event(apply_hdr)
    mp.unregister_event(restore_hdr)
    mp.unregister_event(disable)
end

local function end_file(bind)
    if bind == "bind1" then
        restore_hdr()
    end
end

-- set HDR on every file played
mp.register_event("start-file", apply_hdr)

-- restore HDR on mpv shutdown
mp.register_event("shutdown", restore_hdr)

--disables this script
mp.register_script_message("disable", disable)

-- adjust hdr state when script-opts changes
mp.observe_property("script-opts", "string", apply_hdr)

-- restore HDR on jellyfin-mpv-shim keybind
mp.register_script_message("custom-bind", end_file)