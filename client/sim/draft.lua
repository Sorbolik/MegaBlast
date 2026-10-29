-- Scelta d'inizio partita: tre ventagli uguali per tutti, uno di primarie
-- delle casse, uno di secondarie e quello dell'attrezzo del turno (sempre tutti:
-- Rampino e Bastione); ognuno prende una primaria, una secondaria e un attrezzo.
-- L'attrezzo parte già scelto, quello dell'assetto (players[i].tool), se un
-- compagno non ce l'ha già. Lua puro e deterministico: la fa girare la stanza
-- del server (o il client sullo stesso telefono) prima di game.new, che riceve
-- le scelte in opts.players[i].pick (primaria), .secondary e .tool. Il timer
-- (config.DRAFT_SECONDS) lo tiene chi lo usa.
--
--   local d = draft.new(seed, players)       -- players come in game.new
--   draft.valid(d, i, "shards")              -- il robot i può prenderla? (primaria, secondaria o attrezzo)
--   draft.pick(d, i, "shards")               -- sceglie (o cambia scelta) nella sua categoria
--   draft.done(d, i)                         -- il robot i ha scelto tutto?
--   draft.swap(d, i, j)                      -- due compagni si scambiano le scelte (tutte)
--   players = draft.finish(d)                -- allo scadere: chi manca prende la prima libera

local C = require "sim.config"
local rng = require "sim.rng"
local game = require "sim.game"

local D = {}
local offered, del_compagno, libero -- più sotto

local function teams_mode(players)
	local seen = {}
	for _, p in ipairs(players) do
		if seen[p.team] then return true end
		seen[p.team] = true
	end
	return false
end

local function shuffled(r, list, n)
	local pool = {}
	for i, w in ipairs(list) do pool[i] = w end
	for i = #pool, 2, -1 do
		local j = math.floor(r:range(1, i + 1))
		pool[i], pool[j] = pool[j], pool[i]
	end
	local out = {}
	for i = 1, math.min(n, #pool) do out[i] = pool[i] end
	return out
end

function D.new(seed, players)
	local r = rng.new(seed)
	-- i ventagli: primarie delle casse e secondarie in ordine casuale, gli attrezzi tutti
	local tools = {}
	for i, t in ipairs(game.DRAFT_TOOLS) do tools[i] = t end
	local d = {
		offer = shuffled(r, game.CRATE_WEAPONS, C.DRAFT_OFFER),
		offer2 = shuffled(r, game.DRAFT_SECONDARIES, C.DRAFT_OFFER),
		offer3 = tools,
		players = players, picks = {}, picks2 = {}, picks3 = {}, teams = teams_mode(players),
		proposto = {}, -- i: l'attrezzo è solo quello proposto dall'assetto, non l'ha ancora toccato
	}
	-- l'attrezzo dell'assetto è già scelto; se lo ha già un compagno, il primo libero
	for i, p in ipairs(players) do
		local t = p.tool
		if not (t and offered(tools, t)) or (d.teams and del_compagno(d, i, t)) then t = libero(d, i) end
		d.picks3[i], d.proposto[i] = t, true
	end
	return d
end

offered = function(offer, weapon)
	for _, w in ipairs(offer) do
		if w == weapon then return true end
	end
	return false
end

-- un compagno di i ha l'attrezzo t? (solo_scelti: non conta quelli solo proposti)
del_compagno = function(d, i, t, solo_scelti)
	local team = d.players[i].team
	for j, p in ipairs(d.players) do
		if j ~= i and p.team == team and d.picks3[j] == t and not (solo_scelti and d.proposto[j]) then return true end
	end
	return false
end

-- il primo attrezzo che nessun compagno di i ha
libero = function(d, i)
	for _, t in ipairs(d.offer3) do
		if not (d.teams and del_compagno(d, i, t)) then return t end
	end
	return d.offer3[1]
end

-- Il ventaglio e le scelte della categoria di weapon
local function side(d, weapon)
	if game.SECONDARY[weapon] then return d.offer2, d.picks2 end
	if game.TOOLS[weapon] then return d.offer3, d.picks3 end
	return d.offer, d.picks
end

-- Nelle squadre due compagni non possono avere la stessa arma. L'attrezzo solo
-- proposto dall'assetto a un compagno non blocca: il compagno passa all'altro.
function D.valid(d, i, weapon)
	local offer, picks = side(d, weapon)
	if not offered(offer, weapon) then return false end
	if not d.teams then return true end
	if picks == d.picks3 then return not del_compagno(d, i, weapon, true) end
	local team = d.players[i].team
	for j, p in ipairs(d.players) do
		if j ~= i and p.team == team and picks[j] == weapon then return false end
	end
	return true
end

function D.pick(d, i, weapon)
	if not D.valid(d, i, weapon) then return false end
	local _, picks = side(d, weapon)
	picks[i] = weapon
	if picks == d.picks3 then
		d.proposto[i] = nil
		-- il compagno che lo aveva solo proposto prende il primo libero
		for j, p in ipairs(d.players) do
			if j ~= i and d.teams and p.team == d.players[i].team and d.picks3[j] == weapon then d.picks3[j] = libero(d, j) end
		end
	end
	return true
end

function D.done(d, i)
	return d.picks[i] ~= nil and d.picks2[i] ~= nil and d.picks3[i] ~= nil
end

-- Lo scambio proposto al compagno, quando lui accetta: tutte le scelte insieme
function D.swap(d, i, j)
	if d.players[i].team ~= d.players[j].team then return false end
	d.picks[i], d.picks[j] = d.picks[j], d.picks[i]
	d.picks2[i], d.picks2[j] = d.picks2[j], d.picks2[i]
	d.picks3[i], d.picks3[j] = d.picks3[j], d.picks3[i]
	d.proposto[i], d.proposto[j] = d.proposto[j], d.proposto[i]
	return true
end

-- La prima arma libera del ventaglio per il robot i
function D.first_free(d, i, offer)
	for _, w in ipairs(offer) do
		if D.valid(d, i, w) then return w end
	end
end

-- Conferma le scelte: chi non ha scelto prende la prima arma libera di ogni
-- ventaglio. Restituisce i giocatori per game.new, con pick, secondary e tool.
function D.finish(d)
	local out = {}
	for i, p in ipairs(d.players) do
		if not d.picks[i] then d.picks[i] = D.first_free(d, i, d.offer) end
		if not d.picks2[i] then d.picks2[i] = D.first_free(d, i, d.offer2) end
		if not d.picks3[i] then d.picks3[i] = D.first_free(d, i, d.offer3) end
		out[i] = { team = p.team, stats = p.stats, pick = d.picks[i], secondary = d.picks2[i], tool = d.picks3[i] }
	end
	return out
end

return D
