-- Missions: the lessons (Chapter 0) and the campaign circles (sim/campaign.lua),
-- all in the same format. A mission is a real match with a goal written as
-- data: a few verbs (below) instead of code, so one day the server can send
-- them and they also serve the daily puzzle (docs/roadmap.md, area 3). Pure
-- Lua: the gui_script shows the line, the goal and the stars.
--
--   local r = missions.nuova("attrezzi")
--   local seed, map, opts = missions.partita(r, seed, picks, help)  -- for game.new (or replay.nuova);
--                                                   help: after many losses, softer opponents
--   missions.prepara(r, g)                          -- right after, once
--   missions.evento(r, g, e, bots)                  -- for every simulation event (bots: from replay.partita)
--   local outcome = missions.tick(r, g)             -- every tick: nil, "fatta" or "fallita"
--   missions.tocca(r, what)                         -- the player touched the controls (lessons: time starts; r nil: nothing);
--                                                   what: the chosen weapon, "salta", "mira", "annulla" or nil
--   local what = missions.evidenzia(r)              -- the control to highlight (or nil)
--   missions.vede(r, weapon)                        -- is that weapon (or "teleport", "parachute", "tempo",
--                                                   "punti") shown in the HUD? (r nil: everything)
--   local x, y = missions.bandiera(r)               -- where the chequered flag is (or nil)
--   local i = missions.bersaglio(r)                 -- in the lessons, the robot to hit now (or nil)
--   local w = missions.scheda(r)                    -- the weapon card to open now (once), or nil
--   local z = missions.zoom(r)                      -- the camera level the step wants (once), or nil
--   local text, who = missions.riga(r)              -- the hint to show above robot who (or nil)
--   local text = missions.obiettivo(r)              -- the remaining goal, always in view (or nil)
--   missions.stelle(r)                              -- { true, false, true }: each star with its criterion
--   missions.quante(stars)                          -- how many are lit
--   missions.criteri(l)                             -- what each star needs: { "FATTA", "CON 60 PUNTI DI VANTAGGIO", ... }
--   missions.dopo(id)                               -- the next mission in the chapter (nil after the last)
--
-- A mission (fields, all data except where stated):
--   id, titolo, goal_text (the first line, until the first thing is done), evidenzia
--     (the control the goal_text highlights, as in the lines below)
--   mappa (a game map) or arena = { { x, y, w, h }, ... } (steel rectangles:
--     craters don't break the puzzle) and spawns (the player first)
--   giocatori: opts.players of game.new (team, bot = level, carattere, dummy, pick,
--     secondary, tool, stats); nome: what that robot is called (the keepers);
--     battute: who speaks for it (battaglia/battute.lua; without, its carattere)
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
--     game: battaglia/scheda.lua). In the lessons a limited-shot weapon found
--     there comes back when it can be used again
--   cards = { { dopo = 1, arma = "sword", give = true } }: once step dopo is done
--     that weapon's card opens; give: and you get it, without a crate (Sergio,
--     30 Oct: the Rampino and the parachute aren't found in crates)
--   senza_tempo: no timer and no turns, the turn is yours until you finish.
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
--   the mission fails if the match ends first
--   turni: past this many player turns it starts over
--   stelle = { punti = 60, bonus = { conta = "morti", at_most = 0, testo = "SENZA MORIRE" } }
--     (the second with at least that point lead over the opponents at the end:
--     the circles, where points count; Sergio, 31 Oct: no longer turns) or
--     { bonus = { ... }, bonus2 = { ... } } (two bonuses: the lessons)
--   collaudo = { carattere, piano, senza }: how strumenti/arena/collaudo.lua tests it
--   righe = { { testo, quando, fino, su = "bot", evidenzia, stops, subito } }: quando
--     and fino are { evento = "crate_pick" }, { passo = 2 } (step 2 done),
--     { turno = 2 }, { tocca = "mira" } (the player touched that, this turn) or
--     functions(st, g, e) for cases the data can't express (the guided match).
--     evidenzia: the control the line suggests ("primaria", "secondaria", a
--     weapon, "teleport", "cammina", "salta", "mira", "annulla"): the HUD
--     highlights it and, in the lessons, time stays stopped until you touch it
--     (stops = false: only the highlight, for lines that come while airborne).
--     In the circles the highlight is there but the game never stops. subito:
--     the line replaces the current one (aiming has already started)
--
-- The goal steps (testo: how it reads in the goal line). In addition, in the
-- lessons: only = { "sword", "teleport", "baratto", "primaria", ... }: until
-- the step is done only that can be used; zoom = 2: the camera widens to that
-- level (battaglia/camera.lua); globi = 2 (with usa = "globi"): time stops
-- where those orbs can still be earned
--   { usa = "globi" | "rampino" | "pogo" | "kickback" | "paracadute" | "baratto" }
--   { reach = { x = 1200, y = 150 }, bandiera = true }   standing above that
--                                           height, past that x (bandiera: the chequered flag is there)
--   { prendi = "missile" }                  pick up the crate with that weapon
--   { hit = 2, con = "sword" | "primaria" | "secondaria" | a weapon }
--   { down = 2 | "nemico", come = "vuoto", con = weapon, times = 3 }
--   { win = true }                          the match ends and your team won
-- Other verbs (survive, protect...) come with the missions that use them.
-- The counters for star bonuses: morti, teletrasporti, vuoto (your
-- environmental kills), abbattuti, danni (taken by you), misses (senza_tempo),
-- globi (earned).

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
-- senza_tempo: an attack is over when nothing is flying and the player has been still for many ticks
local MISS_TICK = 45
-- a weapon card opens this many ticks after the hit of the step has landed
local CARD_DELAY = 24
-- how high above the terrain mission crates drop from
local CRATE_ABOVE = 280
-- the third star of the Prima partita: won with at least this point lead
local GUIDED_POINTS = 100
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
-- (p.permesso). Walking and jumping are always allowed
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
for _, cap in ipairs(campaign.CAPITOLI) do
	for i, l in ipairs(cap.missioni) do
		assert(not PER_ID[l.id], "missione doppia: " .. l.id)
		PER_ID[l.id] = l
		l.capitolo = cap.id
		-- in the lessons time waits for you to touch the controls (capitolo.aspetta)
		l.aspetta = cap.aspetta
		-- the nearly forced next action: the lessons, not the Prima partita
		l.riprova = l.aspetta and not l.guidata
		if type(l.obiettivo) == "table" then
			for _, p in ipairs(l.obiettivo) do
				if p.only then p.permesso = allowed_fn(p.only) end
			end
		end
		NEXT_ID[l.id] = cap.missioni[i + 1] and cap.missioni[i + 1].id
		if l.arena then
			l.mappa = "missione_" .. l.id
			maps.registra(l.mappa, { name = l.titolo, spawns = l.spawns, build = function(t)
				for _, q in ipairs(l.arena) do t:rect(q[1], q[2], q[3], q[4], STEEL) end
			end })
		end
	end
end

function M.trova(id)
	return PER_ID[id]
end

function M.dopo(id)
	return NEXT_ID[id]
end

-- What the mission shows in the HUD (l.vedi; without it, everything)
local function category(w)
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
	return { l = l, st = { turni = 0, bot_turns = 0, steps_done = {}, times = {}, conta = {}, touched_cmds = {} },
		viste = {}, prese = {}, cadute = {}, opened = {}, waits = {}, cards = {}, giu = {}, riga = nil, esito = nil }
end

-- seed, map and options of game.new. picks: the players out of the draft
-- (menu/scelta.lua), for the missions that have one
-- the silent help: bots go down two grades (sim/bot.lua M.GRADI) and start with less life
local HELP_HP = 0.75

function M.partita(r, seed, picks, aiuto)
	local l = r.l
	local players = {}
	r.aiuto = aiuto
	for i, p in ipairs(l.giocatori) do
		local q = {}
		for k, v in pairs(p) do
			if k ~= "nome" and k ~= "battute" then q[k] = v end
		end
		if aiuto and q.bot then q.bot = math.max(1, q.bot - 2) end
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
function M.prepara(r, g)
	local l, st = r.l, r.st
	if l.secondi then g.match_left = l.secondi * 60 end
	-- the mission's life is also the full one: regrow goes back there, not to 150
	for i, v in pairs(l.vita or {}) do
		g.robots[i].hp, g.robots[i].max_hp = v, v
	end
	if r.aiuto then
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
	if g.current == PLAYER then st.turni = 1 else st.bot_turns = 1 end
	r.coda = {}
	r.riga = nil
	if l.aspetta then r.attesa, r.fermo = true, { timer = g.timer, window = g.window, match = g.match_left } end
	if l.senza_tempo then r.senza = { timer = g.timer, match = g.match_left } end
	-- the goal_text until the first thing is done
	-- (in the lessons it gives way to the hints as soon as you touch the controls)
	if l.goal_text then
		r.coda[1] = { testo = l.goal_text, yields = l.aspetta, evidenzia = l.evidenzia,
			fino = function(_, g2) return g2.used.primary or g2.used.secondary or g2.used.tool end }
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
			and weapon_ok(p.con, st.arma)
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

-- The quando of a line: a function, or data
local function when(q, st, g, e)
	if type(q) == "function" then return q(st, g, e) end
	if q.evento then
		return e ~= nil and e.type == q.evento and (e.robot == nil or e.robot == PLAYER)
	elseif q.passo then
		return st.steps_done[q.passo] == true
	elseif q.turno then
		return st.turni == q.turno
	elseif q.tocca then
		return touched_cmd(st, q.tocca)
	end
	return false
end

-- One line at a time: the new one waits until the other is done or expired
-- (or another turn starts).
-- Without "fino" it stays LINE_SECONDS, with "fino" at most twice that.
-- A line highlighting a control, in the lessons, stops time until you touch it
-- (if you haven't already touched it this turn).
local function show_line(r, line)
	r.riga, r.line_until, r.line_yields = line.testo, line.fino, line.yields
	r.line_on = line.su == "bot" and 2 or PLAYER
	r.riga_t = (line.fino and 2 or 1) * LINE_SECONDS * 60
	r.luce = line.evidenzia
	r.attende = nil
	local e = line.evidenzia
	if e and r.l.aspetta and line.stops ~= false and not touched_cmd(r.st, e) then
		r.attesa, r.attende = true, e
	end
end

-- The line goes away: if it was waiting for a control, time restarts
local function clear_line(r)
	if r.attende then r.attesa, r.attende, r.fermo = false, nil, nil end
	r.riga, r.riga_t, r.luce, r.line_yields = nil, nil, nil, nil
end

-- e = nil: the check every tick
local function check_event(r, g, e)
	local l, st = r.l, r.st
	if r.esito then return end
	if goal(l, st, g, e) then
		r.esito = "fatta"
		-- the hints aren't needed anymore (there's "Fatta!")
		clear_line(r)
		return
	end
	if r.riga and r.line_until and when(r.line_until, st, g, e) then clear_line(r) end
	-- a new turn: the previous turn's lines aren't needed anymore
	if e and e.type == "turn" then clear_line(r); r.coda = {} end
	for i, line in ipairs(l.righe or {}) do
		if not r.viste[i] and when(line.quando, st, g, e) then
			r.viste[i] = true
			if line.subito then
				clear_line(r)
				table.insert(r.coda, 1, line)
			else
				r.coda[#r.coda + 1] = line
			end
		end
	end
	-- the goal_text of a lesson, once read (you touched the controls), gives way
	if r.riga and r.line_yields and not r.attesa and #r.coda > 0 then clear_line(r) end
	if not r.riga and #r.coda > 0 then show_line(r, table.remove(r.coda, 1)) end
end

local function count(st, k)
	st.conta[k] = (st.conta[k] or 0) + 1
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
		local who_hit = not st.steps_done[i] and (p.hit or p.down)
		if who_hit == robot then return true end
		if who_hit == "nemico" then
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
	elseif e.type == "respawn" and l.riprova and e.robot == PLAYER and r.saved then
		-- in the lessons the player respawns as they were at the last step done, orbs included
		restore_snapshot(r, g)
	elseif e.type == "respawn" and l.riprova and l.spawns and l.spawns[e.robot] then
		-- in the lessons you respawn where you started, not at a random spot of the
		-- arena (a random target would end up in the way)
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
		st.finished, st.vinta = true, e.winner == g.robots[PLAYER].team
	end
	if e.type == "points" or e.type == "over" then st.distacco = lead(g) end
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
		local testo = l.goal_text
		local i, p = next_one(l, st)
		if i and i > 1 then testo = p.testo end
		-- (if the turn doesn't already have its own line to say)
		if testo and not r.riga then show_line(r, { testo = testo, yields = true }) end
	end
	if e.type == "over" and not l.guidata then
		r.esito = "fallita"
	end
end

-- The player touched the controls (what: the chosen weapon, "salta", "mira",
-- "annulla" or nil): time restarts, but if the line waits for one control only
-- when you touch that one
function M.tocca(r, what)
	if not r then return end
	if what then r.st.touched_cmds[what] = true end
	if r.attende then
		if not matches_hint(r.attende, what) then return end
		-- done: the highlight goes off, the line stays as long as needed
		r.attende, r.luce = nil, nil
	end
	r.attesa, r.fermo = false, nil
end

-- The control to highlight, while its line is in view
function M.evidenzia(r)
	return r.riga and r.luce or nil
end

-- senza_tempo: time doesn't pass and the turn doesn't end
local function senza_tempo(r, g)
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
	if r.l.senza_tempo then
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
		show_line(r, { testo = RETRY_TEXT })
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
	local without = p and p.permesso and p.permesso("teleport") and not g:can_use("teleport")
	if without then
		for w in pairs(game.WEAPONS) do
			if not (w == "teleport" or w == "swap" or game.TOOLS[w]) and p.permesso(w) then without = false end
		end
	end
	r.stuck_ticks = without and (r.stuck_ticks or 0) + 1 or 0
	if r.stuck_ticks >= MISS_TICK then
		r.stuck_ticks = 0
		restore_snapshot(r, g)
		count(r.st, "misses")
		clear_line(r)
		show_line(r, { testo = RETRY_TEXT })
	end
end

-- Can step p be done now? (one of the controls it names can be used; to hit,
-- an attack: with only the orb the turn goes on)
local function allowed(g, p)
	if not p.permesso then return false end
	local hit_def = p.hit or p.down
	for w in pairs(game.WEAPONS) do
		local attack = not (w == "teleport" or w == "swap" or game.TOOLS[w])
		if p.permesso(w) and (attack or not hit_def) and g:can_use(w) then return true end
	end
	return false
end

-- Lessons with time: as long as the step to do can be done (or a shot is in
-- flight) time doesn't go below one second; for orbs, not past those
local function hold_clock(r, g, p)
	if not (r.shot or allowed(g, p)) then return end
	local minimum = 60
	if p.usa == "globi" and p.globi then
		local thresholds = {}
		for i, v in ipairs(config.TELEPORT_SOGLIE) do thresholds[i] = v end
		table.sort(thresholds)
		-- (two ticks of margin: the shot leaves the next tick)
		minimum = game.TURN_TICKS - thresholds[#thresholds - p.globi + 1] * 60 + 2
	end
	if g.timer < minimum then g.timer = minimum end
	if g.window > 0 and g.window < 60 then g.window = 60 end
end

-- The robot to hit or down in the step to do (the marker above it), or nil
function M.bersaglio(r)
	if not r or r.esito or not r.l.riprova then return nil end
	local _, p = next_one(r.l, r.st)
	return p and (p.hit or p.down) or nil
end

-- The chequered flag of the step to do (reach with bandiera), or nil
function M.bandiera(r)
	local _, p = next_one(r.l, r.st)
	if p and p.reach and p.bandiera then return p.reach.x, p.reach.y end
end

function M.tick(r, g)
	local l, st = r.l, r.st
	if l.senza_tempo and g.current == PLAYER then senza_tempo(r, g) end
	local _, p = next_one(l, st)
	-- only what the step says can be used (lesson over: everything)
	g.permesso = not r.esito and p and p.permesso or nil
	if l.riprova and g.current == PLAYER then
		attempt_over(r, g)
		if p and not l.senza_tempo and not r.esito then hold_clock(r, g, p) end
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
	check_event(r, g, nil)
	-- on the ground or not before the events of the next tick (the Tonante lifts you off the ground)
	st.on_ground = g.robots[PLAYER].grounded
	if r.riga_t and not r.attesa then
		r.riga_t = r.riga_t - 1
		if r.riga_t <= 0 then clear_line(r) end
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
function M.riga(r)
	return r.riga, r.line_on
end

-- The goal always in view: the missing step, with a number if more than one
function M.obiettivo(r)
	local l = r.l
	local i, p = next_one(l, r.st)
	if not i or r.esito then return nil end
	local n = #l.obiettivo
	return n > 1 and (i .. "/" .. n .. "  " .. p.testo) or p.testo
end

local function lead_text(n)
	return "CON " .. n .. " PUNTI DI VANTAGGIO"
end

-- What each star needs
function M.criteri(l)
	if l.guidata then return { "FINITA", "VINTA", lead_text(GUIDED_POINTS) } end
	local s = l.stelle
	if s.bonus2 then return { "FATTA", s.bonus.testo, s.bonus2.testo } end
	return { "FATTA", lead_text(s.punti), s.bonus.testo }
end

-- The point lead at the end of the mission (nil where there are no points)
function M.vantaggio(r)
	local l = r.l
	if l.guidata or (l.stelle and l.stelle.punti) then return math.floor((r.st.distacco or 0) + 0.5) end
end

local function bonus(b, st)
	local n = st.conta[b.conta] or 0
	if b.at_most then return n <= b.at_most end
	return n >= b.at_least
end

-- Stars: one for completing it, then the point lead and the bonus (or two
-- bonuses). Each counts on its own: you can have the third without the second.
-- In the guided match: finished, won, won with a 100 point lead.
function M.stelle(r)
	if r.esito ~= "fatta" then return { false, false, false } end
	local l, st = r.l, r.st
	local d = st.distacco or 0
	if l.guidata then
		return { true, st.vinta == true, st.vinta == true and d >= GUIDED_POINTS }
	end
	local s = l.stelle
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
