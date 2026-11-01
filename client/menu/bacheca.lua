-- La bacheca degli eventi (EVENTI della home). A sinistra ORA: gli eventi in
-- corso, una carta ciascuno. A destra PROSSIMI: le due settimane, un giorno per
-- casella con una barretta per evento, e sotto i prossimi in fila. Un tocco su
-- un evento apre il dettaglio: cosa cambia, dove si gioca, quando torna, i premi
-- e GIOCA (se è in corso). Niente numeri rossi né finestre sopra: si guarda e
-- basta. Stile in ui/ui.lua, eventi da main/eventi.lua (server/eventi.go).
--
--   local bacheca = require "menu.bacheca"
--   local b = bacheca.new(nomi)   -- nomi: arma -> nome (battaglia/hud.lua)
--   local fine = bacheca.on_input(b, action_id, action)
--     -- "indietro", { coda = ... } per giocare, o nil
--   bacheca.distruggi(b)

local ui = require "ui.ui"
local eventi = require "main.eventi"

local M = {}

local GIORNI = { "dom", "lun", "mar", "mer", "gio", "ven", "sab" }
local MESI = { "gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic" }

local function vec(x, y) return vmath.vector3(x, y, 0) end

-- il colore di ogni tipo di evento
local function colore(o)
	local C = ui.C
	return ({ mod = C.BRACE, torneo = ui.ORO, sfida = C.ACCIAIO, xp = C.MENTA })[o.tipo] or C.LUCE
end

local function riga(t, x, y, scala, col, parent, w)
	local n = ui.testo(t, x, y, scala, col, parent)
	gui.set_pivot(n, w and gui.PIVOT_NW or gui.PIVOT_W)
	if w then
		gui.set_line_break(n, true)
		gui.set_size(n, vec(w / (scala * 0.5), 300))
	end
	return n
end

local function a_destra(t, x, y, scala, col, parent)
	local n = ui.testo(t, x, y, scala, col, parent)
	gui.set_pivot(n, gui.PIVOT_E)
	return n
end

-- "lun 16 nov"; con ora "lun 16 nov 10:00"
local function giorno(t, ora)
	local d = os.date("*t", t)
	local s = GIORNI[d.wday] .. " " .. d.day .. " " .. MESI[d.month]
	if ora then s = s .. string.format(" %02d:%02d", d.hour, d.min) end
	return s
end

-- mezzanotte del giorno di t
local function mezzanotte(t)
	local d = os.date("*t", t)
	d.hour, d.min, d.sec = 0, 0, 0
	return os.time(d)
end

local function barra(x, y, w, h, col, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, col)
	gui.set_parent(n, parent)
	return n
end

-- ORA: le carte degli eventi in corso
local function ora(b, adesso)
	local C = ui.C
	riga("ORA", 48, 560, 0.6, C.SPENTO, b.radice)
	local lista = eventi.in_corso(adesso)
	if #lista == 0 then
		riga("Nessun evento in corso", 48, 500, 0.75, C.TESTO, b.radice)
		return
	end
	local w, h = 560, 128
	for i, o in ipairs(lista) do
		if i > 3 then break end
		local y = 520 - (i - 1) * (h + 16) - h / 2
		local n = ui.bottone(b.bottoni, 48 + w / 2, y, w, h, "", "evento:" .. o.id, nil, b.radice)
		local bt = b.bottoni[#b.bottoni]
		bt.riposo = colore(o)
		gui.set_color(bt.bordo, bt.riposo)
		local x0, y0 = -w / 2 + 24, h / 2 - 26
		riga(eventi.tipo(o), x0, y0, 0.6, colore(o), n)
		a_destra(eventi.quando(o, adesso), w / 2 - 24, y0, 0.6, C.SPENTO, n)
		riga(o.nome, x0, y0 - 42, 0.95, C.TESTO, n)
		local dove = o.coda == o.modo and ("conta nelle partite " .. eventi.nome_coda(o.coda)) or ("coda sua · " .. eventi.nome_coda(o.modo))
		riga(dove, x0, -h / 2 + 24, 0.6, C.SPENTO, n)
	end
end

-- PROSSIMI: due settimane da lunedì, poi i prossimi in fila
local function prossimi(b, adesso)
	local C = ui.C
	local x0 = 680
	riga("PROSSIMI", x0, 560, 0.6, C.SPENTO, b.radice)
	local oggi = mezzanotte(adesso)
	local wday = os.date("*t", oggi).wday
	-- il lunedì di questa settimana (a mezzogiorno: niente sorprese col cambio dell'ora)
	local lunedi = oggi + 43200 - ((wday + 5) % 7) * 86400
	local cw, ch, gap = 76, 70, 4
	for s = 0, 1 do
		local y = 490 - s * (ch + 30)
		for g = 0, 6 do
			local t = mezzanotte(lunedi + (s * 7 + g) * 86400)
			local fine = mezzanotte(t + 86400 + 43200)
			local x = x0 + g * (cw + gap) + cw / 2
			local n, bordo = ui.pannello(x, y, cw, ch, b.radice)
			if t == oggi then gui.set_color(bordo, C.LUCE) end
			local d = os.date("*t", t)
			ui.testo((s == 0 and GIORNI[d.wday] .. " " or "") .. d.day, 0, ch / 2 - 16, 0.55, t < oggi and C.SPENTO or C.TESTO, n)
			-- una barretta per ogni evento di quel giorno
			local k = 0
			for _, o in ipairs(eventi.lista) do
				if o.da < fine and o.a > t and k < 3 then
					barra(0, ch / 2 - 38 - k * 10, cw - 16, 6, colore(o), n)
					k = k + 1
				end
			end
		end
	end
	-- in fila: i prossimi che cominciano (anche quelli che tornano)
	local y = 300
	local lista = eventi.prossimi(adesso)
	if #lista == 0 then riga("Niente in programma", x0, y, 0.65, C.SPENTO, b.radice) end
	for i, o in ipairs(lista) do
		if i > 4 then break end
		local w, h = 7 * (cw + gap) - gap, 52
		local n = ui.bottone(b.bottoni, x0 + w / 2, y - (i - 1) * (h + 10), w, h, "", "evento:" .. o.id, nil, b.radice)
		barra(-w / 2 + 14, 0, 8, h - 20, colore(o), n)
		riga(o.nome, -w / 2 + 32, 0, 0.7, C.TESTO, n)
		a_destra(giorno(o.da, true), w / 2 - 16, 0, 0.6, C.SPENTO, n)
	end
end

-- Il dettaglio di un evento
local function dettaglio(b, o, adesso)
	local C = ui.C
	riga(eventi.tipo(o), 48, 590, 0.6, colore(o), b.radice)
	riga(eventi.quando(o, adesso), 48 + 260, 590, 0.6, C.SPENTO, b.radice)
	gui.set_pivot(ui.titolo(o.nome, 48, 540, 0.9, C.LUCE, b.radice), gui.PIVOT_W)
	if o.riga and o.riga ~= "" then riga(o.riga, 48, 500, 0.65, C.TESTO, b.radice, 640) end

	riga("COSA CAMBIA", 48, 410, 0.65, C.SPENTO, b.radice)
	for i, t in ipairs(eventi.cosa_cambia(o, b.nomi)) do
		if i > 4 then break end
		local n = ui.pannello(48 + 300, 370 - (i - 1) * 52, 600, 44, b.radice)
		riga(t, -300 + 20, 0, 0.7, C.TESTO, n)
	end
	local quando = giorno(o.da, true) .. "  fino a  " .. giorno(o.a, true)
	riga(quando, 48, 130, 0.65, C.SPENTO, b.radice)
	if o.torna then riga("torna " .. giorno(o.torna), 48, 96, 0.65, C.SPENTO, b.radice) end

	-- a destra: i premi (li consegna il server quando ci sono gli account)
	local px, pw = 760, 472
	riga("PREMI", px, 590, 0.65, C.SPENTO, b.radice)
	local premi = type(o.premi) == "table" and o.premi or {}
	if #premi == 0 then riga("Solo per divertirsi", px, 550, 0.7, C.TESTO, b.radice) end
	for i, p in ipairs(premi) do
		if i > 5 then break end
		local n = ui.pannello(px + pw / 2, 550 - (i - 1) * 56, pw, 48, b.radice)
		riga(type(p) == "table" and (p.testo or "") or tostring(p), -pw / 2 + 20, 0, 0.7, C.TESTO, n)
		if type(p) == "table" and p.chi then a_destra(p.chi, pw / 2 - 20, 0, 0.6, ui.ORO, n) end
	end
	if o.da <= adesso then
		-- un evento su una coda normale si gioca in quella coda
		ui.bottone(b.bottoni, 1280 - 48 - 170, 108, 340, 108, "GIOCA", "coda:" .. o.coda,
			{ principale = true, colore = colore(o) }, b.radice)
	end
end

local function trova(id)
	for _, o in ipairs(eventi.lista) do
		if o.id == id then return o end
	end
end

local function costruisci(b)
	if b.radice then gui.delete_node(b.radice) end
	b.bottoni = {}
	b.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(b.radice, false)
	-- la freccia sta fuori dalla radice: solo un nodo senza genitore si attacca al bordo
	if b.freccia then gui.delete_node(b.freccia) end
	b.freccia = ui.indietro(b.bottoni, "indietro")
	local adesso = eventi.ora()
	local o = b.aperto and trova(b.aperto)
	if o then
		dettaglio(b, o, adesso)
		return
	end
	b.aperto = nil
	ui.titolo("EVENTI", 640, 640, 1, ui.C.TESTO, b.radice)
	if not eventi.caricato then
		ui.testo("Il server non risponde: gli eventi tornano appena c'è la rete", 640, 400, 0.75, ui.C.SPENTO, b.radice)
		return
	end
	ora(b, adesso)
	prossimi(b, adesso)
end

function M.new(nomi)
	local b = { nomi = nomi, t = 0 }
	b.fondo = ui.sfondo()
	costruisci(b)
	return b
end

-- ogni mezzo minuto si rifà (i tempi scendono, un evento comincia)
function M.update(b, dt)
	b.t = b.t + dt
	if b.t >= 30 then
		b.t = 0
		costruisci(b)
	end
end

-- di nuovo, con gli eventi appena arrivati dal server
function M.ricostruisci(x)
	costruisci(x)
end

function M.on_input(b, action_id, action)
	local azione = ui.tocco(b.bottoni, action_id, action)
	if not azione then return nil end
	if azione == "indietro" then
		if not b.aperto then return "indietro" end
		b.aperto = nil
		costruisci(b)
		return nil
	end
	local tipo, valore = azione:match("^(%a+):(.*)$")
	if tipo == "coda" then return { coda = valore } end
	b.aperto = valore
	costruisci(b)
	return nil
end

function M.distruggi(b)
	gui.delete_node(b.radice)
	gui.delete_node(b.freccia)
	gui.delete_node(b.fondo)
end

return M
