-- Test della simulazione. Dalla radice del repository:
--   lua tests/sim_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local maps = require "sim.maps"
local terrain = require "sim.terrain"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

local function run(g, ticks, input)
	for _ = 1, ticks do g:step(input) end
end

local function solid_count(t)
	local n = 0
	for i = 1, #t.data do if t.data[i] ~= 0 then n = n + 1 end end
	return n
end

-- Ogni mappa: i robot compaiono appoggiati al terreno
for _, id in ipairs(maps.order) do
	local m = game.new(42, id)
	run(m, 120)
	check(m.robots[1].grounded and m.robots[2].grounded, id .. ": i robot si appoggiano al terreno")
	check(not m.robots[1].dead and not m.robots[2].dead, id .. ": nessun robot muore all'avvio")
end

local g = game.new(42, "isole")
run(g, 120)

-- Il robot di turno cammina
local x0, x2 = g.robots[1].x, g.robots[2].x
run(g, 30, { right = true })
check(g.robots[1].x > x0 + 20, "il robot cammina verso destra")
check(g.robots[2].x == x2, "l'avversario resta fermo")

-- Salto verticale: senza direzione il robot sale dritto e riatterra nello stesso punto
local rb = g.robots[1]
local sx, sy = rb.x, rb.y
g:step({ jump = true })
check(not rb.grounded, "il robot salta")
local top = rb.y
for _ = 1, 120 do
	g:step()
	top = math.max(top, rb.y)
end
check(rb.grounded and rb.x == sx, "il salto senza direzione è verticale")
check(math.abs(top - sy - rb.stats.jump_height) < 4, "il salto arriva all'altezza delle statistiche")

-- Controllo in aria: si salta dritto e poi ci si sposta a mezz'aria
g:step({ jump = true })
run(g, 20, { left = true })
check(rb.x < sx - 10 and not rb.grounded, "in aria il robot si sposta a sinistra")
run(g, 120)

-- Reattività: un robot veloce inverte la direzione in aria più in fretta di uno lento
local function reverse_ticks(stats)
	local q = game.new(42, "isole", { stats = { stats } })
	run(q, 120)
	local r = q.robots[1]
	q:step({ jump = true, right = true })
	run(q, 10, { right = true })
	local n = 0
	while r.vx > 0 and n < 100 do q:step({ left = true }); n = n + 1 end
	return n
end
local slow = reverse_ticks({ air_speed = 60 })
local fast = reverse_ticks({ air_speed = 200 })
check(fast < slow, string.format("il robot veloce cambia direzione prima (%d tick contro %d)", fast, slow))

-- Le statistiche cambiano l'altezza del salto
local hj = game.new(42, "isole", { stats = { { jump_height = 120 } } })
run(hj, 120)
local hy = hj.robots[1].y
hj:step({ jump = true })
local htop = hy
for _ = 1, 120 do hj:step(); htop = math.max(htop, hj.robots[1].y) end
check(htop - hy > 100, "jump_height alto fa saltare di più")

-- L'acciaio non si scava
local tt = g.terrain
local before_steel, before_dirt = 0, 0
for i = 1, #tt.data do
	if tt.data[i] == terrain.STEEL then before_steel = before_steel + 1 end
end
tt:carve(250, 40, 40)
local after_steel = 0
for i = 1, #tt.data do
	if tt.data[i] == terrain.STEEL then after_steel = after_steel + 1 end
end
check(before_steel > 0 and after_steel == before_steel, "i tubi d'acciaio restano dopo un'esplosione")

-- Sparo: dopo lo sparo ci si può ancora muovere per qualche secondo, poi il turno passa
run(g, 60)
local fx = rb.x
g:step({ fire = { angle = math.rad(60), power = 0.6 } })
check(g.phase == "flying" and g.retreat > 0, "il missile parte e inizia la ritirata")
run(g, 30, { left = true })
check(rb.x < fx - 10, "durante la ritirata il robot si muove")
local exploded = false
for _ = 1, 900 do
	g:step()
	for _, e in ipairs(g:pop_events()) do
		if e.type == "explosion" or e.type == "miss" then exploded = true end
	end
	if g.current == 2 then break end
end
check(exploded, "il missile esplode o esce dalla mappa")
check(g.current == 2, "il turno passa al giocatore 2")
local lx = rb.x
run(g, 30, { left = true })
check(rb.x == lx, "finita la ritirata il robot non si muove più")

-- Esplosione diretta su un robot: danno e cratere
local g2 = game.new(7, "casuale")
run(g2, 120)
local r2 = g2.robots[2]
local t0 = solid_count(g2.terrain)
g2:explode(r2.x, r2.y + 2)
check(r2.hp < game.MAX_HP, "l'esplosione fa danno")
check(solid_count(g2.terrain) < t0, "l'esplosione scava un cratere")

-- Teletrasporto e Lama di Nucleo ---------------------------------------------

-- Un'area di cielo libero dove mettere i robot a mano
local function sky_spot(q, x0, w)
	for y = game.WORLD_H - 60, 100, -4 do
		local free = true
		for x = x0 - w, x0 + w, 4 do
			if q:robot_collides(x, y) or q:robot_collides(x, y - 40) then free = false; break end
		end
		if free then return y end
	end
end

local function place(rb, x, y)
	rb.x, rb.y, rb.vx, rb.vy, rb.grounded, rb.knocked = x, y, 0, 0, false, false
end

-- Lanciare il globo non chiude il turno; dopo 2 secondi il robot è dove si trova il globo
local tp = game.new(42, "isole")
run(tp, 120)
tp:pop_events()
local tr = tp.robots[1]
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(tp.orb ~= nil and tp.phase == "aim", "il globo parte e il turno continua")
tp:step({ fire = { angle = math.rad(20), power = 0.5, weapon = "teleport" } })
local ox, oy = tp.orb.x, tp.orb.y
tp:step()
check(tp.orb.x ~= ox or tp.orb.y ~= oy, "il globo vola")
local tp_ev, last_orb
for _ = 1, game.TELEPORT_TICKS do
	if tp.orb then last_orb = { x = tp.orb.x, y = tp.orb.y } end
	tp:step()
	for _, e in ipairs(tp:pop_events()) do
		if e.type == "teleport" then tp_ev = e end
	end
end
check(tp_ev and tp_ev.type == "teleport", "dopo qualche secondo il robot si teletrasporta")
check(tp_ev and math.abs(tp_ev.x - last_orb.x) <= 8 and math.abs(tp_ev.y - (last_orb.y - game.ROBOT_H / 2)) <= 24,
	"il robot compare dove si trova il globo")
check(tp.phase == "aim" and tp.current == 1, "dopo il teletrasporto si può ancora attaccare")
check(tp.orb == nil, "il globo sparisce dopo il teletrasporto")
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(tp.orb ~= nil and tp.phase == "aim", "nello stesso turno si può lanciare un altro globo")

-- Lo stato si conserva: chi sta cadendo continua a cadere con la stessa velocità
local function falling(with_orb)
	local q = game.new(42, "isole")
	run(q, 120)
	local r = q.robots[1]
	local y = sky_spot(q, 640, 120)
	place(r, 560, y)
	r.vx, r.vy = 40, -250
	if with_orb then
		q.orb = { x = 720, y = y + game.ROBOT_H / 2, vx = 0, vy = 0, owner = 1, timer = 1 }
	end
	q:step()
	return r, y
end
local fr, fy = falling(true)
local nr = falling(false)
check(fr.x == 720 and math.abs(fr.y - fy) < 1, "il teletrasporto porta il robot nel punto del globo")
check(fr.vx == nr.vx and fr.vy == nr.vy and fr.vy < -250,
	"la velocità di caduta resta la stessa dopo il teletrasporto")
check(not fr.grounded, "il robot non viene appoggiato a terra")

-- Il globo non si appiccica: tocca terra e rotola
local rl = game.new(42, "isole")
run(rl, 120)
local rr = rl.robots[1]
local gy = rr.y
rl.orb = { x = rr.x + 30, y = gy + 40, vx = 120, vy = -100, owner = 1, timer = 60 }
local touched_x
for _ = 1, 40 do
	rl:step()
	if rl.orb and not touched_x and rl.terrain:solid(rl.orb.x, rl.orb.y - 3) then touched_x = rl.orb.x end
end
check(touched_x and rl.orb and rl.orb.x > touched_x + 10, "il globo rotola dopo aver toccato terra")
check(rl.orb and not rl.terrain:solid(rl.orb.x, rl.orb.y), "il globo non entra nel terreno")

-- Il teletrasporto avviene sempre, anche se il globo è in un punto impossibile
local im = game.new(42, "isole")
run(im, 120)
local ir = im.robots[1]
local tx0 = ir.x
-- un tunnel troppo stretto per il robot, scavato nel terreno pieno sotto i suoi piedi
for cx = math.floor((tx0 + 100) / game.CELL), math.floor((tx0 + 110) / game.CELL) do
	im.terrain:set(cx, math.floor((ir.y - 30) / game.CELL), 0)
end
im.orb = { x = tx0 + 105, y = ir.y - 30, vx = 0, vy = 0, owner = 1, timer = 1 }
local im_tp
im:step()
for _, e in ipairs(im:pop_events()) do if e.type == "teleport" then im_tp = e end end
check(im_tp ~= nil, "nel punto impossibile ti teletrasporta lo stesso")
check(im_tp and not im:robot_collides(ir.x, ir.y) and math.abs(ir.x - (tx0 + 105)) <= 48,
	"e ti mette nel punto libero più vicino")

-- Se il globo esce dalla mappa il teletrasporto ti porta lì e cadi
local om = game.new(42, "isole")
run(om, 120)
om.orb = { x = -200, y = -100, vx = 0, vy = 0, owner = 1, timer = 1 }
om:step()
om:step()
check(om.robots[1].dead, "un globo fuori dalla mappa ti fa cadere nel vuoto")

-- Fendente: colpisce dietro la schiena e davanti
local function sword_game()
	local q = game.new(42, "isole")
	run(q, 120)
	q:pop_events()
	local y = sky_spot(q, 640, 300)
	-- un terzo robot per provare la combo dietro + davanti
	local r3 = {}
	for k, v in pairs(q.robots[2]) do r3[k] = v end
	r3.id = 3
	q.robots[3] = r3
	return q, y
end

local sw, swy = sword_game()
place(sw.robots[1], 640, swy)
place(sw.robots[2], 640 - 25, swy)  -- dietro (il robot 1 guarda a destra)
place(sw.robots[3], 640 + 25, swy)  -- davanti
sw:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
check(sw.phase == "flying" and sw.retreat > 0, "il fendente è un attacco: parte la ritirata")
local order = {}
for _ = 1, game.SWORD_TICKS do
	sw:step()
	for _, e in ipairs(sw:pop_events()) do
		if e.type == "sword_hit" then order[#order + 1] = e.target end
	end
end
check(order[1] == 2 and order[2] == 3, "la spada colpisce prima dietro e poi davanti")
check(sw.robots[2].hp == game.MAX_HP - game.SWORD_DAMAGE and sw.robots[3].hp == game.MAX_HP - game.SWORD_DAMAGE,
	"ogni bersaglio subisce il danno una volta sola")

-- Combo: colpo dietro la schiena, teletrasporto a metà fendente, colpo davanti nel punto d'arrivo
local function combo(with_orb)
	local q, y = sword_game()
	place(q.robots[1], 400, y)
	place(q.robots[2], 400 - 25, y)  -- dietro, nel punto di partenza
	place(q.robots[3], 800 + 25, y)  -- davanti, nel punto d'arrivo
	q.robots[3].vy, q.robots[3].vx = 0, 0
	if with_orb then
		q.orb = { x = 800, y = y + game.ROBOT_H / 2, vx = 0, vy = 0, owner = 1, timer = game.SWORD_TICKS / 2 }
	end
	q:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
	local seq = {}
	for _ = 1, game.SWORD_TICKS do
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "sword_hit" then seq[#seq + 1] = "hit" .. e.target end
			if e.type == "teleport" then seq[#seq + 1] = "tp" end
		end
	end
	return table.concat(seq, " ")
end
check(combo(true) == "hit2 tp hit3", "combo: dietro, teletrasporto, davanti (" .. combo(true) .. ")")
check(combo(false) == "hit2", "senza globo il bersaglio lontano non viene colpito")

-- Il turno aspetta il globo e la ritirata, poi passa all'avversario
local tw = game.new(42, "isole")
run(tw, 120)
tw:step({ fire = { angle = math.rad(90), power = 0.2, weapon = "teleport" } })
run(tw, 30)
tw:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
local tw_tp = false
for _ = 1, 900 do
	tw:step()
	for _, e in ipairs(tw:pop_events()) do
		if e.type == "teleport" then tw_tp = tw.current == 1 end
	end
	if tw.current == 2 then break end
end
check(tw_tp, "il turno non passa prima che il globo abbia finito")
check(tw.current == 2, "dopo fendente e teletrasporto il turno passa")

-- Determinismo: stesso seed, stessi input, stesso risultato
local function play(seed, map)
	local p = game.new(seed, map)
	for i = 1, 3000 do
		local input = { left = math.floor(i / 40) % 3 == 0, jump = i % 97 == 0 }
		if p.phase == "aim" and p.timer == game.TURN_TICKS - 30 then
			input.fire = { angle = math.rad(p.current == 1 and 45 or 135), power = 0.7,
				weapon = p.current == 2 and "sword" or nil }
		elseif p.phase == "aim" and p.timer == game.TURN_TICKS - 10 then
			input.fire = { angle = math.rad(60), power = 0.5, weapon = "teleport" }
		end
		p:step(input)
	end
	return p.robots[1].x, p.robots[1].hp, p.robots[2].x, p.robots[2].hp, solid_count(p.terrain)
end
for _, map in ipairs(maps.order) do
	local a = { play(99, map) }
	local b = { play(99, map) }
	local same = true
	for i = 1, #a do if a[i] ~= b[i] then same = false end end
	check(same, map .. ": stesso seed e stessi input danno lo stesso risultato")
end

-- Una partita finisce
local g3 = game.new(3, "isole")
g3.robots[2].hp = 1
g3:explode(g3.robots[2].x, g3.robots[2].y + 8)
run(g3, game.TURN_TICKS + 600)
check(g3.phase == "over" and g3.winner == 1, "la partita finisce e vince il giocatore 1")

-- Il fendente resta nella direzione di partenza anche se il robot si gira
local g5 = game.new(7, "isole")
for _ = 1, 120 do g5:step({}) end -- i robot cadono e si posano
g5.robots[2].x, g5.robots[2].y = g5.robots[1].x + 25, g5.robots[1].y
g5.robots[2].vx, g5.robots[2].vy = 0, 0
g5:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
check(g5.robots[1].swing_dir == 1, "il fendente parte verso destra")
for _ = 1, 4 do g5:step({ left = true }) end
check(g5.robots[1].facing == -1 and g5.robots[1].swing_dir == 1, "girarsi non cambia la direzione del fendente")
run(g5, game.SWORD_TICKS)
check(g5.robots[2].hp < game.MAX_HP, "il fendente colpisce a destra anche dopo essersi girato")

-- Il colpo di spada fa danno ma non fa volare l'avversario
local g6 = game.new(7, "isole")
for _ = 1, 120 do g6:step({}) end
local t6 = g6.robots[2]
t6.x, t6.y = g6.robots[1].x + 25, g6.robots[1].y
for _ = 1, 30 do g6:step({}) end -- si posa nel nuovo punto
local tx6, ty6 = t6.x, t6.y
g6:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
run(g6, game.SWORD_TICKS + 30)
check(t6.hp < game.MAX_HP, "la spada fa danno")
check(t6.x == tx6 and t6.y == ty6 and t6.grounded, "la spada non sposta l'avversario")

-- Partita a tempo: dopo 3 minuti finisce e vince chi ha più vita
local g7 = game.new(42, "isole")
g7.robots[1].hp = 60
g7.robots[2].hp = 80
local ticks7 = 0
while g7.phase ~= "over" and ticks7 < game.MATCH_TICKS + 2000 do
	g7:step({})
	ticks7 = ticks7 + 1
end
check(g7.phase == "over" and ticks7 >= game.MATCH_TICKS, "la partita finisce allo scadere dei 3 minuti")
check(g7.winner == 2, "a tempo scaduto vince chi ha più vita")
check(ticks7 < game.MATCH_TICKS + game.TURN_TICKS, "il turno in corso si chiude allo scadere")

-- A parità di vita vince chi ha inflitto più danni, altrimenti pareggio
local g8 = game.new(42, "isole")
g8.robots[1].dealt = 10
check(g8:ranking() == 1 and g8.podium[1] == 1 and g8.podium[2] == 2, "a parità di vita conta il danno inflitto")
g8.robots[1].dealt = 0
check(g8:ranking() == nil, "pari in tutto è pareggio")

-- Prestazioni: un cratere e 600 tick di simulazione
local t = os.clock()
local g4 = game.new(5, "casuale")
for i = 1, 600 do g4:step({ right = i % 2 == 0 }) end
for i = 1, 20 do g4.terrain:carve(100 + i * 50, 200, 30) end
print(string.format("info 600 tick + 20 crateri in %.1f ms", (os.clock() - t) * 1000))

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test superati")
