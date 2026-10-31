-- Dove giochi? (GIOCA della home): la coda della partita online. A sinistra la
-- grande, il 2 contro 2 di sempre, con gli eventi che contano anche lì (Torneo,
-- Sfida, XP: "conta anche per"); a destra gli eventi con una coda loro (i
-- modificatori, server/eventi.go) e, piccolo, l'1 contro 1. Il giocatore
-- sceglie solo la coda: una partita conta per tutti gli eventi della sua coda.
-- Stile in ui/ui.lua, eventi da main/eventi.lua.
--
--   local coda = require "menu.coda"
--   local c = coda.new()
--   local fine = coda.on_input(c, action_id, action)
--     -- "indietro", { coda = "2v2" | "1v1" | id dell'evento }, o nil
--   coda.distruggi(c)

local ui = require "ui.ui"
local eventi = require "main.eventi"

local M = {}

-- quanti eventi con la coda loro ci stanno a destra (sopra l'1 contro 1)
local MAX_EVENTI = 2

local function vec(x, y) return vmath.vector3(x, y, 0) end

-- testo allineato a sinistra; w: va a capo oltre quella larghezza
local function riga(t, x, y, scala, colore, parent, w)
	local n = ui.testo(t, x, y, scala, colore, parent)
	gui.set_pivot(n, w and gui.PIVOT_NW or gui.PIVOT_W)
	if w then
		gui.set_line_break(n, true)
		gui.set_size(n, vec(w / (scala * 0.5), 200))
	end
	return n
end

local function a_destra(t, x, y, scala, colore, parent)
	local n = ui.testo(t, x, y, scala, colore, parent)
	gui.set_pivot(n, gui.PIVOT_E)
	return n
end

local function costruisci(c)
	if c.radice then gui.delete_node(c.radice) end
	c.bottoni = {}
	c.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(c.radice, false)
	local C = ui.C
	-- la freccia sta fuori dalla radice: solo un nodo senza genitore si attacca al bordo
	if c.freccia then gui.delete_node(c.freccia) end
	c.freccia = ui.indietro(c.bottoni, "indietro")
	ui.titolo("DOVE GIOCHI?", 640, 640, 1, C.TESTO, c.radice)

	-- il 2 contro 2: la carta grande, col bordo chiaro
	local W2, H2 = 640, 440
	local n = ui.bottone(c.bottoni, 48 + W2 / 2, 300, W2, H2, "", "coda:2v2", { colore = C.LUCE }, c.radice)
	local b = c.bottoni[#c.bottoni]
	b.riposo = C.LUCE
	gui.set_color(b.bordo, C.LUCE)
	local x0, y0 = -W2 / 2 + 36, H2 / 2 - 44
	riga("LA PARTITA DI SEMPRE", x0, y0, 0.65, C.SPENTO, n)
	gui.set_pivot(ui.titolo("2 CONTRO 2", x0, y0 - 64, 1.1, C.LUCE, n), gui.PIVOT_W)
	local anche = eventi.su_coda("2v2")
	if #anche > 0 then
		riga("CONTA ANCHE PER", x0, y0 - 140, 0.65, C.SPENTO, n)
		for i, o in ipairs(anche) do
			if i > 3 then break end
			riga(o.nome, x0, y0 - 140 - i * 44, 0.75, C.TESTO, n)
		end
	end
	a_destra("GIOCA", W2 / 2 - 36, -H2 / 2 + 44, 1.3, C.LUCE, n)

	-- a destra: gli eventi con la coda loro, poi l'1 contro 1
	local x, w = 48 + W2 + 32 + (1280 - 48 * 2 - W2 - 32) / 2, 1280 - 48 * 2 - W2 - 32
	local y = 300 + H2 / 2
	for i, o in ipairs(eventi.con_coda()) do
		if i > MAX_EVENTI then break end
		local h = 150
		local e = ui.bottone(c.bottoni, x, y - h / 2, w, h, "", "coda:" .. o.coda, nil, c.radice)
		gui.set_color(c.bottoni[#c.bottoni].bordo, C.BRACE)
		c.bottoni[#c.bottoni].riposo = C.BRACE
		local ex, ey = -w / 2 + 24, h / 2 - 26
		riga("EVENTO · " .. eventi.nome_coda(o.modo), ex, ey, 0.6, C.BRACE, e)
		a_destra(eventi.quando(o), w / 2 - 24, ey, 0.6, C.SPENTO, e)
		riga(o.nome, ex, ey - 40, 0.85, C.TESTO, e)
		if o.riga and o.riga ~= "" then riga(o.riga, ex, ey - 64, 0.6, C.SPENTO, e, w - 150) end
		a_destra("GIOCA", w / 2 - 24, -h / 2 + 28, 0.9, C.BRACE, e)
		y = y - h - 20
	end
	local h1 = 90
	local u = ui.bottone(c.bottoni, x, 300 - H2 / 2 + h1 / 2, w, h1, "", "coda:1v1", nil, c.radice)
	riga("1 CONTRO 1", -w / 2 + 24, 0, 0.85, C.TESTO, u)
	a_destra("GIOCA", w / 2 - 24, 0, 0.9, C.SPENTO, u)
end

function M.new()
	local c = {}
	c.fondo = ui.sfondo()
	costruisci(c)
	return c
end

-- di nuovo, con gli eventi appena arrivati dal server
function M.ricostruisci(x)
	costruisci(x)
end

function M.on_input(c, action_id, action)
	local azione = ui.tocco(c.bottoni, action_id, action)
	if not azione then return nil end
	if azione == "indietro" then return "indietro" end
	return { coda = azione:match("^coda:(.*)$") }
end

function M.distruggi(c)
	gui.delete_node(c.radice)
	gui.delete_node(c.freccia)
	gui.delete_node(c.fondo)
end

return M
