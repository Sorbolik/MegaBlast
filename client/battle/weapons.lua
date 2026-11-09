-- Made by strumenti/grafica/armi.py, do not edit by hand.
-- The weapons in world units (shots from their center), x forward and
-- y up. For each one: image (tint: the parts in the team color), center
-- (x, y) and size (w, h). Where the hand holds them: battle/grips.lua.
return {
	weapons = {
		missile = { img = "missile", tint = "missile_tinta", x = 2.50, y = -0.75, w = 28.00, h = 14.50 },
		sniper = { img = "sniper", tint = "sniper_tinta", x = 6.25, y = 0.00, w = 31.50, h = 13.00 },
		grenade = { img = "grenade", tint = "grenade_tinta", x = 4.50, y = 3.25, w = 10.00, h = 15.50 },
		shards = { img = "shards", tint = "shards_tinta", x = 5.50, y = 0.00, w = 30.00, h = 15.00 },
		punch = { img = "punch", tint = "punch_tinta", x = 5.00, y = 0.00, w = 17.00, h = 14.00 },
		sword = { img = "sword", tint = "sword_tinta", x = 18.75, y = 0.00, w = 47.50, h = 14.00 },
		teleport = { img = "teleport", tint = "teleport_tinta", x = 5.00, y = 1.25, w = 11.00, h = 11.50 },
		eagle = { img = "eagle", tint = "eagle_tinta", x = 8.25, y = -1.00, w = 24.50, h = 15.00 },
		hook = { img = "hook", tint = "hook_tinta", x = 10.00, y = 0.00, w = 30.00, h = 15.00 },
		mallet = { img = "mallet", tint = "mallet_tinta", x = 20.25, y = -0.25, w = 52.50, h = 17.82 },
		lunge = { img = "lunge", tint = "lunge_tinta", x = 16.50, y = 0.00, w = 52.00, h = 15.00 },
		bellows = { img = "bellows", tint = "bellows_tinta", x = 6.25, y = 0.00, w = 28.50, h = 15.00 },
	},
	pieces = {
		uncino = { img = "uncino", tint = nil, x = 5.25, y = 0.00, w = 14.50, h = 16.00 },
	},
	shots = {
		razzo = { img = "razzo", tint = "razzo_tinta", x = 0.00, y = 0.00, w = 20.80, h = 14.40 },
		palla = { img = "palla", tint = "palla_tinta", x = 0.00, y = 0.00, w = 12.80, h = 12.80 },
		uovo = { img = "uovo", tint = "uovo_tinta", x = 0.00, y = 0.00, w = 17.60, h = 24.00 },
		scheggia = { img = "scheggia", tint = "scheggia_tinta", x = 0.40, y = 0.00, w = 15.20, h = 9.60 },
		globo = { img = "globo", tint = "globo_tinta", x = 0.00, y = 0.00, w = 16.00, h = 16.00 },
		giano = { img = "giano", tint = "giano_tinta", x = 0.00, y = 0.00, w = 16.00, h = 16.00 },
	},
}
