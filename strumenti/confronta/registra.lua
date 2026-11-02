-- Registra partite di bot per il confronto prima/dopo (confronta.py): una
-- riga per partita con l'impronta di tutto lo stato ogni OGNI tick. Serve a
-- dimostrare che una modifica che non deve cambiare il gioco (pulizia,
-- traduzione, rinomi) non lo cambia davvero: le righe devono essere uguali.
--
-- L'impronta non dipende dai nomi: dei campi conta solo il valore (numeri e
-- vero/falso; le stringhe no, perché una traduzione le cambia) e le liste
-- contano in ordine. Così due versioni con i nomi tradotti si confrontano lo
-- stesso. Il terreno conta a ogni cambio di turno (contarlo a ogni tick sarebbe
-- troppo lento; un cratere diverso cambia comunque tutto quello che viene dopo).
--
--   luajit strumenti/confronta/registra.lua [--partite N] [--da K] [--ogni T] [--missioni 0|1]
--
-- Partite: la k-esima ha un seme suo, ruota modo (1v1, 2v2, tutti contro
-- tutti), mappa (tutte quelle di sim/maps.lua), grado del bot (1-10) e, una
-- volta su due, set di equipaggiamento a caso. Con --missioni 1 aggiunge una
-- partita per ogni missione dei gironi (sim/campagna.lua), col bot al posto
-- del giocatore.
package.path = "client/?.lua;" .. package.path

local config = require "sim.config"
local draft = require "sim.draft"
local maps = require "sim.maps"
local rng = require "sim.rng"
local bot = require "sim.bot"
local replay = require "sim.replay"
local assetto = require "sim.assetto"
local equip = require "sim.equipaggiamento"
local game = require "sim.game"
local missioni = require "sim.missioni"
local campagna = require "sim.campagna"

local opt = { partite = 10, da = 1, ogni = 10, missioni = 0 }
do
	local i = 1
	while arg[i] do
		local k = arg[i]:match("^%-%-(.+)")
		assert(k and opt[k] and arg[i + 1], "argomento sconosciuto: " .. tostring(arg[i]))
		opt[k] = assert(tonumber(arg[i + 1]), "serve un numero: " .. arg[i])
		i = i + 2
	end
end

-- Impronta ------------------------------------------------------------------------

local bxor, tobit = bit.bxor, bit.tobit
local M32 = 4294967296

-- a * b modulo 2^32, esatto: b spezzato in due metà da 16 bit (un double
-- tiene esatti solo 53 bit)
local function per(a, b)
	a = a % M32
	return (a * (b % 65536) + (a * math.floor(b / 65536)) % 65536 * 65536) % M32
end

local function mescola(h, x)
	h = per(tobit(bxor(h, x)), 16777619)
	return tobit(per(tobit(bxor(h, bit.rshift(tobit(h), 15))), 2246822519))
end

-- un numero diventa due interi: parte intera e frazione (2^-40 di risoluzione)
local function numero(v)
	if v ~= v then return 7 end
	if v == math.huge then return 11 end
	if v == -math.huge then return 13 end
	local i = math.floor(v)
	return mescola(tobit(i % M32), tobit(math.floor((v - i) * 1099511627776) % M32))
end

local impronta
-- Le tabelle: le liste (1..n) in ordine; gli altri campi sommati, così l'ordine
-- di pairs e i nomi non contano. Chiavi numeriche fuori dalla lista contano
-- col loro valore, quelle di testo no.
local function tabella(t, visti)
	if visti[t] then return 3 end
	visti[t] = true
	local n = #t
	local h = mescola(17, n)
	for i = 1, n do h = mescola(h, impronta(t[i], visti)) end
	local somma = 0
	for k, v in pairs(t) do
		local kn = type(k) == "number"
		if not (kn and k >= 1 and k <= n and k % 1 == 0) then
			local x = impronta(v, visti)
			if x ~= 0 then
				somma = (somma + mescola(kn and numero(k) or 5, x)) % M32
			end
		end
	end
	return mescola(h, tobit(somma))
end

function impronta(v, visti)
	local t = type(v)
	if t == "number" then return numero(v)
	elseif t == "boolean" then return v and 2 or 1
	elseif t == "table" then return tabella(v, visti)
	end
	return 0 -- stringhe, funzioni, nil: non contano
end

-- Lo stato della partita senza il terreno (contato a parte) e senza gli eventi
-- già consegnati
local function stato(g)
	local terreno = g.terrain
	local visti = { [terreno] = true }
	if g.events then visti[g.events] = true end
	return impronta(g, visti)
end

local function terreno(t)
	local h = mescola(19, #t.data)
	for i = 1, #t.data do
		local c = t.data[i]
		if c ~= 0 then h = mescola(mescola(h, i), c) end
	end
	return h
end

-- gli eventi contano per tipo di campi numerici, non per nome
local function eventi(h, lista)
	for _, e in ipairs(lista) do h = mescola(h, impronta(e, {})) end
	return h
end

-- Una partita: impronte ogni opt.ogni tick, in esadecimale
local function gioca(g, step, fine)
	local out, h = {}, 0
	while true do
		step()
		local ev = g:pop_events()
		h = eventi(h, ev)
		for _, e in ipairs(ev) do
			if e.type == "turn" then h = mescola(h, terreno(g.terrain)) end
		end
		if g.tick % opt.ogni == 0 then
			h = mescola(h, stato(g))
			out[#out + 1] = bit.tohex(h)
		end
		if fine() then break end
	end
	out[#out + 1] = bit.tohex(mescola(mescola(h, stato(g)), terreno(g.terrain)))
	return table.concat(out, " ")
end

-- Le partite tra bot --------------------------------------------------------------

local MODI = { "1v1", "2v2", "ffa" }

local function partita(k)
	local seme = (k * 48271) % 2147483647
	local modo = MODI[1 + k % #MODI]
	local mappa = maps.order[1 + k % #maps.order]
	local base = {}
	for i, p in ipairs(config.MODES[modo]) do base[i] = { team = p.team } end
	local d = draft.new(seme, base)
	for i = 1, #base do bot.scegli(d, i, seme) end
	local players = draft.finish(d)
	local r0 = rng.new((seme * 69621 + 777) % 2147483647)
	for _ = 1, 4 do r0:next() end
	for i, p in ipairs(players) do
		p.bot = 1 + (k + i) % #bot.GRADI
		local s = math.floor(r0:next() * (2 * #equip.SETS + 1))
		if k % 2 == 0 and s > 0 then
			local set, variant = equip.SETS[1 + (s - 1) % #equip.SETS].id, s > #equip.SETS and "b" or "a"
			local gear, tiers = {}, {}
			for _, sl in ipairs(equip.SLOTS) do gear[sl.id], tiers[sl.id] = set, equip.TIERS end
			p.stats = assetto.stats(game.base_stats(), { tree = {}, gear = gear, variant = variant }, tiers)
		end
	end
	local r = replay.nuova(seme, mappa, { players = players })
	local g, bots = replay.partita(r)
	return gioca(g, function()
		g:step(replay.input(r, g, bots))
		replay.dopo(r, g)
	end, function() return g.phase == "over" end)
end

-- Le missioni dei gironi, col bot normale al posto del giocatore ---------------------

local TETTO = 8 * 60 * 60

local function missione(l)
	local r = missioni.nuova(l.id)
	local seed, mappa, opts = missioni.partita(r, 101)
	opts.players[1].bot = "normale"
	local ric = replay.nuova(seed, mappa, opts)
	local g, bots = replay.partita(ric)
	missioni.prepara(r, g)
	local esito
	return gioca(g, function()
		g:step(replay.input(ric, g, bots))
		-- gli eventi li guarda prima la missione, poi tornano in coda per gioca
		local ev = g:pop_events()
		for _, e in ipairs(ev) do missioni.evento(r, g, e, bots) end
		for _, e in ipairs(g.events) do ev[#ev + 1] = e end
		g.events = ev
		esito = missioni.tick(r, g)
	end, function() return esito or g.phase == "over" or g.tick >= TETTO end)
end

for k = opt.da, opt.da + opt.partite - 1 do
	io.write("partita ", k, " ", partita(k), "\n")
	io.flush()
end
if opt.missioni == 1 then
	for c, cap in ipairs(campagna.CAPITOLI) do
		if cap.id ~= "addestramento" then
			for i, l in ipairs(cap.missioni) do
				-- per numero e non per nome: una traduzione cambia i nomi
				io.write("missione ", c, ".", i, " ", missione(l), "\n")
				io.flush()
			end
		end
	end
end
