-- Gear: the pieces of the Forge (Sergio, 10-11 Nov, page "I Pezzi della Forgia"
-- https://claude.ai/artifact/F5TiCLHXAqgPe7XUBi138A, choices 1-25).
-- Pure Lua, like sim/skills.lua.
--
-- The Sigilli say what you can do, the pieces say how you do it and who you
-- are. Four slots, five families. Every piece has four rows (Sergio, 14 Nov,
-- document https://claude.ai/artifact/WvXeAErLuw6uw5cHY4wwei): a main bonus
-- from its slot (the type changes from piece to piece), two secondaries on
-- any stat (they make the builds: all attack, all movement...), a minus that
-- never goes away (choosing a piece you give something up) and a signature
-- that only that piece has (on at the step 10). The rows grow a lot with the
-- level: the difference has to be felt, the matchmaking balances it. Two
-- gold pieces (level 20 or more) of the same family give the family's small
-- bonus; the four-piece style is text only for now.

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

-- The stats the pieces touch. points: counted in points (life, Attack and
-- Defense: a share of 0.25 is 25 points); less: lower is better (a plus
-- lowers them); move: the movement, with its own lower caps (the maps are
-- drawn for a jump, Sergio 14 Nov).
M.STATS = {
	attack = { points = true }, defense = { points = true }, max_hp = { points = true },
	walk_speed = { move = true }, jump_height = { move = true }, air_speed = { move = true },
	blast_push = {},
	teleport_ticks = { less = true }, knockback_mul = { less = true }, fall_damage_mul = { less = true },
}
-- What a slot's main bonus can be (one per piece, it changes from piece to
-- piece): the helmet hits, the armor holds, the boots run and jump, the cape flies
M.MAINS = {
	mask = { "attack", "teleport_ticks", "blast_push" },
	chest = { "defense", "max_hp", "knockback_mul" },
	legs = { "walk_speed", "jump_height" },
	cloak = { "air_speed", "fall_damage_mul" },
}
-- The rows of a piece at level 30 (shares of the base; points for life,
-- Attack and Defense). Every piece has the same budget: one main, two
-- secondaries, one minus that never goes away (Sergio, 14 Nov: «rinunci ad
-- una statistica»).
M.MAIN, M.SECOND, M.MINUS = 0.25, 0.10, 0.08
-- the caps on the pluses of a stat: from the pieces alone, and from
-- everything (pieces and Sigilli) over the base
M.CAP_PIECES = { power = 0.60, move = 0.25 }
M.CAP_ALL = { power = 0.70, move = 0.30 }

-- The signatures: one per piece, only that piece has it. They are stats of
-- the robot (config.STATS, default 0) read by sim/game.lua. max: its value
-- at level 30; it lights up at the step 10 (half), grows at 20 (three
-- quarters) and at 30 (all). desc: %d is the value in percent.
M.SIGNS = {
	sig_sword = { max = 0.20, name = "Mano del mestiere", desc = "La Lama fa il %d%% di danno in più" },
	sig_self = { max = 0.50, name = "Guscio di bottega", desc = "Le tue esplosioni ti fanno il %d%% di danno in meno" },
	sig_climb = { max = 0.50, name = "Passo di montagna", desc = "Sali da solo gradini più alti del %d%%" },
	sig_chute = { max = 1.00, name = "Cappa da forgia", desc = "Col paracadute aperto le spinte ti spostano il %d%% in meno" },
	sig_high = { max = 0.12, name = "Dall'alto", desc = "Contro chi sta più in basso di te fai il %d%% di danno in più" },
	sig_air_guard = { max = 0.15, name = "Piume", desc = "In aria prendi il %d%% di danno in meno" },
	sig_soft = { max = 0.50, name = "Atterraggio morbido", desc = "Cadi senza farti male da un'altezza più grande del %d%%" },
	sig_glide = { max = 0.25, name = "Planata", desc = "Scendendo in aria cadi il %d%% più piano" },
	sig_first = { max = 0.15, name = "Primo sangue", desc = "Il primo colpo del tuo turno fa il %d%% di danno in più" },
	sig_thorns = { max = 1.00, name = "Brace addosso", desc = "Chi ti colpisce da vicino (Lama, Maglio, Pugno, Affondo) prende la bruciatura" },
	sig_stomp = { max = 1.00, name = "Pestone", desc = "Atterrando da una caduta lunga spingi via chi ti sta vicino (forza %d%%)" },
	sig_air_fire = { max = 0.10, name = "Coda di fuoco", desc = "Se sei in aria quando il tuo colpo arriva fa il %d%% di danno in più" },
	sig_fury = { max = 0.15, name = "Furia", desc = "Sotto 30 di vita fai il %d%% di danno in più" },
	sig_first_guard = { max = 0.20, name = "Pelle dura", desc = "Il primo colpo che prendi in ogni turno nemico fa il %d%% in meno" },
	sig_rooted = { max = 0.30, name = "Piedi piantati", desc = "A terra le spinte ti spostano il %d%% in meno" },
	sig_ballast = { max = 0.25, name = "Zavorra", desc = "In aria le spinte ti spostano il %d%% in meno" },
	sig_ambush = { max = 0.12, name = "Agguato", desc = "Dopo un tuo teletrasporto, nello stesso turno, fai il %d%% di danno in più" },
	sig_blink_guard = { max = 0.15, name = "Velo", desc = "Dopo un tuo teletrasporto, fino al tuo turno dopo, prendi il %d%% di danno in meno" },
	sig_blink_run = { max = 0.20, name = "Scia breve", desc = "Dopo un tuo teletrasporto corri il %d%% più veloce fino a fine turno" },
	sig_far_orb = { max = 0.20, name = "Lancio lungo", desc = "Il globo parte il %d%% più veloce e arriva più lontano" },
}
-- how much of a signature's max at each grade (I: off)
M.SIGN_TIERS = { 0, 0.5, 0.75, 1 }

-- Families: for each slot { main, { two secondaries }, minus, signature }; art:
-- the piece's picture once it is drawn (nil: the placeholder of
-- menu/pieces.lua); color: the family's color on the placeholders. pair: the
-- bonus of two gold pieces ({ stat, share }); style: the four gold pieces
-- (new rules, next PR: text only for now).
M.SETS = {
	{ id = "fabbro", name = "FABBRO", style_name = "Equilibrio", color = "ffb703",
		pieces = {
			mask = { "attack", { "blast_push", "max_hp" }, "walk_speed", "sig_sword" },
			chest = { "defense", { "attack", "knockback_mul" }, "jump_height", "sig_self" },
			legs = { "walk_speed", { "defense", "attack" }, "air_speed", "sig_climb" },
			cloak = { "fall_damage_mul", { "max_hp", "attack" }, "teleport_ticks", "sig_chute" },
		},
		pair = { stat = "max_hp", share = 0.03 },
		style = { a = "Mestiere: la prima cassa che apri ti dà un colpo in più di quell'arma, salto -5%",
			b = "Mano pesante: la Lama spinge il 15% in più, salto -5%" } },
	{ id = "corvo", name = "CORVO", style_name = "Aria", color = "9ec4e0",
		pieces = {
			mask = { "teleport_ticks", { "jump_height", "attack" }, "max_hp", "sig_high" },
			chest = { "knockback_mul", { "jump_height", "air_speed" }, "max_hp", "sig_air_guard" },
			legs = { "jump_height", { "air_speed", "walk_speed" }, "defense", "sig_soft" },
			cloak = { "air_speed", { "jump_height", "attack" }, "defense", "sig_glide" },
		},
		pair = { stat = "air_speed", share = 0.04 },
		style = { a = "Picchiata: cadendo su un nemico da più di 150 px gli fai 10 di danno e lo spingi, vita -5",
			b = "Volo radente: aria +10%, vita -5" } },
	{ id = "fornace", name = "FORNACE", style_name = "Territorio", color = "f26419",
		pieces = {
			mask = { "attack", { "blast_push", "walk_speed" }, "defense", "sig_first" },
			chest = { "max_hp", { "attack", "blast_push" }, "jump_height", "sig_thorns" },
			legs = { "walk_speed", { "attack", "blast_push" }, "max_hp", "sig_stomp" },
			cloak = { "air_speed", { "attack", "fall_damage_mul" }, "knockback_mul", "sig_air_fire" },
		},
		pair = { stat = "blast_push", share = 0.03 },
		style = { a = "Terra rovente: le tue esplosioni lasciano braci per un turno, chi ci finisce il turno perde 5, salto -5%",
			b = "Brace lunga: braci per due turni, 3 a turno, salto -5%" } },
	{ id = "leviatano", name = "LEVIATANO", style_name = "Resistenza", color = "5cdbb8",
		pieces = {
			mask = { "blast_push", { "defense", "max_hp" }, "jump_height", "sig_fury" },
			chest = { "defense", { "max_hp", "knockback_mul" }, "walk_speed", "sig_first_guard" },
			legs = { "walk_speed", { "defense", "knockback_mul" }, "jump_height", "sig_rooted" },
			cloak = { "fall_damage_mul", { "defense", "knockback_mul" }, "air_speed", "sig_ballast" },
		},
		pair = { stat = "knockback_mul", share = 0.04 },
		style = { a = "Ancora: se finisci il turno senza muoverti prendi metà spinta fino al tuo turno, corsa -5%",
			b = "Scaglie dure: il primo colpo di ogni turno nemico ti fa 3 in meno, corsa -5%" } },
	{ id = "vuoto", name = "VUOTO", style_name = "Inganno", color = "c49cff",
		pieces = {
			mask = { "teleport_ticks", { "attack", "walk_speed" }, "defense", "sig_ambush" },
			chest = { "knockback_mul", { "teleport_ticks", "defense" }, "max_hp", "sig_blink_guard" },
			legs = { "walk_speed", { "teleport_ticks", "jump_height" }, "defense", "sig_blink_run" },
			cloak = { "air_speed", { "teleport_ticks", "walk_speed" }, "max_hp", "sig_far_orb" },
		},
		pair = { stat = "teleport_ticks", share = 0.05 },
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

-- How much of a row's level-30 value a piece has at that level: linear
-- with a jump at every step (Sergio, 14 Nov: «si deve sentire»): 20% at
-- level 1, then 70% of the rest spread evenly and 10% at each step 10, 20, 30.
function M.growth(level)
	level = math.max(1, math.min(M.LIVELLO_MAX, level or 1))
	return 0.2 + 0.8 * (0.7 * (level - 1) / (M.LIVELLO_MAX - 1) + 0.1 * (M.tier(level) - 1))
end

local function round(v) return math.floor(v * 1000 + 0.5) / 1000 end

-- A piece's rows at a level: { { stat, good = share, row = "main" | "second" |
-- "minus" | "sign" }, ... } (good > 0 helps, < 0 hurts; a signature's good is
-- its value, 0 below the step 10)
function M.piece(set, slot, level)
	local f = M.BY_ID[set]
	local p = f and f.pieces[slot]
	if not p then return {} end
	local k = M.growth(level)
	local out = { { stat = p[1], good = round(M.MAIN * k), row = "main" } }
	for _, s in ipairs(p[2]) do out[#out + 1] = { stat = s, good = round(M.SECOND * k), row = "second" } end
	out[#out + 1] = { stat = p[3], good = -M.MINUS, row = "minus" }
	local sg = M.SIGNS[p[4]]
	out[#out + 1] = { stat = p[4], good = round(sg.max * M.SIGN_TIERS[M.tier(level)]), row = "sign" }
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

local function group(stat) return M.STATS[stat].move and "move" or "power" end

-- The pieces' effect on each stat (shares), the pluses already capped at
-- CAP_PIECES (the minuses are never capped), and the signatures' values:
-- { stat = good }
function M.goods(gear, levels)
	local plus, minus, out = {}, {}, {}
	local function add(stat, good)
		if good >= 0 then plus[stat] = (plus[stat] or 0) + good else minus[stat] = (minus[stat] or 0) + good end
	end
	for _, s in ipairs(M.SLOTS) do
		local g = gear[s.id]
		if g then
			for _, e in ipairs(M.piece(g, s.id, levels and levels[s.id] or 1)) do
				if e.row == "sign" then
					if e.good > 0 then out[e.stat] = (out[e.stat] or 0) + e.good end
				else
					add(e.stat, e.good)
				end
			end
		end
	end
	for _, id in ipairs(M.pairs_on(gear, levels)) do
		local b = M.BY_ID[id].pair
		add(b.stat, b.share)
	end
	for stat in pairs(M.STATS) do
		local v = math.min(plus[stat] or 0, M.CAP_PIECES[group(stat)]) + (minus[stat] or 0)
		if v ~= 0 then out[stat] = v end
	end
	return out
end

-- Applies the pieces to stats st (after the Sigilli); base: the stats with
-- nothing. A plus never takes a stat past CAP_ALL from the base, unless the
-- Sigilli alone already did (then the pieces add nothing to it). The
-- signatures are added as they are.
function M.apply(st, base, gear, levels)
	for stat, good in pairs(M.goods(gear, levels)) do
		local info, b, v = M.STATS[stat], base[stat], st[stat]
		if not info then
			st[stat] = (v or 0) + good
		elseif type(b) == "number" and type(v) == "number" then
			local cap = M.CAP_ALL[group(stat)]
			local new
			if info.points then
				new = v + good * 100
				if good > 0 then new = math.min(new, math.max(v, b + cap * 100)) end
			elseif info.less then
				new = v * (1 - good)
				if good > 0 then new = math.max(new, math.min(v, b * (1 - cap))) end
			else
				new = v * (1 + good)
				if good > 0 then new = math.min(new, math.max(v, b * (1 + cap))) end
			end
			st[stat] = new
		end
	end
	return st
end

return M
