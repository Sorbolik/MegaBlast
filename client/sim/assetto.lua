-- Assetto: albero di abilità più equipaggiamento, e le statistiche del robot
-- che ne vengono fuori. Lua puro: il client lo manda al server, che lo
-- controlla con valid() e passa stats() alla partita (opts.stats[i]).
--
-- Un assetto: { tree = { [nodo] = gradi }, gear = { mask = "corvo", ... }, variant = "a" | "b" }
-- Si ricostruisce gratis fuori dalla partita; ogni giocatore ne tiene LOADOUTS.

local abilita = require "sim.abilita"
local equip = require "sim.equipaggiamento"

local M = {}

M.LOADOUTS = 3

-- limiti delle statistiche dopo albero e set
M.MIN = { max_hp = 1, teleport_ticks = 30, teleports = 0, parachutes = 0 }

function M.new()
	return { tree = {}, gear = {}, variant = "a" }
end

-- Applica i gruppi di effetti (un pezzo, un grado, un bonus): prima le somme,
-- poi le moltiplicazioni
local function apply(st, mods)
	for _, g in ipairs(mods) do
		for _, e in ipairs(g) do if e.add then st[e.stat] = st[e.stat] + e.add end end
	end
	for _, g in ipairs(mods) do
		for _, e in ipairs(g) do if e.mul then st[e.stat] = st[e.stat] * e.mul end end
	end
	for k, v in pairs(M.MIN) do
		if type(st[k]) == "number" and st[k] < v then st[k] = v end
	end
	return st
end

-- Statistiche finali. base: game.base_stats() della sim. tiers: tier dei pezzi
-- indossati ({ mask = 1..3, ... }), servono solo per la variante B.
-- I valori interi (vita, tick) restano interi.
function M.stats(base, a, tiers)
	local st = {}
	for k, v in pairs(base) do st[k] = v end
	local mods = {}
	abilita.mods(a.tree or {}, mods)
	equip.mods(a.gear or {}, tiers, a.variant, mods)
	apply(st, mods)
	for _, k in ipairs({ "max_hp", "teleport_ticks" }) do
		if type(st[k]) == "number" then st[k] = math.floor(st[k] + 0.5) end
	end
	return st
end

-- l'assetto è giocabile con questi punti? (il server lo controlla prima della partita)
function M.valid(a, points)
	if type(a) ~= "table" or type(a.gear) ~= "table" then return false end
	for slot, set in pairs(a.gear) do
		if not equip.BY_ID[set] then return false end
		local known = false
		for _, s in ipairs(equip.SLOTS) do known = known or s.id == slot end
		if not known then return false end
	end
	if a.variant ~= "a" and a.variant ~= "b" then return false end
	return abilita.valid(a.tree or {}, points)
end

return M
