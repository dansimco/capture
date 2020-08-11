local parameters = include("lib/parameters")
local helpers = include("lib/helpers")
local ui = include("lib/ui")

local record_states = {
  "IDLE",
  "ARMED",
  "RECORDING",
  "PROCESSING"
}

local app = {
  ready = false,
  input_level_l = 0,
  input_level_r = 0,
  average_input_level_l = 0,
  average_input_level_r = 0,
  averaging_window = 16,
  threshold = 0.001,
  poll_freq = 15, -- hz
  above_threshold_l = false,
  above_threshold_r = false,
  end_of_loop = 360, -- rolling record buffer
  rec_metro_position = 0,
  clipped_l = false, 
  clipped_r = false,
  rec_state = 1,
  rec_head_position = 0,
  armed = false
}

function app.init()
  parameters.init(app)
  app.clearInputHandlers()
  
  -- channel setup
  app.init_channel('l')
  app.init_channel('r')
  
  app.key2up = function() 
    app.clipped_l = false
    app.clipped_r = false
    if app.rec_state == 2 then
      app.rec_state = 1
    end
  end
  app.key3up = app.arm

  -- metros
  app.rec_metro = metro.init(app.rec_metro_loop, 1 / app.poll_freq)
  app.rec_metro:start()

  -- softcut setup
  softcut.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_tape_cut(0)
  audio.level_eng_cut(0)
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

    if val > 0.3 then
      app["clipped_" .. chan] = true
    end
    
    if val > app["average_input_level_" .. chan] then
      app["average_input_level_" .. chan] = val
    else
      app["average_input_level_" .. chan] = average_level.value
    end
    
    if val > app.threshold then

      app["above_threshold_" .. chan] = true
      if app.rec_state == 2 then
        app.start_recording()
      end
    else
      app["above_threshold_" .. chan] = false
    end
  end
  level_poll:start()
end
  
function app.rec_metro_loop(idx)

  app.rec_head_position = app.rec_head_position + 1 / app.poll_freq

  if app.rec_state == 2 then -- armed
    if app.rec_head_position > 10 then -- reset after 45 seconds to keep enough space in buffer (potential bug)
      app.reset_recording() 
    end
  end

  if app.rec_state == 3 then -- recording

    if app.is_above_threshold() then
      app.silence_countdown = 1 * app.poll_freq -- debounce three seconds
      if app.silence_clock then
        app.silence_clock.cancel()
        app.silence_clock = nil
      end
    else
      app.silence_countdown = app.silence_countdown - 1
      print(app.silence_countdown)
      if app.silence_countdown == 0 then
        app.finish_recording()

      end
    end

  end


end



function app.is_above_threshold()
  local above_threshold = false
  if app.above_threshold_l or app.above_threshold_r then
    above_threshold = true
  end
  return above_threshold
end

function app.arm()
  app.reset_recording()
  app.rec_state = 2
  app.key3up = app.start_recording -- this should probably be handled by something like app.state
end

function app.reset_recording()
  print("reset")
  softcut.buffer_clear()
  softcut.position(1, 0)
  softcut.position(2, 0)
  app.rec_head_position = 0
end

function app.start_recording()
  app.rec_state = 3
  local preroll_frame = app.rec_head_position - 0.5
  if preroll_frame < 0 then preroll_frame = 0 end
  app.sample_start = preroll_frame
  app.key3up = app.finish_recording
end

function app.finish_recording()
  app.sample_end = app.rec_head_position
  app.rec_state = 4
  print("Sample from", app.sample_start, "to", app.sample_end)
  app.save_buffer()
end

function app.save_buffer()
  local raw_file = "capture-"..os.time().."."..util.round(app.sample_end)..".wav"
  local outfile = "capture-"..os.time().."."..util.round(app.sample_end)..".trim.wav"

  local path_raw = _path.dust.."audio/tape/".. raw_file
  local path_out = _path.dust.."audio/tape/".. outfile

  softcut.buffer_write_stereo(path_raw, app.sample_start, app.sample_end)

  -- local trim_command = "sox " .. path_raw .. " " .. path_out .. " silence 1 0.005 1%"
  local trim_command = "sox "..path_raw.." "..path_out.." silence 1 0.1 1% reverse silence 1 0.1 1% fade 0.01 reverse fade 0.01 && rm " .. path_raw
  -- local norm_command = "sox " .. path_raw .. " " .. path_out .. " norm -2.0"
  
  function trim_callback()
    clock.sleep(1)
    util.os_capture(trim_command)
    app.rec_state = 1
    app.arm()
  end
  clock.run(trim_callback)

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
