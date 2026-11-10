-- The imp's body in the simulation, in world pixels measured from the center
-- of the feet. The animation editor writes it (tools/animazioni), but it
-- is physics: changing it changes the game for everyone, server included, not
-- the drawing (which is game.DISEGNO_H tall).
return {
	-- the walking capsule: terrain, pushes between robots, crates, who stands on whom
	walk = { width = 29.4, height = 39.2 },
	-- the hit circle: projectiles, explosions, sword, punch, lunge, orbs
	hit = { radius = 20.49, center = 19.6 },
}
