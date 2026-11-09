-- Simulation of a match: robots, missiles, turns.
-- Pure Lua, no Defold API: the same logic runs on the server too.
--
-- Usage:
--   local game = require "sim.game"
--   local g = game.new(seed, "pavimento")   -- without a map the seed picks it
--   g:step({ left = bool, right = bool, jump = bool,
--            fire = { angle = rad, power = 0..1, weapon = "missile" | "sword" | "teleport" | "swap"
--                                                     | "grenade" | "shards" | "punch" } })
--   g:can_use(weapon)   -- can the robot on turn use it now? (g.permitted(w): the lessons forbid some)
-- Turn rules (sim/config.lua): up to one weapon and one sword hit per turn, in
-- any order; after the first attack AFTER_ATTACK_SECONDS remain, during which
-- you can do the second and reposition. The seconds left at the first attack
-- become teleport orbs (rb.teleports_left).
--   for _, e in ipairs(g:pop_events()) do ... end

local rng = require "sim.rng"
local terrain = require "sim.terrain"
local maps = require "sim.maps"
local melee = require "sim.melee"
local C = require "sim.config"
local BODY_SCALE = require "sim.body"

local M = {}
M.__index = M

-- World: 640 x 360 cells (the map masks). CELL 3 since 26 October, it was 2:
-- the map was small for the devil (you crossed it quickly and it didn't fit
-- through the holes in the middle). 3 and not a fractional value, so cells stay
-- whole and the map matches the 1920 x 1080 images pixel for pixel.
M.CELL = 3
M.WORLD_W = 640 * M.CELL
M.WORLD_H = 360 * M.CELL
M.DT = 1 / 60

-- Measures. Jumps, weapons, crates and explosions are measured on a robot
-- REF_H pixels tall, which is 3.612 U units: many measures below are in U. The
-- devil's body is CORPO times bigger (1.4, chosen on 26 October so the painted
-- devil reads well): the walking capsule and the hit circle are in
-- sim/body.lua (animation editor), the rest of the world stays on the REF_H
-- scale. REF_H is 28 since 23 October (it was 20) to see the character better.
-- The measures written in pixels (crates, shards, orb...) were made on a robot
-- 16 tall and then multiplied by 28 / 16.
M.REF_H = 28
M.U = M.REF_H / 3.612
M.CORPO = 1.4
M.GRAVITY = 25 * M.U

-- Robot (the position is the centre of the feet). The body against terrain is
-- a capsule: above and below a half circle of radius ROBOT_HALF_W. The round
-- bottom touches slopes near the centre instead of with the corner, so it
-- doesn't stay hanging.
M.ROBOT_H = BODY_SCALE.walk.height
M.ROBOT_HALF_W = BODY_SCALE.walk.width / 2
-- the height of the drawn devil, from the feet to the top of the head: the
-- drawing doesn't change if the walking capsule or the hit circle change
-- (sim/body.lua). Shots (MUZZLE) and the grapple also start from here.
-- Projectiles, crates and held weapons are drawn on DISEGNO_H / CORPO.
M.DISEGNO_H = M.REF_H * M.CORPO
M.MAX_CLIMB = 10.5       -- highest step the robot climbs by itself

-- Robot movement stats (the others are in sim/config.lua, STATS).
-- Gear and the skill tree modify them.
M.DEFAULT_STATS = {
	walk_speed = 5 * M.U,    -- ground speed, per second
	jump_height = 5.2 * M.U, -- maximum jump height
	air_speed = 5 * M.U,     -- horizontal speed in the air
}
-- No inertia in the air: holding a direction the speed is air_speed at once,
-- with no direction it stays what it was; the robot on turn never moves
-- sideways faster than its run, not even after an explosion.
-- Fall damage: past FALL_SAFE pixels of fall, FALL_DAMAGE per extra pixel up
-- to FALL_DAMAGE_MAX (Sergio, 29 October 2026: "ci vogliono 5 turni per
-- ammazzare qualcuno", all damage went up by 5/3)
M.FALL_SAFE = 40 * M.U
M.FALL_DAMAGE = 1.25 / M.U
M.FALL_DAMAGE_MAX = 75

-- Lanciarune (missile)
M.MISSILE_SPEED = 75 * M.U  -- speed at full power
M.MISSILE_GRAVITY = 1.1     -- how much gravity it feels, relative to robots
-- How an explosion pushes: velocity = (closest point of the square around the
-- hit circle - explosion) * impulse * t, with t = 1 - distance / damage_r.
-- Maximum at half radius, zero on a direct hit. The pushed one's velocity is
-- replaced, not added.
M.SELF_DAMAGE = 0.5      -- how much of the damage whoever hits themselves takes
-- for how many ticks after launch a projectile doesn't touch its launcher
M.OWNER_SAFE_TICKS = 30

-- Lama di Nucleo: the slash of sim/melee.lua rotated on the aim (aiming down
-- the hit comes down from above). Damage lands when the hit window closes, on
-- everyone touched by the blade, and the hit stops the target.
M.MUZZLE = 24.5          -- shots start at this distance from the robot's centre
M.SWORD_PIVOT_Y = 17.5   -- height of the pivot (the shoulder) above the feet
M.SWORD_DAMAGE = 25

-- Where a robot can be hit (projectiles, orbs, blades, explosions): a circle of
-- radius HURT_R, HURT_Y above the feet (sim/body.lua). For explosions the
-- square around the circle counts, HURT_FAT wider on each side.
M.HURT_R = BODY_SCALE.hit.radius
M.HURT_Y = BODY_SCALE.hit.center
M.HURT_FAT = 0.1 * M.U

-- Teleport (Passo d'Ombra): an orb that flies like the missile, bounces and
-- rolls on terrain, and after
-- TELEPORT_TICKS moves the robot to where it is, without touching its state:
-- velocity, ongoing slash and facing stay as they were. It doesn't end the turn.
M.TELEPORT_TICKS = 3 * 60
M.ORB_SPEED = 80 * M.U
M.ORB_GRAVITY = 1.1
M.ORB_DAMPING = 1.1      -- slowdown per second after the first impact
M.MAX_ORBS = 6           -- orbs in flight together, at most

-- Explosions: crater radius, damage radius, damage at centre and at edge,
-- push impulse
M.MISSILE_BLAST = { r = 5 * M.U, damage_r = 9 * M.U, damage = 25, damage_min = 12.5, impulse = 10 }

-- Uovo di Fiamma (grenade): bounces (0.4, slowdown 1 per second after the
-- first impact) and blows up after GRENADE_FUSE ticks, with a bigger explosion
-- than the missile
M.GRENADE_SPEED = 85 * M.U  -- speed at full power
M.GRENADE_FUSE = 5 * 60
M.GRENADE_BOUNCE = 0.4   -- how much speed is left after a bounce
M.GRENADE_FRICTION = 1   -- friction when touching ground
M.GRENADE_GRAVITY = 1.3
M.GRENADE_DAMPING = 1    -- slowdown per second after the first impact (like Box2D's linear damping)
-- damage 80 at the centre and 25 at the edges (bot arena, 29 October 2026: the
-- Uovo was the weakest weapon; Sergio: "non ti dico che si deve oneshottare")
M.GRENADE_BLAST = { r = 5.5 * M.U, damage_r = 10 * M.U, damage = 80, damage_min = 25, impulse = 15 }

-- Sciame di Schegge (machine gun): a burst of straight, fast shards, each with
-- a tiny explosion
M.SHARD_COUNT = 8
M.SHARD_EVERY = 4        -- ticks between one shard and the next
M.SHARD_SPEED = 1662.5   -- power doesn't count: they always leave at the same speed
M.SHARD_GRAVITY = 0.2    -- gravity barely bends them
M.SHARD_SPREAD = math.rad(3)
M.SHARD_BLAST = { r = 12.25, damage_r = 21, damage = 11, impulse = 30 }

-- Cecchino: shot speed (power doesn't count) and its maximum lifetime; damage,
-- push, drop and bounces in config.SNIPER
M.SNIPER_SPEED = 840
M.SNIPER_LIFE = 6 * 60

-- Pugno del Titano: the uppercut of sim/melee.lua rotated on the aim, it
-- launches whoever it touches straight up; the attacker does a little hop
M.PUNCH_DAMAGE = 47      -- 28 instead of 50 (bot arena, 29 October 2026: it won too much), then 47 (5/3)
M.PUNCH_LAUNCH = 40 * M.U   -- upward speed of the target
M.PUNCH_HOP = 15 * M.U      -- the attacker rises a little with the uppercut

-- Weapons, in two categories (Sergio, 24 October 2026; rule redone on the
-- 29th). Each turn one primary and one secondary, in any order, never two of
-- the same category. Primaries: do damage and are the only ones that leave
-- status effects (config.WEAPON_STATUS); the Lanciarune is always there, the
-- others give one shot per crate (rb.ammo). Secondaries: do anything (move the
-- user or the target) but never status effects: the Lama just hits, the
-- Tonante pushes the shooter back, the Maglio bounces them up, the Affondo
-- carries them past, the Mantice blows away whoever is in front. The Lama is
-- always there and unlimited; one of the others is picked at the start of the
-- match (rb.secondary, sim/draft.lua) and has counted shots in rb.ammo, which
-- come back by hitting an enemy with the Lama (config.SECONDARY_SHOTS; Sergio,
-- 31 October 2026).
M.SECONDARY = { sword = true, eagle = true, mallet = true, lunge = true, bellows = true }
M.DRAFT_SECONDARIES = { "eagle", "mallet", "lunge", "bellows" }
-- weapons that don't use up shots
M.FREE_WEAPONS = { missile = true, sword = true, teleport = true }
M.CRATE_WEAPONS = { "grenade", "shards", "punch", "sniper" }
-- Tactical items from crates (also in rb.ammo), the parachute (one per match)
-- and the Rampino (one per turn, for everyone): they aren't attacks (config.lua)
M.ITEMS = { "trap", "shield", "trampoline" }
M.TOOLS = { trap = true, shield = true, trampoline = true, parachute = true, hook = true }
-- items thrown by aiming (the others are used with a tap)
M.THROWN = { trampoline = true, hook = true }
-- all the valid names of fire.weapon
M.WEAPONS = { teleport = true, swap = true }
for w in pairs(M.FREE_WEAPONS) do M.WEAPONS[w] = true end
for _, w in ipairs(M.CRATE_WEAPONS) do M.WEAPONS[w] = true end
for _, w in ipairs(M.DRAFT_SECONDARIES) do M.WEAPONS[w] = true end
for w in pairs(M.TOOLS) do M.WEAPONS[w] = true end

-- Crates: they drop from the sky at a random spot (CRATE_CHANCE below).
-- Whoever touches one finds a shot of a weapon (config.CRATE_CONTENTS). Items
-- drop the same way but visible (c.item, config.ITEM_DROPS), half as often.
-- CRATE_EVERY: the rate the events panel proposes for events with a crate
-- every so many turns (sim/rules.lua, casse).
M.CRATE_EVERY = 3
M.CRATE_MAX = 3          -- crates on the map at most
M.CRATE_HALF_W = 17.5
M.CRATE_H = 31.5
M.CRATE_FALL = 192.5     -- maximum fall speed (it comes down slowly, with a parachute)
-- Each turn a probability, depending on how many crates there already are
-- ({ with 0, with 1, with 2, ... }). With opts.crate_every (event rules,
-- missions, tests) instead one crate every so many turns.
M.CRATE_CHANCE = { 0.9, 0.5, 0.3, 0.1 }
-- the same for items: half (with crate_every: every 2 * crate_every turns)
M.ITEM_CHANCE = { 0.45, 0.25 }
M.ITEM_SET = {}
for _, w in ipairs(M.ITEMS) do M.ITEM_SET[w] = true end

-- Turns: durations are in sim/config.lua, here in ticks
M.MATCH_TICKS = C.MATCH_SECONDS * 60
M.TURN_TICKS = C.TURN_SECONDS * 60
M.AFTER_ATTACK_TICKS = C.AFTER_ATTACK_SECONDS * 60
M.RESPAWN_TICKS = math.floor(C.RESPAWN_SECONDS * 60)
M.SETTLE_TICKS = 60      -- 1 s between one turn and the next
M.MAX_SETTLE_TICKS = 5 * 60

-- Online the server sends a state every SNAPSHOT_TICKS ticks (30 per second)
M.SNAPSHOT_TICKS = 2

-- Controls (used by the client). Shot power comes from how far the finger is:
-- f = distance / reach (0..1). Below AIM_DEADZONE it doesn't count, then it
-- grows with exponent AIM_EXPONENT (2: quadratic, more precise on short shots).
M.AIM_DEADZONE = 0.2
M.AIM_EXPONENT = 2
-- how much of the gap between aim and finger is recovered each frame (at 60 Hz); 1 = at once
M.AIM_SMOOTH = 0.2
-- Short jump (like Hollow Knight): releasing jump while rising multiplies the
-- upward speed by JUMP_CUT. 1 = always a full jump.
-- It only counts if the input says hold = false: without hold the jump is full.
-- Holding jump you jump again as soon as you touch ground (the client does that).
M.JUMP_CUT = 0.45
-- Assists (like Celeste): for COYOTE_TICKS after stepping off an edge you can
-- still jump; a jump asked in the air up to JUMP_BUFFER_TICKS before touching
-- ground starts as soon as you land.
M.COYOTE_TICKS = 6
M.JUMP_BUFFER_TICKS = 6

function M.aim_power(f)
	f = math.max(0, math.min(1, f))
	if M.AIM_DEADZONE > 0 then f = math.max(0, (f - M.AIM_DEADZONE) / (1 - M.AIM_DEADZONE)) end
	return math.max(0.1, f ^ M.AIM_EXPONENT)
end

local NO_INPUT = {}

-- Stats of a robot without tree or gear: config.STATS plus the movement ones
-- (DEFAULT_STATS). sim/loadout.lua starts from here too.
function M.base_stats()
	local st = { teleport_ticks = M.TELEPORT_TICKS }
	for k, v in pairs(C.STATS) do st[k] = v end
	for k, v in pairs(M.DEFAULT_STATS) do st[k] = v end
	return st
end

local function make_stats(custom)
	local st = M.base_stats()
	for k, v in pairs(custom or {}) do st[k] = v end
	st.jump_vy = math.sqrt(2 * M.GRAVITY * st.jump_height)
	return st
end

local function make_ammo(start)
	local a = {}
	for _, w in ipairs(M.CRATE_WEAPONS) do a[w] = start and start[w] or 0 end
	for _, w in ipairs(M.DRAFT_SECONDARIES) do a[w] = start and start[w] or 0 end
	for _, w in ipairs(M.ITEMS) do a[w] = start and start[w] or 0 end
	return a
end

-- opts.players = { { team = 1, stats = { walk_speed = ... }, pick = "shards", secondary = "eagle" }, { team = 2 }, ... }:
-- from 2 to MAX_PLAYERS robots, in the order they come. Same team = allies.
-- stats are the robot's stats (tree and gear); the missing ones come from
-- config.STATS and DEFAULT_STATS.
-- pick is the weapon of the start-of-match draft (sim/draft.lua). dummy = true
-- is a target that never plays its turn (lessons). Without players, two robots
-- on different teams.
M.MAX_PLAYERS = 4

-- Turn order: teams alternate (in 2 v 2 A1, B1, A2, B2), in the order they
-- appear in players. Returns the robot indices.
local function turn_order(players)
	local teams, members = {}, {}
	for i, p in ipairs(players) do
		-- targets don't play
		if not p.dummy then
			if not members[p.team] then
				members[p.team] = {}
				teams[#teams + 1] = p.team
			end
			local m = members[p.team]
			m[#m + 1] = i
		end
	end
	local order = {}
	for round = 1, #players do
		for _, t in ipairs(teams) do
			if members[t][round] then order[#order + 1] = members[t][round] end
		end
	end
	return order
end

-- "1v1", "ffa" (free for all: each team has one robot) or "2v2" (teams)
local function match_mode(players)
	local size = {}
	for _, p in ipairs(players) do size[p.team] = (size[p.team] or 0) + 1 end
	for _, n in pairs(size) do
		if n > 1 then return "2v2" end
	end
	return #players == 2 and "1v1" or "ffa"
end

-- opts.ammo = { grenade = 2, ... } starting shots of crate weapons (for tests)
-- opts.crate_every = turns between one crate and the next (without: CRATE_CHANCE each turn)
-- opts.heals = false: no healing circles (the lessons)
-- opts.hp = starting life (stats.max_hp if missing; for tests)
-- opts.score = match points different from config.SCORE, only the fields that change (the arena tries variants);
--   false: no points (the lessons that aren't about points, Sergio 31 Oct)
-- opts.normalize = tree and gear don't count, everyone has the base stats (the
-- draft weapon stays): an event's livello = "fisso" rule (sim/rules.lua)
function M.new(seed, map_id, opts)
	opts = opts or {}
	local g = setmetatable({}, M)
	-- without a map the seed picks it (maps.ROTATION)
	local map = maps.get(map_id or maps.pick(seed))
	g.map = map.id
	g.rng = rng.new(seed)
	g.terrain = terrain.new(M.WORLD_W / M.CELL, M.WORLD_H / M.CELL, M.CELL)
	map.build(g.terrain, seed)
	g.spawn_spots = M.find_spawn_spots(g.terrain)
	local players = opts.players or C.MODES["1v1"]
	assert(#players >= 2 and #players <= M.MAX_PLAYERS, "da 2 a " .. M.MAX_PLAYERS .. " giocatori")
	g.robots = {}
	g.order = turn_order(players)
	g.mode = match_mode(players)
	g.normalized = opts.normalize or false
	g.score = C.SCORE
	g.no_points = opts.score == false
	if opts.score then
		g.score = {}
		for k, v in pairs(C.SCORE) do g.score[k] = v end
		for k, v in pairs(opts.score) do g.score[k] = v end
	end
	-- the spawn points in turn order (teammates on the same side), then the targets
	local placing = {}
	for k, i in ipairs(g.order) do placing[k] = i end
	for i, p in ipairs(players) do
		if p.dummy then placing[#placing + 1] = i end
	end
	for k, i in ipairs(placing) do
		local p = players[i]
		local sp = map.spawns[k]
		local st = make_stats(not opts.normalize and p.stats or nil)
		g.robots[i] = {
			id = i, team = p.team, x = sp.x, y = g.terrain:ground_below(sp.x, sp.from) or M.WORLD_H / 2,
			vx = 0, vy = 0, grounded = false, knocked = false, facing = sp.x < M.WORLD_W / 2 and 1 or -1,
			hp = opts.hp or st.max_hp, max_hp = st.max_hp, dead = false,
			-- for points and end-of-match results
			points = 0, damage = 0, kills = 0, env_kills = 0, deaths = 0, falls = 0,
			attack_ticks = 0, attack_turns = 0, teleports = 0, crates = 0,
			teleports_left = st.teleports,   -- teleport orbs in hand
			parachutes_left = st.parachutes, -- parachutes left for the match
			shield = nil,     -- damage the shield can still absorb
			parachute = false, -- open
			status = {},      -- status effects: type -> { turns = turns left, by = who gave it }
			parried = 0,      -- parry points earned with the current shield (config.SCORE.parry_max)
			life_damage = {}, -- damage taken from each opponent in this life: id -> hit points
			turns = 0,     -- turns played
			round_done = false, -- has already played in this round of turns
			swing = nil,   -- tick of the ongoing slash (from 0 to the end of the hit), nil if idle
			punch = nil,   -- tick of the ongoing Pugno del Titano, nil if idle
			lunge = nil,   -- ticks left of the ongoing Affondo, nil if idle
			recoil = nil,  -- ticks left of the Tonante's recoil, nil if idle
			mallet = nil,  -- tick of the ongoing Maglio hit, nil if idle
			hooked = nil,  -- hanging from the Rampino's rope: { by = who pulls, left = rope to reel in }
			hook_shot = nil, -- its hook in flight: { x, y, angle, left = cells remaining }
			ammo = make_ammo(opts.ammo),
			-- the secondary picked at the start of the match, besides the Lama (sim/draft.lua)
			secondary = p.secondary or opts.secondary,
			stats = st,
		}
		-- the primary taken in the start-of-match draft (sim/draft.lua)
		if p.pick and g.robots[i].ammo[p.pick] then g.robots[i].ammo[p.pick] = g.robots[i].ammo[p.pick] + C.DRAFT_SHOTS end
		local sec = g.robots[i].secondary
		if sec and g.robots[i].ammo[sec] then g.robots[i].ammo[sec] = g.robots[i].ammo[sec] + C.SECONDARY_SHOTS.draft end
	end
	g.events = {}
	g.tick = 0
	g.orbs = {}              -- teleport orbs in flight, oldest first
	g.orb_seq = 0
	g.match_left = M.MATCH_TICKS
	g.current = 1
	g.window = 0             -- ticks left after the first attack of the turn (0: there hasn't been one yet)
	g.round = 1              -- the current round of turns (the Crown exists from SCORE.crown_rounds + 1)
	g.final_round = false    -- the last round: points are worth SCORE.final_round times
	-- with two teams turns go in pairs (Red, Blue): ahead is the team that opens
	-- the pair, ahead_base its points when it opened it. Until the other has
	-- answered, the points scored by ahead after ahead_base are "pending"
	-- (battle/score.lua). 0 with more than two teams.
	g.ahead, g.ahead_base = 0, 0
	g.winner = nil
	g.shards = {}        -- shards in flight, by place in the burst (1..SHARD_COUNT)
	g.crates = {}
	g.placed = {}            -- placed traps and trampolines
	g.placed_id = 0
	g.heals = {}             -- healing circles { id, x, y }
	g.heals_on = opts.heals ~= false
	g.heal_id = 0
	g.crate_id = 0
	g.crate_every = opts.crate_every or M.CRATE_EVERY
	-- with an explicit crate_every that one is always used (tests need it)
	g.crate_chance = not opts.crate_every and M.CRATE_CHANCE or nil
	g.turn_no = 0
	g.order_pos = 1
	g:start_turn(g.order[1])
	return g
end

function M:emit(e)
	self.events[#self.events + 1] = e
end

function M:pop_events()
	local e = self.events
	self.events = {}
	return e
end

-- Robot / terrain collisions -------------------------------------------------

-- Collisions between robots: they are boxes that can't pass through each
-- other. Walking against another robot pushes it, but slowly (PUSH of your own speed).
M.PUSH = 0.3
-- A teleport orb landing on a robot moves it a little
M.ORB_NUDGE = 5.25
M.ORB_R = 5.25           -- orb radius, for impacts
M.GRENADE_R = 5.25       -- Uovo radius: it bounces on robots like the orb

-- The robot (other than me and alive) whose box overlaps the one with feet at (x, y).
-- A ghost (Favilla who shows the moves in a lesson) passes through and is passed through
function M:robot_at(x, y, me)
	if me and me.ghost then return nil end
	for _, o in ipairs(self.robots) do
		if o ~= me and not o.dead and not o.ghost and math.abs(x - o.x) < 2 * M.ROBOT_HALF_W
			and y < o.y + M.ROBOT_H and y + M.ROBOT_H > o.y then
			return o
		end
	end
end

-- Does the box of the robot with feet at (x, y) touch terrain or another robot?
-- me is the robot itself (so it doesn't bump into itself); without me all robots count.
function M:robot_collides(x, y, me)
	return self:terrain_collides(x, y) or self:robot_at(x, y, me) ~= nil
end

-- Half width of the capsule at the height of the cell row [a, b) (from the feet in y)
local function capsule_half(y, a, b)
	local r, h = M.ROBOT_HALF_W, M.ROBOT_H
	local low, high = y + r, y + h - r
	-- the point of the row closest to the straight part of the capsule
	local p = math.max(a, math.min(b, low))
	if p < low then
		local d = low - p
		return d < r and math.sqrt(r * r - d * d) or nil
	end
	p = math.min(b, math.max(a, high))
	if p > high then
		local d = p - high
		return d < r and math.sqrt(r * r - d * d) or nil
	end
	return r
end

function M:terrain_collides(x, y)
	local t, c = self.terrain, M.CELL
	local cy0 = math.floor(y / c)
	local cy1 = math.floor((y + M.ROBOT_H - 0.01) / c)
	for cy = cy0, cy1 do
		local hw = capsule_half(y, cy * c, cy * c + c)
		if hw and t:any_solid(math.floor((x - hw) / c), math.floor((x + hw) / c), cy, cy) then return true end
	end
	return false
end

-- Moves the robot by dx horizontally, climbing small steps. true if it succeeds.
local function step_x(g, rb, dx)
	for climb = 0, M.MAX_CLIMB do
		if not g:robot_collides(rb.x + dx, rb.y + climb, rb) then
			rb.x = rb.x + dx
			rb.y = rb.y + climb
			return true
		end
	end
	return false
end

-- rb walks into another robot: pushes it a little and follows it
function M:push(rb, dx)
	local other = self:robot_at(rb.x + dx, rb.y, rb)
	if not other then return false end
	local p = dx * M.PUSH
	if step_x(self, other, p) then
		step_x(self, rb, p)
		return true
	end
	return false
end

local function walk(g, rb, dx)
	if not step_x(g, rb, dx) then g:push(rb, dx) end
end

-- Match points ------------------------------------------------------------------
-- Earned with damage to opponents, kills (more for environmental ones: falling
-- off the map or from too high) and by hitting whoever is first in the
-- standings; dying takes some away. Numbers in config.SCORE.

-- reason says where they come from (damage, kill, death, trap, parry), other
-- is the other robot (the one hit; for death the killer). The "points" event
-- serves the UI (the number flying into the standings) and the bot arena.
function M:add_points(rb, n, reason, other)
	if self.no_points then return end
	if self.final_round then n = n * (self.score.final_round or 1) end
	rb.points = rb.points + n
	self:emit({ type = "points", robot = rb.id, amount = n, reason = reason, other = other and other.id })
end

-- Whoever has the most points (only if there's exactly one and they have more
-- than zero): hitting them is worth more. In the first SCORE.crown_rounds
-- rounds there's none: whoever plays first would be first only because they
-- already shot (Sergio, 31 October 2026).
function M:leader()
	if self.round <= (self.score.crown_rounds or 0) then return nil end
	local best, tie = nil, false
	for _, rb in ipairs(self.robots) do
		if not best or rb.points > best.points then
			best, tie = rb, false
		elseif rb.points == best.points then
			tie = true
		end
	end
	if best and not tie and best.points > 0 then return best end
end

local function enemies(a, b)
	return a ~= b and a.team ~= b.team
end

-- by moved rb without damage (Rampino, trampoline): it counts as the last hit,
-- so if rb dies within KILL_CREDIT_SECONDS the kill goes to by
function M:credit(rb, by)
	if by and enemies(by, rb) then rb.last_hit, rb.last_hit_tick = by.id, self.tick end
end

-- Takes amount hit points from rb. by is the robot that hit (nil: nobody, for
-- example a fall), reason goes in the "damage" event. Returns the damage that
-- reached life (0 if the shield took it all).
function M:hurt(rb, amount, by, reason)
	if rb.dead or amount <= 0 then return 0 end
	local foe = by and enemies(by, rb)
	if by and by ~= rb then rb.last_hit, rb.last_hit_tick = by.id, self.tick end
	if rb.status.cracked then amount = math.floor(amount * C.STATUS.cracked.damage + 0.5) end
	if rb.shield then
		-- the shield absorbs first
		local absorbed = math.min(rb.shield, amount)
		rb.shield = rb.shield - absorbed
		amount = amount - absorbed
		self:emit({ type = "shield_hit", robot = rb.id, amount = absorbed, left = rb.shield })
		-- parry: whoever carries the shield earns points for the enemy damage it stops
		if foe then
			local p = math.min(self.score.parry_max - rb.parried, absorbed * self.score.parry)
			if p > 0 then
				rb.parried = rb.parried + p
				self:add_points(rb, p, "parry", by)
			end
		end
		if rb.shield <= 0 then rb.shield = nil end
		if amount <= 0 then return 0 end
	end
	local score = self.score
	local mult = rb == self:leader() and score.leader or 1
	-- for points only the life that was really there counts
	local real = math.min(amount, rb.hp)
	rb.hp = rb.hp - amount
	self:emit({ type = "damage", robot = rb.id, amount = amount, real = real, reason = reason, by = by and by.id })
	if by and by ~= rb then
		if foe then
			by.damage = by.damage + real
			rb.life_damage[by.id] = (rb.life_damage[by.id] or 0) + real
			self:add_points(by, real * 100 / rb.stats.max_hp * score.damage * mult, "damage", rb)
		end
	end
	-- if they were first before the hit, the Crown stays even if the hit makes the killer first
	if rb.hp <= 0 then self:kill(rb, reason == "fall" and "fall_damage" or "damage", mult > 1) end
	return amount
end

-- Status effects ------------------------------------------------------------------
-- They last until the end of the next turn of whoever suffers them (or longer,
-- with stats.status_turns of whoever gives them). Numbers in config.STATUS.

function M:add_status(rb, kind, by)
	if rb.dead then return end
	local turns = by and by.stats.status_turns or 1
	local s = rb.status[kind]
	if s then
		s.turns, s.by = math.max(s.turns, turns), by and by.id
	else
		rb.status[kind] = { turns = turns, by = by and by.id }
	end
	self:emit({ type = "status", robot = rb.id, kind = kind, turns = rb.status[kind].turns })
end

-- The hit of weapon did damage: the effect it carries, if it carries one
function M:hit_status(rb, weapon, by)
	-- secondaries never leave effects (the category rule)
	if M.SECONDARY[weapon] then return end
	local kind = C.WEAPON_STATUS[weapon]
	if not kind and by and by.stats.burning_blasts > 0 and weapon == "grenade" then
		kind = "burn"
	end
	if kind then self:add_status(rb, kind, by) end
end

-- At the end of rb's turn the effects lose a turn
function M:age_status(rb)
	for kind, s in pairs(rb.status) do
		s.turns = s.turns - 1
		if s.turns <= 0 then
			rb.status[kind] = nil
			self:emit({ type = "status_end", robot = rb.id, kind = kind })
		end
	end
end

-- reason: "damage" (hits), "fell" (off the map), "fall_damage" (fall from too
-- high). The kill goes to whoever hit them last, if recently
-- (KILL_CREDIT_SECONDS): so knocking someone off counts. was_leader: whether
-- they were first before the hit that kills them (nil: look now).
function M:kill(rb, reason, was_leader)
	if rb.dead then return end
	local killer
	if rb.last_hit and self.tick - rb.last_hit_tick <= C.KILL_CREDIT_SECONDS * 60 then
		killer = self.robots[rb.last_hit]
	end
	-- died in their own turn without a recent hit from an opponent: the kill goes
	-- to whoever did them the most damage in this life (on equal damage to whoever
	-- hit them last), and they lose more
	local own = rb.id == self.current and self.phase ~= "over" and not (killer and enemies(killer, rb))
	if own then
		killer = nil
		local best = 0
		for _, o in ipairs(self.robots) do
			local dmg = rb.life_damage[o.id] or 0
			if dmg > best or (dmg > 0 and dmg == best and o.id == rb.last_hit) then killer, best = o, dmg end
		end
	end
	-- whoever jumps off by themselves doesn't give away the environmental bonus
	local env = reason ~= "damage" and not own
	local score = self.score
	if was_leader == nil then was_leader = rb == self:leader() end
	local mult = was_leader and score.leader or 1
	rb.dead = true
	rb.hp = 0
	rb.deaths = rb.deaths + 1
	if reason == "fell" then rb.falls = rb.falls + 1 end
	self:add_points(rb, score.death + (own and score.self_death or 0), "death", killer)
	local points = 0
	if killer and enemies(killer, rb) then
		killer.kills = killer.kills + 1
		points = score.kill * mult
		if env then
			killer.env_kills = killer.env_kills + 1
			points = points + score.env_kill * mult
		end
		-- Crown: whoever downs the leader gets crown extra
		if mult > 1 then points = points + score.crown end
		self:add_points(killer, points, "kill", rb)
		if self.no_points then points = 0 end
	end
	rb.last_hit = nil
	rb.respawn_in = M.RESPAWN_TICKS
	self:emit({ type = "death", robot = rb.id, reason = reason, by = killer and killer.id, env = env, points = points, own = own })
end

-- Respawn points: on steel, which can't be destroyed, so there's always ground
-- under the feet (Sergio, 29 October 2026: "sempre su parti fisse della mappa,
-- ma sempre randomici"). Every SPAWN_STEP px along the steel surfaces with room
-- for the robot above; nil if the map has none.
M.SPAWN_STEP = 24
-- minimum distance from living enemies and traps to respawn at a point
M.SPAWN_FAR = 300
M.SPAWN_TRAP = 48

function M.find_spawn_spots(t)
	local head = math.ceil(M.ROBOT_H / t.cell)
	local half = math.ceil(M.ROBOT_HALF_W / t.cell)
	local out = {}
	for x = 30, M.WORLD_W - 30, M.SPAWN_STEP do
		local cx = math.floor(x / t.cell)
		for cy = 0, t.h - 2 do
			if t:get(cx, cy) == terrain.STEEL and t:get(cx, cy + 1) == 0
				and not t:any_solid(cx - half, cx + half, cy + 1, cy + head) then
				out[#out + 1] = { x = x, y = (cy + 1) * t.cell }
			end
		end
	end
	return #out > 0 and out or nil
end

-- rb's respawn point: random among the free ones, far from living enemies
-- (SPAWN_FAR) and from traps; if there are none, the one furthest from enemies.
-- Without steel points, a random free point.
function M:spawn_spot(rb)
	local spots = self.spawn_spots
	if not spots then
		return self:surface_spot(function(x, gy) return not self:robot_collides(x, gy, rb) end)
	end
	local ok, best, best_d = {}, nil, -1
	for _, s in ipairs(spots) do
		if not self:robot_collides(s.x, s.y, rb) then
			local d = math.huge
			for _, o in ipairs(self.robots) do
				if o ~= rb and not o.dead and o.team ~= rb.team then
					local dx, dy = o.x - s.x, o.y - s.y
					d = math.min(d, math.sqrt(dx * dx + dy * dy))
				end
			end
			local trap_name = false
			for _, o in ipairs(self.placed) do
				if o.kind == "trap" and math.abs(o.x - s.x) < M.SPAWN_TRAP and math.abs(o.y - s.y) < M.SPAWN_TRAP then
					trap_name = true
				end
			end
			if not trap_name then
				if d >= M.SPAWN_FAR then ok[#ok + 1] = s end
				if d > best_d then best, best_d = s, d end
			end
		end
	end
	local s = #ok > 0 and ok[1 + math.floor(self.rng:next() * #ok)] or best
	if s then return s.x, s.y end
end

-- On death you start again with full life at a respawn point (spawn_spot).
-- Teleports and weapon shots remain.
function M:respawn(rb)
	local x, y = self:spawn_spot(rb)
	local sp = maps.get(self.map).spawns[1]
	rb.x = x or sp.x
	rb.y = y or self.terrain:ground_below(sp.x, sp.from) or M.WORLD_H / 2
	rb.vx, rb.vy, rb.grounded, rb.knocked, rb.rising, rb.sprung, rb.trapped = 0, 0, false, false, false, nil, nil
	rb.swing, rb.swing_hit, rb.swing_dir, rb.punch, rb.punch_dir, rb.fall_top = nil, nil, nil, nil, nil, nil
	rb.lunge, rb.lunge_hit, rb.hooked, rb.mallet, rb.mallet_stop, rb.recoil = nil, nil, nil, nil, nil, nil
	rb.hook_shot = nil
	rb.hp, rb.dead, rb.shield, rb.status, rb.respawn_in = rb.max_hp, false, nil, {}, nil
	rb.parachute, rb.life_damage = false, {}
	self:emit({ type = "respawn", robot = rb.id, x = rb.x, y = rb.y })
end

-- Whoever leaves the online match (ESCI DALLA PARTITA, server/room.go)
-- disappears at once: no death and no points for anyone, no respawn and no
-- more turns. If it was their turn, it passes to the next.
function M:remove(id)
	local rb = self.robots[id]
	if rb.gone or self.phase == "over" then return end
	rb.gone, rb.dead, rb.hp, rb.respawn_in = true, true, 0, nil
	local pos
	for i, p in ipairs(self.order) do
		if p == id then pos = i end
	end
	table.remove(self.order, pos)
	if pos < self.order_pos then self.order_pos = self.order_pos - 1 end
	self:emit({ type = "gone", robot = id })
	if self.current == id and #self.order > 0 then
		-- the next one is already in their place in the order: end_turn passes to them
		self.order_pos = pos - 1
		if self.projectile and self.projectile.owner == id then self.projectile = nil end
		self:end_turn()
	end
end

-- A random point on the map surface (the highest terrain under x) for which
-- ok(x, y) is true, or nil. It uses the match generator, so server and client
-- find the same point.
function M:surface_spot(ok)
	for _ = 1, 40 do
		local x = math.floor(self.rng:range(40, M.WORLD_W - 40))
		local gy = self.terrain:ground_below(x, M.WORLD_H - 1)
		if gy and gy < M.WORLD_H - 40 and ok(x, gy) then return x, gy end
	end
end

-- Fall damage (only if FALL_SAFE): counts from the highest point where the
-- descent started, even if you got there through an explosion
function M:land(rb)
	local top = rb.fall_top
	rb.fall_top = nil
	if rb.parachute then
		-- with the parachute open you land without damage, and the parachute is used up
		rb.parachute = false
		self:emit({ type = "parachute_land", robot = rb.id })
		return
	end
	if not (M.FALL_SAFE and top) then return end
	local drop = top - rb.y - M.FALL_SAFE
	if drop <= 0 then return end
	local dmg = math.floor(math.min(drop * M.FALL_DAMAGE, M.FALL_DAMAGE_MAX) * rb.stats.fall_damage_mul + 0.5)
	if dmg <= 0 then return end
	self:hurt(rb, dmg, nil, "fall")
end

-- active: it's the robot on turn and it can move (it receives the controls)
function M:update_robot(rb, input, active)
	if rb.dead then return end
	-- during the Affondo the dash drives the movement, in the Tonante's recoil the
	-- push; hanging from the Rampino, the rope
	if rb.lunge then return self:update_lunge(rb) end
	if rb.recoil then return self:update_recoil(rb) end
	if rb.hooked then return self:update_hooked(rb) end

	-- If the robot ended up inside terrain, push it out upwards
	if self:terrain_collides(rb.x, rb.y) then
		rb.y = rb.y + 1
		return
	end
	-- if it's stuck in another robot they move apart one pixel at a time
	local stuck = self:robot_at(rb.x, rb.y, rb)
	if stuck then
		local away = rb.x < stuck.x and -1 or (rb.x > stuck.x and 1 or (rb.id < stuck.id and -1 or 1))
		if not self:terrain_collides(rb.x + away, rb.y) then rb.x = rb.x + away end
	end

	local st = rb.stats
	-- slowed: run, air speed and jump reduced
	local slow = rb.status.slow and C.STATUS.slow
	local move, jump = slow and slow.move or 1, slow and slow.jump or 1
	local dir = (input.right and 1 or 0) - (input.left and 1 or 0)
	-- in a trap: feet locked, it doesn't walk or jump (it still turns, to aim)
	local locked = rb.trapped
	if dir ~= 0 then rb.facing = dir end
	if locked then dir = 0 end

	-- jump assists: the grace time after the edge and the jump asked in advance
	rb.coyote = math.max(0, (rb.coyote or 0) - 1)
	rb.jump_buf = math.max(0, (rb.jump_buf or 0) - 1)
	local want_jump = input.jump and not locked
	-- jump just pressed (holding it you don't jump again in the air)
	local pressed = want_jump and not rb.jump_held
	rb.jump_held = input.jump
	if want_jump and not rb.grounded then
		if rb.coyote > 0 then
			rb.grounded = true
		elseif pressed and active and (rb.air_left or 0) > 0 then
			-- air jump (stats.air_jumps per flight)
			rb.air_left = rb.air_left - 1
			rb.vx, rb.vy = dir * st.walk_speed * move, st.jump_vy * jump
			rb.knocked, rb.rising, rb.fall_top = false, true, nil
			self:emit({ type = "air_jump", robot = rb.id })
		else
			rb.jump_buf = M.JUMP_BUFFER_TICKS
		end
	end
	if rb.grounded then rb.air_left, rb.sprung = st.air_jumps, nil end
	if rb.grounded and rb.jump_buf > 0 then want_jump = true end

	if rb.grounded then
		if dir ~= 0 then
			walk(self, rb, dir * st.walk_speed * move * M.DT)
		end
		if want_jump then
			-- free jump: upwards, or in the direction you're moving
			rb.vx = dir * st.walk_speed * move
			rb.vy = st.jump_vy * jump
			rb.grounded = false
			rb.rising = true
			rb.coyote, rb.jump_buf = 0, 0
		elseif not self:robot_collides(rb.x, rb.y - 1, rb) then
			-- Going downhill it sticks to the terrain, otherwise it starts falling
			local landed = false
			for d = 1, M.MAX_CLIMB do
				if self:robot_collides(rb.x, rb.y - d - 1, rb) then
					rb.y = rb.y - d
					landed = true
					break
				end
			end
			if not landed then
				rb.grounded = false
				rb.vx, rb.vy = 0, 0
				rb.coyote = M.COYOTE_TICKS
			end
		end
	end

	if not rb.grounded then
		-- short jump: releasing the button while rising stops the rise
		if rb.rising and (rb.knocked or rb.vy <= 0) then rb.rising = false end
		if rb.rising and input.hold == false then
			rb.vy = rb.vy * M.JUMP_CUT
			rb.rising = false
		end
		-- with the parachute you move a bit faster, even right after being knocked
		local chute = rb.parachute and C.PARACHUTE.air_mul or 1
		if rb.parachute and active then rb.knocked, rb.sprung = false, nil end
		-- no inertia, even right after being knocked; the robot on turn never moves
		-- sideways faster than its run, except when the Molla throws it
		local air = st.air_speed * move * chute
		-- launched by the Molla: its push stays, and the controls add or take away
		-- the air speed (you counter it a little, Sergio 9 November 2026)
		if rb.sprung then
			rb.vx = rb.sprung + dir * air
		elseif dir ~= 0 then
			rb.vx = dir * air
		end
		if active and not rb.sprung then
			rb.vx = math.max(-air, math.min(air, rb.vx))
		end
		rb.vy = rb.vy - M.GRAVITY * M.DT
		if rb.parachute then rb.vy = math.max(rb.vy, -C.PARACHUTE.fall_speed) end
		if rb.vy < 0 and not rb.fall_top then rb.fall_top = rb.y end
		local landed = false
		local mx, my = rb.vx * M.DT, rb.vy * M.DT
		local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my))))
		local sx, sy = mx / steps, my / steps
		for _ = 1, steps do
			if sx ~= 0 then
				if not self:robot_collides(rb.x + sx, rb.y, rb) then
					rb.x = rb.x + sx
				elseif not self:robot_collides(rb.x + sx, rb.y + 3, rb) then
					-- small step in the air: climb over it instead of getting stuck
					rb.x, rb.y = rb.x + sx, rb.y + 3
				else
					-- against a robot in flight: nudge it a little and stop
					self:push(rb, sx)
					rb.vx, sx = 0, 0
				end
			end
			if sy ~= 0 then
				if self:robot_collides(rb.x, rb.y + sy, rb) then
					if sy < 0 then
						rb.grounded = true
						rb.knocked = false
						rb.vx = 0
						landed = true
					end
					rb.vy, sy = 0, 0
				else
					rb.y = rb.y + sy
				end
			end
		end
		if landed then self:land(rb) end
	else
		rb.fall_top = nil
	end

	if rb.y < -20 or rb.x < -20 or rb.x > M.WORLD_W + 20 then
		self:kill(rb, "fell")
	end
end

-- Missile ----------------------------------------------------------------------

local function launch_velocity(angle, power, max_speed)
	local speed = max_speed * math.max(0.1, math.min(1, power))
	return math.cos(angle) * speed, math.sin(angle) * speed
end

local function muzzle(rb, angle)
	return rb.x + math.cos(angle) * M.MUZZLE, rb.y + M.DISEGNO_H / 2 + math.sin(angle) * M.MUZZLE
end

function M:fire(angle, power)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local vx, vy = launch_velocity(angle, power, M.MISSILE_SPEED)
	self.projectile = { kind = "missile", x = x, y = y, vx = vx, vy = vy, owner = rb.id, age = 0 }
	self:emit({ type = "fire", robot = rb.id })
end

-- Uovo di Fiamma ----------------------------------------------------------------

function M:throw_grenade(angle, power)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local speed = M.GRENADE_SPEED * math.max(0.1, math.min(1, power))
	self.projectile = { kind = "grenade", x = x, y = y, vx = math.cos(angle) * speed, vy = math.sin(angle) * speed,
		owner = rb.id, age = 0, fuse = M.GRENADE_FUSE }
	self:emit({ type = "grenade", robot = rb.id })
end

-- It bounces on terrain moving one axis at a time: simple and stable on the
-- cell grid. On robots it bounces like the teleport orb.
function M:update_grenade(p)
	p.age = p.age + 1
	p.fuse = p.fuse - 1
	p.vy = p.vy - M.GRAVITY * M.GRENADE_GRAVITY * M.DT
	if p.touched and M.GRENADE_DAMPING > 0 then
		local k = 1 / (1 + M.DT * M.GRENADE_DAMPING)
		p.vx, p.vy = p.vx * k, p.vy * k
	end
	local mx, my = p.vx * M.DT, p.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	local sx, sy = mx / steps, my / steps
	local t = self.terrain
	for _ = 1, steps do
		local hit = self:body_hits_robot(p, p.x + sx, p.y + sy, M.GRENADE_R)
		if hit then
			self:bounce_on_robot(p, hit, M.GRENADE_BOUNCE, M.GRENADE_FRICTION)
			break
		end
		if self:spring(p, p.y + sy, M.GRENADE_R) then break end
		if sx ~= 0 then
			if t:solid(p.x + sx, p.y) then
				p.vx, sx = -p.vx * M.GRENADE_BOUNCE, 0
				p.touched = true
			else
				p.x = p.x + sx
			end
		end
		if sy ~= 0 then
			if t:solid(p.x, p.y + sy) then
				if sy < 0 then p.vx = p.vx * M.GRENADE_FRICTION end
				p.touched = true
				p.vy = -p.vy * M.GRENADE_BOUNCE
				-- a small bounce doesn't count: it settles
				if math.abs(p.vy) < 40 then p.vy = 0 end
				sy = 0
			else
				p.y = p.y + sy
			end
		end
	end
	if p.fuse <= 0 then
		self:explode(p.x, p.y, p.owner, M.GRENADE_BLAST, "grenade")
		self.projectile = nil
	elseif p.y < -50 or p.x < -300 or p.x > M.WORLD_W + 300 then
		self:emit({ type = "miss" })
		self.projectile = nil
	end
end

-- Sciame di Schegge --------------------------------------------------------------

function M:fire_shards(angle)
	local rb = self.robots[self.current]
	self.burst = { owner = rb.id, angle = angle, n = 0, wait = 0 }
	self:emit({ type = "shards", robot = rb.id })
end

function M:update_burst()
	local b = self.burst
	local rb = self.robots[b.owner]
	if rb.dead then
		self.burst = nil
		return
	end
	b.wait = b.wait - 1
	if b.wait > 0 then return end
	b.n = b.n + 1
	b.wait = M.SHARD_EVERY
	-- the aim stays the one of the shot, the shards come out from where the robot is
	local a = b.angle + (self.rng:next() * 2 - 1) * M.SHARD_SPREAD
	local x, y = muzzle(rb, a)
	self.shards[b.n] = { x = x, y = y, vx = math.cos(a) * M.SHARD_SPEED, vy = math.sin(a) * M.SHARD_SPEED,
		owner = rb.id, age = 0 }
	if b.n >= M.SHARD_COUNT then self.burst = nil end
end

function M:update_shards()
	for i = 1, M.SHARD_COUNT do
		local p = self.shards[i]
		if p then
			p.age = p.age + 1
			p.vy = p.vy - M.GRAVITY * M.SHARD_GRAVITY * M.DT
			local mx, my = p.vx * M.DT, p.vy * M.DT
			local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
			for _ = 1, steps do
				if self:spring(p, p.y + my / steps, 0) then break end
				p.x = p.x + mx / steps
				p.y = p.y + my / steps
				if self.terrain:solid(p.x, p.y) or self:hits_robot(p.x, p.y, p.owner, p.age) then
					self:explode(p.x, p.y, p.owner, M.SHARD_BLAST, "shards")
					self.shards[i] = nil
					break
				end
			end
			-- above the map too: gravity barely bends them, so one shot upwards would
			-- come back down only after more than a minute, holding the turn (and the camera)
			if self.shards[i] and (p.y < -50 or p.x < -300 or p.x > M.WORLD_W + 300 or p.y > M.WORLD_H + 300) then
				self.shards[i] = nil
			end
		end
	end
end

function M:shards_flying()
	if self.burst then return true end
	for i = 1, M.SHARD_COUNT do
		if self.shards[i] then return true end
	end
	return false
end

-- Teleport -----------------------------------------------------------------

function M:throw_orb(angle, power)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local vx, vy = launch_velocity(angle, power, M.ORB_SPEED)
	self.orb_seq = self.orb_seq + 1
	self.orbs[#self.orbs + 1] = { id = self.orb_seq, x = x, y = y, vx = vx, vy = vy, owner = rb.id,
		timer = rb.stats.teleport_ticks, age = 0 }
	self:emit({ type = "orb", robot = rb.id })
end

-- Look for a free point near (x, y) to make the robot appear
-- Points where the robot can appear around the orb, from nearest to furthest
-- (at equal distance the higher ones first)
M.TELEPORT_SEARCH = 84
local OFFSETS = {}
local function teleport_offsets(r)
	local key = math.floor(r)
	if OFFSETS[key] then return OFFSETS[key] end
	-- 2 pixel steps up to 48, then proportional: always about 1800 points
	local step = math.max(2, math.floor(key / 24))
	local list = {}
	for dy = -key, key, step do
		for dx = -key, key, step do
			if dx * dx + dy * dy <= key * key then list[#list + 1] = { dx, dy, dx * dx + dy * dy } end
		end
	end
	table.sort(list, function(a, b)
		if a[3] ~= b[3] then return a[3] < b[3] end
		if a[2] ~= b[2] then return a[2] > b[2] end
		return a[1] < b[1]
	end)
	OFFSETS[key] = list
	return list
end

-- The teleport always happens: at the free point nearest the orb and, if
-- everything around is full, right there (the robot then gets out of the terrain upwards).
function M:teleport(rb, x, y)
	local tx, ty = x, y
	for _, o in ipairs(teleport_offsets(M.TELEPORT_SEARCH)) do
		if not self:robot_collides(x + o[1], y + o[2], rb) then
			tx, ty = x + o[1], y + o[2]
			break
		end
	end
	local fx, fy = rb.x, rb.y
	rb.x, rb.y = tx, ty
	-- the state stays identical: whoever was falling keeps falling at the same speed.
	-- It no longer rests on anything, physics puts it back on the ground if needed.
	rb.grounded = false
	rb.fall_top = nil
	self:emit({ type = "teleport", robot = rb.id, from_x = fx, from_y = fy, x = tx, y = ty })
end

-- Orb bounce and roll
M.ORB_BOUNCE = 0.4       -- how much speed is left in the bounce
M.ORB_FRICTION = 1       -- friction along the surface, for each tick in contact

-- Direction out of the terrain around (x, y): the opposite of the average of
-- the nearby full cells
local function surface_normal(t, x, y)
	local c = M.CELL
	local cx, cy = math.floor(x / c), math.floor(y / c)
	local nx, ny = 0, 0
	for oy = -3, 3 do
		for ox = -3, 3 do
			if ox * ox + oy * oy <= 9 and t:get(cx + ox, cy + oy) ~= 0 then
				nx, ny = nx - ox, ny - oy
			end
		end
	end
	local d = math.sqrt(nx * nx + ny * ny)
	if d < 1e-6 then return 0, 1 end
	return nx / d, ny / d
end

-- The robot the orb bumps into at (x, y), or nil. Whoever threw it only counts
-- after a moment, so the orb doesn't bounce in their face.
-- The robot touched by a round body of radius r at (x, y) (orb, Uovo), or nil.
-- Whoever threw it doesn't touch it in the first OWNER_SAFE_TICKS.
function M:body_hits_robot(o, x, y, r)
	for _, rb in ipairs(self.robots) do
		if not rb.dead and (rb.id ~= o.owner or o.age > M.OWNER_SAFE_TICKS) and M.hurt_at(rb, x, y, r) then
			return rb
		end
	end
end

-- Body o bounces on the box of robot hit and, if it comes in hard, moves it a tiny bit
function M:bounce_on_robot(o, hit, bounce, friction)
	local sx, sy = 0, 1
	if o.y < hit.y + M.ROBOT_H - 2 then sx, sy = o.x < hit.x and -1 or 1, 0 end
	local vn = o.vx * sx + o.vy * sy
	if vn < -40 then
		local d = (o.vx < 0 and -1 or 1)
		if sy == 0 then d = -sx end
		step_x(self, hit, d * M.ORB_NUDGE)
	end
	if vn < 0 then
		local e = vn < -60 and bounce or 0
		local tx, ty = o.vx - vn * sx, o.vy - vn * sy
		o.vx = tx * friction - e * vn * sx
		o.vy = ty * friction - e * vn * sy
	end
	o.touched = true
end

-- Updates an orb; returns false when it's done (teleport done)
function M:update_orb(o)
	local rb = self.robots[o.owner]
	if rb.dead then return false end
	o.age = (o.age or 0) + 1
	-- flies like the missile; when it touches terrain it bounces and rolls.
	-- If it leaves the map it keeps falling: the teleport takes you there anyway.
	local t = self.terrain
	o.vy = o.vy - M.GRAVITY * M.ORB_GRAVITY * M.DT
	if o.touched and M.ORB_DAMPING > 0 then
		local k = 1 / (1 + M.DT * M.ORB_DAMPING)
		o.vx, o.vy = o.vx * k, o.vy * k
	end
	local mx, my = o.vx * M.DT, o.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	for _ = 1, steps do
		local nx, ny = o.x + mx / steps, o.y + my / steps
		local hit = self:body_hits_robot(o, nx, ny, M.ORB_R)
		if hit then
			self:bounce_on_robot(o, hit, M.ORB_BOUNCE, M.ORB_FRICTION)
			break
		elseif self:spring(o, ny, M.ORB_R) then
			break
		elseif t:solid(nx, ny) then
			local sx, sy = surface_normal(t, nx, ny)
			local vn = o.vx * sx + o.vy * sy
			if vn < 0 then
				-- removes the part of velocity against the terrain (and sends some back if
				-- the impact is strong), slows the part along the surface
				local e = vn < -60 and M.ORB_BOUNCE or 0
				local tx, ty = o.vx - vn * sx, o.vy - vn * sy
				o.vx = tx * M.ORB_FRICTION - e * vn * sx
				o.vy = ty * M.ORB_FRICTION - e * vn * sy
			end
			o.touched = true
			break
		end
		o.x, o.y = nx, ny
	end
	o.timer = o.timer - 1
	if o.timer <= 0 then
		-- the orb is at the centre of the robot, the robot's position is at the feet
		self:teleport(rb, o.x, o.y - M.ROBOT_H / 2)
		return false
	end
	return true
end

-- All the orbs in flight, oldest first: each one teleports when its time is up
function M:update_orbs()
	local orbs, n = self.orbs, 0
	for i = 1, #orbs do
		local o = orbs[i]
		if self:update_orb(o) then
			n = n + 1
			orbs[n] = o
		end
	end
	for i = #orbs, n + 1, -1 do orbs[i] = nil end
	-- orbs also bump into each other: they separate and swap momentum
	for i = 1, n - 1 do
		local a = orbs[i]
		for j = i + 1, n do
			local b = orbs[j]
			local dx, dy = b.x - a.x, b.y - a.y
			local d2 = dx * dx + dy * dy
			local min = 2 * M.ORB_R
			if d2 < min * min then
				local d = math.sqrt(d2)
				if d < 1e-6 then dx, dy, d = 1, 0, 1 end
				local ux, uy = dx / d, dy / d
				local half = (min - d) / 2
				a.x, a.y = a.x - ux * half, a.y - uy * half
				b.x, b.y = b.x + ux * half, b.y + uy * half
				local va, vb = a.vx * ux + a.vy * uy, b.vx * ux + b.vy * uy
				if va - vb > 0 then
					a.vx, a.vy = a.vx + (vb - va) * ux, a.vy + (vb - va) * uy
					b.vx, b.vy = b.vx + (va - vb) * ux, b.vy + (va - vb) * uy
				end
			end
		end
	end
end

-- Cecchino --------------------------------------------------------------------------

function M:fire_sniper(angle)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	self.projectile = { kind = "sniper", x = x, y = y, vx = math.cos(angle) * M.SNIPER_SPEED,
		vy = math.sin(angle) * M.SNIPER_SPEED, owner = rb.id, age = 0, bounces = 0 }
	self:emit({ type = "sniper", robot = rb.id })
end

-- Bounce like a ball on the terrain surface at (x, y): the part of the
-- velocity against the surface flips and is damped (bounce_normal), the one
-- along the surface slows a little (bounce_tangent): each bounce is lower and
-- slower
local function bounce(t, x, y, vx, vy)
	local nx, ny = surface_normal(t, x, y)
	local d = vx * nx + vy * ny
	local tx, ty = vx - d * nx, vy - d * ny
	local s = C.SNIPER
	d = math.abs(d) * s.bounce_normal
	return tx * s.bounce_tangent + nx * d, ty * s.bounce_tangent + ny * d
end

-- One tick of flight: it starts fast and slows down (drag), gravity grows
-- little by little up to drop times the robots' gravity in drop_ramp seconds,
-- so at first it goes almost straight and then drops more and more
local function sniper_step(vx, vy, age)
	local s = C.SNIPER
	local g = M.GRAVITY * s.drop * math.min(1, age / (s.drop_ramp * 60))
	local k = s.drag ^ M.DT
	return vx * k, (vy - g * M.DT) * k
end

function M:update_sniper(p)
	p.age = p.age + 1
	p.vx, p.vy = sniper_step(p.vx, p.vy, p.age)
	local mx, my = p.vx * M.DT, p.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	local t = self.terrain
	for _ = 1, steps do
		local nx, ny = p.x + p.vx * M.DT / steps, p.y + p.vy * M.DT / steps
		local hit = self:body_hits_robot(p, nx, ny, 0)
		if hit then
			self:sniper_hit(p, hit)
			self.projectile = nil
			return
		elseif self:spring(p, ny, 0) then
			break
		elseif t:solid(nx, ny) then
			p.bounces = p.bounces + 1
			p.vx, p.vy = bounce(t, nx, ny, p.vx, p.vy)
			-- too many bounces or almost still: it dies out there
			if p.bounces > C.SNIPER.bounces or p.vx * p.vx + p.vy * p.vy < C.SNIPER.min_speed ^ 2 then
				self:emit({ type = "sniper_end", x = p.x, y = p.y })
				self.projectile = nil
				return
			end
			self:emit({ type = "sniper_bounce", x = p.x, y = p.y })
			break
		end
		p.x, p.y = nx, ny
	end
	if p.age > M.SNIPER_LIFE or p.y < -50 or p.x < -300 or p.x > M.WORLD_W + 300 or p.y > M.WORLD_H + 300 then
		self:emit({ type = "miss" })
		self.projectile = nil
	end
end

-- The hit knocks the target in the direction it was going
function M:sniper_hit(p, rb)
	local sp = math.sqrt(p.vx * p.vx + p.vy * p.vy)
	local k = self:knock_mul(rb)
	local s = C.SNIPER
	rb.vx = p.vx / sp * s.push * k
	rb.vy = (p.vy / sp * s.push + s.lift) * k
	rb.grounded, rb.knocked, rb.fall_top = false, true, nil
	self:emit({ type = "sniper_hit", robot = p.owner, target = rb.id, x = p.x, y = p.y })
	local by = self.robots[p.owner]
	if self:hurt(rb, C.SNIPER.damage, by) > 0 and by ~= rb then self:hit_status(rb, "sniper", by) end
end

-- Sniper aim line: the first second of flight (like the real shot, tick by
-- tick); a bounce ends it at once
M.SNIPER_PREVIEW_TICKS = 60
function M:sniper_preview(x, y, angle, count, pts)
	pts = pts or {}
	local vx, vy = math.cos(angle) * M.SNIPER_SPEED, math.sin(angle) * M.SNIPER_SPEED
	local t, n, after = self.terrain, 0, nil
	local shown = M.SNIPER_PREVIEW_TICKS
	for i = 1, shown do
		vx, vy = sniper_step(vx, vy, i)
		local nx, ny = x + vx * M.DT, y + vy * M.DT
		if t:solid(nx, ny) then
			if after then break end
			vx, vy = bounce(t, nx, ny, vx, vy)
			after = 0
		else
			x, y = nx, ny
			if after then
				after = after + 1
				if after > 4 then break end
			end
			-- the points spaced along the shown stretch
			if i % math.max(1, math.floor(shown / count)) == 0 and n < count then
				n = n + 1
				local pt = pts[n] or {}
				pt.x, pt.y = x, y
				pts[n] = pt
			end
		end
	end
	-- the leftover points stay on the last one
	for i = n + 1, count do
		local pt = pts[i] or {}
		pt.x, pt.y = x, y
		pts[i] = pt
	end
	return pts
end

-- Straight shots: Tonante and Rampino (config.EAGLE, config.HOOK) --------------------
-- Instant: no projectile to follow, a ray over the terrain cells like the aim line.

-- The ray from (x, y) in direction angle, at most range long: where it stops
-- and the robot it meets (nil if it stops on terrain or at the end of its run).
-- The shooter (me) doesn't hit itself.
function M:ray(x, y, angle, range, me)
	local dx, dy = math.cos(angle) * M.CELL, math.sin(angle) * M.CELL
	local t = self.terrain
	for _ = 1, math.ceil(range / M.CELL) do
		local nx, ny = x + dx, y + dy
		if t:solid(nx, ny) then return x, y, nil end
		x, y = nx, ny
		for _, rb in ipairs(self.robots) do
			if rb ~= me and not rb.dead and M.hurt_at(rb, x, y, 0) then return x, y, rb end
		end
	end
	return x, y, nil
end

-- Aim line of straight shots: count points up to the terrain or the end of the run
function M:ray_preview(x, y, angle, range, count, pts)
	pts = pts or {}
	local ex, ey = self:ray(x, y, angle, range, self.robots[self.current])
	for i = 1, count do
		local pt = pts[i] or {}
		pt.x, pt.y = x + (ex - x) * i / count, y + (ey - y) * i / count
		pts[i] = pt
	end
	return pts
end

-- Tonante: flat damage to whoever is on the line; the recoil pushes the
-- shooter the opposite way (from the ground also a bit upwards), so they reposition
function M:fire_eagle(angle)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local ex, ey, hit = self:ray(x, y, angle, C.EAGLE.range, rb)
	rb.facing = math.cos(angle) < 0 and -1 or 1
	local s = C.EAGLE
	rb.recoil = s.recoil_ticks
	rb.recoil_vx, rb.recoil_vy = -math.cos(angle) * s.recoil, -math.sin(angle) * s.recoil
	rb.grounded, rb.knocked, rb.fall_top = false, false, nil
	self:emit({ type = "eagle", robot = rb.id, x0 = x, y0 = y, x1 = ex, y1 = ey, target = hit and hit.id })
	if hit then self:hurt(hit, s.damage, rb) end
end

-- One tick of the Tonante's recoil, in place of the robot's normal physics:
-- fixed speed, no gravity; against terrain or a robot it slides on the free
-- axis (horizontally it climbs steps as when walking), and if both are blocked
-- it stops.
function M:update_recoil(rb)
	local mx, my = rb.recoil_vx * M.DT, rb.recoil_vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my))))
	local sx, sy = mx / steps, my / steps
	for _ = 1, steps do
		if not self:robot_collides(rb.x + sx, rb.y + sy, rb) then
			rb.x, rb.y = rb.x + sx, rb.y + sy
		elseif sx ~= 0 and step_x(self, rb, sx) then
			-- slide horizontally, climbing small steps as when walking
		elseif sy ~= 0 and not self:robot_collides(rb.x, rb.y + sy, rb) then
			rb.y = rb.y + sy
		else
			rb.recoil = 1
			break
		end
	end
	rb.recoil = rb.recoil - 1
	if rb.recoil <= 0 then
		rb.vx, rb.vy = 0, 0
		rb.recoil, rb.recoil_vx, rb.recoil_vy = nil, nil, nil
	end
	if rb.y < -20 or rb.x < -20 or rb.x > M.WORLD_W + 20 then self:kill(rb, "fell") end
end

local HOOK_LAND_DX = { 0, -8, 8, -16, 16 }

-- Rampino (item, one per turn, config.HOOK): the hook flies straight from the
-- muzzle (rb.hook_shot) at shot_speed up to range. On a robot, that one hangs
-- from the rope (rb.hooked.by) and is reeled towards the puller's hand
-- (config.HOOK.reel pixels at most), without damage. On terrain it's the
-- puller who hangs (rb.hooked.x, y = the point hit) and climbs along the rope
-- up there, then stands on top of the platform hit. At the end of the run with
-- nothing: a miss ("hook" event without target or anchor).
function M:fire_hook(angle)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	rb.facing = math.cos(angle) < 0 and -1 or 1
	-- left: cells still to travel, like the instant ray
	rb.hook_shot = { x = x, y = y, x0 = x, y0 = y, angle = angle, left = math.ceil(C.HOOK.range / M.CELL) }
	self:emit({ type = "hook_shot", robot = rb.id, x0 = x, y0 = y, angle = angle })
end

-- One tick of the hook in flight: it advances like the ray (M.ray) and stops
-- on the first robot or on terrain, or at the end of the run
function M:update_hook_shot(rb)
	local h = rb.hook_shot
	local n = math.min(math.ceil(C.HOOK.shot_speed * M.DT / M.CELL), h.left)
	local ex, ey, hit = self:ray(h.x, h.y, h.angle, n * M.CELL, rb)
	h.left = h.left - n
	local dx, dy = math.cos(h.angle) * M.CELL, math.sin(h.angle) * M.CELL
	local anchor = not hit and self.terrain:solid(ex + dx, ey + dy)
	h.x, h.y = ex, ey
	if not hit and not anchor and h.left > 0 then return end
	rb.hook_shot = nil
	self:emit({ type = "hook", robot = rb.id, x0 = h.x0, y0 = h.y0, x1 = ex, y1 = ey, target = hit and hit.id, anchor = anchor })
	if hit then
		hit.hooked = { by = rb.id, left = C.HOOK.reel }
		-- the puller gets the kill if the enemy falls (KILL_CREDIT_SECONDS)
		self:credit(hit, rb)
		hit.vx, hit.vy = 0, 0
		hit.grounded, hit.knocked, hit.fall_top = false, true, nil
	elseif anchor then
		-- the rope hooks inside the full cell, so we know where to climb from
		rb.hooked = { x = ex + dx, y = ey + dy, left = C.HOOK.range }
		rb.vx, rb.vy = 0, 0
		rb.grounded, rb.knocked, rb.fall_top = false, false, nil
	end
end

-- Where the puller's hand is (the rope starts from there)
function M.hook_hand(by)
	return by.x + by.facing * M.MUZZLE * 0.5, by.y + M.SWORD_PIVOT_Y
end

-- One tick of rope, in place of the robot's normal physics: it goes straight
-- towards the puller's hand (which can move meanwhile) or towards the hooked
-- terrain point, until the rope is fully reeled or something stops it. Whoever
-- was pulled falls where they are; whoever climbed a platform stands on it.
function M:update_hooked(rb)
	local h = rb.hooked
	local by = h.by and self.robots[h.by]
	local hx, hy
	if by then hx, hy = M.hook_hand(by) else hx, hy = h.x, h.y end
	local cx, cy = rb.x, rb.y + M.ROBOT_H / 2
	local dx, dy = hx - cx, hy - cy
	local dist = math.sqrt(dx * dx + dy * dy)
	local step = math.min((by and C.HOOK.speed or C.HOOK.climb_speed) * M.DT, h.left, dist)
	local stopped = (by and by.dead) or dist < 1
	if not stopped then
		local ux, uy = dx / dist, dy / dist
		local n = math.max(1, math.ceil(step))
		for _ = 1, n do
			local nx, ny = rb.x + ux * step / n, rb.y + uy * step / n
			if self:robot_collides(nx, ny, rb) then
				-- pulled by a robot: the terrain below doesn't stop it, it slides over steps
				-- and slopes as when walking (hook_slide)
				nx, ny = self:hook_slide(rb, nx, ny, by)
				if not nx then
					stopped = true
					break
				end
			end
			rb.x, rb.y = nx, ny
		end
		h.left = h.left - step
	end
	if stopped or h.left <= 0.5 then
		rb.hooked = nil
		-- reached the terrain (the capsule stops it a step from the point, or against
		-- the bottom of the platform when climbing diagonally): on top
		if not by then
			local ex, ey = h.x - rb.x, h.y - rb.y - M.ROBOT_H / 2
			if ex * ex + ey * ey < C.HOOK.grab * C.HOOK.grab then self:hook_land(rb, h.x, h.y) end
		end
		-- snap: the rope pulled by a robot ran out before arriving, the pulled one
		-- stays there (over the void it falls): in the drawing it breaks
		self:emit({ type = "hook_end", robot = rb.id, by = h.by, snap = by and not stopped or nil })
	end
	if rb.y < -20 or rb.x < -20 or rb.x > M.WORLD_W + 20 then self:kill(rb, "fell") end
end

-- The robot pulled by the rope hits terrain at (nx, ny): instead of stopping
-- it is lifted a little (up to MAX_CLIMB, like a step) or, if the rope pulls
-- downwards, kept at its height, so the floor, a slope or a one-pixel ledge
-- don't break the grab. Returns where it goes, or nil if a wall or a robot
-- stops it (the puller: it has arrived). Only for the pulled one (by): whoever
-- climbs along the rope onto terrain stops at the platform.
function M:hook_slide(rb, nx, ny, by)
	if not by or self:robot_at(nx, ny, rb) then return nil end
	local y = math.max(ny, rb.y)
	for climb = 0, M.MAX_CLIMB do
		if not self:robot_collides(nx, y + climb, rb) then return nx, y + climb end
	end
end

-- Puts the robot standing on top of the platform hit by the Rampino: from the
-- hooked cell it goes up the column to the first empty cell (at most
-- config.HOOK.climb pixels), shifting a little sideways if it doesn't fit
-- there. If the top is too high (the side of a wall), it stays where it is and falls.
function M:hook_land(rb, ax, ay)
	local t, c = self.terrain, M.CELL
	local cx, cy = math.floor(ax / c), math.floor(ay / c)
	for i = 1, math.ceil(C.HOOK.climb / c) do
		if t:get(cx, cy + i) == 0 then
			local y = (cy + i) * c
			for _, ox in ipairs(HOOK_LAND_DX) do
				local x = cx * c + c / 2 + ox
				if not self:robot_collides(x, y, rb) then
					rb.x, rb.y, rb.vx, rb.vy = x, y, 0, 0
					return
				end
			end
			return
		end
	end
end

-- Mantice (config.BELLOWS) --------------------------------------------------------
-- The forge's blast: instant, a fan in front of the user.
-- It hits every robot with its centre within range and within cone of the aim,
-- if there's no terrain between the two (other robots don't shelter), and
-- pushes it along the aim: hard up close, far times less at the edge. The user
-- stays where they are.

-- is there terrain between (x0, y0) and (x1, y1)?
function M:terrain_between(x0, y0, x1, y1)
	local dx, dy = x1 - x0, y1 - y0
	local n = math.ceil(math.sqrt(dx * dx + dy * dy) / M.CELL)
	for i = 1, n do
		if self.terrain:solid(x0 + dx * i / n, y0 + dy * i / n) then return true end
	end
	return false
end

function M:fire_bellows(angle)
	local rb = self.robots[self.current]
	local s = C.BELLOWS
	rb.facing = math.cos(angle) < 0 and -1 or 1
	local cx, cy = rb.x, rb.y + M.DISEGNO_H / 2
	local ux, uy = math.cos(angle), math.sin(angle)
	local x, y = muzzle(rb, angle)
	self:emit({ type = "bellows", robot = rb.id, x = x, y = y, angle = angle })
	for _, o in ipairs(self.robots) do
		if o ~= rb and not o.dead then
			local ox, oy = o.x, o.y + M.HURT_Y
			local dx, dy = ox - cx, oy - cy
			local d = math.sqrt(dx * dx + dy * dy)
			-- inside the fan: the angle from the aim within cone (cosine, no acos)
			if d <= s.range and dx * ux + dy * uy >= d * math.cos(s.cone) and not self:terrain_between(cx, cy, ox, oy) then
				local f = (1 - (1 - s.far) * d / s.range) * self:knock_mul(o)
				o.vx, o.vy = ux * s.push * f, (uy * s.push + s.lift) * f
				o.hooked = nil
				o.grounded, o.knocked, o.fall_top = false, true, nil
				self:emit({ type = "bellows_hit", robot = rb.id, target = o.id, x = ox, y = oy })
				-- the user gets the kill if the enemy falls (even with a shield that parries everything)
				self:credit(o, rb)
				self:hurt(o, s.damage, rb)
			end
		end
	end
end

-- Maglio (config.MALLET) -----------------------------------------------------------
-- Two-handed hammer that swings around the shoulder like the Lama: aiming
-- straight it starts high behind the head, comes down in front and ends below
-- the feet; the arc rotates with the aim (Sergio, 30 Oct: "direzionale come la
-- mira della spada"), so aiming down it also reaches behind the feet and
-- aiming up above the head. It hits each robot it touches along the arc once;
-- the head stops on terrain. The first time it slams into something, a robot
-- or terrain, the attacker bounces up (pogo), on the ground as in the air; on
-- a miss no (Sergio, 30 Oct).

function M:start_mallet(angle)
	local rb = self.robots[self.current]
	rb.mallet_base, rb.facing = M.aim_side(angle)
	rb.mallet = 0
	rb.mallet_dir = rb.facing
	rb.mallet_hit, rb.mallet_stop, rb.mallet_bounced = {}, nil, false
	self:emit({ type = "mallet", robot = rb.id })
end

-- Curve of the Maglio swing: like a real person, it first brings the weapon a
-- little back (wind-up, about 13°) and then speeds up more and more to the end.
-- It's a "back ease-in": it goes below zero at the start and reaches 1 at top speed.
local ARC_WINDUP = 1.2
local function arc_progress(u)
	u = math.max(0, math.min(1, u))
	local s = ARC_WINDUP
	return u * u * ((s + 1) * u - s)
end

-- Hammer angle at tick t, for a robot facing right aiming at base (turned
-- right, 0 straight): wind-up backwards, then faster and faster
-- (arc_progress); stopped on terrain at tick stop it stays there.
function M.mallet_angle(t, base, stop)
	local s = C.MALLET
	if stop then t = math.min(t, stop) end
	return (base or 0) + s.from + (s.to - s.from) * arc_progress(t / s.ticks)
end

-- The first impact of the swing, on a robot or on terrain, bounces you up
function M:mallet_bounce(rb)
	if rb.mallet_bounced then return false end
	rb.mallet_bounced = true
	rb.vy, rb.grounded, rb.knocked, rb.fall_top = C.MALLET.bounce, false, false, nil
	return true
end

function M:mallet_hit(rb, other)
	local bounce = self:mallet_bounce(rb)
	self:emit({ type = "mallet_hit", robot = rb.id, target = other.id, x = other.x, y = other.y + M.HURT_Y, bounce = bounce })
	self:hurt(other, C.MALLET.damage, rb)
end

function M:update_mallet(rb)
	local s = C.MALLET
	local t0 = rb.mallet
	rb.mallet = t0 + 1
	if not rb.mallet_stop and t0 < s.ticks then
		local t, x, y = self:sweep_arc(rb, t0, M.mallet_angle, s.reach, rb.mallet_dir, rb.mallet_hit, M.mallet_hit,
			rb.mallet_base)
		if t then
			rb.mallet_stop = t
			local bounce = self:mallet_bounce(rb)
			self:emit({ type = "mallet_hit", robot = rb.id, x = x, y = y, bounce = bounce })
		end
	end
	if rb.mallet >= s.ticks + s.hold then
		rb.mallet, rb.mallet_dir, rb.mallet_hit, rb.mallet_stop, rb.mallet_bounced, rb.mallet_base = nil, nil, nil, nil, nil, nil
	end
end

-- Lama di Nucleo ----------------------------------------------------------------

-- Blade angle at tick t for a robot facing right: depends on the aim, base is
-- the aim angle (already turned right).
function M.sword_angle(t, base)
	return (base or 0) + math.rad(M.melee_pose(melee.slash, t)[7])
end

-- Fist angle at tick t, like sword_angle
function M.punch_angle(t, base)
	return (base or 0) + math.rad(M.melee_pose(melee.uppercut, t)[7])
end

-- Length in ticks of a melee.lua hit
function M.melee_ticks(hit_def)
	return math.ceil((#hit_def.pose - 1) * 60 / hit_def.fps)
end

-- Pose of the hit at tick t (with fraction): the values between two frames
local POSE_CACHE = {}
function M.melee_pose(hit_def, t)
	local f = math.max(0, math.min(#hit_def.pose - 1, t * hit_def.fps / 60))
	local i = math.floor(f)
	local a, b = hit_def.pose[i + 1], hit_def.pose[math.min(#hit_def.pose, i + 2)]
	local k = f - i
	for j = 1, 7 do POSE_CACHE[j] = a[j] + (b[j] - a[j]) * k end
	return POSE_CACHE
end

-- Aim turned to the right, between -90° and 90°, and the side being faced
local function aim_side(angle)
	local dir = math.cos(angle) < 0 and -1 or 1
	local a = dir > 0 and angle or math.pi - angle
	a = (a + math.pi) % (2 * math.pi) - math.pi
	return a, dir
end
M.aim_side = aim_side

-- A robot hit by point (x, y), with a margin pad around it
function M.hurt_at(r, x, y, pad)
	pad = pad or 0
	local dx, dy = x - r.x, y - (r.y + M.HURT_Y)
	local rr = M.HURT_R + pad
	return dx * dx + dy * dy <= rr * rr
end

-- A robot touched by segment (x0, y0) - (x1, y1), 2 * pad wide
local function seg_hits_robot(r, x0, y0, x1, y1, pad)
	local cx, cy = r.x, r.y + M.HURT_Y
	local ux, uy = x1 - x0, y1 - y0
	local l2 = ux * ux + uy * uy
	local k = l2 > 0 and math.max(0, math.min(1, ((cx - x0) * ux + (cy - y0) * uy) / l2)) or 0
	local dx, dy = x0 + ux * k - cx, y0 + uy * k - cy
	local rr = M.HURT_R + pad
	return dx * dx + dy * dy <= rr * rr
end

function M:swing_sword(angle)
	local rb = self.robots[self.current]
	rb.swing_base, rb.facing = aim_side(angle)
	-- the slash stays in the starting direction even if the robot turns
	rb.swing_dir = rb.facing
	rb.swing = 0
	rb.swing_hit = {}
	self:emit({ type = "swing", robot = rb.id })
end

local function in_robot(r, x, y)
	return M.hurt_at(r, x, y, 0)
end

-- at the end the weapon swings fast: many steps per tick, so it doesn't skip a target
local ARC_SUBSTEPS = 8
local ARC_SAMPLES = 10
-- where to look if the Maglio's head touches terrain: across the weapon
local HEAD_SIDE = { 0, -5, 5 }

-- One tick of a weapon reach long swinging around rb's shoulder (the Maglio),
-- from t0 to t0 + 1: angle(t, base) is its angle for a robot facing right
-- aiming at base, dir the side of the swing. Every robot touched along the
-- weapon gets hit once (hit(self, rb, other, t), marked in done). The tip stops
-- on terrain: returns the tick (with the fraction) and the impact point.
function M:sweep_arc(rb, t0, angle, reach, dir, done, hit, base)
	local px, py = rb.x, rb.y + M.SWORD_PIVOT_Y
	for s = 1, ARC_SUBSTEPS do
		local t = t0 + s / ARC_SUBSTEPS
		local a = angle(t, base)
		local cx, cy = math.cos(a) * dir, math.sin(a)
		for _, other in ipairs(self.robots) do
			if other ~= rb and not other.dead and not done[other.id] then
				for k = 1, ARC_SAMPLES do
					local d = reach * k / ARC_SAMPLES
					if in_robot(other, px + cx * d, py + cy * d) then
						done[other.id] = true
						hit(self, rb, other, t)
						break
					end
				end
			end
		end
		local hx, hy = px + cx * reach, py + cy * reach
		for _, w in ipairs(HEAD_SIDE) do
			if self.terrain:solid(hx - cy * w, hy + cx * w) then return t, hx, hy end
		end
	end
end

function M:update_swing(rb)
	if self:update_melee(rb, melee.slash, rb.swing, rb.swing_base, rb.swing_dir) then
		rb.swing = rb.swing + 1
	else
		rb.swing, rb.swing_hit, rb.swing_dir, rb.swing_base = nil, nil, nil, nil
	end
end

function M:sword_hit(rb, other)
	self:emit({ type = "sword_hit", robot = rb.id, target = other.id })
	-- the sword only does damage and stops the target
	other.vx, other.vy = 0, 0
	self:hurt(other, M.SWORD_DAMAGE, rb)
	-- hitting an enemy with the Lama gives back one shot of the drafted secondary
	local sec = rb.secondary
	if sec and other.team ~= rb.team and rb.ammo[sec] < C.SECONDARY_SHOTS.max then
		rb.ammo[sec] = rb.ammo[sec] + 1
		self:emit({ type = "recharge", robot = rb.id, weapon = sec })
	end
end

-- Affondo (config.LUNGE) -----------------------------------------------------------
-- Dash in the aim direction passing through robots, hitting each once with the
-- body or the spear; it climbs small steps and slides along terrain, it stops
-- only when nothing passes at all.

function M:start_lunge(angle)
	local rb = self.robots[self.current]
	rb.facing = math.cos(angle) < 0 and -1 or 1
	rb.lunge = C.LUNGE.ticks
	rb.lunge_vx, rb.lunge_vy = math.cos(angle) * C.LUNGE.speed, math.sin(angle) * C.LUNGE.speed
	rb.lunge_hit = {}
	rb.grounded, rb.knocked = false, false
	self:emit({ type = "lunge", robot = rb.id, angle = angle })
end

-- Where a dash step from (x, y) by (dx, dy) goes: straight, or climbing a step
-- up to climb, or only the horizontal or vertical part that passes.
-- nil if nothing passes.
function M:lunge_step(rb, dx, dy)
	local x, y = rb.x + dx, rb.y + dy
	if not self:terrain_collides(x, y) then return x, y end
	if math.abs(dx) <= 0.05 then
		return nil
	end
	for d = 1, C.LUNGE.climb do
		if not self:terrain_collides(x, y + d) then return x, y + d end
	end
	if not self:terrain_collides(x, rb.y) then return x, rb.y end
	if math.abs(dy) > 0.05 and not self:terrain_collides(rb.x, y) then return rb.x, y end
end

-- One tick of dash: in place of the robot's normal physics (update_robot)
function M:update_lunge(rb)
	local mx, my = rb.lunge_vx * M.DT, rb.lunge_vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my))))
	local len = math.sqrt(rb.lunge_vx ^ 2 + rb.lunge_vy ^ 2)
	local ux, uy = rb.lunge_vx / len, rb.lunge_vy / len
	local stopped = false
	for _ = 1, steps do
		local nx, ny = self:lunge_step(rb, mx / steps, my / steps)
		if not nx then
			stopped = true
			break
		end
		rb.x, rb.y = nx, ny
		-- hit whoever it touches with the body or the spear
		local cx, cy = rb.x, rb.y + M.DISEGNO_H / 2
		for _, other in ipairs(self.robots) do
			if other ~= rb and not other.dead and not rb.lunge_hit[other.id]
				and (self:robot_at(rb.x, rb.y, rb) == other
					or seg_hits_robot(other, cx, cy, cx + ux * C.LUNGE.reach, cy + uy * C.LUNGE.reach, 2)) then
				rb.lunge_hit[other.id] = true
				self:emit({ type = "lunge_hit", robot = rb.id, target = other.id, x = other.x, y = other.y + M.HURT_Y })
				self:hurt(other, C.LUNGE.damage, rb)
			end
		end
	end
	rb.lunge = rb.lunge - 1
	if stopped or rb.lunge <= 0 then
		-- the momentum that's left: past an edge you fly, against terrain you stop
		local keep = stopped and 0 or C.LUNGE.keep
		rb.vx, rb.vy = rb.lunge_vx * keep, rb.lunge_vy * keep
		rb.lunge, rb.lunge_hit, rb.lunge_vx, rb.lunge_vy = nil, nil, nil, nil
		rb.fall_top = nil
	end
	if rb.y < -20 or rb.x < -20 or rb.x > M.WORLD_W + 20 then self:kill(rb, "fell") end
end

-- Melee hits (sim/melee.lua) --------------------------------------------

-- The rectangle that hits at tick t, in world pixels: axis and half width
function M.melee_blade(rb, hit_def, t, base, dir)
	local p = M.melee_pose(hit_def, t)
	local u = M.U
	local c, s = math.cos(base), math.sin(base)
	local ox, oy = p[1], p[2]
	local x0, y0 = ox + c * p[3] - s * p[4], oy + s * p[3] + c * p[4]
	local x1, y1 = ox + c * p[5] - s * p[6], oy + s * p[5] + c * p[6]
	return rb.x + dir * x0 * u, rb.y + y0 * u, rb.x + dir * x1 * u, rb.y + y1 * u, hit_def.half_width * u
end

-- Advances by one tick the hit that is in pose t at tick t. Whoever the blade
-- touches while the window is open is marked; when it closes they get the hit.
-- Returns false when the hit is over.
local MELEE_SUBSTEPS = 6
function M:update_melee(rb, hit_def, t, base, dir)
	local f0, f1 = t * hit_def.fps / 60, (t + 1) * hit_def.fps / 60
	local hit = rb.melee_hit or {}
	rb.melee_hit = hit
	if t == 0 then for k in pairs(hit) do hit[k] = nil end end
	if f1 >= hit_def.hit_from and f0 <= hit_def.hit_to then
		-- several steps per tick: at the end the blade swings fast and could skip a target
		for s = 1, MELEE_SUBSTEPS do
			local ts = t + s / MELEE_SUBSTEPS
			local f = ts * hit_def.fps / 60
			if f >= hit_def.hit_from and f <= hit_def.hit_to then
				local x0, y0, x1, y1, w = M.melee_blade(rb, hit_def, ts, base, dir)
				for _, other in ipairs(self.robots) do
					if other ~= rb and not other.dead and not hit[other.id]
						and seg_hits_robot(other, x0, y0, x1, y1, w) then
						hit[other.id] = true
					end
				end
			end
		end
	end
	if hit_def.salto and f0 < hit_def.salto and f1 >= hit_def.salto then
		rb.vy, rb.grounded = M.PUNCH_HOP, false
	end
	if f0 < hit_def.hit_to and f1 >= hit_def.hit_to then
		for _, other in ipairs(self.robots) do
			if hit[other.id] then
				hit[other.id] = nil
				if not other.dead then
					if hit_def == melee.slash then self:sword_hit(rb, other) else self:punch_hit(rb, other, dir) end
				end
			end
		end
	end
	return t + 1 < M.melee_ticks(hit_def)
end

-- Pugno del Titano --------------------------------------------------------------

function M:start_punch(angle)
	local rb = self.robots[self.current]
	rb.punch_base, rb.facing = aim_side(angle)
	rb.punch_dir = rb.facing
	rb.punch = 0
	self:emit({ type = "punch", robot = rb.id })
end

function M:punch_hit(rb, other, dir)
	self:emit({ type = "punch_hit", robot = rb.id, target = other.id, x = other.x, y = other.y + M.HURT_Y })
	local k = self:knock_mul(other)
	other.vx, other.vy = 0, M.PUNCH_LAUNCH * k
	other.fall_top = nil
	other.grounded, other.knocked = false, true
	if self:hurt(other, M.PUNCH_DAMAGE, rb) > 0 then self:hit_status(other, "punch", rb) end
end

function M:update_punch(rb)
	if self:update_melee(rb, melee.uppercut, rb.punch, rb.punch_base, rb.punch_dir) then
		rb.punch = rb.punch + 1
	else
		rb.punch, rb.punch_dir, rb.punch_base = nil, nil, nil
	end
end

-- Falling objects: crates, traps, trampolines ---------------------------------

-- Does the 2 * hw wide bottom of an object with its base at (x, y) touch terrain?
function M:object_collides(x, y, hw)
	local t, c = self.terrain, M.CELL
	local cy = math.floor(y / c)
	for cx = math.floor((x - hw + 1) / c), math.floor((x + hw - 1) / c) do
		if t:get(cx, cy) ~= 0 then return true end
	end
	return false
end

-- Drops o.y to the terrain (later too, if an explosion digs below), at most at
-- speed max_fall. Returns true if it's resting.
function M:fall(o, hw, max_fall)
	if self:object_collides(o.x, o.y - 0.5, hw) then
		o.vy = 0
		return true
	end
	o.vy = math.max(o.vy - M.GRAVITY * M.DT, -max_fall)
	local my = o.vy * M.DT
	local steps = math.max(1, math.ceil(-my / M.CELL))
	for _ = 1, steps do
		local ny = o.y + my / steps
		if self:spring(o, ny, hw) then return false end
		if self:object_collides(o.x, ny, hw) then
			-- going back up from the trampoline you pass where you came down: here there's
			-- only a closed-up crater, stop
			if my > 0 then
				o.vy = 0
				return false
			end
			-- resting on the edge of the cell below
			o.y = (math.floor(ny / M.CELL) + 1) * M.CELL
			o.vy = 0
			return true
		end
		o.y = ny
	end
	return false
end

-- Crates --------------------------------------------------------------------------

-- What's in the crate: random according to the weights of config.CRATE_CONTENTS
-- (or of list, { { name, weight }, ... })
function M:crate_content(list)
	list = list or C.CRATE_CONTENTS
	local total = 0
	for _, c in ipairs(list) do total = total + c[2] end
	local r = self.rng:next() * total
	for _, c in ipairs(list) do
		r = r - c[2]
		if r < 0 then return c[1] end
	end
	return list[#list][1]
end

-- How many crates (item false) or items (item true) are on the map
function M:count_crates(item)
	local n = 0
	for _, c in ipairs(self.crates) do
		if (c.item or false) == item then n = n + 1 end
	end
	return n
end

-- Picks a random point on the surface, far from robots and other crates, and
-- drops a crate from the sky there. It uses the match generator, so server and
-- client put it in the same place. weapon and x: that crate right there (the
-- lessons, sim/missions.lua casse). An item (game.ITEMS) drops visible, and
-- item = true drops a random one (config.ITEM_DROPS)
function M:spawn_crate(weapon, x, item)
	if item then weapon = weapon or self:crate_content(C.ITEM_DROPS.contents) end
	item = M.ITEM_SET[weapon] or false
	if self:count_crates(item) >= (item and C.ITEM_DROPS.max or M.CRATE_MAX) then return nil end
	weapon = weapon or self:crate_content()
	local hw = M.CRATE_HALF_W
	-- far from robots and other crates
	local function free_spot(x, gy)
		if self:robot_collides(x, gy) or self:object_collides(x, gy, hw) or self:object_collides(x, gy + M.CRATE_H, hw) then
			return false
		end
		for _, rb in ipairs(self.robots) do
			if not rb.dead and math.abs(rb.x - x) < 60 then return false end
		end
		for _, c in ipairs(self.crates) do
			if math.abs(c.x - x) < 40 then return false end
		end
		return true
	end
	local gy
	if x then
		gy = self.terrain:ground_below(x, M.WORLD_H - 1)
	else
		x, gy = self:surface_spot(free_spot)
	end
	if not x then return nil end
	self.crate_id = self.crate_id + 1
	local c = { id = self.crate_id, x = x, y = M.WORLD_H + 20, vy = 0, landed = false, weapon = weapon, item = item or nil }
	self.crates[#self.crates + 1] = c
	self:emit({ type = "crate", id = c.id, x = x, y = gy, item = item and weapon or nil })
	return c
end

-- Gives the robot what's in a crate. Weapons without counted shots, the
-- Rampino and the parachute only come from the lessons (sim/missions.lua casse
-- and give): the Lanciarune to whoever doesn't have it (rb.disarmed), the
-- secondary replaces theirs, with one shot
function M.give(rb, w)
	if M.FREE_WEAPONS[w] then
		rb.disarmed = nil
	elseif M.SECONDARY[w] then
		rb.disarmed = nil
		rb.secondary = w
		rb.ammo[w] = rb.ammo[w] + 1
	elseif w == "hook" then
		-- everyone has the Rampino: the lesson only shows it
	elseif w == "parachute" then
		rb.parachutes_left = rb.parachutes_left + 1
	else
		rb.ammo[w] = rb.ammo[w] + 1
	end
end

function M:update_crates()
	local i = 1
	while i <= #self.crates do
		local c = self.crates[i]
		c.landed = self:fall(c, M.CRATE_HALF_W, M.CRATE_FALL)
		local taken = false
		for _, rb in ipairs(self.robots) do
			if not rb.dead and not taken
				and math.abs(rb.x - c.x) <= M.ROBOT_HALF_W + M.CRATE_HALF_W
				and rb.y < c.y + M.CRATE_H and rb.y + M.ROBOT_H > c.y then
				M.give(rb, c.weapon)
				rb.crates = rb.crates + 1
				self:emit({ type = "crate_pick", id = c.id, robot = rb.id, weapon = c.weapon })
				taken = true
			end
		end
		if taken or c.y < -20 then
			if not taken then self:emit({ type = "crate_lost", id = c.id }) end
			table.remove(self.crates, i)
		else
			i = i + 1
		end
	end
end

-- Tactical items ----------------------------------------------------------------

-- How far rb gets pushed: less with the shield
function M:knock_mul(rb)
	local k = rb.stats.knockback_mul
	if rb.shield then k = k * C.SHIELD.knockback end
	return k
end

-- Healing circles (config.HEAL) ------------------------------------------------

-- A circle at a random point of the surface, far from other circles
-- (even under a robot: it gets healed, or pushed away)
function M:spawn_heal()
	if #self.heals >= C.HEAL.max then return nil end
	local x, gy = self:surface_spot(function(x)
		for _, h in ipairs(self.heals) do
			if math.abs(h.x - x) < 4 * C.HEAL.r then return false end
		end
		return true
	end)
	if not x then return nil end
	self.heal_id = self.heal_id + 1
	local h = { id = self.heal_id, x = x, y = gy }
	self.heals[#self.heals + 1] = h
	self:emit({ type = "heal_spawn", id = h.id, x = x, y = gy })
	return h
end

-- At the end of the turn: whoever has their feet in a circle is healed, and the
-- circle that healed someone disappears
function M:apply_heals()
	local r2 = C.HEAL.r * C.HEAL.r
	local i = 1
	while i <= #self.heals do
		local h, used = self.heals[i], false
		for _, rb in ipairs(self.robots) do
			local dx, dy = rb.x - h.x, rb.y - h.y
			if not rb.dead and dx * dx + dy * dy <= r2 and rb.hp < rb.max_hp then
				local amount = math.min(C.HEAL.hp, rb.max_hp - rb.hp)
				rb.hp = rb.hp + amount
				used = true
				self:emit({ type = "heal", id = h.id, robot = rb.id, amount = amount })
			end
		end
		if used then
			table.remove(self.heals, i)
			self:emit({ type = "heal_gone", id = h.id })
		else
			i = i + 1
		end
	end
end

-- The robot on turn uses an item (already checked with can_use)
-- fire (angle and power) is needed by thrown items
function M:use_tool(kind, fire)
	local rb = self.robots[self.current]
	if kind == "parachute" then
		-- open it closes (free), closed it opens
		if rb.parachute then
			rb.parachute = false
			self:emit({ type = "parachute_close", robot = rb.id })
			return
		end
		rb.parachutes_left = rb.parachutes_left - 1
		rb.parachute = true
		self:emit({ type = "parachute", robot = rb.id })
		return
	end
	if kind == "hook" then
		-- one Rampino per turn
		self.used.tool = true
		self:fire_hook(fire.angle)
		return
	end
	rb.ammo[kind] = rb.ammo[kind] - 1
	if kind == "shield" then
		rb.shield, rb.parried = C.SHIELD.hp, 0
		self:emit({ type = "shield", robot = rb.id })
		return
	end
	-- the trap is placed at the feet, the trampoline is thrown like the Uovo
	self.placed_id = self.placed_id + 1
	local o = { id = self.placed_id, kind = kind, x = rb.x, y = rb.y, vy = 0, owner = rb.id, team = rb.team,
		armed = false, r = kind == "trap" and rb.stats.trap_radius or C.TRAMPOLINE.half_w, age = 0 }
	if kind == "trampoline" then
		o.x, o.y = muzzle(rb, fire.angle)
		o.vx, o.vy = launch_velocity(fire.angle, fire.power, M.GRENADE_SPEED)
		o.flying = true
		-- the Molla leans towards where it was thrown (straight up: where you look)
		o.dir = o.vx > 0 and 1 or (o.vx < 0 and -1 or rb.facing)
	end
	self.placed[#self.placed + 1] = o
	if #self.placed > C.MAX_PLACED then
		-- too many: the oldest disappears
		self:emit({ type = "placed_gone", id = self.placed[1].id })
		table.remove(self.placed, 1)
	end
	if not o.flying then self:emit({ type = "place", id = o.id, kind = kind, robot = rb.id, x = o.x, y = o.y }) end
end

-- Does the robot have its feet on object o?
local function on_top(rb, o)
	return math.abs(rb.x - o.x) <= M.ROBOT_HALF_W + o.r and rb.y >= o.y - 2 and rb.y <= o.y + 6
end

-- The trampoline in flight, like the Uovo: it stops where it touches terrain,
-- or at the feet of the robot it hits
function M:fly_placed(o)
	o.age = o.age + 1
	o.vy = o.vy - M.GRAVITY * M.GRENADE_GRAVITY * M.DT
	local mx, my = o.vx * M.DT, o.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	for _ = 1, steps do
		local nx, ny = o.x + mx / steps, o.y + my / steps
		local hit = self:body_hits_robot(o, nx, ny, M.GRENADE_R)
		if hit then
			o.x, o.y, o.flying = hit.x, hit.y, false
			break
		elseif self:spring(o, ny, M.GRENADE_R) then
			break
		elseif self.terrain:solid(nx, ny) then
			o.flying = false
			break
		end
		o.x, o.y = nx, ny
	end
	if not o.flying then
		o.vx, o.vy = nil, 0
		self:emit({ type = "place", id = o.id, kind = o.kind, robot = o.owner, x = o.x, y = o.y })
	end
end

-- Bounce speed of b (robot or body) on trampoline o: always, but lower each
-- time while staying on it. nil if the bounces are over.
local function spring_vy(b, o)
	local tr = C.TRAMPOLINE
	local chain = b.bounced_on == o.id and (b.bounces or 0) or 0
	local vy = tr.launch_vy * tr.decay ^ chain
	if vy < tr.min_vy then return nil end
	b.bounced_on, b.bounces = o.id, chain + 1
	return vy
end

-- A robot bouncing on the trampoline
function M:bounce(rb, o)
	local vy = spring_vy(rb, o)
	if not vy then return end
	rb.vy, rb.grounded, rb.rising, rb.knocked, rb.fall_top = vy, false, false, false, nil
	-- the Molla throws it sideways: it doesn't steer until it lands or opens the parachute
	-- the Molla throws it sideways (rb.sprung: the push, kept until it lands or
	-- opens the parachute; the controls only correct it)
	rb.vx = (o.dir or 0) * C.TRAMPOLINE.push_vx
	rb.sprung = rb.vx
	-- an opponent's trampoline launches you: if you fall the kill is theirs
	self:credit(rb, self.robots[o.owner])
	self:emit({ type = "bounce", id = o.id, robot = rb.id })
end

-- A 2 * r wide body (shot, Uovo, orb, crate, item) that crosses a trampoline's
-- board while going down towards ny bounces on it: it goes back onto the board
-- and leaves upwards. Returns true if it bounced.
function M:spring(b, ny, r)
	if b.vy >= 0 then return false end
	local top = C.TRAMPOLINE.top
	for _, o in ipairs(self.placed) do
		if o.kind == "trampoline" and o ~= b and not o.flying and b.y >= o.y + top and ny < o.y + top
			and math.abs(b.x - o.x) <= o.r + r then
			local vy = spring_vy(b, o)
			if not vy then return false end
			b.y, b.vy = o.y + top, vy
			-- shots leave sideways too (crates and items fall straight)
			if b.vx then b.vx = (o.dir or 0) * C.TRAMPOLINE.push_vx end
			self:emit({ type = "bounce", id = o.id, x = b.x, y = b.y })
			return true
		end
	end
	return false
end

function M:update_placed()
	local i = 1
	while i <= #self.placed do
		local o = self.placed[i]
		if o.flying then
			self:fly_placed(o)
		else
			self:fall(o, o.r, M.CRATE_FALL)
		end
		local gone = o.y < -20 or o.x < -300 or o.x > M.WORLD_W + 300
		for _, rb in ipairs(self.robots) do
			if not gone and not o.flying and not rb.dead and on_top(rb, o) and rb.vy <= 0 then
				if o.kind == "trampoline" then
					self:bounce(rb, o)
				elseif o.armed and rb.team ~= o.team then
					-- the trap snaps shut on the feet (config.TRAP) and leaves the ground
					rb.trapped, rb.vx = true, 0
					self:emit({ type = "trap", id = o.id, robot = rb.id, x = o.x, y = o.y })
					local owner = self.robots[o.owner]
					if owner and enemies(owner, rb) then self:add_points(owner, self.score.trap, "trap", rb) end
					gone = true
				end
			end
		end
		if gone then
			if o.kind ~= "trap" or o.y < -20 then self:emit({ type = "placed_gone", id = o.id }) end
			table.remove(self.placed, i)
		else
			i = i + 1
		end
	end
	-- whoever touches ground outside the trampoline bounces high off it again
	for _, rb in ipairs(self.robots) do
		if rb.bounced_on and rb.grounded then
			local still = false
			for _, o in ipairs(self.placed) do
				if o.id == rb.bounced_on and on_top(rb, o) then still = true end
			end
			if not still then rb.bounced_on, rb.bounces = nil, nil end
		end
	end
end

-- Can the robot use this weapon? Crate weapons have counted shots.
-- rb.disarmed: none, until it finds the Lanciarune in a crate (the first lesson)
function M.has_weapon(rb, weapon)
	if rb.disarmed then return false end
	if weapon == "sword" then return true end
	if M.SECONDARY[weapon] then return weapon == rb.secondary and rb.ammo[weapon] > 0 end
	if M.FREE_WEAPONS[weapon] then return true end
	return (rb.ammo[weapon] or 0) > 0
end

-- Points of the predicted trajectory, for the aim line.
-- pts (optional) is a table to reuse, so as not to allocate every frame.
-- weapon (optional): "grenade" and "shards" fly differently from the missile.
function M:preview(angle, power, count, every, pts, weapon)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local vx, vy = launch_velocity(angle, power, M.MISSILE_SPEED)
	local gravity = M.GRAVITY * M.MISSILE_GRAVITY
	if weapon == "grenade" or weapon == "trampoline" then
		vx, vy = launch_velocity(angle, power, M.GRENADE_SPEED)
		gravity = M.GRAVITY * M.GRENADE_GRAVITY
	elseif weapon == "teleport" then
		vx, vy = launch_velocity(angle, power, M.ORB_SPEED)
		gravity = M.GRAVITY * M.ORB_GRAVITY
	elseif weapon == "shards" then
		vx, vy = math.cos(angle) * M.SHARD_SPEED, math.sin(angle) * M.SHARD_SPEED
		gravity = M.GRAVITY * M.SHARD_GRAVITY
	elseif weapon == "sniper" then
		return self:sniper_preview(x, y, angle, count, pts)
	elseif weapon == "eagle" or weapon == "hook" or weapon == "bellows" then
		local range = (weapon == "eagle" and C.EAGLE or weapon == "hook" and C.HOOK or C.BELLOWS).range
		return self:ray_preview(x, y, angle, range, count, pts)
	elseif weapon == "lunge" then
		-- the dash: from the robot's centre, as long as the Affondo
		return self:ray_preview(rb.x, rb.y + M.DISEGNO_H / 2, angle, C.LUNGE.speed * C.LUNGE.ticks / 60, count, pts)
	end
	pts = pts or {}
	local n = 0
	for i = 1, count * every do
		vy = vy - gravity * M.DT
		x, y = x + vx * M.DT, y + vy * M.DT
		if i % every == 0 then
			n = n + 1
			local pt = pts[n] or {}
			pt.x, pt.y = x, y
			pts[n] = pt
		end
	end
	return pts
end

function M:hits_robot(x, y, owner, age)
	for _, rb in ipairs(self.robots) do
		if not rb.dead and (rb.id ~= owner or age > M.OWNER_SAFE_TICKS) and M.hurt_at(rb, x, y, 0) then
			return true
		end
	end
	return false
end

-- owner (optional) is the shooter, to count the damage dealt.
-- blast (optional) says how big it is: MISSILE_BLAST if missing.
-- weapon (optional) is the weapon, for the status effect it carries.
function M:explode(x, y, owner, blast, weapon)
	blast = blast or M.MISSILE_BLAST
	local cy0, cy1 = self.terrain:carve(x, y, blast.r)
	self:emit({ type = "explosion", x = x, y = y, r = blast.r, row_min = cy0, row_max = cy1 })
	self:blast(x, y, owner, blast, weapon)
end

-- The explosion, without the crater: it sets off nearby traps and
-- trampolines, hits and pushes robots
function M:blast(x, y, owner, blast, weapon)
	-- traps and trampolines in the crater blow up
	for i = #self.placed, 1, -1 do
		local o = self.placed[i]
		local ox, oy = o.x - x, o.y - y
		if ox * ox + oy * oy <= (blast.r + 6) * (blast.r + 6) then
			table.remove(self.placed, i)
			self:emit({ type = "placed_gone", id = o.id })
		end
	end
	for _, rb in ipairs(self.robots) do
		if not rb.dead then
			local dmg, vx, vy = self:blast_on(rb, x, y, blast, owner)
			if dmg then
				rb.vx, rb.vy = vx, vy
				rb.grounded = false
				rb.knocked = true
				local by = owner and self.robots[owner]
				if self:hurt(rb, dmg, by) > 0 and weapon and by ~= rb then self:hit_status(rb, weapon, by) end
			end
		end
	end
end

-- What explosion blast at (x, y) by owner does to rb: the damage (before the
-- shield) and the speed it leaves with, or nil if out of reach. It changes
-- nothing: explode and the bot (sim/bot.lua) use it to predict a hit.
function M:blast_on(rb, x, y, blast, owner)
	-- towards the point of the square around the hit circle nearest the explosion
	local hw = M.HURT_R + M.HURT_FAT
	local y0, y1 = rb.y + M.HURT_Y - hw, rb.y + M.HURT_Y + hw
	local dx = math.max(rb.x - hw, math.min(rb.x + hw, x)) - x
	local dy = math.max(y0, math.min(y1, y)) - y
	local d = math.sqrt(dx * dx + dy * dy)
	if d >= blast.damage_r then return nil end
	local f = 1 - d / blast.damage_r
	local dmin = blast.damage_min or 0
	local dmg = dmin + (blast.damage - dmin) * f
	if owner == rb.id then dmg = dmg * M.SELF_DAMAGE end
	dmg = math.floor(dmg + 0.5)
	-- the velocity is replaced
	local imp = blast.impulse * self:knock_mul(rb)
	return dmg, dx * imp * f, dy * imp * f
end

function M:update_projectile()
	local p = self.projectile
	if p.kind == "grenade" then return self:update_grenade(p) end
	if p.kind == "sniper" then return self:update_sniper(p) end
	p.age = p.age + 1
	p.vy = p.vy - M.GRAVITY * M.MISSILE_GRAVITY * M.DT
	local mx, my = p.vx * M.DT, p.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	for _ = 1, steps do
		if self:spring(p, p.y + my / steps, 0) then break end
		p.x = p.x + mx / steps
		p.y = p.y + my / steps
		if self.terrain:solid(p.x, p.y) or self:hits_robot(p.x, p.y, p.owner, p.age) then
			self:explode(p.x, p.y, p.owner, nil, "missile")
			self.projectile = nil
			return
		end
	end
	if p.y < -50 or p.x < -300 or p.x > M.WORLD_W + 300 then
		self:emit({ type = "miss" })
		self.projectile = nil
	end
end

-- Turns ------------------------------------------------------------------------

function M:start_turn(player)
	self.current = player
	self.phase = "aim"
	self.timer = M.TURN_TICKS
	self.window = 0
	-- attacks already done this turn (at most a weapon and a sword hit) and the tool, one per turn
	self.used = { primary = false, secondary = false, tool = false }
	local rb = self.robots[player]
	rb.turns = rb.turns + 1
	self:pair_start(rb)
	-- the shield lasts until the start of the owner's next turn
	if rb.shield then
		rb.shield = nil
		self:emit({ type = "shield_end", robot = rb.id })
	end
	-- traps placed before this turn are armed
	for _, o in ipairs(self.placed) do o.armed = true end
	self:emit({ type = "turn", robot = player })
	-- whoever is burning takes damage at the start of the turn (the kill goes to whoever burned them)
	local burn = rb.status.burn
	if burn then self:hurt(rb, C.STATUS.burn.damage, burn.by and self.robots[burn.by], "burn") end
	-- every crate_every turns a crate drops
	self.turn_no = self.turn_no + 1
	if self.turn_no > 1 then
		if self.crate_chance then
			local chance = self.crate_chance[self:count_crates(false) + 1] or 0
			if self.rng:next() < chance then self:spawn_crate() end
			chance = M.ITEM_CHANCE[self:count_crates(true) + 1] or 0
			if self.rng:next() < chance then self:spawn_crate(nil, nil, true) end
		else
			if (self.turn_no - 1) % self.crate_every == 0 then self:spawn_crate() end
			if (self.turn_no - 1) % (2 * self.crate_every) == 0 then self:spawn_crate(nil, nil, true) end
		end
	end
	if self.heals_on and self.turn_no % C.HEAL.every == 0 then self:spawn_heal() end
end

-- Can the robot on turn use weapon now? "teleport", "sword", a weapon or an
-- item. One weapon and one sword hit per turn, up to the last tick. The
-- teleport uses up an orb (rb.teleports_left) and, like items, can be thrown
-- at any moment of the turn, as many as you have, on the first turn too
-- (Sergio, 3 November).
function M:can_use(weapon)
	if self.phase ~= "aim" then return false end
	-- the lessons only allow what's needed right now (sim/missions.lua only)
	if self.permitted and not self.permitted(weapon) then return false end
	local rb = self.robots[self.current]
	if rb.dead then return false end
	if weapon == "parachute" then
		-- only in the air
		if rb.grounded then return false end
		return rb.parachute or rb.parachutes_left > 0
	elseif weapon == "hook" then
		return not self.used.tool and not rb.trapped
	elseif weapon == "shield" then
		return not rb.shield and rb.ammo.shield > 0
	elseif M.TOOLS[weapon] then
		return rb.ammo[weapon] > 0
	end
	if weapon == "swap" then
		-- swapping the second attack for a teleport: after the first attack, as long as the second is there
		return self.used.primary ~= self.used.secondary
	elseif weapon == "teleport" then
		return #self.orbs < M.MAX_ORBS and rb.teleports_left > 0
	elseif M.SECONDARY[weapon] then
		return not self.used.secondary and M.has_weapon(rb, weapon)
	end
	return not self.used.primary and M.has_weapon(rb, weapon)
end

-- Swap (Sergio, 29 October): after the first attack the second can be
-- exchanged for a teleport orb, to throw whenever you like. The turn goes on
-- as after two attacks.
function M:swap_attack()
	local rb = self.robots[self.current]
	self.used.primary, self.used.secondary = true, true
	rb.teleports_left = rb.teleports_left + 1
	self:emit({ type = "swap", robot = rb.id, total = rb.teleports_left })
end

-- How many teleport orbs the first attack gives after ticks of turn
function M.orbs_for(ticks)
	local n = 0
	for _, s in ipairs(C.TELEPORT_THRESHOLDS) do
		if ticks <= s * 60 then n = n + 1 end
	end
	return n
end

-- The robot on turn attacks with weapon (already checked with can_use)
function M:attack(weapon, fire)
	local rb = self.robots[self.current]
	local first = not (self.used.primary or self.used.secondary)
	if M.SECONDARY[weapon] then self.used.secondary = true else self.used.primary = true end
	if not M.FREE_WEAPONS[weapon] then rb.ammo[weapon] = rb.ammo[weapon] - 1 end
	if weapon == "sword" then
		self:swing_sword(fire.angle)
	elseif weapon == "eagle" then
		self:fire_eagle(fire.angle)
	elseif weapon == "mallet" then
		self:start_mallet(fire.angle)
	elseif weapon == "lunge" then
		self:start_lunge(fire.angle)
	elseif weapon == "bellows" then
		self:fire_bellows(fire.angle)
	else
		if weapon == "punch" then
			self:start_punch(fire.angle)
		elseif weapon == "grenade" then
			self:throw_grenade(fire.angle, fire.power)
		elseif weapon == "shards" then
			self:fire_shards(fire.angle)
		elseif weapon == "sniper" then
			self:fire_sniper(fire.angle)
		else
			self:fire(fire.angle, fire.power)
		end
	end
	if first then
		rb.attack_ticks = rb.attack_ticks + M.TURN_TICKS - self.timer
		rb.attack_turns = rb.attack_turns + 1
		-- attacking early gives teleport orbs, one per threshold not passed
		local gain = rb.stats.time_orbs > 0 and M.orbs_for(M.TURN_TICKS - self.timer) or 0
		if gain > 0 then
			rb.teleports_left = rb.teleports_left + gain
			self:emit({ type = "teleports", robot = rb.id, amount = gain, total = rb.teleports_left })
		end
		self.window = math.min(self.timer, M.AFTER_ATTACK_TICKS)
	end
end

-- Match results, even midway: the standings by team points (on a tie, by
-- robot). place is the team's place: teammates share it, and so does whoever
-- has the same points.
-- { mode, winner = team or nil on a tie, ranking = { { robot, team, place, points, ... } } }
function M:results()
	local team_points = {}
	for _, rb in ipairs(self.robots) do team_points[rb.team] = (team_points[rb.team] or 0) + rb.points end
	local list = {}
	for i, rb in ipairs(self.robots) do list[i] = rb end
	table.sort(list, function(a, b)
		local ta, tb = team_points[a.team], team_points[b.team]
		if ta ~= tb then return ta > tb end
		if a.team ~= b.team then return a.team < b.team end
		if a.points ~= b.points then return a.points > b.points end
		return a.id < b.id
	end)
	local ranking, place, last_team = {}, 0, nil
	for i, rb in ipairs(list) do
		if rb.team ~= last_team then
			-- new team: it drops a place only if it has fewer points than the previous one
			if not last_team or team_points[rb.team] < team_points[last_team] then place = place + 1 end
			last_team = rb.team
		end
		ranking[i] = {
			robot = rb.id, team = rb.team, place = place, points = math.floor(rb.points + 0.5), alive = not rb.dead,
			damage = rb.damage, kills = rb.kills, env_kills = rb.env_kills, deaths = rb.deaths, falls = rb.falls,
			turns = rb.turns, teleports = rb.teleports, crates = rb.crates,
			avg_attack_secs = rb.attack_turns > 0 and math.floor(rb.attack_ticks / rb.attack_turns / 6 + 0.5) / 10 or 0,
		}
	end
	local first, second = ranking[1], nil
	for _, r in ipairs(ranking) do
		if r.team ~= first.team then second = r break end
	end
	local winner = first.team
	if second and second.place == first.place then winner = nil end
	return { mode = self.mode, normalized = self.normalized, winner = winner, ranking = ranking }
end

-- State fingerprint: a number that changes if something that matters changes
-- (tick, turn, rng, robots, shots in flight). Two matches replayed from the
-- same recipe must have the same fingerprints (sim/replay.lua): it's the
-- determinism check, between client and server and between versions.
local FINGERPRINT_MOD = 2147483629
local function shuffle(h, v)
	return (h * 31 + math.floor(v) % FINGERPRINT_MOD) % FINGERPRINT_MOD
end
function M:impronta()
	local h = shuffle(shuffle(shuffle(7, self.tick), self.current), self.rng.state)
	for _, rb in ipairs(self.robots) do
		h = shuffle(h, rb.x * 16)
		h = shuffle(h, rb.y * 16)
		h = shuffle(h, rb.hp * 16)
		h = shuffle(h, rb.points * 16)
		h = shuffle(h, rb.dead and 1 or 0)
	end
	local p = self.projectile
	if p then h = shuffle(shuffle(h, p.x * 16), p.y * 16) end
	h = shuffle(h, #self.orbs)
	h = shuffle(h, #self.placed)
	return h
end

-- Game ticks below which the round that starts is the last (config.FINAL_ROUND_SHARE)
function M:final_round_ticks()
	return #self.order * M.TURN_TICKS * C.FINAL_ROUND_SHARE
end

-- With two teams, at the start of a turn: if the teams have played the same
-- number of turns in the round, whoever starts opens a new pair.
function M:pair_start(rb)
	local done, teams = {}, 0
	for _, r in ipairs(self.robots) do
		if not r.gone then
			if not done[r.team] then done[r.team] = 0; teams = teams + 1 end
			if r.round_done then done[r.team] = done[r.team] + 1 end
		end
	end
	if teams ~= 2 then
		self.ahead, self.ahead_base = 0, 0
		return
	end
	local a, b
	for _, n in pairs(done) do
		if a then b = n else a = n end
	end
	if a ~= b then return end
	local base = 0
	for _, r in ipairs(self.robots) do
		if r.team == rb.team then base = base + r.points end
	end
	self.ahead, self.ahead_base = rb.team, base
end

-- The match ends only at the end of a round: whoever started first doesn't
-- play one turn more than the others. The round that starts when less than
-- final_round_ticks is left is the last, with multiplied points, and then it ends.
function M:end_turn()
	self:apply_heals()
	local rb = self.robots[self.current]
	self:age_status(rb)
	-- the trap lets go at the end of the trapped robot's own turn
	if rb.trapped then
		rb.trapped = nil
		self:emit({ type = "trap_free", robot = rb.id })
	end
	rb.round_done = true
	local next_pos = self.order_pos % #self.order + 1
	if next_pos == 1 then
		if self.final_round then
			self.phase = "over"
			local res = self:results()
			self.winner = res.winner
			self:emit({ type = "over", winner = res.winner, reason = "time", results = res })
			return
		end
		for _, r in ipairs(self.robots) do r.round_done = false end
		self.round = self.round + 1
		if self.match_left <= self:final_round_ticks() then
			self.final_round = true
			self:emit({ type = "final_round" })
		end
	end
	self.order_pos = next_pos
	self:start_turn(self.order[self.order_pos])
end

-- One world tick: robots, orbs, shots, crates, items. Only the robot on turn
-- receives input, if can_move. The bot (sim/bot.lua) also uses it on its
-- copies of the match, to try out moves.
function M:advance(input, can_move)
	for i, rb in ipairs(self.robots) do
		local active = i == self.current and can_move
		self:update_robot(rb, active and input or NO_INPUT, active)
	end
	-- first the teleport, then the sword: the slash already hits from the new position
	if #self.orbs > 0 then self:update_orbs() end
	for _, rb in ipairs(self.robots) do
		if rb.swing then
			if rb.dead then rb.swing, rb.swing_hit = nil, nil else self:update_swing(rb) end
		end
		if rb.punch then
			if rb.dead then rb.punch, rb.punch_dir = nil, nil else self:update_punch(rb) end
		end
		if rb.mallet then
			if rb.dead then rb.mallet, rb.mallet_dir, rb.mallet_stop = nil, nil, nil else self:update_mallet(rb) end
		end
		if rb.dead then rb.lunge, rb.lunge_hit, rb.hooked, rb.recoil, rb.hook_shot = nil, nil, nil, nil, nil end
		if rb.hook_shot then self:update_hook_shot(rb) end
	end
	if self.projectile then self:update_projectile() end
	if self.burst then self:update_burst() end
	self:update_shards()
	if #self.crates > 0 then self:update_crates() end
	if #self.placed > 0 then self:update_placed() end
end

function M:step(input)
	if self.phase == "over" then return end
	input = input or NO_INPUT
	self.tick = self.tick + 1
	-- match time only goes down during turns: while waiting for shots and robots
	-- to settle it's stopped (Sergio, 30 Oct)
	if self.match_left > 0 and self.phase ~= "settle" then
		self.match_left = self.match_left - 1
	end
	-- whoever died starts again after RESPAWN_TICKS, even mid-turn
	for _, rb in ipairs(self.robots) do
		if rb.dead and rb.respawn_in then
			rb.respawn_in = rb.respawn_in - 1
			if rb.respawn_in <= 0 then self:respawn(rb) end
		end
	end

	-- the robot on turn moves for the whole turn, even after the attacks
	self:advance(input, self.phase == "aim")

	if self.phase == "aim" then
		self.timer = math.max(0, self.timer - 1)
		local done = false
		if self.window > 0 then
			self.window = self.window - 1
			done = self.window == 0
		end
		local fire = input.fire
		local weapon = fire and fire.weapon or "missile"
		if not done and fire and self:can_use(weapon) then
			if M.TOOLS[weapon] then
				self:use_tool(weapon, fire)
			elseif weapon == "swap" then
				self:swap_attack()
			elseif weapon == "teleport" then
				-- the orb isn't an attack: it uses up a teleport and the turn goes on
				local rb = self.robots[self.current]
				rb.teleports_left = rb.teleports_left - 1
				rb.teleports = rb.teleports + 1
				self:throw_orb(fire.angle, fire.power)
			else
				self:attack(weapon, fire)
			end
		end
		-- turn over: whoever is aiming loses the shot. Whoever dies in their own turn
		-- starts again and goes on; when the match time runs out the turn is finished.
		if done or self.timer <= 0 then
			self.window = 0
			self.phase, self.settle, self.settle_total = "settle", 0, 0
		end
	elseif self.phase == "settle" then
		-- wait for shots, orbs and robots to settle
		self.settle_total = self.settle_total + 1
		local still = #self.orbs == 0 and not self.projectile and not self:shards_flying()
		for _, o in ipairs(self.placed) do
			if o.flying then still = false end
		end
		for _, rb in ipairs(self.robots) do
			if not rb.dead and (not rb.grounded or rb.swing or rb.punch or rb.lunge or rb.recoil or rb.hooked or rb.hook_shot or rb.mallet) then still = false end
		end
		self.settle = still and self.settle + 1 or 0
		if self.settle >= M.SETTLE_TICKS or self.settle_total >= M.MAX_SETTLE_TICKS then
			self:end_turn()
		end
	end
end

return M
