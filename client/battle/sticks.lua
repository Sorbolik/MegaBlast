-- The two battle sticks on the phone: movement on the left, aim on the
-- right. Only the logic lives here, no GUI nodes, so it can be tested with
-- luajit (tests/sim_test.lua). Positions x, y are fractions of the travel:
-- (0, 0) at the center, length 1 at the edge.
--
-- - the movement stick brought back to the center stops;
-- - the shot fires with the aim from RELEASE seconds before the finger lifts,
--   so the thumb sliding as it lifts doesn't move the shot;
-- - times are in seconds.

local M = {}

local rad, sin = math.rad, math.sin

-- Movement
M.MOVE_START = 0.15 -- sideways past 15% walks...
M.MOVE_START_ANGLE = rad(60) -- ...if it doesn't point higher than 60°
M.MOVE_STOP = 0.25 -- pushed up past 60° and past 25% stops walking
M.MOVE_STOP_ANGLE = rad(60)
M.LATERAL_DEAD = 0.25 -- pointing down it takes 25% sideways
M.MOVE_CENTER = 0.1 -- below 10% (finger back at the center) it stops
M.JUMP_START = 0.25 -- up past 25° and past 25% jumps, and jumps again while it stays there
M.JUMP_START_ANGLE = rad(25)
M.JUMP_STOP = 0.25 -- stops below 22.5° or below 25%
M.JUMP_STOP_ANGLE = rad(22.5)

-- Aim: past 20% the stick lights up (you can fire), below 10% it goes off
-- (releasing fires nothing). Power starts from 20%.
M.AIM_ON = 0.2
M.AIM_OFF = 0.1
M.RELEASE = 0.05

function M.new()
	return { moving = false, dir = 0, jumping = false, active = false, angle = 0, f = 0,
		hist = {}, hist_i = 0 }
end

function M.reset(s)
	s.moving, s.dir, s.jumping, s.active, s.f = false, 0, false, false, 0
	for i = 1, #s.hist do s.hist[i].t = -math.huge end
end

-- The movement stick's finger is at (x, y). Returns true when a jump starts
-- (the repeated jump while the stick stays up is done by the simulation).
function M.muovi(s, x, y)
	local mag = math.sqrt(x * x + y * y)
	local up = mag > 0 and y / mag or 0
	if s.moving and ((up > sin(M.MOVE_STOP_ANGLE) and mag > M.MOVE_STOP) or mag < M.MOVE_CENTER) then
		s.moving = false
	end
	if not s.moving then
		if up > 0 then
			s.moving = up < sin(M.MOVE_START_ANGLE) and mag > M.MOVE_START
		else
			s.moving = math.abs(x) > M.LATERAL_DEAD
		end
	end
	-- the direction changes only with the finger really to one side
	if math.abs(x) > 0.05 then s.dir = x < 0 and -1 or 1 end
	local was = s.jumping
	if s.jumping and (up < sin(M.JUMP_STOP_ANGLE) or mag < M.JUMP_STOP) then s.jumping = false end
	if not s.jumping and up > sin(M.JUMP_START_ANGLE) and mag > M.JUMP_START then s.jumping = true end
	return s.jumping and not was
end

-- The aim stick's finger is at (x, y): direction and power (0..1)
function M.mira(s, x, y)
	local mag = math.sqrt(x * x + y * y)
	if not s.active and mag > M.AIM_ON then
		s.active = true
	elseif s.active and mag < M.AIM_OFF then
		s.active = false
	end
	if mag > 0.02 then s.angle = math.atan2(y, x) end
	s.f = math.max(0, math.min(1, (mag - M.AIM_ON) / (1 - M.AIM_ON)))
end

-- Every frame: what the aim was at instant t (in seconds)
local HIST = 24
function M.registra(s, t, angle, power, active)
	s.hist_i = s.hist_i % HIST + 1
	local h = s.hist[s.hist_i]
	if not h then
		h = {}
		s.hist[s.hist_i] = h
	end
	h.t, h.angle, h.power, h.active = t, angle, power, active
end

-- Aim to fire with if the finger lifts at instant t: the last one recorded
-- at least RELEASE seconds earlier; if there is none, the oldest; nil if none.
function M.on_release(s, t)
	local best, oldest
	for _, h in ipairs(s.hist) do
		if h.t > -math.huge then
			if h.t <= t - M.RELEASE and (not best or h.t > best.t) then best = h end
			if not oldest or h.t < oldest.t then oldest = h end
		end
	end
	return best or oldest
end

-- Angle and power the shot fires with if the finger lifts at instant t: the
-- recorded aim of on_release when it was lit, otherwise (angle, power) as they
-- are now. The lessons' trajectory shows this one too, so it doesn't follow
-- the last instants of the finger that the shot ignores.
function M.shot(s, t, angle, power)
	local h = M.on_release(s, t)
	if h and h.active then return h.angle, h.power end
	return angle, power
end

return M
