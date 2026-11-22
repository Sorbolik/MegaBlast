-- Where the player put the HUD's buttons on the phone (Sergio, 21 Nov: «voglio
-- un modo per spostare e ingrandire e rimpicciolire i tasti dell'hud»): a shift
-- and a size for each group, kept in the profile's settings (disposizione) and
-- changed in IMPOSTAZIONI > DISPOSIZIONE TASTI (menu/hud_editor.lua). Only on
-- the phone: the computer keeps its layout. The sticks are not here, they come
-- where the thumb touches.
--
--   local L = layout.load(profile.setting(p, "disposizione"))
--   x, y, s = layout.place(L, "teletrasporto", x, y, ax, ay)
--     (x, y) where the default puts it, (ax, ay) the group's center: the group
--     grows around it by s and moves by the shift
--   profile.set(p, "disposizione", layout.to_save(L))

local M = {}

-- (the names are ids: they are saved in the profile)
M.UNITS = { "primarie", "secondarie", "cronometro", "teletrasporto", "attrezzi", "oggetti", "zoom" }
M.MIN, M.MAX = 0.7, 1.5

local ONE = { x = 0, y = 0, s = 1 }

local function clamp(s)
	return math.max(M.MIN, math.min(M.MAX, s))
end
M.clamp = clamp

function M.load(saved)
	local L = {}
	for _, u in ipairs(M.UNITS) do
		local v = type(saved) == "table" and type(saved[u]) == "table" and saved[u] or ONE
		L[u] = { x = tonumber(v.x) or 0, y = tonumber(v.y) or 0, s = clamp(tonumber(v.s) or 1) }
	end
	return L
end

-- nil when everything is where the game puts it
function M.to_save(L)
	local t
	for _, u in ipairs(M.UNITS) do
		local v = L[u]
		if v.x ~= 0 or v.y ~= 0 or v.s ~= 1 then
			t = t or {}
			t[u] = { x = math.floor(v.x + 0.5), y = math.floor(v.y + 0.5), s = math.floor(v.s * 100 + 0.5) / 100 }
		end
	end
	return t
end

function M.reset(L)
	for _, u in ipairs(M.UNITS) do
		local v = L[u]
		v.x, v.y, v.s = 0, 0, 1
	end
end

function M.of(L, u)
	return L and L[u] or ONE
end

function M.place(L, u, x, y, ax, ay)
	local v = M.of(L, u)
	return ax + (x - ax) * v.s + v.x, ay + (y - ay) * v.s + v.y, v.s
end

return M
