-- Equipaggiamento: i quattro set dei Titani (bibbia grafica "Le Scorie").
-- Lua puro, come sim/abilita.lua.
--
-- Dal documento di game design: misto di sidegrade (ogni pezzo dà qualcosa e
-- toglie qualcosa) e tier che cambiano aspetto e varianti. Il tier non rende
-- più forti: con tutti e quattro i pezzi di un set all'ultimo tier si sceglie la
-- variante B del bonus del set invece della A. I tier cambieranno l'aspetto
-- quando l'armatura si vedrà sulla Scoria. potere: il nome breve del bonus,
-- sul cartellino (ui/cartellino.lua).
--
-- Effetti come in abilita.lua: { stat, add } | { stat, mul }.

local M = {}

M.SLOTS = {
	{ id = "mask", name = "MASCHERA", art = "maschera" },
	{ id = "chest", name = "CORAZZA", art = "corazza" },
	{ id = "cloak", name = "MANTELLO", art = "mantello" },
	{ id = "legs", name = "GAMBALI", art = "gambali_davanti" },
}
-- Livello di un pezzo: le partite giocate con lui, fino a LIVELLO_MAX. Ogni
-- SCATTI livelli il pezzo sale di tier (Sergio, 31 ott, ancora un'ipotesi:
-- "ogni pezzo uppato 20 o 30 volte, e agli scatti di 10 livelli poteri o
-- cose particolari e graficamente più figo"). Oggi il tier cambia solo
-- l'aspetto (quando l'armatura si vedrà addosso), e coi quattro pezzi di un
-- set al massimo si sceglie la variante B del bonus: come prima, a 30 partite.
M.LIVELLO_MAX = 30
M.SCATTI = { 10, 20, 30 }
M.TIERS = #M.SCATTI + 1
-- pezzi dello stesso set che servono per il bonus
M.SET_PIECES = 4
-- partite giocate con un pezzo per farlo salire di tier (maestria del set)
M.TIER_MATCHES = { 0, M.SCATTI[1], M.SCATTI[2], M.SCATTI[3] }

-- Pezzi: per ogni set e slot un più e un meno, in percentuale sulla base (le
-- statistiche di movimento cambiano col profilo di fisica). Bonus: a pezzi completi.
M.SETS = {
	{ id = "corvo", name = "CORVO", style = "Agilità",
		pieces = {
			mask = { { stat = "jump_height", mul = 1.03 }, { stat = "max_hp", add = -2 } },
			chest = { { stat = "air_speed", mul = 1.03 }, { stat = "max_hp", add = -2 } },
			cloak = { { stat = "air_speed", mul = 1.03 }, { stat = "walk_speed", mul = 0.98 } },
			legs = { { stat = "jump_height", mul = 1.03 }, { stat = "walk_speed", mul = 0.98 } },
		},
		bonus = {
			a = { desc = "Doppio salto e caduta senza danno, vita -10%", potere = "doppio salto",
				effects = { { stat = "air_jumps", add = 1 }, { stat = "fall_damage_mul", mul = 0 },
					{ stat = "max_hp", mul = 0.9 } } },
			b = { desc = "Due salti in aria, vita -10%", potere = "due salti in aria",
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
			a = { desc = "L'Uovo brucia chi colpisce, salto -10%", potere = "uovo che brucia",
				effects = { { stat = "burning_blasts", add = 1 }, { stat = "jump_height", mul = 0.9 } } },
			b = { desc = "L'Uovo brucia, gli effetti durano un turno in più, vita -10%", potere = "brace lunga",
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
			a = { desc = "Spinta subita -30%, metà danno da caduta, corsa -10%", potere = "radici",
				effects = { { stat = "knockback_mul", mul = 0.7 }, { stat = "fall_damage_mul", mul = 0.5 },
					{ stat = "walk_speed", mul = 0.9 } } },
			b = { desc = "Spinta subita dimezzata, salto -10%", potere = "radici profonde",
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
			a = { desc = "Il teletrasporto scatta il 25% prima, vita -10%", potere = "globo lesto",
				effects = { { stat = "teleport_ticks", mul = 0.75 }, { stat = "max_hp", mul = 0.9 } } },
			b = { desc = "Un teletrasporto in più, vita -10%", potere = "globo in più",
				effects = { { stat = "teleports", add = 1 }, { stat = "max_hp", mul = 0.9 } } },
		} },
}

M.BY_ID = {}
for _, s in ipairs(M.SETS) do M.BY_ID[s.id] = s end

-- livello di un pezzo dalle partite giocate con lui
function M.livello(matches)
	return math.min(M.LIVELLO_MAX, matches or 0)
end

-- il prossimo scatto di un pezzo a quel livello (nil: li ha presi tutti)
function M.prossimo_scatto(livello)
	for _, s in ipairs(M.SCATTI) do
		if livello < s then return s end
	end
end

-- tier di un pezzo dalle partite giocate con lui
function M.tier(matches)
	local t = 1
	for i, n in ipairs(M.TIER_MATCHES) do
		if (matches or 0) >= n then t = i end
	end
	return t
end

-- il set che dà il bonus, se c'è: id del set e variante possibile ("b" solo con tutti i pezzi all'ultimo tier)
-- gear = { mask = id del set, ... }, tiers = { mask = 1..3, ... }
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

-- aggiunge a mods gli effetti dei pezzi e del bonus, un gruppo per pezzo e
-- uno per il bonus; variant "b" solo se concessa
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
