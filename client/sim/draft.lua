-- Scelta d'inizio partita: due ventagli uguali per tutti, uno di primarie
-- delle casse e uno di secondarie; ognuno prende una primaria e una
-- secondaria. Lua puro e deterministico: la fa girare la stanza del server
-- (o il client sullo stesso telefono) prima di game.new, che riceve le scelte
-- in opts.players[i].pick (primaria) e .secondary. Il timer
-- (config.DRAFT_SECONDS) lo tiene chi lo usa.
--
--   local d = draft.new(seed, players)       -- players come in game.new
--   draft.valid(d, i, "shards")              -- il robot i può prenderla? (primaria o secondaria)
--   draft.pick(d, i, "shards")               -- sceglie (o cambia scelta) nella sua categoria
--   draft.done(d, i)                         -- il robot i ha scelto tutte e due?
--   draft.swap(d, i, j)                      -- due compagni si scambiano le scelte (tutte e due)
--   players = draft.finish(d)                -- allo scadere: chi manca prende la prima libera

local C = require "sim.config"
local rng = require "sim.rng"
local game = require "sim.game"

local D = {}

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
	-- i ventagli: primarie delle casse e secondarie, in ordine casuale
	return {
		offer = shuffled(r, game.CRATE_WEAPONS, C.DRAFT_OFFER),
		offer2 = shuffled(r, game.DRAFT_SECONDARIES, C.DRAFT_OFFER),
		players = players, picks = {}, picks2 = {}, teams = teams_mode(players),
	}
end

-- Il ventaglio e le scelte della categoria di weapon
local function side(d, weapon)
	if game.SECONDARY[weapon] then return d.offer2, d.picks2 end
	return d.offer, d.picks
end

local function offered(offer, weapon)
	for _, w in ipairs(offer) do
		if w == weapon then return true end
	end
	return false
end

-- Nelle squadre due compagni non possono avere la stessa arma
function D.valid(d, i, weapon)
	local offer, picks = side(d, weapon)
	if not offered(offer, weapon) then return false end
	if not d.teams then return true end
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
	return true
end

function D.done(d, i)
	return d.picks[i] ~= nil and d.picks2[i] ~= nil
end

-- Lo scambio proposto al compagno, quando lui accetta: primaria e secondaria insieme
function D.swap(d, i, j)
	if d.players[i].team ~= d.players[j].team then return false end
	d.picks[i], d.picks[j] = d.picks[j], d.picks[i]
	d.picks2[i], d.picks2[j] = d.picks2[j], d.picks2[i]
	return true
end

-- La prima arma libera del ventaglio per il robot i
function D.first_free(d, i, offer)
	for _, w in ipairs(offer) do
		if D.valid(d, i, w) then return w end
	end
end

-- Conferma le scelte: chi non ha scelto prende la prima arma libera di ogni
-- ventaglio. Restituisce i giocatori per game.new, con pick e secondary.
function D.finish(d)
	local out = {}
	for i, p in ipairs(d.players) do
		if not d.picks[i] then d.picks[i] = D.first_free(d, i, d.offer) end
		if not d.picks2[i] then d.picks2[i] = D.first_free(d, i, d.offer2) end
		out[i] = { team = p.team, stats = p.stats, pick = d.picks[i], secondary = d.picks2[i] }
	end
	return out
end

return D
