-- Sends the recipe of a training match played on this phone to
-- the server, which replays it and writes in its log whether it came out the
-- same (server/recipe.go). Guest profiles plan, PR 1: it measures whether a
-- match is identical on the phone and on the server; nothing waits for the
-- answer and nothing changes in the game if the server isn't there.

local replay = require "sim.replay"

local M = {}

-- ws://host/ws -> http://host/ricetta (wss -> https)
function M.url(ws_url)
	local u = ws_url:gsub("^ws", "http")
	return (u:gsub("/ws$", "")) .. "/ricetta"
end

local function escape(s)
	return (tostring(s):gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", c:byte()) end))
end

local OPTIONS = { timeout = 30 }

function M.send(ws_url, r)
	if not http or not r then return end
	local ok, text = pcall(replay.encode, r)
	if not ok then return end
	local info = sys.get_sys_info()
	local who = (info.system_name or "?") .. " " .. (info.device_model or "")
	local lua = jit and jit.version or _VERSION
	http.request(M.url(ws_url) .. "?p=" .. escape(who) .. "&j=" .. escape(lua), "POST", function() end,
		{ ["Content-Type"] = "text/plain" }, text, OPTIONS)
end

return M
