msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local options = {
    enabled = true,
    socketName = "/tmp/mpv-socket"
}

local function isEnabled()
    read_options(options, "single_instance")
    return options.enabled
end

local function quit()
    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            "cmd",
            "/Q",
            "/C",
            "echo quit-watch-later > \\\\.\\pipe\\tmp\\mpv-socket"
        },
        capture_stderr = true
    })
end

local function isQuit()
    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            "cmd",
            "/Q",
            "/C",
            "echo ignore > \\\\.\\pipe\\tmp\\mpv-socket"
        },
        capture_stderr = true
    })

    if process.stderr:find("The system cannot find the file specified.") or process.stderr:find("Das System kann die angegebene Datei nicht finden.") then
        return true
    else
        return false
    end
end

local function singleInstance()
    if isEnabled() == false then
        do return end
    end

    quit()

    for tries = 0, 1000, 1 do
        if isQuit() == true then
            mp.set_property("input-ipc-server", options.socketName)
            break
        end

        if tries >= 999 then
            msg.error("previous mpv instance did not quit, quitting")
            mp.command("quit")
            break
        else
            if tries == 0 then
                msg.info("waiting for previous mpv instance to quit")
            end
        end
    end
end

mp.add_hook("on_load", 50, singleInstance)