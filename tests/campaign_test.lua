-- Campaign tests (sim/levels.lua, sim/missions.lua): each lesson can really
-- be solved with its mechanic, and not without it; each mission starts clean.
-- How hard the circles are is measured by the bot trial
-- (strumenti/arena/collaudo.lua). From the repository root:
--   luajit tests/campaign_test.lua
-- Solutions are scripts of key presses; where an aim is needed, the test
-- searches a grid of angles and powers, as a person trying would.
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local missions = require "sim.missions"
local campaign = require "sim.campaign"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

local IDLE = {}
local RIGHT = { right = true }
local LEFT = { left = true }

-- Plays the lesson with the script: script(c) calls c.hold(input, tick or
-- condition), c.usa(weapon, angle, power), c.turno() (waits for the player's
-- next turn). Returns the outcome, the lesson and the match.
-- The test player touches what the lesson highlights (time is stopped until
-- it does) and, before using a weapon, selects it
local function obey(r, input)
	local a = r.awaiting
	if a then missions.tocca(r, a == "primaria" and "missile" or a == "secondaria" and "sword" or a) end
	if input and input.fire then
		missions.tocca(r, input.fire.weapon)
		missions.tocca(r, "mira")
	end
	if input and input.jump then missions.tocca(r, "salta") end
	if input and (input.left or input.right) then missions.tocca(r, "cammina") end
end

local function play_mission(id, script, picks, limit)
	local r = missions.nuova(id)
	local seed, map_name, opts = missions.partita(r, 3, picks)
	local g = game.new(seed, map_name, opts)
	missions.prepara(r, g)
	local co = coroutine.wrap(function(c)
		script(c)
		while true do coroutine.yield(IDLE) end
	end)
	local c = {}
	function c.hold(input, until_cond)
		local n = 0
		while true do
			if type(until_cond) == "number" then
				if n >= until_cond then return end
			elseif until_cond(g) then
				return
			end
			n = n + 1
			coroutine.yield(input)
		end
	end
	function c.usa(weapon_name, angle_deg, strength)
		coroutine.yield({ fire = { weapon = weapon_name, angle = angle_deg, power = strength or 1 } })
	end
	-- walks towards the crate with that weapon until it picks it up (waits for it to drop)
	function c.cassa(w)
		while not r.prese[w] do
			local x
			for _, cr in ipairs(g.crates) do
				if cr.weapon == w then x = cr.x end
			end
			local rb = g.robots[1]
			if not x or math.abs(x - rb.x) < 4 then
				coroutine.yield(IDLE)
			else
				coroutine.yield(x > rb.x and RIGHT or LEFT)
			end
		end
		c.hold(IDLE, 2)
	end
	function c.turno()
		local turns_played = r.st.turni
		c.hold(IDLE, function() return r.st.turni > turns_played and g.phase == "aim" end)
	end
	c.g, c.r = g, r
	local first = true
	for _ = 1, limit or 60 * 120 do
		local input = first and IDLE or co(c)
		first = false
		-- any key: in the lessons time starts from here
		obey(r, input)
		if next(input) then missions.tocca(r) end
		g:step(input)
		for _, e in ipairs(g:pop_events()) do missions.evento(r, g, e) end
		local outcome = missions.tick(r, g)
		if outcome then return outcome, r, g end
	end
	return nil, r, g
end

-- Searches angle and power for which the script (which receives a, p) finishes the lesson
local function search(id, script, picks, angles, powers)
	for _, p in ipairs(powers or { 1 }) do
		for a = angles[1], angles[2], angles[3] do
			local outcome, r = play_mission(id, function(c) script(c, a, p) end, picks)
			if outcome == "fatta" then return true, r, a, p end
		end
	end
	return false
end

local function powers(from_pt, a, stride)
	local t = {}
	for p = from_pt, a, stride do t[#t + 1] = p end
	return t
end

local function until_x(x) return function(g) return g.robots[1].x >= x end end

-- Every mission: robots start resting on the ground, and doing nothing doesn't complete it
for _, cap in ipairs(campaign.CAPITOLI) do
for _, l in ipairs(cap.missioni) do
	if not l.guidata and not l.giocatori[2].bot then
		local outcome, r, g = play_mission(l.id, function() end, nil, 60 * 30 * (l.turni or 2) + 600)
		local fell = true
		for _, rb in ipairs(g.robots) do
			if rb.dead and not rb.gone then fell = false end
		end
		check(fell, l.id .. ": nobody falls by themselves")
		-- (and something says what to do: the line, or in the lessons the goal always in view)
		local said = r.riga ~= nil or (l.riprova and missions.obiettivo(r) ~= nil)
		check(outcome ~= "fatta" and said or outcome == "fallita", l.id .. ": doing nothing doesn't finish it")
	end
	-- each star says what it needs (the cortile: «Fatta» and Favilla's medal, if
	-- there is one), and the goal can be read
	check(#missions.criteria(l) == (l.medaglia and 2 or l.stelle and 3 or 1), l.id .. ": a criterion for each star")
	if type(l.obiettivo) == "table" then
		local r = missions.nuova(l.id)
		check(missions.obiettivo(r) ~= nil, l.id .. ": the goal is visible")
	end
end
end

-- In chapter 0 no healing circles: after four turns doing nothing there are none
do
	local _, _, g = play_mission("guidata", function(c)
		for _ = 1, 3 do
			c.hold(RIGHT, 1)
			c.turno()
		end
	end, nil, 60 * 30 * 12)
	check(#g.heals == 0 and g.turn_no >= 4, "lessons: no healing circles")
end

-- Stammi dietro: walk after Favilla, jump the step, reach her at the gate. No
-- timer, turns or weapons. The medal: the spark above the step, only with the
-- jump held to the end
local function to_step(c)
	c.hold(RIGHT, until_x(1075))
	c.hold({ right = true, jump = true }, 40)
	c.hold(RIGHT, until_x(1180))
end
do
	local outcome, r, g = play_mission("primi_passi", function(c)
		c.hold(RIGHT, until_x(1000))
		c.usa("missile", 0.5, 0.6)
		c.hold(IDLE, 60 * 60)
	end)
	check(outcome == nil and r.st.steps_done[1] and not r.st.steps_done[2], "primi_passi: walking alone doesn't get you up the step")
	check(g.turn_no == 1 and g.current == 1, "primi_passi: no turns, even after a minute")
	check(not g.projectile and #g.crates == 0 and not game.has_weapon(g.robots[1], "missile") and not g:can_use("missile"),
		"primi_passi: no weapons")
	check(g.robots[2].gone and missions.guida(r).x > 1500, "primi_passi: only you and Favilla, who waits at the gate")
	outcome, r = play_mission("primi_passi", function(c)
		to_step(c)
		c.hold(RIGHT, until_x(1470))
	end)
	check(outcome == "fatta" and not missions.stelle(r)[2], "primi_passi: the step and Favilla at the gate, without the spark")
	-- under the spark a short jump doesn't reach it, a held one does
	outcome, r = play_mission("primi_passi", function(c)
		to_step(c)
		c.hold(RIGHT, until_x(1290))
		c.hold({ jump = true }, 12)
		c.hold({ hold = false }, 60)
		c.hold(RIGHT, until_x(1470))
	end)
	check(outcome == "fatta" and not missions.stelle(r)[2], "primi_passi: a short jump misses the spark")
	outcome, r = play_mission("primi_passi", function(c)
		to_step(c)
		c.hold(RIGHT, until_x(1290))
		c.hold({ jump = true }, 60)
		c.hold(RIGHT, until_x(1470))
	end)
	check(outcome == "fatta" and missions.stelle(r)[2] and missions.scintilla(r) == nil,
		"primi_passi: the jump held to the end takes the spark: Favilla's medal")
end

-- Il mio vecchio Lanciarune: the crate, the near target, then the one on the ledge.
-- Whoever misses retries at once
local near_a, near_p
for p = 0.3, 1, 0.1 do
	for a = 0.1, 1.3, 0.05 do
		if not near_a then
			local _, r = play_mission("lanciarune", function(c)
				c.cassa("missile")
				c.usa("missile", a, p)
				c.hold(IDLE, 200)
			end, nil, 60 * 30)
			if r.st.steps_done[2] then near_a, near_p = a, p end
		end
	end
end
check(near_a ~= nil, "lanciarune: the crate and the near target")
local ok, r, a, p
if near_a then
	ok, r = search("lanciarune", function(c, a, p)
		c.cassa("missile")
		c.usa("missile", near_a, near_p)
		c.hold(IDLE, function() return c.r.st.steps_done[2] and not c.g.used.primary end)
		c.usa("missile", a, p)
	end, nil, { 0.1, 1.3, 0.05 }, powers(0.4, 1, 0.1))
	check(ok, "lanciarune: then the target on the ledge")
	-- a missed shot (towards the sky behind you): retry at once, in the same turn
	local outcome2, r3, g3 = play_mission("lanciarune", function(c)
		c.cassa("missile")
		c.usa("missile", 2.6, 0.3)
		c.hold(IDLE, function(gg) return not gg.used.primary end)
		c.usa("missile", near_a, near_p)
		c.hold(IDLE, 200)
	end)
	check(r3.st.steps_done[2] and r3.st.conta.misses == 1 and g3.turn_no == 1, "lanciarune: whoever misses retries at once")
end

local outcome, g
-- A turno: the Lanciarune on the target, then the Lama on the same one, then
-- behind the low wall before the turn ends
local hit_a, hit_p
for p = 0.3, 1, 0.1 do
	for a = math.pi - 0.05, math.pi - 1.2, -0.05 do
		if not hit_a then
			local _, r = play_mission("turno", function(c)
				c.usa("missile", a, p)
				c.hold(IDLE, 200)
			end, nil, 60 * 20)
			if r.st.steps_done[1] then hit_a, hit_p = a, p end
		end
	end
end
check(hit_a ~= nil, "turno: the Lanciarune on the target")
local function two_attacks(c)
	c.usa("missile", hit_a, hit_p)
	c.hold(IDLE, function(g) return not g.projectile end)
	c.hold(LEFT, function(g) return g.robots[1].x <= g.robots[2].x + 50 end)
	c.usa("sword", math.pi)
	c.hold(IDLE, 60)
end
-- Favilla shows first (turn 1), then it's yours: everything happens in turn 2
local YOURS = 2
if hit_a then
	outcome, r, g = play_mission("turno", function(c)
		two_attacks(c)
		c.hold(RIGHT, until_x(1020))
		c.hold(IDLE, 30)
		c.usa("teleport", 1.2, 0.65)
		c.hold(IDLE, function(gg) return gg.robots[1].x >= 1120 and gg.robots[1].grounded end)
	end)
	check(outcome == "fatta" and g.turn_no == YOURS, "turno: two attacks in the same turn, then behind the wall")
	-- after the attacks time waits for you to take cover
	outcome, r, g = play_mission("turno", function(c)
		two_attacks(c)
		c.hold(IDLE, 60 * 20)
	end)
	check(outcome == nil and r.st.steps_done[2] and not r.st.steps_done[3] and g.turn_no == YOURS,
		"turno: after the two attacks the turn waits for you behind the wall")
	-- before the right step everything else is disabled: no Lama
	local _, r3, g3 = play_mission("turno", function(c)
		c.usa("sword", 0)
		c.hold(IDLE, 30)
	end)
	check(not r3.st.steps_done[1] and not g3.used.secondary, "turno: only what the step says can be used")
	-- a missed Lama comes back at once, and you where you were: then it hits
	local _, r4, g4 = play_mission("turno", function(c)
		c.usa("missile", hit_a, hit_p)
		c.hold(IDLE, function(g) return not g.projectile end)
		c.hold(IDLE, 40)
		c.hold(RIGHT, 20)
		c.usa("sword", 0)
		c.hold(IDLE, function(g) return not g.used.secondary end)
		c.hold(LEFT, function(g) return g.robots[1].x <= g.robots[2].x + 50 end)
		c.usa("sword", math.pi)
		c.hold(IDLE, 20)
	end)
	check(r4.st.steps_done[2] and r4.st.conta.misses == 1 and g4.turn_no == YOURS, "turno: a missed Lama is retried in the same turn")
	-- the Lama card waits for the missile to land, and a moment after
	local early_attack, late
	play_mission("turno", function(c)
		c.usa("missile", hit_a, hit_p)
		c.hold(IDLE, 2)
		early_attack = c.r.opened[1]
		c.hold(IDLE, function(g) return not g.projectile end)
		c.hold(IDLE, 30)
		late = c.r.opened[1]
	end)
	check(not early_attack and late, "turno: the Lama card after the missile has landed")
end

-- I globi: the Lanciarune at once (orbs), the orb onto the island, the target
-- there falls at the first hit. The medal: two orbs in one turn
local function island_turn(c)
	c.usa("missile", 2.5, 0.3)
	c.hold(IDLE, function(g) return not g.projectile end)
	c.hold(IDLE, 30)
	c.usa("teleport", 0.5, 0.6)
	c.hold(IDLE, function(g) return g.robots[1].x > 1150 and g.robots[1].grounded end)
end
outcome, r, g = play_mission("tempo", function(c)
	island_turn(c)
	c.hold(RIGHT, function(g) return g.robots[1].x >= g.robots[3].x - 40 end)
	c.usa("sword", 0, 0.1)
	c.hold(IDLE, 30)
end)
check(outcome == "fatta" and g.robots[3].dead, "tempo: orbs, the island, the target there")
if outcome == "fatta" then
	check(missions.stelle(r)[2], "tempo: attacking at once, two orbs in a turn: Favilla's medal")
end
do
	-- without attacking time stops before you lose the first orb: no medal
	local _, r2, g2 = play_mission("tempo", function(c)
		c.hold(RIGHT, 1)
		c.hold(IDLE, 60 * 30)
		c.usa("missile", 2.5, 0.3)
		c.hold(IDLE, 30)
	end)
	check(g2.turn_no == 1 and r2.st.conta.globi == 1 and r2.st.conta.globi_turno == 1,
		"tempo: time waits for the first attack, with one orb")
	-- before the right step everything else is disabled: no teleport
	local _, r3, g3 = play_mission("tempo", function(c)
		c.usa("teleport", 0.6, 0.8)
		c.hold(IDLE, 30)
	end)
	check(not r3.st.steps_done[1] and #g3.orbs == 0, "tempo: only what the step says can be used")
	-- wasted orbs come back: thrown into the void, you respawn as you were with your orbs
	local _, r6, g6 = play_mission("tempo", function(c)
		c.usa("missile", 2.5, 0.3)
		c.hold(IDLE, function(g) return not g.projectile end)
		c.hold(IDLE, 30)
		c.usa("teleport", math.pi - 0.3, 1)
		c.hold(IDLE, function(g) return g.robots[1].dead end)
		c.hold(IDLE, function(g) return not g.robots[1].dead end)
		c.hold(IDLE, 10)
	end)
	local rb6 = g6.robots[1]
	check(r6.st.steps_done[1] and not r6.st.steps_done[2] and rb6.teleports_left == 2 and g6:can_use("teleport")
		and math.abs(rb6.x - r6.saved.x) < 2, "tempo: fell with the orb, respawn as you were, with the orbs")
	-- and wasted without falling: Ritenta, and you're back as you were
	local _, r7, g7 = play_mission("tempo", function(c)
		c.usa("missile", 2.5, 0.3)
		c.hold(IDLE, function(g) return not g.projectile end)
		c.hold(IDLE, 30)
		for _ = 1, 2 do
			c.usa("teleport", math.pi / 2, 0.2)
			c.hold(IDLE, function(g) return #g.orbs == 0 and g.robots[1].grounded end)
		end
		c.hold(IDLE, 80)
	end)
	check(not r7.st.steps_done[2] and g7.robots[1].teleports_left == 2 and g7:can_use("teleport")
		and r7.st.conta.misses == 1, "tempo: without orbs for the island, Ritenta and they come back")
end

-- Arriva in cima: the Tonante downwards carries you onto the first pillar, the
-- Maglio coming down bounces you onto the second
ok, r = search("spostano", function(c, a, p)
	c.cassa("eagle")
	c.hold(RIGHT, until_x(975))
	c.hold({ jump = true, right = true }, 30)
	c.usa("eagle", -math.pi / 2 - 0.2)
	c.hold(RIGHT, function(g) return g.robots[1].grounded end)
	c.hold(IDLE, 10)
	c.cassa("mallet")
	c.hold(LEFT, function(g) return g.robots[1].x <= 1080 end)
	c.hold({ jump = true }, 10)
	c.hold(IDLE, function(g) return g.robots[1].vy < 0 and g.robots[1].y < 263 + a end)
	c.usa("mallet", 0)
	c.hold(RIGHT, function(g) return g.robots[1].grounded and g.robots[1].y > 400 end)
	c.hold(IDLE, 10)
end, nil, { 10, 30, 10 })
check(ok, "spostano: the Tonante and the Maglio carry you to the top")
if ok then check(missions.stelle(r)[2], "spostano: without a wasted shot: Favilla's medal") end
outcome = play_mission("spostano", function(c)
	c.cassa("eagle")
	c.hold(RIGHT, until_x(960))
	for _ = 1, 10 do
		c.hold({ right = true, jump = true }, 12)
		c.hold(RIGHT, 30)
	end
end)
check(outcome ~= "fatta", "spostano: just jumping doesn't get you up")
-- Il burrone: no crates, the cards open by themselves. The Rampino carries you
-- onto the platform, the parachute past the void
local function tools_on(c)
	c.hold(RIGHT, until_x(760))
	c.hold(IDLE, 10)
	c.usa("hook", 32, 1)
	c.hold(IDLE, function(g) return g.robots[1].grounded and g.robots[1].y > 300 end)
	c.hold(IDLE, 10)
end
outcome, r = play_mission("attrezzi", function(c)
	tools_on(c)
	c.hold(RIGHT, until_x(1200))
	c.hold({ right = true, jump = true }, 15)
	c.usa("parachute", 0, 1)
	c.hold(RIGHT, function(g) return g.robots[1].grounded end)
	c.hold(RIGHT, until_x(1500))
	c.hold(IDLE, 30)
end)
check(outcome == "fatta", "attrezzi: Rampino and parachute carry you to the other side")
if outcome == "fatta" then check(missions.stelle(r)[2], "attrezzi: across without falling: Favilla's medal") end
outcome, r, g = play_mission("attrezzi", function(c)
	c.hold(RIGHT, until_x(750))
	for _ = 1, 10 do
		c.hold({ right = true, jump = true }, 12)
		c.hold(RIGHT, 30)
	end
end)
check(not r.st.steps_done[2] and r.prese.hook, "attrezzi: the Rampino arrives without a crate, and jumping doesn't get you up")
outcome, r, g = play_mission("attrezzi", function(c)
	tools_on(c)
	c.hold(RIGHT, 600)
end)
check(not r.st.steps_done[4] and g.robots[1].deaths > 0 and r.prese.parachute and r.st.conta.morti > 0,
	"attrezzi: without opening the parachute you fall into the void (and the medal is lost)")

-- The cortile's demonstrations: in every lesson where Favilla shows the moves,
-- each demonstration does what it shows (the player still), with the real keys
do
	local bot = require "sim.bot"
	-- what each demonstration must leave behind: Favilla's x, y (at least) and an event
	local SHOWS = {
		lanciarune = { { passi = 1, evento = "damage", su = 2 } },
		turno = { { passi = 0, evento = "sword_hit" }, { passi = 3, x = 1120, evento = "teleport" } },
		attrezzi = { { passi = 0, x = 880, y = 330 }, { passi = 2, da = { 905, 335 }, x = 1360, evento = "parachute" } },
		spostano = { { passi = 1, y = 255 }, { passi = 4, y = 455 } },
		tempo = { { passi = 0, x = 1200, y = 148, evento = "teleport" } },
	}
	for id, list in pairs(SHOWS) do
		for k, want in ipairs(list) do
			local r = missions.nuova(id)
			local seed, map_name, opts = missions.partita(r, 3)
			local g = game.new(seed, map_name, opts)
			local bots = {}
			missions.prepara(r, g, bots)
			for i = 1, want.passi do r.st.steps_done[i] = true end
			-- the earlier demonstrations are done already (as when you get there)
			for j = 1, k - 1 do r.shown[j] = true end
			if want.da then g.robots[r.l.maestra].x, g.robots[r.l.maestra].y = want.da[1], want.da[2] end
			local F, seen, ended = r.l.maestra, false, false
			-- the lines of those steps have been read already (the big one too: she
			-- shows only after explaining), as when you get there
			missions.tick(r, g)
			r.coda, r.riga, r.line_ticks = {}, nil, nil
			for _ = 1, 60 * 30 do
				missions.tocca(r)
				local keys = bots[g.current] and bot.input(bots[g.current], g) or {}
				g:step(keys)
				for _, e in ipairs(g:pop_events()) do
					if e.type == want.evento and (want.su == nil or e.robot == want.su) and (e.robot == F or e.by == F) then seen = true end
					if e.type == "demo_end" then ended = true end
					missions.evento(r, g, e, bots)
				end
				missions.tick(r, g)
				if ended then break end
			end
			local f = g.robots[F]
			local ok_here = ended and not f.dead and (want.evento == nil or seen)
				and (want.x == nil or f.x >= want.x) and (want.y == nil or f.y >= want.y)
			check(ok_here, id .. ": Favilla's demonstration " .. k .. " does its move (x " .. math.floor(f.x) .. ", y " .. math.floor(f.y) .. ")")
		end
	end
end

-- Giù dal bordo: each of the three targets is knocked off its rock with a single missile
for who = 2, 4 do
	local found, fell = false, false
	for a = -0.5, 3.6, 0.05 do
		for p = 0.2, 1, 0.05 do
			if not found then
				local _, r, g = play_mission("giu_dal_bordo", function(c)
					c.usa("missile", a, p)
					c.hold(IDLE, 400)
				end, nil, 420)
				found = g.robots[1].env_kills > 0 and g.robots[who].deaths > 0
				-- knocked off it stays down (Sergio, 30 Oct)
				if found then fell = g.robots[who].gone or r.giu[who] end
			end
		end
	end
	check(found, "giu_dal_bordo: target " .. who .. " falls with one shot")
	check(fell, "giu_dal_bordo: target " .. who .. " knocked off doesn't respawn")
end

-- Giù dal bordo with the Rampino: from the edge of the platform the hook
-- reaches the side rocks (map unchanged, reach config.HOOK.range) and the
-- target, pulled by reel and released over the void, falls
for who, side_of in pairs({ [2] = -1, [3] = 1 }) do
	local found = false
	for a = 0, 0.6, 0.02 do
		if not found then
			local angle_deg = side_of < 0 and math.pi - a or a
			local _, _, g = play_mission("giu_dal_bordo", function(c)
				c.hold(side_of < 0 and LEFT or RIGHT, function(g2)
					local x = g2.robots[1].x
					return side_of < 0 and x <= 775 or side_of > 0 and x >= 1145
				end)
				c.hold(IDLE, 10)
				c.usa("hook", angle_deg)
				c.hold(IDLE, 300)
			end, nil, 900)
			found = g.robots[1].env_kills > 0 and g.robots[who].deaths > 0
		end
	end
	check(found, "giu_dal_bordo: from the edge the Rampino catches target " .. who .. " and knocks it off")
end

-- The duel with Favilla: the timer waits for the controls to be touched,
-- Favilla (the tutorial bot) shows the two attacks and then the teleport in
-- her first turns, the match lasts 3 minutes. The player fires one missile per
-- turn; no points (they come in the Forgia).
do
	local replay = require "sim.replay"
	local r = missions.nuova("guidata")
	local seed, map_name, opts = missions.partita(r, 5)
	local ric = replay.nuova(seed, map_name, opts)
	local g, bots = replay.partita(ric)
	missions.prepara(r, g)
	local seen, ticks, outcome, frozen = {}, 0, nil, nil
	while not outcome and ticks < 60 * 60 * 6 do
		ticks = ticks + 1
		local input = {}
		if g.current == 1 and g.phase == "aim" and not g.used.primary then
			-- on the first turn wait 30 s before shooting
			if r.st.turni == 1 and ticks < 1800 then
				frozen = g.timer
			else
				input = { fire = { weapon = "missile", angle = 0.6, power = 0.8 } }
				missions.tocca(r)
			end
		end
		if not (r.st.turni == 1 and ticks < 1800) then obey(r, input) end
		g:step(replay.input(ric, g, bots, input))
		for _, e in ipairs(g:pop_events()) do
			missions.evento(r, g, e, bots)
			if e.robot == 2 then seen[r.st.bot_turns .. e.type] = true end
		end
		outcome = missions.tick(r, g)
	end
	check(frozen == game.TURN_TICKS, "guidata: on the first turn the timer waits for the controls to be touched")
	check(seen["1swing"] or seen["1mallet"] or seen["1eagle"] or seen["1lunge"],
		"guidata: on its first turn the bot also uses the secondary")
	check(seen["2teleports"] and seen["2teleport"], "guidata: on its second turn the bot earns orbs and teleports")
	check(outcome ~= nil and (outcome == "fatta" or g.phase == "over"), "guidata: the short match ends")
	check(not g.no_points, "guidata: points in the duel")
	check(ticks < 60 * 60 * 5, "guidata: lasts less than 5 minutes (" .. math.floor(ticks / 60) .. " s)")
end

-- Due mani: after a failed first turn the bot goes back to its mission life
-- (28), not to 150: it can still be finished
do
	local r = missions.nuova("due_mani")
	local seed, map_name, opts = missions.partita(r, 3)
	local g = game.new(seed, map_name, opts)
	missions.prepara(r, g)
	local rb = g.robots[2]
	rb.hp = 10
	missions.evento(r, g, { type = "turn", robot = 2 })
	check(rb.hp == 46 and rb.max_hp == 46, "due_mani: the bot recovers to 46, not to normal life")
end
-- The weapons the Addestramento doesn't introduce: in Primo sangue the Uovo,
-- in Due mani the Schegge, in a crate near you. Walking over it you take it,
-- and it's a single shot (it doesn't come back as in the lessons)
for _, m in ipairs({ { "primo_sangue", "grenade" }, { "due_mani", "shards" } }) do
	local _, r, g = play_mission(m[1], function(c) c.cassa(m[2]) end, nil, 60 * 20)
	local rb = g.robots[1]
	check(r.prese[m[2]] and rb.ammo[m[2]] == 1, m[1] .. ": the crate with the new weapon is taken by walking")
end
-- and whoever respawns does so with the mission life (Fuori portata: 40)
for _, l in ipairs(campaign.CAPITOLI[2].missioni) do
	if l.vita then
		local r = missions.nuova(l.id)
		local seed, map_name, opts = missions.partita(r, 3)
		local g = game.new(seed, map_name, opts)
		missions.prepara(r, g)
		for i, v in pairs(l.vita) do
			check(g.robots[i].max_hp == v, l.id .. ": full life (and respawn life) is the mission's")
		end
	end
end

-- Each star with its criterion: with a small point lead and without dying
-- they are the first and third, not the second (and in the profile each star
-- earned stays)
do
	local r = missions.nuova("primo_sangue")
	r.esito, r.st.gap = "fatta", 40
	local s = missions.stelle(r)
	check(s[1] and not s[2] and s[3], "stars: the bonus without the points lights the third and not the second")
	r.st.gap = 300
	check(missions.stelle(r)[2], "stars: the second with the point lead")
	local profile = require "menu.profile"
	local p = profile.nuovo()
	profile.missione(p, "primo_sangue", s)
	profile.missione(p, "primo_sangue", { true, true, false })
	check(profile.total_stars(p) == 3, "stars: in the profile each one earned stays")
end

-- No points in the lessons that aren't about them (Sergio, 31 Oct: they
-- distract from the exercise): nobody scores, not even by downing. Punti e
-- Corona and the Prima partita have them
for _, l in ipairs(campaign.CAPITOLI[1].missioni) do
	local r = missions.nuova(l.id)
	local seed, map_name, opts = missions.partita(r, 3)
	local g = game.new(seed, map_name, opts)
	missions.prepara(r, g)
	local without = not missions.vede(r, "punti")
	check(g.no_points == without, l.id .. (without and ": no points" or ": with points"))
	g:hurt(g.robots[2], 999, g.robots[1], 0)
	local steps_count = 0
	for _, e in ipairs(g:pop_events()) do
		if e.type == "points" then steps_count = steps_count + 1 end
	end
	check((steps_count == 0) == without and (g.robots[1].points == 0) == without,
		l.id .. ": downing " .. (without and "gives no points" or "gives points"))
end
check(missions.vede(missions.nuova("guidata"), "punti") and not missions.vede(missions.nuova("prima_sfida"), "punti"),
	"the duel with Favilla has points, the first duel doesn't")

-- The help after many losses: the Fabbro goes down a level and starts with
-- less life, but with a full bar (it doesn't show)
do
	local function smith(help)
		local r = missions.nuova("il_fabbro")
		local seed, map_name, opts = missions.partita(r, 7, nil, help)
		local g = game.new(seed, map_name, opts)
		missions.prepara(r, g)
		return opts.players[2].bot, g.robots[2]
	end
	local liv, rb = smith(false)
	local help_level, help_rb = smith(true)
	check(liv == 5 and help_level == 3, "help: the bot goes down two grades")
	check(help_rb.hp < rb.hp and help_rb.hp == help_rb.max_hp, "help: less life, full bar")
end

-- Favilla shows the moves (insegna, dimostra): the turn passes to her, she
-- walks, jumps, says her line, fires the Lanciarune with the real physics,
-- then the turn comes back to the player as it was. Her hit doesn't do the
-- player's step; a second demonstration waits for the player to come near
do
	local bot = require "sim.bot"
	local l = {
		id = "prova_favilla", titolo = "Prova", tipo = "bersagli",
		arena = { { 0, 0, 1920, 150 } },
		spawns = { { x = 300, from = 600 }, { x = 1100, from = 600 }, { x = 600, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 1, insegna = true, nome = "Favilla", pelle = "favilla" } },
		vedi = { "missile" }, without_time = true,
		dimostra = {
			{ mosse = { { dice = "Guarda!" }, { cammina = 800 }, { salta = "destra" },
				{ arma = "missile", angolo = 5, potenza = 0.7 }, { posa = "vittoria", secondi = 0.5 } } },
			{ quando = { vicino = 250 }, mosse = { { arma = "hook", angolo = 70 } } },
		},
		obiettivo = { { hit = 2, testo = "Colpisci il bersaglio" } },
	}
	local r = missions.nuova(missions.prova(l, "addestramento"))
	local seed, map_name, opts = missions.partita(r, 3)
	local g = game.new(seed, map_name, opts)
	local bots = {}
	missions.prepara(r, g, bots)
	check(bots[3] and opts.players[3].dummy, "Favilla: a robot moved by the demonstration, without turns of her own")
	local seen, said, posed, hit_by_her, max_x = {}, nil, false, false, 0
	local function run(ticks, input, stop)
		for _ = 1, ticks do
			local keys = bots[g.current] and bot.input(bots[g.current], g) or input or {}
			g:step(keys)
			for _, e in ipairs(g:pop_events()) do
				seen[e.type .. ":" .. tostring(e.robot)] = true
				if e.type == "damage" and e.robot == 2 and e.by == 3 then hit_by_her = true end
				missions.evento(r, g, e, bots)
			end
			missions.tick(r, g)
			local _, t = missions.battuta(r)
			said = said or t
			posed = posed or missions.posa(r) == 3
			if g.current == 3 then max_x = math.max(max_x, g.robots[3].x) end
			if stop and stop() then return end
		end
	end
	run(2)
	check(g.current == 3 and missions.dimostra(r), "Favilla: the demonstration starts at once, on her turn")
	run(60 * 20, { fire = { weapon = "missile", angle = 0, power = 1 } }, function() return not missions.dimostra(r) end)
	check(not missions.dimostra(r) and g.current == 1 and g.phase == "aim", "Favilla: the turn comes back to the player")
	check(seen["demo:3"] and seen["fire:3"] and not seen["fire:1"], "Favilla fired, the player couldn't meanwhile")
	check(said == "Guarda!" and posed and max_x > 790, "Favilla said her line, walked and struck her pose")
	check(hit_by_her and not r.st.steps_done[1], "Favilla's hit doesn't do the player's step")
	check(g.robots[3].hp == g.robots[3].max_hp, "Favilla doesn't get hurt")
	-- the second waits for the player near her
	run(120)
	check(g.current == 1 and not r.shown[2], "Favilla waits for the player to come near")
	run(60 * 10, { right = true }, function() return missions.dimostra(r) end)
	check(missions.dimostra(r), "near her, the second demonstration starts")
	run(60 * 15, nil, function() return not missions.dimostra(r) end)
	check(seen["hook_shot:3"] or seen["hook:3"], "Favilla used the Rampino")
	check(g.current == 1, "and the turn is the player's again")
end

-- globi_tempo: levels from 'a turno' onwards award orbs from leftover time
for _, id in ipairs({ "turno", "tempo", "prima_sfida", "sfida_burrone", "guidata" }) do
	local r = missions.nuova(id)
	local _, _, opts = missions.partita(r, 1)
	check(opts.players[1].stats.time_orbs == 1, id .. ": time_orbs == 1")
	check(missions.vede(r, "teleport"), id .. ": teleport is visible")
end
for _, id in ipairs({ "primi_passi", "lanciarune" }) do
	local r = missions.nuova(id)
	local _, _, opts = missions.partita(r, 1)
	check(opts.players[1].stats.time_orbs == 0, id .. ": time_orbs == 0")
end

-- custom mission with globi_tempo = false
do
	local l = {
		id = "prova_senza_tempo", titolo = "Prova", tipo = "bersagli",
		arena = { { 0, 0, 1920, 150 } }, spawns = { { x = 300, from = 600 }, { x = 1100, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		globi_tempo = false,
		obiettivo = { { hit = 2, testo = "Colpisci" } },
	}
	local r = missions.nuova(missions.prova(l, "addestramento"))
	local _, _, opts = missions.partita(r, 1)
	check(opts.players[1].stats.time_orbs == 0, "globi_tempo = false forces time_orbs == 0")
end

print(failures == 0 and "\nall tests passed" or ("\n" .. failures .. " tests failed"))
os.exit(failures == 0 and 0 or 1)
