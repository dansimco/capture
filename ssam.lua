-- SAMPLER

local app = include("lib/app")

function audio:vu(in1, in2)
  print(in1)
end

function init()
  app.init()


  app.redraw()
end

function enc()


end

function key(n, z)
  app.key(n, z)
end

function redraw()
  if app.ready then
    app.redraw()
  end
end

-- screen metro
local screen_timer = metro.init()
screen_timer.time = 1/15
screen_timer.event = function() redraw() end
screen_timer:start()
