-- The lights of the battle (Godot's 2D lights brought to Defold, Sergio 13 Nov):
-- every devil's head flame is a warm light that flickers, every explosion a
-- flash that dies out in half a second. Each frame the six strongest go to the
-- render script (render/lit.render_script), which hands them to the pieces'
-- lit materials (battle/light.glsl): x, y in screen pixels, radius, energy.
-- Only the devils of the battle use them (scoria.new(..., lit)).

local game = require "sim.game"

local M = {}
M.__index = M

local SLOTS = 6
-- the head flame: radius in world units, energy (Godot: 1.5 on a darker scene)
local FLAME = { radius = 1.6 * game.DISEGNO_H, energy = 0.8 }
-- an explosion's flash: radius in times the explosion's, energy, seconds
local FLASH = { radius = 2.6, energy = 1.6, life = 0.5 }
-- in battle, with no light near: a bit darker and cooler, so the lights show
-- (Godot darkens the scene too); out of a match the pieces as drawn
M.AMBIENT = vmath.vector4(0.72, 0.70, 0.82, 1)
local WHITE = vmath.vector4(1, 1, 1, 1)
-- world units: the probe's distance from the world's origin (to measure the screen)
local PROBE = 100

-- world: the node that holds the battle (moved and scaled by the camera)
function M.new(world)
	local probe = gui.new_box_node(vmath.vector3(PROBE, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_parent(probe, world)
	gui.set_visible(probe, false)
	local msg_ = {}
	for i = 0, SLOTS - 1 do msg_["l" .. i] = vmath.vector4(0, 0, 1, 0) end
	msg_.ambient = WHITE
	return setmetatable({ world = world, probe = probe, flashes = {}, msg = msg_, t = 0, list = {}, sent_off = nil }, M)
end

-- an explosion at (x, y) in the world, of radius r
function M.flash(L, x, y, r)
	local f = L.flashes
	f[#f + 1] = { x = x, y = y, r = r * FLASH.radius, t = 0 }
end

function M.reset(L)
	L.flashes = {}
end

local function by_energy(a, b)
	if a.e ~= b.e then return a.e > b.e end
	return a.k < b.k
end

-- flames: the flame nodes of the devils on screen (nil holes allowed up to n).
-- The lights are in screen pixels, like the positions the pieces' shader sees
-- (on the phone the screen has more pixels than the 1280 x 720 of the gui)
function M.update(L, dt, flames, n)
	L.t = L.t + dt
	local list, k = L.list, 0
	-- screen to world: the world's origin and the probe, on the screen
	local o = gui.get_screen_position(L.world)
	local p = gui.get_screen_position(L.probe)
	local per = (p.x - o.x) / PROBE  -- screen units per world unit
	if per ~= 0 then
		for i = 1, n do
			local f = flames[i]
			if f then
				local s = gui.get_screen_position(f)
				k = k + 1
				local e = list[k] or {}
				list[k] = e
				e.x, e.y, e.r = s.x, s.y, FLAME.radius * per
				e.e = FLAME.energy * (1 + 0.17 * math.sin(L.t * 11 + i) * math.sin(L.t * 6.1 + 2 * i))
				e.k = k
			end
		end
	end
	local fl = L.flashes
	for i = #fl, 1, -1 do
		local f = fl[i]
		f.t = f.t + dt
		if f.t >= FLASH.life then
			table.remove(fl, i)
		else
			k = k + 1
			local e = list[k] or {}
			list[k] = e
			local q = 1 - f.t / FLASH.life
			e.x, e.y, e.r = o.x + f.x * per, o.y + f.y * per, f.r * per
			e.e, e.k = FLASH.energy * q * q, k
		end
	end
	for i = k + 1, #list do list[i] = nil end
	L.msg.ambient = M.AMBIENT
	if k == 0 and L.sent_off == "battle" then return end
	L.sent_off = k == 0 and "battle"
	if k > SLOTS then table.sort(list, by_energy) end
	for i = 1, SLOTS do
		local v, e = L.msg["l" .. (i - 1)], list[i]
		if e then
			v.x, v.y, v.z, v.w = e.x, e.y, e.r, e.e
		else
			v.w = 0
		end
	end
	msg.post("@render:", "lights", L.msg)
end

-- out of the battle: no lights
function M.off(L)
	L.flashes = {}
	if L.sent_off == "off" then return end
	L.sent_off = "off"
	for i = 0, SLOTS - 1 do L.msg["l" .. i].w = 0 end
	L.msg.ambient = WHITE
	msg.post("@render:", "lights", L.msg)
end

return M
