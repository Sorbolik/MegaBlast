-- The phone's sticks on the screen: the movement one on the left, the aim one on
-- the right (the logic, what the thumb means, is battle/sticks.lua). The drawing
-- and the thumb's place, the same in battle (main/game.gui_script) and in the
-- Forge (menu/forge_ui.lua): the base goes where the thumb rests, within its zone,
-- and goes back to its place when the thumb lifts.
--
--   local SP = require "battle.stick_pad"
--   local pad = SP.new(SP.AIM_PAD, SP.AIM_IDLE)   -- (jump: the movement stick's ticks)
--   SP.press(pad, id, x, y); local dx, dy = SP.drag(pad, x, y); SP.release(pad, SP.AIM_IDLE)
--   SP.color(pad, SP.AIM_LIVE)                     -- the state's color on both borders
--   SP.arrange(x0, y0, x1, y1)                     -- the real screen's edges (screen.lua)

local ui = require "ui.ui"
local sticks = require "battle.sticks"
local screen = require "ui.screen"

local M = {}

local W, H = 1280, 720
M.R = 94                 -- stick travel
M.D = 2 * M.R + 28       -- drawing of the base
M.KNOB_D = 112
M.MOVE_PAD = { x = 115, y = 117 }
M.AIM_PAD = { x = W - 115, y = 117 }
-- the sticks are grabbed in the left and right 40%, below 60% of the height
M.ZONE = { sx = W * 0.4, dx = W * 0.6, y = H * 0.6 }
-- aim ring: light blue when off, red when releasing fires the shot
M.AIM_IDLE = vmath.vector4(0.35, 0.85, 1, 0.35)
M.AIM_LIVE = vmath.vector4(1, 0.22, 0.16, 0.95)
M.MOVE_IDLE = vmath.vector4(1, 1, 1, 0.16)
M.MOVE_LIVE = vmath.vector4(1, 0.85, 0.55, 0.6)
-- fill of the base and of the knob
local BOTTOM = { vmath.vector4(1, 1, 1, 0.05), vmath.vector4(1, 1, 1, 0.08) }

local POS = vmath.vector3(0, 0, 0)

-- The phone's sticks are on (battle: set_touch_ui writes M.touch; before any battle,
-- the device decides): the same choice in battle and in the Forge
local COMMANDS = sys.get_config_string("megablast.comandi", "")
function M.touch_device()
	if COMMANDS == "telefono" then return true end
	if COMMANDS == "computer" then return false end
	local name = sys.get_sys_info().system_name
	if name == "Android" or name == "iPhone OS" then return true end
	if name == "HTML5" and html5 then
		return html5.run("('ontouchstart' in window) || navigator.maxTouchPoints > 0") == "true"
	end
	return false
end

function M.on()
	if M.touch == nil then M.touch = M.touch_device() end
	return M.touch
end

local function fit(node)
	gui.set_adjust_mode(node, gui.ADJUST_FIT)
	return node
end

-- The places on the real screen (screen.lua): the sticks at the bottom corners
function M.arrange(x0, y0, x1, y1)
	M.MOVE_PAD.x, M.MOVE_PAD.y = x0 + 115, y0 + 117
	M.AIM_PAD.x, M.AIM_PAD.y = x1 - 115, y0 + 117
	M.ZONE.sx, M.ZONE.dx, M.ZONE.y = x0 + (x1 - x0) * 0.4, x1 - (x1 - x0) * 0.4, y0 + (y1 - y0) * 0.6
end

-- Stick as in the proposals: a faintly veiled disc with a border and a
-- matching knob; both borders take the state's color (M.color).
-- jump: on the border the ticks of the arc where the stick jumps (from
-- sticks.JUMP_START_ANGLE above the horizontal, on both sides), longer at the
-- two ends; they light up while jumping
function M.new(rest, ring_color, jump_name)
	local pad = { rest = rest }
	pad.base = fit(ui.disc(rest.x, rest.y, M.D, BOTTOM[1]))
	pad.ring = fit(ui.ring_node(0, 0, M.D, 3, ring_color, pad.base))
	if jump_name then
		pad.ticks, pad.tick_off, pad.tick_on = {}, vmath.vector4(1, 1, 1, 0.4), vmath.vector4(1, 0.85, 0.55, 1)
		local a0, n = math.deg(sticks.JUMP_START_ANGLE), 9
		for i = 0, n - 1 do
			local a = a0 + (180 - 2 * a0) * i / (n - 1)
			local long = (i == 0 or i == n - 1) and 16 or 9
			local r = M.D / 2 - 4 - long / 2
			local t = fit(gui.new_box_node(vmath.vector3(r * math.cos(math.rad(a)), r * math.sin(math.rad(a)), 0),
				vmath.vector3(long, (i == 0 or i == n - 1) and 3 or 2, 0)))
			gui.set_euler(t, vmath.vector3(0, 0, a))
			gui.set_color(t, pad.tick_off)
			gui.set_parent(t, pad.base)
			pad.ticks[#pad.ticks + 1] = t
		end
	end
	pad.knob = fit(ui.disc(0, 0, M.KNOB_D, BOTTOM[2], pad.base))
	pad.knob_ring = fit(ui.ring_node(0, 0, M.KNOB_D, 3, ring_color, pad.knob))
	return pad
end

-- jump: the jump ticks lit (only the movement stick has them)
function M.color(pad, c, jump_name)
	gui.set_color(pad.ring, c)
	gui.set_color(pad.knob_ring, c)
	if pad.ticks and pad.salto ~= (jump_name or false) then
		pad.salto = jump_name or false
		for _, t in ipairs(pad.ticks) do gui.set_color(t, jump_name and pad.tick_on or pad.tick_off) end
	end
end

-- The thumb touches down at (x, y): the base goes there, without leaving the screen
function M.press(pad, id, x, y)
	pad.id, pad.x0, pad.y0 = id, x, y
	local h = M.D / 2
	POS.x = math.max(screen.x0 + h, math.min(screen.x1 - h, x))
	POS.y = math.max(screen.y0 + h, math.min(screen.y1 - h, y))
	pad.bx, pad.by = POS.x, POS.y
	gui.set_position(pad.base, POS)
end

-- The thumb is at (x, y): returns the offset from where it touched down, in
-- fractions of the travel (length at most 1)
function M.drag(pad, x, y)
	local dx, dy = (x - pad.x0) / M.R, (y - pad.y0) / M.R
	local mag = math.sqrt(dx * dx + dy * dy)
	if mag > 1 then dx, dy = dx / mag, dy / mag end
	POS.x = pad.x0 - pad.bx + dx * M.R
	POS.y = pad.y0 - pad.by + dy * M.R
	gui.set_position(pad.knob, POS)
	return dx, dy
end

function M.release(pad, ring_color)
	pad.id = nil
	POS.x, POS.y = pad.rest.x, pad.rest.y
	gui.set_position(pad.base, POS)
	POS.x, POS.y = 0, 0
	gui.set_position(pad.knob, POS)
	M.color(pad, ring_color)
end

return M
