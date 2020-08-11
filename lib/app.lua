local parameters = include("lib/parameters")
local helpers = include("lib/helpers")
local ui = include("lib/ui")

local app = {
  ready = false,
  input_level_l = 0,
  input_level_r = 0,
  average_input_level_l = 0,
  average_input_level_r = 0,
  averaging_window = 16,
  threshold = 0.05,
  poll_freq = 15, -- hz
  record_time = 240, -- seconds
  above_threshold_l = false,
  above_threshold_r = false,
  end_of_loop = 240, -- rolling record buffer
  rec_metro_position = 0,
  rec_state = "INIT",
  armed = false
}

function app.init()
  parameters.init(app)
  app.clearInputHandlers()
  
  -- channel setup
  app.init_channel('l')
  app.init_channel('r')
  
  app.key3up = app.arm

  -- metros
  app.rec_metro = metro.init(app.rec_metro_loop, 1 / app.poll_freq)

  -- softcut setup
  softcut.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_tape_cut(0)
  audio.level_eng_cut(0)
  app.end_of_loop = 8
  local buffer_pan = {-1, 1}
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  -- softcut voices
  for si = 1,2 do
    softcut.level(si,1)
    softcut.level_slew_time(si,0.01)
    softcut.level_input_cut(si, si, 1.0)
    softcut.rate(si, 1)
    softcut.rate_slew_time(si,0.1)
    softcut.loop_start(si, 0)
    softcut.loop_end(si, app.end_of_loop)
    softcut.loop(si, 1)
    softcut.fade_time(si, 0.01)
    softcut.rec(si, 1)
    softcut.rec_level(si, 1)
    softcut.pre_level(si, 0)
    softcut.position(si, 0)
    softcut.buffer(si,si)
    softcut.enable(si, 1)
    softcut.filter_dry(si, 1)
    softcut.pan(si, buffer_pan[si])
  end

  -- Input events
  app.key2down = app.save_buffer
  app.ready = true
end


function app.init_channel(chan)
  -- init level poll
  local level_poll = poll.set("amp_in_" .. chan)
  level_poll.time = 1 / app.poll_freq
  local average_level = helpers.averager(app.averaging_window)
  level_poll.callback = function(val)
    app["input_level_" .. chan] = val
    average_level:push(val)
    if val > app["average_input_level_" .. chan] then
      app["average_input_level_" .. chan] = val
    else
      app["average_input_level_" .. chan] = average_level.value
    end
    if val > app.threshold then
      app["above_threshold_" .. chan] = true
      if app.rec_state == "ARMED" then
        app.start_recording()
      end
    else
      app["above_threshold_" .. chan] = false
    end
  end
  level_poll:start()
end
  
function app.rec_metro_loop(idx)
  app.rec_head_position = idx / 15
  -- restart if getting too close to end of buffer and not recording
  -- start timeout for cut and save when input goes below threshold
  if idx >= app.record_time * app.poll_freq then
    if (app.rec_state == "RECORDING") then
      app.finish_recording()
    else
      app.rec_state = "IDLE"
    end
    app.rec_metro:stop()
  end
end

function app.arm()
  softcut.buffer_clear()
  softcut.position(1, 0)
  softcut.position(2, 0)
  app.rec_metro:start()
  app.armed = true
  app.rec_state = "ARMED"
  app.key3up = app.start_recording -- this should probably be handled by something like app.state
end

function app.start_recording()
  app.rec_state = "RECORDING"
  app.sample_start = app.rec_head_position - 1 / app.poll_freq --this shouldn't be the case for quantised or it should be different
  app.key3up = app.finish_recording
end

function app.finish_recording()
  app.rec_metro:stop()
  app.sample_end = app.rec_head_position
  app.rec_state = "WRITING"
  print("Sample from", app.sample_start, "to", app.sample_end)
  app.save_buffer()
end

function app.save_buffer()
  local saved = "sampler-"..string.format("%04.0f",10000*math.random())..".wav"
  softcut.buffer_write_stereo(_path.dust.."/audio/tape/".. saved, app.sample_start, app.sample_end)
  print("write")
  app.rec_state = "IDLE"
  app.arm()
end

function app.redraw()
  ui.redraw(app)
end

function app.clearInputHandlers()
  local f = function() end
  app.key1down = f
  app.key2down = f
  app.key3down = f
  app.key1up   = f
  app.key2up   = f
  app.key3up   = f
end

function app.key(n, z)
  if n==1 and z==1 then
    app.key1down()
  end
  if n==2 and z==1 then
    app.key2down()
  end
  if n==3 and z==1 then
    app.key3down()
  end
  if n==2 and z==0 then
    app.key2up()
  end
  if n==3 and z==0 then
    app.key3up()
  end
end

return app
