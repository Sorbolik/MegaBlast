-- Le due levette della battaglia sul telefono, come in Blastron (ButtonJoystick
-- e ButtonAim), con qualche ritocco. Qui c'è solo la logica, senza nodi GUI,
-- così si prova con luajit (tests/sim_test.lua). Le posizioni x, y sono
-- frazioni della corsa: (0, 0) al centro, lunghezza 1 sul bordo.
--
-- Ritocchi rispetto a Blastron:
-- - la levetta del movimento riportata al centro si ferma (in Blastron il
--   robot continuava a camminare finché non si alzava il dito);
-- - il colpo parte con la mira di RILASCIO secondi prima di staccare il dito,
--   così lo scivolamento del pollice mentre si alza non sposta il tiro;
-- - i tempi sono in secondi, non in fotogrammi.

local M = {}

local rad, sin = math.rad, math.sin

-- Movimento (valori del Tuning di Blastron)
M.MOVE_START = 0.15 -- di lato oltre il 15% cammina...
M.MOVE_START_ANGLE = rad(60) -- ...se non punta più in alto di 60°
M.MOVE_STOP = 0.25 -- spinta in alto oltre 60° e oltre il 25% smette di camminare
M.MOVE_STOP_ANGLE = rad(60)
M.LATERAL_DEAD = 0.25 -- verso il basso serve il 25% di lato
M.MOVE_CENTER = 0.1 -- nostro: sotto il 10% (dito tornato al centro) si ferma
M.JUMP_START = 0.25 -- in alto oltre 25° e oltre il 25% salta, e risalta finché resta lì
M.JUMP_START_ANGLE = rad(25)
M.JUMP_STOP = 0.25 -- smette sotto 22,5° o sotto il 25%
M.JUMP_STOP_ANGLE = rad(22.5)

-- Mira: oltre il 20% la levetta si accende (si può sparare), sotto il 10% si
-- spegne (lasciando non parte niente). La potenza parte dal 20%.
M.AIM_ON = 0.2
M.AIM_OFF = 0.1
M.RILASCIO = 0.05

function M.new()
	return { moving = false, dir = 0, jumping = false, active = false, angle = 0, f = 0,
		hist = {}, hist_i = 0 }
end

function M.reset(s)
	s.moving, s.dir, s.jumping, s.active, s.f = false, 0, false, false, 0
	for i = 1, #s.hist do s.hist[i].t = -math.huge end
end

-- Il dito della levetta del movimento è in (x, y). Torna true quando parte un
-- salto (il salto ripetuto finché la levetta resta in alto lo fa la simulazione).
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
	-- la direzione cambia solo con il dito davvero da un lato
	if math.abs(x) > 0.05 then s.dir = x < 0 and -1 or 1 end
	local was = s.jumping
	if s.jumping and (up < sin(M.JUMP_STOP_ANGLE) or mag < M.JUMP_STOP) then s.jumping = false end
	if not s.jumping and up > sin(M.JUMP_START_ANGLE) and mag > M.JUMP_START then s.jumping = true end
	return s.jumping and not was
end

-- Il dito della levetta della mira è in (x, y): direzione e potenza (0..1)
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

-- Ogni frame: com'era la mira all'istante t (in secondi)
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

-- Mira con cui sparare se il dito si stacca all'istante t: l'ultima registrata
-- almeno RILASCIO secondi prima; se non ce n'è, la più vecchia; nil se nessuna.
function M.al_rilascio(s, t)
	local best, oldest
	for _, h in ipairs(s.hist) do
		if h.t > -math.huge then
			if h.t <= t - M.RILASCIO and (not best or h.t > best.t) then best = h end
			if not oldest or h.t < oldest.t then oldest = h end
		end
	end
	return best or oldest
end

return M
