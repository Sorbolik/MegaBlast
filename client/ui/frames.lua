-- Frame counter: how long each frame really lasts, which ones stutter and
-- why (Sergio, 2 Nov: "come facciamo a misurare gli FPS in maniera affidabile
-- e vedere cosa può avere introdotto dei cali?"). docs/prestazioni.md.
--
-- It measures the real time between one frame and the next (socket.gettime,
-- not the engine's dt) and compares it with the normal frame (the median of
-- the last 10 seconds): a STUTTER is a frame longer than 1.5 times the normal
-- one (at 60 Hz, a missed vsync). For each stutter it gives the most likely cause:
--   - the one marked by whoever did heavy work (M.mark: "dipinto",
--     "maschera", "schermata ..."), in the previous frame or in this one;
--   - "gc" if Lua's memory went down (the collector ran);
--   - "lua" if in the previous frame the scripts worked more than half the stutter;
--   - otherwise "motore" (drawing, GPU, operating system).
--
-- It is switched on from the IMPOSTAZIONI (CONTATORE FPS): at the top center
-- FPS, worst frame, stutters in the last minute and the last one with its
-- cause; every stutter also goes to the console (the Defold editor's, on the
-- PC). In the simulator it is always on and writes the "SIMULA scatto" and
-- "SIMULA fotogrammi" lines that simula.py collects in simulazione/fotogrammi.txt.
--
--   local fotogrammi = require "ui.frames"
--   fotogrammi.inizio()            -- at the top of the GUI update, every frame
--   fotogrammi.fine()              -- at the bottom of the same update (also a small collector step)
--   fotogrammi.segna("dipinto")    -- from whoever does heavy work (also from other scripts)
--   fotogrammi.testo()             -- the line to show (nil if it hasn't changed)
--   fotogrammi.rete(gap)           -- online: seconds between this state from the server and the previous one
--   fotogrammi.scope("bot") ... fotogrammi.scope_end()   -- a named bar in Defold's web profiler
--
-- Online the line also says RETE: the longest wait between two states from
-- the server in the last 10 seconds (normally 33 ms). The drawing hides the
-- waits up to four states (main/playout.lua); a longer one is a stop you see
-- even if the FPS are fine.

local T = require("lang.text").frames

local M = {}

-- last 10 seconds at 60 Hz (at 120 Hz, 5 seconds)
local N = 600
local STUTTER = 1.5
-- how often the normal frame and the on-screen line are recomputed (seconds)
local EVERY = 0.25

-- the real clock (LuaSocket is in every Defold build), not CPU time
local now = socket.gettime

M.acceso = false
-- a transition's veil covers everything (ui/transition.lua): a stutter now is
-- not seen, it is written "(coperto)" and doesn't count among the stutters
M.covered = false
-- in the simulator: log lines for simula.py
M.log = false

local durations = {}
for i = 1, N do durations[i] = 0 end
local pos, full_ms = 0, 0
local sorted = {}
local normal = 1 / 60
local first_one, lua_start, lua_work = nil, nil, 0
local memory
-- causes marked in this frame and in the previous one
local cause, causes_before = nil, nil
-- the veil also covered the previous frame (a stutter is paid one frame later)
local covered_before = false
-- the stutters (time, duration, cause) of the last minute, in a ring (1024 is enough even at 120 Hz all stutters)
local stutters, n_stutters = {}, 0
local clock, computed = 0, 0
local row_changed = false
-- the summary for the simulator (since the last summary)
local summary = { n = 0, scatti = 0, coperti = 0, worst = 0, worst_lua = 0, allocated = 0, t = 0, rete = 0 }
-- online: the waits between states of the last 10 seconds (time, seconds), in a ring
local gaps, n_gaps = {}, 0
local GAPS = 512

function M.mark(culprit)
	cause = cause and (cause .. "+" .. culprit) or culprit
end

local function percentile(list_of, n, p)
	if n == 0 then return 0 end
	return list_of[math.max(1, math.min(n, math.ceil(n * p)))]
end

local function recompute()
	local n = full_ms
	for i = 1, n do sorted[i] = durations[i] end
	for i = n + 1, #sorted do sorted[i] = nil end
	table.sort(sorted)
	return n
end

-- at the top of the GUI update: closes the previous frame
function M.begin()
	-- off: no work (switched back on, it starts from zero)
	if not (M.acceso or M.log) then
		first_one, lua_start, lua_work = nil, nil, 0
		return
	end
	local t = now()
	lua_start = t
	local kb = collectgarbage("count")
	if not first_one then
		first_one, memory, lua_work = t, kb, 0
		return
	end
	local dt = t - first_one
	first_one = t
	-- more than a second: the game was paused or in the background, not a stutter
	if dt > 1 then
		memory, cause, causes_before, lua_work = kb, nil, nil, 0
		return
	end
	pos = pos % N + 1
	durations[pos] = dt
	full_ms = math.min(full_ms + 1, N)
	clock = clock + dt
	-- Lua's memory: if it went down the collector ran
	local gc = kb < memory
	if not gc then summary.allocated = summary.allocated + (kb - memory) end
	memory = kb

	summary.n = summary.n + 1
	summary.t = summary.t + dt
	if dt > summary.worst then summary.worst = dt end
	if lua_work > summary.worst_lua then summary.worst_lua = lua_work end

	-- the normal frame: the median, 4 times a second
	if clock - computed >= EVERY then
		computed = clock
		normal = percentile(sorted, recompute(), 0.5)
		row_changed = true
	end

	local covered = M.covered or covered_before
	covered_before = M.covered
	if full_ms >= 30 and dt > normal * STUTTER then
		-- the work marked in this frame is paid now; the previous frame's sometimes
		-- a frame later (the GPU uploading a texture)
		local culprit = cause or causes_before
		causes_before = nil
		if not culprit then
			if gc then culprit = "gc"
			elseif lua_work > (dt - normal) * 0.5 then culprit = "lua"
			else culprit = "motore" end
		end
		if covered then
			culprit = culprit .. " (coperto)"
			summary.coperti = summary.coperti + 1
		else
			n_stutters = n_stutters % 1024 + 1
			stutters[n_stutters] = { clock, dt, culprit }
			summary.scatti = summary.scatti + 1
			M.ultimo = string.format("%s %.0f ms", culprit, dt * 1000)
			row_changed = true
		end
		if M.acceso or M.log then
			print(string.format("%s %.1f ms (normale %.1f, lua %.1f ms) causa: %s",
				M.log and "SIMULA scatto" or "SCATTO", dt * 1000, normal * 1000, lua_work * 1000, culprit))
		end
	end
	causes_before, cause = cause, nil
	lua_work = 0
end

-- Lua's collector a little at every frame (the Defold manual, "Lua in Defold":
-- «run the collector for a short time every frame with a low step value»), so
-- it keeps up with the garbage instead of stopping a frame now and then. What
-- our step frees doesn't count as "gc" in the counter: only the collector's own
-- runs do. KB of work per frame (collectgarbage "step"); docs/prestazioni.md, Fase 1
M.GC_STEP = 8
local function gc_step()
	local before = collectgarbage("count")
	collectgarbage("step", M.GC_STEP)
	if memory then memory = memory - (before - collectgarbage("count")) end
end

-- at the bottom of the GUI update: how much the scripts worked
function M.finish()
	gc_step()
	if not lua_start then return end
	lua_work = lua_work + now() - lua_start
end

-- work done outside the update (on_input, messages): t = M.ora() at the start
M.ora = now

-- Named scopes for Defold's profiler (debug builds, http://localhost:8002 on
-- the PC): the heavy work shows up as its own bar. Every scope must close in
-- the same frame. Where there is no profiler (release builds, the tests) they do nothing.
local profiler = rawget(_G, "profiler")
local nothing = function() end
M.scope = profiler and profiler.scope_begin or nothing
M.scope_end = profiler and profiler.scope_end or nothing
function M.work(t)
	if not first_one then return end
	lua_work = lua_work + now() - t
end

function M.net(gap)
	n_gaps = n_gaps % GAPS + 1
	gaps[n_gaps] = { clock, gap }
	if gap > summary.rete then summary.rete = gap end
end

-- the longest wait between states in the last 10 seconds, or nil
local function worst_gap()
	local w
	for i = 1, #gaps do
		local e = gaps[i]
		if clock - e[1] <= 10 and (not w or e[2] > w) then w = e[2] end
	end
	return w
end

-- how many stutters in the last minute
local function stutters_minute()
	local n = 0
	for i = 1, #stutters do
		if clock - stutters[i][1] <= 60 then n = n + 1 end
	end
	return n
end

-- The on-screen line, 4 times a second (nil if there is nothing new)
function M.text()
	if not row_changed then return nil end
	row_changed = false
	local n = #sorted
	if n == 0 then return nil end
	local seconds_left = 0
	for i = 1, n do seconds_left = seconds_left + durations[i] end
	local riga = T.row:format(
		n / seconds_left, sorted[n] * 1000, percentile(sorted, n, 0.99) * 1000, stutters_minute())
	local net = worst_gap()
	if net then riga = riga .. T.net:format(net * 1000) end
	if M.ultimo then riga = riga .. T.last:format(string.upper(M.ultimo)) end
	return riga
end

-- In the simulator, every so many seconds: a summary line since the previous one
function M.summary()
	local r = summary
	if r.n == 0 then return nil end
	local n = recompute()
	local riga = string.format(
		"SIMULA fotogrammi n=%d fps=%.1f p50=%.1f p95=%.1f p99=%.1f max=%.1f scatti=%d coperti=%d lua_max=%.1f kb_frame=%.1f rete_max=%.0f",
		r.n, r.n / r.t, percentile(sorted, n, 0.5) * 1000, percentile(sorted, n, 0.95) * 1000,
		percentile(sorted, n, 0.99) * 1000, r.worst * 1000, r.scatti, r.coperti, r.worst_lua * 1000, r.allocated / r.n, r.rete * 1000)
	summary = { n = 0, scatti = 0, coperti = 0, worst = 0, worst_lua = 0, allocated = 0, t = 0, rete = 0 }
	return riga
end

return M
