-- The FORNACE tab of the BOTTEGA (docs/commesse.md "La Fornace"; Sergio, 24 Nov:
-- entry A and pour A). The wall of today sits in a frame, "in vetrina", beside
-- the Smith at his counter, with what is still on it and when the next one comes.
-- COLA pays the Ossidiana (sim/forge.lua, through the profile's door): the frame
-- grows to the whole screen and comes close on the apprentice, the 20 gems fly
-- from the wallet into his ladle and melt, the three throws appear and the camera
-- opens on the whole wall. You aim like in battle (the finger from the apprentice:
-- direction and power; with the controller the aim stick and SPARA, as in battle:
-- battle/aim.lua and battle/sticks.lua), let go and the ladle swings over the head and throws the
-- drop; the flight is the rules' own (forge.fly). After the last throw the camera
-- goes back into the frame. FONDI I FRAMMENTI opens the melting window.
--
-- The place is the Banco degli Usurai (Sergio, 26 Nov; art WB-097): the Sabbione of
-- circle VII under the rain of fire, the usurers sitting with their purse open to the
-- sky are the moulds (the family's crest on the purse), a drop that misses falls in
-- the sand and is a glass bead for the Smith's jar; under the sand, in the band seen
-- only from far, the money-changers' bench with the loot of the wall, sagging as it
-- grows, broken by the jackpot (the «bancarotta»). The usurers talk now and then.
--
-- The forge is a world of its own (the rules' units, the apprentice's feet at
-- (0, 0), y up) under a stencil frame: in the vetrina the frame is the window on
-- the board, while playing it is the whole screen. It is made again with the
-- board, except while playing (a.fx.phase ~= "vetrina").
--
--   forge_ui.board(a)            -- from the armory's build (a.tab == "fornace")
--   forge_ui.update(a, dt)       -- true when the armory must be made again
--   forge_ui.input(a, id, act)   -- true when the forge took the input (playing)
--   forge_ui.cmd(a, kind, x)     -- the board's taps: true if it was one of its own
--   forge_ui.release(a)          -- leaving the tab

local kit = require "ui.kit"
local ui = require "ui.ui"
local coins = require "ui.coins"
local screen = require "ui.screen"
local scoria = require "battle.scoria"
local aim = require "battle.aim"
local sticks = require "battle.sticks"
local controller = require "ui.controller"
local SP = require "battle.stick_pad"
local phone = require "main.phone"
local game = require "sim.game"
local forge = require "sim.forge"
local orders = require "sim.orders"
local equip = require "sim.gear"
local wallet = require "sim.wallet"
local profile = require "menu.profile"
local PIECES = require "menu.forge_pieces"
local T = require("lang.text").forge
local TP = require("lang.text").pieces

local M = {}

local KC = kit.C
local PAPER_MUTE = vmath.vector4(0.36, 0.3, 0.26, 1)
local VEIL = vmath.vector4(0.03, 0.02, 0.035, 0.72)
local DIM = vmath.vector4(1, 1, 1, 0.35)
local WHITE = vmath.vector4(1, 1, 1, 1)
local BELOW = vmath.vector4(0.133, 0.086, 0.086, 1)

-- The vetrina (Figma, 1280 x 720): the frame of the wall in the middle column of
-- the COMMESSE (menu/orders_ui.lua), the paper with the rule under it, the shelf
-- with what is on the wall on the right
local FRAME = { x = 432, y = 96, w = 568, h = 380 }
local INSET = 4
local PAPER = { x = 432, y = 490, w = 568, h = 100 }
local SHELF = { x = 1028, y = 96, w = 236, h = 494 }
local PAD = 14

-- the world: what the vetrina shows (x from -110 to 1690, the sand at the bottom),
-- the whole wall while playing, close on the apprentice for the pour (the rock
-- wall at forge.BACK_X in the view too)
local WALL_X, WALL_W = 790, 1800
local CLOSE = { x = 50, y = 36, s = 2.2 }
-- the paintings (client/paintings/fornace, tools/grafica/fornace.py): the sky
-- fixed behind the frame, the far and the middle layers in the world, a little
-- slower than it when the camera moves (the far one more). Coming close (the pour)
-- they zoom only up to their own pixels (Codex's 1536 over their width, or what the
-- whole wall already shows): never enlarged, they stay as far as a backdrop, kept
-- covering the view (place_layer)
local FAR = { x = -264, y = -187, w = 2120, k = 0.6 }
local MID = { x = -172, y = -158, w = 1936, k = 0.3 }
-- the Sabbione: the river's embankment in front, its sand on the rules' floor (the
-- dark of the band under it), the apprentice on a stone ledge, the rock wall on the
-- right is the back wall (forge.BACK_X), drawn from the floor up out of the view
local FLOOR_TOP = -132
local ARGINE_W, ARGINE_TOP = 720, -124
local LEDGE = { x = -90, y = 2, w = 150 }
local ROCK_W = 160
-- the usurers' purses (the rules' moulds, WB-098; Sergio, 26 Nov: «questi stessi fagotti
-- senza i predoni ... con delle corde»): the purse's mouth on the mould's (m.x, m.y), its
-- rim RIM_W of the mould wide (the rules' lips are at 0.43 of it, the catch at 0.41); the
-- crest by family, iron for the Scaglie; each hangs on a rope from the beam at the top
local PLATE = { fabbro = "oro", corvo = "azzurro", fornace = "arancio", leviatano = "verde", vuoto = "viola" }
local RIM_W = 0.76
local ROPE_W = 7
-- the beam of the accounts over the wall (Sergio, 26 Nov: «riferimenti per i tiri
-- successivi, non proprio una griglia ... solo in alto»): its middle at y, a peg every
-- PEG_STEP with a knotted cord, long and short in turn (the usurers count debts in knots)
local BEAM = { y = 530, h = 30, x0 = -260 }
local PEG_STEP, CORD_W = 95, 15
local CORDS = { "cordino_lungo_rosso", "cordino_corto", "cordino_lungo", "cordino_corto_rosso" }
-- the usurer who keeps the bench's account, sitting at its right end
local BANKER = { x = 1545, y = -330, h = 225 }
-- the money-changers' bench in the band (Sergio, 26 Nov: «il bancone che si piega»):
-- planks on two trestles, the loot of this wall in heaps on it (the Scaglie, the
-- fragments by family), the jar of glass beads at its end; it sags as the loot grows
-- and the jackpot breaks it in the middle. y is the planks' middle
local BENCH = { x = 40, y = -232, seg = 230, n = 6, sag = 22 }
local TRESTLE_W, TRESTLE_IN = 92, 70
local HEAPS_X, HEAP_GAP = 230, 165
local JAR = { x = 1330, w = 56 }
-- the prize tags over the usurers and their lines: always this big on the screen
local TAG = 17
-- the drop as drawn (the rules' one is forge.DROP_R): the falling flake of fire,
-- its head as wide as DROP_W
local DROP_W = 24
local TRAIL_EVERY, TRAIL_LIFE = 0.03, 0.3

-- the pour (seconds): the frame opens, the gems fly one every GEM_GAP, each
-- GEM_FLY long, they melt, the throws appear, the camera opens on the wall
local OPEN, GEM_START, GEM_GAP, GEM_FLY, MELT, SHOTS, PAN = 0.75, 0.1, 0.04, 0.42, 0.25, 0.45, 0.8
-- the throw (Sergio, 24 Nov: «molto più lunga, plateale»): let go, the camera comes
-- close on the apprentice (WINDUP s), the ladle's throw clip plays (lancio_mestolo,
-- from the animation editor) and the drop leaves where the ladle is fastest; the
-- camera follows it as in battle
local WINDUP = 0.35   -- the camera to the apprentice, when the finger lifts
local JOIN = 0.12     -- the drop from the bowl onto the rules' path
local THROW_CAM = { x = 30, y = 40, s = 1.9 }
-- the molten drop's place in the ladle's bowl (the weapon's units, tools/grafica/armi.py)
local BOWL = { 94.3, -5.8 }
-- a hit: the frozen moment, the shake; then the pause before the next aim
local FREEZE, SHAKE, SHAKE_PX, AFTER, BONUS_T = 0.09, 0.28, 7, 0.7, 1.3
local JACKPOT_T = 5  -- how long the jackpot holds the next step
local DOTS_PAST = 1.5 -- the dots: up to the top and half as far again, fading after the top
-- only in the simulator (imposta prova_fornace_centra 1): every throw goes into the
-- nearest empty mould, to see the hits (tools/simula/scenari/fornace.txt)
local SURE = sys.get_config_int("megablast.simula", 0) == 1 and sys.get_config_int("megablast.prova_fornace_centra", 0) == 1

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function clamp(x) return math.max(0, math.min(1, x)) end
local function lerp(a, b, k) return a + (b - a) * k end
local function eio(k) return k < 0.5 and 4 * k * k * k or 1 - (-2 * k + 2) ^ 3 / 2 end
local function eo(k) return 1 - (1 - k) ^ 3 end

-- the hour of the game day (0 is wallet.DAY_HOUR in the morning) and the seconds into it
local function day_clock()
	local t = os.date("*t", os.time() - wallet.DAY_HOUR * 3600)
	return t.hour, t.hour * 3600 + t.min * 60 + t.sec
end

-- the wall the player sees now: the one of his throws if some are left, else the
-- one he is on today (the next of the day when his is full)
local function wall_key(p)
	forge.init(p)
	local f = p.fornace
	if f.tiri > 0 and f.muro ~= "" then return f.muro end
	return forge.current(p, profile.today(p))
end

-- "3:12:05" to the new walls (the game day's turn, at 5 in the morning)
local function until_next()
	local _, now = day_clock()
	local left = math.max(0, 24 * 3600 - now)
	return string.format("%d:%02d:%02d", math.floor(left / 3600), math.floor(left / 60) % 60, left % 60)
end

-- Nodes ------------------------------------------------------------------------------

local function box(parent, x, y, w, h)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_parent(n, parent)
	return n
end

local function empty(parent, x, y)
	local n = gui.new_box_node(vec(x or 0, y or 0), vec(0, 0))
	gui.set_visible(n, false)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- a piece of the Forge's atlas w wide (world units), at (x, y) by its pivot
local function piece(parent, name, x, y, w, pivot)
	local m = PIECES[name]
	local n = box(parent, x, y, w, w * m.h / m.w)
	gui.set_texture(n, "fornace")
	gui.play_flipbook(n, name)
	if pivot then gui.set_pivot(n, pivot) end
	return n
end

-- a painting of the Forge (its texture loaded once while the tab is open)
local function texture(a, name, file)
	a.forge_tex = a.forge_tex or {}
	local id = "fornace_" .. name
	if a.forge_tex[id] then return id, a.forge_tex[id] end
	local data = sys.load_resource("/paintings/fornace/" .. file)
	-- the gui draws premultiplied colors: so must the image be
	local img = data and image.load(data, { premultiply_alpha = true })
	if img and gui.new_texture(id, img.width, img.height, img.type, img.buffer) then
		a.forge_tex[id] = { w = img.width, h = img.height }
		return id, a.forge_tex[id]
	end
end

local function painting(a, parent, name, file, x, y, w)
	local id, dim = texture(a, name, file)
	if not id then return empty(parent, x, y) end
	local n = box(parent, x, y, w, w * dim.h / dim.w)
	gui.set_texture(n, id)
	gui.set_pivot(n, gui.PIVOT_SW)
	return n
end

-- the usurer of mould m: his drawing, its world units per pixel, where his head's top
-- and his sand's bottom are
local function figure(m, full)
	local name = (full and "borsa_chiusa_" or "borsa_") .. (m.set and PLATE[m.set] or "ferro")
	local pc = PIECES[name]
	local k = m.w * RIM_W / pc.mw
	return name, pc, k, m.y + pc.my * k, m.y - (pc.h - pc.my) * k
end

-- Views and cameras -------------------------------------------------------------------

-- the frame on the board, in game coordinates (y up)
local function frame_view()
	return { cx = FRAME.x + FRAME.w / 2, cy = 720 - (FRAME.y + FRAME.h / 2), w = FRAME.w - 2 * INSET, h = FRAME.h - 2 * INSET }
end

local function full_view()
	return { cx = (screen.x0 + screen.x1) / 2, cy = (screen.y0 + screen.y1) / 2, w = screen.width(), h = screen.height() }
end

-- the whole wall in the frame: the width, the floor's slab at the bottom
local function frame_cam(v)
	local s = v.w / WALL_W
	return { x = WALL_X, y = -215 + v.h / (2 * s), s = s }
end

-- the whole wall on the screen, the floor 120 pixels over the bottom
local function full_cam(v)
	local s = math.min(v.w / 1900, v.h / 860)
	return { x = WALL_X, y = forge.FLOOR - 120 / s + v.h / (2 * s), s = s }
end

-- a painting layer: where the parallax puts it, at most at its own pixels on the
-- screen (or at the zoom of the whole wall, most), and then moved to cover the view
local function place_layer(fx, node, L, most)
	local v, c = fx.view, fx.cam
	local dim = fx.layer_px and fx.layer_px[node]
	if not dim then return end
	local s = math.min(c.s, math.max(dim.w / L.w, most))
	local z = s / c.s
	local w, h = L.w * s, L.w * dim.h / dim.w * s
	-- on the screen, around the camera's middle
	local left = v.cx + (L.x + (c.x - WALL_X) * L.k - c.x) * s
	local bottom = v.cy + (L.y - c.y) * s
	if z < 1 then
		local l0, r0, b0 = v.cx - v.w / 2, v.cx + v.w / 2, v.cy - v.h / 2
		if left > l0 then left = l0 end
		if left + w < r0 then left = r0 - w end
		if bottom > b0 then bottom = b0 end
		if bottom + h < b0 + v.h * 0.6 then bottom = b0 + v.h * 0.6 - h end
	end
	-- (on a mirrored wall the layer's origin is its right edge on the screen)
	local x = (fx.mir or 1) < 0 and c.x - (left + w - v.cx) / c.s or c.x + (left - v.cx) / c.s
	gui.set_position(node, vec(x, c.y + (bottom - v.cy) / c.s))
	gui.set_scale(node, vmath.vector3(z, z, 1))
end

local function apply(fx)
	local v, c = fx.view, fx.cam
	gui.set_position(fx.clip, vec(v.cx, v.cy))
	gui.set_size(fx.clip, vec(v.w, v.h))
	local k = math.max(v.w / fx.sky_w, v.h / fx.sky_h)
	gui.set_size(fx.sky, vec(fx.sky_w * k, fx.sky_h * k))
	-- a mirrored wall (forge.mirrored) is the same world seen from behind
	local mir = fx.mir or 1
	gui.set_position(fx.world, vec(-mir * c.x * c.s + (fx.sx or 0), -c.y * c.s + (fx.sy or 0)))
	gui.set_scale(fx.world, vmath.vector3(mir * c.s, c.s, 1))
	local most = full_cam(v).s
	place_layer(fx, fx.far, FAR, most)
	place_layer(fx, fx.mid, MID, most)
	local ts = vmath.vector3(mir / c.s, 1 / c.s, 1)
	for _, t in pairs(fx.tags) do gui.set_scale(t, ts) end
end

-- a world point on the screen (game coordinates), and back
local function to_screen(fx, x, y)
	local v, c = fx.view, fx.cam
	return v.cx + (fx.mir or 1) * (x - c.x) * c.s + (fx.sx or 0), v.cy + (y - c.y) * c.s + (fx.sy or 0)
end

local function to_world(fx, x, y)
	local v, c = fx.view, fx.cam
	return c.x + (fx.mir or 1) * (x - v.cx - (fx.sx or 0)) / c.s, c.y + (y - v.cy - (fx.sy or 0)) / c.s
end

-- a move of the camera (and of the frame) over d seconds
local function travel(fx, view, cam, d)
	fx.tr = { t = 0, d = d, v0 = fx.view, c0 = fx.cam, v1 = view, c1 = cam }
end

local function travel_step(fx, dt)
	local tr = fx.tr
	if not tr then return true end
	tr.t = tr.t + dt
	local k = eio(clamp(tr.t / tr.d))
	local v0, v1, c0, c1 = tr.v0, tr.v1, tr.c0, tr.c1
	fx.view = { cx = lerp(v0.cx, v1.cx, k), cy = lerp(v0.cy, v1.cy, k), w = lerp(v0.w, v1.w, k), h = lerp(v0.h, v1.h, k) }
	-- the zoom eases in its logarithm: the same feel going in and out
	fx.cam = { x = lerp(c0.x, c1.x, k), y = lerp(c0.y, c1.y, k), s = math.exp(lerp(math.log(c0.s), math.log(c1.s), k)) }
	if tr.t >= tr.d then fx.tr = nil; return true end
	return false
end

-- The world ---------------------------------------------------------------------------

-- a family's colour
local function color_of(set)
	local c = equip.BY_ID[set].color
	return vmath.vector4(tonumber(c:sub(1, 2), 16) / 255, tonumber(c:sub(3, 4), 16) / 255, tonumber(c:sub(5, 6), 16) / 255, 1)
end

-- a prize tag: the coin or the family's fragment and the number, over the usurer
local function tag(fx, m)
	local _, _, _, top = figure(m)
	local t = empty(fx.tags_root, m.x, top + 2)
	local g = { node = t, ox = 0, oy = 0 }
	local icon = m.scaglie and "scaglia" or "frammento_" .. m.set
	local txt = m.scaglie and tostring(m.scaglie) or "x" .. m.n
	local color = m.lucky and KC.HOT or KC.SAND
	local shadow = kit.text(g, txt, 0, -6, TAG, KC.INK, "start")
	local n = kit.text(g, txt, 0, -8, TAG, color, "start")
	local ih = TAG * 1.25
	local w = ih + 3 + kit.width(n)
	local x0 = -w / 2
	kit.piece(g, icon, x0 + ih / 2, -8 - TAG * 0.36, ih)
	gui.set_position(n, gui.get_position(n) + vec(x0 + ih + 3, 0))
	gui.set_position(shadow, gui.get_position(shadow) + vec(x0 + ih + 5, 0))
	if m.lucky then
		kit.text(g, T.lucky, 1.5, -8 - TAG * 1.5 + 2, 16, KC.INK, "middle", 1)
		kit.text(g, T.lucky, 0, -8 - TAG * 1.5, 16, KC.HOT, "middle", 1)
	end
	fx.tags[m.slot] = t
end

-- the rope of a purse: from the drawing's top (where its own rope ends) up to the beam,
-- behind it (drawn only: the drop goes through it)
local function rope(fx, m, full)
	if fx.ropes[m.slot] then gui.delete_node(fx.ropes[m.slot]) end
	local _, pc, k, top = figure(m, full)
	local r = empty(fx.ropes_root)
	local x = m.x + (pc.rx - pc.mx) * k
	-- whole pieces down from the beam, the last one up from the drawing's top (over the
	-- one before it: never a stretched piece)
	local h = ROPE_W * PIECES.corda.h / PIECES.corda.w
	local y = BEAM.y
	while y - h > top do
		piece(r, "corda", x, y, ROPE_W, gui.PIVOT_N)
		y = y - h + 1
	end
	piece(r, "corda", x, top - 2, ROPE_W, gui.PIVOT_S)
	fx.ropes[m.slot] = r
end

-- a taken purse (Sergio, 26 Nov: «un coperchio coerente quando sono stati presi»):
-- closed, tied and sealed in wax, the prize on the seal (where the rules' lid is:
-- forge.LID_R, LID_Y, around the mouth)
local SEAL_ICON = 0.62
local function seal(fx, m)
	if fx.seals[m.slot] then gui.delete_node(fx.seals[m.slot]) end
	local name, pc, k = figure(m, true)
	local n = fx.figs[m.slot]
	gui.play_flipbook(n, name)
	gui.set_size(n, vec(pc.w * k, pc.h * k))
	gui.set_position(n, vec((pc.w / 2 - pc.mx) * k, (pc.my - pc.h / 2) * k))
	rope(fx, m, true)
	local s = empty(fx.moulds[m.slot], (pc.sx - pc.mx) * k, (pc.my - pc.sy) * k)
	local g = { node = s, ox = 0, oy = 0 }
	kit.piece(g, m.scaglie and "scaglia" or "frammento_" .. m.set, 0, 0, pc.sw * k * SEAL_ICON)
	fx.seals[m.slot] = s
	return s
end

-- the flame from the mouth when the drop goes in (art WB-094): four frames, three
-- moulds tall, then it falls back and fades
-- The effects of a hit and of the jackpot, as on the page Sergio chose
-- (https://claude.ai/artifact/LcTuEFuH5XKmmmeDPgtGN2, «la fiammata» and «il jackpot del
-- muro pieno»; Sergio, 24 Nov: «falla in quel modo»)

local GOLD, MAGENTA, VIOLET, EMBER = vmath.vector4(1, 0.82, 0.48, 1), vmath.vector4(1, 0.24, 0.65, 1),
	vmath.vector4(0.76, 0.29, 1, 1), vmath.vector4(1, 0.48, 0.1, 1)

-- sparks: round embers flying up and falling (world units, moved in M.update)
local function sparks(fx, parent, x, y, n, spread, speed, size, grav, colors)
	fx.parts = fx.parts or {}
	for i = 1, n do
		local an = math.pi / 2 + (math.random() - 0.5) * spread
		local v = speed * (0.5 + math.random())
		local d = size * (0.6 + math.random() * 0.8)
		local s = ui.disc(x, y, d, colors[i % #colors + 1], parent)
		fx.parts[#fx.parts + 1] = { node = s, x = x, y = y, vx = math.cos(an) * v, vy = math.sin(an) * v,
			g = grav, t = 0, life = 0.6 + math.random() * 0.6 }
	end
end

local function parts_step(fx, dt)
	local ps = fx.parts
	if not ps then return end
	for i = #ps, 1, -1 do
		local q = ps[i]
		q.t = q.t + dt
		if q.t >= q.life then
			gui.delete_node(q.node)
			table.remove(ps, i)
		else
			q.vy = q.vy - q.g * dt
			q.x, q.y = q.x + q.vx * dt, q.y + q.vy * dt
			gui.set_position(q.node, vec(q.x, q.y))
			if q.spin then gui.set_rotation(q.node, vmath.vector3(0, 0, q.t * q.spin)) end
			if not q.keep then
				local c = gui.get_color(q.node)
				c.w = 1 - q.t / q.life
				gui.set_color(q.node, c)
			end
		end
	end
end

-- a golden shock ring on the floor of the mould, growing and fading
local function shock(fx, x, y, w)
	local r = ui.disc(x, y, w, GOLD, fx.splash)
	ui.ring(r, w, w * 0.06, w * 0.42)
	gui.set_scale(r, vmath.vector3(0.3, 0.3, 1))
	gui.animate(r, "scale", vmath.vector3(4.5, 4.5, 1), gui.EASING_OUTCUBIC, 0.5)
	gui.animate(r, "color.w", 0, gui.EASING_LINEAR, 0.5, 0, function() gui.delete_node(r) end)
end

-- the usurer glowing hot (his own drawing, added in ember on top) for d seconds
local function glow(fx, m, d, a)
	local n = fx.figs[m.slot]
	if not n then return end
	local h = gui.new_box_node(vec(0, 0), gui.get_size(n))
	gui.set_texture(h, "fornace")
	gui.play_flipbook(h, gui.get_flipbook(n))
	gui.set_blend_mode(h, gui.BLEND_ADD)
	gui.set_parent(h, n)
	local c = vmath.vector4(EMBER.x, EMBER.y, EMBER.z, a or 0.9)
	gui.set_color(h, c)
	if d then gui.animate(h, "color.w", 0, gui.EASING_INQUAD, d, 0, function() gui.delete_node(h) end) end
	return h
end

-- the usurer trembling around his purse's mouth, less and less
local function tremble(fx, m, d)
	fx.trembles = fx.trembles or {}
	fx.trembles[m.slot] = { t = 0, d = d }
end

local function trembles_step(fx, dt)
	if not fx.trembles then return end
	for slot, q in pairs(fx.trembles) do
		q.t = q.t + dt
		local n = fx.moulds[slot]
		local k = 1 - q.t / q.d
		if k <= 0 or not n then
			if n then gui.set_rotation(n, vmath.vector3(0, 0, 0)) end
			fx.trembles[slot] = nil
		else
			gui.set_rotation(n, vmath.vector3(0, 0, math.sin(q.t * 47) * 5 * k))
		end
	end
end

-- something to do in d seconds (stepped in M.update, so it waits through the freeze)
local function later(fx, d, fn)
	fx.timers = fx.timers or {}
	fx.timers[#fx.timers + 1] = { t = d, fn = fn }
end

local function timers_step(fx, dt)
	local ts = fx.timers
	if not ts then return end
	local due = {}
	for i = #ts, 1, -1 do
		ts[i].t = ts[i].t - dt
		if ts[i].t <= 0 then
			due[#due + 1] = ts[i].fn
			table.remove(ts, i)
		end
	end
	for i = #due, 1, -1 do due[i]() end
end

-- the whole screen dimmed or lit for a moment (a0 to nothing in d seconds)
local function veil(fx, color, a0, d)
	local n = box(fx.hud, 640, 360, screen.x1 - screen.x0 + 40, screen.y1 - screen.y0 + 40)
	gui.set_position(n, vec((screen.x0 + screen.x1) / 2, (screen.y0 + screen.y1) / 2))
	gui.set_color(n, vmath.vector4(color.x, color.y, color.z, a0))
	gui.animate(n, "color.w", 0, gui.EASING_OUTQUAD, d, 0, function() gui.delete_node(n) end)
	return n
end
local WARM = vmath.vector4(1, 0.92, 0.78, 1)

-- the column of Obsidian fire from the mouth (WB-094's four frames): it shoots up,
-- burns at full height flickering, breaks up and falls back
local FLAME_UP, FLAME_HOLD, FLAME_DOWN = 0.18, 0.62, 0.35
local function flame(fx, m)
	local w = m.w * 3 * PIECES.fiammata_1.w / PIECES.fiammata_1.h
	local n = piece(fx.splash, "fiammata_1", m.x, m.y - m.w * 0.04, w, gui.PIVOT_S)
	gui.set_scale(n, vmath.vector3(0.7, 0.05, 1))
	gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTCUBIC, FLAME_UP)
	-- the frames: the burst, then the full column and its top breaking (one and the
	-- other, a flicker), then falling back (by the timers: animations on one property
	-- would cancel each other)
	local t, k = 0.06, 0
	later(fx, t, function() gui.play_flipbook(n, "fiammata_2") end)
	while t < FLAME_UP + FLAME_HOLD do
		t, k = t + 0.09, k + 1
		local f = k % 2 == 0 and "fiammata_2" or "fiammata_3"
		later(fx, t, function() gui.play_flipbook(n, f) end)
	end
	later(fx, t, function()
		gui.play_flipbook(n, "fiammata_4")
		gui.animate(n, "scale", vmath.vector3(1, 0.5, 1), gui.EASING_INQUAD, FLAME_DOWN)
		gui.animate(n, "color.w", 0, gui.EASING_INQUAD, FLAME_DOWN, 0, function() gui.delete_node(n) end)
	end)
	-- the embers, the ring, the mould hot and trembling
	sparks(fx, fx.splash, m.x, m.y, 60, 0.9, 300, m.w * 0.09, 420, { GOLD, MAGENTA, VIOLET, EMBER })
	shock(fx, m.x, m.y - m.w * 0.15, m.w * 0.9)
	glow(fx, m, 1.6, 0.9)
	tremble(fx, m, 0.75)
end

-- a purse: the drawing with its mouth on the mould's (m.x, m.y), under a node on the
-- mouth (it trembles and pops around it), its rope up to the beam
local function draw_mould(fx, m, full)
	local name, pc, k = figure(m)
	local root = empty(fx.wall_root, m.x, m.y)
	local n = piece(root, name, (pc.w / 2 - pc.mx) * k, (pc.my - pc.h / 2) * k, pc.w * k)
	fx.moulds[m.slot], fx.figs[m.slot] = root, n
	if full then seal(fx, m) else rope(fx, m); tag(fx, m) end
end

-- fills a mould on the wall (a hit): the purse jumps, the flame, then once the column
-- has burned it closes with a squash, tied and sealed, the prize on the seal; the tag goes
local LID_AT = 0.85
local function fill_mould(fx, m)
	local n = fx.moulds[m.slot]
	if not n then return end
	gui.set_scale(n, vmath.vector3(1.12, 0.88, 1))
	gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.35)
	flame(fx, m)
	later(fx, LID_AT, function()
		if not fx.moulds[m.slot] then return end
		local s = seal(fx, m)
		gui.set_scale(n, vmath.vector3(0.8, 1.25, 1))
		gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTELASTIC, 0.6)
		gui.set_scale(s, vmath.vector3(0.2, 0.2, 1))
		gui.animate(s, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.35, 0.1)
		sound.play("#martello")
	end)
	if fx.tags[m.slot] then
		gui.delete_node(fx.tags[m.slot])
		fx.tags[m.slot] = nil
	end
end

-- a group of nodes fading away in d seconds (its children take its alpha), then gone
local function fade(n, d, delay)
	for _, q in pairs(gui.get_tree(n)) do gui.set_inherit_alpha(q, true) end
	gui.animate(n, "color.w", 0, gui.EASING_INQUAD, d, delay or 0, function() gui.delete_node(n) end)
end

-- The usurer of the bench says something (Sergio, 26 Nov: «uno di questi predoni accanto
-- al tavolo che ogni tanto ti parla»): plain text over his head, as the bots' lines in
-- battle, for a moment, with his face for it (usuraio_parla, or usuraio_paga at INCASSA)
local SAY_T = 2.2
local function say(fx, lines, face)
	if not lines or not fx.banker or fx.saying then return end
	local line = lines[math.random(#lines)]
	local t = empty(fx.tags_root, BANKER.x, BANKER.y + BANKER.h + 8)
	local g = { node = t, ox = 0, oy = 0 }
	kit.text(g, line, 1.5, -12 + 1.5, 17, KC.INK, "middle", 0.5)
	kit.text(g, line, 0, -12, 17, KC.SAND, "middle", 0.5)
	fx.saying, fx.tags.say = t, t
	gui.set_scale(t, vmath.vector3((fx.mir or 1) / fx.cam.s, 1 / fx.cam.s, 1))
	local pc = PIECES[face or "usuraio_parla"]
	gui.play_flipbook(fx.banker, face or "usuraio_parla")
	gui.set_size(fx.banker, vec(BANKER.h * pc.w / pc.h, BANKER.h))
	later(fx, SAY_T, function()
		fx.saying, fx.tags.say = nil, nil
		fade(t, 0.3)
		if fx.banker then
			local q = PIECES.usuraio_zitto
			gui.play_flipbook(fx.banker, "usuraio_zitto")
			gui.set_size(fx.banker, vec(BANKER.h * q.w / q.h, BANKER.h))
		end
	end)
end

-- The bench ---------------------------------------------------------------------------

-- a chip: the coin or the family's fragment and a number (always this big on the
-- screen, under fx.tags_root), its middle at (x, y)
local function chip(fx, key, x, y, icon, txt, color)
	local t = empty(fx.tags_root, x, y)
	local g = { node = t, ox = 0, oy = 0 }
	kit.text(g, txt, 0, 2, TAG, KC.INK, "start")
	local n = kit.text(g, txt, 0, 0, TAG, color or KC.SAND, "start")
	local ih = TAG * 1.25
	local w = ih + 3 + kit.width(n)
	local x0 = -w / 2
	kit.piece(g, icon, x0 + ih / 2, -TAG * 0.36, ih)
	gui.set_position(n, gui.get_position(n) + vec(x0 + ih + 3, 0))
	fx.tags[key] = t
	gui.set_scale(t, vmath.vector3((fx.mir or 1) / fx.cam.s, 1 / fx.cam.s, 1))
	return t
end

local BREAK_DEG = 13
local HEAPS = { monete = { 90, 140, 200 }, cristalli = { 70, 105, 145 } }

-- the planks' drop at x under the loot (world units, the sag of fx.sag at the middle)
local function bench_sag(fx, x)
	local L = BENCH.seg * BENCH.n
	return -fx.sag * math.sin(math.pi * clamp((x - BENCH.x) / L))
end

-- The money-changers' bench (Sergio, 26 Nov: «si accumulasse tutto sul tavolo ... ti
-- arrivino nel portafoglio solo alla fine»): the loot of this pour in heaps, the jar
-- with its glass beads; the wallet gets it all at INCASSA (pay). got: the pour's loot
-- (nil: an empty bench); pop: the heap that has just grown ("scaglie" or a family), it jumps
local function bench(fx, got, pop)
	if fx.bench then gui.delete_node(fx.bench) end
	for _, k in ipairs(fx.bench_tags or {}) do
		if fx.tags[k] then gui.delete_node(fx.tags[k]); fx.tags[k] = nil end
	end
	fx.bench_tags = {}
	fx.bench = empty(fx.band)
	got = got or {}
	local sc, fr = (got.sacchi or 0) + (got.jackpot or 0), got.fr or {}
	-- (it sags with every purse taken in the pour, all the way at four)
	fx.sag = BENCH.sag * math.min(1, (got.hits or 0) / (forge.THROWS + forge.BONUS))
	local L = BENCH.seg * BENCH.n
	local xl, xr = BENCH.x + TRESTLE_IN, BENCH.x + L - TRESTLE_IN
	local t = BENCH.seg * PIECES.asse.h / PIECES.asse.w
	for _, x in ipairs({ xl, xr }) do piece(fx.bench, "cavalletto", x, BENCH.y - t * 0.3, TRESTLE_W, gui.PIVOT_N) end
	-- two halves, each turning on its trestle's top (the break)
	local halves = { empty(fx.bench, xl, BENCH.y), empty(fx.bench, xr, BENCH.y) }
	fx.halves = halves
	local function on(x)
		local i = x < BENCH.x + L / 2 and 1 or 2
		return halves[i], x - (i == 1 and xl or xr), bench_sag(fx, x)
	end
	fx.planks = {}
	for i = 0, BENCH.n - 1 do
		local name = i == 0 and "asse_sx" or i == BENCH.n - 1 and "asse_dx" or "asse"
		local xc = BENCH.x + BENCH.seg * (i + 0.5)
		local h, x, y = on(xc)
		local q = piece(h, name, x, y, BENCH.seg + 4)
		local slope = -fx.sag * math.pi / L * math.cos(math.pi * (xc - BENCH.x) / L)
		gui.set_rotation(q, vmath.vector3(0, 0, math.deg(math.atan(slope))))
		fx.planks[i + 1] = q
	end
	-- the jar at the end, the beads of the drops that missed in this pour in it
	local jh, jx, jy = on(JAR.x)
	jy = jy + t * 0.5 - 3
	fx.jar = piece(jh, "vaso", jx, jy, JAR.w, gui.PIVOT_S)
	local beads = got.vetri or 0
	fx.beads = {}
	for i = 1, math.min(beads, 16) do
		local row, col = math.floor((i - 1) / 4), (i - 1) % 4
		fx.beads[i] = piece(jh, "perla", jx - 15 + col * 10 + (row % 2) * 4, jy + 10 + row * 8, 10)
	end
	fx.jar_at = { JAR.x, BENCH.y + t * 0.5 + JAR.w * PIECES.vaso.h / PIECES.vaso.w }
	if beads > 0 then
		local k = "jar"
		chip(fx, k, JAR.x, fx.jar_at[2] + 14, "scaglia", coins.format(beads * forge.MISS))
		fx.bench_tags[#fx.bench_tags + 1] = k
	end
	-- the heaps: the Scaglie, then the fragments family by family, bigger as they grow
	fx.heaps, fx.heap_of = {}, {}
	local function heap(what, x, size, color, icon, txt, id)
		local name = what .. "_" .. size
		local h, hx, y = on(x)
		local nd = piece(h, name, hx, y + t * 0.5 - 3, HEAPS[what][size], gui.PIVOT_S)
		if color then gui.set_color(nd, color) end
		fx.heaps[#fx.heaps + 1] = nd
		fx.heap_of[id] = nd
		if pop == id then
			gui.set_scale(nd, vmath.vector3(0.2, 0.2, 1))
			gui.animate(nd, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.45)
		end
		local k = "heap_" .. id
		chip(fx, k, x, BENCH.y - t * 0.5 - 16, icon, txt, color)
		fx.bench_tags[#fx.bench_tags + 1] = k
	end
	if sc > 0 then
		heap("monete", HEAPS_X, sc <= 60 and 1 or sc <= 200 and 2 or 3, nil, "scaglia", coins.format(sc), "scaglie")
	end
	for i, set in ipairs(equip.SETS) do
		local c = fr[set.id]
		if c then
			local fc = color_of(set.id)
			-- (the white crystals in the family's colour, lightened)
			local tint = vmath.vector4((1 + fc.x) / 2, (1 + fc.y) / 2, (1 + fc.z) / 2, 1)
			heap("cristalli", HEAPS_X + 240 + (i - 1) * HEAP_GAP, c <= 1 and 1 or c <= 3 and 2 or 3, tint,
				"frammento_" .. set.id, "x" .. c, set.id)
		end
	end
end

-- The bancarotta (the jackpot): the bench cracks in the middle, the two halves fall
-- on their trestles, the heaps slide off and lie at its feet until INCASSA
local function bankrupt(fx)
	if not fx.planks then return end
	local L = BENCH.seg * BENCH.n
	local i = BENCH.n / 2
	for j, name in ipairs({ "asse_rotta_sx", "asse_rotta_dx" }) do
		local q = fx.planks[i - 1 + j]
		gui.play_flipbook(q, name)
		local w = BENCH.seg + 4
		gui.set_size(q, vec(w, w * PIECES[name].h / PIECES[name].w))
	end
	local c = piece(fx.band, "crepa", BENCH.x + L / 2, BENCH.y + 10, 60)
	gui.set_scale(c, vmath.vector3(0.2, 0.2, 1))
	gui.animate(c, "scale", vmath.vector3(1.4, 1.4, 1), gui.EASING_OUTBACK, 0.25)
	gui.animate(c, "color.w", 0, gui.EASING_INQUAD, 0.4, 0.5, function() gui.delete_node(c) end)
	sparks(fx, fx.band, BENCH.x + L / 2, BENCH.y, 30, 1.6, 260, 6, 500, { GOLD, EMBER })
	gui.animate(fx.halves[1], "euler.z", -BREAK_DEG, gui.EASING_OUTBOUNCE, 0.6)
	gui.animate(fx.halves[2], "euler.z", BREAK_DEG, gui.EASING_OUTBOUNCE, 0.6)
	for k, h in ipairs(fx.heaps or {}) do
		local p = gui.get_position(h)
		gui.animate(h, "position.y", p.y - 50, gui.EASING_OUTBOUNCE, 0.7, 0.15 + k * 0.04)
		gui.animate(h, "euler.z", (k % 2 == 0 and 1 or -1) * 8, gui.EASING_OUTQUAD, 0.5, 0.15 + k * 0.04)
	end
	for _, k in ipairs(fx.bench_tags or {}) do
		local t = fx.tags[k]
		if t then fx.tags[k] = nil; fade(t, 0.3, 0.2) end
	end
	fx.bench_tags = {}
end

-- the rain of fire (Inf. XIV: «piovean di foco dilatate falde»): flakes falling slowly
-- over the whole wall behind the usurers, each again from the top when it reaches the sand
local FLAKES = 18
local function flakes(fx)
	for i = 1, FLAKES do
		local n = piece(fx.flakes, "fiocco_" .. (i % 3 + 1), 0, 0, 6 + (i % 3) * 4)
		gui.set_color(n, vmath.vector4(1, 1, 1, 0.85))
		local speed = 55 + math.random() * 45
		local function fall(y0)
			local x = -200 + math.random() * 1900
			gui.set_position(n, vec(x, y0))
			gui.set_rotation(n, vmath.vector3(0, 0, -8))
			local d = (y0 - FLOOR_TOP) / speed
			gui.animate(n, "position.x", x - d * 12, gui.EASING_LINEAR, d)
			gui.animate(n, "position.y", FLOOR_TOP, gui.EASING_LINEAR, d, 0, function() fall(1000) end)
		end
		fall(FLOOR_TOP + math.random() * 1100)
	end
end

local function make_world(a)
	local p = a.prof
	local fx = a.fx or {}
	a.fx = fx
	fx.phase = fx.phase or "vetrina"
	fx.tags, fx.moulds, fx.seals, fx.figs, fx.ropes, fx.saying = {}, {}, {}, {}, {}, nil
	fx.parts, fx.trembles, fx.timers, fx.bench, fx.bench_tags = nil, nil, nil, nil, nil
	fx.top = empty(nil, 0, 0)
	-- one of the screen's top nodes: the home's door drags it with the page (ui/door_pass.lua;
	-- left out, the wall stayed on the home for a moment: Sergio's video, 25 Nov)
	if kit.tracking then kit.tracking[#kit.tracking + 1] = fx.top end
	fx.clip = box(fx.top, 0, 0, 10, 10)
	gui.set_color(fx.clip, KC.SOOT)
	gui.set_clipping_mode(fx.clip, gui.CLIPPING_MODE_STENCIL)
	local sky, dim = texture(a, "cielo", "cielo.jpg")
	fx.sky = box(fx.clip, 0, 0, 10, 10)
	fx.sky_w, fx.sky_h = dim and dim.w or 16, dim and dim.h or 9
	if sky then gui.set_texture(fx.sky, sky) else gui.set_color(fx.sky, KC.SOOT) end
	fx.world = empty(fx.clip)
	fx.far = painting(a, fx.world, "lontano", "lontano.png", FAR.x, FAR.y, FAR.w)
	fx.mid = painting(a, fx.world, "medio", "medio.png", MID.x, MID.y, MID.w)
	fx.layer_px = { [fx.far] = a.forge_tex.fornace_lontano, [fx.mid] = a.forge_tex.fornace_medio }
	fx.flakes = empty(fx.world)
	flakes(fx)
	-- the band's dark under the embankment
	local ah = ARGINE_W * PIECES.argine.h / PIECES.argine.w
	local under = box(fx.world, WALL_X, ARGINE_TOP - ah + 2 - 1500, 6000, 3000)
	gui.set_color(under, BELOW)
	-- the rock wall on the right (forge.BACK_X): every other piece upside down, so the
	-- outline goes on where they meet
	local rh = ROCK_W * PIECES.parete.h / PIECES.parete.w
	local y, k = FLOOR_TOP - 40, 0
	while y < 1500 do
		local n = piece(fx.world, "parete", forge.BACK_X - 4 + ROCK_W / 2, y + rh / 2, ROCK_W)
		if k % 2 == 1 then gui.set_scale(n, vmath.vector3(1, -1, 1)) end
		y, k = y + rh - 1, k + 1
	end
	-- the purses: their ropes behind them all, the beam over the ropes
	fx.ropes_root = empty(fx.world)
	fx.wall_root = empty(fx.world)
	fx.tags_root = empty(nil)
	local key = wall_key(p)
	local f = p.fornace
	local full = key == f.muro and f.pieni or {}
	fx.key = key
	fx.mir = forge.mirrored(key) and -1 or 1
	-- (in the simulator: imposta prova_fornace_specchio si | no)
	local force = sys.get_config_int("megablast.simula", 0) == 1 and sys.get_config_string("megablast.prova_fornace_specchio", "")
	if force == "si" then fx.mir = -1 elseif force == "no" then fx.mir = 1 end
	fx.cam = fx.cam or { x = WALL_X, y = 0, s = 1 }
	local order = {}
	for i, m in ipairs(forge.wall(p, key)) do order[i] = m end
	table.sort(order, function(m, q) if m.y ~= q.y then return m.y > q.y end return m.slot < q.slot end)
	for _, m in ipairs(order) do draw_mould(fx, m, full[m.slot]) end
	-- the beam of the accounts: its rock ends on the left and in the rock wall, the
	-- middle repeated; a peg every PEG_STEP and its knotted cord under it
	local bk = BEAM.h / PIECES.trave.h
	local lw, rw, mw = PIECES.trave_sx.w * bk, PIECES.trave_dx.w * bk, PIECES.trave.w * bk
	local xr = forge.BACK_X + ROCK_W * 0.4
	local bx = BEAM.x0 + lw - 4
	for x = math.floor((xr - rw - bx) / PEG_STEP) * PEG_STEP + bx, BEAM.x0 + 60, -PEG_STEP do
		local i = math.floor((x - BEAM.x0) / PEG_STEP + 0.5)
		local cord = CORDS[i % #CORDS + 1]
		piece(fx.world, cord, x, BEAM.y - BEAM.h * 0.35, CORD_W, gui.PIVOT_N)
		piece(fx.world, "piolo", x, BEAM.y - BEAM.h * 0.3, CORD_W * 0.8)
	end
	while bx < xr - rw + 4 do
		piece(fx.world, "trave", bx, BEAM.y, mw + 2, gui.PIVOT_W)
		bx = bx + mw - 2
	end
	piece(fx.world, "trave_sx", BEAM.x0, BEAM.y, lw, gui.PIVOT_W)
	piece(fx.world, "trave_dx", xr, BEAM.y, rw, gui.PIVOT_E)
	-- the embankment in front, the apprentice's ledge on its sand
	for x = -900, 2600, ARGINE_W - 2 do piece(fx.world, "argine", x, ARGINE_TOP, ARGINE_W, gui.PIVOT_NW) end
	piece(fx.world, "sporgenza", LEDGE.x, LEDGE.y, LEDGE.w, gui.PIVOT_NW)
	fx.band = empty(fx.world)
	local bp = PIECES.usuraio_zitto
	fx.banker = piece(fx.band, "usuraio_zitto", BANKER.x, BANKER.y, BANKER.h * bp.w / bp.h, gui.PIVOT_S)
	-- the apprentice on the ledge, the ladle in his hand
	local dev = scoria.new(a.colore or ui.C.SQUADRA[1], scoria.player)
	gui.set_parent(dev.root, fx.world)
	scoria.set_weapon(dev, "mestolo")
	scoria.set_enabled(dev, true)
	fx.dev = dev
	-- a point in the ladle's bowl: it follows the ladle (the molten drop sits there)
	fx.bowl_pt = gui.new_box_node(vec(BOWL[1], BOWL[2]), vec(1, 1))
	gui.set_color(fx.bowl_pt, vmath.vector4(0, 0, 0, 0))
	gui.set_parent(fx.bowl_pt, scoria.weapon_joint(dev, "mestolo"))
	fx.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, turno = true }
	scoria.update(dev, 0, fx.st)
	-- the molten Ossidiana in the ladle (after the pour), the drop (a flake of fire, its
	-- head on the node, the tail behind), the aim
	fx.molten = piece(fx.world, "goccia", 0, 0, 9)
	gui.set_enabled(fx.molten, false)
	fx.drop = empty(fx.world)
	piece(fx.drop, "falda", DROP_W * 0.5, 0, DROP_W * 2)
	gui.set_enabled(fx.drop, false)
	fx.aim = aim.new()
	fx.pad_st, fx.pad, fx.clock = sticks.new(), false, 0
	fx.thumb_st = sticks.new()
	for _, n in ipairs(fx.aim.nodi) do gui.set_parent(n, fx.world) end
	gui.set_parent(fx.aim.sign, fx.world)
	fx.splash = empty(fx.world)
	gui.set_parent(fx.tags_root, fx.world)
	fx.view = frame_view()
	fx.cam = frame_cam(fx.view)
	bench(fx, nil)
	apply(fx)
	return fx
end

local function drop_world(a)
	local fx = a.fx
	if not fx then return end
	if fx.purse then coins.delete(fx.purse) end
	if fx.top then gui.delete_node(fx.top) end
	if fx.hud then gui.delete_node(fx.hud) end
	a.fx = nil
end

-- The vetrina -------------------------------------------------------------------------

local function panel(g, x, y, w, h, name)
	local grp = kit.group(g, x + w / 2, y + h / 2)
	if name == "carta" then kit.paper(grp.node, w, h) else kit.panel(grp.node, w, h, name) end
	return grp
end

local function fit(n, w)
	local tw = kit.width(n)
	if tw > w then
		gui.set_scale(n, gui.get_scale(n) * (w / tw))
		kit.check_small(n)
	end
	return n
end

-- what is still on the wall: the Scaglie, the fragments by family, the moulds
-- filled, when the next wall comes
local function shelf(a, g, key)
	local p = a.prof
	local x, y, w, h = SHELF.x, SHELF.y, SHELF.w, SHELF.h
	local c = panel(g, x, y, w, h, "pannello")
	local ix, iw = x + PAD, w - 2 * PAD
	local sc, fr, left = forge.left(p, key)
	local total = 0
	for _, m in ipairs(forge.wall(p, key)) do total = total + (m.scaglie or 0) end
	kit.text(c, T.on_wall:format(forge.level(key) + 1, forge.WALLS), ix, y + PAD + 18, 22, KC.HOT, "start", 1)
	fit(kit.text(c, kit.upper(T.filled:format(#forge.PRIZES - left, #forge.PRIZES)), ix, y + PAD + 42, 16, KC.MUTE, "start", 0.5), iw)
	kit.piece(c, "scaglia", ix + 17, y + 92, 34)
	kit.text(c, coins.format(sc), ix + 42, y + 102, 28, sc > 0 and KC.SAND or KC.MUTE, "start")
	kit.text(c, T.of_total:format(coins.format(total)), x + w - PAD, y + 102, 17, KC.MUTE, "end")
	kit.heading(c, T.fragments, ix, y + 146, KC.MUTE)
	for i, set in ipairs(equip.SETS) do
		local ry = y + 158 + (i - 1) * 35
		local n = fr[set.id] or 0
		local icon = kit.piece(c, "frammento_" .. set.id, ix + 15, ry + 17, 30)
		if n == 0 then gui.set_color(icon, DIM) end
		kit.text(c, set.name, ix + 38, ry + 24, 17, n > 0 and color_of(set.id) or KC.MUTE, "start", 0.5)
		kit.text(c, "x" .. n, x + w - PAD, ry + 25, 20, n > 0 and KC.SAND or KC.MUTE, "end")
	end
	-- the walls of today (Sergio, 25 Nov, proposal A): three purses, the paid ones closed
	-- and sealed, the one of now glowing with its multiplier, the next ones dark
	kit.rect(c, ix, y + 340, iw, 2, KC.LINE)
	kit.heading(c, T.today, ix, y + 368, KC.MUTE)
	local now = forge.level(key)
	local done_now = forge.full(p, key)
	for i = 0, forge.WALLS - 1 do
		local cx, bottom, h = ix + 30 + i * 74, y + 434, 56
		local state = (i < now or (i == now and done_now)) and "done" or i == now and "now" or "next"
		local name = state == "done" and "borsa_chiusa_ferro" or "borsa_ferro"
		local pc = PIECES[name]
		local w = h * pc.w / pc.h
		local gx, gy = cx - c.ox, c.oy - bottom
		local n = piece(c.node, name, gx, gy, w, gui.PIVOT_S)
		if state == "now" then
			-- hot, as a purse glows when it is hit (glow: its own drawing added in ember)
			local hot = piece(c.node, name, gx, gy, w, gui.PIVOT_S)
			gui.set_blend_mode(hot, gui.BLEND_ADD)
			gui.set_color(hot, vmath.vector4(EMBER.x, EMBER.y, EMBER.z, 0.6))
		end
		if state == "next" then gui.set_color(n, vmath.vector4(0.38, 0.36, 0.38, 1)) end
		local label = state == "done" and T.wall_full_short or ("x" .. (tostring(forge.LEVELS[i + 1]):gsub("%.", ",")))
		kit.text(c, label, cx, y + 450, 15, state == "now" and KC.HOT or KC.MUTE, "middle", 0.5)
	end
	kit.text(c, T.new_wall, ix, y + 476, 15, KC.MUTE, "start", 0.5)
	a.fx.timer = kit.text(c, until_next(), x + w - PAD, y + 478, 24, KC.SAND, "end")
	a.fx.timer_text = until_next()
	return left
end

-- the window that melts fragments (docs/commesse.md: MELT_IN of a family for one of
-- another, or one for MELT_SCAGLIE Scaglie). a.melt = { da, a }
local function melt_window(a, base)
	local p = a.prof
	local m = a.melt
	for i = #a.buttons, base + 1, -1 do a.buttons[i] = nil end
	for _, k in ipairs({ "low", "low2", "right" }) do if a[k] then gui.set_enabled(a[k].node, false) end end
	a.over = kit.anchor(0, 0)
	local huge = 1280 * screen.FULL
	kit.rect(a.over, 640 - huge / 2, 360 - huge / 2, huge, huge, VEIL)
	kit.zone(a.over, a.buttons, 640 - huge / 2, 360 - huge / 2, huge, huge, "fondi:chiudi")
	local x, y, w, h = 330, 110, 620, 450
	local c = panel(a.over, x, y, w, h, "pannello")
	kit.zone(c, a.buttons, x, y, w, h, "fondi:niente")
	kit.text(c, T.melt_title, x + 24, y + 44, 26, KC.HOT, "start", 1)
	kit.text(c, T.melt_pick, x + 24, y + 72, 17, KC.MUTE, "start", 0.5)
	-- the families on the left: the one chosen lit
	local lx, lw = x + 24, 270
	for i, set in ipairs(equip.SETS) do
		local ry = y + 94 + (i - 1) * 64
		local n = orders.fragments(p, set.id)
		local card = kit.card(c, lx, ry, lw, 56, nil, { sel = m.da == set.id, off = n == 0 })
		local icon = kit.piece(card.g, "frammento_" .. set.id, lx + 30, ry + 28, 38)
		if n == 0 then gui.set_color(icon, DIM) end
		kit.text(card.g, set.name, lx + 58, ry + 35, 18, n > 0 and color_of(set.id) or KC.MUTE, "start", 0.5)
		kit.text(card.g, "x" .. n, lx + lw - 16, ry + 36, 20, n > 0 and KC.SAND or KC.MUTE, "end")
		if n > 0 then kit.button(a.buttons, card, "fondi:da:" .. set.id) end
	end
	-- on the right: into Scaglie, or into another family
	local rx, rw = x + 324, 272
	local have = m.da and orders.fragments(p, m.da) or 0
	kit.heading(c, T.melt_scaglie, rx, y + 112, KC.MUTE)
	local ok1 = m.da and have >= 1 and profile.can_spend()
	local b1 = kit.secondary(c, T.melt_one, rx, y + 126, rw, 62,
		{ icon = "scaglia", sub = kit.upper(T.melt_one_sub:format(forge.MELT_SCAGLIE)), off = not ok1 })
	kit.button(a.buttons, b1, "fondi:scaglie", { spento = not ok1 })
	kit.heading(c, T.melt_family, rx, y + 238, KC.MUTE)
	local k = 0
	for _, set in ipairs(equip.SETS) do
		if set.id ~= m.da then
			local cx, cy = rx + 30 + k * 70, y + 282
			if m.a == set.id then kit.dot(c, cx, cy, 62, KC.HOT) end
			kit.dot(c, cx, cy, 54, KC.CARD_BOTTOM)
			kit.piece(c, "frammento_" .. set.id, cx, cy, 44)
			if m.da then kit.zone(c, a.buttons, cx - 32, cy - 32, 64, 64, "fondi:a:" .. set.id) end
			k = k + 1
		end
	end
	local ok2 = m.da and m.a and have >= forge.MELT_IN and profile.can_spend()
	local b2 = kit.secondary(c, T.melt_four:format(forge.MELT_IN), rx, y + 334, rw, 62,
		{ icon = "frammento_" .. (m.a or m.da or "fabbro"), sub = kit.upper(T.melt_four_sub:format(forge.MELT_OUT)), off = not ok2 })
	kit.button(a.buttons, b2, "fondi:famiglia", { spento = not ok2 })
end

-- Draws the tab into the armory's groups (a.left, a.mid, a.rt, a.low, a.low2, a.right)
function M.board(a)
	local p = a.prof
	local base = #a.buttons
	forge.init(p)
	-- the world is made again, except while playing (it closes into the new board)
	if not (a.fx and a.fx.phase ~= "vetrina") then
		drop_world(a)
		make_world(a)
	end
	local fx = a.fx
	local key = fx.key
	local f = p.fornace
	-- the Smith at his counter (WB-085), as in COMMESSE
	kit.piece(a.left, "fabbro_al_banco", 215, 350, 500)
	-- the frame of the wall
	panel(a.mid, FRAME.x, FRAME.y, FRAME.w, FRAME.h, "pannello")
	-- the paper with the rule (and the lucky mould, when this wall has one)
	local lucky = false
	for _, m in ipairs(forge.wall(p, key)) do
		if m.lucky and not (key == f.muro and f.pieni[m.slot]) then lucky = true end
	end
	local paper = panel(a.mid, PAPER.x, PAPER.y, PAPER.w, PAPER.h, "carta")
	-- (Sergio, 25 Nov, proposal B: the Smith's paper says the walls of the day)
	fit(kit.text(paper, T.rule_walls:format(forge.WALLS), PAPER.x + 24, PAPER.y + 46, 22, KC.INK, "start"), PAPER.w - 48)
	fit(kit.text(paper, lucky and T.rule_lucky or T.rule_walls_sub, PAPER.x + 24, PAPER.y + 76, 17,
		lucky and vmath.vector4(0.66, 0.28, 0.05, 1) or PAPER_MUTE, "start"), PAPER.w - 48)
	local left = shelf(a, a.rt, key)
	-- the band: FONDI I FRAMMENTI, and COLA (TIRA while throws are left)
	local fb = kit.secondary(a.low, T.melt, 160, 640, 262, 62, { icon = "frammento_fornace" })
	kit.button(a.buttons, fb, "fondi:apri")
	local net = profile.can_spend()
	local label, sub, ok
	if f.tiri > 0 then
		label, ok = T.throw, true
		sub = f.tiri == 1 and T.one_left or T.left:format(f.tiri)
	else
		label = T.pour
		ok = left > 0 and (p.ossidiana or 0) >= forge.COST and net
		sub = (left == 0 and T.wall_done) or (not net and TP.need_network)
			or ((p.ossidiana or 0) < forge.COST and T.missing:format(forge.COST - (p.ossidiana or 0)))
			or T.pour_sub:format(forge.THROWS, forge.COST)
	end
	a.action = kit.action(a.right, label, 948, 628, 308, 80, { icon = "gemma", size = 42, off = not ok, sub = kit.upper(sub) })
	kit.button(a.buttons, a.action, "cola", { main = true, spento = not ok })
	-- the world over the board, in its frame (and the melting window over it)
	gui.move_above(fx.top, nil)
	if a.melt then melt_window(a, base) end
end

-- Playing -----------------------------------------------------------------------------

local MENU = { "left", "mid", "rt", "right", "low", "low2", "over" }

-- the board's nodes on or off (under the whole screen they cost and take taps)
local function menu(a, on)
	for _, k in ipairs(MENU) do if a[k] then gui.set_enabled(a[k].node, on) end end
	if a.head then for _, n in ipairs(a.head.tops) do gui.set_enabled(n, on) end end
end

-- where the drop leaves: the rules' muzzle (forge.launch)
local function bowl(fx)
	local p = screen.node_pos(fx.bowl_pt)
	return to_world(fx, p.x, p.y)
end

-- the throws, top left: one drop each, the used ones dim
local function throws_row(a)
	local fx, f = a.fx, a.prof.fornace
	if fx.row then gui.delete_node(fx.row) end
	fx.row = empty(fx.hud)
	local g = { node = fx.row, ox = 0, oy = 0 }
	local x0 = screen.x0 + 32
	local total = f.lanci + f.tiri
	kit.text(g, T.throws, x0 + 2, -(720 - 58 - 2), 26, KC.INK, "start", 1)
	kit.text(g, T.throws, x0, -(720 - 58), 26, KC.HOT, "start", 1)
	for i = 1, total do
		local n = piece(fx.row, "goccia", x0 + 96 + (i - 1) * 44, 720 - 48, 36)
		if i <= f.lanci then gui.set_color(n, DIM) end
		if fx.pop_from and i >= fx.pop_from then
			gui.set_scale(n, vmath.vector3(0.01, 0.01, 1))
			gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3, (i - fx.pop_from) * 0.12)
		end
	end
	fx.pop_from = nil
end

-- a word in the middle of the screen that pops and fades (3 SU 3!, DOPPIO!)
local function shout(a, t, y, color, life, size)
	local fx = a.fx
	size = size or 40
	local n = empty(fx.hud, 640, y)
	local g = { node = n, ox = 0, oy = 0 }
	local o = math.max(3, size * 0.08)
	kit.text(g, t, o, o * 1.3, size, KC.INK, "middle", 1)
	kit.text(g, t, 0, 0, size, color or KC.HOT, "middle", 1)
	gui.set_scale(n, vmath.vector3(0.3, 0.3, 1))
	gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3)
	gui.animate(n, "position.y", y + 30, gui.EASING_OUTQUAD, life, 0)
	gui.animate(n, "color.w", 0, gui.EASING_INQUAD, 0.3, life - 0.3, function() gui.delete_node(n) end)
	return n
end

-- the orange splash where molten Ossidiana lands (world units)
local function splash(fx, x, y, w)
	local n = piece(fx.splash, "schizzo", x, y, w * 0.5, gui.PIVOT_S)
	gui.animate(n, "size", vec(w, w * PIECES.schizzo.h / PIECES.schizzo.w), gui.EASING_OUTQUAD, 0.22)
	gui.animate(n, "color.w", 0, gui.EASING_INQUAD, 0.25, 0.12, function() gui.delete_node(n) end)
end

-- a game point into the wallet's parent (coins.fly wants it there)
local function in_purse(fx, x, y)
	local at = screen.node_pos(fx.purse_parent)
	return vec(x - at.x, y - at.y)
end

-- the pour's gems: from the wallet to the ladle (phase "gems", M.update)
local function gems(fx)
	fx.phase, fx.t = "gems", 0
	fx.gems = {}
	for i = 1, forge.COST do
		fx.gems[i] = { node = kit.piece({ node = fx.hud, ox = 0, oy = 0 }, "gemma", 0, 0, 40) }
		gui.set_enabled(fx.gems[i].node, false)
	end
end

local function start(a, poured)
	local fx = a.fx
	local p = a.prof
	fx.phase, fx.t = "open", 0
	fx.poured = poured
	fx.got = { sacchi = 0, vetri = 0, fr = {}, hits = 0 }
	travel(fx, full_view(), CLOSE, OPEN)
	-- the throws' things over the whole screen: the wallet and the throws
	fx.hud = empty(nil, 0, 0)
	fx.purse_parent = empty(fx.hud, screen.x1 - 170, 720 - 44)
	fx.purse = coins.wallet(p.scaglie or 0, (p.ossidiana or 0) + (poured and forge.COST or 0), fx.purse_parent, 0, 0)
	-- the phone's aim stick, on the right as in battle (battle/stick_pad.lua)
	SP.arrange(screen.x0, screen.y0, screen.x1, screen.y1)
	fx.stick = SP.new(SP.AIM_PAD, SP.AIM_IDLE)
	gui.set_parent(fx.stick.base, fx.hud)
	gui.set_enabled(fx.stick.base, false)
	gui.set_enabled(fx.hud, false)
	gui.move_above(fx.top, nil)
	a.melt = nil
end

local function pad_off(fx)
	sticks.reset(fx.pad_st)
	fx.pad = false
	-- the phone's stick back to its place
	if fx.stick and fx.stick.id then SP.release(fx.stick, SP.AIM_IDLE) end
	sticks.reset(fx.thumb_st)
end

local function aim_off(fx)
	aim.clear(fx.aim)
	if fx.hint then gui.set_enabled(fx.hint, false) end
end

local function to_aim(a)
	local fx = a.fx
	fx.phase, fx.t = "aim", 0
	fx.aiming = false
	pad_off(fx)
	fx.st.lancio = nil
	if fx.stick then gui.set_enabled(fx.stick.base, SP.on()) end
	if fx.hint then gui.set_enabled(fx.hint, a.prof.fornace.lanci == 0) end
end

local function close(a)
	local fx = a.fx
	aim_off(fx)
	gui.set_enabled(fx.molten, false)
	fx.st.lancio = nil
	fx.stick = nil
	if fx.purse then coins.finish(fx.purse); coins.delete(fx.purse); fx.purse = nil end
	if fx.hud then gui.delete_node(fx.hud); fx.hud = nil end
	-- the effects still going belong to the hud and the wall, which go
	fx.parts, fx.trembles, fx.timers = nil, nil, nil
	fx.row, fx.hint = nil, nil
	fx.got = nil
	fx.phase, fx.t = "close", 0
	travel(fx, frame_view(), frame_cam(frame_view()), OPEN)
	fx.rebuild = true
end

-- the throw leaves: the rules decide (through the profile's door), the drawing follows
local function launch(a)
	local fx, p = a.fx, a.prof
	local f = p.fornace
	local full = {}
	for k, v in pairs(f.pieni) do full[k] = v end
	local wall = forge.wall(p, f.muro)
	local _, path = forge.fly(fx.angle, fx.power, wall, full, true)
	local r = profile.act(p, { k = "tiro", angolo = fx.angle, forza = fx.power })
	if not r then to_aim(a); return end
	fx.result, fx.path, fx.wall, fx.hit_i, fx.wall_i = r, path, wall, 1, 1
	local got = fx.got
	if got then
		if r.esito == "stampo" then
			got.hits = got.hits + 1
			got.sacchi = got.sacchi + (r.scaglie or 0) + (r.base or 0)
		else
			got.vetri = got.vetri + 1
		end
		if r.set then got.fr[r.set] = (got.fr[r.set] or 0) + r.n end
		if r.bonus then got.bonus = true end
		if r.jackpot then got.jackpot, got.medal = r.jackpot, r.medal end
	end
	-- the drop leaves from the ladle's bowl and joins the rules' path in a moment
	local bx, by = bowl(fx)
	fx.off = { bx - path[1][1], by - path[1][2] }
	gui.set_enabled(fx.molten, false)
	gui.set_enabled(fx.drop, true)
	sound.play("#colpo")
	fx.phase, fx.t = "fly", 0
end

local missed, after_throw, recap

-- The whole wall filled (the page's «jackpot del muro pieno»): once the last flame has
-- burned the moulds light up one after another like a row of lamps, a flash, the
-- camera shakes, JACKPOT! huge and wobbling, a rain of Scaglie and fragments over the
-- screen; the Scaglie on the bench (it breaks) and, the first time, the medal
local LAMPS_AT, LAMP_GAP, BANG_AT = 1.2, 0.1, 2.4
local RAIN = { "scaglia", "scaglia", "scaglia", "frammento_fabbro", "scaglia", "scaglia", "scaglia", "frammento_corvo",
	"scaglia", "scaglia", "scaglia", "frammento_fornace", "scaglia", "scaglia", "scaglia", "frammento_leviatano",
	"scaglia", "scaglia", "scaglia", "frammento_vuoto" }
local function banner(a, t, y, size, color, life)
	local fx = a.fx
	local n = shout(a, t, y, color, life, size)
	gui.cancel_animations(n, "position.y")
	gui.set_scale(n, vmath.vector3(0.4, 0.4, 1))
	gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.4)
	gui.animate(n, "position.y", y + 8, gui.EASING_INOUTSINE, 0.5, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	gui.set_rotation(n, vmath.vector3(0, 0, -1.7))
	gui.animate(n, "euler.z", 1.7, gui.EASING_INOUTSINE, 1, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	return n
end

local function jackpot(a, r)
	local fx = a.fx
	fx.hold = JACKPOT_T
	local ms = {}
	for _, m in ipairs(fx.wall) do ms[#ms + 1] = m end
	table.sort(ms, function(p, q) if p.x ~= q.x then return p.x < q.x end return p.slot < q.slot end)
	local lamps = {}
	for i, m in ipairs(ms) do
		later(fx, LAMPS_AT + (i - 1) * LAMP_GAP, function()
			local h = glow(fx, m, nil, 0.9)
			if h then
				gui.animate(h, "color.w", 0.45, gui.EASING_INOUTSINE, 0.4, 0.15, nil, gui.PLAYBACK_LOOP_PINGPONG)
				lamps[#lamps + 1] = h
			end
			-- the golden light on the full purse's top
			local e = ui.disc(m.x, m.y + m.w * 0.42, m.w * 0.9, GOLD, fx.splash)
			gui.set_size(e, vec(m.w * 0.9, m.w * 0.2))
			gui.set_blend_mode(e, gui.BLEND_ADD)
			gui.set_scale(e, vmath.vector3(0.2, 0.2, 1))
			gui.animate(e, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.15)
			lamps[#lamps + 1] = e
			sound.play("#scaglia")
		end)
	end
	later(fx, BANG_AT, function()
		-- the bancarotta: the bench breaks under the loot, the usurers cry
		bankrupt(fx)
		say(fx, T.say_jackpot, "usuraio_paga")
		veil(fx, WARM, 0.7, 0.12)
		fx.shake = SHAKE * 3
		sound.play("#martello")
		local cx = (screen.x0 + screen.x1) / 2
		banner(a, T.jackpot, 400, 120, GOLD, JACKPOT_T - BANG_AT + 0.6)
		later(fx, 0.15, function() shout(a, T.wall_full, 300, KC.HOT, JACKPOT_T - BANG_AT + 0.4, 34) end)
		-- the rain, from above the screen over its whole width
		fx.parts = fx.parts or {}
		local wide = screen.x1 - screen.x0
		for i = 1, 40 do
			later(fx, math.random() * 1.2, function()
				local n = empty(fx.hud, screen.x0 + wide * math.random(), screen.y1 + 40)
				kit.piece({ node = n, ox = 0, oy = 0 }, RAIN[i % #RAIN + 1], 0, 0, 30 + 16 * math.random())
				local p = gui.get_position(n)
				fx.parts[#fx.parts + 1] = { node = n, x = p.x, y = p.y, vx = (math.random() - 0.5) * 60,
					vy = -(260 + 200 * math.random()), g = 600, t = 0, life = 2.2, spin = (math.random() - 0.5) * 360, keep = true }
			end)
		end
		if r.medal then
			later(fx, 0.7, function()
				shout(a, T.medal, 150, KC.SAND, JACKPOT_T - BANG_AT - 0.7, 30)
				-- the medal of WB-094 jumps out under the words, turns a little and goes
				local md = piece(fx.hud, "medaglia_jackpot", cx, 215, 170)
				local life = JACKPOT_T - BANG_AT - 0.7
				gui.set_scale(md, vmath.vector3(0.1, 0.1, 1))
				gui.animate(md, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.45)
				gui.set_rotation(md, vmath.vector3(0, 0, -25))
				gui.animate(md, "euler.z", 0, gui.EASING_OUTBACK, 0.6)
				gui.animate(md, "color.w", 0, gui.EASING_INQUAD, 0.3, life - 0.3, function() gui.delete_node(md) end)
			end)
		end
	end)
	-- the lamps go out as the recap comes
	later(fx, JACKPOT_T + AFTER - 0.4, function()
		for _, h in ipairs(lamps) do
			gui.animate(h, "color.w", 0, gui.EASING_INQUAD, 0.4, 0, function() gui.delete_node(h) end)
		end
	end)
end

-- where the flight ended: the prize, the splash, the coins
local function land(a)
	local fx = a.fx
	local r = fx.result
	local last = fx.path[#fx.path]
	gui.set_enabled(fx.drop, false)
	fx.phase, fx.t = "after", 0
	fx.focus = nil
	-- a record of knocks on the moulds' iron in one throw (6, 10: the medals)
	if r.knocks then
		shout(a, T.knocks:format(r.knocks), 540, KC.SAND, 1.8, 44)
		-- its medal (WB-095) jumps out under the words the first time
		local name = "medaglia_rintocchi_" .. r.knocks
		if PIECES[name] then
			local md = piece(fx.hud, name, (screen.x0 + screen.x1) / 2, 420, 130)
			gui.set_scale(md, vmath.vector3(0.1, 0.1, 1))
			gui.animate(md, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.45, 0.15)
			gui.set_rotation(md, vmath.vector3(0, 0, -25))
			gui.animate(md, "euler.z", 0, gui.EASING_OUTBACK, 0.6, 0.15)
			gui.animate(md, "color.w", 0, gui.EASING_INQUAD, 0.3, 1.6, function() gui.delete_node(md) end)
		end
		if fx.got then fx.got.knocks = math.max(fx.got.knocks or 0, r.knocks) end
	end
	if r.esito == "stampo" then
		local m = fx.wall[r.slot]
		fx.freeze, fx.shake = FREEZE, SHAKE
		fx.focus = { m.x, m.y }
		fill_mould(fx, m)
		fx.shake = SHAKE * 1.6
		sound.play("#martello")
		-- the page's «fiammata»: the screen dark for the moment the drop goes in, then a
		-- warm flash as the column bursts, and CENTRO! big at the top
		veil(fx, KC.INK, 0.35, FREEZE + 0.25)
		later(fx, 0, function() veil(fx, WARM, 0.5, 0.12) end)
		if not r.jackpot then shout(a, T.hit, 610, GOLD, 1.4, 64) end
		fx.hold = 0.5
		if r.jackpot then jackpot(a, r) end
		local sx, sy = to_screen(fx, m.x, m.y + m.w * 0.6)
		if not r.scaglie then
			-- the family's fragment rises from the mould, with how many
			local n = empty(fx.hud, sx, sy)
			local g = { node = n, ox = 0, oy = 0 }
			kit.piece(g, "frammento_" .. r.set, 0, 0, 56)
			kit.text(g, "+" .. r.n, 32 + 2, 12 + 2, 30, KC.INK, "start")
			kit.text(g, "+" .. r.n, 32, 12, 30, color_of(r.set), "start")
			gui.set_scale(n, vmath.vector3(0.3, 0.3, 1))
			gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3)
			gui.animate(n, "position.y", sy + 70, gui.EASING_OUTQUAD, 1.1)
			gui.animate(n, "color.w", 0, gui.EASING_INQUAD, 0.3, 0.9, function() gui.delete_node(n) end)
			sound.play("#scaglia")
		end
		-- the usurer cries, the loot goes on the bench (it sags a little more)
		later(fx, LID_AT + 0.3, function()
			say(fx, T.say_hit)
			bench(fx, fx.got, r.set or "scaglie")
		end)
		if r.lucky then shout(a, T.lucky_hit, 470, KC.HOT, 1.1) end
		if r.sponda then
			shout(a, T.bank:format((string.format("%.1f", r.sponda):gsub("%.0$", ""):gsub("%.", ","))), r.lucky and 410 or 470, KC.HOT, 1.1)
		end
	else
		missed(a, last[1], last[2])
		return
	end
	after_throw(a)
end

-- a drop that missed: its splash, it is glass in the sand and the bead hops into the
-- jar at the end of the bench (MISS, paid at INCASSA); the usurer it nearly went in
-- (or another one) laughs
local HOP_T = 0.75
missed = function(a, x, y)
	local fx = a.fx
	local r = fx.result
	local on_sand = y <= forge.FLOOR + 10
	if on_sand then splash(fx, x, FLOOR_TOP, 50) else splash(fx, x, y - 6, 40) end
	fx.phase, fx.t = "after", 0
	x = math.max(-80, math.min(forge.BACK_X - 20, x))
	y = on_sand and FLOOR_TOP + 2 or y
	local b = piece(fx.splash, "perla", x, y, 18)
	local tx, ty = fx.jar_at[1], fx.jar_at[2] - 6
	local g = 900
	fx.parts = fx.parts or {}
	fx.parts[#fx.parts + 1] = { node = b, x = x, y = y, vx = (tx - x) / HOP_T, vy = (ty - y) / HOP_T + 0.5 * g * HOP_T,
		g = g, t = 0, life = HOP_T, keep = true }
	-- the usurer it passed nearest
	local near, best = nil, math.huge
	for _, m in ipairs(fx.wall) do
		if not a.prof.fornace.pieni[m.slot] then
			for i = 1, #fx.path, 3 do
				local q = fx.path[i]
				local d = ((q[1] - m.x) ^ 2 + (q[2] - m.y) ^ 2) / (m.w * m.w)
				if d < best then near, best = m, d end
			end
		end
	end
	say(fx, near and best < 1 and T.say_near or T.say_miss)
	later(fx, HOP_T, function()
		sound.play("#punto")
		bench(fx, fx.got)
		local bx, by = to_screen(fx, fx.jar_at[1], fx.jar_at[2])
		local n = empty(fx.hud, bx, by + 30)
		local tg = { node = n, ox = 0, oy = 0 }
		kit.text(tg, T.miss, 2, 2, 20, KC.INK, "middle", 1)
		kit.text(tg, T.miss, 0, 0, 20, KC.SAND, "middle", 1)
		gui.animate(n, "position.y", by + 80, gui.EASING_OUTQUAD, 1)
		gui.animate(n, "color.w", 0, gui.EASING_INQUAD, 0.3, 0.7, function() gui.delete_node(n) end)
	end)
	fx.hold = HOP_T
	after_throw(a)
end

-- the throws' row again, and the extra throw of 3 out of 3
after_throw = function(a)
	local fx, p = a.fx, a.prof
	local r = fx.result
	if r.bonus then
		fx.pop_from = p.fornace.lanci + p.fornace.tiri - r.bonus + 1
		fx.bonus_at = AFTER
	end
	throws_row(a)
end

-- The pour's recap (Sergio, 24 Nov: «un riepilogo delle ricompense ... prima di chiudere
-- la partita»): what the throws brought, row by row, then COLA ANCORA and INCASSA (both
-- pay what is on the bench first)
local RECAP_W, RECAP_ROW = 480, 52
function recap(a)
	local fx, p = a.fx, a.prof
	local got = fx.got
	fx.phase, fx.t = "recap", 0
	if fx.stick then gui.set_enabled(fx.stick.base, false) end
	local rows = {}
	rows[#rows + 1] = { icon = "scaglia", label = T.recap_scaglie, value = "+" .. coins.format(got.sacchi), color = KC.SAND }
	if got.vetri > 0 then
		rows[#rows + 1] = { icon = "scaglia", label = T.recap_beads:format(got.vetri), value = "+" .. coins.format(got.vetri * forge.MISS), color = KC.SAND }
	end
	for _, set in ipairs(equip.SETS) do
		local n = got.fr[set.id]
		if n then rows[#rows + 1] = { icon = "frammento_" .. set.id, label = T.recap_fragments:format(set.name), value = "+" .. n, color = color_of(set.id) } end
	end
	if got.bonus then rows[#rows + 1] = { icon = "goccia_hud", label = T.recap_bonus, value = "", color = KC.HOT } end
	if got.jackpot then rows[#rows + 1] = { icon = "scaglia", label = T.recap_jackpot, value = "+" .. coins.format(got.jackpot), color = KC.HOT } end
	if got.medal then rows[#rows + 1] = { icon = "medaglia_jackpot", label = T.medal, value = "", color = KC.HOT } end
	if got.knocks and PIECES["medaglia_rintocchi_" .. got.knocks] then
		rows[#rows + 1] = { icon = "medaglia_rintocchi_" .. got.knocks, label = T.knocks_medal:format(got.knocks), value = "", color = KC.HOT }
	end
	local h = 96 + #rows * RECAP_ROW + 104
	local cx, cy = (screen.x0 + screen.x1) / 2, 360
	local x0, y0 = cx - RECAP_W / 2, cy - h / 2
	local root = empty(fx.hud, 0, 0)
	fx.recap = root
	-- the veil, then the card
	local veil = box(root, cx, 360, screen.width() + 4, 724)
	gui.set_color(veil, VEIL)
	local g = { node = root, ox = 0, oy = 720 }
	kit.card(g, x0, y0, RECAP_W, h, KC.HOT, { sel = true })
	kit.text(g, T.recap_title, cx, y0 + 50, 30, KC.HOT, "middle", 1)
	kit.rect(g, x0 + 28, y0 + 74, RECAP_W - 56, 2, KC.LINE)
	for i, r in ipairs(rows) do
		local y = y0 + 96 + (i - 1) * RECAP_ROW + RECAP_ROW / 2
		local row = empty(root, 0, 0)
		local rg = { node = row, ox = 0, oy = 720 }
		if r.icon == "goccia_hud" then piece(row, "goccia", x0 + 52, 720 - y, 30)
		elseif r.icon:match("^medaglia_") then piece(row, r.icon, x0 + 52, 720 - y, 40)
		elseif r.icon then kit.piece(rg, r.icon, x0 + 52, y, 34) end
		fit(kit.text(rg, r.label, x0 + (r.icon and 84 or 34), y + 7, 19, KC.SAND, "start", 0.4), RECAP_W - 210)
		if r.value ~= "" then kit.text(rg, r.value, x0 + RECAP_W - 34, y + 9, 26, r.color, "end") end
		-- one after the other
		gui.set_color(row, vmath.vector4(1, 1, 1, 0))
		gui.set_position(row, vec(30, 0))
		gui.animate(row, "position.x", 0, gui.EASING_OUTCUBIC, 0.3, 0.25 + i * 0.22)
		gui.animate(row, "color.w", 1, gui.EASING_LINEAR, 0.2, 0.25 + i * 0.22)
	end
	-- COLA ANCORA (while the wall has prizes and there is Ossidiana) and CHIUDI
	local f = p.fornace
	local left = 0
	for _, m in ipairs(forge.wall(p, wall_key(p))) do if not f.pieni[m.slot] or f.muro ~= wall_key(p) then left = left + 1 end end
	local can = left > 0 and (p.ossidiana or 0) >= forge.COST and profile.can_spend()
	local by, bw, bh = y0 + h - 84, (RECAP_W - 72) / 2, 60
	if got.jackpot then
		-- after the jackpot only CHIUDI (Sergio, 25 Nov): the next wall of the day is
		-- shown in the vetrina, a new pour starts from there
		local cw = RECAP_W - 56
		kit.secondary(g, T.recap_close, x0 + 28, by, cw, bh)
		fx.recap_btns = { { x = x0 + 28, y = by, w = cw, h = bh, cmd = "close" } }
	else
		kit.secondary(g, T.recap_again, x0 + 28, by, bw, bh, { main = true, off = not can, icon = "gemma" })
		kit.secondary(g, T.recap_close, x0 + 44 + bw, by, bw, bh)
		fx.recap_btns = { { x = x0 + 28, y = by, w = bw, h = bh, cmd = can and "again" or nil }, { x = x0 + 44 + bw, y = by, w = bw, h = bh, cmd = "close" } }
	end
	gui.set_scale(root, vmath.vector3(0.9, 0.9, 1))
	gui.animate(root, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3)
	gui.move_above(fx.hud, nil)
end

-- a fragment of the bench up to the wallet: it lands under it with its number
local function fragment_home(fx, set, n, x, y)
	local tx, ty = screen.x1 - 200, 720 - 104
	local nd = empty(fx.hud, x, y)
	kit.piece({ node = nd, ox = 0, oy = 0 }, "frammento_" .. set.id, 0, 0, 44)
	gui.set_scale(nd, vmath.vector3(0.3, 0.3, 1))
	gui.animate(nd, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.15)
	gui.animate(nd, "position.x", tx, gui.EASING_OUTQUAD, coins.FLIGHT * 1.4, 0.1)
	gui.animate(nd, "position.y", ty, gui.EASING_INQUAD, coins.FLIGHT * 1.4, 0.1, function()
		sound.play("#scaglia")
		local g = { node = nd, ox = 0, oy = 0 }
		kit.text(g, "+" .. n .. " " .. set.name, 26 + 2, 8 + 2, 20, KC.INK, "start")
		kit.text(g, "+" .. n .. " " .. set.name, 26, 8, 20, color_of(set.id), "start")
		gui.animate(nd, "position.y", ty - 16, gui.EASING_OUTQUAD, 1.2)
		fade(nd, 0.4, 1.1)
	end)
end

-- INCASSA (Sergio, 26 Nov: «ti arrivino nel portafoglio solo alla fine, quando chiudi
-- con la modale ... in un tripudio di animazioni»): the bench empties heap by heap, the
-- Scaglie in arcs into the wallet that counts them up, the beads of the jar too, the
-- fragments up under it with their number; the usurer grumbles; then after()
local PAY_GAP = 0.45
local function pay(a, after)
	local fx = a.fx
	local got = fx.got or {}
	fx.phase, fx.t = "pay", 0
	local jobs = {}
	local heaps = fx.heap_of or {}
	local sc = (got.sacchi or 0) + (got.jackpot or 0)
	if sc > 0 and heaps.scaglie then jobs[#jobs + 1] = { node = heaps.scaglie, coins = sc, tag = "heap_scaglie" } end
	if (got.vetri or 0) > 0 and fx.jar then jobs[#jobs + 1] = { node = fx.jar, coins = got.vetri * forge.MISS, tag = "jar", beads = true } end
	for _, set in ipairs(equip.SETS) do
		local n = got.fr and got.fr[set.id]
		if n and heaps[set.id] then jobs[#jobs + 1] = { node = heaps[set.id], set = set, n = n, tag = "heap_" .. set.id } end
	end
	local t = 0
	for _, j in ipairs(jobs) do
		later(fx, t, function()
			local q = screen.node_pos(j.node)
			-- the heap bursts: embers, a warm flash, a shake
			sparks(fx, fx.hud, q.x, q.y + 10, 26, 1.4, 420, 10, 760, { GOLD, EMBER, GOLD })
			fx.shake = SHAKE * 0.8
			sound.play("#martello")
			if j.coins then
				coins.fly(fx.purse, "scaglia", in_purse(fx, q.x, q.y + (j.beads and 30 or 10)),
					math.min(28, math.max(6, math.floor(j.coins / 8))), j.coins,
					function(i) if i % 2 == 1 then sound.play("#scaglia") end end)
			else
				fragment_home(fx, j.set, j.n, q.x, q.y + 10)
			end
			if j.beads then
				for _, b in ipairs(fx.beads or {}) do fade(b, 0.25) end
			else
				gui.animate(j.node, "scale", vmath.vector3(0.01, 0.01, 1), gui.EASING_INBACK, 0.4, 0.15)
			end
			local tg = fx.tags[j.tag]
			if tg then fx.tags[j.tag] = nil; fade(tg, 0.25) end
		end)
		t = t + PAY_GAP
	end
	if #jobs > 0 then say(fx, T.say_pay, "usuraio_paga") end
	-- once it has all landed: the total big and wobbling, a golden flash
	local total = sc + (got.vetri or 0) * forge.MISS
	if total > 0 then
		later(fx, t + coins.FLIGHT * 0.6, function()
			veil(fx, WARM, 0.45, 0.25)
			banner(a, T.paid:format(coins.format(total)), 470, 64, GOLD, 1.3)
			sound.play("#scaglia")
		end)
	end
	-- the bench straightens up as it empties
	later(fx, t + coins.FLIGHT + 1.4, function()
		if fx.purse then coins.finish(fx.purse) end
		fx.got = nil
		after()
	end)
end

local function recap_do(a, what)
	local fx = a.fx
	if not what then return end
	fx.recap_btns = nil
	if fx.recap then gui.delete_node(fx.recap); fx.recap = nil end
	pay(a, function()
		-- COLA ANCORA stays on the wall (Sergio, 25 Nov: «non c'è bisogno di uscire e
		-- rientrare»): it pays, and the gems fly into the ladle as at every pour
		-- (the same wall only: at 5 in the morning a new one comes, and the recap closes on it)
		if what == "again" and wall_key(a.prof) == fx.key and profile.act(a.prof, { k = "colata", muro = wall_key(a.prof) }) then
			fx.poured = true
			fx.got = { sacchi = 0, vetri = 0, fr = {}, hits = 0 }
			bench(fx, nil)
			gems(fx)
			return
		end
		close(a)
	end)
end

-- an angle and power that fill the nearest empty mould (the simulator's sure aim)
local function sure_aim(p)
	local f = p.fornace
	local wall = forge.wall(p, f.muro)
	local g = game.GRAVITY * game.MISSILE_GRAVITY
	for _, m in ipairs(wall) do
		if not f.pieni[m.slot] then
			for deg = 16, 82, 2 do
				local an = math.rad(deg)
				local x0, y0 = forge.launch(an, 1)
				local dx, dy = m.x - x0, m.y - y0
				local d = dx * math.tan(an) - dy
				if d > 0 then
					local power = math.sqrt(g * dx * dx / (2 * math.cos(an) ^ 2 * d)) / game.MISSILE_SPEED
					if power >= 0.1 and power <= 1 then
						local r = forge.fly(an, power, wall, f.pieni)
						if r.esito == "stampo" and r.slot == m.slot then return an, power end
					end
				end
			end
		end
	end
	-- no straight shot: any throw that ends in an empty mould (after a bounce too)
	for deg = 4, 86, 2 do
		for pw = 10, 100 do
			local r = forge.fly(math.rad(deg), pw / 100, wall, f.pieni)
			if r.esito == "stampo" then return math.rad(deg), pw / 100 end
		end
	end
end

-- the angle and power from the finger (game coordinates), as in battle: the
-- direction in the world from the apprentice's middle, the distance on the screen
local function aim_at(a, x, y)
	local fx = a.fx
	local cx, cy = to_screen(fx, 0, game.DISEGNO_H / 2)
	local an, d, pw = aim.from_finger((fx.mir or 1) * (x - cx), y - cy, 1)
	fx.dist = d
	if d < 1 then return end
	fx.angle, fx.power = an, pw
end

-- the ladle swings: the throw leaves (with the simulator's sure aim, into a mould)
local function throw(a)
	local fx = a.fx
	if SURE then
		local an, pw = sure_aim(a.prof)
		if an then fx.angle, fx.power = an, pw end
	end
	-- the finger lifts: the camera comes close to the apprentice, then the swing
	if fx.stick then gui.set_enabled(fx.stick.base, false) end
	fx.phase, fx.t = "windup", 0
	travel(fx, fx.view, THROW_CAM, WINDUP)
end

-- when the drop leaves the ladle in the throw clip (tools/animazioni: lancio_mestolo):
-- in the middle of the fastest forward stretch of its arma track, so a retouched
-- clip keeps the drop in the bowl
local function release_time(clip)
	local k = clip and clip.tracks and clip.tracks.arma
	if not k then return 0.9 end
	local best, at = 0, (clip.duration or 1) * 0.6
	for i = 1, #k - 3, 3 do
		local dt = k[i + 3] - k[i]
		if dt > 0 then
			local v = (k[i + 4] - k[i + 1]) / dt
			if -v > best then best, at = -v, (k[i] + k[i + 3]) / 2 end
		end
	end
	return at
end

-- Every frame of the aim, the controller's aim stick, as in battle (PAD.aim in
-- game.gui_script): lit past 20% of the travel it aims, brought back to the
-- center it goes off and nothing leaves; SPARA throws (M.input)
local function pad_aim(a)
	local fx = a.fx
	local c = controller.current_value
	if fx.aiming or not c then return end
	local l = c[controller.side("mira")]
	if not l then return end
	local st = fx.pad_st
	sticks.aim(st, l.x, l.y)
	if st.active then
		if not fx.pad and fx.hint then gui.set_enabled(fx.hint, false) end
		fx.pad = true
		fx.angle, fx.power = (fx.mir or 1) < 0 and math.pi - st.angle or st.angle, aim.stick_power(st.f)
		sticks.record(st, fx.clock, fx.angle, fx.power, true)
	elseif fx.pad then
		pad_off(fx)
		aim_off(fx)
	end
end

local function draw_aim(a)
	local fx = a.fx
	local s = fx.cam.s
	local x, y = 0, game.DISEGNO_H / 2
	local color = ui.C.SQUADRA[1]
	aim.needle(fx.aim, x, y, fx.angle, s, fx.power, color)
	aim.tag(fx.aim, x, y, fx.angle, s, aim.degrees(fx.angle), fx.power)
	if (fx.mir or 1) < 0 then
		-- the numbers read the right way, on the outer side of the tip
		gui.set_scale(fx.aim.sign, vmath.vector3(-1 / s, 1 / s, 1))
		local c = fx.aim.c
		local flip = { [gui.PIVOT_W] = gui.PIVOT_E, [gui.PIVOT_E] = gui.PIVOT_W }
		if flip[c.pivot] then c.pivot = flip[c.pivot]; gui.set_pivot(c.text_n, c.pivot) end
	end
	-- the dots over the first part of the flight
	local p = a.prof
	local f = p.fornace
	local wall = forge.wall(p, f.muro)
	-- (only the ticks the dots can use: to the top, from the throw's speed, and past it)
	local _, _, _, vy0 = forge.launch(fx.angle, fx.power)
	local top_t = math.max(0, vy0) / (game.GRAVITY * game.MISSILE_GRAVITY * game.DT)
	local _, path = forge.fly(fx.angle, fx.power, wall, f.pieni, true, math.floor(top_t * DOTS_PAST) + 3)
	fx.pts = fx.pts or {}
	-- up to the top and a little past it, fading there (Sergio, 24 Nov); never past
	-- the first bounce
	local top = 1
	for i = 2, #path do if path[i][2] > path[top][2] then top = i end end
	local n = math.min(#path, math.floor(top * DOTS_PAST))
	if path.hits and path.hits[1] then n = math.min(n, path.hits[1]) end
	n = math.max(2, n)
	local len, at_top = 0, 0
	for i = 1, n do
		local q = fx.pts[i] or {}
		q.x, q.y = path[i][1], path[i][2]
		fx.pts[i] = q
		if i > 1 then len = len + math.sqrt((q.x - path[i - 1][1]) ^ 2 + (q.y - path[i - 1][2]) ^ 2) end
		if i == top then at_top = len end
	end
	aim.trajectory(fx.aim, fx.pts, n, s, len > 0 and math.min(0.95, at_top / len) or 0.95)
end

-- The camera while throwing (docs/commesse.md: it comes closer while the ladle
-- loads, follows the drop and stops on the mould): a little closer than the whole
-- wall, eased toward where things happen, and back to the whole wall to aim
local CAM_EASE = 5
local FOCUS_T = 1.2 -- on the hit mould while its flame burns
local FLY_EASE, FLY_ZOOM = 9, 1.5
local function follow(a, dt)
	local fx = a.fx
	if fx.tr or not (fx.phase == "aim" or fx.phase == "swing" or fx.phase == "fly" or fx.phase == "after") then return end
	local base = full_cam(fx.view)
	local tx, ty, ts = base.x, base.y, base.s
	local ease = CAM_EASE
	if fx.phase == "swing" then
		tx, ty, ts = THROW_CAM.x, THROW_CAM.y, THROW_CAM.s
	elseif fx.phase == "fly" then
		-- as in battle: close on the drop, and quick to keep it in the middle
		local d = gui.get_position(fx.drop)
		tx, ty, ts = d.x, math.max(forge.FLOOR + 60, d.y), math.max(base.s * FLY_ZOOM, math.min(THROW_CAM.s, fx.cam.s))
		ease = FLY_EASE
	elseif fx.phase == "after" and fx.focus and fx.t < FOCUS_T then
		tx, ty, ts = lerp(base.x, fx.focus[1], 0.3), lerp(base.y, fx.focus[2], 0.3), base.s * 1.2
	end
	local k = 1 - math.exp(-dt * ease)
	local c = fx.cam
	fx.cam = { x = c.x + (tx - c.x) * k, y = c.y + (ty - c.y) * k, s = math.exp(math.log(c.s) + (math.log(ts) - math.log(c.s)) * k) }
end

-- Every frame: true when the armory must be made again
function M.update(a, dt)
	M.busy = M.playing(a)
	local fx = a.fx
	if not fx then return false end
	local p = a.prof
	local f = p.fornace
	if fx.dev then scoria.update(fx.dev, dt, fx.st) end
	if fx.phase == "vetrina" then
		-- the clock to the next wall; when it comes, the board is made again
		local t = until_next()
		if fx.timer and t ~= fx.timer_text then
			fx.timer_text = t
			gui.set_text(fx.timer, t)
			if wall_key(p) ~= fx.key then return true end
		end
		return false
	end
	fx.t = fx.t + dt
	fx.clock = fx.clock + dt
	-- the frozen moment of a hit and the shake
	if fx.freeze and fx.freeze > 0 then
		fx.freeze = fx.freeze - dt
		return false
	end
	parts_step(fx, dt)
	trembles_step(fx, dt)
	timers_step(fx, dt)
	if fx.shake and fx.shake > 0 then
		fx.shake = fx.shake - dt
		local k = clamp(fx.shake / SHAKE) * SHAKE_PX
		fx.sx, fx.sy = (math.random() * 2 - 1) * k, (math.random() * 2 - 1) * k
	else
		fx.sx, fx.sy = 0, 0
	end
	local moved = travel_step(fx, dt)
	if fx.phase == "open" then
		if moved then
			menu(a, false)
			gui.set_enabled(fx.hud, true)
			gui.move_above(fx.hud, nil)
			if fx.poured then
				gems(fx)
			else
				fx.phase, fx.t = "shots", 0
				throws_row(a)
			end
		end
	elseif fx.phase == "gems" then
		-- from the wallet's gem to the ladle, on a curve, one after the other
		local wx, wy = screen.node_pos(fx.purse_parent).x - 60, 720 - 44
		local bx, by = to_screen(fx, bowl(fx))
		local landed = 0
		for i, gm in ipairs(fx.gems) do
			local t0 = GEM_START + (i - 1) * GEM_GAP
			local u = (fx.t - t0) / GEM_FLY
			if u >= 1 then
				landed = landed + 1
				if gm.node then
					gui.delete_node(gm.node)
					gm.node = nil
					if i % 4 == 1 then sound.play("#punto") end
				end
			elseif u >= 0 and gm.node then
				local e = u * 0.35 + 0.65 * u * u
				local cx, cy = (wx + bx) / 2 - 80, 700 - (i % 3) * 22
				local x = (1 - e) ^ 2 * wx + 2 * (1 - e) * e * cx + e * e * bx
				local y = (1 - e) ^ 2 * wy + 2 * (1 - e) * e * cy + e * e * by
				gui.set_enabled(gm.node, true)
				gui.set_position(gm.node, vec(x, y))
				local sc = 1 - 0.55 * e
				gui.set_scale(gm.node, vmath.vector3(sc, sc, 1))
				gui.set_rotation(gm.node, vmath.vector3(0, 0, (u * 6 + i) * 57))
			end
		end
		coins.set(fx.purse, p.scaglie or 0, (p.ossidiana or 0) + forge.COST - landed)
		local done = GEM_START + (forge.COST - 1) * GEM_GAP + GEM_FLY
		if fx.t >= done then
			-- it melts: the splash in the ladle, the molten drop stays in it
			local x, y = bowl(fx)
			splash(fx, x, y - 2, 26)
			sound.play("#scaglia")
			fx.phase, fx.t = "shots", 0
			fx.pop_from = 1
			throws_row(a)
		end
	elseif fx.phase == "shots" then
		if fx.t >= (fx.poured and MELT + SHOTS or 0.1) then
			fx.phase, fx.t = "pan", 0
			local v = full_view()
			travel(fx, v, full_cam(v), PAN)
		end
	elseif fx.phase == "pan" then
		if moved then
			-- the hint, the first time
			if f.colate <= 2 and f.lanci == 0 and not fx.hint then
				fx.hint = empty(fx.hud, 640, (screen.y0 or 0) + 40)
				local g = { node = fx.hint, ox = 0, oy = 0 }
				-- with a controller, its stick and its SPARA button
				local c = controller.current_value
				local hint = c and c.connected and T.hint_pad:format(controller.name_of("spara") or "")
					or (SP.on() and T.hint_stick) or T.hint
				kit.text(g, hint, 2, 2, 20, KC.INK, "middle", 0.5)
				kit.text(g, hint, 0, 0, 20, KC.SAND, "middle", 0.5)
			end
			to_aim(a)
		end
	elseif fx.phase == "aim" then
		-- now and then the usurer of the bench says something
		fx.chat = (fx.chat or 3) - dt
		if fx.chat <= 0 then
			fx.chat = 6 + math.random() * 5
			say(fx, T.say_idle)
		end
		pad_aim(a)
		if fx.aiming or fx.pad or (fx.stick and fx.stick.id and fx.thumb_st.active) then draw_aim(a) end
	elseif fx.phase == "windup" then
		-- close on the apprentice: the throw clip starts (it ends with the drop away)
		if moved then
			fx.phase, fx.t = "swing", 0
			fx.lancio_n = (fx.lancio_n or 0) + 1
			fx.st.lancio = fx.lancio_n
			fx.release = release_time(scoria.throw_clip(fx.dev))
		end
	elseif fx.phase == "swing" then
		-- the ladle goes back, trembles full, and whips forward: the drop leaves
		if fx.t >= fx.release then
			launch(a)
		end
	elseif fx.phase == "fly" then
		local i = fx.t / game.DT + 1
		local n = #fx.path
		-- (a drop gone past the right edge or under the floor: no need to watch it fall)
		local q = fx.path[math.min(n, math.floor(i))]
		local qx = to_screen(fx, q[1], q[2])
		if fx.result.esito == "secchio" and (qx > screen.x1 + 30 or q[2] < FLOOR_TOP) then i = n end
		if i >= n then
			local q = fx.path[n]
			gui.set_position(fx.drop, vec(q[1], q[2]))
			land(a)
		else
			local i0 = math.floor(i)
			local q0, q1 = fx.path[i0], fx.path[i0 + 1]
			local k = i - i0
			local o = 1 - clamp(fx.t / JOIN)
			o = o * o
			gui.set_position(fx.drop, vec(lerp(q0[1], q1[1], k) + fx.off[1] * o, lerp(q0[2], q1[2], k) + fx.off[2] * o))
			-- on the iron it bounces (the rules' ball, forge.fly): a splash and a clang
			local hits = fx.path.hits
			fx.hit_i = fx.hit_i or 1
			if hits and hits[fx.hit_i] and i0 >= hits[fx.hit_i] then
				local h = fx.path[hits[fx.hit_i] + 1] or q0
				splash(fx, h[1], h[2], 22)
				sound.play("#martello")
				fx.hit_i = fx.hit_i + 1
			end
			-- on the back wall: a toc, and back
			local walls = fx.path.walls
			fx.wall_i = fx.wall_i or 1
			if walls and walls[fx.wall_i] and i0 >= walls[fx.wall_i] then
				sound.play("#toc")
				fx.shake = math.max(fx.shake or 0, SHAKE * 0.5)
				fx.wall_i = fx.wall_i + 1
			end
			-- the flake of fire heads where it goes, the tail behind
			local dx, dy = q1[1] - q0[1], q1[2] - q0[2]
			if dx ~= 0 or dy ~= 0 then gui.set_rotation(fx.drop, vmath.vector3(0, 0, math.deg(math.atan2(dy, dx)) + 180)) end
			-- a short trail of embers behind it: it reads on the dark forge
			fx.trail = (fx.trail or 0) - dt
			if fx.trail <= 0 then
				fx.trail = TRAIL_EVERY
				local e = piece(fx.splash, "goccia", lerp(q0[1], q1[1], k), lerp(q0[2], q1[2], k), DROP_W * 0.6)
				gui.animate(e, "size", vec(2, 2), gui.EASING_INQUAD, TRAIL_LIFE)
				gui.animate(e, "color.w", 0, gui.EASING_INQUAD, TRAIL_LIFE, 0, function() gui.delete_node(e) end)
			end
		end
	elseif fx.phase == "after" then
		if fx.bonus_at and fx.t >= fx.bonus_at then
			fx.bonus_at = nil
			shout(a, T.bonus, 420, KC.HOT, BONUS_T)
			fx.t = AFTER - BONUS_T
		end
		if fx.t >= AFTER + (fx.hold or 0) and not fx.bonus_at and not coins.busy(fx.purse) then
			fx.hold = nil
			if f.tiri > 0 then
				-- the next one: molten Ossidiana in the ladle again
				to_aim(a)
			else
				fx.phase, fx.t = "end", 0
			end
		end
	elseif fx.phase == "end" then
		if fx.t >= 0.5 then
			if fx.got then recap(a) else close(a); return true end
		end
	elseif fx.phase == "recap" then
		-- (waiting for COLA ANCORA or CHIUDI, M.input)
	elseif fx.phase == "close" then
		if moved then
			fx.phase = "vetrina"
		end
	end
	follow(a, dt)
	apply(fx)
	-- the molten drop rides the ladle while there is one to throw (after the camera:
	-- the bowl is read on the screen)
	local hot = (fx.phase == "aim" or fx.phase == "windup" or fx.phase == "swing" or fx.phase == "pan" or fx.phase == "shots")
		and f.tiri > 0
	gui.set_enabled(fx.molten, hot)
	if hot then
		local x, y = bowl(fx)
		gui.set_position(fx.molten, vec(x, y + 1))
	end
	if fx.rebuild then
		fx.rebuild = nil
		return true
	end
	return false
end

-- While playing every input is the forge's: the finger aims and throws
function M.input(a, action_id, action)
	local fx = a.fx
	if not fx or fx.phase == "vetrina" then return false end
	-- (INCASSA: the bench empties into the wallet, nothing to touch)
	if fx.phase == "pay" then return true end
	if fx.phase == "recap" then
		if action_id == ui.PAD and action.pressed then
			local c = controller.current_value
			if action.ui == "indietro" then recap_do(a, "close")
			elseif c and action.nome and action.nome == controller.key_of(c, "spara") then recap_do(a, fx.recap_btns and fx.recap_btns[1].cmd or "close") end
		elseif action_id == ui.TOUCH and action.released and fx.recap_btns and fx.t > 0.4 then
			local x, y = screen.from_touch(action.x, action.y)
			y = 720 - y
			for _, b in ipairs(fx.recap_btns) do
				if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then recap_do(a, b.cmd); break end
			end
		end
		return true
	end
	if action_id == ui.PAD then
		local c = controller.current_value
		if action.pressed and fx.phase == "aim" and fx.pad and c and action.nome
			and action.nome == controller.key_of(c, "spara") then
			-- SPARA with the stick lit: the aim from a moment earlier, as in battle
			fx.angle, fx.power = sticks.shot(fx.pad_st, fx.clock, fx.angle, fx.power)
			pad_off(fx)
			aim_off(fx)
			throw(a)
		elseif action.pressed and action.ui == "indietro" and fx.phase == "aim" and not fx.aiming and not fx.pad then
			-- the way back: out of the aim, back to the vetrina (the throws stay)
			close(a)
		end
		return true
	end
	if action_id ~= ui.TOUCH then return true end
	-- (a finger put down a moment before the aim comes back starts aiming then)
	if action.pressed then fx.finger = true elseif action.released then fx.finger = false end
	if fx.phase ~= "aim" then return true end
	local x, y = screen.from_touch(action.x, action.y)
	-- on the phone the aim stick on the right, as in battle (game.gui_script
	-- aim_pad_drag / aim_pad_release): lit past AIM_ON it aims, lifting the thumb throws
	local pad = fx.stick
	if pad and SP.on() then
		local st = fx.thumb_st
		if action.pressed and not pad.id and x > SP.ZONE.dx and y < SP.ZONE.y then
			if fx.hint then gui.set_enabled(fx.hint, false) end
			SP.press(pad, 0, x, y)
		end
		if not pad.id then return true end
		if action.released then
			local h = sticks.on_release(st, fx.clock)
			local fire = h and h.active or st.active
			if fire then fx.angle, fx.power = sticks.shot(st, fx.clock, fx.angle, fx.power) end
			pad_off(fx)
			aim_off(fx)
			if fire then throw(a) end
		else
			local was = st.active
			sticks.aim(st, SP.drag(pad, x, y))
			if st.active then
				fx.angle, fx.power = (fx.mir or 1) < 0 and math.pi - st.angle or st.angle, aim.stick_power(st.f)
				if not was then phone.tap() end
			elseif was then
				aim_off(fx)
			end
			sticks.record(st, fx.clock, fx.angle, fx.power, st.active)
			SP.color(pad, st.active and SP.AIM_LIVE or SP.AIM_IDLE)
		end
		return true
	end
	if action.pressed or (fx.finger and not fx.aiming) then
		fx.aiming = true
		if fx.hint then gui.set_enabled(fx.hint, false) end
		aim_at(a, x, y)
		if not fx.power then fx.angle, fx.power = fx.angle or math.rad(40), 0.1 end
	elseif action.released and fx.aiming then
		fx.aiming = false
		aim_at(a, x, y)
		aim_off(fx)
		if (fx.dist or 0) > aim.CANCEL_R then throw(a) end
	elseif fx.aiming then
		aim_at(a, x, y)
	end
	return true
end

-- A tap of the board. Returns true if it was one of its own
function M.cmd(a, kind, x)
	local p = a.prof
	if kind == "cola" then
		forge.init(p)
		if p.fornace.tiri > 0 then
			start(a, false)
		elseif profile.act(p, { k = "colata", muro = wall_key(p) }) then
			start(a, true)
		end
		return true
	elseif kind == "fondi" then
		local what, set = x:match("^(%a+):?(.*)$")
		if what == "apri" then
			a.melt = {}
		elseif what == "chiudi" then
			a.melt = nil
		elseif what == "da" then
			a.melt = { da = set }
		elseif what == "a" and a.melt then
			a.melt.a = set
		elseif what == "scaglie" and a.melt and a.melt.da then
			if profile.act(p, { k = "fondi", da = a.melt.da }) then sound.play("#scaglia") end
			if orders.fragments(p, a.melt.da) == 0 then a.melt = {} end
		elseif what == "famiglia" and a.melt and a.melt.da and a.melt.a then
			if profile.act(p, { k = "fondi", da = a.melt.da, a = a.melt.a }) then sound.play("#scaglia") end
			if orders.fragments(p, a.melt.da) < forge.MELT_IN then a.melt.a = nil end
		end
		return true
	end
	return false
end

-- Is the forge playing (the board's taps and the way back wait)?
function M.playing(a)
	return a.fx ~= nil and a.fx.phase ~= "vetrina"
end

-- Is a pour on screen, from the zoom in to the zoom out (Sergio, 25 Nov: the
-- minigame at the screen's best, 90/120 Hz, like a match: main/phone.lua)
M.busy = false

-- leaving the FORNACE tab: the world goes; the paintings stay while in the BOTTEGA
-- (keep), so the tab opens without decoding them again
function M.release(a, keep)
	M.busy = false
	drop_world(a)
	a.melt = nil
	if keep then return end
	for id in pairs(a.forge_tex or {}) do gui.delete_texture(id) end
	a.forge_tex = nil
end

-- In the other BOTTEGA tabs: the paintings decoded one per frame before the FORNACE
-- tab opens (all three in one frame held Lua over 130 ms)
local PAINTINGS = { { "cielo", "cielo.jpg" }, { "lontano", "lontano.png" }, { "medio", "medio.png" } }
function M.warm(a)
	for _, q in ipairs(PAINTINGS) do
		if not (a.forge_tex and a.forge_tex["fornace_" .. q[1]]) then
			texture(a, q[1], q[2])
			return
		end
	end
end

return M
