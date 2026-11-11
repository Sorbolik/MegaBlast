-- Maps. Each map loads its collision mask from sim/mapdata.lua (or, the
-- mission arenas, draws it with rectangles: sim/missions.lua) and says where
-- the robots appear. Steel cells are indestructible.
-- spawns: four points, one per robot in turn order. 1 and 3 on the left, 2
-- and 4 on the right, so in 2v2 teammates start on the same side. from is the
-- height from which the ground below is searched.
--
-- To add a map: draw it with tools/grafica/mappe_dipinte.py (painting and
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

-- The painted campaign maps (tools/grafica/mappe_dipinte.py, the
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

-- The first circles of the campaign (docs/campagna_gironi.md): one map for each, shared by its
-- levels, with the circle's hazard (sim/hazards.lua, docs/pericoli_mappe.md). In the rotation
-- too, so they also bring variety online (Sergio, 11 Nov).
-- Limbo: less gravity: you jump higher and farther and the shots fly longer.
add("limbo", "Il Limbo", { gravity = 0.6,
	spawns = { { x = 240, from = 480 }, { x = 1680, from = 480 }, { x = 630, from = 300 }, { x = 1290, from = 300 } },
	build = function(t) t:load(mapdata.limbo) end })
-- Lussuria: the storm moves everyone a step at the end of each round; the steel spikes are
-- for the Rampino, the gorge in the middle kills.
add("lussuria", "La bufera", { hazard = "wind",
	spawns = { { x = 150, from = 520 }, { x = 1740, from = 450 }, { x = 336, from = 420 }, { x = 1485, from = 360 } },
	build = function(t) t:load(mapdata.lussuria) end })
-- Gola: the hail falls where a shadow announced it a round before; the two pools of mud
-- (world rectangles x0, x1, y0, y1 around the ground of the pool, as painted by
-- tools/grafica/mappe_dipinte.py GOLA_POZZE) slow whoever stands in them.
add("gola", "La piova eterna", { hazard = "hail", mud = { { 660, 810, 270, 300 }, { 1110, 1260, 270, 300 } },
	spawns = { { x = 180, from = 570 }, { x = 1725, from = 480 }, { x = 550, from = 430 }, { x = 960, from = 400 } },
	build = function(t) t:load(mapdata.gola) end })

-- Violenza: the Flegetonte (the river of blood kills, three stones to cross it, the dead trunks stop
-- the shots until you break them, two pools of blood burn: blood, world rectangles like the mud,
-- tools/grafica/mappe_dipinte.py FLEG_SANGUE) and the Sabbione (flat, no cover, the fire rain).
add("flegetonte", "Il Flegetonte", { blood = { { 600, 720, 285, 315 }, { 1200, 1275, 225, 255 } },
	spawns = { { x = 150, from = 560 }, { x = 1800, from = 590 }, { x = 465, from = 450 }, { x = 1440, from = 420 } },
	build = function(t) t:load(mapdata.flegetonte) end })
add("sabbione", "Il Sabbione", { hazard = "fire_rain",
	spawns = { { x = 150, from = 410 }, { x = 1800, from = 500 }, { x = 560, from = 490 }, { x = 1545, from = 410 } },
	build = function(t) t:load(mapdata.sabbione) end })
-- Frode: the Malebolge, two pits of pitch crossed by cracked bridges that fall (bridges: world
-- rectangle of each, x0, x1, y0, y1; BOLGE_PONTI in tools/grafica/mappe_dipinte.py)
add("malebolge", "Le Malebolge", { hazard = "bridges", bridges = { { 495, 576, 357, 375 }, { 1260, 1341, 252, 270 } },
	spawns = { { x = 150, from = 450 }, { x = 1800, from = 420 }, { x = 375, from = 450 }, { x = 1500, from = 350 } },
	build = function(t) t:load(mapdata.malebolge) end })
-- Tradimento: the Cocito, thin slabs of ice over the cold water: everyone slides, the blasts break them
add("cocito", "Il Cocito", { hazard = "ice", ice = true,
	spawns = { { x = 150, from = 380 }, { x = 1770, from = 410 }, { x = 450, from = 380 }, { x = 1350, from = 350 } },
	build = function(t) t:load(mapdata.cocito) end })
-- Lucifero's arena (three phases, a mission): the lake with the well in the middle; the ice slides and the
-- six wings push everyone away from the middle at the end of each round. Not in the rotation.
add("lucifero", "Il lago di Lucifero", { hazard = "ice", ice = true, wings = true,
	spawns = { { x = 260, from = 380 }, { x = 1700, from = 380 }, { x = 560, from = 380 }, { x = 1400, from = 380 } },
	build = function(t) t:load(mapdata.lucifero) end })

-- The circles' maps Training shows even though no campaign level plays them yet, in
-- the order of the circles (Sergio, 11 Nov: all visible for now; they will open as the
-- campaign meets them: menu/training.lua)
M.CIRCLES = { "limbo", "lussuria", "gola", "flegetonte", "sabbione", "malebolge", "cocito", "lucifero" }
-- the ones that are not in the online rotation (arenas of a single level)
M.OFFLINE = { lucifero = true }

M.DEFAULT = "pavimento"

-- The maps of real matches (online and on the same phone): if no map is asked
-- for, the match seed picks it, so server and client (which share the seed)
-- play on the same one.
M.ROTATION = { "pavimento", "fossa", "limbo", "lussuria", "gola", "flegetonte", "sabbione", "malebolge", "cocito" }

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
