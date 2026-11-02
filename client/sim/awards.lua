-- End-of-match awards (docs/game_design_competitivo.md, "Fine partita"): they
-- reward style, not just the winner. Pure Lua, so the server gives them too.
-- They are computed from the sim results, g:results().ranking.
--
-- Each award looks at one entry of the results: it goes to whoever has the
-- highest value (best = "max") or the lowest ("min"), if it reaches at least
-- min. Ties go to whoever ranks higher. A player gets at most PER_PLAYER of
-- them, in list order.

local M = {}

M.PER_PLAYER = 2

M.LIST = {
	{ id = "becchino", name = "BECCHINO", desc = "Butta giù più nemici", stat = "env_kills", best = "max", min = 1 },
	{ id = "fulmine", name = "FULMINE", desc = "Attacca prima di tutti", stat = "avg_attack_secs", best = "min", min = 0, turns = 1 },
	{ id = "martello", name = "MARTELLO", desc = "Fa più danno", stat = "damage", best = "max", min = 1 },
	{ id = "ombra", name = "OMBRA", desc = "Si teletrasporta di più", stat = "teleports", best = "max", min = 2 },
	{ id = "predone", name = "PREDONE", desc = "Apre più casse", stat = "crates", best = "max", min = 1 },
}

-- ranking: list of players in finishing order. Returns { [robot] = { awards } }
-- and the list { { robot, award } } in order.
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
