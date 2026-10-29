-- Seconda prova (29 ottobre 2026). La prima (Affondo e Pugno 25, Maglio 36,
-- Uovo 65, Cecchino 30) ha girato troppo: Affondo debole, Uovo forte. Qui a
-- metà strada. Più la Fornace, che nel set completo vinceva il 69% nell'1v1:
-- i pezzi davano +10 vita e un teletrasporto, ora solo i loro difetti, e il
-- bonus costa vita -10% come Corvo e Vuoto.
local equip = require "sim.equipaggiamento"
return function(config, game)
	config.LUNGE.damage = 27          -- era 30
	game.PUNCH_DAMAGE = 27            -- era 30
	config.MALLET.damage = 34         -- era 30
	game.GRENADE_BLAST.damage = 60    -- era 55
	config.SNIPER.damage = 28         -- era 25
	local f = equip.BY_ID.fornace
	f.pieces.mask = { { stat = "jump_height", mul = 0.98 } }
	f.pieces.chest = { { stat = "air_speed", mul = 0.97 } }
	f.pieces.cloak = { { stat = "jump_height", mul = 0.95 } }
	f.pieces.legs = { { stat = "walk_speed", mul = 0.98 } }
	local a = f.bonus.a.effects
	a[#a + 1] = { stat = "max_hp", mul = 0.9 }
end
