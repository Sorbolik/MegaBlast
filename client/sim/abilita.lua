-- Albero di abilità (docs/game_design_competitivo.md, "Albero di abilità").
-- Lua puro: lo usa il client per la schermata e il server per controllare
-- l'assetto che gli arriva.
--
-- Le quattro regole del documento:
-- 1. meno punti che nodi: al livello massimo POINTS_MAX punti per un albero che
--    ne costa il doppio, così anche a fine gioco si sceglie;
-- 2. nodi misti: statistiche (salto, velocità, vita) e riserve (teletrasporti, paracadute);
-- 3. differenza che si sente ma si colma con la strategia: con tutti i punti
--    nessuna statistica sale più del 10% (c'è un test);
-- 4. ricostruzione gratuita fuori dalla partita (sim/assetto.lua tiene i 3 assetti).
--
--
-- Un albero scelto è una tabella { [id del nodo] = gradi presi }.
-- Ogni effetto è { stat = chiave, add = n } o { stat = chiave, mul = n }, per
-- grado; le chiavi sono quelle di game.base_stats() (config.STATS e fisica).

local M = {}

-- punti al livello massimo
M.POINTS_MAX = 20
-- punti per livello del giocatore (livello 1 = 2 punti, il massimo al livello 10)
M.POINTS_PER_LEVEL = 2
-- per prendere un nodo della riga r servono ROW_GATE * (r - 1) punti già spesi nel suo ramo
M.ROW_GATE = 3

M.BRANCHES = {
	{ id = "mobility", name = "MOBILITÀ", desc = "Salto, corsa e teletrasporto" },
	{ id = "defense", name = "DIFESA", desc = "Vita, riserve, cadute e spinte" },
	{ id = "arsenal", name = "ARSENALE", desc = "Trappole ed effetti di stato" },
}

-- Nodi: ramo, riga (1 in alto), gradi, costo di ogni grado ed effetto di ogni grado.
-- Somma dei costi di tutti i gradi: 62, più del triplo di POINTS_MAX.
M.NODES = {
	-- Mobilità (28)
	{ id = "jump", branch = "mobility", row = 1, ranks = 3, cost = 2, name = "Gambe di Titano",
		desc = "Salto +3%", effects = { { stat = "jump_height", mul = 1.03 } } },
	{ id = "walk", branch = "mobility", row = 1, ranks = 3, cost = 2, name = "Passo di brace",
		desc = "Corsa +3%", effects = { { stat = "walk_speed", mul = 1.03 } } },
	{ id = "air", branch = "mobility", row = 2, ranks = 3, cost = 2, name = "Ali di cenere",
		desc = "Velocità in aria +3%", effects = { { stat = "air_speed", mul = 1.03 } } },
	{ id = "orb_fast", branch = "mobility", row = 3, ranks = 2, cost = 3, name = "Orbe impaziente",
		desc = "Il teletrasporto scatta il 5% prima", effects = { { stat = "teleport_ticks", mul = 0.95 } } },
	{ id = "air_jump", branch = "mobility", row = 3, ranks = 1, cost = 4, name = "Balzo nel vuoto",
		desc = "Un salto in aria", effects = { { stat = "air_jumps", add = 1 } } },
	-- Difesa (24)
	{ id = "hp", branch = "defense", row = 1, ranks = 4, cost = 2, name = "Crosta spessa",
		desc = "Vita +2", effects = { { stat = "max_hp", add = 2 } } },
	{ id = "fall", branch = "defense", row = 1, ranks = 2, cost = 2, name = "Ossa di pietra",
		desc = "Danno da caduta -5%", effects = { { stat = "fall_damage_mul", mul = 0.95 } } },
	{ id = "teleport", branch = "defense", row = 2, ranks = 1, cost = 4, name = "Globo di riserva",
		desc = "Si parte con un teletrasporto in più", effects = { { stat = "teleports", add = 1 } } },
	{ id = "parachute", branch = "defense", row = 2, ranks = 1, cost = 4, name = "Ali di riserva",
		desc = "Un paracadute in più per partita", effects = { { stat = "parachutes", add = 1 } } },
	{ id = "anchor", branch = "defense", row = 3, ranks = 2, cost = 2, name = "Radici",
		desc = "Spinta subita -5%", effects = { { stat = "knockback_mul", mul = 0.95 } } },
	-- Arsenale (10)
	{ id = "trap_wide", branch = "arsenal", row = 1, ranks = 3, cost = 2, name = "Trappola larga",
		desc = "Raggio delle trappole +3%", effects = { { stat = "trap_radius", mul = 1.03 } } },
	{ id = "long_status", branch = "arsenal", row = 2, ranks = 1, cost = 4, name = "Brace lenta",
		desc = "Gli effetti di stato che dai durano un turno in più", effects = { { stat = "status_turns", add = 1 } } },
}

M.BY_ID = {}
for _, n in ipairs(M.NODES) do M.BY_ID[n.id] = n end

-- punti disponibili a un livello
function M.points(level)
	return math.max(0, math.min(M.POINTS_MAX, (level or 0) * M.POINTS_PER_LEVEL))
end

-- punti spesi, in tutto e nel ramo
function M.spent(tree, branch)
	local n = 0
	for id, r in pairs(tree) do
		local node = M.BY_ID[id]
		if node and (not branch or node.branch == branch) then n = n + r * node.cost end
	end
	return n
end

-- punti spesi nel ramo sulle righe sopra a row (quelli che aprono la riga)
local function spent_above(tree, branch, row)
	local n = 0
	for id, r in pairs(tree) do
		local node = M.BY_ID[id]
		if node and node.branch == branch and node.row < row then n = n + r * node.cost end
	end
	return n
end

-- si può prendere un grado in più di questo nodo? Restituisce true o false, motivo
function M.can_add(tree, id, points)
	local node = M.BY_ID[id]
	if not node then return false, "nodo sconosciuto" end
	if (tree[id] or 0) >= node.ranks then return false, "al massimo" end
	if M.spent(tree) + node.cost > points then return false, "punti finiti" end
	if spent_above(tree, node.branch, node.row) < M.ROW_GATE * (node.row - 1) then
		return false, "riga chiusa"
	end
	return true
end

-- si può togliere un grado senza chiudere le righe sotto?
function M.can_remove(tree, id)
	local node = M.BY_ID[id]
	if not node or (tree[id] or 0) == 0 then return false end
	tree[id] = tree[id] - 1
	local ok = M.valid(tree, math.huge)
	tree[id] = tree[id] + 1
	return ok
end

-- l'albero rispetta gradi, punti e righe? (il server lo controlla prima della partita)
function M.valid(tree, points)
	if type(tree) ~= "table" then return false end
	if M.spent(tree) > points then return false end
	for id, r in pairs(tree) do
		local node = M.BY_ID[id]
		if not node or type(r) ~= "number" or r < 0 or r > node.ranks or r % 1 ~= 0 then return false end
		if r > 0 and spent_above(tree, node.branch, node.row) < M.ROW_GATE * (node.row - 1) then return false end
	end
	return true
end

-- aggiunge alla lista mods gli effetti dell'albero, un gruppo per grado
-- (la applica sim/assetto.lua)
function M.mods(tree, mods)
	for _, node in ipairs(M.NODES) do
		for _ = 1, tree[node.id] or 0 do mods[#mods + 1] = node.effects end
	end
	return mods
end

return M
