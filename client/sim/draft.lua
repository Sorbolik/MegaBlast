-- Start-of-match weapon pick (Sergio, 30 Oct): two fans, the same for
-- everyone, one of crate primaries and one of secondaries; each player takes
-- one primary and one secondary, whichever they want: the others' picks are
-- hidden and duplicates are fine, even between teammates. The tool is not
-- picked: everyone has the Rampino. Pure, deterministic Lua: the server room
-- runs it (or the client on the same phone) before game.new, which receives
-- the picks in opts.players[i].pick (primary) and .secondary. The timer
-- (config.DRAFT_SECONDS) is kept by whoever uses it.
--
--   local d = draft.new(seed, players, viste)  -- players as in game.new; viste: { weapon = true },
--                                              -- if given only those are offered (the campaign: weapons already seen)
--   draft.valid(d, i, "shards")               -- can robot i take it? (primary or secondary)
--   draft.pick(d, i, "shards")                -- picks (or changes pick) in its category
--   draft.done(d, i)                          -- has robot i picked everything?
--   players = draft.finish(d)                 -- at timeout: whoever is missing gets the first of the fan

local C = require "sim.config"
local rng = require "sim.rng"
local game = require "sim.game"

local D = {}

-- n weapons of the list in random order (only the seen ones, if viste is given)
local function shuffled(r, list, n, seen_weapons)
	local pool = {}
	for _, w in ipairs(list) do
		if not seen_weapons or seen_weapons[w] then pool[#pool + 1] = w end
	end
	for i = #pool, 2, -1 do
		local j = math.floor(r:range(1, i + 1))
		pool[i], pool[j] = pool[j], pool[i]
	end
	local out = {}
	for i = 1, math.min(n, #pool) do out[i] = pool[i] end
	return out
end

function D.new(seed, players, seen_weapons)
	local r = rng.new(seed)
	return {
		offer = shuffled(r, game.CRATE_WEAPONS, C.DRAFT_OFFER, seen_weapons),
		offer2 = shuffled(r, game.DRAFT_SECONDARIES, C.DRAFT_OFFER, seen_weapons),
		players = players, picks = {}, picks2 = {},
	}
end

local function offered(offer, weapon)
	for _, w in ipairs(offer) do
		if w == weapon then return true end
	end
	return false
end

-- The fan and the picks of weapon's category
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

-- An empty fan (the campaign, with no seen weapons of that kind) is not picked
function D.done(d, i)
	return (d.picks[i] ~= nil or #d.offer == 0) and (d.picks2[i] ~= nil or #d.offer2 == 0)
end

-- Confirms the picks: whoever has not picked gets the first weapon of each fan.
-- Returns the players for game.new, with pick and secondary.
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
