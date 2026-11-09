-- Tests of the bot (sim/bot.lua) and of the recipes (sim/replay.lua). From the root:
--   luajit tests/bot_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local config = require "sim.config"
local draft = require "sim.draft"
local bot = require "sim.bot"
local replay = require "sim.replay"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

-- A whole match between bots, with the recipe
local function match(seed_n, modo, livello, map_id)
	local players = {}
	for i, p in ipairs(config.MODES[modo]) do players[i] = { team = p.team, bot = livello } end
	local r = replay.nuova(seed_n, map_id, { players = players })
	local g, bots = replay.partita(r)
	local evs = {}
	while g.phase ~= "over" do
		g:step(replay.input(r, g, bots))
		replay.dopo(r, g)
		for _, e in ipairs(g:pop_events()) do evs[e.type] = (evs[e.type] or 0) + 1 end
	end
	return g, r, evs
end

-- The bots play: they attack every turn and do damage
local g, r, ev = match(11, "1v1", "difficile", "pavimento")
check(g.phase == "over", "1v1: the match between bots ends")
local attacks = (ev.fire or 0) + (ev.grenade or 0) + (ev.shards or 0) + (ev.sniper or 0) + (ev.swing or 0)
	+ (ev.eagle or 0) + (ev.mallet or 0) + (ev.lunge or 0) + (ev.punch or 0)
check(attacks >= ev.turn, "1v1: at least one attack per turn (" .. attacks .. " in " .. ev.turn .. " turns)")
check(g.robots[1].damage + g.robots[2].damage > 100, "1v1: the bots damage each other")
for _, rb in ipairs(g.robots) do
	check(rb.attack_turns > 0 and rb.attack_ticks / rb.attack_turns < 15 * 60,
		"robot " .. rb.id .. ": attacca in fretta (guadagna teletrasporti)")
end

-- The recipe replays the same match: all the fingerprints match
local ok, tick = replay.verifica(r)
check(ok, "recipe: the replayed match is identical" .. (ok and "" or " (diverges at tick " .. tostring(tick) .. ")"))
-- a tampered recipe doesn't hold
r.seme = r.seme + 1
local ok2 = replay.verifica(r, 1200)
check(not ok2, "recipe: with a different seed the fingerprints don't match")

-- 2 vs 2 and free-for-all, on the other map
for _, modo in ipairs({ "2v2", "ffa" }) do
	local g2 = match(5, modo, "normale", "fossa")
	local harm = 0
	for _, rb in ipairs(g2.robots) do harm = harm + rb.damage end
	check(g2.phase == "over" and harm > 50, modo .. ": the match between bots ends with some damage")
end

-- Different weights for a bot (players[i].pesi): they are in the recipe, which replays the same match
do
	local function prints(weights)
		local players = { { team = 1, bot = "normale", pesi = weights }, { team = 2, bot = "normale" } }
		local r5 = replay.nuova(6, "pavimento", { players = players })
		local g5, bots = replay.partita(r5)
		while g5.tick < 2400 do
			g5:step(replay.input(r5, g5, bots))
			replay.dopo(r5, g5)
		end
		return r5, g5:impronta()
	end
	local _, h0 = prints(nil)
	local r5, h1 = prints({ globo_riparo = 1000, strada = 0.1 })
	check(h0 ~= h1, "weights: a bot with other weights plays another match")
	check(replay.verifica(r5), "weights: the recipe with the weights replays the same match")

	-- a random neural net instead of the weights: it plays, and the recipe replays the same
	local net = require "sim.rete"
	local layers = { bot.CARATTERISTICHE, 6, 1 }
	local w, x = {}, 7
	for i = 1, net.quanti(layers) do
		x = (x * 1103515245 + 12345) % 2147483648
		w[i] = x / 2147483648 * 2 - 1
	end
	local r6, h2 = prints({ rete = { strati = layers, w = w } })
	check(h2 ~= h0, "net: a bot with the net plays another match")
	check(replay.verifica(r6), "net: the recipe with the net replays the same match")
end

-- The tutorial bot and the turn plan set from outside (guided match)
do
	-- plays robot 2's turn (bot) to the end; returns the turn's events
	local function bot_turn(livello, plan, seed_n)
		local g = game.new(seed_n or 3, "pavimento", { players = { { team = 1 }, { team = 2 } } })
		local b = bot.new(2, livello, seed_n or 3)
		while g.current ~= 2 do g:step({ fire = g.phase == "aim" and { weapon = "missile", angle = 1.4, power = 0.2 } or nil }) end
		g:pop_events()
		b.piano = plan
		local ev, start = {}, g.tick
		local turn_now = g.turn_no
		while g.turn_no == turn_now and g.tick - start < 40 * 60 do
			g:step(bot.input(b, g))
			for _, e in ipairs(g:pop_events()) do ev[#ev + 1] = { e = e, t = g.tick - start } end
		end
		return ev, g
	end
	local ATTACK_EVENTS = { fire = true, grenade = true, shards = true, swing = true, sniper = true, eagle = true,
		mallet = true, lunge = true, punch = true }
	-- tutorial: the first attack hits nobody (the damage before the second)
	local harms, n = 0, 0
	for _, x in ipairs(bot_turn("tutorial")) do
		if ATTACK_EVENTS[x.e.type] then n = n + 1 end
		if n == 1 and x.e.type == "damage" and x.e.robot == 1 then harms = harms + x.e.amount end
	end
	check(n >= 1 and harms == 0, "tutorial: the bot's first attack misses on purpose")
	-- attacca_entro 4 and then teleport
	local at_tick, orb = nil, false
	for _, x in ipairs(bot_turn("normale", { attacca_entro = 4, poi = "teletrasporto" })) do
		if not at_tick and ATTACK_EVENTS[x.e.type] then at_tick = x.t end
		if at_tick and x.e.type == "orb" then orb = true end
	end
	check(at_tick and at_tick <= 4 * 60, "plan: attacks within 4 seconds (" .. tostring(at_tick) .. " tick)")
	check(orb, "plan: then throws the teleport")
	-- two attacks: primary and secondary in the same turn
	n = 0
	for _, x in ipairs(bot_turn("normale", { due_attacchi = true })) do
		if ATTACK_EVENTS[x.e.type] then n = n + 1 end
	end
	check(n >= 2, "plan: two attacks in the same turn (" .. n .. ")")
end

-- Crates: the bot goes for the one nearby (pesi.cassa); with weight 0 it leaves it
do
	local function takes(weight, d)
		local g = game.new(4, "pavimento", { players = { { team = 1 }, { team = 2 } } })
		local b = bot.new(2, "normale", 4, { cassa = weight, cassa_fame = 0 })
		while g.current ~= 2 do g:step({ fire = g.phase == "aim" and { weapon = "missile", angle = 1.4, power = 0.2 } or nil }) end
		-- the bot on the pavimento's flat floor, between the two ramps
		local rb = g.robots[2]
		rb.x = 1000
		rb.y = g.terrain:ground_below(rb.x, game.WORLD_H - 1)
		local c = g:spawn_crate("grenade", rb.x + d)
		while not c.landed do g:update_crates() end
		local turn_now, start = g.turn_no, g.tick
		while g.turn_no == turn_now and g.tick - start < 40 * 60 do g:step(bot.input(b, g)) end
		return rb.crates
	end
	check(takes(12, -110) >= 1 and takes(12, 110) >= 1, "crates: the bot takes the crate nearby")
	check(takes(0, -110) == 0, "crates: with pesi.cassa 0 it leaves it")
end

-- The net: sums by hand on a small net (ReLU in the middle, linear output)
do
	local net = require "sim.rete"
	local r = { strati = { 2, 2, 1 }, w = { 1, -1, 0.5, 0.5, 0, -1, 2, 3, 0.25 } }
	-- hidden: relu(1*3 - 1*1 + 0) = 2, relu(0.5*3 + 0.5*1 - 1) = 1; output 2*2 + 3*1 + 0.25
	check(net.quanti(r.strati) == 9 and net.evaluate(r, { 3, 1 }) == 7.25, "net: the sums add up")
end

-- A real player and a bot: the player's keys end up in the recipe and replay it
do
	local players = { { team = 1 }, { team = 2, bot = "facile" } }
	local r3 = replay.nuova(4, "pavimento", { players = players })
	local g3, bots = replay.partita(r3)
	while g3.tick < 3600 and g3.phase ~= "over" do
		local human = { right = g3.tick % 200 < 100, left = false, hold = true, jump = g3.tick % 150 == 0 }
		if g3.current == 1 and g3.tick % 500 == 120 then human.fire = { weapon = "missile", angle = 0.6, power = 0.8 } end
		g3:step(replay.input(r3, g3, bots, human))
		replay.dopo(r3, g3)
	end
	check(#r3.input > 0 and #r3.input < g3.tick / 10, "recipe: only the key changes (" .. #r3.input .. ")")
	check(replay.verifica(r3), "recipe: player and bot, the replayed match is identical")
end

-- With bot_keys the bots' keys end up in the recipe too: replaying it, nobody
-- thinks (the in-game replay of a moment gets there at once) and it is the same match
do
	local players = { { team = 1 }, { team = 2, bot = "difficile" }, { team = 1, bot = "normale" }, { team = 2, bot = "facile" } }
	local r7 = replay.nuova(5, "pavimento", { players = players })
	r7.bot_keys = true
	local g7, bots = replay.partita(r7)
	while g7.tick < 6000 and g7.phase ~= "over" do
		local human = { right = g7.tick % 200 < 100, left = false, hold = true, jump = g7.tick % 150 == 0 }
		if g7.current == 1 and g7.tick % 500 == 120 then human.fire = { weapon = "missile", angle = 0.6, power = 0.8 } end
		g7:step(replay.input(r7, g7, bots, human))
		replay.dopo(r7, g7)
	end
	check(#r7.input > 0 and #r7.input < g7.tick / 10, "bot keys: still only the key changes (" .. #r7.input .. ")")
	check(replay.verifica(r7), "bot keys: the replayed match is identical")
	-- without bots at all: the keys alone are enough
	local g8 = replay.partita(r7)
	local l, n, same = replay.reader(r7), 1, true
	while g8.tick < g7.tick do
		g8:step(replay.read_step(l, g8, {}))
		local a = r7.impronte[n]
		if a and a.t == g8.tick then
			same = same and a.h == g8:impronta()
			n = n + 1
		end
	end
	check(same and n > 1, "bot keys: replayed without bots, the fingerprints all come back")
end

-- The bot thinks a little at a time: never too much work in one tick
do
	local g4 = game.new(2, "pavimento", { players = { { team = 1 }, { team = 2 } } })
	local b1, b2 = bot.new(1, "difficile", 2), bot.new(2, "difficile", 2)
	local too_much = 0
	while g4.tick < 6000 do
		local b = g4.current == 1 and b1 or b2
		local before = bot.totale or 0
		local input = bot.input(b, g4)
		if (bot.totale or 0) - before > 2 * b.liv.lavoro then too_much = too_much + 1 end
		g4:step(input)
		g4:pop_events()
	end
	check(too_much == 0, "the bot keeps to the work cap per tick")
end

-- The campaign grades: level, changed fields and weights
do
	local g3, g10, by_name = bot.new(2, 3, 1), bot.new(2, 10, 1), bot.new(2, "facile", 1)
	check(#bot.GRADES == 10 and g3.liv.teletrasporto and g3.pesi.teletrasporto == 20 and not by_name.liv.teletrasporto,
		"grades: 3 is easy using the orb, levels by name stay as they are")
	check(g10.liv == bot.LEVELS.difficile and g10.pesi.armi.mallet > 1 and bot.LEVELS.facile.teletrasporto == false,
		"grades: 10 is hard with the brawler, without touching the levels")
end

-- In the match-start draft the bot takes a valid primary and secondary
do
	local players = { { team = 1 }, { team = 2 }, { team = 1 }, { team = 2 } }
	local d = draft.new(9, players)
	for i = 1, 4 do bot.choose(d, i, 9) end
	local all_of = true
	for i = 1, 4 do all_of = all_of and draft.done(d, i) end
	check(all_of, "draft: the bots pick both weapons")
	-- with a taste for weapons (pesi.armi) it takes the ones it likes, if offered
	local d2 = draft.new(9, { { team = 1 }, { team = 2 } })
	bot.choose(d2, 1, 9, { punch = 3, mallet = 3 })
	local has = function(offer, w) for _, x in ipairs(offer) do if x == w then return true end end return false end
	check((d2.picks[1] == "punch") == has(d2.offer, "punch") and (d2.picks2[1] == "mallet") == has(d2.offer2, "mallet"),
		"draft: with a taste for weapons it takes Pugno and Maglio")
end

-- The copies the bot thinks on don't touch the real match
do
	local g5 = game.new(3, "pavimento")
	for _ = 1, 120 do g5:step() end
	local before = g5:impronta()
	local cells = 0
	for i = 1, #g5.terrain.data do cells = cells + g5.terrain.data[i] end
	local w = bot.world(g5)
	w:attack("missile", { angle = -1.2, power = 1 })
	for _ = 1, 200 do w:advance({}, true) end
	local after = 0
	for i = 1, #g5.terrain.data do after = after + g5.terrain.data[i] end
	check(g5:impronta() == before and cells == after, "the bot's tries change neither the match nor the terrain")
end

-- The melee aim: who would take the shot, without touching the match
do
	local g6 = game.new(3, "pavimento", { players = { { team = 1 }, { team = 2 } } })
	for _ = 1, 120 do g6:step() end
	local a, b = g6.robots[g6.current], nil
	for _, r in ipairs(g6.robots) do if r ~= a then b = r end end
	b.x, b.y = a.x + 50, a.y
	a.secondary = "bellows"
	local before, out = g6:impronta(), {}
	local toward = bot.hits(g6, "bellows", 0, out)
	local got = out[1]
	local away = bot.hits(g6, "bellows", math.pi, out)
	check(toward == 1 and got == b.id and away == 0 and g6:impronta() == before,
		"melee aim: the Mantice hits who is in front, not behind, and the match doesn't change")
end

-- Online the client's orbs have only id and position (server/net.lua): the
-- melee aim must not fly them (it crashed in update_orb, owner nil)
do
	local g7 = game.new(3, "pavimento", { players = { { team = 1 }, { team = 2 } } })
	for _ = 1, 120 do g7:step() end
	local a = g7.robots[g7.current]
	g7.orbs = { { id = 1, x = a.x + 30, y = a.y - 40 } }
	local res = {}
	for _, wpn in ipairs({ "sword", "mallet", "lunge" }) do
		local ok, err = pcall(bot.hits, g7, wpn, 0, {})
		if not ok then res[#res + 1] = wpn .. ": " .. tostring(err) end
	end
	check(#res == 0, "melee aim online with an orb in flight (only id and position): no error " .. table.concat(res, "; "))
end

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
