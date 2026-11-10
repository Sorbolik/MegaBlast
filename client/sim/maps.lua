-- Maps. Each map loads its collision mask from sim/mapdata.lua (or, the
-- mission arenas, draws it with rectangles: sim/missions.lua) and says where
-- the robots appear. Steel cells are indestructible.
-- spawns: four points, one per robot in turn order. 1 and 3 on the left, 2
-- and 4 on the right, so in 2v2 teammates start on the same side. from is the
-- height from which the ground below is searched.
--
-- To add a map: draw it with strumenti/grafica/mappe_dipinte.py (painting and
-- mask), bring the mask into sim/mapdata.lua (mappa_in_lua.py) and add it
-- below. World coordinates: 1920 x 1080, y up.

local mapdata = require "sim.mapdata"

local M = {}

M.maps = {}
M.order = {}

local function add(id, name, def)
	def.id, def.name = id, name
	M.maps[id] = def
	M.order[#M.order + 1] = id
end

-- The painted campaign maps (strumenti/grafica/mappe_dipinte.py, the
-- apprentice maps document): the floor, a single wall-to-wall ground with the
-- islands above, where you cannot fall (the free missions of Training and of
-- the Forge), and the pit, the same floor with a lava pit in the middle (the
-- Smith). Sergio's choices, 2 November 2026; the only maps of real matches
-- since 3 November (the old ones are gone), chosen in Training
-- (menu/training.lua).
local PAVIMENTO_SPAWNS = { { x = 225, from = 300 }, { x = 1650, from = 585 }, { x = 630, from = 390 }, { x = 1260, from = 300 } }

add("pavimento", "La Forgia", { spawns = PAVIMENTO_SPAWNS,
	build = function(t) t:load(mapdata.pavimento) end })
add("fossa", "La fossa del Fabbro", { spawns = PAVIMENTO_SPAWNS,
	build = function(t) t:load(mapdata.fossa) end })

add("cortile", "Il cortile", { spawns = { { x = 210, from = 450 }, { x = 1710, from = 450 }, { x = 600, from = 380 }, { x = 1320, from = 380 } },
	build = function(t) t:load(mapdata.cortile) end })

M.DEFAULT = "pavimento"

-- The maps of real matches (online and on the same phone): if no map is asked
-- for, the match seed picks it, so server and client (which share the seed)
-- play on the same one.
M.ROTATION = { "pavimento", "fossa" }

function M.pick(seed)
	return M.ROTATION[math.floor(seed) % #M.ROTATION + 1]
end

-- Maps out of rotation and out of M.order (the mission arenas,
-- sim/missions.lua): they are played only when asked for by name.
function M.register(id, def)
	def.id, def.name = id, def.name or id
	M.maps[id] = def
end

function M.get(id)
	return M.maps[id] or M.maps[M.DEFAULT]
end

return M
