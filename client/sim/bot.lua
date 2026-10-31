-- Bot avversario: gioca il turno di un robot premendo gli stessi tasti di un
-- giocatore (l'input di game:step), quindi non bara e va bene anche online.
-- Lua puro e deterministico (il caso viene da un generatore suo): lo usano il
-- telefono (partite contro i bot) e l'arena (strumenti/arena), e lo userà il
-- server per riempire le code.
--
--   local bot = require "sim.bot"
--   local b = bot.new(id, "normale", seed, pesi, carattere)   -- id del robot, livello (o grado, M.GRADI), seme, pesi e carattere (facoltativi, vedi M.PESI e M.CARATTERI)
--   local input = bot.input(b, g)           -- a ogni tick, prima di g:step(input)
--   bot.scegli(d, i, seed, armi)            -- primaria e secondaria nella scelta (sim/draft.lua)
--   b.piano = { due_attacchi = true }       -- (facoltativo, per il turno che viene) primaria e secondaria
--   b.piano = { attacca_entro = 4, poi = "teletrasporto" }  -- attacca una volta entro 4 s, poi si teletrasporta al riparo
--
-- Come pensa: prova le mosse su copie della partita (bot.mondo), con la
-- stessa fisica del gioco (game:advance) ma senza crateri, così sa cosa
-- succede davvero. Prova dove andare camminando e saltando (e col
-- teletrasporto), da lì le armi che ha verso ogni avversario, e sceglie la
-- mossa che vale più punti partita (config.SCORE). Pensa poco alla volta: un
-- tetto di lavoro per tick (livello.lavoro), così il telefono non scatta.

local game = require "sim.game"
local C = require "sim.config"
local rng = require "sim.rng"
local rete = require "sim.rete"

local M = {}

-- Livelli. reazione: tick prima di agire; mira e potenza: errore massimo
-- (radianti, frazione); sbaglia: probabilità di scegliere una mossa peggiore
-- della migliore; cammino: tick di strada provati per lato; potenze: quante
-- potenze prova per i colpi a parabola; teletrasporto, rampino, oggetti: se li
-- usa; lavoro: tick di simulazione provati per tick di gioco; manca: un
-- attacco su due sbaglia apposta (mira provata sulla copia perché non prenda).
-- tutorial: il bot "maestro" della partita guidata, che si deve battere.
M.LIVELLI = {
	tutorial = { reazione = 90, mira = 0.02, potenza = 0.02, sbaglia = 0, cammino = 200, potenze = 2,
		teletrasporto = false, rampino = false, oggetti = false, lavoro = 400, manca = true },
	facile = { reazione = 80, mira = 0.09, potenza = 0.08, sbaglia = 0.4, cammino = 150, potenze = 2,
		teletrasporto = false, rampino = false, oggetti = false, lavoro = 400 },
	normale = { reazione = 45, mira = 0.035, potenza = 0.03, sbaglia = 0.15, cammino = 300, potenze = 3,
		teletrasporto = true, rampino = true, oggetti = false, lavoro = 400 },
	difficile = { reazione = 20, mira = 0.008, potenza = 0.008, sbaglia = 0, cammino = 420, potenze = 5,
		teletrasporto = true, rampino = true, oggetti = true, lavoro = 400 },
}
M.ORDINE = { "facile", "normale", "difficile" }

-- I gradi della campagna (Sergio, 30 ottobre 2026: "vorrei sentire una bella
-- progressione graduale"): un livello, i campi che cambiano (liv) e i pesi.
-- Misurati a coppie, 1 contro 1, 300 partite: ogni grado batte quello sotto
-- nel 55-75% delle partite (2/1 63%, 3/2 65%, 4/3 75%, 5/4 58%, 6/5 55%,
-- 7/6 58%, 8/7 59%, 9/8 56%; il 10 è il picchiatore di evolvi.py, 54% contro
-- il difficile). Il salto più grande è il globo: il facile non lo usa mai.
-- Nella campagna players[i].bot può essere il numero del grado.
local picchiatore = {}
for k, v in pairs(C.SCORE) do picchiatore[k] = v end
picchiatore.env_kill, picchiatore.kill, picchiatore.damage = C.SCORE.env_kill * 1.86, C.SCORE.kill * 1.57, C.SCORE.damage * 0.94
M.GRADI = {
	{ livello = "tutorial" },
	{ livello = "facile" },
	{ livello = "facile", liv = { teletrasporto = true }, pesi = { teletrasporto = 20 } },
	{ livello = "facile", liv = { teletrasporto = true }, pesi = { teletrasporto = 50 } },
	{ livello = "facile", liv = { teletrasporto = true, rampino = true, mira = 0.06, sbaglia = 0.3 }, pesi = { teletrasporto = 50 } },
	{ livello = "normale", liv = { mira = 0.055, potenza = 0.05, sbaglia = 0.25 } },
	{ livello = "normale" },
	{ livello = "normale", liv = { mira = 0.02, potenza = 0.015, sbaglia = 0.05, oggetti = true } },
	{ livello = "difficile" },
	{ livello = "difficile", pesi = { vita_mia = 0.12, vita_compagno = 2.77, morte = 77, strada = 0.0025, teletrasporto = 119,
		globo_riparo = 8.9, punteggio = picchiatore, armi = { punch = 1.51, mallet = 1.51, lunge = 1.51, sword = 1.51,
		sniper = 0.5, missile = 0.5, grenade = 0.5, shards = 0.5, eagle = 0.5, bellows = 1.09 } } },
}

-- I pesi del bot: come vale il risultato di una mossa oltre ai punti partita.
-- vita_mia, vita_compagno: per punto di vita perso; morte: in più del
-- punteggio, se muore lui o un compagno; strada: quanto costa un tick di strada
-- (a parità di colpo, quello più vicino); teletrasporto: sotto questo punteggio
-- dalla strada a piedi prova il teletrasporto (100 dal 29 ottobre: la rete che
-- impara si teletrasportava molto più del bot e vinceva, e con 100 il bot batte
-- quello di prima nel 72% delle partite); globo_riparo: il riparo col globo
-- vince su quello a piedi se vale almeno tanto di più; punteggio (se c'è): i punti
-- con cui il bot giudica le mosse, al posto di quelli della partita; armi (se
-- c'è): il gusto per ogni arma (moltiplica i colpi che rendono e guida la scelta
-- d'inizio partita, M.scegli). L'arena li fa evolvere
-- (strumenti/arena/evolvi.py) e una partita può darne altri a ogni bot
-- (players[i].pesi, solo i campi che cambiano). rete (se c'è): una rete
-- neurale (sim/rete.lua) che aggiunge il suo giudizio a quello di questi pesi,
-- dalle caratteristiche della posizione dopo la mossa (M.caratteristiche); la allena
-- strumenti/arena/impara.py;
-- esplora: probabilità di scegliere apposta una delle mosse dopo la migliore;
-- larga: prova anche i colpi a ventaglio che non puntano nessuno (per le reti).
M.PESI = { vita_mia = 0.6, vita_compagno = 1, morte = 60, strada = 0.01, teletrasporto = 100, globo_riparo = 3 }

-- Caratteri: come gioca un bot, oltre al livello (quanto è bravo). Sono solo
-- pesi diversi da M.PESI, quindi il bot non bara: preme sempre i tasti di un
-- giocatore. Li usano la campagna (sim/campagna.lua, players[i].carattere) e i
-- custodi dei gironi. codardo: a ogni turno attacca subito (così guadagna i
-- globi) e poi scappa col globo nella tana peggiore, coperta e dove nessuno lo
-- vede (tana: quanto conta; piano: il piano di ogni turno); testa_calda:
-- va addosso anche a costo di morire; cecchino: tira da dove sta e cammina
-- poco; spingitore: cerca il vuoto (l'uccisione ambientale vale il triplo).
local spinta = {}
for k, v in pairs(C.SCORE) do spinta[k] = v end
spinta.env_kill = C.SCORE.env_kill * 3
M.CARATTERI = {
	codardo = { vita_mia = 2, morte = 120, teletrasporto = 225, tana = 12,
		piano = { attacca_entro = 4, poi = "teletrasporto" } },
	testa_calda = { vita_mia = 0.15, morte = 15, strada = 0.004 },
	cecchino = { strada = 0.05, teletrasporto = 25 },
	spingitore = { punteggio = spinta },
}
-- mosse provate fino in fondo (fino a quando tutto è fermo) tra le migliori
local FINALISTE = 4
local POTENZE = { 1, 0.75, 0.55, 0.88, 0.42 }

local FERMO = {}

-- Copie della partita --------------------------------------------------------------

local function copia(t)
	local o = {}
	for k, v in pairs(t) do o[k] = v end
	return o
end

local function clona(rb)
	local c = copia(rb)
	c.ammo = copia(rb.ammo)
	c.life_damage = copia(rb.life_damage)
	local st = {}
	for k, s in pairs(rb.status) do st[k] = copia(s) end
	c.status = st
	if rb.hooked then c.hooked = copia(rb.hooked) end
	if rb.hook_shot then c.hook_shot = copia(rb.hook_shot) end
	return c
end

-- Nelle copie l'esplosione non scava: il terreno è quello vero, in comune
local function senza_cratere(self, x, y, owner, blast, weapon)
	blast = blast or game.MISSILE_BLAST
	self:emit({ type = "explosion", x = x, y = y, r = blast.r })
	self:blast(x, y, owner, blast, weapon)
end

-- Una copia della partita su cui provare le mosse: robot, colpi, oggetti e
-- generatore sono copiati, il terreno è in comune ma non viene toccato. Le
-- regole del turno (fine turno, casse, cure) non girano: si usa game:advance.
function M.mondo(g)
	local w = setmetatable({}, game)
	w.terrain, w.map, w.tick, w.mode, w.normalized = g.terrain, g.map, g.tick, g.mode, g.normalized
	w.current, w.phase, w.timer, w.window, w.teleports = g.current, g.phase, g.timer, g.window, g.teleports
	w.teleports_earned = g.teleports_earned
	w.match_left, w.final_round, w.round, w.order, w.order_pos, w.turn_no = g.match_left, g.final_round, g.round, g.order, g.order_pos, g.turn_no
	w.orb_seq, w.placed_id, w.heals, w.score = g.orb_seq, g.placed_id, g.heals, g.score
	w.rng = rng.new(g.rng.state)
	w.used = copia(g.used)
	w.events, w.crates = {}, {}
	w.robots, w.orbs, w.placed, w.shards = {}, {}, {}, {}
	for i, rb in ipairs(g.robots) do w.robots[i] = clona(rb) end
	for i, o in ipairs(g.orbs) do w.orbs[i] = copia(o) end
	for i, o in ipairs(g.placed) do w.placed[i] = copia(o) end
	for i = 1, game.SHARD_COUNT do
		if g.shards[i] then w.shards[i] = copia(g.shards[i]) end
	end
	w.projectile = g.projectile and copia(g.projectile)
	w.burst = g.burst and copia(g.burst)
	w.explode = senza_cratere
	return w
end

-- Tutto fermo: niente in volo, robot a terra e senza colpi in corso
local function quieto(w)
	if w.projectile or w.burst or #w.orbs > 0 then return false end
	for i = 1, game.SHARD_COUNT do
		if w.shards[i] then return false end
	end
	for _, rb in ipairs(w.robots) do
		if not rb.dead and (not rb.grounded or rb.swing or rb.punch or rb.lunge or rb.recoil or rb.hooked or rb.hook_shot or rb.mallet) then
			return false
		end
	end
	return true
end
M.quieto = quieto

-- Lavoro: ogni prova costa tick simulati; finito il lavoro del tick si aspetta
-- il tick dopo (coroutine.yield). Fuori da una coroutine non si ferma mai.
local function lavora(b, n)
	b.lavoro = b.lavoro + n
	-- in tutto, per i test e per misurare
	M.totale = (M.totale or 0) + n
	if b.lavoro >= b.liv.lavoro and coroutine.running() then
		coroutine.yield()
	end
end

-- Fa andare avanti la copia, per al massimo max tick, finché tutto è fermo
local function fino_a_quieto(b, w, max)
	local nr = #w.robots
	for t = 1, max do
		w.tick = w.tick + 1
		w:advance(FERMO, true)
		if t % 10 == 0 then
			lavora(b, 40 * nr)
			if quieto(w) then return t end
		end
	end
	return max
end

-- Solo i colpi in volo (i robot restano fermi): dove scoppiano e chi colpiscono
local function in_volo(b, w, max)
	for t = 1, max do
		w.tick = w.tick + 1
		if w.projectile then w:update_projectile() end
		if w.burst then w:update_burst() end
		w:update_shards()
		if not w.projectile and not w:shards_flying() then return t end
		if t % 10 == 0 then lavora(b, 10) end
	end
	return max
end

-- Il terreno tra due punti è libero? (a passi di 9 px: basta per sapere se
-- un nemico ha la linea di tiro, e costa poco)
local function libero(t, x0, y0, x1, y1)
	local dx, dy = x1 - x0, y1 - y0
	local n = math.floor(math.sqrt(dx * dx + dy * dy) / 9)
	for i = 1, n - 1 do
		if t:solid(x0 + dx * i / n, y0 + dy * i / n) then return false end
	end
	return true
end

-- Quanto è vicino il vuoto: dei punti a lato (fino a 96 px) quanti non hanno
-- terra sotto entro 60 px, da 0 a 1
local LATI = { -96, -64, -36, -12, 12, 36, 64, 96 }
local function bordo(t, x, y)
	local n = 0
	for _, d in ipairs(LATI) do
		local gb = t:ground_below(x + d, y + 4)
		if not gb or y - gb > 60 then n = n + 1 end
	end
	return n / #LATI
end

-- C'è roccia sopra la testa (fino a 150 px)? Lì i colpi a parabola non arrivano
local function coperto(t, x, y)
	for k = 30, 150, 30 do
		if t:solid(x, y + k) then return 1 end
	end
	return 0
end

-- Le caratteristiche della copia w (dopo una mossa) rispetto alla partita
-- vera g, per il robot del bot: quello che la rete guarda. Numeri vicini a
-- -1..1 (punti e vita a centinaia, distanze a migliaia di pixel).
--   1-20   punti, vita e morti guadagnati e persi, la posizione, lo scarto
--   21-44  gli altri tre robot (prima i compagni, poi i nemici dal più
--          vicino), 8 numeri ciascuno: c'è, nemico, dx, dy, vita, morto,
--          vuoto vicino, si vedono
--   45-54  le armi che ha e quanti colpi (M.ARMI_RETE), 55-58 globi, scudo, chi gioca dopo,
--          roccia sopra la testa
--   59-60  ultimo giro (punti doppi), la Corona (1 la sua squadra, -1 un nemico)
--   61     la fase: 1 subito dopo gli attacchi (prima del riparo), 0 a fine turno.
--          La rete giudica gli attacchi con 1 e i ripari con 0: una posizione
--          scoperta dopo un colpo non è quella in cui il robot finirà il turno
--   62-138 il terreno intorno: 11 x 7 caselle da 64 px, 1 dove è pieno
M.ARMI_RETE = { "missile", "grenade", "shards", "punch", "sniper", "sword", "eagle", "mallet", "lunge", "bellows" }
local GRIGLIA_X, GRIGLIA_Y, CASELLA = 5, 3, 64
M.CARATTERISTICHE = 61 + (2 * GRIGLIA_X + 1) * (2 * GRIGLIA_Y + 1)
local ALTRI = {}
local function caratteristiche(b, g, w, x, fase)
	local me = g.robots[b.id]
	local c = w.robots[b.id]
	for i = 1, M.CARATTERISTICHE do x[i] = 0 end
	local squadre = {}
	for i, o in ipairs(w.robots) do
		local r = g.robots[i]
		local dp = o.points - r.points
		local persa = r.dead and 0 or (o.dead and r.hp or math.max(0, r.hp - o.hp))
		squadre[o.team] = (squadre[o.team] or 0) + o.points
		if i == b.id then
			x[1] = dp / 100
			x[4] = persa / 100
			x[7] = (o.dead and not r.dead) and 1 or 0
		elseif o.team == me.team then
			x[2] = x[2] + dp / 100
			x[5] = x[5] + persa / 100
			x[8] = x[8] + ((o.dead and not r.dead) and 1 or 0)
		else
			x[3] = x[3] + dp / 100
			x[6] = x[6] + persa / 100
			x[9] = x[9] + ((o.dead and not r.dead) and 1 or 0)
		end
	end
	-- la posizione dopo la mossa
	x[10] = c.dead and 0 or c.hp / 100
	local t = w.terrain
	local cy = c.y + game.DISEGNO_H / 2
	local vicino, somma, n, sopra, a_tiro, vedono = math.huge, 0, 0, 0, 0, 0
	for _, o in ipairs(w.robots) do
		if not o.dead and o.team ~= me.team then
			local dx, dy = o.x - c.x, o.y - c.y
			local d = math.sqrt(dx * dx + dy * dy)
			vicino = math.min(vicino, d)
			somma, n, sopra = somma + d, n + 1, sopra + dy
			if d < 200 then a_tiro = a_tiro + 1 end
			if d < 900 and libero(t, c.x, cy, o.x, o.y + game.DISEGNO_H / 2) then vedono = vedono + 1 end
		end
	end
	if n > 0 then
		x[11] = math.min(vicino, 1500) / 1000
		x[12] = somma / n / 1000
		x[13] = sopra / n / 500
	end
	x[14] = c.dead and 1 or bordo(t, c.x, c.y)
	x[15] = a_tiro
	x[16] = vedono
	x[17] = math.min(c.x, game.WORLD_W - c.x) / 1000
	x[18] = c.y / game.WORLD_H
	-- lo scarto dalla squadra avversaria più avanti
	local primo = -math.huge
	for _, team in ipairs({ 1, 2, 3, 4 }) do
		if team ~= me.team and squadre[team] then primo = math.max(primo, squadre[team]) end
	end
	x[19] = primo > -math.huge and ((squadre[me.team] or 0) - primo) / 100 or 0
	x[20] = g.match_left / game.MATCH_TICKS
	-- gli altri robot, uno per uno
	local n_altri = 0
	for _, o in ipairs(w.robots) do
		if o.id ~= b.id then
			n_altri = n_altri + 1
			ALTRI[n_altri] = o
		end
	end
	for k = n_altri + 1, #ALTRI do ALTRI[k] = nil end
	table.sort(ALTRI, function(p, q)
		local cp, cq = p.team == me.team, q.team == me.team
		if cp ~= cq then return cp end
		local dp, dq = (p.x - c.x) ^ 2 + (p.y - c.y) ^ 2, (q.x - c.x) ^ 2 + (q.y - c.y) ^ 2
		if dp ~= dq then return dp < dq end
		return p.id < q.id
	end)
	for k = 1, math.min(3, n_altri) do
		local o, i = ALTRI[k], 20 + (k - 1) * 8
		x[i + 1] = 1
		x[i + 2] = o.team ~= me.team and 1 or 0
		x[i + 3] = (o.x - c.x) / 1000
		x[i + 4] = (o.y - c.y) / 500
		x[i + 5] = o.dead and 0 or o.hp / 100
		x[i + 6] = o.dead and 1 or 0
		if not o.dead then
			x[i + 7] = bordo(t, o.x, o.y)
			local dx, dy = o.x - c.x, o.y - c.y
			if dx * dx + dy * dy < 900 * 900 and libero(t, c.x, cy, o.x, o.y + game.DISEGNO_H / 2) then x[i + 8] = 1 end
		end
	end
	-- le armi (1 se ha colpi infiniti, se no i colpi che restano, fino a 4), i globi, lo scudo
	for k, a in ipairs(M.ARMI_RETE) do
		local v = 0
		if game.has_weapon(c, a) then
			local n = not game.FREE_WEAPONS[a] and c.ammo[a]
			v = n and math.min(n, 4) / 4 or 1
		end
		x[44 + k] = v
	end
	x[55] = (c.teleports_left or 0) / 3
	x[56] = c.shield and 1 or 0
	-- chi gioca dopo: 1 un nemico
	local ordine = w.order
	for k, id in ipairs(ordine) do
		if id == b.id then
			local dopo = w.robots[ordine[k % #ordine + 1]]
			x[57] = (dopo and dopo.team ~= me.team) and 1 or 0
			break
		end
	end
	x[58] = c.dead and 0 or coperto(t, c.x, c.y + game.DISEGNO_H)
	-- l'ultimo giro e la Corona
	x[59] = w.final_round and 1 or 0
	local corona = w:leader()
	x[60] = corona and (corona.team == me.team and 1 or -1) or 0
	x[61] = fase or 0
	-- il terreno intorno
	local i = 61
	for gy = GRIGLIA_Y, -GRIGLIA_Y, -1 do
		for gx = -GRIGLIA_X, GRIGLIA_X do
			i = i + 1
			local px, py = c.x + gx * CASELLA, cy + gy * CASELLA
			x[i] = (px >= 0 and px < game.WORLD_W and py >= 0 and py < game.WORLD_H and t:solid(px, py)) and 1 or 0
		end
	end
	return x
end
M.caratteristiche = caratteristiche

local CAR = {}

-- Quanto vale la copia w rispetto alla partita vera g, per il robot del bot
-- Con la rete: il giudizio di qui sopra più quello che la rete aggiunge (lei
-- impara solo la differenza fra questo e quanto rende davvero la posizione,
-- così parte già brava e non deve reimparare da zero che un colpo che prende vale)
-- fase (caratteristiche): 1 per gli attacchi (se non si dice), 0 per il riparo
local function valore(b, g, w, fase)
	local me = g.robots[b.id]
	local s = 0
	for i, c in ipairs(w.robots) do
		local r = g.robots[i]
		if not r.dead then
			local dp = c.points - r.points
			local persa = c.dead and r.hp or math.max(0, r.hp - c.hp)
			if c.team == me.team then
				s = s + dp - persa * (i == b.id and b.pesi.vita_mia or b.pesi.vita_compagno)
				if c.dead then s = s - b.pesi.morte end
			else
				s = s - dp
			end
		end
	end
	if b.pesi.rete then
		fase = fase or 1
		-- negli attacchi la rete giudica solo le finaliste (b.finale), provate
		-- fino in fondo: fra centinaia di colpi provati in fretta vincerebbe
		-- quello su cui la rete sbaglia di più in alto (31 ottobre: la rete su
		-- tutti gli attacchi 35% contro il bot di oggi, solo sul riparo 54%).
		-- rete_attacco (0..1): quanto conta lì, per misurarla
		local quanto = fase ~= 1 and 1 or b.finale and (b.pesi.rete_attacco or 1) or 0
		local registra = b.finale and b.registro
		if quanto > 0 or registra then
			local x = caratteristiche(b, g, w, CAR, fase)
			if quanto > 0 then s = s + quanto * rete.valuta(b.pesi.rete, x) * 100 end
			-- per impara.py: quello che la rete ha visto di questa finalista
			if registra then b.visto = copia(x) end
		end
	end
	return s
end

-- Distanza dal nemico più vicino a (x, y): a parità di danno, un colpo che
-- cade vicino vale un pizzico di più (così anche da lontano si avvicina)
local function vicinanza(g, me, x, y)
	local best = math.huge
	for _, o in ipairs(g.robots) do
		if not o.dead and o.team ~= me.team then
			local dx, dy = o.x - x, o.y + game.HURT_Y - y
			best = math.min(best, dx * dx + dy * dy)
		end
	end
	return -math.sqrt(best) / 1000
end

-- Mosse ----------------------------------------------------------------------------
-- Una mossa: dove andare (posto: x, y, strada) e cosa fare lì
-- (arma, angolo, potenza), col suo punteggio.

-- Mette il robot del bot nel posto della copia, fermo a terra
local function in_posto(w, id, posto)
	local c = w.robots[id]
	if posto.strada then
		c.x, c.y, c.vx, c.vy = posto.x, posto.y, 0, 0
		c.grounded, c.knocked, c.rising = true, false, false
		c.facing = posto.facing
	end
	return c
end

-- Chi prenderebbe adesso il colpo da vicino arma mirato ad angolo: lo prova su
-- una copia della partita fino alla fine del colpo. out[1..k] = id dei robot
-- colpiti, torna k. Serve alla mira delle armi da vicino (battaglia/mira.lua).
local COLPI = { sword_hit = true, punch_hit = true, mallet_hit = true, lunge_hit = true, bellows_hit = true }
function M.colpiti(g, arma, angolo, out)
	local w = M.mondo(g)
	w:attack(arma, { weapon = arma, angle = angolo, power = 1 })
	local rb = w.robots[w.current]
	for _ = 1, 4 * 60 do
		if not (rb.swing or rb.punch or rb.mallet or rb.lunge) then break end
		w.tick = w.tick + 1
		w:advance(FERMO, true)
	end
	local k = 0
	for _, e in ipairs(w.events) do
		if COLPI[e.type] and e.target then
			k = k + 1
			out[k] = e.target
		end
	end
	return k
end

-- Prova un attacco dal posto. fino: "volo" (solo i colpi) o "tutto" (finché
-- tutto è fermo). Restituisce il punteggio.
local function prova(b, g, posto, arma, angolo, potenza, fino)
	local w = M.mondo(g)
	w.score = b.pesi.punteggio or g.score
	lavora(b, 20)
	local c = in_posto(w, b.id, posto)
	local fire = { weapon = arma, angle = angolo, power = potenza }
	if game.TOOLS[arma] then w:use_tool(arma, fire) else w:attack(arma, fire) end
	local px, py = c.x, c.y
	if fino == "volo" and (w.projectile or w.burst) then
		in_volo(b, w, 6 * 60)
	else
		fino_a_quieto(b, w, fino == "volo" and 90 or 5 * 60)
	end
	local s = valore(b, g, w)
	if s == 0 and not b.pesi.rete then
		-- niente colpito: conta dove è scoppiato
		for _, e in ipairs(w.events) do
			if e.type == "explosion" then px, py = e.x, e.y end
		end
		s = vicinanza(g, g.robots[b.id], px, py)
	end
	return s
end

-- Il Rampino sul nemico numero chi, e poi il colpo migliore con le armi di
-- lista (dritto verso di lui, a tutta potenza): quanto vale tutto insieme
local function prova_rampino(b, g, posto, angolo, chi, lista)
	local w = M.mondo(g)
	w.score = b.pesi.punteggio or g.score
	lavora(b, 20)
	local c = in_posto(w, b.id, posto)
	w:use_tool("hook", { weapon = "hook", angle = angolo, power = 1 })
	fino_a_quieto(b, w, 3 * 60)
	local o = w.robots[chi]
	local meglio = valore(b, g, w)
	if c.dead or o.dead then return meglio end
	local a = math.atan2(o.y + game.HURT_Y - (c.y + game.DISEGNO_H / 2), o.x - c.x)
	for _, arma in ipairs(lista) do
		if w:can_use(arma) then
			local w2 = M.mondo(w)
			lavora(b, 20)
			w2:attack(arma, { weapon = arma, angle = a, power = 1 })
			fino_a_quieto(b, w2, 4 * 60)
			meglio = math.max(meglio, valore(b, g, w2))
		end
	end
	return meglio
end

-- Angoli per colpire (dx, dy) partendo a velocità v con gravità gr (le due
-- parabole, bassa e alta)
local function parabole(dx, dy, v, gr, out)
	local v2 = v * v
	local disc = v2 * v2 - gr * (gr * dx * dx + 2 * dy * v2)
	if disc < 0 then return end
	local r = math.sqrt(disc)
	out[#out + 1] = math.atan2(v2 - r, gr * dx)
	out[#out + 1] = math.atan2(v2 + r, gr * dx)
end

-- Ordine delle mosse: la migliore prima, a pari punti la prima trovata
-- (table.sort non è stabile e LuaJIT e gopher-lua ordinano i pari in modo
-- diverso: senza questo client e server sceglierebbero mosse diverse)
local function prima(x, y)
	if x.punti ~= y.punti then return x.punti > y.punti end
	return x.k < y.k
end

-- Le armi a parabola: velocità massima, gravità, punta il centro o i piedi
local PARABOLA = {
	missile = function() return game.MISSILE_SPEED, game.GRAVITY * game.MISSILE_GRAVITY end,
	grenade = function() return game.GRENADE_SPEED, game.GRAVITY * game.GRENADE_GRAVITY end,
}

-- Gli avversari vivi, dal più vicino al posto
local function nemici(g, me, x, y)
	local out = {}
	for _, o in ipairs(g.robots) do
		if not o.dead and o.team ~= me.team then out[#out + 1] = o end
	end
	table.sort(out, function(a, c)
		local da, dc = (a.x - x) ^ 2 + (a.y - y) ^ 2, (c.x - x) ^ 2 + (c.y - y) ^ 2
		if da ~= dc then return da < dc end
		return a.id < c.id
	end)
	return out
end

-- Le armi che il robot può usare adesso nella partita vera (primarie e secondarie)
local function armi(g, rb)
	local out = {}
	local function prendi(w)
		if g:can_use(w) then out[#out + 1] = w end
	end
	prendi("missile")
	for _, w in ipairs(game.CRATE_WEAPONS) do prendi(w) end
	prendi("sword")
	if rb.secondary then prendi(rb.secondary) end
	return out
end

-- Il gusto per l'arma (pesi.armi, per gli specialisti): un colpo che rende
-- vale tanto di più quanto piace l'arma
local function gusto(b, arma, s)
	local g = b.pesi.armi and b.pesi.armi[arma]
	if g and s > 0 then return s * g end
	return s
end

-- La guida (le reti, strumenti/arena/impara.py): una rete piccola che da
-- pochi numeri di una mossa, prima di provarla, dice quanto promette. Con la
-- guida il bot prova il ventaglio da ogni posto, ma sulla copia solo i
-- pesi.guida_k colpi che promettono di più, più qualcuno a turno perché la
-- guida impari anche da quelli: il ventaglio da ogni posto senza pagarlo in
-- tempo del turno. La guida la allena la scheda video.
--   1-11  l'arma (M.ARMI_RETE e il Rampino), 12-14 coseno e seno dell'angolo
--         e potenza, 15-17 il posto (dx, dy, tick di strada), 18 vuoto
--         vicino al posto, 19 il nemico più vicino al posto (distanza), 20
--         quanto il colpo va verso di lui, 21-22 vita sua e del nemico
M.DESCRIZIONE = 22
local ARMA_N = {}
for k, a in ipairs(M.ARMI_RETE) do ARMA_N[a] = k end
ARMA_N.hook = #M.ARMI_RETE + 1

local function descrivi(b, g, m, d)
	for i = 1, M.DESCRIZIONE do d[i] = 0 end
	local me = g.robots[b.id]
	local posto = m.posto
	if ARMA_N[m.arma] then d[ARMA_N[m.arma]] = 1 end
	d[12], d[13], d[14] = math.cos(m.angolo), math.sin(m.angolo), m.potenza
	d[15], d[16], d[17] = (posto.x - me.x) / 1000, (posto.y - me.y) / 500, (posto.n or 0) / 300
	d[18] = bordo(g.terrain, posto.x, posto.y)
	local vicino, dv = nil, math.huge
	for _, o in ipairs(g.robots) do
		if not o.dead and o.team ~= me.team then
			local dd = (o.x - posto.x) ^ 2 + (o.y - posto.y) ^ 2
			if dd < dv then vicino, dv = o, dd end
		end
	end
	if vicino then
		d[19] = math.sqrt(dv) / 1000
		d[20] = math.cos(m.angolo - math.atan2(vicino.y - posto.y, vicino.x - posto.x))
		d[22] = vicino.hp / 100
	end
	d[21] = me.hp / 100
	return d
end
M.descrivi = descrivi

-- Una mossa da provare: con la guida si mette da parte (b.proposte), se no si
-- prova subito sulla copia. b.diario (arena.lua --impara): per i colpi del
-- ventaglio con nota, la descrizione e quanto ha reso, per allenare la guida
-- (nota "conta": uno ogni 23).
local DESCR = {}
local function proponi(b, g, posto, arma, a, p, fino, mosse, nota)
	local m = { posto = posto, arma = arma, angolo = a, potenza = p, fino = fino }
	if b.proposte then
		b.proposte[#b.proposte + 1] = m
		return
	end
	local s = gusto(b, arma, prova(b, g, posto, arma, a, p, fino))
	m.punti, m.k = s - (posto.n or 0) * b.pesi.strada, #mosse + 1
	mosse[#mosse + 1] = m
	if b.diario and nota then
		b.conta = (b.conta or 0) + 1
		if nota == true or b.conta % 23 == 0 then
			local d = descrivi(b, g, m, {})
			for i = 1, #d do d[i] = math.floor(d[i] * 1000 + 0.5) / 1000 end
			b.diario[#b.diario + 1] = { d = d, v = math.floor(m.punti * 10 + 0.5) / 1000 }
		end
	end
end

-- Il ventaglio delle mosse larghe: le potenze provate per arma e fin dove si
-- prova il colpo in fretta (le armi da vicino fino in fondo)
local VENTAGLIO = {
	missile = { 1, 0.7, 0.45, fino = "volo" }, grenade = { 1, 0.7, 0.45, fino = "volo" },
	shards = { 1, fino = "volo" }, sniper = { 1, fino = "volo" },
	bellows = { 1, fino = "tutto" }, lunge = { 1, fino = "tutto" },
}

-- Tutte le mosse da un posto, provate in fretta (solo il volo per i colpi a
-- distanza). Le aggiunge a mosse.
local function mosse_dal_posto(b, g, posto, lista_armi, mosse)
	local me = g.robots[b.id]
	local x, y = posto.x, posto.y
	local cy = y + game.DISEGNO_H / 2
	local bersagli = nemici(g, me, x, y)
	local function aggiungi(arma, a, p, fino)
		proponi(b, g, posto, arma, a, p, fino, mosse)
	end
	for k, o in ipairs(bersagli) do
		if k > 2 then break end
		local ox, oy = o.x, o.y + game.HURT_Y
		local dx, dy = ox - x, oy - cy
		local dist = math.sqrt(dx * dx + dy * dy)
		local dritto = math.atan2(dy, dx)
		for _, arma in ipairs(lista_armi) do
			local par = PARABOLA[arma]
			if par then
				local v, gr = par()
				local mira = { oy }
				if arma == "grenade" then mira = { o.y + 2 } end
				for n = 1, b.liv.potenze do
					local p = POTENZE[n]
					for _, ty in ipairs(mira) do
						local angoli = {}
						-- la bocca è a game.MUZZLE dal centro, nella direzione del colpo
						parabole(dx, ty - cy, v * p, gr, angoli)
						for _, a in ipairs(angoli) do
							local mx, my = math.cos(a) * game.MUZZLE, math.sin(a) * game.MUZZLE
							local giusti = {}
							parabole(ox - x - mx, ty - cy - my, v * p, gr, giusti)
							-- delle due parabole, quella dalla stessa parte (bassa o alta)
							local g2 = giusti[a == angoli[1] and 1 or 2]
							if g2 then aggiungi(arma, g2, p, "volo") end
						end
					end
				end
			elseif arma == "shards" then
				local angoli = {}
				parabole(dx, dy, game.SHARD_SPEED, game.GRAVITY * game.SHARD_GRAVITY, angoli)
				if angoli[1] then aggiungi(arma, angoli[1], 1, "volo") end
			elseif arma == "sniper" then
				if dist < 900 then
					for _, su in ipairs({ 0, 0.05, 0.12, 0.2 }) do
						aggiungi(arma, dritto + (dx < 0 and -su or su), 1, "volo")
					end
				end
			elseif arma == "eagle" then
				if dist < C.EAGLE.range then aggiungi(arma, dritto, 1, "tutto") end
			elseif arma == "lunge" then
				if dist < C.LUNGE.speed * C.LUNGE.ticks / 60 + C.LUNGE.reach then
					aggiungi(arma, dritto, 1, "tutto")
					aggiungi(arma, dritto + (dx < 0 and -0.15 or 0.15), 1, "tutto")
				end
			elseif arma == "bellows" then
				-- il soffio: dritto o un po' in su, per staccarlo da terra verso il vuoto
				if dist < C.BELLOWS.range then
					aggiungi(arma, dritto, 1, "tutto")
					aggiungi(arma, dritto + (dx < 0 and -0.35 or 0.35), 1, "tutto")
				end
			elseif arma == "mallet" then
				if math.abs(dx) < C.MALLET.reach + 30 and math.abs(dy) < C.MALLET.reach + 30 then
					-- l'arco gira con la mira: dritto e verso il nemico
					aggiungi(arma, dx < 0 and math.pi or 0, 1, "tutto")
					aggiungi(arma, dritto, 1, "tutto")
				end
			elseif arma == "sword" or arma == "punch" then
				if dist < 80 then aggiungi(arma, dritto, 1, "tutto") end
			end
		end
	end
end

-- larga (le reti, strumenti/arena/impara.py): anche i colpi che non puntano
-- nessuno, a ventaglio, così la rete può scoprire mosse che il bot di oggi
-- non prova mai (scavare, rimbalzi, colpi alti che ricadono). Solo da due
-- posti (dove sta e quello della mossa migliore): il pensiero costa tempo del
-- turno, e da ogni posto il ventaglio faceva perdere (19% contro il bot di oggi)
local function ventaglio(b, g, posto, lista_armi, mosse)
	for _, arma in ipairs(lista_armi) do
		local v = VENTAGLIO[arma]
		if v then
			for _, p in ipairs(v) do
				for a = -40, 220, 20 do proponi(b, g, posto, arma, math.rad(a), p, v.fino, mosse, "conta") end
			end
		end
	end
end

-- Posti dove si arriva camminando (e saltando) da dove si è: per ogni lato
-- due modi (ai bordi salta o scende). Ogni posto ha la strada: i tasti tick
-- per tick (dirs: -1, 0, 1; salti: true dove si salta).
local function posti_a_piedi(b, g, max)
	local me = g.robots[b.id]
	local posti = { { x = me.x, y = me.y, facing = me.facing, n = 0 } }
	if max <= 0 or not me.grounded then return posti end
	local w = M.mondo(g)
	local hw = game.ROBOT_HALF_W
	for _, d in ipairs({ -1, 1 }) do
		for _, salta_bordi in ipairs({ true, false }) do
			local c = clona(me)
			w.robots[b.id] = c
			local dirs, salti = {}, {}
			local strada = { dirs = dirs, salti = salti }
			local input = { left = d < 0, right = d > 0, jump = false, hold = true }
			local fermo_da, ultimo_x = 0, c.x
			for t = 1, max do
				local salta = false
				if c.grounded then
					if w:terrain_collides(c.x + d * 3, c.y + game.MAX_CLIMB) then
						salta = true
					elseif salta_bordi then
						local gb = w.terrain:ground_below(c.x + d * (hw + 6), c.y + 2)
						if not gb or c.y - gb > 50 then salta = true end
					end
				end
				input.jump = salta
				dirs[t], salti[t] = d, salta
				w:update_robot(c, input, true)
				if c.dead or c.y < 40 then break end
				if math.abs(c.x - ultimo_x) >= 1 then fermo_da, ultimo_x = t, c.x end
				if t - fermo_da > 40 then break end
				if c.grounded and t % 6 == 0 then
					local nuovo = true
					for _, p in ipairs(posti) do
						if math.abs(p.x - c.x) < 24 and math.abs(p.y - c.y) < 20 then
							nuovo = false
							break
						end
					end
					if nuovo then
						posti[#posti + 1] = { x = c.x, y = c.y, facing = c.facing, n = t, strada = strada }
					end
				end
				if t % 10 == 0 then lavora(b, 40) end
			end
		end
	end
	return posti
end

-- Il posto dove porta un globo del teletrasporto lanciato ora con (a, p), o nil
local function posto_teletrasporto(b, g, a, p)
	local w = M.mondo(g)
	local c = w.robots[b.id]
	w:throw_orb(a, p)
	local t = 0
	while #w.orbs > 0 and t < 6 * 60 do
		t = t + 1
		w:update_orbs()
		if t % 10 == 0 then lavora(b, 10) end
	end
	for _ = 1, 3 * 60 do
		if c.grounded or c.dead then break end
		t = t + 1
		w:update_robot(c, FERMO, true)
		if t % 10 == 0 then lavora(b, 40) end
	end
	if c.dead or not c.grounded or c.y < 60 then return nil end
	return { x = c.x, y = c.y, facing = c.facing, n = t, strada = { dirs = {}, salti = {} }, globo = { a, p } }
end

-- Un angolo vicino a quello della mossa m con cui il colpo non fa male a
-- nessuno (provato sulla copia), per il livello che sbaglia apposta
local function angolo_che_manca(b, g, m)
	for _, d in ipairs({ 0.3, -0.3, 0.5, -0.5, 0.8, -0.8 }) do
		local w = M.mondo(g)
		lavora(b, 20)
		in_posto(w, b.id, m.posto)
		w:attack(m.arma, { weapon = m.arma, angle = m.angolo + d, power = m.potenza })
		fino_a_quieto(b, w, 5 * 60)
		local nessuno = true
		for i, c in ipairs(w.robots) do
			local r = g.robots[i]
			if not r.dead and (c.dead or c.hp < r.hp) then
				nessuno = false
				break
			end
		end
		if nessuno then return m.angolo + d end
	end
	return m.angolo + 0.8
end

-- Il pensiero: sceglie la mossa del momento. Mette in b.scelta la migliore
-- trovata finora, così se il tempo stringe si usa quella.
local function pensa(b, g)
	local me = g.robots[b.id]
	local liv = b.liv
	-- quanto tempo resta per camminare: il turno, o i secondi dopo il primo attacco
	local resta = g.window > 0 and g.window or g.timer
	local lista = armi(g, me)
	local mosse = {}
	local cammino = math.min(liv.cammino, resta - 90)
	local piano = b.piano
	if piano and piano.attacca_entro and not (g.used.primary or g.used.secondary) then
		-- il primo attacco entro attacca_entro secondi dall'inizio del turno
		cammino = math.min(cammino, piano.attacca_entro * 60 - (g.tick - b.inizio) - 40)
	end
	local posti = posti_a_piedi(b, g, cammino)
	local guida = b.pesi.guida
	if guida and #lista > 0 then
		-- i colpi mirati da tutti i posti come sempre; il ventaglio da tutti i
		-- posti, ma si provano solo i colpi che la guida dice più promettenti
		for _, posto in ipairs(posti) do mosse_dal_posto(b, g, posto, lista, mosse) end
		b.proposte = {}
		for _, posto in ipairs(posti) do ventaglio(b, g, posto, lista, mosse) end
		local proposte = b.proposte
		b.proposte = nil
		for i, m in ipairs(proposte) do
			m.punti, m.k = rete.valuta(guida, descrivi(b, g, m, DESCR)), i
			if i % 50 == 0 then lavora(b, 20) end
		end
		table.sort(proposte, prima)
		local k = b.pesi.guida_k or 20
		for i, m in ipairs(proposte) do
			-- le prime k, e una su 40 delle altre (a turno, senza caso) perché la
			-- guida veda anche come rendono le mosse che scarta. Nel diario va
			-- una su 80 di tutte, buone e scartate allo stesso modo: se la guida
			-- imparasse solo dalle sue prime k (tutte buone) non saprebbe più
			-- distinguere le buone dalle cattive
			if i <= k or (i + b.attacchi) % 40 == 0 then
				proponi(b, g, m.posto, m.arma, m.angolo, m.potenza, m.fino, mosse, (i + b.attacchi) % 80 == 0)
			end
		end
	else
		for _, posto in ipairs(posti) do
			if #lista > 0 then mosse_dal_posto(b, g, posto, lista, mosse) end
		end
		table.sort(mosse, prima)
		if b.pesi.larga and #lista > 0 then
			ventaglio(b, g, posti[1], lista, mosse)
			if mosse[1] and mosse[1].posto ~= posti[1] then ventaglio(b, g, mosse[1].posto, lista, mosse) end
		end
	end
	table.sort(mosse, prima)
	b.scelta = mosse[1]

	-- il Rampino porta un nemico lontano a tiro: vale quanto il colpo migliore
	-- che si può dare dopo averlo tirato (provato sulla copia)
	if liv.rampino and g:can_use("hook") and #lista > 0 then
		local cx, cy = me.x, me.y + game.DISEGNO_H / 2
		for k, o in ipairs(nemici(g, me, me.x, me.y)) do
			if k > 2 then break end
			local dx, dy = o.x - cx, o.y + game.HURT_Y - cy
			local d = math.sqrt(dx * dx + dy * dy)
			if d > 80 and d < C.HOOK.range then
				local a = math.atan2(dy, dx)
				local mx, my = math.cos(a) * game.MUZZLE, math.sin(a) * game.MUZZLE
				local _, _, hit = g:ray(cx + mx, cy + my, a, C.HOOK.range, me)
				if hit == o then
					mosse[#mosse + 1] = { posto = posti[1], arma = "hook", angolo = a, potenza = 1, chi = o.id,
						punti = prova_rampino(b, g, posti[1], a, o.id, lista), k = #mosse + 1 }
				end
			end
		end
	end

	-- le migliori si provano fino in fondo: chi cade, chi muore, dove finisce chi spara
	table.sort(mosse, prima)
	local finaliste = math.min(b.pesi.larga and 2 * FINALISTE or FINALISTE, #mosse)
	b.finale = true
	for i = 1, finaliste do
		local m = mosse[i]
		b.visto = nil
		if m.arma ~= "hook" then
			m.punti = gusto(b, m.arma, prova(b, g, m.posto, m.arma, m.angolo, m.potenza, "tutto")) - (m.posto.n or 0) * b.pesi.strada
		elseif b.pesi.rete then
			-- anche il Rampino col giudizio della rete, come le altre finaliste
			m.punti = prova_rampino(b, g, m.posto, m.angolo, m.chi, lista)
		end
		m.visto = b.visto
	end
	b.finale = false
	-- col ventaglio (e con la rete, che giudica solo le finaliste) si sceglie
	-- solo fra le finaliste: fra migliaia di colpi
	-- provati in fretta qualcuno sembra sempre meglio di quanto è (31 ottobre:
	-- senza questo il ventaglio da solo vinceva il 19% contro il bot di oggi)
	if b.pesi.larga or b.pesi.rete then
		-- una tabella nuova: in gopher-lua (il server) i buchi in fondo lasciano
		-- # più lungo e table.sort troverebbe dei nil
		local tenute = {}
		for i = 1, finaliste do tenute[i] = mosse[i] end
		mosse = tenute
	end
	table.sort(mosse, prima)
	b.scelta = mosse[1]

	-- se a piedi non c'è niente di buono, il teletrasporto verso un posto migliore
	-- (non col piano poi = "teletrasporto": il globo serve per scappare)
	local best = mosse[1] and mosse[1].punti or -math.huge
	local scappa = piano and piano.poi == "teletrasporto"
	if liv.teletrasporto and not scappa and best < b.pesi.teletrasporto and g:can_use("teleport") and resta > 6 * 60 then
		local migliore
		for a = 20, 160, 20 do
			for _, p in ipairs({ 0.45, 0.7, 0.95 }) do
				local posto = posto_teletrasporto(b, g, math.rad(a), p)
				if posto then
					local qui = {}
					mosse_dal_posto(b, g, posto, lista, qui)
					for _, m in ipairs(qui) do
						if not migliore or m.punti > migliore.punti then migliore = m end
					end
				end
			end
		end
		if migliore and migliore.punti > best + 10 then
			-- si lancia il globo; arrivati, si ripensa da lì
			local globo = migliore.posto.globo
			b.scelta = { posto = posti[1], arma = "teleport", angolo = globo[1], potenza = globo[2], punti = migliore.punti }
			return
		end
	end

	-- a volte (livelli bassi) una mossa meno buona, ma non una che fa male a sé
	-- o al compagno (punti sotto zero quando la migliore non lo è). esplora:
	-- lo stesso per i bot che imparano (strumenti/arena/impara.py), che così
	-- vedono anche mosse che non sceglierebbero
	-- il bivio (arena.lua --impara con --confronta): le due finaliste migliori
	-- si giocano tutte e due su due copie della partita fino al turno dopo, e
	-- la rete impara quale rendeva di più (da una partita sola vedrebbe solo
	-- la mossa scelta). b.forza: nella copia, alla decisione n si prende la j
	b.decisioni = (b.decisioni or 0) + 1
	local forza = b.forza
	if forza and forza.n == b.decisioni then
		b.scelta = mosse[forza.j] or mosse[1]
		return
	end
	if b.bivio and mosse[2] and mosse[1].visto and mosse[2].visto then b.bivio(b, g, mosse) end
	local sbaglia = b.pesi.esplora or liv.sbaglia
	if sbaglia > 0 and #mosse > 1 and b.rng:next() < sbaglia then
		local m = mosse[1 + math.floor(b.rng:next() * math.min(3, #mosse))]
		if m.punti >= math.min(0, mosse[1].punti) then b.scelta = m end
	end

	-- piano due_attacchi: se l'arma che resta non arriva al nemico da nessun
	-- posto, ci si avvicina più che si può e la si usa lo stesso
	if not b.scelta and piano and piano.due_attacchi and #lista > 0 then
		local o = nemici(g, me, me.x, me.y)[1]
		if o then
			local vicino = posti[1]
			for _, p in ipairs(posti) do
				if math.abs(p.x - o.x) < math.abs(vicino.x - o.x) then vicino = p end
			end
			local a = math.atan2(o.y + game.HURT_Y - (vicino.y + game.DISEGNO_H / 2), o.x - vicino.x)
			b.scelta = { posto = vicino, arma = lista[#lista], angolo = a, potenza = 1, punti = 0 }
		end
	end

	-- livello manca: un attacco su due (il primo, il terzo...) non deve prendere
	local m = b.scelta
	if liv.manca and m and not game.TOOLS[m.arma] and b.attacchi % 2 == 0 then
		m.angolo = angolo_che_manca(b, g, m)
	end
	-- b.registro (arena.lua --impara): la posizione dopo l'attacco scelto come
	-- l'ha giudicata la rete; l'arena ci aggiunge com'è andata davvero
	if b.registro and m and m.visto then b.registro[#b.registro + 1] = m.visto end
end

-- Il riparo: finiti gli attacchi, il tempo che resta si usa per mettersi al
-- sicuro dal turno degli altri (a piedi o col Rampino su un appiglio). Con la
-- rete decide lei dove; senza, lontano dai nemici, fuori dalla loro linea di
-- tiro e lontano dal vuoto.
local function riparo(b, g, w)
	if b.pesi.rete then return valore(b, g, w, 0) end
	local x = caratteristiche(b, g, w, CAR)
	if x[7] == 1 then return -1000 end
	local s = x[11] * 10 - x[16] * 4 - x[14] * 8 - x[15] * 3 - x[4] * 50
	-- la tana del codardo: coperto e che nessuno vede
	local tana = b.pesi.tana
	if tana then
		local c = w.robots[b.id]
		s = s + tana * (2 * coperto(w.terrain, c.x, c.y + game.DISEGNO_H) - x[16])
	end
	return s
end

-- le potenze dei lanci del globo per scappare
local LANCI, LANCI_TANA = { 0.45, 0.7, 0.95 }, { 0.3, 0.45, 0.6, 0.75, 0.9, 1 }

local function ripara(b, g)
	local me = g.robots[b.id]
	local resta = g.window > 0 and g.window or g.timer
	-- piano poi = "teletrasporto": al riparo col globo invece che a piedi;
	-- altrimenti il globo si confronta con i posti a piedi e col Rampino e
	-- vince se è meglio di almeno pesi.globo_riparo
	-- (chi cerca la tana prova più lanci, per trovare anche i buchi stretti)
	local col_globo = b.piano and b.piano.poi == "teletrasporto"
	local globo
	if (col_globo or b.liv.teletrasporto) and g:can_use("teleport") then
		local migliore
		local passo = b.pesi.tana and 10 or 20
		for a = passo, 180 - passo, passo do
			for _, p in ipairs(b.pesi.tana and LANCI_TANA or LANCI) do
				local posto = posto_teletrasporto(b, g, math.rad(a), p)
				if posto then
					local w = M.mondo(g)
					in_posto(w, b.id, posto)
					local s = riparo(b, g, w)
					if not migliore or s > migliore.punti then
						migliore = { posto = { x = me.x, y = me.y, n = 0 }, arma = "teleport", angolo = math.rad(a), potenza = p, punti = s }
					end
				end
			end
		end
		if migliore and col_globo then
			b.scelta = migliore
			return
		end
		globo = migliore
	end
	local posti = posti_a_piedi(b, g, math.min(b.liv.cammino, resta - 30))
	local migliore
	for _, posto in ipairs(posti) do
		local w = M.mondo(g)
		in_posto(w, b.id, posto)
		lavora(b, 20)
		local s = riparo(b, g, w) - (posto.n or 0) * b.pesi.strada
		if not migliore or s > migliore.punti then migliore = { posto = posto, punti = s } end
	end
	if b.liv.rampino and g:can_use("hook") and resta > 3 * 60 then
		for gradi = 15, 165, 25 do
			local a = math.rad(gradi)
			local w = M.mondo(g)
			lavora(b, 20)
			w:use_tool("hook", { weapon = "hook", angle = a, power = 1 })
			fino_a_quieto(b, w, 3 * 60)
			local c = w.robots[b.id]
			if not c.dead and c.grounded and math.abs(c.x - me.x) + math.abs(c.y - me.y) > 40 then
				local s = riparo(b, g, w)
				if s > migliore.punti then
					migliore = { posto = posti[1], arma = "hook", angolo = a, potenza = 1, punti = s }
				end
			end
		end
	end
	if globo and globo.punti > migliore.punti + b.pesi.globo_riparo then migliore = globo end
	b.scelta = migliore
end

-- Il turno ----------------------------------------------------------------------------

-- Generatore del bot: semi vicini (stesso seme della partita, robot diversi)
-- darebbero numeri quasi uguali ai primi passi di Park-Miller (sim/rng.lua),
-- quindi se ne scartano alcuni
local function generatore(seme)
	local r = rng.new(seme)
	for _ = 1, 4 do r:next() end
	return r
end

function M.new(id, livello, seed, pesi, carattere)
	local grado = M.GRADI[livello] or {}
	local liv = M.LIVELLI[grado.livello or livello] or M.LIVELLI.normale
	if grado.liv then
		liv = copia(liv)
		for k, v in pairs(grado.liv) do liv[k] = v end
	end
	local p = copia(M.PESI)
	for k, v in pairs(grado.pesi or {}) do p[k] = v end
	local car = carattere and assert(M.CARATTERI[carattere], "carattere sconosciuto: " .. carattere) or {}
	for k, v in pairs(car) do
		if k ~= "piano" then p[k] = v end
	end
	for k, v in pairs(pesi or {}) do p[k] = v end
	-- piano_suo: il piano del carattere, per i turni che non ne hanno un altro
	return { id = id, livello = livello, liv = liv, pesi = p, rng = generatore((seed or 1) * 7919 + id), lavoro = 0,
		attacchi = 0, piano_suo = car.piano }
end

-- Rumore tra -1 e 1, più spesso vicino a 0
local function rumore(b)
	return b.rng:next() + b.rng:next() - 1
end

-- Ricomincia a pensare (dopo aver aspettato attesa tick); come: pensa
-- (l'attacco) o ripara
local function ripensa(b, attesa, come)
	b.stato, b.attesa, b.scelta, b.passo = "pensa", attesa, nil, 0
	b.co = coroutine.create(come or pensa)
end

-- Niente più da attaccare: una volta per turno si cerca riparo, poi si sta fermi
local function basta(b)
	if b.riparato then
		b.stato = "fine"
	else
		b.riparato = true
		ripensa(b, 5, ripara)
	end
end

-- In aria sopra il vuoto, nel proprio turno: il paracadute (e verso la terra
-- più vicina). Restituisce l'input, o nil se non serve.
local function salvataggio(b, g, rb)
	if rb.grounded or rb.vy > -30 or rb.lunge or rb.recoil or rb.hooked then return nil end
	local t = g.terrain
	if t:ground_below(rb.x, rb.y) then
		if not rb.parachute then return nil end
	end
	if not rb.parachute and g:can_use("parachute") then
		return { fire = { weapon = "parachute", angle = 0, power = 0 } }
	end
	-- la colonna con la terra più vicina, da quella parte
	for d = 20, 600, 20 do
		for _, s in ipairs({ -1, 1 }) do
			local x = rb.x + s * d
			if x > 30 and x < game.WORLD_W - 30 and t:ground_below(x, rb.y) then
				return { left = s < 0, right = s > 0 }
			end
		end
	end
	return nil
end

-- L'input del bot per questo tick (FERMO se non è il suo turno)
function M.input(b, g)
	local rb = g.robots[b.id]
	if g.current ~= b.id or g.phase ~= "aim" or rb.dead then
		b.turno = nil
		return FERMO
	end
	if b.turno ~= g.turn_no then
		b.turno, b.riparato, b.inizio = g.turn_no, false, g.tick
		b.piano = b.piano or b.piano_suo
		local piano = b.piano
		ripensa(b, (piano and piano.attacca_entro) and math.min(b.liv.reazione, 20) or b.liv.reazione)
	end
	local salva = salvataggio(b, g, rb)
	if salva then return salva end

	if b.stato == "pensa" then
		b.attesa = b.attesa - 1
		if coroutine.status(b.co) ~= "dead" then
			b.lavoro = 0
			local ok, err = coroutine.resume(b.co, b, g)
			if not ok then error(err) end
			-- il tempo stringe: si usa la mossa migliore trovata finora
			local entro = b.piano and b.piano.attacca_entro and not (g.used.primary or g.used.secondary)
				and g.tick - b.inizio >= b.piano.attacca_entro * 60 - 30
			if coroutine.status(b.co) ~= "dead" and (g.window > 0 and g.window or g.timer) > 45 and not entro then return FERMO end
		end
		if b.attesa > 0 then return FERMO end
		if not b.scelta then
			basta(b)
			return FERMO
		end
		b.stato, b.passo = "vai", 0
	end

	if b.stato == "vai" then
		local s = b.scelta
		local strada = s.posto.strada
		b.passo = b.passo + 1
		if strada and b.passo <= s.posto.n then
			local d = strada.dirs[b.passo]
			return { left = d < 0, right = d > 0, jump = strada.salti[b.passo], hold = true }
		end
		-- solo strada (il riparo): arrivato
		if not s.arma then
			b.stato = "fine"
			return FERMO
		end
		-- arrivato: il colpo, con l'errore del livello
		if not g:can_use(s.arma) then
			ripensa(b, 10)
			return FERMO
		end
		local a = s.angolo + rumore(b) * b.liv.mira
		local p = math.max(0.1, math.min(1, s.potenza + rumore(b) * b.liv.potenza))
		if not game.TOOLS[s.arma] and s.arma ~= "teleport" then b.attacchi = b.attacchi + 1 end
		b.stato, b.attesa = "aspetta", 0
		return { fire = { weapon = s.arma, angle = a, power = p } }
	end

	if b.stato == "aspetta" then
		-- dopo un colpo si aspetta che tutto sia fermo, poi si ripensa
		b.attesa = b.attesa + 1
		if quieto(g) or b.attesa > 4 * 60 then
			if b.liv.oggetti and rb.ammo.shield > 0 and g:can_use("shield") and g.used.primary and g.used.secondary then
				return { fire = { weapon = "shield", angle = 0, power = 0 } }
			end
			-- col piano poi = "teletrasporto" basta un attacco: poi si scappa
			local scappa = b.piano and b.piano.poi == "teletrasporto" and (g.used.primary or g.used.secondary)
			if b.riparato or scappa or (g.used.primary and g.used.secondary and not g:can_use("teleport")) then
				basta(b)
			else
				ripensa(b, math.floor(b.liv.reazione / 2))
			end
		end
		return FERMO
	end
	return FERMO
end

-- Scelta d'inizio partita: una primaria e una secondaria a caso tra quelle
-- che può prendere (sim/draft.lua); armi (pesi.armi, se c'è): quella che gli
-- piace di più, a pari gusto quella a caso
function M.scegli(d, i, seed, armi)
	local draft = require "sim.draft"
	local r = generatore((seed or 1) * 104729 + i)
	for _, offer in ipairs({ d.offer, d.offer2 }) do
		local libere = {}
		for _, w in ipairs(offer) do
			if draft.valid(d, i, w) then libere[#libere + 1] = w end
		end
		if #libere > 0 then
			local w = libere[1 + math.floor(r:next() * #libere)]
			for _, x in ipairs(armi and libere or {}) do
				if (armi[x] or 1) > (armi[w] or 1) then w = x end
			end
			draft.pick(d, i, w)
		end
	end
end

return M
