-- Gear: the pieces of the Forge (Sergio, 10-11 Nov, page "I Pezzi della Forgia"
-- https://claude.ai/artifact/F5TiCLHXAqgPe7XUBi138A, choices 1-25).
-- Pure Lua, like sim/skills.lua.
--
-- The Sigilli say what you can do, the pieces say how you do it and who you
-- are: a piece never gives a power of the Sigilli. Four slots, each with its
-- job (choice 3A); five families that go sideways, never stronger (6A, 14A).
-- A piece has one plus from its slot's job and one minus (2A): the plus grows
-- from +2% at level 1 to +4.9% at 30 (life from +2 to +5), the minus is -2%,
-- halves at the step 20 and is gone at 30. Two gold pieces (level 20 or more)
-- of the same family give the family's small bonus (5A); the four-piece style,
-- the traits of the step 10 and variant B are new rules and come in the next
-- PR (they are written here as text only). Pieces add at most +10% to a stat,
-- pieces and Sigilli together at most +20% (8A).
--
-- A loadout's gear: { mask = family id, ... }; levels: { mask = 1..30, ... }.

local M = {}

M.SLOTS = {
	{ id = "mask", name = "ELMO", art = "maschera" },
	{ id = "chest", name = "CORAZZA", art = "corazza" },
	{ id = "cloak", name = "MANTELLO", art = "mantello" },
	{ id = "legs", name = "STIVALI", art = "gambali_davanti" },
}
-- Level of a piece: from 1 to LIVELLO_MAX, bought with Scaglie (Sergio, 10
-- Nov, page "Scaglie e Ossidiana", choices 4A-6A). Every TIER_LEVELS level is a
-- step ("scatto"): the grade goes up (bronze, silver, gold, ember).
M.LIVELLO_MAX = 30
M.TIER_LEVELS = { 10, 20, 30 }
M.TIERS = #M.TIER_LEVELS + 1
-- the level from which a piece is "gold": it counts for its family's bonus
M.GOLD = 20

-- Scaglie to go up TO each level (2..30): the normal levels rise slowly,
-- the steps cost about three normal levels. 3,050 for a piece at 30.
M.COSTS = { [10] = 150, [20] = 300, [30] = 450 }
for l = 2, 9 do M.COSTS[l] = 15 + 5 * (l - 2) end
for l = 11, 19 do M.COSTS[l] = 60 + 5 * (l - 11) end
for l = 21, 29 do M.COSTS[l] = 110 + 5 * (l - 21) end
-- the Proof of a step: matches played wearing the piece at the level just
-- below it (9, 19, 29) before you can buy the step
M.PROOF = { [10] = 3, [20] = 5, [30] = 8 }
-- the Smith's hand: once a piece of a slot is at 30, every other piece of
-- that slot costs this much (30% off), to buy and to level up
M.SMITH_HAND = 0.7

-- Scaglie to go up to level l (nil past the last); discounted: the Smith's
-- hand. Rounded to 5, like the price list.
function M.cost(l, discounted)
	local c = M.COSTS[l]
	if not c then return nil end
	if discounted then c = math.floor(c * M.SMITH_HAND / 5 + 0.5) * 5 end
	return c
end

-- matches with the piece needed before going up to level l (0: none)
function M.proof(l)
	return M.PROOF[l] or 0
end

-- The stats the pieces touch. less: lower is better (a plus lowers them).
-- hp: counted in points of life, not in percent.
M.STATS = {
	max_hp = { hp = true },
	walk_speed = {}, jump_height = {}, air_speed = {}, blast_push = {},
	teleport_ticks = { less = true }, knockback_mul = { less = true }, fall_damage_mul = { less = true },
}
-- what each slot's plus can come from (choice 3A); the minus can be any stat
M.JOBS = {
	mask = { "max_hp", "teleport_ticks" },
	chest = { "max_hp", "knockback_mul" },
	legs = { "walk_speed", "jump_height" },
	cloak = { "air_speed", "fall_damage_mul" },
}
-- the caps of choice 8A, as a share of the base (life: of 100 points)
M.CAP_PIECES, M.CAP_ALL = 0.10, 0.20

-- Families: for each slot the stat of its plus and of its minus; pair: the
-- bonus of two gold pieces ({ stat, pct } or { stat, hp }); style: the four
-- gold pieces (new rules, next PR: text only for now).
M.SETS = {
	{ id = "fabbro", name = "FABBRO", style_name = "Equilibrio",
		pieces = {
			mask = { "max_hp", "teleport_ticks" }, chest = { "knockback_mul", "air_speed" },
			legs = { "walk_speed", "jump_height" }, cloak = { "air_speed", "walk_speed" },
		},
		pair = { stat = "max_hp", hp = 3 },
		style = { a = "Mestiere: la prima cassa che apri ti dà un colpo in più di quell'arma, salto -5%",
			b = "Mano pesante: la Lama spinge il 15% in più, salto -5%" } },
	{ id = "corvo", name = "CORVO", style_name = "Aria",
		pieces = {
			mask = { "teleport_ticks", "max_hp" }, chest = { "max_hp", "walk_speed" },
			legs = { "jump_height", "walk_speed" }, cloak = { "air_speed", "knockback_mul" },
		},
		pair = { stat = "air_speed", pct = 0.04 },
		style = { a = "Picchiata: cadendo su un nemico da più di 150 px gli fai 10 di danno e lo spingi, vita -5",
			b = "Volo radente: aria +10%, vita -5" } },
	{ id = "fornace", name = "FORNACE", style_name = "Territorio",
		pieces = {
			mask = { "max_hp", "jump_height" }, chest = { "max_hp", "air_speed" },
			legs = { "jump_height", "walk_speed" }, cloak = { "fall_damage_mul", "jump_height" },
		},
		pair = { stat = "blast_push", pct = 0.03 },
		style = { a = "Terra rovente: le tue esplosioni lasciano braci per un turno, chi ci finisce il turno perde 5, salto -5%",
			b = "Brace lunga: braci per due turni, 3 a turno, salto -5%" } },
	{ id = "leviatano", name = "LEVIATANO", style_name = "Resistenza",
		pieces = {
			mask = { "max_hp", "teleport_ticks" }, chest = { "knockback_mul", "walk_speed" },
			legs = { "walk_speed", "jump_height" }, cloak = { "fall_damage_mul", "air_speed" },
		},
		pair = { stat = "knockback_mul", pct = 0.04 },
		style = { a = "Ancora: se finisci il turno senza muoverti prendi metà spinta fino al tuo turno, corsa -5%",
			b = "Scaglie dure: il primo colpo di ogni turno nemico ti fa 3 in meno, corsa -5%" } },
	{ id = "vuoto", name = "VUOTO", style_name = "Inganno",
		pieces = {
			mask = { "teleport_ticks", "max_hp" }, chest = { "knockback_mul", "max_hp" },
			legs = { "walk_speed", "knockback_mul" }, cloak = { "air_speed", "max_hp" },
		},
		pair = { stat = "teleport_ticks", pct = 0.05 },
		style = { a = "Senza scia: gli avversari non vedono la tua mira né dove va il globo, vita -5",
			b = "Passo nel vuoto: dopo un teletrasporto il primo colpo che prendi spinge la metà, vita -5" } },
}

M.BY_ID = {}
for _, s in ipairs(M.SETS) do M.BY_ID[s.id] = s end

-- the next step of a piece at that level (nil: it has reached all of them)
function M.next_tier(level)
	for _, s in ipairs(M.TIER_LEVELS) do
		if level < s then return s end
	end
end

-- tier of a piece at that level: 1 below the first step, then one per step
function M.tier(level)
	local t = 1
	for i, n in ipairs(M.TIER_LEVELS) do
		if (level or 1) >= n then t = i + 1 end
	end
	return t
end

-- The plus of a piece at that level: a share (0.02 .. 0.049) or, for life,
-- points (2 .. 5)
function M.plus(stat, level)
	level = math.max(1, math.min(M.LIVELLO_MAX, level or 1))
	if M.STATS[stat].hp then return 2 + math.floor(3 * (level - 1) / (M.LIVELLO_MAX - 1) + 0.5) end
	return (20 + (level - 1)) / 1000
end

-- The minus at that level: -2% (life -2), halved at the step 20, gone at 30
function M.minus(stat, level)
	level = level or 1
	local n = level >= M.LIVELLO_MAX and 0 or level >= M.GOLD and 1 or 2
	if M.STATS[stat].hp then return n end
	return n / 100
end

-- A piece's effects at a level: { { stat, good = share or points }, ... }
-- (good > 0 helps, < 0 hurts; for life it is in points)
function M.piece(set, slot, level)
	local f = M.BY_ID[set]
	local p = f and f.pieces[slot]
	if not p then return {} end
	local out = { { stat = p[1], good = M.plus(p[1], level) } }
	local m = M.minus(p[2], level)
	if m > 0 then out[2] = { stat = p[2], good = -m } end
	return out
end

-- the families with two gold pieces worn (in the order of SETS)
function M.pairs_on(gear, levels)
	local n = {}
	for _, s in ipairs(M.SLOTS) do
		local g = gear[s.id]
		if g and M.BY_ID[g] and (levels and levels[s.id] or 1) >= M.GOLD then n[g] = (n[g] or 0) + 1 end
	end
	local out = {}
	for _, f in ipairs(M.SETS) do
		if (n[f.id] or 0) >= 2 then out[#out + 1] = f.id end
	end
	return out
end

-- The pieces' effect on each stat, already capped at CAP_PIECES (the pluses
-- and the pairs; the minuses are never capped): { stat = good }
function M.goods(gear, levels)
	local plus, minus = {}, {}
	local function add(stat, good)
		if good >= 0 then plus[stat] = (plus[stat] or 0) + good else minus[stat] = (minus[stat] or 0) + good end
	end
	for _, s in ipairs(M.SLOTS) do
		local g = gear[s.id]
		if g then
			for _, e in ipairs(M.piece(g, s.id, levels and levels[s.id] or 1)) do add(e.stat, e.good) end
		end
	end
	for _, id in ipairs(M.pairs_on(gear, levels)) do
		local b = M.BY_ID[id].pair
		add(b.stat, b.hp or b.pct)
	end
	local out = {}
	for stat, info in pairs(M.STATS) do
		local cap = info.hp and M.CAP_PIECES * 100 or M.CAP_PIECES
		local v = math.min(plus[stat] or 0, cap) + (minus[stat] or 0)
		if v ~= 0 then out[stat] = v end
	end
	return out
end

-- Applies the pieces to stats st (after the Sigilli); base: the stats with
-- nothing. A plus never takes a stat past CAP_ALL from the base, unless the
-- Sigilli alone already did (then the pieces add nothing to it).
function M.apply(st, base, gear, levels)
	for stat, good in pairs(M.goods(gear, levels)) do
		local info, b, v = M.STATS[stat], base[stat], st[stat]
		if type(b) == "number" and type(v) == "number" then
			local new
			if info.hp then
				new = v + good
				if good > 0 then new = math.min(new, math.max(v, b + M.CAP_ALL * 100)) end
			elseif info.less then
				new = v * (1 - good)
				if good > 0 then new = math.max(new, math.min(v, b * (1 - M.CAP_ALL))) end
			else
				new = v * (1 + good)
				if good > 0 then new = math.min(new, math.max(v, b * (1 + M.CAP_ALL))) end
			end
			st[stat] = new
		end
	end
	return st
end

return M
