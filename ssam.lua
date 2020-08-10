-- SAMPLER

local app = include("lib/app")

function init()
  app.init()
  app.redraw()
end

function enc()


end

function key()

end

function redraw()
  app.redraw()
end

-- screen metro
local screen_timer = metro.init()
screen_timer.time = 1/15
screen_timer.event = function() redraw() end
screen_timer:start()
