-- The server's events (GET /eventi, server/events.go): the game asks for them
-- on the entry screen, before opening the home (ui/entry.lua), then every
-- minute while the home is visible and every time the board and DOVE GIOCHI?
-- open. Only data and words here; the screens are menu/board.lua and
-- menu/queue.lua.
--
--   local eventi = require "main.events"
--   eventi.load_up(server_url, done, went_wrong)    -- ws://host/ws -> http://host/eventi
--   eventi.in_progress(), eventi.upcoming()          -- lists of occurrences, by start time
--   eventi.on_queue("2v2")                           -- the running ones that count for that queue
--   eventi.home_line()                               -- the line under EVENTI in the home
--   eventi.what_changes(o, name_list)                -- the rules in words ("Casse ogni 2 turni")
--
-- An occurrence: { id, evento, tipo = mod|torneo|sfida|xp, nome, riga, da, a,
-- torna, coda, modo, giocatori, regole, premi }. da, a, torna in Unix seconds.

local M = {}

M.lista = {}      -- the occurrences of the last answer
M.offset = 0      -- server time minus phone time
M.loaded_ok = false
M.without_net = false  -- the last request got no answer

-- The server's time (the phone's clock may be ahead or behind)
function M.ora()
	return os.time() + M.offset
end

function M.read(answer, now)
	local ok, d = pcall(json.decode, answer)
	if not ok or type(d) ~= "table" or type(d.eventi) ~= "table" then return false end
	M.lista = d.eventi
	M.offset = (d.ora or now) - now
	M.loaded_ok = true
	return true
end

local function events_url(ws_url)
	local u = ws_url:gsub("^ws", "http")
	return (u:gsub("/ws$", "")) .. "/eventi"
end

-- Always the fresh answer: never the one the engine keeps aside
local OPTIONS = { ignore_cache = true, timeout = 3 }

function M.load_up(ws_url, done, went_wrong)
	if not http then
		if went_wrong then went_wrong() end
		return
	end
	http.request(events_url(ws_url), "GET", function(_, _, res)
		if res.status == 200 and M.read(res.response, os.time()) then
			M.without_net = false
			if done then done() end
		else
			M.without_net = true
			if went_wrong then went_wrong() end
		end
	end, nil, nil, OPTIONS)
end

function M.in_progress(now)
	now = now or M.ora()
	local out = {}
	for _, o in ipairs(M.lista) do
		if o.da <= now and now < o.a then out[#out + 1] = o end
	end
	return out
end

function M.upcoming(now)
	now = now or M.ora()
	local out = {}
	for _, o in ipairs(M.lista) do
		if o.da > now then out[#out + 1] = o end
	end
	return out
end

-- The running events that sit on a normal queue (Tournament, Challenge, XP):
-- a match in that queue counts for them too
function M.on_queue(coda, now)
	local out = {}
	for _, o in ipairs(M.in_progress(now)) do
		if o.coda == coda then out[#out + 1] = o end
	end
	return out
end

-- The running events with their own queue (the modifiers)
function M.with_queue(now)
	local out = {}
	for _, o in ipairs(M.in_progress(now)) do
		if o.coda ~= o.modo then out[#out + 1] = o end
	end
	return out
end

-- 2g 3h, 3h 20m, 12m
function M.durata(s)
	s = math.max(0, s)
	local g, h, m = math.floor(s / 86400), math.floor(s % 86400 / 3600), math.floor(s % 3600 / 60)
	if g > 0 then return h > 0 and (g .. "g " .. h .. "h") or (g .. "g") end
	if h > 0 then return m > 0 and (h .. "h " .. m .. "m") or (h .. "h") end
	return math.max(m, 1) .. "m"
end

function M.quando(o, now)
	now = now or M.ora()
	if o.da > now then return "comincia tra " .. M.durata(o.da - now) end
	return "finisce tra " .. M.durata(o.a - now)
end

-- The line under EVENTI in the home: no red numbers, only what is happening
function M.home_line(now)
	if not M.loaded_ok then return M.without_net and "senza rete" or "" end
	local hour_of = M.in_progress(now)
	if #hour_of == 1 then return hour_of[1].nome end
	if #hour_of > 1 then return #hour_of .. " in corso" end
	local after_step = M.upcoming(now)[1]
	if after_step then return "il prossimo tra " .. M.durata(after_step.da - (now or M.ora())) end
	return "nessuno in programma"
end

local TYPES = { mod = "MODIFICATORE", torneo = "TORNEO", sfida = "SFIDA", xp = "XP" }
function M.tipo(o) return TYPES[o.tipo] or string.upper(o.tipo or "") end

local CODE = { ["1v1"] = "1 CONTRO 1", ["2v2"] = "2 CONTRO 2", ffa = "TUTTI CONTRO TUTTI" }
function M.queue_name(modo) return CODE[modo] or modo end

-- The rules in words, one per line (sim/rules.lua). name_list: weapon -> name (battle/hud.lua)
function M.what_changes(o, name_list)
	local r, out = o.regole or {}, {}
	if o.coda ~= o.modo then out[#out + 1] = M.queue_name(o.modo) end
	if r.armi then
		local n = {}
		for i, w in ipairs(r.armi) do n[i] = (name_list and name_list[w]) or w end
		out[#out + 1] = "Armi: " .. table.concat(n, ", ")
	end
	if r.casse then out[#out + 1] = r.casse == 1 and "Una cassa a ogni turno" or ("Casse ogni " .. r.casse .. " turni") end
	if r.cure == false then out[#out + 1] = "Niente cure" end
	if r.livello == "fisso" then out[#out + 1] = "Tutti allo stesso livello" end
	if r.punti then out[#out + 1] = "Punti diversi" end
	if #out == 0 then out[1] = o.coda == o.modo and ("Le partite normali " .. M.queue_name(o.coda)) or "Regole normali" end
	-- the cap doesn't change the match: after the Tournament's "Le partite normali"
	if r.tetto then out[#out + 1] = "Pezzi al massimo al livello " .. r.tetto end
	return out
end

return M
