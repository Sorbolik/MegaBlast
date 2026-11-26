-- The Maestro: a bot that picks its move by playing it. Among the best
-- candidates the bot finds (b.scegli, sim/bot.lua) it copies the whole match
-- (terrain too), makes the move and has everyone play on with ordinary bots,
-- for a few turns and a few seeds (the same seeds for every candidate, so luck
-- weighs the same on all), and keeps the one that leaves its team furthest
-- ahead: match points plus a share of the life difference. It is the
-- backgammon "rollout": in a game with luck, playing on from a position says
-- what it is worth better than any rule written by hand. Measured in the arena
-- (tools/arena/maestro.py, 26 Nov 2026, 2v2 against grade 10): 96% with 5
-- candidates, 4 seeds and a whole round; 77% with 2 candidates, 1 seed and up to
-- the enemy's reply (the training's MAESTRO, bot.LEVELS.maestro).
--
--   b.scegli = master.chooser(opts)
--
-- opts: candidate (how many), semi (seeds), turni (stop at the start of the
-- n-th turn after; 0: a whole round, giri of them), vita (points per hit point
-- of difference), leggero (the bots on the copies search less), grado(team):
-- the level and weights of the bots that play on the copies, solo ("attacco" or
-- "riparo": only those choices), finto (plays the first anyway: the proof that
-- the copies don't touch the match), log(choice) for the arena's data, libero
-- (the arena's teacher: thinks without the work cap, all in one tick), primo
-- (seconds: only the turn's first attack, if at least that much turn is left),
-- tempo (seconds: no rollout with less time than this left to play), corto
-- (on the copy the turn ends as soon as the move has come to rest), stima
-- (the units a rollout costs, about: none if the time left isn't enough).
-- It thinks a little at a time like the bot (bot.work: the copies' ticks and
-- the thinking of their bots count), so the phone doesn't stop a frame.

-- sim/bot.lua requires this module when it makes a MAESTRO: this one takes it
-- when first used (bob refuses a circular require, as the Defold editor does)
local bot
local rng = require "sim.rng"

local M = {}

-- tables nobody writes during a match: shared by the copies
-- (events: not copied, the copy starts with none: who replays a recipe doesn't
-- take them, and the turns of the past would end the rollouts early)
local SHARE = { map = true, score = true, stats = true, terrain = true, events = true }

local function deep(v, memo)
	if type(v) ~= "table" then return v end
	local c = memo[v]
	if c then return c end
	c = {}
	memo[v] = c
	for k, x in pairs(v) do
		if type(x) == "table" and not SHARE[k] then c[k] = deep(x, memo) else c[k] = x end
	end
	local mt = getmetatable(v)
	if mt then setmetatable(c, mt) end
	return c
end

-- what a tick of the whole match costs, in the bot's units (a tick of its copies,
-- which have fewer things): measured, without JIT
local STEP_WORK = 12

-- cells copied per unit of work (the terrain is 230,400 cells)
local CELLS_PER_WORK = 400

-- A copy of g to play on: the terrain a piece at a time (b: whose work it is),
-- the match's generator changed with seed s (the coming crates aren't known)
-- and the crates on the ground with nothing inside, like the bot's copies
function M.copy(g, s, b)
	bot = bot or package.loaded["sim.bot"]
	local c = deep(g, {})
	local t = g.terrain:blank()
	local n = g.terrain.w * g.terrain.h
	local step = CELLS_PER_WORK * 50
	for i = 1, n, step do
		g.terrain:copy_cells(t, i, math.min(n, i + step - 1))
		if b and not b.libero then bot.work(b, 50) end
	end
	c.terrain = t
	c.events = {}
	c.rng = rng.new(s)
	for _ = 1, 4 do c.rng:next() end
	for _, k in ipairs(c.crates) do k.weapon = "hook" end
	return c
end

local function margin(g, team)
	local mine, others = 0, {}
	for _, rb in ipairs(g.robots) do
		if rb.team == team then mine = mine + rb.points else others[rb.team] = (others[rb.team] or 0) + rb.points end
	end
	local first
	for t = 1, 4 do
		if others[t] and (not first or others[t] > first) then first = others[t] end
	end
	return mine - (first or 0)
end

-- the team's life minus the others' average (the dead count 0)
local function lives(g, team)
	local mine, others, teams = 0, 0, {}
	for _, rb in ipairs(g.robots) do
		local hp = rb.dead and 0 or rb.hp
		if rb.team == team then mine = mine + hp else
			others = others + hp
			teams[rb.team] = true
		end
	end
	local n = 0
	for t = 1, 4 do
		if teams[t] then n = n + 1 end
	end
	return mine - others / math.max(1, n)
end

M.margin = margin

local function worth(g, team, o)
	return margin(g, team) + o.vita * lives(g, team)
end

local function rounded(x)
	local out = {}
	for k = 1, #x do out[k] = math.floor(x[k] * 10000 + 0.5) / 10000 end
	return out
end

local DEAD = coroutine.create(function() end)
coroutine.resume(DEAD)

-- Plays copy G on: robot me starts with move m already chosen (from the state
-- of bot b now), then everyone as a bot. Returns what it is worth at the end
-- and the features of the position as soon as the move has come to rest.
local function rollout(G, b, m, s, o, ref)
	local me = b.id
	local team = G.robots[me].team
	local bots = {}
	for k, rb in ipairs(G.robots) do
		local level, weights = o.grado(rb.team)
		local x = bot.new(k, level, s * 31 + k, weights)
		if o.leggero then
			local l = {}
			for kk, v in pairs(x.liv) do l[kk] = v end
			l.walk_ticks, l.powers = math.min(l.walk_ticks, 120), 2
			-- leggero 2: much less (a short walk, one power, no orb nor Grapple)
			if o.leggero == 2 then l.walk_ticks, l.powers, l.teletrasporto, l.rampino = 60, 1, false, false end
			-- leggero 3: the same search on foot, but no orb nor Grapple
			if o.leggero == 3 then l.teletrasporto, l.rampino = false, false end
			x.liv = l
		end
		bots[k] = x
	end
	local rb = bots[me]
	rb.turno, rb.sheltered, rb.inizio, rb.attacks, rb.piano = G.turn_no, b.sheltered, b.inizio, b.attacks, b.piano
	rb.stato, rb.attesa, rb.co, rb.scelta, rb.passo, rb.think_from = "pensa", b.attesa or 0, DEAD, m, 0, G.tick
	local x, moved, rounds, turns = nil, false, 0, 0
	local stop = G.tick + o.max_tick * math.max(1, o.giri)
	local idle = {}
	while G.phase ~= "over" and G.tick < stop do
		local before = bot.totale or 0
		local who = bots[G.current]
		G:step(who and bot.input(who, G) or idle)
		for _, e in ipairs(G:pop_events()) do
			if e.type == "turn" then
				turns = turns + 1
				if e.robot == me then rounds = rounds + 1 end
			end
		end
		-- the copies' bots think as they go: their work is the Maestro's (bot.totale
		-- counts it once more: it is only for measuring)
		if not o.libero then bot.work(b, STEP_WORK + (bot.totale or 0) - before) end
		if rb.stato ~= "pensa" then moved = true end
		local rest = G.current ~= me or (moved and (rb.stato == "fine" or rb.stato == "pensa") and bot.quiet(G))
		if o.log and not x and rest then
			x = rounded(bot.caratteristiche({ id = me }, ref, G, {}))
		end
		-- corto: once the move has come to rest the turn ends there (the rest of
		-- it isn't played: half the work, the enemy's reply is what counts)
		if o.corto and rest and G.current == me and G.phase == "aim" then G.timer = 0 end
		-- and the enemy's reply ends with its first attack, once all is still
		if o.corto and G.current ~= me and turns > 0 then
			local eb = bots[G.current]
			if eb.stato == "aspetta" then eb.fired = true end
			if eb.fired and eb.stato ~= "aspetta" and bot.quiet(G) then break end
		end
		if (o.turni > 0 and turns >= o.turni) or (o.turni == 0 and rounds >= o.giri) then break end
	end
	return worth(G, team, o), x
end

-- The first n different candidates: same weapon, angle, power and nearly the
-- same spot are the same move
local function same(a, c)
	return a.arma == c.arma and math.abs((a.ang or 0) - (c.ang or 0)) < 0.03 and math.abs((a.potenza or 0) - (c.potenza or 0)) < 0.03
		and math.abs(a.posto.x - c.posto.x) < 9 and math.abs(a.posto.y - c.posto.y) < 9
end

local function different(all, n)
	local out = {}
	for _, m in ipairs(all) do
		local new = true
		for _, c in ipairs(out) do
			if same(m, c) then
				new = false
				break
			end
		end
		if new then out[#out + 1] = m end
		if #out >= n then break end
	end
	return out
end

local DEFAULTS = { candidate = 2, semi = 1, turni = 2, giri = 1, vita = 0.5, max_tick = 6000 }

function M.chooser(opts)
	bot = bot or package.loaded["sim.bot"]
	local o = {}
	for k, v in pairs(DEFAULTS) do o[k] = v end
	for k, v in pairs(opts or {}) do o[k] = v end
	o.grado = o.grado or function() return "difficile" end
	return function(b, g, all, kind)
		if o.solo and o.solo ~= kind then return all[1] end
		-- primo: only the turn's first attack, while there is time (the second
		-- attack and the cover have the few seconds after the first: thinking
		-- there costs more than it gains)
		if o.primo and (kind ~= "attacco" or g.used.primary or g.used.secondary or g.window > 0 or g.timer < o.primo * 60) then
			return all[1]
		end
		-- tempo: not with fewer than these seconds left to play (the turn, or the window after the first attack)
		if o.tempo and (g.window > 0 and g.window or g.timer) < o.tempo * 60 then return all[1] end
		local cands = different(all, o.candidate)
		local n = #cands
		if n <= 1 then return cands[1] end
		-- stima (units a rollout costs): not if the time left to play isn't enough
		-- to think them all at the bot's pace (it would stand still, then play worse)
		if o.stima and not o.libero then
			local need = n * o.semi * o.stima / b.liv.lavoro + 60
			if (g.window > 0 and g.window or g.timer) < need then return cands[1] end
		end
		local team = g.robots[b.id].team
		-- one copy now: g goes on ticking while the Maestro thinks
		b.libero = o.libero
		local base = M.copy(g, 1, b)
		local ref = o.log and bot.world(g) or nil
		local v0 = worth(base, team, o)
		local q, xs = {}, {}
		for k = 1, n do
			local sum = 0
			for s = 1, o.semi do
				-- the same seeds for every candidate
				local seed = (base.tick * 977 + b.id * 131 + s * 7919) % 2147483647 + 1
				local v, x = rollout(M.copy(base, seed, b), b, cands[k], seed, o, ref)
				sum = sum + v - v0
				if s == 1 then xs[k] = x or false end
			end
			q[k] = sum / o.semi
		end
		local best = 1
		for k = 2, n do
			if q[k] > q[best] then best = k end
		end
		if o.finto then best = 1 end
		if o.log then
			local points = {}
			for k = 1, n do points[k] = cands[k].punti end
			o.log({ tipo = kind, chi = b.id, t = g.tick, q = q, punti = points, x = xs, scelta = best,
				arma = cands[best].arma or "riparo" })
		end
		return cands[best]
	end
end

return M
