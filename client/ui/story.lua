-- The campaign's story (Sergio, 4 Nov, proposal B:
-- https://claude.ai/artifact/MRGtRcTEyXSAYEZP7kWgF8): a comic in five short
-- chapters, one for each turn of the story, each one panel after the other
-- with the lines in balloons written by the game (lang/it.lua, story.chapters).
-- A chapter comes once, at the first chance after its moment: the Prologue the
-- first time you open the CAMPAGNA, the others after (or before) their
-- mission. The panels are the WB-012 and WB-017 ones (JPEGs in
-- /paintings/story/, strumenti/grafica/illustrazioni.py): a panel not there
-- yet is skipped, a chapter without panels doesn't come. Client only, pure
-- Lua (tests/story_test.lua).
--
--   local story = require "ui.story"
--   local id = story.pending(profilo, mission_id)   -- the chapter to show now, or nil
--     (mission_id: the mission about to start; nil when opening the CAMPAGNA)
--   local pages = story.pages(id)       -- { { img, where, lines = { { chi, testo } } } }
--   story.seen(profilo, id)             -- it doesn't come again (then save the profile)
--   local pages = story.read_again(profilo)  -- every chapter already seen, in order

local T = require("lang.text").story

local M = {}

-- The chapters in story order. after: it comes once that mission is done
-- (its first star, «Fatta»); before: right before that mission starts.
-- Each page: the panel and where its balloons go, in the calm corner Codex
-- left for them ("tl" top left, "tr" top right, "t" top, "b" bottom)
M.CHAPTERS = {
	{ id = "prologo", pages = {
		{ "s_viaggio", "tl" }, { "4_arrivo_a", "tr" }, { "4_arrivo_b", "b" }, { "4_arrivo_c", "b" },
		{ "5_fabbro_a", "tr" }, { "5_fabbro_c_1", "t" },
	} },
	{ id = "forgia_aperta", after = "guidata", pages = { { "s_forgia_aperta", "tr" } } },
	{ id = "insieme", before = "battaglia_forgia", pages = { { "s_insieme", "tl" } } },
	-- the Forge done: the Fabbro's boots (the ARMERIA) and then the kidnapping
	-- (the gironi), together (Sergio, 4 Nov)
	{ id = "regalo", after = "battaglia_forgia", pages = { { "s_regalo", "tr" } } },
	{ id = "rapimento", after = "battaglia_forgia", pages = {
		{ "6_rapimento_a", "tl" }, { "6_rapimento_b", "t" }, { "6_rapimento_c", "t" }, { "s_ghiaccio", "t" },
	} },
}

-- The panels in the game (illustrazioni.py writes them: add the new ones here)
M.PANELS = {
	["4_arrivo_a"] = true, ["4_arrivo_b"] = true, ["4_arrivo_c"] = true, ["5_fabbro_a"] = true,
	["5_fabbro_c_1"] = true, ["6_rapimento_a"] = true, ["6_rapimento_b"] = true, ["6_rapimento_c"] = true,
}

local by_id = {}
for _, ch in ipairs(M.CHAPTERS) do by_id[ch.id] = ch end

-- the chapter's pages that have their panel, with their lines
function M.pages(id)
	local ch, out = by_id[id], {}
	if not ch then return out end
	local lines = T.chapters[id] or {}
	for _, pg in ipairs(ch.pages) do
		if M.PANELS[pg[1]] then
			local l = {}
			for i, line in ipairs(lines[pg[1]] or {}) do l[i] = { chi = line[1], testo = line[2] } end
			out[#out + 1] = { img = pg[1], where = pg[2], lines = l }
		end
	end
	return out
end

local function done(p, mission)
	local s = p.stelle and p.stelle[mission]
	return s ~= nil and s[1] == true
end

function M.pending(p, starting)
	local seen = p.storia or {}
	for _, ch in ipairs(M.CHAPTERS) do
		local due = (not ch.after and not ch.before)
			or (ch.after and done(p, ch.after))
			or (ch.before and ch.before == starting)
		if due and not seen[ch.id] and #M.pages(ch.id) > 0 then return ch.id end
	end
	return nil
end

function M.seen(p, id)
	p.storia = p.storia or {}
	p.storia[id] = true
end

function M.read_again(p)
	local out, seen = {}, p.storia or {}
	for _, ch in ipairs(M.CHAPTERS) do
		if seen[ch.id] then
			for _, pg in ipairs(M.pages(ch.id)) do out[#out + 1] = pg end
		end
	end
	return out
end

return M
