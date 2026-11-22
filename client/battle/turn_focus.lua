-- Who is the screen for (Sergio, 21 Nov, docs/decisioni/interfaccia.md).
--
-- - On the others' turn the buttons go very see-through (FADE_LOW) but stay
--   touchable: you can already put a weapon in hand and see the whole scene.
-- - On your turn the points look in for a moment (LOOK seconds, the summary)
--   then slide up off the screen (OUT pixels); the camera then keeps what it
--   follows LIFT pixels higher, so the map rises above the buttons. The numbers
--   of the hits still fly up toward the points and leave the screen.
-- - The last TENSION_S seconds of your turn the scene closes in very slowly
--   (up to ZOOM) and warms toward the embers (SHADE, a multiply over the world,
--   under the HUD): faster and faster toward the end, nothing blinks.
--
--   focus.capture_begin()               -- before making the buttons
--   focus.capture_end(roots)            -- after: their nodes take the alpha of the roots
--   local f = focus.new()
--   focus.update(f, dt, mine, key, clock) -- every frame; mine: it's the turn of
--     whoever holds the phone; key changes at every new turn of theirs
--   f.alpha (the buttons), f.hide (0..1, the points away), f.lift (camera pixels)
--   focus.tension(f, dt, left)           -- left: seconds of your turn left (nil: not your turn)
--   f.zoom (camera factor), f.shade (multiply color), f.shading (shade to draw)

local M = {}

M.FADE_LOW = 0.2
M.LOOK, M.OUT, M.LIFT = 1.6, 150, 60
M.TENSION_S, M.ZOOM = 8, 0.09
M.SHADE = vmath.vector4(0.7, 0.5, 0.4, 1)

local exp, max, min, floor = math.exp, math.max, math.min, math.floor

-- The buttons are made by many modules (ui.lua, hud.lua) and their nodes only
-- take the alpha of their root if they inherit it: while the buttons are
-- being made, every new node is noted, then those under a root inherit
local MAKERS = { "new_box_node", "new_text_node", "new_pie_node" }
local made, originals

function M.capture_begin()
	made, originals = {}, {}
	for _, f in ipairs(MAKERS) do
		local orig = gui[f]
		originals[f] = orig
		gui[f] = function(...)
			local n = orig(...)
			made[#made + 1] = n
			return n
		end
	end
end

function M.capture_end(roots)
	for _, f in ipairs(MAKERS) do gui[f] = originals[f] end
	-- an invisible parent passes no alpha down: the empty holders (size 0) are
	-- made visible, they draw nothing anyway
	for _, r in ipairs(roots) do
		if not gui.get_visible(r) then gui.set_visible(r, true) end
	end
	-- (node handles compare with ==, not as table keys)
	for _, n in ipairs(made) do
		local p, under = gui.get_parent(n), false
		while p and not under do
			for _, r in ipairs(roots) do
				if p == r then under = true; break end
			end
			p = gui.get_parent(p)
		end
		if under then gui.set_inherit_alpha(n, true) end
	end
	made, originals = nil, nil
end

function M.new()
	return { k = 1, alpha = 1, hide = 0, lift = 0, hold = 0, e = 0, zoom = 1,
		shade = vmath.vector4(1, 1, 1, 1), shading = false }
end

local function toward(v, target, dt, rate)
	return v + (target - v) * (1 - exp(-dt * rate))
end

function M.update(f, dt, mine, key, clock)
	if key and key ~= f.key then f.hold = clock + M.LOOK end
	f.key = key
	f.k = toward(f.k, mine and 1 or 0, dt, 7)
	-- in hundredths: the roots are recolored only when it really changes
	f.alpha = floor((M.FADE_LOW + (1 - M.FADE_LOW) * f.k) * 100 + 0.5) / 100
	f.hide = toward(f.hide, (mine and clock > f.hold) and 1 or 0, dt, 6)
	if f.hide < 1e-3 then f.hide = 0 elseif f.hide > 1 - 1e-3 then f.hide = 1 end
	f.lift = f.hide * M.LIFT
end

function M.tension(f, dt, left)
	local e = left and max(0, min(1, (M.TENSION_S - left) / M.TENSION_S)) or 0
	e = e * e
	-- it comes in slowly and goes away fast (the turn is over)
	f.e = toward(f.e, e, dt, e > f.e and 3 or 6)
	if f.e < 0.002 then f.e = 0 end
	f.zoom = 1 + M.ZOOM * f.e
	f.shading = f.e > 0
	local s, sh = f.shade, M.SHADE
	s.x, s.y, s.z = 1 + (sh.x - 1) * f.e, 1 + (sh.y - 1) * f.e, 1 + (sh.z - 1) * f.e
end

return M
