-- Test della simulazione. Dalla radice del repository:
--   lua tests/sim_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local config = require "sim.config"
local mischia = require "sim.mischia"
local maps = require "sim.maps"
local terrain = require "sim.terrain"

-- Quasi tutti i test sono scritti per i valori "megablast"; quelli del profilo
-- "blastron" (il predefinito) sono in fondo.
game.use_physics("megablast")

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
	local q = game.new(42, "isole", { players = { { team = 1, stats = stats }, { team = 2 } } })
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
local hj = game.new(42, "isole", { players = { { team = 1, stats = { jump_height = 120 } }, { team = 2 } } })
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
check(g.phase == "aim" and g.window > 0 and g.used.weapon, "il missile parte e si apre il tempo del secondo attacco")
run(g, 30, { left = true })
check(rb.x < fx - 10, "dopo lo sparo il robot si muove")
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
check(r2.hp < r2.max_hp, "l'esplosione fa danno")
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
check(tr.nucleo == config.STATS.start_nucleo - config.STATS.teleport_cost, "il teletrasporto costa Nucleo")
tr.nucleo = 5
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(tp.orbs[1] == nil and tr.nucleo == 5, "al primo turno si fa un solo teletrasporto")
tr.turns = 2
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(tp.orbs[1] ~= nil and tr.nucleo == 4, "dal secondo turno, con Nucleo, se ne lancia un altro")
tr.nucleo = 0
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(#tp.orbs == 1, "senza Nucleo il globo non parte")

-- Più globi in volo insieme: ognuno teletrasporta allo scadere del suo tempo,
-- e in mezzo si può sparare. Il turno passa solo quando tutti hanno finito.
-- Un robot che può teletrasportarsi quanto vuole (per le prove)
local function free_tp(r)
	r.nucleo, r.turns = 99, 2
end

local function multi(plan)
	local q = game.new(42, "isole")
	run(q, 120)
	q:pop_events()
	free_tp(q.robots[1])
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
check(sw.used.sword and sw.window > 0, "il fendente è un attacco: si apre il tempo del secondo")
local order = {}
for _ = 1, game.SWORD_TICKS do
	sw:step()
	for _, e in ipairs(sw:pop_events()) do
		if e.type == "sword_hit" then order[#order + 1] = e.target end
	end
end
check(order[1] == 2 and order[2] == 3, "la spada colpisce prima dietro e poi davanti")
check(sw.robots[2].hp == sw.robots[2].max_hp - game.SWORD_DAMAGE and sw.robots[3].hp == sw.robots[3].max_hp - game.SWORD_DAMAGE,
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

-- Due attacchi per turno e Nucleo --------------------------------------------------
do

	local MISSILE = { fire = { angle = math.rad(60), power = 0.6 } }
	local SWORD = { fire = { angle = 0, power = 1, weapon = "sword" } }
	local TELE = { fire = { angle = math.rad(90), power = 0.2, weapon = "teleport" } }

	-- Primo attacco dopo 9 s: restano 16 s, cioè 3 Nucleo (mai oltre NUCLEO_MAX)
	local at = game.new(42, "isole")
	local ar = at.robots[1]
	run(at, 9 * 60 - 1)
	at:pop_events()
	at:step(MISSILE)
	local gain = math.min(math.floor(at.timer / (60 * config.NUCLEO_SECONDS)), config.NUCLEO_MAX - config.STATS.start_nucleo)
	local nev
	for _, e in ipairs(at:pop_events()) do if e.type == "nucleo" then nev = e end end
	check(ar.nucleo == config.STATS.start_nucleo + gain and nev and nev.amount == gain,
		"i secondi rimasti al primo attacco diventano Nucleo (" .. ar.nucleo .. ")")
	check(at.window == game.SECOND_ATTACK_TICKS, "dopo il primo attacco ci sono 5 s per il secondo")
	at:step(MISSILE)
	check(not at:can_use("missile") and at.used.weapon, "una sola arma per turno")
	local n0 = ar.nucleo
	run(at, 60)
	at:step(SWORD)
	check(at.used.sword and at.window == 0 and at.retreat == game.REPOSITION_TICKS,
		"spada come secondo attacco: poi 5 s di riposizionamento")
	check(ar.nucleo == n0, "il secondo attacco non dà Nucleo")
	check(not at:can_use("teleport") and not at:can_use("sword"), "nel riposizionamento niente attacchi né teletrasporto")
	local turn_at
	for i = 1, 2000 do
		at:step()
		if at.current == 2 then turn_at = i break end
	end
	check(turn_at and turn_at >= game.REPOSITION_TICKS, "il turno passa dopo il riposizionamento")

	-- Se il secondo attacco non arriva, dopo 5 s si passa comunque al riposizionamento
	local aw = game.new(42, "isole")
	run(aw, 60)
	aw:step(SWORD)
	run(aw, game.SECOND_ATTACK_TICKS)
	check(aw.window == 0 and aw.retreat > 0 and not aw:can_use("missile"), "scaduti i 5 s non si attacca più")

	-- Ordine libero: prima la spada, poi il missile
	local ao = game.new(42, "isole")
	run(ao, 60)
	ao:step(SWORD)
	run(ao, 30)
	check(ao:can_use("missile"), "dopo la spada si può ancora sparare")
	ao:step(MISSILE)
	check(ao.used.weapon and ao.retreat > 0, "spada e missile nello stesso turno")

	-- Il teletrasporto si lancia fino al colpo di spada, non dopo
	local ak = game.new(42, "isole")
	run(ak, 60)
	free_tp(ak.robots[1])
	ak:step(MISSILE)
	check(ak:can_use("teleport"), "dopo il missile il teletrasporto si può ancora lanciare")
	ak:step(SWORD)
	check(not ak:can_use("teleport"), "dopo il colpo di spada no")

	-- Chi attacca allo scadere non ha tempo per altro
	local az = game.new(42, "isole")
	run(az, game.TURN_TICKS - 2)
	az:step(MISSILE)
	check(az.used.weapon and az.window <= 1, "attaccando allo scadere non resta tempo")
	run(az, 3)
	check(az.phase ~= "aim", "il turno chiude allo scadere anche dopo un attacco")

	-- I teletrasporti gratis si usano prima del Nucleo
	local fz = game.new(42, "isole", { players = { { team = 1, stats = { free_teleports = 1 } }, { team = 2 } } })
	run(fz, 60)
	fz:step(TELE)
	check(#fz.orbs == 1 and fz.robots[1].free_teleports == 0 and fz.robots[1].nucleo == config.STATS.start_nucleo,
		"il teletrasporto gratis non consuma Nucleo")

	-- La vita parte dal valore del config e si può cambiare per robot
	local hv = game.new(42, "isole", { players = { { team = 1, stats = { max_hp = 200 } }, { team = 2 } } })
	check(hv.robots[1].hp == 200 and hv.robots[2].hp == config.STATS.max_hp, "vita dalle statistiche del robot")
end

-- Da 2 a 4 giocatori, con squadre -------------------------------------------------
do

	-- 2 contro 2: le squadre si alternano e i compagni partono dallo stesso lato
	local four = { { team = 1 }, { team = 1 }, { team = 2 }, { team = 2 } }
	for _, id in ipairs(maps.order) do
		local q = game.new(42, id, { players = four })
		run(q, 120)
		local ok = #q.robots == 4
		for _, r in ipairs(q.robots) do ok = ok and r.grounded and not r.dead end
		check(ok, id .. ": quattro robot compaiono appoggiati al terreno")
		check((q.robots[1].x < 640) == (q.robots[2].x < 640) and (q.robots[3].x < 640) == (q.robots[4].x < 640)
			and (q.robots[1].x < 640) ~= (q.robots[3].x < 640), id .. ": i compagni partono dallo stesso lato")
	end

	-- Gioca il turno corrente (un missile verso l'alto) e restituisce chi gioca dopo
	local function next_turn(q)
		local cur = q.current
		q:step({ fire = { angle = math.rad(90), power = 0.1 } })
		for _ = 1, 3000 do
			q:step()
			if q.current ~= cur or q.phase == "over" then break end
		end
		return q.current
	end

	local q4 = game.new(42, "isole", { players = four })
	check(q4.mode == "2v2" and table.concat(q4.order, " ") == "1 3 2 4",
		"2 contro 2: turni A1, B1, A2, B2 (" .. table.concat(q4.order, " ") .. ")")
	local seen4 = { q4.current }
	for _ = 1, 4 do seen4[#seen4 + 1] = next_turn(q4) end
	check(table.concat(seen4, " ") == "1 3 2 4 1", "i turni seguono l'ordine delle squadre (" .. table.concat(seen4, " ") .. ")")
	-- chi muore ricomincia a fine turno e non perde il suo turno
	q4:kill(q4.robots[3])
	check(next_turn(q4) == 3 and not q4.robots[3].dead and q4.robots[3].hp == q4.robots[3].max_hp,
		"il robot morto ricomincia con la vita piena e gioca il suo turno")

	-- Tutti contro tutti: quattro squadre da uno, turni nell'ordine di arrivo
	local ffa = game.new(42, "forgia", { players = { { team = 1 }, { team = 2 }, { team = 3 }, { team = 4 } } })
	check(ffa.mode == "ffa" and table.concat(ffa.order, " ") == "1 2 3 4", "tutti contro tutti: turni 1, 2, 3, 4")
	check(game.new(42, "forgia").mode == "1v1", "senza players è un 1 contro 1")
end

-- Oggetti tattici: trappole, scudi, trampolini, paracadute, ancoraggi -------------
do
	-- le casse contengono anche gli oggetti
	local mix = game.new(5, "isole")
	local seen = {}
	for _ = 1, 60 do
		mix.crates = {}
		local c = mix:spawn_crate()
		if c then seen[c.weapon] = true end
	end
	check(seen.trap and seen.shield and seen.trampoline, "nelle casse ci sono trappole, scudi e trampolini")

	-- gli oggetti si usano anche nel riposizionamento e non sono attacchi
	local q = game.new(42, "isole", { ammo = { trap = 1, shield = 1 } })
	run(q, 60)
	local r1, r2 = q.robots[1], q.robots[2]
	q:step({ fire = { angle = 0, power = 1, weapon = "shield" } })
	check(r1.shield == config.SHIELD.hp and not q.used.weapon and not q.used.sword,
		"lo scudo si attiva e non è un attacco")
	q:step({ fire = { angle = math.rad(60), power = 0.6 } })
	q:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
	check(q.retreat > 0 and q:can_use("trap"), "nel riposizionamento la trappola si può ancora posare")
	q:step({ fire = { angle = 0, power = 1, weapon = "trap" } })
	local trap = q.placed[1]
	check(trap and trap.kind == "trap" and not trap.armed and r1.ammo.trap == 0, "la trappola è posata ai piedi, non ancora armata")

	-- scudo: assorbe il danno e finisce all'inizio del proprio turno dopo
	q:hurt(r1, 20, r2)
	check(r1.hp == r1.max_hp and r1.shield == config.SHIELD.hp - 20, "lo scudo assorbe il danno")
	check(q:knock_mul(r1) < 1, "con lo scudo si viene spinti meno")

	-- al turno dopo la trappola è armata: l'avversario che ci passa sopra vola via
	for _ = 1, 3000 do
		q:step()
		if q.current == 2 then break end
	end
	check(trap.armed and r1.shield, "al turno dopo la trappola è armata e lo scudo c'è ancora")
	r2.x, r2.y, r2.vx, r2.vy, r2.grounded = trap.x, trap.y, 0, 0, true
	local hp2 = r2.hp
	q:step()
	check(r2.vy > 0 and math.abs(r2.vx) > 0 and r2.hp == hp2 - config.TRAP.damage and #q.placed == 0,
		"la trappola lancia l'avversario e sparisce")
	for _ = 1, 3000 do
		q:step()
		if q.current == 1 then break end
	end
	check(r1.shield == nil, "lo scudo finisce all'inizio del proprio turno")

	-- un compagno non fa scattare la trappola
	local t2 = game.new(42, "isole", { players = config.MODES["2v2"], ammo = { trap = 1 } })
	run(t2, 60)
	t2:step({ fire = { angle = 0, power = 1, weapon = "trap" } })
	local tt = t2.placed[1]
	tt.armed = true
	local mate = t2.robots[3]
	mate.x, mate.y, mate.vy, mate.grounded = tt.x, tt.y, 0, true
	t2.robots[1].x = tt.x + 60
	t2:step()
	check(#t2.placed == 1 and mate.vy <= 0, "il compagno non fa scattare la trappola")

	-- trampolino: chi lo posa non rimbalza; chi ci cade sopra rimbalza una volta
	local tb = game.new(42, "isole", { ammo = { trampoline = 1 } })
	run(tb, 60)
	local a = tb.robots[1]
	tb:step({ fire = { angle = 0, power = 1, weapon = "trampoline" } })
	local tramp = tb.placed[1]
	run(tb, 5)
	check(tramp and a.grounded, "chi posa il trampolino non rimbalza")
	local b = tb.robots[2]
	b.x, b.y, b.vx, b.vy, b.grounded = tramp.x + 4, tramp.y + 60, 0, 0, false
	a.x = tramp.x - 40
	local bounces = 0
	for _ = 1, 400 do
		tb:step()
		for _, e in ipairs(tb:pop_events()) do if e.type == "bounce" then bounces = bounces + 1 end end
	end
	check(bounces == 1 and b.grounded, "si rimbalza una volta, poi ci si ferma sopra (" .. bounces .. ")")

	-- un'esplosione porta via quello che è posato
	tb:explode(tramp.x, tramp.y + 4)
	check(#tb.placed == 0, "un'esplosione distrugge il trampolino")

	-- paracadute: costa Nucleo, si apre cadendo e annulla il danno da caduta
	local pc = game.new(42, "isole")
	run(pc, 60)
	local p = pc.robots[1]
	pc:step({ fire = { angle = 0, power = 1, weapon = "parachute" } })
	check(p.parachute == "armed" and p.nucleo == config.STATS.start_nucleo - config.STATS.parachute_cost, "il paracadute costa Nucleo")
	check(not pc:can_use("parachute"), "un paracadute alla volta")
	local safe, dmg, max = game.FALL_SAFE, game.FALL_DAMAGE, game.FALL_DAMAGE_MAX
	game.FALL_SAFE, game.FALL_DAMAGE, game.FALL_DAMAGE_MAX = 10, 1, 100
	local y = sky_spot(pc, 640, 200)
	place(p, 640, y + 200)
	local opened, slowest = false, 0
	for _ = 1, 600 do
		pc:step()
		for _, e in ipairs(pc:pop_events()) do if e.type == "parachute" then opened = true end end
		slowest = math.min(slowest, p.vy)
		if p.grounded then break end
	end
	game.FALL_SAFE, game.FALL_DAMAGE, game.FALL_DAMAGE_MAX = safe, dmg, max
	check(opened and slowest >= -config.PARACHUTE.open_speed - 20 and p.hp == p.max_hp and p.parachute == nil,
		"il paracadute si apre, rallenta la caduta e si atterra senza danno")

	-- punto di ancoraggio: chi ci sta sopra viene spinto molto meno
	local an = game.new(42, "forgia")
	local anc = maps.get("forgia").anchors[1]
	local ar = an.robots[1]
	ar.x, ar.y = anc.x, anc.y
	check(an:knock_mul(ar) == config.ANCHOR_KNOCKBACK, "sull'ancoraggio la spinta si riduce")
	ar.x = anc.x + anc.r + 10
	check(an:knock_mul(ar) == 1, "fuori dall'ancoraggio la spinta è piena")
end

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

-- Punti, uccisioni e respawn -------------------------------------------------------
do
	-- uccisione a colpi: punti del danno e dell'uccisione a chi colpisce, meno a chi muore
	local g3 = game.new(3, "isole")
	run(g3, 60)
	local a, b = g3.robots[1], g3.robots[2]
	b.hp = 10
	g3:pop_events()
	g3:explode(b.x, b.y + 8, 1)
	local death
	for _, e in ipairs(g3:pop_events()) do if e.type == "death" then death = e end end
	check(b.dead and death and death.by == 1 and not death.env, "l'uccisione va a chi ha colpito")
	check(a.kills == 1 and a.points == 10 * config.SCORE.damage + config.SCORE.kill and b.points == config.SCORE.death,
		"punti: danno e uccisione a chi colpisce (" .. a.points .. "), " .. config.SCORE.death .. " a chi muore")
	-- a fine turno ricomincia in un punto a caso, lontano dagli altri
	local resp
	for _ = 1, game.TURN_TICKS + 900 do
		g3:step()
		for _, e in ipairs(g3:pop_events()) do if e.type == "respawn" then resp = e end end
		if g3.current == 2 then break end
	end
	check(resp and not b.dead and b.hp == b.max_hp and math.abs(b.x - a.x) >= config.RESPAWN_DISTANCE,
		"alla morte si ricomincia con la vita piena, lontano dagli altri")
	check(g3.phase == "aim" and g3.current == 2, "e si gioca il proprio turno")

	-- uccisione ambientale: chi colpisce un robot che poi cade fuori dalla mappa
	-- prende anche il bonus; senza colpi recenti nessuno prende niente
	local ge = game.new(3, "isole")
	run(ge, 60)
	local ea, eb = ge.robots[1], ge.robots[2]
	ge:hurt(eb, 5, ea)
	eb.x, eb.y = -40, 300
	ge:step()
	check(eb.dead and ea.env_kills == 1 and eb.falls == 1, "chi butta fuori dalla mappa fa un'uccisione ambientale")
	check(ea.points == 5 + config.SCORE.kill + config.SCORE.env_kill, "che vale più di un'uccisione a colpi (" .. ea.points .. ")")
	local gf = game.new(3, "isole")
	run(gf, 60)
	gf:hurt(gf.robots[2], 5, gf.robots[1])
	gf.tick = gf.tick + config.KILL_CREDIT_SECONDS * 60 + 1
	gf:kill(gf.robots[2], "fell")
	check(gf.robots[1].kills == 0, "una caduta molto dopo il colpo non conta come uccisione")

	-- colpire chi è primo vale di più
	local gl = game.new(3, "isole", { players = config.MODES.ffa })
	gl.robots[3].points = 100
	gl:hurt(gl.robots[3], 10, gl.robots[1])
	gl:hurt(gl.robots[4], 10, gl.robots[2])
	check(gl.robots[1].points == 10 * config.SCORE.leader and gl.robots[2].points == 10, "colpire il primo vale di più")

	-- nel 2 contro 2 il danno al compagno non dà punti, e i punti si sommano per squadra
	local gt = game.new(3, "isole", { players = config.MODES["2v2"] })
	gt:hurt(gt.robots[3], 10, gt.robots[1])
	check(gt.robots[1].points == 0, "colpire il compagno non dà punti")
	gt.robots[2].points, gt.robots[3].points, gt.robots[4].points = 30, 20, 0
	local res = gt:results()
	check(res.mode == "2v2" and res.winner == 2 and res.ranking[1].robot == 2 and res.ranking[2].robot == 4
		and res.ranking[2].place == 1 and res.ranking[3].place == 2, "risultati: classifica per punti di squadra")
	gt.robots[3].points = 30
	check(gt:results().winner == nil, "squadre pari: pareggio")
end

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
check(g5.robots[2].hp < g5.robots[2].max_hp, "il fendente colpisce a destra anche dopo essersi girato")

-- Il colpo di spada fa danno ma non fa volare l'avversario
local g6 = game.new(7, "isole")
for _ = 1, 120 do g6:step({}) end
local t6 = g6.robots[2]
t6.x, t6.y = g6.robots[1].x + 25, g6.robots[1].y
for _ = 1, 30 do g6:step({}) end -- si posa nel nuovo punto
local tx6, ty6 = t6.x, t6.y
g6:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
run(g6, game.SWORD_TICKS + 30)
check(t6.hp < t6.max_hp, "la spada fa danno")
check(t6.x == tx6 and t6.y == ty6 and t6.grounded, "la spada non sposta l'avversario")

-- Partita a tempo: dopo 5 minuti finisce e vince chi ha più vita
local g7 = game.new(42, "isole")
g7.robots[2].points = 10
local ticks7 = 0
while g7.phase ~= "over" and ticks7 < game.MATCH_TICKS + 2000 do
	g7:step({})
	ticks7 = ticks7 + 1
end
check(g7.phase == "over" and ticks7 >= game.MATCH_TICKS, "la partita finisce allo scadere dei 5 minuti")
check(g7.winner == 2, "a tempo scaduto vince chi ha più punti")
check(ticks7 < game.MATCH_TICKS + game.TURN_TICKS, "il turno in corso si chiude allo scadere")


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
check(not sh:shards_flying(), "finita la raffica non resta niente in volo")

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
check(ph and pq.robots[2].hp == pq.robots[2].max_hp - game.PUNCH_DAMAGE, "il pugno colpisce chi è davanti")
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

-- Profilo "blastron" ------------------------------------------------------------

game.use_physics("blastron")
local U = game.BLASTRON_UNIT

-- Movimento: corsa 5 u/s, salto alto 5,2 u
local bm = game.new(42, "isole")
run(bm, 120)
local br = bm.robots[1]
local x0 = br.x
run(bm, 60, { right = true })
check(math.abs((br.x - x0) - 5 * U) < 2, string.format("blastron: corsa 5 u/s (%.1f px in 1 s)", br.x - x0))
local top, base = br.y, br.y
bm:step({ jump = true })
for _ = 1, 200 do
	bm:step()
	top = math.max(top, br.y)
end
check(math.abs((top - base) - 5.2 * U) < 0.35 * U, string.format("blastron: salto alto 5,2 u (%.1f px)", top - base))

-- Controllo in aria istantaneo; senza direzione la velocità resta
local ba = game.new(42, "isole")
run(ba, 120)
local ar = ba.robots[1]
ba:step({ jump = true, right = true })
run(ba, 5, { right = true })
check(ar.vx == ar.stats.air_speed, "blastron: in aria va subito a tutta corsa")
ba:step({ left = true })
check(ar.vx == -ar.stats.air_speed, "blastron: e si gira di colpo")
ba:step()
check(ar.vx == -ar.stats.air_speed and not ar.grounded, "blastron: senza direzione in aria la velocità resta")

-- Esplosione: danno dal punto più vicino della scatola, spinta nulla nel colpo
-- diretto, massima a metà raggio, metà danno a sé stessi
local function blast_at(dx, owner)
	local q = game.new(42, "isole")
	run(q, 120)
	local r = q.robots[2]
	local y = sky_spot(q, 640, 60)
	place(r, 640, y)
	local hp = r.hp
	-- il bordo destro della scatola (col cerchio, del quadrato attorno)
	local edge = game.HURTBOX == "cerchio" and game.HURT_R + game.HURT_FAT or game.ROBOT_HALF_W
	q:explode(640 + edge + dx, y + game.ROBOT_H / 2, owner, game.MISSILE_BLAST)
	return r, hp - r.hp
end
local B = game.MISSILE_BLAST
local d0r, d0 = blast_at(-1, 1)
check(d0 == math.floor(B.damage + 0.5) and d0r.vx == 0 and d0r.vy == 0,
	"blastron: colpo diretto, danno pieno e nessuna spinta")
local half = B.damage_r / 2
local dhr, dh = blast_at(half, 1)
check(math.abs(dhr.vx + half * B.impulse * 0.5) < 0.01 and dhr.vy == 0,
	string.format("blastron: a metà raggio spinta di %.0f px/s", -dhr.vx))
check(dh == math.floor(B.damage_min + (B.damage - B.damage_min) * 0.5 + 0.5), "blastron: danno tra minimo e massimo")
local _, ds = blast_at(-1, 2)
check(ds == math.floor(B.damage * 0.5 + 0.5), "blastron: metà danno a sé stessi")

-- Dove si viene colpiti: un cerchio a metà altezza, non la scatola
local hb = game.new(42, "isole")
local hr = hb.robots[2]
local hcy = hr.y + game.ROBOT_H / 2
check(hb:hits_robot(hr.x + game.HURT_R - 0.5, hcy, 1, 0) and not hb:hits_robot(hr.x + game.HURT_R + 0.5, hcy, 1, 0),
	"blastron: il bersaglio è un cerchio di raggio HURT_R")
check(not hb:hits_robot(hr.x + game.ROBOT_HALF_W, hr.y, 1, 0), "blastron: l'angolo in basso della scatola non conta")

-- Mischia sulla mira: target = posizione del bersaglio rispetto ai piedi (in unità
-- di Blastron), i robot restano fermi in aria; restituisce il tick del colpo o false
local function melee_at(deg, tx, ty, weapon)
	local q = game.new(42, "isole")
	run(q, 120)
	q:pop_events()
	local pos = { { 0, 0 }, { tx * U, ty * U } }
	local function hold()
		for i, rb in ipairs(q.robots) do
			rb.x, rb.y, rb.vx, rb.vy, rb.grounded = 640 + pos[i][1], 400 + pos[i][2], 0, 0, false
		end
	end
	hold()
	if weapon == "punch" then q.robots[1].ammo.punch = 1 end
	q:step({ fire = { angle = math.rad(deg), power = 1, weapon = weapon or "sword" } })
	for t = 1, 200 do
		hold()
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "sword_hit" or e.type == "punch_hit" then return t, q end
		end
	end
	return false, q
end
local close = math.ceil(mischia.fendente.chiudi * 60 / mischia.fendente.fps)
check(melee_at(0, 5, 0) == close, "blastron: il fendente colpisce quando si chiude la finestra (0,8 s)")
check(melee_at(0, -4, 0) and melee_at(0, 0, 7), "blastron: mirando dritto prende anche dietro e sopra la testa")
check(melee_at(-60, 4, -4) and not melee_at(60, 4, -4), "blastron: mirando in basso la lama scende davanti in basso")
check(melee_at(60, 4, 5) and melee_at(-60, 0, -5) and not melee_at(60, 0, -5),
	"blastron: il colpo gira con la mira")
check(melee_at(-90, 4, -4) and not melee_at(-90, -4, 0), "blastron: mirando giù non prende chi è dietro")
local pt, pq2 = melee_at(0, 2, 0, "punch")
check(pt and pq2.robots[2].vy == game.PUNCH_LAUNCH and pq2.robots[2].vx == 0,
	"blastron: il montante lancia dritto in alto")
check(not melee_at(-60, 0, 4, "punch"), "blastron: il montante mirato in basso non prende chi è sopra")
check(game.melee_ticks(mischia.fendente) == game.SWORD_TICKS and game.melee_ticks(mischia.montante) == game.PUNCH_TICKS,
	"blastron: durate del fendente e del montante coerenti con le animazioni")


-- Danno da caduta oltre 40 u
local bf = game.new(42, "isole")
run(bf, 120)
local fr2 = bf.robots[1]
local hp0 = fr2.hp
-- la mappa è alta 57,6 u: per avere spazio la soglia scende a 20 u
local safe0 = game.FALL_SAFE
game.FALL_SAFE = 20 * U
local DROP = math.floor(28 * U)
local fx, gy2
for x = 60, game.WORLD_W - 60, 8 do
	-- la terra più alta sotto il robot, largo 2 * ROBOT_HALF_W
	local gy
	for _, o in ipairs({ -game.ROBOT_HALF_W, 0, game.ROBOT_HALF_W }) do
		local g = bf.terrain:ground_below(x + o, game.WORLD_H - 1)
		if g and (not gy or g > gy) then gy = g end
	end
	if gy and gy + DROP < game.WORLD_H - game.ROBOT_H and not bf:robot_collides(x, gy + DROP)
		and math.abs(x - bf.robots[2].x) > 4 * game.ROBOT_HALF_W then
		fx, gy2 = x, gy
		break
	end
end
check(fx ~= nil, "blastron: c'è un punto da cui cadere")
place(fr2, fx, gy2 + DROP)
for _ = 1, 400 do
	bf:step()
	if fr2.grounded then break end
end
local fall = gy2 + DROP - fr2.y
local expect = math.floor(math.min((fall - game.FALL_SAFE) * game.FALL_DAMAGE, game.FALL_DAMAGE_MAX) + 0.5)
game.FALL_SAFE = safe0
check(fr2.grounded and fall > 20 * U and expect > 0 and hp0 - fr2.hp == expect,
	string.format("blastron: cadendo da %.0f px perde %d (%d)", fall, expect, hp0 - fr2.hp))
local bf2 = game.new(42, "isole")
run(bf2, 120)
local sr = bf2.robots[1]
bf2:step({ jump = true })
run(bf2, 200)
check(sr.hp == sr.max_hp, "blastron: un salto non fa danno")

-- Potenza: zona morta 20% e curva quadratica
check(game.aim_power(0.2) == 0.1 and game.aim_power(1) == 1 and math.abs(game.aim_power(0.6) - 0.25) < 1e-9,
	"blastron: potenza quadratica con zona morta")

-- Casse a probabilità: ne cadono, e sempre negli stessi punti con lo stesso seed
local function crates_seen(seed)
	local q = game.new(seed, "isole")
	local seen = {}
	for i = 1, 12 * (game.TURN_TICKS + 200) do
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "crate" then seen[#seen + 1] = e.x end
		end
		if q.phase == "over" then break end
	end
	return table.concat(seen, " ")
end
local cs = crates_seen(9)
check(cs ~= "" and cs == crates_seen(9), "blastron: le casse cadono a caso ma uguali con lo stesso seed (" .. cs .. ")")

-- Una partita intera con tutte le armi è deterministica anche con questo profilo
check(play2(5) == play2(5), "blastron: partita deterministica")

-- Corpo a capsula, salto corto, coyote time e salto in anticipo -----------------

-- Un mondo vuoto con il terreno pieno sotto ground(x) (pixel dal basso)
local function shaped_world(ground)
	local q = game.new(42, "isole")
	local t, c = q.terrain, game.CELL
	for i = 1, #t.data do t.data[i] = 0 end
	for cx = 0, game.WORLD_W / c - 1 do
		local h = ground(cx * c + c / 2)
		for cy = 0, math.floor(h / c) - 1 do t:set(cx, cy, 1) end
	end
	place(q.robots[2], 60, ground(60))
	q.robots[2].grounded = true
	q:pop_events()
	return q
end

-- Su un pendio a 45 gradi il fondo rotondo resta più vicino al terreno del rettangolo
local function slope_gap(round)
	local saved = game.ROBOT_ROUND
	game.ROBOT_ROUND = round
	local slope = function(x) return 100 + math.max(0, math.min(200, x - 500)) end
	local q = shaped_world(slope)
	local r = q.robots[1]
	place(r, 600, 260)
	run(q, 120)
	game.ROBOT_ROUND = saved
	return r.y - slope(r.x), r.grounded
end
local gap_box, gb = slope_gap(false)
local gap_round, gr = slope_gap(true)
check(gb and gr and gap_round < gap_box - 2,
	string.format("capsula: sul pendio a 45 gradi resta più bassa del rettangolo (%.1f px contro %.1f)", gap_round, gap_box))
check(gap_round < game.ROBOT_HALF_W * 0.6, string.format("capsula: al centro sta sopra il pendio quanto il bordo del cerchio (%.1f px)", gap_round))

-- Salto corto: lasciando il tasto subito si sale molto meno
local function jump_top(hold_ticks)
	local q = shaped_world(function() return 100 end)
	local r = q.robots[1]
	place(r, 640, 100)
	run(q, 30)
	local base, top = r.y, r.y
	q:step({ jump = true, hold = true })
	for i = 1, 150 do
		q:step({ hold = i < hold_ticks })
		top = math.max(top, r.y)
	end
	return top - base
end
local full, short = jump_top(1000), jump_top(4)
check(math.abs(full - 5.2 * U) < 0.35 * U, string.format("salto corto: tenendo premuto il salto è pieno (%.1f px)", full))
check(short < full * 0.5, string.format("salto corto: lasciando subito sale meno della metà (%.1f px)", short))

-- Coyote time: appena scesi dal bordo si salta ancora, poco dopo no
local function ledge_jump(after)
	local q = shaped_world(function(x) return x < 640 and 200 or 40 end)
	local r = q.robots[1]
	place(r, 600, 200)
	run(q, 30)
	local n = 0
	while r.grounded and n < 200 do q:step({ right = true }); n = n + 1 end
	run(q, after - 1)
	q:step({ jump = true })
	return r.vy > 0
end
check(ledge_jump(3), "coyote: tre tick dopo il bordo il salto parte")
check(not ledge_jump(game.COYOTE_TICKS + 4), "coyote: più tardi in aria non si salta")

-- Salto in anticipo: chiesto poco prima di atterrare parte appena si tocca terra
local function buffered(early)
	local q = shaped_world(function() return 100 end)
	local r = q.robots[1]
	place(r, 640, 160)
	local n = 0
	while not r.grounded and n < 300 do q:step(); n = n + 1 end
	place(r, 640, 160)
	for i = 1, n do q:step({ jump = i == n - early }) end
	q:step()
	return r.vy > 0 and not r.grounded
end
check(buffered(3), "salto in anticipo: chiesto 3 tick prima, parte all'atterraggio")
check(not buffered(game.JUMP_BUFFER_TICKS + 4), "salto in anticipo: chiesto troppo presto non conta")

game.use_physics("megablast")

-- Prestazioni: un cratere e 600 tick di simulazione
local t = os.clock()
local g4 = game.new(5, "casuale")
for i = 1, 600 do g4:step({ right = i % 2 == 0 }) end
for i = 1, 20 do g4.terrain:carve(100 + i * 50, 200, 30) end
print(string.format("info 600 tick + 20 crateri in %.1f ms", (os.clock() - t) * 1000))

-- Levette del telefono (client/battaglia/levette.lua)
do
	local levette = require "battaglia.levette"
	local s = levette.new()
	levette.muovi(s, 0.1, 0)
	check(not s.moving, "levetta: al 10% di lato non cammina")
	levette.muovi(s, 0.5, 0)
	check(s.moving and s.dir == 1, "levetta: di lato cammina a destra")
	local jumped = levette.muovi(s, 0.5, 0.5)
	check(s.moving and s.jumping and jumped, "levetta: in diagonale cammina e salta")
	check(not levette.muovi(s, 0.5, 0.55), "levetta: il salto parte una volta sola")
	levette.muovi(s, 0.05, 0.6)
	check(not s.moving and s.jumping, "levetta: dritta in alto salta sul posto")
	levette.muovi(s, -0.6, -0.1)
	check(s.moving and s.dir == -1 and not s.jumping, "levetta: in basso a sinistra cammina e non salta")
	levette.muovi(s, -0.05, 0)
	check(not s.moving, "levetta: tornata al centro si ferma")
	levette.muovi(s, 0.2, -0.6)
	check(not s.moving, "levetta: verso il basso serve il 25% di lato")

	local a = levette.new()
	levette.mira(a, 0.15, 0)
	check(not a.active, "mira: sotto il 20% spenta")
	levette.mira(a, 0, -0.6)
	check(a.active and math.abs(a.angle + math.pi / 2) < 1e-6 and math.abs(a.f - 0.5) < 1e-6,
		"mira: accesa, verso il basso, potenza 0,5 al 60%")
	levette.mira(a, 0.15, 0)
	check(a.active, "mira: tra il 10% e il 20% resta accesa")
	levette.mira(a, 0.05, 0)
	check(not a.active, "mira: sotto il 10% si spegne")

	-- lo scivolamento del pollice nell'ultimo istante non conta
	local r = levette.new()
	for i = 0, 30 do levette.registra(r, i / 60, i < 28 and 1.0 or 2.0, 0.7, i < 30) end
	local h = levette.al_rilascio(r, 30 / 60)
	check(h and h.angle == 1.0 and h.active, "mira: al rilascio vale la mira di 50 ms prima")
	levette.reset(r)
	check(levette.al_rilascio(r, 1) == nil, "mira: dopo reset nessuna mira registrata")
end

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test superati")
