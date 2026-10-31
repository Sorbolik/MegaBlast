-- Rete neurale piccola per il bot (sim/bot.lua): un percettrone a strati che
-- dalle caratteristiche di una posizione dà quanto vale. I pesi non si
-- allenano qui: li allena strumenti/arena/impara.py.
-- Solo somme, prodotti e max (ReLU): niente exp o tanh, che LuaJIT e
-- gopher-lua potrebbero calcolare con un'ultima cifra diversa, così il bot
-- resta identico sul telefono e sul server.
--
--   local rete = require "sim.rete"
--   local r = { strati = { 22, 16, 8, 1 }, w = { ... } }   -- pesi in fila, strato per strato
--   local v = rete.valuta(r, x)                             -- x: lista di #strati[1] numeri
--   rete.quanti(strati)                                     -- quanti pesi servono

local M = {}

-- Per ogni strato: prima i pesi (uscita per uscita, una riga di ingressi
-- ciascuna), poi gli scarti
function M.quanti(strati)
	local n = 0
	for k = 2, #strati do n = n + strati[k] * (strati[k - 1] + 1) end
	return n
end

local a, b, nz = {}, {}, {}

-- Strato per strato, solo sugli ingressi diversi da zero (il terreno e i
-- robot che mancano nel primo, quelli spenti dalla ReLU negli altri: circa
-- metà): w * 0 non cambia la somma, quindi il risultato è identico e costa meno
function M.valuta(r, x)
	local strati, w = r.strati, r.w
	local ingresso, uscita = x, a
	local p = 1
	for k = 2, #strati do
		local nin, nout = strati[k - 1], strati[k]
		local ultimo = k == #strati
		local n = 0
		for i = 1, nin do
			if ingresso[i] ~= 0 then
				n = n + 1
				nz[n] = i
			end
		end
		for o = 1, nout do
			local s = 0
			local q = p - 1
			for j = 1, n do
				local i = nz[j]
				s = s + w[q + i] * ingresso[i]
			end
			uscita[o] = s
			p = p + nin
		end
		for o = 1, nout do
			local s = uscita[o] + w[p]
			p = p + 1
			uscita[o] = (ultimo or s > 0) and s or 0
		end
		ingresso = uscita
		uscita = uscita == a and b or a
	end
	return ingresso[1]
end

return M
