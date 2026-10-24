-- WebSocket del browser per la build HTML5 senza l'estensione (strumenti/web/build.sh:
-- l'estensione si compila sul build server di Defold, che dal cloud non si raggiunge).
-- Stessa interfaccia dell'estensione per quello che usa game.gui_script; gli eventi
-- arrivano da una coda in JavaScript che poll(self) svuota a ogni frame.

local M = {
	EVENT_CONNECTED = 0, EVENT_DISCONNECTED = 1, EVENT_MESSAGE = 2, EVENT_ERROR = 3,
	DATA_TYPE_TEXT = 0,
}

-- Una riga in coda per evento: "id evento testo"; ogni socket manda un solo evento di chiusura
local JS = [[
window.mbws = window.mbws || { n: 0, s: {}, q: [],
	connect: function (url, timeout) {
		var id = ++this.n, q = this.q, s = this.s, w;
		function fine(ev) { if (s[id]) { delete s[id]; q.push(id + " " + ev + " "); } }
		try { w = new WebSocket(url); } catch (e) { q.push(id + " 3 "); return id; }
		s[id] = w;
		w.onopen = function () { q.push(id + " 0 "); };
		w.onmessage = function (e) { q.push(id + " 2 " + e.data); };
		w.onerror = function () { fine(3); w.close(); };
		w.onclose = function () { fine(1); };
		setTimeout(function () { if (w.readyState === 0) { fine(3); w.close(); } }, timeout);
		return id;
	},
	send: function (id, d) { var w = this.s[id]; if (w && w.readyState === 1) w.send(d); },
	close: function (id) { var w = this.s[id]; if (w) { delete this.s[id]; w.close(); } },
	poll: function () { return this.q.length ? this.q.shift() : ""; }
};
]]

local callback, attuale

-- stringa Lua -> stringa JavaScript tra virgolette
local function js_str(s)
	return json.encode({ s }):sub(2, -2)
end

function M.connect(url, params, cb)
	html5.run(JS)
	callback = cb
	attuale = tonumber(html5.run(("mbws.connect(%s, %d)"):format(js_str(url), params and params.timeout or 5000)))
	return attuale
end

function M.send(conn, data)
	html5.run(("mbws.send(%d, %s)"):format(conn, js_str(data)))
end

function M.disconnect(conn)
	html5.run(("mbws.close(%d)"):format(conn))
end

function M.poll(self)
	if not callback then return end
	while true do
		local riga = html5.run("mbws.poll()")
		if riga == "" then return end
		local id, ev, testo = riga:match("^(%d+) (%d) (.*)$")
		-- gli eventi rimasti di un socket chiuso si buttano
		if tonumber(id) == attuale then
			callback(self, attuale, { event = tonumber(ev), message = testo })
		end
	end
end

return M
