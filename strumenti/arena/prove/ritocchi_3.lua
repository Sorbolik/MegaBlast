-- Terza prova (29 ottobre 2026). Con la seconda le armi sono in equilibrio nel
-- tutti contro tutti (Uovo appena sopra: 60 -> 58), ma la Fornace vinceva
-- ancora il 70% nell'1v1 anche senza la vita e il teletrasporto dei pezzi:
-- la colpa è la bruciatura su ogni missile. Qui i pezzi tornano quelli di
-- oggi e il set fa bruciare solo l'Uovo.
return function(config, game)
	config.LUNGE.damage = 27          -- era 30
	game.PUNCH_DAMAGE = 27            -- era 30
	config.MALLET.damage = 34         -- era 30
	game.GRENADE_BLAST.damage = 58    -- era 55
	config.SNIPER.damage = 28         -- era 25
	function game:hit_status(rb, weapon, by)
		local kind = config.WEAPON_STATUS[weapon]
		if not kind and by and by.stats.burning_blasts > 0 and weapon == "grenade" then kind = "burn" end
		if kind then self:add_status(rb, kind, by) end
	end
end
