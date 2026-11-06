-- The campaign: chapters of missions. The levels themselves, all data, are in
-- sim/levels.lua (the Copione, strumenti/copione, edits them); here the
-- chapters, in order, and what opens them.

local levels = require "sim.levels"

local M = {}

-- serve: the stars (from all chapters) needed to open the chapter
M.CAPITOLI = {
	{ id = "addestramento", titolo = "Addestramento", serve = 0, missioni = levels.addestramento, aspetta = true },
	{ id = "girone_1", titolo = "I girone: la Forgia", serve = 8, missioni = levels.girone_1 },
}

return M
