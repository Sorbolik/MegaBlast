-- Missioni: le lezioni (Capitolo 0) e i gironi della campagna (sim/campagna.lua),
-- tutte nello stesso formato. Una missione è una partita vera con un obiettivo
-- scritto come dati: pochi verbi (sotto) invece di codice, così un giorno le
-- manda il server e servono anche al rompicapo del giorno (docs/roadmap.md,
-- area 3). Lua puro: il gui_script mostra la riga, l'obiettivo e le stelle.
--
--   local r = missioni.nuova("rampino")
--   local seed, mappa, opts = missioni.partita(r, seed, picks, aiuto)  -- per game.new (o replay.nuova);
--                                                   aiuto: dopo tante perse, avversari più morbidi
--   missioni.prepara(r, g)                          -- subito dopo, una volta
--   missioni.evento(r, g, e, bots)                  -- per ogni evento della simulazione (bots: di replay.partita)
--   local esito = missioni.tick(r, g)               -- a ogni tick: nil, "fatta" o "fallita"
--   local testo, chi = missioni.riga(r)             -- il suggerimento da mostrare sopra il robot chi (o nil)
--   local testo = missioni.obiettivo(r)             -- l'obiettivo che resta, sempre in vista (o nil)
--   missioni.stelle(r)                              -- 1..3 quando è fatta
--   missioni.criteri(l)                             -- cosa serve per ogni stella: { "FATTA", "IN 2 TURNI", ... }
--   missioni.dopo(id)                               -- la missione che viene dopo nel capitolo (nil dopo l'ultima)
--
-- Una missione (campi, tutti dati salvo dove si dice):
--   id, titolo, scopo (la prima riga, finché non si fa la prima cosa)
--   mappa (una mappa del gioco) oppure arena = { { x, y, w, h }, ... } (rettangoli
--     d'acciaio: i crateri non rompono il rompicapo) e spawns (prima il giocatore)
--   giocatori: opts.players di game.new (team, bot = livello, carattere, dummy, pick,
--     secondary, tool, stats); nome: come si chiama quel robot (i custodi)
--   regole: altre opts di game.new; secondi: durata della partita; globi: con
--     quanti teletrasporti parte il giocatore; vita, punti = { [robot] = n } all'inizio;
--     rigenera = { robot, ... }: a ogni turno tornano con la vita piena
--   obiettivo: i passi (sotto), in ordine se non c'è in_ordine = false
--   fallisce = { muori = true, esaurito = "paracadute" } (e sempre se la partita finisce prima)
--   turni: oltre questi turni del giocatore si ricomincia
--   stelle = { 3, 2 } (turni per la seconda e la terza) oppure
--     { turni = 3, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA MORIRE" } }
--   collaudo = { carattere, piano, senza }: come la prova strumenti/arena/collaudo.lua
--   righe = { { testo, quando, fino, su = "bot" } }: quando e fino sono
--     { evento = "crate_pick" }, { passo = 2 } (fatto il passo 2), { turno = 2 }
--     oppure funzioni(st, g, e) per i casi che i dati non dicono (la partita guidata)
--
-- I passi dell'obiettivo (testo: come si legge nella riga dell'obiettivo):
--   { usa = "globi" | "rampino" | "bastione" | "rimbalzo" | "rinculo" | "paracadute" }
--   { raggiungi = { x = 1200, y = 150 } }   in piedi sopra quella quota, oltre quella x
--   { colpisci = 2, con = "sword" | "primaria" | "secondaria" | un'arma }
--   { abbatti = 2 | "nemico", come = "vuoto", con = arma, volte = 3 }
-- Altri verbi (vinci, sopravvivi, proteggi...) entrano con le missioni che li usano.
-- I conteggi per i bonus delle stelle: morti, teletrasporti, vuoto (uccisioni
-- ambientali tue), abbattuti, danni (presi da te).

local game = require "sim.game"
local maps = require "sim.maps"
local terrain = require "sim.terrain"
local campagna = require "sim.campagna"

local M = {}

local STEEL = terrain.STEEL
M.GIOCATORE = 1
local GIOCATORE = M.GIOCATORE
-- secondi di una riga che non ha un "fino": poi sparisce da sola
local RIGA_SECONDI = 5

-- Quale arma ha appena usato chi: l'evento dell'attacco -> nome dell'arma
local ATTACCHI = {
	fire = "missile", grenade = "grenade", shards = "shards", punch = "punch", sniper = "sniper",
	swing = "sword", eagle = "eagle", mallet = "mallet", lunge = "lunge",
}
local CATEGORIE = {
	primaria = { grenade = true, shards = true, punch = true, sniper = true },
	secondaria = { eagle = true, mallet = true, lunge = true },
}
-- usa: l'evento del giocatore che dice che la meccanica è stata usata
local USA = {
	globi = function(e) return e.type == "teleports" and e.amount > 0 end,
	rampino = function(e) return e.type == "hook" and e.anchor end,
	bastione = function(e) return e.type == "wall" and e.v == 1 end,
	rimbalzo = function(e) return e.type == "mallet_hit" and e.bounce end,
	-- il Tonante sparato in aria: il rinculo porta via
	rinculo = function(e, st) return e.type == "eagle" and not st.a_terra end,
	paracadute = function(e) return e.type == "parachute" end,
}

-- Le missioni, per id e per capitolo --------------------------------------------------

local PER_ID, DOPO = {}, {}
for _, cap in ipairs(campagna.CAPITOLI) do
	for i, l in ipairs(cap.missioni) do
		assert(not PER_ID[l.id], "missione doppia: " .. l.id)
		PER_ID[l.id] = l
		l.capitolo = cap.id
		DOPO[l.id] = cap.missioni[i + 1] and cap.missioni[i + 1].id
		if l.arena then
			l.mappa = "missione_" .. l.id
			maps.registra(l.mappa, { name = l.titolo, spawns = l.spawns, build = function(t)
				for _, q in ipairs(l.arena) do t:rect(q[1], q[2], q[3], q[4], STEEL) end
			end })
		end
	end
end

function M.trova(id)
	return PER_ID[id]
end

function M.dopo(id)
	return DOPO[id]
end

-- Lo stato di una missione in corso
function M.nuova(id)
	local l = assert(PER_ID[id], "missione sconosciuta: " .. tostring(id))
	return { l = l, st = { turni = 0, turni_bot = 0, passi = {}, volte = {}, conta = {} }, viste = {}, riga = nil, esito = nil }
end

-- seme, mappa e opzioni di game.new. picks: i giocatori usciti dal draft
-- (menu/scelta.lua), per le missioni che lo fanno fare
-- l'aiuto silenzioso: i bot scendono di un livello e partono con meno vita
local PIU_FACILE = { difficile = "normale", normale = "facile", facile = "facile" }
local AIUTO_VITA = 0.75

function M.partita(r, seed, picks, aiuto)
	local l = r.l
	local players = {}
	r.aiuto = aiuto
	for i, p in ipairs(l.giocatori) do
		local q = {}
		for k, v in pairs(p) do
			if k ~= "nome" then q[k] = v end
		end
		if aiuto and q.bot then q.bot = PIU_FACILE[q.bot] end
		if picks and picks[i] then
			q.pick, q.secondary, q.tool = picks[i].pick, picks[i].secondary, picks[i].tool or q.tool
		end
		players[i] = q
	end
	if l.globi then
		local st = {}
		for k, v in pairs(players[GIOCATORE].stats or {}) do st[k] = v end
		st.teleports = l.globi
		players[GIOCATORE].stats = st
	end
	local opts = { players = players }
	for k, v in pairs(l.regole or {}) do opts[k] = v end
	-- senza casse: le missioni non cambiano col caso
	if not l.guidata and not opts.crate_every then opts.crate_every = 1000 end
	return seed or 1, l.mappa, opts
end

-- Dopo game.new: tempo della partita, vita e punti d'inizio, la prima riga.
-- Gli eventi dell'inizio (il primo turno) li conta qui e li scarta.
function M.prepara(r, g)
	local l, st = r.l, r.st
	if l.secondi then g.match_left = l.secondi * 60 end
	for i, v in pairs(l.vita or {}) do
		g.robots[i].hp, g.robots[i].max_hp = v, math.max(v, g.robots[i].max_hp)
	end
	if r.aiuto then
		for i, p in ipairs(l.giocatori) do
			-- anche la vita piena: la barra resta piena, non si vede
			local rb = g.robots[i]
			if p.bot then rb.hp = math.floor(rb.hp * AIUTO_VITA); rb.max_hp = rb.hp end
		end
	end
	for i, v in pairs(l.punti or {}) do g.robots[i].points = v end
	g:pop_events()
	if g.current == GIOCATORE then st.turni = 1 else st.turni_bot = 1 end
	r.coda = {}
	r.riga = nil
	-- lo scopo finché non si fa la prima cosa
	if l.scopo then
		r.coda[1] = { testo = l.scopo, fino = function(_, g2) return g2.used.primary or g2.used.secondary or g2.used.tool end }
	end
end

-- I passi -----------------------------------------------------------------------------

local function nemici(g, a, b)
	return g.robots[a].team ~= g.robots[b].team
end

local function bersaglio(g, voluto, robot)
	if voluto == "nemico" then return nemici(g, GIOCATORE, robot) end
	return voluto == robot
end

local function arma_ok(con, arma)
	if not con then return true end
	if CATEGORIE[con] then return CATEGORIE[con][arma] == true end
	return con == arma
end

-- in piedi sopra la quota y, oltre la x
local function sopra(g, x, y)
	local rb = g.robots[GIOCATORE]
	return not rb.dead and rb.grounded and rb.x >= x and rb.y >= y - 1
end

-- Il passo p è fatto adesso? e = nil: il controllo a ogni tick
local function passo_fatto(p, i, st, g, e)
	if p.usa then
		return e ~= nil and e.robot == GIOCATORE and USA[p.usa](e, st)
	elseif p.raggiungi then
		return sopra(g, p.raggiungi.x, p.raggiungi.y)
	elseif p.colpisci then
		return e ~= nil and e.type == "damage" and e.amount > 0 and bersaglio(g, p.colpisci, e.robot)
			and arma_ok(p.con, st.arma)
	elseif p.abbatti then
		if e and e.type == "death" and e.by == GIOCATORE and bersaglio(g, p.abbatti, e.robot)
			and (p.come ~= "vuoto" or e.env) and arma_ok(p.con, st.arma) then
			st.volte[i] = (st.volte[i] or 0) + 1
			return st.volte[i] >= (p.volte or 1)
		end
		return false
	end
	error("passo sconosciuto")
end

-- obiettivo fatto? Segna i passi che si chiudono con e
local function obiettivo(l, st, g, e)
	if type(l.obiettivo) == "function" then return l.obiettivo(st, g, e) end
	local tutti = true
	for i, p in ipairs(l.obiettivo) do
		if not st.passi[i] then
			if passo_fatto(p, i, st, g, e) then
				st.passi[i] = true
			else
				tutti = false
				if l.in_ordine ~= false then return false end
			end
		end
	end
	return tutti
end

-- Il primo passo che manca (o nil)
local function prossimo(l, st)
	if type(l.obiettivo) ~= "table" then return nil end
	for i, p in ipairs(l.obiettivo) do
		if not st.passi[i] then return i, p end
	end
end

-- Quando di una riga: funzione, o dati
local function quando(q, st, g, e)
	if type(q) == "function" then return q(st, g, e) end
	if q.evento then
		return e ~= nil and e.type == q.evento and (e.robot == nil or e.robot == GIOCATORE)
	elseif q.passo then
		return st.passi[q.passo] == true
	elseif q.turno then
		return st.turni == q.turno
	end
	return false
end

-- Una riga alla volta: quella nuova aspetta che l'altra sia fatta o scaduta
-- (o che cominci un altro turno).
-- Senza "fino" resta RIGA_SECONDI, con "fino" al massimo il doppio.
local function mostra(r, riga)
	r.riga, r.riga_fino = riga.testo, riga.fino
	r.riga_su = riga.su == "bot" and 2 or GIOCATORE
	r.riga_t = (riga.fino and 2 or 1) * RIGA_SECONDI * 60
end

-- e = nil: il controllo a ogni tick
local function controlla(r, g, e)
	local l, st = r.l, r.st
	if r.esito then return end
	if obiettivo(l, st, g, e) then
		r.esito = "fatta"
		return
	end
	if r.riga and r.riga_fino and quando(r.riga_fino, st, g, e) then r.riga = nil end
	-- un turno nuovo: le righe del turno prima non servono più
	if e and e.type == "turn" then r.riga, r.coda = nil, {} end
	for i, riga in ipairs(l.righe or {}) do
		if not r.viste[i] and quando(riga.quando, st, g, e) then
			r.viste[i] = true
			r.coda[#r.coda + 1] = riga
		end
	end
	if not r.riga and #r.coda > 0 then mostra(r, table.remove(r.coda, 1)) end
end

local function conta(st, k)
	st.conta[k] = (st.conta[k] or 0) + 1
end

function M.evento(r, g, e, bots)
	local l, st = r.l, r.st
	if ATTACCHI[e.type] and e.robot == GIOCATORE then st.arma = ATTACCHI[e.type] end
	if e.type == "turn" then
		if e.robot == GIOCATORE then st.turni = st.turni + 1 else st.turni_bot = st.turni_bot + 1 end
		-- il bot di turno fa vedere quello che il giocatore farà dopo (sim/bot.lua, b.piano)
		local b = bots and bots[e.robot]
		if b then b.piano = l.piani and l.piani[st.turni_bot] or nil end
		for _, i in ipairs(l.rigenera or {}) do
			local rb = g.robots[i]
			if not rb.dead then rb.hp = rb.max_hp end
		end
		-- oltre i turni della missione si ricomincia
		if l.turni and st.turni > l.turni and not r.esito then r.esito = "fallita" end
	elseif e.type == "teleport" and e.robot == GIOCATORE then
		conta(st, "teletrasporti")
	elseif e.type == "damage" and e.robot == GIOCATORE then
		st.conta.danni = (st.conta.danni or 0) + e.amount
	elseif e.type == "death" then
		if e.robot == GIOCATORE then conta(st, "morti") end
		if e.by == GIOCATORE and nemici(g, GIOCATORE, e.robot) then
			conta(st, "abbattuti")
			if e.env then conta(st, "vuoto") end
		end
	elseif e.type == "over" then
		st.finita, st.vinta = true, e.winner == g.robots[GIOCATORE].team
		local me, altri = g.robots[GIOCATORE].points, 0
		for i, rb in ipairs(g.robots) do
			if i ~= GIOCATORE then altri = math.max(altri, rb.points) end
		end
		st.distacco = me - altri
	end
	controlla(r, g, e)
	if r.esito then return end
	local f = l.fallisce or {}
	if (f.muori and e.type == "death" and e.robot == GIOCATORE) or (e.type == "over" and not l.guidata) then
		r.esito = "fallita"
	end
end

function M.tick(r, g)
	local l, st = r.l, r.st
	-- primo turno della partita guidata: il cronometro aspetta il primo colpo
	if l.guidata and st.turni == 1 and g.current == GIOCATORE and g.phase == "aim"
		and not g.used.primary and not g.used.secondary then
		g.timer = game.TURN_TICKS
	end
	controlla(r, g, nil)
	-- a terra o no prima degli eventi del prossimo tick (il Tonante stacca da terra)
	st.a_terra = g.robots[GIOCATORE].grounded
	-- esaurito: la risorsa è finita, sei a terra e il posto da raggiungere no
	local f = l.fallisce
	if not r.esito and f and f.esaurito == "paracadute" then
		local rb = g.robots[GIOCATORE]
		local _, p = prossimo(l, st)
		if rb.grounded and rb.parachutes_left == 0 and p and p.raggiungi then r.esito = "fallita" end
	end
	if r.riga_t then
		r.riga_t = r.riga_t - 1
		if r.riga_t <= 0 then r.riga, r.riga_t = nil, nil end
	end
	return r.esito
end

-- La riga da mostrare e sopra chi (il robot), o nil
function M.riga(r)
	return r.riga, r.riga_su
end

-- L'obiettivo sempre in vista: il passo che manca, col numero se sono più d'uno
function M.obiettivo(r)
	local l = r.l
	local i, p = prossimo(l, r.st)
	if not i or r.esito then return nil end
	local n = #l.obiettivo
	return n > 1 and (i .. "/" .. n .. "  " .. p.testo) or p.testo
end

local function turni(n)
	return "IN " .. n .. (n == 1 and " TURNO" or " TURNI")
end

-- Cosa serve per ogni stella
function M.criteri(l)
	if l.guidata then return { "FINITA", "VINTA", "CON 100 PUNTI DI VANTAGGIO" } end
	local s = l.stelle
	if s.bonus then return { "FATTA", turni(s.turni), s.bonus.testo } end
	return { "FATTA", turni(s[1]), turni(s[2]) }
end

local function bonus(b, st)
	local n = st.conta[b.conta] or 0
	if b.al_massimo then return n <= b.al_massimo end
	return n >= b.almeno
end

-- Stelle: una per averla fatta, poi i turni e il bonus (o due soglie di
-- turni). Nella partita guidata: finita, vinta, vinta con 100 punti di distacco.
function M.stelle(r)
	if r.esito ~= "fatta" then return 0 end
	local l, st = r.l, r.st
	if l.guidata then
		if not st.vinta then return 1 end
		return st.distacco >= 100 and 3 or 2
	end
	local s = l.stelle
	if s.bonus then
		return 1 + (st.turni <= s.turni and 1 or 0) + (bonus(s.bonus, st) and 1 or 0)
	end
	if st.turni <= s[2] then return 3 end
	if st.turni <= s[1] then return 2 end
	return 1
end

return M
