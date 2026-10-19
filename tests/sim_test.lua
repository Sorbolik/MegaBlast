-- Test della simulazione. Dalla radice del repository:
--   lua tests/sim_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"

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

-- I robot cadono e si appoggiano sul terreno
local g = game.new(42)
run(g, 120)
check(g.robots[1].grounded and g.robots[2].grounded, "i robot si appoggiano al terreno")
check(not g.robots[1].dead and not g.robots[2].dead, "nessun robot muore all'avvio")

-- Il robot di turno cammina
local x0, x2 = g.robots[1].x, g.robots[2].x
run(g, 60, { right = true })
check(g.robots[1].x > x0 + 20, "il robot cammina verso destra")
check(g.robots[2].x == x2, "l'avversario resta fermo")

-- Salto: il robot si stacca da terra e poi riatterra
g:step({ jump = true })
check(not g.robots[1].grounded, "il robot salta")
run(g, 120)
check(g.robots[1].grounded, "il robot riatterra")

-- Sparo: il missile esplode, scava il terreno e passa il turno
local function solid_count(t)
	local n = 0
	for i = 1, #t.data do n = n + t.data[i] end
	return n
end
local before = solid_count(g.terrain)
g:step({ fire = { angle = math.rad(60), power = 0.6 } })
check(g.phase == "flying", "il missile parte")
local exploded = false
for _ = 1, 600 do
	g:step()
	for _, e in ipairs(g:pop_events()) do
		if e.type == "explosion" or e.type == "miss" then exploded = true end
	end
	if g.current == 2 then break end
end
check(exploded, "il missile esplode o esce dalla mappa")
check(g.current == 2, "il turno passa al giocatore 2")

-- Esplosione diretta su un robot: danno e cratere
local g2 = game.new(7)
run(g2, 120)
local rb = g2.robots[2]
local t0 = solid_count(g2.terrain)
g2:explode(rb.x, rb.y + 2)
check(rb.hp < game.MAX_HP, "l'esplosione fa danno")
check(solid_count(g2.terrain) < t0, "l'esplosione scava un cratere")

-- Determinismo: stesso seed, stessi input, stesso risultato
local function play(seed)
	local p = game.new(seed)
	for i = 1, 3000 do
		local input = {}
		if p.phase == "aim" and p.timer == game.TURN_TICKS - 30 then
			input.fire = { angle = math.rad(p.current == 1 and 45 or 135), power = 0.7 }
		end
		p:step(input)
	end
	return p.robots[1].x, p.robots[1].hp, p.robots[2].x, p.robots[2].hp, solid_count(p.terrain)
end
local a = { play(99) }
local b = { play(99) }
local same = true
for i = 1, #a do if a[i] ~= b[i] then same = false end end
check(same, "stesso seed e stessi input danno lo stesso risultato")

-- Una partita finisce: il timer scade e i turni si alternano
local g3 = game.new(3)
g3.robots[2].hp = 1
g3:explode(g3.robots[2].x, g3.robots[2].y + 8)
run(g3, game.TURN_TICKS + 600)
check(g3.phase == "over" and g3.winner == 1, "la partita finisce e vince il giocatore 1")

-- Prestazioni: un cratere e 600 tick di simulazione
local t = os.clock()
local g4 = game.new(5)
for i = 1, 600 do g4:step({ right = i % 2 == 0 }) end
for i = 1, 20 do g4.terrain:carve(100 + i * 50, 200, 30) end
print(string.format("info 600 tick + 20 crateri in %.1f ms", (os.clock() - t) * 1000))

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test superati")
