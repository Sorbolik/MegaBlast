-- Mappe. Ogni mappa disegna il terreno con forme semplici (rettangoli, cerchi,
-- tubi) oppure carica una maschera da sim/mapdata.lua, e dice dove compaiono i robot. Le forme in acciaio sono indistruttibili.
-- spawns: quattro punti, uno per robot nell'ordine dei turni. 1 e 3 a
-- sinistra, 2 e 4 a destra, così nel 2 contro 2 i compagni partono dallo
-- stesso lato. from è l'altezza da cui si cerca il terreno sotto.
--
-- Per aggiungere una mappa: scrivi una funzione build(t, seed) qui sotto e
-- aggiungila a M.maps. Coordinate del mondo: 1920 x 1080, y verso l'alto.

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

-- Forgia dei Titani: due fortezze a specchio con torre a gradini e galleria,
-- l'incudine in mezzo con il corno d'acciaio per ripararsi, piattaforme in alto.
-- Forma a poligoni dritti (grafica/strumenti/mappa_forgia.py): quello che si
-- vede è esattamente quello su cui si cammina. Travi e bordi in acciaio.
add("forgia", "Forgia dei Titani", {
	spawns = { { x = 480, from = 600 }, { x = 1440, from = 600 }, { x = 180, from = 1080 }, { x = 1740, from = 1080 } },
	build = function(t)
		t:load(mapdata.forgia)
	end,
})

-- Isole del cimitero: due grandi isole con archi d'osso, isole volanti su più piani.
-- La forma viene dalla maschera disegnata (grafica/mappe/mappa_isole_cimitero/):
-- terra scavabile, ossa e catene indistruttibili. È simmetrica a specchio.
add("isole", "Isole del cimitero", {
	spawns = { { x = 630, from = 390 }, { x = 1290, from = 390 }, { x = 240, from = 1080 }, { x = 1680, from = 1080 } },
	build = function(t)
		t:load(mapdata.cimitero)
	end,
})

-- Casuale: colline generate dal seed, con un tubo di fondazione.
add("casuale", "Colline casuali", {
	seeded = true, -- il terreno cambia con il seed
	spawns = { { x = 384, from = 1080 }, { x = 1536, from = 1080 }, { x = 780, from = 1080 }, { x = 1140, from = 1080 } },
	build = function(t, seed)
		t:generate(seed)
		t:capsule(0, 36, 1920, 36, 18, STEEL)
	end,
})

M.DEFAULT = "forgia"

function M.get(id)
	return M.maps[id] or M.maps[M.DEFAULT]
end

return M
