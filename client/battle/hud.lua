-- Pieces of the battle HUD (docs/decisioni/interfaccia.md, 29 October):
-- the ring stopwatch at the bottom center, the round buttons (teleport,
-- tool, items) and the tag with the name of what you're holding.
-- game.gui_script decides the layout; here only how they look.
--
--   local c = hud.stopwatch(x, y)
--   hud.stopwatch_update(c, dt, fase, left_ones, total, squadra, clock)
--   hud.stopwatch_ticks(c)     -- purple orb ticks (config.TELEPORT_THRESHOLDS) on the turn ring
--   hud.orbs_nodes(c)      -- after the buttons, so the orbs fly over them
--   hud.globi(c, n, pos, slowed, arrival) -- the saved seconds fly as orbs onto pos
--     (the teleport); arrival(i) when orb i touches the button
--   hud.round_flash(t)     -- the button lights up: a growing ring and the number jumps
--     fase: "turno" (white), "secondo" (yellow, the second attack is left),
--     "riparati" (blue, attacks used up) or nil (no turn to count)
--   local t = hud.tondo(x, y, d, icon_img, colore, parent)   -- icon_img: "<icon>_icona" of the weapons atlas
--   hud.round_number(t, "2")
--   local s = hud.scambio()     -- the button that swaps the second attack for a teleport
--   hud.swap_update(s, is_visible, c) / if hud.swap_press(s, px, py) then ... end
--   local k = hud.tag()
--   hud.tag_up(k, x, y, "LAMA") / hud.tag_away(k)
--   local a = hud.avviso()
--   local why = hud.motivo(g, "teleport")   -- why it can't be used now (or nil: it can)
--   hud.rifiuta(a, nodo, x, y, d, why)      -- the button shakes its head and the reason shows above

local ui = require "ui.ui"
local config = require "sim.config"
local game = require "sim.game"
local screen = require "ui.screen"

local M = {}

local max, min, ceil = math.max, math.min, math.ceil

-- the tag's names
M.NAMES = { missile = "LANCIARUNE", grenade = "UOVO DI FIAMMA", shards = "SCIAME DI SCHEGGE", punch = "PUGNO DEL TITANO",
	sniper = "CECCHINO", sword = "LAMA", eagle = "TONANTE", mallet = "MAGLIO", lunge = "AFFONDO", bellows = "MANTICE", hook = "RAMPINO",
	teleport = "TELETRASPORTO", parachute = "PARACADUTE", trampoline = "TRAMPOLINO" }

-- The colors of the turn phases, the ones of the old bar
M.WHITE = vmath.vector4(0.92, 0.9, 0.86, 1)
M.YELLOW = vmath.vector4(1, 0.8, 0.2, 1)
M.BLUE = vmath.vector4(0.3, 0.6, 1, 1)
local PHASES = {
	turno = { colore = M.WHITE },
	secondo = { colore = M.YELLOW, word = "SECONDO!" },
	riparati = { colore = M.BLUE, word = "RIPARATI" },
}

-- Ring sizes: line radius, thickness; the dark disc behind and the thin
-- border in the player's color sit just outside
M.RADIUS, M.THICKNESS = 54, 11
M.OUTSIDE = M.RADIUS + M.THICKNESS * 0.55 + 2
local BOTTOM = vmath.vector4(0.04, 0.035, 0.05, 0.72)
local TRACK = vmath.vector4(1, 1, 1, 0.1)
local NUMBER, WORD, CLOCK = 2.4, 0.6, 1.0   -- ui.testo scales
local NOTCH = vmath.vector4(0.04, 0.035, 0.05, 1)
local ORBS, ORB_FLIGHT, ORB_AFTER = 6, 0.55, 0.09
M.ORBS = ORBS   -- orbs flying together, at most
-- speed of the "pling" of each orb reaching the teleport: it rises by a
-- major third, then a fifth and an octave (C, E, G, C...)
M.ORB_TONES = { 1, 1.26, 1.5, 2, 2.52, 3 }

local V = vmath.vector3(0, 0, 0)
local C = vmath.vector4(1, 1, 1, 1)

local function fit(n)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	return n
end

local function scale(n, s)
	V.x, V.y, V.z = s, s, 1
	gui.set_scale(n, V)
end

-- The beat of every second (extra size fraction): barely there at turn start,
-- stronger and stronger toward the end; strong when the second-attack window
-- is about to close; an even breath while taking cover.
local function lerp(a, b, k) return a + (b - a) * max(0, min(1, k)) end
local function amplitude(stage, s)
	if stage == "turno" then
		if s > 10 then return 0.03 end
		if s > 5 then return lerp(0.04, 0.08, (10 - s) / 5) end
		return lerp(0.10, 0.18, (5 - s) / 4)
	elseif stage == "secondo" then
		return lerp(0.05, 0.16, (8 - s) / 7)
	end
	return 0.02
end
M.amplitude = amplitude
local WAVE_FROM = 0.1   -- from this beat up the wave also comes out of the border

function M.stopwatch(x, y)
	local c = { beat = 0, amp = 0, wave = 0, on = true }
	c.radice = fit(gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(0, 0, 0)))
	gui.set_visible(c.radice, false)
	c.wave_n = fit(ui.ring_node(0, 0, 2 * M.OUTSIDE, 3, M.WHITE, c.radice))
	gui.set_enabled(c.wave_n, false)
	-- in the last lap a golden halo and ring around it (stopwatch_gold)
	c.gold_halo = fit(ui.alone(0, 0, 2 * M.OUTSIDE + 70, ui.GOLD, c.radice))
	c.gold_ring = fit(ui.ring_node(0, 0, 2 * M.OUTSIDE + 12, 4, ui.GOLD, c.radice))
	gui.set_enabled(c.gold_halo, false)
	gui.set_enabled(c.gold_ring, false)
	fit(ui.disco(0, 0, 2 * M.OUTSIDE, BOTTOM, c.radice))
	c.squadra = fit(ui.ring_node(0, 0, 2 * M.OUTSIDE, 3, ui.C.LIGHT, c.radice))
	local d = 2 * M.RADIUS + M.THICKNESS
	fit(ui.ring_node(0, 0, d, M.THICKNESS, TRACK, c.radice))
	-- the arc starts at noon and wears away clockwise
	c.arco = fit(ui.ring_node(0, 0, d, M.THICKNESS, M.WHITE, c.radice))
	gui.set_euler(c.arco, vmath.vector3(0, 0, 90))
	c.numero = fit(ui.testo("", 0, 2, NUMBER, ui.C.TEXT, c.radice))
	c.word = fit(ui.testo("", 0, -M.RADIUS * 0.5, WORD, M.WHITE, c.radice))
	-- the match time above, smaller and still
	c.clock = fit(ui.testo("", x, y + M.OUTSIDE + 16, CLOCK, ui.C.TEXT))
	c.x, c.y, c.k = x, y, 1
	return c
end

-- at the real bottom of the screen (ui/screen.lua: below 0 on a tablet)
function M.stopwatch_move(c, x, y)
	c.x, c.y = x, y
	gui.set_position(c.radice, vmath.vector3(x, y, 0))
	gui.set_position(c.clock, vmath.vector3(x, y + M.OUTSIDE + 16, 0))
end

function M.stopwatch_on(c, on)
	c.on = on
	gui.set_enabled(c.radice, on)
	gui.set_enabled(c.clock, on)
end

-- The last lap (double points): golden ring and halo, golden label above
function M.stopwatch_gold(c, on)
	if c.oro == on then return end
	c.oro = on
	gui.set_enabled(c.gold_halo, on)
	gui.set_enabled(c.gold_ring, on)
	gui.set_color(c.clock, on and ui.GOLD or ui.C.TEXT)
end

-- left_ones, total: seconds (with decimals); squadra: color of the player
function M.stopwatch_update(c, dt, stage, left_ones, total, team, clock)
	if not c.on then return end
	if c.clock_s ~= clock then gui.set_text(c.clock, clock); c.clock_s = clock end
	if team and c.team_c ~= team then gui.set_color(c.squadra, team); c.team_c = team end
	local f = PHASES[stage]
	local sec = f and max(0, ceil(left_ones - 1e-6)) or nil
	-- phase change: the yellow comes in with a flash
	if stage ~= c.fase then
		c.fase = stage
		gui.set_color(c.arco, f and f.colore or M.WHITE)
		gui.set_color(c.wave_n, f and f.colore or M.WHITE)
		gui.set_color(c.word, f and f.colore or M.WHITE)
		gui.set_text(c.word, f and f.word or "")
		c.sec = sec
		if stage == "secondo" then c.beat, c.amp, c.wave = 1, 0.2, 1 end
	end
	c.k = f and max(0, min(1, left_ones / total)) or 0
	gui.set_fill_angle(c.arco, -360 * c.k)
	if c.num_s ~= sec then
		gui.set_text(c.numero, sec and tostring(sec) or "")
		gui.set_position(c.numero, vmath.vector3(0, f and f.word and 8 or 2, 0))
		-- a beat for every second that passes
		if sec and c.sec and sec < c.sec and sec > 0 then
			c.beat, c.amp = 1, amplitude(stage, left_ones)
			if c.amp >= WAVE_FROM then c.wave = 1 end
		end
		c.sec, c.num_s = sec, sec
	end
	-- the orb ticks show during the turn until the tip of the arc passes them
	-- (c.ticks_on = false: leftover time gives no orbs)
	if c.ticks then
		for _, t in ipairs(c.ticks) do
			local on = c.ticks_on ~= false and stage == "turno" and total - left_ones <= t.sec
			if t.on ~= on then gui.set_enabled(t.nodo, on); t.on = on end
		end
	end
	c.beat = max(0, c.beat - dt * 4)
	scale(c.radice, 1 + c.amp * c.beat * c.beat)
	c.wave = max(0, c.wave - dt * 2.2)
	gui.set_enabled(c.wave_n, c.wave > 0)
	if c.wave > 0 then
		scale(c.wave_n, 1.05 + (1 - c.wave) * 0.35)
		local col = f and f.colore or M.WHITE
		C.x, C.y, C.z, C.w = col.x, col.y, col.z, c.wave * 0.8
		gui.set_color(c.wave_n, C)
	end
end

-- The orb ticks: where the tip of the arc will be at each threshold, a short
-- purple line on the ring and a purple dot outside, the orb you lose by
-- passing it (Sergio: a single dot per tick, two looked like something else)
function M.stopwatch_ticks(c)
	local thresholds, total = config.TELEPORT_THRESHOLDS, config.TURN_SECONDS
	c.ticks = {}
	for i, sec in ipairs(thresholds) do
		local a = math.rad(90 + 360 * sec / total)
		local cs, sn = math.cos(a), math.sin(a)
		local t = { sec = sec, on = true }
		t.nodo = fit(gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0)))
		gui.set_parent(t.nodo, c.radice)
		gui.set_visible(t.nodo, false)
		-- a dark notch in the ring with the purple line inside
		for _, s in ipairs({ { 8, M.THICKNESS + 2, NOTCH }, { 3, M.THICKNESS + 12, ui.C.PURPLE } }) do
			local riga = fit(gui.new_box_node(vmath.vector3(cs * M.RADIUS, sn * M.RADIUS, 0), vmath.vector3(s[1], s[2], 0)))
			gui.set_color(riga, s[3])
			gui.set_euler(riga, vmath.vector3(0, 0, math.deg(a) - 90))
			gui.set_parent(riga, t.nodo)
		end
		local r = M.OUTSIDE + 9
		fit(ui.disco(cs * r, sn * r, 15, NOTCH, t.nodo))
		fit(ui.disco(cs * r, sn * r, 11, ui.C.PURPLE, t.nodo))
		c.ticks[i] = t
	end
end

-- When you attack, the seconds left become teleports: n orbs come off the
-- tip of the arc, swell and fly in a curve one after the other onto the
-- button (sideways first, then down or up into the button)
local ORB_POP = 0.16
local ALONE = vmath.vector4(ui.C.PURPLE.x, ui.C.PURPLE.y, ui.C.PURPLE.z, 0.35)

-- the orb nodes, created after the buttons so they fly on top
function M.orbs_nodes(c)
	c.globi = {}
	for i = 1, ORBS do
		local g = fit(ui.disco(c.x, c.y, 26, ui.C.PURPLE))
		fit(ui.disco(0, 0, 42, ALONE, g))
		fit(ui.disco(0, 0, 11, ui.C.LIGHT, g))
		gui.set_enabled(g, false)
		c.globi[i] = g
	end
end

-- slowed: how many times slower (the guided match makes you watch them)
function M.globi(c, n, pos, slowed, arrival)
	slowed = slowed or 1
	local a0 = math.rad(90 - 360 * c.k)
	for i = 1, min(n, ORBS) do
		local g = c.globi[i]
		local a = a0 + math.rad(10 * (i - 1))
		local after_step = (i - 1) * ORB_AFTER * slowed
		gui.cancel_animations(g, "position.x")
		gui.cancel_animations(g, "position.y")
		gui.cancel_animations(g, "scale")
		gui.set_position(g, vmath.vector3(c.x + math.cos(a) * M.RADIUS, c.y + math.sin(a) * M.RADIUS, 0))
		scale(g, 0.2)
		gui.set_enabled(g, true)
		gui.animate(g, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, ORB_POP * slowed, after_step)
		-- in a curve: sideways they leave fast, up or down they arrive fast
		local flight, part = ORB_FLIGHT * slowed, after_step + ORB_POP * slowed
		gui.animate(g, "position.x", pos.x, gui.EASING_OUTSINE, flight, part)
		gui.animate(g, "position.y", pos.y, gui.EASING_INQUAD, flight, part, function()
			gui.set_enabled(g, false)
			if arrival then arrival(i) end
		end)
	end
end

-- Round button: dark disc, border in its family's color, icon
function M.tondo(x, y, d, icon_img, color, parent)
	local t = { d = d, colore = color }
	t.nodo = fit(ui.disco(x, y, d, ui.C.PANEL, parent))
	t.bordo = fit(ui.ring_node(0, 0, d, 3, color, t.nodo))
	t.icon_img = fit(gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(d * 0.74, d * 0.74, 0)))
	gui.set_texture(t.icon_img, "armi")
	gui.play_flipbook(t.icon_img, icon_img .. "_icona")
	gui.set_parent(t.icon_img, t.nodo)
	return t
end

-- the small number at the top right (teleports left, items in hand)
function M.round_number(t, txt)
	if not t.num then
		local r = t.d * 0.36
		t.num = fit(ui.disco(r, r, t.d * 0.36, t.colore, t.nodo))
		t.num_t = fit(ui.testo("", 0, 1, t.d / 84 * 0.8, ui.C.BOTTOM, t.num))
		gui.set_outline(t.num_t, vmath.vector4(0, 0, 0, 0))
	end
	gui.set_enabled(t.num, txt ~= "")
	gui.set_text(t.num_t, txt)
end

-- The button lights up (an orb arrived): a light ring grows and fades,
-- the small number jumps
function M.round_flash(t)
	if not t.lampo then
		t.lampo = fit(ui.ring_node(0, 0, t.d, 5, ui.C.LIGHT, t.nodo))
		gui.set_enabled(t.lampo, false)
	end
	gui.cancel_animations(t.lampo, "scale")
	gui.cancel_animations(t.lampo, "color.w")
	scale(t.lampo, 1)
	gui.set_color(t.lampo, ui.C.LIGHT)
	gui.set_enabled(t.lampo, true)
	gui.animate(t.lampo, "scale", vmath.vector3(1.6, 1.6, 1), gui.EASING_OUTQUAD, 0.4)
	gui.animate(t.lampo, "color.w", 0, gui.EASING_OUTQUAD, 0.4, 0, function() gui.set_enabled(t.lampo, false) end)
	if t.num then
		gui.cancel_animations(t.num, "scale")
		scale(t.num, 1)
		gui.animate(t.num, "scale", vmath.vector3(1.5, 1.5, 1), gui.EASING_OUTQUAD, 0.12, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
	end
end

-- The light tag with the name, pointing down
function M.tag()
	local k = {}
	k.nodo, k.bordo = ui.pannello(0, 0, 100, 26)
	fit(k.nodo)
	gui.set_color(k.nodo, ui.C.LIGHT)
	gui.set_color(k.bordo, ui.C.BOTTOM)
	k.punta = fit(gui.new_box_node(vmath.vector3(0, -13, 0), vmath.vector3(10, 10, 0)))
	gui.set_color(k.punta, ui.C.LIGHT)
	gui.set_euler(k.punta, vmath.vector3(0, 0, 45))
	gui.set_parent(k.punta, k.nodo)
	k.testo = fit(ui.testo("", 0, 1, 0.8, ui.C.BOTTOM, k.nodo))
	gui.set_outline(k.testo, vmath.vector4(0, 0, 0, 0))
	gui.set_enabled(k.nodo, false)
	return k
end

function M.tag_up(k, x, y, txt)
	if k.text_s ~= txt then
		gui.set_text(k.testo, txt)
		k.font = k.font or gui.get_font_resource(gui.get_font(k.testo))
		local w = resource.get_text_metrics(k.font, txt).width * gui.get_scale(k.testo).x + 24
		V.x, V.y, V.z = w, 26, 0
		gui.set_size(k.nodo, V)
		gui.set_size(k.bordo, V)
		k.text_s = txt
	end
	if k.x ~= x or k.y ~= y then
		V.x, V.y, V.z = x, y, 0
		gui.set_position(k.nodo, V)
		k.x, k.y = x, y
	end
	if not k.on then gui.set_enabled(k.nodo, true); k.on = true end
end

function M.tag_away(k)
	if k.on then gui.set_enabled(k.nodo, false); k.on = false end
end

-- Touching a button always selects that thing (Sergio, 30 October: no more
-- toggling on and off). If it can't be used now, what you hold stays and
-- the button says so: it shakes its head and the reason appears above for a
-- moment (and the phone vibrates lightly, game.gui_script).
local NOTICE_H, NOTICE_LIFE = 26, 1.1
local SHAKE = vmath.vector({ 0, 1, -1, 0.8, -0.6, 0.3, 0 })

function M.avviso()
	local a = {}
	a.nodo, a.bordo = ui.pannello(0, 0, 100, NOTICE_H)
	fit(a.nodo)
	gui.set_color(a.nodo, ui.C.PANEL)
	gui.set_color(a.bordo, ui.C.BRACE)
	a.testo = fit(ui.testo("", 0, 1, 0.7, ui.C.TEXT, a.nodo))
	gui.set_outline(a.testo, vmath.vector4(0, 0, 0, 0))
	-- everything fades together
	gui.set_inherit_alpha(a.bordo, true)
	gui.set_inherit_alpha(a.testo, true)
	gui.set_enabled(a.nodo, false)
	return a
end

-- Why the robot whose turn it is can't use w now, or nil if it can. Always
-- two plain words (Sergio, 30 October): used up, already used, or not now
-- (lessons, parachute on the ground, shield already up, orbs in flight)
function M.motivo(g, w)
	if g:can_use(w) then return nil end
	local rb = g.robots[g.current]
	if g.permitted and not g.permitted(w) then return "NON ORA" end
	if w == "teleport" then
		return rb.teleports_left <= 0 and "GLOBI ESAURITI" or "NON ORA"
	elseif w == "hook" then
		return "GIÀ USATO"
	elseif w == "parachute" then
		return rb.parachutes_left <= 0 and not rb.parachute and "MUNIZIONI ESAURITE" or "NON ORA"
	elseif game.TOOLS[w] then
		return rb.ammo[w] <= 0 and "MUNIZIONI ESAURITE" or "NON ORA"
	elseif game.SECONDARY[w] then
		if g.used.secondary then return "GIÀ USATA" end
		return game.has_weapon(rb, w) and "NON ORA" or "MUNIZIONI ESAURITE"
	elseif g.used.primary then
		return "GIÀ USATA"
	end
	return game.has_weapon(rb, w) and "NON ORA" or "MUNIZIONI ESAURITE"
end

-- nodo: the button (at x, y, d wide, in the same parent as the notice)
function M.rifiuta(a, gui_node, x, y, d, txt)
	gui.cancel_animations(gui_node, "position.x")
	V.x, V.y, V.z = x, y, 0
	gui.set_position(gui_node, V)
	gui.animate(gui_node, "position.x", x + 7, SHAKE, 0.32)
	gui.set_text(a.testo, txt)
	a.font = a.font or gui.get_font_resource(gui.get_font(a.testo))
	local w = resource.get_text_metrics(a.font, txt).width * gui.get_scale(a.testo).x + 24
	V.x, V.y = w, NOTICE_H
	gui.set_size(a.nodo, V)
	gui.set_size(a.bordo, V)
	-- above the button, but inside the screen (the teleport sits on the edge)
	V.x = max(screen.x0 + w / 2 + 8, min(screen.x1 - w / 2 - 8, x))
	V.y = y + d / 2 + 50
	gui.set_position(a.nodo, V)
	gui.cancel_animations(a.nodo, "color.w")
	gui.set_color(a.nodo, ui.C.PANEL)
	gui.set_enabled(a.nodo, true)
	gui.animate(a.nodo, "color.w", 0, gui.EASING_INCUBIC, 0.4, NOTICE_LIFE, function() gui.set_enabled(a.nodo, false) end)
end

-- Swapping the second attack for a teleport: after the first attack a small
-- button with two arrows chasing each other appears above the stopwatch, with
-- the label next to it; one tap is enough (Sergio, 29 October evening: before,
-- you had to hold it).
local SWAP_D = 54

function M.scambio()
	local s = { on = true }
	s.radice = fit(gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0)))
	gui.set_visible(s.radice, false)
	s.tondo = M.tondo(0, 0, SWAP_D, "scambio", ui.C.PURPLE, s.radice)
	local x = SWAP_D / 2 + 10
	for _, r in ipairs({ { "BARATTA IL SECONDO ATTACCO", 8 }, { "CON UN TELETRASPORTO", -8 } }) do
		local n = fit(ui.testo(r[1], x, r[2], 0.5, ui.C.TEXT, s.radice))
		gui.set_pivot(n, gui.PIVOT_W)
	end
	M.swap_update(s, false)
	return s
end

-- c: the stopwatch; the button sits above the match time
function M.swap_update(s, is_visible, c)
	if s.on ~= is_visible then
		s.on = is_visible
		gui.set_enabled(s.radice, is_visible)
	end
	if is_visible then gui.set_position(s.radice, vmath.vector3(c.x, c.y + M.OUTSIDE + 36 + SWAP_D / 2, 0)) end
end

-- a tap on the button (true if it took it)
function M.swap_press(s, px, py)
	return s.on and gui.pick_node(s.tondo.nodo, px, py)
end

return M
