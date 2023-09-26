-- FRAME DOUBLER
--
-- Uses ffmpeg to multiply source video framerate
--

local msg = require 'mp.msg'
require 'mp.options'
local options = {
  enabled = false,
  maxVideoFps = 60,
  maxVsyncRatio = 5,
  minDisplayFps = 119,
  roundFps = false
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
  if containerFps == nil or displayFps == nil then
    do return end
  end
  
  mp.set_property("vf", "") -- reset

  if math.floor(containerFps) > options.maxVideoFps then -- disable for High Framerate content
    do return end
  end

  if options.minDisplayFps > displayFps then
    do return end
  end

  local fps = containerFps
  fps = math.floor(1000*fps)/1000 -- round down to three decimals
  if options.roundFps then
    fps = math.floor(fps + 0.1) 
  end

  local vsyncRatio = 1
  while (vsyncRatio+1)*fps <= displayFps do
    vsyncRatio = vsyncRatio + 1
  end

  if vsyncRatio > options.maxVsyncRatio then
    vsyncRatio = options.maxVsyncRatio
  end

  if vsyncRatio == 1 then
    do return end
  end

  mp.set_property("vf", "fps=fps=source_fps*" .. vsyncRatio)
end

mp.observe_property('container-fps', 'number', sync_frames)
mp.observe_property('display-fps', 'number', sync_frames)