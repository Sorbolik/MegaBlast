-- The SIGILLI tab of the profile (menu/profile_tabs.lua; Sergio, 10 Nov:
-- everything that is yours in one place). Three bars, one per path of
-- sim/skills.lua: a point goes in with +, comes out with -, and on the bar a
-- disc every STEP points is a threshold: gold when its power is chosen (the
-- name under it), a gold ring when it is reached but still to choose. Tapping a
-- disc opens it in the panel on the right with its two powers: tapping one
-- chooses it (even before reaching it: it counts once the bar gets there) and
-- PORTA QUI moves the bar up to it. At the top the points and the loadouts
-- (the 2nd and 3rd open at the levels of loadout.LOADOUT_LEVELS), at the bottom
-- what changes in a match.
--
--   seals.build(s, parent)        -- s: the profile screen (prof, buttons, sel)
--   seals.run(s, kind, x, y) -> true if the action was its own (then rebuild)

local ui = require "ui.ui"
local skills = require "sim.skills"
local loadout = require "sim.loadout"
local profile = require "menu.profile"
local T = require("lang.text").seals

local M = {}

local C = ui.C
local TOP = ui.BODY_TOP
-- the bars: from BAR_X0, BAR_W long; the rows' centers
M.BAR_X0, M.BAR_W = 220, 540
M.ROWS = { TOP - 110, TOP - 230, TOP - 350 }
M.PANEL_X, M.PANEL_W = 1085, 330
M.COLOR = { wings = C.PURPLE, armor = C.STEEL, forge = C.BRACE }

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function txt(t, x, y, scale, color, parent, pivot)
	local n = ui.testo(t, x, y, scale, color, parent)
	if pivot then gui.set_pivot(n, pivot) end
	return n
end

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, color)
	gui.set_parent(n, parent)
	return n
end

local function zone(s, x, y, w, h, ui_action, parent)
	local n = box(x, y, w, h, C.LIGHT, parent)
	gui.set_visible(n, false)
	local clear = vmath.vector4(C.LIGHT.x, C.LIGHT.y, C.LIGHT.z, 0)
	s.buttons[#s.buttons + 1] = { nodo = n, bordo = n, ui_action = ui_action, colore = clear, riposo = clear }
end

-- 7.2 -> "7,2", 8 -> "8"
local function number(v)
	local s = string.format("%.1f", v):gsub("%.0$", "")
	return (s:gsub("%.", ","))
end

local function tree(s)
	return profile.active_loadout(s.prof).tree
end

-- the threshold shown on the right: the chosen one, else the first to choose,
-- else the next one of the fullest path
local function selected(s)
	if s.sel then return s.sel[1], s.sel[2] end
	local t = tree(s)
	local path, k = skills.to_choose(t)
	if path then return path, k end
	local best = skills.PATHS[1]
	for _, p in ipairs(skills.PATHS) do
		if skills.spent(t, p.id) > skills.spent(t, best.id) then best = p end
	end
	return best.id, math.min(skills.STEPS, skills.reached(t, best.id) + 1)
end

local function row(s, i, p, parent)
	local t = tree(s)
	local y = M.ROWS[i]
	local col = M.COLOR[p.id] or C.TEXT
	local n = skills.spent(t, p.id)
	txt(p.name, ui.EDGE, y + 14, 1.1, col, parent, gui.PIVOT_W)
	txt(T.of:format(n, skills.PATH_MAX), ui.EDGE, y - 18, 0.7, C.OFF, parent, gui.PIVOT_W)
	-- the track and the fill
	box(M.BAR_X0 + M.BAR_W / 2, y, M.BAR_W, 10, C.SHADOW, parent)
	local fill = box(M.BAR_X0, y, M.BAR_W * n / skills.PATH_MAX, 10, col, parent)
	gui.set_pivot(fill, gui.PIVOT_W)
	local sp, sk = selected(s)
	for k = 1, skills.STEPS do
		local x = M.BAR_X0 + M.BAR_W * k * skills.STEP / skills.PATH_MAX
		local reached = n >= k * skills.STEP
		local pick = skills.pick(t, p.id, k)
		local d = k == skills.STEPS and 40 or 30
		if sp == p.id and sk == k then ui.alone(x, y, d * 2.2, vmath.vector4(1, 0.8, 0.25, 0.35), parent) end
		ui.disco(x, y, d, C.BOTTOM, parent)
		if reached and pick then
			ui.disco(x, y, d - 6, C.GOLD, parent)
			txt(string.upper(p.steps[k][pick].name), x, y - 34, 0.5, C.TEXT, parent)
		elseif reached then
			ui.ring_node(x, y, d - 4, 4, C.GOLD, parent)
			txt(T.choose, x, y - 34, 0.5, C.GOLD, parent)
		else
			ui.ring_node(x, y, d - 4, 2, C.LINE, parent)
			if pick then txt(string.upper(p.steps[k][pick].name), x, y - 34, 0.5, C.OFF, parent) end
		end
		zone(s, x, y, 56, 56, "soglia:" .. p.id .. ":" .. k, parent)
	end
	-- - and +
	local free = skills.points(s.prof.livello) - skills.spent(t)
	ui.button(s.buttons, M.BAR_X0 + M.BAR_W + 50, y, 52, 48, "-", "meno:" .. p.id,
		{ spento = n == 0 }, parent)
	ui.button(s.buttons, M.BAR_X0 + M.BAR_W + 110, y, 52, 48, "+", "piu:" .. p.id,
		{ spento = free <= 0 or n >= skills.PATH_MAX }, parent)
end

-- the right panel: the selected threshold and its two powers
local function panel(s, parent)
	local t = tree(s)
	local path, k = selected(s)
	local p = skills.BY_ID[path]
	local h = TOP - 60 - 110
	local pan = ui.pannello(M.PANEL_X, 110 + h / 2, M.PANEL_W, h, parent)
	local top = h / 2
	ui.titolo(T.threshold:format(p.name, k * skills.STEP), 0, top - 30, 0.5, M.COLOR[p.id] or C.TEXT, pan)
	local need = k * skills.STEP - skills.spent(t, path)
	local free = skills.points(s.prof.livello) - skills.spent(t)
	local status = need <= 0 and (skills.pick(t, path, k) and T.taken or T.choose_now)
		or (need == 1 and T.missing_one or T.missing):format(need)
	if need > free then status = T.missing_free:format(need, free) end
	txt(status, 0, top - 60, 0.6, need <= 0 and C.GOLD or C.OFF, pan)
	local pick = skills.pick(t, path, k)
	for w = 1, 2 do
		local pw = p.steps[k][w]
		local cy = top - 128 - (w - 1) * 108
		local b = ui.scheda(s.buttons, 0, cy, M.PANEL_W - 30, 98, "", "scegli:" .. path .. ":" .. k .. ":" .. w, pick == w, pan)
		ui.titolo(string.upper(pw.name), 0, 24, 0.5, pick == w and C.GOLD or C.TEXT, b)
		-- the description in at most two lines, cut at a space near the middle
		local d = pw.desc
		local a, z = d, nil
		if #d > 30 then
			local cut = d:find(" ", math.floor(#d / 2)) or #d
			a, z = d:sub(1, cut - 1), d:sub(cut + 1)
		end
		txt(a, 0, z and 0 or -8, 0.62, C.OFF, b)
		if z then txt(z, 0, -24, 0.62, C.OFF, b) end
	end
	if need > 0 then
		ui.button(s.buttons, 0, -top + 40, M.PANEL_W - 30, 56, T.bring_here, "porta:" .. path .. ":" .. k,
			{ spento = free < need }, pan)
	else
		txt(T.change_any_time, 0, -top + 40, 0.55, C.OFF, pan)
	end
end

-- at the bottom: what the Sigilli give in a match
local function summary(s, parent)
	local t = tree(s)
	local parts = {}
	for _, p in ipairs(skills.PATHS) do
		local n = skills.spent(t, p.id)
		if n > 0 then parts[#parts + 1] = p.name .. " " .. p.per_point_desc:format(number(n * skills.PER_POINT_SHOWN)) end
	end
	local names = {}
	for _, w in ipairs(skills.powers(t)) do names[#names + 1] = string.lower(w.power.name) end
	local w = M.PANEL_X - M.PANEL_W / 2 - ui.EDGE - 20
	local pan = ui.pannello(ui.EDGE + w / 2, 70, w, 80, parent)
	txt(T.in_match, -w / 2 + 18, 16, 0.6, C.OFF, pan, gui.PIVOT_W)
	txt(#parts > 0 and table.concat(parts, " · ") or T.nothing, -w / 2 + 140, 16, 0.6, C.TEXT, pan, gui.PIVOT_W)
	txt(#names > 0 and table.concat(names, " · ") or T.no_power, -w / 2 + 140, -16, 0.6, C.GOLD, pan, gui.PIVOT_W)
end

function M.build(s, parent)
	local t = tree(s)
	local p = s.prof
	local pts = skills.points(p.livello)
	local n = ui.titolo(T.points:format(skills.spent(t), pts), ui.EDGE, TOP - 22, 0.7, C.GOLD, parent)
	gui.set_pivot(n, gui.PIVOT_W)
	ui.button(s.buttons, 330, TOP - 22, 130, 44, T.reset, "azzera", { spento = skills.spent(t) == 0 }, parent)
	-- the loadouts: the closed ones say from which level
	txt(T.loadout, 470, TOP - 22, 0.65, C.OFF, parent, gui.PIVOT_W)
	local x = 590
	for i = 1, loadout.LOADOUTS do
		local open = loadout.open(i, p.livello)
		local w = open and 48 or 110
		local label = open and tostring(i) or T.locked:format(i, loadout.LOADOUT_LEVELS[i])
		ui.button(s.buttons, x + w / 2, TOP - 22, w, 44, label, "assetto:" .. i, { spento = not open }, parent)
		if open then ui.sheet_active(s.buttons[#s.buttons], p.is_active == i) end
		x = x + w + 10
	end
	for i, path in ipairs(skills.PATHS) do row(s, i, path, parent) end
	panel(s, parent)
	summary(s, parent)
end

-- the actions of the tab; true if it was one (the profile rebuilds the screen)
function M.run(s, kind, x)
	local t = tree(s)
	local pts = skills.points(s.prof.livello)
	local a, b, c = (x or ""):match("^([^:]*):?([^:]*):?(.*)$")
	if kind == "piu" then
		skills.move(t, a, 1, pts)
	elseif kind == "meno" then
		skills.move(t, a, -1, pts)
	elseif kind == "soglia" then
		s.sel = { a, tonumber(b) }
	elseif kind == "scegli" then
		skills.choose(t, a, tonumber(b), tonumber(c))
		s.sel = { a, tonumber(b) }
	elseif kind == "porta" then
		local k = tonumber(b)
		local need = k * skills.STEP - skills.spent(t, a)
		if need > 0 and skills.spent(t) + need <= pts then skills.move(t, a, need, pts) end
		s.sel = { a, k }
	elseif kind == "azzera" then
		for _, p in ipairs(skills.PATHS) do t[p.id] = nil end
	else
		return false
	end
	profile.salva(s.prof)
	return true
end

return M
