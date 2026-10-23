-- Equipaggiamento: i quattro set dei Titani (bibbia grafica "Le Scorie").
-- Lua puro, come sim/abilita.lua.
--
-- Dal documento di game design: misto di sidegrade (ogni pezzo dà qualcosa e
-- toglie qualcosa) e tier che cambiano aspetto e varianti. Il tier non rende
-- più forti: con tutti e quattro i pezzi di un set al tier III si sceglie la
-- variante B del bonus del set invece della A. I tier cambieranno l'aspetto
-- quando l'armatura si vedrà sulla Scoria.
--
-- Effetti come in abilita.lua: { stat, add } | { stat, mul }.

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

-- Pezzi: per ogni set e slot un più e un meno, in percentuale sulla base (le
-- statistiche di movimento cambiano col profilo di fisica). Bonus: a pezzi completi.
-- Ci sono solo i bonus delle meccaniche che il gioco ha già: quelli del
-- documento per Corvo (doppio salto) e Fornace (terreno bruciante) arrivano
-- con la loro meccanica.
M.SETS = {
	{ id = "corvo", name = "CORVO", style = "Agilità",
		pieces = {
			mask = { { stat = "jump_height", mul = 1.03 }, { stat = "max_hp", add = -3 } },
			chest = { { stat = "air_speed", mul = 1.03 }, { stat = "max_hp", add = -3 } },
			cloak = { { stat = "air_speed", mul = 1.03 }, { stat = "walk_speed", mul = 0.98 } },
			legs = { { stat = "jump_height", mul = 1.03 }, { stat = "walk_speed", mul = 0.98 } },
		} },
	{ id = "fornace", name = "FORNACE", style = "Territorio",
		pieces = {
			mask = { { stat = "max_hp", add = 3 }, { stat = "jump_height", mul = 0.98 } },
			chest = { { stat = "max_hp", add = 4 }, { stat = "air_speed", mul = 0.97 } },
			cloak = { { stat = "start_nucleo", add = 1 }, { stat = "jump_height", mul = 0.95 } },
			legs = { { stat = "max_hp", add = 3 }, { stat = "walk_speed", mul = 0.98 } },
		} },
	{ id = "leviatano", name = "LEVIATANO", style = "Resistenza",
		pieces = {
			mask = { { stat = "max_hp", add = 4 }, { stat = "jump_height", mul = 0.97 } },
			chest = { { stat = "max_hp", add = 6 }, { stat = "walk_speed", mul = 0.96 } },
			cloak = { { stat = "knockback_mul", mul = 0.95 }, { stat = "air_speed", mul = 0.97 } },
			legs = { { stat = "max_hp", add = 4 }, { stat = "walk_speed", mul = 0.97 } },
		},
		bonus = {
			a = { desc = "Spinta subita -30%, metà danno da caduta, corsa -10%",
				effects = { { stat = "knockback_mul", mul = 0.7 }, { stat = "fall_damage_mul", mul = 0.5 },
					{ stat = "walk_speed", mul = 0.9 } } },
			b = { desc = "Spinta subita dimezzata, salto -10%",
				effects = { { stat = "knockback_mul", mul = 0.5 }, { stat = "jump_height", mul = 0.9 } } },
		} },
	{ id = "vuoto", name = "VUOTO", style = "Inganno",
		pieces = {
			mask = { { stat = "teleport_ticks", mul = 0.96 }, { stat = "max_hp", add = -3 } },
			chest = { { stat = "walk_speed", mul = 1.03 }, { stat = "max_hp", add = -3 } },
			cloak = { { stat = "teleport_ticks", mul = 0.96 }, { stat = "jump_height", mul = 0.98 } },
			legs = { { stat = "walk_speed", mul = 1.03 }, { stat = "air_speed", mul = 0.98 } },
		},
		bonus = {
			a = { desc = "Il teletrasporto scatta il 25% prima, vita -10%",
				effects = { { stat = "teleport_ticks", mul = 0.75 }, { stat = "max_hp", mul = 0.9 } } },
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
