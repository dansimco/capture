local parameters = include("lib/parameters")
local ui = include("lib/ui")

local poll_freq = 1/15

local app = {
  input_level_l=0,
  input_level_r=0,
}


function app.init()
  parameters.init(app)


  local level_poll_l = poll.set("amp_in_l")
  local level_poll_r = poll.set("amp_in_r")
  level_poll_l.time = poll_freq
  level_poll_r.time = poll_freq
  
  level_poll_l.callback = function(val) app.input_level_l = val end
  level_poll_r.callback = function(val) app.input_level_r = val end

  level_poll_l:start()
  level_poll_r:start()

end

function app.redraw()
  ui.redraw(app)
end

return app
