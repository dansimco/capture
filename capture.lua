--          CAPTURE
--
--         @&&&&@%      
--       @@&@@&&&@
--      &@@&&@@@&@&  
--      @&&@@&@@@&@
--      &,     &      @   
--      @@&&&&&&&@&   
--      *@@&    @@&   
--     #@@@&@@@&@   
--      &@@@@@@@@ 
--        *@@@@@&     
--
-- key 1: 
--  - disarm,
--  - clear clipping warning
--
-- key 2: 
--  - arm, 
--  - manual start recording,
--  - finish recording
-- 

local app = include("lib/app")

function init()
  app.init()
	local screen_timer = metro.init()
  screen_timer.time = 1/15
	screen_timer.event = function() redraw() end
  screen_timer:start()
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

