-- A LuaJIT process of the server (server/proc.go): it runs the simulation of
-- the rooms of one worker. The Go server keeps the connections, the queues and
-- the rooms; here live the matches (sim/game.lua) and the drafts, by room id.
--
-- Every tick Go sends one batch: lines "<n>\t<Lua table of n commands>", then
-- an empty line. Each command is a table with f (what to do, see CMD below)
-- and r (the room). For each command, in order, the answer is
--
--   <raws> <len>\n<head JSON>   then, raws times:   <len>\n<JSON>
--
-- head is a small object Go reads (cur, over, ...); the raws are messages
-- already in JSON that Go sends to the players as they are (events, state,
-- draft). A command that fails answers {"err":"..."} and the others go on.
-- stdout is only for the answers: print writes to stderr (the server's log).
-- On Windows stdin and stdout are in text mode: "\n" goes out as "\r\n" (Go
-- skips the \r) and a byte 26 would end the input; neither can happen inside
-- the data, because Go escapes every control byte of the commands and the
-- JSON of the answers escapes them too.

local dir = arg[1] or "."
package.path = dir .. "/?.lua;" .. package.path
io.stdout:setvbuf("full")
_G.print = function(...)
	local t = { ... }
	for i = 1, select("#", ...) do t[i] = tostring(t[i]) end
	io.stderr:write(table.concat(t, "\t"), "\n")
end

local N = require "net"

-- JSON like the server always wrote it (luajson.go before LuaJIT): integers
-- stay integers, the other numbers get two decimals (enough for positions and
-- angles, smaller messages), NaN and infinities become 0; a table with only
-- the list part (or empty) is an array, otherwise an object of its string keys.
local floor, format, type, next, pairs = math.floor, string.format, type, next, pairs
local concat = table.concat

local ESC = {}
for c = 0, 31 do ESC[string.char(c)] = format("\\u%04x", c) end
ESC['"'], ESC["\\"] = '\\"', "\\\\"

local function str(s)
	if s:find('[%c"\\]') then s = s:gsub('[%c"\\]', ESC) end
	return '"' .. s .. '"'
end

local encode
encode = function(v, b, n)
	local tv = type(v)
	if tv == "number" then
		if v ~= v or v == math.huge or v == -math.huge then
			b[n] = "0"
		elseif v == floor(v) and v < 1e15 and v > -1e15 then
			b[n] = format("%d", v)
		else
			b[n] = format("%.2f", v)
		end
		return n + 1
	elseif tv == "string" then
		b[n] = str(v)
		return n + 1
	elseif tv == "boolean" then
		b[n] = v and "true" or "false"
		return n + 1
	elseif tv == "table" then
		local len = #v
		if len > 0 or next(v) == nil then
			b[n] = "["
			n = n + 1
			for i = 1, len do
				if i > 1 then b[n] = ","; n = n + 1 end
				n = encode(v[i], b, n)
			end
			b[n] = "]"
			return n + 1
		end
		b[n] = "{"
		n = n + 1
		local first = true
		for k, x in pairs(v) do
			if type(k) == "string" then
				if not first then b[n] = ","; n = n + 1 end
				first = false
				b[n] = str(k)
				b[n + 1] = ":"
				n = encode(x, b, n + 2)
			end
		end
		b[n] = "}"
		return n + 1
	end
	b[n] = "null"
	return n + 1
end

local buf = {}
local function json(v)
	local n = encode(v, buf, 1)
	local s = concat(buf, "", 1, n - 1)
	for i = n - 1, 1, -1 do buf[i] = nil end
	return s
end

-- Answers of the batch, written all together at the end
local out, outn = {}, 0
local function put(s)
	outn = outn + 1
	out[outn] = s
end

-- answer of one command: head (a table, nil = {}, or a string as it is) and
-- the raws (JSON strings)
local function answer(head, raws)
	local h = type(head) == "string" and head or head and json(head) or "{}"
	local nr = raws and #raws or 0
	put(format("%d %d\n", nr, #h))
	put(h)
	for i = 1, nr do
		local r = raws[i]
		put(format("%d\n", #r))
		put(r)
	end
end

local ROOMS = {}

local function room(c)
	local r = ROOMS[c.r]
	if not r then error("stanza " .. tostring(c.r) .. " sconosciuta") end
	return r
end

local EMPTY = {}

local CMD = {}

-- open{r, seed, mode, rules, bots}: the room's weapon draft starts; secs: its time
function CMD.open(c)
	ROOMS[c.r] = { seed = c.seed, rules = c.rules, d = N.draft_new(c.seed, c.mode, c.rules, c.bots) }
	answer({ secs = N.draft_seconds() })
end

-- draft{r, i}: what seat i sees of the draft (Go adds who they are and the others)
function CMD.draft(c)
	answer(nil, { json(N.draft_state(room(c).d, c.i)) })
end

-- pick{r, i, w}: seat i picks w; if it counts, the new draft of seat i
function CMD.pick(c)
	local r = room(c)
	if N.draft_pick(r.d, c.i, c.w) then
		answer(nil, { json(N.draft_state(r.d, c.i)) })
	else
		answer()
	end
end

-- start{r}: the draft closes and the match starts; map and players (with picks)
function CMD.start(c)
	local r = room(c)
	local players = N.draft_finish(r.d)
	r.d = nil
	r.g = N.new(r.seed, nil, players, r.rules)
	answer({ map = r.g.map, cur = N.current(r.g) }, { json(N.start_players(players)) })
end

-- new{r, seed, map, players, rules}: a match without draft (tests)
function CMD.new(c)
	ROOMS[c.r] = { g = N.new(c.seed, c.map, c.players, c.rules) }
	answer({ map = ROOMS[c.r].g.map })
end

-- tick{r, k, s}: one tick of the match. k: the keys of the player on turn,
-- if any (l, r, j: left, right, jump; h: jump held; a, p, w: fire at angle a
-- with power p and weapon w; m: aiming at angle m), s: also the state.
-- head "cur next over st": on turn before and after, 1 if over, 1 if the
-- last raw is the state (asked, or the match is over); raws: the events, then
-- the state.
function CMD.tick(c)
	local g = room(c).g
	local cur = g.current
	local k = c.k or EMPTY
	N.step(g, k.l, k.r, k.j, k.h, k.a, k.p, k.w)
	local nxt = g.current
	local evs = N.events(g)
	local raws = {}
	for i = 1, #evs do raws[i] = json(evs[i]) end
	local over = N.over(g)
	local st = c.s or over
	if st then
		-- the aim of whoever is still on turn (a new turn starts without)
		raws[#raws + 1] = json(N.snapshot(g, nxt == cur and k.m or nil))
	end
	answer(format("%d %d %d %d", cur, nxt, over and 1 or 0, st and 1 or 0), raws)
end

-- step{r, l, rt, j, h, a, p, w}: like tick but without events and state (tests)
function CMD.step(c)
	local g = room(c).g
	N.step(g, c.l, c.rt, c.j, c.h, c.a, c.p, c.w)
	answer({ cur = g.current })
end

function CMD.events(c)
	local raws = {}
	for i, e in ipairs(N.events(room(c).g)) do raws[i] = json(e) end
	answer(nil, raws)
end

-- snapshot{r, m}: the state, with the aim m (nil if not aiming)
function CMD.snapshot(c)
	answer(nil, { json(N.snapshot(room(c).g, c.m)) })
end

-- resume{r}: for whoever comes back, the digs so far and the state
function CMD.resume(c)
	local g = room(c).g
	answer(nil, { json(N.sync(g)), json(N.snapshot(g)) })
end

function CMD.current(c)
	local g = room(c).g
	answer({ cur = g.current, over = N.over(g), map = g.map })
end

-- remove{r, i}: the player of seat i left (their robot disappears)
function CMD.remove(c)
	local r = room(c)
	if r.g then N.remove(r.g, c.i) end
	answer()
end

-- free{r}: the room is closed
function CMD.free(c)
	ROOMS[c.r] = nil
	answer()
end

-- rules_valid{rules, normal}: can an event's rules be used? (events.go)
function CMD.rules_valid(c)
	answer({ msg = N.rules_valid(c.rules, c.normal) })
end

-- eval{code}: runs code (with N among the globals) and answers what it
-- returns as head (tests and checks of the server, never from the players)
local env = setmetatable({ N = N }, { __index = _G })
function CMD.eval(c)
	local f = assert(loadstring(c.code, "=eval"))
	setfenv(f, env)
	local v = f()
	answer({ v = v })
end

-- the batch: commands come in as Lua tables; nothing else is reachable from
-- them (empty environment)
local function run(line)
	local count, src = line:match("^(%d+)\t(.*)$")
	count = tonumber(count) or 0
	local f, err = loadstring("return " .. (src or ""), "=batch")
	local cmds
	if f then
		setfenv(f, {})
		local ok, v = pcall(f)
		if ok then cmds = v else err = v end
	end
	for i = 1, count do
		local c = cmds and cmds[i]
		local ok, e
		if c then
			local fn = CMD[c.f]
			if fn then
				local mark = outn
				ok, e = pcall(fn, c)
				if not ok then
					-- what it may have written before the error is dropped
					for j = mark + 1, outn do out[j] = nil end
					outn = mark
				end
			else
				e = "comando sconosciuto: " .. tostring(c.f)
			end
		else
			e = err or "comando mancante"
		end
		if not ok then answer({ err = tostring(e) }) end
	end
end

for line in io.stdin:lines() do
	if line == "" then
		io.stdout:write(concat(out, "", 1, outn))
		io.stdout:flush()
		for i = 1, outn do out[i] = nil end
		outn = 0
	else
		run(line)
	end
end
