-- The guest profile on the server (plan of 17 Nov, server/accounts.go). At
-- the first start with the network the phone asks for an identity (a number
-- and a key, kept in a file of its own) and brings its progress over once
-- (the server cuts it to the caps). From then on the server's profile is the
-- one that counts (PR 4): every action that changes the progress
-- (sim/progress.lua: a purchase, the ZAINO, a match...) is done at once on
-- the phone and goes to the server in a queue kept in a file (it waits there
-- without the network); the server does it again with its own rules and
-- answers its profile, which takes the place of the phone's (what it hasn't
-- seen yet is done again on top). The last matches, the settings and the
-- little things only of this phone stay as they are. The test profiles
-- (menu/profile.lua, test) never go to the server.

local replay = require "sim.replay"
local progress = require "sim.progress"
local wallet = require "sim.wallet"

local M = {}

-- seconds between two tries while actions wait without the network
M.RETRY = 30
-- the most actions waiting (the oldest go)
M.QUEUE_MAX = 200
-- the most matches (actions with a recipe) in one request: the server replays them
M.MATCHES_MAX = 5
-- what stays on the phone: the last matches (with their replays and their
-- count), the settings, the weapons and the story already seen, the badges
-- chosen, the lost missions in a row
local PHONE_ONLY = { partite = true, numero = true, impostazioni = true, armi = true, storia = true, badge = true,
	failed_ones = true }

local OPTIONS = { timeout = 30 }

-- ws://host/ws -> http://host/profilo... (wss -> https)
function M.url(ws_url, path)
	local u = ws_url:gsub("^ws", "http")
	return (u:gsub("/ws$", "")) .. path
end

local function save_file(name)
	return sys.get_save_file("megablast", name)
end

function M.identity()
	local ok, t = pcall(sys.load, save_file("identita"))
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

-- The server's profile (text) in the place of p's progress; done: the last
-- action the server did, the ones after it are done again on top
function M.adopt(p, text, done, queue, today)
	local ok, sp = pcall(replay.read, text or "")
	if not ok or type(sp) ~= "table" then return false end
	for k in pairs(p) do
		if not PHONE_ONLY[k] then p[k] = nil end
	end
	for k, v in pairs(sp) do
		if not PHONE_ONLY[k] then p[k] = v end
	end
	for _, a in ipairs(queue or {}) do
		if a.n > done then progress.act(p, a, today) end
	end
	return true
end

local function who()
	local info = sys.get_sys_info()
	local s = (info.system_name or "?") .. " " .. (info.device_model or "")
	return (s:gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", c:byte()) end))
end

-- p: the profile in use; is_test(): it is a test one; save(p)
local state = { url = nil, p = nil, is_test = nil, save = nil, asking = false, busy = false, online = false, timer = nil }
-- the actions waiting: n = the last number given
local queue = { n = 0, list = {} }

local function load_queue()
	local ok, t = pcall(sys.load, save_file("azioni"))
	if ok and type(t) == "table" and type(t.n) == "number" and type(t.list) == "table" then
		queue.n, queue.list = t.n, t.list
	end
end

local function save_queue()
	pcall(sys.save, save_file("azioni"), { n = queue.n, list = queue.list })
end

local function auth(id)
	return { ["Content-Type"] = "text/plain", Authorization = "Profilo " .. string.format("%d", id.id) .. "." .. id.chiave }
end

local flush, birth

-- without the network: again in a while (the Armeria waits for it)
local function retry_later()
	if state.timer or not timer then return end
	state.timer = timer.delay(M.RETRY, false, function()
		state.timer = nil
		if state.is_test() then return end
		if M.identity() then flush() else birth() end
	end)
end

local function take(t)
	if state.is_test() then return end
	if M.adopt(state.p, t.profilo, t.ultima or 0, queue.list, wallet.today()) then state.save(state.p) end
end

-- Sends the actions waiting (none: just takes the server's profile)
flush = function()
	local id = M.identity()
	if state.busy or not id then return end
	-- the first actions, in order, up to the most matches a request carries
	local sent, matches = {}, 0
	for _, a in ipairs(queue.list) do
		if a.ricetta then
			if matches == M.MATCHES_MAX then break end
			matches = matches + 1
		end
		sent[#sent + 1] = a
	end
	local body = replay.write({ azioni = sent })
	state.busy = true
	http.request(M.url(state.url, "/profilo/fai") .. "?p=" .. who(), "POST", function(_, _, res)
		state.busy = false
		local status = res and res.status or 0
		if status == 401 then
			-- the server doesn't know this identity (or its key): a new one, from this profile
			pcall(sys.save, save_file("identita"), {})
			queue.list = {}
			save_queue()
			birth()
			return
		end
		local ok, t = pcall(json.decode, status == 200 and res.response or "")
		if not ok or type(t) ~= "table" then
			state.online = false
			retry_later()
			return
		end
		state.online = true
		local refused = {}
		for _, n in ipairs(type(t.rifiutate) == "table" and t.rifiutate or {}) do refused[n] = true end
		local kept = {}
		for _, a in ipairs(queue.list) do
			if a.n > (t.ultima or 0) then
				kept[#kept + 1] = a
			elseif M.on_result then
				M.on_result(a.n, not refused[a.n])
			end
		end
		queue.list = kept
		-- the server did more than this phone numbered (a phone put back from
		-- Android's backup, the profile recovered here): the next ones after it
		queue.n = math.max(queue.n, t.ultima or 0)
		save_queue()
		take(t)
		if #queue.list > 0 then flush() end
	end, auth(id), body, OPTIONS)
end

-- A new identity, bringing this profile's progress over
birth = function()
	if state.asking or state.is_test() then return end
	local text = M.text(state.p)
	if not text then return end
	state.asking = true
	http.request(M.url(state.url, "/profilo/nuovo") .. "?p=" .. who(), "POST", function(_, _, res)
		state.asking = false
		local ok, t = pcall(json.decode, res and res.status == 200 and res.response or "")
		if not ok or type(t) ~= "table" or type(t.id) ~= "number" or type(t.chiave) ~= "string" then
			state.online = false
			retry_later()
			return
		end
		state.online = true
		pcall(sys.save, save_file("identita"), { id = t.id, chiave = t.chiave, nome = t.nome })
		take({ profilo = t.profilo, ultima = 0 })
		-- what was done while it was being born
		if #queue.list > 0 then flush() end
	end, { ["Content-Type"] = "text/plain" }, text, OPTIONS)
end

-- At startup: the identity if missing (with the import of the progress), else
-- the actions waiting and the server's profile. is_test(): the profile in use
-- is a test one (nothing goes to the server, nothing comes back); save(p)
function M.start(ws_url, p, is_test, save)
	if not http or not ws_url then return end
	state.url, state.p, state.is_test, state.save = ws_url, p, is_test, save
	load_queue()
	if is_test() then return end
	if M.identity() then flush() else birth() end
end

-- An action done on the phone (menu/profile.lua act): to the server. Returns
-- its number (nil: it doesn't go); when the server has done it,
-- M.on_result(n, paid) is called (paid false: a match replayed and not paid)
function M.send(p, a)
	if not state.url or state.is_test() then return end
	if not M.identity() and not state.asking then
		-- the server wasn't there at startup: the identity, with this profile
		birth()
		return
	end
	local ok, copy = pcall(function() return replay.read(replay.write(a)) end)
	if not ok or type(copy) ~= "table" then return end
	queue.n = queue.n + 1
	copy.n = queue.n
	queue.list[#queue.list + 1] = copy
	while #queue.list > M.QUEUE_MAX do table.remove(queue.list, 1) end
	save_queue()
	flush()
	return copy.n
end

-- The recovery code of this profile (IMPOSTAZIONI, server/recovery.go): the
-- one kept with the identity, or a new one from the server when fresh or
-- there is none (the old one stops working). done(code or nil, why)
function M.code(fresh, done)
	local id = M.identity()
	if id and id.codice and not fresh then return done(id.codice) end
	if not state.url or not id or state.is_test() then return done(nil, "rete") end
	http.request(M.url(state.url, "/profilo/codice") .. "?p=" .. who(), "POST", function(_, _, res)
		local ok, t = pcall(json.decode, res and res.status == 200 and res.response or "")
		if not ok or type(t) ~= "table" or type(t.codice) ~= "string" then return done(nil, "rete") end
		local now = M.identity()
		if now and now.id == id.id then
			now.codice = t.codice
			pcall(sys.save, save_file("identita"), now)
		end
		done(t.codice)
	end, auth(id), "", OPTIONS)
end

-- «Ho già un profilo»: the profile of that recovery code takes this phone's
-- place (its waiting actions go: they were of the profile left).
-- done(true) or done(false, why): "codice" (unknown), "tentativi" (too many in
-- an hour), "rete"
function M.recover(code, done)
	if not state.url or state.is_test() then return done(false, "rete") end
	http.request(M.url(state.url, "/profilo/recupera") .. "?p=" .. who(), "POST", function(_, _, res)
		local status = res and res.status or 0
		if status == 404 then return done(false, "codice") end
		if status == 429 then return done(false, "tentativi") end
		local ok, t = pcall(json.decode, status == 200 and res.response or "")
		if not ok or type(t) ~= "table" or type(t.id) ~= "number" or type(t.chiave) ~= "string" then
			return done(false, "rete")
		end
		local plain = code:upper():gsub("[^%w]", "")
		local shown = plain:sub(1, 4) .. "-" .. plain:sub(5, 8) .. "-" .. plain:sub(9, 12)
		pcall(sys.save, save_file("identita"), { id = t.id, chiave = t.chiave, nome = t.nome, codice = shown })
		queue.list, queue.n = {}, t.ultima or 0
		save_queue()
		take({ profilo = t.profilo, ultima = queue.n })
		done(true)
	end, { ["Content-Type"] = "text/plain" }, code, OPTIONS)
end

-- The profile for the online greeting, "<id>.<chiave>" (nil: none, or a test one)
function M.key(test)
	local id = not test and M.identity()
	return id and string.format("%d", id.id) .. "." .. id.chiave or nil
end

-- The server's profile again (after an online match: its prizes)
function M.refresh()
	if state.url and state.is_test and not state.is_test() and M.identity() then flush() end
end

-- Whether the server answered the last time (the Armeria spends only then).
-- Without a server to talk to (no address, no http) the phone is on its own
function M.online()
	if not http or not state.url then return true end
	return state.online
end

return M
