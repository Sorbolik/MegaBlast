-- The server replays the matches played on the phone before paying them
-- (sim/judge.lua): a training match and a campaign battle are played here as
-- the phone plays them (the player's keys from a bot outside the recipe),
-- then judged; a tampered recipe, someone stronger than their profile and a
-- recipe sent twice are not paid. From the root:
--   luajit tests/judge_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local replay = require "sim.replay"
local bot = require "sim.bot"
local loadout = require "sim.loadout"
local missions = require "sim.missions"
local tally = require "sim.tally"
local profile = require "sim.profile"
local judge = require "sim.judge"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

-- Plays r to the end like game.gui_script: replay.input, the tally of player
-- 1, the mission's events and ticks (mr), the touches of the controls
local function play(r, mr, ticks)
	local g, bots = replay.match(r)
	if mr then missions.prepare(mr, g, bots) end
	local me = bot.new(1, 10, r.seme)
	local c = tally.new(g, 1)
	while g.phase ~= "over" and g.tick < ticks and not (mr and mr.esito) do
		local keys
		if g.current == 1 and not bots[1] then
			keys = bot.input(me, g)
			if mr and keys.fire then
				missions.touch(mr, keys.fire.weapon)
				replay.touch(r, g, keys.fire.weapon)
			end
		end
		local input = replay.input(r, g, bots, keys)
		if input.fire and g.current == 1 then tally.shot(c, g, input.fire.weapon) end
		g:step(input)
		replay.after(r, g)
		for _, e in ipairs(g:pop_events()) do
			tally.event(c, g, e)
			if mr then missions.event(mr, g, e, bots) end
		end
		tally.tick(c, g)
		if mr then missions.tick(mr, g) end
	end
	replay.close(r, g)
	return g, c
end

local p = profile.new()

-- Training: the player wears the profile, the bot what comes out of it
do
	local seed = 4242
	local mine = profile.equip(p)
	local r = replay.new(seed, nil, { players = { { team = 1, eq = mine }, { team = 2, bot = 3, eq = loadout.rival(mine, seed, 2) } } })
	r.bot_keys = true
	r.durata = 120 * 60
	local g, c = play(r, nil, 60 * 60 * 5)
	check(g.phase == "over" and c.colpi > 0, "training: the match ends, the player shot " .. c.colpi .. " times")
	local text = replay.encode(r)
	local a = judge.action(p, { k = "partita", ricetta = text })
	local mine_points
	for _, v in ipairs(g:results().ranking) do
		if v.robot == 1 then mine_points = v.points end
	end
	check(a and a.k == "partita" and a.r.points == mine_points and a.conta.valori.colpi == c.colpi,
		"training: replayed on the server, the same points and stats")
	local _, why = judge.action(p, { k = "partita", ricetta = text })
	check(why == "già pagata", "the same recipe twice is paid once")

	-- the end written by hand (better points than the match gave): what the
	-- server sees replaying it isn't that
	local t = replay.decode(text)
	t.impronte[#t.impronte].h = t.impronte[#t.impronte].h + 1
	local bad, why2 = judge.action(profile.new(), { k = "partita", ricetta = replay.encode(t) })
	check(not bad and why2 and why2:find("^diversa"), "a recipe that doesn't come back: not paid (" .. tostring(why2) .. ")")

	-- stronger than the profile: pieces at 30 the server's profile doesn't have
	local strong = profile.new()
	strong.posseduti.corvo_mask, strong.pezzi.corvo_mask = true, 30
	strong.loadouts[1].gear.mask = "corvo"
	local eq = profile.equip(strong)
	local r2 = replay.new(seed + 1, nil, { players = { { team = 1, eq = eq }, { team = 2, bot = 3, eq = loadout.rival(eq, seed + 1, 2) } } })
	r2.bot_keys, r2.durata = true, 20 * 60
	play(r2, nil, 60 * 60 * 5)
	local fake, why3 = judge.action(profile.new(), { k = "partita", ricetta = replay.encode(r2) })
	check(not fake and why3 and why3:find("^diversa"), "pieces the server's profile doesn't have: not paid")
	check(judge.action(strong, { k = "partita", ricetta = replay.encode(r2) }), "with them on the server's profile: paid")
end

-- A campaign battle (the Forgia's first): won it is a missione with its
-- stars, lost its stats only
do
	local id = "primo_sangue"
	local mr = missions.new(id)
	local seed, map, opts = missions.match(mr, 777, nil, false, profile.stats(p, profile.active_loadout(p), game.base_stats()))
	local r = replay.new(seed, map, opts)
	r.bot_keys = true
	r.missione = { id = id }
	local g = play(r, mr, 60 * 60 * 10)
	local kind = mr.esito == "fatta" and "missione" or "statistiche"
	print("     (" .. id .. ": " .. tostring(mr.esito) .. ", " .. g.phase .. " at tick " .. g.tick .. ")")
	local a, why = judge.action(p, { k = kind, ricetta = replay.encode(r) })
	if kind == "missione" then
		local st = missions.stars(mr)
		check(a and a.k == "missione" and a.stars[1] == st[1] and a.stars[2] == st[2] and a.stars[3] == st[3],
			"campaign: the mission done, the same stars on the server (" .. tostring(why) .. ")")
	else
		check(g.phase ~= "over" or (a and a.k == "statistiche"), "campaign: the battle lost, its stats (" .. tostring(why) .. ")")
	end
	local _, why2 = judge.action(profile.new(), { k = "missione", ricetta = replay.encode((function()
		local t = replay.decode(replay.encode(r))
		t.missione.id = "inventata"
		return t
	end)()) })
	check(why2 == "missione sconosciuta", "a mission that doesn't exist: not paid")
end

print(failures == 0 and "OK" or (failures .. " FAIL"))
os.exit(failures == 0 and 0 or 1)
