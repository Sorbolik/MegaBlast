-- Frame counter: how long each frame really lasts, which ones stutter and
-- why (Sergio, 2 Nov: "come facciamo a misurare gli FPS in maniera affidabile
-- e vedere cosa può avere introdotto dei cali?"). docs/prestazioni.md.
--
-- It measures the real time between one frame and the next (socket.gettime,
-- not the engine's dt) and compares it with the normal frame (the median of
-- the last 10 seconds): a STUTTER is a frame longer than 1.5 times the normal
-- one (at 60 Hz, a missed vsync). For each stutter it gives the most likely cause:
--   - the one marked by whoever did heavy work (M.segna: "dipinto",
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
--   local fotogrammi = require "ui.fotogrammi"
--   fotogrammi.inizio()            -- at the top of the GUI update, every frame
--   fotogrammi.fine()              -- at the bottom of the same update
--   fotogrammi.segna("dipinto")    -- from whoever does heavy work (also from other scripts)
--   fotogrammi.testo()             -- the line to show (nil if it hasn't changed)

local M = {}

-- last 10 seconds at 60 Hz (at 120 Hz, 5 seconds)
local N = 600
local STUTTER = 1.5
-- how often the normal frame and the on-screen line are recomputed (seconds)
local EVERY = 0.25

-- the real clock (LuaSocket is in every Defold build), not CPU time
local now = socket.gettime

M.acceso = false
-- a transition's veil covers everything (ui/passaggio.lua): a stutter now is
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
local summary = { n = 0, scatti = 0, coperti = 0, worst = 0, worst_lua = 0, allocated = 0, t = 0 }

function M.segna(culprit)
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
function M.inizio()
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

-- at the bottom of the GUI update: how much the scripts worked
function M.fine()
	if not lua_start then return end
	lua_work = lua_work + now() - lua_start
end

-- work done outside the update (on_input, messages): t = M.ora() at the start
M.ora = now
function M.lavoro(t)
	if not first_one then return end
	lua_work = lua_work + now() - t
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
function M.testo()
	if not row_changed then return nil end
	row_changed = false
	local n = #sorted
	if n == 0 then return nil end
	local seconds_left = 0
	for i = 1, n do seconds_left = seconds_left + durations[i] end
	local riga = string.format("%.0f FPS  PEGGIORE %.0f MS  99%% SOTTO %.0f  SCATTI %d/MIN",
		n / seconds_left, sorted[n] * 1000, percentile(sorted, n, 0.99) * 1000, stutters_minute())
	if M.ultimo then riga = riga .. "  ULTIMO: " .. string.upper(M.ultimo) end
	return riga
end

-- In the simulator, every so many seconds: a summary line since the previous one
function M.summary()
	local r = summary
	if r.n == 0 then return nil end
	local n = recompute()
	local riga = string.format(
		"SIMULA fotogrammi n=%d fps=%.1f p50=%.1f p95=%.1f p99=%.1f max=%.1f scatti=%d coperti=%d lua_max=%.1f kb_frame=%.1f",
		r.n, r.n / r.t, percentile(sorted, n, 0.5) * 1000, percentile(sorted, n, 0.95) * 1000,
		percentile(sorted, n, 0.99) * 1000, r.worst * 1000, r.scatti, r.coperti, r.worst_lua * 1000, r.allocated / r.n)
	summary = { n = 0, scatti = 0, coperti = 0, worst = 0, worst_lua = 0, allocated = 0, t = 0 }
	return riga
end

return M
