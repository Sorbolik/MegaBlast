-- Glue between the server and the simulation: passes inputs to the game and
-- prepares state and events as simple Lua tables, which server/worker.lua
-- writes as JSON. It runs in the server's LuaJIT processes (server/proc.go).
local game = require "sim.game"
local maps = require "sim.maps"
local config = require "sim.config"
local draft = require "sim.draft"
local rules = require "sim.rules"
local bot = require "sim.bot"

local N = {}

-- The bots that fill a queue (lobby.go, after BotAfter): those of each match,
-- by robot. Since the server runs the simulation in LuaJIT (proc.go, 9 Nov) a
-- bot thinks like on the phone (400 simulated ticks per game tick, sim/bot.lua):
-- on gopher-lua it had 100 and thought over more ticks. After THINK_MAX ticks
-- of thinking it plays the best move found so far, so it never stands still
-- for long (Sergio, 9 Nov). Its moves can differ from the phone's: fine, online
-- the client only follows the server's state and these matches are not replayed.
N.THINK_MAX = 120
local BOTS = setmetatable({}, { __mode = "k" })

-- Terrain cells in a byte array (LuaJIT FFI) instead of a table of 230,400
-- numbers: 230 KB per match instead of 3.7 MB. The simulation reads and writes
-- t.data[i] with i from 1 to w * h, always inside the grid (sim/terrain.lua),
-- so the array has one cell more and position 0 unused.
local ffi = require "ffi"
local terrain = require "sim.terrain"
function terrain.new(w, h, cell, ox)
	return setmetatable({ w = w, h = h, cell = cell, ox = ox or 0, data = ffi.new("uint8_t[?]", w * h + 1) }, terrain)
end

-- Fixed maps are drawn only once per process: later matches copy the ready
-- cells instead of drawing them again.
local DRAWN = {}
for id, def in pairs(maps.maps) do
	if not def.seeded then
		local build = def.build
		def.build = function(t, seed)
			local size = t.w * t.h + 1
			local cells = DRAWN[id]
			if cells then
				ffi.copy(t.data, cells, size)
				return
			end
			build(t, seed)
			cells = ffi.new("uint8_t[?]", size)
			ffi.copy(cells, t.data, size)
			DRAWN[id] = cells
		end
	end
end

-- players: like opts.players of game.new (teams and draft picks);
-- r: the rules of the queue's event (sim/rules.lua), nil outside events
function N.new(seed, map, players, r)
	local g = game.new(seed, map, rules.opzioni(r, { players = players, random_spawns = true, intro = game.INTRO_TICKS }))
	g:pop_events()
	g.carves = {} -- terrain digs, for whoever reconnects
	for i, p in ipairs(players or {}) do
		if p.bot then
			local b = bot.new(i, p.bot, seed)
			b.liv = setmetatable({ think_max = N.THINK_MAX }, { __index = b.liv })
			BOTS[g] = BOTS[g] or {}
			BOTS[g][i] = b
		end
	end
	return g
end

-- hold: jump is still held down (releasing it while rising makes the jump short)
function N.step(g, left, right, jump, hold, angle, power, weapon)
	-- a bot's turn: the keys are its own (the server passes none)
	local b = BOTS[g] and BOTS[g][g.current]
	if b then
		g:step(bot.input(b, g))
		return
	end
	local fire = nil
	if angle then fire = { angle = angle, power = power, weapon = game.WEAPONS[weapon] and weapon or "missile" } end
	g:step({ left = left, right = right, jump = jump, hold = hold, fire = fire })
end

function N.current(g)
	return g.current
end

-- player i left the match (room.go, leave): their robot disappears
function N.remove(g, i)
	g:remove(i)
end

function N.over(g)
	return g.phase == "over"
end

-- The robots' tables are reused from one state to the next (30 a second per
-- match: less garbage for the collector); every field is written each time
local ROBOTS = setmetatable({}, { __mode = "k" })

-- aim: the angle the player on turn is aiming at (room.go, the "aim" message), nil
-- if they aren't aiming; a bot aims at its best move while it thinks
function N.snapshot(g, aim)
	local robots = ROBOTS[g]
	if not robots then
		robots = {}
		ROBOTS[g] = robots
	end
	for i, rb in ipairs(g.robots) do
		-- s: tick of the ongoing slash (0 if the robot isn't hitting), sd: its direction
		-- pu, pd: the same for the Pugno del Titano; ag, as, ap, ac: shots of Uovo, Schegge, Pugno and Cecchino;
		-- ab, at, ar: shots of Falcetto, Pozza di Pece and Trapano
		-- sb, pb: aim angle of the slash and the punch (the hit rotates with the aim)
		-- tl: teleports in hand, mh: max life, tu: turns played, pt: points
		-- ak, ad, am: traps, shields and trampolines; sh: shield left; pa: parachute open;
		-- pl: parachutes left; st: turns left of the effects (burn + 10 x slow + 100 x cracked armour)
		-- sw: the secondary picked at the start (besides the Lama, "" if none), ss: its shots;
		-- lu: ticks left of the Affondo, la: angle of its dash;
		-- kn: knocked by a hit (doesn't run by itself); tr: feet locked by a trap;
		-- hk: who's pulling it with the Rampino (0 nobody, -1 if hanging from the terrain at hx, hy);
		-- gs: its Rampino hook is in flight, at gx, gy; ml: tick of the Maglio swing,
		-- ms: tick (with fraction) when its head stopped on terrain (0 if still swinging), md: its side;
		-- gn: left the match (gone, won't come back); gd: has already played in this round
		local r = robots[i]
		if not r then
			r = {}
			robots[i] = r
		end
		local ammo, status, hooked, hook = rb.ammo, rb.status, rb.hooked, rb.hook_shot
		r.x, r.y, r.hp, r.f, r.d, r.g = rb.x, rb.y, math.floor(rb.hp), rb.facing, rb.dead, rb.grounded
		r.tl, r.mh, r.tu, r.pt = rb.teleports_left, rb.max_hp, rb.turns, math.floor(rb.points + 0.5)
		r.ak, r.ad, r.am, r.sh, r.pl = ammo.trap, ammo.shield, ammo.trampoline, rb.shield or 0, rb.parachutes_left
		r.pa = rb.parachute
		r.st = (status.burn and status.burn.turns or 0) + 10 * (status.slow and status.slow.turns or 0)
			+ 100 * (status.cracked and status.cracked.turns or 0)
		r.s, r.sd, r.pu, r.pd = rb.swing or 0, rb.swing_dir or 0, rb.punch or 0, rb.punch_dir or 0
		r.sb, r.pb = rb.swing_base or 0, rb.punch_base or 0
		r.ag, r.as, r.ap, r.ac = ammo.grenade, ammo.shards, ammo.punch, ammo.sniper
		r.ab, r.at, r.ar = ammo.boomerang, ammo.tar, ammo.drill
		r.sw, r.ss, r.lu = rb.secondary or "", rb.secondary and ammo[rb.secondary] or 0, rb.lunge or 0
		r.hk = hooked and (hooked.by or -1) or 0
		r.hx, r.hy, r.ml = hooked and hooked.x or 0, hooked and hooked.y or 0, rb.mallet or 0
		r.gs, r.gx, r.gy = hook ~= nil, hook and hook.x or 0, hook and hook.y or 0
		r.ms, r.md, r.mb, r.kn = rb.mallet_stop or 0, rb.mallet_dir or 0, rb.mallet_base or 0, rb.knocked
		r.tr = rb.trapped or false
		r.la, r.gn = rb.lunge_vx and math.atan2(rb.lunge_vy, rb.lunge_vx) or 0, rb.gone or false
		r.gd = rb.round_done
	end
	-- k: "missile", "grenade", "sniper", "boomerang", "drill", "tar" or "petard", fu: ticks before the Uovo blows up
	local p = g.projectile and { x = g.projectile.x, y = g.projectile.y, k = g.projectile.kind, fu = g.projectile.fuse or 0 }
	-- o: the teleport orbs in flight (i = orb number, to follow it from one state to the next)
	local orbs = {}
	for i, ob in ipairs(g.orbs) do orbs[i] = { i = ob.id, x = ob.x, y = ob.y } end
	-- shards in flight with their place in the burst, crates (the weapon inside stays
	-- secret; w: the item, for the items that drop on the map visible)
	local shards, crates = {}, {}
	for i = 1, game.SHARD_COUNT do
		local sh = g.shards[i]
		if sh then shards[#shards + 1] = { i = i, x = sh.x, y = sh.y } end
	end
	for _, c in ipairs(g.crates) do
		crates[#crates + 1] = { i = c.id, x = c.x, y = c.y, l = c.landed, w = c.item and c.weapon or nil }
	end
	-- pl: traps and trampolines (k: kind, a: armed, tm: team, r: half width, v: in flight,
	-- d: the side the trampoline leans to, 1 or -1)
	local placed = {}
	for i, o in ipairs(g.placed) do
		placed[i] = { i = o.id, k = o.kind, x = o.x, y = o.y, a = o.armed, tm = o.team, r = o.r, v = o.flying or false, d = o.dir }
	end
	-- pp: pools of burning pitch (Pozza di Pece; r: radius, tn: turns left)
	local pools = {}
	for i, pool in ipairs(g.pools) do pools[i] = { i = pool.id, x = pool.x, y = pool.y, r = pool.r, tn = pool.turns } end
	-- hl: healing circles
	local heals = {}
	for i, h in ipairs(g.heals) do heals[i] = { i = h.id, x = h.x, y = h.y } end
	-- win: ticks left after the first attack; u: attacks done (1 primary, 2 secondary); tp: teleports
	-- of the turn; te: orbs earned this turn; fr: last round (multiplied points);
	-- av, ab: team that opened the pair of turns and its points then (game.ahead);
	-- gr: the current round (the Crown only exists from SCORE.crown_rounds + 1);
	-- aim: where the robot on turn is aiming (absent if it isn't), the others see it
	local b = BOTS[g] and BOTS[g][g.current]
	if b then aim = bot.shown_aim(b) end
	if g.phase ~= "aim" then aim = nil end
	local used = (g.used.primary and 1 or 0) + (g.used.secondary and 2 or 0) + (g.used.tool and 4 or 0)
	return { t = "state", phase = g.phase, cur = g.current, timer = g.timer, win = g.window,
		u = used, mt = g.match_left, ai = g.intro > 0 and g.intro or nil, fr = g.final_round, gr = g.round,
		av = g.ahead, ab = g.ahead_base, r = robots, p = p, o = orbs, s = shards,
		c = crates, pl = placed, hl = heals, pp = pools, aim = aim }
end

-- Events since the last tick (a list, empty if none happened)
function N.events(g)
	local list = g:pop_events()
	for _, e in ipairs(list) do
		e.t = "ev"
		if e.type == "explosion" or e.type == "carve" then g.carves[#g.carves + 1] = { e.x, e.y, e.r } end
	end
	return list
end

-- The digs made so far: whoever reconnects redoes them on their terrain, in
-- the same order
function N.sync(g)
	return { t = "sync", x = g.carves }
end

-- Start-of-match draft (sim/draft.lua), before N.new --------------------

function N.mode_players(mode)
	return config.MODES[mode]
end

-- the draft starts with the line-up of the cards (menu/lineup.lua): its
-- time is inside the draft time, and meanwhile you can already pick
function N.draft_seconds()
	return config.DRAFT_SECONDS + config.LINEUP_SECONDS
end

-- bots: the grade (sim/bot.lua GRADES) of the robots that are bots, by robot;
-- they pick at once, like on the phone
function N.draft_new(seed, mode, r, bots)
	local players = {}
	for i, p in ipairs(config.MODES[mode]) do
		players[i] = { team = p.team, bot = bots and bots[i] or nil }
	end
	local d = draft.new(seed, players, rules.armi(r))
	for i, p in ipairs(players) do
		if p.bot then bot.choose(d, i, seed) end
	end
	return d
end

-- can an event's rules be used? (events.go, when it reads the file)
function N.rules_valid(r, normal)
	local ok, err = rules.validate(r, normal)
	return ok and "" or err
end

function N.draft_pick(d, i, weapon)
	return draft.pick(d, i, weapon)
end

function N.draft_finish(d)
	local out = draft.finish(d)
	for i, p in ipairs(d.players) do out[i].bot = p.bot end
	return out
end

-- The two fans (offer: primaries, offer2: secondaries) and the picks of robot i
-- (p, p2, or ""): the others' picks aren't sent (Sergio, 30 Oct)
function N.draft_state(d, i)
	return { t = "draft", offer = d.offer, offer2 = d.offer2, p = d.picks[i] or "", p2 = d.picks2[i] or "" }
end

-- The match players for the start message: team and draft picks, so the
-- client creates its copy of the match with the same weapons
function N.start_players(players)
	local out = {}
	for i, p in ipairs(players) do
		out[i] = { team = p.team, pick = p.pick, secondary = p.secondary, bot = p.bot }
	end
	return out
end

return N
