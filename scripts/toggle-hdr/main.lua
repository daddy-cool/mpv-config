-- Toggle HDR
--
-- Apply HDR state on every file played, auto-restore HDR state on mpv shutdown
--


msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local hdr_cmd = mp.get_script_directory() .. "/HDRCmd.exe"

local options = {
    enabled = true,
    hdr_enabled_original = false,
    rewind_secs = 5
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
            hdr_cmd,
            "status"
        },
        capture_stdout = true
    })

    if process.status < 0 then
        msg.error('Error reading HDR status')
        return false
    end

    local hdr_enabled = process.stdout:match("HDR is on") ~= nil

    if hdr_enabled == enabled then
        return false
    end

    local command = enabled and "on" or "off"

    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            hdr_cmd,
            command
        }
    })

    return true
end

local function apply_hdr()
    local options = get_options()
    if options.enabled ~= true then
        do return end
    end

    local applied_hdr = false

    local colormatrix = mp.get_property("colormatrix")
    if colormatrix == nil then
        do return end
    end

    if colormatrix:match("bt.2020") ~= nil or colormatrix:match("dolby") ~= nil then
        applied_hdr = set_hdr(true)
    else 
        applied_hdr = set_hdr(false)
    end

    if applied_hdr then
        mp.command("seek -" .. options.rewind_secs .. " relative+exact")
    end
end

local function restore_hdr()
    local options = get_options()
    if options.enabled ~= true then
        do return end
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

mp.add_periodic_timer(1, apply_hdr)

--mp.register_event('start-file', apply_hdr)

-- restore HDR on mpv shutdown
mp.register_event("shutdown", restore_hdr)

--disables this script
mp.register_script_message("disable", disable)

-- adjust hdr state when script-opts changes
mp.observe_property("script-opts", "string", apply_hdr)

-- restore HDR on jellyfin-mpv-shim keybind
mp.register_script_message("custom-bind", end_file)