-- The ZAINO (Figma "RIORGANIZZAZIONE MENU · 14 nov", Consigliata/2 and /3;
-- Sergio, 14 Nov): it opens from the apprentice in the home. Two tabs:
--   INVENTARIO  on the left the loadouts of the pieces and the apprentice with
--               its four pieces labeled on it; in the middle every piece you
--               own as a slot, filtered by slot and by family; on the right the
--               stats (with "a → b" for the piece chosen); at the bottom the
--               piece chosen and INDOSSA
--   SIGILLI     the loadouts of the Sigilli (apart from the pieces'), the three
--               paths as bars with a disc at each threshold and its two powers
--               under it, across the whole width (phone-sized: Sergio, 15 Nov);
--               STATISTICHE opens the stats as a sheet in their place; SALVA
-- Rebuilt at every tap, like the armory.
--
--   local s = zaino.new(prof, tab, color)        -- tab: "inventario" (default) or "sigilli"
--   zaino.update(s, dt)
--   zaino.on_input(s, action_id, action) -> "indietro" or nil
--   zaino.destroy(s)

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local equip = require "sim.gear"
local skills = require "sim.skills"
local scoria = require "battle.scoria"
local profile = require "menu.profile"
local wallet = require "menu.wallet"
local gear_ui = require "menu.gear_ui"
local T = require("lang.text").backpack
local TG = require("lang.text").gear_ui
local TP = require("lang.text").pieces
local common = require("lang.text").common

local M = {}

local KC = kit.C
-- the paths of the Sigilli: their color and their bar (Figma: movement ice, defense mint, arsenal ember)
local PATH_LOOK = {
	wings = { KC.STEEL, "barra_gelo" },
	armor = { KC.MINT, "barra_chiara" },
	forge = { KC.HOT_BOTTOM, "barra_brace" },
}

local function copy(t)
	if type(t) ~= "table" then return t end
	local o = {}
	for k, v in pairs(t) do o[k] = copy(v) end
	return o
end

local function same(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return a == b end
	for k, v in pairs(a) do if not same(v, b[k]) then return false end end
	for k, v in pairs(b) do if a[k] == nil then return false end end
	return true
end

-- the pieces you own, family after family, slot after slot (the filters on)
local function owned(s)
	local out = {}
	for _, f in ipairs(equip.SETS) do
		for _, sl in ipairs(equip.SLOTS) do
			if wallet.owns(s.prof, f.id, sl.id) and (not s.slot or s.slot == sl.id) and (not s.family or s.family == f.id) then
				out[#out + 1] = { f.id, sl.id }
			end
		end
	end
	return out
end

-- INVENTARIO ------------------------------------------------------------------------

local function inventory(s)
	local p = s.prof
	local a = profile.active_loadout(p)
	gear_ui.loadouts(s, s.left, 36, 96, p.is_active, "assetto", T.loadout)
	gear_ui.devil(s, s.left, 250, 600, 360)
	gear_ui.worn(s, s.left, a, 250, 600, 360, 36, { 206, 308, 410, 512 }, 72, s.slot)

	-- the stats: with the piece chosen on, what changes; VEDI TUTTE opens all of them
	-- in the middle, in place of the pieces
	local items = owned(s)
	if not s.sel and items[1] then s.sel = items[1] end
	local a2
	if s.sel and a.gear[s.sel[2]] ~= s.sel[1] then
		a2 = copy(a)
		a2.gear[s.sel[2]] = s.sel[1]
	end
	local g = s.mid
	if s.sheet then
		gear_ui.sheet(s, g, a, a2, TG.back_to_pieces)
	else
		-- the filters: the slot, then the families
		local list = { { T.all, "filtro:" } }
		for _, sl in ipairs(equip.SLOTS) do list[#list + 1] = { sl.name, "filtro:" .. sl.id } end
		local active = 1
		for i, sl in ipairs(equip.SLOTS) do if s.slot == sl.id then active = i + 1 end end
		gear_ui.chips(s, g, 430, 100, list, active)

		-- the pieces, six in a row
		for i, it in ipairs(items) do
			if i > 24 then break end
			local c, r = (i - 1) % 6, math.floor((i - 1) / 6)
			local x, y = 430 + c * 100, 164 + r * 100
			local set, slot = it[1], it[2]
			gear_ui.slot(g, x, y, 86, { set = set, slot = slot, level = wallet.level(p, set, slot),
				worn = a.gear[slot] == set, sel = s.sel and s.sel[1] == set and s.sel[2] == slot })
			kit.zone(g, s.buttons, x - 6, y - 10, 98, 104, "pezzo:" .. set .. ":" .. slot)
		end
		if #items == 0 then
			kit.text(g, kit.upper(T.nothing), 730, 300, 18, KC.MUTE, "middle", 1)
		end
		-- under the pieces the families (big dots: a finger hits them)
		gear_ui.families(s, g, 1006 - 5 * 50, 558, s.family)
		gear_ui.stats_short(s, s.rt, 1040, 106, 210, a, a2)
	end

	-- the piece chosen, at the bottom, and INDOSSA
	if s.sel then
		local set, slot = s.sel[1], s.sel[2]
		local level = wallet.level(p, set, slot)
		gear_ui.slot(s.low, 140, 630, 64, { set = set, slot = slot })
		kit.text(s.low, gear_ui.name(set, slot), 220, 656, 28, KC.SAND)
		local tier = equip.tier(level)
		kit.foot_text(s.low, kit.upper(T.piece_line:format(level, gear_ui.ROMAN[tier], TP.grades[tier], gear_ui.effects(set, slot, level))),
			220, 688, 18, KC.MUTE, 720, 0.5)
		local worn = a.gear[slot] == set
		s.action = kit.action(s.right, T.wear, 980, 628, 276, 80, { size = 44, off = worn, sub = worn and kit.upper(T.worn) or nil })
		kit.button(s.buttons, s.action, "indossa", { main = true, spento = worn })
	end
end

-- SIGILLI ---------------------------------------------------------------------------

-- the area of the paths, and the bars in their rows
-- The Sigilli as in the proposal chosen by Sergio (15 Nov 22:48, "Sigilli A col
-- bivio"): the three paths as rows with − and +, a pip for every point (in
-- groups of five) and what one point gives; under them the open path runs left
-- to right, and at every step it forks: up to one power, down to the other, the
-- fire only in the branch chosen. Pieces of WB-062; the branches are drawn here
-- (Codex's ones are too wide for five steps in a row).
local SEAL_X, SEAL_W = 452, 790
local PIP_X, PIP = 660, 18
local BAR_X, BAR_W = PIP_X, 25 * PIP + 4 * 8
local ROW_Y, ROW_H = 146, 68
local STEP_W = 157
local LINE_Y = 478
local PIP_LOOK = { wings = "tacca_ali", armor = "tacca_corazza", forge = "tacca_fucina" }

local function seal_tree(s)
	return s.draft
end

-- a branch of the fork: from the node up (or down) and right to the power,
-- an ink line with the color inside, round at the bends
local function branch(g, x0, y0, y1, x1, color)
	for _, w in ipairs({ { 14, KC.INK }, { 8, color } }) do
		kit.line(g, x0, y0, x0, y1, w[1], w[2])
		kit.line(g, x0, y1, x1, y1, w[1], w[2])
		kit.dot(g, x0, y1, w[1], w[2])
	end
end

-- "+4.8%": what the points of a path give now (the end of its description)
local function gain(path, n)
	local tail = path.per_point_desc:match("(%S*%%s%S*)$") or "+%s"
	local v = string.format("%.1f", n * skills.PER_POINT_SHOWN):gsub("%.0$", "")
	return tail:format(v)
end

local function seals_tab(s)
	local p = s.prof
	local t = seal_tree(s)
	gear_ui.loadouts(s, s.left, 36, 96, p.seal_active or p.is_active, "sigilli", T.seal_loadout)
	gear_ui.devil(s, s.left, 250, 600, 360)
	local g = s.mid
	local a = profile.active_loadout(p)
	local changed = not same(t, a.tree)
	local a2 = changed and { gear = a.gear, tree = t, variant = a.variant } or nil
	local pts = skills.points(p.livello)
	local free = pts - skills.spent(t)
	if s.sheet then
		gear_ui.sheet(s, g, a, a2, T.back_to_seals)
	else
		kit.panel(kit.group(g, 846, 345).node, 824, 514)
		-- the free points, a flame each (spent: the grey flame), and how many are used
		local title = kit.text(g, T.free, 452, 126, 24, KC.HOT, "start", 1)
		local fx = 452 + kit.width(title) + 12
		for i = 1, math.min(free, 8) do
			kit.piece(g, "punto_libero", fx + (i - 1) * 26 + 11, 116, 30)
		end
		if free > 8 then kit.text(g, "+" .. (free - 8), fx + 8 * 26 + 4, 126, 20, KC.HOT, "start") end
		if free == 0 then kit.piece(g, "punto_speso", fx + 11, 116, 30) end
		kit.text(g, T.used:format(skills.spent(t), pts), fx + math.max(1, math.min(free, 8)) * 26 + (free > 8 and 40 or 10), 125, 18, KC.MUTE, "start")
		local sb = kit.card(g, 1242 - 216, 98, 216, 40, KC.ROSE)
		kit.text(sb.g, T.see_stats, 1242 - 108, 125, 19, KC.SAND, "middle")
		kit.button(s.buttons, sb, "foglio")
	end
	local open_path = s.path or skills.to_choose(t) or skills.PATHS[1].id
	for i, path in ipairs(not s.sheet and skills.PATHS or {}) do
		local look = PATH_LOOK[path.id] or { KC.SAND, "barra_chiara" }
		local y = ROW_Y + (i - 1) * ROW_H
		local on = path.id == open_path
		local v = skills.spent(t, path.id)
		if on then kit.card(g, 440, y, 808, 62, KC.ROSE, { sel = true }) end
		kit.text(g, path.name, 456, y + 26, 24, on and look[1] or kit.with_alpha(look[1], 0.75), "start", 1)
		kit.text(g, T.of:format(v, skills.PATH_MAX), 456, y + 52, 18, KC.SAND, "start")
		kit.zone(g, s.buttons, 440, y, 150, 62, "via:" .. path.id)
		-- − and +: one point at a time
		local can_less, can_more = skills.can_remove(t, path.id), skills.can_add(t, path.id, pts)
		kit.piece(g, can_less and "tasto_meno" or "tasto_meno_spento", 622, y + 24, 44)
		kit.zone(g, s.buttons, 596, y - 4, 54, 62, "meno:" .. path.id)
		kit.piece(g, can_more and "tasto_piu" or "tasto_piu_spento", 1218, y + 24, 44)
		kit.zone(g, s.buttons, 1190, y - 4, 58, 62, "piu:" .. path.id)
		-- a pip for every point, in groups of five (a tap on them puts that many)
		for k = 1, skills.PATH_MAX do
			local px = PIP_X + (k - 1) * PIP + math.floor((k - 1) / skills.STEP) * 8
			kit.piece(g, k <= v and PIP_LOOK[path.id] or "tacca_vuota", px + 8, y + 14, 20)
		end
		kit.zone(g, s.buttons, BAR_X - 6, y - 4, BAR_W + 12, 34, "barra:" .. path.id)
		kit.text(g, kit.upper(T.per_point:format(path.per_point_desc:format(gain(path, 1):match("[%d.]+")), gain(path, v))), PIP_X, y + 50, 16, KC.MUTE, "start", 0.5)
	end
	local path = not s.sheet and skills.BY_ID[open_path]
	if path then
		local v = skills.spent(t, path.id)
		local node_x = function(k) return SEAL_X + (k - 1) * STEP_W + 16 end
		-- the rail of the points: iron all along, lit as far as the points go
		local last = node_x(skills.STEPS)
		kit.strip(g, "bivio_binario_spento", 446, LINE_Y - 10, last - 446, 20)
		local lit = math.min(last, 446 + (node_x(1) - 446) * math.min(v, skills.STEP) / skills.STEP
			+ math.max(0, v - skills.STEP) / skills.STEP * STEP_W)
		if v > 0 then kit.strip(g, "bivio_binario_acceso", 446, LINE_Y - 10, math.max(30, lit - 446), 20) end
		for k = 1, skills.STEPS do
			local cx = node_x(k)
			local got = v >= k * skills.STEP
			local pick = skills.pick(t, path.id, k)
			local card_x = cx + 22
			for which = 1, 2 do
				local chosen = got and pick == which
				local cy = which == 1 and 416 or 540
				branch(g, cx, LINE_Y + (which == 1 and -12 or 12), cy, card_x + 8,
					chosen and KC.HOT_BOTTOM or got and KC.LINE or kit.hex("2b2530"))
				local look = chosen and "acceso" or got and "spento" or "chiuso"
				local card = kit.drawn_plate(g, "bivio_piastra_" .. look, card_x, cy - 44, 118, 88)
				local ink = chosen and KC.INK or got and (pick and kit.with_alpha(KC.SAND, 0.75) or KC.HOT_TOP)
					or kit.with_alpha(KC.MUTE, 0.8)
				local step = path.steps[k][which]
				local name = kit.upper(step.name)
				local cut = name:find(" ", math.floor(#name / 2) - 3, true) or name:find(" ", 1, true)
				local lines = { name }
				local probe = kit.text(card.g, name, 0, 0, 17, ink)
				if kit.width(probe) > 104 and cut then lines = { name:sub(1, cut - 1), name:sub(cut + 1) } end
				gui.delete_node(probe)
				local mid = card_x + 59
				local ty = cy + 6 - (#lines - 1) * 10
				for li, line in ipairs(lines) do
					local n = kit.text(g, line, mid, ty + (li - 1) * 20, 17, ink, "middle")
					local wide = kit.width(n)
					if wide > 104 then gui.set_scale(n, gui.get_scale(n) * (104 / wide)) end
				end
				if got then kit.zone(g, s.buttons, card_x, cy - 44, 118, 88, "potere:" .. path.id .. ":" .. k .. ":" .. which) end
			end
			kit.piece(g, got and "bivio_nodo_acceso" or "bivio_nodo_spento", cx, LINE_Y, 40)
			kit.text(g, tostring(k * skills.STEP), cx, LINE_Y + 7, 18, got and KC.INK or KC.SAND, "middle")
			if got and not pick then
				-- a step reached and not chosen yet
				local d = ui.disc(cx + 18 - g.ox, g.oy - (LINE_Y - 18), 20, KC.RED, g.node)
				gui.set_blend_mode(d, gui.BLEND_ALPHA)
				kit.text(g, "!", cx + 18, LINE_Y - 11, 16, KC.SAND, "middle")
			end
		end
	end
	-- at the bottom: the power you touched (or the first to choose), and the other one
	local fp, fk, fw = s.focus and s.focus[1], s.focus and s.focus[2], s.focus and s.focus[3]
	if not fp then fp, fk = skills.to_choose(t) end
	local fpath = fp and skills.BY_ID[fp]
	local room = 800
	if fpath then
		local pick = fw or skills.pick(t, fp, fk)
		local two = fpath.steps[fk]
		if pick then
			local other = two[3 - pick]
			-- (in the queue the lines go on two, left of the pill: all a little higher)
			local q = kit.in_queue and -10 or 0
			kit.text(s.low, kit.upper(two[pick].name), 140, 648 + q, 26, KC.SAND)
			local lines = kit.foot_text(s.low, kit.upper(T.step:format(fpath.name, fk * skills.STEP)) .. " · " .. kit.upper(two[pick].desc), 140, 676 + q, 18, KC.HOT_TOP, room, 0.5)
			kit.foot_text(s.low, kit.upper(T.other:format(other.name, other.desc)), 140, (#lines > 1 and 712 or 700) + q, 17, KC.MUTE, room, 0.5)
		else
			kit.foot_text(s.low, kit.upper(T.step:format(fpath.name, fk * skills.STEP)) .. " · " .. kit.upper(T.to_choose), 140, 660, 22, KC.HOT_TOP, room)
			kit.foot_text(s.low, kit.upper(two[1].name .. " · " .. two[1].desc .. "   /   " .. two[2].name .. " · " .. two[2].desc), 140, 690, 17, KC.MUTE, room, 0.5)
		end
	else
		kit.foot_text(s.low, kit.upper(T.pick_hint), 140, 674, 19, KC.MUTE, room, 0.5)
	end
	s.action = kit.action(s.right, T.save, 980, 628, 276, 80, { size = 48, off = not changed, sub = not changed and kit.upper(T.saved) or nil })
	kit.button(s.buttons, s.action, "salva", { main = true, spento = not changed })
end

-- Screen ----------------------------------------------------------------------------

local function build(s)
	if s.head then kit.header_delete(s.head) end
	for _, k in ipairs({ "left", "mid", "rt", "right", "low" }) do
		if s[k] then gui.delete_node(s[k].node) end
	end
	s.buttons, s.figure, s.action = {}, nil, nil
	local p = s.prof
	s.head = kit.header(s.buttons, T.title, KC.PURPLE, "indietro", common.home)
	s.wallet = coins.wallet(p.scaglie or 0, p.ossidiana or 0, kit.group(s.head.top_right, 1110, 44).node, 0, 0)
	coins.vouchers(s.wallet, p.buoni or 0)
	kit.tabs(s.head.top_left, s.buttons, 300, 28, { { T.tab_inventory, "scheda:inventario" }, { T.tab_seals, "scheda:sigilli" } },
		s.tab == "sigilli" and 2 or 1, KC.PURPLE, true)
	-- the left column sticks to the left edge, the stats to the right one, the rest in the middle
	s.left = kit.anchor(0, 0, gui.ANCHOR_LEFT)
	s.mid = kit.anchor(0, 0)
	s.rt = kit.anchor(1280, 0, gui.ANCHOR_RIGHT)
	s.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	s.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	if s.tab == "sigilli" then
		seals_tab(s)
	else
		inventory(s)
	end
end

function M.new(prof, tab, color)
	local s = { prof = prof, tab = tab or "inventario", colore = color or ui.C.SQUADRA[1] }
	s.draft = copy(profile.active_loadout(prof).tree or {})
	s.scene = kit.scene(250, 420, { accent = KC.PURPLE, bg = "zaino" })
	build(s)
	return s
end

function M.update(s, dt)
	if s.figure then scoria.update(s.figure, dt, s.st) end
end

-- what you wear shows at once on the apprentice here (and in every menu after)
local function dress(p)
	local a = profile.active_loadout(p)
	scoria.set_player(scoria.look_of(a.gear, profile.tier(p, a)))
end

local function run_cmd(s, ui_action)
	local kind, x = ui_action:match("^(%a+):?(.*)$")
	local p = s.prof
	local a, b = x:match("^([^:]*):?(.*)$")
	if kind == "scheda" then
		s.tab, s.sheet = x, nil
		s.draft = copy(profile.active_loadout(p).tree or {})
	elseif kind == "assetto" then
		p.is_active = tonumber(x)
		profile.save(p)
		dress(p)
	elseif kind == "sigilli" then
		p.seal_active = tonumber(x)
		profile.save(p)
		s.draft = copy(profile.active_loadout(p).tree or {})
	elseif kind == "filtro" then
		s.slot = x ~= "" and x or nil
	elseif kind == "posto" then
		s.slot = s.slot ~= x and x or nil
		s.sheet = nil
	elseif kind == "famiglia" then
		s.family = s.family ~= x and x or nil
	elseif kind == "pezzo" then
		s.sel = { a, b }
	elseif kind == "indossa" and s.sel then
		profile.active_loadout(p).gear[s.sel[2]] = s.sel[1]
		profile.save(p)
		dress(p)
	elseif kind == "barra" then
		-- where on the bar: that many points, as many as are free
		local t = s.draft
		local path = x
		local want = math.floor((s.tap_x - BAR_X) / BAR_W * skills.PATH_MAX + 0.5)
		if want >= skills.PATH_MAX - 0.5 then want = skills.PATH_MAX end
		s.path = path
		want = math.max(0, math.min(skills.PATH_MAX, want))
		skills.move(t, path, want - skills.spent(t, path), skills.points(p.livello))
	elseif kind == "via" then
		s.path = x
	elseif kind == "meno" or kind == "piu" then
		-- one point at a time (Sergio, 15 Nov: the points one by one)
		s.path = x
		skills.move(s.draft, x, kind == "piu" and 1 or -1, skills.points(p.livello))
	elseif kind == "potere" then
		-- a power under a step: it becomes that step's choice
		local k, which = b:match("^(%d+):(%d)$")
		k, which = tonumber(k), tonumber(which)
		if k and which then
			skills.choose(s.draft, a, k, which)
			s.focus = { a, k, which }
		end
	elseif kind == "foglio" then
		s.sheet = not s.sheet
	elseif kind == "salva" then
		local live = profile.active_loadout(p).tree
		for key in pairs(live) do live[key] = nil end
		for key, v in pairs(copy(s.draft)) do live[key] = v end
		profile.save(p)
	end
	build(s)
end

function M.on_input(s, action_id, action)
	local ui_action = ui.touch(s.buttons, action_id, action)
	if ui_action == "indietro" then return ui_action end
	if ui_action then
		-- the tap in the Figma's coordinates of the middle (for the bars)
		if action.screen_x then
			s.tap_x = gui.screen_to_local(s.mid.node, vmath.vector3(action.screen_x, action.screen_y, 0)).x
		else
			s.tap_x = action.x or 640
		end
		return run_cmd(s, ui_action)
	end
	return nil
end

function M.destroy(s)
	kit.header_delete(s.head)
	for _, k in ipairs({ "left", "mid", "rt", "right", "low" }) do
		if s[k] then gui.delete_node(s[k].node) end
	end
	kit.scene_drop(s.scene)
end

return M
