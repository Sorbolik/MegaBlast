-- Online every phone and the server play the same match from the same keys
-- (Sergio, 22 Nov: «voglio vedere in tempo reale quello che faccio, senza input
-- lag, quindi deve essere il client a comandare quello che vedi»). The match is
-- deterministic and comes out the same on phones and server (docs/server.md,
-- the recipes), so what travels is only the input of each tick, as a short
-- string: on your turn your phone steps the match at once with your keys and
-- sends them, the server applies them and passes them on; on the others' turns
-- each phone steps with the keys the server passes.
--
--   local code = netkeys.encode(input)    -- "" without keys
--   local input = netkeys.decode(code)    -- nil without keys
--
-- Letters: l left, r right, j jump, h hold the jump, n jump released (hold =
-- false: a short jump); then f<weapon>,<angle>,<power> for a shot, the numbers
-- with all their digits (17: the same double on every machine). Before the
-- keys, x<robot>; for each robot that left the match right before this tick.
-- Everyone steps with decode(encode(input)), the server too: a weapon that
-- isn't one becomes the missile, as before, the same everywhere.

local game = require "sim.game"

local M = {}

local format, tonumber = string.format, tonumber

local function num(v)
	v = tonumber(v) or 0
	if v ~= v or v == math.huge or v == -math.huge then v = 0 end
	return format("%.17g", v)
end

function M.encode(input)
	if not input then return "" end
	local s = (input.left and "l" or "") .. (input.right and "r" or "") .. (input.jump and "j" or "")
		.. (input.hold == true and "h" or input.hold == false and "n" or "")
	local f = input.fire
	if f then
		local w = game.WEAPONS[f.weapon] and f.weapon or "missile"
		s = s .. "f" .. w .. "," .. num(f.angle) .. "," .. num(f.power)
	end
	return s
end

-- the input of a code (nil if it has no keys) and the robots it removes first
-- (a list, or nil). A code that can't be read is no keys.
function M.decode(code)
	if type(code) ~= "string" or code == "" then return nil end
	local gone
	while true do
		local i, rest = code:match("^x(%d+);(.*)$")
		if not i then break end
		gone = gone or {}
		gone[#gone + 1] = tonumber(i)
		code = rest
	end
	if code == "" then return nil, gone end
	local keys, w, a, p = code:match("^([lrjhn]*)f([%a_]+),([^,]+),([^,]+)$")
	if not keys then
		keys = code:match("^([lrjhn]*)$")
		if not keys then return nil, gone end
	end
	local input = {}
	if keys:find("l", 1, true) then input.left = true end
	if keys:find("r", 1, true) then input.right = true end
	if keys:find("j", 1, true) then input.jump = true end
	if keys:find("h", 1, true) then input.hold = true elseif keys:find("n", 1, true) then input.hold = false end
	if w then
		a, p = tonumber(a) or 0, tonumber(p) or 0
		if a ~= a or a == math.huge or a == -math.huge then a = 0 end
		if p ~= p or p == math.huge or p == -math.huge then p = 0 end
		input.fire = { weapon = game.WEAPONS[w] and w or "missile", angle = a, power = p }
	end
	return input, gone
end

-- the code as it is applied: what each machine steps with and passes on
function M.clean(input)
	local code = M.encode(input)
	return code, (M.decode(code))
end

return M
