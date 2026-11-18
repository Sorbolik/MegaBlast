-- One clock for what moves behind and in the menus (Sergio, 18 Nov: «deve
-- restare costante, senza resettarsi»): the sky of the home and the idle of the
-- apprentice read it, so changing screen they go on where they were instead of
-- starting again
--
--   local clock = require "ui.clock"
--   local t = clock.now()   -- seconds since the game started

local M = {}

local EPOCH = socket.gettime()

function M.now()
	return socket.gettime() - EPOCH
end

-- The apprentice s (scoria.new) at the clock's time in his idle; ahead: the
-- seconds that will be run on him at once, before he shows
function M.sync(s, ahead)
	s.t = M.now() - (ahead or 0)
end

return M
