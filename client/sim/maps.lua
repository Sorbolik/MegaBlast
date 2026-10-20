-- Mappe. Ogni mappa disegna il terreno con forme semplici (rettangoli, cerchi,
-- tubi) oppure carica una maschera da sim/mapdata.lua, e dice dove compaiono i robot. Le forme in acciaio sono indistruttibili.
--
-- Per aggiungere una mappa: scrivi una funzione build(t, seed) qui sotto e
-- aggiungila a M.maps. Coordinate del mondo: 1280 x 720, y verso l'alto.

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

-- Isole del cimitero: due grandi isole con archi d'osso, isole volanti su più piani.
-- La forma viene dalla maschera disegnata (grafica/mappe/mappa_isole_cimitero/):
-- terra scavabile, ossa e catene indistruttibili. È simmetrica a specchio.
add("isole", "Isole del cimitero", {
	spawns = { { x = 420, from = 260 }, { x = 860, from = 260 } },
	build = function(t)
		t:load(mapdata.cimitero)
	end,
})

-- Casuale: colline generate dal seed, con un tubo di fondazione.
add("casuale", "Colline casuali", {
	spawns = { { x = 256, from = 720 }, { x = 1024, from = 720 } },
	build = function(t, seed)
		t:generate(seed)
		t:capsule(0, 24, 1280, 24, 12, STEEL)
	end,
})

M.DEFAULT = "isole"

function M.get(id)
	return M.maps[id] or M.maps[M.DEFAULT]
end

return M
