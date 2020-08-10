local ui = {}

screen.font_face(1)
screen.font_size(8)
local threshold = 0.1
local is_recording = false


function ui.redraw(app)
  screen.aa(0)
  screen.clear()
  screen.level(16)
  screen.move(0, 10)
  screen.text("LEFT: "..app.input_level_l)
  screen.move(0, 20)
  screen.text("RIGHT: "..app.input_level_l)
  screen.move(0, 30)
  if (is_recording) then 
    state = "recording"
  else
    state = "waiting"
  end
  screen.text(state)
  ui.draw_meters(app.input_level_l, app.input_level_r)
  screen.update()
end


local averaging_frames = 8

ui.level_history_l = {}
ui.level_history_r = {}
ui.level_i = 0

function ui.draw_meters(level_l, level_r)
  screen.level(4)

  ui.level_i = ui.level_i + 1
  ui.level_history_l[ui.level_i] = level_l
  ui.level_history_r[ui.level_i] = level_r
  if (ui.level_i == (averaging_frames+1)) then ui.level_i = 0 end
  local l=table.reduce(ui.level_history_l, function(a, b) return a+b end) / averaging_frames
  local r=table.reduce(ui.level_history_r, function(a, b) return a+b end) / averaging_frames
  ui.average_l = l
  ui.average_r = r

  local h = 40

  if (level_l > threshold or level_r > threshold) then
    screen.level(16)
    is_recording = true
  elseif (l < threshold and r < threshold) then
    is_recording = false
  end
  screen.rect(119, 1+(64-h*l), 2, h*l)
  screen.rect(124, 1+(64-h*r), 2, h*r)
  screen.fill()

end


table.reduce = function (list, fn) 
    local acc
    for k, v in ipairs(list) do
        if 1 == k then
            acc = v
        else
            acc = fn(acc, v)
        end 
    end 
    return acc 
end


return ui
