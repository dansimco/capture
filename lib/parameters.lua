local parameters = {}

function parameters.init(app)
  local output_options = {"audio", "audio + midi", "midi"}
  params:add_option("output", "OUTPUT", output_options, 1)


  -- metronome
  -- count in
  -- bpm
  -- clock in clock out
  -- mode {one-shot-auto, one-shot-manual, clocked}
  -- count in
  -- rec length bars
  -- normalize
  -- trim

end


return parameters