-- Rules as data (Sergio, 31 October 2026): what an event can change about a
-- match, written as values and never as code. The whitelist is here: the
-- server rejects an event with an unknown key or a value out of bounds, and
-- client and server pass the same rules to game.new and to the weapon draft,
-- so the match is identical on both sides.
-- Proposal: https://claude.ai/artifact/WhmGJpMT4hfsD2MdPfHpUC
--
--   local rules = require "sim.rules"
--   local ok, err = rules.validate(r)       -- r = { casse = 2, armi = { "punch", "mallet" }, ... }
--   rules.validate(r, true)                 -- on a normal queue: only CODA_NORMALE (tetto)
--   rules.opzioni(r, opts)                  -- adds to the opts of game.new
--   local offered = rules.armi(r)           -- weapons offered in the draft (sim/draft.lua), or nil
--
-- A new rule is added here (with its bounds) and in opzioni; if it needs
-- something game.new cannot do yet, teach it to the simulation first.

local C = require "sim.config"
local game = require "sim.game"
local equip = require "sim.gear"

local M = {}

local PRIMARIES, SECONDARIES = {}, {}
for _, w in ipairs(game.CRATE_WEAPONS) do PRIMARIES[w] = true end
for _, w in ipairs(game.DRAFT_SECONDARIES) do SECONDARIES[w] = true end

-- an integer between a and b
local function integer(a, b)
	return function(v)
		return type(v) == "number" and v == math.floor(v) and v >= a and v <= b, "da " .. a .. " a " .. b
	end
end

-- The whitelist: key -> check of the value (true, or false and why)
M.WHITELIST = {
	-- turns between one crate and the next (the first always drops on the first turn)
	casse = integer(1, 10),
	-- false: no healing circles
	cure = function(v) return type(v) == "boolean", "vero o falso" end,
	-- "fisso": skill tree and gear don't count, everyone has the base stats
	livello = function(v) return v == "fisso", "solo \"fisso\"" end,
	-- the weapons of the start-of-match draft: at least one primary and one secondary
	-- (Lanciarune and Lama always stay)
	armi = function(v)
		if type(v) ~= "table" or #v == 0 then return false, "una lista di armi" end
		local p, s = false, false
		for _, w in ipairs(v) do
			if PRIMARIES[w] then p = true elseif SECONDARIES[w] then s = true
			else return false, "arma sconosciuta: " .. tostring(w) end
		end
		return p and s, "almeno una primaria e una secondaria"
	end,
	-- the cap on piece levels (Torneo, Sergio 31 October: "fissati a un
	-- massimo, magari 12 o 15 su 20"): it is allowed on normal queues too because
	-- it doesn't change the match, only who can join; it takes effect when
	-- loadouts arrive online (until then the game only shows it)
	tetto = integer(1, equip.LIVELLO_MAX - 1),
	-- match points different from config.SCORE, only the fields that change
	punti = function(v)
		if type(v) ~= "table" then return false, "una tabella di punti" end
		for k, n in pairs(v) do
			if C.SCORE[k] == nil then return false, "punto sconosciuto: " .. tostring(k) end
			if type(n) ~= "number" or n < -1000 or n > 1000 then return false, k .. " da -1000 a 1000" end
		end
		return true
	end,
}

-- The rules that can also go on a normal queue (Torneo, Sfida, XP): they
-- don't change the match, so they don't change it for people playing normally.
M.CODA_NORMALE = { tetto = true }

-- normal: the event is on a normal queue, so only the rules in CODA_NORMALE
function M.validate(r, normal)
	if type(r) ~= "table" then return nil, "le regole sono una tabella" end
	for k, v in pairs(r) do
		local checker = M.WHITELIST[k]
		if not checker then return nil, "regola sconosciuta: " .. tostring(k) end
		if normal and not M.CODA_NORMALE[k] then
			return nil, k .. ": cambia la partita, solo per i modificatori (tipo mod, con la coda loro)"
		end
		local ok, why = checker(v)
		if not ok then return nil, k .. ": " .. why end
	end
	return true
end

function M.options(r, opts)
	if not r then return opts end
	if r.casse then opts.crate_every = r.casse end
	if r.cure == false then opts.heals = false end
	if r.livello == "fisso" then opts.normalize = true end
	if r.punti then opts.score = r.punti end
	return opts
end

function M.weapons(r)
	if not (r and r.armi) then return nil end
	local seen_weapons = {}
	for _, w in ipairs(r.armi) do seen_weapons[w] = true end
	return seen_weapons
end

return M
