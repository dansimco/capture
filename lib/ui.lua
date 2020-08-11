local ui = {}


function ui.redraw(app)
  screen.aa(0)
  screen.clear()
  screen.level(16)
  screen.move(0, 10)
  screen.text("L " .. util.round(app.input_level_l, 0.01) .. "  R " .. util.round(app.input_level_r, 0.01))
  screen.move(0, 30)
  screen.text(app.rec_state)
  screen.move(0, 40)
  if (app.above_threshold_l or app.above_threshold_r) then 
    state = "above threshold"
  else
    state = ""
  end
  screen.text(state)
  -- meters
  ui:draw_meter(119, 1, 40, app.average_input_level_l)
  ui:draw_meter(124, 1, 40, app.average_input_level_r)
  screen.update()
end


function ui:draw_meter(x, y, h, l) --x pos, y pos, height, audio Level
  screen.level(3)
  -- screen.rect(x, 1+(64-h), 2, h)
  screen.fill()
  screen.level(6)
  if above_threshold then screen.level(10) end
  screen.rect(x, 1+(64-h*l), 2, h*l)
  screen.fill()
end

return ui
