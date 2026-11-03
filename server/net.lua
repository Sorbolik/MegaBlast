-- Glue between the Go server and the simulation: passes inputs to the game and
-- prepares state and events as simple Lua tables. The JSON is written by the
-- server in Go (server/luajson.go), much faster than string.format here.
local game = require "sim.game"
local maps = require "sim.maps"
local config = require "sim.config"
local draft = require "sim.draft"
local rules = require "sim.rules"
local bot = require "sim.bot"

local N = {}

-- The bots that fill a queue (lobby.go, after BotAfter): those of each match,
-- by robot. On the server a bot thinks at most WORK simulated ticks per game
-- tick (on the phone 400, sim/bot.lua): a worker runs many rooms, and with 400
-- a "normale" took 2.2 ms per tick with peaks of 50 ms on gopher-lua; with 100,
-- 1.6 ms and peaks of 21 ms (measured 3 Nov). It thinks over more ticks, so
-- its moves can differ from the phone's: fine, online the client only follows
-- the server's state and these matches are not replayed.
N.WORK = 100
local BOTS = setmetatable({}, { __mode = "k" })

-- Fixed maps are drawn only once per process: later matches copy the ready
-- cells (server/terrain.go), instead of drawing them again (over 100 ms in
-- gopher-lua).
for id, def in pairs(maps.maps) do
	if not def.seeded then
		local build = def.build
		def.build = function(t, seed)
			if not terrain_restore(t, id) then
				build(t, seed)
				terrain_store(t, id)
			end
		end
	end
end

-- players: like opts.players of game.new (teams and draft picks);
-- r: the rules of the queue's event (sim/rules.lua), nil outside events
function N.new(seed, map, players, r)
	local g = game.new(seed, map, rules.opzioni(r, { players = players }))
	g:pop_events()
	g.carves = {} -- terrain digs, for whoever reconnects
	for i, p in ipairs(players or {}) do
		if p.bot then
			local b = bot.new(i, p.bot, seed)
			b.liv = setmetatable({ lavoro = N.WORK }, { __index = b.liv })
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

function N.snapshot(g)
	local robots = {}
	for i, rb in ipairs(g.robots) do
		-- s: tick of the ongoing slash (0 if the robot isn't hitting), sd: its direction
		-- pu, pd: the same for the Pugno del Titano; ag, as, ap, ac: shots of Uovo, Schegge, Pugno and Cecchino
		-- sb, pb: aim angle of the slash and the punch (the hit rotates with the aim)
		-- tl: teleports in hand, mh: max life, tu: turns played, pt: points
		-- ak, ad, am: traps, shields and trampolines; sh: shield left; pa: parachute open;
		-- pl: parachutes left; st: turns left of the effects (burn + 10 x slow + 100 x cracked armour)
		-- sw: the secondary picked at the start (besides the Lama, "" if none), ss: its shots;
		-- lu: ticks left of the Affondo, la: angle of its dash;
		-- kn: knocked by a hit (doesn't run by itself);
		-- hk: who's pulling it with the Rampino (0 nobody, -1 if hanging from the terrain at hx, hy);
		-- gs: its Rampino hook is in flight, at gx, gy; ml: tick of the Maglio swing,
		-- ms: tick (with fraction) when its head stopped on terrain (0 if still swinging), md: its side;
		-- gn: left the match (gone, won't come back); gd: has already played in this round
		robots[i] = { x = rb.x, y = rb.y, hp = math.floor(rb.hp), f = rb.facing, d = rb.dead, g = rb.grounded,
			tl = rb.teleports_left, mh = rb.max_hp, tu = rb.turns, pt = math.floor(rb.points + 0.5),
			ak = rb.ammo.trap, ad = rb.ammo.shield, am = rb.ammo.trampoline, sh = rb.shield or 0, pl = rb.parachutes_left,
			pa = rb.parachute,
			st = (rb.status.burn and rb.status.burn.turns or 0) + 10 * (rb.status.slow and rb.status.slow.turns or 0)
				+ 100 * (rb.status.cracked and rb.status.cracked.turns or 0),
			s = rb.swing or 0, sd = rb.swing_dir or 0, pu = rb.punch or 0, pd = rb.punch_dir or 0,
			sb = rb.swing_base or 0, pb = rb.punch_base or 0,
			ag = rb.ammo.grenade, as = rb.ammo.shards, ap = rb.ammo.punch, ac = rb.ammo.sniper,
			sw = rb.secondary or "", ss = rb.secondary and rb.ammo[rb.secondary] or 0, lu = rb.lunge or 0, hk = rb.hooked and (rb.hooked.by or -1) or 0,
			hx = rb.hooked and rb.hooked.x or 0, hy = rb.hooked and rb.hooked.y or 0, ml = rb.mallet or 0,
			gs = rb.hook_shot ~= nil, gx = rb.hook_shot and rb.hook_shot.x or 0, gy = rb.hook_shot and rb.hook_shot.y or 0,
			ms = rb.mallet_stop or 0, md = rb.mallet_dir or 0, mb = rb.mallet_base or 0, kn = rb.knocked,
			la = rb.lunge_vx and math.atan2(rb.lunge_vy, rb.lunge_vx) or 0, gn = rb.gone or false,
			gd = rb.round_done }
	end
	-- k: "missile", "grenade" or "sniper", fu: ticks before the Uovo blows up
	local p = g.projectile and { x = g.projectile.x, y = g.projectile.y, k = g.projectile.kind, fu = g.projectile.fuse or 0 }
	-- o: the teleport orbs in flight (i = orb number, to follow it from one state to the next)
	local orbs = {}
	for i, ob in ipairs(g.orbs) do orbs[i] = { i = ob.id, x = ob.x, y = ob.y } end
	-- shards in flight with their place in the burst, crates (the weapon inside stays secret)
	local shards, crates = {}, {}
	for i = 1, game.SHARD_COUNT do
		local sh = g.shards[i]
		if sh then shards[#shards + 1] = { i = i, x = sh.x, y = sh.y } end
	end
	for _, c in ipairs(g.crates) do
		crates[#crates + 1] = { i = c.id, x = c.x, y = c.y, l = c.landed }
	end
	-- pl: traps and trampolines (k: kind, a: armed, tm: team, r: half width, v: in flight)
	local placed = {}
	for i, o in ipairs(g.placed) do
		placed[i] = { i = o.id, k = o.kind, x = o.x, y = o.y, a = o.armed, tm = o.team, r = o.r, v = o.flying or false }
	end
	-- hl: healing circles
	local heals = {}
	for i, h in ipairs(g.heals) do heals[i] = { i = h.id, x = h.x, y = h.y } end
	-- win: ticks left after the first attack; u: attacks done (1 primary, 2 secondary); tp: teleports
	-- of the turn; te: orbs earned this turn; fr: last round (multiplied points);
	-- av, ab: team that opened the pair of turns and its points then (game.ahead);
	-- gr: the current round (the Crown only exists from SCORE.crown_rounds + 1)
	local used = (g.used.primary and 1 or 0) + (g.used.secondary and 2 or 0) + (g.used.tool and 4 or 0)
	return { t = "state", phase = g.phase, cur = g.current, timer = g.timer, win = g.window,
		u = used, mt = g.match_left, fr = g.final_round, gr = g.round,
		av = g.ahead, ab = g.ahead_base, r = robots, p = p, o = orbs, s = shards,
		c = crates, pl = placed, hl = heals }
end

-- Events since the last tick (a list, empty if none happened)
function N.events(g)
	local list = g:pop_events()
	for _, e in ipairs(list) do
		e.t = "ev"
		if e.type == "explosion" then g.carves[#g.carves + 1] = { e.x, e.y, e.r } end
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

-- the draft starts with the line-up of the cards (menu/schieramento.lua): its
-- time is inside the draft time, and meanwhile you can already pick
function N.draft_seconds()
	return config.DRAFT_SECONDS + config.LINEUP_SECONDS
end

-- bots: the grade (sim/bot.lua GRADI) of the robots that are bots, by robot;
-- they pick at once, like on the phone
function N.draft_new(seed, mode, r, bots)
	local players = {}
	for i, p in ipairs(config.MODES[mode]) do
		players[i] = { team = p.team, bot = bots and bots[i] or nil }
	end
	local d = draft.new(seed, players, rules.armi(r))
	for i, p in ipairs(players) do
		if p.bot then bot.scegli(d, i, seed) end
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
