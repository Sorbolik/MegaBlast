-- Campaign tests (sim/campaign.lua, sim/missions.lua): each lesson can really
-- be solved with its mechanic, and not without it; each mission starts clean.
-- How hard the circles are is measured by the bot trial
-- (strumenti/arena/collaudo.lua). From the repository root:
--   luajit tests/campaign_test.lua
-- Solutions are scripts of key presses; where an aim is needed, the test
-- searches a grid of angles and powers, as a person trying would.
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local missioni = require "sim.missions"
local campagna = require "sim.campaign"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

local FERMO = {}
local DESTRA = { right = true }
local SINISTRA = { left = true }

-- Plays the lesson with the script: script(c) calls c.hold(input, tick or
-- condition), c.usa(weapon, angle, power), c.turno() (waits for the player's
-- next turn). Returns the outcome, the lesson and the match.
-- The test player touches what the lesson highlights (time is stopped until
-- it does) and, before using a weapon, selects it
local function obey(r, input)
	local a = r.attende
	if a then missioni.tocca(r, a == "primaria" and "missile" or a == "secondaria" and "sword" or a) end
	if input and input.fire then
		missioni.tocca(r, input.fire.weapon)
		missioni.tocca(r, "mira")
	end
	if input and input.jump then missioni.tocca(r, "salta") end
	if input and (input.left or input.right) then missioni.tocca(r, "cammina") end
end

local function gioca(id, script, picks, limit)
	local r = missioni.nuova(id)
	local seed, mappa, opts = missioni.partita(r, 3, picks)
	local g = game.new(seed, mappa, opts)
	missioni.prepara(r, g)
	local co = coroutine.wrap(function(c)
		script(c)
		while true do coroutine.yield(FERMO) end
	end)
	local c = {}
	function c.hold(input, fino)
		local n = 0
		while true do
			if type(fino) == "number" then
				if n >= fino then return end
			elseif fino(g) then
				return
			end
			n = n + 1
			coroutine.yield(input)
		end
	end
	function c.usa(arma, angolo, potenza)
		coroutine.yield({ fire = { weapon = arma, angle = angolo, power = potenza or 1 } })
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
				coroutine.yield(FERMO)
			else
				coroutine.yield(x > rb.x and DESTRA or SINISTRA)
			end
		end
		c.hold(FERMO, 2)
	end
	function c.turno()
		local turni = r.st.turni
		c.hold(FERMO, function() return r.st.turni > turni and g.phase == "aim" end)
	end
	c.g, c.r = g, r
	local primo = true
	for _ = 1, limit or 60 * 120 do
		local input = primo and FERMO or co(c)
		primo = false
		-- any key: in the lessons time starts from here
		obey(r, input)
		if next(input) then missioni.tocca(r) end
		g:step(input)
		for _, e in ipairs(g:pop_events()) do missioni.evento(r, g, e) end
		local esito = missioni.tick(r, g)
		if esito then return esito, r, g end
	end
	return nil, r, g
end

-- Searches angle and power for which the script (which receives a, p) finishes the lesson
local function search(id, script, picks, angoli, potenze)
	for _, p in ipairs(potenze or { 1 }) do
		for a = angoli[1], angoli[2], angoli[3] do
			local esito, r = gioca(id, function(c) script(c, a, p) end, picks)
			if esito == "fatta" then return true, r, a, p end
		end
	end
	return false
end

local function potenze(da, a, passo)
	local t = {}
	for p = da, a, passo do t[#t + 1] = p end
	return t
end

local function until_x(x) return function(g) return g.robots[1].x >= x end end

-- Every mission: robots start resting on the ground, and doing nothing doesn't complete it
for _, cap in ipairs(campagna.CAPITOLI) do
for _, l in ipairs(cap.missioni) do
	if not l.guidata and not l.giocatori[2].bot then
		local esito, r, g = gioca(l.id, function() end, nil, 60 * 30 * (l.turni or 2) + 600)
		local giu = true
		for _, rb in ipairs(g.robots) do
			if rb.dead then giu = false end
		end
		check(giu, l.id .. ": nobody falls by themselves")
		-- (and something says what to do: the line, or in the lessons the goal always in view)
		local detto = r.riga ~= nil or (l.riprova and missioni.obiettivo(r) ~= nil)
		check(esito ~= "fatta" and detto or esito == "fallita", l.id .. ": doing nothing doesn't finish it")
	end
	-- each star says what it needs, and the goal can be read
	check(#missioni.criteri(l) == 3, l.id .. ": three star criteria")
	if type(l.obiettivo) == "table" then
		local r = missioni.nuova(l.id)
		check(missioni.obiettivo(r) ~= nil, l.id .. ": the goal is visible")
	end
end
end

-- In chapter 0 no healing circles: after four turns doing nothing there are none
do
	local _, _, g = gioca("guidata", function(c)
		for _ = 1, 3 do
			c.hold(DESTRA, 1)
			c.turno()
		end
	end, nil, 60 * 30 * 12)
	check(#g.heals == 0 and g.turn_no >= 4, "lessons: no healing circles")
end

-- Primi passi: flag, step, the crate with the Lanciarune, the target.
-- No timer or turns; without the crate you can't shoot; whoever misses retries at once
local function to_target(c)
	c.hold(DESTRA, until_x(1075))
	c.hold({ right = true, jump = true }, 40)
	c.hold(DESTRA, until_x(1180))
	-- the crate drops on the step: go to meet it
	c.hold(DESTRA, function(g) return g.robots[1].x >= 1260 or g.robots[1].disarmed == nil end)
	c.hold(FERMO, function(g) return g.robots[1].disarmed == nil end)
end
do
	local esito, r, g = gioca("primi_passi", function(c)
		c.hold(DESTRA, until_x(1000))
		c.usa("missile", 0.5, 0.6)
		c.hold(FERMO, 60 * 60)
	end)
	check(esito == nil and r.st.steps_done[1] and not r.st.steps_done[2], "primi_passi: walking alone doesn't get you up the step")
	check(g.turn_no == 1 and g.current == 1, "primi_passi: no turns, even after a minute")
	check(not g.projectile and #g.crates == 0 and not game.has_weapon(g.robots[1], "missile") and not g:can_use("missile"),
		"primi_passi: without the crate no weapons")
end
local ok, r, a, p = search("primi_passi", function(c, a, p)
	to_target(c)
	c.usa("missile", a, p)
end, nil, { 0.1, 1.3, 0.05 }, potenze(0.3, 1, 0.1))
check(ok, "primi_passi: flag, step, crate and the target with the Lanciarune")
if ok then
	check(missioni.vede(r, "missile") and missioni.quante(missioni.stelle(r)) == 3, "primi_passi: three stars at the first shot")
	-- a missed shot (towards the sky behind you): retry at once, in the same turn
	local outcome2, r3, g3 = gioca("primi_passi", function(c)
		to_target(c)
		c.usa("missile", 2.6, 0.3)
		c.hold(FERMO, function(gg) return not gg.used.primary end)
		c.usa("missile", a, p)
	end)
	check(outcome2 == "fatta" and r3.st.conta.misses == 1 and g3.turn_no == 1, "primi_passi: whoever misses retries at once")
	check(missioni.quante(missioni.stelle(r3)) == 2, "primi_passi: one missed shot, two stars")
end

local ok, r, a, p, esito, g
-- Il turno: the Lanciarune at once (orbs), the Lama, the orb onto the island,
-- the target there falls at the first hit, the barter, and the next turn from
-- the first one again
local function island_turn(c)
	c.usa("missile", 2.5, 0.3)
	c.hold(FERMO, 20)
	c.usa("sword", 0)
	c.hold(FERMO, 60)
	c.usa("teleport", 0.5, 0.6)
	c.hold(FERMO, function(g) return g.robots[1].x > 1150 and g.robots[1].grounded end)
end
ok, r = search("turno", function(c, a, p)
	island_turn(c)
	c.turno()
	c.hold(DESTRA, function(g) return g.robots[1].x >= g.robots[3].x - 50 end)
	c.usa("sword", 0)
	c.hold(FERMO, function() return c.r.st.steps_done[4] end)
	c.usa("swap")
	c.hold(FERMO, 20)
	c.turno()
	c.usa("teleport", math.pi - a, p)
	c.hold(FERMO, function(g) return g.robots[1].x < 900 and g.robots[1].grounded end)
	c.hold(SINISTRA, function(g) return g.robots[1].x <= g.robots[2].x + 60 end)
	c.usa("sword", math.pi)
end, nil, { 0.3, 0.8, 0.1 }, potenze(0.3, 1, 0.1))
check(ok, "turno: orbs, the Lama, the island, the barter and back to the first")
if ok then
	check(missioni.quante(missioni.stelle(r)) == 3, "turno: without mistakes, three stars")
end
do
	-- without attacking time stops before you lose the two orbs
	local _, r2, g2 = gioca("turno", function(c)
		c.hold(DESTRA, 1)
		c.hold(FERMO, 60 * 30)
		c.usa("missile", 2.5, 0.3)
		c.hold(FERMO, 30)
	end)
	check(g2.turn_no == 1 and r2.st.conta.globi == 2, "turno: time waits for the first attack, with the two orbs")
	-- before the right step everything else is disabled: no teleport or Lama
	local _, r3, g3 = gioca("turno", function(c)
		c.usa("teleport", 0.6, 0.8)
		c.usa("sword", 0)
		c.hold(FERMO, 30)
	end)
	check(not r3.st.steps_done[2] and #g3.orbs == 0 and not g3.used.secondary, "turno: only what the step says can be used")
	-- a missed Lama comes back at once, and you where you were: then it hits
	local outcome4, r4, g4 = gioca("turno", function(c)
		c.usa("missile", 2.5, 0.3)
		c.hold(FERMO, function(g) return not g.projectile end)
		c.hold(SINISTRA, 60)
		c.usa("sword", math.pi)
		c.hold(FERMO, function(g) return not g.used.secondary end)
		c.hold(DESTRA, until_x(600))
		c.usa("sword", 0)
		c.hold(FERMO, 30)
	end)
	check(r4.st.steps_done[2] and r4.st.conta.misses == 1 and g4.turn_no == 1, "turno: a missed Lama is retried in the same turn")
	-- the Lama card waits for the missile to land, and a moment after
	local early_attack, late
	gioca("turno", function(c)
		c.usa("missile", 2.5, 0.3)
		c.hold(FERMO, 2)
		early_attack = c.r.opened[1]
		c.hold(FERMO, function(g) return not g.projectile end)
		c.hold(FERMO, 30)
		late = c.r.opened[1]
	end)
	check(not early_attack and late, "turno: the Lama card after the missile has landed")
	-- the downed island target doesn't respawn
	local _, _, g5 = gioca("turno", function(c)
		island_turn(c)
		c.turno()
		c.hold(DESTRA, function(g) return g.robots[1].x >= g.robots[3].x - 50 end)
		c.usa("sword", 0)
		c.hold(FERMO, 300)
	end)
	check(g5.robots[3].dead and g5.robots[3].gone and not g5.robots[2].dead, "turno: the downed island target doesn't respawn")
	-- wasted orbs come back: thrown into the void, you respawn as you were with your orbs
	local _, r6, g6 = gioca("turno", function(c)
		c.usa("missile", 2.5, 0.3)
		c.hold(FERMO, 20)
		c.usa("sword", 0)
		c.hold(FERMO, 60)
		c.usa("teleport", math.pi - 0.3, 1)
		c.hold(FERMO, function(g) return g.robots[1].dead end)
		c.hold(FERMO, function(g) return not g.robots[1].dead end)
		c.hold(FERMO, 10)
	end)
	local rb6 = g6.robots[1]
	check(r6.st.steps_done[2] and not r6.st.steps_done[3] and rb6.teleports_left == 2 and g6:can_use("teleport")
		and math.abs(rb6.x - r6.saved.x) < 2, "turno: fell with the orb, respawn as you were, with the orbs")
	-- and wasted without falling: Ritenta, and you're back as you were
	local _, r7, g7 = gioca("turno", function(c)
		c.usa("missile", 2.5, 0.3)
		c.hold(FERMO, 20)
		c.usa("sword", 0)
		c.hold(FERMO, 60)
		for _ = 1, 2 do
			c.usa("teleport", math.pi / 2, 0.2)
			c.hold(FERMO, function(g) return #g.orbs == 0 and g.robots[1].grounded end)
		end
		c.hold(FERMO, 80)
	end)
	check(not r7.st.steps_done[3] and g7.robots[1].teleports_left == 2 and g7:can_use("teleport")
		and r7.st.conta.misses == 1, "turno: without orbs for the island, Ritenta and they come back")
end

-- Weapons that move you: the Tonante downwards carries you onto the first
-- pillar, the Maglio coming down bounces you onto the second, the Affondo hits the target
ok, r = search("spostano", function(c, a, p)
	c.cassa("eagle")
	c.hold(DESTRA, until_x(975))
	c.hold({ jump = true, right = true }, 30)
	c.usa("eagle", -math.pi / 2 - 0.2)
	c.hold(DESTRA, function(g) return g.robots[1].grounded end)
	c.hold(FERMO, 10)
	c.cassa("mallet")
	c.hold(SINISTRA, function(g) return g.robots[1].x <= 1080 end)
	c.hold({ jump = true }, 10)
	c.hold(FERMO, function(g) return g.robots[1].vy < 0 and g.robots[1].y < 263 + a end)
	c.usa("mallet", 0)
	c.hold(DESTRA, function(g) return g.robots[1].grounded and g.robots[1].y > 400 end)
	c.hold(FERMO, 10)
	c.cassa("lunge")
	c.usa("lunge", 0)
end, nil, { 10, 30, 10 })
check(ok, "spostano: Tonante, Maglio and Affondo carry you to the target")
if ok then check(missioni.quante(missioni.stelle(r)) == 3, "spostano: without mistakes, three stars") end
esito = gioca("spostano", function(c)
	c.cassa("eagle")
	c.hold(DESTRA, until_x(960))
	for _ = 1, 10 do
		c.hold({ right = true, jump = true }, 12)
		c.hold(DESTRA, 30)
	end
end)
check(esito ~= "fatta", "spostano: just jumping doesn't get you up")
-- Rampino and parachute: no crates, the cards open after the steps. The
-- Rampino carries you onto the platform, the parachute past the void, the Lama on the target
local function tools_on(c)
	c.hold(DESTRA, until_x(860))
	c.hold(FERMO, 10)
	c.usa("hook", 1)
	c.hold(FERMO, function(g) return g.robots[1].grounded and g.robots[1].y > 300 end)
	c.hold(FERMO, 10)
end
ok, r = search("attrezzi", function(c, a)
	tools_on(c)
	c.hold(DESTRA, function(g) return g.robots[1].x > 1222 and not g.robots[1].grounded end)
	c.usa("parachute", 0, 1)
	c.hold(DESTRA, function(g) return g.robots[1].grounded end)
	c.hold(DESTRA, function(g) return g.robots[1].x >= g.robots[2].x - 50 end)
	c.usa("sword", a)
end, nil, { 0, 0, 1 })
check(ok, "attrezzi: Rampino and parachute carry you to the other side, the Lama on the target")
if ok then check(missioni.quante(missioni.stelle(r)) == 3, "attrezzi: without mistakes, three stars") end
esito, r, g = gioca("attrezzi", function(c)
	c.hold(DESTRA, until_x(860))
	for _ = 1, 10 do
		c.hold({ right = true, jump = true }, 12)
		c.hold(DESTRA, 30)
	end
end)
check(not r.st.steps_done[3] and r.prese.hook, "attrezzi: the Rampino arrives without a crate, and jumping doesn't get you up")
esito, r, g = gioca("attrezzi", function(c)
	tools_on(c)
	c.hold(DESTRA, 600)
end)
check(not r.st.steps_done[5] and g.robots[1].deaths > 0 and r.prese.parachute, "attrezzi: without opening the parachute you fall into the void")

-- Giù dal bordo: each of the three targets is knocked off its rock with a single missile
for chi = 2, 4 do
	local found, giu = false, false
	for a = -0.5, 3.6, 0.05 do
		for p = 0.2, 1, 0.05 do
			if not found then
				local _, r, g = gioca("giu_dal_bordo", function(c)
					c.usa("missile", a, p)
					c.hold(FERMO, 400)
				end, nil, 420)
				found = g.robots[1].env_kills > 0 and g.robots[chi].deaths > 0
				-- knocked off it stays down (Sergio, 30 Oct)
				if found then giu = g.robots[chi].gone or r.giu[chi] end
			end
		end
	end
	check(found, "giu_dal_bordo: target " .. chi .. " falls with one shot")
	check(giu, "giu_dal_bordo: target " .. chi .. " knocked off doesn't respawn")
end

-- Giù dal bordo with the Rampino: from the edge of the platform the hook
-- reaches the side rocks (map unchanged, reach config.HOOK.range) and the
-- target, pulled by reel and released over the void, falls
for chi, lato in pairs({ [2] = -1, [3] = 1 }) do
	local found = false
	for a = 0, 0.6, 0.02 do
		if not found then
			local angolo = lato < 0 and math.pi - a or a
			local _, _, g = gioca("giu_dal_bordo", function(c)
				c.hold(lato < 0 and SINISTRA or DESTRA, function(g2)
					local x = g2.robots[1].x
					return lato < 0 and x <= 775 or lato > 0 and x >= 1145
				end)
				c.hold(FERMO, 10)
				c.usa("hook", angolo)
				c.hold(FERMO, 300)
			end, nil, 900)
			found = g.robots[1].env_kills > 0 and g.robots[chi].deaths > 0
		end
	end
	check(found, "giu_dal_bordo: from the edge the Rampino catches target " .. chi .. " and knocks it off")
end

-- Punti e Corona: the Mantice throws the first target into the void, then two Pugni on whoever has the Crown
ok, r = search("punti", function(c, a)
	c.cassa("bellows")
	c.hold(SINISTRA, function(g) return g.robots[1].x <= a end)
	c.usa("bellows", math.pi)
	c.hold(FERMO, 200)
	c.cassa("punch")
	c.hold(DESTRA, until_x(975))
	for _ = 1, 2 do
		c.usa("punch", 0.3)
		c.hold(FERMO, 200)
	end
end, nil, { 310, 350, 20 })
check(ok, "punti: the Mantice knocks off, the Pugno downs whoever has the Crown")
if ok then check(missioni.quante(missioni.stelle(r)) == 3, "punti: without mistakes, three stars") end
-- the downed target no longer needed stays down (Sergio, 30 Oct)
esito, r, g = gioca("punti", function(c)
	c.cassa("bellows")
	c.hold(SINISTRA, function(g) return g.robots[1].x <= 330 end)
	c.usa("bellows", math.pi)
	c.hold(FERMO, 300)
end)
check(r.st.steps_done[2] and g.robots[2].gone and g.robots[2].dead, "punti: the target knocked off doesn't respawn")
esito, r = gioca("punti", function(c)
	c.cassa("bellows")
	c.hold(SINISTRA, 600)
end)
check(not r.st.steps_done[2], "punti: pushing on foot nobody falls")

-- The guided match: the timer waits for the controls to be touched, the
-- tutorial bot shows the two attacks and then the teleport in its first
-- turns, the match lasts 3 minutes. The player fires one missile per turn.
do
	local replay = require "sim.replay"
	local r = missioni.nuova("guidata")
	local seed, mappa, opts = missioni.partita(r, 5)
	local ric = replay.nuova(seed, mappa, opts)
	local g, bots = replay.partita(ric)
	missioni.prepara(r, g)
	local visti, ticks, esito, fermo = {}, 0, nil, nil
	while not esito and ticks < 60 * 60 * 6 do
		ticks = ticks + 1
		local input = {}
		if g.current == 1 and g.phase == "aim" and not g.used.primary then
			-- on the first turn wait 30 s before shooting
			if r.st.turni == 1 and ticks < 1800 then
				fermo = g.timer
			else
				input = { fire = { weapon = "missile", angle = 0.6, power = 0.8 } }
				missioni.tocca(r)
			end
		end
		if not (r.st.turni == 1 and ticks < 1800) then obey(r, input) end
		g:step(replay.input(ric, g, bots, input))
		for _, e in ipairs(g:pop_events()) do
			missioni.evento(r, g, e, bots)
			if e.robot == 2 then visti[r.st.bot_turns .. e.type] = true end
		end
		esito = missioni.tick(r, g)
	end
	check(fermo == game.TURN_TICKS, "guidata: on the first turn the timer waits for the controls to be touched")
	check(visti["1swing"] or visti["1mallet"] or visti["1eagle"] or visti["1lunge"],
		"guidata: on its first turn the bot also uses the secondary")
	check(visti["2teleports"] and visti["2teleport"], "guidata: on its second turn the bot earns orbs and teleports")
	check(esito == "fatta" and g.phase == "over", "guidata: the short match ends")
	check(ticks < 60 * 60 * 5, "guidata: lasts less than 5 minutes (" .. math.floor(ticks / 60) .. " s)")
end

-- Due mani: after a failed first turn the bot goes back to its mission life
-- (28), not to 150: it can still be finished
do
	local r = missioni.nuova("due_mani")
	local seed, mappa, opts = missioni.partita(r, 3)
	local g = game.new(seed, mappa, opts)
	missioni.prepara(r, g)
	local rb = g.robots[2]
	rb.hp = 10
	missioni.evento(r, g, { type = "turn", robot = 2 })
	check(rb.hp == 46 and rb.max_hp == 46, "due_mani: the bot recovers to 46, not to normal life")
end
-- The weapons the Addestramento doesn't introduce: in Primo sangue the Uovo,
-- in Due mani the Schegge, in a crate near you. Walking over it you take it,
-- and it's a single shot (it doesn't come back as in the lessons)
for _, m in ipairs({ { "primo_sangue", "grenade" }, { "due_mani", "shards" } }) do
	local _, r, g = gioca(m[1], function(c) c.cassa(m[2]) end, nil, 60 * 20)
	local rb = g.robots[1]
	check(r.prese[m[2]] and rb.ammo[m[2]] == 1, m[1] .. ": the crate with the new weapon is taken by walking")
end
-- and whoever respawns does so with the mission life (Fuori portata: 40)
for _, l in ipairs(campagna.CAPITOLI[2].missioni) do
	if l.vita then
		local r = missioni.nuova(l.id)
		local seed, mappa, opts = missioni.partita(r, 3)
		local g = game.new(seed, mappa, opts)
		missioni.prepara(r, g)
		for i, v in pairs(l.vita) do
			check(g.robots[i].max_hp == v, l.id .. ": full life (and respawn life) is the mission's")
		end
	end
end

-- Each star with its criterion: with a small point lead and without dying
-- they are the first and third, not the second (and in the profile each star
-- earned stays)
do
	local r = missioni.nuova("primo_sangue")
	r.esito, r.st.distacco = "fatta", 40
	local s = missioni.stelle(r)
	check(s[1] and not s[2] and s[3], "stars: the bonus without the points lights the third and not the second")
	r.st.distacco = 160
	check(missioni.stelle(r)[2], "stars: the second with the point lead")
	local profilo = require "menu.profilo"
	local p = profilo.nuovo()
	profilo.missione(p, "primo_sangue", s)
	profilo.missione(p, "primo_sangue", { true, true, false })
	check(profilo.stelle_totali(p) == 3, "stars: in the profile each one earned stays")
end

-- No points in the lessons that aren't about them (Sergio, 31 Oct: they
-- distract from the exercise): nobody scores, not even by downing. Punti e
-- Corona and the Prima partita have them
for _, l in ipairs(campagna.CAPITOLI[1].missioni) do
	local r = missioni.nuova(l.id)
	local seed, mappa, opts = missioni.partita(r, 3)
	local g = game.new(seed, mappa, opts)
	missioni.prepara(r, g)
	local senza = not missioni.vede(r, "punti")
	check(g.no_points == senza, l.id .. (senza and ": no points" or ": with points"))
	g:hurt(g.robots[2], 999, g.robots[1], 0)
	local fatti = 0
	for _, e in ipairs(g:pop_events()) do
		if e.type == "points" then fatti = fatti + 1 end
	end
	check((fatti == 0) == senza and (g.robots[1].points == 0) == senza,
		l.id .. ": downing " .. (senza and "gives no points" or "gives points"))
end
check(missioni.vede(missioni.nuova("punti"), "punti") and missioni.vede(missioni.nuova("guidata"), "punti"),
	"punti and guidata have points")

-- The help after many losses: the Fabbro goes down a level and starts with
-- less life, but with a full bar (it doesn't show)
do
	local function fabbro(aiuto)
		local r = missioni.nuova("il_fabbro")
		local seed, mappa, opts = missioni.partita(r, 7, nil, aiuto)
		local g = game.new(seed, mappa, opts)
		missioni.prepara(r, g)
		return opts.players[2].bot, g.robots[2]
	end
	local liv, rb = fabbro(false)
	local help_level, help_rb = fabbro(true)
	check(liv == 5 and help_level == 3, "help: the bot goes down two grades")
	check(help_rb.hp < rb.hp and help_rb.hp == help_rb.max_hp, "help: less life, full bar")
end

print(failures == 0 and "\nall tests passed" or ("\n" .. failures .. " tests failed"))
os.exit(failures == 0 and 0 or 1)
