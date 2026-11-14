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
local kit = require "ui.kit"
local skills = require "sim.skills"
local loadout = require "sim.loadout"
local profile = require "menu.profile"
local T = require("lang.text").seals

local M = {}

local C = ui.C
local KC = kit.C
local TOP = ui.BODY_TOP
-- the bars: from BAR_X0, BAR_W long; the rows' centers
M.BAR_X0, M.BAR_W = 220, 540
M.ROWS = { TOP - 110, TOP - 230, TOP - 350 }
M.PANEL_X, M.PANEL_W = 1085, 330
M.COLOR = { wings = KC.PURPLE, armor = KC.STEEL, forge = KC.HOT }

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function txt(t, x, y, scale, color, parent, pivot)
	local n = ui.text(t, x, y, scale, color, parent)
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

local function row(s, i, p)
	local g = s.kg
	local t = tree(s)
	local y, x = 240 + (i - 1) * 108, 440 + (i - 1) * 8
	local col = M.COLOR[p.id] or KC.SAND
	local n = skills.spent(t, p.id)
	local name = kit.text(g, p.name, x, y + 26, 32, col)
	local wide = kit.width(name)
	if wide > 126 then gui.set_scale(name, gui.get_scale(name) * (126 / wide)) end
	kit.text(g, T.of:format(n, skills.PATH_MAX), x + 2, y + 52, 16, KC.MUTE, "start", 1)
	kit.bar(g, x + 140, y + 21, 270, 14, n / skills.PATH_MAX, col)
	local sp, sk = selected(s)
	local names = {}
	for k = 1, skills.STEPS do
		local sx = x + 140 + 270 * k / skills.STEPS
		local reached = n >= k * skills.STEP
		local pick = skills.pick(t, p.id, k)
		local state = (sp == p.id and sk == k) and "cur" or (reached and pick) and "got" or "todo"
		-- reached but still to choose: its ring calls, in the action's color
		kit.seal(g, sx, y + 28, tostring(k * skills.STEP), state, (reached and not pick) and KC.HOT or col)
		if reached and pick then names[#names + 1] = string.upper(p.steps[k][pick].name) end
		kit.zone(g, s.buttons, sx - 29, y - 6, 58, 68, "soglia:" .. p.id .. ":" .. k)
	end
	kit.text(g, #names > 0 and table.concat(names, " · ") or string.upper(T.no_power), x + 142, y + 78, 14, KC.MUTE, "start", 1.2)
	local free = skills.points(s.prof.livello) - skills.spent(t)
	kit.stepper(g, s.buttons, x + 452, y, "meno:" .. p.id, "piu:" .. p.id, n == 0, free <= 0 or n >= skills.PATH_MAX)
end

-- on the right: the selected threshold, its two powers as cards and, as the
-- screen's action, PORTA QUI
local function panel(s)
	local g = s.kg
	local t = tree(s)
	local path, k = selected(s)
	local p = skills.BY_ID[path]
	local col = M.COLOR[p.id] or KC.SAND
	kit.heading(g, T.threshold:format(p.name, k * skills.STEP), 1070 + kit.air(), 190, col)
	local need = k * skills.STEP - skills.spent(t, path)
	local free = skills.points(s.prof.livello) - skills.spent(t)
	local status = need <= 0 and (skills.pick(t, path, k) and T.taken or T.choose_now)
		or (need == 1 and T.missing_one or T.missing):format(need)
	if need > free then status = T.missing_free:format(need, free) end
	kit.text(g, string.upper(status), 1070 + kit.air(), 212, 13, KC.MUTE, "start", 1)
	local pick = skills.pick(t, path, k)
	for w = 1, 2 do
		local pw = p.steps[k][w]
		local y = 226 + (w - 1) * 152
		local c = kit.card(g, 1056 + kit.air(), y, 196, 136, col, { sel = pick == w })
		kit.text(c.g, string.upper(pw.name), 1154 + kit.air(), y + 50, #pw.name > 13 and 18 or 23, KC.SAND, "middle")
		-- the description in at most two lines, cut at a space near the middle
		local d = pw.desc
		local a, z = d, nil
		if #d > 20 then
			local cut = d:find(" ", math.floor(#d / 2)) or #d
			a, z = d:sub(1, cut - 1), d:sub(cut + 1)
		end
		kit.text(c.g, string.upper(a), 1154 + kit.air(), y + 84, 13, KC.MUTE, "middle", 0.5)
		if z then kit.text(c.g, string.upper(z), 1154 + kit.air(), y + 104, 13, KC.MUTE, "middle", 0.5) end
		kit.zone(c.g, s.buttons, 1056 + kit.air(), y, 196, 136, "scegli:" .. path .. ":" .. k .. ":" .. w)
	end
	if need > 0 and free >= need then
		s.action = kit.action(s.right, T.bring_here, 930, 560, 270, 84, { size = 44 })
		kit.button(s.buttons, s.action, "porta:" .. path .. ":" .. k, { main = true })
	else
		s.action = kit.action(s.right, T.bring_here, 930, 560, 270, 84, { size = 44, off = true, sub = string.upper(status) })
	end
end

-- at the bottom: what the Sigilli give in a match
local function summary(s)
	local g = s.kg
	local t = tree(s)
	local parts = {}
	for _, p in ipairs(skills.PATHS) do
		local n = skills.spent(t, p.id)
		if n > 0 then parts[#parts + 1] = p.name .. " " .. p.per_point_desc:format(number(n * skills.PER_POINT_SHOWN)) end
	end
	kit.text(g, T.in_match, 444, 572, 15, KC.HOT_TOP, "start", 1.5)
	kit.text(g, string.upper(#parts > 0 and table.concat(parts, " · ") or T.nothing), 444, 596, 14, kit.with_alpha(KC.SAND, 0.9), "start", 0.5)
end

function M.build(s)
	local g = s.kg
	local t = tree(s)
	local p = s.prof
	local pts = skills.points(p.livello)
	local spent = skills.spent(t)
	local big = kit.text(g, tostring(spent), 440, 216, 44, KC.SAND)
	local wide = kit.width(big)
	kit.text(g, T.points_of:format(pts), 440 + wide + 8, 216, 20, KC.MUTE, "start", 1)
	if pts > spent then kit.text(g, T.free:format(pts - spent), 440 + wide + 10, 190, 14, KC.HOT_TOP, "start", 1.5) end
	local reset = kit.plate(g, 690, 172, 150, 54, KC.ROSE, { sk = 0, d = 5, piece = "piastrina" })
	kit.text(reset.g, T.reset, 765, 207, 20, kit.with_alpha(KC.SAND, spent == 0 and 0.4 or 0.9), "middle")
	kit.button(s.buttons, reset, "azzera", { spento = spent == 0 })
	for i, path in ipairs(skills.PATHS) do row(s, i, path) end
	panel(s)
	summary(s)
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
	profile.save(s.prof)
	return true
end

return M
