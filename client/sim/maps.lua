-- Maps. Each map draws its terrain with simple shapes (rectangles, circles,
-- pipes) or loads a mask from sim/mapdata.lua, and says where the robots
-- appear. Steel shapes are indestructible.
-- spawns: four points, one per robot in turn order. 1 and 3 on the left, 2
-- and 4 on the right, so in 2v2 teammates start on the same side. from is the
-- height from which the ground below is searched.
--
-- To add a map: write a build(t, seed) function below and add it to M.maps.
-- World coordinates: 1920 x 1080, y up.

local terrain = require "sim.terrain"
local mapdata = require "sim.mapdata"

local STEEL = terrain.STEEL

local M = {}

M.maps = {}
M.order = {}

local function add(id, name, def)
	def.id, def.name = id, name
	M.maps[id] = def
	M.order[#M.order + 1] = id
end

-- Forge of the Titans: two mirrored fortresses with a stepped tower and a
-- tunnel, the anvil in the middle with the steel horn for cover, platforms up
-- high. Straight polygon shape (grafica/strumenti/mappa_forgia.py): what you
-- see is exactly what you walk on. Beams and edges in steel.
add("forgia", "Forgia dei Titani", {
	spawns = { { x = 480, from = 600 }, { x = 1440, from = 600 }, { x = 180, from = 1080 }, { x = 1740, from = 1080 } },
	build = function(t)
		t:load(mapdata.forgia)
	end,
})

-- The Crucible: plateaus on the sides with a cave below, steel bridges up to
-- the crucible in the middle (a 45° bowl where grenades roll), a tunnel
-- crossing the bottom, hanging ladles and a beam on top.
-- Shape and drawing: strumenti/grafica/mappa_crogiolo.py.
add("crogiolo", "Il Crogiolo", {
	spawns = { { x = 195, from = 1080 }, { x = 1725, from = 1080 }, { x = 630, from = 300 }, { x = 1290, from = 300 } },
	build = function(t)
		t:load(mapdata.crogiolo)
	end,
})

-- Random: hills generated from the seed, with a foundation pipe.
add("casuale", "Colline casuali", {
	seeded = true, -- the terrain changes with the seed
	spawns = { { x = 384, from = 1080 }, { x = 1536, from = 1080 }, { x = 780, from = 1080 }, { x = 1140, from = 1080 } },
	build = function(t, seed)
		t:generate(seed)
		t:capsule(0, 36, 1920, 36, 18, STEEL)
	end,
})

M.DEFAULT = "forgia"

-- The maps of real matches (online and on the same phone): if no map is asked
-- for, the match seed picks it, so server and client (which share the seed)
-- play on the same one. Only the official campaign maps (Sergio, 3 Nov 2026:
-- the old ones out of the game); Forge of the Titans, the Crucible and the
-- random hills stay only as test terrain (tests and simulator scenarios).
M.ROTATION = { "pavimento", "fossa" }

function M.pick(seed)
	return M.ROTATION[math.floor(seed) % #M.ROTATION + 1]
end

-- Maps out of rotation and out of M.order (the missions, sim/missions.lua):
-- they are played only when asked for by name.
function M.registra(id, def)
	def.id, def.name = id, def.name or id
	M.maps[id] = def
end

function M.get(id)
	return M.maps[id] or M.maps[M.DEFAULT]
end

-- The painted campaign maps (strumenti/grafica/mappe_dipinte.py, the
-- apprentice maps document): the floor, a single wall-to-wall ground with the
-- islands above, where you cannot fall (the free missions of Training and of
-- the Forge), and the pit, the same floor with a lava pit in the middle (the
-- Smith). Sergio's choices, 2 November 2026. In M.ROTATION since 3 November,
-- chosen in Training (menu/allenamento.lua).
local PAVIMENTO_SPAWNS = { { x = 225, from = 300 }, { x = 1650, from = 585 }, { x = 630, from = 390 }, { x = 1260, from = 300 } }

M.registra("pavimento", { name = "La Forgia", spawns = PAVIMENTO_SPAWNS,
	build = function(t) t:load(mapdata.pavimento) end })
M.registra("fossa", { name = "La fossa del Fabbro", spawns = PAVIMENTO_SPAWNS,
	build = function(t) t:load(mapdata.fossa) end })

return M
