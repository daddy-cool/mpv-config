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

local function singleInstance()
    if startUp ~= true then
        do return end
    end
    startUp = false

    if isEnabled() == false then
        do return end
    end

    --msg.info(mp.get_property("path"))

    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            "cmd",
            "/k",
            "echo loadfile '" .. mp.get_property("path") .. "' replace >\\\\.\\pipe\\tmp\\mpv-socket"
        },
        capture_stderr = true
    })

    if process.stderr ~= "" then
        --msg.info(process.stderr)
        mp.set_property("input-ipc-server", options.socketName)
    else
        msg.info("socket found")
        mp.command("quit")
    end
end

mp.register_event("start-file", singleInstance)
