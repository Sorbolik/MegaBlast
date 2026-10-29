-- Collaudo delle missioni coi bot: un bot gioca al posto del giocatore ogni
-- missione dei gironi (sim/campagna.lua) con tanti semi e a ogni livello, e
-- dice quante ne vince, in quanti turni e con quante stelle. Così si vede se
-- una missione si vince, se è troppo dura, dove mettere le soglie delle
-- stelle (la seconda alla mediana dei turni del bot normale) e se la
-- difficoltà sale lungo il girone. Con collaudo.senza nella missione rifà la
-- prova col bot senza la meccanica richiesta (per esempio senza teletrasporto):
-- lì non deve vincere mai; con collaudo.piano il bot segue quel piano a ogni
-- turno (sim/bot.lua, b.piano). Le lezioni no: sono rompicapi, li risolvono i
-- copioni di tests/campagna_test.lua.
--
--   luajit strumenti/arena/collaudo.lua [semi] [id della missione]
--
-- Scrive anche simulazione/arena/collaudo.md.
package.path = "client/?.lua;" .. package.path

local missioni = require "sim.missioni"
local campagna = require "sim.campagna"
local replay = require "sim.replay"

local SEMI = tonumber(arg[1]) or 12
local SOLO = arg[2]
local LIVELLI = { "facile", "normale", "difficile" }
-- tetto di tick per partita: 12 turni da 25 s
local TETTO = 12 * 26 * 60

local function copia(t)
	local o = {}
	for k, v in pairs(t) do o[k] = v end
	return o
end

-- Una missione giocata da un bot di livello livello; senza: campi del livello
-- tolti (la meccanica che manca). Restituisce l'esito, i turni e le stelle
local function gioca(l, livello, seme, senza)
	local r = missioni.nuova(l.id)
	local seed, mappa, opts = missioni.partita(r, seme)
	local c = l.collaudo or {}
	opts.players[1].bot, opts.players[1].carattere = livello, c.carattere
	local ric = replay.nuova(seed, mappa, opts)
	local g, bots = replay.partita(ric)
	if senza then
		local liv = copia(bots[1].liv)
		for k, v in pairs(senza) do liv[k] = v end
		bots[1].liv = liv
	end
	missioni.prepara(r, g)
	for _ = 1, TETTO do
		g:step(replay.input(ric, g, bots))
		for _, e in ipairs(g:pop_events()) do
			missioni.evento(r, g, e, bots)
			if e.type == "turn" and e.robot == missioni.GIOCATORE then bots[1].piano = c.piano end
		end
		local esito = missioni.tick(r, g)
		if esito then return esito, r.st.turni, missioni.quante(missioni.stelle(r)) end
	end
	return "tetto", r.st.turni, 0
end

local function mediana(t)
	if #t == 0 then return nil end
	table.sort(t)
	return t[math.floor((#t + 1) / 2)]
end

local righe = {
	"# Collaudo delle missioni coi bot",
	"",
	SEMI .. " partite per missione e livello: il bot gioca al posto tuo. Vinte in %, turni (mediana delle vinte), stelle in media.",
	"",
	"| Missione | Facile | Normale | Difficile | ★★ ora | ★★ dal bot | Senza la meccanica |",
	"| --- | --- | --- | --- | --- | --- | --- |",
}
for _, cap in ipairs(campagna.CAPITOLI) do
	if cap.id ~= "addestramento" then
		for _, l in ipairs(cap.missioni) do
			if not SOLO or SOLO == l.id then
				local celle, turni_normale = {}, {}
				for _, livello in ipairs(LIVELLI) do
					local vinte, stelle, turni = 0, 0, {}
					for s = 1, SEMI do
						local esito, n, st = gioca(l, livello, s * 101)
						if esito == "fatta" then
							vinte, stelle = vinte + 1, stelle + st
							turni[#turni + 1] = n
							if livello == "normale" then turni_normale[#turni_normale + 1] = n end
						end
					end
					celle[#celle + 1] = string.format("%d%% · %s t · %.1f★", math.floor(100 * vinte / SEMI + 0.5),
						tostring(mediana(turni) or "-"), vinte > 0 and stelle / vinte or 0)
				end
				local senza = "-"
				local c = l.collaudo
				if c and c.senza then
					local vinte = 0
					for s = 1, SEMI do
						if gioca(l, "difficile", s * 101, c.senza) == "fatta" then vinte = vinte + 1 end
					end
					senza = math.floor(100 * vinte / SEMI + 0.5) .. "%" .. (vinte == 0 and "" or " (DEVE ESSERE 0)")
				end
				local riga = string.format("| %s | %s | %s | %s | %s | %s | %s |", l.titolo, celle[1], celle[2], celle[3],
					tostring(l.stelle.turni), tostring(mediana(turni_normale) or "-"), senza)
				print(riga)
				righe[#righe + 1] = riga
			end
		end
	end
end

os.execute("mkdir -p simulazione/arena")
local f = io.open("simulazione/arena/collaudo.md", "w")
f:write(table.concat(righe, "\n") .. "\n")
f:close()
print("scritto simulazione/arena/collaudo.md")
