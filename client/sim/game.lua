-- Simulazione di una partita: robot, missile, turni.
-- Lua puro, nessuna API Defold: la stessa logica girerà anche sul server.
--
-- Uso:
--   local game = require "sim.game"
--   local g = game.new(seed, "isole")
--   g:step({ left = bool, right = bool, jump = bool,
--            fire = { angle = rad, power = 0..1, weapon = "missile" | "sword" | "teleport" } })
--   for _, e in ipairs(g:pop_events()) do ... end

local rng = require "sim.rng"
local terrain = require "sim.terrain"
local maps = require "sim.maps"

local M = {}
M.__index = M

-- Mondo
M.WORLD_W = 1280
M.WORLD_H = 720
M.CELL = 2
M.DT = 1 / 60
M.GRAVITY = 600

-- Robot (la posizione è il centro dei piedi)
M.ROBOT_HALF_W = 6
M.ROBOT_H = 16
M.MAX_CLIMB = 6          -- gradino massimo che il robot sale da solo
M.MAX_HP = 100

-- Statistiche base del robot. L'equipaggiamento le modificherà.
M.DEFAULT_STATS = {
	walk_speed = 70,     -- pixel al secondo a terra
	jump_height = 56,    -- altezza massima del salto in pixel
	air_speed = 90,      -- velocità orizzontale massima in aria
}
-- Reattività in aria: l'accelerazione è air_speed^2 / AIR_REACTION, quindi
-- più un robot è veloce, più in fretta cambia direzione (meno inerzia).
M.AIR_REACTION = 8

-- Missile
M.MISSILE_SPEED = 750    -- velocità alla potenza massima
M.EXPLOSION_R = 30       -- raggio del cratere
M.DAMAGE_R = 50          -- raggio entro cui si subisce danno
M.MAX_DAMAGE = 45
M.KNOCKBACK = 320

-- Lama di Nucleo: fendente di 240° che parte da dietro la schiena (205°),
-- passa sopra la testa e finisce davanti in basso (-35°). Colpisce dietro e davanti.
M.SWORD_REACH = 40       -- lunghezza della lama dal perno
M.SWORD_PIVOT_Y = 10     -- altezza del perno (la spalla) sopra i piedi
M.SWORD_FROM = math.rad(205)
M.SWORD_TO = math.rad(-35)
M.SWORD_TICKS = 36       -- durata del fendente
M.SWORD_DAMAGE = 35
M.SWORD_KNOCKBACK = 260

-- Teletrasporto (Passo d'Ombra): un globo che vola come il missile e dopo
-- TELEPORT_TICKS sposta il robot dove si trova, senza toccare il suo stato:
-- velocità, fendente in corso e direzione restano quelli di prima.
M.TELEPORT_TICKS = 2 * 60

-- Turni
M.TURN_TICKS = 15 * 60
M.RETREAT_TICKS = 3 * 60 -- dopo lo sparo ci si può ancora muovere per ripararsi
M.SETTLE_TICKS = 30
M.MAX_SETTLE_TICKS = 5 * 60

-- Online il server manda uno stato ogni SNAPSHOT_TICKS tick (30 al secondo)
M.SNAPSHOT_TICKS = 2

local NO_INPUT = {}

local function make_stats(custom)
	local st = {}
	for k, v in pairs(M.DEFAULT_STATS) do st[k] = v end
	for k, v in pairs(custom or {}) do st[k] = v end
	st.jump_vy = math.sqrt(2 * M.GRAVITY * st.jump_height)
	st.air_accel = st.air_speed * st.air_speed / M.AIR_REACTION
	return st
end

-- opts.stats = { [1] = { walk_speed = ... }, [2] = { ... } } per cambiare le statistiche
function M.new(seed, map_id, opts)
	opts = opts or {}
	local g = setmetatable({}, M)
	local map = maps.get(map_id)
	g.map = map.id
	g.rng = rng.new(seed)
	g.terrain = terrain.new(M.WORLD_W / M.CELL, M.WORLD_H / M.CELL, M.CELL)
	map.build(g.terrain, seed)
	g.robots = {}
	for i = 1, 2 do
		local sp = map.spawns[i]
		g.robots[i] = {
			id = i, x = sp.x, y = g.terrain:ground_below(sp.x, sp.from) or M.WORLD_H / 2,
			vx = 0, vy = 0, grounded = false, knocked = false, facing = i == 1 and 1 or -1,
			hp = M.MAX_HP, dead = false,
			swing = nil,   -- tick del fendente in corso (1..SWORD_TICKS), nil se fermo
			stats = make_stats(opts.stats and opts.stats[i]),
		}
	end
	g.events = {}
	g.tick = 0
	g.current = 1
	g.retreat = 0
	g.winner = nil
	g:start_turn(1)
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

-- Collisioni robot / terreno -------------------------------------------------

function M:robot_collides(x, y)
	local t, c = self.terrain, M.CELL
	local cx0 = math.floor((x - M.ROBOT_HALF_W) / c)
	local cx1 = math.floor((x + M.ROBOT_HALF_W) / c)
	local cy0 = math.floor(y / c)
	local cy1 = math.floor((y + M.ROBOT_H - 0.01) / c)
	for cy = cy0, cy1 do
		for cx = cx0, cx1 do
			if t:get(cx, cy) ~= 0 then return true end
		end
	end
	return false
end

local function walk(g, rb, dx)
	for climb = 0, M.MAX_CLIMB do
		if not g:robot_collides(rb.x + dx, rb.y + climb) then
			rb.x = rb.x + dx
			rb.y = rb.y + climb
			return
		end
	end
end

function M:kill(rb, reason)
	if rb.dead then return end
	rb.dead = true
	rb.hp = 0
	self:emit({ type = "death", robot = rb.id, reason = reason })
end

function M:update_robot(rb, input)
	if rb.dead then return end

	-- Se il robot è finito dentro il terreno, lo spingiamo fuori verso l'alto
	if self:robot_collides(rb.x, rb.y) then
		rb.y = rb.y + 1
		return
	end

	local st = rb.stats
	local dir = (input.right and 1 or 0) - (input.left and 1 or 0)
	if dir ~= 0 then rb.facing = dir end

	if rb.grounded then
		if dir ~= 0 then
			walk(self, rb, dir * st.walk_speed * M.DT)
		end
		if input.jump then
			-- salto libero: verso l'alto, oppure nella direzione in cui si sta andando
			rb.vx = dir * st.walk_speed
			rb.vy = st.jump_vy
			rb.grounded = false
		elseif not self:robot_collides(rb.x, rb.y - 1) then
			-- In discesa resta attaccato al terreno, altrimenti inizia a cadere
			local landed = false
			for d = 1, M.MAX_CLIMB do
				if self:robot_collides(rb.x, rb.y - d - 1) then
					rb.y = rb.y - d
					landed = true
					break
				end
			end
			if not landed then
				rb.grounded = false
				rb.vx, rb.vy = 0, 0
			end
		end
	end

	if not rb.grounded then
		-- controllo in aria (non mentre si viene sbalzati da un'esplosione)
		if not rb.knocked then
			local dv = dir * st.air_speed - rb.vx
			local max_dv = st.air_accel * M.DT
			rb.vx = rb.vx + math.max(-max_dv, math.min(max_dv, dv))
		end
		rb.vy = rb.vy - M.GRAVITY * M.DT
		local mx, my = rb.vx * M.DT, rb.vy * M.DT
		local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my))))
		local sx, sy = mx / steps, my / steps
		for _ = 1, steps do
			if sx ~= 0 then
				if not self:robot_collides(rb.x + sx, rb.y) then
					rb.x = rb.x + sx
				elseif not self:robot_collides(rb.x + sx, rb.y + 3) then
					-- piccolo gradino in aria: lo scavalca invece di incastrarsi
					rb.x, rb.y = rb.x + sx, rb.y + 3
				else
					rb.vx, sx = 0, 0
				end
			end
			if sy ~= 0 then
				if self:robot_collides(rb.x, rb.y + sy) then
					if sy < 0 then
						rb.grounded = true
						rb.knocked = false
						rb.vx = 0
					end
					rb.vy, sy = 0, 0
				else
					rb.y = rb.y + sy
				end
			end
		end
	end

	if rb.y < -20 or rb.x < -20 or rb.x > M.WORLD_W + 20 then
		self:kill(rb, "fell")
	end
end

-- Missile ----------------------------------------------------------------------

local function launch_velocity(angle, power)
	local speed = M.MISSILE_SPEED * math.max(0.1, math.min(1, power))
	return math.cos(angle) * speed, math.sin(angle) * speed
end

local function muzzle(rb, angle)
	return rb.x + math.cos(angle) * 14, rb.y + M.ROBOT_H / 2 + math.sin(angle) * 14
end

function M:fire(angle, power)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local vx, vy = launch_velocity(angle, power)
	self.projectile = { x = x, y = y, vx = vx, vy = vy, owner = rb.id, age = 0 }
	self:emit({ type = "fire", robot = rb.id })
end

-- Teletrasporto -----------------------------------------------------------------

function M:throw_orb(angle, power)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local vx, vy = launch_velocity(angle, power)
	self.orb = { x = x, y = y, vx = vx, vy = vy, owner = rb.id, timer = M.TELEPORT_TICKS, resting = false }
	self.orb_used = true
	self:emit({ type = "orb", robot = rb.id })
end

-- Cerca un punto libero vicino a (x, y) dove far comparire il robot
local TELEPORT_OFFSETS = {}
for dy = 0, 24, 2 do
	for _, dx in ipairs({ 0, -2, 2, -4, 4, -6, 6, -8, 8 }) do
		TELEPORT_OFFSETS[#TELEPORT_OFFSETS + 1] = { dx, dy }
	end
end

function M:teleport(rb, x, y)
	for _, o in ipairs(TELEPORT_OFFSETS) do
		local tx, ty = x + o[1], y + o[2]
		if not self:robot_collides(tx, ty) then
			local fx, fy = rb.x, rb.y
			rb.x, rb.y = tx, ty
			-- lo stato resta identico: chi cadeva continua a cadere con la stessa velocità.
			-- Non è più appoggiato a niente, la fisica lo rimette a terra se serve.
			rb.grounded = false
			self:emit({ type = "teleport", robot = rb.id, from_x = fx, from_y = fy, x = tx, y = ty })
			return true
		end
	end
	self:emit({ type = "teleport_fail", robot = rb.id })
	return false
end

function M:update_orb()
	local o = self.orb
	local rb = self.robots[o.owner]
	if rb.dead then
		self.orb = nil
		return
	end
	if not o.resting then
		-- vola come il missile; quando tocca il terreno si ferma lì
		o.vy = o.vy - M.GRAVITY * M.DT
		local mx, my = o.vx * M.DT, o.vy * M.DT
		local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
		for _ = 1, steps do
			local nx, ny = o.x + mx / steps, o.y + my / steps
			if self.terrain:solid(nx, ny) then
				o.resting, o.vx, o.vy = true, 0, 0
				break
			end
			o.x, o.y = nx, ny
		end
		if o.y < -50 or o.x < -300 or o.x > M.WORLD_W + 300 then
			-- fuori dalla mappa: il globo si spegne invece di farti cadere nel vuoto
			self:emit({ type = "teleport_fail", robot = rb.id })
			self.orb = nil
			return
		end
	end
	o.timer = o.timer - 1
	if o.timer <= 0 then
		self.orb = nil
		-- il globo è al centro del robot, la posizione del robot è ai piedi
		self:teleport(rb, o.x, o.y - M.ROBOT_H / 2)
	end
end

-- Lama di Nucleo ----------------------------------------------------------------

-- Angolo della lama al tick t del fendente, per un robot rivolto a destra
function M.sword_angle(t)
	return M.SWORD_FROM + (M.SWORD_TO - M.SWORD_FROM) * math.min(1, t / M.SWORD_TICKS)
end

function M:swing_sword(angle)
	local rb = self.robots[self.current]
	rb.facing = math.cos(angle) < 0 and -1 or 1
	rb.swing = 0
	rb.swing_hit = {}
	self:emit({ type = "swing", robot = rb.id })
end

local function in_robot(r, x, y)
	return math.abs(x - r.x) <= M.ROBOT_HALF_W and y >= r.y and y <= r.y + M.ROBOT_H
end

local SWORD_SUBSTEPS = 2
local SWORD_SAMPLES = 10

function M:update_swing(rb)
	local t0 = rb.swing
	rb.swing = t0 + 1
	local px, py = rb.x, rb.y + M.SWORD_PIVOT_Y
	-- controlliamo anche gli angoli intermedi, così la lama non salta un bersaglio
	for s = 1, SWORD_SUBSTEPS do
		local a = M.sword_angle(t0 + s / SWORD_SUBSTEPS)
		local cx, cy = math.cos(a) * rb.facing, math.sin(a)
		for _, other in ipairs(self.robots) do
			if other ~= rb and not other.dead and not rb.swing_hit[other.id] then
				for k = 1, SWORD_SAMPLES do
					local d = M.SWORD_REACH * k / SWORD_SAMPLES
					if in_robot(other, px + cx * d, py + cy * d) then
						rb.swing_hit[other.id] = true
						self:sword_hit(rb, other)
						break
					end
				end
			end
		end
	end
	if rb.swing >= M.SWORD_TICKS then
		rb.swing, rb.swing_hit = nil, nil
	end
end

function M:sword_hit(rb, other)
	other.hp = other.hp - M.SWORD_DAMAGE
	self:emit({ type = "damage", robot = other.id, amount = M.SWORD_DAMAGE })
	self:emit({ type = "sword_hit", robot = rb.id, target = other.id })
	local dx = other.x - rb.x
	local dir = dx < 0 and -1 or 1
	other.vx = dir * M.SWORD_KNOCKBACK
	other.vy = M.SWORD_KNOCKBACK * 0.5
	other.grounded = false
	other.knocked = true
	if other.hp <= 0 then self:kill(other, "damage") end
end

-- Punti della traiettoria prevista, per la linea di mira.
-- pts (facoltativo) è una tabella da riusare, per non allocare a ogni frame.
function M:preview(angle, power, count, every, pts)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local vx, vy = launch_velocity(angle, power)
	pts = pts or {}
	local n = 0
	for i = 1, count * every do
		vy = vy - M.GRAVITY * M.DT
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
		if not rb.dead and (rb.id ~= owner or age > 20)
			and math.abs(x - rb.x) <= M.ROBOT_HALF_W and y >= rb.y and y <= rb.y + M.ROBOT_H then
			return true
		end
	end
	return false
end

function M:explode(x, y)
	local cy0, cy1 = self.terrain:carve(x, y, M.EXPLOSION_R)
	self:emit({ type = "explosion", x = x, y = y, r = M.EXPLOSION_R, row_min = cy0, row_max = cy1 })
	for _, rb in ipairs(self.robots) do
		if not rb.dead then
			local dx, dy = rb.x - x, (rb.y + M.ROBOT_H / 2) - y
			local d = math.sqrt(dx * dx + dy * dy)
			if d < M.DAMAGE_R then
				local f = 1 - d / M.DAMAGE_R
				local dmg = math.floor(M.MAX_DAMAGE * f + 0.5)
				rb.hp = rb.hp - dmg
				self:emit({ type = "damage", robot = rb.id, amount = dmg })
				if d < 1 then dx, dy, d = 0, 1, 1 end
				rb.vx = dx / d * M.KNOCKBACK * f
				rb.vy = dy / d * M.KNOCKBACK * f + 120 * f
				rb.grounded = false
				rb.knocked = true
				if rb.hp <= 0 then self:kill(rb, "damage") end
			end
		end
	end
end

function M:update_projectile()
	local p = self.projectile
	p.age = p.age + 1
	p.vy = p.vy - M.GRAVITY * M.DT
	local mx, my = p.vx * M.DT, p.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	for _ = 1, steps do
		p.x = p.x + mx / steps
		p.y = p.y + my / steps
		if self.terrain:solid(p.x, p.y) or self:hits_robot(p.x, p.y, p.owner, p.age) then
			self:explode(p.x, p.y)
			self.projectile = nil
			return
		end
	end
	if p.y < -50 or p.x < -300 or p.x > M.WORLD_W + 300 then
		self:emit({ type = "miss" })
		self.projectile = nil
	end
end

-- Turni ------------------------------------------------------------------------

function M:alive_count()
	local n = 0
	for _, rb in ipairs(self.robots) do
		if not rb.dead then n = n + 1 end
	end
	return n
end

function M:start_turn(player)
	self.current = player
	self.phase = "aim"
	self.timer = M.TURN_TICKS
	self.retreat = 0
	self.orb_used = false
	self:emit({ type = "turn", robot = player })
end

function M:end_turn()
	if self:alive_count() <= 1 then
		self.phase = "over"
		for _, rb in ipairs(self.robots) do
			if not rb.dead then self.winner = rb.id end
		end
		self:emit({ type = "over", winner = self.winner })
		return
	end
	local nxt = self.current
	repeat
		nxt = nxt % #self.robots + 1
	until not self.robots[nxt].dead
	self:start_turn(nxt)
end

function M:step(input)
	if self.phase == "over" then return end
	input = input or NO_INPUT
	self.tick = self.tick + 1

	-- il robot di turno si muove mentre mira e durante la ritirata dopo lo sparo
	local can_move = self.phase == "aim" or self.retreat > 0
	for i, rb in ipairs(self.robots) do
		local active = i == self.current and can_move
		self:update_robot(rb, active and input or NO_INPUT)
	end
	if self.retreat > 0 then self.retreat = self.retreat - 1 end
	-- prima il teletrasporto, poi la spada: il fendente colpisce già dalla nuova posizione
	if self.orb then self:update_orb() end
	for _, rb in ipairs(self.robots) do
		if rb.swing then
			if rb.dead then rb.swing, rb.swing_hit = nil, nil else self:update_swing(rb) end
		end
	end

	if self.phase == "aim" then
		self.timer = self.timer - 1
		local fire = input.fire
		local weapon = fire and fire.weapon or "missile"
		if self.robots[self.current].dead then
			self.phase, self.settle = "settle", 0
		elseif fire and weapon == "teleport" then
			-- lanciare il globo non chiude il turno: si può ancora attaccare
			if not self.orb_used then self:throw_orb(fire.angle, fire.power) end
		elseif fire then
			if weapon == "sword" then
				self:swing_sword(fire.angle)
			else
				self:fire(fire.angle, fire.power)
			end
			self.phase = "flying"
			self.retreat = M.RETREAT_TICKS
		elseif self.timer <= 0 then
			self.phase, self.settle = "settle", 0
		end
	elseif self.phase == "flying" then
		if self.projectile then self:update_projectile() end
		if not self.projectile and not self.robots[self.current].swing then
			self.phase, self.settle, self.settle_total = "settle", 0, 0
		end
	elseif self.phase == "settle" then
		self.settle_total = (self.settle_total or 0) + 1
		local still = not self.orb
		for _, rb in ipairs(self.robots) do
			if not rb.dead and (not rb.grounded or rb.swing) then still = false end
		end
		self.settle = (still and self.retreat == 0) and self.settle + 1 or 0
		if self.settle >= M.SETTLE_TICKS or self.settle_total >= M.MAX_SETTLE_TICKS then
			self.settle_total = 0
			self:end_turn()
		end
	end
end

return M
