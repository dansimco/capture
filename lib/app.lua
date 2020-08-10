local parameters = include("lib/parameters")
local helpers = include("lib/helpers")
local ui = include("lib/ui")

local poll_freq = 1/15

local app = {
  ready = false,
  input_level_l = 0,
  input_level_r = 0,
  average_input_level_l = 0,
  average_input_level_r = 0,
  averaging_window = 16,
  threshold = 0.1,
  poll_freq = 1/15,
  above_threshold = false,
  armed = false
}


function app.init()
  parameters.init(app)
  app.clearInputHandlers()
  
  -- channel setup
  app.init_channel('l')
  app.init_channel('r')
  
  app.key3down = app.arm


  -- softcut setup
  softcut.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_tape_cut(0)
  audio.level_eng_cut(0)
  
  local end_of_loop = 10
  local cut_pan = {-0.75, 0.75}
  local time_ref = 0

  for si = 1,2 do
    audio.level_cut(1)
    audio.level_adc_cut(1)
    audio.level_eng_cut(1)
    softcut.level(si,1)
    softcut.level_slew_time(si,0.1)
    softcut.level_input_cut(si, 1, 1.0)
    softcut.rate(si, 1)
    softcut.rate_slew_time(si,0.1)
    softcut.loop_start(si, 0)
    softcut.loop_end(si, end_of_loop)
    softcut.loop(si, 1)
    softcut.fade_time(si, 0.1)
    softcut.rec(si, 1)
    softcut.rec_level(si, 1)
    softcut.pre_level(si, 0)
    softcut.play(si, 1)
    softcut.position(si, 0)
    softcut.buffer(si,si)
    softcut.enable(si, 1)
    -- softcut.filter_dry(si, 1)
    softcut.rec_offset(si,-0.06)
    softcut.pan(si, cut_pan[si])
  end
  softcut.poll_start_phase()

  -- Input events
  app.key2down = function()
    local saved = "sampler-"..string.format("%04.0f",10000*math.random())..".wav"
    softcut.buffer_write_stereo(_path.dust.."/audio/tape/".. saved, 2, 4)
    print("write")
  end
  app.ready = true
end


function app.init_channel(chan)
  -- init level poll
  local level_poll = poll.set("amp_in_" .. chan)
  level_poll.time = app.poll_freq
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
    else
      app["above_threshold_" .. chan] = false
    end
  end
  level_poll:start()
end
  

function app.arm()
  app.armed = true
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
