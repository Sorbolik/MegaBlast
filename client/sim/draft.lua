-- Scelta d'inizio partita: un ventaglio di armi uguale per tutti, ognuno ne
-- prende una. Lua puro e deterministico: la fa girare la stanza del server
-- (o il client sullo stesso telefono) prima di game.new, che riceve le scelte
-- in opts.players[i].pick. Il timer (config.DRAFT_SECONDS) lo tiene chi lo usa.
--
--   local d = draft.new(seed, players)       -- players come in game.new
--   draft.valid(d, i, "shards")              -- il robot i può prenderla?
--   draft.pick(d, i, "shards")               -- sceglie (o cambia scelta)
--   draft.swap(d, i, j)                      -- due compagni si scambiano le scelte
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

function D.new(seed, players)
	local r = rng.new(seed)
	-- il ventaglio: DRAFT_OFFER armi delle casse in ordine casuale
	local pool = {}
	for i, w in ipairs(game.CRATE_WEAPONS) do pool[i] = w end
	for i = #pool, 2, -1 do
		local j = math.floor(r:range(1, i + 1))
		pool[i], pool[j] = pool[j], pool[i]
	end
	local offer = {}
	for i = 1, math.min(C.DRAFT_OFFER, #pool) do offer[i] = pool[i] end
	return { offer = offer, players = players, picks = {}, teams = teams_mode(players) }
end

local function offered(d, weapon)
	for _, w in ipairs(d.offer) do
		if w == weapon then return true end
	end
	return false
end

-- Nelle squadre due compagni non possono avere la stessa arma
function D.valid(d, i, weapon)
	if not offered(d, weapon) then return false end
	if not d.teams then return true end
	local team = d.players[i].team
	for j, p in ipairs(d.players) do
		if j ~= i and p.team == team and d.picks[j] == weapon then return false end
	end
	return true
end

function D.pick(d, i, weapon)
	if not D.valid(d, i, weapon) then return false end
	d.picks[i] = weapon
	return true
end

-- Lo scambio proposto al compagno, quando lui accetta
function D.swap(d, i, j)
	if d.players[i].team ~= d.players[j].team then return false end
	d.picks[i], d.picks[j] = d.picks[j], d.picks[i]
	return true
end

-- Conferma le scelte: chi non ha scelto prende la prima arma libera del
-- ventaglio. Restituisce i giocatori per game.new, con pick.
function D.finish(d)
	local out = {}
	for i, p in ipairs(d.players) do
		if not d.picks[i] then
			for _, w in ipairs(d.offer) do
				if D.valid(d, i, w) then
					d.picks[i] = w
					break
				end
			end
		end
		out[i] = { team = p.team, stats = p.stats, pick = d.picks[i] }
	end
	return out
end

return D
