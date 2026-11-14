-- The weapons in hand, made in the animation editor (tools/animazioni).
-- For each weapon:
--   grip: where whoever holds it holds it (the clip chooses who: an arm, which
--         turns toward the grip, or a little hand, which sits on it);
--   pivot: the point of the weapon it turns around (aiming and with "Arma, gira");
--   shoulder: where the pivot sits in the body, in drawing units from the feet.
--   scale: how much the weapon in hand is enlarged (1 if missing); grip and
--          pivot stay in units of the image as it is.
-- grip and pivot in world units from the weapon's origin, x toward where it
-- points and y up.
return {
	missile = { grip = { 0.6, -4.4 }, pivot = { -11.2, 0 }, shoulder = { 15.6, 163.8 }, scale = 0.73 },
	sniper = { grip = { 3.6, -2.6 }, pivot = { -9.6, -1 }, shoulder = { 9.5, 133.7 }, scale = 0.81 },
	grenade = { grip = { 4.7, 0.5 }, pivot = { 2.5, -7.3 }, shoulder = { 66.1, 121.2 } },
	shards = { grip = { 3.1, -3 }, pivot = { -9, -1.1 }, shoulder = { 20.5, 124.8 }, scale = 0.81 },
	punch = { grip = { 0, 0 }, pivot = { -9.3, 0 }, shoulder = { 32, 110 } },
	sword = { grip = { -0.3, 0.3 }, pivot = { -7.2, 0.5 }, shoulder = { 4, 157.1 }, scale = 0.9 },
	teleport = { grip = { 2.8, -0.6 }, pivot = { -6.5, -0.6 }, shoulder = { 32, 110 } },
	eagle = { grip = { 1.6, -1.2 }, pivot = { -7.7, -1.2 }, shoulder = { 32, 110 } },
	hook = { grip = { 5.3, -2.6 }, pivot = { -4, -2.6 }, shoulder = { 32, 110 } },
	mallet = { grip = { 6.5, 0 }, pivot = { -2.8, 0 }, shoulder = { 32, 110 } },
	lunge = { grip = { 2, 0 }, pivot = { -7.3, 0 }, shoulder = { 32, 110 } },
	bellows = { grip = { -1.5, 0 }, pivot = { -10.8, 0 }, shoulder = { 32, 110 } },
	boomerang = { grip = { -1, -1 }, pivot = { -8, -1 }, shoulder = { 32, 110 } },
	tar = { grip = { 4.4, 1.2 }, pivot = { -2.7, -7.9 }, shoulder = { -13.8, 111.5 } },
	drill = { grip = { 1.8, -5.3 }, pivot = { -11.9, 0 }, shoulder = { 28.5, 133.9 } },
	magnet = { grip = { 0, -2 }, pivot = { -8, -2 }, shoulder = { 32, 110 } },
	cannon = { grip = { 1.6, -2 }, pivot = { -9, -1 }, shoulder = { 32, 110 } },
	petard = { grip = { 4.4, 1.2 }, pivot = { -2.7, -7.9 }, shoulder = { -13.8, 111.5 } },
}
