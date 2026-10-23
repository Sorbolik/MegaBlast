-- COPIA PROVVISORIA dell'API del thread "Interfaccia minimale del gioco", solo
-- per provare le schermate di podio e assetto: va sostituita dal modulo vero.

local M = {}

local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end
M.C = {
	FONDO = c(0.05, 0.045, 0.06), PANNELLO = c(0.11, 0.10, 0.12), LINEA = c(0.30, 0.27, 0.30),
	TESTO = c(0.93, 0.89, 0.80), SPENTO = c(0.52, 0.50, 0.50), BRACE = c(1, 0.45, 0.16),
	SQUADRA = { c(1, 0.231, 0.306), c(0.239, 0.482, 1), c(0.35, 0.85, 0.45), c(0.95, 0.80, 0.25) },
}
local SCURO = c(0, 0, 0, 1)

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function nodo(n, parent)
	if parent then gui.set_parent(n, parent) end
	return n
end

local function scritta(font, t, x, y, scala, colore, parent)
	local n = gui.new_text_node(vec(x, y), t)
	gui.set_font(n, font)
	gui.set_color(n, colore or M.C.TESTO)
	gui.set_outline(n, SCURO)
	gui.set_scale(n, vmath.vector3(scala or 1, scala or 1, 1))
	return nodo(n, parent)
end

function M.testo(t, x, y, scala, colore, parent) return scritta("default", t, x, y, scala, colore, parent) end
function M.titolo(t, x, y, scala, colore, parent) return scritta("titoli", t, x, y, scala, colore, parent) end

function M.pannello(x, y, w, h, parent)
	local n = nodo(gui.new_box_node(vec(x, y), vec(w, h)), parent)
	gui.set_color(n, M.C.PANNELLO)
	return n
end

function M.sfondo(parent)
	local n = nodo(gui.new_box_node(vec(640, 360), vec(1280, 720)), parent)
	gui.set_adjust_mode(n, gui.ADJUST_STRETCH)
	gui.set_color(n, M.C.FONDO)
	return n
end

local function aggiungi(lista, n, azione)
	lista[#lista + 1] = { nodo = n, azione = azione }
end

function M.bottone(lista, x, y, w, h, t, azione, opz, parent)
	opz = opz or {}
	local n = M.pannello(x, y, w, h, parent)
	local col = opz.colore or (opz.principale and M.C.BRACE or M.C.LINEA)
	if opz.spento then col = M.C.PANNELLO end
	gui.set_color(n, col)
	M.testo(t, 0, 0, 1, opz.spento and M.C.SPENTO or M.C.TESTO, n)
	if not opz.spento then aggiungi(lista, n, azione) end
	return n
end

function M.scheda(lista, x, y, w, h, t, azione, attiva, parent)
	local n = M.bottone(lista, x, y, w, h, t, azione, { colore = attiva and M.C.BRACE or M.C.PANNELLO }, parent)
	return n
end

function M.indietro(lista, azione, parent)
	local n = M.bottone(lista, 50, 680, 70, 50, "<", azione, nil, parent)
	return n
end

function M.barra(x, y, w, h, colore, parent)
	local fondo = M.pannello(x, y, w, h, parent)
	gui.set_color(fondo, M.C.LINEA)
	local pieno = nodo(gui.new_box_node(vec(-w / 2, 0), vec(0, h)), fondo)
	gui.set_pivot(pieno, gui.PIVOT_W)
	gui.set_color(pieno, colore or M.C.BRACE)
	return { fondo = fondo, pieno = pieno, w = w, h = h }
end

function M.barra_valore(b, v)
	gui.set_size(b.pieno, vec(b.w * math.max(0, math.min(1, v)), b.h))
end

function M.tocco(lista, action_id, action)
	if action_id ~= hash("touch") then return nil end
	if action.pressed then
		lista.premuto = nil
		for _, b in ipairs(lista) do
			if gui.pick_node(b.nodo, action.x, action.y) then lista.premuto = b end
		end
	elseif action.released and lista.premuto then
		local b = lista.premuto
		lista.premuto = nil
		if gui.pick_node(b.nodo, action.x, action.y) then return b.azione end
	end
	return nil
end

return M
