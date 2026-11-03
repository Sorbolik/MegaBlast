-- Skill tree (docs/game_design_competitivo.md, "Albero di abilità").
-- Pure Lua: the client uses it for the screen and the server to check the
-- loadout it receives.
--
-- The four rules of the document:
-- 1. fewer points than nodes: at max level POINTS_MAX points for a tree that
--    costs twice as much, so even at the end of the game you choose;
-- 2. mixed nodes: stats (jump, speed, hp) and reserves (teleports, parachutes);
-- 3. a difference you feel but that strategy can close: with all points no
--    stat goes up more than 10% (there is a test);
-- 4. free rebuild outside matches (sim/loadout.lua keeps the 3 loadouts).
--
--
-- A chosen tree is a table { [node id] = ranks taken }.
-- Each effect is { stat = key, add = n } or { stat = key, mul = n }, per rank;
-- the keys are those of game.base_stats() (config.STATS and physics).

local M = {}

-- points at max level
M.POINTS_MAX = 20
-- points per player level (level 1 = 2 points, the maximum at level 10)
M.POINTS_PER_LEVEL = 2
-- taking a node in row r needs ROW_GATE * (r - 1) points already spent in its branch
M.ROW_GATE = 3

M.BRANCHES = {
	{ id = "mobility", name = "MOBILITÀ", desc = "Salto, corsa e teletrasporto" },
	{ id = "defense", name = "DIFESA", desc = "Vita, riserve, cadute e spinte" },
	{ id = "arsenal", name = "ARSENALE", desc = "Trappole ed effetti di stato" },
}

-- Nodes: branch, row (1 at the top), ranks, cost of each rank and effect of each rank.
-- potere: the nodes that give something new (not just a number) and what it
-- is called on the player card (ui/tag_card.lua).
-- Sum of the costs of all ranks: 62, more than three times POINTS_MAX.
M.NODES = {
	-- Mobility (28)
	{ id = "jump", branch = "mobility", row = 1, ranks = 3, cost = 2, name = "Gambe di Titano",
		desc = "Salto +3%", effects = { { stat = "jump_height", mul = 1.03 } } },
	{ id = "walk", branch = "mobility", row = 1, ranks = 3, cost = 2, name = "Passo di brace",
		desc = "Corsa +3%", effects = { { stat = "walk_speed", mul = 1.03 } } },
	{ id = "air", branch = "mobility", row = 2, ranks = 3, cost = 2, name = "Ali di cenere",
		desc = "Velocità in aria +3%", effects = { { stat = "air_speed", mul = 1.03 } } },
	{ id = "orb_fast", branch = "mobility", row = 3, ranks = 2, cost = 3, name = "Orbe impaziente",
		desc = "Il teletrasporto scatta il 5% prima", effects = { { stat = "teleport_ticks", mul = 0.95 } } },
	{ id = "air_jump", branch = "mobility", row = 3, ranks = 1, cost = 4, name = "Balzo nel vuoto", power_name = "salto in aria",
		desc = "Un salto in aria", effects = { { stat = "air_jumps", add = 1 } } },
	-- Defense (24)
	{ id = "hp", branch = "defense", row = 1, ranks = 4, cost = 2, name = "Crosta spessa",
		desc = "Vita +2", effects = { { stat = "max_hp", add = 2 } } },
	{ id = "fall", branch = "defense", row = 1, ranks = 2, cost = 2, name = "Ossa di pietra",
		desc = "Danno da caduta -5%", effects = { { stat = "fall_damage_mul", mul = 0.95 } } },
	{ id = "teleport", branch = "defense", row = 2, ranks = 1, cost = 4, name = "Globo di riserva", power_name = "globo di riserva",
		desc = "Si parte con un teletrasporto in più", effects = { { stat = "teleports", add = 1 } } },
	{ id = "parachute", branch = "defense", row = 2, ranks = 1, cost = 4, name = "Ali di riserva", power_name = "paracadute in più",
		desc = "Un paracadute in più per partita", effects = { { stat = "parachutes", add = 1 } } },
	{ id = "anchor", branch = "defense", row = 3, ranks = 2, cost = 2, name = "Radici",
		desc = "Spinta subita -5%", effects = { { stat = "knockback_mul", mul = 0.95 } } },
	-- Arsenal (10)
	{ id = "trap_wide", branch = "arsenal", row = 1, ranks = 3, cost = 2, name = "Trappola larga",
		desc = "Raggio delle trappole +3%", effects = { { stat = "trap_radius", mul = 1.03 } } },
	{ id = "long_status", branch = "arsenal", row = 2, ranks = 1, cost = 4, name = "Brace lenta", power_name = "brace lenta",
		desc = "Gli effetti di stato che dai durano un turno in più", effects = { { stat = "status_turns", add = 1 } } },
}

M.BY_ID = {}
for _, n in ipairs(M.NODES) do M.BY_ID[n.id] = n end

-- points available at a level
function M.points(level)
	return math.max(0, math.min(M.POINTS_MAX, (level or 0) * M.POINTS_PER_LEVEL))
end

-- points spent, in total and in the branch
function M.spent(tree, branch)
	local n = 0
	for id, r in pairs(tree) do
		local node = M.BY_ID[id]
		if node and (not branch or node.branch == branch) then n = n + r * node.cost end
	end
	return n
end

-- points spent in the branch on the rows above row (those that open the row)
local function spent_above(tree, branch, row)
	local n = 0
	for id, r in pairs(tree) do
		local node = M.BY_ID[id]
		if node and node.branch == branch and node.row < row then n = n + r * node.cost end
	end
	return n
end

-- can one more rank of this node be taken? Returns true or false, reason
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

-- can a rank be removed without closing the rows below?
function M.can_remove(tree, id)
	local node = M.BY_ID[id]
	if not node or (tree[id] or 0) == 0 then return false end
	tree[id] = tree[id] - 1
	local ok = M.valid(tree, math.huge)
	tree[id] = tree[id] + 1
	return ok
end

-- does the tree respect ranks, points and rows? (the server checks it before the match)
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

-- adds to the mods list the tree's effects, one group per rank
-- (sim/loadout.lua applies them)
function M.mods(tree, mods)
	for _, node in ipairs(M.NODES) do
		for _ = 1, tree[node.id] or 0 do mods[#mods + 1] = node.effects end
	end
	return mods
end

return M
