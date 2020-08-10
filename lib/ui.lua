local ui = {}

function ui.redraw(app)
  screen.aa(0)
  screen.clear()
  screen.move(0, 5)
  screen.fill()
  screen.update()
end

return ui