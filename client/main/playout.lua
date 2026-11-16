-- Online playout: the server sends a state every SNAPSHOT_TICKS ticks (30 a
-- second), but over WiFi they don't arrive evenly: one late, then two together
-- (Sergio, 4 Nov: "il primo sparo che faccio del teletrasporto scatta più
-- volte"). Drawing each one as soon as it arrives, a flying orb stops and then
-- jumps ahead. So we keep the states that arrive in a queue and draw them at
-- an even pace, a little behind the newest: as far behind as the latest
-- delays need (at least two states, at most six), and when the line is
-- calm again we get closer, slowly.
--
-- Everything else that came with a state waits in the same queue (Sergio, 16
-- Nov: "tutti vedano esattamente quello che è successo allo stesso modo, è più
-- importante del ritardo"): each state carries its data (the events before it
-- and the state's other fields), handed back by on_reach when the drawing
-- gets there, in order and never skipped. Before, a blast or the Grapple's rope
-- were shown on arrival, ahead of the robots drawn from the queue.
--
--   local p = playout.new(new_pose, capture, period, capture_net)
--   playout.reset(p, g)                    -- start of the match: the current state, shown at once
--   playout.arrive(p, src, now, snaps, data) -- a state arrived: capture_net(pose, src) fills its pose
--   local a, b, k = playout.advance(p, dt, now, on_snap, on_reach)  -- every frame: draw a -> b at k

local M = {}

-- how far behind the newest state we draw, in states
M.LAG_MIN, M.LAG_MAX = 2, 6
-- the delay we remember fades by this much at every state (about 5 s)
M.FADE = 0.995
-- behind or ahead by more than this many states (a second: the game was in
-- the background): jump there. Less than that we catch up, a little faster
M.JUMP = 30

-- capture(pose, g): the pose of a match (reset); capture_net(pose, src): the
-- pose of what arrives (without it, capture)
function M.new(new_pose, capture, period, capture_net)
	return { q = {}, free = {}, n = 0, t = 0, lag = M.LAG_MIN, late = 0,
		new_pose = new_pose, capture = capture, capture_net = capture_net or capture,
		period = period, last_at = nil }
end

local function push(p, capture, src, snaps, data)
	local pose = table.remove(p.free) or p.new_pose()
	capture(pose, src)
	p.n = p.n + 1
	p.q[#p.q + 1] = { pose = pose, n = p.n, snap = snaps, data = data }
end

local function drop_first(p)
	local e = table.remove(p.q, 1)
	p.free[#p.free + 1] = e.pose
end

function M.reset(p, g)
	while #p.q > 0 do drop_first(p) end
	p.n, p.last_at, p.late, p.lag = -1, nil, 0, M.LAG_MIN
	push(p, p.capture, g, nil, nil)
	p.t = 0
end

-- snaps: the robots that teleported or came back since the previous state
-- (i = true), or nil: in this state they are already in the new place.
-- data: what on_reach gets when the drawing arrives at this state
function M.arrive(p, src, now, snaps, data)
	-- (more than a second: the game was in the background or reconnecting, not the WiFi)
	if p.last_at and now - p.last_at < 1 then
		local gap = now - p.last_at
		-- 0 if on time, 1 if a whole state late
		p.late = math.max(gap / p.period - 1, p.late * M.FADE)
		p.lag = math.max(M.LAG_MIN, math.min(M.LAG_MAX, p.late + 0.25))
	end
	p.last_at = now
	-- no limit to the queue: a state's data must never be lost (its digs), and
	-- if nobody drew for a while advance goes through them all at once
	push(p, p.capture_net, src, snaps, data)
end

-- Advances the drawing clock by dt (0 in the hit-stop: the world stands still)
-- and returns the two poses to draw between and how far along (0..1).
-- on_snap(i): robot i reappears elsewhere at the start of this stretch.
-- on_reach(data): the drawing got to a state with data (one call per state, in order).
function M.advance(p, dt, now, on_snap, on_reach)
	-- where we should be: behind the newest by lag, moving on smoothly between arrivals
	local since = p.last_at and math.min(1, (now - p.last_at) / p.period) or 0
	local target = p.n + since - 0.5 - p.lag
	local err = target - p.t
	if err > M.JUMP or err < -M.JUMP then
		p.t = target
	else
		-- a little faster or slower until we are there: a few percent don't show
		p.t = p.t + dt / p.period * (1 + math.max(-0.2, math.min(0.5, err * 0.1)))
	end
	local q = p.q
	p.t = math.max(q[1].n, math.min(p.n, p.t))
	while #q >= 2 and q[2].n <= p.t do
		drop_first(p)
		local data = q[1].data
		if data then
			q[1].data = nil
			on_reach(data)
		end
	end
	-- toward a state where a robot is somewhere else: it is there at once
	local nxt = q[2]
	if nxt and nxt.snap then
		for i in pairs(nxt.snap) do
			local ra, rb = q[1].pose.r[i], nxt.pose.r[i]
			ra.x, ra.y = rb.x, rb.y
			on_snap(i)
		end
		nxt.snap = nil
	end
	local a, b = q[1], q[2] or q[1]
	return a.pose, b.pose, b == a and 0 or p.t - a.n
end

return M
