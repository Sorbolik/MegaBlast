-- The game's texts in the player's language. For now there is only Italian
-- (lang/it.lua); another language will be one more file with the same keys.
-- Each module takes its own group:
--
--   local T = require("lang.text").pick
--   gui.set_text(node, T.ready)
--   gui.set_text(node, T.shots_many:format(n))   -- %s and %d where the numbers go
--
-- Texts shared by many screens are in the group common. A key that does not
-- exist is an error that names it (not an empty text on the screen);
-- tests/lang_test.lua checks every key the code uses, and that every text is used.

local texts = require "lang.it"

local function strict(t, path)
	return setmetatable(t, { __index = function(_, k)
		error("testo mancante: " .. path .. "." .. tostring(k), 2)
	end })
end

for name, group in pairs(texts) do strict(group, name) end
return strict(texts, "lang")
