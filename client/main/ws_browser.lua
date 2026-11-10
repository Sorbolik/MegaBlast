-- Browser WebSocket for the HTML5 build without the extension (tools/web/build.sh:
-- the extension compiles on Defold's build server, which can't be reached from the cloud).
-- Same interface as the extension for what game.gui_script uses; events
-- arrive from a JavaScript queue that poll(self) empties every frame.

local M = {
	EVENT_CONNECTED = 0, EVENT_DISCONNECTED = 1, EVENT_MESSAGE = 2, EVENT_ERROR = 3,
	DATA_TYPE_TEXT = 0,
}

-- One queued line per event: "id event text"; every socket sends a single close event
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

local callback, current_value

-- Lua string -> quoted JavaScript string
local function js_str(s)
	return json.encode({ s }):sub(2, -2)
end

function M.connect(url, params, cb)
	html5.run(JS)
	callback = cb
	current_value = tonumber(html5.run(("mbws.connect(%s, %d)"):format(js_str(url), params and params.timeout or 5000)))
	return current_value
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
		local id, ev, txt = riga:match("^(%d+) (%d) (.*)$")
		-- leftover events of a closed socket are thrown away
		if tonumber(id) == current_value then
			callback(self, current_value, { event = tonumber(ev), message = txt })
		end
	end
end

return M
