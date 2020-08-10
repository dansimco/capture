local paramaters = {}

function paramaters.init(app)
  local output_options = {"audio", "audio + midi", "midi"}
  params:add_option("output", "OUTPUT", output_options, 1)
end


return paramaters