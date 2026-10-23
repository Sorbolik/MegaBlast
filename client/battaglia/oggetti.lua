-- Oggetti tattici nella battaglia, disegnati solo con forme (niente immagini):
-- trappole e trampolini posati, punti di ancoraggio della mappa, scudo e
-- paracadute dei robot, e le icone degli oggetti nella barra.
--
--   local o = oggetti.new(colori)             -- colori[squadra]
--   oggetti.nodi(o)                            -- da mettere nel nodo "mondo"
--   oggetti.mappa(o, g)                        -- a ogni partita nuova
--   oggetti.update(o, g, view, clock)          -- a ogni frame, nessuna allocazione
--   oggetti.icona(tipo, parent)                -- forma per lo slot della barra

local game = require "sim.game"
local config = require "sim.config"

local M = {}

local AMBRA = vmath.vector4(1, 0.72, 0.25, 1)
local ACCIAIO = vmath.vector4(0.55, 0.75, 0.95, 0.55)
local BIANCO = vmath.vector4(1, 1, 1, 0.9)
local MAX_ANCORE = 4

local function nodo(w, h, color, parent)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(w, h, 0))
	gui.set_adjust_mode(n, gui.ADJUST_STRETCH)
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

local function cerchio(d, color, parent)
	local n = gui.new_pie_node(vmath.vector3(0, 0, 0), vmath.vector3(d, d, 0))
	gui.set_adjust_mode(n, gui.ADJUST_STRETCH)
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

local function pos(n, x, y)
	gui.set_position(n, vmath.vector3(x, y, 0))
end

-- Trappola: un rombo; trampolino: una tavola sopra due gambe
local function trappola(r, parent)
	local n = nodo(r * 1.2, r * 1.2, BIANCO, parent)
	gui.set_euler(n, vmath.vector3(0, 0, 45))
	return n
end

local function trampolino(hw, parent)
	local n = nodo(hw * 2, 3, AMBRA, parent)
	local a = nodo(2, 5, AMBRA, n)
	pos(a, -hw * 0.6, -4)
	local b = nodo(2, 5, AMBRA, n)
	pos(b, hw * 0.6, -4)
	return n
end

-- Scudo: un anello; paracadute: una cupola (mezzo cerchio)
local function anello(d, color, parent)
	local n = cerchio(d, color, parent)
	gui.set_inner_radius(n, d * 0.42)
	return n
end

function M.new(colori)
	local o = { colori = colori, posati = {}, ancore = {}, scudi = {}, paracadute = {}, col = vmath.vector4() }
	local h = game.ROBOT_H
	for i = 1, config.MAX_PLACED do
		local root = nodo(0, 0, BIANCO)
		local t = trappola(config.STATS.trap_radius, root)
		local b = trampolino(config.TRAMPOLINE.half_w, root)
		gui.set_visible(root, false)
		gui.set_enabled(root, false)
		o.posati[i] = { root = root, trap = t, tramp = b, id = nil }
	end
	for i = 1, MAX_ANCORE do
		local n = anello(60, ACCIAIO)
		gui.set_enabled(n, false)
		o.ancore[i] = n
	end
	for i = 1, game.MAX_PLAYERS do
		local s = anello(h * 1.9, BIANCO)
		gui.set_enabled(s, false)
		o.scudi[i] = s
		local p = cerchio(h * 1.6, BIANCO)
		gui.set_fill_angle(p, 180)
		gui.set_enabled(p, false)
		o.paracadute[i] = p
	end
	return o
end

-- I nodi da mettere nel mondo, nell'ordine in cui si disegnano
function M.nodi(o)
	local list = {}
	for _, n in ipairs(o.ancore) do list[#list + 1] = n end
	for _, p in ipairs(o.posati) do list[#list + 1] = p.root end
	for _, n in ipairs(o.scudi) do list[#list + 1] = n end
	for _, n in ipairs(o.paracadute) do list[#list + 1] = n end
	return list
end

-- Punti di ancoraggio della mappa: un anello schiacciato sul terreno
function M.mappa(o, g)
	for i, n in ipairs(o.ancore) do
		local a = g.anchors[i]
		gui.set_enabled(n, a ~= nil)
		if a then
			pos(n, a.x, a.y)
			gui.set_size(n, vmath.vector3(a.r * 2, a.r * 2, 0))
			gui.set_inner_radius(n, a.r * 0.85)
			gui.set_scale(n, vmath.vector3(1, 0.25, 1))
		end
	end
end

function M.update(o, g, view, clock)
	-- trappole (del colore della squadra, lampeggiano quando sono armate) e trampolini
	for i, p in ipairs(o.posati) do
		local it = g.placed[i]
		gui.set_enabled(p.root, it ~= nil)
		if it then
			gui.set_enabled(p.trap, it.kind == "trap")
			gui.set_enabled(p.tramp, it.kind == "trampoline")
			if it.kind == "trap" then
				local c = o.colori[it.team]
				o.col.x, o.col.y, o.col.z = c.x, c.y, c.z
				o.col.w = it.armed and (0.6 + 0.4 * math.sin(clock * 6 + i)) or 0.35
				gui.set_color(p.trap, o.col)
				pos(p.root, it.x, it.y + it.r * 0.5)
			else
				pos(p.root, it.x, it.y + 6)
			end
		end
	end
	-- scudo attorno al robot, paracadute aperto sopra la testa
	for i = 1, game.MAX_PLAYERS do
		local rb, v = g.robots[i], view[i]
		local shield = rb ~= nil and not rb.dead and rb.shield ~= nil
		gui.set_enabled(o.scudi[i], shield)
		if shield then
			local c = o.colori[rb.team]
			o.col.x, o.col.y, o.col.z, o.col.w = c.x, c.y, c.z, 0.35 + 0.25 * rb.shield / config.SHIELD.hp
			gui.set_color(o.scudi[i], o.col)
			pos(o.scudi[i], v.x, v.y + game.ROBOT_H / 2)
		end
		local open = rb ~= nil and not rb.dead and rb.parachute == "open"
		gui.set_enabled(o.paracadute[i], open)
		if open then pos(o.paracadute[i], v.x, v.y + game.ROBOT_H * 1.3) end
	end
end

-- Forma dell'oggetto per lo slot della barra (al posto dell'immagine delle armi)
function M.icona(tipo, parent)
	if tipo == "trap" then
		trappola(28, parent)
	elseif tipo == "trampoline" then
		gui.set_scale(trampolino(22, parent), vmath.vector3(1, 2, 1))
	elseif tipo == "shield" then
		anello(44, ACCIAIO, parent)
	else -- parachute
		local n = cerchio(44, BIANCO, parent)
		gui.set_fill_angle(n, 180)
		pos(n, 0, -6)
	end
end

return M
