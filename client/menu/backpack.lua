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

	-- the filters: the slot, then the families
	local g = s.mid
	local list = { { T.all, "filtro:" } }
	for _, sl in ipairs(equip.SLOTS) do list[#list + 1] = { sl.name, "filtro:" .. sl.id } end
	local active = 1
	for i, sl in ipairs(equip.SLOTS) do if s.slot == sl.id then active = i + 1 end end
	gear_ui.chips(s, g, 430, 100, list, active)

	-- the pieces, six in a row
	local items = owned(s)
	if not s.sel and items[1] then s.sel = items[1] end
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
	-- under the pieces: how many, and the families (big dots: a finger hits them)
	kit.text(g, kit.upper(T.count:format(#items)), 430, 592, 18, KC.MUTE, "start", 1)
	gear_ui.families(s, g, 1030 - 5 * 50, 558, s.family)

	-- the stats: with the piece chosen on, what changes
	local a2
	if s.sel and a.gear[s.sel[2]] ~= s.sel[1] then
		a2 = copy(a)
		a2.gear[s.sel[2]] = s.sel[1]
	end
	gear_ui.stats(s, s.rt, 1046, 104, 210, a, a2)

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

local function seal_tree(s)
	return s.draft
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
	-- the stats are a sheet of their own here (the powers take the whole width, to be
	-- read and touched on a phone: Sergio, 15 Nov): a button opens and closes it
	local sb = kit.card(g, 1255 - 236, 100, 236, 48, KC.ROSE, { sel = s.sheet })
	kit.text(sb.g, s.sheet and T.back_to_seals or T.see_stats, 1255 - 118, 131, 19, KC.SAND, "middle")
	kit.button(s.buttons, sb, "foglio")
	if s.sheet then
		gear_ui.stats(s, g, 460, 110, 370, a, a2, { from = 1, to = gear_ui.STAT_ROWS })
		gear_ui.stats(s, g, 878, 110, 370, a, a2, { from = gear_ui.STAT_ROWS + 1, to = #gear_ui.STATS, title = false })
	else
		local pts = skills.points(p.livello)
		kit.text(g, T.points:format(skills.spent(t), pts), 452, 132, 24, KC.HOT, "start", 1)
	end
	for i, path in ipairs(not s.sheet and skills.PATHS or {}) do
		local look = PATH_LOOK[path.id] or { KC.SAND, "barra_chiara" }
		local y, x, w = 160 + (i - 1) * 148, 452, 730
		local v = skills.spent(t, path.id)
		local title = kit.text(g, path.name, x, y + 22, 26, look[1], "start", 1)
		kit.text(g, T.of:format(v, skills.PATH_MAX), x + kit.width(title) + 18, y + 22, 20, KC.SAND)
		kit.strip(g, "riga_scura", x, y + 34, w, 24)
		if v > 0 then
			local bar = kit.strip(g, look[2], x + 3, y + 37, math.max(22, (w - 6) * v / skills.PATH_MAX), 18)
			if look[2] == "barra_chiara" then kit.tint(bar.parts, look[1]) end
		end
		-- a tap on the bar puts the points there (as many as are free)
		kit.zone(g, s.buttons, x - 10, y + 18, w + 20, 54, "barra:" .. path.id)
		-- every step is a fork: its two powers always in sight under the disc, the
		-- chosen one with the ember rim, the other plain; a tap on the other takes it (Sergio, 15 Nov)
		for k = 1, skills.STEPS do
			local cx = x + w * k * skills.STEP / skills.PATH_MAX
			local got = v >= k * skills.STEP
			local pick = skills.pick(t, path.id, k)
			kit.pic(g, got and "tondo_oro" or "tondo_ferro", cx - 26, y + 20, 52, 52)
			kit.text(g, tostring(k * skills.STEP), cx, y + 53, 19, got and KC.HOT_TOP or KC.SAND, "middle")
			if got and not pick then
				-- a step reached and not chosen yet
				local d = ui.disc(cx + 22 - g.ox, g.oy - (y + 24), 22, KC.RED, g.node)
				gui.set_blend_mode(d, gui.BLEND_ALPHA)
				kit.text(g, "!", cx + 22, y + 31, 18, KC.SAND, "middle")
			end
			for which = 1, 2 do
				local on = pick == which
				local cy = y + 76 + (which - 1) * 35
				local cw = 138
				local chip = kit.card(g, cx - cw / 2, cy, cw, 32, KC.ROSE, { sel = on })
				local ink = on and KC.SAND or (got and not pick and KC.HOT_TOP) or (got and KC.MUTE) or kit.with_alpha(KC.MUTE, 0.55)
				local n = kit.text(chip.g, kit.upper(path.steps[k][which].name), cx, cy + 22, 16, ink, "middle", 0.4)
				local wide = kit.width(n)
				if wide > cw - 14 then gui.set_scale(n, gui.get_scale(n) * ((cw - 14) / wide)) end
				kit.button(s.buttons, chip, "potere:" .. path.id .. ":" .. k .. ":" .. which)
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
		s.tab = x
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
		local want = math.floor((s.tap_x - 452) / 730 * skills.PATH_MAX + 0.5)
		want = math.max(0, math.min(skills.PATH_MAX, want))
		skills.move(t, path, want - skills.spent(t, path), skills.points(p.livello))
	elseif kind == "potere" then
		-- a power under a step: it becomes that step's choice
		local k, which = b:match("^(%d+):(%d)$")
		k, which = tonumber(k), tonumber(which)
		if k and which then
			skills.choose(s.draft, a, k, which)
			s.focus = { a, k, which }
		end
	elseif kind == "statistiche" then
		s.stat_page = (s.stat_page or 1) % 2 + 1
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
