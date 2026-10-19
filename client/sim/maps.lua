-- Mappe. Ogni mappa disegna il terreno con forme semplici (rettangoli, cerchi,
-- tubi) e dice dove compaiono i robot. Le forme in acciaio sono indistruttibili.
--
-- Per aggiungere una mappa: scrivi una funzione build(t, seed) qui sotto e
-- aggiungila a M.maps. Coordinate del mondo: 1280 x 720, y verso l'alto.

local terrain = require "sim.terrain"

local DIRT, STEEL = terrain.DIRT, terrain.STEEL

local M = {}

M.maps = {}
M.order = {}

local function add(id, name, def)
	def.id, def.name = id, name
	M.maps[id] = def
	M.order[#M.order + 1] = id
end

-- Isola volante: cima piatta all'altezza top, sotto arrotondata.
local function island(t, x, top, w, depth)
	t:rect(x - w / 2, top - 10, w, 10, DIRT)
	t:capsule(x - w / 2 + depth / 2, top - depth / 2, x + w / 2 - depth / 2, top - depth / 2, depth / 2, DIRT)
	t:rect(x - w / 2 - depth, top, w + 2 * depth, depth, terrain.EMPTY)
end

-- Isole: due basi sorrette da tubi, un ponte al centro, isole volanti su due piani.
add("isole", "Isole", {
	spawns = { { x = 150, from = 320 }, { x = 1130, from = 320 } },
	build = function(t)
		-- basi a sinistra e a destra, con il vuoto in mezzo
		t:rect(0, 0, 500, 120, DIRT)
		t:circle(250, 110, 150, DIRT)
		t:rect(780, 0, 500, 120, DIRT)
		t:circle(1030, 110, 150, DIRT)
		-- tubi di fondazione: non si possono scavare
		t:capsule(10, 40, 490, 40, 14, STEEL)
		t:capsule(790, 40, 1270, 40, 14, STEEL)
		t:capsule(250, 40, 250, 200, 9, STEEL)
		t:capsule(1030, 40, 1030, 200, 9, STEEL)

		-- ponte centrale sorretto da un tubo
		island(t, 640, 260, 150, 40)
		t:capsule(565, 236, 715, 236, 7, STEEL)

		-- primo piano: due isole volanti con una trave d'acciaio dentro
		island(t, 380, 400, 120, 50)
		t:capsule(340, 380, 420, 380, 6, STEEL)
		island(t, 900, 400, 120, 50)
		t:capsule(860, 380, 940, 380, 6, STEEL)

		-- secondo piano: tre isolette e una passerella d'acciaio al centro
		island(t, 160, 560, 90, 34)
		island(t, 1120, 560, 90, 34)
		island(t, 640, 600, 100, 40)
		t:capsule(570, 480, 710, 480, 5, STEEL)
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
