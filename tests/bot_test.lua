-- Test del bot (sim/bot.lua) e delle ricette (sim/replay.lua). Dalla radice:
--   luajit tests/bot_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local config = require "sim.config"
local draft = require "sim.draft"
local bot = require "sim.bot"
local replay = require "sim.replay"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

-- Una partita intera tra bot, con la ricetta
local function partita(seme, modo, livello, mappa)
	local players = {}
	for i, p in ipairs(config.MODES[modo]) do players[i] = { team = p.team, bot = livello } end
	local r = replay.nuova(seme, mappa, { players = players })
	local g, bots = replay.partita(r)
	local eventi = {}
	while g.phase ~= "over" do
		g:step(replay.input(r, g, bots))
		replay.dopo(r, g)
		for _, e in ipairs(g:pop_events()) do eventi[e.type] = (eventi[e.type] or 0) + 1 end
	end
	return g, r, eventi
end

-- I bot giocano: attaccano a ogni turno e fanno danno
local g, r, ev = partita(11, "1v1", "difficile", "forgia")
check(g.phase == "over", "1v1: la partita tra bot finisce")
local attacchi = (ev.fire or 0) + (ev.grenade or 0) + (ev.shards or 0) + (ev.sniper or 0) + (ev.swing or 0)
	+ (ev.eagle or 0) + (ev.mallet or 0) + (ev.lunge or 0) + (ev.punch or 0)
check(attacchi >= ev.turn, "1v1: almeno un attacco per turno (" .. attacchi .. " in " .. ev.turn .. " turni)")
check(g.robots[1].damage + g.robots[2].damage > 100, "1v1: i bot si fanno danno")
for _, rb in ipairs(g.robots) do
	check(rb.attack_turns > 0 and rb.attack_ticks / rb.attack_turns < 15 * 60,
		"robot " .. rb.id .. ": attacca in fretta (guadagna teletrasporti)")
end

-- La ricetta rigioca la stessa partita: le impronte tornano tutte
local ok, tick = replay.verifica(r)
check(ok, "ricetta: la partita rigiocata è identica" .. (ok and "" or " (diverge al tick " .. tostring(tick) .. ")"))
-- una ricetta toccata non vale
r.seme = r.seme + 1
local ok2 = replay.verifica(r, 1200)
check(not ok2, "ricetta: con un seme diverso le impronte non tornano")

-- 2 contro 2 e tutti contro tutti, sull'altra mappa
for _, modo in ipairs({ "2v2", "ffa" }) do
	local g2 = partita(5, modo, "normale", "crogiolo")
	local danno = 0
	for _, rb in ipairs(g2.robots) do danno = danno + rb.damage end
	check(g2.phase == "over" and danno > 50, modo .. ": la partita tra bot finisce con dei danni")
	-- nel 2 contro 2 i compagni non si colpiscono apposta: niente uccisioni tra compagni
end

-- Un giocatore vero e un bot: i tasti del giocatore finiscono nella ricetta e la rigiocano
do
	local players = { { team = 1 }, { team = 2, bot = "facile" } }
	local r3 = replay.nuova(4, "forgia", { players = players })
	local g3, bots = replay.partita(r3)
	while g3.tick < 3600 and g3.phase ~= "over" do
		local umano = { right = g3.tick % 200 < 100, left = false, hold = true, jump = g3.tick % 150 == 0 }
		if g3.current == 1 and g3.tick % 500 == 120 then umano.fire = { weapon = "missile", angle = 0.6, power = 0.8 } end
		g3:step(replay.input(r3, g3, bots, umano))
		replay.dopo(r3, g3)
	end
	check(#r3.input > 0 and #r3.input < g3.tick / 10, "ricetta: solo i cambiamenti dei tasti (" .. #r3.input .. ")")
	check(replay.verifica(r3), "ricetta: giocatore e bot, la partita rigiocata è identica")
end

-- Il bot pensa poco alla volta: mai troppo lavoro in un tick
do
	local g4 = game.new(2, "forgia", { players = { { team = 1 }, { team = 2 } } })
	local b1, b2 = bot.new(1, "difficile", 2), bot.new(2, "difficile", 2)
	local troppo = 0
	while g4.tick < 6000 do
		local b = g4.current == 1 and b1 or b2
		local prima = bot.totale or 0
		local input = bot.input(b, g4)
		if (bot.totale or 0) - prima > 2 * b.liv.lavoro then troppo = troppo + 1 end
		g4:step(input)
		g4:pop_events()
	end
	check(troppo == 0, "il bot rispetta il tetto di lavoro per tick")
end

-- Nella scelta d'inizio partita il bot prende una primaria e una secondaria valide
do
	local players = { { team = 1 }, { team = 2 }, { team = 1 }, { team = 2 } }
	local d = draft.new(9, players)
	for i = 1, 4 do bot.scegli(d, i, 9) end
	local tutti = true
	for i = 1, 4 do tutti = tutti and draft.done(d, i) end
	check(tutti, "scelta: i bot scelgono tutte e due le armi")
	check(d.picks[1] ~= d.picks[3] and d.picks2[1] ~= d.picks2[3], "scelta: compagni con armi diverse")
end

-- Le copie su cui pensa il bot non toccano la partita vera
do
	local g5 = game.new(3, "forgia")
	for _ = 1, 120 do g5:step() end
	local prima = g5:impronta()
	local celle = 0
	for i = 1, #g5.terrain.data do celle = celle + g5.terrain.data[i] end
	local w = bot.mondo(g5)
	w:attack("missile", { angle = -1.2, power = 1 })
	for _ = 1, 200 do w:advance({}, true) end
	local dopo = 0
	for i = 1, #g5.terrain.data do dopo = dopo + g5.terrain.data[i] end
	check(g5:impronta() == prima and celle == dopo, "le prove del bot non cambiano la partita né il terreno")
end

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test superati")
