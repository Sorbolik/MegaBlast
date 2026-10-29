-- Quarta prova, per conferma (29 ottobre 2026): i numeri proposti. Dalla terza
-- il Pugno a 27 era sceso troppo, Uovo e Schegge un poco sopra, Cecchino sotto.
return function(config, game)
	config.LUNGE.damage = 27          -- era 30
	game.PUNCH_DAMAGE = 28            -- era 30
	config.MALLET.damage = 34         -- era 30
	game.GRENADE_BLAST.damage = 57    -- era 55
	game.SHARD_BLAST.damage = 6.5     -- era 7
	config.SNIPER.damage = 30         -- era 25
	function game:hit_status(rb, weapon, by)
		local kind = config.WEAPON_STATUS[weapon]
		if not kind and by and by.stats.burning_blasts > 0 and weapon == "grenade" then kind = "burn" end
		if kind then self:add_status(rb, kind, by) end
	end
end
