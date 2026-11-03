-- Gear: the four Titan sets (art bible "Le Scorie").
-- Pure Lua, like sim/skills.lua.
--
-- From the game design document: a mix of sidegrades (each piece gives
-- something and takes something away) and tiers that change look and variants.
-- Tiers do not make you stronger: with all four pieces of a set at the last
-- tier you pick variant B of the set bonus instead of A. Tiers will change the
-- look once armour is visible on the Scoria. potere: the short name of the
-- bonus, shown on the card (ui/cartellino.lua).
--
-- Effects as in skills.lua: { stat, add } | { stat, mul }.

local M = {}

M.SLOTS = {
	{ id = "mask", name = "MASCHERA", art = "maschera" },
	{ id = "chest", name = "CORAZZA", art = "corazza" },
	{ id = "cloak", name = "MANTELLO", art = "mantello" },
	{ id = "legs", name = "GAMBALI", art = "gambali_davanti" },
}
-- Level of a piece: matches played with it, up to LIVELLO_MAX. Every SCATTI
-- levels the piece goes up a tier (Sergio, 31 Oct, still a hypothesis:
-- "ogni pezzo uppato 20 o 30 volte, e agli scatti di 10 livelli poteri o
-- cose particolari e graficamente più figo"). Today the tier only changes the
-- look (once armour is visible on the character), and with all four pieces of
-- a set maxed you pick variant B of the bonus: as before, at 30 matches.
M.LIVELLO_MAX = 30
M.TIER_LEVELS = { 10, 20, 30 }
M.TIERS = #M.TIER_LEVELS + 1
-- pieces of the same set needed for the bonus
M.SET_PIECES = 4
-- matches played with a piece to raise its tier (set mastery)
M.TIER_MATCHES = { 0, M.TIER_LEVELS[1], M.TIER_LEVELS[2], M.TIER_LEVELS[3] }

-- Pieces: for each set and slot one plus and one minus, as a percentage of the
-- base (movement stats start from sim/game.lua, DEFAULT_STATS). Bonus: full set.
M.SETS = {
	{ id = "corvo", name = "CORVO", style = "Agilità",
		pieces = {
			mask = { { stat = "jump_height", mul = 1.03 }, { stat = "max_hp", add = -2 } },
			chest = { { stat = "air_speed", mul = 1.03 }, { stat = "max_hp", add = -2 } },
			cloak = { { stat = "air_speed", mul = 1.03 }, { stat = "walk_speed", mul = 0.98 } },
			legs = { { stat = "jump_height", mul = 1.03 }, { stat = "walk_speed", mul = 0.98 } },
		},
		bonus = {
			a = { desc = "Doppio salto e caduta senza danno, vita -10%", power_name = "doppio salto",
				effects = { { stat = "air_jumps", add = 1 }, { stat = "fall_damage_mul", mul = 0 },
					{ stat = "max_hp", mul = 0.9 } } },
			b = { desc = "Due salti in aria, vita -10%", power_name = "due salti in aria",
				effects = { { stat = "air_jumps", add = 2 }, { stat = "max_hp", mul = 0.9 } } },
		} },
	{ id = "fornace", name = "FORNACE", style = "Territorio",
		pieces = {
			mask = { { stat = "max_hp", add = 2 }, { stat = "jump_height", mul = 0.98 } },
			chest = { { stat = "max_hp", add = 3 }, { stat = "air_speed", mul = 0.97 } },
			cloak = { { stat = "teleports", add = 1 }, { stat = "jump_height", mul = 0.95 } },
			legs = { { stat = "max_hp", add = 2 }, { stat = "walk_speed", mul = 0.98 } },
		},
		bonus = {
			a = { desc = "L'Uovo brucia chi colpisce, salto -10%", power_name = "uovo che brucia",
				effects = { { stat = "burning_blasts", add = 1 }, { stat = "jump_height", mul = 0.9 } } },
			b = { desc = "L'Uovo brucia, gli effetti durano un turno in più, vita -10%", power_name = "brace lunga",
				effects = { { stat = "burning_blasts", add = 1 }, { stat = "status_turns", add = 1 },
					{ stat = "max_hp", mul = 0.9 } } },
		} },
	{ id = "leviatano", name = "LEVIATANO", style = "Resistenza",
		pieces = {
			mask = { { stat = "max_hp", add = 3 }, { stat = "jump_height", mul = 0.97 } },
			chest = { { stat = "max_hp", add = 4 }, { stat = "walk_speed", mul = 0.96 } },
			cloak = { { stat = "knockback_mul", mul = 0.95 }, { stat = "air_speed", mul = 0.97 } },
			legs = { { stat = "max_hp", add = 3 }, { stat = "walk_speed", mul = 0.97 } },
		},
		bonus = {
			a = { desc = "Spinta subita -30%, metà danno da caduta, corsa -10%", power_name = "radici",
				effects = { { stat = "knockback_mul", mul = 0.7 }, { stat = "fall_damage_mul", mul = 0.5 },
					{ stat = "walk_speed", mul = 0.9 } } },
			b = { desc = "Spinta subita dimezzata, salto -10%", power_name = "radici profonde",
				effects = { { stat = "knockback_mul", mul = 0.5 }, { stat = "jump_height", mul = 0.9 } } },
		} },
	{ id = "vuoto", name = "VUOTO", style = "Inganno",
		pieces = {
			mask = { { stat = "teleport_ticks", mul = 0.96 }, { stat = "max_hp", add = -2 } },
			chest = { { stat = "walk_speed", mul = 1.03 }, { stat = "max_hp", add = -2 } },
			cloak = { { stat = "teleport_ticks", mul = 0.96 }, { stat = "jump_height", mul = 0.98 } },
			legs = { { stat = "walk_speed", mul = 1.03 }, { stat = "air_speed", mul = 0.98 } },
		},
		bonus = {
			a = { desc = "Il teletrasporto scatta il 25% prima, vita -10%", power_name = "globo lesto",
				effects = { { stat = "teleport_ticks", mul = 0.75 }, { stat = "max_hp", mul = 0.9 } } },
			b = { desc = "Un teletrasporto in più, vita -10%", power_name = "globo in più",
				effects = { { stat = "teleports", add = 1 }, { stat = "max_hp", mul = 0.9 } } },
		} },
}

M.BY_ID = {}
for _, s in ipairs(M.SETS) do M.BY_ID[s.id] = s end

-- level of a piece from the matches played with it
function M.livello(matches)
	return math.min(M.LIVELLO_MAX, matches or 0)
end

-- the next step of a piece at that level (nil: it has reached all of them)
function M.next_tier(level)
	for _, s in ipairs(M.TIER_LEVELS) do
		if level < s then return s end
	end
end

-- tier of a piece from the matches played with it
function M.tier(matches)
	local t = 1
	for i, n in ipairs(M.TIER_MATCHES) do
		if (matches or 0) >= n then t = i end
	end
	return t
end

-- the set giving the bonus, if any: set id and allowed variant ("b" only with all pieces at the last tier)
-- gear = { mask = set id, ... }, tiers = { mask = 1..3, ... }
function M.full_set(gear, tiers)
	local id, n, top = nil, 0, true
	for _, s in ipairs(M.SLOTS) do
		local g = gear[s.id]
		if g and (id == nil or g == id) then
			id, n = g, n + 1
			if (tiers and tiers[s.id] or 1) < M.TIERS then top = false end
		end
	end
	if n < M.SET_PIECES then return nil end
	return id, top
end

-- adds to mods the effects of the pieces and of the bonus, one group per piece
-- and one for the bonus; variant "b" only if allowed
function M.mods(gear, tiers, variant, mods)
	for _, s in ipairs(M.SLOTS) do
		local set = M.BY_ID[gear[s.id] or ""]
		if set then mods[#mods + 1] = set.pieces[s.id] end
	end
	local id, top = M.full_set(gear, tiers)
	local bonus = id and M.BY_ID[id].bonus
	if bonus then mods[#mods + 1] = bonus[(variant == "b" and top) and "b" or "a"].effects end
	return mods
end

return M
