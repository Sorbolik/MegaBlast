-- Il controllo del Copione: legge i livelli della campagna (client/sim/levels.lua,
-- capitoli in client/sim/campaign.lua) e controlla che lo script di ogni livello
-- stia in piedi: niente funzioni (un livello deve poter viaggiare come JSON),
-- passi, eventi, armi, comandi e facce che esistono, segnaposto noti, punti
-- dentro la mappa. Gira in strumenti/controlli/tutti.sh. Dalla radice:
--   luajit strumenti/copione/controlla.lua
-- Finisce con "ok" o con un "FAIL" per ogni problema.
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local campaign = require "sim.campaign"

local errori = 0
local function male(dove, cosa)
	errori = errori + 1
	print("FAIL " .. dove .. ": " .. cosa)
end

local function insieme(lista)
	local t = {}
	for _, v in ipairs(lista) do t[v] = true end
	return t
end

-- gli eventi della simulazione (game:emit) che una riga può aspettare
local EVENTI = {}
for f in io.popen("ls client/sim/*.lua"):lines() do
	local h = assert(io.open(f))
	for tipo in h:read("*a"):gmatch('emit%(%{ type = "([%w_]+)"') do EVENTI[tipo] = true end
	h:close()
end

-- i comandi che si accendono (highlight) o si toccano (tocca): armi e oggetti,
-- più i comandi dell'HUD
local COMANDI = insieme({ "primaria", "secondaria", "cammina", "salta", "mira", "annulla", "baratto" })
for w in pairs(game.WEAPONS) do COMANDI[w] = true end
-- quello che una lezione mostra nell'HUD (vedi)
local VEDI = insieme({ "primarie", "secondarie", "teleport", "parachute", "tempo", "punti", "baratto" })
for w in pairs(game.WEAPONS) do VEDI[w] = true end
-- i disegni della vignetta grande (client/battle/vignette.lua, DRAW.<nome>) e le facce
local DISEGNI, FACCE = {}, {}
do
	local h = assert(io.open("client/battle/vignette.lua"))
	local src = h:read("*a")
	h:close()
	for nome in src:gmatch("\nDRAW%.([%w_]+) =") do DISEGNI[nome] = true end
	for nome in src:match("M%.FACCE = (%b{})"):gmatch("([%w_]+) = true") do FACCE[nome] = true end
end
-- i segnaposto dei testi ({salta}: come si salta coi comandi che hai, PAD.texts)
local SEGNAPOSTO = insieme({ "salta", "cammina", "mira", "annulla" })
local USATO = insieme({ "primaria", "secondaria", "attrezzo" })
-- le chiavi di un quando / fino (client/sim/missions.lua, when)
local CHIAVI = insieme({ "uno", "evento", "di", "arma", "passo", "turno", "turno_altri", "di_turno", "tocca",
	"usato", "finestra", "in_caduta", "corona", "conta", "almeno", "vicino" })
-- le mosse di Favilla quando mostra (client/sim/missions.lua, dimostra): un verbo ciascuna
local MOSSE = insieme({ "cammina", "salta", "arma", "aspetta", "dice", "posa" })
local LATI = insieme({ "destra", "sinistra", "su" })
-- i campi che accompagnano il verbo di una mossa
local EXTRA = insieme({ "angolo", "potenza", "secondi", "in_aria", "subito", "verso", "fino_a" })
-- le clip delle animazioni (client/battle/animations.lua) che Favilla può fare in posa
local CLIP = {}
do
	local h = assert(io.open("client/battle/animations.lua"))
	for nome in h:read("*a"):gmatch("\n\t([%w_]+) = { duration") do CLIP[nome] = true end
	h:close()
end
local MAPPA_W, MAPPA_H = 1920, 1080

-- niente funzioni, da nessuna parte
local function senza_funzioni(v, dove)
	if type(v) == "function" then
		male(dove, "è una funzione: il Copione vuole solo dati (verbi in client/sim/missions.lua)")
	elseif type(v) == "table" then
		for k, x in pairs(v) do senza_funzioni(x, dove .. "." .. tostring(k)) end
	end
end

local function testo(t, dove)
	if type(t) ~= "string" or t == "" then return male(dove, "manca il testo") end
	for nome in t:gmatch("{(%a+)}") do
		if not SEGNAPOSTO[nome] then male(dove, "segnaposto sconosciuto {" .. nome .. "}") end
	end
end

local function condizione(q, dove, passi)
	if type(q) ~= "table" then return male(dove, "non è una condizione") end
	if next(q) == nil then return male(dove, "condizione vuota") end
	for k in pairs(q) do
		if not CHIAVI[k] then male(dove, "chiave sconosciuta " .. tostring(k)) end
	end
	if q.evento and not EVENTI[q.evento] then male(dove, "evento sconosciuto " .. q.evento) end
	if (q.di or q.arma) and not q.evento then male(dove, "di e arma valgono solo con evento") end
	if q.di and q.di ~= "tu" and q.di ~= "altri" then male(dove, "di è tu o altri") end
	if q.di_turno and q.di_turno ~= "tu" and q.di_turno ~= "altri" then male(dove, "di_turno è tu o altri") end
	if q.arma and not game.WEAPONS[q.arma] then male(dove, "arma sconosciuta " .. q.arma) end
	if q.passo and not (passi[q.passo]) then male(dove, "il passo " .. tostring(q.passo) .. " non c'è") end
	if q.tocca and not COMANDI[q.tocca] then male(dove, "comando sconosciuto " .. q.tocca) end
	if q.usato and not USATO[q.usato] then male(dove, "usato è primaria, secondaria o attrezzo") end
	if q.corona and q.corona ~= "tu" then male(dove, "corona è tu") end
	if q.almeno and not q.conta then male(dove, "almeno vale solo con conta") end
	if q.vicino and not (type(q.vicino) == "number" and q.vicino > 0) then male(dove, "vicino è una distanza in pixel") end
	for i, o in ipairs(q.uno or {}) do condizione(o, dove .. ".uno[" .. i .. "]", passi) end
end

local function dentro(x, y, dove)
	if type(x) ~= "number" or x < 0 or x > MAPPA_W then male(dove, "x fuori dalla mappa") end
	if y ~= nil and (type(y) ~= "number" or y < 0 or y > MAPPA_H) then male(dove, "y fuori dalla mappa") end
end

-- I quattro tempi delle mosse nuove di un livello: { [passo] = { spiega, mostra, fai, bravo } }
-- per ogni passo con nuova = true. Spiega: una vignetta grande (o l'apertura) da
-- quando è finita la mossa nuova di prima; mostra: Favilla, la comparsa (guida) o
-- una sua dimostrazione dallo stesso momento; bravo: una riga con la faccia quando
-- il passo è fatto, o il bravo del livello se è l'ultimo passo.
-- Lo stesso calcolo è in pagina.html (tempi), per il Copione.
local M = {}
function M.tempi(l)
	local fuori, prima = {}, 0
	local passi = l.obiettivo or {}
	-- il momento di una condizione: il passo che aspetta (0: dall'inizio)
	local function momento(q)
		if q == nil then return 0 end
		return q.passo or (q.turno == 1 and 0) or nil
	end
	for i, p in ipairs(passi) do
		if p.nuova then
			local t = { fai = true }
			local function dentro_finestra(m) return m ~= nil and m >= prima and m <= i - 1 end
			if prima == 0 and l.goal_text then t.spiega = true end
			for _, r in ipairs(l.righe or {}) do
				if r.mostra == "grande" and dentro_finestra(momento(r.quando)) then t.spiega = true end
				if r.faccia and r.quando and r.quando.passo == i then t.bravo = true end
			end
			if i == #passi and l.bravo then t.bravo = true end
			if l.guida then t.mostra = true end
			for _, d in ipairs(l.dimostra or {}) do
				if dentro_finestra(momento(d.quando)) then t.mostra = true end
			end
			fuori[i] = t
			prima = i
		end
	end
	return fuori
end

local function livello(l, cap)
	local dove = l.id or "?"
	senza_funzioni(l, dove)
	testo(l.titolo, dove .. ".titolo")
	if l.goal_text then testo(l.goal_text, dove .. ".goal_text") end
	if l.highlight and not COMANDI[l.highlight] then male(dove, "highlight sconosciuto " .. l.highlight) end
	if not l.mappa and not l.arena then male(dove, "serve una mappa o un'arena") end
	local passi = {}
	for i, p in ipairs(l.obiettivo or {}) do
		passi[i] = true
		local dp = dove .. ".obiettivo[" .. i .. "]"
		testo(p.testo, dp)
		if p.reach then dentro(p.reach.x, p.reach.y, dp .. ".reach") end
		if p.prendi and not game.WEAPONS[p.prendi] then male(dp, "arma sconosciuta " .. p.prendi) end
		if p.con and not COMANDI[p.con] then male(dp, "arma sconosciuta " .. p.con) end
		for _, o in ipairs(p.only or {}) do
			if not COMANDI[o] then male(dp, "comando sconosciuto " .. o) end
		end
	end
	for i, r in ipairs(l.arena or {}) do
		local dr = dove .. ".arena[" .. i .. "]"
		dentro(r[1], r[2], dr)
		dentro(r[1] + r[3], r[2] + r[4], dr)
	end
	for i, s in ipairs(l.spawns or {}) do dentro(s.x, s.from, dove .. ".spawns[" .. i .. "]") end
	if l.spawns and #l.spawns < #(l.giocatori or {}) then male(dove, "meno punti di partenza che giocatori") end
	for _, nome in ipairs(l.vedi or {}) do
		if not VEDI[nome] then male(dove, "vedi: sconosciuto " .. nome) end
	end
	for _, campo in ipairs({ "casse", "cards" }) do
		for i, c in ipairs(l[campo] or {}) do
			local dc = dove .. "." .. campo .. "[" .. i .. "]"
			if not game.WEAPONS[c.arma] then male(dc, "arma sconosciuta " .. tostring(c.arma)) end
			if c.dopo ~= 0 and not passi[c.dopo] then male(dc, "il passo " .. tostring(c.dopo) .. " non c'è") end
			if c.x then dentro(c.x, nil, dc) end
		end
	end
	if l.scintilla then dentro(l.scintilla.x, l.scintilla.y, dove .. ".scintilla") end
	if l.guida then
		for i, pt in ipairs(l.guida.percorso or {}) do dentro(pt.x, pt.y, dove .. ".guida[" .. i .. "]") end
	end
	-- Favilla che mostra le mosse: un giocatore con insegna, della tua squadra
	local maestra = nil
	for i, p in ipairs(l.giocatori or {}) do
		if p.insegna then
			if maestra then male(dove, "due giocatori con insegna") end
			maestra = i
			if i == 1 then male(dove, "insegna: il primo giocatore sei tu") end
			if p.bot then male(dove, "insegna: Favilla non è un bot (si muove con le mosse di dimostra)") end
			if l.giocatori[1] and p.team ~= l.giocatori[1].team then male(dove, "insegna: Favilla è della tua squadra") end
		end
	end
	if l.dimostra and not maestra then male(dove, "dimostra senza un giocatore con insegna = true") end
	if maestra and l.guida then male(dove, "Favilla vera (insegna) e la comparsa (guida) insieme") end
	for i, d in ipairs(l.dimostra or {}) do
		local dd = dove .. ".dimostra[" .. i .. "]"
		if d.quando then condizione(d.quando, dd .. ".quando", passi) end
		if type(d.mosse) ~= "table" or #d.mosse == 0 then male(dd, "nessuna mossa") end
		for k, m in ipairs(d.mosse or {}) do
			local dm = dd .. ".mosse[" .. k .. "]"
			local n = 0
			for verbo in pairs(m) do
				if MOSSE[verbo] then n = n + 1 end
			end
			if n ~= 1 then male(dm, "ogni mossa ha un verbo solo (cammina, salta, arma, aspetta, dice, posa)") end
			for campo in pairs(m) do
				if not (MOSSE[campo] or EXTRA[campo]) then
					male(dm, "campo sconosciuto " .. tostring(campo))
				end
			end
			if m.cammina then dentro(m.cammina, nil, dm) end
			if m.salta and not LATI[m.salta] then male(dm, "salta è destra, sinistra o su") end
			if m.arma and not game.WEAPONS[m.arma] then male(dm, "arma sconosciuta " .. tostring(m.arma)) end
			if m.potenza and not (type(m.potenza) == "number" and m.potenza > 0 and m.potenza <= 1) then
				male(dm, "potenza da 0 a 1")
			end
			if m.aspetta and not (type(m.aspetta) == "number" and m.aspetta > 0) then male(dm, "aspetta: secondi") end
			if m.dice then testo(m.dice, dm) end
			if m.posa and not CLIP[m.posa] then male(dm, "posa: clip sconosciuta " .. tostring(m.posa)) end
			if m.in_aria and not m.salta then male(dm, "in_aria vale solo con salta") end
			if (m.subito or m.verso) and not m.arma then male(dm, "subito e verso valgono solo con arma") end
			if m.verso and not LATI[m.verso] then male(dm, "verso è destra o sinistra") end
			if m.fino_a and not m.verso then male(dm, "fino_a vale solo con verso") end
			if m.fino_a then dentro(m.fino_a, nil, dm) end
		end
	end
	for i, r in ipairs(l.righe or {}) do
		local dr = dove .. ".righe[" .. i .. "]"
		testo(r.testo, dr)
		condizione(r.quando, dr .. ".quando", passi)
		if r.fino then condizione(r.fino, dr .. ".fino", passi) end
		if r.highlight and not COMANDI[r.highlight] then male(dr, "highlight sconosciuto " .. r.highlight) end
		if r.faccia and not FACCE[r.faccia] then male(dr, "faccia sconosciuta " .. r.faccia) end
		if r.mostra ~= nil and r.mostra ~= "grande" and r.mostra ~= "striscia" then
			male(dr, "mostra è grande o striscia")
		end
		-- la vignetta grande ferma il gioco: si usa nelle lezioni, che aspettano te
		if r.mostra == "grande" and not cap.aspetta then male(dr, "vignetta grande fuori dalle lezioni") end
		if r.mostra == "grande" and r.highlight and not DISEGNI[r.highlight] then
			male(dr, "la vignetta grande non ha il disegno di " .. r.highlight .. " (client/battle/vignette.lua)")
		end
		if r.secondi ~= nil and not (type(r.secondi) == "number" and r.secondi > 0) then male(dr, "secondi: quanti") end
	end
	if l.bravo then testo(l.bravo, dove .. ".bravo") end
	if l.bravo_faccia and not FACCE[l.bravo_faccia] then male(dove, "faccia sconosciuta " .. l.bravo_faccia) end
	-- i quattro tempi di ogni mossa nuova (Sergio, 6 nov: Favilla spiega, la fa, la fai
	-- tu, ti dice brava): per ogni passo con nuova = true, dopo la mossa nuova di prima
	for i, t in pairs(M.tempi(l)) do
		for _, nome in ipairs({ "spiega", "mostra", "bravo" }) do
			if not t[nome] then male(dove .. ".obiettivo[" .. i .. "]", "mossa nuova senza «" .. nome .. "»") end
		end
	end
end

local visti, n = {}, 0
for _, cap in ipairs(campaign.CAPITOLI) do
	for _, l in ipairs(cap.missioni) do
		if visti[l.id] then male(l.id or "?", "id ripetuto") end
		visti[l.id] = true
		livello(l, cap)
		n = n + 1
	end
end
if errori == 0 then print("ok   " .. n .. " livelli del copione") end
os.exit(errori == 0 and 0 or 1)
