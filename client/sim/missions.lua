-- Missions: the lessons (Chapter 0) and the campaign circles (sim/levels.lua),
-- all in the same format. A mission is a real match with a goal written as
-- data: a few verbs (below) instead of code, so one day the server can send
-- them and they also serve the daily puzzle (docs/roadmap.md, area 3). Pure
-- Lua: the gui_script shows the line, the goal and the stars.
--
--   local r = missions.nuova("attrezzi")
--   missions.prova(l, chapter_id, painted)          -- the Copione's GIOCA: that level as it is being edited (its id)
--   local seed, map, opts = missions.partita(r, seed, picks, help)  -- for game.new (or replay.nuova);
--                                                   help: after many losses, softer opponents
--   missions.prepara(r, g, bots)                    -- right after, once (bots: replay.partita's; Favilla's
--                                                   demonstrations play through it, like a bot)
--   missions.evento(r, g, e, bots)                  -- for every simulation event (bots: from replay.partita)
--   local outcome = missions.tick(r, g)             -- every tick: nil, "fatta" or "fallita"
--   missions.tocca(r, what)                         -- the player touched the controls (lessons: time starts; r nil: nothing);
--                                                   what: the chosen weapon, "salta", "mira", "annulla" or nil
--   local what = missions.highlight(r)              -- the control to highlight (or nil)
--   missions.vede(r, weapon)                        -- is that weapon (or "teleport", "parachute", "tempo",
--                                                   "punti") shown in the HUD? (r nil: everything)
--   local x, y = missions.flag(r)                   -- where the chequered flag is (or nil)
--   local i = missions.target_robot(r)              -- in the lessons, the robot to hit now (or nil)
--   local w = missions.scheda(r)                    -- the weapon card to open now (once), or nil
--   local z = missions.zoom(r)                      -- the camera level the step wants (once), or nil
--   local line = missions.line(r)                   -- the line of the moment (testo, faccia...) or nil:
--                                                   -- the battle shows it in a vignette (battle/vignette.lua)
--   local text = missions.obiettivo(r)              -- the remaining goal, always in view (or nil)
--   local f = missions.guida(r)                     -- where Favilla is in the cortile (l.guida), or nil:
--                                                   -- { x, y, vx, vy, grounded, facing } (battle/favilla.lua draws her)
--   local x, y = missions.scintilla(r)              -- the spark still to take (l.scintilla), or nil
--   local a = missions.mira(r)                      -- Favilla aiming in a demonstration: { robot, weapon, angle, power } or nil
--   local i, clip = missions.posa(r)                -- Favilla striking a pose (an animation clip), or nil
--   local i, text = missions.battuta(r)             -- what Favilla says over her head now (once), or nil
--   missions.stelle(r)                              -- { true, false, true }: each star with its criterion
--   missions.quante(stars)                          -- how many are lit
--   missions.criteria(l)                            -- what each star needs: { "FATTA", "CON 60 PUNTI DI VANTAGGIO", ... }
--   missions.dopo(id)                               -- the next mission in the chapter (nil after the last)
--
-- A mission (fields, all data except where stated):
--   id, titolo, goal_text (the first line, until the first thing is done), highlight
--     (the control the goal_text highlights, as in the lines below)
--   tipo: what kind of level it is (corsa, bersagli, duello, squadra, orda,
--     resistenza, bottino, custode): only shown, on its card in the CAMPAGNA and
--     its postcard (ui/level_types.lua), the rules don't read it
--   mappa (a game map) or arena = { { x, y, w, h }, ... } (steel rectangles:
--     craters don't break the puzzle) and spawns (the player first)
--   giocatori: opts.players of game.new (team, bot = level, carattere, dummy, pick,
--     secondary, tool, stats); nome: what that robot is called (the keepers);
--     battute: who speaks for it (battle/quips.lua; without, its carattere);
--     pelle: the skin it wears in this match (battle/skins.lua: Favilla), only drawn
--   vedi = { "missile", "eagle", ... }: the lessons show only what's needed
--     ("primarie", "secondarie": all the ones you have; "teleport": the button and
--     the orbs from time; "parachute"; "tempo": the timer; "punti": the scores;
--     "baratto": the second attack swapped for a teleport): the rest isn't
--     there at all. The UI is discovered little by little (Sergio, 29 Oct):
--     without vedi everything shows, with vedi the timer and points only if listed.
--     Without "punti" there are no points at all (Sergio, 31 Oct: they distract
--     from the exercise): nobody scores, no Crown.
--     A weapon picked up from a crate shows from then on
--   no_weapons: the player starts without weapons, until they find the Lanciarune in a crate
--   casse = { { dopo = 2, arma = "missile", x = 1250 }, ... }: once step dopo is done
--     (0: at once), that crate drops there (the card of a new weapon pauses the
--     game: battle/card.lua). In the lessons a limited-shot weapon found
--     there comes back when it can be used again
--   cards = { { dopo = 1, arma = "sword", give = true } }: once step dopo is done
--     that weapon's card opens; give: and you get it, without a crate (Sergio,
--     30 Oct: the Rampino and the parachute aren't found in crates)
--   without_time: no timer and no turns, the turn is yours until you finish.
--     After an attack (or the Rampino) you can use it again at once; if it hit
--     nobody and did no step, "Ritenta" (counts "misses"). Sergio, 29 Oct: in a
--     lesson you never wait a turn to retry. A parachute you found comes back
--     as soon as you're on the ground
--   In the lessons (not in the Prima partita) the next action is nearly forced
--   (Sergio, 30 Oct): only what the step says can be used (only, below); if
--   time is about to run out it stops at one second until you do it; a missed
--   shot is given back at once (with time: you go back where you were when you
--   shot); whoever falls respawns as they were at the last step done, orbs
--   included (targets where they started; a downed one no longer needed by any
--   step stays down); if the step can only be done with orbs and you have none
--   left, Ritenta and you're back as you were.
--   The cards (below) open when the hit of the step has landed
--   regole: other opts of game.new; secondi: match length; globi: how many
--     teleports the player starts with; vita, punti = { [robot] = n } at the start;
--     regrow = { robot, ... }: every turn they come back with full life
--   obiettivo: the steps (below), in order unless in_order = false
--   the mission fails if the match ends first; al_tempo = "abbattimenti": when
--     time runs out you win if you downed the others at least as many times as
--     they downed you (the Duello: on a tie Favilla gives it to you)
--   turni: past this many player turns it starts over
--   al_posto: everyone respawns at their spawn, as in the lessons (the sniper
--     knocked off its island comes back there, not within reach)
--   stelle = { punti = 60, bonus = { conta = "morti", at_most = 0, testo = "SENZA MORIRE" } }
--     (the second with at least that point lead over the opponents at the end:
--     the circles, where points count; Sergio, 31 Oct: no longer turns) or
--     { bonus = { ... }, bonus2 = { ... } } (two bonuses: the lessons)
--   medaglia = { conta = "scintille", at_least = 1, testo = "LA SCINTILLA" }: the lessons
--     of the cortile have no three stars (Sergio, 3 Nov): «Fatta» and, where
--     there's a real challenge, Favilla's optional medal (a bonus, below)
--   guida = { parte = 1, gara = true, percorso = { { x =, y =, t = }, { x =, y =, t =, salto = 30 }, ... } }:
--     Favilla in the cortile, a puppet drawn by the battle and never hit: from
--     step parte done (0: at once) she follows the path, t in seconds of game
--     (vignettes stop it), salto = the height of the arc to that point. gara:
--     the medal counter "prima" if you finish before she arrives
--   insegna = true (in giocatori, with nome and pelle): Favilla as a real robot of the
--     player's team, who shows the moves by doing them (dimostra, below). She
--     never plays a turn of her own and doesn't get hurt; her hits don't do the
--     player's steps
--   dimostra = { { quando = { passo = 1 }, mosse = { { cammina = 900 }, { salta = "destra" },
--     { arma = "missile", angolo = 45, potenza = 0.7 }, ... } } }: Favilla's
--     demonstrations (Sergio, 6 Nov: she shows a move by doing it, then you do
--     it). When quando holds (as the lines; without: at once) and you are still
--     on your turn, the turn passes to her: she does the moves in order with
--     the real keys and physics, then the turn comes back to you as it was
--     (time stopped meanwhile; her shots can push you but don't take your
--     life). Once each. The moves (one verb each):
--       cammina = x (walks there; ends also falling off an edge), salta =
--       "destra" | "sinistra" | "su", arma = a weapon or tool ("missile",
--       "sword", "hook", "parachute", "teleport"...) with angolo (degrees, 0
--       right, 90 up) and potenza (0-1, default 1): she aims a second, showing
--       it, then fires (the parachute and the shield as soon as they can be used)
--       and waits for everything to settle (subito = true: fires at once,
--       without showing the aim; verso = "destra" | "sinistra": steers that way
--       meanwhile, the parachute across a gap; fino_a = x: until past that x);
--       salta with in_aria = true: the
--       next move starts at the top of the jump; aspetta = seconds; dice = "text"
--       (over her head, like the bots); posa = "vittoria" (an animation clip,
--       battle/animations.lua) for secondi (default 1.5)
--   scintilla = { x =, y = }: a spark in the air, taken when your body touches it
--     over that height there (counter "scintille"): the medal of a full jump
--   nascosti = { 2 }: robots that aren't there (the game wants at least two)
--   collaudo = { carattere, piano, senza }: how strumenti/arena/collaudo.lua tests it
--   righe = { { testo, quando, fino, highlight, stops, subito, mostra, faccia } }:
--     quando and fino are data, every key must hold (and):
--       passo = 2 (step 2 done), turno = 2 (your 2nd turn), turno_altri = 2 (the
--       others' 2nd turn), di_turno = "tu" | "altri" (whose turn it is now),
--       evento = "crate_pick" (that simulation event; di = "tu" | "altri": whose,
--       without: yours or nobody's; arma = "punch": with that weapon), tocca = "mira"
--       (the player touched that, this turn), usato = "primaria" | "secondaria" |
--       "attrezzo" (already used this turn), finestra = true (after the first
--       attack, while its window is open), in_caduta = true (you are falling fast
--       and still have the parachute), corona = "tu" (you are first), conta = "prima",
--       almeno = 1 (a counter, below); vicino = 250 (you are within that many
--       pixels of Favilla, insegna: she waits for you); uno = { {...}, {...} }: one of them (or).
--     Only data, never functions: the Copione (strumenti/copione) shows and
--     edits them, and a level travels as text to the web build (docs/copione.md).
--     highlight: the control the line suggests ("primaria", "secondaria", a
--     weapon, "teleport", "cammina", "salta", "mira", "annulla"): the HUD
--     highlights it and, in the lessons, time stays stopped until you touch it
--     (stops = false: only the highlight, for lines that come while airborne).
--     In the circles the highlight is there but the game never stops. subito:
--     the line replaces the current one (aiming has already started).
--     mostra = "grande": the battle stops on the big vignette with the drawing
--     of the highlight before showing it in the strip (only drawn, the
--     simulation doesn't read it); without, only the strip. faccia: the face of
--     who says it (battle/vignette.lua FACCE); secondi: how long it stays (a short
--     «bravo»: 2), without the usual 5 (10 with a fino)
--   bravo = "Eccoti al cancello!" (bravo_faccia, default "ride"): Favilla's line when the
--     lesson is done, the «bravo» of its last step (it stays under «Fatta»)
--   Each step that closes a new move has nuova = true: then the lesson has the
--   four beats of Sergio's rule (6 Nov) for it, which strumenti/copione/controlla.lua
--   checks: spiega (a big line, or the opening, after the previous new move),
--   mostra (Favilla: her path, guida, or a demonstration from that moment), fai
--   (the step) and bravo (a line with a face when the step is done, or bravo)
--
-- The goal steps (testo: how it reads in the goal line). In addition, in the
-- lessons: only = { "sword", "teleport", "baratto", "primaria", ... }: until
-- the step is done only that can be used; zoom = 2: the camera widens to that
-- level (battle/camera.lua); globi = 2 (with usa = "globi"): time stops
-- where those orbs can still be earned
--   { usa = "globi" | "rampino" | "pogo" | "kickback" | "paracadute" | "baratto" }
--   { reach = { x = 1200, y = 150 }, flag = true }       standing above that
--                                           height, past that x (flag: the chequered flag is there)
--   { prendi = "missile" }                  pick up the crate with that weapon
--   { hit = 2, con = "sword" | "primaria" | "secondaria" | a weapon }
--   { down = 2 | "nemico", come = "vuoto", con = weapon, times = 3 }
--   { win = true }                          the match ends and your team won
-- Other verbs (survive, protect...) come with the missions that use them.
-- The counters for star bonuses: morti, teletrasporti, vuoto (your
-- environmental kills), abbattuti, danni (taken by you), misses (without_time),
-- globi (earned), globi_turno (the most earned in one turn), scintille, prima.

local game = require "sim.game"
local config = require "sim.config"
local maps = require "sim.maps"
local terrain = require "sim.terrain"
local campaign = require "sim.campaign"

local M = {}

local STEEL = terrain.STEEL
M.GIOCATORE = 1
local PLAYER = M.GIOCATORE
-- seconds of a line without a "fino": then it disappears by itself
local LINE_SECONDS = 5
-- without_time: an attack is over when nothing is flying and the player has been still for many ticks
local MISS_TICK = 45
-- a weapon card opens this many ticks after the hit of the step has landed
local CARD_DELAY = 24
-- how high above the terrain mission crates drop from
local CRATE_ABOVE = 280
-- the spark is a glow this wide around its point (battle/favilla.lua draws it
-- the same size): it is taken when your hit circle touches it
local SPARK_R = 13
local RETRY_TEXT = "Ritenta! Prendi confidenza con i comandi, prenditi il tuo tempo: {mira}"

-- Which weapon someone just used: the attack event -> weapon name
local ATTACKS = {
	fire = "missile", grenade = "grenade", shards = "shards", punch = "punch", sniper = "sniper",
	swing = "sword", eagle = "eagle", mallet = "mallet", lunge = "lunge", bellows = "bellows",
}
-- the player events that use up the attack or the Rampino of the turn
local ATTEMPTS = { hook_shot = true }
for k in pairs(ATTACKS) do ATTEMPTS[k] = true end
local CATEGORIES = {
	primaria = { grenade = true, shards = true, punch = true, sniper = true },
	secondaria = { eagle = true, mallet = true, lunge = true, bellows = true },
}
-- usa: the player event saying the mechanic was used
local USES = {
	globi = function(e) return e.type == "teleports" and e.amount > 0 end,
	rampino = function(e) return e.type == "hook" and e.anchor end,
	pogo = function(e) return e.type == "mallet_hit" and e.bounce end,
	-- the Tonante fired in the air: the kickback carries you away
	kickback = function(e, st) return e.type == "eagle" and not st.on_ground end,
	paracadute = function(e) return e.type == "parachute" end,
	baratto = function(e) return e.type == "swap" end,
}

-- only = { ... } of a step -> the function saying whether a control can be used
-- (p.permitted). Walking and jumping are always allowed
local function allowed_fn(only)
	local ok = {}
	for _, w in ipairs(only) do ok[w == "baratto" and "swap" or w] = true end
	return function(w)
		if ok[w] then return true end
		if game.SECONDARY[w] then return ok.secondaria == true end
		return ok.primaria == true and not game.TOOLS[w] and w ~= "teleport" and w ~= "swap"
	end
end

-- Missions, by id and by chapter --------------------------------------------------

local PER_ID, NEXT_ID = {}, {}
-- A level ready to play: its chapter's rules, the permitted controls of its
-- steps, its arena as a map (map: the map's id, missione_<id> unless said)
local function install(l, cap, map)
	PER_ID[l.id] = l
	l.chapter = cap.id
	-- in the lessons time waits for you to touch the controls (capitolo.aspetta)
	l.aspetta = cap.aspetta
	-- the nearly forced next action: the lessons, not the Prima partita
	l.riprova = l.aspetta and not l.guidata
	if type(l.obiettivo) == "table" then
		for _, p in ipairs(l.obiettivo) do
			if p.only then p.permitted = allowed_fn(p.only) end
		end
	end
	-- Favilla who shows the moves (insegna), if the level has her
	l.maestra = nil
	for i, p in ipairs(l.giocatori or {}) do
		if p.insegna then l.maestra = i end
	end
	if l.arena then
		l.mappa = map or "missione_" .. l.id
		maps.registra(l.mappa, { name = l.titolo, spawns = l.spawns, build = function(t)
			for _, q in ipairs(l.arena) do t:rect(q[1], q[2], q[3], q[4], STEEL) end
		end })
	end
end

for _, cap in ipairs(campaign.CAPITOLI) do
	for i, l in ipairs(cap.missioni) do
		assert(not PER_ID[l.id], "missione doppia: " .. l.id)
		install(l, cap)
		NEXT_ID[l.id] = cap.missioni[i + 1] and cap.missioni[i + 1].id
	end
end

-- The Copione's GIOCA (strumenti/copione): a level as it is being edited, in
-- place of the saved one with the same id (or a new one), in the chapter
-- chapter_id; no next mission. painted = false: its arena changed, the
-- painting of the saved one would lie (an unpainted map)
function M.prova(l, chapter_id, painted)
	local cap = campaign.CAPITOLI[1]
	for _, c in ipairs(campaign.CAPITOLI) do
		if c.id == chapter_id then cap = c end
	end
	install(l, cap, painted == false and "copione_" .. l.id or nil)
	NEXT_ID[l.id] = nil
	return l.id
end

function M.trova(id)
	return PER_ID[id]
end

function M.dopo(id)
	return NEXT_ID[id]
end

-- What the mission shows in the HUD (l.vedi; without it, everything)
local function category(w)
	-- (the HUD pieces that aren't weapons, "punti", "tempo"..., only by name)
	if not game.WEAPONS[w] then return nil end
	if game.SECONDARY[w] then return "secondarie" end
	if game.TOOLS[w] or w == "teleport" then return nil end
	return "primarie"
end

-- Is the touched control (what) the one the line suggests (att)?
local function matches_hint(att, what)
	if att == what then return true end
	if not what or not game.WEAPONS[what] then return false end
	if att == "secondaria" then return game.SECONDARY[what] == true end
	if att == "primaria" then return not game.SECONDARY[what] and not game.TOOLS[what] end
	return false
end

-- Has the player already touched that control (or one of its category) this turn?
local function touched_cmd(st, att)
	for what in pairs(st.touched_cmds) do
		if matches_hint(att, what) then return true end
	end
	return false
end

function M.vede(r, w)
	local l = r and r.l
	if not l or not l.vedi then return true end
	if r.prese and r.prese[w] then return true end
	local c = category(w)
	for _, v in ipairs(l.vedi) do
		if v == w or v == c then return true end
	end
	return false
end

-- The state of a running mission
function M.nuova(id)
	local l = assert(PER_ID[id], "missione sconosciuta: " .. tostring(id))
	return { l = l, st = { turni = 0, bot_turns = 0, steps_done = {}, times = {}, conta = {}, touched_cmds = {}, maestra = l.maestra },
		seen_weapons = {}, prese = {}, cadute = {}, opened = {}, waits = {}, cards = {}, giu = {}, riga = nil, esito = nil,
		shown = {}, ready = {}, battute = {} }
end

-- seed, map and options of game.new. picks: the players out of the draft
-- (menu/pick.lua), for the missions that have one
-- the silent help: bots go down two grades (sim/bot.lua M.GRADES) and start with less life
local HELP_HP = 0.75

function M.partita(r, seed, picks, help)
	local l = r.l
	local players = {}
	r.help = help
	for i, p in ipairs(l.giocatori) do
		local q = {}
		for k, v in pairs(p) do
			if k ~= "nome" and k ~= "battute" and k ~= "pelle" then q[k] = v end
		end
		if help and q.bot then q.bot = math.max(1, q.bot - 2) end
		-- Favilla who shows the moves never plays a turn of her own
		if q.insegna then q.dummy = true end
		if picks and picks[i] then
			q.pick, q.secondary = picks[i].pick, picks[i].secondary
		end
		players[i] = q
	end
	if l.globi or l.vedi then
		local st = {}
		for k, v in pairs(players[PLAYER].stats or {}) do st[k] = v end
		st.teleports = l.globi or st.teleports
		-- what the lesson doesn't show isn't there: no orbs (not even from time), no
		-- parachute
		if not M.vede(r, "teleport") then st.teleports, st.time_orbs = 0, 0 end
		if not M.vede(r, "parachute") then st.parachutes = 0 end
		players[PLAYER].stats = st
		-- nor for Favilla who shows the moves: no "+2 teletrasporti" in a lesson without orbs
		if l.maestra and not M.vede(r, "teleport") then
			local fs = {}
			for k, v in pairs(players[l.maestra].stats or {}) do fs[k] = v end
			fs.teleports, fs.time_orbs = 0, 0
			players[l.maestra].stats = fs
		end
	end
	local opts = { players = players }
	for k, v in pairs(l.regole or {}) do opts[k] = v end
	-- no crates: missions don't change with chance
	if not l.guidata and not opts.crate_every then opts.crate_every = 1000 end
	-- in the lessons no healing circles popping up at random (Sergio, 29 Oct)
	if l.aspetta then opts.heals = false end
	-- and no points where the lesson doesn't talk about them (Sergio, 31 Oct)
	if not M.vede(r, "punti") then opts.score = false end
	return seed or 1, l.mappa, opts
end

-- After game.new: match time, starting life and points, the first line.
-- The events of the start (the first turn) are counted here and discarded.
function M.prepara(r, g, bots)
	local l, st = r.l, r.st
	-- Favilla plays her demonstrations like a bot: the keys come from here
	if l.maestra and bots then
		bots[l.maestra] = { id = l.maestra, script = function(gg) return M.demo_keys(r, gg) end }
		r.can_demo = true
	elseif l.maestra then
		-- nobody to press her keys (the tests, the bot trial): she isn't there, not even in the way
		local rb = g.robots[l.maestra]
		rb.gone, rb.dead, rb.hp, rb.respawn_in = true, true, 0, nil
	end
	if l.secondi then g.match_left = l.secondi * 60 end
	-- the mission's life is also the full one: regrow goes back there, not to 150
	for i, v in pairs(l.vita or {}) do
		g.robots[i].hp, g.robots[i].max_hp = v, v
	end
	if r.help then
		for i, p in ipairs(l.giocatori) do
			-- the full life too: the bar stays full, it doesn't show
			local rb = g.robots[i]
			if p.bot then rb.hp = math.floor(rb.hp * HELP_HP); rb.max_hp = rb.hp end
		end
	end
	for i, v in pairs(l.punti or {}) do g.robots[i].points = v end
	-- whoever starts with the mission's points already has the Crown (it usually
	-- comes after SCORE.crown_rounds rounds): the Punti e Corona lesson has it hit at once
	if l.punti then g.round = math.max(g.round, (g.score.crown_rounds or 0) + 1) end
	if l.no_weapons then g.robots[PLAYER].disarmed = true end
	g:pop_events()
	-- the robots that aren't there (the game wants two): they vanish at once
	for _, i in ipairs(l.nascosti or {}) do
		local rb = g.robots[i]
		rb.gone, rb.dead, rb.hp, rb.respawn_in = true, true, 0, nil
		g:emit({ type = "gone", robot = i })
	end
	if g.current == PLAYER then st.turni = 1 else st.bot_turns = 1 end
	r.coda = {}
	r.riga = nil
	if l.aspetta then r.attesa, r.fermo = true, { timer = g.timer, window = g.window, match = g.match_left } end
	if l.without_time then r.senza = { timer = g.timer, match = g.match_left } end
	-- the goal_text until the first thing is done
	-- (in the lessons it gives way to the hints as soon as you touch the controls)
	if l.goal_text then
		r.coda[1] = { testo = l.goal_text, yields = l.aspetta, highlight = l.highlight, apertura = true,
			fino = { uno = { { usato = "primaria" }, { usato = "secondaria" }, { usato = "attrezzo" } } } }
	end
end

-- The steps -----------------------------------------------------------------------------

local function enemies_list(g, a, b)
	return g.robots[a].team ~= g.robots[b].team
end

-- The player's team points minus those of the leading opposing team
local function lead(g)
	local team_points_of = {}
	for _, rb in ipairs(g.robots) do team_points_of[rb.team] = (team_points_of[rb.team] or 0) + rb.points end
	local my_team, others = g.robots[PLAYER].team, nil
	for t = 1, #g.robots do
		if t ~= my_team and team_points_of[t] and (not others or team_points_of[t] > others) then others = team_points_of[t] end
	end
	return team_points_of[my_team] - (others or 0)
end

local function target(g, wanted, robot)
	if wanted == "nemico" then return enemies_list(g, PLAYER, robot) end
	return wanted == robot
end

local function weapon_ok(with_weapon, weapon_name)
	if not with_weapon then return true end
	if CATEGORIES[with_weapon] then return CATEGORIES[with_weapon][weapon_name] == true end
	return with_weapon == weapon_name
end

-- standing above height y, past x
local function over_it(g, x, y)
	local rb = g.robots[PLAYER]
	return not rb.dead and rb.grounded and rb.x >= x and rb.y >= y - 1
end

-- Is step p done now? e = nil: the check every tick
local function step_done(p, i, st, g, e)
	if p.usa then
		return e ~= nil and e.robot == PLAYER and USES[p.usa](e, st)
	elseif p.reach then
		return over_it(g, p.reach.x, p.reach.y)
	elseif p.hit then
		return e ~= nil and e.type == "damage" and e.amount > 0 and target(g, p.hit, e.robot)
			and weapon_ok(p.con, st.arma) and not (st.maestra and e.by == st.maestra)
	elseif p.prendi then
		return e ~= nil and e.type == "crate_pick" and e.robot == PLAYER and e.weapon == p.prendi
	elseif p.win then
		return e ~= nil and e.type == "over" and e.winner == g.robots[PLAYER].team
	elseif p.down then
		if e and e.type == "death" and e.by == PLAYER and target(g, p.down, e.robot)
			and (p.come ~= "vuoto" or e.env) and weapon_ok(p.con, st.arma) then
			st.times[i] = (st.times[i] or 0) + 1
			return st.times[i] >= (p.times or 1)
		end
		return false
	end
	error("passo sconosciuto")
end

-- goal done? Marks the steps that close with e
local function goal(l, st, g, e)
	if type(l.obiettivo) == "function" then return l.obiettivo(st, g, e) end
	local all_done = true
	for i, p in ipairs(l.obiettivo) do
		if not st.steps_done[i] then
			if step_done(p, i, st, g, e) then
				st.steps_done[i] = true
			else
				all_done = false
				if l.in_order ~= false then return false end
			end
		end
	end
	return all_done
end

-- How many steps are done
local function steps_count(st)
	local n = 0
	for _ in pairs(st.steps_done) do n = n + 1 end
	return n
end

-- The first missing step (or nil)
local function next_one(l, st)
	if type(l.obiettivo) ~= "table" then return nil end
	for i, p in ipairs(l.obiettivo) do
		if not st.steps_done[i] then return i, p end
	end
end

-- What a line waits for, as data only (the level script, strumenti/copione):
-- every key of the table must hold (and), uno = { {...}, {...} } holds if one
-- of them does (or)
local USED = { primaria = "primary", secondaria = "secondary", attrezzo = "tool" }
local function when(q, st, g, e)
	if q.uno then
		local any = false
		for _, o in ipairs(q.uno) do
			if when(o, st, g, e) then any = true break end
		end
		if not any then return false end
	end
	if q.evento then
		if e == nil or e.type ~= q.evento then return false end
		-- di: whose event ("tu", "altri"); without, yours or nobody's
		if q.di == "tu" then
			if e.robot ~= PLAYER then return false end
		elseif q.di == "altri" then
			if e.robot == PLAYER then return false end
		elseif e.robot ~= nil and e.robot ~= PLAYER then
			return false
		end
		if q.arma and e.weapon ~= q.arma then return false end
	end
	if q.passo and st.steps_done[q.passo] ~= true then return false end
	if q.turno and st.turni ~= q.turno then return false end
	if q.turno_altri and st.bot_turns ~= q.turno_altri then return false end
	if q.di_turno == "tu" and g.current ~= PLAYER then return false end
	if q.di_turno == "altri" and g.current == PLAYER then return false end
	if q.tocca and not touched_cmd(st, q.tocca) then return false end
	if q.usato and not g.used[USED[q.usato]] then return false end
	-- after the first attack of the turn, while the hit window is open
	if q.finestra and not (g.window > 0) then return false end
	if q.in_caduta then
		local rb = g.robots[PLAYER]
		if rb.grounded or not (rb.vy < -220) or not (rb.parachutes_left > 0) then return false end
	end
	if q.corona == "tu" then
		local l = g:leader()
		if l == nil or l.id ~= PLAYER then return false end
	end
	if q.conta and (st.conta[q.conta] or 0) < (q.almeno or 1) then return false end
	if q.vicino then
		local me, f = g.robots[PLAYER], st.maestra and g.robots[st.maestra]
		if not f or me.dead or f.dead then return false end
		local dx, dy = me.x - f.x, me.y - f.y
		if dx * dx + dy * dy > q.vicino * q.vicino then return false end
	end
	return next(q) ~= nil
end

-- One line at a time: the new one waits until the other is done or expired
-- (or another turn starts).
-- Without "fino" it stays LINE_SECONDS, with "fino" at most twice that.
-- A line highlighting a control, in the lessons, stops time until you touch it
-- (if you haven't already touched it this turn).
local function show_line(r, line)
	r.riga, r.line_until, r.line_yields, r.line = line.testo, line.fino, line.yields, line
	r.line_ticks = line.secondi and line.secondi * 60 or (line.fino and 2 or 1) * LINE_SECONDS * 60
	r.luce = line.highlight
	r.awaiting = nil
	local e = line.highlight
	if e and r.l.aspetta and line.stops ~= false and not touched_cmd(r.st, e) then
		r.attesa, r.awaiting = true, e
	end
end

-- The line goes away: if it was waiting for a control, time restarts
local function clear_line(r)
	if r.awaiting then r.attesa, r.awaiting, r.fermo = false, nil, nil end
	r.riga, r.line_ticks, r.luce, r.line_yields, r.line = nil, nil, nil, nil, nil
end

local function count(st, k)
	st.conta[k] = (st.conta[k] or 0) + 1
end

-- e = nil: the check every tick
local function check_event(r, g, e)
	local l, st = r.l, r.st
	if r.esito then return end
	if goal(l, st, g, e) then
		r.esito = "fatta"
		-- the race with Favilla: you finished before she arrived
		local gd = l.guida
		if gd and gd.gara and (r.guida_t or 0) < gd.percorso[#gd.percorso].t * 60 then count(st, "prima") end
		-- the hints aren't needed anymore (there's "Fatta!"); Favilla's «bravo» of the last step instead yes
		clear_line(r)
		if l.bravo then show_line(r, { testo = l.bravo, faccia = l.bravo_faccia or "ride" }) end
		return
	end
	if r.riga and r.line_until and when(r.line_until, st, g, e) then clear_line(r) end
	-- a new turn: the previous turn's lines aren't needed anymore
	if e and e.type == "turn" then clear_line(r); r.coda = {} end
	for i, line in ipairs(l.righe or {}) do
		if not r.seen_weapons[i] and when(line.quando, st, g, e) then
			r.seen_weapons[i] = true
			if line.subito then
				clear_line(r)
				table.insert(r.coda, 1, line)
			else
				r.coda[#r.coda + 1] = line
			end
		end
	end
	-- Favilla's demonstrations whose moment has come (they start when you're still)
	for i, d in ipairs(l.dimostra or {}) do
		if not r.ready[i] and (d.quando == nil or when(d.quando, st, g, e)) then r.ready[i] = true end
	end
	-- the goal_text of a lesson, once read (you touched the controls), and
	-- Ritenta give way to the next line
	if r.riga and r.line_yields and not r.attesa and #r.coda > 0 then clear_line(r) end
	if not r.riga and #r.coda > 0 then show_line(r, table.remove(r.coda, 1)) end
end

-- How far along the goal is: the steps done and the counted times
local function forward(st)
	local n = steps_count(st)
	for _, v in pairs(st.times) do n = n + v end
	return n
end

-- Is a down step missing?
local function needs_down(l, st)
	for i, p in ipairs(l.obiettivo) do
		if not st.steps_done[i] and p.down then return true end
	end
	return false
end

-- Does a missing step still have to hit or down that robot? (for "nemico",
-- only if no other enemy is left standing)
local function needs(l, st, g, robot)
	for i, p in ipairs(l.obiettivo) do
		local who = not st.steps_done[i] and (p.hit or p.down)
		if who == robot then return true end
		if who == "nemico" then
			local others = false
			for j, rb in ipairs(g.robots) do
				if j ~= robot and not rb.dead and enemies_list(g, PLAYER, j) then others = true end
			end
			if not others then return true end
		end
	end
	return false
end

-- Lessons: go back to how you were at the last step done (r.saved): where you
-- were and the orbs you had, so a wasted orb doesn't leave you without the move you need
local function restore_snapshot(r, g)
	local rb, s = g.robots[PLAYER], r.saved
	if not rb.dead then rb.x, rb.y, rb.vx, rb.vy = s.x, s.y, 0, 0 end
	rb.teleports_left = math.max(rb.teleports_left, s.globi)
end

function M.evento(r, g, e, bots)
	local l, st = r.l, r.st
	if ATTACKS[e.type] and e.robot == PLAYER then
		st.arma = ATTACKS[e.type]
	end
	-- lessons: an attempt, until it's over; it counts if it hits someone or does a step
	if l.riprova and ATTEMPTS[e.type] and e.robot == PLAYER and e.v ~= 0 and not r.shot then
		local rb = g.robots[PLAYER]
		r.shot = { t = 0, steps_done = steps_count(st), tipo = e.type, x = rb.x, y = rb.y }
	end
	if e.type == "damage" and e.amount > 0 and r.shot and e.robot ~= PLAYER then r.shot.preso = true end
	if e.type == "crate_pick" and e.robot == PLAYER then r.prese[e.weapon] = true end
	if e.type == "turn" then
		if e.robot == PLAYER then st.turni = st.turni + 1 else st.bot_turns = st.bot_turns + 1 end
		st.touched_cmds = {}
		-- the bot on turn shows what the player will do next (sim/bot.lua, b.piano)
		local b = bots and bots[e.robot]
		if b then b.piano = l.plans and l.plans[st.bot_turns] or nil end
		for _, i in ipairs(l.regrow or {}) do
			local rb = g.robots[i]
			if not rb.dead then rb.hp = rb.max_hp end
		end
		-- past the mission's turns it starts over
		if l.turni and st.turni > l.turni and not r.esito then r.esito = "fallita" end
	elseif e.type == "teleport" and e.robot == PLAYER then
		count(st, "teletrasporti")
	elseif e.type == "teleports" and e.robot == PLAYER then
		st.conta.globi = (st.conta.globi or 0) + e.amount
		st.conta.globi_turno = math.max(st.conta.globi_turno or 0, e.amount)
	elseif e.type == "respawn" and l.riprova and e.robot == PLAYER and r.saved then
		-- in the lessons the player respawns as they were at the last step done, orbs included
		restore_snapshot(r, g)
	elseif e.type == "respawn" and (l.riprova or l.al_posto) and l.spawns and l.spawns[e.robot] then
		-- in the lessons (and with al_posto) you respawn where you started, not at a
		-- random spot of the arena (a random target would end up in the way)
		local rb, sp = g.robots[e.robot], l.spawns[e.robot]
		rb.x, rb.y = sp.x, g.terrain:ground_below(sp.x, sp.from) or rb.y
	elseif e.type == "damage" and e.robot == PLAYER then
		st.conta.danni = (st.conta.danni or 0) + e.amount
	elseif e.type == "death" then
		if e.robot == PLAYER then count(st, "morti") end
		if e.by == PLAYER and enemies_list(g, PLAYER, e.robot) then
			count(st, "abbattuti")
			if e.env then count(st, "vuoto") end
		end
	elseif e.type == "over" then
		st.finished, st.won = true, e.winner == g.robots[PLAYER].team
	end
	if e.type == "points" or e.type == "over" then st.gap = lead(g) end
	local first_one = forward(st)
	check_event(r, g, e)
	-- lessons and still targets: downed by you, if no longer needed it stays down
	-- (Sergio, 30 Oct: the island of Il turno, the targets of Giù dal bordo). If
	-- there's a down step, only if counted (thrown into the void): otherwise it goes back to its place
	local frozen = l.giocatori[e.robot] and l.giocatori[e.robot].dummy
	if e.type == "death" and (l.riprova or frozen) and e.by == PLAYER and e.robot ~= PLAYER
		and not needs(l, st, g, e.robot) and (forward(st) > first_one or not needs_down(l, st)) then
		r.giu[e.robot] = true
	end
	if r.esito then return end
	-- lessons: on each of your turns and when you respawn the goal is rewritten and
	-- time waits for you to touch the controls, so there's time to read
	if l.aspetta and e.robot == PLAYER and (e.type == "turn" or e.type == "respawn") then
		r.attesa, r.fermo = true, { timer = g.timer, window = g.window, match = g.match_left }
		local txt = l.goal_text
		local i, p = next_one(l, st)
		if i and i > 1 then txt = p.testo end
		-- (if the turn doesn't already have its own line to say)
		if txt and not r.riga then show_line(r, { testo = txt, yields = true }) end
	end
	if e.type == "over" then
		local c = st.conta
		local tied = l.al_tempo == "abbattimenti" and (c.abbattuti or 0) >= (c.morti or 0)
		r.esito = tied and "fatta" or "fallita"
	end
end

-- The player touched the controls (what: the chosen weapon, "salta", "mira",
-- "annulla" or nil): time restarts, but if the line waits for one control only
-- when you touch that one
function M.tocca(r, what)
	if not r then return end
	if what then r.st.touched_cmds[what] = true end
	if r.awaiting then
		if not matches_hint(r.awaiting, what) then return end
		-- done: the highlight goes off, the line stays as long as needed
		r.awaiting, r.luce = nil, nil
	end
	r.attesa, r.fermo = false, nil
end

-- The control to highlight, while its line is in view
function M.highlight(r)
	return r.riga and r.luce or nil
end

-- without_time: time doesn't pass and the turn doesn't end
local function without_time(r, g)
	local f = r.senza
	g.timer, g.match_left, g.window = f.timer, f.match, 0
	local rb = g.robots[PLAYER]
	-- a parachute you found comes back as soon as you're on the ground: retry as often as needed
	if r.prese.parachute and rb.grounded and not rb.parachute and rb.parachutes_left == 0 then
		rb.parachutes_left = 1
	end
end

-- Lessons: after an attempt, without time everything can be used again; if it
-- did nothing, Ritenta (and with time that shot comes back, and you go back
-- where you were when you fired it)
local function attempt_over(r, g)
	local t = r.shot
	if not t or r.esito then return end
	local rb = g.robots[PLAYER]
	local frozen = not (g.projectile or g:shards_flying() or #g.orbs > 0) and (rb.dead or rb.grounded
		and not (rb.hooked or rb.hook_shot or rb.swing or rb.punch or rb.lunge or rb.mallet or rb.recoil))
	t.t = frozen and t.t + 1 or 0
	if t.t < MISS_TICK then return end
	r.shot = nil
	local missed = not t.preso and steps_count(r.st) == t.steps_done
	if r.l.without_time then
		g.used.primary, g.used.secondary, g.used.tool = false, false, false
	elseif missed then
		if not ATTACKS[t.tipo] then
			g.used.tool = false
		elseif game.SECONDARY[ATTACKS[t.tipo]] then
			g.used.secondary = false
		else
			g.used.primary = false
		end
		if not (g.used.primary or g.used.secondary) then g.window = 0 end
		if not rb.dead then rb.x, rb.y, rb.vx, rb.vy = t.x, t.y, 0, 0 end
	end
	if missed then
		count(r.st, "misses")
		clear_line(r)
		show_line(r, { testo = RETRY_TEXT, faccia = "preoccupata", yields = true })
	end
end

-- Lessons: after a step, on the ground and still, the player saves how they
-- are (r.saved: they go back there if they fall or are left without the move
-- they need). If the step can only be done with orbs and none are left,
-- Ritenta and go back as you were
local function hold_still(r, g, p)
	local rb = g.robots[PLAYER]
	local flying = g.projectile or g:shards_flying() or #g.orbs > 0
	if rb.dead or not rb.grounded or flying then
		r.stuck_ticks = 0
		return
	end
	local n = steps_count(r.st)
	if not r.saved or r.saved.steps_done ~= n then
		r.saved = { steps_done = n, x = rb.x, y = rb.y, globi = rb.teleports_left }
	end
	local without = p and p.permitted and p.permitted("teleport") and not g:can_use("teleport")
	if without then
		for w in pairs(game.WEAPONS) do
			if not (w == "teleport" or w == "swap" or game.TOOLS[w]) and p.permitted(w) then without = false end
		end
	end
	r.stuck_ticks = without and (r.stuck_ticks or 0) + 1 or 0
	if r.stuck_ticks >= MISS_TICK then
		r.stuck_ticks = 0
		restore_snapshot(r, g)
		count(r.st, "misses")
		clear_line(r)
		show_line(r, { testo = RETRY_TEXT, faccia = "preoccupata", yields = true })
	end
end

-- Can step p be done now? (one of the controls it names can be used; to hit,
-- an attack: with only the orb the turn goes on)
local function allowed(g, p)
	if not p.permitted then return false end
	local hit_def = p.hit or p.down
	for w in pairs(game.WEAPONS) do
		local attack = not (w == "teleport" or w == "swap" or game.TOOLS[w])
		if p.permitted(w) and (attack or not hit_def) and g:can_use(w) then return true end
	end
	return false
end

-- Lessons with time: as long as the step to do can be done (or a shot is in
-- flight) time doesn't go below one second; for orbs, not past those
local function hold_clock(r, g, p)
	-- (a place to reach on foot can always be reached: taking cover after the attacks)
	local on_foot = p.reach and not p.only
	if not (r.shot or on_foot or allowed(g, p)) then return end
	local minimum = 60
	if p.usa == "globi" and p.globi then
		local thresholds = {}
		for i, v in ipairs(config.TELEPORT_THRESHOLDS) do thresholds[i] = v end
		table.sort(thresholds)
		-- (two ticks of margin: the shot leaves the next tick)
		minimum = game.TURN_TICKS - thresholds[#thresholds - p.globi + 1] * 60 + 2
	end
	if g.timer < minimum then g.timer = minimum end
	if g.window > 0 and g.window < 60 then g.window = 60 end
end

-- The robot to hit or down in the step to do (the marker above it), or nil
function M.target_robot(r)
	if not r or r.esito or not r.l.riprova then return nil end
	local _, p = next_one(r.l, r.st)
	return p and (p.hit or p.down) or nil
end

-- The chequered flag of the step to do (reach with flag), or nil
function M.flag(r)
	local _, p = next_one(r.l, r.st)
	if p and p.reach and p.flag then return p.reach.x, p.reach.y end
end

-- Favilla's demonstrations (l.dimostra) -------------------------------------------
-- The turn passes to her, she presses the keys of each move (as a bot,
-- sim/bot.lua b.script), then it comes back to the player as it was.

local IDLE = {}
-- how long she aims, showing it, before firing
local DEMO_AIM = 60
-- a move that can't end (stuck, fallen) gives up after this many ticks
local DEMO_LIMIT = 8 * 60
-- still ticks after a shot (and at the end) before going on
local DEMO_STILL = 20
local DEMO_POSE = 1.5
local SIDES = { destra = 1, sinistra = -1, su = 0 }
-- the tools used at once, without aiming
local NO_AIM = { parachute = true, shield = true, swap = true }

-- nothing flying and rb still on the ground
local function settled(g, rb)
	if g.projectile or g.burst or g:shards_flying() or #g.orbs > 0 then return false end
	return rb.dead or rb.grounded and not (rb.hooked or rb.hook_shot or rb.swing or rb.punch
		or rb.lunge or rb.mallet or rb.recoil or rb.parachute)
end

-- she can always use the move she shows: the weapon, an orb, a parachute
local function arm(g, rb, w)
	g.used.primary, g.used.secondary, g.used.tool = false, false, false
	if w == "teleport" then
		rb.teleports_left = math.max(rb.teleports_left, 1)
	elseif w == "parachute" then
		rb.parachutes_left = math.max(rb.parachutes_left, 1)
	elseif game.WEAPONS[w] and not game.FREE_WEAPONS[w] then
		rb.ammo[w] = math.max(rb.ammo[w] or 0, 1)
		if game.SECONDARY[w] then rb.secondary = w end
	end
	rb.disarmed = nil
end

-- The keys of Favilla's move, this tick (only on her turn, during a demonstration)
function M.demo_keys(r, g)
	local d = r.demo
	if not d or g.current ~= d.who or g.phase ~= "aim" then return IDLE end
	local mv = r.l.dimostra[d.i].mosse[d.k]
	-- all done: she waits for everything to settle (demonstrations, below)
	if not mv then return IDLE end
	local rb = g.robots[d.who]
	d.t = d.t + 1
	d.aim, d.pose = nil, nil
	local finished = false
	local keys = IDLE
	if d.t > DEMO_LIMIT then
		finished = true
	elseif mv.cammina then
		local dx = mv.cammina - rb.x
		-- arrived, or off an edge and falling (the next move: the parachute)
		if math.abs(dx) <= 6 or (not rb.grounded and rb.vy < -150) then
			finished = true
		else
			keys = { left = dx < 0, right = dx > 0 }
		end
	elseif mv.salta then
		local side = SIDES[mv.salta] or 0
		if not rb.grounded then d.up = true end
		-- in_aria: the next move starts at the top of the jump (the Maglio, the Tonante in the air)
		if (d.up and rb.grounded) or (mv.in_aria and d.up and rb.vy <= 0) then
			finished = true
		else
			keys = { left = side < 0, right = side > 0, jump = d.t == 1, hold = true }
		end
	elseif mv.arma then
		local w = mv.arma
		if d.t == 1 then arm(g, rb, w) end
		if d.shot then
			d.still = settled(g, rb) and d.still + 1 or 0
			finished = d.still >= DEMO_STILL
			-- verso: she steers that way meanwhile (the parachute across a gap)
			-- (fino_a = x: only until she gets past that x)
			local side = SIDES[mv.verso]
			local far = mv.fino_a == nil or (side or 0) * (mv.fino_a - rb.x) > 0
			if side and side ~= 0 and far then keys = { left = side < 0, right = side > 0 } end
		elseif g:can_use(w) then
			local a, power = math.rad(mv.angolo or 0), mv.potenza or 1
			d.aimed = d.aimed + 1
			-- subito: no aiming shown (a move in the middle of a jump)
			if NO_AIM[w] or mv.subito or d.aimed > DEMO_AIM then
				d.shot = true
				keys = { fire = { weapon = w, angle = a, power = power } }
			else
				d.aim = { robot = d.who, weapon = w, angle = a, power = power }
			end
		end
	elseif mv.aspetta then
		finished = d.t >= mv.aspetta * 60
	elseif mv.dice then
		r.battute[#r.battute + 1] = { robot = d.who, testo = mv.dice }
		finished = true
	elseif mv.posa then
		d.pose = mv.posa
		finished = d.t >= (mv.secondi or DEMO_POSE) * 60
	else
		finished = true
	end
	if finished then
		d.k, d.t, d.shot, d.aimed, d.still, d.up, d.aim, d.pose = d.k + 1, 0, nil, 0, 0, nil, nil, nil
	end
	return keys
end

-- Starts the demonstration whose moment has come, when you're still on your
-- turn; ends the running one when her moves are done and everything is still
local function demonstrations(r, g)
	local l, d = r.l, r.demo
	local f = l.maestra and g.robots[l.maestra]
	if not f then return end
	-- she doesn't get hurt
	if not f.dead then f.hp = f.max_hp end
	if d then
		-- her turn doesn't end and match time doesn't pass; her shots don't hurt you
		g.timer, g.window, g.match_left = math.max(g.timer, 120), 0, d.saved.match
		local me = g.robots[PLAYER]
		if not me.dead and me.hp < d.saved.hp then me.hp = d.saved.hp end
		local moves = l.dimostra[d.i].mosse
		if d.k > #moves then
			d.still = settled(g, f) and d.still + 1 or 0
			if d.still >= DEMO_STILL or d.t > DEMO_LIMIT then
				local s = d.saved
				g.current, g.timer, g.window, g.used = PLAYER, s.timer, s.window, s.used
				r.demo = nil
				g:emit({ type = "demo_end", robot = PLAYER })
			else
				d.t = d.t + 1
			end
		end
		return
	end
	-- (without someone pressing her keys, as in the bot trial, she shows nothing)
	if not r.can_demo or r.esito or g.current ~= PLAYER or g.phase ~= "aim" or not settled(g, g.robots[PLAYER]) then return end
	for i in ipairs(l.dimostra or {}) do
		if r.ready[i] and not r.shown[i] then
			r.shown[i] = true
			local u = g.used
			r.demo = { i = i, k = 1, t = 0, who = f.id, aimed = 0, still = 0, saved = { timer = g.timer, hp = g.robots[PLAYER].hp,
				window = g.window, match = g.match_left, used = { primary = u.primary, secondary = u.secondary, tool = u.tool } } }
			g.current, g.window = f.id, 0
			g.used = { primary = false, secondary = false, tool = false }
			g:emit({ type = "demo", robot = f.id })
			return
		end
	end
end

-- Favilla aiming in a demonstration, or nil
function M.mira(r)
	return r and r.demo and r.demo.aim or nil
end

-- Favilla striking a pose: her robot and the clip, or nil
function M.posa(r)
	local d = r and r.demo
	if d and d.pose then return d.who, d.pose end
end

-- What Favilla says now (once): her robot and the text, or nil
function M.battuta(r)
	local b = r and table.remove(r.battute, 1)
	if b then return b.robot, b.testo end
end

-- Is Favilla showing a move?
function M.dimostra(r)
	return r ~= nil and r.demo ~= nil
end

function M.tick(r, g)
	local l, st = r.l, r.st
	if l.without_time and g.current == PLAYER then without_time(r, g) end
	local _, p = next_one(l, st)
	-- only what the step says can be used (lesson over: everything)
	g.permitted = not r.esito and p and p.permitted or nil
	if l.riprova and g.current == PLAYER then
		attempt_over(r, g)
		if p and not l.without_time and not r.esito then hold_clock(r, g, p) end
		hold_still(r, g, p)
	end
	-- the targets that stay down vanish when they would respawn
	for i, rb in ipairs(g.robots) do
		if r.giu[i] and rb.dead and rb.respawn_in and rb.respawn_in <= 1 then
			r.giu[i] = nil
			local in_order_now = false
			for _, o in ipairs(g.order) do in_order_now = in_order_now or o == i end
			if in_order_now then
				g:remove(i)
			else
				-- still targets have no turns: they just vanish
				rb.gone, rb.respawn_in = true, nil
				g:emit({ type = "gone", robot = i })
			end
		end
	end
	-- the cards of weapons that arrive without a crate: when the hit that did the
	-- step has landed, and a moment later
	local flying = g.projectile or g.burst or g:shards_flying() or #g.orbs > 0
	for i, c in ipairs(l.cards or {}) do
		if not r.opened[i] and (c.dopo == 0 or st.steps_done[c.dopo]) then
			-- (if nothing is flying, at once)
			r.waits[i] = flying and 0 or (r.waits[i] or CARD_DELAY - 1) + 1
		end
		if not r.opened[i] and (r.waits[i] or 0) >= CARD_DELAY then
			r.opened[i] = true
			if c.give then
				game.give(g.robots[PLAYER], c.arma)
				r.prese[c.arma] = true
			end
			r.cards[#r.cards + 1] = c.arma
		end
	end
	-- the mission's crates drop, once their step is done
	for i, c in ipairs(l.casse or {}) do
		if not r.cadute[i] and (c.dopo == 0 or st.steps_done[c.dopo]) then
			r.cadute[i] = g:spawn_crate(c.arma, c.x) or true
			-- it starts a little above the terrain: you wait a couple of seconds, not ten
			local cr, gy = r.cadute[i], g.terrain:ground_below(c.x, game.WORLD_H - 1)
			if cr ~= true and gy then cr.y = math.min(cr.y, gy + CRATE_ABOVE) end
		end
	end
	-- lessons: a limited-shot weapon found in a crate comes back as soon as you can
	-- attack again, retry as often as needed (in the circles the crate is one shot only)
	local rb = g.robots[PLAYER]
	for _, c in ipairs(l.riprova and l.casse or {}) do
		local n = rb.ammo[c.arma]
		local used_up = game.SECONDARY[c.arma] and g.used.secondary or g.used.primary
		if n == 0 and r.prese[c.arma] and not used_up then rb.ammo[c.arma] = 1 end
	end
	-- lessons: until you touch the controls the turn and match time are stopped
	if r.attesa and g.current == PLAYER then
		r.fermo = r.fermo or { timer = g.timer, window = g.window, match = g.match_left }
		local f = r.fermo
		g.timer, g.window, g.match_left = f.timer, f.window, f.match
	end
	-- Favilla's path runs from its step on; the spark is taken passing over it
	local gd = l.guida
	if gd and (r.guida_t or gd.parte == 0 or st.steps_done[gd.parte]) then r.guida_t = (r.guida_t or 0) + 1 end
	local sp = l.scintilla
	if sp and not r.scintilla_presa then
		local me = g.robots[PLAYER]
		-- the body's hit circle from the last tick to this one, so a fast jump can't skip it
		local cx, cy = me.x, me.y + game.HURT_Y
		local px, py = r.spark_prev_x or cx, r.spark_prev_y or cy
		r.spark_prev_x, r.spark_prev_y = cx, cy
		local dx, dy = cx - px, cy - py
		local t = 0
		local len2 = dx * dx + dy * dy
		if len2 > 0 then t = math.max(0, math.min(1, ((sp.x - px) * dx + (sp.y - py) * dy) / len2)) end
		local qx, qy = px + dx * t - sp.x, py + dy * t - sp.y
		local reach = game.HURT_R + SPARK_R
		if not me.dead and qx * qx + qy * qy <= reach * reach then
			r.scintilla_presa = true
			count(st, "scintille")
			g:emit({ type = "spark", robot = PLAYER })
		end
	end
	check_event(r, g, nil)
	demonstrations(r, g)
	-- Favilla uses what she shows, not only what the step allows
	if r.demo then g.permitted = nil end
	-- on the ground or not before the events of the next tick (the Tonante lifts you off the ground)
	st.on_ground = g.robots[PLAYER].grounded
	if r.line_ticks and not r.attesa then
		r.line_ticks = r.line_ticks - 1
		if r.line_ticks <= 0 then clear_line(r) end
	end
	return r.esito
end

-- The weapon card to open (mission cards), once
function M.scheda(r)
	return r and table.remove(r.cards, 1)
end

-- The camera level the step to do wants (zoom), once per step
function M.zoom(r)
	if not r then return nil end
	local i, p = next_one(r.l, r.st)
	if p and p.zoom and r.zoomed ~= i then
		r.zoomed = i
		return p.zoom
	end
end

-- The line to show and above whom (the robot), or nil
-- The line in view (battle/vignette.lua): testo, apertura (the goal_text),
-- highlight, faccia (the face of who says it)
function M.line(r)
	return r.riga and r.line or nil
end

-- The goal always in view: the missing step, with a number if more than one
function M.obiettivo(r)
	local l = r.l
	local i, p = next_one(l, r.st)
	if not i or r.esito then return nil end
	local n = #l.obiettivo
	return n > 1 and (i .. "/" .. n .. "  " .. p.testo) or p.testo
end

-- Favilla on her path (l.guida), at tick r.guida_t: where she is and how she
-- moves, for the drawing. Before her step, at the first point; at the end, still
local GUIDE_STATE = {}
function M.guida(r)
	local gd = r and r.l.guida
	if not gd then return nil end
	local pts, s, f = gd.percorso, (r.guida_t or 0) / 60, GUIDE_STATE
	local a, b = pts[1], pts[1]
	for i = 2, #pts do
		if s < pts[i].t then a, b = pts[i - 1], pts[i] break end
		a, b = pts[i], pts[i]
	end
	if a == b then
		f.x, f.y, f.vx, f.vy, f.grounded = a.x, a.y, 0, 0, true
		f.facing = f.facing or 1
		return f
	end
	local d = b.t - a.t
	local u = (s - a.t) / d
	local h = b.salto or 0
	f.x = a.x + (b.x - a.x) * u
	f.y = a.y + (b.y - a.y) * u + 4 * h * u * (1 - u)
	f.vx = (b.x - a.x) / d
	f.vy = (b.y - a.y) / d + 4 * h * (1 - 2 * u) / d
	f.grounded = h == 0
	if f.vx ~= 0 then f.facing = f.vx < 0 and -1 or 1 else f.facing = f.facing or 1 end
	return f
end

-- The spark still to take (l.scintilla), or nil
function M.scintilla(r)
	local sp = r and r.l.scintilla
	if sp and not r.scintilla_presa and not r.esito then return sp.x, sp.y end
end

local function lead_text(n)
	return "CON " .. n .. " PUNTI DI VANTAGGIO"
end

-- What each star needs
function M.criteria(l)
	if l.medaglia then return { "FATTA", l.medaglia.testo } end
	local s = l.stelle
	if not s then return { "FATTA" } end
	if s.bonus2 then return { "FATTA", s.bonus.testo, s.bonus2.testo } end
	return { "FATTA", lead_text(s.punti), s.bonus.testo }
end

-- The point lead at the end of the mission (nil where there are no points)
function M.vantaggio(r)
	local l = r.l
	if l.stelle and l.stelle.punti then return math.floor((r.st.gap or 0) + 0.5) end
end

local function bonus(b, st)
	local n = st.conta[b.conta] or 0
	if b.at_most then return n <= b.at_most end
	return n >= b.at_least
end

-- Stars: one for completing it, then the point lead and the bonus (or two
-- bonuses). Each counts on its own: you can have the third without the second.
-- The cortile: «Fatta» and the medal (or nothing more).
function M.stelle(r)
	if r.esito ~= "fatta" then return { false, false, false } end
	local l, st = r.l, r.st
	local d = st.gap or 0
	if l.medaglia then return { true, bonus(l.medaglia, st), false } end
	local s = l.stelle
	if not s then return { true, false, false } end
	if s.bonus2 then return { true, bonus(s.bonus, st), bonus(s.bonus2, st) } end
	return { true, d >= s.punti, bonus(s.bonus, st) }
end

function M.quante(stars)
	local n = 0
	for i = 1, 3 do
		if stars[i] then n = n + 1 end
	end
	return n
end

return M
