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
-- Le prove si fanno sulla forgia (alcune sul crogiolo).

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

-- Partite vere: senza mappa la sceglie il seed, fra quelle di maps.ROTATION
do
	local seen = {}
	for seed = 1, 4 do
		local id = game.new(seed).map
		check(id == game.new(seed).map, "stesso seed, stessa mappa")
		seen[id] = true
	end
	for _, id in ipairs(maps.ROTATION) do
		check(maps.maps[id] and seen[id], id .. ": esce nelle partite")
	end
end

local g = game.new(42, "forgia")
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
	local q = game.new(42, "forgia", { players = { { team = 1, stats = stats }, { team = 2 } } })
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
local hj = game.new(42, "forgia", { players = { { team = 1, stats = { jump_height = 120 } }, { team = 2 } } })
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
check(g.phase == "aim" and g.window > 0 and g.used.primary, "il missile parte e si apre il tempo del secondo attacco")
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
local tp = game.new(42, "forgia")
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
check(tr.teleports_left == config.STATS.teleports - 1, "il teletrasporto consuma un globo")
tr.teleports_left = 5
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(tp.orbs[1] == nil and tr.teleports_left == 5, "al primo turno si fa un solo teletrasporto")
tr.turns = 2
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(tp.orbs[1] ~= nil and tr.teleports_left == 4, "dal secondo turno, con globi in mano, se ne lancia un altro")
tr.teleports_left = 0
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(#tp.orbs == 1, "senza globi il teletrasporto non parte")

-- Più globi in volo insieme: ognuno teletrasporta allo scadere del suo tempo,
-- e in mezzo si può sparare. Il turno passa solo quando tutti hanno finito.
-- Un robot che può teletrasportarsi quanto vuole (per le prove)
local function free_tp(r)
	r.teleports_left, r.turns = 99, 2
end

local function multi(plan)
	local q = game.new(42, "forgia")
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
	local q = game.new(42, "forgia")
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
local rl = game.new(42, "forgia")
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
local im = game.new(42, "forgia")
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
local om = game.new(42, "forgia")
run(om, 120)
om.orbs = { { x = -200, y = -100, vx = 0, vy = 0, owner = 1, timer = 1 } }
om:step()
om:step()
check(om.robots[1].dead, "un globo fuori dalla mappa ti fa cadere nel vuoto")

-- Fendente: colpisce dietro la schiena e davanti
local function sword_game()
	local q = game.new(42, "forgia")
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
check(sw.used.secondary and sw.window > 0, "il fendente è un attacco: si apre il tempo del secondo")
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
local tw = game.new(42, "forgia")
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

-- Due attacchi per turno e teletrasporti --------------------------------------------------
do

	local MISSILE = { fire = { angle = math.rad(60), power = 0.6 } }
	local SWORD = { fire = { angle = 0, power = 1, weapon = "sword" } }
	local TELE = { fire = { angle = math.rad(90), power = 0.2, weapon = "teleport" } }

	-- Primo attacco dopo 9 s: restano 16 s, cioè un teletrasporto (uno ogni TELEPORT_SECONDS)
	local at = game.new(42, "forgia")
	local ar = at.robots[1]
	run(at, 9 * 60 - 1)
	at:pop_events()
	at:step(MISSILE)
	local gain = math.floor(at.timer / (60 * config.TELEPORT_SECONDS))
	local nev
	for _, e in ipairs(at:pop_events()) do if e.type == "teleports" then nev = e end end
	check(gain >= 1 and ar.teleports_left == config.STATS.teleports + gain and nev and nev.amount == gain,
		"i secondi rimasti al primo attacco diventano teletrasporti (" .. ar.teleports_left .. ")")
	check(at.window == game.AFTER_ATTACK_TICKS, "dopo il primo attacco restano 8 s")
	at:step(MISSILE)
	check(not at:can_use("missile") and at.used.primary, "una sola arma per turno")
	local n0 = ar.teleports_left
	run(at, game.AFTER_ATTACK_TICKS - 30)
	check(at:can_use("sword"), "il secondo attacco si fa fino all'ultimo secondo")
	at:step(SWORD)
	check(at.used.secondary and at.window > 0, "dopo il secondo attacco il tempo continua")
	check(ar.teleports_left == n0, "il secondo attacco non dà teletrasporti")
	check(not at:can_use("missile") and not at:can_use("sword"), "dopo i due attacchi niente più attacchi")
	local turn_at
	for i = 1, 2000 do
		at:step()
		if at.current == 2 then turn_at = i break end
	end
	check(turn_at and turn_at >= 28, "il turno passa allo scadere degli 8 s")

	-- Ordine libero: prima la spada, poi il missile
	local ao = game.new(42, "forgia")
	run(ao, 60)
	ao:step(SWORD)
	run(ao, 30)
	check(ao:can_use("missile"), "dopo la spada si può ancora sparare")
	ao:step(MISSILE)
	check(ao.used.primary and ao.used.secondary, "spada e missile nello stesso turno")

	-- Il teletrasporto non si spegne mai sparando: dopo la secondaria, dopo la
	-- primaria e dopo tutte e due si lancia ancora, come gli oggetti
	for _, order in ipairs({ { "sword" }, { "missile" }, { "sword", "missile" }, { "missile", "sword" } }) do
		local q = game.new(42, "forgia")
		run(q, 120)
		free_tp(q.robots[1])
		for _, w in ipairs(order) do
			q:step({ fire = { angle = math.rad(60), power = 0.6, weapon = w } })
		end
		local label = table.concat(order, "+")
		check(q.phase == "aim" and q:can_use("teleport"), "teletrasporto usabile dopo " .. label)
		q:step({ fire = { angle = math.rad(90), power = 0.15, weapon = "teleport" } })
		check(#q.orbs == 1, "il globo parte dopo " .. label)
	end

	-- Chi attacca allo scadere non ha tempo per altro
	local az = game.new(42, "forgia")
	run(az, game.TURN_TICKS - 2)
	az:step(MISSILE)
	check(az.used.primary and az.window <= 1, "attaccando allo scadere non resta tempo")
	run(az, 3)
	check(az.phase ~= "aim", "il turno chiude allo scadere anche dopo un attacco")

	-- Nessun tetto: i globi si accumulano
	local fz = game.new(42, "forgia", { players = { { team = 1, stats = { teleports = 5 } }, { team = 2 } } })
	run(fz, 60)
	fz:step(MISSILE)
	check(fz.robots[1].teleports_left == 5 + math.floor(fz.timer / (60 * config.TELEPORT_SECONDS))
		and fz.robots[1].teleports_left > 5, "i teletrasporti si accumulano senza tetto")

	-- La vita parte dal valore del config e si può cambiare per robot
	local hv = game.new(42, "forgia", { players = { { team = 1, stats = { max_hp = 200 } }, { team = 2 } } })
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
		local mid = game.WORLD_W / 2
		check((q.robots[1].x < mid) == (q.robots[2].x < mid) and (q.robots[3].x < mid) == (q.robots[4].x < mid)
			and (q.robots[1].x < mid) ~= (q.robots[3].x < mid), id .. ": i compagni partono dallo stesso lato")
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

	local q4 = game.new(42, "forgia", { players = four })
	check(q4.mode == "2v2" and table.concat(q4.order, " ") == "1 3 2 4",
		"2 contro 2: turni A1, B1, A2, B2 (" .. table.concat(q4.order, " ") .. ")")
	local seen4 = { q4.current }
	for _ = 1, 4 do seen4[#seen4 + 1] = next_turn(q4) end
	check(table.concat(seen4, " ") == "1 3 2 4 1", "i turni seguono l'ordine delle squadre (" .. table.concat(seen4, " ") .. ")")
	-- chi muore ricomincia dopo RESPAWN_TICKS, anche a metà del turno, e non perde il suo turno
	q4:kill(q4.robots[3])
	run(q4, game.RESPAWN_TICKS)
	check(not q4.robots[3].dead and q4.robots[3].hp == q4.robots[3].max_hp and q4.current == 1,
		"il robot morto ricomincia nello stesso turno con la vita piena")
	check(next_turn(q4) == 3, "e gioca il suo turno")
	-- chi muore nel suo turno ricomincia e il turno continua
	local own = game.new(42, "forgia")
	run(own, 30)
	own:kill(own.robots[1], "fell")
	run(own, game.RESPAWN_TICKS + 5)
	check(own.current == 1 and own.phase == "aim" and not own.robots[1].dead and own:can_use("missile"),
		"morto nel proprio turno: si ricomincia e il turno continua")

	-- Tutti contro tutti: quattro squadre da uno, turni nell'ordine di arrivo
	local ffa = game.new(42, "forgia", { players = { { team = 1 }, { team = 2 }, { team = 3 }, { team = 4 } } })
	check(ffa.mode == "ffa" and table.concat(ffa.order, " ") == "1 2 3 4", "tutti contro tutti: turni 1, 2, 3, 4")
	check(game.new(42, "forgia").mode == "1v1", "senza players è un 1 contro 1")
end

-- Oggetti tattici: trappole, scudi, trampolini, paracadute, cerchi di cura -------------
do
	-- le casse contengono anche gli oggetti
	local mix = game.new(5, "forgia")
	local seen = {}
	for _ = 1, 60 do
		mix.crates = {}
		local c = mix:spawn_crate()
		if c then seen[c.weapon] = true end
	end
	check(seen.trap and seen.shield and seen.trampoline, "nelle casse ci sono trappole, scudi e trampolini")

	-- gli oggetti si usano anche nel riposizionamento e non sono attacchi
	local q = game.new(42, "forgia", { ammo = { trap = 1, shield = 1 } })
	run(q, 60)
	local r1, r2 = q.robots[1], q.robots[2]
	q:step({ fire = { angle = 0, power = 1, weapon = "shield" } })
	check(r1.shield == config.SHIELD.hp and not q.used.primary and not q.used.secondary,
		"lo scudo si attiva e non è un attacco")
	q:step({ fire = { angle = math.rad(60), power = 0.6 } })
	q:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
	check(q.window > 0 and q:can_use("trap"), "dopo i due attacchi la trappola si può ancora posare")
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
	local t2 = game.new(42, "forgia", { players = config.MODES["2v2"], ammo = { trap = 1 } })
	run(t2, 60)
	t2:step({ fire = { angle = 0, power = 1, weapon = "trap" } })
	local tt = t2.placed[1]
	tt.armed = true
	local mate = t2.robots[3]
	mate.x, mate.y, mate.vy, mate.grounded = tt.x, tt.y, 0, true
	t2.robots[1].x = tt.x + 60
	t2:step()
	check(#t2.placed == 1 and mate.vy <= 0, "il compagno non fa scattare la trappola")

	-- trampolino: si lancia; tirato addosso a un robot cade ai suoi piedi e lo fa
	-- rimbalzare, sempre; restandoci sopra i rimbalzi calano fino a fermarsi
	local tb = game.new(42, "forgia", { ammo = { trampoline = 1 } })
	run(tb, 60)
	local a, b = tb.robots[1], tb.robots[2]
	b.x, b.y = a.x + 40, a.y
	run(tb, 5)
	tb:step({ fire = { angle = math.rad(10), power = 0.4, weapon = "trampoline" } })
	local tramp = tb.placed[1]
	check(tramp and tramp.flying and a.ammo.trampoline == 0, "il trampolino si lancia")
	local bounces, first_vy = 0, nil
	for _ = 1, 600 do
		tb:step()
		for _, e in ipairs(tb:pop_events()) do
			if e.type == "bounce" and e.robot == 2 then
				bounces = bounces + 1
				first_vy = first_vy or b.vy
			end
		end
	end
	check(not tramp.flying and math.abs(tramp.x - b.x) <= tramp.r + game.ROBOT_HALF_W,
		"tirato su un robot cade ai suoi piedi")
	check(bounces >= 2 and first_vy == config.TRAMPOLINE.launch_vy, "e lo fa rimbalzare (" .. bounces .. ")")
	check(b.grounded and b.vy == 0, "restando sopra i rimbalzi calano e ci si ferma")
	-- sceso e risalito, si rimbalza di nuovo alto
	b.x = tramp.x + 60
	run(tb, 30)
	b.x, b.y = tramp.x, tramp.y
	b.vy = 0
	local again
	for _ = 1, 5 do
		tb:step()
		for _, e in ipairs(tb:pop_events()) do if e.type == "bounce" then again = b.vy end end
	end
	check(again == config.TRAMPOLINE.launch_vy, "risalendoci si rimbalza di nuovo alto")

	-- sul trampolino rimbalza tutto: missile, Uovo, schegge, Cecchino, globo, cassa.
	-- Ogni corpo cade dritto sulla tavola e deve risalire alla velocità del rimbalzo.
	local top = tramp.y + config.TRAMPOLINE.top
	b.x = tramp.x + 80
	run(tb, 30)
	local function falls_on(body, advance)
		body.x, body.y, body.vx, body.vy = tramp.x + tramp.r - 1, top + 3, 0, -200
		for _ = 1, 3 do
			advance()
			if body.vy > 0 then return body.vy end
		end
	end
	local bodies = {
		missile = { kind = "missile", owner = 1, age = 100 },
		grenade = { kind = "grenade", owner = 1, age = 100, fuse = 600 },
		sniper = { kind = "sniper", owner = 1, age = 100, bounces = 0 },
	}
	for kind, body in pairs(bodies) do
		tb.projectile = body
		local vy = falls_on(body, function() tb:update_projectile() end)
		check(tb.projectile == body and vy == config.TRAMPOLINE.launch_vy, "sul trampolino rimbalza: " .. kind)
	end
	tb.projectile = nil
	local shard = { owner = 1, age = 100 }
	tb.shards[1] = shard
	check(falls_on(shard, function() tb:update_shards() end) == config.TRAMPOLINE.launch_vy and tb.shards[1] == shard,
		"sul trampolino rimbalza: scheggia")
	tb.shards[1] = nil
	local orb = { id = 99, owner = 1, age = 100, timer = 600 }
	check(falls_on(orb, function() tb:update_orb(orb) end) == config.TRAMPOLINE.launch_vy,
		"sul trampolino rimbalza: globo")
	local crate = { id = 99, weapon = "grenade", landed = false }
	check(falls_on(crate, function() tb:fall(crate, game.CRATE_HALF_W, game.CRATE_FALL) end)
		== config.TRAMPOLINE.launch_vy, "sul trampolino rimbalza: cassa")
	-- l'Uovo lasciato sopra rimbalza sempre meno e poi si posa
	local egg = { kind = "grenade", owner = 1, age = 100, fuse = 100000, x = tramp.x, y = top + 20, vx = 0, vy = 0 }
	tb.projectile = egg
	tb:pop_events()
	local egg_bounces = 0
	for _ = 1, 900 do
		tb:update_projectile()
		for _, e in ipairs(tb:pop_events()) do
			if e.type == "bounce" and not e.robot then egg_bounces = egg_bounces + 1 end
		end
	end
	check(egg_bounces == 3 and egg.vy == 0 and egg.y < top, "l'Uovo rimbalza sempre più basso e si posa (" .. egg_bounces .. ")")
	tb.projectile = nil

	-- un'esplosione porta via quello che è posato
	tb:explode(tramp.x, tramp.y + 4)
	check(#tb.placed == 0, "un'esplosione distrugge il trampolino")

	-- paracadute: in aria un tocco lo apre (uno a partita), rallenta la caduta,
	-- dà più controllo in orizzontale e annulla il danno da caduta
	local pc = game.new(42, "forgia")
	run(pc, 60)
	local p = pc.robots[1]
	check(not pc:can_use("parachute"), "a terra il paracadute non si apre")
	local safe, dmg, max = game.FALL_SAFE, game.FALL_DAMAGE, game.FALL_DAMAGE_MAX
	game.FALL_SAFE, game.FALL_DAMAGE, game.FALL_DAMAGE_MAX = 10, 1, 100
	local y = sky_spot(pc, 640, 200)
	place(p, 640, y)
	pc:step()
	pc:step({ fire = { angle = 0, power = 1, weapon = "parachute" } })
	check(p.parachute and p.parachutes_left == config.STATS.parachutes - 1, "il paracadute in aria si apre e ne consuma uno")
	check(pc:can_use("parachute"), "aperto si può richiudere")
	local slowest, fastest = 0, 0
	-- a destra solo per un secondo: col paracadute veloce si uscirebbe dalla mappa
	for i = 1, 1200 do
		pc:step({ right = i <= 60 })
		slowest = math.min(slowest, p.vy)
		fastest = math.max(fastest, p.vx)
		if p.grounded then break end
	end
	check(slowest >= -config.PARACHUTE.fall_speed - 1 and p.hp == p.max_hp and not p.parachute,
		"col paracadute si scende piano e si atterra senza danno")
	check(fastest > p.stats.air_speed, "col paracadute in orizzontale si va un po' più veloci")
	-- richiuderlo non lo restituisce
	p.parachutes_left = 3
	place(p, 640, y)
	pc:step()
	pc:step({ fire = { angle = 0, power = 1, weapon = "parachute" } })
	pc:step({ fire = { angle = 0, power = 1, weapon = "parachute" } })
	check(not p.parachute and p.parachutes_left == 2, "un altro tocco lo chiude")
	p.parachutes_left = 0
	check(not pc:can_use("parachute"), "finiti i paracadute della partita non si apre più")
	game.FALL_SAFE, game.FALL_DAMAGE, game.FALL_DAMAGE_MAX = safe, dmg, max

	-- cerchio di cura: a fine turno chi ha i piedi dentro si cura e il cerchio
	-- sparisce (a inizio turno ne può comparire un altro)
	local hg = game.new(42, "forgia")
	run(hg, 60)
	local function has_heal(id)
		for _, x in ipairs(hg.heals) do if x.id == id then return true end end
		return false
	end
	local h = hg:spawn_heal()
	local ha, hb = hg.robots[1], hg.robots[2]
	ha.x, ha.y, ha.hp = h.x, h.y, 50
	hg:end_turn()
	check(ha.hp == 50 + config.HEAL.hp and not has_heal(h.id), "a fine turno nel cerchio ci si cura e il cerchio sparisce")
	hg.heals = {}
	local h2 = hg:spawn_heal()
	hb.x, hb.y, hb.hp = h2.x, h2.y, hb.max_hp
	hg:end_turn()
	check(has_heal(h2.id), "con la vita piena il cerchio resta")
	hb.hp = 10
	hb.x = h2.x + config.HEAL.r + 10
	hg:end_turn()
	check(hb.hp == 10 and has_heal(h2.id), "fuori dal cerchio niente cura")
end

-- L'Uovo rimbalza sui robot, come il globo del teletrasporto
do
	local q = game.new(42, "forgia", { ammo = { grenade = 1 } })
	run(q, 60)
	local a, b = q.robots[1], q.robots[2]
	b.x, b.y = a.x + 60, a.y
	run(q, 5)
	q:step({ fire = { angle = math.rad(5), power = 0.6, weapon = "grenade" } })
	local max_x = 0
	for _ = 1, 60 do
		q:step()
		if q.projectile then max_x = math.max(max_x, q.projectile.x) end
	end
	check(q.projectile and max_x < b.x and q.projectile.touched, "l'Uovo rimbalza sul robot invece di attraversarlo")
end

-- Cecchino: lento, dritto e poi cala, rimbalza, sbalza nella direzione del colpo ---
do
	local q = game.new(42, "forgia", { ammo = { sniper = 1 } })
	run(q, 60)
	local a, b = q.robots[1], q.robots[2]
	-- in cielo, così il terreno non si mette in mezzo
	local sy = sky_spot(q, 640, 80)
	place(a, 600, sy)
	place(b, 650, sy)
	local hp = b.hp
	q:step({ fire = { angle = 0, power = 1, weapon = "sniper" } })
	check(q.projectile and q.projectile.kind == "sniper" and a.ammo.sniper == 0, "il cecchino spara")
	local hit
	for _ = 1, 60 do
		q:step()
		for _, e in ipairs(q:pop_events()) do if e.type == "sniper_hit" then hit = e end end
		if hit then break end
	end
	check(hit and hit.target == 2 and hp - b.hp == config.SNIPER.damage, "colpisce e fa danno")
	check(b.vx > 0 and not b.grounded and b.knocked, "sbalza nella direzione del colpo")
	local sp = math.sqrt(b.vx * b.vx + b.vy * b.vy)
	check(sp <= config.SNIPER.push + config.SNIPER.lift + 1, "con una spinta moderata")

	-- parte veloce e quasi dritto, poi frena e cala sempre di più
	local d = game.new(42, "forgia", { ammo = { sniper = 1 } })
	run(d, 60)
	local da = d.robots[1]
	d.robots[2].x = -1000
	local dy = sky_spot(d, 500, 300)
	place(da, 200, dy)
	d.terrain:rect(0, dy - 200, 1280, 260, 0)  -- cielo libero davanti
	d:step({ fire = { angle = 0, power = 1, weapon = "sniper" } })
	local p = d.projectile
	run(d, 10)
	check(d.projectile == p and p.vy > -40 and p.vx > game.SNIPER_SPEED * 0.9, "all'inizio va quasi dritto e veloce")
	local vy10 = p.vy
	run(d, 30)
	check(d.projectile == p and p.vy < vy10 - 100 and p.vx < game.SNIPER_SPEED * 0.85, "poi cala sempre di più e frena")

	-- verso il terreno rimbalza (non scava), e dopo l'ultimo rimbalzo si ferma
	local r = game.new(42, "forgia", { ammo = { sniper = 1 } })
	run(r, 60)
	local cells = solid_count(r.terrain)
	r:step({ fire = { angle = math.rad(-60), power = 1, weapon = "sniper" } })
	local bounces, speeds = 0, {}
	for _ = 1, game.SNIPER_LIFE + 5 do
		r:step()
		for _, e in ipairs(r:pop_events()) do
			if e.type == "sniper_bounce" then
				bounces = bounces + 1
				local pr = r.projectile
				speeds[bounces] = math.sqrt(pr.vx * pr.vx + pr.vy * pr.vy)
			end
		end
		if not r.projectile then break end
	end
	check(bounces >= 1 and bounces <= config.SNIPER.bounces, "rimbalza sul terreno, al massimo " .. config.SNIPER.bounces .. " volte (" .. bounces .. ")")
	local slower = true
	for i = 2, bounces do if speeds[i] >= speeds[i - 1] then slower = false end end
	check(slower, "come una palla: a ogni rimbalzo è più lento")
	check(solid_count(r.terrain) == cells, "il cecchino non scava")

	-- la linea di mira piega al primo rimbalzo
	local pts = r:preview(math.rad(-60), 1, 30, 4, nil, "sniper")
	check(#pts == 30 and pts[30].y > pts[1].y - 200, "la mira del cecchino segue il rimbalzo")
end

-- Secondarie da lontano e Affondo: Tonante, Rampino, Affondo --------------------
do
	-- Tonante: colpo dritto e istantaneo, danno secco senza effetti, rinculo su chi spara
	local q = game.new(42, "forgia", { secondary = "eagle" })
	run(q, 60)
	local a, b = q.robots[1], q.robots[2]
	local sy = sky_spot(q, 640, 80)
	place(a, 600, sy)
	place(b, 700, sy)
	local hp = b.hp
	q:step({ fire = { angle = 0, power = 1, weapon = "eagle" } })
	local ev
	for _, e in ipairs(q:pop_events()) do if e.type == "eagle" then ev = e end end
	check(ev and ev.target == 2 and hp - b.hp == config.EAGLE.damage, "il Tonante colpisce subito e fa danno secco")
	check(next(b.status) == nil and b.vx == 0, "senza effetti di stato e senza spingere il bersaglio")
	check(a.recoil and a.recoil_vx < 0 and a.recoil_vy == 0 and not a.grounded, "il rinculo spinge chi spara dalla parte opposta")
	check(not q.projectile, "senza proiettile in volo")

	-- il rinculo è lo stesso in tutte le direzioni: in cielo sposta della
	-- stessa distanza a destra, a sinistra, in alto e in diagonale
	local push = config.EAGLE.recoil * config.EAGLE.recoil_ticks / 60
	for _, deg in ipairs({ 0, 180, 90, -90, 45, -45, -135 }) do
		local d = game.new(42, "forgia", { secondary = "eagle" })
		run(d, 60)
		local da = d.robots[1]
		d.robots[2].x = -1000
		-- un buco di 150 px di raggio nel terreno, per avere spazio da tutte le parti
		d.terrain:carve(640, 400, 150)
		place(da, 640, 400 - game.ROBOT_H / 2)
		local x0, y0 = da.x, da.y
		d:step({ fire = { angle = math.rad(deg), power = 1, weapon = "eagle" } })
		run(d, config.EAGLE.recoil_ticks)
		local dist = math.sqrt((da.x - x0) ^ 2 + (da.y - y0) ^ 2)
		check(math.abs(dist - push) <= 2 and not da.recoil and da.vx == 0 and da.vy == 0,
			"rinculo di " .. math.floor(push) .. " px sparando a " .. deg .. " gradi (" .. math.floor(dist) .. ")")
	end

	-- da terra, sparando in orizzontale, si scivola sul terreno della stessa distanza
	local g2 = game.new(42, "forgia", { secondary = "eagle" })
	run(g2, 60)
	local ga = g2.robots[1]
	g2.robots[2].x = -1000
	local gx = ga.x
	g2:step({ fire = { angle = math.pi, power = 1, weapon = "eagle" } })
	run(g2, config.EAGLE.recoil_ticks)
	check(ga.x - gx > push * 0.8, "da terra il rinculo in orizzontale sposta quanto in aria (" .. math.floor(ga.x - gx) .. ")")

	-- il terreno ferma il colpo, entro la portata
	local t = game.new(42, "forgia", { secondary = "eagle" })
	run(t, 60)
	t.robots[2].x = -1000
	t:step({ fire = { angle = math.rad(-90), power = 1, weapon = "eagle" } })
	for _, e in ipairs(t:pop_events()) do if e.type == "eagle" then ev = e end end
	check(ev and ev.target == nil and ev.y0 - ev.y1 < 40, "il terreno ferma il colpo")
	local pts = t:preview(0, 1, 12, 4, nil, "eagle")
	check(#pts == 12 and math.abs(pts[12].x - pts[1].x) <= config.EAGLE.range, "la linea di mira è dritta e non supera la portata")

	-- Rampino: oggetto, uno a turno, non un attacco; riavvolge il bersaglio dritto
	-- verso la mano, fin addosso a chi tira, poi lo molla
	local h = game.new(42, "forgia")
	run(h, 60)
	local ha, hb = h.robots[1], h.robots[2]
	sy = sky_spot(h, 640, 120)
	-- cielo libero tutto attorno: la fune va fino a chi tira
	h.terrain:rect(500, sy - 60, 300, 140, 0)
	place(ha, 560, sy)
	place(hb, 740, sy)
	hp = hb.hp
	check(h:can_use("hook"), "il Rampino si usa senza colpi")
	h:step({ fire = { angle = 0, power = 1, weapon = "hook" } })
	for _, e in ipairs(h:pop_events()) do if e.type == "hook" then ev = e end end
	check(ev and ev.target == 2 and hb.hp == hp, "il Rampino aggancia senza fare danno")
	check(h.used.hook and not h:can_use("hook") and not h.used.primary and not h.used.secondary and h.window == 0,
		"uno a turno e non conta come attacco")
	check(hb.hooked and hb.hooked.by == 1 and ha.vx == 0, "il bersaglio resta appeso alla fune, chi tira no")
	local y_start = hb.y
	-- chi tira resta fermo lì (in cielo cadrebbe e la fune lo inseguirebbe)
	for _ = 1, 10 do
		ha.y, ha.vy = sy, 0
		h:step()
	end
	check(hb.x < 740 - 40 and math.abs(hb.y - y_start) < 2 and hb.hooked, "viene tirato dritto, senza cadere")
	local ended
	for _ = 1, 60 do
		ha.y, ha.vy = sy, 0
		h:step()
		for _, e in ipairs(h:pop_events()) do if e.type == "hook_end" then ended = true end end
		if not hb.hooked then break end
	end
	check(ended and not hb.hooked and math.abs(hb.x - ha.x) < 2 * game.ROBOT_HALF_W + 2, "arriva fin addosso a chi tira e viene mollato")
	run(h, 5)
	check(hb.y < y_start and hb.vx == 0, "e cade dritto dov'è")
	-- tirato da sotto sale fino a chi tira; un robot vicino ferma la fune
	local u = game.new(42, "forgia")
	run(u, 60)
	local ua, ub = u.robots[1], u.robots[2]
	sy = sky_spot(u, 640, 120)
	place(ua, 640, sy)
	place(ub, 640 + 30, sy - 60)
	u:step({ fire = { angle = math.atan2(-60 + game.ROBOT_H / 2, 30), power = 1, weapon = "hook" } })
	check(ub.hooked, "aggancia anche in diagonale")
	for _ = 1, 40 do
		u:step()
		if not ub.hooked then break end
	end
	check(not ub.hooked and ub.y > sy - 60 + 20 and math.abs(ub.x - ua.x) < 2 * game.ROBOT_HALF_W + 2,
		"da sotto lo tira su fino a chi spara e lo ferma addosso")
	-- sul terreno è chi tira che sale lungo la fune e si mette sopra la
	-- piattaforma colpita: da sotto una piattaforma si finisce in piedi sopra
	local m = game.new(42, "forgia")
	run(m, 60)
	local ma, mb = m.robots[1], m.robots[2]
	mb.x = -1000
	-- una colonna di cielo libero con dentro una piattaforma a sé, vuoto sotto e sopra
	m.terrain:rect(560, 100, 160, 500, 0)
	m.terrain:rect(600, 300, 80, 16, 1)
	place(ma, 640, 240)
	local y0 = ma.y
	m:step({ fire = { angle = math.rad(90), power = 1, weapon = "hook" } })
	for _, e in ipairs(m:pop_events()) do if e.type == "hook" then ev = e end end
	check(ev and ev.anchor and not ev.target and ma.hooked and ma.hooked.x == 640, "sul terreno la fune si aggancia e chi tira resta appeso")
	for _ = 1, 40 do
		m:step()
		if not ma.hooked then break end
	end
	run(m, 5)
	check(not ma.hooked and math.abs(ma.y - 316) < 4 and math.abs(ma.x - 640) < 10 and ma.grounded,
		"sale lungo la fune e si mette in piedi sopra la piattaforma")
	-- sparando nel vuoto non succede niente
	place(ma, 640, 340)
	m:step({ fire = { angle = math.rad(90), power = 1, weapon = "hook" } })
	check(not ma.hooked and ma.vx == 0, "nel vuoto il Rampino non aggancia niente")

	-- Maglio: arco attorno alla spalla come la Lama, da sopra la testa (dietro)
	-- fino sotto i piedi; colpisce tutto lungo l'arco, la testa si ferma sul
	-- terreno; in aria, se sbatte mentre cala, chi colpisce rimbalza in alto.
	-- sky(g): svuota una colonna di cielo e rende un punto in mezzo
	local function sky(g)
		g.terrain:rect(540, 200, 200, 300, 0)
		return 640, 350
	end
	-- mallet(g, angolo): tutto il colpo; rende gli urti e la vy di chi colpisce
	-- subito dopo ogni urto
	local function mallet(g, angle)
		local rb = g.robots[g.current]
		g:step({ fire = { angle = angle, power = 1, weapon = "mallet" } })
		local hits = {}
		for _ = 1, config.MALLET.ticks + config.MALLET.hold + 2 do
			for _, e in ipairs(g:pop_events()) do
				if e.type == "mallet_hit" then e.vy = rb.vy; hits[#hits + 1] = e end
			end
			if not rb.mallet then break end
			g:step()
		end
		return hits, rb
	end
	-- in aria: il robot sotto i piedi è colpito mentre il martello cala, e si rimbalza
	local g1 = game.new(42, "forgia", { secondary = "mallet" })
	run(g1, 60)
	local ga, gb = g1.robots[1], g1.robots[2]
	local sx
	sx, sy = sky(g1)
	place(ga, sx, sy)
	place(gb, sx, sy - game.ROBOT_H - 6)
	hp = gb.hp
	local hits = mallet(g1, math.rad(-90))
	check(#hits == 1 and hits[1].target == 2 and hits[1].bounce and hp - gb.hp == config.MALLET.damage
		and next(gb.status) == nil, "in aria colpisce il robot sotto, danno secco, e rimbalza")
	check(hits[1].vy >= config.MALLET.bounce - 20 and gb.vx == 0, "chi colpisce va in alto, il colpito non viene spinto")
	check(ga.mallet == nil, "il colpo finisce")
	-- come la Lama prende tutto quello che c'è sull'arco: anche chi sta dietro in
	-- alto, dove il martello parte; lì però non si rimbalza (non sta calando)
	local g5 = game.new(42, "forgia", { secondary = "mallet" })
	run(g5, 60)
	local g5a, g5b = g5.robots[1], g5.robots[2]
	sx, sy = sky(g5)
	place(g5a, sx, sy)
	place(g5b, sx - 20, sy + 35)
	hp = g5b.hp
	hits = mallet(g5, 0)
	check(#hits == 1 and hits[1].target == 2 and not hits[1].bounce and hp - g5b.hp == config.MALLET.damage and g5a.vy < 0,
		"colpisce anche dietro in alto, all'inizio dell'arco, senza rimbalzo")
	-- sul terreno sotto i piedi la testa si ferma e si rimbalza (pogo)
	local g2 = game.new(42, "forgia", { secondary = "mallet" })
	run(g2, 60)
	local g2a = g2.robots[1]
	g2.robots[2].x = -1000
	place(g2a, g2a.x, g2a.y + 20)
	g2:step({ fire = { angle = math.rad(-90), power = 1, weapon = "mallet" } })
	local stop
	for _ = 1, config.MALLET.ticks do
		g2:step()
		if g2a.mallet_stop and not stop then stop = g2a.mallet_stop; check(g2a.vy >= config.MALLET.bounce - 20, "sul terreno sotto i piedi rimbalza in alto (pogo)") end
	end
	check(stop and stop < config.MALLET.ticks and game.mallet_angle(config.MALLET.ticks, stop) == game.mallet_angle(stop),
		"la testa si ferma dove sbatte e resta lì")
	-- a vuoto in aria non rimbalza
	local g3 = game.new(42, "forgia", { secondary = "mallet" })
	run(g3, 60)
	local g3a = g3.robots[1]
	g3.robots[2].x = -1000
	place(g3a, sky(g3))
	hits = mallet(g3, math.rad(-90))
	check(#hits == 0 and g3a.vy < 0, "a vuoto in aria non rimbalza")
	-- a terra colpisce davanti, la testa sbatte sul terreno e non si rimbalza
	local g4 = game.new(42, "forgia", { secondary = "mallet" })
	run(g4, 60)
	local g4a, g4b = g4.robots[1], g4.robots[2]
	place(g4b, g4a.x + 2 * game.ROBOT_HALF_W + 16, g4a.y)
	g4b.grounded = true
	hp = g4b.hp
	hits = mallet(g4, 0)
	check(hp - g4b.hp == config.MALLET.damage and g4a.grounded and #hits == 2 and not hits[1].bounce and not hits[2].bounce,
		"a terra colpisce davanti, sbatte sul terreno e resta a terra")
	check(not g4:can_use("sword") and g4:can_use("missile"), "Maglio e Lama sono tutte e due secondarie")

	-- Affondo: scatto che attraversa il robot davanti e lo colpisce una volta
	local l = game.new(42, "forgia", { secondary = "lunge" })
	run(l, 60)
	local la, lb = l.robots[1], l.robots[2]
	sy = sky_spot(l, 640, 120)
	place(la, 600, sy)
	place(lb, 640, sy)
	hp = lb.hp
	local x1 = la.x
	l:step({ fire = { angle = 0, power = 1, weapon = "lunge" } })
	check(la.lunge == config.LUNGE.ticks and la.lunge_vx > 0, "l'Affondo parte")
	run(l, config.LUNGE.ticks)
	check(la.lunge == nil and la.x > lb.x + 10, "e passa oltre il robot davanti")
	check(hp - lb.hp == config.LUNGE.damage and next(lb.status) == nil, "colpendolo una volta, senza effetti")
	check(la.vx > 0 and la.vx < config.LUNGE.speed, "alla fine resta un po' di slancio")
	-- il terreno lo ferma
	local w = game.new(42, "forgia", { secondary = "lunge" })
	run(w, 60)
	local wa = w.robots[1]
	local y1 = wa.y
	w:step({ fire = { angle = math.rad(-90), power = 1, weapon = "lunge" } })
	run(w, 2)
	check(wa.lunge == nil and wa.y >= y1 - 2, "il terreno ferma l'Affondo")
	-- gradini e gobbe piccoli non lo fermano: li sale e va avanti
	local v = game.new(42, "forgia", { secondary = "lunge" })
	run(v, 60)
	local va, vb = v.robots[1], v.robots[2]
	v.terrain:rect(300, 200, 680, 300, 0)
	v.terrain:rect(300, 200, 680, 20, 1)
	v.terrain:rect(500, 220, 10, 12, 1)
	place(va, 440, 220)
	vb.x = -1000
	v:step({ fire = { angle = 0, power = 1, weapon = "lunge" } })
	run(v, config.LUNGE.ticks)
	check(va.x > 440 + 0.9 * config.LUNGE.speed * config.LUNGE.ticks / 60, "sale la gobba e fa tutto lo scatto")
	-- un muro alto lo ferma
	local wl = game.new(42, "forgia", { secondary = "lunge" })
	run(wl, 60)
	local wla = wl.robots[1]
	wl.robots[2].x = -1000
	wl.terrain:rect(300, 200, 680, 300, 0)
	wl.terrain:rect(300, 200, 680, 20, 1)
	wl.terrain:rect(500, 220, 10, 100, 1)
	place(wla, 440, 220)
	wl:step({ fire = { angle = 0, power = 1, weapon = "lunge" } })
	run(wl, config.LUNGE.ticks)
	check(wla.x < 500 and wla.x > 480, "contro un muro alto si ferma")
	-- la lancia colpisce anche chi resta oltre la fine dello scatto
	local q = game.new(42, "forgia", { secondary = "lunge" })
	run(q, 60)
	local qa, qb = q.robots[1], q.robots[2]
	q.terrain:rect(300, 200, 680, 300, 0)
	q.terrain:rect(300, 200, 680, 20, 1)
	place(qa, 400, 220)
	local fin = 400 + config.LUNGE.speed * config.LUNGE.ticks / 60
	place(qb, fin + 2 * game.ROBOT_HALF_W + 12, 220)
	hp = qb.hp
	q:step({ fire = { angle = 0, power = 1, weapon = "lunge" } })
	run(q, config.LUNGE.ticks)
	check(hp - qb.hp == config.LUNGE.damage, "la lancia prende chi sta poco oltre la fine dello scatto")
	-- Affondo e Lama sono tutte e due secondarie: una per turno
	check(not w:can_use("sword") and w:can_use("missile"), "dopo l'Affondo niente Lama nello stesso turno")
end

-- Effetti di stato: bruciatura, rallentamento, armatura incrinata ------------------
do
	local function to_turn(q, who)
		for _ = 1, 4000 do
			q:step()
			if q.current == who and q.phase == "aim" then return end
		end
	end

	-- le schegge rallentano: corsa e salto ridotti fino alla fine del proprio turno dopo
	local q = game.new(42, "forgia")
	run(q, 30)
	local r1, r2 = q.robots[1], q.robots[2]
	q:explode(r2.x, r2.y + 4, 1, game.SHARD_BLAST, "shards")
	check(r2.status.slow and r2.status.slow.turns == 1, "le schegge rallentano")
	local x0 = r2.x
	q.current = 2
	run(q, 20, { right = true })
	local slow_dx = math.abs(r2.x - x0)
	r2.status.slow = nil
	x0 = r2.x
	run(q, 20, { right = true })
	check(slow_dx < math.abs(r2.x - x0) * 0.8, "rallentato si corre più piano")
	q.current = 1

	-- armatura incrinata dal pugno: si prende più danno
	local c = game.new(42, "forgia")
	local a, b = c.robots[1], c.robots[2]
	c:punch_hit(a, b, 1)
	check(b.status.cracked, "il pugno incrina l'armatura")
	local hp = b.hp
	c:hurt(b, 20, a)
	check(hp - b.hp == math.floor(20 * config.STATUS.cracked.damage + 0.5), "con l'armatura incrinata il danno sale")

	-- lo scudo ferma l'effetto
	local s = game.new(42, "forgia")
	local sb = s.robots[2]
	sb.shield = config.SHIELD.hp
	s:punch_hit(s.robots[1], sb, 1)
	check(not sb.status.cracked, "lo scudo ferma l'effetto di stato")

	-- Uovo normale: niente bruciatura; col set Fornace (burning_blasts) l'Uovo
	-- brucia, il missile no
	local f = game.new(42, "forgia", { players = { { team = 1, stats = { burning_blasts = 1 } }, { team = 2 } } })
	run(f, 30)
	local fa, fb = f.robots[1], f.robots[2]
	f:explode(fb.x, fb.y + 4, 2, nil, "grenade")
	check(not fa.status.burn, "l'Uovo senza Fornace non brucia")
	f:explode(fb.x + 20, fb.y + 4, 1, nil, "missile")
	check(not fb.status.burn, "col set Fornace il missile non brucia")
	f:explode(fb.x + 20, fb.y + 4, 1, nil, "grenade")
	check(fb.status.burn and fb.status.burn.by == 1, "col set Fornace l'Uovo brucia")
	-- all'inizio del turno chi brucia prende danno, e a fine turno l'effetto finisce
	run(f, 200)
	local before, points = fb.hp, fa.points
	to_turn(f, 2)
	check(fb.hp == before - config.STATUS.burn.damage and fa.points > points, "la bruciatura fa danno a inizio turno e dà punti")
	to_turn(f, 1)
	check(next(fb.status) == nil, "gli effetti finiscono alla fine del proprio turno")

	-- status_turns di chi colpisce allunga l'effetto
	local l = game.new(42, "forgia", { players = { { team = 1, stats = { status_turns = 2 } }, { team = 2 } } })
	run(l, 30)
	local lb = l.robots[2]
	l:explode(lb.x, lb.y + 4, 1, game.SHARD_BLAST, "shards")
	to_turn(l, 2)
	to_turn(l, 1)
	check(lb.status.slow and lb.status.slow.turns == 1, "con status_turns 2 dura un turno in più")

	-- la morte cancella gli effetti
	l:kill(lb, "damage")
	l:respawn(lb)
	check(next(lb.status) == nil, "dopo il respawn niente effetti")
end

-- Scelta d'inizio partita (sim/draft.lua) ----------------------------------------
do
	local draft = require "sim.draft"
	local d = draft.new(7, config.MODES["2v2"])
	check(#d.offer == config.DRAFT_OFFER, "il ventaglio ha " .. config.DRAFT_OFFER .. " armi")
	local again = draft.new(7, config.MODES["2v2"])
	check(table.concat(d.offer, ",") == table.concat(again.offer, ","), "stesso seme, stesso ventaglio")
	local w1, w2 = d.offer[1], d.offer[2]
	check(draft.pick(d, 1, w1), "il primo sceglie")
	check(not draft.valid(d, 3, w1), "il compagno non può prendere la stessa arma")
	check(draft.valid(d, 2, w1), "l'avversario sì")
	check(not draft.pick(d, 1, "teleport"), "solo armi del ventaglio")
	draft.pick(d, 3, w2)
	check(draft.swap(d, 1, 3) and d.picks[1] == w2 and d.picks[3] == w1, "i compagni si scambiano le armi")
	check(not draft.swap(d, 1, 2), "niente scambi con gli avversari")
	local players = draft.finish(d)
	check(players[2].pick == d.offer[1] and players[4].pick ~= players[2].pick,
		"allo scadere chi non ha scelto prende la prima arma libera")
	local g = game.new(7, "forgia", { players = players })
	check(g.robots[1].ammo[w2] == config.DRAFT_SHOTS and g.robots[1].ammo[w1] == 0, "in partita l'arma scelta ha i suoi colpi")

	-- il secondo ventaglio: le secondarie, una a testa, illimitate
	check(#d.offer2 == #game.DRAFT_SECONDARIES and game.SECONDARY[d.offer2[1]], "il ventaglio delle secondarie")
	local e = draft.new(9, config.MODES["2v2"])
	local s1, s2 = e.offer2[1], e.offer2[2]
	check(not draft.done(e, 1) and draft.pick(e, 1, s1) and not draft.done(e, 1), "la secondaria da sola non basta")
	check(draft.pick(e, 1, e.offer[1]) and draft.done(e, 1), "primaria e secondaria: ha finito")
	check(not draft.valid(e, 3, s1) and draft.valid(e, 2, s1), "anche la secondaria del compagno non si prende")
	draft.pick(e, 3, s2)
	draft.pick(e, 3, e.offer[2])
	check(draft.swap(e, 1, 3) and e.picks2[1] == s2 and e.picks[1] == e.offer[2], "lo scambio porta primaria e secondaria")
	local ep = draft.finish(e)
	check(ep[2].secondary == e.offer2[1] and ep[4].secondary ~= ep[2].secondary, "allo scadere la prima secondaria libera")
	local eg = game.new(9, "forgia", { players = ep })
	local r1 = eg.robots[1]
	check(r1.secondary == s2 and game.has_weapon(r1, s2) and game.has_weapon(r1, "sword") and not game.has_weapon(r1, s1),
		"in partita hai la Lama e la secondaria scelta, non le altre")
	check(game.FREE_WEAPONS[s2] and eg:can_use(s2) and eg:can_use("sword"), "le secondarie non consumano colpi")
	eg:step({ fire = { angle = 0, power = 1, weapon = s2 } })
	check(eg.used.secondary and not eg.used.primary and not eg:can_use("sword") and eg:can_use("missile"),
		"usata la secondaria scelta, la Lama non si usa più nel turno")

	-- tutti contro tutti: doppioni ammessi
	local f = draft.new(3, config.MODES.ffa)
	for i = 1, 4 do draft.pick(f, i, f.offer[1]) end
	local fp = draft.finish(f)
	check(fp[1].pick == fp[4].pick, "nel tutti contro tutti i doppioni vanno bene")
end

-- Salto in aria, scudo, Torneo ----------------------------------------------------
do
	-- salto in aria: con air_jumps, premendo di nuovo in volo, gratis
	local q = game.new(42, "forgia", { players = { { team = 1, stats = { air_jumps = 1 } }, { team = 2 } } })
	run(q, 60)
	local r = q.robots[1]
	q:step({ jump = true })
	run(q, 10, { jump = true })
	check(r.air_left == 1, "tenendo premuto il salto non si salta in aria")
	run(q, 2)
	local vy0 = r.vy
	q:step({ jump = true })
	check(r.vy > vy0 and r.air_left == 0, "premendo di nuovo in aria si risalta")
	run(q, 2)
	vy0 = r.vy
	q:step({ jump = true })
	check(r.vy < vy0, "un solo salto in aria con air_jumps 1")
	local n = game.new(42, "forgia")
	run(n, 60)
	local nr = n.robots[1]
	n:step({ jump = true })
	run(n, 12)
	vy0 = nr.vy
	n:step({ jump = true })
	check(nr.vy < vy0, "senza air_jumps niente salto in aria")

	-- scudo: si trova solo nelle casse e si usa quando si vuole
	local s = game.new(42, "forgia")
	run(s, 30)
	local sr = s.robots[1]
	check(not s:can_use("shield"), "senza scudi delle casse niente scudo")
	sr.ammo.shield = 1
	check(s:can_use("shield"), "con uno scudo in tasca si usa subito")
	s:step({ fire = { angle = 0, power = 1, weapon = "shield" } })
	check(sr.shield == config.SHIELD.hp and sr.ammo.shield == 0, "lo scudo delle casse si consuma")

	-- Torneo: le statistiche di albero e equipaggiamento non contano, l'arma scelta sì
	local custom = { { team = 1, stats = { max_hp = 300, walk_speed = 999 }, pick = "shards" }, { team = 2 } }
	local t = game.new(42, "forgia", { players = custom, normalize = true })
	check(t.robots[1].max_hp == config.STATS.max_hp and t.robots[1].stats.walk_speed == t.robots[2].stats.walk_speed,
		"nel Torneo tutti hanno le statistiche di base")
	check(t.robots[1].ammo.shards == config.DRAFT_SHOTS and t:results().normalized, "nel Torneo resta l'arma scelta")
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
	local g3 = game.new(3, "forgia")
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
	-- dopo RESPAWN_TICKS ricomincia in un punto libero a caso, nel turno di chi l'ha ucciso
	local resp
	for _ = 1, game.RESPAWN_TICKS do
		g3:step()
		for _, e in ipairs(g3:pop_events()) do if e.type == "respawn" then resp = e end end
	end
	check(resp and not b.dead and b.hp == b.max_hp and g3.current == 1,
		"alla morte si ricomincia con la vita piena, nello stesso turno")
	check(not g3:robot_collides(b.x, b.y, b), "in un punto libero")

	-- uccisione ambientale: chi colpisce un robot che poi cade fuori dalla mappa
	-- prende anche il bonus; senza colpi recenti nessuno prende niente
	local ge = game.new(3, "forgia")
	run(ge, 60)
	local ea, eb = ge.robots[1], ge.robots[2]
	ge:hurt(eb, 5, ea)
	eb.x, eb.y = -40, 300
	ge:step()
	check(eb.dead and ea.env_kills == 1 and eb.falls == 1, "chi butta fuori dalla mappa fa un'uccisione ambientale")
	check(ea.points == 5 + config.SCORE.kill + config.SCORE.env_kill, "che vale più di un'uccisione a colpi (" .. ea.points .. ")")
	local gf = game.new(3, "forgia")
	run(gf, 60)
	gf:hurt(gf.robots[2], 5, gf.robots[1])
	gf.tick = gf.tick + config.KILL_CREDIT_SECONDS * 60 + 1
	gf:kill(gf.robots[2], "fell")
	check(gf.robots[1].kills == 0, "una caduta molto dopo il colpo non conta come uccisione")

	-- chi si butta giù nel proprio turno: l'uccisione va a chi gli ha fatto più
	-- danno in questa vita (senza bonus ambientale) e lui perde di più
	local gs = game.new(3, "forgia", { players = config.MODES.ffa })
	run(gs, 60)
	local s1, s2, s3 = gs.robots[1], gs.robots[2], gs.robots[3]
	gs:hurt(s1, 30, s2)
	gs:hurt(s1, 10, s3)
	gs.tick = gs.tick + config.KILL_CREDIT_SECONDS * 60 + 1
	gs:pop_events()
	s1.x, s1.y = -40, 300
	gs:step()
	local sd
	for _, e in ipairs(gs:pop_events()) do if e.type == "death" then sd = e end end
	check(s1.dead and sd and sd.own and sd.by == 2 and not sd.env, "chi si butta giù regala l'uccisione a chi gli ha fatto più danno")
	check(s2.kills == 1 and s2.env_kills == 0 and s2.points == 30 + config.SCORE.kill and s3.points == 10,
		"che prende i punti di un'uccisione (" .. s2.points .. ")")
	check(s1.points == config.SCORE.death + config.SCORE.self_death, "e chi si butta giù perde di più (" .. s1.points .. ")")
	run(gs, game.RESPAWN_TICKS + 5)
	check(not s1.dead and gs.current == 1 and gs.phase == "aim" and next(s1.life_damage) == nil,
		"poi ricomincia nel suo turno, e il danno della vita prima non conta più")
	-- nel proprio turno, colpito da poco da un avversario: vale la regola normale
	local gr = game.new(3, "forgia")
	run(gr, 60)
	gr:hurt(gr.robots[1], 5, gr.robots[2])
	gr:kill(gr.robots[1], "fell")
	check(gr.robots[2].env_kills == 1 and gr.robots[1].points == config.SCORE.death, "colpito da poco: uccisione ambientale normale")
	-- nel proprio turno senza danni da nessuno: niente punti agli altri, ma la penalità sì
	local gn = game.new(3, "forgia")
	run(gn, 60)
	gn:kill(gn.robots[1], "fell")
	check(gn.robots[2].kills == 0 and gn.robots[1].points == config.SCORE.death + config.SCORE.self_death,
		"morto da solo senza danni: solo la penalità")

	-- colpire chi è primo vale di più
	local gl = game.new(3, "forgia", { players = config.MODES.ffa })
	gl.robots[3].points = 100
	gl:hurt(gl.robots[3], 10, gl.robots[1])
	gl:hurt(gl.robots[4], 10, gl.robots[2])
	check(gl.robots[1].points == 10 * config.SCORE.leader and gl.robots[2].points == 10, "colpire il primo vale di più")

	-- nel 2 contro 2 il danno al compagno non dà punti, e i punti si sommano per squadra
	local gt = game.new(3, "forgia", { players = config.MODES["2v2"] })
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
local g5 = game.new(7, "forgia")
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
local g6 = game.new(7, "forgia")
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
local g7 = game.new(42, "forgia")
g7.robots[2].points = 10
local ticks7 = 0
while g7.phase ~= "over" and ticks7 < game.MATCH_TICKS + 2000 do
	g7:step({})
	ticks7 = ticks7 + 1
end
check(g7.phase == "over" and ticks7 >= game.MATCH_TICKS, "la partita finisce allo scadere dei 5 minuti")
check(g7.winner == 2, "a tempo scaduto vince chi ha più punti")
check(ticks7 <= game.MATCH_TICKS + 2 * (game.TURN_TICKS + game.MAX_SETTLE_TICKS),
	"dopo lo scadere si finisce il giro di turni")

-- Supplementari: il turno in corso non si interrompe e si finisce il giro
do
	-- scade durante il turno del primo: si finisce il suo e si gioca quello del secondo
	local ot = game.new(42, "forgia")
	run(ot, 60)
	ot.match_left = 10
	run(ot, 20)
	check(ot.overtime and ot.phase == "aim" and ot.current == 1, "allo scadere il turno in corso continua")
	for _ = 1, 4000 do
		ot:step()
		if ot.current == 2 or ot.phase == "over" then break end
	end
	check(ot.current == 2 and ot.phase == "aim", "supplementari: gioca anche il secondo")
	for _ = 1, 4000 do
		ot:step()
		if ot.phase == "over" then break end
	end
	check(ot.phase == "over" and ot.current == 2, "finito il giro la partita finisce")
	check(ot.robots[1].turns == ot.robots[2].turns, "tutti hanno giocato gli stessi turni")
end


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
local cg = game.new(7, "forgia")
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
local hg = game.new(7, "forgia")
for _ = 1, 120 do hg:step({}) end
local h1, h2 = hg.robots[1], hg.robots[2]
h2.x, h2.y, h2.vx, h2.vy, h2.grounded = h1.x, h1.y + 60, 0, 0, false
for _ = 1, 90 do hg:step({}) end
check(h2.grounded and math.abs(h2.y - (h1.y + game.ROBOT_H)) < 1.01, "chi cade su un robot gli resta in testa")

-- Il globo che arriva addosso a un robot lo sposta un briciolo e rimbalza
local og = game.new(7, "forgia")
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
local bg = game.new(42, "forgia")
run(bg, 120)
local by = 500 -- cielo libero sulla forgia
bg.orbs = {
	{ id = 1, x = 600, y = by, vx = 200, vy = 0, owner = 1, timer = 100, age = 100 },
	{ id = 2, x = 680, y = by, vx = -200, vy = 0, owner = 1, timer = 100, age = 100 },
}
for _ = 1, 20 do bg:step({}) end
check(bg.orbs[1].x < bg.orbs[2].x and bg.orbs[1].vx < 0 and bg.orbs[2].vx > 0, "due globi che si scontrano rimbalzano")

-- Armi delle casse -------------------------------------------------------------

-- Senza colpi le armi delle casse non sparano; con un colpo sparano una volta
local am = game.new(42, "forgia")
run(am, 120)
am:step({ fire = { angle = math.rad(45), power = 0.6, weapon = "grenade" } })
check(am.phase == "aim" and not am.projectile, "senza colpi l'Uovo di Fiamma non parte")
am.robots[1].ammo.grenade = 1
am:step({ fire = { angle = math.rad(45), power = 0.6, weapon = "grenade" } })
check(am.projectile and am.projectile.kind == "grenade" and am.robots[1].ammo.grenade == 0,
	"con un colpo l'Uovo parte e il colpo si consuma")

-- Uovo di Fiamma: rimbalza, si posa e scoppia dopo 3 secondi, più grande del missile
local gr = game.new(42, "forgia")
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
local sh = game.new(42, "forgia")
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
	local q = game.new(42, "forgia")
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
	local q = game.new(seed, "crogiolo")
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
local pk = game.new(42, "forgia", { crate_every = 1 })
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
local mix = game.new(11, "forgia")
for _ = 1, 30 do
	mix.crates = {}
	local cc = mix:spawn_crate()
	if cc then seen[cc.weapon] = true end
end
check(seen.grenade and seen.shards and seen.punch, "nelle casse si trovano tutte e tre le armi")

-- Determinismo con le armi nuove: stesso seed e stessi input, stesso risultato
local function play2(seed)
	local p = game.new(seed, "crogiolo", { ammo = { grenade = 9, shards = 9, punch = 9 }, crate_every = 1 })
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
local bm = game.new(42, "forgia")
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
local ba = game.new(42, "forgia")
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
	local q = game.new(42, "forgia")
	run(q, 120)
	local r = q.robots[2]
	local y = sky_spot(q, 640, 60)
	place(r, 640, y)
	local hp = r.hp
	-- il bordo destro della scatola (col cerchio, del quadrato attorno)
	local edge = game.HURTBOX == "cerchio" and game.HURT_R + game.HURT_FAT or game.ROBOT_HALF_W
	q:explode(640 + edge + dx, y + game.HURT_Y, owner, game.MISSILE_BLAST)
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
local hb = game.new(42, "forgia")
local hr = hb.robots[2]
local hcy = hr.y + game.HURT_Y
check(hb:hits_robot(hr.x + game.HURT_R - 0.5, hcy, 1, 0) and not hb:hits_robot(hr.x + game.HURT_R + 0.5, hcy, 1, 0),
	"blastron: il bersaglio è un cerchio di raggio HURT_R")
check(not hb:hits_robot(hr.x + game.ROBOT_HALF_W, hr.y, 1, 0), "blastron: l'angolo in basso della scatola non conta")

-- Capsula per camminare e cerchio dei colpi vengono da sim/corpo.lua (l'editor
-- delle animazioni li cambia); il disegno resta della sua misura
local corpo = require "sim.corpo"
check(game.ROBOT_H == corpo.cammina.alto and game.ROBOT_HALF_W * 2 == corpo.cammina.largo
	and game.HURT_R == corpo.colpi.raggio and game.HURT_Y == corpo.colpi.centro,
	"blastron: capsula e cerchio dei colpi da sim/corpo.lua")
check(game.DISEGNO_H == game.BLASTRON_ROBOT_H * game.BLASTRON_CORPO, "blastron: il disegno non dipende da sim/corpo.lua")

-- Mischia sulla mira: target = posizione del bersaglio rispetto ai piedi (in unità
-- di Blastron), i robot restano fermi in aria; restituisce il tick del colpo o false
local function melee_at(deg, tx, ty, weapon)
	local q = game.new(42, "forgia")
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
-- i bersagli da non prendere stanno più lontani quanto il corpo è più grande di
-- quello di Blastron (BLASTRON_CORPO)
local C = game.BLASTRON_CORPO
check(melee_at(60, 4, 5) and melee_at(-60, 0, -5) and not melee_at(60, 0, -5 - 7.5 * (C - 1)),
	"blastron: il colpo gira con la mira")
check(melee_at(-90, 4, -4) and not melee_at(-90, -4, 0), "blastron: mirando giù non prende chi è dietro")
local pt, pq2 = melee_at(0, 2, 0, "punch")
check(pt and pq2.robots[2].vy == game.PUNCH_LAUNCH and pq2.robots[2].vx == 0,
	"blastron: il montante lancia dritto in alto")
check(not melee_at(-60, 0, 4 + 7.5 * (C - 1), "punch"), "blastron: il montante mirato in basso non prende chi è sopra")
check(game.melee_ticks(mischia.fendente) == game.SWORD_TICKS and game.melee_ticks(mischia.montante) == game.PUNCH_TICKS,
	"blastron: durate del fendente e del montante coerenti con le animazioni")


-- Danno da caduta oltre 40 u
local bf = game.new(42, "forgia")
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
local bf2 = game.new(42, "forgia")
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
	local q = game.new(seed, "crogiolo")
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
	local q = game.new(42, "forgia")
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

-- Rampino su un robot a terra: il pavimento sotto il bersaglio non ferma la
-- fune, né in piano (anche con chi tira una cella più in basso) né su un
-- pendio, in salita o in discesa: arriva fin addosso a chi tira. Prima 9
-- volte su 10 si fermava subito. hook_drag dà la distanza finale tra i due.
local function hook_drag(ground, xa, xb)
	local q = shaped_world(ground)
	local a, b = q.robots[1], q.robots[2]
	place(a, xa, ground(xa))
	place(b, xb, ground(xb))
	for _ = 1, 30 do q:step() end
	local ang = math.atan2(b.y + game.ROBOT_H / 2 - (a.y + game.SWORD_PIVOT_Y), b.x - a.x)
	q:step({ fire = { angle = ang, power = 1, weapon = "hook" } })
	if not b.hooked then return math.huge end
	for _ = 1, 60 do
		q:step()
		if not b.hooked then break end
	end
	return math.abs(b.x - a.x)
end
local close = 2 * game.ROBOT_HALF_W + 4
check(hook_drag(function() return 100 end, 500, 680) < close, "Rampino in piano: il nemico a terra viene trascinato fin addosso")
check(hook_drag(function(x) return x < 560 and 100 - game.CELL or 100 end, 500, 680) < close,
	"Rampino in piano, chi tira una cella più in basso: trascinato lo stesso")
check(hook_drag(function(x) return 100 + (x - 500) * 0.4 end, 500, 680) < close,
	"Rampino in salita (il nemico più in alto): trascinato giù")
check(hook_drag(function(x) return 200 - (x - 500) * 0.4 end, 500, 680) < close,
	"Rampino in discesa (il nemico più in basso): trascinato su")
check(hook_drag(function(x) return 100 + math.floor(x / 24) % 2 * 4 end, 500, 680) < close,
	"Rampino su un pavimento a gradini: trascinato lo stesso")
-- sulle mappe vere: nemici a terra a 120 pixel, in tanti punti diversi
for _, id in ipairs(maps.order) do
	local pulled, tries = 0, 0
	for x0 = 100, game.WORLD_W - 220, 37 do
		local q = game.new(42, id)
		run(q, 60)
		local a, b = q.robots[1], q.robots[2]
		local ya = q.terrain:ground_below(x0, game.WORLD_H - 1)
		local yb = q.terrain:ground_below(x0 + 120, game.WORLD_H - 1)
		if ya and yb and math.abs(ya - yb) < 30 then
			place(a, x0, ya)
			place(b, x0 + 120, yb)
			run(q, 30)
			if a.grounded and b.grounded and not a.dead and not b.dead then
				local bx, by = b.x, b.y
				q:step({ fire = { angle = math.atan2(b.y + game.ROBOT_H / 2 - (a.y + game.SWORD_PIVOT_Y), b.x - a.x),
					power = 1, weapon = "hook" } })
				if b.hooked then
					tries = tries + 1
					for _ = 1, 40 do
						q:step()
						if not b.hooked then break end
					end
					if math.sqrt((bx - b.x) ^ 2 + (by - b.y) ^ 2) > 80 then pulled = pulled + 1 end
				end
			end
		end
	end
	check(tries > 0 and pulled == tries, id .. ": il Rampino trascina il nemico a terra ogni volta (" .. pulled .. "/" .. tries .. ")")
end
check(hook_drag(function(x) return (x > 560 and x < 572) and 100 + game.ROBOT_H or 100 end, 500, 650) > 650 - 560,
	"Rampino: un muro alto ferma il nemico")

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
