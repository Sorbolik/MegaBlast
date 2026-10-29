-- Bot avversario: gioca il turno di un robot premendo gli stessi tasti di un
-- giocatore (l'input di game:step), quindi non bara e va bene anche online.
-- Lua puro e deterministico (il caso viene da un generatore suo): lo usano il
-- telefono (partite contro i bot) e l'arena (strumenti/arena), e lo userà il
-- server per riempire le code.
--
--   local bot = require "sim.bot"
--   local b = bot.new(id, "normale", seed, pesi)   -- id del robot, livello, seme, pesi (facoltativi, vedi M.PESI)
--   local input = bot.input(b, g)           -- a ogni tick, prima di g:step(input)
--   bot.scegli(d, i, seed)                  -- primaria e secondaria nella scelta (sim/draft.lua)
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
-- usa; lavoro: tick di simulazione provati per tick di gioco.
M.LIVELLI = {
	facile = { reazione = 80, mira = 0.09, potenza = 0.08, sbaglia = 0.4, cammino = 150, potenze = 2,
		teletrasporto = false, rampino = false, oggetti = false, lavoro = 400 },
	normale = { reazione = 45, mira = 0.035, potenza = 0.03, sbaglia = 0.15, cammino = 300, potenze = 3,
		teletrasporto = true, rampino = true, oggetti = false, lavoro = 400 },
	difficile = { reazione = 20, mira = 0.008, potenza = 0.008, sbaglia = 0, cammino = 420, potenze = 5,
		teletrasporto = true, rampino = true, oggetti = true, lavoro = 400 },
}
M.ORDINE = { "facile", "normale", "difficile" }

-- I pesi del bot: come vale il risultato di una mossa oltre ai punti partita.
-- vita_mia, vita_compagno: per punto di vita perso; morte: in più del
-- punteggio, se muore lui o un compagno; strada: quanto costa un tick di strada
-- (a parità di colpo, quello più vicino); teletrasporto: sotto questo punteggio
-- dalla strada a piedi prova il teletrasporto; punteggio (se c'è): i punti
-- con cui il bot giudica le mosse, al posto di quelli della partita. L'arena li fa evolvere
-- (strumenti/arena/evolvi.py) e una partita può darne altri a ogni bot
-- (players[i].pesi, solo i campi che cambiano). rete (se c'è): una rete
-- neurale (sim/rete.lua) che giudica le mosse al posto di questi pesi, dalle
-- caratteristiche della posizione dopo la mossa (M.caratteristiche); la fanno
-- evolvere strumenti/arena/evolvi.py o imparare strumenti/arena/impara.py;
-- esplora: probabilità di scegliere apposta una delle mosse dopo la migliore.
M.PESI = { vita_mia = 0.6, vita_compagno = 1, morte = 60, strada = 0.01, teletrasporto = 20 }
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
	w.match_left, w.overtime, w.order, w.order_pos, w.turn_no = g.match_left, g.overtime, g.order, g.order_pos, g.turn_no
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
		if not rb.dead and (not rb.grounded or rb.swing or rb.punch or rb.lunge or rb.recoil or rb.hooked or rb.mallet) then
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

-- Le caratteristiche della copia w (dopo una mossa) rispetto alla partita
-- vera g, per il robot del bot: quello che la rete guarda. Numeri vicini a
-- -1..1 (punti e vita a centinaia, distanze a migliaia di pixel).
M.CARATTERISTICHE = 20
local function caratteristiche(b, g, w, x)
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
	return x
end
M.caratteristiche = caratteristiche

local CAR = {}

-- Quanto vale la copia w rispetto alla partita vera g, per il robot del bot
local function valore(b, g, w)
	if b.pesi.rete then return rete.valuta(b.pesi.rete, caratteristiche(b, g, w, CAR)) * 100 end
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

-- Tutte le mosse da un posto, provate in fretta (solo il volo per i colpi a
-- distanza). Le aggiunge a mosse.
local function mosse_dal_posto(b, g, posto, lista_armi, mosse)
	local me = g.robots[b.id]
	local x, y = posto.x, posto.y
	local cy = y + game.DISEGNO_H / 2
	local bersagli = nemici(g, me, x, y)
	local function aggiungi(arma, a, p, fino)
		local s = prova(b, g, posto, arma, a, p, fino)
		mosse[#mosse + 1] = { posto = posto, arma = arma, angolo = a, potenza = p, punti = s - (posto.n or 0) * b.pesi.strada,
			k = #mosse + 1 }
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
			elseif arma == "mallet" then
				if math.abs(dx) < C.MALLET.reach + 30 and math.abs(dy) < C.MALLET.reach + 30 then
					aggiungi(arma, dx < 0 and math.pi or 0, 1, "tutto")
				end
			elseif arma == "sword" or arma == "punch" then
				if dist < 80 then aggiungi(arma, dritto, 1, "tutto") end
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

-- Il pensiero: sceglie la mossa del momento. Mette in b.scelta la migliore
-- trovata finora, così se il tempo stringe si usa quella.
local function pensa(b, g)
	local me = g.robots[b.id]
	local liv = b.liv
	-- quanto tempo resta per camminare: il turno, o i secondi dopo il primo attacco
	local resta = g.window > 0 and g.window or g.timer
	local lista = armi(g, me)
	local mosse = {}
	local posti = posti_a_piedi(b, g, math.min(liv.cammino, resta - 90))
	for _, posto in ipairs(posti) do
		if #lista > 0 then mosse_dal_posto(b, g, posto, lista, mosse) end
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
					mosse[#mosse + 1] = { posto = posti[1], arma = "hook", angolo = a, potenza = 1,
						punti = prova_rampino(b, g, posti[1], a, o.id, lista), k = #mosse + 1 }
				end
			end
		end
	end

	-- le migliori si provano fino in fondo: chi cade, chi muore, dove finisce chi spara
	table.sort(mosse, prima)
	for i = 1, math.min(FINALISTE, #mosse) do
		local m = mosse[i]
		if m.arma ~= "hook" then
			m.punti = prova(b, g, m.posto, m.arma, m.angolo, m.potenza, "tutto") - (m.posto.n or 0) * b.pesi.strada
		end
	end
	table.sort(mosse, prima)
	b.scelta = mosse[1]

	-- se a piedi non c'è niente di buono, il teletrasporto verso un posto migliore
	local best = mosse[1] and mosse[1].punti or -math.huge
	if liv.teletrasporto and best < b.pesi.teletrasporto and g:can_use("teleport") and resta > 6 * 60 then
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
	local sbaglia = b.pesi.esplora or liv.sbaglia
	if sbaglia > 0 and #mosse > 1 and b.rng:next() < sbaglia then
		local m = mosse[1 + math.floor(b.rng:next() * math.min(3, #mosse))]
		if m.punti >= math.min(0, mosse[1].punti) then b.scelta = m end
	end
end

-- Il riparo: finiti gli attacchi, il tempo che resta si usa per mettersi al
-- sicuro dal turno degli altri (a piedi o col Rampino su un appiglio). Con la
-- rete decide lei dove; senza, lontano dai nemici, fuori dalla loro linea di
-- tiro e lontano dal vuoto.
local function riparo(b, g, w)
	if b.pesi.rete then return valore(b, g, w) end
	local x = caratteristiche(b, g, w, CAR)
	if x[7] == 1 then return -1000 end
	return x[11] * 10 - x[16] * 4 - x[14] * 8 - x[15] * 3 - x[4] * 50
end

local function ripara(b, g)
	local me = g.robots[b.id]
	local resta = g.window > 0 and g.window or g.timer
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

function M.new(id, livello, seed, pesi)
	local liv = M.LIVELLI[livello] or M.LIVELLI.normale
	local p = copia(M.PESI)
	for k, v in pairs(pesi or {}) do p[k] = v end
	return { id = id, livello = livello, liv = liv, pesi = p, rng = generatore((seed or 1) * 7919 + id), lavoro = 0 }
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
		b.turno, b.riparato = g.turn_no, false
		ripensa(b, b.liv.reazione)
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
			if coroutine.status(b.co) ~= "dead" and (g.window > 0 and g.window or g.timer) > 45 then return FERMO end
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
			if b.riparato or (g.used.primary and g.used.secondary and not g:can_use("teleport")) then
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
-- che può prendere (sim/draft.lua)
function M.scegli(d, i, seed)
	local draft = require "sim.draft"
	local r = generatore((seed or 1) * 104729 + i)
	for _, offer in ipairs({ d.offer, d.offer2 }) do
		local libere = {}
		for _, w in ipairs(offer) do
			if draft.valid(d, i, w) then libere[#libere + 1] = w end
		end
		if #libere > 0 then draft.pick(d, i, libere[1 + math.floor(r:next() * #libere)]) end
	end
end

return M
