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
M.SWORD_TICKS = 20       -- durata del fendente (1/3 di secondo)
M.SWORD_DAMAGE = 35

-- Teletrasporto (Passo d'Ombra): un globo che vola come il missile, rimbalza e
-- rotola sul terreno, e dopo
-- TELEPORT_TICKS sposta il robot dove si trova, senza toccare il suo stato:
-- velocità, fendente in corso e direzione restano quelli di prima.
M.TELEPORT_TICKS = 2 * 60
M.MAX_ORBS = 6           -- globi in volo insieme, al massimo

-- Turni
M.MATCH_TICKS = 3 * 60 * 60 -- durata massima della partita: 3 minuti
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
			hp = M.MAX_HP, dead = false, dealt = 0,
			swing = nil,   -- tick del fendente in corso (1..SWORD_TICKS), nil se fermo
			stats = make_stats(opts.stats and opts.stats[i]),
		}
	end
	g.events = {}
	g.tick = 0
	g.orbs = {}              -- globi del teletrasporto in volo, dal più vecchio
	g.orb_seq = 0
	g.match_left = M.MATCH_TICKS
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

-- Collisioni tra robot: sono scatole che non si attraversano. Camminando contro
-- un altro robot lo si spinge, ma piano (PUSH della propria velocità).
M.PUSH = 0.3
-- Un globo del teletrasporto che arriva addosso a un robot lo sposta di poco
M.ORB_NUDGE = 3
M.ORB_R = 3              -- raggio del globo, per gli urti

-- Il robot (diverso da me e vivo) la cui scatola si sovrappone a quella con i piedi in (x, y)
function M:robot_at(x, y, me)
	for _, o in ipairs(self.robots) do
		if o ~= me and not o.dead and math.abs(x - o.x) < 2 * M.ROBOT_HALF_W
			and y < o.y + M.ROBOT_H and y + M.ROBOT_H > o.y then
			return o
		end
	end
end

-- La scatola del robot con i piedi in (x, y) tocca il terreno o un altro robot?
-- me è il robot stesso (per non urtare sé stesso); senza me contano tutti i robot.
function M:robot_collides(x, y, me)
	return self:terrain_collides(x, y) or self:robot_at(x, y, me) ~= nil
end

function M:terrain_collides(x, y)
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

-- Sposta il robot di dx in orizzontale, salendo i gradini piccoli. true se ci riesce.
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

-- rb va contro un altro robot: lo spinge di poco e lo segue
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

function M:kill(rb, reason)
	if rb.dead then return end
	rb.dead = true
	rb.hp = 0
	self:emit({ type = "death", robot = rb.id, reason = reason })
end

function M:update_robot(rb, input)
	if rb.dead then return end

	-- Se il robot è finito dentro il terreno, lo spingiamo fuori verso l'alto
	if self:terrain_collides(rb.x, rb.y) then
		rb.y = rb.y + 1
		return
	end
	-- se è incastrato in un altro robot si allontanano di un pixel alla volta
	local stuck = self:robot_at(rb.x, rb.y, rb)
	if stuck then
		local away = rb.x < stuck.x and -1 or (rb.x > stuck.x and 1 or (rb.id < stuck.id and -1 or 1))
		if not self:terrain_collides(rb.x + away, rb.y) then rb.x = rb.x + away end
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
		elseif not self:robot_collides(rb.x, rb.y - 1, rb) then
			-- In discesa resta attaccato al terreno, altrimenti inizia a cadere
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
				if not self:robot_collides(rb.x + sx, rb.y, rb) then
					rb.x = rb.x + sx
				elseif not self:robot_collides(rb.x + sx, rb.y + 3, rb) then
					-- piccolo gradino in aria: lo scavalca invece di incastrarsi
					rb.x, rb.y = rb.x + sx, rb.y + 3
				else
					-- contro un robot in volo: lo sposta un pizzico e si ferma
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
	self.orb_seq = self.orb_seq + 1
	self.orbs[#self.orbs + 1] = { id = self.orb_seq, x = x, y = y, vx = vx, vy = vy, owner = rb.id,
		timer = M.TELEPORT_TICKS, age = 0 }
	self:emit({ type = "orb", robot = rb.id })
end

-- Cerca un punto libero vicino a (x, y) dove far comparire il robot
-- Punti dove far comparire il robot attorno al globo, dal più vicino al più
-- lontano (a parità di distanza prima quelli più in alto)
local TELEPORT_SEARCH = 48
local TELEPORT_OFFSETS = {}
for dy = -TELEPORT_SEARCH, TELEPORT_SEARCH, 2 do
	for dx = -TELEPORT_SEARCH, TELEPORT_SEARCH, 2 do
		if dx * dx + dy * dy <= TELEPORT_SEARCH * TELEPORT_SEARCH then
			TELEPORT_OFFSETS[#TELEPORT_OFFSETS + 1] = { dx, dy, dx * dx + dy * dy }
		end
	end
end
table.sort(TELEPORT_OFFSETS, function(a, b)
	if a[3] ~= b[3] then return a[3] < b[3] end
	if a[2] ~= b[2] then return a[2] > b[2] end
	return a[1] < b[1]
end)

-- Il teletrasporto avviene sempre: nel punto libero più vicino al globo e, se
-- attorno è tutto pieno, proprio lì (il robot poi esce dal terreno verso l'alto).
function M:teleport(rb, x, y)
	local tx, ty = x, y
	for _, o in ipairs(TELEPORT_OFFSETS) do
		if not self:robot_collides(x + o[1], y + o[2], rb) then
			tx, ty = x + o[1], y + o[2]
			break
		end
	end
	local fx, fy = rb.x, rb.y
	rb.x, rb.y = tx, ty
	-- lo stato resta identico: chi cadeva continua a cadere con la stessa velocità.
	-- Non è più appoggiato a niente, la fisica lo rimette a terra se serve.
	rb.grounded = false
	self:emit({ type = "teleport", robot = rb.id, from_x = fx, from_y = fy, x = tx, y = ty })
end

-- Rimbalzo e rotolamento del globo
M.ORB_BOUNCE = 0.35      -- quanta velocità resta nel rimbalzo
M.ORB_FRICTION = 0.97    -- attrito lungo la superficie, per ogni tick a contatto

-- Direzione verso fuori dal terreno attorno a (x, y): l'opposto della media
-- delle celle piene vicine
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

-- Il robot contro cui urta il globo in (x, y), o nil. Chi l'ha lanciato
-- conta solo dopo un attimo, così il globo non gli rimbalza in faccia.
function M:orb_hits_robot(o, x, y)
	local r = M.ORB_R
	for _, rb in ipairs(self.robots) do
		if not rb.dead and (rb.id ~= o.owner or o.age > 20)
			and math.abs(x - rb.x) <= M.ROBOT_HALF_W + r and y >= rb.y - r and y <= rb.y + M.ROBOT_H + r then
			return rb
		end
	end
end

-- Aggiorna un globo; restituisce false quando ha finito (teletrasporto fatto)
function M:update_orb(o)
	local rb = self.robots[o.owner]
	if rb.dead then return false end
	o.age = (o.age or 0) + 1
	-- vola come il missile; quando tocca il terreno rimbalza e rotola.
	-- Se esce dalla mappa continua a cadere: il teletrasporto ti porta lì lo stesso.
	local t = self.terrain
	o.vy = o.vy - M.GRAVITY * M.DT
	local mx, my = o.vx * M.DT, o.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	for _ = 1, steps do
		local nx, ny = o.x + mx / steps, o.y + my / steps
		local hit = self:orb_hits_robot(o, nx, ny)
		if hit then
			-- urta un robot: rimbalza sulla sua scatola e, se arriva forte, lo sposta un briciolo
			local sx, sy = 0, 1
			if o.y < hit.y + M.ROBOT_H - 2 then sx, sy = o.x < hit.x and -1 or 1, 0 end
			local vn = o.vx * sx + o.vy * sy
			if vn < -40 then
				local d = (o.vx < 0 and -1 or 1)
				if sy == 0 then d = -sx end
				step_x(self, hit, d * M.ORB_NUDGE)
			end
			if vn < 0 then
				local e = vn < -60 and M.ORB_BOUNCE or 0
				local tx, ty = o.vx - vn * sx, o.vy - vn * sy
				o.vx = tx * M.ORB_FRICTION - e * vn * sx
				o.vy = ty * M.ORB_FRICTION - e * vn * sy
			end
			break
		elseif t:solid(nx, ny) then
			local sx, sy = surface_normal(t, nx, ny)
			local vn = o.vx * sx + o.vy * sy
			if vn < 0 then
				-- toglie la parte di velocità contro il terreno (e ne rimanda indietro
				-- un po' se l'urto è forte), frena quella lungo la superficie
				local e = vn < -60 and M.ORB_BOUNCE or 0
				local tx, ty = o.vx - vn * sx, o.vy - vn * sy
				o.vx = tx * M.ORB_FRICTION - e * vn * sx
				o.vy = ty * M.ORB_FRICTION - e * vn * sy
			end
			break
		end
		o.x, o.y = nx, ny
	end
	o.timer = o.timer - 1
	if o.timer <= 0 then
		-- il globo è al centro del robot, la posizione del robot è ai piedi
		self:teleport(rb, o.x, o.y - M.ROBOT_H / 2)
		return false
	end
	return true
end

-- Tutti i globi in volo, dal più vecchio: ognuno teletrasporta allo scadere del suo tempo
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
	-- i globi si urtano anche tra loro: si separano e si scambiano la spinta
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

-- Lama di Nucleo ----------------------------------------------------------------

-- Angolo della lama al tick t del fendente, per un robot rivolto a destra
-- Curva del fendente: come una persona vera, prima porta la lama un po'
-- indietro (slancio, circa 13°) e poi accelera sempre di più fino alla fine.
-- È un "back ease-in": va sotto lo zero all'inizio e arriva a 1 con la velocità massima.
M.SWORD_WINDUP = 1.2
function M.sword_progress(u)
	u = math.max(0, math.min(1, u))
	local s = M.SWORD_WINDUP
	return u * u * ((s + 1) * u - s)
end

function M.sword_angle(t)
	return M.SWORD_FROM + (M.SWORD_TO - M.SWORD_FROM) * M.sword_progress(t / M.SWORD_TICKS)
end

function M:swing_sword(angle)
	local rb = self.robots[self.current]
	rb.facing = math.cos(angle) < 0 and -1 or 1
	-- il fendente resta nella direzione di partenza anche se il robot si gira
	rb.swing_dir = rb.facing
	rb.swing = 0
	rb.swing_hit = {}
	self:emit({ type = "swing", robot = rb.id })
end

local function in_robot(r, x, y)
	return math.abs(x - r.x) <= M.ROBOT_HALF_W and y >= r.y and y <= r.y + M.ROBOT_H
end

-- alla fine la lama gira veloce: tanti passi per tick, così non salta un bersaglio
local SWORD_SUBSTEPS = 8
local SWORD_SAMPLES = 10

function M:update_swing(rb)
	local t0 = rb.swing
	rb.swing = t0 + 1
	local px, py = rb.x, rb.y + M.SWORD_PIVOT_Y
	-- controlliamo anche gli angoli intermedi, così la lama non salta un bersaglio
	for s = 1, SWORD_SUBSTEPS do
		local a = M.sword_angle(t0 + s / SWORD_SUBSTEPS)
		local cx, cy = math.cos(a) * rb.swing_dir, math.sin(a)
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
		rb.swing, rb.swing_hit, rb.swing_dir = nil, nil, nil
	end
end

function M:sword_hit(rb, other)
	other.hp = other.hp - M.SWORD_DAMAGE
	rb.dealt = rb.dealt + M.SWORD_DAMAGE
	self:emit({ type = "damage", robot = other.id, amount = M.SWORD_DAMAGE })
	self:emit({ type = "sword_hit", robot = rb.id, target = other.id })
	-- la spada fa solo danno: il bersaglio resta dov'è
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

-- owner (facoltativo) è chi ha sparato, per contare i danni inflitti
function M:explode(x, y, owner)
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
				if owner and owner ~= rb.id then self.robots[owner].dealt = self.robots[owner].dealt + dmg end
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
			self:explode(p.x, p.y, p.owner)
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
	self:emit({ type = "turn", robot = player })
end

-- Classifica a tempo scaduto: più vita rimasta, a parità più danni inflitti.
-- Riempie self.podium e restituisce il vincitore, o nil se i primi due sono pari in tutto.
function M:ranking()
	local order = {}
	for _, rb in ipairs(self.robots) do
		if not rb.dead then order[#order + 1] = rb end
	end
	table.sort(order, function(a, b)
		if a.hp ~= b.hp then return a.hp > b.hp end
		if a.dealt ~= b.dealt then return a.dealt > b.dealt end
		return a.id < b.id
	end)
	self.podium = {}
	for i, rb in ipairs(order) do self.podium[i] = rb.id end
	local a, b = order[1], order[2]
	if a and b and a.hp == b.hp and a.dealt == b.dealt then return nil end
	return a and a.id
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
	if self.match_left <= 0 then
		-- tempo scaduto: vince chi ha più vita
		self.phase = "over"
		self.winner = self:ranking()
		self:emit({ type = "over", winner = self.winner, reason = "time" })
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
	if self.match_left > 0 then self.match_left = self.match_left - 1 end

	-- il robot di turno si muove mentre mira e durante la ritirata dopo lo sparo
	local can_move = self.phase == "aim" or self.retreat > 0
	for i, rb in ipairs(self.robots) do
		local active = i == self.current and can_move
		self:update_robot(rb, active and input or NO_INPUT)
	end
	if self.retreat > 0 then self.retreat = self.retreat - 1 end
	-- prima il teletrasporto, poi la spada: il fendente colpisce già dalla nuova posizione
	if #self.orbs > 0 then self:update_orbs() end
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
			-- lanciare il globo non chiude il turno e se ne possono lanciare quanti
			-- se ne vuole, anche mentre altri sono ancora in volo
			if #self.orbs < M.MAX_ORBS then self:throw_orb(fire.angle, fire.power) end
		elseif fire then
			if weapon == "sword" then
				self:swing_sword(fire.angle)
			else
				self:fire(fire.angle, fire.power)
			end
			self.phase = "flying"
			self.retreat = M.RETREAT_TICKS
		elseif self.timer <= 0 or self.match_left <= 0 then
			-- turno finito, o partita finita: chi mira perde il colpo
			self.phase, self.settle = "settle", 0
		end
	elseif self.phase == "flying" then
		if self.projectile then self:update_projectile() end
		if not self.projectile and not self.robots[self.current].swing then
			self.phase, self.settle, self.settle_total = "settle", 0, 0
		end
	elseif self.phase == "settle" then
		self.settle_total = (self.settle_total or 0) + 1
		local still = #self.orbs == 0
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
