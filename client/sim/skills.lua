-- The Sigilli (Sergio, 10 Nov: "Daje, mi piace tutto", the name his pick; proposal
-- https://claude.ai/artifact/5d22qHU8FcyZrzaMFGF5cx): the skill tree as three
-- paths, ALI, CORAZZA and FUCINA. Points go into a path, not into nodes: every
-- point gives a little of the path's stat, and every STEP points the path
-- reaches a threshold where you pick one of two powers. At PATH_MAX there is the
-- path's big power. Pure Lua: the client uses it for the screen and the server
-- to check the loadout it receives.
--
-- The rules:
-- 1. fewer points than paths: POINTS_MAX points for 3 * PATH_MAX, so you finish
--    two paths at most and give something up;
-- 2. every point is worth a little (PER_POINT), the thresholds are worth a lot;
-- 3. with all points of a path its stat goes up 10% at most (there is a test):
--    the powers are sidegrades or situational;
-- 4. free rebuild outside matches (sim/loadout.lua keeps the loadouts).
--
-- A chosen tree: { wings = 18, armor = 12, forge = 4, pick = { wings = { 2, 1, 1 }, ... } }
-- pick[path][k] is the power (1 or 2) chosen at threshold k * STEP. A pick of a
-- threshold not reached stays (moving the points back and forth keeps it) but
-- counts only once the path reaches it; a reached threshold without a pick
-- gives nothing (the screen asks to choose).
-- Effects as in sim/gear.lua: { stat, add } | { stat, mul }; keys of game.base_stats().

local M = {}

-- the player's levels and the points they give: one per level
M.LEVEL_MAX = 50
M.POINTS_MAX = 50
-- points one path can hold, and the distance between thresholds
M.PATH_MAX = 25
M.STEP = 5
M.STEPS = M.PATH_MAX / M.STEP
-- What the player's level gives by itself, on top of the points (Sergio, 14
-- Nov: «statistiche di base flat ad ogni livello»): at LEVEL_MAX these points
-- of Attack and life, 70% spread evenly over the levels and 6% at every
-- tenth level (10, 20, 30, 40, 50), so a round level is felt.
M.LEVEL_BONUS = { attack = 10, max_hp = 10 }
function M.level_share(level)
	level = math.max(1, math.min(M.LEVEL_MAX, level or 1))
	return 0.7 * (level - 1) / (M.LEVEL_MAX - 1) + 0.06 * math.floor(level / 10)
end
-- the points each stat gets at that level: { attack = 4.2, max_hp = 4.2 }
function M.level_bonus(level)
	local k, out = M.level_share(level), {}
	for stat, v in pairs(M.LEVEL_BONUS) do out[stat] = math.floor(v * k * 10 + 0.5) / 10 end
	return out
end

-- what one point gives, as the screen writes it (0.4% or 0.4 hp, all paths)
M.PER_POINT_SHOWN = 0.4

-- per_point: the path's stat, each point (add per point, or mul = 1 + share per point);
-- per_point_desc: what all the points give, %s is points * PER_POINT_SHOWN.
-- steps[k] = the two powers at threshold k * STEP. power_name: what the player
-- card calls it (ui/tag_card.lua).
M.PATHS = {
	{ id = "wings", name = "ALI", desc = "Muoversi: salto, corsa, globi, Rampino",
		per_point = { { stat = "jump_height", share = 0.004 }, { stat = "walk_speed", share = 0.004 },
			{ stat = "air_speed", share = 0.004 } },
		per_point_desc = "salto, corsa e aria +%s%%",
		steps = {
			{ { name = "Passo di brace", desc = "Corsa +5%", effects = { { stat = "walk_speed", mul = 1.05 } } },
				{ name = "Salto lungo", desc = "Salto +5%", effects = { { stat = "jump_height", mul = 1.05 } } } },
			{ { name = "Balzo nel vuoto", desc = "Un salto in aria", power_name = "salto in aria",
					effects = { { stat = "air_jumps", add = 1 } } },
				{ name = "Ali di riserva", desc = "Un paracadute in più", power_name = "paracadute in più",
					effects = { { stat = "parachutes", add = 1 } } } },
			{ { name = "Globo lesto", desc = "Il teletrasporto scatta il 25% prima", power_name = "globo lesto",
					effects = { { stat = "teleport_ticks", mul = 0.75 } } },
				{ name = "Globo di riserva", desc = "Si parte con un globo in più", power_name = "globo in più",
					effects = { { stat = "teleports", add = 1 } } } },
			{ { name = "Corda lunga", desc = "Il Rampino arriva il 40% più lontano", power_name = "corda lunga",
					effects = { { stat = "hook_range", mul = 1.4 } } },
				{ name = "Piedi di gatto", desc = "Niente danno da caduta", power_name = "piedi di gatto",
					effects = { { stat = "fall_damage_mul", mul = 0 } } } },
			{ { name = "Scia d'ombra", desc = "Dopo un teletrasporto, prima di attaccare: 3 secondi in più nel turno",
					power_name = "scia d'ombra", effects = { { stat = "orb_time", add = 180 } } },
				{ name = "Doppio Rampino", desc = "Il Rampino due volte per turno", power_name = "doppio Rampino",
					effects = { { stat = "extra_hooks", add = 1 } } } },
		} },
	{ id = "armor", name = "CORAZZA", desc = "Resistere: vita, cadute, spinte, scudi",
		per_point = { { stat = "max_hp", add = 0.4 } },
		per_point_desc = "vita +%s",
		steps = {
			{ { name = "Crosta", desc = "Vita +5", effects = { { stat = "max_hp", add = 5 } } },
				{ name = "Ossa di pietra", desc = "Danno da caduta -30%", effects = { { stat = "fall_damage_mul", mul = 0.7 } } } },
			{ { name = "Radici", desc = "Spinta subita -20%", power_name = "radici",
					effects = { { stat = "knockback_mul", mul = 0.8 } } },
				{ name = "Scudo pronto", desc = "Si parte con uno scudo", power_name = "scudo pronto",
					effects = { { stat = "start_shields", add = 1 } } } },
			{ { name = "Cura calda", desc = "I cerchi di cura ti curano il 50% in più", power_name = "cura calda",
					effects = { { stat = "heal_mul", mul = 1.5 } } },
				{ name = "Pelle di brace", desc = "La bruciatura non ti tocca", power_name = "pelle di brace",
					effects = { { stat = "burn_immune", add = 1 } } } },
			{ { name = "Ultimo respiro", desc = "Una volta a partita resti a 1 di vita invece di morire (non nel vuoto)",
					power_name = "ultimo respiro", effects = { { stat = "last_stand", add = 1 } } },
				{ name = "Radici profonde", desc = "Spinta subita dimezzata, salto -10%", power_name = "radici profonde",
					effects = { { stat = "knockback_mul", mul = 0.5 }, { stat = "jump_height", mul = 0.9 } } } },
			{ { name = "Fenice", desc = "Quando muori esplodi: danno intorno a te", power_name = "fenice",
					effects = { { stat = "phoenix", add = 1 } } },
				{ name = "Scudo doppio", desc = "I tuoi scudi parano il doppio", power_name = "scudo doppio",
					effects = { { stat = "shield_mul", mul = 2 } } } },
		} },
	{ id = "forge", name = "FUCINA", desc = "Colpire e ingannare: spinte, trappole, casse",
		per_point = { { stat = "blast_push", share = 0.004 } },
		per_point_desc = "spinta delle tue esplosioni +%s%%",
		steps = {
			{ { name = "Trappola larga", desc = "Raggio delle trappole +20%", effects = { { stat = "trap_radius", mul = 1.2 } } },
				{ name = "Molla dura", desc = "I tuoi trampolini lanciano il 20% più in alto",
					effects = { { stat = "trampoline_mul", mul = 1.2 } } } },
			{ { name = "Brace lenta", desc = "Gli effetti che dai durano un turno in più", power_name = "brace lenta",
					effects = { { stat = "status_turns", add = 1 } } },
				{ name = "Uovo che brucia", desc = "L'Uovo dà la bruciatura", power_name = "uovo che brucia",
					effects = { { stat = "burning_blasts", add = 1 } } } },
			{ { name = "Tasca in più", desc = "Un colpo in più dell'arma secondaria", power_name = "tasca in più",
					effects = { { stat = "extra_secondary", add = 1 } } },
				{ name = "Cassa piena", desc = "Le armi delle casse hanno un colpo in più", power_name = "cassa piena",
					effects = { { stat = "crate_bonus", add = 1 } } } },
			{ { name = "Trappola doppia", desc = "Le trappole delle casse valgono due", power_name = "trappola doppia",
					effects = { { stat = "double_traps", add = 1 } } },
				{ name = "Molla doppia", desc = "I trampolini delle casse valgono due", power_name = "molla doppia",
					effects = { { stat = "double_springs", add = 1 } } } },
			{ { name = "Colpo di grazia", desc = "Contro chi ha meno di 20 vita le tue esplosioni spingono il doppio",
					power_name = "colpo di grazia", effects = { { stat = "finisher", add = 1 } } },
				{ name = "Fuoco vivo", desc = "La tua bruciatura toglie il doppio", power_name = "fuoco vivo",
					effects = { { stat = "burn_mul", mul = 2 } } } },
		} },
}

M.BY_ID = {}
for _, p in ipairs(M.PATHS) do M.BY_ID[p.id] = p end

-- points available at a level
function M.points(level)
	return math.max(0, math.min(M.POINTS_MAX, math.floor(level or 0)))
end

local function count(tree, id)
	local n = type(tree) == "table" and tree[id]
	return type(n) == "number" and n or 0
end

-- points in a path, or in the whole tree
function M.spent(tree, path)
	if path then return count(tree, path) end
	local n = 0
	for _, p in ipairs(M.PATHS) do n = n + count(tree, p.id) end
	return n
end

-- the power chosen at threshold k of a path (1 or 2), nil if none
function M.pick(tree, path, k)
	local t = type(tree) == "table" and type(tree.pick) == "table" and tree.pick[path]
	local v = type(t) == "table" and t[k]
	return (v == 1 or v == 2) and v or nil
end

-- thresholds reached by a path
function M.reached(tree, path)
	return math.floor(count(tree, path) / M.STEP)
end

-- the first reached threshold without a pick (the screen and the podium point to it), or nil
function M.to_choose(tree)
	for _, p in ipairs(M.PATHS) do
		for k = 1, M.reached(tree, p.id) do
			if not M.pick(tree, p.id, k) then return p.id, k end
		end
	end
end

-- can one more point go into this path? true, or false and the reason
function M.can_add(tree, path, points)
	if not M.BY_ID[path] then return false, "via sconosciuta" end
	if count(tree, path) >= M.PATH_MAX then return false, "al massimo" end
	if M.spent(tree) + 1 > points then return false, "punti finiti" end
	return true
end

function M.can_remove(tree, path)
	return count(tree, path) > 0
end

-- adds (n > 0) or takes away (n < 0) up to |n| points; returns how many moved
function M.move(tree, path, n, points)
	local moved = 0
	while n > 0 and M.can_add(tree, path, points) do
		tree[path], n, moved = count(tree, path) + 1, n - 1, moved + 1
	end
	while n < 0 and M.can_remove(tree, path) do
		tree[path], n, moved = count(tree, path) - 1, n + 1, moved + 1
	end
	if tree[path] == 0 then tree[path] = nil end
	return moved
end

function M.choose(tree, path, k, which)
	tree.pick = tree.pick or {}
	tree.pick[path] = tree.pick[path] or {}
	tree.pick[path][k] = which
end

-- does the tree respect points and picks? (the server checks it before the match)
function M.valid(tree, points)
	if type(tree) ~= "table" then return false end
	for k, v in pairs(tree) do
		if k == "pick" then
			if type(v) ~= "table" then return false end
			for path, list in pairs(v) do
				if not M.BY_ID[path] or type(list) ~= "table" then return false end
				for i, w in pairs(list) do
					if type(i) ~= "number" or i < 1 or i > M.STEPS or i % 1 ~= 0 or (w ~= 1 and w ~= 2) then return false end
				end
			end
		elseif not M.BY_ID[k] or type(v) ~= "number" or v < 0 or v > M.PATH_MAX or v % 1 ~= 0 then
			return false
		end
	end
	return M.spent(tree) <= points
end

-- the powers taken: list of { path, k, power }
function M.powers(tree)
	local out = {}
	for _, p in ipairs(M.PATHS) do
		for k = 1, M.reached(tree, p.id) do
			local w = M.pick(tree, p.id, k)
			if w then out[#out + 1] = { path = p, k = k, power = p.steps[k][w] } end
		end
	end
	return out
end

-- adds to the mods list the tree's effects: one group per path for its
-- points, one per power (sim/loadout.lua applies them)
function M.mods(tree, mods)
	for _, p in ipairs(M.PATHS) do
		local n = count(tree, p.id)
		if n > 0 then
			local g = {}
			for _, e in ipairs(p.per_point) do
				if e.share then g[#g + 1] = { stat = e.stat, mul = 1 + e.share * n }
				else g[#g + 1] = { stat = e.stat, add = e.add * n } end
			end
			mods[#mods + 1] = g
		end
	end
	for _, w in ipairs(M.powers(tree)) do mods[#mods + 1] = w.power.effects end
	return mods
end

return M
