-- Match rules: all the numbers to balance in one place.
-- Pure Lua, read-only: read by the simulation (client and server) and by the
-- UI. The choices come from docs/game_design_competitivo.md ("Decisioni
-- prese"); those taken without Sergio are marked "our choice".
-- Physics (gravity, weapons, jump) stays in sim/game.lua.

local C = {}

-- Match and turns, in seconds
-- match length, in seconds of turn. The round of turns that starts when less
-- than FINAL_ROUND_SHARE of a full round is left (full turns: 50 s in 2 v 2)
-- is the last one: everyone plays one turn, points are worth
-- SCORE.final_round times, and when it ends the match ends, even if time
-- hasn't run out yet (if time runs out first, the round is finished). Everyone
-- plays the same number of turns (Sergio, 31 October 2026: "l'ultimo turno con
-- punti doppi"; the half-round threshold is ours: a match lasts 5 minutes on average).
C.MATCH_SECONDS = 5 * 60
C.FINAL_ROUND_SHARE = 0.5
C.TURN_SECONDS = 25          -- turn length
-- After the first attack AFTER_ATTACK_SECONDS remain (never past the end of
-- the turn): in all of them you can do the second attack, reposition, use items.
-- Sergio: 4 s "per il secondo attacco" + 4 to reposition, but you can attack
-- during all 8, so you never lose the second hit without understanding why.
C.AFTER_ATTACK_SECONDS = 8

-- Game modes: the players to pass to game.new (opts.players), with each one's
-- team. In 2 v 2 the teams already alternate in the list.
C.MODES = {
	["1v1"] = { { team = 1 }, { team = 2 } },
	["2v2"] = { { team = 1 }, { team = 2 }, { team = 1 }, { team = 2 } },
	ffa = { { team = 1 }, { team = 2 }, { team = 3 }, { team = 4 } },
}

-- Teleports: attacking early gives teleport orbs (Sergio, 24 October 2026:
-- the Nucleo is removed, saved time gives teleports).
-- One orb for each threshold not yet passed at the first attack of the turn,
-- in seconds from the start of the turn: within 9 s two orbs, within 17 s one,
-- after that none; never three (Sergio, 29 October: getting two was
-- frustrating, the first a little wider than before and the second much
-- wider; the numbers are ours, they used to be 5 and 15 s). The timer shows
-- them as notches.
C.TELEPORT_THRESHOLDS = { 9, 17 }

-- Match points (strategy 7 of the document): besides kills, damage counts,
-- environmental kills and hits on whoever is first. The team with the most
-- points when time runs out wins. Values are our choice. Sergio, 29 October
-- 2026 (variant A without knock-off and double): Crown on the leader, trap,
-- shield parry; Rampino and trampoline give the kill to whoever used them.
-- Damage is worth the share of life removed, not the hit points: a full life
-- is worth 100 * damage, even for someone with more life from pieces or the
-- tree (Sergio, 29 October 2026: "disaccoppiare i punti dai danni"). The stats
-- life counts: life given by a mission doesn't change damage points.
C.SCORE = {
	damage = 1,       -- per hundredth of a full life taken from an opponent
	kill = 50,        -- kill
	env_kill = 50,    -- extra if environmental (off the map or a fall)
	death = -20,      -- for whoever dies
	self_death = -30, -- extra for whoever dies in their own turn with no opponent to blame
	leader = 1.5,     -- multiplier if the target is first in the standings (the Crown)
	crown = 25,       -- extra to whoever kills the leader
	crown_rounds = 1, -- full rounds before there is a Crown (whoever opens doesn't take it alone)
	trap = 10,        -- to whoever placed it, when the trap fires on an opponent
	parry = 0.5,      -- to whoever carries the shield, for each point of enemy damage it stops
	parry_max = 20,   -- at most per shield (lasts until the owner's next turn)
	final_round = 2,  -- multiplier of all points in the last round (FINAL_ROUND_SHARE)
}
-- the kill goes to whoever hit last, if it was within these seconds
C.KILL_CREDIT_SECONDS = 10
-- Whoever dies in their own turn without a recent hit from an opponent (jumps
-- off, hits themselves) doesn't take points away from others: the kill goes
-- to the opponent who did the most damage to them in this life, and they lose
-- death + self_death (Sergio, 26 October 2026: "deve essere punitivo e
-- bilanciato"). The turn goes on anyway (Sergio's correction of the 24th).
-- After dying you come back after RESPAWN_SECONDS, even mid-turn (the turn of
-- whoever hit you or yours: the turn doesn't pass), with full life at a free
-- random point of the surface. Even near an opponent: with a bit of luck they
-- hit you again.
C.RESPAWN_SECONDS = 1.5

-- Crates: what's inside (hidden until opened), with a weight: the higher, the
-- more often it comes out. Only one-shot weapons (Sergio, 9 November 2026).
C.CRATE_CONTENTS = {
	{ "grenade", 2 }, { "shards", 2 }, { "punch", 2 }, { "sniper", 2 },
	{ "boomerang", 2 }, { "tar", 2 }, { "drill", 2 },
}
-- Tactical items drop on the map on their own, visible (you see what it is
-- before going to take it), half as often as crates (game.ITEM_CHANCE) and at
-- most max at once. Same weight for all (Claude: the trampoline was the
-- rarest and the least used).
C.ITEM_DROPS = { max = 2, contents = { { "trap", 1 }, { "shield", 1 }, { "trampoline", 1 } } }

-- Cecchino (crate weapon): a shot that starts fast (speed in sim/game.lua) and
-- slows down (each second it keeps drag of its speed), while gravity grows
-- little by little up to drop times the robots' gravity in drop_ramp seconds:
-- at first it flies almost straight, then it drops more and more, so it's
-- hard to aim from far away (Sergio, 24 October 2026: "inizia veloce e poi
-- scende a poco a poco"). On terrain it bounces like a ball, lower and slower
-- each time (bounce_normal against the surface, bounce_tangent along it), at
-- most bounces times or until it's slower than min_speed; it doesn't dig.
-- Whoever is hit takes damage and is knocked in the direction of the shot at
-- push pixels per second (plus lift upward, to get them off the ground). With
-- a trampoline under their feet they fly away.
C.SNIPER = { damage = 42, push = 280, lift = 80, drag = 0.7, drop = 1, drop_ramp = 0.8,
	bounces = 6, bounce_normal = 0.5, bounce_tangent = 0.85, min_speed = 40 }

-- The two categories (Sergio, 29 October 2026, replacing the rule of the 24th):
-- PRIMARIES do damage and are the only ones that leave status effects
-- (C.STATUS: slowed, cracked armour, burn); SECONDARIES can do anything (move
-- you, move the opponent, flat damage) but never leave status effects.
-- Secondaries are unlimited. The Lama is in sim/game.lua (SWORD_*); Tonante,
-- Maglio, Affondo and Mantice are picked one each at the start of the match.
-- Distances in pixels, speeds in pixels per second.
-- Tonante (heavy pistol): straight instant shot up to range, it stops at the
-- first robot or terrain. The recoil pushes the shooter opposite to the aim,
-- straight, at recoil for recoil_ticks: the same push in every direction
-- (Sergio, 26 October 2026), without gravity or air control, and it slides
-- along the terrain it meets. Then you fall from standstill.
C.EAGLE = { damage = 38, range = 600, recoil = 300, recoil_ticks = 22 }
-- Maglio: two-handed hammer that swings around the shoulder like the Lama,
-- from from (high behind the head) to to (below the feet) in ticks ticks,
-- reach long from the shoulder; the arc rotates with the aim (from and to are
-- for a straight aim). It hits every robot it touches along the arc; the head
-- stops on terrain. At the first impact, on a robot or on terrain, the
-- attacker bounces up at bounce (pogo), on the ground as in the air; on a miss no.
-- When the arc ends (or stops), the hammer stays down for hold ticks.
C.MALLET = { damage = 57, reach = 44, from = math.rad(115), to = math.rad(-100), ticks = 12, hold = 12, bounce = 320 }
-- Rampino (tactical item, Sergio 24 October 2026: not a weapon, one per turn,
-- usable at any moment of the turn and does no damage): the hook leaves the
-- muzzle and flies straight at shot_speed, without gravity, up to range
-- (Sergio, 29 October 2026: with maps 1.5 times bigger 220 wasn't enough; 400
-- reaches from the edge of the platform to the rocks of "Giù dal bordo"). If
-- it catches nothing it falls with its rope (drawing only).
-- On a robot: it is pulled by the rope towards the puller's hand, straight
-- along the rope, without gravity, at speed, for at most reel pixels, then it
-- is released and falls where it is. From close by it comes right up to the
-- puller (Sergio 26 October 2026: "ce lo dobbiamo tirare per bene"); from
-- further than reel it stays halfway: over the void it falls (our choice, so
-- "Giù dal bordo" can be done with the Rampino).
-- The floor under it doesn't stop it (it slides and climbs steps,
-- game.hook_slide); a high wall or another robot in between does. From below
-- you lift it up to you. The puller can move meanwhile: the rope follows the hand.
-- On terrain: the puller climbs along the rope at climb_speed up to the hit
-- point and stands on top of the platform, if its top is within climb pixels
-- of the point (the side of a high wall doesn't count: they stay there and
-- fall). If the climb stops against terrain (from below, diagonally) being
-- within grab pixels of the point (from the robot's centre) is enough to get up.
C.HOOK = { range = 400, shot_speed = 1500, reel = 220, speed = 300, climb_speed = 420, climb = 96, grab = 80 }
-- Giano (swap tool, Sergio 9 November 2026, a prototype): a two-faced coin
-- thrown like the missile, that swaps places with the first robot it touches
-- (ally or enemy, never the thrower) and stops at terrain. The two trade
-- position and movement (speed, fall); nothing else changes: no damage, no hit
-- credit (a fall after the swap is nobody's kill), no trap goes off on arrival.
-- need_ground: swap only if both stand (off for now: a thrower falling into the
-- void who swaps with someone is the skill check Sergio wants to try).
C.JANUS = { need_ground = false }
-- Affondo: dash in the aim direction at speed for ticks ticks, passing through
-- robots (damage once to each). It hits whoever it touches with the body or
-- with the spear, reach long from the body centre. Steps and bumps up to climb
-- pixels are climbed without stopping; against a higher obstacle it slides
-- along the terrain (only the part of the dash that passes remains) and stops
-- only if nothing passes at all. At the end keep of the speed remains: past
-- an edge you fly.
C.LUNGE = { damage = 45, speed = 520, ticks = 18, keep = 0.35, reach = 40, climb = 16 }
-- Mantice (Sergio, 29 October 2026: "una secondaria che sposta il nemico"):
-- the forge's blast. Instant, fan shaped: it hits every robot (not the user)
-- with its centre within range pixels and within cone radians of the aim, if
-- no terrain is in between. It does little damage and pushes it far along the
-- aim at push (plus lift upward, to get it off the ground), less the further
-- it is (at the edge of the fan far of the push). The user doesn't move. The
-- shield halves the push as for hits. Damage on the life-100 scale (#79): 10,
-- one tenth
C.BELLOWS = { damage = 10, range = 170, cone = math.rad(35), push = 400, lift = 100, far = 0.35 }

-- New weapons (Sergio, 9 November 2026: "integrale tutte"), the six of the page
-- "Armi nuove della Forgia" (https://claude.ai/artifact/3cSDdonHszZBPpayb3jSxG).
-- Numbers are Claude's first guess (autonomous): to tune in play.
--
-- Falcetto (primary, boomerang): a sickle that flies straight for up to range
-- pixels (or until terrain), turns round and comes back to whoever threw it,
-- flying over terrain. It hits each robot once going out (damage) and once
-- coming back (damage, and the armour cracks). It never digs. Allies are hit
-- too, like the Lanciarune.
C.BOOMERANG = { damage = 18, speed = 450, range = 400, back_speed = 520, radius = 14, life = 4 * 60 }
-- Pozza di Pece (primary, tar): a flask lobbed like the Uovo that breaks on the
-- first thing it touches: damage to whoever it hits and a pool of burning pitch
-- on the spot. Whoever stands in the pool (radius pixels around the spot) when
-- it appears, or walks in later, is set alight (status burn, once per turn).
-- It lasts turns turns (the thrower's and the next); only one pool per team.
C.TAR = { damage = 45, radius = 60, turns = 3, fuse = 4 * 60 }
-- Trapano (primary, drill): flies like the rocket until it touches terrain, then
-- bores straight on, digging a tunnel of radius pixels at speed px/s for at most
-- dig pixels. If it touches a robot it blows up there (damage, slow); if it comes
-- out into the open it keeps flying straight for after pixels at fly_speed (it hits
-- whoever is behind the wall) and blows up on the first robot or at the end of the
-- run; if the dig runs out inside the terrain it blows up weakly.
C.DRILL = { speed = 560, dig_speed = 300, dig = 220, radius = 7, after = 200, fly_speed = 560,
	blast = { r = 14, damage_r = 24, damage = 48, impulse = 30 },
	inner = { r = 10, damage_r = 18, damage = 24, impulse = 20 } }
-- Calamita (secondary, magnet): instant pulse centred distance pixels from the
-- user along the aim: every robot (the user too) within radius slides to the
-- centre in ticks ticks, for a little damage (not to the user). Nothing happens
-- if there is no ground within drop pixels under the centre (nobody is pulled
-- over a pit: no killing with a teleport + magnet) or the centre is in terrain.
C.MAGNET = { distance = 120, radius = 150, ticks = 30, damage = 40, drop = 120 }
-- Cannonata (secondary, cannon): the user is launched as a ballistic body at
-- speed * power (at least min_power) with gravity times the robots', no control.
-- It passes through robots hitting each once (damage, and pushes them away at
-- push) and stops against terrain. Past an edge it just falls: whoever lands
-- in the void dies, the parachute and the air jumps still work after it ends.
C.CANNON = { speed = 640, min_power = 0.35, gravity = 0.8, damage = 40, push = 320, lift = 160 }
-- Petardo (secondary, petard): a small bomb thrown like the Uovo that bounces and
-- blows up on touching a robot (not the thrower in the first moments) or after
-- fuse ticks: damage, no crater, and everyone within radius (the thrower too, for
-- jumping) is pushed away from the centre at push, plus lift.
C.PETARD = { damage = 28, radius = 60, push = 450, lift = 120, fuse = 90 }

-- Tactical items: usable at any moment of your own turn, repositioning
-- included, and they don't count as attacks. Speeds in pixels per second.
-- Trap: placed at the feet and armed from the next turn; an opponent stepping
-- on it gets its feet locked (Sergio, 9 November 2026: no damage, no launch):
-- it can't walk, jump or use the Rampino until the end of its own turn (the
-- next one, if it was trapped in someone else's turn), but it can still shoot,
-- use items and teleport. Explosions still push it. game.lua, rb.trapped.
-- Trampoline ("Molla", Sergio, 9 November 2026): thrown like the Uovo and
-- stays where it lands (if it lands on a robot, at its feet), launching towards
-- where it was thrown (dir, a chevron on the board). Anything falling on it bounces up: robots, shots,
-- Uova, orbs, crates and items (the board is top pixels above the base); robots
-- and shots also leave sideways at push_vx in its direction (about 400 px on
-- flat ground). A robot launched like that keeps the push until it touches
-- ground or opens the parachute: the controls only add or take away its air speed. Staying on it each bounce is lower (decay)
-- until below min_vy you stop (shots then touch the terrain below, and the
-- missile explodes).
C.TRAMPOLINE = { half_w = 18, top = 7, launch_vy = 300, push_vx = 145, decay = 0.6, min_vy = 80 }
-- Shield: absorbs hp damage and halves pushes until the start of the owner's next turn
C.SHIELD = { hp = 40, knockback = 0.5 }
-- Parachute: in your own turn, in the air, one tap opens it (if you have any
-- of stats.parachutes per match) and another closes it. Open, you fall at most
-- at fall_speed, move horizontally air_mul times faster (even right after
-- being knocked) and landing does no damage. Fast because it is a once per
-- match resource (Sergio, 26 October 2026)
C.PARACHUTE = { fall_speed = 60, air_mul = 1.5 }
-- Healing circles: at the start of a turn every every turns one appears at a
-- random point of the surface (at most max at once). At the end of a turn,
-- anyone's, every robot with its feet inside (radius r) gets back hp of life
-- and, if it healed someone, the circle disappears
C.HEAL = { every = 2, max = 2, hp = 27, r = 26 }
-- traps and trampolines on the map at most, all together
C.MAX_PLACED = 8

-- Start-of-match draft (sim/draft.lua): two fans, the same for everyone, one
-- of DRAFT_OFFER crate primaries and one of secondaries (game.DRAFT_SECONDARIES).
-- Everyone takes a primary (with DRAFT_SHOTS shots) and a secondary
-- (SECONDARY_SHOTS.draft shots), one and then the other; the others' picks are
-- hidden and duplicates are fine (Sergio, 30 October 2026). When
-- DRAFT_SECONDS run out whoever hasn't picked takes the first weapon of each fan.
-- Sergio (24 October 2026): 2 shots, with 3 turns each a single one gets used
-- up on the first useful turn.
C.DRAFT_SECONDS = 15
-- the line-up with everyone's cards (client/menu/lineup.lua) before the
-- draft: online the server waits these seconds too
C.LINEUP_SECONDS = 5
C.DRAFT_OFFER = 3
C.DRAFT_SHOTS = 2
-- Shots of the drafted secondary (Sergio, 31 October 2026: no longer unlimited):
-- draft at the start; each Lama hit on an enemy gives one back, up to max.
-- The Lama stays unlimited.
C.SECONDARY_SHOTS = { draft = 2, max = 2 }

-- Status effects (strategy 9): they last until the end of the next turn of
-- whoever suffers them (stats.status_turns of the attacker) and show on the robot.
-- The shield stops them: they only pass if the hit reaches life.
-- Burn: damage at the start of each of your turns. Slow: run, air speed and
-- jump reduced. Cracked armour: you take more damage.
C.STATUS = {
	burn = { damage = 17 },
	slow = { move = 0.6, jump = 0.8 },
	cracked = { damage = 1.25 },
}
-- Map hazards (sim/hazards.lua; the maps ask for them in sim/maps.lua).
-- Storm: the gust at the end of a round moves every robot by step world units.
-- Hail: count stones per round fall on columns at least gap apart (margin from the
-- sides), r is the stone's radius, speed its fall in units per second, blast its
-- explosion (the same fields as game.MISSILE_BLAST: a missile does 25).
C.WIND = { step = 66 }
C.HAIL = { count = 3, margin = 260, gap = 340, r = 12, speed = 480,
	blast = { r = 30, damage_r = 62, damage = 35, damage_min = 15, impulse = 10 } }
-- Boulders (Avarizia): one rolls down each slope at the end of a round. r is its radius, v0 the
-- first speed (world units per second), accel how fast the slope speeds it up (a drop of d
-- gives accel * d / v), fric the slowing down everywhere, vmax the top speed, stop the speed
-- under which it crumbles, climb the highest step it rolls over. Whoever it meets takes
-- damage once and is shoved shove units along.
C.BOULDER = { r = 33, v0 = 60, accel = 250, fric = 90, vmax = 300, stop = 12, climb = 9, damage = 22, shove = 18 }
-- Rising water (Ira): from the round "from" on, at the end of every round the level goes up
-- by step; whoever stands under it is out (drowned: the same as falling off the map).
C.WATER = { from = 3, step = 40 }
-- Fire rain (Violenza's Sabbione): the hail, more stones and each one sets alight (status burn).
C.FIRE_RAIN = { count = 4, margin = 200, gap = 280, r = 12, speed = 480,
	blast = { r = 30, damage_r = 62, damage = 30, damage_min = 12, impulse = 10 } }
-- False bridges (Frode): once a robot steps on one, or a shot hits it, it falls after delay
-- ticks (the crumbling is announced: 150 ticks are about two thirds of its way across).
C.BRIDGE = { delay = 150 }
-- Ice (Tradimento, Lucifero's lake): whoever stops walking on it keeps sliding, the speed
-- (world units per tick, at most max) shrinking by decay at every tick.
C.ICE = { decay = 0.97, max = 1.2, min = 0.05 }

-- Which weapon gives which effect (our choice). Burn comes from the Uova of
-- whoever has stats.burning_blasts (the Fornace set).
C.WEAPON_STATUS = { shards = "slow", punch = "cracked", boomerang = "cracked", tar = "burn", drill = "slow", fire_rain = "burn" }

-- Stats of each robot that aren't physics. Changed by the skill tree and gear
-- (opts.players[i].stats in game.new); run, jump and air speed come from
-- sim/game.lua (DEFAULT_STATS).
C.STATS = {
	-- 100: every damage is a percentage of life. It was 150 (23 October, for the
	-- two attacks per turn); Sergio, 29 October 2026: "ci vogliono 5 turni per
	-- ammazzare qualcuno, tutto deve togliere di più in percentuale". With weapons
	-- at 5/3 a hit takes 2.5 times the share of life it used to: a life lasts
	-- about 2 enemy turns in 1 v 1 (it was 4), rarely just one.
	-- Shield, heals, pieces and tree went down to 2/3, the same share of life.
	max_hp = 100,
	teleports = 2,           -- teleport orbs at the start (Sergio: 2); more are earned by attacking early
	parachutes = 1,          -- parachutes per match (Sergio, 24 October 2026: one)
	time_orbs = 1,           -- 1: leftover seconds become orbs; 0 no (the lessons that aren't about orbs)
	knockback_mul = 1,       -- how far you get pushed by hits
	fall_damage_mul = 1,     -- how much falling hurts
	trap_radius = 12,        -- how wide the placed trap is
	air_jumps = 0,           -- air jumps before touching the ground (Mobilità branch, Corvo set)
	burning_blasts = 0,      -- 1: the Uovo burns whoever it hits (Fornace set)
	status_turns = 1,        -- for how many turns a status effect given by this robot lasts
	-- the powers of the Sigilli (sim/skills.lua); these values change nothing
	hook_range = 1,          -- how far the Rampino reaches, relative to HOOK.range
	extra_hooks = 0,         -- Rampini per turn beyond the first
	orb_time = 0,            -- ticks added to the turn by a teleport before attacking
	start_shields = 0,       -- shields in hand at the start
	heal_mul = 1,            -- how much the healing circles heal you
	burn_immune = 0,         -- 1: burning doesn't hurt you
	last_stand = 0,          -- times per match a hit leaves you at 1 hp instead of killing you
	phoenix = 0,             -- 1: dying you explode (PHOENIX_BLAST)
	shield_mul = 1,          -- how much your shields absorb, relative to SHIELD.hp
	blast_push = 1,          -- how far your explosions push
	trampoline_mul = 1,      -- how high your trampolines throw
	extra_secondary = 0,     -- more shots of the draft secondary
	crate_bonus = 0,         -- more shots of each crate weapon you pick up
	double_traps = 0,        -- 1: a trap from a crate counts two
	double_springs = 0,      -- 1: a trampoline from a crate counts two
	finisher = 0,            -- 1: your explosions push twice as far whoever has less than FINISHER_HP
	burn_mul = 1,            -- how much the burning you give takes
	-- Attack and Defense (Sergio, 14 Nov): damage = weapon x (100 + Attack) / (100 + Defense)
	-- of whoever is hit; equal points cancel out, every point of Defense is 1% more life
	attack = 0,
	defense = 0,
	-- the signatures of the pieces (sim/gear.lua M.SIGNS): 0 = off
	sig_sword = 0, sig_self = 0, sig_climb = 0, sig_chute = 0,
	sig_high = 0, sig_air_guard = 0, sig_soft = 0, sig_glide = 0,
	sig_first = 0, sig_thorns = 0, sig_stomp = 0, sig_air_fire = 0,
	sig_fury = 0, sig_first_guard = 0, sig_rooted = 0, sig_ballast = 0,
	sig_ambush = 0, sig_blink_guard = 0, sig_blink_run = 0, sig_far_orb = 0,
}
-- Signatures: how much higher than its target the Dall'alto attacker must be,
-- the life under which Furia hits harder, the Pestone's reach and push
C.SIG = { high = 48, fury_hp = 30, stomp = { r = 0, damage_r = 70, damage = 0, impulse = 10 } }
-- the weapons that hit up close (Brace addosso)
C.MELEE = { sword = true, mallet = true, punch = true, lunge = true }
-- Colpo di grazia (sim/skills.lua): below this life your explosions push twice as far
C.FINISHER_HP = 20

return C
