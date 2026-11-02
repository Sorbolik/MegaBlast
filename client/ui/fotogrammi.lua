-- Contatore dei fotogrammi: quanto dura davvero ogni frame, quali sono gli
-- scatti e perché (Sergio, 2 nov: "come facciamo a misurare gli FPS in maniera
-- affidabile e vedere cosa può avere introdotto dei cali?"). docs/prestazioni.md.
--
-- Misura il tempo vero fra un frame e il successivo (socket.gettime, non il dt
-- del motore) e lo confronta col frame normale (la mediana degli ultimi 10
-- secondi): uno SCATTO è un frame lungo più di 1,5 volte il normale (a 60 Hz,
-- un vsync perso). Per ogni scatto dice la causa più probabile:
--   - quella segnata da chi ha fatto un lavoro pesante (M.segna: "dipinto",
--     "maschera", "schermata ..."), nel frame prima o in questo;
--   - "gc" se la memoria di Lua è scesa (è passato il raccoglitore);
--   - "lua" se il frame prima gli script hanno lavorato più della metà dello scatto;
--   - altrimenti "motore" (disegno, GPU, sistema operativo).
--
-- Si accende dalle IMPOSTAZIONI (CONTATORE FPS): in alto al centro FPS, frame
-- peggiore, scatti dell'ultimo minuto e l'ultimo con la causa; ogni scatto va
-- anche nella console (quella dell'editor di Defold, sul PC). Nel simulatore è
-- sempre acceso e scrive le righe "SIMULA scatto" e "SIMULA fotogrammi" che
-- simula.py raccoglie in simulazione/fotogrammi.txt.
--
--   local fotogrammi = require "ui.fotogrammi"
--   fotogrammi.inizio()            -- in testa all'update della GUI, ogni frame
--   fotogrammi.fine()              -- in fondo allo stesso update
--   fotogrammi.segna("dipinto")    -- da chi fa un lavoro pesante (anche da altri script)
--   fotogrammi.testo()             -- la riga da mostrare (nil se non è cambiata)

local M = {}

-- ultimi 10 secondi a 60 Hz (a 120 Hz, 5 secondi)
local N = 600
local SCATTO = 1.5
-- ogni quanto si ricalcola il frame normale e la riga sullo schermo (secondi)
local OGNI = 0.25

local adesso = socket and socket.gettime or os.clock

M.acceso = false
-- nel simulatore: righe nel log per simula.py
M.log = false

local tempi = {}
for i = 1, N do tempi[i] = 0 end
local pos, pieni = 0, 0
local ordinati = {}
local normale = 1 / 60
local prima, inizio_lua, lavoro_lua = nil, nil, 0
local memoria
-- cause segnate in questo frame e nel frame prima
local cause, cause_prima = nil, nil
-- gli scatti (tempo, durata, causa) dell'ultimo minuto, in giro
local scatti, n_scatti = {}, 0
local orologio, calcolato = 0, 0
local riga_cambiata = false
-- il riassunto per il simulatore (dall'ultimo riassunto)
local riassunto = { n = 0, scatti = 0, peggiore = 0, peggiore_lua = 0, allocati = 0, t = 0 }

function M.segna(causa)
	cause = cause and (cause .. "+" .. causa) or causa
end

local function percentile(lista, n, p)
	if n == 0 then return 0 end
	return lista[math.max(1, math.min(n, math.ceil(n * p)))]
end

local function ricalcola()
	local n = pieni
	for i = 1, n do ordinati[i] = tempi[i] end
	for i = n + 1, #ordinati do ordinati[i] = nil end
	table.sort(ordinati)
	return n
end

-- in testa all'update della GUI: chiude il frame prima
function M.inizio()
	local t = adesso()
	inizio_lua = t
	local kb = collectgarbage("count")
	if not prima then
		prima, memoria = t, kb
		return
	end
	local dt = t - prima
	prima = t
	pos = pos % N + 1
	tempi[pos] = dt
	pieni = math.min(pieni + 1, N)
	orologio = orologio + dt
	-- la memoria di Lua: se è scesa è passato il raccoglitore
	local gc = kb < memoria
	if not gc then riassunto.allocati = riassunto.allocati + (kb - memoria) end
	memoria = kb

	riassunto.n = riassunto.n + 1
	riassunto.t = riassunto.t + dt
	if dt > riassunto.peggiore then riassunto.peggiore = dt end
	if lavoro_lua > riassunto.peggiore_lua then riassunto.peggiore_lua = lavoro_lua end

	-- il frame normale: la mediana, 4 volte al secondo
	if orologio - calcolato >= OGNI then
		calcolato = orologio
		normale = percentile(ordinati, ricalcola(), 0.5)
		riga_cambiata = true
	end

	if pieni >= 30 and dt > normale * SCATTO then
		local causa = cause_prima or cause
		if not causa then
			if gc then causa = "gc"
			elseif lavoro_lua > (dt - normale) * 0.5 then causa = "lua"
			else causa = "motore" end
		end
		n_scatti = n_scatti % 64 + 1
		scatti[n_scatti] = { orologio, dt, causa }
		riassunto.scatti = riassunto.scatti + 1
		M.ultimo = string.format("%s %.0f ms", causa, dt * 1000)
		riga_cambiata = true
		if M.acceso or M.log then
			print(string.format("%s %.1f ms (normale %.1f, lua %.1f ms) causa: %s",
				M.log and "SIMULA scatto" or "SCATTO", dt * 1000, normale * 1000, lavoro_lua * 1000, causa))
		end
	end
	cause_prima, cause = cause, nil
	lavoro_lua = 0
end

-- in fondo all'update della GUI: quanto hanno lavorato gli script
function M.fine()
	if not inizio_lua then return end
	lavoro_lua = lavoro_lua + adesso() - inizio_lua
end

-- il lavoro fatto fuori dall'update (on_input): t = M.ora() all'inizio
M.ora = adesso
function M.lavoro(t)
	lavoro_lua = lavoro_lua + adesso() - t
end

-- quanti scatti nell'ultimo minuto
local function scatti_minuto()
	local n = 0
	for i = 1, #scatti do
		if orologio - scatti[i][1] <= 60 then n = n + 1 end
	end
	return n
end

-- La riga sullo schermo, 4 volte al secondo (nil se non c'è niente di nuovo)
function M.testo()
	if not riga_cambiata then return nil end
	riga_cambiata = false
	local n = #ordinati
	if n == 0 then return nil end
	local secondi = 0
	for i = 1, n do secondi = secondi + tempi[i] end
	local riga = string.format("%.0f FPS  PEGGIORE %.0f MS  99%% SOTTO %.0f  SCATTI %d/MIN",
		n / secondi, ordinati[n] * 1000, percentile(ordinati, n, 0.99) * 1000, scatti_minuto())
	if M.ultimo then riga = riga .. "  ULTIMO: " .. string.upper(M.ultimo) end
	return riga
end

-- Nel simulatore, ogni tot secondi: una riga di riassunto da quella prima
function M.riassunto()
	local r = riassunto
	if r.n == 0 then return nil end
	local n = ricalcola()
	local riga = string.format(
		"SIMULA fotogrammi n=%d fps=%.1f p50=%.1f p95=%.1f p99=%.1f max=%.1f scatti=%d lua_max=%.1f kb_frame=%.1f",
		r.n, r.n / r.t, percentile(ordinati, n, 0.5) * 1000, percentile(ordinati, n, 0.95) * 1000,
		percentile(ordinati, n, 0.99) * 1000, r.peggiore * 1000, r.scatti, r.peggiore_lua * 1000, r.allocati / r.n)
	riassunto = { n = 0, scatti = 0, peggiore = 0, peggiore_lua = 0, allocati = 0, t = 0 }
	return riga
end

return M
