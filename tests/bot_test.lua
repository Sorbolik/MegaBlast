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
end

-- Pesi diversi per un bot (players[i].pesi): stanno nella ricetta, che rigioca la stessa partita
do
	local function impronte(pesi)
		local players = { { team = 1, bot = "normale", pesi = pesi }, { team = 2, bot = "normale" } }
		local r5 = replay.nuova(6, "forgia", { players = players })
		local g5, bots = replay.partita(r5)
		while g5.tick < 2400 do
			g5:step(replay.input(r5, g5, bots))
			replay.dopo(r5, g5)
		end
		return r5, g5:impronta()
	end
	local _, h0 = impronte(nil)
	local r5, h1 = impronte({ globo_riparo = 1000, strada = 0.1 })
	check(h0 ~= h1, "pesi: un bot con altri pesi gioca un'altra partita")
	check(replay.verifica(r5), "pesi: la ricetta con i pesi rigioca la stessa partita")

	-- una rete neurale a caso al posto dei pesi: gioca, e la ricetta rigioca uguale
	local rete = require "sim.rete"
	local strati = { bot.CARATTERISTICHE, 6, 1 }
	local w, x = {}, 7
	for i = 1, rete.quanti(strati) do
		x = (x * 1103515245 + 12345) % 2147483648
		w[i] = x / 2147483648 * 2 - 1
	end
	local r6, h2 = impronte({ rete = { strati = strati, w = w } })
	check(h2 ~= h0, "rete: un bot con la rete gioca un'altra partita")
	check(replay.verifica(r6), "rete: la ricetta con la rete rigioca la stessa partita")
end

-- Il bot del tutorial e il piano del turno imposto da fuori (partita guidata)
do
	-- gioca il turno del robot 2 (bot) fino alla fine; restituisce gli eventi del turno
	local function turno_del_bot(livello, piano, seme)
		local g = game.new(seme or 3, "forgia", { players = { { team = 1 }, { team = 2 } } })
		local b = bot.new(2, livello, seme or 3)
		while g.current ~= 2 do g:step({ fire = g.phase == "aim" and { weapon = "missile", angle = 1.4, power = 0.2 } or nil }) end
		g:pop_events()
		b.piano = piano
		local ev, inizio = {}, g.tick
		local turno = g.turn_no
		while g.turn_no == turno and g.tick - inizio < 40 * 60 do
			g:step(bot.input(b, g))
			for _, e in ipairs(g:pop_events()) do ev[#ev + 1] = { e = e, t = g.tick - inizio } end
		end
		return ev, g
	end
	local ATTACCHI = { fire = true, grenade = true, shards = true, swing = true, sniper = true, eagle = true,
		mallet = true, lunge = true, punch = true }
	-- tutorial: il primo attacco non prende nessuno (il danno prima del secondo)
	local danni, n = 0, 0
	for _, x in ipairs(turno_del_bot("tutorial")) do
		if ATTACCHI[x.e.type] then n = n + 1 end
		if n == 1 and x.e.type == "damage" and x.e.robot == 1 then danni = danni + x.e.amount end
	end
	check(n >= 1 and danni == 0, "tutorial: il primo attacco del bot sbaglia apposta")
	-- attacca_entro 4 e poi teletrasporto
	local quando, globo = nil, false
	for _, x in ipairs(turno_del_bot("normale", { attacca_entro = 4, poi = "teletrasporto" })) do
		if not quando and ATTACCHI[x.e.type] then quando = x.t end
		if quando and x.e.type == "orb" then globo = true end
	end
	check(quando and quando <= 4 * 60, "piano: attacca entro 4 secondi (" .. tostring(quando) .. " tick)")
	check(globo, "piano: poi lancia il teletrasporto")
	-- due attacchi: primaria e secondaria nello stesso turno
	n = 0
	for _, x in ipairs(turno_del_bot("normale", { due_attacchi = true })) do
		if ATTACCHI[x.e.type] then n = n + 1 end
	end
	check(n >= 2, "piano: due attacchi nello stesso turno (" .. n .. ")")
end

-- La rete: conti a mano su una rete piccola (ReLU nel mezzo, uscita lineare)
do
	local rete = require "sim.rete"
	local r = { strati = { 2, 2, 1 }, w = { 1, -1, 0.5, 0.5, 0, -1, 2, 3, 0.25 } }
	-- nascosti: relu(1*3 - 1*1 + 0) = 2, relu(0.5*3 + 0.5*1 - 1) = 1; uscita 2*2 + 3*1 + 0.25
	check(rete.quanti(r.strati) == 9 and rete.valuta(r, { 3, 1 }) == 7.25, "rete: i conti tornano")
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
	-- col gusto per le armi (pesi.armi) prende quelle che gli piacciono, se ci sono
	local d2 = draft.new(9, { { team = 1 }, { team = 2 } })
	bot.scegli(d2, 1, 9, { punch = 3, mallet = 3 })
	local ha = function(offer, w) for _, x in ipairs(offer) do if x == w then return true end end end
	check((d2.picks[1] == "punch") == ha(d2.offer, "punch") and (d2.picks2[1] == "mallet") == ha(d2.offer2, "mallet"),
		"scelta: con il gusto per le armi prende Pugno e Maglio")
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

-- La mira da vicino: chi prenderebbe il colpo, senza toccare la partita
do
	local g6 = game.new(3, "forgia", { players = { { team = 1 }, { team = 2 } } })
	for _ = 1, 120 do g6:step() end
	local a, b = g6.robots[g6.current], nil
	for _, r in ipairs(g6.robots) do if r ~= a then b = r end end
	b.x, b.y = a.x + 50, a.y
	a.secondary = "bellows"
	local prima, out = g6:impronta(), {}
	local verso = bot.colpiti(g6, "bellows", 0, out)
	local preso = out[1]
	local via = bot.colpiti(g6, "bellows", math.pi, out)
	check(verso == 1 and preso == b.id and via == 0 and g6:impronta() == prima,
		"mira da vicino: il Mantice prende chi ha davanti, non chi ha dietro, e la partita non cambia")
end

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test superati")
