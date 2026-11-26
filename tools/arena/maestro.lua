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
-- cercano meno (più veloci); --finto 1: rollout fatti ma gioca la prima candidata;
-- --limiti 1: pensa a pezzi come nel gioco (di base tutto in un tick).
-- Il livello del gioco si prova con --grado maestro --maestro 0 (bot.LEVELS.maestro).

package.path = "client/?.lua;" .. package.path

local config = require "sim.config"
local draft = require "sim.draft"
local maps = require "sim.maps"
local bot = require "sim.bot"
local replay = require "sim.replay"
local master = require "sim.master"

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

-- Il Maestro (sim/master.lua) ------------------------------------------------------------

local scelte -- le scelte della partita, per --dati

local function maestro(team_m)
	return master.chooser({ candidate = opt.candidate, semi = opt.semi, turni = opt.turni, giri = opt.giri,
		vita = opt.vita, max_tick = opt.max_tick, leggero = (opt.leggero or 0) > 0 and opt.leggero or nil, solo = opt.solo, finto = opt.finto == 1,
		libero = opt.limiti ~= 1,
		primo = opt.primo, tempo = opt.tempo, corto = opt.corto == 1,
		-- nei rollout la squadra del Maestro gioca con l'allievo, gli altri col grado che crede (--modello)
		grado = function(team)
			if team == team_m then return opt.grado, ALLIEVO end
			return opt.modello, nil
		end,
		log = function(s) scelte[#scelte + 1] = s end })
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
		punti = punti, margine = master.margin(g, team_m), secondi = os.clock() - t0, scelte = #scelte }, scelte
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
