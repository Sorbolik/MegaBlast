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
local game = require "sim.game"
-- profiles, recipes and actions travel as pure data text (sim/replay.lua write/read)
local replay_text = require "sim.replay"

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

-- open{r, seed, mode, rules, bots, eq}: the room's weapon draft starts; secs: its time,
-- and the players (teams, bots, what everyone wears: the bots too, net.lua draft_new)
-- (eq: what each player wears, by seat: net.lua equip_stats)
function CMD.open(c)
	local d = N.draft_new(c.seed, c.mode, c.rules, c.bots, c.eq)
	ROOMS[c.r] = { seed = c.seed, rules = c.rules, d = d }
	answer({ secs = N.draft_seconds() }, { json(N.draft_players(d)) })
end

-- draft{r, i}: what seat i sees of the draft (Go adds who they are and the others)
function CMD.draft(c)
	answer(nil, { json(N.draft_state(room(c).d, c.i)) })
end

-- pick{r, i, w}: seat i picks w; if it counts, the new draft of seat i
-- (un: the pick took its PRONTO away, the others must see it)
function CMD.pick(c)
	local r = room(c)
	local ok, un = N.draft_pick(r.d, c.i, c.w)
	if ok then
		answer({ un = un }, { json(N.draft_state(r.d, c.i)) })
	else
		answer()
	end
end

-- ready{r, i}: seat i presses PRONTO; ok if it counts (both weapons picked),
-- all if now everyone is ready: the match starts without waiting for the time
function CMD.ready(c)
	local ok, all = N.draft_confirm(room(c).d, c.i)
	answer({ ok = ok, all = all })
end

-- the stats of each person in an online match (sim/tally.lua), for their
-- rewards at the end (prizes)
local tally = require "sim.tally"

-- start{r}: the draft closes and the match starts; map and players (with picks)
function CMD.start(c)
	local r = room(c)
	local players = N.draft_finish(r.d)
	r.d = nil
	r.g = N.new(r.seed, nil, players, r.rules)
	r.tallies = {}
	for i, p in ipairs(players) do
		if not p.bot then r.tallies[i] = tally.new(r.g, i) end
	end
	answer({ map = r.g.map, cur = N.current(r.g) }, { json(N.start_players(players)) })
end

-- new{r, seed, map, players, rules}: a match without draft (tests)
function CMD.new(c)
	ROOMS[c.r] = { g = N.new(c.seed, c.map, c.players, c.rules) }
	answer({ map = ROOMS[c.r].g.map })
end

-- tick{r, k, lead, s}: one tick of the match. k: the keys of the player of
-- robot lead (sim/netkeys.lua), who is on turn and leads from their phone;
-- without them a bot or nobody plays; s: also the state.
-- head "cur next over st code aim": on turn before and after, 1 if over, 1 if
-- the raw is the state (asked, or the match is over), the keys applied ("-"
-- none), where the bot on turn aims ("-" none); raws: the state, if st.
function CMD.tick(c)
	local rm = room(c)
	local g = rm.g
	local cur = g.current
	local code, input, by_bot = N.input(g, c.k, c.lead)
	local t = rm.tallies and rm.tallies[cur]
	-- a person's shot (not the bot standing in for them), for their stats
	if t and input and input.fire and not by_bot then tally.shot(t, g, input.fire.weapon) end
	g:step(input)
	local nxt = g.current
	local evs = N.events(g)
	for _, tt in pairs(rm.tallies or EMPTY) do
		for i = 1, #evs do tally.event(tt, g, evs[i]) end
		tally.tick(tt, g)
	end
	local over = N.over(g)
	local st = c.s or over
	local aim = N.bot_aim(g)
	local raws = st and { json(N.snapshot(g, c.m)) } or nil
	answer(format("%d %d %d %d %s %s", cur, nxt, over and 1 or 0, st and 1 or 0,
		code == "" and "-" or code, aim and format("%.2f", aim) or "-"), raws)
end

-- step{r, k}: one tick with the keys k of whoever is on turn, without events
-- and state (tests)
function CMD.step(c)
	local g = room(c).g
	N.step(g, c.k, g.current)
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

-- stand_in{r, i, g}: a bot of grade g plays for seat i while its player is
-- away; without g the player is back
function CMD.stand_in(c)
	local r = room(c)
	if r.g then N.stand_in(r.g, c.i, c.g) end
	answer()
end

-- prizes{r}: the match is over. For each person, by seat, what they did as an
-- action of the profile (sim/progress.lua partita, online: the full price;
-- sim/replay.lua text): Go gives it to the profile of whoever sat there
-- (accounts.go, Award); "" for the bots' seats
local awards = require "sim.awards"
local orders = require "sim.orders"
function CMD.prizes(c)
	local rm = room(c)
	local g = rm.g
	local res = g:results()
	local per_robot, mvp = awards.assign(res.ranking), awards.mvp(res.ranking)
	local raws = {}
	-- the people who started the match (the Smith's orders count only with company)
	local humans = 0
	for _ in pairs(rm.tallies or {}) do humans = humans + 1 end
	for i = 1, #g.robots do
		local t = rm.tallies and rm.tallies[i]
		local mine
		for _, v in ipairs(res.ranking) do
			if v.robot == i then mine = v end
		end
		if t and mine then
			local won = nil
			if res.winner then won = res.winner == mine.team end
			local s = tally.finish(t, g, res, { gruppo = res.mode })
			raws[i] = replay_text.write({ k = "partita",
				r = { points = mine.points, won = won, second = res.mode == "ffa" and mine.place == 2, mvp = mvp == i,
					awards = per_robot[i], online = true },
				conta = { gruppo = res.mode, valori = s.valori, armi = s.armi, won = s.won },
				commesse = orders.summary(res, i, g.map, humans, #(per_robot[i] or {}), s.valori) })
		else
			raws[i] = ""
		end
	end
	answer(nil, raws)
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

-- Guest profiles (server/accounts.go): the profile travels and is stored as
-- the recipes' text (sim/replay.lua, write and read: pure data, never code).
-- profile_new{name, text}: a new profile, from the phone's progress when text
-- is there (sim/profile.lua, import: cut to the caps); profile_do{text,
-- actions, today, last}: the phone's actions on the profile (sim/progress.lua,
-- the same rules as on the phone; last: the number of the last one already
-- done, the ones up to it are skipped).
local profile_rules = require "sim.profile"
local progress = require "sim.progress"
local judge = require "sim.judge"

-- the most actions of one request (the phone's queue sends them together),
-- and the most matches to replay (a second or two each): the phone sends the
-- rest again
local ACTIONS_MAX, MATCHES_MAX = 200, 5
-- the matches played on the phone: paid only replayed (sim/judge.lua)
local MATCH_ACTIONS = { partita = true, missione = true, statistiche = true }

local function summary(p)
	local pieces = 0
	for _ in pairs(p.posseduti or {}) do pieces = pieces + 1 end
	return { livello = p.livello, xp = p.xp, scaglie = p.scaglie, ossidiana = p.ossidiana, pezzi = pieces,
		stelle = profile_rules.total_stars(p) }
end

-- profile_summary{text}: its few numbers (the panel, server/recovery.go)
function CMD.profile_summary(c)
	local p = replay_text.read(c.text)
	if not p then error("profilo illeggibile") end
	answer(summary(p))
end

function CMD.profile_new(c)
	local src = c.text and c.text ~= "" and replay_text.read(c.text)
	if c.text and c.text ~= "" and not src then error("profilo illeggibile") end
	local p = src and profile_rules.import(src) or profile_rules.new()
	p.nome = c.name
	local s = summary(p)
	s.profilo = replay_text.write(p)
	answer(s)
end

function CMD.profile_do(c)
	local p = replay_text.read(c.text)
	if not p then error("profilo illeggibile") end
	local req = { azioni = {} }
	if (c.actions or "") ~= "" then req = replay_text.read(c.actions) end
	if type(req) ~= "table" or type(req.azioni) ~= "table" then error("azioni illeggibili") end
	local last = tonumber(c.last) or 0
	local done, refused, matches = {}, {}, 0
	for i = 1, math.min(#req.azioni, ACTIONS_MAX) do
		local a = req.azioni[i]
		if type(a) == "table" and type(a.n) == "number" and a.n % 1 == 0 and a.n > last then
			local n, k = a.n, type(a.k) == "string" and a.k:sub(1, 20) or "?"
			local why
			if MATCH_ACTIONS[a.k] then
				matches = matches + 1
				if matches > MATCHES_MAX then break end
				local ok, a2, w = pcall(judge.action, p, a)
				if ok and a2 then a = a2 else why = ok and w or "errore" end
			end
			last = n
			if why then
				done[#done + 1] = "non valida " .. k .. " (" .. why .. ")"
				refused[#refused + 1] = n
			else
				local ok, r = pcall(progress.act, p, a, c.today)
				done[#done + 1] = (ok and r) and k or "no " .. k
			end
		end
	end
	local s = summary(p)
	s.profilo = replay_text.write(p)
	s.ultima = last
	s.fatte = table.concat(done, ",")
	-- the matches not paid (the phone's receipt says so, ui/receipt.lua verdict)
	if #refused > 0 then s.rifiutate = refused end
	answer(s)
end

-- profile_cards{text}: what the player of that profile shows and wears online
-- (sim/profile.lua showcase and equip): the server's, never the phone's
function CMD.profile_cards(c)
	local p = replay_text.read(c.text)
	if not p then error("profilo illeggibile") end
	answer({ vetrina = profile_rules.showcase(p), eq = profile_rules.equip(p) })
end

-- profile_award{text, action, today}: an online match's action (prizes) on
-- the profile, done as it is (the server made it); head: the profile and the
-- gain (sim/profile.lua match_end, with the coins), raw: the gain as JSON for
-- the phone's podium
function CMD.profile_award(c)
	local p = replay_text.read(c.text)
	local a = replay_text.read(c.action)
	if not p or not a then error("premio illeggibile") end
	local gain = progress.act(p, a, c.today)
	if not gain then error("premio non dato") end
	local s = summary(p)
	s.profilo = replay_text.write(p)
	s.fatte = "online"
	answer(s, { json(gain) })
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
