-- Made by tools/grafica/armi.py, do not edit by hand.
-- The weapons in world units (shots from their center), x forward and
-- y up. For each one: image (tint: the parts in the team color), center
-- (x, y) and size (w, h). Where the hand holds them: battle/characters/<name>/grips.lua.
return {
	weapons = {
		missile = { img = "missile", tint = "missile_tinta", x = 2.50, y = -0.75, w = 28.00, h = 14.10 },
		sniper = { img = "sniper", tint = "sniper_tinta", x = 6.25, y = 0.00, w = 31.50, h = 6.84 },
		grenade = { img = "grenade", tint = "grenade_tinta", x = 4.50, y = 3.25, w = 10.00, h = 14.27 },
		shards = { img = "shards", tint = "shards_tinta", x = 5.50, y = 0.00, w = 30.00, h = 17.66 },
		punch = { img = "punch", tint = "punch_tinta", x = 5.00, y = 0.00, w = 17.00, h = 11.38 },
		sword = { img = "sword", tint = "sword_tinta", x = 18.75, y = 0.00, w = 47.50, h = 11.30 },
		teleport = { img = "teleport", tint = "teleport_tinta", x = 5.00, y = 1.25, w = 11.00, h = 11.33 },
		eagle = { img = "eagle", tint = "eagle_tinta", x = 8.25, y = -1.00, w = 24.50, h = 12.77 },
		hook = { img = "hook", tint = "hook_tinta", x = 6.24, y = -1.70, w = 17.91, h = 11.25 },
		mallet = { img = "mallet", tint = "mallet_tinta", x = 20.25, y = -0.25, w = 52.50, h = 18.27 },
		lunge = { img = "lunge", tint = "lunge_tinta", x = 16.50, y = 0.00, w = 52.00, h = 12.48 },
		bellows = { img = "bellows", tint = "bellows_tinta", x = 6.25, y = 0.00, w = 28.50, h = 12.04 },
		boomerang = { img = "boomerang", tint = "boomerang_tinta", x = 5.50, y = 3.50, w = 28.00, h = 12.43 },
		tar = { img = "tar", tint = "tar_tinta", x = 4.25, y = 3.25, w = 11.50, h = 13.59 },
		drill = { img = "drill", tint = "drill_tinta", x = 5.50, y = -0.75, w = 34.00, h = 9.68 },
		vortex = { img = "vortex", tint = "vortex_tinta", x = 4.50, y = 2.25, w = 11.00, h = 11.13 },
		cannon = { img = "cannon", tint = "cannon_tinta", x = 4.38, y = -1.00, w = 23.25, h = 18.75 },
		petard = { img = "petard", tint = "petard_tinta", x = 4.25, y = 3.25, w = 10.34, h = 19.38 },
	},
	pieces = {
		uncino = { img = "uncino", tint = nil, x = 5.25, y = 0.00, w = 14.50, h = 7.27 },
	},
	shots = {
		razzo = { img = "razzo", tint = "razzo_tinta", x = 0.00, y = 0.00, w = 15.14, h = 18.00 },
		palla = { img = "palla", tint = "palla_tinta", x = 0.00, y = 0.00, w = 12.80, h = 12.16 },
		uovo = { img = "uovo", tint = "uovo_tinta", x = 0.00, y = 0.00, w = 17.60, h = 25.26 },
		scheggia = { img = "scheggia", tint = "scheggia_tinta", x = 0.40, y = 0.00, w = 15.20, h = 3.93 },
		globo = { img = "globo", tint = "globo_tinta", x = 0.00, y = 0.00, w = 16.00, h = 16.48 },
		giano = { img = "giano", tint = "giano_tinta", x = 0.00, y = 0.00, w = 16.00, h = 16.56 },
		falce = { img = "falce", tint = "falce_tinta", x = 0.40, y = -0.80, w = 20.00, h = 8.88 },
		fiasco = { img = "fiasco", tint = "fiasco_tinta", x = 0.00, y = 0.00, w = 17.60, h = 20.79 },
		punta = { img = "punta", tint = "punta_tinta", x = 2.00, y = 0.00, w = 23.20, h = 10.32 },
		petardo_volo = { img = "petardo_volo", tint = "petardo_volo_tinta", x = 0.00, y = 0.80, w = 12.81, h = 24.00 },
		voragine_volo = { img = "voragine_volo", tint = "voragine_volo_tinta", x = 0.00, y = 0.00, w = 16.00, h = 16.19 },
	},
}
