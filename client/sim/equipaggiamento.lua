-- Equipaggiamento: i quattro set dei Titani (bibbia grafica "Le Scorie").
-- Lua puro, come sim/abilita.lua.
--
-- Dal documento di game design: misto di sidegrade (ogni pezzo dà qualcosa e
-- toglie qualcosa) e tier che cambiano aspetto e varianti. Il tier non rende
-- più forti: con tutti e quattro i pezzi di un set al tier III si sceglie la
-- variante B del bonus del set invece della A.
--
-- Effetti come in abilita.lua: { stat, add } | { stat, mul } | { stat, set }.

local M = {}

M.SLOTS = {
	{ id = "mask", name = "MASCHERA", art = "maschera" },
	{ id = "chest", name = "CORAZZA", art = "corazza" },
	{ id = "cloak", name = "MANTELLO", art = "mantello" },
	{ id = "legs", name = "GAMBALI", art = "gambali_davanti" },
}
M.TIERS = 3
-- pezzi dello stesso set che servono per il bonus
M.SET_PIECES = 4
-- partite giocate con un pezzo per farlo salire di tier (maestria del set)
M.TIER_MATCHES = { 0, 10, 30 }

-- Pezzi: per ogni set e slot un più e un meno. Bonus: a pezzi completi.
M.SETS = {
	{ id = "corvo", name = "CORVO", style = "Agilità",
		pieces = {
			mask = { { stat = "jump_height", add = 2 }, { stat = "max_hp", add = -2 } },
			chest = { { stat = "air_speed", add = 3 }, { stat = "max_hp", add = -3 } },
			cloak = { { stat = "air_speed", add = 3 }, { stat = "walk_speed", add = -2 } },
			legs = { { stat = "jump_height", add = 2 }, { stat = "walk_speed", add = -2 } },
		},
		bonus = {
			a = { desc = "Doppio salto gratis, nessun danno da caduta, vita -10%",
				effects = { { stat = "air_jumps", add = 1 }, { stat = "air_jump_cost", set = 0 },
					{ stat = "fall_damage_mul", set = 0 }, { stat = "max_hp", mul = 0.9 } } },
			b = { desc = "Doppio salto gratis, +5 di velocità in aria, vita -10%",
				effects = { { stat = "air_jumps", add = 1 }, { stat = "air_jump_cost", set = 0 },
					{ stat = "air_speed", add = 5 }, { stat = "max_hp", mul = 0.9 } } },
		} },
	{ id = "fornace", name = "FORNACE", style = "Territorio",
		pieces = {
			mask = { { stat = "status_ticks", add = 15 }, { stat = "jump_height", add = -2 } },
			chest = { { stat = "max_hp", add = 4 }, { stat = "air_speed", add = -3 } },
			cloak = { { stat = "trap_radius", add = 3 }, { stat = "jump_height", add = -2 } },
			legs = { { stat = "max_hp", add = 3 }, { stat = "walk_speed", add = -2 } },
		},
		bonus = {
			a = { desc = "Le esplosioni lasciano terreno bruciante per un turno, salto più basso",
				effects = { { stat = "burning_blasts", set = true }, { stat = "jump_height", mul = 0.9 } } },
			b = { desc = "Gli effetti di stato durano il doppio, salto più basso",
				effects = { { stat = "status_ticks", mul = 2 }, { stat = "jump_height", mul = 0.9 } } },
		} },
	{ id = "leviatano", name = "LEVIATANO", style = "Resistenza",
		pieces = {
			mask = { { stat = "max_hp", add = 3 }, { stat = "jump_height", add = -2 } },
			chest = { { stat = "max_hp", add = 5 }, { stat = "walk_speed", add = -3 } },
			cloak = { { stat = "knockback_mul", add = -0.05 }, { stat = "air_speed", add = -3 } },
			legs = { { stat = "knockback_mul", add = -0.05 }, { stat = "walk_speed", add = -2 } },
		},
		bonus = {
			a = { desc = "Spinto poco dai colpi, metà danno da caduta, cammina più lento",
				effects = { { stat = "knockback_mul", mul = 0.7 }, { stat = "fall_damage_mul", mul = 0.5 },
					{ stat = "walk_speed", mul = 0.9 } } },
			b = { desc = "Vita +10%, metà danno da caduta, cammina più lento",
				effects = { { stat = "max_hp", mul = 1.1 }, { stat = "fall_damage_mul", mul = 0.5 },
					{ stat = "walk_speed", mul = 0.9 } } },
		} },
	{ id = "vuoto", name = "VUOTO", style = "Inganno",
		pieces = {
			mask = { { stat = "teleport_ticks", add = -6 }, { stat = "max_hp", add = -2 } },
			chest = { { stat = "walk_speed", add = 3 }, { stat = "max_hp", add = -3 } },
			cloak = { { stat = "teleport_ticks", add = -6 }, { stat = "jump_height", add = -2 } },
			legs = { { stat = "walk_speed", add = 3 }, { stat = "air_speed", add = -2 } },
		},
		bonus = {
			a = { desc = "Il teletrasporto scatta dopo 1,5 s invece di 2, vita -10%",
				effects = { { stat = "teleport_ticks", add = -30 }, { stat = "max_hp", mul = 0.9 } } },
			b = { desc = "Il primo teletrasporto è gratis, vita -10%",
				effects = { { stat = "free_teleports", add = 1 }, { stat = "max_hp", mul = 0.9 } } },
		} },
}

M.BY_ID = {}
for _, s in ipairs(M.SETS) do M.BY_ID[s.id] = s end

-- tier di un pezzo dalle partite giocate con lui
function M.tier(matches)
	local t = 1
	for i, n in ipairs(M.TIER_MATCHES) do
		if (matches or 0) >= n then t = i end
	end
	return t
end

-- il set che dà il bonus, se c'è: id del set e variante possibile ("b" solo a tier III)
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

-- aggiunge gli effetti dei pezzi e del bonus a mods; variant "b" solo se concessa
function M.mods(gear, tiers, variant, mods)
	for _, s in ipairs(M.SLOTS) do
		local set = M.BY_ID[gear[s.id] or ""]
		if set then
			for _, e in ipairs(set.pieces[s.id]) do mods[#mods + 1] = e end
		end
	end
	local id, top = M.full_set(gear, tiers)
	if id then
		local bonus = M.BY_ID[id].bonus[(variant == "b" and top) and "b" or "a"]
		for _, e in ipairs(bonus.effects) do mods[#mods + 1] = e end
	end
	return mods
end

return M
