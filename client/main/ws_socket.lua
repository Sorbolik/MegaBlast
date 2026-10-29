-- WebSocket su LuaSocket per il simulatore (strumenti/simula): la build del
-- simulatore non ha l'estensione WebSocket (si compila sul build server di
-- Defold, che dal cloud non si raggiunge), così l'online si prova contro un
-- server vero (comando "server" degli scenari). Stessa interfaccia
-- dell'estensione per quello che usa game.gui_script; gli eventi arrivano da
-- poll(self) a ogni frame. Solo testo, solo ws:// (niente TLS).

local M = {
	EVENT_CONNECTED = 0, EVENT_DISCONNECTED = 1, EVENT_MESSAGE = 2, EVENT_ERROR = 3,
	DATA_TYPE_TEXT = 0,
}

local attuale -- { tcp, cb, buf, eventi }

local function evento(c, ev, testo)
	c.eventi[#c.eventi + 1] = { event = ev, message = testo }
end

function M.connect(url, params, cb)
	local c = { cb = cb, buf = "", eventi = {} }
	attuale = c
	local host, porta, via = url:match("^ws://([^:/]+):?(%d*)(.*)$")
	local tcp = host and socket.tcp()
	if not tcp then
		evento(c, M.EVENT_ERROR)
		return c
	end
	tcp:settimeout((params and params.timeout or 5000) / 1000)
	local ok = tcp:connect(host, tonumber(porta) or 80)
	if ok then
		ok = tcp:send(("GET %s HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
			.. "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"):format(via ~= "" and via or "/", host))
		-- la risposta: "HTTP/1.1 101 ..." e le intestazioni fino alla riga vuota
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

-- Un frame dal client: sempre mascherato (lo vuole il protocollo)
local function frame(op, data)
	local n = #data
	local testa = string.char(0x80 + op)
	if n < 126 then
		testa = testa .. string.char(0x80 + n)
	elseif n < 65536 then
		testa = testa .. string.char(0x80 + 126, math.floor(n / 256), n % 256)
	else
		testa = testa .. string.char(0x80 + 127, 0, 0, 0, 0, math.floor(n / 16777216) % 256,
			math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
	end
	local chiave = { math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255) }
	local out = {}
	for i = 1, n do
		out[i] = string.char(bit.bxor(data:byte(i), chiave[(i - 1) % 4 + 1]))
	end
	return testa .. string.char(chiave[1], chiave[2], chiave[3], chiave[4]) .. table.concat(out)
end

function M.send(conn, data)
	if conn.tcp then conn.tcp:send(frame(1, data)) end
end

function M.disconnect(conn)
	if conn.tcp then
		conn.tcp:close()
		conn.tcp = nil
	end
	if attuale == conn then attuale = nil end
end

local function chiusa(c)
	c.tcp:close()
	c.tcp = nil
	evento(c, M.EVENT_DISCONNECTED)
end

-- I frame completi in c.buf (dal server non sono mascherati)
local function leggi_frame(c)
	while true do
		local b = c.buf
		if #b < 2 then return end
		local op, n, da = b:byte(1) % 16, b:byte(2) % 128, 3
		if n == 126 then
			if #b < 4 then return end
			n, da = b:byte(3) * 256 + b:byte(4), 5
		elseif n == 127 then
			if #b < 10 then return end
			n = 0
			for i = 3, 10 do n = n * 256 + b:byte(i) end
			da = 11
		end
		if #b < da + n - 1 then return end
		local data = b:sub(da, da + n - 1)
		c.buf = b:sub(da + n)
		if op == 1 or op == 0 then
			c.parte = (c.parte or "") .. data
			if b:byte(1) >= 128 then
				evento(c, M.EVENT_MESSAGE, c.parte)
				c.parte = nil
			end
		elseif op == 9 then
			c.tcp:send(frame(10, data))
		elseif op == 8 then
			chiusa(c)
			return
		end
	end
end

function M.poll(self)
	local c = attuale
	if not c then return end
	if c.tcp then
		local data, err, parte = c.tcp:receive("*a")
		c.buf = c.buf .. (data or parte or "")
		leggi_frame(c)
		if err == "closed" and c.tcp then chiusa(c) end
	end
	local eventi = c.eventi
	c.eventi = {}
	for _, e in ipairs(eventi) do
		if attuale ~= c then return end
		c.cb(self, c, e)
	end
end

return M
