-- Counts the stats of whoever plays on this phone during the match, and at
-- the end of the match makes the summary for the profile (profilo.registra):
-- the stat numbers, the damage per weapon, and the match for the PARTITE tab
-- (how it went lap by lap, the moments to rewatch, who was there). Pure Lua:
-- it watches the simulation's events and the state, the same locally and online.
--
--   local c = conta.nuova(g, me, nomi)       -- me: the robot of whoever plays here
--   conta.sparo(c, g, arma)                  -- when me attacks
--   conta.evento(c, g, e)                    -- for every sim event
--   conta.tick(c, g)                         -- after every step (the laps)
--   local r = conta.fine(c, g, results, info) -- info: gruppo, mappa, quando, giocatori

local T = require("lang.text").tally

local M = {}

-- from how many pixels a shot becomes a moment of the match
M.LONG = 900
-- the moments that are kept
M.MOMENTS = 8

local function team_points(g)
	local t = {}
	for _, rb in ipairs(g.robots) do t[rb.team] = (t[rb.team] or 0) + rb.points end
	return t
end

-- my team's points minus those of the best of the others
local function lead_text(c, g)
	local t = team_points(g)
	local my_own, another = t[c.team] or 0, nil
	for team, v in pairs(t) do
		if team ~= c.team and (not another or v > another) then another = v end
	end
	return math.floor(my_own - (another or 0) + 0.5), math.floor(my_own + 0.5), math.floor((another or 0) + 0.5)
end

function M.nuova(g, me, name_list)
	local c = { me = me, team = g.robots[me].team, nomi = name_list or {}, armi = {}, moments = {},
		fune = { 0 }, giro = g.round or 1,
		colpi = 0, a_segno = 0, globi = 0, colpo_lungo = 0 }
	return c
end

local function lap(c, g)
	return g.final_round and T.final or T.round:format(g.round or 1)
end

local function moment(c, g, txt)
	if #c.moments >= M.MOMENTS then return end
	c.moments[#c.moments + 1] = { t = g.tick, giro = lap(c, g), testo = txt }
end

-- The robot me attacks with arma (also the swap for an orb, which doesn't count)
function M.sparo(c, g, weapon_name)
	if weapon_name == "swap" or weapon_name == "teleport" then return end
	local rb = g.robots[c.me]
	c.arma = weapon_name
	c.colpi = c.colpi + 1
	c.colpo = { x = rb.x, y = rb.y, preso = false }
end

local function enemy(c, g, i)
	local rb = g.robots[i]
	return rb and rb.team ~= c.team
end

function M.evento(c, g, e)
	local t = e.type
	if t == "damage" and e.by == c.me and enemy(c, g, e.robot) and c.colpo then
		-- real: the health really taken away (like the standings' damage)
		c.armi[c.arma] = (c.armi[c.arma] or 0) + (e.real or e.amount or 0)
		if not c.colpo.preso then
			c.colpo.preso = true
			c.a_segno = c.a_segno + 1
			local o = g.robots[e.robot]
			local d = math.floor(math.sqrt((o.x - c.colpo.x) ^ 2 + (o.y - c.colpo.y) ^ 2) + 0.5)
			if d > c.colpo_lungo then c.colpo_lungo = d end
			if d >= M.LONG then
				moment(c, g, T.long_shot:format(d, c.nomi[e.robot] or "?"))
			end
		end
	elseif t == "death" then
		if e.by == c.me and enemy(c, g, e.robot) then
			moment(c, g, (e.env and T.you_drop or T.you_kill):format(c.nomi[e.robot] or "?"))
		elseif e.robot == c.me and e.by and enemy(c, g, e.by) then
			moment(c, g, (e.env and T.drops_you or T.kills_you):format(c.nomi[e.by] or "?"))
		end
	elseif (t == "teleports" or t == "swap") and e.robot == c.me then
		c.globi = c.globi + (t == "swap" and 1 or (e.amount or 0))
	elseif t == "final_round" then
		moment(c, g, T.double_points)
	elseif t == "turn" then
		c.colpo = nil
	end
end

-- After every step: at every new lap the lead on the rope
function M.tick(c, g)
	local r = g.round or 1
	if r ~= c.giro then
		c.giro = r
		c.fune[#c.fune + 1] = (lead_text(c, g))
	end
end

-- The summary for profilo.registra. info (its keys stay Italian for now: the
-- tools and the bot read them too): gruppo (2v2, 1v1, torneo,
-- campagna...), mappa (the name), quando (os.time()), giocatori ({ nome,
-- squadra, vetrina } per robot)
function M.fine(c, g, results, info)
	local my_team
	for _, v in ipairs(results.ranking) do
		if v.robot == c.me then my_team = v end
	end
	my_team = my_team or {}
	local diff, my_own, another = lead_text(c, g)
	c.fune[#c.fune + 1] = diff
	local won = nil
	if results.winner then won = results.winner == c.team end
	local values = {
		colpi = c.colpi, a_segno = c.a_segno, globi = c.globi, colpo_lungo = c.colpo_lungo,
		danno = my_team.damage or 0, abbattuti = my_team.kills or 0, nel_vuoto = my_team.env_kills or 0,
		cadute = my_team.falls or 0, morti = my_team.deaths or 0, casse = my_team.crates or 0,
		teletrasporti = my_team.teleports or 0,
	}
	local armi = {}
	for w, n in pairs(c.armi) do armi[w] = math.floor(n + 0.5) end
	return {
		gruppo = info.gruppo, valori = values, armi = armi, won = won,
		partita = {
			quando = info.quando, gruppo = info.gruppo, modo = results.mode, mappa = info.mappa,
			esito = won == true and "V" or won == false and "S" or "P",
			punti = { my_own, another }, fune = c.fune, moments = c.moments,
			giocatori = info.giocatori, me = c.me,
		},
	}
end

return M
