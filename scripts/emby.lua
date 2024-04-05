msg = require 'mp.msg'
require 'mp.options'
utils = require 'mp.utils'

local first_run = true

local options = {
    enabled = false
}

local function isEnabled()
    read_options(options, "emby")
    return options.enabled
end

local function emby()
  if isEnabled() == false then
    do return end
  end

  --msg.info("stream-open-filename: " .. mp.get_property("stream-open-filename"))

  local path = mp.get_property("path")

  local item_id_raw = string.sub(path, string.find(path, "/emby/%a+/%d+"))
  local item_id = string.sub(item_id_raw, item_id_raw.find(item_id_raw, "%d+$"))
  
  local api_key_raw = string.sub(path, path.find(path, "api_key=%w+"))
  local api_key = string.gsub(api_key_raw, "api_key=", "")

  local request = mp.command_native({
    name = "subprocess",
    capture_stdout = true,
    capture_stderr = true,
    args = {
      "curl",
      "-X", "GET",
      "-H", "Content-Type: application/json",
      "http://chronos:8096/emby/Items/" .. item_id .. "/PlaybackInfo?api_key=" .. api_key
    }
  })
  local response = utils.parse_json(request.stdout)

  if first_run == false then
    mp.set_property("title", response["MediaSources"][1]["Name"])
  else
    first_run = false
    local stream_open_filename = string.sub(path, string.find(path, "^.+/emby/%a+/%d+/original.mkv")) .. "?api_key=" .. api_key
    mp.command("loadfile " .. stream_open_filename)
  end
end

mp.add_hook("on_load", 50, emby)