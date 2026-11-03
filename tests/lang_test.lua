-- The game's texts (client/lang/): every text the code asks for exists, and
-- every text is used somewhere. Run from the repository root:
--   luajit tests/lang_test.lua
package.path = "client/?.lua;" .. package.path

local it = require "lang.it"
local text = require "lang.text"

local failures = 0
local function check(ok, what)
	if ok then print("ok   " .. what) else failures = failures + 1; print("FAIL " .. what) end
end

-- the client's code files (not the sim: the server embeds it)
local files = {}
local p = io.popen("find client -name '*.lua' -o -name '*.gui_script' -o -name '*.script' | sort")
for f in p:lines() do
	if not f:match("^client/sim/") and not f:match("^client/lang/") then files[#files + 1] = f end
end
p:close()

-- local X = require("lang.text").group  ->  X.key must exist; group keys used
local used = {}
for group in pairs(it) do used[group] = {} end
for _, f in ipairs(files) do
	local h = io.open(f); local src = h:read("*a"); h:close()
	for var, group in src:gmatch('local%s+([%a_][%w_]*)%s*=%s*require%s*%(?%s*"lang%.text"%s*%)?%s*%.([%a_][%w_]*)') do
		check(it[group] ~= nil, f .. ": il gruppo " .. group .. " esiste")
		if it[group] then
			for key in src:gmatch("%f[%w_]" .. var .. "%.([%a_][%w_]*)") do
				if not used[group][key] then
					check(it[group][key] ~= nil, f .. ": " .. group .. "." .. key .. " esiste")
				end
				used[group][key] = true
			end
		end
	end
end
for group, keys in pairs(it) do
	for key in pairs(keys) do
		check(used[group][key], group .. "." .. key .. " si usa")
	end
end

-- a missing key is an error that names it
local ok, err = pcall(function() return text.common.no_such_text end)
check(not ok and tostring(err):find("common.no_such_text", 1, true), "un testo mancante è un errore col suo nome")

if failures > 0 then print(failures .. " controlli falliti"); os.exit(1) end
