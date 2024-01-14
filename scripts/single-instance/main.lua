msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local batPath = mp.get_script_directory() .. "/send_keys.bat"

local startUp = true

local options = {
    enabled = true,
    socketName = "/tmp/mpv-socket"
}

local function isEnabled()
    read_options(options, "single_instance")
    return options.enabled
end

local function escapeForCmd(str)
    return str:gsub("&", "^&"):gsub("%%", "%%%%")
end


local function singleInstance()
    local path = mp.get_property("path")
    if path == nil then
        do return end
    end
    
    if startUp ~= true then
        do return end
    end
    startUp = false

    if isEnabled() == false then
        do return end
    end
    
    local process = mp.command_native({
        name = 'subprocess',
        args = {
            "cmd",
            "/Q",
            "/C",
            "echo script-message-to " .. mp.get_script_name() .. " override-playback '" .. escapeForCmd(path) .. "' >\\\\.\\pipe\\tmp\\mpv-socket"
        },
        capture_stderr = true
    })

    if process.stderr:find("The system cannot find the file specified.") or process.stderr:find("Das System kann die angegebene Datei nicht finden.") then
        msg.info("No previous MPV instance detected, starting playback")
        mp.set_property("input-ipc-server", options.socketName)
    else
        msg.info("Previous MPV instance detected, quitting")
        mp.set_property("save-position-on-quit", "no")
        mp.command("quit")
    end
end

local function override_playback(path)
    mp.command_native({
        name = 'subprocess',
        args = {
            batPath,
            mp.get_property("pid"),
            ""
        }
    })
    
    mp.commandv("loadfile", path)
end

mp.register_event("start-file", singleInstance)
mp.register_script_message("override-playback", override_playback)