-- Collante tra il server Go e la simulazione: passa gli input al gioco e
-- prepara stato ed eventi come tabelle Lua semplici. Il JSON lo scrive il
-- server in Go (server/luajson.go), molto più in fretta di string.format qui.
local game = require "sim.game"
local maps = require "sim.maps"
local config = require "sim.config"
local draft = require "sim.draft"

local N = {}

-- Le mappe fisse si disegnano una volta sola per processo: le partite dopo
-- copiano le celle già pronte (server/terreno.go), invece di ridisegnarle
-- (più di 100 ms in gopher-lua).
for id, def in pairs(maps.maps) do
	if not def.seeded then
		local build = def.build
		def.build = function(t, seed)
			if not terrain_restore(t, id) then
				build(t, seed)
				terrain_store(t, id)
			end
		end
	end
end

-- players: come opts.players di game.new (squadre e scelte del draft);
-- normalize: modalità Torneo
function N.new(seed, map, players, normalize)
	local g = game.new(seed, map, { players = players, normalize = normalize })
	g:pop_events()
	g.carves = {} -- scavi del terreno, per chi si riconnette
	return g
end

-- hold: il salto è ancora tenuto premuto (lasciandolo mentre si sale il salto è corto)
function N.step(g, left, right, jump, hold, angle, power, weapon)
	local fire = nil
	if angle then fire = { angle = angle, power = power, weapon = game.WEAPONS[weapon] and weapon or "missile" } end
	g:step({ left = left, right = right, jump = jump, hold = hold, fire = fire })
end

function N.current(g)
	return g.current
end

-- il giocatore i è uscito dalla partita (room.go, leave): il suo robot sparisce
function N.remove(g, i)
	g:remove(i)
end

function N.over(g)
	return g.phase == "over"
end

function N.snapshot(g)
	local robots = {}
	for i, rb in ipairs(g.robots) do
		-- s: tick del fendente in corso (0 se il robot non sta colpendo), sd: sua direzione
		-- pu, pd: lo stesso per il Pugno del Titano; ag, as, ap, ac: colpi di Uovo, Schegge, Pugno e Cecchino
		-- sb, pb: angolo di mira del fendente e del pugno (servono col modello "blastron")
		-- tl: teletrasporti in mano, mh: vita massima, tu: turni giocati, pt: punti
		-- ak, ad, am: trappole, scudi e trampolini; sh: scudo rimasto; pa: paracadute aperto;
		-- pl: paracadute rimasti; st: turni rimasti degli effetti (bruciatura + 10 x rallentamento + 100 x armatura incrinata)
		-- sw: la secondaria scelta all'inizio (oltre alla Lama, "" se nessuna);
		-- lu: tick rimasti dell'Affondo, la: angolo del suo scatto;
		-- kn: sbalzato da un colpo (non corre da sé);
		-- hk: chi lo sta tirando col Rampino (0 nessuno, -1 se è appeso al terreno in hx, hy);
		-- gs: il suo uncino del Rampino è in volo, in gx, gy; ml: tick del colpo di Maglio,
		-- ms: tick (con frazione) in cui la sua testa si è fermata sul terreno (0 se gira ancora), md: suo lato;
		-- gn: è uscito dalla partita (sparito, non torna)
		robots[i] = { x = rb.x, y = rb.y, hp = math.floor(rb.hp), f = rb.facing, d = rb.dead, g = rb.grounded,
			tl = rb.teleports_left, mh = rb.max_hp, tu = rb.turns, pt = math.floor(rb.points + 0.5),
			ak = rb.ammo.trap, ad = rb.ammo.shield, am = rb.ammo.trampoline, sh = rb.shield or 0, pl = rb.parachutes_left,
			pa = rb.parachute,
			st = (rb.status.burn and rb.status.burn.turns or 0) + 10 * (rb.status.slow and rb.status.slow.turns or 0)
				+ 100 * (rb.status.cracked and rb.status.cracked.turns or 0),
			s = rb.swing or 0, sd = rb.swing_dir or 0, pu = rb.punch or 0, pd = rb.punch_dir or 0,
			sb = rb.swing_base or 0, pb = rb.punch_base or 0,
			ag = rb.ammo.grenade, as = rb.ammo.shards, ap = rb.ammo.punch, ac = rb.ammo.sniper,
			sw = rb.secondary or "", lu = rb.lunge or 0, hk = rb.hooked and (rb.hooked.by or -1) or 0,
			hx = rb.hooked and rb.hooked.x or 0, hy = rb.hooked and rb.hooked.y or 0, ml = rb.mallet or 0,
			gs = rb.hook_shot ~= nil, gx = rb.hook_shot and rb.hook_shot.x or 0, gy = rb.hook_shot and rb.hook_shot.y or 0,
			ms = rb.mallet_stop or 0, md = rb.mallet_dir or 0, mb = rb.mallet_base or 0, kn = rb.knocked,
			la = rb.lunge_vx and math.atan2(rb.lunge_vy, rb.lunge_vx) or 0, gn = rb.gone or false }
	end
	-- k: "missile", "grenade" o "sniper", fu: tick prima che l'Uovo scoppi
	local p = g.projectile and { x = g.projectile.x, y = g.projectile.y, k = g.projectile.kind, fu = g.projectile.fuse or 0 }
	-- o: i globi del teletrasporto in volo (i = numero del globo, per seguirlo tra uno stato e l'altro)
	local orbs = {}
	for i, ob in ipairs(g.orbs) do orbs[i] = { i = ob.id, x = ob.x, y = ob.y } end
	-- schegge in volo col loro posto nella raffica, casse (l'arma dentro resta segreta)
	local shards, crates = {}, {}
	for i = 1, game.SHARD_COUNT do
		local sh = g.shards[i]
		if sh then shards[#shards + 1] = { i = i, x = sh.x, y = sh.y } end
	end
	for _, c in ipairs(g.crates) do
		crates[#crates + 1] = { i = c.id, x = c.x, y = c.y, l = c.landed }
	end
	-- pl: trappole e trampolini (k: tipo, a: armata, tm: squadra, r: mezza larghezza, v: in volo)
	local placed = {}
	for i, o in ipairs(g.placed) do
		placed[i] = { i = o.id, k = o.kind, x = o.x, y = o.y, a = o.armed, tm = o.team, r = o.r, v = o.flying or false }
	end
	-- hl: cerchi di cura
	local heals = {}
	for i, h in ipairs(g.heals) do heals[i] = { i = h.id, x = h.x, y = h.y } end
	-- win: tick rimasti dopo il primo attacco; u: attacchi fatti (1 primaria, 2 secondaria); tp: teletrasporti
	-- del turno; te: globi guadagnati nel turno; ot: supplementari (tempo scaduto, si finisce il giro)
	local used = (g.used.primary and 1 or 0) + (g.used.secondary and 2 or 0) + (g.used.tool and 4 or 0)
	return { t = "state", phase = g.phase, cur = g.current, timer = g.timer, win = g.window,
		u = used, tp = g.teleports, te = g.teleports_earned, mt = g.match_left, ot = g.overtime, r = robots, p = p, o = orbs, s = shards,
		c = crates, pl = placed, hl = heals }
end

-- Eventi dall'ultimo tick (una lista, vuota se non ne sono successi)
function N.events(g)
	local list = g:pop_events()
	for _, e in ipairs(list) do
		e.t = "ev"
		if e.type == "explosion" then g.carves[#g.carves + 1] = { e.x, e.y, e.r } end
	end
	return list
end

-- Gli scavi fatti finora (e i Bastioni posati o crollati, quelli con m): chi si
-- riconnette li rifà sul suo terreno, nello stesso ordine
function N.sync(g)
	return { t = "sync", x = g.carves }
end

-- Scelta d'inizio partita (sim/draft.lua), prima di N.new --------------------

function N.mode_players(mode)
	return config.MODES[mode]
end

function N.draft_seconds()
	return config.DRAFT_SECONDS
end

function N.draft_new(seed, mode)
	local players = {}
	for i, p in ipairs(config.MODES[mode]) do
		players[i] = { team = p.team }
	end
	return draft.new(seed, players)
end

function N.draft_pick(d, i, weapon)
	return draft.pick(d, i, weapon)
end

function N.draft_finish(d)
	return draft.finish(d)
end

-- I due ventagli (offer: primarie, offer2: secondarie) e le scelte del robot i
-- (p, p2, o ""): quelle degli altri non si mandano (Sergio, 30 ott)
function N.draft_state(d, i)
	return { t = "draft", offer = d.offer, offer2 = d.offer2, p = d.picks[i] or "", p2 = d.picks2[i] or "" }
end

-- I giocatori della partita per il messaggio start: squadra e scelte del draft,
-- così il client crea la sua copia della partita con le stesse armi
function N.start_players(players)
	local out = {}
	for i, p in ipairs(players) do
		out[i] = { team = p.team, pick = p.pick, secondary = p.secondary }
	end
	return out
end

return N
