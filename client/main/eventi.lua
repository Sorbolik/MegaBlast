-- Gli eventi del server (GET /eventi, server/eventi.go): il gioco li chiede
-- quando si apre la home e poi ogni minuto mentre la home si vede. Qui solo i
-- dati e le parole; le schermate sono menu/bacheca.lua e menu/coda.lua.
--
--   local eventi = require "main.eventi"
--   eventi.carica(server_url, function() ... end)   -- ws://host/ws -> http://host/eventi
--   eventi.in_corso(), eventi.prossimi()             -- liste di occorrenze, in ordine di inizio
--   eventi.su_coda("2v2")                            -- quelli in corso che contano per quella coda
--   eventi.riga_home()                               -- la riga sotto EVENTI nella home
--   eventi.cosa_cambia(o, nomi)                      -- le regole in parole ("Casse ogni 2 turni")
--
-- Un'occorrenza: { id, evento, tipo = mod|torneo|sfida|xp, nome, riga, da, a,
-- torna, coda, modo, giocatori, regole, premi }. da, a, torna in secondi Unix.

local M = {}

M.lista = {}      -- le occorrenze dell'ultima risposta
M.scarto = 0      -- ora del server meno ora del telefono
M.caricato = false

-- L'ora del server (il telefono può avere l'orologio avanti o indietro)
function M.ora()
	return os.time() + M.scarto
end

function M.leggi(risposta, adesso)
	local ok, d = pcall(json.decode, risposta)
	if not ok or type(d) ~= "table" or type(d.eventi) ~= "table" then return false end
	M.lista = d.eventi
	M.scarto = (d.ora or adesso) - adesso
	M.caricato = true
	return true
end

local function url_eventi(ws_url)
	local u = ws_url:gsub("^ws", "http")
	return (u:gsub("/ws$", "")) .. "/eventi"
end

function M.carica(ws_url, fatto)
	if not http then return end
	http.request(url_eventi(ws_url), "GET", function(_, _, res)
		if res.status == 200 and M.leggi(res.response, os.time()) and fatto then fatto() end
	end)
end

function M.in_corso(adesso)
	adesso = adesso or M.ora()
	local out = {}
	for _, o in ipairs(M.lista) do
		if o.da <= adesso and adesso < o.a then out[#out + 1] = o end
	end
	return out
end

function M.prossimi(adesso)
	adesso = adesso or M.ora()
	local out = {}
	for _, o in ipairs(M.lista) do
		if o.da > adesso then out[#out + 1] = o end
	end
	return out
end

-- Gli eventi in corso che stanno su una coda normale (Torneo, Sfida, XP):
-- una partita in quella coda conta anche per loro
function M.su_coda(coda, adesso)
	local out = {}
	for _, o in ipairs(M.in_corso(adesso)) do
		if o.coda == coda then out[#out + 1] = o end
	end
	return out
end

-- Gli eventi in corso con la coda loro (i modificatori)
function M.con_coda(adesso)
	local out = {}
	for _, o in ipairs(M.in_corso(adesso)) do
		if o.coda ~= o.modo then out[#out + 1] = o end
	end
	return out
end

-- 2g 3h, 3h 20m, 12m
function M.durata(s)
	s = math.max(0, s)
	local g, h, m = math.floor(s / 86400), math.floor(s % 86400 / 3600), math.floor(s % 3600 / 60)
	if g > 0 then return h > 0 and (g .. "g " .. h .. "h") or (g .. "g") end
	if h > 0 then return m > 0 and (h .. "h " .. m .. "m") or (h .. "h") end
	return math.max(m, 1) .. "m"
end

function M.quando(o, adesso)
	adesso = adesso or M.ora()
	if o.da > adesso then return "comincia tra " .. M.durata(o.da - adesso) end
	return "finisce tra " .. M.durata(o.a - adesso)
end

-- La riga sotto EVENTI nella home: niente numeri rossi, solo cosa succede
function M.riga_home(adesso)
	if not M.caricato then return "" end
	local ora = M.in_corso(adesso)
	if #ora == 1 then return ora[1].nome end
	if #ora > 1 then return #ora .. " in corso" end
	local dopo = M.prossimi(adesso)[1]
	if dopo then return "il prossimo tra " .. M.durata(dopo.da - (adesso or M.ora())) end
	return "nessuno in programma"
end

local TIPI = { mod = "MODIFICATORE", torneo = "TORNEO", sfida = "SFIDA", xp = "XP" }
function M.tipo(o) return TIPI[o.tipo] or string.upper(o.tipo or "") end

local CODE = { ["1v1"] = "1 CONTRO 1", ["2v2"] = "2 CONTRO 2", ffa = "TUTTI CONTRO TUTTI" }
function M.nome_coda(modo) return CODE[modo] or modo end

-- Le regole in parole, una per riga (sim/regole.lua). nomi: arma -> nome (battaglia/hud.lua)
function M.cosa_cambia(o, nomi)
	local r, out = o.regole or {}, {}
	if o.coda ~= o.modo then out[#out + 1] = M.nome_coda(o.modo) end
	if r.armi then
		local n = {}
		for i, w in ipairs(r.armi) do n[i] = (nomi and nomi[w]) or w end
		out[#out + 1] = "Armi: " .. table.concat(n, ", ")
	end
	if r.casse then out[#out + 1] = r.casse == 1 and "Una cassa a ogni turno" or ("Casse ogni " .. r.casse .. " turni") end
	if r.cure == false then out[#out + 1] = "Niente cure" end
	if r.livello == "fisso" then out[#out + 1] = "Tutti allo stesso livello" end
	if r.punti then out[#out + 1] = "Punti diversi" end
	if #out == 0 then out[1] = o.coda == o.modo and ("Le partite normali " .. M.nome_coda(o.coda)) or "Regole normali" end
	return out
end

return M
