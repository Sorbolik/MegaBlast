-- The guest profile on the server (plan of 17 Nov, PR 3: "in the shadow",
-- server/accounts.go). At the first start with the network the phone asks for
-- an identity (a number and a key, kept in a file of its own) and brings its
-- progress over once (the server cuts it to the caps); then, at every start
-- and after a save (at most every COPY_EVERY seconds), it sends a copy of
-- its profile. For now the phone's profile is the one that counts: nothing
-- waits for the answers and nothing changes in the game if the server isn't
-- there. The test profiles (menu/profile.lua, test) never go to the server.

local replay = require "sim.replay"

local M = {}

M.COPY_EVERY = 30
-- what stays on the phone: the last matches (with their replays) and the settings
local PHONE_ONLY = { partite = true, impostazioni = true }

local OPTIONS = { timeout = 30 }

-- ws://host/ws -> http://host/profilo... (wss -> https)
function M.url(ws_url, path)
	local u = ws_url:gsub("^ws", "http")
	return (u:gsub("/ws$", "")) .. path
end

local function file()
	return sys.get_save_file("megablast", "identita")
end

function M.identity()
	local ok, t = pcall(sys.load, file())
	if ok and type(t) == "table" and type(t.id) == "number" and type(t.chiave) == "string" then return t end
	return nil
end

-- the profile as the server keeps it (sim/replay.lua write: pure data)
function M.text(p)
	local t = {}
	for k, v in pairs(p) do
		if not PHONE_ONLY[k] then t[k] = v end
	end
	local ok, s = pcall(replay.write, t)
	return ok and s or nil
end

local function who()
	local info = sys.get_sys_info()
	local s = (info.system_name or "?") .. " " .. (info.device_model or "")
	return (s:gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", c:byte()) end))
end

local state = { url = nil, asking = false, last = -math.huge, pending = nil, timer = nil }

local function send_copy(p)
	local id = M.identity()
	local text = id and M.text(p)
	if not text then return end
	state.last = socket and socket.gettime and socket.gettime() or os.time()
	http.request(M.url(state.url, "/profilo/copia") .. "?p=" .. who(), "POST", function() end,
		{ ["Content-Type"] = "text/plain", Authorization = "Profilo " .. string.format("%d", id.id) .. "." .. id.chiave },
		text, OPTIONS)
end

-- At startup: the identity if missing (with the import of the progress), else a copy.
-- test: the profile in use is a test one (nothing goes to the server)
function M.start(ws_url, p, test)
	if not http or not ws_url then return end
	-- the address stays even with a test profile: back on the real one, the
	-- next save asks for the identity (M.saved)
	state.url = ws_url
	if test then return end
	if M.identity() then
		send_copy(p)
		return
	end
	if state.asking then return end
	local text = M.text(p)
	if not text then return end
	state.asking = true
	http.request(M.url(ws_url, "/profilo/nuovo") .. "?p=" .. who(), "POST", function(_, _, res)
		state.asking = false
		if not res or res.status ~= 200 then return end
		local ok, t = pcall(json.decode, res.response or "")
		if ok and type(t) == "table" and type(t.id) == "number" and type(t.chiave) == "string" then
			pcall(sys.save, file(), { id = t.id, chiave = t.chiave, nome = t.nome })
		end
	end, { ["Content-Type"] = "text/plain" }, text, OPTIONS)
end

-- After a save: a copy now, or at most COPY_EVERY seconds after the last one
-- (without an identity yet, because the server wasn't there at startup: it
-- asks again, at most every COPY_EVERY seconds)
function M.saved(p, test)
	if not http or not state.url or test then return end
	local now = socket and socket.gettime and socket.gettime() or os.time()
	if not M.identity() then
		if now - state.last >= M.COPY_EVERY then
			state.last = now
			M.start(state.url, p, test)
		end
		return
	end
	if now - state.last >= M.COPY_EVERY then
		send_copy(p)
		return
	end
	state.pending = p
	if state.timer or not timer then return end
	state.timer = timer.delay(M.COPY_EVERY - (now - state.last), false, function()
		state.timer = nil
		local q = state.pending
		state.pending = nil
		if q then send_copy(q) end
	end)
end

return M
