-- Arena: partite tra bot senza grafica, per bilanciare e trovare le partite
-- da vedere. Gira con luajit dalla radice del repository; per usare tutti i
-- core c'è arena.py, che ne lancia una per core e mette insieme i risultati.
--
--   luajit strumenti/arena/arena.lua [--partite N] [--da SEME] [--modo 1v1|2v2|ffa|tutti]
--          [--livello facile|normale|difficile|misto] [--mappa forgia|crogiolo] [--uscita file.jsonl]
--          [--punteggio variante.lua]   -- una tabella come config.SCORE (opts.score), per provare varianti
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
	swing = "sword", eagle = "eagle", mallet = "mallet", lunge = "lunge", hook = "hook",
	orb = "teleport", parachute = "parachute", shield = "shield",
}
local MODI = { "1v1", "2v2", "ffa" }
local PUNTEGGIO = opt.punteggio and dofile(opt.punteggio) or nil

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
local function partita(k)
	local seme = (k * 48271) % 2147483647
	local r0 = rng.new(seme)
	for _ = 1, 4 do r0:next() end
	local modo = opt.modo == "tutti" and MODI[1 + (k % #MODI)] or opt.modo
	local mappa = opt.mappa or maps.pick(seme)
	local base = {}
	for k, p in ipairs(config.MODES[modo]) do base[k] = { team = p.team } end
	local d = draft.new(seme, base)
	for k = 1, #base do bot.scegli(d, k, seme) end
	local players = draft.finish(d)
	for k, p in ipairs(players) do
		p.bot = opt.livello == "misto" and bot.ORDINE[1 + math.floor(r0:next() * #bot.ORDINE)] or opt.livello
	end
	local r = replay.nuova(seme, mappa, { players = players, score = PUNTEGGIO })
	local g, bots = replay.partita(r)

	local ultima = {}       -- l'ultima arma usata da ogni robot
	local stats = {}
	for k = 1, #g.robots do stats[k] = { uso = {}, danno = {}, uccisioni = {} } end
	local turni, turno = {}, nil
	local punti = {}
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
	local res = g:results()
	local robot = {}
	for k, rb in ipairs(g.robots) do
		local s = stats[k]
		local pl = players[k]
		local place
		for _, x in ipairs(res.ranking) do
			if x.robot == k then place = x.place end
		end
		robot[k] = { squadra = rb.team, livello = pl.bot, primaria = pl.pick, secondaria = pl.secondary,
			posto = place, punti = rb.points, danno = rb.damage, uccisioni = rb.kills, ambientali = rb.env_kills,
			morti = rb.deaths, cadute = rb.falls, teletrasporti = rb.teleports, casse = rb.crates,
			uso = s.uso, danno_arma = s.danno, uccisioni_arma = s.uccisioni }
	end
	r.ultimo = nil
	return { numero = k, ricetta = r, modo = modo, mappa = mappa, vincitore = res.winner or 0, tick = g.tick, robot = robot,
		turni = turni, punti = punti }
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
