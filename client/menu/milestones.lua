-- Player stats and their badges (docs/roadmap.md, "Statistiche, obiettivi e
-- badge"; character sheet, Sergio 31 Oct). Pure Lua: the profile counts them
-- at the end of the match (menu/profile.lua, menu/tally.lua), the STATISTICHE
-- tab shows them (menu/profile_tabs.lua), the tag carries the badges
-- (ui/tag_card.lua).
--
-- Each stat with a badge has thresholds growing tenfold (10, 100, 1,000,
-- 10,000): each threshold passed is a badge grade (I..IV). The badge has a
-- shape (which stat) and the grade's color.

local T = require("lang.text").milestones

local M = {}

-- The stats, in the tab's order. id: the key in the profile; nome: how it
-- reads; badge: the badge's name (nil: none); forma: cerchio, rombo, esagono
-- or stella; thresholds: the grades; record: keep the max, not the sum.
M.WHITELIST = {
	{ id = "nel_vuoto", nome = T.names.nel_vuoto, badge = T.badges.nel_vuoto, forma = "rombo", thresholds = { 10, 100, 1000, 10000 } },
	{ id = "abbattuti", nome = T.names.abbattuti, badge = T.badges.abbattuti, forma = "esagono", thresholds = { 10, 100, 1000, 10000 } },
	{ id = "a_segno", nome = T.names.a_segno, badge = T.badges.a_segno, forma = "cerchio", thresholds = { 10, 100, 1000, 10000 } },
	{ id = "danno", nome = T.names.danno, badge = T.badges.danno, forma = "stella", thresholds = { 1000, 10000, 100000, 1000000 } },
	{ id = "globi", nome = T.names.globi, badge = T.badges.globi, forma = "esagono", thresholds = { 10, 100, 1000, 10000 } },
	{ id = "colpo_lungo", nome = T.names.colpo_lungo, badge = T.badges.colpo_lungo, forma = "stella", thresholds = { 600, 900, 1200, 1500 },
		record = true, unit = "px" },
	{ id = "casse", nome = T.names.casse, badge = T.badges.casse, forma = "cerchio", thresholds = { 10, 100, 1000, 10000 } },
	{ id = "vinte", nome = T.names.vinte, badge = T.badges.vinte, forma = "rombo", thresholds = { 10, 100, 1000, 10000 } },
	{ id = "cadute", nome = T.names.cadute },
}
M.BY_ID = {}
for _, s in ipairs(M.WHITELIST) do M.BY_ID[s.id] = s end

-- The other entries counted (at the top of the tab, or to compute others)
M.OTHERS = { "partite", "serie", "colpi", "morti", "teletrasporti" }

-- how many badges show next to the name
M.SHOWN = 3

-- badge grade for value v (0: none)
function M.grado(s, v)
	local g = 0
	for i, threshold in ipairs(s.thresholds or {}) do
		if (v or 0) >= threshold then g = i end
	end
	return g
end

-- the next threshold and how far off it is, from 0 to 1 (from the previous threshold)
function M.prossima(s, v)
	v = v or 0
	local first_one = 0
	for _, threshold in ipairs(s.thresholds or {}) do
		if v < threshold then return threshold, math.max(0, (v - first_one) / (threshold - first_one)) end
		first_one = threshold
	end
	return nil, 1
end

-- The badges earned with those values, from the highest grade (same grade in
-- list order): { { id, grade }, ... }
function M.presi(values)
	local out = {}
	for i, s in ipairs(M.WHITELIST) do
		local g = M.grado(s, values[s.id])
		if g > 0 then out[#out + 1] = { id = s.id, grado = g, i = i } end
	end
	table.sort(out, function(a, b)
		if a.grado ~= b.grado then return a.grado > b.grado end
		return a.i < b.i
	end)
	for _, b in ipairs(out) do b.i = nil end
	return out
end

-- The badges to show: the chosen ones (still earned), then the highest, up to SHOWN
function M.shown(values, picked_ones)
	local taken = M.presi(values)
	local by_id = {}
	for _, b in ipairs(taken) do by_id[b.id] = b end
	local out, placed = {}, {}
	for _, id in ipairs(picked_ones or {}) do
		if by_id[id] and not placed[id] and #out < M.SHOWN then
			out[#out + 1] = by_id[id]
			placed[id] = true
		end
	end
	for _, b in ipairs(taken) do
		if #out >= M.SHOWN then break end
		if not placed[b.id] then
			out[#out + 1] = b
			placed[b.id] = true
		end
	end
	return out
end

-- A badge arriving from outside (online, from the others): valid or nil
function M.valid(b)
	if type(b) ~= "table" then return nil end
	local s = M.BY_ID[b.id]
	local g = tonumber(b.grado)
	if not (s and s.thresholds and g and g >= 1 and g <= #s.thresholds and g % 1 == 0) then return nil end
	return { id = b.id, grado = g }
end

return M
