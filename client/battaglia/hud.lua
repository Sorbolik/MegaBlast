-- Pezzi dell'HUD della battaglia (docs/decisioni/interfaccia.md, 29 ottobre):
-- il cronometro ad anello in basso al centro, i pulsanti tondi (teletrasporto,
-- attrezzo, oggetti) e il cartellino col nome di quello che hai in mano.
-- La disposizione la decide game.gui_script; qui solo come sono fatti.
--
--   local c = hud.cronometro(x, y)
--   hud.cronometro_update(c, dt, fase, rimasti, totale, squadra, orologio)
--   hud.globi_nodi(c)      -- dopo i pulsanti, così i globi ci volano sopra
--   hud.globi(c, n, pos, lento) -- i secondi risparmiati volano come globi su pos (il teletrasporto)
--     fase: "turno" (bianco), "secondo" (giallo, resta il secondo attacco),
--     "riparati" (blu, attacchi finiti) o nil (nessun turno da contare)
--   local t = hud.tondo(x, y, d, icona, colore, parent)   -- icona: "<icona>_icona" dell'atlante armi
--   hud.tondo_numero(t, "2")
--   local k = hud.cartellino()
--   hud.cartellino_su(k, x, y, "LAMA") / hud.cartellino_via(k)

local ui = require "ui.ui"

local M = {}

local max, min, ceil = math.max, math.min, math.ceil

-- i nomi del cartellino
M.NOMI = { missile = "LANCIARUNE", grenade = "UOVO DI FIAMMA", shards = "SCIAME DI SCHEGGE", punch = "PUGNO DEL TITANO",
	sniper = "CECCHINO", sword = "LAMA", eagle = "TONANTE", mallet = "MAGLIO", lunge = "AFFONDO", bellows = "MANTICE", hook = "RAMPINO",
	wall = "BASTIONE", teleport = "TELETRASPORTO", parachute = "PARACADUTE", trampoline = "TRAMPOLINO" }

-- I colori delle fasi del turno, quelli della barra di prima
M.BIANCO = vmath.vector4(0.92, 0.9, 0.86, 1)
M.GIALLO = vmath.vector4(1, 0.8, 0.2, 1)
M.BLU = vmath.vector4(0.3, 0.6, 1, 1)
local FASI = {
	turno = { colore = M.BIANCO },
	secondo = { colore = M.GIALLO, parola = "SECONDO!" },
	riparati = { colore = M.BLU, parola = "RIPARATI" },
}

-- Misure dell'anello: raggio della linea, spessore; il disco scuro dietro e il
-- bordino del colore di chi gioca stanno appena fuori
M.RAGGIO, M.SPESSORE = 54, 11
M.FUORI = M.RAGGIO + M.SPESSORE * 0.55 + 2
local FONDO = vmath.vector4(0.04, 0.035, 0.05, 0.72)
local BINARIO = vmath.vector4(1, 1, 1, 0.1)
local NUMERO, PAROLA, OROLOGIO = 2.4, 0.6, 1.0   -- scale di ui.testo
local GLOBI, GLOBO_VOLO, GLOBO_DOPO = 6, 0.55, 0.09

local V = vmath.vector3(0, 0, 0)
local C = vmath.vector4(1, 1, 1, 1)

local function fit(n)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	return n
end

local function scala(n, s)
	V.x, V.y, V.z = s, s, 1
	gui.set_scale(n, V)
end

-- Il battito di ogni secondo (frazione di grandezza in più): appena accennato
-- a inizio turno, sempre più forte verso la fine; forte quando sta per finire
-- la finestra del secondo attacco; un respiro uguale quando ci si ripara.
local function lerp(a, b, k) return a + (b - a) * max(0, min(1, k)) end
local function ampiezza(fase, s)
	if fase == "turno" then
		if s > 10 then return 0.03 end
		if s > 5 then return lerp(0.04, 0.08, (10 - s) / 5) end
		return lerp(0.10, 0.18, (5 - s) / 4)
	elseif fase == "secondo" then
		return lerp(0.05, 0.16, (8 - s) / 7)
	end
	return 0.02
end
M.ampiezza = ampiezza
local ONDA_DA = 0.1   -- da questo battito in su esce anche l'onda dal bordo

function M.cronometro(x, y)
	local c = { battito = 0, amp = 0, onda = 0, on = true }
	c.radice = fit(gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(0, 0, 0)))
	gui.set_visible(c.radice, false)
	c.onda_n = fit(ui.anello(0, 0, 2 * M.FUORI, 3, M.BIANCO, c.radice))
	gui.set_enabled(c.onda_n, false)
	fit(ui.disco(0, 0, 2 * M.FUORI, FONDO, c.radice))
	c.squadra = fit(ui.anello(0, 0, 2 * M.FUORI, 3, ui.C.LUCE, c.radice))
	local d = 2 * M.RAGGIO + M.SPESSORE
	fit(ui.anello(0, 0, d, M.SPESSORE, BINARIO, c.radice))
	-- l'arco parte da mezzogiorno e si consuma in senso orario
	c.arco = fit(ui.anello(0, 0, d, M.SPESSORE, M.BIANCO, c.radice))
	gui.set_euler(c.arco, vmath.vector3(0, 0, 90))
	c.numero = fit(ui.testo("", 0, 2, NUMERO, ui.C.TESTO, c.radice))
	c.parola = fit(ui.testo("", 0, -M.RAGGIO * 0.5, PAROLA, M.BIANCO, c.radice))
	-- il tempo della partita sopra, più piccolo e fermo
	c.orologio = fit(ui.testo("", x, y + M.FUORI + 16, OROLOGIO, ui.C.TESTO))
	c.x, c.y, c.k = x, y, 1
	return c
end

-- sul fondo vero dello schermo (ui/schermo.lua: più in basso di 0 su un tablet)
function M.cronometro_sposta(c, x, y)
	c.x, c.y = x, y
	gui.set_position(c.radice, vmath.vector3(x, y, 0))
	gui.set_position(c.orologio, vmath.vector3(x, y + M.FUORI + 16, 0))
end

function M.cronometro_on(c, on)
	c.on = on
	gui.set_enabled(c.radice, on)
	gui.set_enabled(c.orologio, on)
end

-- rimasti, totale: secondi (con la virgola); squadra: colore di chi gioca
function M.cronometro_update(c, dt, fase, rimasti, totale, squadra, orologio)
	if not c.on then return end
	if c.orologio_s ~= orologio then gui.set_text(c.orologio, orologio); c.orologio_s = orologio end
	if squadra and c.squadra_c ~= squadra then gui.set_color(c.squadra, squadra); c.squadra_c = squadra end
	local f = FASI[fase]
	local sec = f and max(0, ceil(rimasti - 1e-6)) or nil
	-- cambio di fase: il giallo entra con un lampo
	if fase ~= c.fase then
		c.fase = fase
		gui.set_color(c.arco, f and f.colore or M.BIANCO)
		gui.set_color(c.onda_n, f and f.colore or M.BIANCO)
		gui.set_color(c.parola, f and f.colore or M.BIANCO)
		gui.set_text(c.parola, f and f.parola or "")
		c.sec = sec
		if fase == "secondo" then c.battito, c.amp, c.onda = 1, 0.2, 1 end
	end
	c.k = f and max(0, min(1, rimasti / totale)) or 0
	gui.set_fill_angle(c.arco, -360 * c.k)
	if c.num_s ~= sec then
		gui.set_text(c.numero, sec and tostring(sec) or "")
		gui.set_position(c.numero, vmath.vector3(0, f and f.parola and 8 or 2, 0))
		-- un battito a ogni secondo che passa
		if sec and c.sec and sec < c.sec and sec > 0 then
			c.battito, c.amp = 1, ampiezza(fase, rimasti)
			if c.amp >= ONDA_DA then c.onda = 1 end
		end
		c.sec, c.num_s = sec, sec
	end
	c.battito = max(0, c.battito - dt * 4)
	scala(c.radice, 1 + c.amp * c.battito * c.battito)
	c.onda = max(0, c.onda - dt * 2.2)
	gui.set_enabled(c.onda_n, c.onda > 0)
	if c.onda > 0 then
		scala(c.onda_n, 1.05 + (1 - c.onda) * 0.35)
		local col = f and f.colore or M.BIANCO
		C.x, C.y, C.z, C.w = col.x, col.y, col.z, c.onda * 0.8
		gui.set_color(c.onda_n, C)
	end
end

-- Quando attacchi, i secondi rimasti diventano teletrasporti: n globi si
-- staccano dalla punta dell'arco e volano uno dopo l'altro sul pulsante
local function spegni(_, nodo) gui.set_enabled(nodo, false) end

-- i nodi dei globi, da creare dopo i pulsanti così volano sopra
function M.globi_nodi(c)
	c.globi = {}
	for i = 1, GLOBI do
		local g = fit(ui.disco(c.x, c.y, 20, ui.C.VIOLA))
		fit(ui.disco(0, 0, 8, ui.C.LUCE, g))
		gui.set_enabled(g, false)
		c.globi[i] = g
	end
end

-- lento: quante volte più piano (la partita guidata li fa guardare)
function M.globi(c, n, pos, lento)
	lento = lento or 1
	local a0 = math.rad(90 - 360 * c.k)
	for i = 1, min(n, GLOBI) do
		local g = c.globi[i]
		local a = a0 + math.rad(10 * (i - 1))
		gui.cancel_animations(g, "position")
		gui.set_position(g, vmath.vector3(c.x + math.cos(a) * M.RAGGIO, c.y + math.sin(a) * M.RAGGIO, 0))
		gui.set_enabled(g, true)
		gui.animate(g, "position", pos, gui.EASING_INQUAD, GLOBO_VOLO * lento, (i - 1) * GLOBO_DOPO * lento, spegni)
	end
end

-- Pulsante tondo: disco scuro, bordo del colore della sua famiglia, icona
function M.tondo(x, y, d, icona, colore, parent)
	local t = { d = d, colore = colore }
	t.nodo = fit(ui.disco(x, y, d, ui.C.PANNELLO, parent))
	t.bordo = fit(ui.anello(0, 0, d, 3, colore, t.nodo))
	t.icona = fit(gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(d * 0.74, d * 0.74, 0)))
	gui.set_texture(t.icona, "armi")
	gui.play_flipbook(t.icona, icona .. "_icona")
	gui.set_parent(t.icona, t.nodo)
	return t
end

-- il numerino in alto a destra (teletrasporti rimasti, oggetti in mano)
function M.tondo_numero(t, testo)
	if not t.num then
		local r = t.d * 0.36
		t.num = fit(ui.disco(r, r, t.d * 0.36, t.colore, t.nodo))
		t.num_t = fit(ui.testo("", 0, 1, t.d / 84 * 0.8, ui.C.FONDO, t.num))
		gui.set_outline(t.num_t, vmath.vector4(0, 0, 0, 0))
	end
	gui.set_enabled(t.num, testo ~= "")
	gui.set_text(t.num_t, testo)
end

-- Il cartellino chiaro col nome, con la punta verso il basso
function M.cartellino()
	local k = {}
	k.nodo, k.bordo = ui.pannello(0, 0, 100, 26)
	fit(k.nodo)
	gui.set_color(k.nodo, ui.C.LUCE)
	gui.set_color(k.bordo, ui.C.FONDO)
	k.punta = fit(gui.new_box_node(vmath.vector3(0, -13, 0), vmath.vector3(10, 10, 0)))
	gui.set_color(k.punta, ui.C.LUCE)
	gui.set_euler(k.punta, vmath.vector3(0, 0, 45))
	gui.set_parent(k.punta, k.nodo)
	k.testo = fit(ui.testo("", 0, 1, 0.8, ui.C.FONDO, k.nodo))
	gui.set_outline(k.testo, vmath.vector4(0, 0, 0, 0))
	gui.set_enabled(k.nodo, false)
	return k
end

function M.cartellino_su(k, x, y, testo)
	if k.testo_s ~= testo then
		gui.set_text(k.testo, testo)
		k.font = k.font or gui.get_font_resource(gui.get_font(k.testo))
		local w = resource.get_text_metrics(k.font, testo).width * gui.get_scale(k.testo).x + 24
		V.x, V.y, V.z = w, 26, 0
		gui.set_size(k.nodo, V)
		gui.set_size(k.bordo, V)
		k.testo_s = testo
	end
	if k.x ~= x or k.y ~= y then
		V.x, V.y, V.z = x, y, 0
		gui.set_position(k.nodo, V)
		k.x, k.y = x, y
	end
	if not k.on then gui.set_enabled(k.nodo, true); k.on = true end
end

function M.cartellino_via(k)
	if k.on then gui.set_enabled(k.nodo, false); k.on = false end
end

return M
