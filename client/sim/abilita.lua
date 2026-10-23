-- Albero di abilità (docs/game_design_competitivo.md, "Albero di abilità").
-- Lua puro: lo usa il client per la schermata e il server per controllare
-- l'assetto che gli arriva.
--
-- Le quattro regole del documento:
-- 1. meno punti che nodi: al livello massimo POINTS_MAX punti per un albero che
--    ne costa il doppio, così anche a fine gioco si sceglie;
-- 2. nodi misti: statistiche (salto, velocità, vita) e nodi del Nucleo, in tre
--    rami (Mobilità, Difesa, Arsenale);
-- 3. differenza piccola: ogni nodo sposta una statistica di pochi punti
--    percentuali, le chiavi sono quelle di config.STATS (rb.stats);
-- 4. ricostruzione gratuita fuori dalla partita (sim/assetto.lua tiene i 3 assetti).
--
-- Un albero scelto è una tabella { [id del nodo] = gradi presi }.
-- Ogni effetto è { stat = chiave, add = n } o { stat = chiave, mul = n }, per grado.

local M = {}

-- punti al livello massimo; in Torneo tutti hanno questi
M.POINTS_MAX = 20
-- punti per livello del giocatore (livello 1 = 1 punto)
M.POINTS_PER_LEVEL = 1
-- per prendere un nodo della riga r servono ROW_GATE * (r - 1) punti già spesi nel suo ramo
M.ROW_GATE = 3

M.BRANCHES = {
	{ id = "mobility", name = "MOBILITÀ", desc = "Salto, corsa e teletrasporto" },
	{ id = "defense", name = "DIFESA", desc = "Vita, scudi e paracadute" },
	{ id = "arsenal", name = "ARSENALE", desc = "Trappole, effetti e Nucleo" },
}

-- Nodi: ramo, riga (1 in alto), gradi, costo di ogni grado ed effetto di ogni grado.
-- Somma dei costi di tutti i gradi: 40, il doppio di POINTS_MAX.
M.NODES = {
	-- Mobilità (16)
	{ id = "jump", branch = "mobility", row = 1, ranks = 3, cost = 1, name = "Gambe di Titano",
		desc = "+3 di altezza del salto", effects = { { stat = "jump_height", add = 3 } } },
	{ id = "walk", branch = "mobility", row = 1, ranks = 3, cost = 1, name = "Passo di brace",
		desc = "+4 di velocità a terra", effects = { { stat = "walk_speed", add = 4 } } },
	{ id = "air", branch = "mobility", row = 2, ranks = 3, cost = 1, name = "Ali di cenere",
		desc = "+3 di velocità in aria", effects = { { stat = "air_speed", add = 3 } } },
	{ id = "orb_fast", branch = "mobility", row = 3, ranks = 2, cost = 2, name = "Orbe impaziente",
		desc = "Il teletrasporto scatta 0,2 s prima", effects = { { stat = "teleport_ticks", add = -12 } } },
	{ id = "air_jump", branch = "mobility", row = 4, ranks = 1, cost = 3, name = "Salto d'ombra",
		desc = "Un salto in aria per 1 Nucleo", effects = { { stat = "air_jumps", add = 1 } } },
	-- Difesa (13)
	{ id = "hp", branch = "defense", row = 1, ranks = 4, cost = 1, name = "Crosta spessa",
		desc = "+3 di vita", effects = { { stat = "max_hp", add = 3 } } },
	{ id = "parachute", branch = "defense", row = 2, ranks = 1, cost = 3, name = "Ali di riserva",
		desc = "Il primo paracadute della partita è gratis", effects = { { stat = "free_parachutes", add = 1 } } },
	{ id = "shield", branch = "defense", row = 3, ranks = 1, cost = 3, name = "Scudo forgiato",
		desc = "Lo scudo costa 1 Nucleo in meno", effects = { { stat = "shield_cost", add = -1 } } },
	{ id = "start_nucleo", branch = "defense", row = 4, ranks = 1, cost = 3, name = "Nucleo di riserva",
		desc = "Si parte con 1 Nucleo in più", effects = { { stat = "start_nucleo", add = 1 } } },
	-- Arsenale (11)
	{ id = "trap", branch = "arsenal", row = 1, ranks = 3, cost = 1, name = "Fauci larghe",
		desc = "+4 di raggio delle trappole", effects = { { stat = "trap_radius", add = 4 } } },
	{ id = "status", branch = "arsenal", row = 2, ranks = 2, cost = 1, name = "Brace lenta",
		desc = "Gli effetti di stato durano 0,5 s in più", effects = { { stat = "status_ticks", add = 30 } } },
	{ id = "tele_cost", branch = "arsenal", row = 3, ranks = 1, cost = 3, name = "Passo leggero",
		desc = "Il primo teletrasporto della partita è gratis", effects = { { stat = "free_teleports", add = 1 } } },
	{ id = "fall", branch = "arsenal", row = 4, ranks = 1, cost = 3, name = "Ossa di pietra",
		desc = "Danno da caduta -25%", effects = { { stat = "fall_damage_mul", mul = 0.75 } } },
}

M.BY_ID = {}
for _, n in ipairs(M.NODES) do M.BY_ID[n.id] = n end

-- punti disponibili a un livello (in Torneo: POINTS_MAX)
function M.points(level, tournament)
	if tournament then return M.POINTS_MAX end
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
