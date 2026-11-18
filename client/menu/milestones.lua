-- The stats and their badges (sim/milestones.lua) with their names from the
-- game's text: nome (how the stat reads) and badge (the badge's name, nil:
-- none). Same module table, so menu.milestones and sim.milestones are one.

local M = require "sim.milestones"
local T = require("lang.text").milestones

for _, s in ipairs(M.WHITELIST) do
	s.nome = T.names[s.id]
	if s.thresholds then s.badge = T.badges[s.id] end
end

return M
