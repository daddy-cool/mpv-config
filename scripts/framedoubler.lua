-- FRAME DOUBLER
--
-- Uses ffmpeg to multiply source video framerate
--

local msg = require 'mp.msg'
require 'mp.options'
local options = {
  enabled = true,
  maxVideoFps = 60,
  maxVsyncRatio = 20,
  minDisplayFps = 71,
  roundDispayFps = true,
  roundFps = false,
  vfAppend = ""
}

local function isEnabled()
    read_options(options, "framedoubler")
    return options.enabled
end

function sync_frames()
  if isEnabled() == false then
    do return end
  end

  local containerFps = mp.get_property_number('container-fps')
  local displayFps = mp.get_property_number('display-fps')
  local speed = mp.get_property_number('speed')
  if containerFps == nil or displayFps == nil or speed == nil then
    do return end
  end
  
  mp.set_property("vf", "") -- reset

  if math.floor(containerFps) > options.maxVideoFps then -- disable for High Framerate content
    do return end
  end

  if options.minDisplayFps > displayFps then
    do return end
  end

  displayFps = math.floor(1000*displayFps)/1000
  if options.roundDispayFps then
    displayFps = math.floor(displayFps + 0.5)
  end

  local fps = containerFps
  fps = math.floor(1000*fps)/1000 -- round down to three decimals
  if options.roundFps then
    fps = math.floor(fps + 0.1) 
  end

  local vsyncRatio = 1
  while (vsyncRatio+1)*fps*speed <= displayFps do
    vsyncRatio = vsyncRatio + 1
  end

  if vsyncRatio > options.maxVsyncRatio then
    vsyncRatio = options.maxVsyncRatio
  end

  if vsyncRatio == 1 then
    do return end
  end

  local seperator = ""
  if options.vfAppend ~= "" then
    seperator = ","
  end

  mp.set_property("msg-level", "ffmpeg=error")
  mp.set_property("vf", "fps=fps=source_fps*" .. vsyncRatio .. seperator .. options.vfAppend)
end

mp.observe_property('container-fps', 'number', sync_frames)
mp.observe_property('display-fps', 'number', sync_frames)
mp.observe_property('speed', 'number', sync_frames)