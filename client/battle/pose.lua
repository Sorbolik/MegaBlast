-- The devil's animation clips (battle/animations.lua, made with the
-- editor strumenti/animazioni/editor.html): keyframes per channel, sampled at
-- any time, so motion is smooth at every frame rate.
--
-- A clip: { duration = seconds, loop = true if it loops, tracks = { channel =
-- { t, v, curve, t, v, curve, ... } }, face = { t, "face", ... },
-- layers = { pieces from the back }, held_by = "who holds the weapon" }. The
-- curve says how to go from one key to the next: 0 smooth, 1 linear, 2 step.
-- Channels a clip doesn't have stay neutral.
--
-- Several clips add up into a pose with a weight (running fading into idle,
-- the jump going up or down): each adds weight * (value - neutral).
--   local posa = pose.nuova()
--   pose.azzera(posa); pose.aggiungi(posa, clip, t, weight)   -- no allocation
-- posa.clip is the clip with the biggest weight: it gives the layers and who grips the weapon.

local M = {}

-- the channels and their neutral value; angles in radians, sizes in drawing
-- units (battle/devil.lua, 200 from feet to head)
M.CHANNELS = { "corpo", "salto", "schiaccia", "testa", "testa_y", "braccio_a", "braccio_d",
	"gamba_a", "gamba_d", "alza_a", "alza_d", "ala", "fiamma",
	-- the torso: turns around its pivot and moves (busto_x, busto_y); the
	-- tail curls (coda) and turns as a whole around its pivot (coda_gira)
	"busto", "coda", "coda_gira",
	-- forward and back moves (x, toward where it faces) and up and down (y)
	"corpo_x", "testa_x", "busto_x", "busto_y", "braccio_a_x", "braccio_a_y", "braccio_d_x", "braccio_d_y",
	"gamba_a_x", "gamba_d_x", "ala_x", "ala_y", "coda_x", "coda_y", "fiamma_x", "fiamma_y",
	-- the flame squash and stretch
	"fiamma_schiaccia", "fiamma_scala_x", "fiamma_scala_y",
	-- the weapon in hand: how much more it turns around its pivot when not
	-- aiming, and the pivot's offset
	"arma", "arma_x", "arma_y",
	-- the detached little hands: free pieces on the body, at rest where the
	-- hanging arms end; they turn and move
	"manina_a", "manina_d", "manina_a_x", "manina_a_y", "manina_d_x", "manina_d_y",
	-- the pieces shown (1) or not (0): the editor's bucket puts and removes them
	"mostra_testa", "mostra_fiamma", "mostra_busto", "mostra_braccio_a", "mostra_braccio_d", "mostra_gamba_a", "mostra_gamba_d",
	"mostra_ala", "mostra_coda", "mostra_manina_a", "mostra_manina_d", "mostra_arma" }
M.NEUTRAL = { schiaccia = 1, fiamma_schiaccia = 1, fiamma_scala_x = 1, fiamma_scala_y = 1 }
for _, c in ipairs(M.CHANNELS) do
	if c:find("^mostra_") and c ~= "mostra_manina_a" and c ~= "mostra_manina_d" then M.NEUTRAL[c] = 1 end
end
for _, c in ipairs(M.CHANNELS) do M.NEUTRAL[c] = M.NEUTRAL[c] or 0 end

local floor = math.floor

function M.nuova()
	local p = { face_name = nil, face_weight = 0 }
	M.azzera(p)
	return p
end

function M.azzera(p)
	local neutral, channels = M.NEUTRAL, M.CHANNELS
	for i = 1, #channels do
		local c = channels[i]
		p[c] = neutral[c]
	end
	p.face_name, p.face_weight = nil, 0
	p.clip, p.clip_weight = nil, 0
end

-- the time inside the clip: looping it wraps, otherwise it stops at the end
local function inside(clip, t)
	local d = clip.duration
	if clip.loop then return t - floor(t / d) * d end
	return t < 0 and 0 or (t > d and d or t)
end

-- the slope at a key (i: key index, from 0), from its neighbors: for the
-- smooth curve (Catmull-Rom). At the ends of a non-looping clip it is
-- flat, so it starts and arrives gently
local function slope(tr, i, n, d, cycle)
	local ta, va, tb, vb
	if i > 0 then
		ta, va = tr[3 * i - 2], tr[3 * i - 1]
	elseif cycle and n > 1 then
		ta, va = tr[3 * n - 2] - d, tr[3 * n - 1]
	else
		return 0
	end
	if i < n - 1 then
		tb, vb = tr[3 * i + 4], tr[3 * i + 5]
	elseif cycle and n > 1 then
		tb, vb = tr[1] + d, tr[2]
	else
		return 0
	end
	if tb - ta < 1e-9 then return 0 end
	return (vb - va) / (tb - ta)
end

-- the value of a track at time t (already inside the clip)
function M.valore(tr, t, d, cycle)
	local n = #tr / 3
	if n == 1 then return tr[2] end
	-- the key before t (i, from 0) and the one after (j); looping, before the
	-- first key it comes from the last one of the previous loop
	local i = -1
	for k = 0, n - 1 do
		if tr[3 * k + 1] <= t then i = k else break end
	end
	local t0, t1, j
	if i < 0 then
		if not cycle then return tr[2] end
		i, j = n - 1, 0
		t0, t1 = tr[3 * n - 2] - d, tr[1]
	elseif i == n - 1 then
		if not cycle then return tr[3 * n - 1] end
		j = 0
		t0, t1 = tr[3 * i + 1], tr[1] + d
	else
		j = i + 1
		t0, t1 = tr[3 * i + 1], tr[3 * j + 1]
	end
	local v0, v1, curve = tr[3 * i + 2], tr[3 * j + 2], tr[3 * i + 3]
	local h = t1 - t0
	if curve == 2 or h < 1e-9 then return v0 end
	local u = (t - t0) / h
	if curve == 1 then return v0 + (v1 - v0) * u end
	local m0, m1 = slope(tr, i, n, d, cycle) * h, slope(tr, j, n, d, cycle) * h
	local u2, u3 = u * u, u * u * u
	return (2 * u3 - 3 * u2 + 1) * v0 + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * v1 + (u3 - u2) * m1
end

-- adds the clip at time t to the pose, with its weight
function M.aggiungi(p, clip, t, weight)
	if weight <= 0 then return end
	t = inside(clip, t)
	local d, cycle = clip.duration, clip.loop
	for c, tr in pairs(clip.tracks) do
		p[c] = p[c] + weight * (M.valore(tr, t, d, cycle) - M.NEUTRAL[c])
	end
	if weight > p.clip_weight then p.clip, p.clip_weight = clip, weight end
	local visage = clip.face
	if visage and weight > p.face_weight then
		-- the face steps: the last key not after t (before the first one, looping,
		-- the last one of the previous loop)
		local f = cycle and visage[#visage] or visage[2]
		for k = 1, #visage, 2 do
			if visage[k] <= t then f = visage[k + 1] else break end
		end
		p.face_name, p.face_weight = f, weight
	end
end

return M
