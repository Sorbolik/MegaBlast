-- Riconoscimenti di fine partita (docs/game_design_competitivo.md, "Fine
-- partita"): premiano lo stile oltre al vincitore. Lua puro, così li dà anche
-- il server. Si calcolano dai risultati della sim, g:results().ranking.
--
-- Ogni riconoscimento guarda una voce dei risultati: va a chi ha il valore più
-- alto (best = "max") o più basso ("min"), se arriva almeno a min. A parità
-- vince chi sta più in alto in classifica. Un giocatore ne prende al massimo
-- PER_PLAYER, nell'ordine della lista.

local M = {}

M.PER_PLAYER = 2

M.LIST = {
	{ id = "becchino", name = "BECCHINO", desc = "Butta giù più nemici", stat = "env_kills", best = "max", min = 1 },
	{ id = "fulmine", name = "FULMINE", desc = "Attacca prima di tutti", stat = "avg_attack_secs", best = "min", min = 0, turns = 1 },
	{ id = "martello", name = "MARTELLO", desc = "Fa più danno", stat = "damage", best = "max", min = 1 },
	{ id = "ombra", name = "OMBRA", desc = "Si teletrasporta di più", stat = "teleports", best = "max", min = 2 },
	{ id = "tesoriere", name = "TESORIERE", desc = "Spende più Nucleo", stat = "nucleo_spent", best = "max", min = 2 },
	{ id = "predone", name = "PREDONE", desc = "Apre più casse", stat = "crates", best = "max", min = 1 },
}

-- ranking: lista dei giocatori in ordine di posto. Restituisce { [robot] = { riconoscimenti } }
-- e la lista { { robot, award } } in ordine.
function M.assign(ranking)
	local by_robot, list, count = {}, {}, {}
	for _, aw in ipairs(M.LIST) do
		local best, who = nil, nil
		for _, p in ipairs(ranking) do
			local v = p[aw.stat]
			local ok = type(v) == "number" and (count[p.robot] or 0) < M.PER_PLAYER
				and v >= aw.min and (not aw.turns or (p.turns or 0) >= aw.turns)
			if ok and (best == nil or (aw.best == "max" and v > best) or (aw.best == "min" and v < best)) then
				best, who = v, p.robot
			end
		end
		if who then
			count[who] = (count[who] or 0) + 1
			by_robot[who] = by_robot[who] or {}
			table.insert(by_robot[who], aw)
			list[#list + 1] = { robot = who, award = aw }
		end
	end
	return by_robot, list
end

return M
