-- Scelta d'inizio partita (Sergio, 30 ott): due ventagli uguali per tutti, uno
-- di primarie delle casse e uno di secondarie; ognuno prende una primaria e una
-- secondaria, quella che vuole: le scelte degli altri non si vedono e i doppioni
-- vanno bene, anche fra compagni. L'attrezzo non si sceglie: il Rampino ce
-- l'hanno tutti. Lua puro e deterministico: la fa girare la stanza del server
-- (o il client sullo stesso telefono) prima di game.new, che riceve le scelte in
-- opts.players[i].pick (primaria) e .secondary. Il timer (config.DRAFT_SECONDS)
-- lo tiene chi lo usa.
--
--   local d = draft.new(seed, players, viste)  -- players come in game.new; viste: { arma = true },
--                                              -- se c'è si offrono solo quelle (la campagna: le armi già viste)
--   draft.valid(d, i, "shards")               -- il robot i può prenderla? (primaria o secondaria)
--   draft.pick(d, i, "shards")                -- sceglie (o cambia scelta) nella sua categoria
--   draft.done(d, i)                          -- il robot i ha scelto tutto?
--   players = draft.finish(d)                 -- allo scadere: chi manca prende la prima del ventaglio

local C = require "sim.config"
local rng = require "sim.rng"
local game = require "sim.game"

local D = {}

-- n armi della lista in ordine casuale (solo quelle viste, se viste c'è)
local function shuffled(r, list, n, viste)
	local pool = {}
	for _, w in ipairs(list) do
		if not viste or viste[w] then pool[#pool + 1] = w end
	end
	for i = #pool, 2, -1 do
		local j = math.floor(r:range(1, i + 1))
		pool[i], pool[j] = pool[j], pool[i]
	end
	local out = {}
	for i = 1, math.min(n, #pool) do out[i] = pool[i] end
	return out
end

function D.new(seed, players, viste)
	local r = rng.new(seed)
	return {
		offer = shuffled(r, game.CRATE_WEAPONS, C.DRAFT_OFFER, viste),
		offer2 = shuffled(r, game.DRAFT_SECONDARIES, C.DRAFT_OFFER, viste),
		players = players, picks = {}, picks2 = {},
	}
end

local function offered(offer, weapon)
	for _, w in ipairs(offer) do
		if w == weapon then return true end
	end
	return false
end

-- Il ventaglio e le scelte della categoria di weapon
local function side(d, weapon)
	if game.SECONDARY[weapon] then return d.offer2, d.picks2 end
	return d.offer, d.picks
end

function D.valid(d, i, weapon)
	return offered((side(d, weapon)), weapon)
end

function D.pick(d, i, weapon)
	if not D.valid(d, i, weapon) then return false end
	local _, picks = side(d, weapon)
	picks[i] = weapon
	return true
end

-- Un ventaglio vuoto (la campagna, senza armi viste di quel tipo) non si sceglie
function D.done(d, i)
	return (d.picks[i] ~= nil or #d.offer == 0) and (d.picks2[i] ~= nil or #d.offer2 == 0)
end

-- Conferma le scelte: chi non ha scelto prende la prima arma di ogni ventaglio.
-- Restituisce i giocatori per game.new, con pick e secondary.
function D.finish(d)
	local out = {}
	for i, p in ipairs(d.players) do
		d.picks[i] = d.picks[i] or d.offer[1]
		d.picks2[i] = d.picks2[i] or d.offer2[1]
		out[i] = { team = p.team, stats = p.stats, pick = d.picks[i], secondary = d.picks2[i] }
	end
	return out
end

return D
