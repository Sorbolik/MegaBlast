-- Il tasto del controller disegnato come sopra il controller vero (Sergio, 30
-- ott): Xbox coi tondi A B X Y colorati, PlayStation coi simboli (croce,
-- cerchio, quadrato, triangolo), Nintendo con le lettere al loro posto; i
-- dorsali (LB, L1, ZL...), Start e Select in una pillola, la croce con il
-- braccio acceso. Solo forme di ui.lua, niente immagini.
--
--   local glifo = require "ui.glifo"
--   local g = glifo.new(parent)                 -- vuoto, d è l'altezza (34)
--   glifo.mostra(g, controller, tasto, x, y)    -- disegna il tasto (nil: lo nasconde)

local ui = require "ui.ui"
local controller = require "ui.controller"

local M = {}

M.D = 34

local function c(r, g, b) return vmath.vector4(r, g, b, 1) end
local XBOX = { a = c(0.42, 0.8, 0.3), b = c(0.95, 0.33, 0.3), x = c(0.3, 0.58, 1), y = c(1, 0.8, 0.2) }
local PS = { a = c(0.5, 0.72, 1), b = c(1, 0.42, 0.45), x = c(0.96, 0.58, 0.85), y = c(0.36, 0.88, 0.74) }
local GRIGIO = c(0.4, 0.38, 0.4)
local FACCIA = { a = true, b = true, x = true, y = true }
local CROCE = { su = { 0, 1 }, giu = { 0, -1 }, sinistra = { -1, 0 }, destra = { 1, 0 } }

local V = vmath.vector3()

local function scatola(x, y, w, h, colore, angolo, parent)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_color(n, colore)
	if angolo then gui.set_euler(n, vmath.vector3(0, 0, angolo)) end
	gui.set_parent(n, parent)
	return n
end

-- I simboli di PlayStation, larghi s, spessi t
local SIMBOLI = {
	a = function(s, t, col, p)
		scatola(0, 0, s * 1.15, t, col, 45, p)
		scatola(0, 0, s * 1.15, t, col, -45, p)
	end,
	b = function(s, t, col, p)
		ui.anello(0, 0, s, t, col, p)
	end,
	x = function(s, t, col, p)
		local h = s * 0.42
		scatola(0, h, s * 0.84 + t, t, col, nil, p)
		scatola(0, -h, s * 0.84 + t, t, col, nil, p)
		scatola(h, 0, t, s * 0.84, col, nil, p)
		scatola(-h, 0, t, s * 0.84, col, nil, p)
	end,
	y = function(s, t, col, p)
		-- i tre lati attorno al centro: in mezzo a ogni lato, a R / 2 dal centro
		local lato = s * 1.05
		local r = lato / math.sqrt(3) / 2
		for _, a in ipairs({ { 270, 0 }, { 30, -60 }, { 150, 60 } }) do
			local q = math.rad(a[1])
			scatola(math.cos(q) * r, math.sin(q) * r - s * 0.06, lato + t * 0.6, t, col, a[2], p)
		end
	end,
}

local function disegna(r, famiglia, tasto, d)
	local C = ui.C
	if FACCIA[tasto] then
		local col = famiglia == "xbox" and XBOX[tasto] or famiglia == "playstation" and PS[tasto] or C.LUCE
		ui.disco(0, 0, d, C.PANNELLO, r)
		ui.anello(0, 0, d, 2, famiglia == "nintendo" and C.LUCE or col, r)
		if famiglia == "playstation" then
			SIMBOLI[tasto](d * 0.44, math.max(2, d * 0.08), col, r)
		else
			ui.testo(controller.FAMIGLIE[famiglia][tasto], 0, 1, d / 52, col, r)
		end
		return d
	end
	if CROCE[tasto] then
		-- la croce grigia, col braccio del tasto acceso
		local b, t = d * 0.7, d * 0.24
		ui.disco(0, 0, d, C.PANNELLO, r)
		ui.anello(0, 0, d, 2, C.LUCE, r)
		scatola(0, 0, b, t, GRIGIO, nil, r)
		scatola(0, 0, t, b, GRIGIO, nil, r)
		local v = CROCE[tasto]
		local l = b * 0.42
		scatola(v[1] * (b - l) / 2, v[2] * (b - l) / 2, v[1] ~= 0 and l or t, v[2] ~= 0 and l or t, C.LUCE, nil, r)
		return d
	end
	-- dorsali, Start e Select: una pillola col nome
	local nome = controller.FAMIGLIE[famiglia][tasto] or string.upper(tasto)
	local w = math.max(d, 12 + #nome * d * 0.42)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(w, d * 0.82, 0))
	gui.set_texture(n, "ui")
	gui.play_flipbook(n, "forma")
	gui.set_slice9(n, vmath.vector4(16, 16, 16, 16))
	gui.set_color(n, C.PANNELLO)
	gui.set_parent(n, r)
	local bordo = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(w, d * 0.82, 0))
	gui.set_texture(bordo, "ui")
	gui.play_flipbook(bordo, "bordo")
	gui.set_slice9(bordo, vmath.vector4(16, 16, 16, 16))
	gui.set_color(bordo, C.LUCE)
	gui.set_parent(bordo, r)
	ui.testo(nome, 0, 1, d / 44, C.TESTO, r)
	return w
end

function M.new(parent, d)
	local r = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(r, false)
	if parent then gui.set_parent(r, parent) end
	local g = { radice = r, d = d or M.D, figli = nil, chi = nil, w = 0 }
	gui.set_enabled(r, false)
	return g
end

-- La larghezza del tasto disegnato (per metterlo accanto a qualcosa)
function M.largo(g)
	return g.w
end

function M.mostra(g, ctrl, tasto, x, y)
	if not (ctrl and tasto) then
		if g.acceso then
			gui.set_enabled(g.radice, false)
			g.acceso = false
		end
		return
	end
	local chi = ctrl.famiglia .. ":" .. tasto
	if g.chi ~= chi then
		g.chi = chi
		if g.figli then gui.delete_node(g.figli) end
		g.figli = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
		gui.set_visible(g.figli, false)
		gui.set_parent(g.figli, g.radice)
		g.w = disegna(g.figli, ctrl.famiglia, tasto, g.d)
	end
	if x and (g.x ~= x or g.y ~= y) then
		g.x, g.y = x, y
		V.x, V.y, V.z = x, y, 0
		gui.set_position(g.radice, V)
	end
	if not g.acceso then
		gui.set_enabled(g.radice, true)
		g.acceso = true
	end
end

return M
