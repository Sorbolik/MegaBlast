-- WebSocket over LuaSocket for the simulator (strumenti/simula): the
-- simulator build doesn't have the WebSocket extension (it compiles on
-- Defold's build server, which can't be reached from the cloud), so online is
-- tested against a real server (the scenarios' "server" command). Same
-- interface as the extension for what game.gui_script uses; events arrive from
-- poll(self) every frame. Text only, ws:// only (no TLS).

local M = {
	EVENT_CONNECTED = 0, EVENT_DISCONNECTED = 1, EVENT_MESSAGE = 2, EVENT_ERROR = 3,
	DATA_TYPE_TEXT = 0,
}

local active_conn -- { tcp, cb, buf, eventi }

-- "imposta prova_rete MS" (scenario rete_tele.txt): a WiFi that sometimes
-- holds the messages back up to MS ms and then hands them over all together
local JITTER = sys.get_config_int("megablast.prova_rete", 0) / 1000
local held_until = 0

local function evento(c, ev, txt)
	local at = 0
	if JITTER > 0 then
		local now = socket.gettime()
		if math.random() < 0.08 then held_until = math.max(held_until, now + math.random() * JITTER) end
		at = math.max(now, held_until)
	end
	c.eventi[#c.eventi + 1] = { event = ev, message = txt, at = at }
end

function M.connect(url, params, cb)
	local c = { cb = cb, buf = "", eventi = {} }
	active_conn = c
	local host, port, path = url:match("^ws://([^:/]+):?(%d*)(.*)$")
	local tcp = host and socket.tcp()
	if not tcp then
		evento(c, M.EVENT_ERROR)
		return c
	end
	tcp:settimeout((params and params.timeout or 5000) / 1000)
	local ok = tcp:connect(host, tonumber(port) or 80)
	if ok then
		ok = tcp:send(("GET %s HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
			.. "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"):format(path ~= "" and path or "/", host))
		-- the answer: "HTTP/1.1 101 ..." and the headers up to the empty line
		local riga = ok and tcp:receive("*l")
		ok = riga and riga:find(" 101 ")
		while ok and riga ~= "" do
			riga = tcp:receive("*l")
			ok = riga
		end
	end
	if not ok then
		tcp:close()
		evento(c, M.EVENT_ERROR)
		return c
	end
	tcp:settimeout(0)
	c.tcp = tcp
	evento(c, M.EVENT_CONNECTED)
	return c
end

-- A frame from the client: always masked (the protocol wants it)
local function frame(op, data)
	local n = #data
	local head = string.char(0x80 + op)
	if n < 126 then
		head = head .. string.char(0x80 + n)
	elseif n < 65536 then
		head = head .. string.char(0x80 + 126, math.floor(n / 256), n % 256)
	else
		head = head .. string.char(0x80 + 127, 0, 0, 0, 0, math.floor(n / 16777216) % 256,
			math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
	end
	local mask = { math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255) }
	local out = {}
	for i = 1, n do
		out[i] = string.char(bit.bxor(data:byte(i), mask[(i - 1) % 4 + 1]))
	end
	return head .. string.char(mask[1], mask[2], mask[3], mask[4]) .. table.concat(out)
end

function M.send(conn, data)
	if conn.tcp then conn.tcp:send(frame(1, data)) end
end

function M.disconnect(conn)
	if conn.tcp then
		conn.tcp:close()
		conn.tcp = nil
	end
	if active_conn == conn then active_conn = nil end
end

local function closed(c)
	c.tcp:close()
	c.tcp = nil
	evento(c, M.EVENT_DISCONNECTED)
end

-- The complete frames in c.buf (from the server they aren't masked)
local function read_frame(c)
	while true do
		local b = c.buf
		if #b < 2 then return end
		local op, n, start = b:byte(1) % 16, b:byte(2) % 128, 3
		if n == 126 then
			if #b < 4 then return end
			n, start = b:byte(3) * 256 + b:byte(4), 5
		elseif n == 127 then
			if #b < 10 then return end
			n = 0
			for i = 3, 10 do n = n * 256 + b:byte(i) end
			start = 11
		end
		if #b < start + n - 1 then return end
		local data = b:sub(start, start + n - 1)
		c.buf = b:sub(start + n)
		if op == 1 or op == 0 then
			c.parte = (c.parte or "") .. data
			if b:byte(1) >= 128 then
				evento(c, M.EVENT_MESSAGE, c.parte)
				c.parte = nil
			end
		elseif op == 9 then
			c.tcp:send(frame(10, data))
		elseif op == 8 then
			closed(c)
			return
		end
	end
end

function M.poll(self)
	local c = active_conn
	if not c then return end
	if c.tcp then
		local data, err, part = c.tcp:receive("*a")
		c.buf = c.buf .. (data or part or "")
		read_frame(c)
		if err == "closed" and c.tcp then closed(c) end
	end
	local events = c.eventi
	c.eventi = {}
	local now = socket.gettime()
	for i, e in ipairs(events) do
		if active_conn ~= c then return end
		if e.at > now then
			-- held back (prova_rete): it and those behind it wait for the next frames
			for j = i, #events do c.eventi[#c.eventi + 1] = events[j] end
			return
		end
		c.cb(self, c, e)
	end
end

return M
