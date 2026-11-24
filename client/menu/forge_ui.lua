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

-- the world: what the vetrina shows (x from -150 to 1590, the floor's slab at the
-- bottom), the whole wall while playing, close on the apprentice for the pour
local WALL_X, WALL_W = 720, 1660
local CLOSE = { x = 50, y = 36, s = 2.2 }
-- the paintings (client/paintings/fornace, tools/grafica/fornace.py): the sky
-- fixed behind the frame, the far and the middle layers in the world, a little
-- slower than it when the camera moves (the far one more)
-- slower than it when the camera moves (the far one more). Coming close (the pour)
-- they zoom only up to their own pixels (Codex's 1536 over their width, or what the
-- whole wall already shows): never enlarged, they stay as far as a backdrop, kept
-- covering the view (place_layer)
local FAR = { x = -264, y = -187, w = 2120, k = 0.6 }
local MID = { x = -172, y = -158, w = 1936, k = 0.3 }
local FLOOR_TOP, FLOOR_W = -132, 560
local LEDGE = { x = -90, y = 2, w = 150 }
local BUCKET = { x = forge.BUCKET_X, y = -150, w = 120 }
-- the moulds' plates by family (WB-093), the Scaglie ones in iron
local PLATE = { fabbro = "oro", corvo = "azzurro", fornace = "arancio", leviatano = "verde", vuoto = "viola" }
-- the image is a little wider than the mould (the rings), its rim at RIM x width
-- above its bottom (the rules' depth, 0.78)
local IMG_W, RIM = 1.05, 0.79
local CHAIN_W, CHAIN_TOP = 10, 1000
-- the prize tags over the moulds: always this big on the screen
local TAG = 17
-- the drop as drawn (the rules' one is forge.DROP_R)
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
local JACKPOT_T = 2.4  -- how long the jackpot holds the next step
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

-- the wall the player sees now: the one of his throws if some are left, else today's
local function wall_key(p)
	forge.init(p)
	local f = p.fornace
	if f.tiri > 0 and f.muro ~= "" then return f.muro end
	return forge.key(profile.today(p), (day_clock()))
end

-- "3:12:05" to the next wall
local function until_next()
	local _, now = day_clock()
	local next_at = (math.floor(now / (forge.SHIFT_HOURS * 3600)) + 1) * forge.SHIFT_HOURS * 3600
	local left = math.max(0, next_at - now)
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

local function mould_name(m, full)
	return "stampo_" .. (m.small and "piccoli" or "grandi") .. "_" .. (full and "pieni" or "vuoti") .. "_"
		.. (m.set and PLATE[m.set] or "ferro")
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
	local s = math.min(v.w / 1840, v.h / 860)
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
	gui.set_position(node, vec(c.x + (left - v.cx) / c.s, c.y + (bottom - v.cy) / c.s))
	gui.set_scale(node, vmath.vector3(z, z, 1))
end

local function apply(fx)
	local v, c = fx.view, fx.cam
	gui.set_position(fx.clip, vec(v.cx, v.cy))
	gui.set_size(fx.clip, vec(v.w, v.h))
	local k = math.max(v.w / fx.sky_w, v.h / fx.sky_h)
	gui.set_size(fx.sky, vec(fx.sky_w * k, fx.sky_h * k))
	gui.set_position(fx.world, vec(-c.x * c.s + (fx.sx or 0), -c.y * c.s + (fx.sy or 0)))
	gui.set_scale(fx.world, vmath.vector3(c.s, c.s, 1))
	local most = full_cam(v).s
	place_layer(fx, fx.far, FAR, most)
	place_layer(fx, fx.mid, MID, most)
	local ts = vmath.vector3(1 / c.s, 1 / c.s, 1)
	for _, t in pairs(fx.tags) do gui.set_scale(t, ts) end
end

-- a world point on the screen (game coordinates), and back
local function to_screen(fx, x, y)
	local v, c = fx.view, fx.cam
	return v.cx + (x - c.x) * c.s + (fx.sx or 0), v.cy + (y - c.y) * c.s + (fx.sy or 0)
end

local function to_world(fx, x, y)
	local v, c = fx.view, fx.cam
	return c.x + (x - v.cx - (fx.sx or 0)) / c.s, c.y + (y - v.cy - (fx.sy or 0)) / c.s
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

-- a prize tag: the coin or the family's fragment and the number, over the mould
local function tag(fx, m)
	local top = m.y - RIM * m.w + IMG_W * m.w * PIECES[mould_name(m, false)].h / PIECES[mould_name(m, false)].w
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

-- the sealed look of a taken mould (Sergio, 24 Nov, «coperchio sigillato»; the lid of
-- WB-094 to come): the empty drawing shaded and the prize stamped on the mouth
local SEALED = vmath.vector4(0.55, 0.5, 0.52, 1)
local function seal(fx, m)
	local n = fx.moulds[m.slot]
	if not n then return end
	gui.set_color(n, SEALED)
	if fx.seals[m.slot] then gui.delete_node(fx.seals[m.slot]) end
	local s = empty(fx.wall_root, m.x, m.y + m.w * 0.02)
	local g = { node = s, ox = 0, oy = 0 }
	kit.piece(g, m.scaglie and "scaglia" or "frammento_" .. m.set, 0, 0, m.w * 0.42)
	fx.seals[m.slot] = s
	return s
end

local function draw_mould(fx, m, full)
	local name = mould_name(m, false)
	if m.chain then
		local h = CHAIN_W * PIECES.catena.h / PIECES.catena.w
		local top_img = m.y - RIM * m.w + IMG_W * m.w * PIECES[name].h / PIECES[name].w
		local y = top_img - 6 * m.w / 78
		while y < CHAIN_TOP do
			piece(fx.chains, "catena", m.x, y, CHAIN_W, gui.PIVOT_S)
			y = y + h - 1
		end
	end
	fx.moulds[m.slot] = piece(fx.wall_root, name, m.x, m.y - RIM * m.w, m.w * IMG_W, gui.PIVOT_S)
	if full then seal(fx, m) else tag(fx, m) end
end

-- fills a mould on the wall (a hit): the full drawing, a pop, the tag goes
local function fill_mould(fx, m)
	local n = fx.moulds[m.slot]
	if not n then return end
	gui.set_scale(n, vmath.vector3(1.3, 0.75, 1))
	gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.35)
	-- the seal comes down on the mouth a moment later, with a bounce
	local s = seal(fx, m)
	gui.set_scale(s, vmath.vector3(2.2, 2.2, 1))
	gui.set_color(s, vmath.vector4(1, 1, 1, 0))
	gui.animate(s, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBOUNCE, 0.4, 0.45)
	gui.animate(s, "color.w", 1, gui.EASING_LINEAR, 0.12, 0.45)
	if fx.tags[m.slot] then
		gui.delete_node(fx.tags[m.slot])
		fx.tags[m.slot] = nil
	end
end

local function make_world(a)
	local p = a.prof
	local fx = a.fx or {}
	a.fx = fx
	fx.phase = fx.phase or "vetrina"
	fx.tags, fx.moulds, fx.seals = {}, {}, {}
	fx.top = empty(nil, 0, 0)
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
	-- the floor's slab, and the dark under it
	local fh = FLOOR_W * PIECES.pavimento.h / PIECES.pavimento.w
	local under = box(fx.world, WALL_X, FLOOR_TOP - fh + 2 - 1500, 6000, 3000)
	gui.set_color(under, BELOW)
	for x = -900, 2600, FLOOR_W - 4 do piece(fx.world, "pavimento", x, FLOOR_TOP, FLOOR_W, gui.PIVOT_NW) end
	piece(fx.world, "secchio", BUCKET.x, BUCKET.y, BUCKET.w, gui.PIVOT_S)
	piece(fx.world, "sporgenza", LEDGE.x, LEDGE.y, LEDGE.w, gui.PIVOT_NW)
	-- the wall: chains behind the moulds, the tags on top of everything
	fx.chains = empty(fx.world)
	fx.wall_root = empty(fx.world)
	local key = wall_key(p)
	local f = p.fornace
	local full = key == f.muro and f.pieni or {}
	fx.key = key
	for _, m in ipairs(forge.wall(p, key)) do draw_mould(fx, m, full[m.slot]) end
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
	-- the molten Ossidiana in the ladle (after the pour), the drop, the aim
	fx.molten = piece(fx.world, "goccia", 0, 0, 9)
	gui.set_enabled(fx.molten, false)
	fx.drop = piece(fx.world, "goccia", 0, 0, DROP_W)
	gui.set_enabled(fx.drop, false)
	fx.aim = aim.new()
	fx.pad_st, fx.pad, fx.clock = sticks.new(), false, 0
	fx.thumb_st = sticks.new()
	for _, n in ipairs(fx.aim.nodi) do gui.set_parent(n, fx.world) end
	gui.set_parent(fx.aim.sign, fx.world)
	fx.splash = empty(fx.world)
	fx.tags_root = empty(fx.world)
	for _, m in ipairs(forge.wall(p, key)) do
		if fx.tags[m.slot] then gui.set_parent(fx.tags[m.slot], fx.tags_root) end
	end
	fx.view = frame_view()
	fx.cam = frame_cam(fx.view)
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

local function color_of(set)
	local c = equip.BY_ID[set].color
	return vmath.vector4(tonumber(c:sub(1, 2), 16) / 255, tonumber(c:sub(3, 4), 16) / 255, tonumber(c:sub(5, 6), 16) / 255, 1)
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
	for _, pz in ipairs(forge.PRIZES) do total = total + (pz.scaglie or 0) end
	kit.text(c, T.on_wall, ix, y + PAD + 18, 22, KC.HOT, "start", 1)
	fit(kit.text(c, kit.upper(T.filled:format(#forge.PRIZES - left, #forge.PRIZES)), ix, y + PAD + 42, 16, KC.MUTE, "start", 0.5), iw)
	kit.piece(c, "scaglia", ix + 17, y + 92, 34)
	kit.text(c, coins.format(sc), ix + 42, y + 102, 28, sc > 0 and KC.SAND or KC.MUTE, "start")
	kit.text(c, T.of_total:format(coins.format(total)), x + w - PAD, y + 102, 17, KC.MUTE, "end")
	kit.heading(c, T.fragments, ix, y + 146, KC.MUTE)
	for i, set in ipairs(equip.SETS) do
		local ry = y + 158 + (i - 1) * 38
		local n = fr[set.id] or 0
		local icon = kit.piece(c, "frammento_" .. set.id, ix + 15, ry + 17, 30)
		if n == 0 then gui.set_color(icon, DIM) end
		kit.text(c, set.name, ix + 38, ry + 24, 17, n > 0 and color_of(set.id) or KC.MUTE, "start", 0.5)
		kit.text(c, "x" .. n, x + w - PAD, ry + 25, 20, n > 0 and KC.SAND or KC.MUTE, "end")
	end
	kit.rect(c, ix, y + 368, iw, 2, KC.LINE)
	kit.heading(c, T.new_wall, ix, y + 400, KC.MUTE)
	a.fx.timer = kit.text(c, until_next(), ix, y + 444, 34, KC.SAND, "start")
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
	kit.text(paper, T.rule, PAPER.x + 24, PAPER.y + 46, 24, KC.INK, "start")
	fit(kit.text(paper, lucky and T.rule_lucky or T.rule_sub:format(forge.THROWS, forge.THROWS), PAPER.x + 24, PAPER.y + 76, 18,
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
local function shout(a, t, y, color, life)
	local fx = a.fx
	local n = empty(fx.hud, 640, y)
	local g = { node = n, ox = 0, oy = 0 }
	kit.text(g, t, 3, 4, 40, KC.INK, "middle", 1)
	kit.text(g, t, 0, 0, 40, color or KC.HOT, "middle", 1)
	gui.set_scale(n, vmath.vector3(0.3, 0.3, 1))
	gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3)
	gui.animate(n, "position.y", y + 30, gui.EASING_OUTQUAD, life, 0)
	gui.animate(n, "color.w", 0, gui.EASING_INQUAD, 0.3, life - 0.3, function() gui.delete_node(n) end)
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

local function start(a, poured)
	local fx = a.fx
	local p = a.prof
	fx.phase, fx.t = "open", 0
	fx.poured = poured
	fx.got = { scaglie = 0, fr = {}, hits = 0 }
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
	fx.row, fx.hint = nil, nil
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
	local wall = forge.layout(f.muro, f.seme, f.fortunato)
	local _, path = forge.fly(fx.angle, fx.power, wall, full, true)
	local r = profile.act(p, { k = "tiro", angolo = fx.angle, forza = fx.power })
	if not r then to_aim(a); return end
	fx.result, fx.path, fx.wall, fx.hit_i = r, path, wall, 1
	local got = fx.got
	if got then
		got.scaglie = got.scaglie + (r.scaglie or 0)
		if r.set then got.fr[r.set] = (got.fr[r.set] or 0) + r.n end
		if r.esito == "stampo" then got.hits = got.hits + 1 end
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

-- where the flight ended: the prize, the splash, the coins
local function land(a)
	local fx = a.fx
	local r = fx.result
	local last = fx.path[#fx.path]
	gui.set_enabled(fx.drop, false)
	fx.phase, fx.t = "after", 0
	fx.focus = nil
	if r.esito == "stampo" then
		local m = fx.wall[r.slot]
		fx.freeze, fx.shake = FREEZE, SHAKE
		fx.focus = { m.x, m.y }
		fill_mould(fx, m)
		-- the flame from the mouth (WB-094 to come): splashes rising one over the other
		fx.shake = SHAKE * 1.6
		for i = 0, 3 do
			local sp = piece(fx.splash, "schizzo", m.x, m.y, m.w * (1.3 - i * 0.18), gui.PIVOT_S)
			gui.set_color(sp, vmath.vector4(1, 1, 1, 0))
			local up = m.y + m.w * (0.5 + i * 0.75)
			gui.animate(sp, "color.w", 1, gui.EASING_LINEAR, 0.05, i * 0.06)
			gui.animate(sp, "position.y", up, gui.EASING_OUTQUAD, 0.35, i * 0.06)
			gui.animate(sp, "color.w", 0, gui.EASING_INQUAD, 0.3, 0.3 + i * 0.06, function() gui.delete_node(sp) end)
		end
		sound.play("#martello")
		if r.jackpot then
			-- the whole wall filled: JACKPOT, a rain of Scaglie, the medal the first time
			fx.hold = JACKPOT_T
			fx.shake = SHAKE * 3
			shout(a, T.jackpot, 470, KC.HOT, JACKPOT_T)
			if r.medal then shout(a, T.medal, 400, KC.SAND, JACKPOT_T) end
			local cx = (screen.x0 + screen.x1) / 2
			coins.fly(fx.purse, "scaglia", in_purse(fx, cx, 520), 14, r.jackpot,
				function(i) if i % 4 == 1 then sound.play("#scaglia") end end)
		end
		local sx, sy = to_screen(fx, m.x, m.y + m.w * 0.6)
		if r.scaglie then
			coins.fly(fx.purse, "scaglia", in_purse(fx, sx, sy), math.min(10, math.max(3, math.floor(r.scaglie / 8))), r.scaglie,
				function(i) if i == 1 then sound.play("#scaglia") end end)
		else
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
		if r.lucky then shout(a, T.lucky_hit, 470, KC.HOT, 1.1) end
	else
		missed(a, last[1], last[2])
		return
	end
	after_throw(a)
end

-- a drop that missed: its splash, and the bucket pays MISS
missed = function(a, x, y)
	local fx = a.fx
	local r = fx.result
	if y > forge.FLOOR + 10 then splash(fx, x, y - 6, 40) else splash(fx, x, FLOOR_TOP, 50) end
	fx.phase, fx.t = "after", 0
	local bx, by = to_screen(fx, BUCKET.x, BUCKET.y + BUCKET.w * 0.9)
	coins.fly(fx.purse, "scaglia", in_purse(fx, bx, by), 3, r.scaglie or forge.MISS)
	local n = empty(fx.hud, bx, by + 20)
	local g = { node = n, ox = 0, oy = 0 }
	kit.text(g, T.miss, 2, 2, 20, KC.INK, "middle", 1)
	kit.text(g, T.miss, 0, 0, 20, KC.MUTE, "middle", 1)
	gui.animate(n, "position.y", by + 70, gui.EASING_OUTQUAD, 1)
	gui.animate(n, "color.w", 0, gui.EASING_INQUAD, 0.3, 0.7, function() gui.delete_node(n) end)
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
-- la partita»): what the throws brought, row by row, then COLA ANCORA and CHIUDI
local RECAP_W, RECAP_ROW = 480, 52
function recap(a)
	local fx, p = a.fx, a.prof
	local got = fx.got
	fx.phase, fx.t = "recap", 0
	if fx.stick then gui.set_enabled(fx.stick.base, false) end
	local rows = {}
	rows[#rows + 1] = { icon = "scaglia", label = T.recap_scaglie, value = "+" .. coins.format(got.scaglie), color = KC.SAND }
	for _, set in ipairs(equip.SETS) do
		local n = got.fr[set.id]
		if n then rows[#rows + 1] = { icon = "frammento_" .. set.id, label = T.recap_fragments:format(set.name), value = "+" .. n, color = color_of(set.id) } end
	end
	if got.bonus then rows[#rows + 1] = { icon = "goccia_hud", label = T.recap_bonus, value = "", color = KC.HOT } end
	if got.jackpot then rows[#rows + 1] = { icon = "scaglia", label = T.recap_jackpot, value = "+" .. coins.format(got.jackpot), color = KC.HOT } end
	if got.medal then rows[#rows + 1] = { label = T.medal, value = "", color = KC.HOT } end
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
		if r.icon and r.icon ~= "goccia_hud" then kit.piece(rg, r.icon, x0 + 52, y, 34) end
		if r.icon == "goccia_hud" then piece(row, "goccia", x0 + 52, 720 - y, 30) end
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
	kit.secondary(g, T.recap_again, x0 + 28, by, bw, bh, { main = true, off = not can, icon = "gemma" })
	kit.secondary(g, T.recap_close, x0 + 44 + bw, by, bw, bh)
	fx.recap_btns = { { x = x0 + 28, y = by, w = bw, h = bh, cmd = can and "again" or nil }, { x = x0 + 44 + bw, y = by, w = bw, h = bh, cmd = "close" } }
	gui.set_scale(root, vmath.vector3(0.9, 0.9, 1))
	gui.animate(root, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3)
	gui.move_above(fx.hud, nil)
end

local function recap_do(a, what)
	local fx = a.fx
	if not what then return end
	fx.recap_btns = nil
	if fx.recap then gui.delete_node(fx.recap); fx.recap = nil end
	if what == "again" then fx.again = true end
	close(a)
end

-- an angle and power that fill the nearest empty mould (the simulator's sure aim)
local function sure_aim(p)
	local f = p.fornace
	local wall = forge.layout(f.muro, f.seme, f.fortunato)
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
	local an, d, pw = aim.from_finger(x - cx, y - cy, 1)
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
		fx.angle, fx.power = st.angle, aim.stick_power(st.f)
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
	-- the dots over the first part of the flight
	local p = a.prof
	local f = p.fornace
	local wall = forge.layout(f.muro, f.seme, f.fortunato)
	local _, path = forge.fly(fx.angle, fx.power, wall, f.pieni, true)
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
	elseif fx.phase == "after" and fx.focus and fx.t < AFTER then
		tx, ty, ts = lerp(base.x, fx.focus[1], 0.3), lerp(base.y, fx.focus[2], 0.3), base.s * 1.2
	end
	local k = 1 - math.exp(-dt * ease)
	local c = fx.cam
	fx.cam = { x = c.x + (tx - c.x) * k, y = c.y + (ty - c.y) * k, s = math.exp(math.log(c.s) + (math.log(ts) - math.log(c.s)) * k) }
end

-- Every frame: true when the armory must be made again
function M.update(a, dt)
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
				fx.phase, fx.t = "gems", 0
				fx.gems = {}
				for i = 1, forge.COST do
					fx.gems[i] = { node = kit.piece({ node = fx.hud, ox = 0, oy = 0 }, "gemma", 0, 0, 40) }
					gui.set_enabled(fx.gems[i].node, false)
				end
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
			gui.set_rotation(fx.drop, vmath.vector3(0, 0, fx.t * 400))
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
			-- COLA ANCORA from the recap: the next pour, as the button of the vetrina
			if fx.again then
				fx.again = nil
				M.cmd(a, "cola")
				return true
			end
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
				fx.angle, fx.power = st.angle, aim.stick_power(st.f)
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

function M.release(a)
	drop_world(a)
	a.melt = nil
	for id in pairs(a.forge_tex or {}) do gui.delete_texture(id) end
	a.forge_tex = nil
end

return M
