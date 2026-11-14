-- Collaudo delle missioni coi bot: un bot gioca al posto del giocatore ogni
-- missione dei gironi (sim/levels.lua) con tanti semi e a ogni livello, e
-- dice quante ne vince, in quanti turni, con quanti punti fatti e con
-- quante stelle. Così si vede se una missione si vince, se è troppo dura, dove
-- mettere le soglie delle stelle (Sergio 14 nov: la prima è la vittoria, la
-- seconda e la terza soglie dei punti fatti dal giocatore; la seconda alla
-- mediana dei punti del bot normale nelle vinte, la terza all'80° percentile)
-- e se la difficoltà sale lungo il girone. Con collaudo.senza nella missione rifà la
-- prova col bot senza la meccanica richiesta (per esempio senza teletrasporto):
-- lì non deve vincere mai; con collaudo.piano il bot segue quel piano a ogni
-- turno (sim/bot.lua, b.piano). Le lezioni no: sono rompicapi, li risolvono i
-- copioni di tests/campaign_test.lua.
--
-- La taratura delle stelle: per ogni missione la quota di vinte del bot normale
-- che prende la seconda e la terza stella, e cosa guardare (DA GUARDARE) quando
-- le soglie non vanno più bene: la seconda o la terza prese da troppe o troppo
-- poche vinte, la missione troppo dura. Con --vita prova
-- la vita degli avversari moltiplicata (0.5 metà, 2 doppia) e dice come cambiano
-- le soglie: quello che succederebbe cambiando la vita dei bot, senza cambiarla.
-- Con --ritocchi file.lua (function(config, game), come l'arena) prova qualunque
-- altro numero del gioco.
-- Dalla Forgia i bot avversari hanno un pezzo uppato col progresso della
-- campagna e il bot che gioca al posto tuo ha lo stesso (il giocatore atteso,
-- Sergio 14 nov): le stelle si tarano su di lui. Con --minimo gioca coi pezzi al
-- minimo: se passa tutto, la campagna è troppo facile.
--
--   luajit tools/arena/collaudo.lua [semi] [id della missione]
--   luajit tools/arena/collaudo.lua 12 --vita 0.5,1,2
--   luajit tools/arena/collaudo.lua 12 --ritocchi danni.lua
--   luajit tools/arena/collaudo.lua 12 --minimo     -- il giocatore coi pezzi al minimo: non deve passare tutto
--   luajit tools/arena/collaudo.lua 12 --avvisi     -- anche gli avvisi per GitHub (::warning::)
--
-- Scrive anche simulazione/arena/collaudo.md.
package.path = "client/?.lua;" .. package.path

local missioni = require "sim.missions"
local campagna = require "sim.campaign"
local replay = require "sim.replay"
local config = require "sim.config"
local game = require "sim.game"

local SEMI, SOLO, VITE, RITOCCHI, AVVISI, MINIMO = 12, nil, nil, nil, false, false
do
	local k = 1
	while arg[k] do
		local a = arg[k]
		if a == "--vita" then
			VITE = {}
			for x in arg[k + 1]:gmatch("[^,]+") do VITE[#VITE + 1] = tonumber(x) end
			k = k + 1
		elseif a == "--ritocchi" then
			RITOCCHI = arg[k + 1]
			k = k + 1
		elseif a == "--minimo" then
			MINIMO = true
		elseif a == "--avvisi" then
			AVVISI = true
		elseif tonumber(a) then
			SEMI = tonumber(a)
		else
			SOLO = a
		end
		k = k + 1
	end
end
if RITOCCHI then dofile(RITOCCHI)(config, game) end
local LIVELLI = { "facile", "normale", "difficile" }
-- tetto di tick per partita: 12 turni da 25 s; le partite vere (senza limite
-- di turni) fino alla fine del tempo, con l'ultimo giro
local TETTO = 12 * 26 * 60
local TETTO_PARTITA = 8 * 60 * 60
-- quando una soglia è da guardare: la seconda stella presa da meno del 35% o da
-- più del 65% delle vinte del bot normale (è alla mediana: la metà), la terza
-- da meno del 5% o da più del 35% (è all'80° percentile: un quinto), il bot
-- normale che ne vince meno del 60%. L'avviso dice dove guardare, la scelta
-- resta a chi fa la PR
local VINTE_MINIMO = 0.6
local PUNTI_DURO, PUNTI_FACILE = 0.35, 0.65
local TERZA_DURO, TERZA_FACILE = 0.05, 0.35

local function copia(t)
	local o = {}
	for k, v in pairs(t) do o[k] = v end
	return o
end

-- Una missione giocata da un bot di livello livello; senza: campi del livello
-- tolti (la meccanica che manca); vita: la vita degli avversari moltiplicata.
-- Restituisce l'esito, i turni, i punti fatti dal giocatore e le stelle (una per criterio)
local function gioca(l, livello, seme, senza, vita)
	local r = missioni.new(l.id)
	-- il giocatore che la campagna si aspetta (Sergio, 14 nov): un pezzo uppato
	-- lungo la stessa linea dei bot; con --minimo i pezzi al minimo (base)
	local seed, mappa, opts = missioni.match(r, seme, nil, nil, not MINIMO and missioni.expected_stats(l) or nil)
	local c = l.collaudo or {}
	opts.players[1].bot, opts.players[1].carattere = livello, c.carattere
	local ric = replay.new(seed, mappa, opts)
	local g, bots = replay.match(ric)
	if senza then
		local liv = copia(bots[1].liv)
		for k, v in pairs(senza) do liv[k] = v end
		bots[1].liv = liv
	end
	missioni.prepare(r, g)
	if vita and vita ~= 1 then
		for _, rb in ipairs(g.robots) do
			if rb.team ~= g.robots[missioni.GIOCATORE].team then
				rb.max_hp = math.max(1, math.floor(rb.max_hp * vita + 0.5))
				rb.hp = rb.max_hp
			end
		end
	end
	for _ = 1, l.turni and TETTO or TETTO_PARTITA do
		g:step(replay.input(ric, g, bots))
		for _, e in ipairs(g:pop_events()) do
			missioni.event(r, g, e, bots)
			if e.type == "turn" and e.robot == missioni.GIOCATORE then bots[1].piano = c.piano end
		end
		local esito = missioni.tick(r, g)
		if esito then return esito, r.st.turni, missioni.points(r), missioni.stars(r) end
	end
	return "tetto", r.st.turni, nil, { false, false, false }
end

local function mediana(t)
	if #t == 0 then return nil end
	table.sort(t)
	return t[math.floor((#t + 1) / 2)]
end

-- il valore sotto cui sta la quota q della lista (0.8: l'80° percentile)
local function percentile(t, q)
	if #t == 0 then return nil end
	table.sort(t)
	return t[math.max(1, math.ceil(q * #t))]
end

-- Un livello per SEMI partite: vinte, turni e punti fatti nelle vinte,
-- quante vinte con la seconda e con la terza stella
local function prova(l, livello, vita)
	local p = { vinte = 0, turni = {}, punti = {}, seconda = 0, terza = 0 }
	for s = 1, SEMI do
		local esito, n, v, st = gioca(l, livello, s * 101, nil, vita)
		if esito == "fatta" then
			p.vinte = p.vinte + 1
			p.turni[#p.turni + 1] = n
			p.punti[#p.punti + 1] = v
			if st[2] then p.seconda = p.seconda + 1 end
			if st[3] then p.terza = p.terza + 1 end
		end
	end
	p.mediana = mediana(p.turni)
	p.alta = percentile(p.punti, 0.8)
	p.fatti = mediana(p.punti)
	return p
end

local function pc(x, n)
	return n > 0 and math.floor(100 * x / n + 0.5) .. "%" or "-"
end

local function missioni_girone()
	local out = {}
	for _, cap in ipairs(campagna.CAPITOLI) do
		if cap.id ~= "addestramento" then
			for _, l in ipairs(cap.missioni) do
				if not SOLO or SOLO == l.id then out[#out + 1] = l end
			end
		end
	end
	return out
end

-- Cosa guardare nelle stelle di una missione, dal bot normale
local function da_guardare(l, n, d)
	local out = {}
	-- se nemmeno il bot difficile la vince non è la missione che è dura: è il
	-- bot che non la sa giocare (un rompicapo), e le stelle si tarano a mano
	if d.vinte < 0.3 * SEMI then
		return { "il bot non la sa giocare (il difficile ne vince " .. pc(d.vinte, SEMI) .. "): stelle da tarare a mano" }
	end
	if n.vinte < VINTE_MINIMO * SEMI then
		out[#out + 1] = "troppo dura: il bot normale ne vince " .. pc(n.vinte, SEMI)
	end
	local s = l.stelle
	if s.punti and n.vinte > 0 then
		local q = n.seconda / n.vinte
		if q < PUNTI_DURO or q > PUNTI_FACILE then
			out[#out + 1] = string.format("★★ con %d punti la prende il %s delle vinte: %s a %d (la mediana)",
				s.punti[1], pc(n.seconda, n.vinte), q < PUNTI_DURO and "abbassa" or "alza", n.fatti)
		end
		q = n.terza / n.vinte
		if q < TERZA_DURO or q > TERZA_FACILE then
			out[#out + 1] = string.format("★★★ con %d punti la prende il %s delle vinte: %s a %d (l'80° percentile)",
				s.punti[2], pc(n.terza, n.vinte), q < TERZA_DURO and "abbassa" or "alza", n.alta)
		end
	end
	return out
end

local righe = {
	"# Collaudo delle missioni coi bot",
	"",
	SEMI .. " partite per missione e livello: il bot gioca al posto tuo. Vinte in %, turni e punti fatti "
		.. "(mediana delle vinte), stelle in media. Soglie ora: i punti che chiedono la ★★ e la ★★★; dal bot: la mediana "
		.. "e l'80° percentile del bot normale. ★★ e ★★★: quante delle vinte dal bot normale le prendono."
		.. (RITOCCHI and (" Con i ritocchi di " .. RITOCCHI .. ".") or ""),
	"",
	"| Missione | Facile | Normale | Difficile | Soglie ora | Dal bot | ★★ / ★★★ | Senza la meccanica | Da guardare |",
	"| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
}
local avvisi = {}
local elenco = missioni_girone()
for _, l in ipairs(elenco) do
	local celle, normale, difficile = {}, nil, nil
	for _, livello in ipairs(LIVELLI) do
		local p = prova(l, livello)
		if livello == "normale" then normale = p end
		if livello == "difficile" then difficile = p end
		local stelle = p.vinte + p.seconda + p.terza
		celle[#celle + 1] = string.format("%s · %s t · %s p · %.1f★", pc(p.vinte, SEMI), tostring(p.mediana or "-"),
			tostring(p.fatti or "-"), p.vinte > 0 and stelle / p.vinte or 0)
	end
	local senza = "-"
	local c = l.collaudo
	if c and c.senza then
		local vinte = 0
		for s = 1, SEMI do
			if gioca(l, "difficile", s * 101, c.senza) == "fatta" then vinte = vinte + 1 end
		end
		senza = pc(vinte, SEMI) .. (vinte == 0 and "" or " (DEVE ESSERE 0)")
	end
	local guarda = da_guardare(l, normale, difficile)
	for _, a in ipairs(guarda) do avvisi[#avvisi + 1] = l.titolo .. ": " .. a end
	local riga = string.format("| %s | %s | %s | %s | %s | %s | %s / %s | %s | %s |", l.titolo, celle[1], celle[2], celle[3],
		l.stelle.punti[1] .. " / " .. l.stelle.punti[2], tostring(normale.fatti or "-") .. " / " .. tostring(normale.alta or "-"),
		pc(normale.seconda, normale.vinte),
		pc(normale.terza, normale.vinte), senza, #guarda > 0 and table.concat(guarda, "; ") or "ok")
	print(riga)
	righe[#righe + 1] = riga
end

-- Come cambiano le soglie con la vita degli avversari moltiplicata
if VITE then
	righe[#righe + 1] = ""
	righe[#righe + 1] = "## Se cambia la vita degli avversari"
	righe[#righe + 1] = ""
	righe[#righe + 1] = "Bot normale al posto tuo. Per ogni vita: vinte, punti fatti (mediana: dove andrebbe "
		.. "la ★★), quante delle vinte prendono la ★★★. Ogni raddoppio: di quanti punti si sposta la ★★."
	righe[#righe + 1] = ""
	local testa, sotto = "| Missione |", "| --- |"
	for _, v in ipairs(VITE) do
		testa, sotto = testa .. " vita ×" .. v .. " |", sotto .. " --- |"
	end
	righe[#righe + 1] = testa .. " ogni raddoppio |"
	righe[#righe + 1] = sotto .. " --- |"
	for _, l in ipairs(elenco) do
		local riga, punti = "| " .. l.titolo .. " |", {}
		for _, v in ipairs(VITE) do
			local p = prova(l, "normale", v)
			riga = riga .. string.format(" %s · %s p · ★★★ %s |", pc(p.vinte, SEMI), tostring(p.fatti or "-"),
				pc(p.terza, p.vinte))
			if p.fatti then punti[#punti + 1] = { math.log(v) / math.log(2), p.fatti } end
		end
		-- la pendenza (minimi quadrati) dei punti sul logaritmo in base 2 della vita
		local pendenza = "-"
		if #punti >= 2 then
			local sx, sy, sxx, sxy = 0, 0, 0, 0
			for _, q in ipairs(punti) do
				sx, sy, sxx, sxy = sx + q[1], sy + q[2], sxx + q[1] * q[1], sxy + q[1] * q[2]
			end
			local d = #punti * sxx - sx * sx
			if d > 0 then pendenza = string.format("%+.0f punti", (#punti * sxy - sx * sy) / d) end
		end
		riga = riga .. " " .. pendenza .. " |"
		print(riga)
		righe[#righe + 1] = riga
	end
end

if #avvisi > 0 then
	righe[#righe + 1] = ""
	righe[#righe + 1] = "## Da guardare"
	righe[#righe + 1] = ""
	for _, a in ipairs(avvisi) do
		righe[#righe + 1] = "- " .. a
		if AVVISI then print("::warning title=Stelle della campagna::" .. a) end
	end
end

os.execute("mkdir -p simulazione/arena")
local f = io.open("simulazione/arena/collaudo.md", "w")
f:write(table.concat(righe, "\n") .. "\n")
f:close()
print("scritto simulazione/arena/collaudo.md")
