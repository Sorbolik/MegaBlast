-- Generatore pseudo-casuale deterministico (Park-Miller).
-- Non usiamo math.random perché deve dare gli stessi numeri
-- nel client (LuaJIT) e nel server (gopher-lua).

local M = {}
M.__index = M

local MOD = 2147483647

function M.new(seed)
	seed = math.floor(seed or 1) % MOD
	if seed <= 0 then seed = seed + MOD - 1 end
	return setmetatable({ state = seed }, M)
end

-- Numero intero in [1, MOD - 1]
function M:next_int()
	self.state = (self.state * 16807) % MOD
	return self.state
end

-- Numero reale in [0, 1)
function M:next()
	return (self:next_int() - 1) / (MOD - 1)
end

-- Numero reale in [a, b)
function M:range(a, b)
	return a + (b - a) * self:next()
end

return M
