-- Oggetti tattici nella battaglia, disegnati solo con forme (niente immagini):
-- trappole e trampolini posati, cerchi di cura, scudo,
-- paracadute ed effetti di stato dei robot, e le icone degli oggetti nella barra.
--
--   local o = oggetti.new(colori)             -- colori[squadra]
--   oggetti.nodi(o)                            -- da mettere nel nodo "mondo"
--   oggetti.update(o, g, view, clock)          -- a ogni frame, nessuna allocazione
--   oggetti.icona(tipo, parent)                -- forma per lo slot della barra

local game = require "sim.game"
local config = require "sim.config"

local M = {}

local AMBRA = vmath.vector4(1, 0.72, 0.25, 1)
local ACCIAIO = vmath.vector4(0.55, 0.75, 0.95, 0.55)
local BIANCO = vmath.vector4(1, 1, 1, 0.9)
-- effetti di stato: fiamma sulla testa, anello freddo ai piedi, crepa sul petto
local FUOCO = vmath.vector4(1, 0.45, 0.1, 0.7)
local GELO = vmath.vector4(0.45, 0.8, 1, 0.8)
local CREPA = vmath.vector4(1, 1, 1, 0.75)
-- cerchio di cura: anello a terra e una croce che galleggia sopra
local CURA = vmath.vector4(0.45, 1, 0.6, 0.85)

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
	local o = { colori = colori, posati = {}, cure = {}, scudi = {}, paracadute = {}, fiamme = {}, geli = {}, crepe = {},
		col = vmath.vector4(), size = vmath.vector3() }
	local h = game.ROBOT_H
	for i = 1, config.MAX_PLACED do
		local root = nodo(0, 0, BIANCO)
		local t = trappola(config.STATS.trap_radius, root)
		local b = trampolino(config.TRAMPOLINE.half_w, root)
		gui.set_visible(root, false)
		gui.set_enabled(root, false)
		o.posati[i] = { root = root, trap = t, tramp = b, id = nil }
	end
	local r = config.HEAL.r
	for i = 1, config.HEAL.max do
		local root = nodo(0, 0, CURA)
		gui.set_visible(root, false)
		local a = anello(r * 2, CURA, root)
		gui.set_scale(a, vmath.vector3(1, 0.3, 1))
		local croce = nodo(4, 14, CURA, root)
		nodo(14, 4, CURA, croce)
		gui.set_enabled(root, false)
		o.cure[i] = { root = root, croce = croce }
	end
	for i = 1, game.MAX_PLAYERS do
		local s = anello(h * 1.9, BIANCO)
		gui.set_enabled(s, false)
		o.scudi[i] = s
		local p = cerchio(h * 1.6, BIANCO)
		gui.set_fill_angle(p, 180)
		gui.set_enabled(p, false)
		o.paracadute[i] = p
		local f = cerchio(h * 0.5, FUOCO)
		gui.set_enabled(f, false)
		o.fiamme[i] = f
		local ge = anello(h * 1.4, GELO)
		gui.set_scale(ge, vmath.vector3(1, 0.3, 1))
		gui.set_enabled(ge, false)
		o.geli[i] = ge
		local c = nodo(0, 0, CREPA)
		gui.set_euler(nodo(2, h * 0.7, CREPA, c), vmath.vector3(0, 0, 30))
		gui.set_euler(nodo(2, h * 0.5, CREPA, c), vmath.vector3(0, 0, -40))
		gui.set_enabled(c, false)
		o.crepe[i] = c
	end
	return o
end

-- I nodi da mettere nel mondo, nell'ordine in cui si disegnano
function M.nodi(o)
	local list = {}
	for _, c in ipairs(o.cure) do list[#list + 1] = c.root end
	for _, p in ipairs(o.posati) do list[#list + 1] = p.root end
	for _, n in ipairs(o.scudi) do list[#list + 1] = n end
	for _, n in ipairs(o.paracadute) do list[#list + 1] = n end
	for _, n in ipairs(o.geli) do list[#list + 1] = n end
	for _, n in ipairs(o.crepe) do list[#list + 1] = n end
	for _, n in ipairs(o.fiamme) do list[#list + 1] = n end
	return list
end


function M.update(o, g, view, clock)
	-- cerchi di cura: la croce sale e scende piano
	for i, c in ipairs(o.cure) do
		local h = g.heals[i]
		gui.set_enabled(c.root, h ~= nil)
		if h then
			pos(c.root, h.x, h.y)
			pos(c.croce, 0, 16 + 3 * math.sin(clock * 3 + i))
		end
	end
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
		local open = rb ~= nil and not rb.dead and rb.parachute
		gui.set_enabled(o.paracadute[i], open)
		if open then pos(o.paracadute[i], v.x, v.y + game.ROBOT_H * 1.3) end
		-- effetti di stato
		local st = rb ~= nil and not rb.dead and rb.status or nil
		local burn, slow, cracked = st and st.burn, st and st.slow, st and st.cracked
		gui.set_enabled(o.fiamme[i], burn ~= nil)
		if burn then
			-- la fiamma tremola
			local d = game.ROBOT_H * (0.32 + 0.06 * math.sin(clock * 17 + i * 2))
			o.size.x, o.size.y = d, d * 1.3
			gui.set_size(o.fiamme[i], o.size)
			pos(o.fiamme[i], v.x, v.y + game.ROBOT_H * 1.05)
		end
		gui.set_enabled(o.geli[i], slow ~= nil)
		if slow then pos(o.geli[i], v.x, v.y + 1) end
		gui.set_enabled(o.crepe[i], cracked ~= nil)
		if cracked then pos(o.crepe[i], v.x, v.y + game.ROBOT_H * 0.55) end
	end
end

-- Forma dell'oggetto per lo slot della barra (al posto dell'immagine delle armi)
function M.icona(tipo, parent)
	if tipo == "trap" then
		trappola(28, parent)
	elseif tipo == "trampoline" then
		gui.set_scale(trampolino(22, parent), vmath.vector3(1, 2, 1))
	elseif tipo == "sniper" then
		-- cecchino: canna lunga e mirino tondo
		gui.set_euler(nodo(50, 5, BIANCO, parent), vmath.vector3(0, 0, 20))
		pos(anello(18, BIANCO, parent), -6, 10)
	elseif tipo == "eagle" then
		-- Tonante: canna corta e grossa, impugnatura in giù
		pos(nodo(40, 10, BIANCO, parent), 4, 6)
		local m = nodo(9, 20, BIANCO, parent)
		gui.set_euler(m, vmath.vector3(0, 0, 15))
		pos(m, -10, -6)
	elseif tipo == "hook" then
		-- Rampino: la fune e l'uncino aperto in punta
		gui.set_euler(nodo(44, 3, BIANCO, parent), vmath.vector3(0, 0, 30))
		local u = anello(20, BIANCO, parent)
		gui.set_fill_angle(u, 240)
		gui.set_euler(u, vmath.vector3(0, 0, 120))
		pos(u, 16, 12)
	elseif tipo == "lunge" then
		-- Affondo: lancia lunga e sottile con la punta
		gui.set_euler(nodo(54, 4, BIANCO, parent), vmath.vector3(0, 0, 30))
		local punta = nodo(10, 10, BIANCO, parent)
		gui.set_euler(punta, vmath.vector3(0, 0, 75))
		pos(punta, 22, 13)
	elseif tipo == "shield" then
		anello(44, ACCIAIO, parent)
	else -- parachute
		local n = cerchio(44, BIANCO, parent)
		gui.set_fill_angle(n, 180)
		pos(n, 0, -6)
	end
end

return M
