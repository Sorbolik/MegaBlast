-- Lo schieramento (scheda personaggio, Sergio 31 ott): prima della scelta delle
-- armi i cartellini di tutti (ui/cartellino.lua), le squadre una di fronte
-- all'altra. È il momento in cui si ha il tempo di guardare, e serve: le armi
-- si scelgono a carte coperte, quindi sapere che l'altro ha il doppio salto fa
-- scegliere meglio. Dura SECONDI (config.SCHIERAMENTO_SECONDS) o finché non si
-- tocca. Durante la scelta i cartellini restano in alto in una striscia: un
-- tocco su uno lo apre, un altro tocco lo chiude.
--
--   local s = schieramento.new(vetrine, titolo)  -- vetrine: una per robot (menu/vetrina.lua)
--   schieramento.update(s, dt) -> true quando è finito (tempo o tocco)
--   schieramento.on_input(s, action_id, action)
--   schieramento.distruggi(s)
--
--   local st = schieramento.striscia(vetrine)    -- la striscia in alto durante la scelta
--   schieramento.striscia_tocco(st, action_id, action) -> true se il tocco era suo
--   schieramento.distruggi(st)

local ui = require "ui.ui"
local schermo = require "ui.schermo"
local config = require "sim.config"
local cartellino = require "ui.cartellino"

local M = {}

local C = ui.C
local W, H = 1280, 720
local TOUCH = hash("touch")
local CIMA = 616          -- dove comincia un cartellino
local STRISCIA_Y, STRISCIA_W, STRISCIA_H = 680, 284, 56

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function con_alfa(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

-- Le x dei cartellini: due squadre ai lati del centro (nel tutti contro tutti
-- in fila). squadre: la squadra di ogni robot
function M.posti(squadre)
	local n = #squadre
	local teams = {}
	for _, t in ipairs(squadre) do teams[t] = true end
	local quante = 0
	for _ in pairs(teams) do quante = quante + 1 end
	local xs = {}
	if n == 2 then return { 640 - 175, 640 + 175 }, true end
	if n == 4 and quante == 2 then
		-- prima la squadra del primo, a sinistra; poi l'altra, a destra
		local sx, dx = {}, {}
		for i, t in ipairs(squadre) do
			if t == squadre[1] then sx[#sx + 1] = i else dx[#dx + 1] = i end
		end
		local pos = { 163, 469, 811, 1117 }
		for k, i in ipairs(sx) do xs[i] = pos[k] end
		for k, i in ipairs(dx) do xs[i] = pos[2 + k] end
		return xs, true
	end
	local passo = 306
	local x0 = 640 - (n - 1) * passo / 2
	for i = 1, n do xs[i] = x0 + (i - 1) * passo end
	return xs, false
end

function M.new(vetrine, titolo)
	local s = { vetrine = vetrine, carte = {}, t = config.SCHIERAMENTO_SECONDS }
	s.fondo = ui.sfondo()
	-- titolo e tempo si attaccano ai bordi veri: solo un nodo senza genitore si attacca
	local alto_sx = gui.new_box_node(vec(44, H - 34), vec(0, 0))
	gui.set_visible(alto_sx, false)
	gui.set_xanchor(alto_sx, gui.ANCHOR_LEFT)
	gui.set_yanchor(alto_sx, gui.ANCHOR_TOP)
	local t = ui.titolo(titolo, 0, 0, 0.75, C.LUCE, alto_sx)
	gui.set_pivot(t, gui.PIVOT_W)
	local sotto = ui.testo("TOCCA PER SCEGLIERE LE ARMI", 2, -40, 0.75, C.SPENTO, alto_sx)
	gui.set_pivot(sotto, gui.PIVOT_W)
	local alto_dx = gui.new_box_node(vec(W - 44 - 115, H - 52), vec(0, 0))
	gui.set_visible(alto_dx, false)
	gui.set_xanchor(alto_dx, gui.ANCHOR_RIGHT)
	gui.set_yanchor(alto_dx, gui.ANCHOR_TOP)
	s.angoli = { alto_sx, alto_dx }
	s.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(s.radice, false)
	ui.pannello(0, 0, 230, 58, alto_dx)
	local armi = ui.testo("ARMI TRA", -24, 0, 0.85, C.SPENTO, alto_dx)
	gui.set_pivot(armi, gui.PIVOT_E)
	s.conto = ui.testo("", -12, 0, 0.95, C.LUCE, alto_dx)
	gui.set_pivot(s.conto, gui.PIVOT_W)

	local squadre = {}
	for i, v in ipairs(vetrine) do squadre[i] = v.squadra end
	local xs, vs = M.posti(squadre)
	for i, v in ipairs(vetrine) do
		v.verso = xs[i] < 640 and 1 or -1
		s.carte[i] = cartellino.new(v, xs[i], CIMA, { ritratto = true, tu = v.tu }, s.radice)
	end
	if vs then
		ui.titolo("VS", 640, CIMA - 260, 0.75, C.SPENTO, s.radice)
		-- una linea del colore di ogni squadra sopra i suoi cartellini
		local per = {}
		for i, v in ipairs(vetrine) do
			local p = per[v.squadra] or { min = 9999, max = -9999 }
			p.min, p.max = math.min(p.min, xs[i]), math.max(p.max, xs[i])
			per[v.squadra] = p
		end
		for team, p in pairs(per) do
			local w = p.max - p.min + cartellino.LARGO
			local n = gui.new_box_node(vec((p.min + p.max) / 2, CIMA + 10), vec(w, 3))
			gui.set_color(n, C.SQUADRA[team] or C.LUCE)
			gui.set_parent(n, s.radice)
		end
	end
	M.update(s, 0)
	return s
end

function M.update(s, dt)
	for _, c in ipairs(s.carte or {}) do cartellino.update(c, dt) end
	if not s.t then return false end
	s.t = s.t - dt
	if s.conto then gui.set_text(s.conto, string.format("0:%02d", math.max(0, math.ceil(s.t)))) end
	return s.t <= 0 or s.toccato
end

function M.on_input(s, action_id, action)
	if (action_id == TOUCH and action.released) or (action_id == ui.PAD and action.pressed) then
		s.toccato = true
	end
end

-- La striscia in alto durante la scelta: un cartellino piccolo per robot
function M.striscia(vetrine)
	local st = { vetrine = vetrine, mini = {} }
	st.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(st.radice, false)
	local squadre = {}
	for i, v in ipairs(vetrine) do squadre[i] = v.squadra end
	local xs = M.posti(squadre)
	for i, v in ipairs(vetrine) do
		local col = C.SQUADRA[v.squadra] or C.LUCE
		local n, bordo = ui.pannello(xs[i], STRISCIA_Y, STRISCIA_W, STRISCIA_H, st.radice)
		gui.set_color(bordo, v.tu and col or con_alfa(col, 0.6))
		local sx = -STRISCIA_W / 2 + 12
		ui.anello(sx + 17, 0, 34, 2.5, col, n)
		ui.testo(v.livello and tostring(v.livello) or v.bot and "BOT" or "–", sx + 17, 0, (v.livello or not v.bot) and 0.75 or 0.5, col, n)
		local nome = ui.titolo(v.nome or "?", sx + 42, 8, 0.4, C.LUCE, n)
		gui.set_pivot(nome, gui.PIVOT_W)
		-- i quattro pezzi in piccolo: un quadretto col bordo del tier e il livello
		for k, p in ipairs(v.pezzi or {}) do
			local x = sx + 50 + (k - 1) * 24
			local q = gui.new_box_node(vec(x, -12), vec(20, 20))
			gui.set_color(q, not p.set and con_alfa(C.LUCE, 0.12) or p.tier >= 3 and C.ORO or p.tier == 2 and C.ACCIAIO
				or con_alfa(C.LUCE, 0.5))
			gui.set_parent(q, n)
			local d = gui.new_box_node(vec(0, 0), vec(16, 16))
			gui.set_color(d, C.FONDO)
			gui.set_parent(d, q)
			if p.set then ui.testo(tostring(p.livello), 0, 0, 0.5, C.LUCE, q) end
		end
		local bx = STRISCIA_W / 2 - 14
		for k = #(v.badge or {}), 1, -1 do
			cartellino.badge(v.badge[k], bx, -12, 18, n)
			bx = bx - 22
		end
		local poteri = #(v.poteri or {})
		if poteri > 0 then
			local t = ui.testo(poteri == 1 and "1 potere" or poteri .. " poteri", STRISCIA_W / 2 - 14, 10, 0.5, C.ORO, n)
			gui.set_pivot(t, gui.PIVOT_E)
		end
		st.mini[i] = n
	end
	return st
end

-- Un tocco sulla striscia: apre il cartellino toccato; col cartellino aperto
-- un tocco qualsiasi lo chiude. true se il tocco era della striscia
function M.striscia_tocco(st, action_id, action)
	if action_id ~= TOUCH or not st.radice then return false end
	if st.aperto then
		if action.pressed then
			cartellino.distruggi(st.aperto)
			gui.delete_node(st.velo)
			st.aperto, st.velo = nil, nil
			st.mangia = true
		end
		return true
	end
	if st.mangia then
		-- il dito che ha chiuso il cartellino: anche il suo rilascio è nostro
		if action.released then st.mangia = nil end
		return true
	end
	if not action.pressed then return false end
	for i, n in ipairs(st.mini) do
		if gui.pick_node(n, action.x, action.y) then
			st.velo = gui.new_box_node(vec(W / 2, H / 2), vec(W * schermo.PIENO, H * schermo.PIENO))
			gui.set_color(st.velo, con_alfa(C.FONDO, 0.8))
			gui.set_parent(st.velo, st.radice)
			local v = st.vetrine[i]
			v.verso = 1
			st.aperto = cartellino.new(v, W / 2, 360 + cartellino.ALTO({ ritratto = true }) / 2, { ritratto = true, tu = v.tu }, st.radice)
			st.mangia = true
			return true
		end
	end
	return false
end

function M.update_striscia(st, dt)
	if st.aperto then cartellino.update(st.aperto, dt) end
end

function M.distruggi(s)
	for _, n in ipairs(s.angoli or {}) do gui.delete_node(n) end
	s.angoli = nil
	if s.radice then gui.delete_node(s.radice) end
	if s.fondo then gui.delete_node(s.fondo) end
	s.radice, s.fondo, s.aperto = nil, nil, nil
end

return M
