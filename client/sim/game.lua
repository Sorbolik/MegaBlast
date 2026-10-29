-- Simulazione di una partita: robot, missile, turni.
-- Lua puro, nessuna API Defold: la stessa logica girerà anche sul server.
--
-- Uso:
--   local game = require "sim.game"
--   local g = game.new(seed, "forgia")   -- senza mappa la sceglie il seed
--   g:step({ left = bool, right = bool, jump = bool,
--            fire = { angle = rad, power = 0..1, weapon = "missile" | "sword" | "teleport"
--                                                     | "grenade" | "shards" | "punch" } })
--   g:can_use(weapon)   -- il robot di turno può usarla adesso?
-- Regole del turno (sim/config.lua): fino a un'arma e un colpo di spada per
-- turno, in ordine libero; dopo il primo attacco restano AFTER_ATTACK_SECONDS,
-- in cui si può fare il secondo e riposizionarsi. I secondi rimasti al primo
-- attacco diventano globi del teletrasporto (rb.teleports_left).
--   for _, e in ipairs(g:pop_events()) do ... end

local rng = require "sim.rng"
local terrain = require "sim.terrain"
local maps = require "sim.maps"
local mischia = require "sim.mischia"
local C = require "sim.config"
local CORPO = require "sim.corpo"

local M = {}
M.__index = M

-- Mondo: 640 x 360 celle (le maschere delle mappe). CELL 3 dal 26 ottobre, era 2:
-- la mappa era piccola per il diavoletto (ci si attraversava in fretta e nei
-- buchi in mezzo non passava). 3 e non un valore con la virgola, così le celle
-- restano intere e la mappa coincide pixel per pixel con le immagini 1920 x 1080.
M.CELL = 3
M.WORLD_W = 640 * M.CELL
M.WORLD_H = 360 * M.CELL
M.DT = 1 / 60
M.GRAVITY = 600

-- Robot (la posizione è il centro dei piedi)
M.ROBOT_HALF_W = 6
M.ROBOT_H = 16
-- l'altezza del diavoletto disegnato, dai piedi alla cima della testa: il
-- disegno non cambia se cambiano la capsula per camminare o il cerchio dei colpi
-- (sim/corpo.lua). Da qui partono anche i colpi (MUZZLE) e il rampino.
M.DISEGNO_H = 16
-- quante volte il corpo è più grande della misura su cui è fatto il resto del mondo
-- (proiettili, casse, armi in mano si disegnano su DISEGNO_H / CORPO)
M.CORPO = 1
M.MAX_CLIMB = 6          -- gradino massimo che il robot sale da solo
-- Forma del corpo contro il terreno: false = rettangolo; true = capsula, con
-- sopra e sotto un mezzo cerchio di raggio ROBOT_HALF_W. Il fondo rotondo tocca
-- i pendii vicino al centro invece che con lo spigolo, così non resta sospeso.
M.ROBOT_ROUND = false
-- I danni delle armi sono pensati per una vita di DAMAGE_BASE punti; la vita
-- vera dei robot è in sim/config.lua (STATS.max_hp)
M.DAMAGE_BASE = 100

-- Statistiche di movimento del robot (le altre sono in sim/config.lua, STATS).
-- L'equipaggiamento e l'albero di abilità le modificano.
M.DEFAULT_STATS = {
	walk_speed = 70,     -- pixel al secondo a terra
	jump_height = 56,    -- altezza massima del salto in pixel
	air_speed = 90,      -- velocità orizzontale massima in aria
}
-- Reattività in aria: l'accelerazione è air_speed^2 / AIR_REACTION, quindi
-- più un robot è veloce, più in fretta cambia direzione (meno inerzia).
M.AIR_REACTION = 8
-- "accel": in aria si accelera fino a air_speed (e non mentre si è sbalzati).
-- "instant" (Blastron): tenendo una direzione la velocità è subito air_speed,
-- senza direzione resta quella che era.
M.AIR_CONTROL = "accel"
-- Blastron: il robot di turno non va mai di lato più veloce della sua corsa,
-- nemmeno dopo un'esplosione
M.CLAMP_ACTIVE_VX = false
-- Danno da caduta: oltre FALL_SAFE pixel di caduta, FALL_DAMAGE per pixel in
-- più fino a FALL_DAMAGE_MAX. FALL_SAFE = false: niente danno.
M.FALL_SAFE = false
M.FALL_DAMAGE = 0
M.FALL_DAMAGE_MAX = 0

-- Missile
M.MISSILE_SPEED = 750    -- velocità alla potenza massima
M.MISSILE_GRAVITY = 1    -- quanta gravità sente, rispetto ai robot
M.EXPLOSION_R = 30       -- raggio del cratere
M.DAMAGE_R = 50          -- raggio entro cui si subisce danno
M.MAX_DAMAGE = 45
M.KNOCKBACK = 320
-- Come spinge un'esplosione:
-- "centro": dal centro del robot, forte quanto knockback (al centro) e un po' in alto.
-- "blastron": velocità = (punto più vicino della scatola - esplosione) * impulse * t,
-- con t = 1 - distanza / damage_r. Massima a metà raggio, nulla nel colpo diretto.
M.KNOCKBACK_MODEL = "centro"
M.SELF_DAMAGE = 1        -- quanto del danno subisce chi si colpisce da solo
-- per quanti tick dopo il lancio un proiettile non tocca chi l'ha lanciato
M.OWNER_SAFE_TICKS = 20

-- Lama di Nucleo: fendente di 240° che parte da dietro la schiena (205°),
-- passa sopra la testa e finisce davanti in basso (-35°). Colpisce dietro e davanti.
M.SWORD_REACH = 40       -- lunghezza della lama dal perno
M.MUZZLE = 14            -- i colpi partono a questa distanza dal centro del robot
M.SWORD_PIVOT_Y = 10     -- altezza del perno (la spalla) sopra i piedi
M.SWORD_FROM = math.rad(205)
M.SWORD_TO = math.rad(-35)
M.SWORD_TICKS = 20       -- durata del fendente (1/3 di secondo)
M.SWORD_DAMAGE = 35
-- Come si muove la lama:
-- "arco": l'arco fisso qui sopra, uguale qualunque sia la mira.
-- "blastron": il fendente di Blastron (sim/mischia.lua) ruotato sulla mira:
-- mirando in basso il colpo scende dall'alto verso il basso. I danni arrivano
-- quando si chiude la finestra del colpo, a tutti quelli toccati dalla lama.
M.SWORD_MODEL = "arco"
M.SWORD_STOP = false     -- il colpo ferma il bersaglio (in Blastron la spada gli azzera la velocità)

-- Dove un robot può essere colpito (proiettili, globi, lame, esplosioni):
-- "scatola": il rettangolo del robot, largo 2 * ROBOT_HALF_W e alto ROBOT_H;
-- "cerchio": come in Blastron, un cerchio di raggio HURT_R alto HURT_Y dai piedi.
-- Per le esplosioni Blastron misura dal quadrato attorno al cerchio, un po'
-- più largo (HURT_FAT).
M.HURTBOX = "scatola"
M.HURT_R = 8
M.HURT_Y = 8
M.HURT_FAT = 0

-- Teletrasporto (Passo d'Ombra): un globo che vola come il missile, rimbalza e
-- rotola sul terreno, e dopo
-- TELEPORT_TICKS sposta il robot dove si trova, senza toccare il suo stato:
-- velocità, fendente in corso e direzione restano quelli di prima.
M.TELEPORT_TICKS = 2 * 60
M.ORB_SPEED = M.MISSILE_SPEED
M.ORB_GRAVITY = 1
M.ORB_DAMPING = 0        -- frenata per secondo dopo il primo urto
M.MAX_ORBS = 6           -- globi in volo insieme, al massimo

-- Esplosioni: raggio del cratere, raggio del danno, danno massimo, spinta
M.MISSILE_BLAST = { r = M.EXPLOSION_R, damage_r = M.DAMAGE_R, damage = M.MAX_DAMAGE, knockback = M.KNOCKBACK }

-- Uovo di Fiamma (granata): rimbalza e scoppia dopo GRENADE_FUSE tick, con
-- un'esplosione più grande del missile
M.GRENADE_SPEED = 600    -- velocità alla potenza massima
M.GRENADE_FUSE = 3 * 60
M.GRENADE_BOUNCE = 0.45  -- quanta velocità resta dopo un rimbalzo
M.GRENADE_FRICTION = 0.7 -- attrito quando tocca terra
M.GRENADE_GRAVITY = 1
M.GRENADE_DAMPING = 0    -- frenata per secondo dopo il primo urto (come il linear damping di Box2D)
M.GRENADE_BLAST = { r = 40, damage_r = 64, damage = 55, knockback = 380 }

-- Sciame di Schegge (mitragliatrice): una raffica di schegge dritte e veloci,
-- ognuna con un'esplosione piccolissima
M.SHARD_COUNT = 8
M.SHARD_EVERY = 4        -- tick tra una scheggia e l'altra
M.SHARD_SPEED = 950      -- la potenza non conta: escono sempre alla stessa velocità
M.SHARD_GRAVITY = 0.2    -- la gravità le piega appena
M.SHARD_SPREAD = math.rad(3)
M.SHARD_BLAST = { r = 7, damage_r = 12, damage = 6.5, knockback = 90 }

-- Cecchino: velocità del colpo (la potenza non conta) e quanto vive al massimo;
-- danno, spinta, caduta e rimbalzi in config.SNIPER
M.SNIPER_SPEED = 480
M.SNIPER_LIFE = 6 * 60

-- Pugno del Titano: montante corpo a corpo che lancia in alto chi è davanti.
-- PUNCH_MODEL come SWORD_MODEL: "fisso" (qui sotto) o "blastron" (montante sulla mira).
M.PUNCH_MODEL = "fisso"
M.PUNCH_TICKS = 24       -- durata del colpo
M.PUNCH_HIT_TICK = 8     -- tick in cui il pugno arriva
M.PUNCH_REACH = 24       -- quanto arriva davanti al robot
M.PUNCH_DAMAGE = 30
M.PUNCH_LAUNCH = 480     -- velocità verso l'alto del bersaglio
M.PUNCH_PUSH = 140       -- e in avanti
M.PUNCH_HOP = 220        -- chi colpisce si alza un po' col montante

-- Armi, in due categorie (scelta di Sergio del 24 ottobre 2026). Ogni turno una
-- primaria e una secondaria, in ordine libero, mai due della stessa categoria.
-- Primarie: agiscono sul mondo e sugli altri (cratere, effetto di stato,
-- sbalzo). Il Lanciarune c'è sempre; le altre danno un colpo per cassa (rb.ammo).
-- Secondarie: danno secco, nessun effetto, illimitate; ognuna sposta chi la usa
-- a modo suo (la Lama gira attorno, il Tonante spinge indietro, il Maglio fa
-- rimbalzare in alto, l'Affondo passa oltre). La Lama c'è sempre; una delle
-- altre si sceglie all'inizio della partita (rb.secondary, sim/draft.lua).
M.SECONDARY = { sword = true, eagle = true, mallet = true, lunge = true }
M.DRAFT_SECONDARIES = { "eagle", "mallet", "lunge" }
-- armi che non consumano colpi
M.FREE_WEAPONS = { missile = true, teleport = true }
for w in pairs(M.SECONDARY) do M.FREE_WEAPONS[w] = true end
M.CRATE_WEAPONS = { "grenade", "shards", "punch", "sniper" }
-- Oggetti tattici delle casse (anche loro in rb.ammo), il paracadute (uno a
-- partita) e l'attrezzo (uno a turno: Rampino o Bastione, rb.tool, scelto
-- all'inizio della partita): non sono attacchi (config.lua)
M.ITEMS = { "trap", "shield", "trampoline" }
M.TOOLS = { trap = true, shield = true, trampoline = true, parachute = true, hook = true, wall = true }
M.DRAFT_TOOLS = { "hook", "wall" }
-- oggetti che si lanciano mirando (gli altri si usano col tocco)
M.THROWN = { trampoline = true, hook = true, wall = true }
-- tutti i nomi validi di fire.weapon
M.WEAPONS = { teleport = true }
for w in pairs(M.FREE_WEAPONS) do M.WEAPONS[w] = true end
for _, w in ipairs(M.CRATE_WEAPONS) do M.WEAPONS[w] = true end
for w in pairs(M.TOOLS) do M.WEAPONS[w] = true end

-- Casse: ogni CRATE_EVERY turni ne cade una dal cielo in un punto a caso.
-- Chi la tocca trova un colpo di un'arma o un oggetto (config.CRATE_CONTENTS).
-- Sergio (24 ottobre 2026): provata una ogni 2 turni, è tornato a questa.
M.CRATE_EVERY = 3
M.CRATE_MAX = 3          -- casse in mappa al massimo
M.CRATE_HALF_W = 10
M.CRATE_H = 18
M.CRATE_FALL = 110       -- velocità massima di caduta (scende piano, col paracadute)
-- Blastron: a ogni turno una probabilità, secondo quante casse ci sono già
-- ({ con 0, con 1, con 2, ... }). false: una cassa ogni CRATE_EVERY turni.
M.CRATE_CHANCE = false

-- Turni: le durate sono in sim/config.lua, qui in tick
M.MATCH_TICKS = C.MATCH_SECONDS * 60
M.TURN_TICKS = C.TURN_SECONDS * 60
M.AFTER_ATTACK_TICKS = C.AFTER_ATTACK_SECONDS * 60
M.RESPAWN_TICKS = math.floor(C.RESPAWN_SECONDS * 60)
M.SETTLE_TICKS = 30
M.MAX_SETTLE_TICKS = 5 * 60

-- Online il server manda uno stato ogni SNAPSHOT_TICKS tick (30 al secondo)
M.SNAPSHOT_TICKS = 2

-- Comandi (li usa il client). La potenza del tiro viene da quanto è lontano il
-- dito: f = distanza / portata (0..1). Sotto AIM_DEADZONE non conta, poi
-- cresce con l'esponente AIM_EXPONENT (2: quadratica, più precisa sui tiri corti).
M.AIM_DEADZONE = 0
M.AIM_EXPONENT = 1
-- quanto della differenza tra mira e dito si recupera a ogni frame (a 60 Hz); 1 = subito
M.AIM_SMOOTH = 1
-- punti della traiettoria mostrati mentre si mira (false: tutti)
M.AIM_PREVIEW_DOTS = false
-- tenendo premuto il salto si risalta appena si tocca terra
M.JUMP_REPEAT = false
-- Salto corto (come Hollow Knight): lasciando il salto mentre si sale la
-- velocità verso l'alto si moltiplica per JUMP_CUT. 1 = salto sempre pieno.
-- Conta solo se l'input dice hold = false: senza hold il salto è pieno.
M.JUMP_CUT = 1
-- Aiuti (come Celeste): per COYOTE_TICKS dopo essere scesi da un bordo si può
-- ancora saltare; un salto chiesto in aria fino a JUMP_BUFFER_TICKS prima di
-- toccare terra parte appena si atterra.
M.COYOTE_TICKS = 0
M.JUMP_BUFFER_TICKS = 0

function M.aim_power(f)
	f = math.max(0, math.min(1, f))
	if M.AIM_DEADZONE > 0 then f = math.max(0, (f - M.AIM_DEADZONE) / (1 - M.AIM_DEADZONE)) end
	return math.max(0.1, f ^ M.AIM_EXPONENT)
end

local NO_INPUT = {}

-- Statistiche di un robot senza albero né equipaggiamento: config.STATS più
-- quelle del profilo di fisica. Da qui parte anche sim/assetto.lua.
function M.base_stats()
	local st = { teleport_ticks = M.TELEPORT_TICKS }
	for k, v in pairs(C.STATS) do st[k] = v end
	for k, v in pairs(M.DEFAULT_STATS) do st[k] = v end
	return st
end

local function make_stats(custom)
	local st = M.base_stats()
	for k, v in pairs(custom or {}) do st[k] = v end
	st.jump_vy = math.sqrt(2 * M.GRAVITY * st.jump_height)
	st.air_accel = st.air_speed * st.air_speed / M.AIR_REACTION
	return st
end

local function make_ammo(start)
	local a = {}
	for _, w in ipairs(M.CRATE_WEAPONS) do a[w] = start and start[w] or 0 end
	for _, w in ipairs(M.ITEMS) do a[w] = start and start[w] or 0 end
	return a
end

-- opts.players = { { team = 1, stats = { walk_speed = ... }, pick = "shards", secondary = "eagle" }, { team = 2 }, ... }:
-- da 2 a MAX_PLAYERS robot, nell'ordine in cui arrivano. Stesso team = alleati.
-- stats sono le statistiche del robot (albero e equipaggiamento); quelle che
-- mancano vengono da config.STATS e dal profilo di fisica.
-- pick è l'arma della scelta d'inizio partita (sim/draft.lua). dummy = true è
-- un bersaglio che non gioca mai il suo turno (lezioni). Senza players, due
-- robot in squadre diverse.
M.MAX_PLAYERS = 4

-- Ordine dei turni: le squadre si alternano (nel 2 contro 2 A1, B1, A2, B2),
-- nell'ordine in cui compaiono in players. Restituisce gli indici dei robot.
local function turn_order(players)
	local teams, members = {}, {}
	for i, p in ipairs(players) do
		-- i bersagli non giocano
		if not p.dummy then
			if not members[p.team] then
				members[p.team] = {}
				teams[#teams + 1] = p.team
			end
			local m = members[p.team]
			m[#m + 1] = i
		end
	end
	local order = {}
	for round = 1, #players do
		for _, t in ipairs(teams) do
			if members[t][round] then order[#order + 1] = members[t][round] end
		end
	end
	return order
end

-- "1v1", "ffa" (tutti contro tutti: ogni squadra ha un robot) o "2v2" (squadre)
local function match_mode(players)
	local size = {}
	for _, p in ipairs(players) do size[p.team] = (size[p.team] or 0) + 1 end
	for _, n in pairs(size) do
		if n > 1 then return "2v2" end
	end
	return #players == 2 and "1v1" or "ffa"
end

-- opts.ammo = { grenade = 2, ... } colpi iniziali delle armi delle casse (per le prove)
-- opts.crate_every = turni tra una cassa e l'altra (CRATE_EVERY se manca)
-- opts.hp = vita iniziale (stats.max_hp se manca; per le prove)
-- opts.score = punti partita diversi da config.SCORE, solo i campi che cambiano (l'arena prova le varianti)
-- opts.normalize = modalità Torneo: le statistiche di albero e equipaggiamento
-- non contano, tutti hanno quelle di base (resta l'arma della scelta)
function M.new(seed, map_id, opts)
	opts = opts or {}
	local g = setmetatable({}, M)
	-- senza mappa la sceglie il seed (maps.ROTATION)
	local map = maps.get(map_id or maps.pick(seed))
	g.map = map.id
	g.rng = rng.new(seed)
	g.terrain = terrain.new(M.WORLD_W / M.CELL, M.WORLD_H / M.CELL, M.CELL)
	map.build(g.terrain, seed)
	g.spawn_spots = M.find_spawn_spots(g.terrain)
	local players = opts.players or C.MODES["1v1"]
	assert(#players >= 2 and #players <= M.MAX_PLAYERS, "da 2 a " .. M.MAX_PLAYERS .. " giocatori")
	g.robots = {}
	g.order = turn_order(players)
	g.mode = match_mode(players)
	g.normalized = opts.normalize or false
	g.score = C.SCORE
	if opts.score then
		g.score = {}
		for k, v in pairs(C.SCORE) do g.score[k] = v end
		for k, v in pairs(opts.score) do g.score[k] = v end
	end
	-- i punti di partenza nell'ordine dei turni (compagni dallo stesso lato), poi i bersagli
	local placing = {}
	for k, i in ipairs(g.order) do placing[k] = i end
	for i, p in ipairs(players) do
		if p.dummy then placing[#placing + 1] = i end
	end
	for k, i in ipairs(placing) do
		local p = players[i]
		local sp = map.spawns[k]
		local st = make_stats(not opts.normalize and p.stats or nil)
		g.robots[i] = {
			id = i, team = p.team, x = sp.x, y = g.terrain:ground_below(sp.x, sp.from) or M.WORLD_H / 2,
			vx = 0, vy = 0, grounded = false, knocked = false, facing = sp.x < M.WORLD_W / 2 and 1 or -1,
			hp = opts.hp or st.max_hp, max_hp = st.max_hp, dead = false,
			-- per i punti e i risultati di fine partita
			points = 0, damage = 0, kills = 0, env_kills = 0, deaths = 0, falls = 0,
			attack_ticks = 0, attack_turns = 0, teleports = 0, crates = 0,
			teleports_left = st.teleports,   -- globi del teletrasporto in mano
			parachutes_left = st.parachutes, -- paracadute rimasti per la partita
			shield = nil,     -- danni che lo scudo può ancora assorbire
			parachute = false, -- aperto
			status = {},      -- effetti di stato: tipo -> { turns = turni rimasti, by = chi l'ha dato }
			parried = 0,      -- punti di parata presi con lo scudo di adesso (config.SCORE.parry_max)
			life_damage = {}, -- danno preso da ogni avversario in questa vita: id -> punti di vita
			turns = 0,     -- turni giocati
			swing = nil,   -- tick del fendente in corso (1..SWORD_TICKS), nil se fermo
			punch = nil,   -- tick del Pugno del Titano in corso, nil se fermo
			lunge = nil,   -- tick rimasti dell'Affondo in corso, nil se fermo
			recoil = nil,  -- tick rimasti del rinculo del Tonante, nil se fermo
			mallet = nil,  -- tick del colpo di Maglio in corso, nil se fermo
			hooked = nil,  -- appeso alla fune del Rampino: { by = chi tira, left = fune da riavvolgere }
			tool = p.tool or opts.tool or "hook", -- l'attrezzo del turno: "hook" (Rampino) o "wall" (Bastione)
			walls = {},    -- i suoi Bastioni in mappa, dal più vecchio
			ammo = make_ammo(opts.ammo),
			-- la secondaria scelta all'inizio della partita, oltre alla Lama (sim/draft.lua)
			secondary = p.secondary or opts.secondary,
			stats = st,
		}
		-- la primaria presa nella scelta d'inizio partita (sim/draft.lua)
		if p.pick then g.robots[i].ammo[p.pick] = g.robots[i].ammo[p.pick] + C.DRAFT_SHOTS end
	end
	g.events = {}
	g.tick = 0
	g.orbs = {}              -- globi del teletrasporto in volo, dal più vecchio
	g.orb_seq = 0
	g.match_left = M.MATCH_TICKS
	g.current = 1
	g.window = 0             -- tick rimasti dopo il primo attacco del turno (0: non c'è ancora stato)
	g.overtime = false       -- tempo scaduto: si finisce il giro di turni
	g.winner = nil
	g.shards = {}        -- schegge in volo, per posto nella raffica (1..SHARD_COUNT)
	g.crates = {}
	g.placed = {}            -- trappole e trampolini posati
	g.placed_id = 0
	g.wall_id = 0
	g.wall_cells = {}        -- cella (indice in terrain.data) -> Bastione che l'ha riempita
	g.heals = {}             -- cerchi di cura { id, x, y }
	g.heal_id = 0
	g.crate_id = 0
	g.crate_every = opts.crate_every or M.CRATE_EVERY
	-- con crate_every esplicito si usa sempre quello (le prove ne hanno bisogno)
	g.crate_chance = not opts.crate_every and M.CRATE_CHANCE or nil
	g.turn_no = 0
	g.order_pos = 1
	g:start_turn(g.order[1])
	return g
end

function M:emit(e)
	self.events[#self.events + 1] = e
end

function M:pop_events()
	local e = self.events
	self.events = {}
	return e
end

-- Collisioni robot / terreno -------------------------------------------------

-- Collisioni tra robot: sono scatole che non si attraversano. Camminando contro
-- un altro robot lo si spinge, ma piano (PUSH della propria velocità).
M.PUSH = 0.3
-- Un globo del teletrasporto che arriva addosso a un robot lo sposta di poco
M.ORB_NUDGE = 3
M.ORB_R = 3              -- raggio del globo, per gli urti
M.GRENADE_R = 3          -- raggio dell'Uovo: rimbalza sui robot come il globo

-- Il robot (diverso da me e vivo) la cui scatola si sovrappone a quella con i piedi in (x, y)
function M:robot_at(x, y, me)
	for _, o in ipairs(self.robots) do
		if o ~= me and not o.dead and math.abs(x - o.x) < 2 * M.ROBOT_HALF_W
			and y < o.y + M.ROBOT_H and y + M.ROBOT_H > o.y then
			return o
		end
	end
end

-- La scatola del robot con i piedi in (x, y) tocca il terreno o un altro robot?
-- me è il robot stesso (per non urtare sé stesso); senza me contano tutti i robot.
function M:robot_collides(x, y, me)
	return self:terrain_collides(x, y) or self:robot_at(x, y, me) ~= nil
end

-- Mezza larghezza della capsula all'altezza della riga di celle [a, b) (dai piedi in y)
local function capsule_half(y, a, b)
	local r, h = M.ROBOT_HALF_W, M.ROBOT_H
	local low, high = y + r, y + h - r
	-- il punto della riga più vicino al tratto dritto della capsula
	local p = math.max(a, math.min(b, low))
	if p < low then
		local d = low - p
		return d < r and math.sqrt(r * r - d * d) or nil
	end
	p = math.min(b, math.max(a, high))
	if p > high then
		local d = p - high
		return d < r and math.sqrt(r * r - d * d) or nil
	end
	return r
end

function M:terrain_collides(x, y)
	local t, c = self.terrain, M.CELL
	if M.ROBOT_ROUND then
		local cy0 = math.floor(y / c)
		local cy1 = math.floor((y + M.ROBOT_H - 0.01) / c)
		for cy = cy0, cy1 do
			local hw = capsule_half(y, cy * c, cy * c + c)
			if hw and t:any_solid(math.floor((x - hw) / c), math.floor((x + hw) / c), cy, cy) then return true end
		end
		return false
	end
	return t:any_solid(math.floor((x - M.ROBOT_HALF_W) / c), math.floor((x + M.ROBOT_HALF_W) / c),
		math.floor(y / c), math.floor((y + M.ROBOT_H - 0.01) / c))
end

-- Sposta il robot di dx in orizzontale, salendo i gradini piccoli. true se ci riesce.
local function step_x(g, rb, dx)
	for climb = 0, M.MAX_CLIMB do
		if not g:robot_collides(rb.x + dx, rb.y + climb, rb) then
			rb.x = rb.x + dx
			rb.y = rb.y + climb
			return true
		end
	end
	return false
end

-- rb va contro un altro robot: lo spinge di poco e lo segue
function M:push(rb, dx)
	local other = self:robot_at(rb.x + dx, rb.y, rb)
	if not other then return false end
	local p = dx * M.PUSH
	if step_x(self, other, p) then
		step_x(self, rb, p)
		return true
	end
	return false
end

local function walk(g, rb, dx)
	if not step_x(g, rb, dx) then g:push(rb, dx) end
end

-- Punti partita ------------------------------------------------------------------
-- Si guadagnano con il danno agli avversari, le uccisioni (di più quelle
-- ambientali: caduta fuori dalla mappa o da troppo in alto) e colpendo chi è
-- primo in classifica; morire ne toglie. Numeri in config.SCORE.

-- reason dice da dove vengono (damage, kill, death, trap, parry), other è
-- l'altro robot (il colpito; per death chi ha ucciso). L'evento "points" serve
-- all'interfaccia (il numero che vola nella classifica) e all'arena dei bot.
function M:add_points(rb, n, reason, other)
	rb.points = rb.points + n
	self:emit({ type = "points", robot = rb.id, amount = n, reason = reason, other = other and other.id })
end

-- Chi ha più punti (solo se è uno solo e ne ha più di zero): colpirlo vale di più
function M:leader()
	local best, tie = nil, false
	for _, rb in ipairs(self.robots) do
		if not best or rb.points > best.points then
			best, tie = rb, false
		elseif rb.points == best.points then
			tie = true
		end
	end
	if best and not tie and best.points > 0 then return best end
end

local function enemies(a, b)
	return a ~= b and a.team ~= b.team
end

-- by ha spostato rb senza danno (Rampino, trampolino): conta come ultimo
-- colpo, così se rb muore entro KILL_CREDIT_SECONDS l'uccisione è di by
function M:credit(rb, by)
	if by and enemies(by, rb) then rb.last_hit, rb.last_hit_tick = by.id, self.tick end
end

-- Toglie amount punti di vita a rb. by è il robot che ha colpito (nil: nessuno,
-- per esempio una caduta), reason va nell'evento "damage". Restituisce il danno
-- arrivato alla vita (0 se lo scudo ha preso tutto).
function M:hurt(rb, amount, by, reason)
	if rb.dead or amount <= 0 then return 0 end
	local foe = by and enemies(by, rb)
	if by and by ~= rb then rb.last_hit, rb.last_hit_tick = by.id, self.tick end
	if rb.status.cracked then amount = math.floor(amount * C.STATUS.cracked.damage + 0.5) end
	if rb.shield then
		-- lo scudo assorbe per primo
		local absorbed = math.min(rb.shield, amount)
		rb.shield = rb.shield - absorbed
		amount = amount - absorbed
		self:emit({ type = "shield_hit", robot = rb.id, amount = absorbed, left = rb.shield })
		-- parata: chi porta lo scudo prende punti per il danno nemico che ferma
		if foe then
			local p = math.min(self.score.parry_max - rb.parried, absorbed * self.score.parry)
			if p > 0 then
				rb.parried = rb.parried + p
				self:add_points(rb, p, "parry", by)
			end
		end
		if rb.shield <= 0 then rb.shield = nil end
		if amount <= 0 then return 0 end
	end
	local score = self.score
	local mult = rb == self:leader() and score.leader or 1
	-- per i punti conta solo la vita che c'era davvero
	local real = math.min(amount, rb.hp)
	rb.hp = rb.hp - amount
	self:emit({ type = "damage", robot = rb.id, amount = amount, reason = reason })
	if by and by ~= rb then
		if foe then
			by.damage = by.damage + real
			rb.life_damage[by.id] = (rb.life_damage[by.id] or 0) + real
			self:add_points(by, real * 100 / rb.stats.max_hp * score.damage * mult, "damage", rb)
		end
	end
	-- se era il primo prima del colpo, la Corona resta anche se il colpo fa primo chi uccide
	if rb.hp <= 0 then self:kill(rb, reason == "fall" and "fall_damage" or "damage", mult > 1) end
	return amount
end

-- Effetti di stato ------------------------------------------------------------------
-- Durano fino alla fine del prossimo turno di chi li subisce (o di più, con
-- stats.status_turns di chi li dà). Numeri in config.STATUS.

function M:add_status(rb, kind, by)
	if rb.dead then return end
	local turns = by and by.stats.status_turns or 1
	local s = rb.status[kind]
	if s then
		s.turns, s.by = math.max(s.turns, turns), by and by.id
	else
		rb.status[kind] = { turns = turns, by = by and by.id }
	end
	self:emit({ type = "status", robot = rb.id, kind = kind, turns = rb.status[kind].turns })
end

-- Il colpo di weapon ha fatto danno: l'effetto che porta, se ne porta uno
function M:hit_status(rb, weapon, by)
	local kind = C.WEAPON_STATUS[weapon]
	if not kind and by and by.stats.burning_blasts > 0 and weapon == "grenade" then
		kind = "burn"
	end
	if kind then self:add_status(rb, kind, by) end
end

-- A fine turno di rb gli effetti perdono un turno
function M:age_status(rb)
	for kind, s in pairs(rb.status) do
		s.turns = s.turns - 1
		if s.turns <= 0 then
			rb.status[kind] = nil
			self:emit({ type = "status_end", robot = rb.id, kind = kind })
		end
	end
end

-- reason: "damage" (colpi), "fell" (fuori dalla mappa), "fall_damage" (caduta
-- da troppo in alto). L'uccisione va all'ultimo che l'ha colpito, se è stato
-- da poco (KILL_CREDIT_SECONDS): così buttare giù qualcuno conta. was_leader:
-- se era il primo prima del colpo che lo uccide (nil: si guarda adesso).
function M:kill(rb, reason, was_leader)
	if rb.dead then return end
	local killer
	if rb.last_hit and self.tick - rb.last_hit_tick <= C.KILL_CREDIT_SECONDS * 60 then
		killer = self.robots[rb.last_hit]
	end
	-- morto nel proprio turno senza un colpo recente di un avversario: l'uccisione
	-- va a chi gli ha fatto più danno in questa vita (a pari danno a chi l'ha
	-- colpito per ultimo), e lui perde di più
	local own = rb.id == self.current and self.phase ~= "over" and not (killer and enemies(killer, rb))
	if own then
		killer = nil
		local best = 0
		for _, o in ipairs(self.robots) do
			local dmg = rb.life_damage[o.id] or 0
			if dmg > best or (dmg > 0 and dmg == best and o.id == rb.last_hit) then killer, best = o, dmg end
		end
	end
	-- chi si butta giù da solo non regala il bonus ambientale
	local env = reason ~= "damage" and not own
	local score = self.score
	if was_leader == nil then was_leader = rb == self:leader() end
	local mult = was_leader and score.leader or 1
	rb.dead = true
	rb.hp = 0
	rb.deaths = rb.deaths + 1
	if reason == "fell" then rb.falls = rb.falls + 1 end
	self:add_points(rb, score.death + (own and score.self_death or 0), "death", killer)
	local points = 0
	if killer and enemies(killer, rb) then
		killer.kills = killer.kills + 1
		points = score.kill * mult
		if env then
			killer.env_kills = killer.env_kills + 1
			points = points + score.env_kill * mult
		end
		-- Corona: chi abbatte il primo in classifica prende in più crown
		if mult > 1 then points = points + score.crown end
		self:add_points(killer, points, "kill", rb)
	end
	rb.last_hit = nil
	rb.respawn_in = M.RESPAWN_TICKS
	self:emit({ type = "death", robot = rb.id, reason = reason, by = killer and killer.id, env = env, points = points, own = own })
end

-- Punti di rinascita: sopra l'acciaio, che non si distrugge, così sotto i
-- piedi c'è sempre terreno (Sergio, 29 ottobre 2026: "sempre su parti fisse
-- della mappa, ma sempre randomici"). Ogni SPAWN_PASSO px lungo le superfici
-- d'acciaio con lo spazio per il robot sopra; nil se la mappa non ne ha.
M.SPAWN_PASSO = 24
-- distanza minima dai nemici vivi e dalle trappole per rinascere in un punto
M.SPAWN_LONTANO = 300
M.SPAWN_TRAPPOLA = 48

function M.find_spawn_spots(t)
	local head = math.ceil(M.ROBOT_H / t.cell)
	local half = math.ceil(M.ROBOT_HALF_W / t.cell)
	local out = {}
	for x = 30, M.WORLD_W - 30, M.SPAWN_PASSO do
		local cx = math.floor(x / t.cell)
		for cy = 0, t.h - 2 do
			if t:get(cx, cy) == terrain.STEEL and t:get(cx, cy + 1) == 0
				and not t:any_solid(cx - half, cx + half, cy + 1, cy + head) then
				out[#out + 1] = { x = x, y = (cy + 1) * t.cell }
			end
		end
	end
	return #out > 0 and out or nil
end

-- Il punto di rinascita di rb: a caso tra quelli liberi, lontani dai nemici
-- vivi (SPAWN_LONTANO) e dalle trappole; se non ce n'è nessuno, il più
-- lontano dai nemici. Senza punti d'acciaio, un punto libero a caso.
function M:spawn_spot(rb)
	local spots = self.spawn_spots
	if not spots then
		return self:surface_spot(function(x, gy) return not self:robot_collides(x, gy, rb) end)
	end
	local ok, best, best_d = {}, nil, -1
	for _, s in ipairs(spots) do
		if not self:robot_collides(s.x, s.y, rb) then
			local d = math.huge
			for _, o in ipairs(self.robots) do
				if o ~= rb and not o.dead and o.team ~= rb.team then
					local dx, dy = o.x - s.x, o.y - s.y
					d = math.min(d, math.sqrt(dx * dx + dy * dy))
				end
			end
			local trappola = false
			for _, o in ipairs(self.placed) do
				if o.kind == "trap" and math.abs(o.x - s.x) < M.SPAWN_TRAPPOLA and math.abs(o.y - s.y) < M.SPAWN_TRAPPOLA then
					trappola = true
				end
			end
			if not trappola then
				if d >= M.SPAWN_LONTANO then ok[#ok + 1] = s end
				if d > best_d then best, best_d = s, d end
			end
		end
	end
	local s = #ok > 0 and ok[1 + math.floor(self.rng:next() * #ok)] or best
	if s then return s.x, s.y end
end

-- Alla morte si ricomincia con la vita piena in un punto di rinascita
-- (spawn_spot). Teletrasporti e colpi delle armi restano.
function M:respawn(rb)
	local x, y = self:spawn_spot(rb)
	local sp = maps.get(self.map).spawns[1]
	rb.x = x or sp.x
	rb.y = y or self.terrain:ground_below(sp.x, sp.from) or M.WORLD_H / 2
	rb.vx, rb.vy, rb.grounded, rb.knocked, rb.rising = 0, 0, false, false, false
	rb.swing, rb.swing_hit, rb.swing_dir, rb.punch, rb.punch_dir, rb.fall_top = nil, nil, nil, nil, nil, nil
	rb.lunge, rb.lunge_hit, rb.hooked, rb.mallet, rb.mallet_stop, rb.recoil = nil, nil, nil, nil, nil, nil
	rb.hp, rb.dead, rb.shield, rb.status, rb.respawn_in = rb.max_hp, false, nil, {}, nil
	rb.parachute, rb.life_damage = false, {}
	self:emit({ type = "respawn", robot = rb.id, x = rb.x, y = rb.y })
end

-- Chi esce dalla partita online (ESCI DALLA PARTITA, server/room.go) sparisce
-- subito: niente morte né punti a nessuno, non rinasce e non ha più turni. Se
-- era il suo turno, passa al prossimo.
function M:remove(id)
	local rb = self.robots[id]
	if rb.gone or self.phase == "over" then return end
	rb.gone, rb.dead, rb.hp, rb.respawn_in = true, true, 0, nil
	local pos
	for i, p in ipairs(self.order) do
		if p == id then pos = i end
	end
	table.remove(self.order, pos)
	if pos < self.order_pos then self.order_pos = self.order_pos - 1 end
	self:emit({ type = "gone", robot = id })
	if self.current == id and #self.order > 0 then
		-- il prossimo è già al posto suo nell'ordine: end_turn passa a lui
		self.order_pos = pos - 1
		if self.projectile and self.projectile.owner == id then self.projectile = nil end
		self:end_turn()
	end
end

-- Un punto a caso sulla superficie della mappa (il terreno più alto sotto x)
-- per cui ok(x, y) è vero, o nil. Usa il generatore della partita, così
-- server e client trovano lo stesso punto.
function M:surface_spot(ok)
	for _ = 1, 40 do
		local x = math.floor(self.rng:range(40, M.WORLD_W - 40))
		local gy = self.terrain:ground_below(x, M.WORLD_H - 1)
		if gy and gy < M.WORLD_H - 40 and ok(x, gy) then return x, gy end
	end
end

-- Danno da caduta (solo se FALL_SAFE): conta dal punto più alto da cui è
-- iniziata la discesa, anche se ci si è arrivati per un'esplosione
function M:land(rb)
	local top = rb.fall_top
	rb.fall_top = nil
	if rb.parachute then
		-- col paracadute aperto si atterra senza danno, e il paracadute è finito
		rb.parachute = false
		self:emit({ type = "parachute_land", robot = rb.id })
		return
	end
	if not (M.FALL_SAFE and top) then return end
	local drop = top - rb.y - M.FALL_SAFE
	if drop <= 0 then return end
	local dmg = math.floor(math.min(drop * M.FALL_DAMAGE, M.FALL_DAMAGE_MAX) * rb.stats.fall_damage_mul + 0.5)
	if dmg <= 0 then return end
	self:hurt(rb, dmg, nil, "fall")
end

-- active: è il robot di turno e può muoversi (riceve i comandi)
function M:update_robot(rb, input, active)
	if rb.dead then return end
	-- durante l'Affondo lo scatto comanda il movimento, nel rinculo del Tonante
	-- la spinta; appeso al Rampino, la fune
	if rb.lunge then return self:update_lunge(rb) end
	if rb.recoil then return self:update_recoil(rb) end
	if rb.hooked then return self:update_hooked(rb) end

	-- Se il robot è finito dentro il terreno, lo spingiamo fuori verso l'alto
	if self:terrain_collides(rb.x, rb.y) then
		rb.y = rb.y + 1
		return
	end
	-- se è incastrato in un altro robot si allontanano di un pixel alla volta
	local stuck = self:robot_at(rb.x, rb.y, rb)
	if stuck then
		local away = rb.x < stuck.x and -1 or (rb.x > stuck.x and 1 or (rb.id < stuck.id and -1 or 1))
		if not self:terrain_collides(rb.x + away, rb.y) then rb.x = rb.x + away end
	end

	local st = rb.stats
	-- rallentato: corsa, velocità in aria e salto ridotti
	local slow = rb.status.slow and C.STATUS.slow
	local move, jump = slow and slow.move or 1, slow and slow.jump or 1
	local dir = (input.right and 1 or 0) - (input.left and 1 or 0)
	if dir ~= 0 then rb.facing = dir end

	-- aiuti al salto: il tempo concesso dopo il bordo e il salto chiesto in anticipo
	rb.coyote = math.max(0, (rb.coyote or 0) - 1)
	rb.jump_buf = math.max(0, (rb.jump_buf or 0) - 1)
	local want_jump = input.jump
	-- salto appena premuto (tenendolo premuto non si risalta in aria)
	local pressed = input.jump and not rb.jump_held
	rb.jump_held = input.jump
	if want_jump and not rb.grounded then
		if rb.coyote > 0 then
			rb.grounded = true
		elseif pressed and active and (rb.air_left or 0) > 0 then
			-- salto in aria (stats.air_jumps per ogni volo)
			rb.air_left = rb.air_left - 1
			rb.vx, rb.vy = dir * st.walk_speed * move, st.jump_vy * jump
			rb.knocked, rb.rising, rb.fall_top = false, true, nil
			self:emit({ type = "air_jump", robot = rb.id })
		else
			rb.jump_buf = M.JUMP_BUFFER_TICKS
		end
	end
	if rb.grounded then rb.air_left = st.air_jumps end
	if rb.grounded and rb.jump_buf > 0 then want_jump = true end

	if rb.grounded then
		if dir ~= 0 then
			walk(self, rb, dir * st.walk_speed * move * M.DT)
		end
		if want_jump then
			-- salto libero: verso l'alto, oppure nella direzione in cui si sta andando
			rb.vx = dir * st.walk_speed * move
			rb.vy = st.jump_vy * jump
			rb.grounded = false
			rb.rising = true
			rb.coyote, rb.jump_buf = 0, 0
		elseif not self:robot_collides(rb.x, rb.y - 1, rb) then
			-- In discesa resta attaccato al terreno, altrimenti inizia a cadere
			local landed = false
			for d = 1, M.MAX_CLIMB do
				if self:robot_collides(rb.x, rb.y - d - 1, rb) then
					rb.y = rb.y - d
					landed = true
					break
				end
			end
			if not landed then
				rb.grounded = false
				rb.vx, rb.vy = 0, 0
				rb.coyote = M.COYOTE_TICKS
			end
		end
	end

	if not rb.grounded then
		-- salto corto: lasciando il tasto mentre si sale si smette di salire
		if rb.rising and (rb.knocked or rb.vy <= 0) then rb.rising = false end
		if rb.rising and input.hold == false then
			rb.vy = rb.vy * M.JUMP_CUT
			rb.rising = false
		end
		-- col paracadute ci si muove un po' più veloci, anche appena sbalzati
		local chute = rb.parachute and C.PARACHUTE.air_mul or 1
		if rb.parachute and active then rb.knocked = false end
		if M.AIR_CONTROL == "instant" then
			-- Blastron: niente inerzia, anche appena sbalzati
			local air = st.air_speed * move * chute
			if dir ~= 0 then rb.vx = dir * air end
			if active and M.CLAMP_ACTIVE_VX then
				rb.vx = math.max(-air, math.min(air, rb.vx))
			end
		elseif not rb.knocked then
			-- controllo in aria (non mentre si viene sbalzati da un'esplosione)
			local dv = dir * st.air_speed * move * chute - rb.vx
			local max_dv = st.air_accel * M.DT
			rb.vx = rb.vx + math.max(-max_dv, math.min(max_dv, dv))
		end
		rb.vy = rb.vy - M.GRAVITY * M.DT
		if rb.parachute then rb.vy = math.max(rb.vy, -C.PARACHUTE.fall_speed) end
		if rb.vy < 0 and not rb.fall_top then rb.fall_top = rb.y end
		local landed = false
		local mx, my = rb.vx * M.DT, rb.vy * M.DT
		local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my))))
		local sx, sy = mx / steps, my / steps
		for _ = 1, steps do
			if sx ~= 0 then
				if not self:robot_collides(rb.x + sx, rb.y, rb) then
					rb.x = rb.x + sx
				elseif not self:robot_collides(rb.x + sx, rb.y + 3, rb) then
					-- piccolo gradino in aria: lo scavalca invece di incastrarsi
					rb.x, rb.y = rb.x + sx, rb.y + 3
				else
					-- contro un robot in volo: lo sposta un pizzico e si ferma
					self:push(rb, sx)
					rb.vx, sx = 0, 0
				end
			end
			if sy ~= 0 then
				if self:robot_collides(rb.x, rb.y + sy, rb) then
					if sy < 0 then
						rb.grounded = true
						rb.knocked = false
						rb.vx = 0
						landed = true
					end
					rb.vy, sy = 0, 0
				else
					rb.y = rb.y + sy
				end
			end
		end
		if landed then self:land(rb) end
	else
		rb.fall_top = nil
	end

	if rb.y < -20 or rb.x < -20 or rb.x > M.WORLD_W + 20 then
		self:kill(rb, "fell")
	end
end

-- Missile ----------------------------------------------------------------------

local function launch_velocity(angle, power, max_speed)
	local speed = max_speed * math.max(0.1, math.min(1, power))
	return math.cos(angle) * speed, math.sin(angle) * speed
end

local function muzzle(rb, angle)
	return rb.x + math.cos(angle) * M.MUZZLE, rb.y + M.DISEGNO_H / 2 + math.sin(angle) * M.MUZZLE
end

function M:fire(angle, power)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local vx, vy = launch_velocity(angle, power, M.MISSILE_SPEED)
	self.projectile = { kind = "missile", x = x, y = y, vx = vx, vy = vy, owner = rb.id, age = 0 }
	self:emit({ type = "fire", robot = rb.id })
end

-- Uovo di Fiamma ----------------------------------------------------------------

function M:throw_grenade(angle, power)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local speed = M.GRENADE_SPEED * math.max(0.1, math.min(1, power))
	self.projectile = { kind = "grenade", x = x, y = y, vx = math.cos(angle) * speed, vy = math.sin(angle) * speed,
		owner = rb.id, age = 0, fuse = M.GRENADE_FUSE }
	self:emit({ type = "grenade", robot = rb.id })
end

-- Rimbalza sul terreno muovendosi un asse alla volta: semplice e stabile sulla
-- griglia di celle. Sui robot rimbalza come il globo del teletrasporto.
function M:update_grenade(p)
	p.age = p.age + 1
	p.fuse = p.fuse - 1
	p.vy = p.vy - M.GRAVITY * M.GRENADE_GRAVITY * M.DT
	if p.touched and M.GRENADE_DAMPING > 0 then
		local k = 1 / (1 + M.DT * M.GRENADE_DAMPING)
		p.vx, p.vy = p.vx * k, p.vy * k
	end
	local mx, my = p.vx * M.DT, p.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	local sx, sy = mx / steps, my / steps
	local t = self.terrain
	for _ = 1, steps do
		local hit = self:body_hits_robot(p, p.x + sx, p.y + sy, M.GRENADE_R)
		if hit then
			self:bounce_on_robot(p, hit, M.GRENADE_BOUNCE, M.GRENADE_FRICTION)
			break
		end
		if self:spring(p, p.y + sy, M.GRENADE_R) then break end
		if sx ~= 0 then
			if t:solid(p.x + sx, p.y) then
				p.vx, sx = -p.vx * M.GRENADE_BOUNCE, 0
				p.touched = true
			else
				p.x = p.x + sx
			end
		end
		if sy ~= 0 then
			if t:solid(p.x, p.y + sy) then
				if sy < 0 then p.vx = p.vx * M.GRENADE_FRICTION end
				p.touched = true
				p.vy = -p.vy * M.GRENADE_BOUNCE
				-- un rimbalzo piccolo non vale: si posa
				if math.abs(p.vy) < 40 then p.vy = 0 end
				sy = 0
			else
				p.y = p.y + sy
			end
		end
	end
	if p.fuse <= 0 then
		self:explode(p.x, p.y, p.owner, M.GRENADE_BLAST, "grenade")
		self.projectile = nil
	elseif p.y < -50 or p.x < -300 or p.x > M.WORLD_W + 300 then
		self:emit({ type = "miss" })
		self.projectile = nil
	end
end

-- Sciame di Schegge --------------------------------------------------------------

function M:fire_shards(angle)
	local rb = self.robots[self.current]
	self.burst = { owner = rb.id, angle = angle, n = 0, wait = 0 }
	self:emit({ type = "shards", robot = rb.id })
end

function M:update_burst()
	local b = self.burst
	local rb = self.robots[b.owner]
	if rb.dead then
		self.burst = nil
		return
	end
	b.wait = b.wait - 1
	if b.wait > 0 then return end
	b.n = b.n + 1
	b.wait = M.SHARD_EVERY
	-- la mira resta quella dello sparo, le schegge escono da dove si trova il robot
	local a = b.angle + (self.rng:next() * 2 - 1) * M.SHARD_SPREAD
	local x, y = muzzle(rb, a)
	self.shards[b.n] = { x = x, y = y, vx = math.cos(a) * M.SHARD_SPEED, vy = math.sin(a) * M.SHARD_SPEED,
		owner = rb.id, age = 0 }
	if b.n >= M.SHARD_COUNT then self.burst = nil end
end

function M:update_shards()
	for i = 1, M.SHARD_COUNT do
		local p = self.shards[i]
		if p then
			p.age = p.age + 1
			p.vy = p.vy - M.GRAVITY * M.SHARD_GRAVITY * M.DT
			local mx, my = p.vx * M.DT, p.vy * M.DT
			local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
			for _ = 1, steps do
				if self:spring(p, p.y + my / steps, 0) then break end
				p.x = p.x + mx / steps
				p.y = p.y + my / steps
				if self.terrain:solid(p.x, p.y) or self:hits_robot(p.x, p.y, p.owner, p.age) then
					self:explode(p.x, p.y, p.owner, M.SHARD_BLAST, "shards")
					self.shards[i] = nil
					break
				end
			end
			if self.shards[i] and (p.y < -50 or p.x < -300 or p.x > M.WORLD_W + 300) then
				self.shards[i] = nil
			end
		end
	end
end

function M:shards_flying()
	if self.burst then return true end
	for i = 1, M.SHARD_COUNT do
		if self.shards[i] then return true end
	end
	return false
end

-- Teletrasporto -----------------------------------------------------------------

function M:throw_orb(angle, power)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local vx, vy = launch_velocity(angle, power, M.ORB_SPEED)
	self.orb_seq = self.orb_seq + 1
	self.orbs[#self.orbs + 1] = { id = self.orb_seq, x = x, y = y, vx = vx, vy = vy, owner = rb.id,
		timer = rb.stats.teleport_ticks, age = 0 }
	self:emit({ type = "orb", robot = rb.id })
end

-- Cerca un punto libero vicino a (x, y) dove far comparire il robot
-- Punti dove far comparire il robot attorno al globo, dal più vicino al più
-- lontano (a parità di distanza prima quelli più in alto)
M.TELEPORT_SEARCH = 48
local OFFSETS = {}
local function teleport_offsets(r)
	local key = math.floor(r)
	if OFFSETS[key] then return OFFSETS[key] end
	-- passo di 2 pixel fino a 48, poi in proporzione: sempre circa 1800 punti
	local step = math.max(2, math.floor(key / 24))
	local list = {}
	for dy = -key, key, step do
		for dx = -key, key, step do
			if dx * dx + dy * dy <= key * key then list[#list + 1] = { dx, dy, dx * dx + dy * dy } end
		end
	end
	table.sort(list, function(a, b)
		if a[3] ~= b[3] then return a[3] < b[3] end
		if a[2] ~= b[2] then return a[2] > b[2] end
		return a[1] < b[1]
	end)
	OFFSETS[key] = list
	return list
end

-- Il teletrasporto avviene sempre: nel punto libero più vicino al globo e, se
-- attorno è tutto pieno, proprio lì (il robot poi esce dal terreno verso l'alto).
function M:teleport(rb, x, y)
	local tx, ty = x, y
	for _, o in ipairs(teleport_offsets(M.TELEPORT_SEARCH)) do
		if not self:robot_collides(x + o[1], y + o[2], rb) then
			tx, ty = x + o[1], y + o[2]
			break
		end
	end
	local fx, fy = rb.x, rb.y
	rb.x, rb.y = tx, ty
	-- lo stato resta identico: chi cadeva continua a cadere con la stessa velocità.
	-- Non è più appoggiato a niente, la fisica lo rimette a terra se serve.
	rb.grounded = false
	rb.fall_top = nil
	self:emit({ type = "teleport", robot = rb.id, from_x = fx, from_y = fy, x = tx, y = ty })
end

-- Rimbalzo e rotolamento del globo
M.ORB_BOUNCE = 0.35      -- quanta velocità resta nel rimbalzo
M.ORB_FRICTION = 0.97    -- attrito lungo la superficie, per ogni tick a contatto

-- Direzione verso fuori dal terreno attorno a (x, y): l'opposto della media
-- delle celle piene vicine
local function surface_normal(t, x, y)
	local c = M.CELL
	local cx, cy = math.floor(x / c), math.floor(y / c)
	local nx, ny = 0, 0
	for oy = -3, 3 do
		for ox = -3, 3 do
			if ox * ox + oy * oy <= 9 and t:get(cx + ox, cy + oy) ~= 0 then
				nx, ny = nx - ox, ny - oy
			end
		end
	end
	local d = math.sqrt(nx * nx + ny * ny)
	if d < 1e-6 then return 0, 1 end
	return nx / d, ny / d
end

-- Il robot contro cui urta il globo in (x, y), o nil. Chi l'ha lanciato
-- conta solo dopo un attimo, così il globo non gli rimbalza in faccia.
-- Il robot toccato da un corpo rotondo di raggio r in (x, y) (globo, Uovo), o nil.
-- Chi l'ha lanciato non lo tocca nei primi OWNER_SAFE_TICKS.
function M:body_hits_robot(o, x, y, r)
	for _, rb in ipairs(self.robots) do
		if not rb.dead and (rb.id ~= o.owner or o.age > M.OWNER_SAFE_TICKS) and M.hurt_at(rb, x, y, r) then
			return rb
		end
	end
end

-- Il corpo o rimbalza sulla scatola del robot hit e, se arriva forte, lo sposta un briciolo
function M:bounce_on_robot(o, hit, bounce, friction)
	local sx, sy = 0, 1
	if o.y < hit.y + M.ROBOT_H - 2 then sx, sy = o.x < hit.x and -1 or 1, 0 end
	local vn = o.vx * sx + o.vy * sy
	if vn < -40 then
		local d = (o.vx < 0 and -1 or 1)
		if sy == 0 then d = -sx end
		step_x(self, hit, d * M.ORB_NUDGE)
	end
	if vn < 0 then
		local e = vn < -60 and bounce or 0
		local tx, ty = o.vx - vn * sx, o.vy - vn * sy
		o.vx = tx * friction - e * vn * sx
		o.vy = ty * friction - e * vn * sy
	end
	o.touched = true
end

-- Aggiorna un globo; restituisce false quando ha finito (teletrasporto fatto)
function M:update_orb(o)
	local rb = self.robots[o.owner]
	if rb.dead then return false end
	o.age = (o.age or 0) + 1
	-- vola come il missile; quando tocca il terreno rimbalza e rotola.
	-- Se esce dalla mappa continua a cadere: il teletrasporto ti porta lì lo stesso.
	local t = self.terrain
	o.vy = o.vy - M.GRAVITY * M.ORB_GRAVITY * M.DT
	if o.touched and M.ORB_DAMPING > 0 then
		local k = 1 / (1 + M.DT * M.ORB_DAMPING)
		o.vx, o.vy = o.vx * k, o.vy * k
	end
	local mx, my = o.vx * M.DT, o.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	for _ = 1, steps do
		local nx, ny = o.x + mx / steps, o.y + my / steps
		local hit = self:body_hits_robot(o, nx, ny, M.ORB_R)
		if hit then
			self:bounce_on_robot(o, hit, M.ORB_BOUNCE, M.ORB_FRICTION)
			break
		elseif self:spring(o, ny, M.ORB_R) then
			break
		elseif t:solid(nx, ny) then
			local sx, sy = surface_normal(t, nx, ny)
			local vn = o.vx * sx + o.vy * sy
			if vn < 0 then
				-- toglie la parte di velocità contro il terreno (e ne rimanda indietro
				-- un po' se l'urto è forte), frena quella lungo la superficie
				local e = vn < -60 and M.ORB_BOUNCE or 0
				local tx, ty = o.vx - vn * sx, o.vy - vn * sy
				o.vx = tx * M.ORB_FRICTION - e * vn * sx
				o.vy = ty * M.ORB_FRICTION - e * vn * sy
			end
			o.touched = true
			break
		end
		o.x, o.y = nx, ny
	end
	o.timer = o.timer - 1
	if o.timer <= 0 then
		-- il globo è al centro del robot, la posizione del robot è ai piedi
		self:teleport(rb, o.x, o.y - M.ROBOT_H / 2)
		return false
	end
	return true
end

-- Tutti i globi in volo, dal più vecchio: ognuno teletrasporta allo scadere del suo tempo
function M:update_orbs()
	local orbs, n = self.orbs, 0
	for i = 1, #orbs do
		local o = orbs[i]
		if self:update_orb(o) then
			n = n + 1
			orbs[n] = o
		end
	end
	for i = #orbs, n + 1, -1 do orbs[i] = nil end
	-- i globi si urtano anche tra loro: si separano e si scambiano la spinta
	for i = 1, n - 1 do
		local a = orbs[i]
		for j = i + 1, n do
			local b = orbs[j]
			local dx, dy = b.x - a.x, b.y - a.y
			local d2 = dx * dx + dy * dy
			local min = 2 * M.ORB_R
			if d2 < min * min then
				local d = math.sqrt(d2)
				if d < 1e-6 then dx, dy, d = 1, 0, 1 end
				local ux, uy = dx / d, dy / d
				local half = (min - d) / 2
				a.x, a.y = a.x - ux * half, a.y - uy * half
				b.x, b.y = b.x + ux * half, b.y + uy * half
				local va, vb = a.vx * ux + a.vy * uy, b.vx * ux + b.vy * uy
				if va - vb > 0 then
					a.vx, a.vy = a.vx + (vb - va) * ux, a.vy + (vb - va) * uy
					b.vx, b.vy = b.vx + (va - vb) * ux, b.vy + (va - vb) * uy
				end
			end
		end
	end
end

-- Cecchino --------------------------------------------------------------------------

function M:fire_sniper(angle)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	self.projectile = { kind = "sniper", x = x, y = y, vx = math.cos(angle) * M.SNIPER_SPEED,
		vy = math.sin(angle) * M.SNIPER_SPEED, owner = rb.id, age = 0, bounces = 0 }
	self:emit({ type = "sniper", robot = rb.id })
end

-- Rimbalzo come una palla sulla superficie del terreno in (x, y): la parte
-- della velocità contro la superficie si ribalta e si smorza (bounce_normal),
-- quella lungo la superficie frena un po' (bounce_tangent): ogni rimbalzo è
-- più basso e più lento
local function bounce(t, x, y, vx, vy)
	local nx, ny = surface_normal(t, x, y)
	local d = vx * nx + vy * ny
	local tx, ty = vx - d * nx, vy - d * ny
	local s = C.SNIPER
	d = math.abs(d) * s.bounce_normal
	return tx * s.bounce_tangent + nx * d, ty * s.bounce_tangent + ny * d
end

-- Un tick di volo: parte veloce e frena (drag), la gravità cresce a poco a
-- poco fino a drop volte quella dei robot in drop_ramp secondi, così
-- all'inizio va quasi dritto e poi cala sempre di più
local function sniper_step(vx, vy, age)
	local s = C.SNIPER
	local g = M.GRAVITY * s.drop * math.min(1, age / (s.drop_ramp * 60))
	local k = s.drag ^ M.DT
	return vx * k, (vy - g * M.DT) * k
end

function M:update_sniper(p)
	p.age = p.age + 1
	p.vx, p.vy = sniper_step(p.vx, p.vy, p.age)
	local mx, my = p.vx * M.DT, p.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	local t = self.terrain
	for _ = 1, steps do
		local nx, ny = p.x + p.vx * M.DT / steps, p.y + p.vy * M.DT / steps
		local hit = self:body_hits_robot(p, nx, ny, 0)
		if hit then
			self:sniper_hit(p, hit)
			self.projectile = nil
			return
		elseif self:spring(p, ny, 0) then
			break
		elseif t:solid(nx, ny) then
			p.bounces = p.bounces + 1
			p.vx, p.vy = bounce(t, nx, ny, p.vx, p.vy)
			-- troppi rimbalzi o quasi fermo: si spegne lì
			if p.bounces > C.SNIPER.bounces or p.vx * p.vx + p.vy * p.vy < C.SNIPER.min_speed ^ 2 then
				self:emit({ type = "sniper_end", x = p.x, y = p.y })
				self.projectile = nil
				return
			end
			self:emit({ type = "sniper_bounce", x = p.x, y = p.y })
			break
		end
		p.x, p.y = nx, ny
	end
	if p.age > M.SNIPER_LIFE or p.y < -50 or p.x < -300 or p.x > M.WORLD_W + 300 or p.y > M.WORLD_H + 300 then
		self:emit({ type = "miss" })
		self.projectile = nil
	end
end

-- Il colpo sbalza il bersaglio nella direzione in cui andava
function M:sniper_hit(p, rb)
	local sp = math.sqrt(p.vx * p.vx + p.vy * p.vy)
	local k = self:knock_mul(rb)
	local s = C.SNIPER
	rb.vx = p.vx / sp * s.push * k
	rb.vy = (p.vy / sp * s.push + s.lift) * k
	rb.grounded, rb.knocked, rb.fall_top = false, true, nil
	self:emit({ type = "sniper_hit", robot = p.owner, target = rb.id, x = p.x, y = p.y })
	local by = self.robots[p.owner]
	if self:hurt(rb, C.SNIPER.damage, by) > 0 and by ~= rb then self:hit_status(rb, "sniper", by) end
end

-- Linea di mira del cecchino: il primo secondo di volo (com'è il colpo vero,
-- tick per tick); un rimbalzo la chiude subito
M.SNIPER_PREVIEW_TICKS = 60
function M:sniper_preview(x, y, angle, count, pts)
	pts = pts or {}
	local vx, vy = math.cos(angle) * M.SNIPER_SPEED, math.sin(angle) * M.SNIPER_SPEED
	local t, n, after = self.terrain, 0, nil
	local shown = M.SNIPER_PREVIEW_TICKS
	for i = 1, shown do
		vx, vy = sniper_step(vx, vy, i)
		local nx, ny = x + vx * M.DT, y + vy * M.DT
		if t:solid(nx, ny) then
			if after then break end
			vx, vy = bounce(t, nx, ny, vx, vy)
			after = 0
		else
			x, y = nx, ny
			if after then
				after = after + 1
				if after > 4 then break end
			end
			-- i punti spaziati lungo il tratto mostrato
			if i % math.max(1, math.floor(shown / count)) == 0 and n < count then
				n = n + 1
				local pt = pts[n] or {}
				pt.x, pt.y = x, y
				pts[n] = pt
			end
		end
	end
	-- i punti che avanzano restano sull'ultimo
	for i = n + 1, count do
		local pt = pts[i] or {}
		pt.x, pt.y = x, y
		pts[i] = pt
	end
	return pts
end

-- Colpi dritti: Tonante e Rampino (config.EAGLE, config.HOOK) --------------------
-- Istantanei: niente proiettile da seguire, un raggio sulle celle del terreno
-- come la linea di mira.

-- Il raggio da (x, y) nella direzione angle, lungo al massimo range: dove si
-- ferma e il robot che incontra (nil se si ferma sul terreno o a fine corsa).
-- Chi spara (me) non si colpisce.
function M:ray(x, y, angle, range, me)
	local dx, dy = math.cos(angle) * M.CELL, math.sin(angle) * M.CELL
	local t = self.terrain
	for _ = 1, math.ceil(range / M.CELL) do
		local nx, ny = x + dx, y + dy
		if t:solid(nx, ny) then return x, y, nil end
		x, y = nx, ny
		for _, rb in ipairs(self.robots) do
			if rb ~= me and not rb.dead and M.hurt_at(rb, x, y, 0) then return x, y, rb end
		end
	end
	return x, y, nil
end

-- Linea di mira dei colpi dritti: count punti fino al terreno o a fine corsa
function M:ray_preview(x, y, angle, range, count, pts)
	pts = pts or {}
	local ex, ey = self:ray(x, y, angle, range, self.robots[self.current])
	for i = 1, count do
		local pt = pts[i] or {}
		pt.x, pt.y = x + (ex - x) * i / count, y + (ey - y) * i / count
		pts[i] = pt
	end
	return pts
end

-- Tonante: danno secco a chi è sulla linea; il rinculo spinge chi spara
-- dalla parte opposta (da terra anche un po' in alto), così si riposiziona
function M:fire_eagle(angle)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local ex, ey, hit = self:ray(x, y, angle, C.EAGLE.range, rb)
	rb.facing = math.cos(angle) < 0 and -1 or 1
	local s = C.EAGLE
	rb.recoil = s.recoil_ticks
	rb.recoil_vx, rb.recoil_vy = -math.cos(angle) * s.recoil, -math.sin(angle) * s.recoil
	rb.grounded, rb.knocked, rb.fall_top = false, false, nil
	self:emit({ type = "eagle", robot = rb.id, x0 = x, y0 = y, x1 = ex, y1 = ey, target = hit and hit.id })
	if hit then self:hurt(hit, s.damage, rb) end
end

-- Un tick di rinculo del Tonante, al posto della fisica normale del robot:
-- velocità fissa, niente gravità; contro il terreno o un robot scivola
-- sull'asse libero (in orizzontale sale i gradini come camminando), e se sono
-- bloccati tutti e due si ferma.
function M:update_recoil(rb)
	local mx, my = rb.recoil_vx * M.DT, rb.recoil_vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my))))
	local sx, sy = mx / steps, my / steps
	for _ = 1, steps do
		if not self:robot_collides(rb.x + sx, rb.y + sy, rb) then
			rb.x, rb.y = rb.x + sx, rb.y + sy
		elseif sx ~= 0 and step_x(self, rb, sx) then
			-- scivola in orizzontale, salendo i gradini piccoli come camminando
		elseif sy ~= 0 and not self:robot_collides(rb.x, rb.y + sy, rb) then
			rb.y = rb.y + sy
		else
			rb.recoil = 1
			break
		end
	end
	rb.recoil = rb.recoil - 1
	if rb.recoil <= 0 then
		rb.vx, rb.vy = 0, 0
		rb.recoil, rb.recoil_vx, rb.recoil_vy = nil, nil, nil
	end
	if rb.y < -20 or rb.x < -20 or rb.x > M.WORLD_W + 20 then self:kill(rb, "fell") end
end

local HOOK_LAND_DX = { 0, -8, 8, -16, 16 }

-- Rampino (oggetto, uno a turno, config.HOOK): colpo dritto. Su un robot, quello
-- resta appeso alla fune (rb.hooked.by) e viene riavvolto verso la mano di chi
-- tira fin addosso (config.HOOK.reel pixel al massimo), senza danno. Sul terreno è chi tira che
-- resta appeso (rb.hooked.x, y = il punto colpito) e sale lungo la fune fin
-- lì, per poi mettersi in piedi sopra la piattaforma colpita.
function M:fire_hook(angle)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local ex, ey, hit = self:ray(x, y, angle, C.HOOK.range, rb)
	rb.facing = math.cos(angle) < 0 and -1 or 1
	local dx, dy = math.cos(angle) * M.CELL, math.sin(angle) * M.CELL
	local anchor = not hit and self.terrain:solid(ex + dx, ey + dy)
	self:emit({ type = "hook", robot = rb.id, x0 = x, y0 = y, x1 = ex, y1 = ey, target = hit and hit.id, anchor = anchor })
	if hit then
		hit.hooked = { by = rb.id, left = C.HOOK.reel }
		-- chi tira prende l'uccisione se il nemico cade (KILL_CREDIT_SECONDS)
		self:credit(hit, rb)
		hit.vx, hit.vy = 0, 0
		hit.grounded, hit.knocked, hit.fall_top = false, true, nil
	elseif anchor then
		-- la fune si aggancia dentro la cella piena, così si sa da dove salire
		rb.hooked = { x = ex + dx, y = ey + dy, left = C.HOOK.range }
		rb.vx, rb.vy = 0, 0
		rb.grounded, rb.knocked, rb.fall_top = false, false, nil
	end
end

-- Bastione (attrezzo, config.WALL): il rettangolo di celle dove va il blocco,
-- mirando con angle e power. Restituisce cx0, cy0, larghezza e altezza in celle.
function M:wall_rect(angle, power)
	local rb = self.robots[self.current]
	local d = C.WALL.range * math.max(0, math.min(1, power))
	local x, y = rb.x + math.cos(angle) * d, rb.y + M.DISEGNO_H / 2 + math.sin(angle) * d
	local w, h = C.WALL.w, C.WALL.h
	if math.abs(math.sin(angle)) > math.sqrt(0.5) then w, h = h, w end
	local cw, ch = math.floor(w / M.CELL + 0.5), math.floor(h / M.CELL + 0.5)
	return math.floor(x / M.CELL - cw / 2 + 0.5), math.floor(y / M.CELL - ch / 2 + 0.5), cw, ch
end

-- La sagoma del blocco per la mira: count punti lungo il bordo
function M:wall_preview(angle, power, count, pts)
	pts = pts or {}
	local cx0, cy0, cw, ch = self:wall_rect(angle, power)
	local x0, y0, w, h = cx0 * M.CELL, cy0 * M.CELL, cw * M.CELL, ch * M.CELL
	local per = 2 * (w + h)
	for i = 1, count do
		local t = (i - 1) / count * per
		local pt = pts[i] or {}
		if t < w then pt.x, pt.y = x0 + t, y0
		elseif t < w + h then pt.x, pt.y = x0 + w, y0 + t - w
		elseif t < 2 * w + h then pt.x, pt.y = x0 + w - (t - w - h), y0 + h
		else pt.x, pt.y = x0, y0 + h - (t - 2 * w - h) end
		pts[i] = pt
	end
	return pts
end

-- Mette (v = 1) o toglie (v = 0) le celle di un Bastione: il rettangolo cx0, cy0,
-- cw, ch e mask, una stringa di "0" e "1" riga per riga dal basso (1: la cella
-- cambia). Serve anche al client online, che rifà sul suo terreno quello che
-- dice l'evento "wall" del server.
function M.wall_cells(terrain, cx0, cy0, cw, ch, mask, v)
	local k = 0
	for cy = cy0, cy0 + ch - 1 do
		for cx = cx0, cx0 + cw - 1 do
			k = k + 1
			if mask:byte(k) == 49 then terrain:set(cx, cy, v) end
		end
	end
end

-- Bastione: riempie le celle vuote del rettangolo mirato, tranne quelle addosso a
-- un robot. Il blocco di troppo (oltre config.WALL.max) crolla.
function M:fire_wall(angle, power)
	local rb = self.robots[self.current]
	local cx0, cy0, cw, ch = self:wall_rect(angle, power)
	rb.facing = math.cos(angle) < 0 and -1 or 1
	local cell, tw = M.CELL, self.terrain.w
	self.wall_id = self.wall_id + 1
	local wall = { id = self.wall_id, x = cx0, y = cy0, w = cw, h = ch }
	local mask, any = {}, false
	for cy = cy0, cy0 + ch - 1 do
		for cx = cx0, cx0 + cw - 1 do
			local free = cx >= 0 and cy >= 0 and cx < tw and cy < self.terrain.h and self.terrain:get(cx, cy) == 0
			if free then
				-- non dentro un robot (la sua capsula, con un pixel di margine)
				for _, o in ipairs(self.robots) do
					if not o.dead and (cx + 1) * cell > o.x - M.ROBOT_HALF_W - 1 and cx * cell < o.x + M.ROBOT_HALF_W + 1
						and (cy + 1) * cell > o.y - 1 and cy * cell < o.y + M.ROBOT_H + 1 then
						free = false
						break
					end
				end
			end
			mask[#mask + 1] = free and "1" or "0"
			if free then
				any = true
				self.wall_cells[cy * tw + cx + 1] = wall.id
			end
		end
	end
	wall.mask = table.concat(mask)
	if not any then return end
	M.wall_cells(self.terrain, cx0, cy0, cw, ch, wall.mask, 1)
	self:emit({ type = "wall", robot = rb.id, x = cx0, y = cy0, w = cw, h = ch, m = wall.mask, v = 1 })
	rb.walls[#rb.walls + 1] = wall
	if #rb.walls > C.WALL.max then self:crumble_wall(rb, table.remove(rb.walls, 1)) end
end

-- Un Bastione crolla: tornano vuote le sue celle ancora piene (quelle scavate nel
-- frattempo, o riempite da un altro Bastione, restano come sono)
function M:crumble_wall(rb, wall)
	local tw, mask, k = self.terrain.w, {}, 0
	for cy = wall.y, wall.y + wall.h - 1 do
		for cx = wall.x, wall.x + wall.w - 1 do
			k = k + 1
			local i = cy * tw + cx + 1
			local mine = wall.mask:byte(k) == 49 and self.wall_cells[i] == wall.id and self.terrain:get(cx, cy) ~= 0
			if wall.mask:byte(k) == 49 and self.wall_cells[i] == wall.id then self.wall_cells[i] = nil end
			mask[k] = mine and "1" or "0"
		end
	end
	local m = table.concat(mask)
	M.wall_cells(self.terrain, wall.x, wall.y, wall.w, wall.h, m, 0)
	self:emit({ type = "wall", robot = rb.id, x = wall.x, y = wall.y, w = wall.w, h = wall.h, m = m, v = 0 })
end

-- Dove sta la mano di chi tira (la fune parte da lì)
function M.hook_hand(by)
	return by.x + by.facing * M.MUZZLE * 0.5, by.y + M.SWORD_PIVOT_Y
end

-- Un tick di fune, al posto della fisica normale del robot: va dritto verso
-- la mano di chi tira (che intanto può muoversi) o verso il punto agganciato
-- del terreno, finché la fune non è riavvolta tutta o qualcosa lo ferma. Chi
-- era tirato cade dov'è; chi è salito su una piattaforma ci si mette sopra.
function M:update_hooked(rb)
	local h = rb.hooked
	local by = h.by and self.robots[h.by]
	local hx, hy
	if by then hx, hy = M.hook_hand(by) else hx, hy = h.x, h.y end
	local cx, cy = rb.x, rb.y + M.ROBOT_H / 2
	local dx, dy = hx - cx, hy - cy
	local dist = math.sqrt(dx * dx + dy * dy)
	local step = math.min((by and C.HOOK.speed or C.HOOK.climb_speed) * M.DT, h.left, dist)
	local stopped = (by and by.dead) or dist < 1
	if not stopped then
		local ux, uy = dx / dist, dy / dist
		local n = math.max(1, math.ceil(step))
		for _ = 1, n do
			local nx, ny = rb.x + ux * step / n, rb.y + uy * step / n
			if self:robot_collides(nx, ny, rb) then
				-- tirato da un robot: il terreno sotto non lo ferma, scivola
				-- sopra gradini e pendii come camminando (hook_slide)
				nx, ny = self:hook_slide(rb, nx, ny, by)
				if not nx then
					stopped = true
					break
				end
			end
			rb.x, rb.y = nx, ny
		end
		h.left = h.left - step
	end
	if stopped or h.left <= 0.5 then
		rb.hooked = nil
		-- arrivato al terreno (la capsula lo ferma a un passo dal punto): sopra
		if not by and dist < M.ROBOT_H then self:hook_land(rb, h.x, h.y) end
		self:emit({ type = "hook_end", robot = rb.id })
	end
	if rb.y < -20 or rb.x < -20 or rb.x > M.WORLD_W + 20 then self:kill(rb, "fell") end
end

-- Il robot tirato dalla fune urta il terreno in (nx, ny): invece di fermarsi
-- lo si alza di poco (fino a MAX_CLIMB, come un gradino) o, se la fune tira
-- verso il basso, lo si tiene alla sua altezza, così il pavimento, un pendio o
-- un dislivello di un pixel non bloccano la presa. Restituisce dove va, o nil
-- se lo ferma un muro o un robot (chi tira: è arrivato). Solo per chi è tirato
-- (by): chi sale lungo la fune sul terreno si ferma alla piattaforma.
function M:hook_slide(rb, nx, ny, by)
	if not by or self:robot_at(nx, ny, rb) then return nil end
	local y = math.max(ny, rb.y)
	for climb = 0, M.MAX_CLIMB do
		if not self:robot_collides(nx, y + climb, rb) then return nx, y + climb end
	end
end

-- Mette il robot in piedi sopra la piattaforma colpita dal Rampino: dalla
-- cella agganciata sale nella colonna fino alla prima cella vuota (al massimo
-- config.HOOK.climb pixel), spostandosi di poco ai lati se lì non ci sta. Se
-- la cima è troppo in alto (il fianco di un muro), resta dov'è e cade.
function M:hook_land(rb, ax, ay)
	local t, c = self.terrain, M.CELL
	local cx, cy = math.floor(ax / c), math.floor(ay / c)
	for i = 1, math.ceil(C.HOOK.climb / c) do
		if t:get(cx, cy + i) == 0 then
			local y = (cy + i) * c
			for _, ox in ipairs(HOOK_LAND_DX) do
				local x = cx * c + c / 2 + ox
				if not self:robot_collides(x, y, rb) then
					rb.x, rb.y, rb.vx, rb.vy = x, y, 0, 0
					return
				end
			end
			return
		end
	end
end

-- Maglio (config.MALLET) -----------------------------------------------------------
-- Martello a due mani che gira attorno alla spalla come la Lama: parte alto
-- dietro la testa, cala davanti e finisce sotto i piedi. Colpisce una volta
-- ogni robot che tocca lungo l'arco; la testa si ferma sul terreno. Se il
-- colpo è partito in aria e la testa sbatte su un robot o sul terreno mentre
-- cala (dalla spalla in giù), chi colpisce rimbalza in alto (pogo), una volta
-- per colpo, anche se intanto è atterrato.

function M:start_mallet(angle)
	local rb = self.robots[self.current]
	rb.facing = math.cos(angle) < 0 and -1 or 1
	rb.mallet = 0
	rb.mallet_dir = rb.facing
	rb.mallet_hit, rb.mallet_stop, rb.mallet_bounced = {}, nil, false
	rb.mallet_air = not rb.grounded
	self:emit({ type = "mallet", robot = rb.id })
end

-- Angolo del martello al tick t, per un robot rivolto a destra: la stessa
-- curva della Lama (slancio indietro, poi sempre più veloce); fermato sul
-- terreno al tick stop resta lì.
function M.mallet_angle(t, stop)
	local s = C.MALLET
	if stop then t = math.min(t, stop) end
	return s.from + (s.to - s.from) * M.sword_progress(t / s.ticks)
end

-- Partito in aria, un colpo che arriva mentre il martello cala fa rimbalzare in alto
function M:mallet_bounce(rb, t)
	if not rb.mallet_air or rb.mallet_bounced or M.mallet_angle(t) > 0 then return false end
	rb.mallet_bounced = true
	rb.vy, rb.grounded, rb.knocked, rb.fall_top = C.MALLET.bounce, false, false, nil
	return true
end

function M:mallet_hit(rb, other, t)
	local bounce = self:mallet_bounce(rb, t)
	self:emit({ type = "mallet_hit", robot = rb.id, target = other.id, x = other.x, y = other.y + M.HURT_Y, bounce = bounce })
	self:hurt(other, C.MALLET.damage, rb)
end

function M:update_mallet(rb)
	local s = C.MALLET
	local t0 = rb.mallet
	rb.mallet = t0 + 1
	if not rb.mallet_stop and t0 < s.ticks then
		local t, x, y = self:sweep_arc(rb, t0, M.mallet_angle, s.reach, rb.mallet_dir, rb.mallet_hit, M.mallet_hit, true)
		if t then
			rb.mallet_stop = t
			local bounce = self:mallet_bounce(rb, t)
			self:emit({ type = "mallet_hit", robot = rb.id, x = x, y = y, bounce = bounce })
		end
	end
	if rb.mallet >= s.ticks + s.hold then
		rb.mallet, rb.mallet_dir, rb.mallet_hit, rb.mallet_stop, rb.mallet_bounced, rb.mallet_air = nil, nil, nil, nil, nil, nil
	end
end

-- Lama di Nucleo ----------------------------------------------------------------

-- Angolo della lama al tick t del fendente, per un robot rivolto a destra
-- Curva del fendente: come una persona vera, prima porta la lama un po'
-- indietro (slancio, circa 13°) e poi accelera sempre di più fino alla fine.
-- È un "back ease-in": va sotto lo zero all'inizio e arriva a 1 con la velocità massima.
M.SWORD_WINDUP = 1.2
function M.sword_progress(u)
	u = math.max(0, math.min(1, u))
	local s = M.SWORD_WINDUP
	return u * u * ((s + 1) * u - s)
end

-- Angolo della lama al tick t per un robot rivolto a destra. Col modello
-- "blastron" dipende dalla mira: base è l'angolo di mira (già girato a destra).
function M.sword_angle(t, base)
	if M.SWORD_MODEL == "blastron" then
		return (base or 0) + math.rad(M.melee_pose(mischia.fendente, t)[7])
	end
	return M.SWORD_FROM + (M.SWORD_TO - M.SWORD_FROM) * M.sword_progress(t / M.SWORD_TICKS)
end

-- Angolo del pugno al tick t (modello "blastron"), come sword_angle
function M.punch_angle(t, base)
	return (base or 0) + math.rad(M.melee_pose(mischia.montante, t)[7])
end

-- Durata in tick di un colpo di mischia.lua
function M.melee_ticks(colpo)
	return math.ceil((#colpo.pose - 1) * 60 / colpo.fps)
end

-- Posa del colpo al tick t (con frazione): i valori tra due fotogrammi
local POSA = {}
function M.melee_pose(colpo, t)
	local f = math.max(0, math.min(#colpo.pose - 1, t * colpo.fps / 60))
	local i = math.floor(f)
	local a, b = colpo.pose[i + 1], colpo.pose[math.min(#colpo.pose, i + 2)]
	local k = f - i
	for j = 1, 7 do POSA[j] = a[j] + (b[j] - a[j]) * k end
	return POSA
end

-- Mira girata verso destra, tra -90° e 90°, e il lato verso cui si guarda
local function aim_side(angle)
	local dir = math.cos(angle) < 0 and -1 or 1
	local a = dir > 0 and angle or math.pi - angle
	a = (a + math.pi) % (2 * math.pi) - math.pi
	return a, dir
end
M.aim_side = aim_side

-- Un robot preso dal punto (x, y), con un margine pad attorno
function M.hurt_at(r, x, y, pad)
	pad = pad or 0
	if M.HURTBOX == "cerchio" then
		local dx, dy = x - r.x, y - (r.y + M.HURT_Y)
		local rr = M.HURT_R + pad
		return dx * dx + dy * dy <= rr * rr
	end
	return math.abs(x - r.x) <= M.ROBOT_HALF_W + pad and y >= r.y - pad and y <= r.y + M.ROBOT_H + pad
end

-- Un robot toccato dal segmento (x0, y0) - (x1, y1) largo 2 * pad
local function seg_hits_robot(r, x0, y0, x1, y1, pad)
	if M.HURTBOX == "cerchio" then
		local cx, cy = r.x, r.y + M.HURT_Y
		local ux, uy = x1 - x0, y1 - y0
		local l2 = ux * ux + uy * uy
		local k = l2 > 0 and math.max(0, math.min(1, ((cx - x0) * ux + (cy - y0) * uy) / l2)) or 0
		local dx, dy = x0 + ux * k - cx, y0 + uy * k - cy
		local rr = M.HURT_R + pad
		return dx * dx + dy * dy <= rr * rr
	end
	for k = 0, 10 do
		if M.hurt_at(r, x0 + (x1 - x0) * k / 10, y0 + (y1 - y0) * k / 10, pad) then return true end
	end
	return false
end

function M:swing_sword(angle)
	local rb = self.robots[self.current]
	rb.swing_base, rb.facing = aim_side(angle)
	-- il fendente resta nella direzione di partenza anche se il robot si gira
	rb.swing_dir = rb.facing
	rb.swing = 0
	rb.swing_hit = {}
	self:emit({ type = "swing", robot = rb.id })
end

local function in_robot(r, x, y)
	return M.hurt_at(r, x, y, 0)
end

-- alla fine l'arma gira veloce: tanti passi per tick, così non salta un bersaglio
local ARC_SUBSTEPS = 8
local ARC_SAMPLES = 10
-- dove si guarda se la testa del Maglio tocca il terreno: di traverso all'arma
local HEAD_SIDE = { 0, -5, 5 }

-- Un tick di un'arma lunga reach che gira attorno alla spalla di rb (Lama,
-- Maglio), da t0 a t0 + 1: angle(t) è il suo angolo per un robot rivolto a
-- destra, dir il lato del colpo. Ogni robot toccato lungo l'arma viene colpito
-- una volta (hit(self, rb, other, t), segnato in done). Con stop la punta si
-- ferma sul terreno: rende il tick (con la frazione) e il punto dell'urto.
function M:sweep_arc(rb, t0, angle, reach, dir, done, hit, stop)
	local px, py = rb.x, rb.y + M.SWORD_PIVOT_Y
	for s = 1, ARC_SUBSTEPS do
		local t = t0 + s / ARC_SUBSTEPS
		local a = angle(t)
		local cx, cy = math.cos(a) * dir, math.sin(a)
		for _, other in ipairs(self.robots) do
			if other ~= rb and not other.dead and not done[other.id] then
				for k = 1, ARC_SAMPLES do
					local d = reach * k / ARC_SAMPLES
					if in_robot(other, px + cx * d, py + cy * d) then
						done[other.id] = true
						hit(self, rb, other, t)
						break
					end
				end
			end
		end
		if stop then
			local hx, hy = px + cx * reach, py + cy * reach
			for _, w in ipairs(HEAD_SIDE) do
				if self.terrain:solid(hx - cy * w, hy + cx * w) then return t, hx, hy end
			end
		end
	end
end

function M:update_swing(rb)
	if M.SWORD_MODEL == "blastron" then
		if self:update_melee(rb, mischia.fendente, rb.swing, rb.swing_base, rb.swing_dir) then
			rb.swing = rb.swing + 1
		else
			rb.swing, rb.swing_hit, rb.swing_dir, rb.swing_base = nil, nil, nil, nil
		end
		return
	end
	local t0 = rb.swing
	rb.swing = t0 + 1
	self:sweep_arc(rb, t0, M.sword_angle, M.SWORD_REACH, rb.swing_dir, rb.swing_hit, M.sword_hit)
	if rb.swing >= M.SWORD_TICKS then
		rb.swing, rb.swing_hit, rb.swing_dir = nil, nil, nil
	end
end

function M:sword_hit(rb, other)
	self:emit({ type = "sword_hit", robot = rb.id, target = other.id })
	-- la spada fa solo danno: il bersaglio resta dov'è (in Blastron si ferma)
	if M.SWORD_STOP then other.vx, other.vy = 0, 0 end
	self:hurt(other, M.SWORD_DAMAGE, rb)
end

-- Affondo (config.LUNGE) -----------------------------------------------------------
-- Scatto nella direzione della mira che passa attraverso i robot, colpendoli
-- una volta ciascuno col corpo o con la lancia; sale i gradini piccoli e
-- scivola lungo il terreno, si ferma solo quando non passa per niente.

function M:start_lunge(angle)
	local rb = self.robots[self.current]
	rb.facing = math.cos(angle) < 0 and -1 or 1
	rb.lunge = C.LUNGE.ticks
	rb.lunge_vx, rb.lunge_vy = math.cos(angle) * C.LUNGE.speed, math.sin(angle) * C.LUNGE.speed
	rb.lunge_hit = {}
	rb.grounded, rb.knocked = false, false
	self:emit({ type = "lunge", robot = rb.id, angle = angle })
end

-- Dove va un passo di scatto da (x, y) di (dx, dy): dritto, o salendo un
-- gradino fino a climb, o solo la parte orizzontale o verticale che passa.
-- nil se non passa niente.
function M:lunge_step(rb, dx, dy)
	local x, y = rb.x + dx, rb.y + dy
	if not self:terrain_collides(x, y) then return x, y end
	if math.abs(dx) <= 0.05 then
		return nil
	end
	for d = 1, C.LUNGE.climb do
		if not self:terrain_collides(x, y + d) then return x, y + d end
	end
	if not self:terrain_collides(x, rb.y) then return x, rb.y end
	if math.abs(dy) > 0.05 and not self:terrain_collides(rb.x, y) then return rb.x, y end
end

-- Un tick di scatto: al posto della fisica normale del robot (update_robot)
function M:update_lunge(rb)
	local mx, my = rb.lunge_vx * M.DT, rb.lunge_vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my))))
	local len = math.sqrt(rb.lunge_vx ^ 2 + rb.lunge_vy ^ 2)
	local ux, uy = rb.lunge_vx / len, rb.lunge_vy / len
	local stopped = false
	for _ = 1, steps do
		local nx, ny = self:lunge_step(rb, mx / steps, my / steps)
		if not nx then
			stopped = true
			break
		end
		rb.x, rb.y = nx, ny
		-- colpito chi tocca col corpo o con la lancia
		local cx, cy = rb.x, rb.y + M.DISEGNO_H / 2
		for _, other in ipairs(self.robots) do
			if other ~= rb and not other.dead and not rb.lunge_hit[other.id]
				and (self:robot_at(rb.x, rb.y, rb) == other
					or seg_hits_robot(other, cx, cy, cx + ux * C.LUNGE.reach, cy + uy * C.LUNGE.reach, 2)) then
				rb.lunge_hit[other.id] = true
				self:emit({ type = "lunge_hit", robot = rb.id, target = other.id, x = other.x, y = other.y + M.HURT_Y })
				self:hurt(other, C.LUNGE.damage, rb)
			end
		end
	end
	rb.lunge = rb.lunge - 1
	if stopped or rb.lunge <= 0 then
		-- lo slancio che resta: oltre un bordo si vola, contro il terreno ci si ferma
		local keep = stopped and 0 or C.LUNGE.keep
		rb.vx, rb.vy = rb.lunge_vx * keep, rb.lunge_vy * keep
		rb.lunge, rb.lunge_hit, rb.lunge_vx, rb.lunge_vy = nil, nil, nil, nil
		rb.fall_top = nil
	end
	if rb.y < -20 or rb.x < -20 or rb.x > M.WORLD_W + 20 then self:kill(rb, "fell") end
end

-- Colpi di mischia alla Blastron ---------------------------------------------------

-- Il rettangolo che colpisce al tick t, in pixel del mondo: asse e mezza larghezza
function M.melee_blade(rb, colpo, t, base, dir)
	local p = M.melee_pose(colpo, t)
	local u = M.BLASTRON_UNIT
	local c, s = math.cos(base), math.sin(base)
	local ox, oy = p[1], p[2]
	local x0, y0 = ox + c * p[3] - s * p[4], oy + s * p[3] + c * p[4]
	local x1, y1 = ox + c * p[5] - s * p[6], oy + s * p[5] + c * p[6]
	return rb.x + dir * x0 * u, rb.y + y0 * u, rb.x + dir * x1 * u, rb.y + y1 * u, colpo.mezza_larghezza * u
end

-- Avanza di un tick il colpo che al tick t è nella posa t. Chi la lama tocca
-- mentre la finestra è aperta viene segnato; quando si chiude riceve il colpo.
-- Restituisce false quando il colpo è finito.
local MELEE_SUBSTEPS = 6
function M:update_melee(rb, colpo, t, base, dir)
	local f0, f1 = t * colpo.fps / 60, (t + 1) * colpo.fps / 60
	local hit = rb.melee_hit or {}
	rb.melee_hit = hit
	if t == 0 then for k in pairs(hit) do hit[k] = nil end end
	if f1 >= colpo.apri and f0 <= colpo.chiudi then
		-- più passi per tick: alla fine la lama gira veloce e potrebbe saltare un bersaglio
		for s = 1, MELEE_SUBSTEPS do
			local ts = t + s / MELEE_SUBSTEPS
			local f = ts * colpo.fps / 60
			if f >= colpo.apri and f <= colpo.chiudi then
				local x0, y0, x1, y1, w = M.melee_blade(rb, colpo, ts, base, dir)
				for _, other in ipairs(self.robots) do
					if other ~= rb and not other.dead and not hit[other.id]
						and seg_hits_robot(other, x0, y0, x1, y1, w) then
						hit[other.id] = true
					end
				end
			end
		end
	end
	if colpo.salto and f0 < colpo.salto and f1 >= colpo.salto then
		rb.vy, rb.grounded = M.PUNCH_HOP, false
	end
	if f0 < colpo.chiudi and f1 >= colpo.chiudi then
		for _, other in ipairs(self.robots) do
			if hit[other.id] then
				hit[other.id] = nil
				if not other.dead then
					if colpo == mischia.fendente then self:sword_hit(rb, other) else self:punch_hit(rb, other, dir) end
				end
			end
		end
	end
	return t + 1 < M.melee_ticks(colpo)
end

-- Pugno del Titano --------------------------------------------------------------

function M:start_punch(angle)
	local rb = self.robots[self.current]
	rb.punch_base, rb.facing = aim_side(angle)
	rb.punch_dir = rb.facing
	rb.punch = 0
	self:emit({ type = "punch", robot = rb.id })
end

function M:punch_hit(rb, other, dir)
	self:emit({ type = "punch_hit", robot = rb.id, target = other.id, x = other.x, y = other.y + M.HURT_Y })
	local k = self:knock_mul(other)
	other.vx, other.vy = dir * M.PUNCH_PUSH * k, M.PUNCH_LAUNCH * k
	other.fall_top = nil
	other.grounded, other.knocked = false, true
	if self:hurt(other, M.PUNCH_DAMAGE, rb) > 0 then self:hit_status(other, "punch", rb) end
end

function M:update_punch(rb)
	if M.PUNCH_MODEL == "blastron" then
		if self:update_melee(rb, mischia.montante, rb.punch, rb.punch_base, rb.punch_dir) then
			rb.punch = rb.punch + 1
		else
			rb.punch, rb.punch_dir, rb.punch_base = nil, nil, nil
		end
		return
	end
	rb.punch = rb.punch + 1
	if rb.punch == M.PUNCH_HIT_TICK then
		local dir = rb.punch_dir
		for _, other in ipairs(self.robots) do
			if other ~= rb and not other.dead then
				local dx, dy = (other.x - rb.x) * dir, other.y - rb.y
				if dx >= -4 and dx <= M.PUNCH_REACH and dy > -M.ROBOT_H and dy < M.ROBOT_H + 8 then
					self:punch_hit(rb, other, dir)
				end
			end
		end
		-- il montante solleva anche chi colpisce
		rb.vy, rb.grounded = M.PUNCH_HOP, false
	end
	if rb.punch >= M.PUNCH_TICKS then
		rb.punch, rb.punch_dir = nil, nil
	end
end

-- Oggetti che cadono: casse, trappole, trampolini ---------------------------------

-- Il fondo largo 2 * hw di un oggetto con la base in (x, y) tocca il terreno?
function M:object_collides(x, y, hw)
	local t, c = self.terrain, M.CELL
	local cy = math.floor(y / c)
	for cx = math.floor((x - hw + 1) / c), math.floor((x + hw - 1) / c) do
		if t:get(cx, cy) ~= 0 then return true end
	end
	return false
end

-- Fa cadere o.y fino al terreno (anche dopo, se un'esplosione scava sotto),
-- al massimo a velocità max_fall. Restituisce true se è appoggiato.
function M:fall(o, hw, max_fall)
	if self:object_collides(o.x, o.y - 0.5, hw) then
		o.vy = 0
		return true
	end
	o.vy = math.max(o.vy - M.GRAVITY * M.DT, -max_fall)
	local my = o.vy * M.DT
	local steps = math.max(1, math.ceil(-my / M.CELL))
	for _ = 1, steps do
		local ny = o.y + my / steps
		if self:spring(o, ny, hw) then return false end
		if self:object_collides(o.x, ny, hw) then
			-- risalendo dal trampolino si ripassa da dove si è scesi: qui
			-- c'è solo un cratere richiuso, ci si ferma
			if my > 0 then
				o.vy = 0
				return false
			end
			-- appoggiato sul bordo della cella sotto
			o.y = (math.floor(ny / M.CELL) + 1) * M.CELL
			o.vy = 0
			return true
		end
		o.y = ny
	end
	return false
end

-- Casse --------------------------------------------------------------------------

-- Cosa c'è nella cassa: a caso secondo i pesi di config.CRATE_CONTENTS
function M:crate_content()
	local total = 0
	for _, c in ipairs(C.CRATE_CONTENTS) do total = total + c[2] end
	local r = self.rng:next() * total
	for _, c in ipairs(C.CRATE_CONTENTS) do
		r = r - c[2]
		if r < 0 then return c[1] end
	end
	return C.CRATE_CONTENTS[#C.CRATE_CONTENTS][1]
end

-- Sceglie un punto a caso sulla superficie, lontano dai robot e dalle altre
-- casse, e fa cadere lì una cassa dal cielo. Usa il generatore della partita,
-- così server e client la mettono nello stesso posto.
function M:spawn_crate()
	if #self.crates >= M.CRATE_MAX then return nil end
	local weapon = self:crate_content()
	local hw = M.CRATE_HALF_W
	local x, gy = self:surface_spot(function(x, gy)
		if self:robot_collides(x, gy) or self:object_collides(x, gy, hw) or self:object_collides(x, gy + M.CRATE_H, hw) then
			return false
		end
		for _, rb in ipairs(self.robots) do
			if not rb.dead and math.abs(rb.x - x) < 60 then return false end
		end
		for _, c in ipairs(self.crates) do
			if math.abs(c.x - x) < 40 then return false end
		end
		return true
	end)
	if not x then return nil end
	self.crate_id = self.crate_id + 1
	local c = { id = self.crate_id, x = x, y = M.WORLD_H + 20, vy = 0, landed = false, weapon = weapon }
	self.crates[#self.crates + 1] = c
	self:emit({ type = "crate", id = c.id, x = x, y = gy })
	return c
end

function M:update_crates()
	local i = 1
	while i <= #self.crates do
		local c = self.crates[i]
		c.landed = self:fall(c, M.CRATE_HALF_W, M.CRATE_FALL)
		local taken = false
		for _, rb in ipairs(self.robots) do
			if not rb.dead and not taken
				and math.abs(rb.x - c.x) <= M.ROBOT_HALF_W + M.CRATE_HALF_W
				and rb.y < c.y + M.CRATE_H and rb.y + M.ROBOT_H > c.y then
				rb.ammo[c.weapon] = rb.ammo[c.weapon] + 1
				rb.crates = rb.crates + 1
				self:emit({ type = "crate_pick", id = c.id, robot = rb.id, weapon = c.weapon })
				taken = true
			end
		end
		if taken or c.y < -20 then
			if not taken then self:emit({ type = "crate_lost", id = c.id }) end
			table.remove(self.crates, i)
		else
			i = i + 1
		end
	end
end

-- Oggetti tattici ----------------------------------------------------------------

-- Quanto viene spinto rb: meno con lo scudo
function M:knock_mul(rb)
	local k = rb.stats.knockback_mul
	if rb.shield then k = k * C.SHIELD.knockback end
	return k
end

-- Cerchi di cura (config.HEAL) ------------------------------------------------

-- Un cerchio in un punto a caso della superficie, lontano dagli altri cerchi
-- (anche sotto un robot: va curato lui, o spinto via)
function M:spawn_heal()
	if #self.heals >= C.HEAL.max then return nil end
	local x, gy = self:surface_spot(function(x)
		for _, h in ipairs(self.heals) do
			if math.abs(h.x - x) < 4 * C.HEAL.r then return false end
		end
		return true
	end)
	if not x then return nil end
	self.heal_id = self.heal_id + 1
	local h = { id = self.heal_id, x = x, y = gy }
	self.heals[#self.heals + 1] = h
	self:emit({ type = "heal_spawn", id = h.id, x = x, y = gy })
	return h
end

-- A fine turno: chi ha i piedi in un cerchio si cura, e il cerchio che ha
-- curato qualcuno sparisce
function M:apply_heals()
	local r2 = C.HEAL.r * C.HEAL.r
	local i = 1
	while i <= #self.heals do
		local h, used = self.heals[i], false
		for _, rb in ipairs(self.robots) do
			local dx, dy = rb.x - h.x, rb.y - h.y
			if not rb.dead and dx * dx + dy * dy <= r2 and rb.hp < rb.max_hp then
				local amount = math.min(C.HEAL.hp, rb.max_hp - rb.hp)
				rb.hp = rb.hp + amount
				used = true
				self:emit({ type = "heal", id = h.id, robot = rb.id, amount = amount })
			end
		end
		if used then
			table.remove(self.heals, i)
			self:emit({ type = "heal_gone", id = h.id })
		else
			i = i + 1
		end
	end
end

-- Il robot di turno usa un oggetto (già controllato con can_use)
-- fire (angolo e potenza) serve agli oggetti lanciati
function M:use_tool(kind, fire)
	local rb = self.robots[self.current]
	if kind == "parachute" then
		-- aperto si chiude (gratis), chiuso si apre
		if rb.parachute then
			rb.parachute = false
			self:emit({ type = "parachute_close", robot = rb.id })
			return
		end
		rb.parachutes_left = rb.parachutes_left - 1
		rb.parachute = true
		self:emit({ type = "parachute", robot = rb.id })
		return
	end
	if kind == "hook" or kind == "wall" then
		-- un attrezzo per turno
		self.used.tool = true
		if kind == "hook" then self:fire_hook(fire.angle) else self:fire_wall(fire.angle, fire.power) end
		return
	end
	rb.ammo[kind] = rb.ammo[kind] - 1
	if kind == "shield" then
		rb.shield, rb.parried = C.SHIELD.hp, 0
		self:emit({ type = "shield", robot = rb.id })
		return
	end
	-- la trappola si posa ai piedi, il trampolino si lancia come l'Uovo
	self.placed_id = self.placed_id + 1
	local o = { id = self.placed_id, kind = kind, x = rb.x, y = rb.y, vy = 0, owner = rb.id, team = rb.team,
		armed = false, r = kind == "trap" and rb.stats.trap_radius or C.TRAMPOLINE.half_w, age = 0 }
	if kind == "trampoline" then
		o.x, o.y = muzzle(rb, fire.angle)
		o.vx, o.vy = launch_velocity(fire.angle, fire.power, M.GRENADE_SPEED)
		o.flying = true
	end
	self.placed[#self.placed + 1] = o
	if #self.placed > C.MAX_PLACED then
		-- troppi: sparisce il più vecchio
		self:emit({ type = "placed_gone", id = self.placed[1].id })
		table.remove(self.placed, 1)
	end
	if not o.flying then self:emit({ type = "place", id = o.id, kind = kind, robot = rb.id, x = o.x, y = o.y }) end
end

-- Il robot ha i piedi sopra l'oggetto o?
local function on_top(rb, o)
	return math.abs(rb.x - o.x) <= M.ROBOT_HALF_W + o.r and rb.y >= o.y - 2 and rb.y <= o.y + 6
end

-- Il trampolino in volo, come l'Uovo: si ferma dove tocca il terreno, o ai
-- piedi del robot che colpisce
function M:fly_placed(o)
	o.age = o.age + 1
	o.vy = o.vy - M.GRAVITY * M.GRENADE_GRAVITY * M.DT
	local mx, my = o.vx * M.DT, o.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	for _ = 1, steps do
		local nx, ny = o.x + mx / steps, o.y + my / steps
		local hit = self:body_hits_robot(o, nx, ny, M.GRENADE_R)
		if hit then
			o.x, o.y, o.flying = hit.x, hit.y, false
			break
		elseif self:spring(o, ny, M.GRENADE_R) then
			break
		elseif self.terrain:solid(nx, ny) then
			o.flying = false
			break
		end
		o.x, o.y = nx, ny
	end
	if not o.flying then
		o.vx, o.vy = nil, 0
		self:emit({ type = "place", id = o.id, kind = o.kind, robot = o.owner, x = o.x, y = o.y })
	end
end

-- Velocità del rimbalzo di b (robot o corpo) sul trampolino o: sempre, ma
-- restandoci sopra ogni volta più bassa. nil se i rimbalzi sono finiti.
local function spring_vy(b, o)
	local tr = C.TRAMPOLINE
	local chain = b.bounced_on == o.id and (b.bounces or 0) or 0
	local vy = tr.launch_vy * tr.decay ^ chain
	if vy < tr.min_vy then return nil end
	b.bounced_on, b.bounces = o.id, chain + 1
	return vy
end

-- Rimbalzo di un robot sul trampolino
function M:bounce(rb, o)
	local vy = spring_vy(rb, o)
	if not vy then return end
	rb.vy, rb.grounded, rb.rising, rb.knocked, rb.fall_top = vy, false, false, false, nil
	-- il trampolino di un avversario ti lancia: se cadi l'uccisione è sua
	self:credit(rb, self.robots[o.owner])
	self:emit({ type = "bounce", id = o.id, robot = rb.id })
end

-- Un corpo largo 2 * r (colpo, Uovo, globo, cassa, oggetto) che scendendo
-- verso ny passa la tavola di un trampolino ci rimbalza: torna sulla tavola e
-- riparte in alto. Restituisce true se è rimbalzato.
function M:spring(b, ny, r)
	if b.vy >= 0 then return false end
	local top = C.TRAMPOLINE.top
	for _, o in ipairs(self.placed) do
		if o.kind == "trampoline" and o ~= b and not o.flying and b.y >= o.y + top and ny < o.y + top
			and math.abs(b.x - o.x) <= o.r + r then
			local vy = spring_vy(b, o)
			if not vy then return false end
			b.y, b.vy = o.y + top, vy
			self:emit({ type = "bounce", id = o.id, x = b.x, y = b.y })
			return true
		end
	end
	return false
end

function M:update_placed()
	local i = 1
	while i <= #self.placed do
		local o = self.placed[i]
		if o.flying then
			self:fly_placed(o)
		else
			self:fall(o, o.r, M.CRATE_FALL)
		end
		local gone = o.y < -20 or o.x < -300 or o.x > M.WORLD_W + 300
		for _, rb in ipairs(self.robots) do
			if not gone and not o.flying and not rb.dead and on_top(rb, o) and rb.vy <= 0 then
				if o.kind == "trampoline" then
					self:bounce(rb, o)
				elseif o.armed and rb.team ~= o.team then
					-- la trappola lancia in alto e lontano dal suo centro, poi sparisce
					local dir = rb.x > o.x and 1 or (rb.x < o.x and -1 or -rb.facing)
					local k = self:knock_mul(rb)
					rb.vx, rb.vy = dir * C.TRAP.push_vx * k, C.TRAP.launch_vy * k
					rb.grounded, rb.knocked, rb.fall_top = false, true, nil
					self:emit({ type = "trap", id = o.id, robot = rb.id, x = o.x, y = o.y })
					local owner = self.robots[o.owner]
					if self:hurt(rb, C.TRAP.damage, owner) > 0 and owner and enemies(owner, rb) then
						self:add_points(owner, self.score.trap, "trap", rb)
					end
					gone = true
				end
			end
		end
		if gone then
			if o.kind ~= "trap" or o.y < -20 then self:emit({ type = "placed_gone", id = o.id }) end
			table.remove(self.placed, i)
		else
			i = i + 1
		end
	end
	-- chi tocca terra fuori dal trampolino ci rimbalza di nuovo alto
	for _, rb in ipairs(self.robots) do
		if rb.bounced_on and rb.grounded then
			local still = false
			for _, o in ipairs(self.placed) do
				if o.id == rb.bounced_on and on_top(rb, o) then still = true end
			end
			if not still then rb.bounced_on, rb.bounces = nil, nil end
		end
	end
end

-- Il robot può usare quest'arma? Le armi delle casse hanno colpi contati.
function M.has_weapon(rb, weapon)
	if M.SECONDARY[weapon] then return weapon == "sword" or weapon == rb.secondary end
	if M.FREE_WEAPONS[weapon] then return true end
	return (rb.ammo[weapon] or 0) > 0
end

-- Punti della traiettoria prevista, per la linea di mira.
-- pts (facoltativo) è una tabella da riusare, per non allocare a ogni frame.
-- weapon (facoltativo): "grenade" e "shards" volano diversamente dal missile.
function M:preview(angle, power, count, every, pts, weapon)
	local rb = self.robots[self.current]
	local x, y = muzzle(rb, angle)
	local vx, vy = launch_velocity(angle, power, M.MISSILE_SPEED)
	local gravity = M.GRAVITY * M.MISSILE_GRAVITY
	if weapon == "grenade" or weapon == "trampoline" then
		vx, vy = launch_velocity(angle, power, M.GRENADE_SPEED)
		gravity = M.GRAVITY * M.GRENADE_GRAVITY
	elseif weapon == "teleport" then
		vx, vy = launch_velocity(angle, power, M.ORB_SPEED)
		gravity = M.GRAVITY * M.ORB_GRAVITY
	elseif weapon == "shards" then
		vx, vy = math.cos(angle) * M.SHARD_SPEED, math.sin(angle) * M.SHARD_SPEED
		gravity = M.GRAVITY * M.SHARD_GRAVITY
	elseif weapon == "sniper" then
		return self:sniper_preview(x, y, angle, count, pts)
	elseif weapon == "wall" then
		return self:wall_preview(angle, power, count, pts)
	elseif weapon == "eagle" or weapon == "hook" then
		return self:ray_preview(x, y, angle, (weapon == "eagle" and C.EAGLE or C.HOOK).range, count, pts)
	elseif weapon == "lunge" then
		-- lo scatto: dal centro del robot, lungo quanto l'Affondo
		return self:ray_preview(rb.x, rb.y + M.DISEGNO_H / 2, angle, C.LUNGE.speed * C.LUNGE.ticks / 60, count, pts)
	end
	pts = pts or {}
	local n = 0
	for i = 1, count * every do
		vy = vy - gravity * M.DT
		x, y = x + vx * M.DT, y + vy * M.DT
		if i % every == 0 then
			n = n + 1
			local pt = pts[n] or {}
			pt.x, pt.y = x, y
			pts[n] = pt
		end
	end
	return pts
end

function M:hits_robot(x, y, owner, age)
	for _, rb in ipairs(self.robots) do
		if not rb.dead and (rb.id ~= owner or age > M.OWNER_SAFE_TICKS) and M.hurt_at(rb, x, y, 0) then
			return true
		end
	end
	return false
end

-- owner (facoltativo) è chi ha sparato, per contare i danni inflitti.
-- blast (facoltativo) dice quanto è grande: MISSILE_BLAST se manca.
-- weapon (facoltativo) è l'arma, per l'effetto di stato che porta.
function M:explode(x, y, owner, blast, weapon)
	blast = blast or M.MISSILE_BLAST
	local cy0, cy1 = self.terrain:carve(x, y, blast.r)
	self:emit({ type = "explosion", x = x, y = y, r = blast.r, row_min = cy0, row_max = cy1 })
	self:blast(x, y, owner, blast, weapon)
end

-- L'esplosione, senza il cratere: fa saltare trappole e trampolini vicini,
-- colpisce e spinge i robot
function M:blast(x, y, owner, blast, weapon)
	-- trappole e trampolini nel cratere saltano
	for i = #self.placed, 1, -1 do
		local o = self.placed[i]
		local ox, oy = o.x - x, o.y - y
		if ox * ox + oy * oy <= (blast.r + 6) * (blast.r + 6) then
			table.remove(self.placed, i)
			self:emit({ type = "placed_gone", id = o.id })
		end
	end
	for _, rb in ipairs(self.robots) do
		if not rb.dead then
			local dmg, vx, vy = self:blast_on(rb, x, y, blast, owner)
			if dmg then
				rb.vx, rb.vy = vx, vy
				rb.grounded = false
				rb.knocked = true
				local by = owner and self.robots[owner]
				if self:hurt(rb, dmg, by) > 0 and weapon and by ~= rb then self:hit_status(rb, weapon, by) end
			end
		end
	end
end

-- Cosa fa a rb l'esplosione blast in (x, y) di owner: il danno (prima dello
-- scudo) e la velocità con cui parte, o nil se è fuori portata. Non cambia
-- niente: lo usano explode e il bot (sim/bot.lua) per prevedere un colpo.
function M:blast_on(rb, x, y, blast, owner)
	local blastron = M.KNOCKBACK_MODEL == "blastron"
	local dx, dy
	if blastron then
		-- verso il punto della scatola del robot più vicino all'esplosione
		-- (col cerchio, il quadrato che lo contiene)
		local hw, y0, y1 = M.ROBOT_HALF_W, rb.y, rb.y + M.ROBOT_H
		if M.HURTBOX == "cerchio" then
			hw = M.HURT_R + M.HURT_FAT
			y0, y1 = rb.y + M.HURT_Y - hw, rb.y + M.HURT_Y + hw
		end
		dx = math.max(rb.x - hw, math.min(rb.x + hw, x)) - x
		dy = math.max(y0, math.min(y1, y)) - y
	else
		dx, dy = rb.x - x, (rb.y + M.HURT_Y) - y
	end
	local d = math.sqrt(dx * dx + dy * dy)
	if d >= blast.damage_r then return nil end
	local f = 1 - d / blast.damage_r
	local dmin = blast.damage_min or 0
	local dmg = dmin + (blast.damage - dmin) * f
	if owner == rb.id then dmg = dmg * M.SELF_DAMAGE end
	dmg = math.floor(dmg + 0.5)
	local k = self:knock_mul(rb)
	if blastron then
		-- la velocità viene sostituita; senza impulse, uno con la
		-- stessa spinta massima del modello "centro"
		local imp = (blast.impulse or 4 * blast.knockback / blast.damage_r) * k
		return dmg, dx * imp * f, dy * imp * f
	end
	if d < 1 then dx, dy, d = 0, 1, 1 end
	return dmg, dx / d * blast.knockback * f * k, (dy / d * blast.knockback * f + 120 * f) * k
end

function M:update_projectile()
	local p = self.projectile
	if p.kind == "grenade" then return self:update_grenade(p) end
	if p.kind == "sniper" then return self:update_sniper(p) end
	p.age = p.age + 1
	p.vy = p.vy - M.GRAVITY * M.MISSILE_GRAVITY * M.DT
	local mx, my = p.vx * M.DT, p.vy * M.DT
	local steps = math.max(1, math.ceil(math.max(math.abs(mx), math.abs(my)) / M.CELL))
	for _ = 1, steps do
		if self:spring(p, p.y + my / steps, 0) then break end
		p.x = p.x + mx / steps
		p.y = p.y + my / steps
		if self.terrain:solid(p.x, p.y) or self:hits_robot(p.x, p.y, p.owner, p.age) then
			self:explode(p.x, p.y, p.owner, nil, "missile")
			self.projectile = nil
			return
		end
	end
	if p.y < -50 or p.x < -300 or p.x > M.WORLD_W + 300 then
		self:emit({ type = "miss" })
		self.projectile = nil
	end
end

-- Turni ------------------------------------------------------------------------

function M:start_turn(player)
	self.current = player
	self.phase = "aim"
	self.timer = M.TURN_TICKS
	self.window = 0
	-- attacchi già fatti nel turno (al massimo un'arma e un colpo di spada) e l'attrezzo, uno a turno
	self.used = { primary = false, secondary = false, tool = false }
	self.teleports = 0
	local rb = self.robots[player]
	rb.turns = rb.turns + 1
	-- lo scudo dura fino all'inizio del proprio turno dopo
	if rb.shield then
		rb.shield = nil
		self:emit({ type = "shield_end", robot = rb.id })
	end
	-- le trappole posate prima di questo turno sono armate
	for _, o in ipairs(self.placed) do o.armed = true end
	self:emit({ type = "turn", robot = player })
	-- chi brucia prende danno all'inizio del turno (l'uccisione va a chi l'ha bruciato)
	local burn = rb.status.burn
	if burn then self:hurt(rb, C.STATUS.burn.damage, burn.by and self.robots[burn.by], "burn") end
	-- dopo ogni crate_every turni cade una cassa
	self.turn_no = self.turn_no + 1
	if self.turn_no > 1 then
		if self.crate_chance then
			local chance = self.crate_chance[#self.crates + 1] or 0
			if self.rng:next() < chance then self:spawn_crate() end
		elseif (self.turn_no - 1) % self.crate_every == 0 then
			self:spawn_crate()
		end
	end
	if self.turn_no % C.HEAL.every == 0 then self:spawn_heal() end
end

-- Il robot di turno può usare weapon adesso? "teleport", "sword", un'arma o un
-- oggetto. Un'arma e un colpo di spada per turno, fino all'ultimo tick. Il
-- teletrasporto consuma un globo (rb.teleports_left) e, come gli oggetti, si
-- lancia in qualsiasi momento del turno.
function M:can_use(weapon)
	if self.phase ~= "aim" then return false end
	local rb = self.robots[self.current]
	if rb.dead then return false end
	if weapon == "parachute" then
		-- solo in aria
		if rb.grounded then return false end
		return rb.parachute or rb.parachutes_left > 0
	elseif weapon == "hook" or weapon == "wall" then
		return rb.tool == weapon and not self.used.tool
	elseif weapon == "shield" then
		return not rb.shield and rb.ammo.shield > 0
	elseif M.TOOLS[weapon] then
		return rb.ammo[weapon] > 0
	end
	if weapon == "teleport" then
		return #self.orbs < M.MAX_ORBS and rb.teleports_left > 0
			and (rb.turns > 1 or self.teleports < C.FIRST_TURN_TELEPORTS)
	elseif M.SECONDARY[weapon] then
		return not self.used.secondary and M.has_weapon(rb, weapon)
	end
	return not self.used.primary and M.has_weapon(rb, weapon)
end

-- Il robot di turno attacca con weapon (già controllata con can_use)
function M:attack(weapon, fire)
	local rb = self.robots[self.current]
	local first = not (self.used.primary or self.used.secondary)
	if M.SECONDARY[weapon] then self.used.secondary = true else self.used.primary = true end
	if not M.FREE_WEAPONS[weapon] then rb.ammo[weapon] = rb.ammo[weapon] - 1 end
	if weapon == "sword" then
		self:swing_sword(fire.angle)
	elseif weapon == "eagle" then
		self:fire_eagle(fire.angle)
	elseif weapon == "mallet" then
		self:start_mallet(fire.angle)
	elseif weapon == "lunge" then
		self:start_lunge(fire.angle)
	else
		if weapon == "punch" then
			self:start_punch(fire.angle)
		elseif weapon == "grenade" then
			self:throw_grenade(fire.angle, fire.power)
		elseif weapon == "shards" then
			self:fire_shards(fire.angle)
		elseif weapon == "sniper" then
			self:fire_sniper(fire.angle)
		else
			self:fire(fire.angle, fire.power)
		end
	end
	if first then
		rb.attack_ticks = rb.attack_ticks + M.TURN_TICKS - self.timer
		rb.attack_turns = rb.attack_turns + 1
		-- i secondi rimasti diventano globi del teletrasporto
		local gain = rb.stats.time_orbs > 0 and math.floor(self.timer / (60 * C.TELEPORT_SECONDS)) or 0
		if gain > 0 then
			rb.teleports_left = rb.teleports_left + gain
			self:emit({ type = "teleports", robot = rb.id, amount = gain, total = rb.teleports_left })
		end
		self.window = math.min(self.timer, M.AFTER_ATTACK_TICKS)
	end
end

-- Risultati della partita, anche a metà: la classifica per punti della
-- squadra (a parità, dei robot). place è il posto della squadra: i compagni
-- hanno lo stesso, chi ha gli stessi punti pure.
-- { mode, winner = squadra o nil se pari, ranking = { { robot, team, place, points, ... } } }
function M:results()
	local team_points = {}
	for _, rb in ipairs(self.robots) do team_points[rb.team] = (team_points[rb.team] or 0) + rb.points end
	local list = {}
	for i, rb in ipairs(self.robots) do list[i] = rb end
	table.sort(list, function(a, b)
		local ta, tb = team_points[a.team], team_points[b.team]
		if ta ~= tb then return ta > tb end
		if a.team ~= b.team then return a.team < b.team end
		if a.points ~= b.points then return a.points > b.points end
		return a.id < b.id
	end)
	local ranking, place, last_team = {}, 0, nil
	for i, rb in ipairs(list) do
		if rb.team ~= last_team then
			-- squadra nuova: scende di posto solo se ha meno punti della precedente
			if not last_team or team_points[rb.team] < team_points[last_team] then place = place + 1 end
			last_team = rb.team
		end
		ranking[i] = {
			robot = rb.id, team = rb.team, place = place, points = math.floor(rb.points + 0.5), alive = not rb.dead,
			damage = rb.damage, kills = rb.kills, env_kills = rb.env_kills, deaths = rb.deaths, falls = rb.falls,
			turns = rb.turns, teleports = rb.teleports, crates = rb.crates,
			avg_attack_secs = rb.attack_turns > 0 and math.floor(rb.attack_ticks / rb.attack_turns / 6 + 0.5) / 10 or 0,
		}
	end
	local first, second = ranking[1], nil
	for _, r in ipairs(ranking) do
		if r.team ~= first.team then second = r break end
	end
	local winner = first.team
	if second and second.place == first.place then winner = nil end
	return { mode = self.mode, normalized = self.normalized, winner = winner, ranking = ranking }
end

-- Impronta dello stato: un numero che cambia se cambia qualcosa che conta
-- (tick, turno, caso, robot, colpi in volo). Due partite rigiocate con la
-- stessa ricetta devono avere le stesse impronte (sim/replay.lua): è il
-- controllo del determinismo, tra client e server e tra versioni.
local IMPRONTA_MOD = 2147483629
local function mescola(h, v)
	return (h * 31 + math.floor(v) % IMPRONTA_MOD) % IMPRONTA_MOD
end
function M:impronta()
	local h = mescola(mescola(mescola(7, self.tick), self.current), self.rng.state)
	for _, rb in ipairs(self.robots) do
		h = mescola(h, rb.x * 16)
		h = mescola(h, rb.y * 16)
		h = mescola(h, rb.hp * 16)
		h = mescola(h, rb.points * 16)
		h = mescola(h, rb.dead and 1 or 0)
	end
	local p = self.projectile
	if p then h = mescola(mescola(h, p.x * 16), p.y * 16) end
	h = mescola(h, #self.orbs)
	h = mescola(h, #self.placed)
	return h
end

-- La partita finisce solo allo scadere del tempo, e solo a fine giro: chi ha
-- cominciato per primo non gioca un turno in più degli altri.
function M:end_turn()
	self:apply_heals()
	self:age_status(self.robots[self.current])
	local next_pos = self.order_pos % #self.order + 1
	if self.match_left <= 0 and next_pos == 1 then
		self.phase = "over"
		local res = self:results()
		self.winner = res.winner
		self:emit({ type = "over", winner = res.winner, reason = "time", results = res })
		return
	end
	self.order_pos = next_pos
	self:start_turn(self.order[self.order_pos])
end

-- Un tick del mondo: robot, globi, colpi, casse, oggetti. Solo il robot di
-- turno riceve input, se can_move. Lo usa anche il bot (sim/bot.lua) sulle
-- sue copie della partita, per provare le mosse.
function M:advance(input, can_move)
	for i, rb in ipairs(self.robots) do
		local active = i == self.current and can_move
		self:update_robot(rb, active and input or NO_INPUT, active)
	end
	-- prima il teletrasporto, poi la spada: il fendente colpisce già dalla nuova posizione
	if #self.orbs > 0 then self:update_orbs() end
	for _, rb in ipairs(self.robots) do
		if rb.swing then
			if rb.dead then rb.swing, rb.swing_hit = nil, nil else self:update_swing(rb) end
		end
		if rb.punch then
			if rb.dead then rb.punch, rb.punch_dir = nil, nil else self:update_punch(rb) end
		end
		if rb.mallet then
			if rb.dead then rb.mallet, rb.mallet_dir, rb.mallet_stop = nil, nil, nil else self:update_mallet(rb) end
		end
		if rb.dead then rb.lunge, rb.lunge_hit, rb.hooked, rb.recoil = nil, nil, nil, nil end
	end
	if self.projectile then self:update_projectile() end
	if self.burst then self:update_burst() end
	self:update_shards()
	if #self.crates > 0 then self:update_crates() end
	if #self.placed > 0 then self:update_placed() end
end

function M:step(input)
	if self.phase == "over" then return end
	input = input or NO_INPUT
	self.tick = self.tick + 1
	if self.match_left > 0 then
		self.match_left = self.match_left - 1
		if self.match_left == 0 then
			self.overtime = true
			self:emit({ type = "overtime" })
		end
	end
	-- chi è morto ricomincia dopo RESPAWN_TICKS, anche a metà turno
	for _, rb in ipairs(self.robots) do
		if rb.dead and rb.respawn_in then
			rb.respawn_in = rb.respawn_in - 1
			if rb.respawn_in <= 0 then self:respawn(rb) end
		end
	end

	-- il robot di turno si muove per tutto il turno, anche dopo gli attacchi
	self:advance(input, self.phase == "aim")

	if self.phase == "aim" then
		self.timer = math.max(0, self.timer - 1)
		local done = false
		if self.window > 0 then
			self.window = self.window - 1
			done = self.window == 0
		end
		local fire = input.fire
		local weapon = fire and fire.weapon or "missile"
		if not done and fire and self:can_use(weapon) then
			if M.TOOLS[weapon] then
				self:use_tool(weapon, fire)
			elseif weapon == "teleport" then
				-- il globo non è un attacco: consuma un teletrasporto e il turno continua
				local rb = self.robots[self.current]
				rb.teleports_left = rb.teleports_left - 1
				rb.teleports = rb.teleports + 1
				self.teleports = self.teleports + 1
				self:throw_orb(fire.angle, fire.power)
			else
				self:attack(weapon, fire)
			end
		end
		-- turno finito: chi mira perde il colpo. Chi muore nel suo turno
		-- ricomincia e continua; allo scadere della partita il turno si finisce.
		if done or self.timer <= 0 then
			self.window = 0
			self.phase, self.settle, self.settle_total = "settle", 0, 0
		end
	elseif self.phase == "settle" then
		-- si aspetta che colpi, globi e robot si fermino
		self.settle_total = self.settle_total + 1
		local still = #self.orbs == 0 and not self.projectile and not self:shards_flying()
		for _, o in ipairs(self.placed) do
			if o.flying then still = false end
		end
		for _, rb in ipairs(self.robots) do
			if not rb.dead and (not rb.grounded or rb.swing or rb.punch or rb.lunge or rb.recoil or rb.hooked or rb.mallet) then still = false end
		end
		self.settle = still and self.settle + 1 or 0
		if self.settle >= M.SETTLE_TICKS or self.settle_total >= M.MAX_SETTLE_TICKS then
			self:end_turn()
		end
	end
end

-- Profili di fisica -------------------------------------------------------------
-- "megablast": i valori decisi finora, quelli scritti sopra.
-- "blastron": ricostruiti dall'APK di Blastron (docs/blastron.md). Le misure
-- là sono in unità di Farseer, qui diventano pixel in proporzione al robot:
-- il robot di Blastron è alto 3,612 unità, il nostro BLASTRON_ROBOT_H pixel
-- (28: 1,4 volte i 20 di prima, scelto il 23 ottobre per vedere meglio il
-- personaggio; tutto il resto è in proporzione, quindi la mappa sembra più piccola).
-- La vita là partiva da 2000, qui da DAMAGE_BASE: i danni sono riscalati.
M.BLASTRON_ROBOT_H = 28
-- Il diavoletto disegnato è BLASTRON_CORPO volte il robot di Blastron (la
-- capsula per camminare e il cerchio dei colpi, partiti dalla stessa misura,
-- sono in sim/corpo.lua); tutto il resto (salti, armi, casse,
-- esplosioni) resta sulla misura di Blastron. 1,4 scelto il 26 ottobre perché il
-- diavoletto dipinto si legga.
M.BLASTRON_CORPO = 1.4
M.BLASTRON_UNIT = M.BLASTRON_ROBOT_H / 3.612

local function blastron_profile()
	local u = M.BLASTRON_UNIT
	local hp = M.DAMAGE_BASE / 2000
	-- quanto è più grande il robot rispetto a quello del profilo megablast,
	-- per le nostre misure (casse, schegge, globo...)
	local k = M.BLASTRON_ROBOT_H / M.ROBOT_H
	local corpo = M.BLASTRON_CORPO
	return {
		-- capsula per camminare e cerchio dei colpi: sim/corpo.lua (editor delle
		-- animazioni); all'inizio erano BLASTRON_ROBOT_H * corpo di altezza,
		-- ROBOT_HALF_W * k * corpo di mezza larghezza e il cerchio qui sotto
		ROBOT_H = CORPO.cammina.alto,
		ROBOT_HALF_W = CORPO.cammina.largo / 2,
		DISEGNO_H = M.BLASTRON_ROBOT_H * corpo,
		CORPO = corpo,
		MAX_CLIMB = M.MAX_CLIMB * k,
		TELEPORT_SEARCH = M.TELEPORT_SEARCH * k,
		ORB_R = M.ORB_R * k,
		GRENADE_R = M.GRENADE_R * k,
		ORB_NUDGE = M.ORB_NUDGE * k,
		CRATE_HALF_W = M.CRATE_HALF_W * k,
		CRATE_H = M.CRATE_H * k,
		CRATE_FALL = M.CRATE_FALL * k,
		SWORD_REACH = M.SWORD_REACH * k,
		MUZZLE = M.MUZZLE * k,
		SWORD_PIVOT_Y = M.SWORD_PIVOT_Y * k,
		SHARD_SPEED = M.SHARD_SPEED * k,
		SNIPER_SPEED = M.SNIPER_SPEED * k,
		SHARD_BLAST = { r = M.SHARD_BLAST.r * k, damage_r = M.SHARD_BLAST.damage_r * k,
			damage = 11, knockback = M.SHARD_BLAST.knockback * k },
		GRAVITY = 25 * u,
		-- corsa 5 u/s a terra e in aria, salto alto 5,2 u
		DEFAULT_STATS = { walk_speed = 5 * u, jump_height = 5.2 * u, air_speed = 5 * u },
		AIR_CONTROL = "instant",
		CLAMP_ACTIVE_VX = true,
		-- MegaBlast sopra Blastron: corpo a capsula, salto corto, coyote time e
		-- salto in anticipo (pilastri e riferimenti, fase 2 della roadmap)
		ROBOT_ROUND = true,
		JUMP_CUT = 0.45,
		COYOTE_TICKS = 6,
		JUMP_BUFFER_TICKS = 6,
		-- cadere da più di 40 u toglie 15 punti (su 2000) per unità, al massimo 900;
		-- da noi 25 e 1500: i danni sono 5/3 di Blastron (Sergio, 29 ottobre 2026:
		-- "ci vogliono 5 turni per ammazzare qualcuno", tutto deve togliere di più)
		FALL_SAFE = 40 * u,
		FALL_DAMAGE = 25 * hp / u,
		FALL_DAMAGE_MAX = 1500 * hp,
		KNOCKBACK_MODEL = "blastron",
		SELF_DAMAGE = 0.5,
		OWNER_SAFE_TICKS = 30,
		-- Rocket: cratere 5 u, danno e spinta entro 9 u, 150-300 danni, impulso 10
		-- (da noi 250-500, 5/3)
		MISSILE_SPEED = 75 * u,
		MISSILE_GRAVITY = 1.1,
		MISSILE_BLAST = { r = 5 * u, damage_r = 9 * u, damage = 500 * hp, damage_min = 250 * hp, impulse = 10 },
		-- Grenade: rimbalzo 0,4, frenata 1/s dopo il primo urto, scoppia dopo 5 s
		GRENADE_SPEED = 85 * u,
		GRENADE_GRAVITY = 1.3,
		GRENADE_FUSE = 5 * 60,
		GRENADE_BOUNCE = 0.4,
		GRENADE_FRICTION = 1,
		GRENADE_DAMPING = 1,
		-- danno al centro 57 invece di 27,5 (arena dei bot, 29 ottobre 2026: l'Uovo era l'arma più debole),
		-- poi 80 e 25 ai bordi: 5/3 come tutti, ma il centro sotto la vita intera
		-- (Sergio, 29 ottobre 2026: "non ti dico che si deve oneshottare")
		GRENADE_BLAST = { r = 5.5 * u, damage_r = 10 * u, damage = 1600 * hp, damage_min = 500 * hp, impulse = 15 },
		-- Teleport Grenade: non chiude il turno, ti porta lì dopo 3 s
		ORB_SPEED = 80 * u,
		ORB_GRAVITY = 1.1,
		TELEPORT_TICKS = 3 * 60,
		ORB_BOUNCE = 0.4,
		ORB_FRICTION = 1,
		ORB_DAMPING = 1.1,
		-- dove si viene colpiti: il cerchio dei robot di Blastron, raggio 0,523 volte
		-- l'altezza (3,612 × 0,66 × 0,5 × 0,66 × 2,4 = 1,888 u, per BLASTRON_CORPO)
		-- a metà altezza, ora in sim/corpo.lua; per le esplosioni il quadrato
		-- attorno, più largo di 0,1 u per lato
		HURTBOX = "cerchio",
		HURT_R = CORPO.colpi.raggio,
		HURT_Y = CORPO.colpi.centro,
		HURT_FAT = 0.1 * u,
		-- Hanzo Special: fendente sulla mira (sim/mischia.lua), 300 danni (da noi 500), ferma il bersaglio
		SWORD_MODEL = "blastron",
		SWORD_TICKS = 56,
		SWORD_DAMAGE = 500 * hp,
		SWORD_STOP = true,
		-- Flame-Yuken: montante sulla mira, 1000 danni, lancia dritto in alto a
		-- 40 u/s, saltello di 15 u/s
		PUNCH_MODEL = "blastron",
		PUNCH_TICKS = 127,
		PUNCH_DAMAGE = 940 * hp,   -- 28 invece di 50 (arena dei bot, 29 ottobre 2026: vinceva troppo), poi 47 (5/3)
		PUNCH_LAUNCH = 40 * u,
		PUNCH_PUSH = 0,
		PUNCH_HOP = 15 * u,
		PUNCH_REACH = 3.5 * u,
		-- 1 s tra un turno e l'altro (durate del turno e della partita in sim/config.lua)
		SETTLE_TICKS = 60,
		CRATE_CHANCE = { 0.9, 0.5, 0.3, 0.1 },
		-- comandi: zona morta 20%, potenza quadratica, mira che insegue il dito,
		-- solo l'inizio della traiettoria, salto ripetuto
		AIM_DEADZONE = 0.2,
		AIM_EXPONENT = 2,
		AIM_SMOOTH = 0.2,
		AIM_PREVIEW_DOTS = 4,
		JUMP_REPEAT = true,
	}
end

local PROFILES = { blastron = blastron_profile() }
PROFILES.megablast = {}
for k in pairs(PROFILES.blastron) do PROFILES.megablast[k] = M[k] end

M.DEFAULT_PHYSICS = "blastron"

-- Sceglie il profilo di fisica per tutte le partite che verranno create.
-- Client e server devono usare lo stesso.
function M.use_physics(name)
	local prof = PROFILES[name]
	assert(prof, "profilo di fisica sconosciuto: " .. tostring(name))
	for k, v in pairs(prof) do M[k] = v end
	M.PHYSICS = name
end

M.use_physics(M.DEFAULT_PHYSICS)

return M
