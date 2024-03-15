msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local startUp = true

local options = {
    enabled = true,
    socketName = "/tmp/mpv-socket"
}

local function isEnabled()
    read_options(options, "single_instance")
    return options.enabled
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

local function quitOtherInstance()
    if startUp == false then
        do return end
    end

    if isEnabled() == false then
        do return end
    end

    mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            "cmd",
            "/Q",
            "/C",
            "echo script-message-to single_instance quit > \\\\.\\pipe\\tmp\\mpv-socket"
        },
        capture_stderr = true
    })
end

local function quit()
    mp.command("script-message disable")
    mp.command("quit")
end

local function verify(hook)
    if startUp == false then
        do return end
    end
    startUp = false

    if isEnabled() == false then
        do return end
    end

    hook:defer()
    local quitTimer

    local function checkOtherInstance()
        if isQuit() == true then
            mp.set_property("input-ipc-server", options.socketName)
            hook:cont()
            if quitTimer ~= nil then
                quitTimer:kill()
            end
            return true
        else
            mp.add_timeout(0.1, checkOtherInstance)
            return false
        end
    end

    if checkOtherInstance() == false then
        msg.info("waiting for previous mpv instance to quit")
        quitTimer = mp.add_timeout(5, quit)
    end
end

mp.add_hook("on_load", 50, quitOtherInstance)
mp.add_hook("on_preloaded", 50, verify)
mp.register_script_message("quit", quit)