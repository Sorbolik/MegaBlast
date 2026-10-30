-- Test della campagna (sim/campagna.lua, sim/missioni.lua): ogni lezione si
-- risolve davvero con la sua meccanica, e senza no; ogni missione parte pulita.
-- Quanto sono difficili i gironi lo misura il collaudo coi bot
-- (strumenti/arena/collaudo.lua). Dalla radice del repository:
--   luajit tests/campagna_test.lua
-- Le soluzioni sono copioni di tasti; dove serve una mira, il test la cerca
-- su una griglia di angoli e potenze, come farebbe chi prova.
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local missioni = require "sim.missioni"
local campagna = require "sim.campagna"

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
-- Il giocatore dei test tocca quello che la lezione mette in luce (il tempo
-- è fermo finché non lo fa) e, prima di usare un'arma, la sceglie
local function obbedisci(r, input)
	local a = r.attende
	if a then missioni.tocca(r, a == "primaria" and "missile" or a == "secondaria" and "sword" or a) end
	if input and input.fire then
		missioni.tocca(r, input.fire.weapon)
		missioni.tocca(r, "mira")
	end
	if input and input.jump then missioni.tocca(r, "salta") end
	if input and (input.left or input.right) then missioni.tocca(r, "cammina") end
end

local function gioca(id, copione, picks, limite)
	local r = missioni.nuova(id)
	local seed, mappa, opts = missioni.partita(r, 3, picks)
	local g = game.new(seed, mappa, opts)
	missioni.prepara(r, g)
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
		-- un tasto qualsiasi: nelle lezioni il tempo parte da qui
		obbedisci(r, input)
		if next(input) then missioni.tocca(r) end
		g:step(input)
		for _, e in ipairs(g:pop_events()) do missioni.evento(r, g, e) end
		local esito = missioni.tick(r, g)
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

-- Ogni missione: i robot partono appoggiati, e senza fare niente non è fatta
for _, cap in ipairs(campagna.CAPITOLI) do
for _, l in ipairs(cap.missioni) do
	if not l.guidata and not l.giocatori[2].bot then
		local esito, r, g = gioca(l.id, function() end, nil, 60 * 30 * (l.turni or 2) + 600)
		local giu = true
		for _, rb in ipairs(g.robots) do
			if rb.dead then giu = false end
		end
		check(giu, l.id .. ": nessuno cade da solo")
		-- (e qualcosa dice cosa fare: la riga, o senza tempo l'obiettivo sempre in vista)
		local detto = r.riga ~= nil or (l.senza_tempo and missioni.obiettivo(r) ~= nil)
		check(esito ~= "fatta" and detto or esito == "fallita", l.id .. ": senza fare niente non si finisce")
	end
	-- ogni stella dice cosa serve, e l'obiettivo si legge
	check(#missioni.criteri(l) == 3, l.id .. ": tre criteri per le stelle")
	if type(l.obiettivo) == "table" then
		local r = missioni.nuova(l.id)
		check(missioni.obiettivo(r) ~= nil, l.id .. ": l'obiettivo si vede")
	end
end
end

-- Nelle lezioni niente cerchi di cura: dopo quattro turni senza fare niente non ce n'è nessuno
do
	local _, _, g = gioca("corona", function(c)
		for _ = 1, 3 do
			c.tieni(DESTRA, 1)
			c.turno()
		end
	end, nil, 60 * 30 * 12)
	check(#g.heals == 0 and g.turn_no >= 4, "lezioni: niente cerchi di cura")
end

-- Primi passi: bandierina, gradino, la cassa col Lanciarune, il bersaglio.
-- Niente tempo né turni; senza la cassa non si spara; chi manca ritenta subito
local function al_bersaglio(c)
	c.tieni(DESTRA, fino_x(1075))
	c.tieni({ right = true, jump = true }, 40)
	c.tieni(DESTRA, fino_x(1180))
	-- la cassa cade sul gradino: le si va incontro
	c.tieni(DESTRA, function(g) return g.robots[1].x >= 1260 or g.robots[1].disarmed == nil end)
	c.tieni(FERMO, function(g) return g.robots[1].disarmed == nil end)
end
do
	local esito, r, g = gioca("primi_passi", function(c)
		c.tieni(DESTRA, fino_x(1000))
		c.usa("missile", 0.5, 0.6)
		c.tieni(FERMO, 60 * 60)
	end)
	check(esito == nil and r.st.passi[1] and not r.st.passi[2], "primi_passi: camminando soltanto il gradino non si sale")
	check(g.turn_no == 1 and g.current == 1, "primi_passi: niente turni, anche dopo un minuto")
	check(not g.projectile and #g.crates == 0 and not game.has_weapon(g.robots[1], "missile") and not g:can_use("missile"),
		"primi_passi: senza la cassa niente armi")
end
local ok, r, a, p = cerca("primi_passi", function(c, a, p)
	al_bersaglio(c)
	c.usa("missile", a, p)
end, nil, { 0.1, 1.3, 0.05 }, potenze(0.3, 1, 0.1))
check(ok, "primi_passi: bandierina, gradino, cassa e il bersaglio col Lanciarune")
if ok then
	check(missioni.vede(r, "missile") and missioni.quante(missioni.stelle(r)) == 3, "primi_passi: al primo tiro tre stelle")
	-- un tiro a vuoto (verso il cielo dietro di sé): si ritenta subito, nello stesso turno
	local esito2, r3, g3 = gioca("primi_passi", function(c)
		al_bersaglio(c)
		c.usa("missile", 2.6, 0.3)
		c.tieni(FERMO, function(gg) return not gg.used.primary end)
		c.usa("missile", a, p)
	end)
	check(esito2 == "fatta" and r3.st.conta.mancati == 1 and g3.turn_no == 1, "primi_passi: chi manca ritenta subito")
	check(missioni.quante(missioni.stelle(r3)) == 2, "primi_passi: un tiro a vuoto, due stelle")
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
if ok then check(missioni.quante(missioni.stelle(r)) == 3, "armi: in due turni sono tre stelle") end
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

-- Il Tonante: salto, colpo in basso a mezz'aria, il rinculo porta sul pilastro, poi il missile (il Tonante è già la secondaria del turno)
ok = cerca("tonante", function(c, a, p)
	c.tieni(DESTRA, fino_x(975))
	c.tieni({ jump = true, right = true }, 30)
	c.usa("eagle", -math.pi / 2 - 0.2)
	c.tieni(DESTRA, function(g) return g.robots[1].grounded end)
	c.tieni(FERMO, 10)
	c.usa("missile", a, p)
end, nil, { 0, 0.6, 0.1 }, potenze(0.3, 1, 0.1))
check(ok, "tonante: il rinculo porta sul pilastro")
esito = gioca("tonante", function(c)
	c.tieni(DESTRA, fino_x(960))
	for _ = 1, 10 do
		c.tieni({ right = true, jump = true }, 12)
		c.tieni(DESTRA, 30)
	end
end)
check(esito ~= "fatta", "tonante: saltando e basta non si sale")

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

-- Giù dal bordo: ognuno dei tre bersagli si butta giù dal suo scoglio con un missile solo
for chi = 2, 4 do
	local trovato = false
	for a = -0.5, 3.6, 0.05 do
		for p = 0.2, 1, 0.05 do
			if not trovato then
				local _, _, g = gioca("giu_dal_bordo", function(c)
					c.usa("missile", a, p)
					c.tieni(FERMO, 400)
				end, nil, 420)
				trovato = g.robots[1].env_kills > 0 and g.robots[chi].deaths > 0
			end
		end
	end
	check(trovato, "giu_dal_bordo: il bersaglio " .. chi .. " cade con un colpo")
end

-- Giù dal bordo col Rampino: dal bordo della piattaforma l'uncino arriva agli
-- scogli dei lati (mappa invariata, gittata config.HOOK.range) e il bersaglio,
-- tirato per reel e mollato sopra il vuoto, cade
for chi, lato in pairs({ [2] = -1, [3] = 1 }) do
	local trovato = false
	for a = 0, 0.6, 0.02 do
		if not trovato then
			local angolo = lato < 0 and math.pi - a or a
			local _, _, g = gioca("giu_dal_bordo", function(c)
				c.tieni(lato < 0 and SINISTRA or DESTRA, function(g2)
					local x = g2.robots[1].x
					return lato < 0 and x <= 775 or lato > 0 and x >= 1145
				end)
				c.tieni(FERMO, 10)
				c.usa("hook", angolo)
				c.tieni(FERMO, 300)
			end, nil, 900)
			trovato = g.robots[1].env_kills > 0 and g.robots[chi].deaths > 0
		end
	end
	check(trovato, "giu_dal_bordo: dal bordo il Rampino prende il bersaglio " .. chi .. " e lo butta giù")
end

-- Punti e Corona: si abbatte quello con la Corona (missile e Lama)
ok = cerca("corona", function(c, a, p)
	c.usa("missile", a, p)
	c.tieni(FERMO, 30)
	c.tieni(DESTRA, fino_x(1080))
	c.usa("sword", 0)
end, nil, { 0, 1, 0.1 }, potenze(0.3, 1, 0.1))
check(ok, "corona: si abbatte chi è primo")

-- La partita guidata: il cronometro aspetta che si tocchino i comandi, il
-- bot del tutorial fa vedere i due attacchi e poi il teletrasporto nei suoi
-- primi turni, la partita dura 3 minuti. Il giocatore spara un missile per turno.
do
	local replay = require "sim.replay"
	local r = missioni.nuova("guidata")
	local seed, mappa, opts = missioni.partita(r, 5)
	local ric = replay.nuova(seed, mappa, opts)
	local g, bots = replay.partita(ric)
	missioni.prepara(r, g)
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
				missioni.tocca(r)
			end
		end
		if not (r.st.turni == 1 and ticks < 1800) then obbedisci(r, input) end
		g:step(replay.input(ric, g, bots, input))
		for _, e in ipairs(g:pop_events()) do
			missioni.evento(r, g, e, bots)
			if e.robot == 2 then visti[r.st.turni_bot .. e.type] = true end
		end
		esito = missioni.tick(r, g)
	end
	check(fermo == game.TURN_TICKS, "guidata: al primo turno il cronometro aspetta che si tocchino i comandi")
	check(visti["1swing"] or visti["1mallet"] or visti["1eagle"] or visti["1lunge"],
		"guidata: al suo primo turno il bot usa anche la secondaria")
	check(visti["2teleports"] and visti["2teleport"], "guidata: al suo secondo turno il bot guadagna globi e si teletrasporta")
	check(esito == "fatta" and g.phase == "over", "guidata: la partita corta finisce")
	check(ticks < 60 * 60 * 5, "guidata: dura meno di 5 minuti (" .. math.floor(ticks / 60) .. " s)")
end

-- Due mani: sbagliato il primo turno il bot torna alla sua vita della
-- missione (28), non a 150: si può ancora finire
do
	local r = missioni.nuova("due_mani")
	local seed, mappa, opts = missioni.partita(r, 3)
	local g = game.new(seed, mappa, opts)
	missioni.prepara(r, g)
	local rb = g.robots[2]
	rb.hp = 10
	missioni.evento(r, g, { type = "turn", robot = 2 })
	check(rb.hp == 46 and rb.max_hp == 46, "due_mani: il bot si rimette a 46, non alla vita normale")
end
-- e chi rinasce rinasce con la vita della missione (Fuori portata: 40)
for _, l in ipairs(campagna.CAPITOLI[2].missioni) do
	if l.vita then
		local r = missioni.nuova(l.id)
		local seed, mappa, opts = missioni.partita(r, 3)
		local g = game.new(seed, mappa, opts)
		missioni.prepara(r, g)
		for i, v in pairs(l.vita) do
			check(g.robots[i].max_hp == v, l.id .. ": la vita piena (e della rinascita) è quella della missione")
		end
	end
end

-- Ogni stella col suo criterio: in 6 turni senza morire sono la prima e la
-- terza, non la seconda (e nel profilo ogni stella presa resta)
do
	local r = missioni.nuova("primo_sangue")
	r.esito, r.st.turni = "fatta", 6
	local s = missioni.stelle(r)
	check(s[1] and not s[2] and s[3], "stelle: il bonus senza i turni accende la terza e non la seconda")
	local profilo = require "menu.profilo"
	local p = profilo.nuovo()
	profilo.missione(p, "primo_sangue", s)
	profilo.missione(p, "primo_sangue", { true, true, false })
	check(profilo.stelle_totali(p) == 3, "stelle: nel profilo ognuna presa resta")
end

-- L'aiuto dopo tante perse: il Fabbro scende di livello e parte con meno vita,
-- ma con la barra piena (non si vede)
do
	local function fabbro(aiuto)
		local r = missioni.nuova("il_fabbro")
		local seed, mappa, opts = missioni.partita(r, 7, nil, aiuto)
		local g = game.new(seed, mappa, opts)
		missioni.prepara(r, g)
		return opts.players[2].bot, g.robots[2]
	end
	local liv, rb = fabbro(false)
	local liv_aiuto, rb_aiuto = fabbro(true)
	check(liv == "normale" and liv_aiuto == "facile", "aiuto: il bot scende di un livello")
	check(rb_aiuto.hp < rb.hp and rb_aiuto.hp == rb_aiuto.max_hp, "aiuto: meno vita, barra piena")
end

print(failures == 0 and "\ntutti i test passati" or ("\n" .. failures .. " test falliti"))
os.exit(failures == 0 and 0 or 1)
