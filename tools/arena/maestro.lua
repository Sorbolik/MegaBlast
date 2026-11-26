-- Maestro: un bot che sceglie la mossa giocandola. Per le mosse migliori che
-- trova il bot del gioco (le candidate, b.scegli in sim/bot.lua) copia la
-- partita intera (terreno compreso), fa la mossa e fa giocare a tutti il resto
-- del giro col bot del gioco, più volte con semi diversi (gli stessi semi per
-- ogni candidata, così il caso pesa uguale su tutte), e prende quella che in
-- media lascia la squadra più avanti. È il "rollout" del backgammon: in un
-- gioco col caso, giocare avanti da una posizione dice quanto vale meglio di
-- qualsiasi regola scritta a mano.
--
-- Serve a tre cose: dire quanto rende pensare meglio (il tetto di bravura,
-- mappa per mappa), insegnare al bot del gioco (ogni scelta del Maestro con le
-- caratteristiche delle candidate va in --dati, maestro.py ne impara una
-- correzione) ed esaminare il bot corretto contro quello di oggi (--maestro 0).
--
--   luajit tools/arena/maestro.lua [--partite N] [--da K] [--modo 2v2|1v1|ffa] [--grado 10]
--          [--mappa NOME] [--maestro 1] [--candidate 5] [--semi 4] [--giri 1] [--turni 0] [--vita 0.5]
--          [--allievo pesi.lua] [--avversario GRADO] [--modello GRADO] [--solo attacco|riparo]
--          [--leggero 1] [--finto 1] [--uscita partite.jsonl] [--dati scelte.jsonl]
--
-- Le partite vanno a coppie (2j e 2j + 1 uguali, squadre scambiate): nella
-- partita k la squadra del Maestro è la 1 + k % 2. --allievo: i pesi della
-- squadra del Maestro (anche correzione e riparo), che usa pure nei suoi
-- rollout; gli altri sono il grado puro. --maestro 0: niente rollout, la
-- squadra gioca col bot e i pesi dell'allievo (l'esame). --vita: quanti punti
-- vale un punto vita di differenza alla fine del rollout. --giri: quanti giri
-- interi gioca avanti (un giro: finché tocca di nuovo al robot che sceglie);
-- --turni N (se non è 0): invece si ferma all'inizio dell'N-esimo turno dopo
-- (1: appena finito il proprio, 2: dopo la risposta del primo avversario).
-- --avversario: il grado della squadra avversaria (di base lo stesso);
-- --modello: il grado che il Maestro crede abbiano gli avversari nei rollout
-- (di base quello vero: provarne un altro dice se vince solo perché li conosce).
-- --solo attacco|riparo: sceglie solo quelle; --leggero 1: nei rollout bot che
-- cercano meno (più veloci); --finto 1: rollout fatti ma gioca la prima candidata.

package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local config = require "sim.config"
local draft = require "sim.draft"
local maps = require "sim.maps"
local rng = require "sim.rng"
local bot = require "sim.bot"
local replay = require "sim.replay"

local opt = { partite = 2, da = 0, modo = "2v2", grado = 10, maestro = 1, candidate = 5, semi = 4, giri = 1, turni = 0,
	vita = 0.5, max_tick = 6000 }
local i = 1
while arg[i] do
	local k = arg[i]:match("^%-%-(.+)")
	assert(k and arg[i + 1], "argomento sconosciuto: " .. tostring(arg[i]))
	opt[k] = tonumber(arg[i + 1]) or arg[i + 1]
	i = i + 2
end
local ALLIEVO = opt.allievo and dofile(opt.allievo) or nil
opt.avversario = opt.avversario or opt.grado
opt.modello = opt.modello or opt.avversario

-- JSON ------------------------------------------------------------------------------

local function json(v, out)
	local t = type(v)
	if t == "table" then
		if #v > 0 or next(v) == nil then
			out[#out + 1] = "["
			for k, x in ipairs(v) do
				if k > 1 then out[#out + 1] = "," end
				json(x, out)
			end
			out[#out + 1] = "]"
		else
			local keys = {}
			for k in pairs(v) do keys[#keys + 1] = tostring(k) end
			table.sort(keys)
			out[#out + 1] = "{"
			for n, k in ipairs(keys) do
				if n > 1 then out[#out + 1] = "," end
				out[#out + 1] = string.format("%q:", k)
				json(v[k] ~= nil and v[k] or v[tonumber(k)], out)
			end
			out[#out + 1] = "}"
		end
	elseif t == "string" then
		out[#out + 1] = string.format("%q", v):gsub("\\\n", "\\n")
	elseif t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then
			out[#out + 1] = "null"
		elseif v == math.floor(v) then
			out[#out + 1] = string.format("%d", v)
		else
			out[#out + 1] = string.format("%.4f", v)
		end
	elseif t == "boolean" then
		out[#out + 1] = tostring(v)
	else
		out[#out + 1] = "null"
	end
end

local function to_json(v)
	local out = {}
	json(v, out)
	return table.concat(out)
end

-- La partita intera copiata -----------------------------------------------------------

-- tabelle che nessuno scrive durante la partita: restano in comune
local SHARE = { map = true, score = true, stats = true }

local function deep(v, memo)
	if type(v) ~= "table" then return v end
	local c = memo[v]
	if c then return c end
	c = {}
	memo[v] = c
	for k, x in pairs(v) do
		if type(x) == "table" and not SHARE[k] then c[k] = deep(x, memo) else c[k] = x end
	end
	local mt = getmetatable(v)
	if mt then setmetatable(c, mt) end
	return c
end

-- La copia di g da giocare avanti col seme s: il terreno a parte (è grande:
-- un ciclo sui numeri), il generatore della partita cambiato (le casse future
-- non si sanno) e le casse a terra senza contenuto, come le copie del bot
local function copia(g, s)
	local data = g.terrain.data
	g.terrain.data = nil
	local c = deep(g, {})
	g.terrain.data = data
	local d = {}
	for k = 1, #data do d[k] = data[k] end
	c.terrain.data = d
	c.rng = rng.new(s)
	for _ = 1, 4 do c.rng:next() end
	for _, k in ipairs(c.crates) do k.weapon = "hook" end
	return c
end

-- Valore e caratteristiche --------------------------------------------------------------

local function margine(g, team)
	local mio, altri = 0, {}
	for _, rb in ipairs(g.robots) do
		if rb.team == team then mio = mio + rb.points else altri[rb.team] = (altri[rb.team] or 0) + rb.points end
	end
	local primo = -math.huge
	for _, v in pairs(altri) do primo = math.max(primo, v) end
	return mio - (primo == -math.huge and 0 or primo)
end

-- vita della squadra meno la media delle altre (i morti contano 0)
local function vite(g, team)
	local mio, altri, n = 0, 0, {}
	for _, rb in ipairs(g.robots) do
		local hp = rb.dead and 0 or rb.hp
		if rb.team == team then mio = mio + hp else
			altri = altri + hp
			n[rb.team] = true
		end
	end
	local squadre = 0
	for _ in pairs(n) do squadre = squadre + 1 end
	return mio - altri / math.max(1, squadre)
end

local function valore(g, team)
	return margine(g, team) + opt.vita * vite(g, team)
end

local function arrotonda(x)
	local out = {}
	for k = 1, #x do out[k] = math.floor(x[k] * 10000 + 0.5) / 10000 end
	return out
end

-- Il Maestro --------------------------------------------------------------------------

local DEAD = coroutine.create(function() end)
coroutine.resume(DEAD)

-- i pesi di chi gioca: l'allievo per la squadra del Maestro, il grado per gli altri
local function pesi_di(team, team_m)
	return team == team_m and ALLIEVO or nil
end

-- Gioca avanti la copia G: il robot me parte con la mossa m già scelta (lo
-- stato del bot b di adesso), poi tutti col bot. Restituisce il valore alla
-- fine e le caratteristiche della posizione appena la mossa si è fermata.
local function rollout(g, b, m, tipo, s, team_m)
	local G = copia(g, s)
	local me = b.id
	local team = g.robots[me].team
	local bots = {}
	for k, rb in ipairs(G.robots) do
		bots[k] = bot.new(k, rb.team == team_m and opt.grado or opt.modello, s * 31 + k, pesi_di(rb.team, team_m))
		-- --leggero 1: nei rollout bot che cercano meno (meno passi e potenze), stessa mira
		if opt.leggero == 1 then
			local l = {}
			for kk, v in pairs(bots[k].liv) do l[kk] = v end
			l.walk_ticks, l.powers = math.min(l.walk_ticks, 120), 2
			bots[k].liv = l
		end
	end
	local rb = bots[me]
	rb.turno, rb.sheltered, rb.inizio, rb.attacks, rb.piano = G.turn_no, b.sheltered, b.inizio, b.attacks, b.piano
	rb.stato, rb.attesa, rb.co, rb.scelta, rb.passo, rb.think_from = "pensa", b.attesa or 0, DEAD, m, 0, G.tick
	local ref = bot.world(g)
	local x, mossa, giri, turni = nil, false, 0, 0
	local fine = G.tick + opt.max_tick * opt.giri
	while G.phase ~= "over" and G.tick < fine do
		local who = bots[G.current]
		G:step(who and bot.input(who, G) or {})
		for _, e in ipairs(G:pop_events()) do
			if e.type == "turn" then
				turni = turni + 1
				if e.robot == me then giri = giri + 1 end
			end
		end
		-- la mossa si è fermata: la posizione che ne è uscita
		if rb.stato ~= "pensa" then mossa = true end
		if not x and (G.current ~= me or (mossa and (rb.stato == "fine" or rb.stato == "pensa") and bot.quiet(G))) then
			x = arrotonda(bot.caratteristiche({ id = me }, ref, G, {}))
		end
		if (opt.turni > 0 and turni >= opt.turni) or (opt.turni == 0 and giri >= opt.giri) then break end
	end
	return valore(G, team), x
end

local scelte -- le scelte della partita, per --dati

-- Le prime n candidate diverse: stessa arma, stesso angolo e quasi lo stesso posto sono la stessa mossa
local function uguali(a, c)
	return a.arma == c.arma and math.abs((a.ang or 0) - (c.ang or 0)) < 0.03 and math.abs((a.potenza or 0) - (c.potenza or 0)) < 0.03
		and math.abs(a.posto.x - c.posto.x) < 9 and math.abs(a.posto.y - c.posto.y) < 9
end

local function uniche(all, n)
	local out = {}
	for _, m in ipairs(all) do
		local nuova = true
		for _, c in ipairs(out) do
			if uguali(m, c) then
				nuova = false
				break
			end
		end
		if nuova then out[#out + 1] = m end
		if #out >= n then break end
	end
	return out
end

local function maestro(team_m)
	return function(b, g, all, tipo)
		-- --solo attacco|riparo: il Maestro sceglie solo quelle
		if opt.solo and opt.solo ~= tipo then return all[1] end
		local cands = uniche(all, opt.candidate)
		local n = #cands
		if n <= 1 then return cands[1] end
		local team = g.robots[b.id].team
		local v0 = valore(g, team)
		local q, xs = {}, {}
		for k = 1, n do
			local sum = 0
			for s = 1, opt.semi do
				-- gli stessi semi per ogni candidata
				local seed = (g.tick * 977 + b.id * 131 + s * 7919) % 2147483647 + 1
				local v, x = rollout(g, b, cands[k], tipo, seed, team_m)
				sum = sum + v - v0
				if s == 1 then xs[k] = x end
			end
			q[k] = sum / opt.semi
		end
		local best = 1
		for k = 2, n do
			if q[k] > q[best] then best = k end
		end
		-- --finto 1: i rollout si fanno ma si gioca la prima (la prova che non toccano la partita vera)
		if opt.finto == 1 then best = 1 end
		local punti = {}
		for k = 1, n do punti[k] = cands[k].punti end
		scelte[#scelte + 1] = { tipo = tipo, chi = b.id, t = g.tick, q = q, punti = punti, x = xs, scelta = best,
			arma = cands[best].arma or "riparo" }
		return cands[best]
	end
end

-- Una partita -----------------------------------------------------------------------

local MODI = { "1v1", "2v2", "ffa" }

local function partita(k)
	local j = math.floor(k / 2)
	local seme = (j * 48271 + 99991) % 2147483647
	local modo = opt.modo == "tutti" and MODI[1 + (j % #MODI)] or opt.modo
	local mappa = opt.mappa or maps.pick(seme)
	local team_m = 1 + k % 2
	local base = {}
	for n, p in ipairs(config.MODES[modo]) do base[n] = { team = p.team } end
	local d = draft.new(seme, base)
	for n = 1, #base do bot.choose(d, n, seme, nil) end
	local players = draft.finish(d)
	for _, p in ipairs(players) do
		p.bot = p.team == team_m and opt.grado or opt.avversario
		if p.team == team_m then p.pesi = ALLIEVO end
	end
	local r = replay.new(seme, mappa, { players = players })
	local g, bots = replay.match(r)
	scelte = {}
	if opt.maestro == 1 then
		for n, b in pairs(bots) do
			if g.robots[n].team == team_m then b.scegli = maestro(team_m) end
		end
	end
	local t0 = os.clock()
	while g.phase ~= "over" do
		g:step(replay.input(r, g, bots))
		replay.after(r, g)
		g:pop_events()
	end
	local res = g:results()
	local punti = {}
	for _, rb in ipairs(g.robots) do punti[rb.team] = (punti[rb.team] or 0) + rb.points end
	return { numero = k, modo = modo, mappa = mappa, squadra_maestro = team_m, vincitore = res.winner or 0,
		punti = punti, margine = margine(g, team_m), secondi = os.clock() - t0, scelte = #scelte }, scelte
end

local out = opt.uscita and assert(io.open(opt.uscita, "w")) or io.stdout
local dati = opt.dati and assert(io.open(opt.dati, "w")) or nil
for k = opt.da, opt.da + opt.partite - 1 do
	local riga, sc = partita(k)
	out:write(to_json(riga), "\n")
	out:flush()
	if dati then
		for _, s in ipairs(sc) do
			s.partita = k
			dati:write(to_json(s), "\n")
		end
		dati:flush()
	end
end
if opt.uscita then out:close() end
if dati then dati:close() end
