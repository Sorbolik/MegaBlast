-- Arena: partite tra bot senza grafica, per bilanciare e trovare le partite
-- da vedere. Gira con luajit dalla radice del repository; per usare tutti i
-- core c'è arena.py, che ne lancia una per core e mette insieme i risultati.
--
--   luajit strumenti/arena/arena.lua [--partite N] [--da SEME] [--modo 1v1|2v2|ffa|tutti]
--          [--livello facile|normale|difficile|misto] [--mappa forgia|crogiolo] [--uscita file.jsonl]
--          [--punteggio variante.lua]   -- una tabella come config.SCORE (opts.score), per provare varianti
--          [--ritocchi armi.lua]       -- function(config, game) che cambia i numeri delle armi (solo arena:
--                                         la ricetta non li contiene, si rigioca con lo stesso file)
--          [--set misto]               -- ogni robot un set completo a caso (o nessuno), variante a o b
--          [--pesi popolazione.lua]     -- una lista di pesi del bot (bot.PESI, anche con la rete): ogni robot ne prende uno a caso
--          [--impara 1]                -- scrive anche gli esempi per impara.py: a ogni fine turno le
--                                         caratteristiche della posizione (bot.caratteristiche) e quanto
--                                         ha guadagnato la sua squadra sulle altre da lì a fine partita;
--                                         e in una partita su quattro le mosse provate dalle reti (guida:
--                                         la descrizione, bot.descrivi, e quanto ha reso)
--          [--assegna turno]           -- con --pesi: invece che a caso, a turno (il robot i prende il numero
--                                         i + partita) e a coppie: le partite 2j e 2j + 1 sono la stessa
--                                         (seme, modo, mappa, armi) con i numeri scambiati, così due
--                                         individui si incontrano sempre alla pari
--
-- Con --pesi la ricetta non contiene i pesi (le reti sono grandi): ogni
-- giocatore ha il suo numero (individuo) e la riga il file dei pesi; arena.py
-- li rimette per il video, dal .json accanto al .lua.
--
-- Per ogni partita scrive una riga JSON: la ricetta (sim/replay.lua, basta a
-- rigiocarla identica), l'esito, i numeri di ogni robot (armi scelte, punti,
-- danno e uccisioni per arma), ogni evento che dà o toglie punti (tick, chi, a
-- chi, punti, motivo, arma e categoria) e i turni, ognuno con la sua "firma" (le mosse in
-- ordine, per esempio "hook>sword+kill"), che arena.py usa per gli highlight.

package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local config = require "sim.config"
local draft = require "sim.draft"
local maps = require "sim.maps"
local rng = require "sim.rng"
local bot = require "sim.bot"
local replay = require "sim.replay"
local assetto = require "sim.assetto"
local equip = require "sim.equipaggiamento"

local opt = { partite = 10, da = 1, modo = "tutti", livello = "normale" }
local i = 1
while arg[i] do
	local k = arg[i]:match("^%-%-(.+)")
	assert(k and arg[i + 1], "argomento sconosciuto: " .. tostring(arg[i]))
	opt[k] = tonumber(arg[i + 1]) or arg[i + 1]
	i = i + 2
end

-- JSON -----------------------------------------------------------------------------

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
				json(v[k] == nil and v[tonumber(k)] or v[k], out)
			end
			out[#out + 1] = "}"
		end
	elseif t == "string" then
		out[#out + 1] = string.format("%q", v)
	elseif t == "number" then
		-- abbastanza cifre per ritrovare lo stesso numero (angoli della ricetta)
		out[#out + 1] = (v == math.floor(v) and math.abs(v) < 1e15) and string.format("%d", v) or string.format("%.17g", v)
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

-- Una partita ---------------------------------------------------------------------

-- Gli eventi che dicono che un robot ha usato un'arma o un oggetto
local USO = {
	fire = "missile", grenade = "grenade", shards = "shards", sniper = "sniper", punch = "punch",
	swing = "sword", eagle = "eagle", mallet = "mallet", lunge = "lunge", bellows = "bellows", hook = "hook",
	orb = "teleport", parachute = "parachute", shield = "shield",
}
local MODI = { "1v1", "2v2", "ffa" }
local PUNTEGGIO = opt.punteggio and dofile(opt.punteggio) or nil
local POPOLAZIONE = opt.pesi and dofile(opt.pesi) or nil
if opt.ritocchi then dofile(opt.ritocchi)(config, game) end

-- primaria, secondaria o oggetto (il teletrasporto è un oggetto)
local PRIMARIE = { missile = true }
for _, w in ipairs(game.CRATE_WEAPONS) do PRIMARIE[w] = true end
local function categoria(w)
	if not w then return "altro" end
	if game.SECONDARY[w] then return "secondaria" end
	return PRIMARIE[w] and "primaria" or "oggetto"
end

-- La partita numero k. Il seme non è k: semi vicini darebbero ai primi passi
-- del generatore (sim/rng.lua) numeri quasi uguali, e quindi partite simili
-- (stessa scelta d'inizio partita, stesse casse)
-- Con --assegna turno le partite vanno a coppie (j = k // 2): prima, con due
-- mappe in rotazione, la parità di k decideva insieme mappa e individui, e il
-- primo individuo partiva sempre primo sulla stessa mappa (esami falsati di 6-8
-- punti anche fra due bot uguali)
local function partita(k)
	local j = opt.assegna == "turno" and math.floor(k / 2) or k
	local seme = (j * 48271) % 2147483647
	local r0 = rng.new(seme)
	for _ = 1, 4 do r0:next() end
	local modo = opt.modo == "tutti" and MODI[1 + (j % #MODI)] or opt.modo
	local mappa = opt.mappa or maps.pick(seme)
	local base = {}
	for k, p in ipairs(config.MODES[modo]) do base[k] = { team = p.team } end
	-- i pesi con un generatore a parte: livelli e armi restano quelli delle
	-- stesse partite senza --pesi, così si confrontano a coppie (le armi
	-- cambiano solo per chi ha un gusto per le armi, pesi.armi)
	local individui = {}
	if POPOLAZIONE then
		local r1 = rng.new((seme * 16807 + 12345) % 2147483647)
		for _ = 1, 4 do r1:next() end
		for i = 1, #base do
			individui[i] = opt.assegna == "turno" and 1 + (i + k) % #POPOLAZIONE
				or 1 + math.floor(r1:next() * #POPOLAZIONE)
		end
	end
	local d = draft.new(seme, base)
	for i = 1, #base do bot.scegli(d, i, seme, individui[i] and POPOLAZIONE[individui[i]].armi) end
	local players = draft.finish(d)
	for i, p in ipairs(players) do
		p.bot = opt.livello == "misto" and bot.ORDINE[1 + math.floor(r0:next() * #bot.ORDINE)] or opt.livello
		if individui[i] then p.individuo, p.pesi = individui[i], POPOLAZIONE[individui[i]] end
	end
	-- i set con un altro generatore ancora, per lo stesso motivo
	if opt.set == "misto" then
		local r2 = rng.new((seme * 69621 + 777) % 2147483647)
		for _ = 1, 4 do r2:next() end
		for _, p in ipairs(players) do
			local k = math.floor(r2:next() * (2 * #equip.SETS + 1))
			if k > 0 then
				local set, variant = equip.SETS[1 + (k - 1) % #equip.SETS].id, k > #equip.SETS and "b" or "a"
				local gear, tiers = {}, {}
				for _, sl in ipairs(equip.SLOTS) do gear[sl.id], tiers[sl.id] = set, equip.TIERS end
				p.set = set .. "_" .. variant
				p.stats = assetto.stats(game.base_stats(), { tree = {}, gear = gear, variant = variant }, tiers)
			end
		end
	end
	local r = replay.nuova(seme, mappa, { players = players, score = PUNTEGGIO })
	local g, bots = replay.partita(r)
	-- per la guida (impara.py): in una partita su quattro, le mosse provate dalle reti
	local guida = opt.impara and k % 4 == 0 and {} or nil
	if guida then
		for _, b in pairs(bots) do
			if b.pesi.rete then b.diario = guida end
		end
	end

	local ultima = {}       -- l'ultima arma usata da ogni robot
	local stats = {}
	for k = 1, #g.robots do stats[k] = { uso = {}, danno = {}, uccisioni = {} } end
	local turni, turno = {}, nil
	local punti = {}
	-- esempi per impara.py: dall'inizio di un turno alla fine, la posizione
	-- che ne è uscita; a fine partita, quanto ha reso
	local esempi, inizio = opt.impara and {} or nil, nil
	local function margine(team)
		local mio, altri = 0, {}
		for _, rb in ipairs(g.robots) do
			if rb.team == team then mio = mio + rb.points else altri[rb.team] = (altri[rb.team] or 0) + rb.points end
		end
		local primo = 0
		for _, t in ipairs({ 1, 2, 3, 4 }) do
			if altri[t] then primo = math.max(primo, altri[t]) end
		end
		return mio - primo
	end
	local function fine_turno()
		if inizio then
			local x = bot.caratteristiche({ id = inizio.chi }, inizio.ref, g, {})
			for j = 1, #x do x[j] = math.floor(x[j] * 10000 + 0.5) / 10000 end
			esempi[#esempi + 1] = { c = inizio.chi, x = x, m = inizio.m }
		end
	end
	local function chiudi_turno()
		if turno then
			turno.firma = table.concat(turno.mosse, ">") .. (turno.uccisioni > 0 and "+kill" or "")
				.. (turno.ambientali > 0 and "+fuori" or "")
			turno.mosse = nil
			turni[#turni + 1] = turno
		end
	end
	while g.phase ~= "over" do
		g:step(replay.input(r, g, bots))
		replay.dopo(r, g)
		for _, e in ipairs(g:pop_events()) do
			local w = USO[e.type] or (e.type == "place" and e.kind) or nil
			if w and e.robot then
				ultima[e.robot] = w
				local u = stats[e.robot].uso
				u[w] = (u[w] or 0) + 1
				if turno and e.robot == turno.chi then turno.mosse[#turno.mosse + 1] = w end
			elseif e.type == "points" then
				-- per i danni e le uccisioni l'arma di chi prende i punti, per le morti quella dell'altro
				local w = ultima[e.reason == "death" and e.other or e.robot]
				if e.reason == "death" and not e.other then w = nil end
				punti[#punti + 1] = { t = g.tick, chi = e.robot, altro = e.other or 0, punti = e.amount,
					motivo = e.reason, arma = w or "altro", cat = categoria(w) }
			elseif e.type == "turn" then
				chiudi_turno()
				if esempi then
					fine_turno()
					inizio = { chi = e.robot, ref = bot.mondo(g), m = margine(g.robots[e.robot].team) }
				end
				turno = { t = g.tick, chi = e.robot, mosse = {}, danno = 0, uccisioni = 0, ambientali = 0 }
			elseif e.type == "damage" and turno then
				local vittima = g.robots[e.robot]
				local chi = g.robots[turno.chi]
				if vittima.team ~= chi.team then
					local w = ultima[chi.id] or "altro"
					local dn = stats[chi.id].danno
					dn[w] = (dn[w] or 0) + e.amount
					turno.danno = turno.danno + e.amount
				end
			elseif e.type == "death" and e.by then
				local w = (turno and e.by == turno.chi) and (ultima[e.by] or "altro") or "altro"
				local u = stats[e.by].uccisioni
				u[w] = (u[w] or 0) + 1
				if turno and e.by == turno.chi then
					turno.uccisioni = turno.uccisioni + 1
					if e.env then turno.ambientali = turno.ambientali + 1 end
				end
			end
		end
	end
	chiudi_turno()
	if esempi then
		fine_turno()
		for _, x in ipairs(esempi) do
			x.y = (margine(g.robots[x.c].team) - x.m) / 100
			x.m = x.m / 100 -- per impara.py (il ritorno a passi, TD)
		end
	end
	local res = g:results()
	local robot = {}
	for k, rb in ipairs(g.robots) do
		local s = stats[k]
		local pl = players[k]
		local place
		for _, x in ipairs(res.ranking) do
			if x.robot == k then place = x.place end
		end
		robot[k] = { squadra = rb.team, livello = pl.bot, individuo = pl.individuo, set = pl.set, primaria = pl.pick, secondaria = pl.secondary,
			posto = place, punti = rb.points, danno = rb.damage, uccisioni = rb.kills, ambientali = rb.env_kills,
			morti = rb.deaths, cadute = rb.falls, teletrasporti = rb.teleports, casse = rb.crates,
			uso = s.uso, danno_arma = s.danno, uccisioni_arma = s.uccisioni }
	end
	r.ultimo = nil
	if POPOLAZIONE then
		for _, p in ipairs(r.opzioni.players) do p.pesi = nil end
	end
	return { numero = k, ricetta = r, modo = modo, mappa = mappa, vincitore = res.winner or 0, tick = g.tick, robot = robot,
		turni = turni, punti = punti, ritocchi = opt.ritocchi, pesi = opt.pesi, esempi = esempi,
		guida = guida }
end

local out = opt.uscita and assert(io.open(opt.uscita, "w")) or io.stdout
local t0 = os.clock()
for s = opt.da, opt.da + opt.partite - 1 do
	out:write(to_json(partita(s)), "\n")
	out:flush()
end
if opt.uscita then
	out:close()
	io.stderr:write(string.format("%d partite in %.1f s\n", opt.partite, os.clock() - t0))
end
