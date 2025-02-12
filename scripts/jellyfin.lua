msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local options = {
    enabled = false
}

local function isEnabled()
    read_options(options, "jellyfin")
    return options.enabled
end

local function select_subtitles() 
  mp.set_property("aid", "auto")
  mp.set_property("sid", "auto")
  mp.commandv('script-message-to', 'sub_select', 'select-subtitles')
end

local function jellyfin()
  if isEnabled() == false then
    do return end
  end

  -- jellyfin mpv shim compatiblity keybinds
  mp.command("keybind esc 'script-message custom-bind bind1'")
  mp.command("keybind alt+left 'script-message custom-bind bind4'")
  mp.command("keybind alt+right 'script-message custom-bind bind5'")
  
  -- jellyfin mpv shim compatiblity for uosc
  mp.commandv('script-message-to', 'uosc', 'overwrite-binding', 'prev', 'script-message custom-bind bind4')
  mp.commandv('script-message-to', 'uosc', 'overwrite-binding', 'next', 'script-message custom-bind bind5')
  mp.commandv('script-message-to', 'uosc', 'disable-elements', mp.get_script_name(), 'top_bar')

  -- jellyfin mpv shim overwrites some keybinds fix
  mp.command("keybind right 'seek 5 relative+exact'")
  mp.command("keybind left 'seek -5 relative+exact'")
  mp.command("keybind up 'add volume 5'")
  mp.command("keybind down 'add volume -5'")

  

  mp.add_timeout(1, select_subtitles)
end

mp.register_event("file-loaded", jellyfin)

local last_mouse_pos = ""
local function cursor_workaround()
  if isEnabled() == false then
    do return end
  end

  if last_mouse_pos ~= mp.get_property('mouse-pos') then
    last_mouse_pos = mp.get_property('mouse-pos')
    mp.set_property("cursor-autohide", "1000")
  else  
    mp.set_property("cursor-autohide", "always")
  end
end

mp.add_periodic_timer(1, cursor_workaround)