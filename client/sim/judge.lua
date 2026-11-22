-- The server replays a match played on the phone before paying it (guest
-- profiles plan, step 5, Sergio's choice of 19 Nov): campaign missions and
-- lessons, training against the bots, the same phone. The phone sends the
-- recipe (sim/replay.lua) with what it did (sim/progress.lua, partita and
-- missione); here the match is built again from the server's profile (the
-- player's pieces and Sigilli, the bots made from them, the mission as
-- written in sim/levels.lua: nothing the phone says about strength counts),
-- replayed with the bots thinking again, its fingerprints checked, and the
-- results counted again (sim/tally.lua, sim/awards.lua, sim/missions.lua).
--
--   local a2, why = judge.action(p, a)   -- a: the phone's action (partita, missione, statistiche: a
--                                        -- campaign battle lost) with its recipe (a.ricetta, text);
--                                        -- a2: the same action with the server's numbers, or nil and why
--
-- Pure Lua: the server runs it in its own LuaJIT (server/worker.lua).

local game = require "sim.game"
local replay = require "sim.replay"
local loadout = require "sim.loadout"
local missions = require "sim.missions"
local tally = require "sim.tally"
local awards = require "sim.awards"
local profile = require "sim.profile"

local M = {}

-- the most ticks a replayed match can last (an hour)
M.MAX_TICKS = 60 * 60 * 60
-- the recipes already paid that are remembered (the same one twice pays once)
M.PAID = 200

-- the robot of whoever plays on the phone (the first, locally and in the missions)
local ME = 1

local function plain(v, kind)
	return type(v) == kind and v or nil
end

-- The training's or the same phone's players, built again: teams, bots'
-- grades and characters, the draft's picks; the player wears the server's
-- profile, the bots what comes out of it with the seed (sim/loadout.lua dress_bots)
local function local_players(r, p)
	local src = type(r.opzioni) == "table" and type(r.opzioni.players) == "table" and r.opzioni.players or {}
	if #src < 2 or #src > game.MAX_PLAYERS then return nil end
	local training = type(src[ME]) == "table" and src[ME].eq ~= nil
	local mine = profile.equip(p)
	local players = {}
	for i, q in ipairs(src) do
		if type(q) ~= "table" or type(q.team) ~= "number" then return nil end
		local out = { team = q.team, pick = plain(q.pick, "string"), secondary = plain(q.secondary, "string"),
			tool = plain(q.tool, "string") }
		if i ~= ME and q.bot ~= nil then
			if type(q.bot) ~= "number" and q.bot ~= true then return nil end
			out.bot, out.carattere = q.bot, plain(q.carattere, "string")
		end
		if training then
			out.eq = i == ME and mine or nil
		elseif i == ME then
			out.stats = profile.stats(p, profile.active_loadout(p), game.base_stats())
		end
		players[i] = out
	end
	if training then loadout.dress_bots(players, r.seme) end
	local opts = { players = players, random_spawns = r.opzioni.random_spawns == true or nil,
		intro = plain(r.opzioni.intro, "number") }
	return opts, training
end

-- The mission's match, as the phone builds it (game.gui_script start_mission)
local function mission_match(r, p)
	local m = r.missione
	if type(m) ~= "table" or type(m.id) ~= "string" then return nil end
	local ok, mr = pcall(missions.new, m.id)
	if not ok then return nil end
	local picks
	if type(m.picks) == "table" then
		picks = {}
		for i, pk in pairs(m.picks) do
			if type(i) == "number" and type(pk) == "table" then
				picks[i] = { pick = plain(pk.pick, "string"), secondary = plain(pk.secondary, "string") }
			end
		end
	end
	local own = profile.stats(p, profile.active_loadout(p), game.base_stats())
	local _, map, opts = missions.match(mr, r.seme, picks, m.help == true, own)
	return mr, map, opts
end

-- Replays r (its options already the server's) and counts it. Returns the
-- game, the tally and the mission state, or nil and why
local function play(r, mr)
	local g, bots = replay.match(r)
	if mr then missions.prepare(mr, g, bots) end
	local c = tally.new(g, ME)
	local l = replay.reader(r)
	l.rethink = true
	local waits, n = r.impronte, 1
	local touches, k = type(r.tocchi) == "table" and r.tocchi or {}, 1
	local last = waits[#waits]
	local stop = math.min(M.MAX_TICKS, plain(r.fine, "number") or (last and last.t) or 0)
	while g.phase ~= "over" and g.tick < stop do
		-- what the player touched in a mission, before this step (missions.touch)
		while touches[k] and touches[k].t <= g.tick do
			if mr then missions.touch(mr, touches[k].w or nil) end
			k = k + 1
		end
		local input = replay.read_step(l, g, bots)
		if input.fire and g.current == ME then tally.shot(c, g, input.fire.weapon) end
		g:step(input)
		local w = waits[n]
		if w and w.t == g.tick then
			if w.h ~= g:fingerprint() then return nil, "diversa al tick " .. g.tick end
			n = n + 1
		end
		for _, e in ipairs(g:pop_events()) do
			tally.event(c, g, e)
			if mr then missions.event(mr, g, e, bots) end
		end
		tally.tick(c, g)
		if mr then missions.tick(mr, g) end
	end
	if waits[n] then return nil, "impronta mancante al tick " .. waits[n].t end
	return g, c
end

-- the stats of the match for the profile (sim/tally.lua finish)
local function stats(c, g, res, group)
	local t = tally.finish(c, g, res, { gruppo = group })
	return { gruppo = group, valori = t.valori, armi = t.armi, won = t.won }
end

-- a key of the recipe: the same match sent twice is paid once
local function key_of(r)
	local last = r.impronte[#r.impronte]
	return tostring(r.seme) .. ":" .. tostring(last and last.t) .. ":" .. tostring(last and last.h)
end

local function paid(p, key)
	p.pagate = type(p.pagate) == "table" and p.pagate or {}
	for _, k in ipairs(p.pagate) do
		if k == key then return true end
	end
	return false
end

function M.action(p, a)
	if type(a.ricetta) ~= "string" then return nil, "senza ricetta" end
	local r = replay.decode(a.ricetta)
	if type(r) ~= "table" or type(r.impronte) ~= "table" or #r.impronte == 0 or type(r.seme) ~= "number" then
		return nil, "ricetta illeggibile"
	end
	local key = key_of(r)
	if paid(p, key) then return nil, "già pagata" end
	local out
	if a.k == "missione" or a.k == "statistiche" then
		local mr, map, opts = mission_match(r, p)
		if not mr then return nil, "missione sconosciuta" end
		r.mappa, r.opzioni = map, opts
		local g, c = play(r, mr)
		if not g then return nil, c end
		if a.k == "statistiche" then
			-- a battle lost: only its stats
			if mr.esito ~= "fallita" or g.phase ~= "over" then return nil, "battaglia non finita" end
			out = { k = "statistiche", conta = stats(c, g, g:results(), "campagna") }
		else
			if mr.esito ~= "fatta" then return nil, "missione non fatta" end
			out = { k = "missione", id = mr.l.id, stars = missions.stars(mr), made = missions.points(mr) }
			if g.phase == "over" then out.conta = stats(c, g, g:results(), "campagna") end
		end
	elseif a.k == "partita" then
		local opts = local_players(r, p)
		if not opts then return nil, "giocatori sbagliati" end
		r.opzioni = opts
		local g, c = play(r, nil)
		if not g then return nil, c end
		if g.phase ~= "over" then return nil, "partita non finita" end
		local res = g:results()
		local mine
		for _, v in ipairs(res.ranking) do
			if v.robot == ME then mine = v end
		end
		if not mine then return nil, "giocatore mancante" end
		local won = nil
		if res.winner then won = res.winner == mine.team end
		out = { k = "partita", r = { points = mine.points, won = won, second = res.mode == "ffa" and mine.place == 2,
			mvp = awards.mvp(res.ranking) == ME, awards = awards.assign(res.ranking)[ME] },
			conta = stats(c, g, res, res.mode) }
	else
		return nil, "azione senza partita"
	end
	table.insert(p.pagate, 1, key)
	while #p.pagate > M.PAID do table.remove(p.pagate) end
	return out
end

return M
