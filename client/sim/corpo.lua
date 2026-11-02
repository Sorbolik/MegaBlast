-- The imp's body in the simulation, in world pixels measured from the center
-- of the feet. The animation editor writes it (strumenti/animazioni), but it
-- is physics: changing it changes the game for everyone, server included, not
-- the drawing (which is game.DISEGNO_H tall).
return {
	-- the walking capsule: terrain, pushes between robots, crates, who stands on whom
	cammina = { largo = 29.4, alto = 39.2 },
	-- the hit circle: projectiles, explosions, sword, punch, lunge, orbs
	colpi = { raggio = 20.49, centro = 19.6 },
}
