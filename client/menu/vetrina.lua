-- Vetrina: quello che il cartellino di un giocatore mostra (ui/cartellino.lua),
-- in dati. Lua puro, così si prova nei test, si salva nelle partite del profilo
-- (com'era quel giocatore quella volta) e online si manda agli altri.
--
--   v = { nome, squadra (1..4), sotto (la riga sotto il nome), livello (nil: non si sa), bot,
--         torneo (i valori sono quelli del Torneo), badge = { { id, grado }, ... },
--         pezzi = { { slot, set, livello, tier } x4 (set nil: vuoto) },
--         poteri = { "doppio salto", ... }, albero = { punti per ramo }, punti (dell'albero),
--         stats = { le statistiche in partita che il cartellino mostra } }
--
--   vetrina.da_profilo(p, nome, squadra, sotto, torneo)  -- chi gioca su questo telefono
--   vetrina.semplice(nome, squadra, sotto, livello, badge) -- bot, compagni, avversari online
--   vetrina.con_stats(v, st)                 -- le statistiche vere della partita (g.robots[i].stats)
--   vetrina.righe(v, base)                   -- le quattro barre: { nome, valore, scarto }
--   vetrina.risorse(v)                       -- globi, paracadute, salti in aria

local game = require "sim.game"
local abilita = require "sim.abilita"
local assetto = require "sim.assetto"
local equip = require "sim.equipaggiamento"
local profilo = require "menu.profilo"

local M = {}

-- le statistiche che il cartellino legge
M.CHIAVI = { "max_hp", "jump_height", "walk_speed", "air_speed", "teleports", "parachutes", "air_jumps" }
-- le quattro barre: la vita in punti, le altre in percentuale sulla base
M.BARRE = { { "max_hp", "VITA", "punti" }, { "jump_height", "SALTO" }, { "walk_speed", "CORSA" }, { "air_speed", "ARIA" } }
-- fin dove arriva una barra (piena da un lato): 10% sopra o sotto la base
M.SCALA = 0.1

local function copia_stats(st)
	local o = {}
	for _, k in ipairs(M.CHIAVI) do o[k] = st[k] end
	return o
end

local function pezzi_vuoti()
	local out = {}
	for i, s in ipairs(equip.SLOTS) do out[i] = { slot = s.id, livello = 0, tier = 1 } end
	return out
end

-- I poteri di un assetto: il bonus del set completo e i nodi dell'albero che
-- danno una cosa nuova
function M.poteri(a, tiers)
	local out = {}
	local id, top = equip.full_set(a.gear or {}, tiers)
	local set = id and equip.BY_ID[id]
	if set and set.bonus then
		local b = set.bonus[(a.variant == "b" and top) and "b" or "a"]
		out[#out + 1] = b.potere
	end
	for _, n in ipairs(abilita.NODES) do
		if n.potere and (a.tree or {})[n.id] then out[#out + 1] = n.potere end
	end
	return out
end

function M.da_profilo(p, nome, squadra, sotto, torneo)
	local a = profilo.assetto_attivo(p)
	local tiers = profilo.tier(p, a)
	local v = { nome = nome, squadra = squadra, sotto = sotto, livello = p.livello, torneo = torneo,
		badge = profilo.badge(p), pezzi = {}, poteri = M.poteri(a, tiers), albero = {},
		punti = profilo.punti(p, torneo) }
	for i, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		local n = set and (p.maestria[set .. "_" .. s.id] or 0) or 0
		v.pezzi[i] = { slot = s.id, set = set, livello = set and equip.livello(n) or 0, tier = tiers[s.id] or 1 }
	end
	for i, r in ipairs(abilita.BRANCHES) do v.albero[i] = abilita.spent(a.tree or {}, r.id) end
	v.stats = copia_stats(assetto.stats(game.base_stats(), a, tiers))
	return v
end

function M.semplice(nome, squadra, sotto, livello, badge)
	local v = { nome = nome, squadra = squadra, sotto = sotto, livello = livello, badge = badge or {},
		pezzi = pezzi_vuoti(), poteri = {}, albero = {}, punti = 0 }
	for i in ipairs(abilita.BRANCHES) do v.albero[i] = 0 end
	v.stats = copia_stats(game.base_stats())
	return v
end

-- Le statistiche vere della partita (online l'equipaggiamento non conta ancora:
-- il cartellino dice quello che vale davvero)
function M.con_stats(v, st)
	if st then v.stats = copia_stats(st) end
	return v
end

local function arrotonda(x) return math.floor(x + 0.5) end

-- Le quattro barre: nome, valore scritto e scarto dalla base (-1..1 = ±SCALA)
function M.righe(v, base)
	base = base or game.base_stats()
	local out = {}
	for i, b in ipairs(M.BARRE) do
		local k = b[1]
		local val, ref = v.stats[k] or base[k], base[k]
		local frac = ref ~= 0 and (val / ref - 1) or 0
		local testo
		if b[3] == "punti" then
			testo = tostring(arrotonda(val))
		else
			local pc = arrotonda(frac * 100)
			testo = pc == 0 and "=" or (pc > 0 and "+" or "−") .. math.abs(pc) .. "%"
		end
		out[i] = { nome = b[2], valore = testo, scarto = math.max(-1, math.min(1, frac / M.SCALA)) }
	end
	return out
end

function M.risorse(v)
	local st = v.stats
	return { globi = st.teleports or 0, paracadute = st.parachutes or 0, aria = st.air_jumps or 0 }
end

-- Una vetrina arrivata da fuori (online): solo livello e badge, controllati
-- (i pezzi online non contano ancora: arriveranno con i profili sul server)
function M.da_rete(t, nome, squadra, sotto)
	local traguardi = require "menu.traguardi"
	local liv = type(t) == "table" and tonumber(t.liv)
	if liv then liv = math.max(1, math.min(999, math.floor(liv))) end
	local badge = {}
	for _, b in ipairs(type(t) == "table" and type(t.bdg) == "table" and t.bdg or {}) do
		local ok = traguardi.valido(b)
		if ok and #badge < traguardi.MOSTRATI then badge[#badge + 1] = ok end
	end
	return M.semplice(nome, squadra, sotto, liv, badge)
end

-- Quello che si manda al server col saluto (hello): livello e badge
function M.per_rete(p)
	local bdg = {}
	for _, b in ipairs(profilo.badge(p)) do bdg[#bdg + 1] = { id = b.id, grado = b.grado } end
	-- (senza badge niente bdg: la tabella vuota in JSON sarebbe un oggetto)
	return { liv = p.livello, bdg = #bdg > 0 and bdg or nil }
end

return M
