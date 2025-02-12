--[[
    This script uses nircmd to change the refresh rate of the display that the mpv window is currently open in
    This was written because I could not get autospeedwin to work :(

    The script uses a hotkey by default, but can be setup to run on startup, see the options below for more details

    If the display does not support the specified resolution or refresh rate it will silently fail
    If the video refresh rate does not match any on the whitelist it will pick the next highest.
    If the video fps is higher than any on the whitelist it will pick the highest available
    The whitelist is specified via the script-opt 'rates'. Valid rates are separated via semicolons, do not include spaces and list in asceding order.
        Example:    script-opts=changerefresh-rates="23;24;30;60"

    You can also set a custom display rate for individual video rates using a hyphen:
        Example:    script-opts=changerefresh-rates="23;24;25-50;30;60"
    This will change the display to 23, 24, and 30 fps when playing videos in those same rates, but will change the display to 50 fps when
    playing videos in 25 Hz

    The script will keep track of the original refresh rate of the monitor and revert when either the
    correct keybind is pressed, or when mpv exits. The original rate needs to be included on the whitelist and follows
    custom rate rules (i.e. if the monitor was originally 25Hz and the whitelist contains "25-50", then it will revert to 50)

    The keybind to switch refresh rates is f10 by default, but this can be changed by setting different script bindings in input.conf. All of the valid keybinds,
    their names, and their defaults are at the bottom of this script file

    You can also send refresh change commands directly using script messages:
        script-message change-refresh [rate] [display]

    Display stands for the display number (starting from 0) which is printed to the console when the display is changed.
    Leaving out this argument will auto-detect the currently used monitor, like the usual behaviour.

    These script messages completely bypass the whitelist and rate associations and are sent to nircmd directly, so make sure you send a valid integer.
    They are also completely independant from the usual automatic reversion system, so you'll have to handle that yourself.

    Note that if the mpv window is lying across multiple displays it may not save the original refresh rate of the correct display

    See below for the full options list, don't change the defaults manually, use script opts.
]]--

msg = require 'mp.msg'
utils = require 'mp.utils'
require 'mp.options'

--options available through --script-opts=changerefresh-[option]=value
--all of these options can be changed at runtime using profiles, the script will automatically update
local options = {
    --the location of nircmd.exe, tries to use the system path by default
    nircmd = mp.get_script_directory() .. "/nircmd.exe",

    --list of valid refresh rates, separated by semicolon, listed in ascending order
    --by adding a hyphen after a number you can set a custom display rate for that specific video rate:
    --  "23;24;25-50;60"  Will set the display to 50fps for 25fps videos
    --this whitelist also applies when attempting to revert the display, so include that rate in the list
    --nircmd only seems to work with integers, DO NOT use the full refresh rate, i.e. 23.976
    rates = "23;24;25;29;30;50;59;60",

    -- list all possible resolutions here, split up into width and height
    valid_resolutions_w = "",
    valid_resolutions_h = "",

    --change refresh automatically on startup
    auto = false,

    --colour bit depth to send to nircmd
    --you shouldn't need to change this, but it's here just in case
    bdepth = "32",

    --set whether to use the estimated fps or the container fps
    --see https://mpv.io/manual/master/#command-interface-container-fps for details
    estimated_fps = false,

    --default width and height to use when reverting the refresh rate
    original_width = 3840,
    original_height = 2160,

    --if this value is set to anything but zero to script will always to to revert to this rate
    --this rate bypasses the usual rates whitelist, so make sure it is valid
    --the actual original rate will be ignored
    original_rate = 0,

    --set whether to output status messages to the osd
    osd_output = true,

    -- by how much to rewind playback to accomodate delays in changing the refresh rate
    rewind_secs = 5
}

local var = {
    --saved as strings
    dname = "",
    dnumber = "",

    --saved as numbers
    new_fps = 0,

    rateList = {},
    rates = {},
}

--is run whenever a change in script-opts is detected
function updateOptions(changes)
    msg.verbose('updating options')
    msg.debug(utils.to_string(changes))

    --only runs the heavy commands if the rates string has been changed
    if changes == nil or changes.rates then
        msg.verbose('rates whitelist has changed')

        checkRatesString()
        updateTable()
    end
end
read_options(options, 'changerefresh', updateOptions)

--checks if the rates string contains any invalid characters
function checkRatesString()
    local str = options.rates

    str = str:gsub(";", '')
    str = str:gsub("%-", '')

    if str:match("%D") then
        msg.error('Rates whitelist contains invalid characters, can only contain numbers, semicolons and hyphens. Be prepared for the script to crash')
    end
end

--creates an array of valid video rates and a map of display rates to switch to
function updateTable()
    var.rates = {}
    var.rateList = {}

    msg.verbose("updating tables of valid rates")
    for rate in string.gmatch(options.rates, "[^;]+") do
        msg.debug("found option: " .. rate)
        if rate:match("-") then
            msg.debug("contains hyphen, extracting custom rates")

            local originalRate = rate:gsub("-.*$", "")
            msg.debug("-originalRate = " .. originalRate)

            local newRate = rate:gsub(".*-", "")
            msg.debug("-customRate = " .. newRate)

            originalRate = tonumber(originalRate)
            newRate = tonumber(newRate)

            --tests for nil values caused by missing rates on either side of hyphens
            if originalRate == nil and newRate == nil then
                msg.debug('-no rates found, ignoring')
                goto loopend
            end

            if originalRate == nil then
                msg.warn("missing rate before hyphen in whitelist, ignoring option")
                goto loopend
            end
            if newRate == nil then
                msg.warn("missing rate after hyphen in whitelist for option: " .. rate)
                msg.warn("ignoring and setting " .. rate .. " to " .. originalRate)
                newRate = originalRate
            end
            var.rates[originalRate] = newRate
            rate = originalRate
        else
            rate = tonumber(rate)
            var.rates[rate] = rate
        end
        table.insert(var.rateList, rate)

        ::loopend::
    end

    if #var.rateList < 1 then
        msg.warn('rate list empty, will not be able to change refresh rate')
    end
end

--prints osd messages if the option is enabled
function osdMessage(string)
    if options.osd_output then
        mp.osd_message(string)
    end
end

--calls nircmd to change the display rate
function changeRefresh(rate, display)
    rate = tostring(rate)
    display = tostring(display)
    if display == "" then
        do return end
    end

    msg.verbose('calling nircmd with command: ' .. options.nircmd .. " setdisplay monitor:" .. display .. " " .. options.bdepth .. " " .. rate)

    msg.info("changing display " .. display .. " to " .. rate .. "Hz")
    
    width = options.original_width
    height = options.original_height

    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            options.nircmd,
            "setdisplay",
            "monitor:" .. display,
            tostring(width),
            tostring(height),
            options.bdepth,
            rate
        }
    })

    if (process.status < 0) then
        local error = process.error_string
        msg.warn(utils.to_string(process))
        msg.error('Error sending command')
        if error == "init" then
            msg.error('could not start nircmd - make sure you are using the right path')
        end
    end

    osdMessage("changing display " .. var.dnumber .. " to " .. rate .. "Hz")
end

--Finds the name of the display mpv is currently running on
--when passed display names nircmd seems to apply the command across all displays instead of just one
--so to get around this the name must be converted into an integer
--the names are in the form \\.\DISPLAY# starting from 1, while the integers start from 0
function getDisplayDetails()
    local name = mp.get_property_native('display-names')
    if name == nil then
        do return "", "0" end
    end

    --the display-fps property always refers to the display with the lowest refresh rate
    --there is no way to test which display this is, so reverting the refresh when mpv is on multiple monitors is unpredictable
    --however, by default I'm just selecting whatever the first monitor in the list is
    if #name > 1 then
        msg.warn('mpv window is on multiple displays, script may revert to wrong display rate')
    end

    name = name[1]
    msg.verbose('display name = ' .. name)

    --the last character in the name will always be the display number
    --we extract the integer and subtract by 1, as nircmd starts from 0
    local number = string.sub(name, -1)
    number = tonumber(number)
    number = number - 1

    msg.verbose('display number = ' .. number)
    return name, tostring(number)
end


--picks which whitelisted rate to switch the monitor to
function findValidRate(rate)
    msg.verbose('searching for closest valid rate to ' .. rate)
    
    --if the rate already exists in the table then the function just returns that
    if var.rates[rate] ~= nil then
        msg.verbose(rate .. ' already in list, returning matching rate: ' .. var.rates[rate])
        return var.rates[rate]
    end

    local closestRate
    rate = tonumber(rate)

    --picks either the same fps in the whitelist, or the next highest
    --if none of the whitelisted rates are higher, then it uses the highest
    for i = 1, #var.rateList, 1 do
        closestRate = var.rateList[i]
        msg.debug('comparing ' .. rate .. ' to ' .. closestRate)
        if (closestRate >= rate) then
            break
        end
    end

    if closestRate == nil then
        closestRate = 0
    end
    msg.verbose('closest rate is ' .. closestRate .. ', saving...')

    --saves the rate to reduce repeated searches
    var.rates[rate] = var.rates[closestRate]

    return closestRate
end

--executes commands to switch monior to video refreshrate
function matchVideo()    
    if options.auto == false then
        do return end
    end
    
    local old_rate = mp.get_property('display-fps')
    if old_rate == nil then
        do return end
    end

    --gets display details
    local dname, dnumber = getDisplayDetails()

    if dname == "" then
        do return end
    end

    --if the change is executed on a different monitor to the previous, and the previous monitor has not been been reverted
    --then revert the previous changes before changing the new monitor
    if var.dname ~= dname then
        msg.verbose('changing new display, reverting old one first')
        revertRefresh()
    end
    
    --saves the current name and number for next time
    var.dname = dname
    var.dnumber = dnumber

    local new_fps = nil

    --saves either the estimated or specified fps of the video
    if (options.estimated_fps == true) then
        new_fps = mp.get_property_number('estimated-vf-fps', 0)
    else
        new_fps = mp.get_property_number('container-fps', 0)
    end

    if new_fps == nil or new_fps < 23 then
        do return end
    end
    
    --Floor is used because 23fps video has an actual framerate of ~23.9, this occurs across many video rates
    new_fps = math.floor(new_fps)

    --picks which whitelisted rate to switch the monitor to based on the video rate
    new_fps = findValidRate(new_fps)

    
    if  math.floor(old_rate) ~= math.floor(new_fps) then
        changeRefresh(new_fps, dnumber)
        mp.command("seek -" .. options.rewind_secs .. " relative+exact")
    end
end

--reverts the monitor to its original refresh rate
function revertRefresh()
    if options.auto == false then
        do return end
    end

    if options.original_rate ~= 0 then
        msg.verbose("reverting refresh rate")
        changeRefresh(options.original_rate, var.dnumber)
    end
end

--toggles between using estimated and specified fps
function toggleFpsType()
    if options.estimated_fps then
        options.estimated_fps = false
        osdMessage("[Change-Refresh] now using container fps")
        msg.info("now using container fps")
    else
        options.estimated_fps = true
        osdMessage("[Change-Refresh] now using estimated fps")
        msg.info("now using estimated fps")
    end
    return
end

function scriptMessage(rate, display)
    local name
    if display == nil then
        name, display = getDisplayDetails()
    end

    if rate == nil then
        msg.warn('script message must include a rate')
        return
    end

    msg.verbose('recieved script message: ' .. rate .. ' ' .. display)
    changeRefresh(rate, display)
end

local function disable()
    mp.unregister_event(matchVideo)
    mp.unregister_event(revertRefresh)
    mp.unregister_event(toggleFpsType)
    mp.unregister_event(scriptMessage)
    mp.unregister_event(autoChange)
    mp.unregister_event(revertRefresh)
    mp.unregister_event(disable)
end

local function end_file(bind)
    if bind == "bind1" then
        revertRefresh()
    end
end

updateOptions()

--sends a command to switch to the specified display rate
--syntax is: script-message change-refresh [rate] [display]
mp.register_script_message("change-refresh", scriptMessage)

mp.add_periodic_timer(1, matchVideo)

--reverts refresh on mpv shutdown
mp.register_event("shutdown", revertRefresh)

--disables this script
mp.register_script_message("disable", disable)

-- restore refresh rate on jellyfin-mpv-shim keybind
mp.register_script_message("custom-bind", end_file)

-- -- adjust options
-- mp.observe_property("script-opts", "string", read_options)