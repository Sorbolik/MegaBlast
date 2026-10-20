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
check(tp.orbs[1] ~= nil and tp.phase == "aim", "il globo parte e il turno continua")
tp:step()
local ox, oy = tp.orbs[1].x, tp.orbs[1].y
tp:step()
check(tp.orbs[1].x ~= ox or tp.orbs[1].y ~= oy, "il globo vola")
local tp_ev, last_orb
for _ = 1, game.TELEPORT_TICKS do
	if tp.orbs[1] then last_orb = { x = tp.orbs[1].x, y = tp.orbs[1].y } end
	tp:step()
	for _, e in ipairs(tp:pop_events()) do
		if e.type == "teleport" then tp_ev = e end
	end
end
check(tp_ev and tp_ev.type == "teleport", "dopo qualche secondo il robot si teletrasporta")
check(tp_ev and math.abs(tp_ev.x - last_orb.x) <= 8 and math.abs(tp_ev.y - (last_orb.y - game.ROBOT_H / 2)) <= 24,
	"il robot compare dove si trova il globo")
check(tp.phase == "aim" and tp.current == 1, "dopo il teletrasporto si può ancora attaccare")
check(tp.orbs[1] == nil, "il globo sparisce dopo il teletrasporto")
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(tp.orbs[1] ~= nil and tp.phase == "aim", "nello stesso turno si può lanciare un altro globo")

-- Più globi in volo insieme: ognuno teletrasporta allo scadere del suo tempo,
-- e in mezzo si può sparare. Il turno passa solo quando tutti hanno finito.
local function multi(plan)
	local q = game.new(42, "isole")
	run(q, 120)
	q:pop_events()
	local seq = {}
	for i = 1, 900 do
		local f = plan[i]
		if f == "tp" then
			q:step({ fire = { angle = math.rad(90), power = 0.15, weapon = "teleport" } })
		elseif f == "missile" then
			q:step({ fire = { angle = math.rad(60), power = 0.6 } })
		else
			q:step()
		end
		for _, e in ipairs(q:pop_events()) do
			if e.type == "orb" or e.type == "teleport" or e.type == "fire" or e.type == "turn" then
				seq[#seq + 1] = e.type
			end
		end
		if q.current == 2 then break end
	end
	return table.concat(seq, " ")
end
local m1 = multi({ [1] = "tp", [20] = "tp", [40] = "missile" })
check(m1 == "orb orb fire teleport teleport turn", "tp, tp, missile: due teletrasporti e poi il turno passa (" .. m1 .. ")")
local m2 = multi({ [1] = "tp", [60] = "tp", [game.TELEPORT_TICKS + 10] = "missile" })
check(m2 == "orb orb teleport fire teleport turn", "tp, tp, teletrasporto, missile, teletrasporto (" .. m2 .. ")")

-- Lo stato si conserva: chi sta cadendo continua a cadere con la stessa velocità
local function falling(with_orb)
	local q = game.new(42, "isole")
	run(q, 120)
	local r = q.robots[1]
	local y = sky_spot(q, 640, 120)
	place(r, 560, y)
	r.vx, r.vy = 40, -250
	if with_orb then
		q.orbs = { { x = 720, y = y + game.ROBOT_H / 2, vx = 0, vy = 0, owner = 1, timer = 1 } }
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
rl.orbs = { { x = rr.x + 30, y = gy + 40, vx = 120, vy = -100, owner = 1, timer = 60 } }
local touched_x
for _ = 1, 40 do
	rl:step()
	if rl.orbs[1] and not touched_x and rl.terrain:solid(rl.orbs[1].x, rl.orbs[1].y - 3) then touched_x = rl.orbs[1].x end
end
check(touched_x and rl.orbs[1] and rl.orbs[1].x > touched_x + 10, "il globo rotola dopo aver toccato terra")
check(rl.orbs[1] and not rl.terrain:solid(rl.orbs[1].x, rl.orbs[1].y), "il globo non entra nel terreno")

-- Il teletrasporto avviene sempre, anche se il globo è in un punto impossibile
local im = game.new(42, "isole")
run(im, 120)
local ir = im.robots[1]
local tx0 = ir.x
-- un tunnel troppo stretto per il robot, scavato nel terreno pieno sotto i suoi piedi
for cx = math.floor((tx0 + 100) / game.CELL), math.floor((tx0 + 110) / game.CELL) do
	im.terrain:set(cx, math.floor((ir.y - 30) / game.CELL), 0)
end
im.orbs = { { x = tx0 + 105, y = ir.y - 30, vx = 0, vy = 0, owner = 1, timer = 1 } }
local im_tp
im:step()
for _, e in ipairs(im:pop_events()) do if e.type == "teleport" then im_tp = e end end
check(im_tp ~= nil, "nel punto impossibile ti teletrasporta lo stesso")
check(im_tp and not im:robot_collides(ir.x, ir.y, ir) and math.abs(ir.x - (tx0 + 105)) <= 48,
	"e ti mette nel punto libero più vicino")

-- Se il globo esce dalla mappa il teletrasporto ti porta lì e cadi
local om = game.new(42, "isole")
run(om, 120)
om.orbs = { { x = -200, y = -100, vx = 0, vy = 0, owner = 1, timer = 1 } }
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
		q.orbs = { { x = 800, y = y + game.ROBOT_H / 2, vx = 0, vy = 0, owner = 1, timer = math.floor(game.SWORD_TICKS * 0.75) } }
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

-- Il fendente non è lineare: prima torna un po' indietro, poi accelera fino alla fine
local a0, a1 = game.sword_angle(0), game.sword_angle(game.SWORD_TICKS * 0.3)
check(a1 > a0, "all'inizio del fendente la lama va un po' indietro")
local function step_deg(u)
	local t = game.SWORD_TICKS
	return math.abs(math.deg(game.sword_angle(t * u + 1) - game.sword_angle(t * u)))
end
check(step_deg(0.9) > 2 * step_deg(0.55), "verso la fine il fendente è sempre più veloce")
check(math.abs(game.sword_angle(game.SWORD_TICKS) - game.SWORD_TO) < 1e-9, "il fendente finisce davanti in basso")

-- Collisioni: i robot non si attraversano, camminando si spingono un pizzico
local cg = game.new(7, "isole")
for _ = 1, 120 do cg:step({}) end
local c1, c2 = cg.robots[1], cg.robots[2]
c2.x, c2.y, c2.vx, c2.vy = c1.x + 20, c1.y + 4, 0, 0
for _ = 1, 30 do cg:step({}) end -- il robot 2 si posa
local c2x = c2.x
local c1x = c1.x
for _ = 1, 60 do cg:step({ right = true }) end
check(c2.x > c1.x and cg:robot_at(c1.x, c1.y, c1) == nil, "i robot non si attraversano")
check(c2.x > c2x + 2 and c2.x < c2x + 35, string.format("camminando si spinge l'altro un pizzico (%.1f px)", c2.x - c2x))
check(c1.x < c1x + 50, "chi spinge va più piano")

-- Un robot che cade su un altro gli resta sopra
local hg = game.new(7, "isole")
for _ = 1, 120 do hg:step({}) end
local h1, h2 = hg.robots[1], hg.robots[2]
h2.x, h2.y, h2.vx, h2.vy, h2.grounded = h1.x, h1.y + 60, 0, 0, false
for _ = 1, 90 do hg:step({}) end
check(h2.grounded and math.abs(h2.y - (h1.y + game.ROBOT_H)) < 1.01, "chi cade su un robot gli resta in testa")

-- Il globo che arriva addosso a un robot lo sposta un briciolo e rimbalza
local og = game.new(7, "isole")
for _ = 1, 120 do og:step({}) end
local o2 = og.robots[2]
local o2x = o2.x
og.orbs = { { id = 99, x = o2.x - 30, y = o2.y + 8, vx = 400, vy = 0, owner = 1, timer = 60, age = 100 } }
local bounced = false
for _ = 1, 10 do
	og:step({})
	if og.orbs[1] and og.orbs[1].vx < 0 then bounced = true end
end
check(o2.x > o2x and o2.x <= o2x + game.ORB_NUDGE + 0.01, string.format("il globo sposta il robot di un briciolo (%.1f px)", o2.x - o2x))
check(bounced, "il globo rimbalza sul robot")

-- I globi si urtano anche tra loro
local bg = game.new(42, "isole")
run(bg, 120)
local by = 500 -- cielo libero sulla mappa isole
bg.orbs = {
	{ id = 1, x = 600, y = by, vx = 200, vy = 0, owner = 1, timer = 100, age = 100 },
	{ id = 2, x = 680, y = by, vx = -200, vy = 0, owner = 1, timer = 100, age = 100 },
}
for _ = 1, 20 do bg:step({}) end
check(bg.orbs[1].x < bg.orbs[2].x and bg.orbs[1].vx < 0 and bg.orbs[2].vx > 0, "due globi che si scontrano rimbalzano")

-- Armi delle casse -------------------------------------------------------------

-- Senza colpi le armi delle casse non sparano; con un colpo sparano una volta
local am = game.new(42, "isole")
run(am, 120)
am:step({ fire = { angle = math.rad(45), power = 0.6, weapon = "grenade" } })
check(am.phase == "aim" and not am.projectile, "senza colpi l'Uovo di Fiamma non parte")
am.robots[1].ammo.grenade = 1
am:step({ fire = { angle = math.rad(45), power = 0.6, weapon = "grenade" } })
check(am.projectile and am.projectile.kind == "grenade" and am.robots[1].ammo.grenade == 0,
	"con un colpo l'Uovo parte e il colpo si consuma")

-- Uovo di Fiamma: rimbalza, si posa e scoppia dopo 3 secondi, più grande del missile
local gr = game.new(42, "isole")
run(gr, 120)
gr:pop_events()
gr.robots[1].ammo.grenade = 1
local gy0 = sky_spot(gr, 640, 60)
place(gr.robots[1], 640, gy0)
gr:step({ fire = { angle = math.rad(-60), power = 0.8, weapon = "grenade" } })
local bounced, boom, boom_tick = false, nil, nil
for i = 1, game.GRENADE_FUSE + 5 do
	local p = gr.projectile
	local vy0 = p and p.vy
	gr:step()
	if p and gr.projectile and vy0 < 0 and gr.projectile.vy > 0 then bounced = true end
	for _, e in ipairs(gr:pop_events()) do
		if e.type == "explosion" and not boom then boom, boom_tick = e, i end
	end
end
check(bounced, "l'Uovo rimbalza sul terreno")
check(boom and boom.r == game.GRENADE_BLAST.r and boom.r > game.EXPLOSION_R, "l'Uovo fa un'esplosione più grande del missile")
check(boom_tick and math.abs(boom_tick - game.GRENADE_FUSE) <= 1, "l'Uovo scoppia dopo 3 secondi (" .. tostring(boom_tick) .. " tick)")

-- Sciame di Schegge: una raffica di SHARD_COUNT schegge con piccoli crateri
local sh = game.new(42, "isole")
run(sh, 120)
sh:pop_events()
sh.robots[1].ammo.shards = 1
local tx = sh.robots[2]
sh:step({ fire = { angle = math.atan2(tx.y - sh.robots[1].y, tx.x - sh.robots[1].x), power = 1, weapon = "shards" } })
local booms, max_flying = 0, 0
for _ = 1, 120 do
	sh:step()
	local n = 0
	for i = 1, game.SHARD_COUNT do if sh.shards[i] then n = n + 1 end end
	max_flying = math.max(max_flying, n)
	for _, e in ipairs(sh:pop_events()) do
		if e.type == "explosion" then
			booms = booms + 1
			check(e.r == game.SHARD_BLAST.r, "le schegge fanno crateri piccoli")
		end
	end
end
check(booms == game.SHARD_COUNT, "la raffica spara " .. game.SHARD_COUNT .. " schegge (" .. booms .. ")")
check(max_flying > 1, "più schegge in volo insieme")
check(sh.phase ~= "flying", "finita la raffica il turno va avanti")

-- Pugno del Titano: lancia in alto chi è davanti, non chi è dietro
local function punch_game(dx)
	local q = game.new(42, "isole")
	run(q, 120)
	q:pop_events()
	local y = sky_spot(q, 640, 120)
	place(q.robots[1], 640, y)
	place(q.robots[2], 640 + dx, y)
	q.robots[1].ammo.punch = 1
	q:step({ fire = { angle = 0, power = 1, weapon = "punch" } })
	local hit
	for _ = 1, game.PUNCH_TICKS do
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "punch_hit" then hit = { vx = q.robots[2].vx, vy = q.robots[2].vy } end
		end
	end
	return q, hit
end
local pq, ph = punch_game(14)
check(ph and pq.robots[2].hp == game.MAX_HP - game.PUNCH_DAMAGE, "il pugno colpisce chi è davanti")
check(ph and ph.vy == game.PUNCH_LAUNCH and ph.vx > 0, "il pugno lancia in alto e in avanti")
local _, ph2 = punch_game(-14)
check(ph2 == nil, "il pugno non colpisce chi è dietro")

-- Casse ---------------------------------------------------------------------------

-- Una cassa cade dopo ogni 3 turni, sempre nello stesso punto con lo stesso seed
local function crate_turns(seed)
	local q = game.new(seed, "isole")
	local spawned = {}
	for _ = 1, 12000 do
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "crate" then spawned[#spawned + 1] = { turn = q.turn_no, x = e.x, y = e.y } end
		end
		if #spawned >= 2 then break end
	end
	return q, spawned
end
local cq, cs = crate_turns(42)
check(cs[1] and cs[1].turn == 4 and cs[2] and cs[2].turn == 7, "una cassa ogni 3 turni (turni " ..
	tostring(cs[1] and cs[1].turn) .. ", " .. tostring(cs[2] and cs[2].turn) .. ")")
local _, cs2 = crate_turns(42)
check(cs2[1] and cs2[1].x == cs[1].x and cs2[2].x == cs[2].x, "stesso seed, casse negli stessi punti")
local _, cs3 = crate_turns(7)
check(cs3[1] and cs3[1].x ~= cs[1].x, "con un altro seed le casse cadono altrove")
local c1, c2 = cq.crates[1], cq.crates[2]
check(#cq.crates == 2 and c2.y > game.WORLD_H, "la cassa nuova cade dal cielo")
check(c1.landed and math.abs(c1.y - cs[1].y) <= game.CELL, "la cassa si posa sulla superficie")
check(c1.x >= 40 and c1.x <= game.WORLD_W - 40 and c2.x >= 40 and c2.x <= game.WORLD_W - 40, "le casse sono dentro la mappa")

-- Toccare una cassa dà un colpo di un'arma delle casse
local pk = game.new(42, "isole", { crate_every = 1 })
run(pk, 120)
local c = pk:spawn_crate()
check(c ~= nil and c.y > game.WORLD_H, "la cassa parte dal cielo")
run(pk, 600)
check(c.landed, "la cassa atterra")
pk:pop_events()
local pr = pk.robots[pk.current]
place(pr, c.x, c.y)
pk:step()
local got
for _, e in ipairs(pk:pop_events()) do if e.type == "crate_pick" then got = e end end
check(got and got.robot == pr.id and pr.ammo[got.weapon] == 1, "chi tocca la cassa trova un'arma (" ..
	tostring(got and got.weapon) .. ")")
check(#pk.crates == 0, "la cassa raccolta sparisce")

-- Le casse scelgono tutte e tre le armi
local seen = {}
local mix = game.new(11, "isole")
for _ = 1, 30 do
	mix.crates = {}
	local cc = mix:spawn_crate()
	if cc then seen[cc.weapon] = true end
end
check(seen.grenade and seen.shards and seen.punch, "nelle casse si trovano tutte e tre le armi")

-- Determinismo con le armi nuove: stesso seed e stessi input, stesso risultato
local function play2(seed)
	local p = game.new(seed, "isole", { ammo = { grenade = 9, shards = 9, punch = 9 }, crate_every = 1 })
	local ws = { "grenade", "shards", "punch", "missile" }
	local k = 0
	for i = 1, 4000 do
		local input = { right = math.floor(i / 50) % 2 == 0, jump = i % 83 == 0 }
		if p.phase == "aim" and p.timer == game.TURN_TICKS - 40 then
			k = k + 1
			input.fire = { angle = math.rad(p.current == 1 and 40 or 140), power = 0.7, weapon = ws[k % #ws + 1] }
		end
		p:step(input)
	end
	local r = { p.robots[1].x, p.robots[1].hp, p.robots[2].x, p.robots[2].hp, solid_count(p.terrain), #p.crates }
	for _, cr in ipairs(p.crates) do r[#r + 1] = cr.x; r[#r + 1] = cr.y end
	return table.concat(r, " ")
end
check(play2(5) == play2(5), "armi delle casse e casse sono deterministiche")

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
