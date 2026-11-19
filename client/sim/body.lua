-- The imp's body in the simulation, in world pixels measured from the center
-- of the feet, for each character. The animation editor writes it
-- (tools/animazioni), but it is physics: the game uses the active character's
-- (everyone's, battle/scoria.lua M.PERSONAGGIO), for everyone, server included;
-- the other characters' change nothing until one becomes active. Not the drawing
-- (which is game.DISEGNO_H tall).
--   walk: the walking capsule (terrain, pushes between robots, crates, who stands on whom)
--   hit: the hit circle (projectiles, explosions, sword, punch, lunge, orbs)
return {
	active = "apprendista_nuovo",
	apprendista_nuovo = { walk = { width = 20, height = 46.2 }, hit = { radius = 23, center = 23.5 } },
	apprendista = { walk = { width = 20, height = 46.2 }, hit = { radius = 23, center = 23.5 } },
	favilla = { walk = { width = 20, height = 46.2 }, hit = { radius = 23, center = 23.5 } },
}
