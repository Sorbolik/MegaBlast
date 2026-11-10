-- Small neural net for the bot (sim/bot.lua): a layered perceptron that,
-- from a position's features, gives what it is worth. The weights aren't
-- trained here: tools/arena/impara.py trains them.
-- Only sums, products and max (ReLU): no exp or tanh, which LuaJIT and
-- gopher-lua might compute with a different last digit, so the bot stays
-- identical on the phone and on the server.
-- The file's name, valuta, quanti and the fields strati and w stay Italian:
-- impara.py writes and reads them.
--
--   local rete = require "sim.rete"
--   local r = { strati = { 22, 16, 8, 1 }, w = { ... } }   -- weights in a row, layer by layer
--   local v = rete.valuta(r, x)                             -- x: list of #strati[1] numbers
--   rete.quanti(strati)                                     -- how many weights are needed

local M = {}

-- For each layer: first the weights (output by output, one row of inputs
-- each), then the biases
function M.quanti(layers)
	local n = 0
	for k = 2, #layers do n = n + layers[k] * (layers[k - 1] + 1) end
	return n
end

local a, b = {}, {}

function M.evaluate(r, x)
	local layers, w = r.strati, r.w
	local layer_in, layer_out = x, a
	local p = 1
	for k = 2, #layers do
		local nin, nout = layers[k - 1], layers[k]
		local last = k == #layers
		for o = 1, nout do
			local s = 0
			for i = 1, nin do
				s = s + w[p] * layer_in[i]
				p = p + 1
			end
			layer_out[o] = s
		end
		for o = 1, nout do
			local s = layer_out[o] + w[p]
			p = p + 1
			layer_out[o] = (last or s > 0) and s or 0
		end
		layer_in = layer_out
		layer_out = layer_out == a and b or a
	end
	return layer_in[1]
end

return M
