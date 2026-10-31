-- Collaudo delle missioni coi bot: un bot gioca al posto del giocatore ogni
-- missione dei gironi (sim/campagna.lua) con tanti semi e a ogni livello, e
-- dice quante ne vince, in quanti turni, con quanti punti di vantaggio e con
-- quante stelle. Così si vede se una missione si vince, se è troppo dura, dove
-- mettere le soglie delle stelle (la seconda alla mediana dei punti di
-- vantaggio del bot normale, Sergio 31 ott: non più i turni) e se la
-- difficoltà sale lungo il girone. Con collaudo.senza nella missione rifà la
-- prova col bot senza la meccanica richiesta (per esempio senza teletrasporto):
-- lì non deve vincere mai; con collaudo.piano il bot segue quel piano a ogni
-- turno (sim/bot.lua, b.piano). Le lezioni no: sono rompicapi, li risolvono i
-- copioni di tests/campagna_test.lua.
--
-- La taratura delle stelle: per ogni missione la quota di vinte del bot normale
-- che prende la seconda e la terza stella, e cosa guardare (DA GUARDARE) quando
-- le soglie non vanno più bene: la seconda presa da troppe o troppo poche vinte, il
-- bonus quasi impossibile o regalato, la missione troppo dura. Con --vita prova
-- la vita degli avversari moltiplicata (0.5 metà, 2 doppia) e dice come cambiano
-- le soglie: quello che succederebbe cambiando la vita dei bot, senza cambiarla.
-- Con --ritocchi file.lua (function(config, game), come l'arena) prova qualunque
-- altro numero del gioco.
--
--   luajit strumenti/arena/collaudo.lua [semi] [id della missione]
--   luajit strumenti/arena/collaudo.lua 12 --vita 0.5,1,2
--   luajit strumenti/arena/collaudo.lua 12 --ritocchi danni.lua
--   luajit strumenti/arena/collaudo.lua 12 --avvisi     -- anche gli avvisi per GitHub (::warning::)
--
-- Scrive anche simulazione/arena/collaudo.md.
package.path = "client/?.lua;" .. package.path

local missioni = require "sim.missioni"
local campagna = require "sim.campagna"
local replay = require "sim.replay"
local config = require "sim.config"
local game = require "sim.game"

local SEMI, SOLO, VITE, RITOCCHI, AVVISI = 12, nil, nil, nil, false
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
-- più del 65% delle vinte del bot normale (è alla mediana: la metà), il bonus in meno del 15% o più dell'85% delle vinte, il bot
-- normale che ne vince meno del 60%. Il bot non è un giocatore: un bonus che
-- chiede una mossa precisa (buttare nel vuoto) lui non lo cerca, uno come
-- "senza morire" gli riesce più facile che a una persona; l'avviso dice dove
-- guardare, la scelta resta a chi fa la PR
local BONUS_DURO, BONUS_FACILE, VINTE_MINIMO = 0.15, 0.85, 0.6
local PUNTI_DURO, PUNTI_FACILE = 0.35, 0.65

local function copia(t)
	local o = {}
	for k, v in pairs(t) do o[k] = v end
	return o
end

-- Una missione giocata da un bot di livello livello; senza: campi del livello
-- tolti (la meccanica che manca); vita: la vita degli avversari moltiplicata.
-- Restituisce l'esito, i turni, i punti di vantaggio e le stelle (una per criterio)
local function gioca(l, livello, seme, senza, vita)
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
			missioni.evento(r, g, e, bots)
			if e.type == "turn" and e.robot == missioni.GIOCATORE then bots[1].piano = c.piano end
		end
		local esito = missioni.tick(r, g)
		if esito then return esito, r.st.turni, missioni.vantaggio(r), missioni.stelle(r) end
	end
	return "tetto", r.st.turni, nil, { false, false, false }
end

local function mediana(t)
	if #t == 0 then return nil end
	table.sort(t)
	return t[math.floor((#t + 1) / 2)]
end

-- Un livello per SEMI partite: vinte, turni e punti di vantaggio delle vinte,
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
	p.vantaggio = mediana(p.punti)
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
			out[#out + 1] = string.format("★★ con %d punti di vantaggio la prende il %s delle vinte: %s a %d (la mediana)",
				s.punti, pc(n.seconda, n.vinte), q < PUNTI_DURO and "abbassa" or "alza", n.vantaggio)
		end
	end
	if n.vinte > 0 and (s.bonus or s.bonus2) then
		local q = n.terza / n.vinte
		if q < BONUS_DURO then
			out[#out + 1] = "★★★ quasi impossibile (" .. pc(n.terza, n.vinte) .. " delle vinte)"
		elseif q > BONUS_FACILE then
			out[#out + 1] = "★★★ regalata (" .. pc(n.terza, n.vinte) .. " delle vinte)"
		end
	end
	return out
end

local righe = {
	"# Collaudo delle missioni coi bot",
	"",
	SEMI .. " partite per missione e livello: il bot gioca al posto tuo. Vinte in %, turni e punti di vantaggio "
		.. "(mediana delle vinte), stelle in media. ★★ ora: i punti di vantaggio che chiede; ★★ dal bot: la mediana "
		.. "del bot normale. ★★ e ★★★: quante delle vinte dal bot normale le prendono."
		.. (RITOCCHI and (" Con i ritocchi di " .. RITOCCHI .. ".") or ""),
	"",
	"| Missione | Facile | Normale | Difficile | ★★ ora | ★★ dal bot | ★★ / ★★★ | Senza la meccanica | Da guardare |",
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
			tostring(p.vantaggio or "-"), p.vinte > 0 and stelle / p.vinte or 0)
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
		tostring(l.stelle.punti or "-"), tostring(normale.vantaggio or "-"), pc(normale.seconda, normale.vinte),
		pc(normale.terza, normale.vinte), senza, #guarda > 0 and table.concat(guarda, "; ") or "ok")
	print(riga)
	righe[#righe + 1] = riga
end

-- Come cambiano le soglie con la vita degli avversari moltiplicata
if VITE then
	righe[#righe + 1] = ""
	righe[#righe + 1] = "## Se cambia la vita degli avversari"
	righe[#righe + 1] = ""
	righe[#righe + 1] = "Bot normale al posto tuo. Per ogni vita: vinte, punti di vantaggio (mediana: dove andrebbe "
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
			riga = riga .. string.format(" %s · %s p · ★★★ %s |", pc(p.vinte, SEMI), tostring(p.vantaggio or "-"),
				pc(p.terza, p.vinte))
			if p.vantaggio then punti[#punti + 1] = { math.log(v) / math.log(2), p.vantaggio } end
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
