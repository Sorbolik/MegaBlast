-- The campaign's story (client/ui/story.lua): which chapter comes when, and
-- that every panel has its lines. Run from the repository root:
--   luajit tests/story_test.lua
package.path = "client/?.lua;" .. package.path

local story = require "ui.story"
local T = require("lang.text").story

local failures = 0
local function check(ok, what)
	if ok then print("ok   " .. what) else failures = failures + 1; print("FAIL " .. what) end
end

-- a new profile: the Prologue first, and only once
local p = { stelle = {} }
check(story.pending(p, nil) == "prologo", "la prima volta in CAMPAGNA arriva il Prologo")
check(story.pending(p, "primi_passi") == "prologo", "anche entrando dritti nella prima lezione")
story.seen(p, "prologo")
check(story.pending(p, nil) == nil, "il Prologo visto non torna")

-- the kidnapping once the Battle of the Forge is done (its panels are there)
p.stelle.battaglia_forgia = { false, true }
check(story.pending(p, nil) == nil, "senza la prima stella della Battaglia niente rapimento")
p.stelle.battaglia_forgia = { true, false, false }
check(story.pending(p, nil) == "rapimento", "vinta la Battaglia arriva il rapimento")
story.seen(p, "rapimento")
check(story.pending(p, nil) == nil, "il rapimento visto non torna")

-- a chapter whose panels aren't in the game yet doesn't come
local had = story.PANELS.s_insieme
story.PANELS.s_insieme = nil
check(story.pending(p, "battaglia_forgia") == nil, "un capitolo senza tavole non arriva")
story.PANELS.s_insieme = true
check(story.pending(p, "battaglia_forgia") == "insieme", "Insieme arriva prima della Battaglia")
check(story.pending(p, nil) == nil, "Insieme non arriva aprendo la CAMPAGNA")
story.PANELS.s_insieme = had

-- reading it again: the chapters seen, in order
local again = story.read_again(p)
check(#again == #story.pages("prologo") + #story.pages("rapimento"), "LA STORIA rilegge i capitoli visti")
check(again[1].img == story.pages("prologo")[1].img, "dal primo")

-- every panel of every chapter has its lines, and every line someone to say it
local WHO = { favilla = true, fabbro = true, apprendista = true, voce = true, didascalia = true }
for _, ch in ipairs(story.CHAPTERS) do
	for _, pg in ipairs(ch.pages) do
		local lines = (T.chapters[ch.id] or {})[pg[1]]
		check(lines and #lines > 0, ch.id .. "/" .. pg[1] .. " ha i suoi fumetti")
		for _, l in ipairs(lines or {}) do
			check(WHO[l[1]] and type(l[2]) == "string" and #l[2] > 0, ch.id .. "/" .. pg[1] .. ": " .. tostring(l[1]))
		end
		check(({ tl = true, tr = true, t = true, b = true })[pg[2]], ch.id .. "/" .. pg[1] .. " sa dove va il fumetto")
	end
end

-- the panels said to be there have their JPEG
for id in pairs(story.PANELS) do
	local f = io.open("client/paintings/story/" .. id .. ".jpg", "rb")
	check(f ~= nil, "c'è client/paintings/story/" .. id .. ".jpg")
	if f then f:close() end
end

if failures > 0 then print(failures .. " controlli falliti"); os.exit(1) end
