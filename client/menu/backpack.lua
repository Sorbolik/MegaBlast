-- The ZAINO (Figma "RIORGANIZZAZIONE MENU · 14 nov", Consigliata/2 and /3;
-- Sergio, 14 Nov): it opens from the apprentice in the home. Two tabs:
--   INVENTARIO  on the left the loadouts of the pieces and the apprentice with
--               its four pieces labeled on it; in the middle every piece you
--               own as a slot, filtered by slot and by family; on the right the
--               stats (with "a → b" for the piece chosen); at the bottom the
--               piece chosen and INDOSSA
--   SIGILLI     the loadouts of the Sigilli (apart from the pieces'), the three
--               paths as bars with a disc at each threshold and the power
--               chosen under it, the stats, SALVA
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
	gear_ui.worn(s, s.left, a, 250, 600, 360, 36, { 196, 300, 404, 508 }, 72, s.slot)

	-- the filters: the slot, then the families
	local g = s.mid
	local list = { { T.all, "filtro:" } }
	for _, sl in ipairs(equip.SLOTS) do list[#list + 1] = { sl.name, "filtro:" .. sl.id } end
	local active = 1
	for i, sl in ipairs(equip.SLOTS) do if s.slot == sl.id then active = i + 1 end end
	local after = gear_ui.chips(s, g, 430, 104, list, active)
	gear_ui.families(s, g, math.max(870, after + 8), 104, s.family)

	-- the pieces, six in a row
	local items = owned(s)
	if not s.sel and items[1] then s.sel = items[1] end
	for i, it in ipairs(items) do
		if i > 24 then break end
		local c, r = (i - 1) % 6, math.floor((i - 1) / 6)
		local x, y = 430 + c * 100, 162 + r * 100
		local set, slot = it[1], it[2]
		gear_ui.slot(g, x, y, 86, { set = set, slot = slot, level = wallet.level(p, set, slot),
			worn = a.gear[slot] == set, sel = s.sel and s.sel[1] == set and s.sel[2] == slot })
		kit.zone(g, s.buttons, x - 6, y - 10, 98, 104, "pezzo:" .. set .. ":" .. slot)
	end
	if #items == 0 then
		kit.text(g, kit.upper(T.nothing), 730, 300, 18, KC.MUTE, "middle", 1)
	end
	kit.text(g, kit.upper(T.count:format(#items)), 430, 584, 13, KC.MUTE, "start", 1)

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
		kit.text(s.low, gear_ui.name(set, slot), 220, 657, 26, KC.SAND)
		local tier = equip.tier(level)
		local line = kit.text(s.low, kit.upper(T.piece_line:format(level, gear_ui.ROMAN[tier], TP.grades[tier], gear_ui.effects(set, slot, level))),
			220, 684, 14, KC.MUTE, "start", 0.5)
		local wide = kit.width(line)
		if wide > 520 then gui.set_scale(line, gui.get_scale(line) * (520 / wide)) end
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
	local pts = skills.points(p.livello)
	kit.text(g, T.points:format(skills.spent(t), pts), 470, 120, 18, KC.HOT, "start", 1)
	for i, path in ipairs(skills.PATHS) do
		local look = PATH_LOOK[path.id] or { KC.SAND, "barra_chiara" }
		local y, x, w = 170 + (i - 1) * 140, 470, 520
		local v = skills.spent(t, path.id)
		kit.text(g, path.name, x, y + 12, 22, look[1], "start", 1)
		kit.text(g, T.of:format(v, skills.PATH_MAX), x + w, y + 12, 16, KC.SAND, "end")
		kit.strip(g, "riga_scura", x, y + 24, w, 22)
		if v > 0 then
			local bar = kit.strip(g, look[2], x + 3, y + 27, math.max(22, (w - 6) * v / skills.PATH_MAX), 16)
			if look[2] == "barra_chiara" then kit.tint(bar.parts, look[1]) end
		end
		-- a tap on the bar puts the points there (as many as are free)
		kit.zone(g, s.buttons, x - 10, y + 14, w + 20, 40, "barra:" .. path.id)
		for k = 1, skills.STEPS do
			local cx = x + w * k * skills.STEP / skills.PATH_MAX - 18
			local got = v >= k * skills.STEP
			kit.pic(g, got and "tondo_oro" or "tondo_ferro", cx - 4, y + 12, 44, 44)
			kit.text(g, tostring(k * skills.STEP), cx + 18, y + 40, 15, got and KC.HOT_TOP or KC.SAND, "middle")
			local pick = skills.pick(t, path.id, k)
			local name = pick and kit.upper(path.steps[k][pick].name) or "—"
			local n = kit.text(g, name, cx + 18, y + 76, 12, got and KC.SAND or KC.MUTE, "middle", 0.5)
			local wide = kit.width(n)
			if wide > 98 then gui.set_scale(n, gui.get_scale(n) * (98 / wide)) end
			-- tapping a disc changes its power (the other of the two)
			kit.zone(g, s.buttons, cx - 8, y + 58, 52, 30, "potere:" .. path.id .. ":" .. k)
		end
	end
	local a = profile.active_loadout(p)
	local a2 = { gear = a.gear, tree = t, variant = a.variant }
	gear_ui.stats(s, s.rt, 1046, 104, 210, a, not same(t, a.tree) and a2 or nil)
	local changed = not same(t, a.tree)
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
	s.scene = kit.scene(250, 420, { accent = KC.PURPLE, bg = true })
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
		local want = math.floor((s.tap_x - 470) / 520 * skills.PATH_MAX + 0.5)
		want = math.max(0, math.min(skills.PATH_MAX, want))
		skills.move(t, path, want - skills.spent(t, path), skills.points(p.livello))
	elseif kind == "potere" then
		local k = tonumber(b)
		local now = skills.pick(s.draft, a, k)
		skills.choose(s.draft, a, k, now == 1 and 2 or 1)
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
