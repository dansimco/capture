local app = {}
local parameters = include("lib/parameters")
local ui = include("lib/ui")

function app.init()
  parameters.init(app)
end

function app.redraw()
  ui.redraw(app)
end

return app
