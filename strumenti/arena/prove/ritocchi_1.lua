-- Prima prova di bilanciamento dalla base di 10.000 partite (29 ottobre 2026):
-- Affondo e Pugno vincono troppo nel tutti contro tutti, Maglio, Uovo e
-- Cecchino troppo poco. Un numero per arma.
return function(config, game)
	config.LUNGE.damage = 25          -- era 30
	game.PUNCH_DAMAGE = 25            -- era 30
	config.MALLET.damage = 36         -- era 30
	game.GRENADE_BLAST.damage = 65    -- era 55
	config.SNIPER.damage = 30         -- era 25
end
