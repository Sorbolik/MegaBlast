-- The match points on screen (docs/decisioni/interfaccia.md, 29 October):
-- the standings at the top center, readable without reading.
--
-- - Free-for-all: one token per team in order of place, sliding when the
--   standings change; yours has a thick border, the first one the Crown.
-- - Two teams (1 vs 1, 2 vs 2): the tug of war, a bar with the two colors
--   that moves toward whoever is ahead, with the points at the two ends.
-- - Every point is born where it happens (on the one hit, on your shield) and
--   flies into the token of whoever gets it; there the number rises with a
--   ticking that goes up in pitch.
-- - Under your token the gap (from the first, or over the second if you are
--   first); at the end of the turn a line with the turn's balance, which fades
--   by itself.
-- - Above everyone's head the place and the Crown (targa.posto).
-- - Two teams: turns go in pairs (Red, Blue). The big number is the score at
--   even turns: the points of whoever opened the pair stay "pending" in a
--   token with an hourglass next to their box (and striped on the rope) until
--   the other team has answered; under that one appears "+N PER PAREGGIARE"
--   (Sergio, 31 October: the gap halfway through a lap must not demotivate).
--   Under each box a dot per player: full if they already played this lap.
-- - Last lap (double points, game.final_round): a golden banner, golden boxes
--   and dots, golden numbers with their ×2 (the number is already doubled); in
--   the last minute before it, under the board, "TRA POCO: ULTIMO GIRO ×2".
--
--   local p = punteggio.nuovo(palette, tick) -- in init; tick(speed) plays a point
--   punteggio.partita(p, g, nomi, plates)    -- at every new match; team names
--   punteggio.punti(p, e, x, y)              -- "points" event: x, y on screen where it is born
--   punteggio.turno(p, g)                    -- "turn" event
--   punteggio.update(p, dt, g, mio)          -- every frame; mio: the robot of whoever is watching
--   punteggio.obiettivo(p, testo)            -- in missions: what is left to do, fixed under the points (nil = nothing)
--   punteggio.last_lap(p)                    -- "final_round" event: the banner
--   punteggio.set_enabled(p, on)
--   punteggio.conceal(p, si)                 -- lessons that haven't explained points yet: the goal stays
--
-- Numbers in flight stay out of the tokens until they arrive: the token shows
-- the real points minus those still in flight, so online (where points arrive
-- with the state) and locally you see the same thing.

local ui = require "ui.ui"
local plate = require "battle.plate"
local T = require("lang.text").score

local M = {}

local max, min, floor, abs = math.max, math.min, math.floor, math.abs

local TEAMS = 4
-- center of the row, centered on screen (M.cima); low enough to leave room
-- above for the Crown
local TOP = 38
local Y, HALF = 720 - TOP, 640
local GET_W, GET_H, GET_GAP = 104, 30, 6
local STRIP, BORDER_MINE = 6, 3
-- two teams: two point tokens and the rope in between
local VAL_W, ROPE_W, ROPE_H, ROPE_GAP = 60, 250, 12, 8
local BAND_W, BAND_STEP, BAND_V = 4, 10, 16  -- stripes of the pending points: width, spacing, px/s
local SOFT = 60                    -- with the first points the rope moves little
local CAPTION, SMALL = 0.8, 0.6     -- ui.testo scales
-- the first one's Crown: the gold one of the plates (fx/targa_corona.png, 108 x 59)
local CROWN_W = 25
local CROWN_Y = GET_H / 2 + 1 + CROWN_W * 59 / 108 / 2
local FLIGHT_SCALE, ARRIVAL_SCALE = 1.7, 0.8
local SPAWN_T, FLIGHT_T, SALE = 0.5, 0.45, 24
-- two numbers born in the same spot (the Swarm, an egg on two close robots)
-- don't cover each other (Sergio, 3 Nov): the new one is born in the first free
-- spot of STACK (in rows of STACK_Y above and columns of STACK_X to the side), so
-- even eight shards stay near the one hit; "the same spot" is within STACK_X and STACK_Y
local STACK_X, STACK_Y = 70, 32
local STACK = { { 0, 0 }, { 0, 1 }, { -1, 0 }, { 1, 0 }, { -1, 1 }, { 1, 1 }, { 0, 2 }, { -1, 2 }, { 1, 2 } }
local TURN_T, TURN_FADE = 2.4, 0.8
local NUMBERS = 8
local TICK_EVERY, TICK_STEP = 0.045, 5  -- one tick every 5 points, never more often than this
-- turn pairs: pending-points token next to the box, dots below
local WAIT_W, WAIT_H, WAIT_GAP = 58, 24, 8
local DOT, DOT_GAP, DOT_Y = 10, 5, GET_H / 2 + 9
local BELOW_Y = GET_H / 2 + 27              -- gap and "+N PER PAREGGIARE", under the dots
-- last lap: the banner and the warning before it
local BANNER_DURATION, BANNER_W, BANNER_H = 2.6, 760, 112
local NOTICE_BEFORE = 60 * 60                -- game ticks before the last lap

local V = vmath.vector3(0, 0, 0)
local C = vmath.vector4(1, 1, 1, 1)

local function root_node(x, y)
	local r = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(0, 0, 0))
	gui.set_adjust_mode(r, gui.ADJUST_FIT)
	gui.set_visible(r, false)
	return r
end

local function box(parent, x, y, w, h, color)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	gui.set_color(n, color)
	return n
end

local function size(n, w, h)
	V.x, V.y, V.z = w, h, 0
	gui.set_size(n, V)
end

local function position(n, x, y)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(n, V)
end

local function scale(n, s)
	V.x, V.y, V.z = s, s, 1
	gui.set_scale(n, V)
end

local function round_off(v) return floor(v + 0.5) end

local function with_sign(v)
	v = round_off(v)
	return (v > 0 and "+" or "") .. v
end

-- a token: border (light and thick for yours), background, strip in the team color,
-- place, Crown and points
local function token(color)
	local gt = { colore = color, x = 0, tx = 0, display = 0, bump = 0, w = GET_W }
	gt.radice = root_node(0, Y)
	gt.dentro = box(gt.radice, 0, 0, 0, 0, vmath.vector4(1, 1, 1, 1))
	gui.set_visible(gt.dentro, false)
	gt.bordo = box(gt.dentro, 0, 0, GET_W + 2 * BORDER_MINE, GET_H + 2 * BORDER_MINE, ui.C.LIGHT)
	gt.fondo = box(gt.dentro, 0, 0, GET_W, GET_H, ui.C.PANEL)
	gt.strip = box(gt.dentro, -GET_W / 2 + STRIP / 2, 0, STRIP, GET_H, color)
	gt.posto = ui.testo("", -GET_W / 2 + STRIP + 6, 0, CAPTION, color, gt.dentro)
	gui.set_pivot(gt.posto, gui.PIVOT_W)
	-- the first one's Crown: big, resting on the token's top border
	gt.crown = gui.new_box_node(vmath.vector3(0, CROWN_Y, 0), vmath.vector3(CROWN_W, CROWN_W * 59 / 108, 0))
	gui.set_texture(gt.crown, "battaglia")
	gui.play_flipbook(gt.crown, "targa_corona")
	gui.set_adjust_mode(gt.crown, gui.ADJUST_FIT)
	gui.set_parent(gt.crown, gt.dentro)
	gui.set_inherit_alpha(gt.crown, true)
	gt.valore = ui.testo("0", GET_W / 2 - 8, 0, CAPTION, ui.C.TEXT, gt.dentro)
	gui.set_pivot(gt.valore, gui.PIVOT_E)
	-- the pending points: a dashed token... in our own way, border in the team
	-- color, an hourglass (two bars and an X) and the number
	gt.attesa = root_node(0, 0)
	gui.set_parent(gt.attesa, gt.radice)
	gui.set_visible(gt.attesa, false)
	local bottom, border = ui.pannello(0, 0, WAIT_W, WAIT_H, gt.attesa)
	gui.set_color(bottom, ui.C.PANEL)
	gui.set_color(border, color)
	local cx = -WAIT_W / 2 + 12
	box(gt.attesa, cx, 5, 9, 2, color)
	box(gt.attesa, cx, -5, 9, 2, color)
	for _, a in ipairs({ 50, -50 }) do
		local x = box(gt.attesa, cx, 0, 2, 11, color)
		gui.set_euler(x, vmath.vector3(0, 0, a))
	end
	gt.waiting_text = ui.testo("", 6, 0, SMALL, ui.C.TEXT, gt.attesa)
	gt.waiting_on = false
	gui.set_enabled(gt.attesa, false)
	-- the dots of the lap's turns (at most two per team), under the box
	gt.dots = {}
	for i = 1, 2 do
		local pl = { ring_node = ui.ring_node(0, -DOT_Y, DOT, 2, color, gt.radice) }
		pl.full = ui.disco(0, -DOT_Y, DOT - 3, color, gt.radice)
		gui.set_enabled(pl.ring_node, false)
		gui.set_enabled(pl.full, false)
		gt.dots[i] = pl
	end
	return gt
end

-- token width; the strip sits on the outer side (right: on the right)
local function shape(gt, w, right)
	gt.w = w
	gt.mio = nil
	size(gt.fondo, w, GET_H)
	position(gt.strip, (right and 1 or -1) * (w / 2 - STRIP / 2), 0)
	if w == GET_W then
		position(gt.valore, w / 2 - 8, 0)
		gui.set_pivot(gt.valore, gui.PIVOT_E)
	else
		-- rope end: the number in the center
		position(gt.valore, (right and -1 or 1) * STRIP / 2, 0)
		gui.set_pivot(gt.valore, gui.PIVOT_CENTER)
	end
end

function M.nuovo(palette, tick)
	local p = { gettoni = {}, numeri = {}, tick = tick, tick_t = 0, tick_n = 0, on = true }
	for t = 1, TEAMS do p.gettoni[t] = token(palette[t]) end

	-- the rope
	p.fune = root_node(HALF, Y)
	box(p.fune, 0, 0, ROPE_W + 4, ROPE_H + 4, ui.C.SHADOW)
	p.rope_a = box(p.fune, -ROPE_W / 2, 0, ROPE_W / 2, ROPE_H, palette[1])
	gui.set_pivot(p.rope_a, gui.PIVOT_W)
	p.rope_b = box(p.fune, ROPE_W / 2, 0, ROPE_W / 2, ROPE_H, palette[2])
	gui.set_pivot(p.rope_b, gui.PIVOT_E)
	-- the part of the rope for pending points: like the rope, in the color of
	-- whoever has them, but with diagonal stripes scrolling toward the other team
	-- (the stripes are clipped by the part itself, which acts as a stencil)
	p.rope_wait = box(p.fune, 0, 0, 0, ROPE_H, palette[1])
	gui.set_pivot(p.rope_wait, gui.PIVOT_W)
	gui.set_clipping_mode(p.rope_wait, gui.CLIPPING_MODE_STENCIL)
	gui.set_enabled(p.rope_wait, false)
	p.fasce = {}
	for i = 1, math.ceil(ROPE_W / BAND_STEP) + 3 do
		local f = box(p.rope_wait, 0, 0, BAND_W, ROPE_H * 2.2, palette[1])
		gui.set_rotation(f, vmath.vector3(0, 0, 45))
		p.fasce[i] = f
	end
	p.rope_sign = box(p.fune, 0, 0, 3, ROPE_H + 10, ui.C.LIGHT)
	p.rope_f = 0.5

	-- gap under your token, turn balance under the row
	p.gap = root_node(0, Y - GET_H / 2 - 12)
	p.gap_text = ui.testo("", 0, 0, SMALL, ui.C.TEXT, p.gap)
	p.riga = root_node(HALF, Y - GET_H / 2 - 34)
	p.row_text = ui.testo("", 0, 0, SMALL, ui.C.LIGHT, p.riga)
	p.line_ticks = 0
	-- the mission goal, under the turn line
	p.obiettivo = root_node(HALF + 215, Y)
	p.objective_text = ui.testo("", 0, 0, CAPTION, ui.GOLD, p.obiettivo)
	gui.set_pivot(p.objective_text, gui.PIVOT_W)
	gui.set_line_break(p.objective_text, true)
	gui.set_size(p.objective_text, vmath.vector3(300 / (CAPTION * 0.5), 100, 0))
	p.goal_on = false
	-- "+N PER PAREGGIARE" under the team that has to answer
	p.tie = root_node(0, Y - BELOW_Y)
	p.tie_text = ui.testo("", 0, 0, SMALL, ui.C.TEXT, p.tie)
	p.tie_s = ""
	-- before the last lap, under the board
	p.avviso = root_node(HALF, Y - GET_H / 2 - 62)
	ui.testo(T.last_round_soon, 0, 0, SMALL, ui.GOLD, p.avviso)
	p.notice_on = false
	gui.set_enabled(p.avviso, false)
	-- the last-lap banner, in the middle of the screen
	p.banner = root_node(HALF, 400)
	box(p.banner, 0, 0, BANNER_W, BANNER_H, vmath.vector4(0.16, 0.1, 0.02, 0.9))
	box(p.banner, 0, BANNER_H / 2, BANNER_W, 3, ui.GOLD)
	box(p.banner, 0, -BANNER_H / 2, BANNER_W, 3, ui.GOLD)
	ui.testo(T.last_round, 0, 14, 2.4, ui.GOLD, p.banner)
	ui.testo(T.double_points, 0, -32, 0.9, ui.C.TEXT, p.banner)
	p.banner_time = 0
	gui.set_inherit_alpha(p.banner, true)
	gui.set_enabled(p.banner, false)

	-- the flying numbers, on top of everything else
	for i = 1, NUMBERS do
		local n = { nodo = ui.testo("", 0, 0, FLIGHT_SCALE, ui.C.TEXT), colore = vmath.vector4(1, 1, 1, 1) }
		gui.set_adjust_mode(n.nodo, gui.ADJUST_FIT)
		gui.set_enabled(n.nodo, false)
		p.numeri[i] = n
	end
	M.set_enabled(p, false)
	return p
end

-- The real top of the screen (ui/screen.lua: higher than 720 on a tablet)
function M.cima(p, y1)
	Y = y1 - TOP
	position(p.fune, HALF, Y)
	position(p.riga, HALF, Y - GET_H / 2 - 34)
	position(p.obiettivo, HALF + 215, Y)
	position(p.avviso, HALF, Y - GET_H / 2 - 62)
	position(p.banner, HALF, y1 / 2 + 40)
	for _, gt in ipairs(p.gettoni) do
		if gt.x then position(gt.radice, gt.x, Y) end
	end
end

function M.obiettivo(p, txt)
	p.goal_on = txt ~= nil
	if txt and txt ~= p.goal_written then gui.set_text(p.objective_text, txt) end
	p.goal_written = txt
	gui.set_enabled(p.obiettivo, p.on and p.goal_on)
end

-- Lessons that haven't explained points yet don't show them (sim/missions.lua vedi)
function M.conceal(p, si)
	p.nascosti = si
	M.set_enabled(p, p.on)
end

function M.set_enabled(p, on)
	p.on = on
	-- the goal stays even without the points
	local punti = on and not p.nascosti
	for t, gt in ipairs(p.gettoni) do gui.set_enabled(gt.radice, punti and p.squadre and p.squadre[t] or false) end
	gui.set_enabled(p.fune, punti and p.rope_on or false)
	gui.set_enabled(p.gap, punti)
	gui.set_enabled(p.riga, punti and p.line_ticks > 0)
	gui.set_enabled(p.obiettivo, on and p.goal_on)
	gui.set_enabled(p.tie, punti and p.tie_s ~= "")
	gui.set_enabled(p.avviso, punti and p.notice_on and not p.goal_on)
	gui.set_enabled(p.banner, punti and p.banner_time > 0)
	if not on then
		for _, n in ipairs(p.numeri) do n.is_active = false; gui.set_enabled(n.nodo, false) end
	end
end

-- team -> real points (or, with flight, minus those still in the air)
local function team_points(p, g, flight)
	local s = {}
	for t in pairs(p.squadre) do s[t] = 0 end
	for i, rb in ipairs(g.robots) do s[rb.team] = s[rb.team] + rb.points - (flight and p.volo[i] or 0) end
	return s
end

function M.partita(p, g, name_list, plates)
	p.nomi, p.plates, p.volo = name_list, plates, {}
	p.squadre, p.lista = {}, {}
	for _, rb in ipairs(g.robots) do
		if not p.squadre[rb.team] then p.squadre[rb.team] = true; p.lista[#p.lista + 1] = rb.team end
	end
	table.sort(p.lista)
	p.rope_on = #p.lista == 2
	-- left edge of the row, so it is centered
	local n = #p.lista
	p.x0 = HALF - (p.rope_on and (2 * VAL_W + 2 * ROPE_GAP + ROPE_W) or (n * GET_W + (n - 1) * GET_GAP)) / 2
	for _, n in ipairs(p.numeri) do n.is_active = false; gui.set_enabled(n.nodo, false) end
	for i, t in ipairs(p.lista) do
		local gt = p.gettoni[t]
		gt.display, gt.bump = 0, 0
		gui.set_text(gt.valore, "0")
		gui.set_text(gt.posto, "")
		gui.set_enabled(gt.crown, false)
		if p.rope_on then
			-- the two ends of the rope; the pending-points token on the outer side
			shape(gt, VAL_W, i == 2)
			gt.x = i == 1 and p.x0 + VAL_W / 2 or p.x0 + VAL_W + 2 * ROPE_GAP + ROPE_W + VAL_W / 2
			gt.waiting_x = (i == 1 and -1 or 1) * (VAL_W / 2 + WAIT_GAP + WAIT_W / 2)
			position(gt.attesa, gt.waiting_x, 0)
		else
			shape(gt, GET_W, false)
			gt.x = p.x0 + GET_W / 2 + (i - 1) * (GET_W + GET_GAP)
		end
		gt.tx = gt.x
		position(gt.radice, gt.x, Y)
	end
	if p.rope_on then
		gui.set_color(p.rope_a, p.gettoni[p.lista[1]].colore)
		gui.set_color(p.rope_b, p.gettoni[p.lista[2]].colore)
	end
	p.rope_f, p.line_ticks = 0.5, 0
	p.banner_time, p.ultimo = 0, nil
	for _, gt in ipairs(p.gettoni) do
		gt.waiting_on, gt.waiting_s, gt.dots_s = false, nil, nil
		gui.set_enabled(gt.attesa, false)
		for _, pl in ipairs(gt.dots) do gui.set_enabled(pl.ring_node, false); gui.set_enabled(pl.full, false) end
	end
	p.inizio = team_points(p, g)
	p.in_order_now = g.robots[g.current] and g.robots[g.current].team
	for i in ipairs(g.robots) do plate.posto(plates[i], "", false) end
	p.posti = {}
	M.set_enabled(p, p.on)
end

-- a number is born at x, y (screen); if the same robot has one just born
-- from the same hit (damage and kill together) it adds to that one
function M.punti(p, e, x, y)
	if not p.squadre or p.nascosti or e.amount == 0 then return end
	local r = e.robot
	p.volo[r] = (p.volo[r] or 0) + e.amount
	for _, n in ipairs(p.numeri) do
		if n.is_active and n.fase == 1 and n.chi == r and n.altro == e.other then
			n.punti, n.t = n.punti + e.amount, 0
			gui.set_text(n.nodo, with_sign(n.punti) .. (n.doppio and T.doubled or ""))
			return
		end
	end
	local n
	for _, m in ipairs(p.numeri) do
		if not m.is_active then n = m; break end
	end
	if not n then
		-- all in the air: the oldest one arrives at once
		n = p.numeri[1]
		for _, m in ipairs(p.numeri) do if m.born < n.born then n = m end end
		p.volo[n.chi] = p.volo[n.chi] - n.punti
	end
	n.is_active, n.fase, n.t, n.chi, n.altro, n.punti, n.born = true, 1, 0, r, e.other, e.amount, (p.born or 0) + 1
	n.doppio = p.ultimo
	p.born = n.born
	n.x, n.y = x, y
	for _, q in ipairs(STACK) do
		local px, py, free_spot = x + q[1] * STACK_X, y + q[2] * STACK_Y, true
		for _, m in ipairs(p.numeri) do
			if m ~= n and m.is_active and m.fase == 1 and abs(m.x - px) < STACK_X and abs(m.y - py) < STACK_Y then free_spot = false end
		end
		if free_spot then
			n.x, n.y = px, py
			break
		end
	end
	gui.set_text(n.nodo, with_sign(n.punti) .. (n.doppio and T.doubled or ""))
	gui.set_enabled(n.nodo, p.on)
end

-- The last lap starts: the golden banner
function M.last_lap(p)
	if not p.squadre or p.nascosti then return end
	p.banner_time = BANNER_DURATION
	gui.set_enabled(p.banner, p.on)
end

-- at every new turn, the balance of the one just ended
function M.turno(p, g)
	if not p.squadre or p.nascosti then return end
	local now_pts = team_points(p, g)
	local t = p.in_order_now
	if t and p.inizio[t] then
		local d = round_off(now_pts[t] - p.inizio[t])
		if d ~= 0 then
			gui.set_text(p.row_text, T.turn_of:format(p.nomi[t], with_sign(d)))
			local c = p.gettoni[t].colore
			p.row_color = p.row_color or vmath.vector4(1, 1, 1, 1)
			p.row_color.x, p.row_color.y, p.row_color.z = c.x, c.y, c.z
			p.line_ticks = TURN_T
			gui.set_enabled(p.riga, p.on)
		end
	end
	p.inizio = now_pts
	p.in_order_now = g.robots[g.current] and g.robots[g.current].team
end

local function arrives(p, n)
	n.is_active = false
	gui.set_enabled(n.nodo, false)
	p.volo[n.chi] = (p.volo[n.chi] or 0) - n.punti
	if abs(p.volo[n.chi]) < 1e-6 then p.volo[n.chi] = 0 end
end

-- where r's number lands: its token
local function target_pt(p, g, r)
	local rb = g.robots[r]
	local gt = rb and p.gettoni[rb.team]
	if not gt then return 0, Y end
	-- pending points go into their token, next to the box
	if gt.waiting_on then return gt.x + gt.waiting_x, Y end
	return gt.x + (gt.w == GET_W and gt.w / 2 - 22 or 0), Y
end

local function numbers(p, dt, g)
	for _, n in ipairs(p.numeri) do
		if n.is_active then
			n.t = n.t + dt
			local rb = g.robots[n.chi]
			local c = rb and p.gettoni[rb.team] and p.gettoni[rb.team].colore or ui.C.TEXT
			if n.punti < 0 then c = ui.C.OFF elseif n.doppio then c = ui.GOLD end
			local s, x, y
			if n.fase == 1 then
				-- born: pops out big and rises a little
				local k = min(1, n.t / SPAWN_T)
				s = FLIGHT_SCALE * (1 + 0.5 * max(0, 1 - n.t / 0.12))
				x, y = n.x, n.y + SALE * (1 - (1 - k) * (1 - k))
				if n.t >= SPAWN_T then n.fase, n.t, n.x0, n.y0 = 2, 0, x, y end
			else
				-- flies into the token, faster and faster
				local k = min(1, n.t / FLIGHT_T)
				local e = k * k
				local tx, ty = target_pt(p, g, n.chi)
				x, y = n.x0 + (tx - n.x0) * e, n.y0 + (ty - n.y0) * e
				s = FLIGHT_SCALE + (ARRIVAL_SCALE - FLIGHT_SCALE) * e
				if k >= 1 then
					arrives(p, n)
					if rb and p.gettoni[rb.team] then p.gettoni[rb.team].bump = 1 end
				end
			end
			if n.is_active then
				position(n.nodo, x, y)
				scale(n.nodo, s * 0.5)
				C.x, C.y, C.z, C.w = c.x, c.y, c.z, 1
				gui.set_color(n.nodo, C)
			end
		end
	end
end

-- The turn dots of team t: one per player, in turn order; full for whoever
-- already played this lap, pulsing for whoever is playing now.
-- Golden in the last lap.
local function dots(p, g, t, gt)
	local who = {}
	for _, id in ipairs(g.order) do
		local rb = g.robots[id]
		if rb and rb.team == t and not rb.gone and #who < #gt.dots then who[#who + 1] = rb end
	end
	local key = (p.ultimo and "u" or "") .. #who
	for _, rb in ipairs(who) do key = key .. (rb.round_done and "1" or "0") end
	if gt.dots_s ~= key then
		gt.dots_s = key
		local col = p.ultimo and ui.GOLD or gt.colore
		for i, pl in ipairs(gt.dots) do
			local rb = who[i]
			gui.set_enabled(pl.ring_node, rb ~= nil)
			gui.set_enabled(pl.full, rb ~= nil and rb.round_done or false)
			if rb then
				local x = (i - (#who + 1) / 2) * (DOT + DOT_GAP)
				position(pl.ring_node, x, -DOT_Y)
				position(pl.full, x, -DOT_Y)
				gui.set_color(pl.ring_node, col)
				gui.set_color(pl.full, col)
			end
		end
	end
	for i, pl in ipairs(gt.dots) do
		local rb = who[i]
		scale(pl.ring_node, rb and rb.id == g.current and g.phase ~= "over" and 1.15 + 0.2 * math.sin(p.ora * 7) or 1)
	end
end

-- places: 1 + how many teams have more points; none if they are all even
local function places(p, v)
	local out, even = {}, true
	local first = v[p.lista[1]]
	for _, t in ipairs(p.lista) do
		if v[t] ~= first then even = false end
	end
	for _, t in ipairs(p.lista) do
		local k = 1
		for _, u in ipairs(p.lista) do if v[u] > v[t] then k = k + 1 end end
		out[t] = not even and k or nil
	end
	return out
end

function M.update(p, dt, g, my_own)
	if not p.squadre or not p.on or p.nascosti then return end
	p.ora = (p.ora or 0) + dt
	numbers(p, dt, g)

	-- what the tokens show: the points that arrived, rounded
	local v = team_points(p, g, true)
	for t, x in pairs(v) do v[t] = round_off(x) end
	p.ultimo = g.final_round or nil
	-- turn pairs: the points of whoever opened the pair beyond what they had
	-- then stay pending; the rest of the board is at even turns
	local waiting_t, waiting, alive = nil, 0, nil
	if p.rope_on and (g.ahead or 0) > 0 and v[g.ahead] then
		local d = v[g.ahead] - round_off(g.ahead_base or 0)
		if d >= 1 then
			waiting_t, waiting = g.ahead, d
			alive = { [p.lista[1]] = v[p.lista[1]], [p.lista[2]] = v[p.lista[2]] }
			v[waiting_t] = v[waiting_t] - d
		end
	end
	local pos = places(p, v)
	local head_end = g:leader()
	local firsts = 0
	for _, t in ipairs(p.lista) do if pos[t] == 1 then firsts = firsts + 1 end end
	local my_team = g.robots[my_own] and g.robots[my_own].team

	-- free-for-all: the tokens line up by place (on ties, by team)
	if not p.rope_on then
		local ordering = {}
		for i, t in ipairs(p.lista) do ordering[i] = t end
		table.sort(ordering, function(a, b)
			if v[a] ~= v[b] then return v[a] > v[b] end
			return a < b
		end)
		for i, t in ipairs(ordering) do p.gettoni[t].tx = p.x0 + GET_W / 2 + (i - 1) * (GET_W + GET_GAP) end
	end

	local tick = false
	for _, t in ipairs(p.lista) do
		local gt = p.gettoni[t]
		-- slides into place in under 200 ms
		gt.x = gt.x + (gt.tx - gt.x) * min(1, dt * 22)
		if abs(gt.tx - gt.x) < 0.5 then gt.x = gt.tx end
		position(gt.radice, gt.x, Y)
		-- the number climbs toward the points that arrived, in steps of TICK_STEP
		if gt.display ~= v[t] then
			local d = v[t] - gt.display
			local step = max(1, abs(d) * dt * 8, 40 * dt)
			local first_one = gt.display
			gt.display = abs(d) <= step and v[t] or gt.display + (d > 0 and step or -step)
			if d > 0 and floor(gt.display / TICK_STEP) ~= floor(first_one / TICK_STEP) then tick = true end
			gui.set_text(gt.valore, tostring(round_off(gt.display)))
		end
		gt.bump = max(0, gt.bump - dt * 5)
		scale(gt.dentro, 1 + 0.18 * gt.bump)
		local k = (t == my_team and 1 or 0) + (p.ultimo and 2 or 0)
		if gt.border_k ~= k then
			gt.border_k, gt.mio = k, t == my_team
			local b = gt.mio and BORDER_MINE or 1
			size(gt.bordo, gt.w + 2 * b, GET_H + 2 * b)
			-- in the last lap the boxes are golden
			gui.set_color(gt.bordo, p.ultimo and ui.GOLD or gt.mio and ui.C.LIGHT or ui.C.LINE)
		end
		-- the pending points next to the box
		local on = waiting_t == t
		if gt.waiting_on ~= on then gt.waiting_on = on; gui.set_enabled(gt.attesa, on) end
		if on then
			local s = "+" .. waiting
			if gt.waiting_s ~= s then gui.set_text(gt.waiting_text, s); gt.waiting_s = s end
		end
		if p.rope_on then dots(p, g, t, gt) end
		local s = not p.rope_on and pos[t] and (pos[t] .. "°") or ""
		if gt.place_s ~= s then gui.set_text(gt.posto, s); gt.place_s = s end
		-- the Crown on the token that is first alone, once its points arrived
		-- (and after the first laps without a Crown, like game:leader)
		gui.set_enabled(gt.crown, pos[t] == 1 and firsts == 1 and (g.round or 1) > (g.score.crown_rounds or 0))
	end

	-- the ticking rises in pitch while points keep arriving
	p.tick_t = p.tick_t - dt
	if tick and p.tick_t <= 0 and p.tick then
		p.tick(1 + 0.05 * min(p.tick_n, 16))
		p.tick_n, p.tick_t = p.tick_n + 1, TICK_EVERY
	elseif not tick and p.tick_t < -0.4 then
		p.tick_n = 0
	end

	-- the rope: toward whoever is ahead, still in the center when even
	if p.rope_on then
		local a, b = v[p.lista[1]], v[p.lista[2]]
		local f = 0.5 + 0.5 * (a - b) / (max(a, 0) + max(b, 0) + SOFT)
		f = max(0.04, min(0.96, f))
		p.rope_f = p.rope_f + (f - p.rope_f) * min(1, dt * 10)
		size(p.rope_a, ROPE_W * p.rope_f, ROPE_H)
		size(p.rope_b, ROPE_W * (1 - p.rope_f), ROPE_H)
		position(p.rope_sign, ROPE_W * (p.rope_f - 0.5), 0)
		-- where it would be with the pending points: a part pulsing in the color of whoever has them
		local fv = p.rope_f
		if alive then
			local va, vb = alive[p.lista[1]], alive[p.lista[2]]
			fv = max(0.04, min(0.96, 0.5 + 0.5 * (va - vb) / (max(va, 0) + max(vb, 0) + SOFT)))
		end
		p.rope_v = (p.rope_v or fv) + (fv - (p.rope_v or fv)) * min(1, dt * 10)
		local from_pt, a2 = min(p.rope_f, p.rope_v), max(p.rope_f, p.rope_v)
		local on = alive ~= nil and a2 - from_pt > 0.002
		gui.set_enabled(p.rope_wait, on)
		if on then
			position(p.rope_wait, ROPE_W * (from_pt - 0.5), 0)
			size(p.rope_wait, ROPE_W * (a2 - from_pt), ROPE_H)
			-- darker background and stripes in the team's full color
			if p.bands_t ~= waiting_t then
				p.bands_t = waiting_t
				local c = p.gettoni[waiting_t].colore
				C.x, C.y, C.z, C.w = c.x * 0.55, c.y * 0.55, c.z * 0.55, 1
				gui.set_color(p.rope_wait, C)
				for _, f in ipairs(p.fasce) do gui.set_color(f, c) end
			end
			-- the stripes are still relative to the rope and scroll toward whoever must answer
			local toward = waiting_t == p.lista[1] and 1 or -1
			local x0 = (ROPE_W * (0.5 - from_pt) + toward * p.ora * BAND_V) % BAND_STEP - 2 * BAND_STEP
			for i, f in ipairs(p.fasce) do position(f, x0 + (i - 1) * BAND_STEP, 0) end
		end
	end

	-- "+N PER PAREGGIARE" under whoever must answer
	local other_one
	if waiting_t then
		for _, t in ipairs(p.lista) do if t ~= waiting_t then other_one = t end end
	end
	local ps = other_one and T.to_tie:format(waiting) or ""
	if p.tie_s ~= ps then
		gui.set_text(p.tie_text, ps)
		if other_one then gui.set_color(p.tie_text, p.gettoni[other_one].colore) end
		p.tie_s = ps
		gui.set_enabled(p.tie, ps ~= "")
	end
	if other_one then position(p.tie, p.gettoni[other_one].x, Y - BELOW_Y) end

	-- before the last lap, the warning
	local notice = not p.ultimo and g.phase ~= "over" and g.match_left <= g:final_round_ticks() + NOTICE_BEFORE
	if p.notice_on ~= notice then
		p.notice_on = notice
		gui.set_enabled(p.avviso, notice and not p.goal_on)
	end

	-- the last-lap banner comes in at once and fades
	if p.banner_time > 0 then
		p.banner_time = p.banner_time - dt
		local past = BANNER_DURATION - p.banner_time
		C.x, C.y, C.z, C.w = 1, 1, 1, min(1, past / 0.15, max(0, p.banner_time) / 0.6)
		gui.set_color(p.banner, C)
		scale(p.banner, 1 + 0.25 * max(0, 1 - past / 0.2))
		if p.banner_time <= 0 then gui.set_enabled(p.banner, false) end
	end

	-- gap under your token
	local s = ""
	if my_team and pos[my_team] then
		local mine_v, another = v[my_team], nil
		for _, t in ipairs(p.lista) do
			if t ~= my_team then
				if pos[my_team] == 1 then
					if not another or v[t] > another then another = v[t] end
				elseif pos[t] == 1 then
					another = v[t]
				end
			end
		end
		if another then
			if p.rope_on then
				s = with_sign(mine_v - another)
			elseif mine_v == another then
				s = T.tied_first
			else
				s = pos[my_team] == 1 and T.ahead:format(mine_v - another) or T.behind:format(mine_v - another)
			end
		end
	end
	-- under my box the "+N PER PAREGGIARE" takes the place of the gap
	if other_one and other_one == my_team then s = "" end
	if p.gap_s ~= s then gui.set_text(p.gap_text, s); p.gap_s = s end
	if my_team then position(p.gap, p.gettoni[my_team].x, Y - (p.rope_on and BELOW_Y or GET_H / 2 + 13)) end

	-- the turn line stays a moment and fades
	if p.line_ticks > 0 then
		p.line_ticks = p.line_ticks - dt
		local c = p.row_color
		C.x, C.y, C.z, C.w = c.x, c.y, c.z, min(1, p.line_ticks / TURN_FADE)
		gui.set_color(p.row_text, C)
		if p.line_ticks <= 0 then gui.set_enabled(p.riga, false) end
	end

	-- place and Crown above the head
	for i, rb in ipairs(g.robots) do
		local k = pos[rb.team]
		local txt = k and (k .. "°") or ""
		local crown = head_end == rb
		local key = txt .. (crown and "c" or "")
		if p.posti[i] ~= key then
			plate.posto(p.plates[i], txt, crown)
			p.posti[i] = key
		end
	end
end

return M
