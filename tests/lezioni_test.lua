-- Test delle lezioni (sim/lezioni.lua): ognuna si risolve davvero con la sua
-- meccanica, e senza no. Dalla radice del repository:
--   luajit tests/lezioni_test.lua
-- Le soluzioni sono copioni di tasti; dove serve una mira, il test la cerca
-- su una griglia di angoli e potenze, come farebbe chi prova.
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local lezioni = require "sim.lezioni"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

local FERMO = {}
local DESTRA = { right = true }
local SINISTRA = { left = true }

-- Gioca la lezione col copione: copione(c) chiama c.tieni(input, tick o
-- condizione), c.usa(arma, angolo, potenza), c.turno() (aspetta il prossimo
-- turno del giocatore). Restituisce l'esito, la lezione e la partita.
local function gioca(id, copione, picks, limite)
	local r = lezioni.nuova(id)
	local seed, mappa, opts = lezioni.partita(r, 3, picks)
	local g = game.new(seed, mappa, opts)
	lezioni.prepara(r, g)
	local co = coroutine.wrap(function(c)
		copione(c)
		while true do coroutine.yield(FERMO) end
	end)
	local c = {}
	function c.tieni(input, fino)
		local n = 0
		while true do
			if type(fino) == "number" then
				if n >= fino then return end
			elseif fino(g) then
				return
			end
			n = n + 1
			coroutine.yield(input)
		end
	end
	function c.usa(arma, angolo, potenza)
		coroutine.yield({ fire = { weapon = arma, angle = angolo, power = potenza or 1 } })
	end
	function c.turno()
		local turni = r.st.turni
		c.tieni(FERMO, function() return r.st.turni > turni and g.phase == "aim" end)
	end
	c.g = g
	local primo = true
	for _ = 1, limite or 60 * 120 do
		local input = primo and FERMO or co(c)
		primo = false
		g:step(input)
		for _, e in ipairs(g:pop_events()) do lezioni.evento(r, g, e) end
		local esito = lezioni.tick(r, g)
		if esito then return esito, r, g end
	end
	return nil, r, g
end

-- Cerca angolo e potenza per cui il copione (che riceve a, p) finisce la lezione
local function cerca(id, copione, picks, angoli, potenze)
	for _, p in ipairs(potenze or { 1 }) do
		for a = angoli[1], angoli[2], angoli[3] do
			local esito, r = gioca(id, function(c) copione(c, a, p) end, picks)
			if esito == "fatta" then return true, r, a, p end
		end
	end
	return false
end

local function potenze(da, a, passo)
	local t = {}
	for p = da, a, passo do t[#t + 1] = p end
	return t
end

local function fino_x(x) return function(g) return g.robots[1].x >= x end end

-- Ogni lezione: i robot partono appoggiati, e senza fare niente non è fatta
for _, l in ipairs(lezioni.LISTA) do
	if not l.guidata then
		local esito, r, g = gioca(l.id, function() end, nil, 60 * 30 * (l.turni or 2) + 600)
		local giu = true
		for _, rb in ipairs(g.robots) do
			if rb.dead then giu = false end
		end
		check(giu, l.id .. ": nessuno cade da solo")
		check(esito ~= "fatta" and r.riga ~= nil or esito == "fallita", l.id .. ": senza fare niente non si finisce")
	end
end

-- Armi e draft: granata (primaria scelta) da lontano, poi Maglio da vicino
local SCELTA = { { pick = "grenade", secondary = "mallet", tool = "hook" } }
local ok, r, a, p = cerca("armi", function(c, a, p)
	c.usa("grenade", a, p)
	c.turno()
	c.tieni(DESTRA, fino_x(1040))
	c.usa("mallet", 0)
end, SCELTA, { 0.2, 1.2, 0.1 }, potenze(0.4, 1, 0.1))
check(ok, "armi: si finisce con la primaria e la secondaria scelte")
if ok then check(lezioni.stelle(r) == 3, "armi: in due turni sono tre stelle") end
-- Solo Lanciarune e Lama non bastano mai
local esito = gioca("armi", function(c)
	for _ = 1, 4 do
		c.tieni(DESTRA, fino_x(1040))
		c.usa("missile", 0.3, 0.4)
		c.tieni(FERMO, 30)
		c.usa("sword", 0)
		c.turno()
	end
end, SCELTA)
check(esito ~= "fatta", "armi: con Lanciarune e Lama non si finisce")

-- Tempo e globi: un missile subito sul bersaglio vicino, poi il globo sull'isola e la Lama
ok, r = cerca("globi", function(c, a, p)
	c.usa("missile", 0.15, 0.5)
	c.tieni(FERMO, 20)
	c.usa("teleport", a, p)
	c.tieni(FERMO, function(g) return g.robots[1].x > 1150 end)
	c.tieni(FERMO, 60)
	local g = c.g
	if g.robots[1].x < 1340 then
		c.tieni(DESTRA, fino_x(1338))
		c.usa("sword", 0)
	else
		c.usa("sword", math.pi)
	end
end, nil, { 0.3, 1.2, 0.05 }, potenze(0.5, 1, 0.1))
check(ok, "globi: attaccare presto dà il globo che porta sull'isola")
-- Senza attaccare prima non ci sono globi
esito = gioca("globi", function(c)
	c.usa("teleport", 0.6, 0.8)
	c.tieni(FERMO, 400)
end)
check(esito ~= "fatta", "globi: senza globi non si arriva")

-- Le casse: al secondo turno la cassa cade vicino, la si prende e si lancia la Granata
ok = cerca("casse", function(c, a, p)
	c.turno()
	c.tieni(FERMO, function(g) return g.crates[1] and g.crates[1].landed end)
	c.tieni(DESTRA, function(g) return g.robots[1].ammo.grenade > 0 end)
	c.usa("grenade", a, p)
end, nil, { 0.2, 1.2, 0.1 }, potenze(0.4, 1, 0.1))
check(ok, "casse: si finisce con quello che c'è nella cassa")

-- Il paracadute: giù dalla torre, aperto subito, a destra fino alla piattaforma, poi il missile
ok = cerca("paracadute", function(c, a, p)
	c.tieni(DESTRA, function(g) return not g.robots[1].grounded end)
	c.usa("parachute", 0, 1)
	c.tieni(DESTRA, function(g) return g.robots[1].grounded end)
	c.tieni(FERMO, 20)
	c.usa("missile", a, p)
end, nil, { 0, 0.8, 0.1 }, potenze(0.3, 1, 0.1))
check(ok, "paracadute: planando si arriva al bersaglio")
esito = gioca("paracadute", function(c)
	c.tieni(DESTRA, function(g) return g.robots[1].grounded == false end)
	c.tieni(DESTRA, 600)
end)
check(esito ~= "fatta", "paracadute: senza paracadute non si arriva")

-- Il Rampino: sotto il bordo, aggancio in alto, su e la Lama
ok = cerca("rampino", function(c, a)
	c.tieni(DESTRA, fino_x(960))
	c.usa("hook", a)
	c.tieni(FERMO, function(g) return g.robots[1].grounded and g.robots[1].y > 300 end)
	c.tieni(FERMO, 10)
	c.tieni(DESTRA, fino_x(1182))
	c.usa("sword", 0)
end, nil, { 0.8, 1.5, 0.05 })
check(ok, "rampino: agganciato il bordo si sale sulla piattaforma")
esito = gioca("rampino", function(c)
	c.tieni(DESTRA, fino_x(990))
	for _ = 1, 10 do
		c.tieni({ right = true, jump = true }, 12)
		c.tieni(DESTRA, 30)
	end
end)
check(esito ~= "fatta", "rampino: saltando e basta non si sale")

-- Il Bastione: il blocco come gradino, poi su e la Lama
ok = cerca("bastione", function(c, a, p)
	c.tieni(DESTRA, fino_x(1000))
	c.usa("wall", a, p)
	c.tieni(FERMO, 10)
	for _ = 1, 8 do
		c.tieni({ right = true, jump = true }, 12)
		c.tieni(DESTRA, 30)
	end
	c.tieni(DESTRA, fino_x(1262))
	c.usa("sword", 0)
end, nil, { 0.1, 1.4, 0.1 }, potenze(0.15, 0.6, 0.05))
check(ok, "bastione: sul blocco si sale alla sporgenza")
esito = gioca("bastione", function(c)
	c.tieni(DESTRA, fino_x(1040))
	for _ = 1, 10 do
		c.tieni({ right = true, jump = true }, 12)
		c.tieni(DESTRA, 30)
	end
end)
check(esito ~= "fatta", "bastione: saltando e basta non si sale")

-- Il Maglio: salto, colpo a terra in discesa, rimbalzo sul pilastro, poi il missile
ok = cerca("maglio", function(c, a, p)
	c.tieni(DESTRA, fino_x(900))
	c.tieni({ jump = true }, 10)
	c.tieni(FERMO, function(g) return g.robots[1].vy < 0 and g.robots[1].y < 153 + a end)
	c.usa("mallet", 0)
	c.tieni(DESTRA, function(g) return g.robots[1].grounded and g.robots[1].y > 300 end)
	c.tieni(FERMO, 10)
	c.usa("missile", 0.1, p)
end, nil, { 10, 30, 10 }, potenze(0.3, 1, 0.1))
check(ok, "maglio: il rimbalzo porta sul pilastro")
esito = gioca("maglio", function(c)
	c.tieni(DESTRA, fino_x(960))
	for _ = 1, 10 do
		c.tieni({ right = true, jump = true }, 12)
		c.tieni(DESTRA, 30)
	end
end)
check(esito ~= "fatta", "maglio: saltando e basta non si sale")

-- Punti e Corona: si abbatte quello con la Corona (missile e Lama)
ok = cerca("corona", function(c, a, p)
	c.usa("missile", a, p)
	c.tieni(FERMO, 30)
	c.tieni(DESTRA, fino_x(1080))
	c.usa("sword", 0)
end, nil, { 0, 1, 0.1 }, potenze(0.3, 1, 0.1))
check(ok, "corona: si abbatte chi è primo")

-- La partita guidata: il cronometro del primo turno aspetta il primo colpo, il
-- bot del tutorial fa vedere i due attacchi e poi il teletrasporto nei suoi
-- primi turni, la partita dura 3 minuti. Il giocatore spara un missile per turno.
do
	local replay = require "sim.replay"
	local r = lezioni.nuova("guidata")
	local seed, mappa, opts = lezioni.partita(r, 5)
	local ric = replay.nuova(seed, mappa, opts)
	local g, bots = replay.partita(ric)
	lezioni.prepara(r, g)
	local visti, ticks, esito, fermo = {}, 0, nil, nil
	while not esito and ticks < 60 * 60 * 6 do
		ticks = ticks + 1
		local input = {}
		if g.current == 1 and g.phase == "aim" and not g.used.primary then
			-- al primo turno si aspettano 30 s prima di sparare
			if r.st.turni == 1 and ticks < 1800 then
				fermo = g.timer
			else
				input = { fire = { weapon = "missile", angle = 0.6, power = 0.8 } }
			end
		end
		g:step(replay.input(ric, g, bots, input))
		for _, e in ipairs(g:pop_events()) do
			lezioni.evento(r, g, e, bots)
			if e.robot == 2 then visti[r.st.turni_bot .. e.type] = true end
		end
		esito = lezioni.tick(r, g)
	end
	check(fermo == game.TURN_TICKS, "guidata: al primo turno il cronometro aspetta il primo colpo")
	check(visti["1swing"] or visti["1mallet"] or visti["1eagle"] or visti["1lunge"],
		"guidata: al suo primo turno il bot usa anche la secondaria")
	check(visti["2teleports"] and visti["2teleport"], "guidata: al suo secondo turno il bot guadagna globi e si teletrasporta")
	check(esito == "fatta" and g.phase == "over", "guidata: la partita corta finisce")
	check(ticks < 60 * 60 * 5, "guidata: dura meno di 5 minuti (" .. math.floor(ticks / 60) .. " s)")
end

print(failures == 0 and "\ntutti i test passati" or ("\n" .. failures .. " test falliti"))
os.exit(failures == 0 and 0 or 1)
