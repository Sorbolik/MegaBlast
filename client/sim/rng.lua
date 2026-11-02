-- Deterministic pseudo-random generator (Park-Miller).
-- We don't use math.random because it must give the same numbers on the
-- client (LuaJIT) and on the server (gopher-lua).

local M = {}
M.__index = M

local MOD = 2147483647

function M.new(seed)
	seed = math.floor(seed or 1) % MOD
	if seed <= 0 then seed = seed + MOD - 1 end
	return setmetatable({ state = seed }, M)
end

-- Integer in [1, MOD - 1]
function M:next_int()
	self.state = (self.state * 16807) % MOD
	return self.state
end

-- Real number in [0, 1)
function M:next()
	return (self:next_int() - 1) / (MOD - 1)
end

-- Real number in [a, b)
function M:range(a, b)
	return a + (b - a) * self:next()
end

return M
