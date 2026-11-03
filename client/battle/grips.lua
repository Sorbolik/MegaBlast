-- The weapons in hand, made in the animation editor (strumenti/animazioni).
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
	missile = { grip = { 1.8, -5.3 }, pivot = { -11.9, 0 }, shoulder = { 28.5, 133.9 } },
	sniper = { grip = { 4.3, -2.9 }, pivot = { -11.8, -2.1 }, shoulder = { -11, 113.7 } },
	grenade = { grip = { 4.4, 1.2 }, pivot = { -2.7, -7.9 }, shoulder = { -13.8, 111.5 } },
	shards = { grip = { 2.9, -3.4 }, pivot = { -9.5, -0.8 }, shoulder = { -16.5, 115.3 } },
	punch = { grip = { 0, 0 }, pivot = { -9.3, 0 }, shoulder = { 32, 110 } },
	sword = { grip = { 4.2, -0.1 }, pivot = { -8.2, 0.5 }, shoulder = { -14.2, 106.9 } },
	teleport = { grip = { 2.8, -0.6 }, pivot = { -6.5, -0.6 }, shoulder = { 32, 110 } },
	eagle = { grip = { 1.6, -1.2 }, pivot = { -7.7, -1.2 }, shoulder = { 32, 110 } },
	hook = { grip = { 5.3, -2.6 }, pivot = { -4, -2.6 }, shoulder = { 32, 110 } },
	mallet = { grip = { 6.5, 0 }, pivot = { -2.8, 0 }, shoulder = { 32, 110 } },
	lunge = { grip = { 2, 0 }, pivot = { -7.3, 0 }, shoulder = { 32, 110 } },
	bellows = { grip = { -1.5, 0 }, pivot = { -10.8, 0 }, shoulder = { 32, 110 } },
}
