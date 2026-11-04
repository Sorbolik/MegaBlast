-- Character quips: campaign bots with a personality (sim/bot.lua
-- M.CARATTERI) or a keeper speak in the strip at the top, with their face
-- (battle/vignette.lua quip), when something happens. Client only: they
-- don't touch the match, so neither the server nor the recipes.
--
--   local p = battute.nuove()                    -- one per match
--   p.chi[robot] = "codardo"                     -- who speaks: the personality or the keeper
--   local robot, testo, forte, moment = p:evento(e, current_one)  -- for every match
--     event (current_one: the robot whose turn it is): who says what, or nil;
--     forte: a quip that may cover the previous one
--   local testo = battute.di(chi, moment, n)     -- quip n of that moment
--
-- Quips cycle in order (n: how many times it already happened), no randomness.
-- Moments: turno (their turn starts), colpisce (hurts someone on their turn),
-- colpito (they get hurt), scappa (teleports), abbatte, muore.

local T = require("lang.text").quips

local M = {}

local QUIPS = T.by_character

function M.di(who, moment, n)
	local b = QUIPS[who]
	local list_of = b and b[moment]
	if not list_of then return nil end
	return list_of[n % #list_of + 1]
end

function M.nuove()
	return setmetatable({ chi = {}, n = {} }, { __index = M })
end

-- The event's moment and who says it: whoever takes it, or whoever's turn it is
local function moment(who, e, current_one)
	if e.type == "turn" then
		return e.robot, "turno"
	elseif e.type == "teleport" then
		return e.robot, "scappa"
	elseif e.type == "damage" and e.amount > 0 then
		if who[e.robot] then return e.robot, "colpito" end
		if e.robot ~= current_one then return current_one, "colpisce" end
	elseif e.type == "death" then
		if who[e.robot] then return e.robot, "muore" end
		return e.by, "abbatte"
	end
	return nil
end

local STRONG = { muore = true, abbatte = true, scappa = true }

function M.evento(p, e, current_one)
	local i, m = moment(p.chi, e, current_one)
	local who = i and p.chi[i]
	if not who then return nil end
	local k = who .. m
	local n = p.n[k] or 0
	p.n[k] = n + 1
	-- at turn start, every other one
	if m == "turno" and n % 2 == 1 then return nil end
	local s = M.di(who, m, n)
	return s and i, s, STRONG[m] == true, m
end

return M
