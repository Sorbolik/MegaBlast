-- Opponent bot: it plays a robot's turn by pressing the same keys as a
-- player (game:step's input), so it doesn't cheat and works online too.
-- Pure, deterministic Lua (randomness comes from its own generator): the
-- phone uses it (matches against bots), so do the arena (tools/arena)
-- and the server, to fill the queues.
--
--   local bot = require "sim.bot"
--   local b = bot.new(id, "normale", seed, pesi, carattere)   -- robot id, level (or grade, M.GRADES), seed, weights and personality (optional, see M.PESI and M.PERSONALITIES)
--   local input = bot.input(b, g)           -- every tick, before g:step(input)
--   bot.choose(d, i, seed, armi)            -- primary and secondary in the draft (sim/draft.lua)
--   b.piano = { due_attacchi = true }       -- (optional, for the coming turn) primary and secondary
--   b.piano = { attacca_entro = 4, poi = "teletrasporto" }  -- attacks once within 4 s, then teleports to cover
--   { id = i, script = function(g) return keys end }  -- a robot moved by a script instead (sim/missions.lua)
--
-- How it thinks: it tries moves on copies of the match (bot.world), with the
-- game's own physics (game:advance) but no craters, so it knows what really
-- happens. It tries where to go walking and jumping (and with the teleport),
-- from there the weapons it has against each opponent, and picks the move
-- worth the most match points (config.SCORE). It thinks a little at a time:
-- a work cap per tick (level.lavoro), so the phone doesn't stutter.

local game = require "sim.game"
local C = require "sim.config"
local rng = require "sim.rng"
local net = require "sim.rete"

local M = {}

-- Levels. reazione: ticks before acting; mira and potenza: maximum error
-- (radians, fraction); sbaglia: chance of picking a move worse than the best;
-- cammino: path ticks tried per side; potenze: how many powers it tries for
-- arc shots; teletrasporto, rampino, oggetti: whether it uses them; lavoro:
-- simulation ticks tried per game tick; manca: every other attack misses on
-- purpose (aim tried on the copy so that it doesn't hit); think_max (none
-- here, the server sets it, server/net.lua): game ticks of thinking after
-- which it plays the best move found so far instead of standing still.
-- tutorial: the guided match's "teacher" bot, which must be beaten.
M.LEVELS = {
	tutorial = { reaction = 90, mira = 0.02, potenza = 0.02, sbaglia = 0, walk_ticks = 200, powers = 2,
		teletrasporto = false, rampino = false, oggetti = false, lavoro = 400, manca = true },
	facile = { reaction = 80, mira = 0.09, potenza = 0.08, sbaglia = 0.4, walk_ticks = 150, powers = 2,
		teletrasporto = false, rampino = false, oggetti = false, lavoro = 400 },
	normale = { reaction = 45, mira = 0.035, potenza = 0.03, sbaglia = 0.15, walk_ticks = 300, powers = 3,
		teletrasporto = true, rampino = true, oggetti = false, lavoro = 400 },
	difficile = { reaction = 20, mira = 0.008, potenza = 0.008, sbaglia = 0, walk_ticks = 420, powers = 5,
		teletrasporto = true, rampino = true, oggetti = true, lavoro = 400 },
}
M.ORDER = { "facile", "normale", "difficile" }

-- The campaign grades (Sergio, 30 October 2026: "vorrei sentire una bella
-- progressione graduale"): a level, the fields that change (liv) and the weights.
-- Crates (Sergio, 2 November 2026): up to grade 4 the bots leave them to
-- you, 5 and 6 take them only when they are within easy reach (half weight),
-- from 7 they contest them like the bots outside the campaign (M.PESI).
-- Measured in pairs, 1 vs 1, 300 matches (2 November, with crates): each
-- grade beats the one below (2/1 52%, 3/2 58%, 4/3 59%, 5/4 76%, 6/5 66%,
-- 7/6 58%; from 30 October, without crates: 8/7 59%, 9/8 56%; 10 is
-- evolvi.py's brawler, 54% against hard). The biggest jumps are the orb
-- (easy never uses it) and the crates (from 5).
-- In the campaign players[i].bot can be the grade's number.
local brawler = {}
for k, v in pairs(C.SCORE) do brawler[k] = v end
brawler.env_kill, brawler.kill, brawler.damage = C.SCORE.env_kill * 1.86, C.SCORE.kill * 1.57, C.SCORE.damage * 0.94
M.GRADES = {
	{ livello = "tutorial", pesi = { cassa = 0, cassa_fame = 0 } },
	{ livello = "facile", pesi = { cassa = 0, cassa_fame = 0 } },
	{ livello = "facile", liv = { teletrasporto = true }, pesi = { teletrasporto = 20, cassa = 0, cassa_fame = 0 } },
	{ livello = "facile", liv = { teletrasporto = true }, pesi = { teletrasporto = 50, cassa = 0, cassa_fame = 0 } },
	{ livello = "facile", liv = { teletrasporto = true, rampino = true, mira = 0.06, sbaglia = 0.3 },
		pesi = { teletrasporto = 50, cassa = 6, cassa_fame = 4 } },
	{ livello = "normale", liv = { mira = 0.055, potenza = 0.05, sbaglia = 0.25 }, pesi = { cassa = 6, cassa_fame = 4 } },
	{ livello = "normale" },
	{ livello = "normale", liv = { mira = 0.02, potenza = 0.015, sbaglia = 0.05, oggetti = true } },
	{ livello = "difficile" },
	{ livello = "difficile", pesi = { vita_mia = 0.12, vita_compagno = 2.77, morte = 77, strada = 0.0025, teletrasporto = 119,
		globo_riparo = 8.9, punteggio = brawler, armi = { punch = 1.51, mallet = 1.51, lunge = 1.51, sword = 1.51,
		sniper = 0.5, missile = 0.5, grenade = 0.5, shards = 0.5, eagle = 0.5, bellows = 1.09 } } },
}

-- The bot's weights: what a move's outcome is worth besides match points.
-- The keys stay Italian: the arena saves them (tools/arena, specialists' JSON).
-- vita_mia, vita_compagno: per hit point lost; morte: on top of the score, if
-- it or a teammate dies; strada: what a path tick costs (for the same shot,
-- the nearer one); teletrasporto: below this score from the path on foot it
-- tries the teleport (100 since 29 October: the learning net teleported much
-- more than the bot and won, and with 100 the bot beats the previous one in
-- 72% of the matches); globo_riparo: cover with the orb beats cover on foot
-- if it is worth at least this much more; punteggio (if set): the points the
-- bot judges moves by, instead of the match's; armi (if set): the taste for
-- each weapon (multiplies the shots that pay and guides the match-start
-- draft, M.choose). The arena evolves them (tools/arena/evolvi.py) and a
-- match can give each bot others (players[i].pesi, only the fields that
-- change). rete (if set): a neural net (sim/rete.lua) that judges moves
-- instead of these weights, from the features of the position after the move
-- (M.caratteristiche); tools/arena/impara.py trains it;
-- esplora: chance of picking on purpose one of the moves after the best;
-- cassa: what taking a crate is worth (in match points), plus cassa_fame
-- for each shot that robot is short of HUNGER (crate primaries and chosen
-- secondary: whoever runs dry wants it more).
M.PESI = { vita_mia = 0.6, vita_compagno = 1, morte = 60, strada = 0.01, teletrasporto = 100, globo_riparo = 3,
	cassa = 12, cassa_fame = 8 }

-- Personalities: how a bot plays, besides its level (how good it is). They
-- are only weights different from M.PESI, so the bot doesn't cheat: it always
-- presses a player's keys. The campaign uses them (sim/levels.lua,
-- players[i].carattere) and so do the circles' keepers; their names are ids.
-- codardo: every turn attacks at once (so it earns the orbs) and then flees
-- with the orb to the worst den, covered and where nobody sees it (tana: how
-- much that counts; piano: every turn's plan); testa_calda: charges in even
-- at the cost of dying; cecchino: shoots from where it is and walks little;
-- spingitore: looks for the void (an environment kill is worth triple).
local push_scoring = {}
for k, v in pairs(C.SCORE) do push_scoring[k] = v end
push_scoring.env_kill = C.SCORE.env_kill * 3
M.PERSONALITIES = {
	codardo = { vita_mia = 2, morte = 120, teletrasporto = 225, den = 12,
		piano = { attacca_entro = 4, poi = "teletrasporto" } },
	testa_calda = { vita_mia = 0.15, morte = 15, strada = 0.004 },
	cecchino = { strada = 0.05, teletrasporto = 25 },
	spingitore = { punteggio = push_scoring },
}
-- moves tried to the end (until everything is still) among the best
local FINALISTS = 4
-- below how many shots (crate primaries and secondary) a crate is worth more
local HUNGER = 2
local POWER_STEPS = { 1, 0.75, 0.55, 0.88, 0.42 }

local IDLE = {}

-- Match copies ---------------------------------------------------------------------

local function copy(t)
	local o = {}
	for k, v in pairs(t) do o[k] = v end
	return o
end

-- dst becomes a copy of src (its old keys go): reusing dst instead of a new
-- table, the thinking doesn't fill Lua's memory with garbage (about 10 KB per
-- copy of the match, hundreds of copies per second; docs/prestazioni.md, Fase 2)
local function refill(dst, src)
	for k in pairs(dst) do dst[k] = nil end
	for k, v in pairs(src) do dst[k] = v end
	return dst
end

-- The tables a reused copy owns (lists, the robots' sub-tables), kept beside
-- it so the copy itself has exactly the fields of the original
local OWN = setmetatable({}, { __mode = "k" })
local function own(t, fresh)
	local o = OWN[t]
	if not o then
		o = fresh()
		OWN[t] = o
	end
	return o
end
local function robot_parts() return { ammo = {}, life_damage = {}, status = {}, hooked = {}, hook_shot = {} } end

-- A robot's copy; into: a copy made before, to overwrite
local function clone(rb, into)
	local c = into or {}
	local o = own(c, robot_parts)
	refill(c, rb)
	c.ammo = refill(o.ammo, rb.ammo)
	c.life_damage = refill(o.life_damage, rb.life_damage)
	local st = o.status
	for k in pairs(st) do st[k] = nil end
	for k, v in pairs(rb.status) do st[k] = copy(v) end
	c.status = st
	if rb.hooked then c.hooked = refill(o.hooked, rb.hooked) end
	if rb.hook_shot then c.hook_shot = refill(o.hook_shot, rb.hook_shot) end
	return c
end

-- In the copies the explosion doesn't dig: the terrain is the real one, shared
local function no_crater(self, x, y, owner, blast, weapon)
	blast = blast or game.MISSILE_BLAST
	self:emit({ type = "explosion", x = x, y = y, r = blast.r })
	self:blast(x, y, owner, blast, weapon)
end

local function world_parts()
	return { robots = {}, orbs = {}, placed = {}, pools = {}, shards = {}, crates = {}, events = {}, used = {}, rng = rng.new(1) }
end

-- a list of copies of src's items, in the reused list dst
local function copies(dst, src)
	for i = #dst, #src + 1, -1 do dst[i] = nil end
	for i, v in ipairs(src) do dst[i] = copy(v) end
	return dst
end

-- A copy of the match to try moves on: robots, shots, items, crates and
-- generator are copied, the terrain is shared but never touched. The turn
-- rules (end of turn, new crates, heals) don't run: it uses game:advance.
-- The copied crates hold nothing ("hook": game.dai gives nothing), because
-- the bot mustn't know what they contain. into: a copy made before (by the
-- same caller, no longer used), overwritten instead of making a new one.
function M.world(g, into)
	local w = into or setmetatable({}, game)
	local o = own(w, world_parts)
	for k in pairs(w) do w[k] = nil end
	w.terrain, w.map, w.tick, w.mode, w.normalized = g.terrain, g.map, g.tick, g.mode, g.normalized
	w.current, w.phase, w.timer, w.window, w.turn_bonus = g.current, g.phase, g.timer, g.window, g.turn_bonus
	w.match_left, w.final_round, w.round, w.order, w.order_pos, w.turn_no = g.match_left, g.final_round, g.round, g.order, g.order_pos, g.turn_no
	w.orb_seq, w.placed_id, w.heals, w.score = g.orb_seq, g.placed_id, g.heals, g.score
	w.gravity, w.mud = g.gravity, g.mud
	o.rng.state = g.rng.state
	w.rng = o.rng
	w.used = refill(o.used, g.used)
	local events = o.events
	for i = #events, 1, -1 do events[i] = nil end
	w.events = events
	local crates = o.crates
	for i = #crates, #g.crates + 1, -1 do crates[i] = nil end
	for i, c in ipairs(g.crates) do
		local k = crates[i] or {}
		k.id, k.x, k.y, k.vy, k.landed, k.weapon = c.id, c.x, c.y, c.vy, c.landed, "hook"
		crates[i] = k
	end
	w.crates = crates
	local robots = o.robots
	for i = #robots, #g.robots + 1, -1 do robots[i] = nil end
	for i, rb in ipairs(g.robots) do robots[i] = clone(rb, robots[i]) end
	w.robots = robots
	w.orbs = copies(o.orbs, g.orbs)
	w.placed = copies(o.placed, g.placed)
	w.pools = copies(o.pools, g.pools)
	w.pool_id = g.pool_id
	local shards = o.shards
	for i = 1, game.SHARD_COUNT do
		shards[i] = g.shards[i] and copy(g.shards[i]) or nil
	end
	w.shards = shards
	w.projectile = g.projectile and copy(g.projectile)
	w.burst = g.burst and copy(g.burst)
	w.explode = no_crater
	-- the Trapano's tunnel doesn't dig either
	w.dig = function() return 0, 0 end
	return w
end

-- The copy of the match a bot reuses at one place of its thinking (slot):
-- each place has its own, and none outlives the function that asked for it
local function scratch(b, slot, g)
	local ws = b.worlds
	if not ws then
		ws = {}
		b.worlds = ws
	end
	local w = M.world(g, ws[slot])
	ws[slot] = w
	return w
end

-- All still: nothing in flight, robots on the ground and no shots under way
local function quiet(w)
	if w.projectile or w.burst or #w.orbs > 0 then return false end
	for i = 1, game.SHARD_COUNT do
		if w.shards[i] then return false end
	end
	for _, rb in ipairs(w.robots) do
		if not rb.dead and (not rb.grounded or rb.swing or rb.punch or rb.lunge or rb.recoil or rb.hooked or rb.hook_shot or rb.mallet
			or rb.cannon or rb.pull) then
			return false
		end
	end
	return true
end
M.quiet = quiet

-- Work: every try costs simulated ticks; when the tick's work is used up it
-- waits for the next tick (coroutine.yield). Outside a coroutine it never stops.
local function work(b, n)
	b.lavoro = b.lavoro + n
	-- overall, for the tests and for measuring
	M.totale = (M.totale or 0) + n
	if b.lavoro >= b.liv.lavoro and coroutine.running() then
		coroutine.yield()
	end
end

-- Runs the copy, for at most max ticks, until everything is still
local function until_quiet(b, w, max)
	local nr = #w.robots
	for t = 1, max do
		w.tick = w.tick + 1
		w:advance(IDLE, true)
		if t % 10 == 0 then
			work(b, 40 * nr)
			if quiet(w) then return t end
		end
	end
	return max
end

-- Only the shots in flight (robots stay still): where they burst and whom they hit
local function in_flight(b, w, max)
	for t = 1, max do
		w.tick = w.tick + 1
		if w.projectile then w:update_projectile() end
		if w.burst then w:update_burst() end
		w:update_shards()
		if not w.projectile and not w:shards_flying() then return t end
		if t % 10 == 0 then work(b, 10) end
	end
	return max
end

-- Is the terrain between two points clear? (in 9 px steps: enough to know
-- whether an enemy has a line of fire, and cheap)
local function clear_line(t, x0, y0, x1, y1)
	local dx, dy = x1 - x0, y1 - y0
	local n = math.floor(math.sqrt(dx * dx + dy * dy) / 9)
	for i = 1, n - 1 do
		if t:solid(x0 + dx * i / n, y0 + dy * i / n) then return false end
	end
	return true
end

-- How near the void is: of the points to the side (up to 96 px), how many
-- have no ground within 60 px below, from 0 to 1
local SIDES = { -96, -64, -36, -12, 12, 36, 64, 96 }
local function edge(t, x, y)
	local n = 0
	for _, d in ipairs(SIDES) do
		local gb = t:ground_below(x + d, y + 4)
		if not gb or y - gb > 60 then n = n + 1 end
	end
	return n / #SIDES
end

-- The features of copy w (after a move) against the real match g, for the
-- bot's robot: what the net looks at. Numbers near -1..1 (points and life in
-- hundreds, distances in thousands of pixels).
M.CARATTERISTICHE = 20
local function caratteristiche(b, g, w, x)
	local me = g.robots[b.id]
	local c = w.robots[b.id]
	for i = 1, M.CARATTERISTICHE do x[i] = 0 end
	local squads = {}
	for i, o in ipairs(w.robots) do
		local r = g.robots[i]
		local dp = o.points - r.points
		local lost = r.dead and 0 or (o.dead and r.hp or math.max(0, r.hp - o.hp))
		squads[o.team] = (squads[o.team] or 0) + o.points
		if i == b.id then
			x[1] = dp / 100
			x[4] = lost / 100
			x[7] = (o.dead and not r.dead) and 1 or 0
		elseif o.team == me.team then
			x[2] = x[2] + dp / 100
			x[5] = x[5] + lost / 100
			x[8] = x[8] + ((o.dead and not r.dead) and 1 or 0)
		else
			x[3] = x[3] + dp / 100
			x[6] = x[6] + lost / 100
			x[9] = x[9] + ((o.dead and not r.dead) and 1 or 0)
		end
	end
	-- the position after the move
	x[10] = c.dead and 0 or c.hp / 100
	local t = w.terrain
	local cy = c.y + game.DISEGNO_H / 2
	local near, sum, n, above, in_reach, seen_by = math.huge, 0, 0, 0, 0, 0
	for _, o in ipairs(w.robots) do
		if not o.dead and o.team ~= me.team then
			local dx, dy = o.x - c.x, o.y - c.y
			local d = math.sqrt(dx * dx + dy * dy)
			near = math.min(near, d)
			sum, n, above = sum + d, n + 1, above + dy
			if d < 200 then in_reach = in_reach + 1 end
			if d < 900 and clear_line(t, c.x, cy, o.x, o.y + game.DISEGNO_H / 2) then seen_by = seen_by + 1 end
		end
	end
	if n > 0 then
		x[11] = math.min(near, 1500) / 1000
		x[12] = sum / n / 1000
		x[13] = above / n / 500
	end
	x[14] = c.dead and 1 or edge(t, c.x, c.y)
	x[15] = in_reach
	x[16] = seen_by
	x[17] = math.min(c.x, game.WORLD_W - c.x) / 1000
	x[18] = c.y / game.WORLD_H
	-- the gap from the leading opposing team
	local first = -math.huge
	for _, team in ipairs({ 1, 2, 3, 4 }) do
		if team ~= me.team and squads[team] then first = math.max(first, squads[team]) end
	end
	x[19] = first > -math.huge and ((squads[me.team] or 0) - first) / 100 or 0
	x[20] = g.match_left / game.MATCH_TICKS
	return x
end
M.caratteristiche = caratteristiche

local FEAT_BUF = {}

-- How many counted shots rb has: the crate primaries and the chosen secondary
local function shots_left(rb)
	local n = 0
	for _, a in ipairs(game.CRATE_WEAPONS) do n = n + rb.ammo[a] end
	if rb.secondary then n = n + rb.ammo[rb.secondary] end
	return n
end

-- What the crates taken in copy w are worth to the bot (rb.crates goes up
-- with each crate): plus for its team, minus for the opponents
local function casse(b, g, w)
	local me = g.robots[b.id]
	local s = 0
	for i, c in ipairs(w.robots) do
		local r = g.robots[i]
		local n = c.crates - r.crates
		if n > 0 and not r.dead then
			local v = n * (b.pesi.cassa + b.pesi.cassa_fame * math.max(0, HUNGER - shots_left(r)))
			s = s + (c.team == me.team and v or -v)
		end
	end
	return s
end

-- What copy w is worth against the real match g, for the bot's robot
local function value(b, g, w)
	if b.pesi.rete then return net.evaluate(b.pesi.rete, caratteristiche(b, g, w, FEAT_BUF)) * 100 end
	local me = g.robots[b.id]
	local s = 0
	for i, c in ipairs(w.robots) do
		local r = g.robots[i]
		if not r.dead then
			local dp = c.points - r.points
			local lost = c.dead and r.hp or math.max(0, r.hp - c.hp)
			if c.team == me.team then
				s = s + dp - lost * (i == b.id and b.pesi.vita_mia or b.pesi.vita_compagno)
				if c.dead then s = s - b.pesi.morte end
			else
				s = s - dp
			end
		end
	end
	return s + casse(b, g, w)
end

-- Distance from the enemy nearest to (x, y): for the same damage, a shot
-- that lands near is worth a pinch more (so from afar it closes in too)
local function nearness(g, me, x, y)
	local best = math.huge
	for _, o in ipairs(g.robots) do
		if not o.dead and o.team ~= me.team then
			local dx, dy = o.x - x, o.y + game.HURT_Y - y
			best = math.min(best, dx * dx + dy * dy)
		end
	end
	return -math.sqrt(best) / 1000
end

-- Moves ----------------------------------------------------------------------------
-- A move: where to go (posto: x, y, strada) and what to do there
-- (arma, ang, potenza), with its score (punti).

-- Puts the bot's robot on the copy's spot, still on the ground, with the
-- crates it touched on the way (posto.casse: their ids)
local function at_spot(w, id, spot)
	local c = w.robots[id]
	if spot.strada then
		c.x, c.y, c.vx, c.vy = spot.x, spot.y, 0, 0
		c.grounded, c.knocked, c.rising = true, false, false
		c.facing = spot.facing
	end
	if spot.casse then
		for _, cid in ipairs(spot.casse) do
			for i, k in ipairs(w.crates) do
				if k.id == cid then
					table.remove(w.crates, i)
					c.crates = c.crates + 1
					break
				end
			end
		end
	end
	return c
end

-- Who would take the melee shot wpn aimed at ang right now: tries it on a
-- copy of the match until the shot ends. out[1..k] = ids of the robots hit,
-- returns k. For the melee weapons' aim (battle/aim.lua).
local HIT_EVENTS = { sword_hit = true, punch_hit = true, mallet_hit = true, lunge_hit = true, bellows_hit = true }
local HITS_WORLD
function M.hits(g, wpn, ang, out)
	-- the client asks it at every frame of aiming: always the same copy
	local w = M.world(g, HITS_WORLD)
	HITS_WORLD = w
	-- online the client's orbs come from the server with only id and position
	-- (no owner, speed or age): they can't fly in the copy, and the melee
	-- shot doesn't need them
	local orbs, n = w.orbs, 0
	for i = 1, #orbs do
		if orbs[i].owner then
			n = n + 1
			orbs[n] = orbs[i]
		end
	end
	for i = #orbs, n + 1, -1 do orbs[i] = nil end
	w:attack(wpn, { weapon = wpn, angle = ang, power = 1 })
	local rb = w.robots[w.current]
	for _ = 1, 4 * 60 do
		if not (rb.swing or rb.punch or rb.mallet or rb.lunge) then break end
		w.tick = w.tick + 1
		w:advance(IDLE, true)
	end
	local k = 0
	for _, e in ipairs(w.events) do
		if HIT_EVENTS[e.type] and e.target then
			k = k + 1
			out[k] = e.target
		end
	end
	return k
end

-- Tries an attack from the spot. fino: "volo" (only the shots) or "tutto"
-- (until everything is still). Returns the score, and whether it changed
-- anything that counts (points, crates, robots moved: value ~= 0).
local function try_move(b, g, spot, wpn, ang, pow, fino)
	local w = scratch(b, "move", g)
	w.score = b.pesi.punteggio or g.score
	work(b, 20)
	local c = at_spot(w, b.id, spot)
	local fire = { weapon = wpn, angle = ang, power = pow }
	if game.TOOLS[wpn] then w:use_tool(wpn, fire) else w:attack(wpn, fire) end
	local px, py = c.x, c.y
	if fino == "volo" and (w.projectile or w.burst) then
		in_flight(b, w, 6 * 60)
	else
		until_quiet(b, w, fino == "volo" and 90 or 5 * 60)
	end
	local s = value(b, g, w)
	local counts = s ~= 0
	if s == 0 and not b.pesi.rete then
		-- nothing hit: what counts is where it burst
		for _, e in ipairs(w.events) do
			if e.type == "explosion" then px, py = e.x, e.y end
		end
		s = nearness(g, g.robots[b.id], px, py)
	end
	return s, counts
end

-- The Grapple on enemy number who, then the best shot with the weapons in
-- list (straight at it, full power): what it is all worth together
local function try_hook(b, g, spot, ang, who, list)
	local w = scratch(b, "hook", g)
	w.score = b.pesi.punteggio or g.score
	work(b, 20)
	local c = at_spot(w, b.id, spot)
	w:use_tool("hook", { weapon = "hook", angle = ang, power = 1 })
	until_quiet(b, w, 3 * 60)
	local o = w.robots[who]
	local better = value(b, g, w)
	if c.dead or o.dead then return better end
	local a = math.atan2(o.y + game.HURT_Y - (c.y + game.DISEGNO_H / 2), o.x - c.x)
	for _, wpn in ipairs(list) do
		if w:can_use(wpn) then
			local w2 = scratch(b, "hook_then", w)
			work(b, 20)
			w2:attack(wpn, { weapon = wpn, angle = a, power = 1 })
			until_quiet(b, w2, 4 * 60)
			better = math.max(better, value(b, g, w2))
		end
	end
	return better
end

-- Angles to hit (dx, dy) leaving at speed v with gravity gr (the two
-- arcs, low and high)
local function arcs(dx, dy, v, gr, out)
	local v2 = v * v
	local disc = v2 * v2 - gr * (gr * dx * dx + 2 * dy * v2)
	if disc < 0 then return end
	local r = math.sqrt(disc)
	out[#out + 1] = math.atan2(v2 - r, gr * dx)
	out[#out + 1] = math.atan2(v2 + r, gr * dx)
end

-- Move order: the best first, on equal points the first found (table.sort
-- isn't stable and LuaJIT and gopher-lua order ties differently: without
-- this client and server would pick different moves)
local function ranks_before(x, y)
	if x.punti ~= y.punti then return x.punti > y.punti end
	return x.k < y.k
end

-- The arc weapons: top speed, gravity, aims at the centre or the feet
local ARC_WEAPONS = {
	missile = function(g) return game.MISSILE_SPEED, g.gravity * game.MISSILE_GRAVITY end,
	grenade = function(g) return game.GRENADE_SPEED, g.gravity * game.GRENADE_GRAVITY end,
	tar = function(g) return game.GRENADE_SPEED, g.gravity * game.GRENADE_GRAVITY end,
	petard = function(g) return game.GRENADE_SPEED, g.gravity * game.GRENADE_GRAVITY end,
	drill = function(g) return game.MISSILE_SPEED, g.gravity * game.MISSILE_GRAVITY end,
	trampoline = function(g) return game.GRENADE_SPEED, g.gravity * game.GRENADE_GRAVITY end,
}

-- The living opponents, nearest to the spot first
local function enemies(g, me, x, y)
	local out = {}
	for _, o in ipairs(g.robots) do
		if not o.dead and o.team ~= me.team then out[#out + 1] = o end
	end
	table.sort(out, function(a, c)
		local from, dc = (a.x - x) ^ 2 + (a.y - y) ^ 2, (c.x - x) ^ 2 + (c.y - y) ^ 2
		if from ~= dc then return from < dc end
		return a.id < c.id
	end)
	return out
end

-- The weapons the robot can use now in the real match (primaries and secondaries)
local function armi(g, rb)
	local out = {}
	local function take(w)
		if g:can_use(w) then out[#out + 1] = w end
	end
	take("missile")
	for _, w in ipairs(game.CRATE_WEAPONS) do take(w) end
	take("sword")
	if rb.secondary then take(rb.secondary) end
	return out
end

-- The taste for the weapon (pesi.armi, for the specialists): a shot that
-- pays is worth more the more the weapon is liked
local function taste(b, wpn, s)
	local g = b.pesi.armi and b.pesi.armi[wpn]
	if g and s > 0 then return s * g end
	return s
end

-- All the moves from a spot, tried quickly (only the flight for ranged
-- shots). Adds them to moves.
local function moves_from_spot(b, g, spot, weapon_list, moves)
	local me = g.robots[b.id]
	local x, y = spot.x, spot.y
	local cy = y + game.DISEGNO_H / 2
	local targets = enemies(g, me, x, y)
	local function add(wpn, a, p, fino)
		local s, counts = try_move(b, g, spot, wpn, a, p, fino)
		-- the Molla only if it does something (it isn't an attack: no aiming at nothing)
		if wpn == "trampoline" and not (counts and s > 0) then return end
		s = taste(b, wpn, s)
		moves[#moves + 1] = { posto = spot, arma = wpn, ang = a, potenza = p, punti = s - (spot.n or 0) * b.pesi.strada,
			k = #moves + 1 }
	end
	for k, o in ipairs(targets) do
		if k > 2 then break end
		local ox, oy = o.x, o.y + game.HURT_Y
		local dx, dy = ox - x, oy - cy
		local dist = math.sqrt(dx * dx + dy * dy)
		local straight = math.atan2(dy, dx)
		for _, wpn in ipairs(weapon_list) do
			local arc = ARC_WEAPONS[wpn]
			if arc then
				local v, gr = arc(g)
				local aim = { oy }
				-- the Uovo and the Molla at the feet; the Molla is tried to the end
				-- (where the robot it launches lands)
				if wpn == "grenade" or wpn == "trampoline" or wpn == "tar" or wpn == "petard" then aim = { o.y + 2 } end
				local fino = wpn == "trampoline" and "tutto" or "volo"
				for n = 1, b.liv.powers do
					local p = POWER_STEPS[n]
					for _, ty in ipairs(aim) do
						local angles = {}
						-- the muzzle is game.MUZZLE from the centre, in the shot's direction
						arcs(dx, ty - cy, v * p, gr, angles)
						for _, a in ipairs(angles) do
							local mx, my = math.cos(a) * game.MUZZLE, math.sin(a) * game.MUZZLE
							local right_ones = {}
							arcs(ox - x - mx, ty - cy - my, v * p, gr, right_ones)
							-- of the two arcs, the one on the same side (low or high)
							local g2 = right_ones[a == angles[1] and 1 or 2]
							if g2 then add(wpn, g2, p, fino) end
						end
					end
				end
			elseif wpn == "shards" then
				local angles = {}
				arcs(dx, dy, game.SHARD_SPEED, g.gravity * game.SHARD_GRAVITY, angles)
				if angles[1] then add(wpn, angles[1], 1, "volo") end
			elseif wpn == "sniper" then
				if dist < 900 then
					for _, up in ipairs({ 0, 0.05, 0.12, 0.2 }) do
						add(wpn, straight + (dx < 0 and -up or up), 1, "volo")
					end
				end
			elseif wpn == "eagle" then
				if dist < C.EAGLE.range then add(wpn, straight, 1, "tutto") end
			elseif wpn == "lunge" then
				if dist < C.LUNGE.speed * C.LUNGE.ticks / 60 + C.LUNGE.reach then
					add(wpn, straight, 1, "tutto")
					add(wpn, straight + (dx < 0 and -0.15 or 0.15), 1, "tutto")
				end
			elseif wpn == "bellows" then
				-- the gust: straight or slightly up, to lift it off the ground towards the void
				if dist < C.BELLOWS.range then
					add(wpn, straight, 1, "tutto")
					add(wpn, straight + (dx < 0 and -0.35 or 0.35), 1, "tutto")
				end
			elseif wpn == "boomerang" then
				if dist < C.BOOMERANG.range + 40 then add(wpn, straight, 1, "volo") end
			elseif wpn == "magnet" then
				-- the centre is C.MAGNET.distance along the aim: aim so that the enemy is inside the pulse
				if dist < C.MAGNET.distance + C.MAGNET.radius then add(wpn, straight, 1, "tutto") end
			elseif wpn == "cannon" then
				-- the flight at full power, towards the enemy or a bit above it
				if dist < 600 then
					add(wpn, straight, 1, "tutto")
					add(wpn, straight + (dx < 0 and -0.3 or 0.3), 1, "tutto")
				end
			elseif wpn == "mallet" then
				if math.abs(dx) < C.MALLET.reach + 30 and math.abs(dy) < C.MALLET.reach + 30 then
					-- the arc turns with the aim: straight and towards the enemy
					add(wpn, dx < 0 and math.pi or 0, 1, "tutto")
					add(wpn, straight, 1, "tutto")
				end
			elseif wpn == "sword" or wpn == "punch" then
				if dist < 80 then add(wpn, straight, 1, "tutto") end
			end
		end
	end
end

-- The crates resting on the ground in the real match that robot c touches
-- and that aren't in taken yet (list of ids): a new list with those too, or
-- taken if there are none (same rule as game:update_crates)
local function touches(g, c, taken)
	local fresh
	for _, k in ipairs(g.crates) do
		if k.landed and math.abs(c.x - k.x) <= game.ROBOT_HALF_W + game.CRATE_HALF_W
			and c.y < k.y + game.CRATE_H and c.y + game.ROBOT_H > k.y then
			local already = false
			for _, id in ipairs(taken) do
				if id == k.id then already = true end
			end
			if not already then
				if not fresh then
					fresh = {}
					for i, id in ipairs(taken) do fresh[i] = id end
				end
				fresh[#fresh + 1] = k.id
			end
		end
	end
	return fresh or taken
end

-- Spots reached walking (and jumping) from where it stands: two ways per
-- side (at edges it jumps or drops). Each spot has its path: the keys tick
-- by tick (dirs: -1, 0, 1; salti: true where it jumps).
local function spots_on_foot(b, g, max)
	local me = g.robots[b.id]
	local spots = { { x = me.x, y = me.y, facing = me.facing, n = 0 } }
	if max <= 0 or not me.grounded then return spots end
	local w = scratch(b, "on_foot", g)
	local hw = game.ROBOT_HALF_W
	for _, d in ipairs({ -1, 1 }) do
		for _, hop_edges in ipairs({ true, false }) do
			local c = clone(me, w.robots[b.id])
			local dirs, hops = {}, {}
			local road = { dirs = dirs, hops = hops }
			local input = { left = d < 0, right = d > 0, jump = false, hold = true }
			local idle_since, last_x = 0, c.x
			-- the crates touched on the way (in the real match it takes them walking)
			local taken, first_crate = {}, false
			for t = 1, max do
				local hop = false
				if c.grounded then
					if w:terrain_collides(c.x + d * 3, c.y + game.MAX_CLIMB) then
						hop = true
					elseif hop_edges then
						local gb = w.terrain:ground_below(c.x + d * (hw + 6), c.y + 2)
						if not gb or c.y - gb > 50 then hop = true end
					end
				end
				input.jump = hop
				dirs[t], hops[t] = d, hop
				w:update_robot(c, input, true)
				if c.dead or c.y < 40 then break end
				if math.abs(c.x - last_x) >= 1 then idle_since, last_x = t, c.x end
				if t - idle_since > 40 then break end
				if #g.crates > 0 then
					local p = touches(g, c, taken)
					if p ~= taken then first_crate, taken = true, p end
				end
				if c.grounded and (t % 6 == 0 or first_crate) then
					local is_new = true
					for _, p in ipairs(spots) do
						if math.abs(p.x - c.x) < 24 and math.abs(p.y - c.y) < 20 then
							is_new = false
							break
						end
					end
					if is_new or first_crate then
						spots[#spots + 1] = { x = c.x, y = c.y, facing = c.facing, n = t, strada = road,
							casse = #taken > 0 and taken or nil }
						first_crate = false
					end
				end
				if t % 10 == 0 then work(b, 40) end
			end
		end
	end
	return spots
end

-- The spot a teleport orb thrown now with (a, p) leads to, or nil
local function teleport_spot(b, g, a, p)
	local w = scratch(b, "orb", g)
	local c = w.robots[b.id]
	w:throw_orb(a, p)
	local t = 0
	while #w.orbs > 0 and t < 6 * 60 do
		t = t + 1
		w:update_orbs()
		if t % 10 == 0 then work(b, 10) end
	end
	for _ = 1, 3 * 60 do
		if c.grounded or c.dead then break end
		t = t + 1
		w:update_robot(c, IDLE, true)
		if t % 10 == 0 then work(b, 40) end
	end
	if c.dead or not c.grounded or c.y < 60 then return nil end
	local taken = #g.crates > 0 and touches(g, c, {}) or {}
	return { x = c.x, y = c.y, facing = c.facing, n = t, strada = { dirs = {}, hops = {} }, globo = { a, p },
		casse = #taken > 0 and taken or nil }
end

-- An angle near move m's with which the shot hurts nobody (tried on the
-- copy), for the level that misses on purpose
local function missing_angle(b, g, m)
	for _, d in ipairs({ 0.3, -0.3, 0.5, -0.5, 0.8, -0.8 }) do
		local w = scratch(b, "miss", g)
		work(b, 20)
		at_spot(w, b.id, m.posto)
		w:attack(m.arma, { weapon = m.arma, angle = m.ang + d, power = m.potenza })
		until_quiet(b, w, 5 * 60)
		local nobody = true
		for i, c in ipairs(w.robots) do
			local r = g.robots[i]
			if not r.dead and (c.dead or c.hp < r.hp) then
				nobody = false
				break
			end
		end
		if nobody then return m.ang + d end
	end
	return m.ang + 0.8
end

-- The thinking: picks the move of the moment. Puts the best found so far in
-- b.scelta, so if time runs short that one is used.
local function think(b, g)
	local me = g.robots[b.id]
	local overrides = b.liv
	-- how much time is left to walk: the turn, or the seconds after the first attack
	local remaining = g.window > 0 and g.window or g.timer
	local list = armi(g, me)
	local moves = {}
	local walk_ticks = math.min(overrides.walk_ticks, remaining - 90)
	local plan = b.piano
	if plan and plan.attacca_entro and not (g.used.primary or g.used.secondary) then
		-- the first attack within attacca_entro seconds of the turn's start
		walk_ticks = math.min(walk_ticks, plan.attacca_entro * 60 - (g.tick - b.inizio) - 40)
	end
	local spots = spots_on_foot(b, g, walk_ticks)
	for _, spot in ipairs(spots) do
		if #list > 0 then moves_from_spot(b, g, spot, list, moves) end
	end
	-- the Molla under an enemy, only from where it stands (each try goes to the end)
	if overrides.oggetti and g:can_use("trampoline") then
		moves_from_spot(b, g, spots[1], { "trampoline" }, moves)
	end
	table.sort(moves, ranks_before)
	b.scelta = moves[1]

	-- the Grapple brings a far enemy into range: it is worth the best shot
	-- that can follow the pull (tried on the copy)
	if overrides.rampino and g:can_use("hook") and #list > 0 then
		local cx, cy = me.x, me.y + game.DISEGNO_H / 2
		for k, o in ipairs(enemies(g, me, me.x, me.y)) do
			if k > 2 then break end
			local dx, dy = o.x - cx, o.y + game.HURT_Y - cy
			local d = math.sqrt(dx * dx + dy * dy)
			if d > 80 and d < C.HOOK.range then
				local a = math.atan2(dy, dx)
				local mx, my = math.cos(a) * game.MUZZLE, math.sin(a) * game.MUZZLE
				local _, _, hit = g:ray(cx + mx, cy + my, a, C.HOOK.range, me)
				if hit == o then
					moves[#moves + 1] = { posto = spots[1], arma = "hook", ang = a, potenza = 1,
						punti = try_hook(b, g, spots[1], a, o.id, list), k = #moves + 1 }
				end
			end
		end
	end

	-- the best ones are tried to the end: who falls, who dies, where the shooter ends up
	table.sort(moves, ranks_before)
	for i = 1, math.min(FINALISTS, #moves) do
		local m = moves[i]
		if m.arma ~= "hook" then
			m.punti = taste(b, m.arma, try_move(b, g, m.posto, m.arma, m.ang, m.potenza, "tutto")) - (m.posto.n or 0) * b.pesi.strada
		end
	end
	table.sort(moves, ranks_before)
	b.scelta = moves[1]

	-- if there is nothing good on foot, the teleport to a better spot
	-- (not with plan poi = "teletrasporto": the orb is for fleeing)
	local best = moves[1] and moves[1].punti or -math.huge
	local flee = plan and plan.poi == "teletrasporto"
	if overrides.teletrasporto and not flee and best < b.pesi.teletrasporto and g:can_use("teleport") and remaining > 6 * 60 then
		local best_move
		for a = 20, 160, 20 do
			for _, p in ipairs({ 0.45, 0.7, 0.95 }) do
				local spot = teleport_spot(b, g, math.rad(a), p)
				if spot then
					local here = {}
					moves_from_spot(b, g, spot, list, here)
					for _, m in ipairs(here) do
						if not best_move or m.punti > best_move.punti then best_move = m end
					end
				end
			end
		end
		if best_move and best_move.punti > best + 10 then
			-- throw the orb; once there, think again from there
			local orb = best_move.posto.globo
			b.scelta = { posto = spots[1], arma = "teleport", ang = orb[1], potenza = orb[2], punti = best_move.punti }
			return
		end
	end

	-- sometimes (low levels) a worse move, but not one that hurts itself or
	-- its teammate (points below zero when the best isn't). esplora: the same
	-- for the learning bots (tools/arena/impara.py), so they also see
	-- moves they wouldn't pick
	local mistake = b.pesi.esplora or overrides.sbaglia
	if mistake > 0 and #moves > 1 and b.rng:next() < mistake then
		local m = moves[1 + math.floor(b.rng:next() * math.min(3, #moves))]
		if m.punti >= math.min(0, moves[1].punti) then b.scelta = m end
	end

	-- plan due_attacchi: if the weapon left reaches the enemy from no spot,
	-- get as close as possible and use it anyway
	if not b.scelta and plan and plan.due_attacchi and #list > 0 then
		local o = enemies(g, me, me.x, me.y)[1]
		if o then
			local near = spots[1]
			for _, p in ipairs(spots) do
				if math.abs(p.x - o.x) < math.abs(near.x - o.x) then near = p end
			end
			local a = math.atan2(o.y + game.HURT_Y - (near.y + game.DISEGNO_H / 2), o.x - near.x)
			b.scelta = { posto = near, arma = list[#list], ang = a, potenza = 1, punti = 0 }
		end
	end

	-- level manca: every other attack (the first, the third...) must not hit
	local m = b.scelta
	if overrides.manca and m and not game.TOOLS[m.arma] and b.attacks % 2 == 0 then
		m.ang = missing_angle(b, g, m)
	end
end

-- Cover: once the attacks are over, the time left is used to get safe from
-- the others' turns (on foot or with the Grapple on a hold). With the net, it
-- decides where; without, away from the enemies, out of their line of fire
-- and away from the void.
-- Is there rock above the head (up to 150 px)? Arc shots don't get there
local function covered(t, x, y)
	for k = 30, 150, 30 do
		if t:solid(x, y + k) then return 1 end
	end
	return 0
end

local function shelter(b, g, w)
	if b.pesi.rete then return value(b, g, w) end
	local x = caratteristiche(b, g, w, FEAT_BUF)
	if x[7] == 1 then return -1000 end
	local s = x[11] * 10 - x[16] * 4 - x[14] * 8 - x[15] * 3 - x[4] * 50 + casse(b, g, w)
	-- the coward's den: covered and seen by nobody
	local den = b.pesi.den
	if den then
		local c = w.robots[b.id]
		s = s + den * (2 * covered(w.terrain, c.x, c.y + game.DISEGNO_H) - x[16])
	end
	return s
end

-- the powers of the orb throws for fleeing
local THROWS, DEN_THROWS = { 0.45, 0.7, 0.95 }, { 0.3, 0.45, 0.6, 0.75, 0.9, 1 }

local function take_cover(b, g)
	local me = g.robots[b.id]
	local remaining = g.window > 0 and g.window or g.timer
	-- plan poi = "teletrasporto": to cover with the orb instead of on foot;
	-- otherwise the orb is compared with the spots on foot and with the
	-- Grapple and wins if it is better by at least pesi.globo_riparo
	-- (whoever looks for a den tries more throws, to find narrow holes too)
	local with_orb = b.piano and b.piano.poi == "teletrasporto"
	local orb
	if (with_orb or b.liv.teletrasporto) and g:can_use("teleport") then
		local best_move
		local stride = b.pesi.den and 10 or 20
		for a = stride, 180 - stride, stride do
			for _, p in ipairs(b.pesi.den and DEN_THROWS or THROWS) do
				local spot = teleport_spot(b, g, math.rad(a), p)
				if spot then
					local w = scratch(b, "shelter", g)
					at_spot(w, b.id, spot)
					local s = shelter(b, g, w)
					if not best_move or s > best_move.punti then
						best_move = { posto = { x = me.x, y = me.y, n = 0 }, arma = "teleport", ang = math.rad(a), potenza = p, punti = s }
					end
				end
			end
		end
		if best_move and with_orb then
			b.scelta = best_move
			return
		end
		orb = best_move
	end
	local spots = spots_on_foot(b, g, math.min(b.liv.walk_ticks, remaining - 30))
	local best_move
	for _, spot in ipairs(spots) do
		local w = scratch(b, "shelter", g)
		at_spot(w, b.id, spot)
		work(b, 20)
		local s = shelter(b, g, w) - (spot.n or 0) * b.pesi.strada
		if not best_move or s > best_move.punti then best_move = { posto = spot, punti = s } end
	end
	if b.liv.rampino and g:can_use("hook") and remaining > 3 * 60 then
		for grades = 15, 165, 25 do
			local a = math.rad(grades)
			local w = scratch(b, "shelter", g)
			work(b, 20)
			w:use_tool("hook", { weapon = "hook", angle = a, power = 1 })
			until_quiet(b, w, 3 * 60)
			local c = w.robots[b.id]
			if not c.dead and c.grounded and math.abs(c.x - me.x) + math.abs(c.y - me.y) > 40 then
				local s = shelter(b, g, w)
				if s > best_move.punti then
					best_move = { posto = spots[1], arma = "hook", ang = a, potenza = 1, punti = s }
				end
			end
		end
	end
	if orb and orb.punti > best_move.punti + b.pesi.globo_riparo then best_move = orb end
	b.scelta = best_move
end

-- The turn ----------------------------------------------------------------------------

-- The bot's generator: close seeds (same match seed, different robots)
-- would give almost equal numbers in Park-Miller's first steps (sim/rng.lua),
-- so a few are thrown away
local function generator(seed_n)
	local r = rng.new(seed_n)
	for _ = 1, 4 do r:next() end
	return r
end

function M.new(id, livello, seed, weights, personality)
	local grade = M.GRADES[livello] or {}
	local overrides = M.LEVELS[grade.livello or livello] or M.LEVELS.normale
	if grade.liv then
		overrides = copy(overrides)
		for k, v in pairs(grade.liv) do overrides[k] = v end
	end
	local p = copy(M.PESI)
	for k, v in pairs(grade.pesi or {}) do p[k] = v end
	local feat = personality and assert(M.PERSONALITIES[personality], "carattere sconosciuto: " .. personality) or {}
	for k, v in pairs(feat) do
		if k ~= "piano" then p[k] = v end
	end
	for k, v in pairs(weights or {}) do p[k] = v end
	-- own_plan: the personality's plan, for the turns that have no other
	return { id = id, livello = livello, liv = overrides, pesi = p, rng = generator((seed or 1) * 7919 + id), lavoro = 0,
		attacks = 0, own_plan = feat.piano }
end

-- Noise between -1 and 1, more often near 0
local function noise(b)
	return b.rng:next() + b.rng:next() - 1
end

-- Starts thinking again (after waiting wait ticks); how: think (the attack)
-- or take_cover
local function rethink(b, wait, how)
	b.stato, b.attesa, b.scelta, b.passo = "pensa", wait, nil, 0
	b.co = coroutine.create(how or think)
	b.think_from = nil
end

-- Nothing left to attack: once per turn it looks for cover, then stays still
local function enough(b)
	if b.sheltered then
		b.stato = "fine"
	else
		b.sheltered = true
		rethink(b, 5, take_cover)
	end
end

-- In the air above the void, on its own turn: the parachute (and towards
-- the nearest ground). Returns the input, or nil if not needed.
local function rescue(b, g, rb)
	if rb.grounded or rb.vy > -30 or rb.lunge or rb.recoil or rb.hooked then return nil end
	local t = g.terrain
	if t:ground_below(rb.x, rb.y) then
		if not rb.parachute then return nil end
	end
	if not rb.parachute and g:can_use("parachute") then
		return { fire = { weapon = "parachute", angle = 0, power = 0 } }
	end
	-- the column with the nearest ground, on that side
	for d = 20, 600, 20 do
		for _, s in ipairs({ -1, 1 }) do
			local x = rb.x + s * d
			if x > 30 and x < game.WORLD_W - 30 and t:ground_below(x, rb.y) then
				return { left = s < 0, right = s > 0 }
			end
		end
	end
	return nil
end

-- Where the bot is aiming, to show it (not the simulation): at the best move
-- found while it thinks, nil otherwise
function M.shown_aim(b)
	return b.stato == "pensa" and b.scelta and b.scelta.ang or nil
end

-- The bot's input for this tick (IDLE if it isn't its turn)
function M.input(b, g)
	-- a robot moved by a script (Favilla's demonstrations, sim/missions.lua)
	if b.script then return b.script(g) end
	local rb = g.robots[b.id]
	if g.current ~= b.id or g.phase ~= "aim" or rb.dead then
		b.turno = nil
		return IDLE
	end
	if b.turno ~= g.turn_no then
		b.turno, b.sheltered, b.inizio = g.turn_no, false, g.tick
		b.piano = b.piano or b.own_plan
		local plan = b.piano
		rethink(b, (plan and plan.attacca_entro) and math.min(b.liv.reaction, 20) or b.liv.reaction)
	end
	local rescue_input = rescue(b, g, rb)
	if rescue_input then return rescue_input end

	if b.stato == "pensa" then
		b.attesa = b.attesa - 1
		if coroutine.status(b.co) ~= "dead" then
			b.lavoro = 0
			b.think_from = b.think_from or g.tick
			local ok, err = coroutine.resume(b.co, b, g)
			if not ok then error(err) end
			-- time is short: use the best move found so far
			local within = b.piano and b.piano.attacca_entro and not (g.used.primary or g.used.secondary)
				and g.tick - b.inizio >= b.piano.attacca_entro * 60 - 30
			local long = b.liv.think_max and b.scelta and g.tick - b.think_from >= b.liv.think_max
			if coroutine.status(b.co) ~= "dead" and (g.window > 0 and g.window or g.timer) > 45 and not within
				and not long then return IDLE end
		end
		if b.attesa > 0 then return IDLE end
		if not b.scelta then
			enough(b)
			return IDLE
		end
		b.stato, b.passo = "vai", 0
	end

	if b.stato == "vai" then
		local s = b.scelta
		local road = s.posto.strada
		b.passo = b.passo + 1
		if road and b.passo <= s.posto.n then
			local d = road.dirs[b.passo]
			return { left = d < 0, right = d > 0, jump = road.hops[b.passo], hold = true }
		end
		-- path only (the cover): arrived
		if not s.arma then
			b.stato = "fine"
			return IDLE
		end
		-- arrived: the shot, with the level's error
		if not g:can_use(s.arma) then
			rethink(b, 10)
			return IDLE
		end
		local a = s.ang + noise(b) * b.liv.mira
		local p = math.max(0.1, math.min(1, s.potenza + noise(b) * b.liv.potenza))
		if not game.TOOLS[s.arma] and s.arma ~= "teleport" then b.attacks = b.attacks + 1 end
		b.stato, b.attesa = "aspetta", 0
		return { fire = { weapon = s.arma, angle = a, power = p } }
	end

	if b.stato == "aspetta" then
		-- after a shot wait until everything is still, then think again
		b.attesa = b.attesa + 1
		if quiet(g) or b.attesa > 4 * 60 then
			if b.liv.oggetti and rb.ammo.shield > 0 and g:can_use("shield") and g.used.primary and g.used.secondary then
				return { fire = { weapon = "shield", angle = 0, power = 0 } }
			end
			-- with plan poi = "teletrasporto" one attack is enough: then flee
			local flee = b.piano and b.piano.poi == "teletrasporto" and (g.used.primary or g.used.secondary)
			if b.sheltered or flee or (g.used.primary and g.used.secondary and not g:can_use("teleport")) then
				enough(b)
			else
				rethink(b, math.floor(b.liv.reaction / 2))
			end
		end
		return IDLE
	end
	return IDLE
end

-- Match-start draft: a random primary and secondary among those it can
-- take (sim/draft.lua); armi (pesi.armi, if set): the one it likes most, on
-- equal taste the random one
function M.choose(d, i, seed, armi)
	local draft = require "sim.draft"
	local r = generator((seed or 1) * 104729 + i)
	for _, offer in ipairs({ d.offer, d.offer2 }) do
		local free = {}
		for _, w in ipairs(offer) do
			if draft.valid(d, i, w) then free[#free + 1] = w end
		end
		if #free > 0 then
			local w = free[1 + math.floor(r:next() * #free)]
			for _, x in ipairs(armi and free or {}) do
				if (armi[x] or 1) > (armi[w] or 1) then w = x end
			end
			draft.pick(d, i, w)
		end
	end
end

return M
