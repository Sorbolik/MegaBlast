-- Regole della partita: tutti i numeri da bilanciare in un posto solo.
-- Lua puro, di sola lettura: lo leggono la simulazione (client e server) e
-- l'interfaccia. Le scelte vengono da docs/game_design_competitivo.md
-- ("Decisioni prese"); quelle prese senza Sergio sono segnate con "scelta nostra".
-- La fisica (gravità, armi, salto) resta nei profili di sim/game.lua.

local C = {}

-- Partita e turni, in secondi
-- durata della partita; allo scadere si finisce il giro di turni in corso
-- (supplementari): tutti hanno giocato lo stesso numero di turni
C.MATCH_SECONDS = 5 * 60
C.TURN_SECONDS = 25          -- durata del turno (Blastron con più di due giocatori)
-- Dopo il primo attacco restano AFTER_ATTACK_SECONDS (mai oltre la fine del
-- turno): in tutti si può fare il secondo attacco, riposizionarsi, usare oggetti.
-- Sergio: 4 s "per il secondo attacco" + 4 di riposizionamento, ma in tutti e 8
-- si può attaccare, così non si perde il secondo colpo senza capire perché.
C.AFTER_ATTACK_SECONDS = 8

-- Modi di gioco: i giocatori da passare a game.new (opts.players), con la
-- squadra di ognuno. Nel 2 contro 2 le squadre si alternano già nell'elenco.
C.MODES = {
	["1v1"] = { { team = 1 }, { team = 2 } },
	["2v2"] = { { team = 1 }, { team = 2 }, { team = 1 }, { team = 2 } },
	ffa = { { team = 1 }, { team = 2 }, { team = 3 }, { team = 4 } },
}

-- Teletrasporti: i secondi rimasti al primo attacco del turno diventano
-- globi del teletrasporto, uno ogni TELEPORT_SECONDS, senza tetto (Sergio,
-- 24 ottobre 2026: il Nucleo è tolto, il tempo risparmiato dà teletrasporti).
-- Scelta nostra sui 10 s: chi attacca entro 5 s ne guadagna 2, entro 15 s
-- uno, dopo niente; con 1 ogni 5 s se ne accumulavano più di quanti se ne
-- lanciano.
C.TELEPORT_SECONDS = 10
-- al primo turno di ogni robot si può fare un solo teletrasporto
C.FIRST_TURN_TELEPORTS = 1

-- Punti partita (strategia 7 del documento): oltre alle uccisioni contano il
-- danno, le uccisioni ambientali e i colpi a chi è primo. Vince la squadra con
-- più punti allo scadere. Scelta nostra sui valori. Sergio, 29 ottobre 2026
-- (variante A senza sbalzo e senza doppietta): Corona sul primo, trappola,
-- parata dello scudo; Rampino e trampolino danno l'uccisione a chi li ha usati.
-- Il danno vale per la parte di vita tolta, non per i punti di vita: una vita
-- intera vale 100 * damage, anche a chi ha più vita dai pezzi o dall'albero
-- (Sergio, 29 ottobre 2026: "disaccoppiare i punti dai danni"). Conta la vita
-- delle statistiche: la vita data da una missione non cambia i punti del danno.
C.SCORE = {
	damage = 1,       -- per ogni centesimo della vita intera tolto a un avversario
	kill = 50,        -- uccisione
	env_kill = 50,    -- in più se è ambientale (fuori dalla mappa o caduta)
	death = -20,      -- per chi muore
	self_death = -30, -- in più per chi muore nel proprio turno senza colpa di un avversario
	leader = 1.5,     -- moltiplicatore se il colpito è il primo in classifica (la Corona)
	crown = 25,       -- in più a chi uccide il primo in classifica
	trap = 10,        -- a chi l'ha posata, quando la trappola scatta su un avversario
	parry = 0.5,      -- a chi porta lo scudo, per ogni punto di danno nemico che ferma
	parry_max = 20,   -- al massimo per ogni scudo (dura fino al proprio turno dopo)
}
-- l'uccisione va a chi ha colpito per ultimo, se è stato entro questi secondi
C.KILL_CREDIT_SECONDS = 10
-- Chi muore nel proprio turno senza un colpo recente di un avversario (si butta
-- giù, si colpisce da solo) non toglie i punti agli altri: l'uccisione va
-- all'avversario che gli ha fatto più danno in questa vita, e lui perde
-- death + self_death (Sergio, 26 ottobre 2026: "deve essere punitivo e
-- bilanciato"). Il turno continua lo stesso (correzione di Sergio del 24).
-- Alla morte si ricomincia dopo RESPAWN_SECONDS, anche a metà del turno (di
-- chi ti ha colpito o del tuo: il turno non passa), con la vita piena in un
-- punto a caso della superficie, libero. Anche vicino a un avversario: con un
-- po' di fortuna ti colpisce ancora.
C.RESPAWN_SECONDS = 1.5

-- Casse: cosa c'è dentro (nascosto finché non si apre), col peso: più è
-- alto, più spesso esce. Armi da 1 colpo e oggetti tattici.
C.CRATE_CONTENTS = {
	{ "grenade", 2 }, { "shards", 2 }, { "punch", 2 }, { "sniper", 2 },
	{ "trap", 2 }, { "shield", 1 }, { "trampoline", 1 },
}

-- Cecchino (arma delle casse): un colpo che parte veloce (velocità in
-- sim/game.lua) e frena (ogni secondo gli resta drag della velocità), mentre
-- la gravità cresce a poco a poco fino a drop volte quella dei robot in
-- drop_ramp secondi: all'inizio va quasi dritto, poi cala sempre di più, così
-- da lontano è difficile mirare (Sergio, 24 ottobre 2026: "inizia veloce e
-- poi scende a poco a poco"). Sul terreno rimbalza come una palla, sempre più
-- basso e più lento (bounce_normal contro la superficie, bounce_tangent
-- lungo), al massimo bounces volte o finché va più piano di min_speed; non
-- scava. Chi è colpito prende damage e viene sbalzato nella direzione del
-- colpo a push pixel al secondo (più lift verso l'alto, per staccarlo da
-- terra). Con un trampolino sotto i piedi vola via.
C.SNIPER = { damage = 50, push = 280, lift = 80, drag = 0.7, drop = 1, drop_ramp = 0.8,
	bounces = 6, bounce_normal = 0.5, bounce_tangent = 0.85, min_speed = 40 }

-- Le due categorie (Sergio, 29 ottobre 2026, al posto della regola del 24):
-- le PRIMARIE fanno danno e sono le sole che lasciano effetti di stato
-- (C.STATUS: rallentato, armatura incrinata, bruciatura); le SECONDARIE
-- possono fare di tutto (spostare te, spostare l'avversario, danno secco)
-- ma non lasciano mai effetti di stato. Le secondarie sono illimitate. La
-- Lama è in sim/game.lua (SWORD_*); Tonante, Maglio, Affondo e Mantice si
-- scelgono una a testa all'inizio della partita. Distanze in pixel, velocità
-- in pixel al secondo.
-- Tonante (pistola pesante): colpo dritto e istantaneo fino a range, si ferma
-- al primo robot o terreno. Il rinculo spinge chi spara dalla parte opposta
-- alla mira, dritto, a recoil per recoil_ticks: la stessa spinta in tutte le
-- direzioni (Sergio, 26 ottobre 2026), senza gravità né controllo in aria,
-- e scivola lungo il terreno che incontra. Poi si cade da fermi.
C.EAGLE = { damage = 38, range = 600, recoil = 300, recoil_ticks = 22 }
-- Maglio: martello a due mani che gira attorno alla spalla come la Lama, da
-- from (alto dietro la testa) a to (sotto i piedi) in ticks tick, lungo reach
-- dalla spalla. Colpisce ogni robot che tocca lungo l'arco; la testa si ferma
-- sul terreno. Se il colpo parte in aria e la testa sbatte su un robot o sul
-- terreno mentre cala (dalla spalla in giù), chi colpisce rimbalza in alto a
-- bounce (pogo), anche se nel frattempo è atterrato.
-- Finito (o fermato) l'arco, il martello resta giù hold tick.
C.MALLET = { damage = 57, reach = 44, from = math.rad(115), to = math.rad(-100), ticks = 12, hold = 12, bounce = 320 }
-- Rampino (oggetto tattico, Sergio 24 ottobre 2026: non un'arma, uno a
-- turno, si usa in qualsiasi momento del turno e non fa danno): l'uncino parte
-- dalla canna e vola dritto a shot_speed, senza gravità, fino a range (Sergio,
-- 29 ottobre 2026: con le mappe 1,5 volte più grandi 220 non bastava; 400 arriva
-- dal bordo della piattaforma agli scogli di "Giù dal bordo"). Se non prende
-- niente cade col filo (solo nel disegno).
-- Su un robot: viene tirato con la fune verso la mano di chi tira, dritto
-- lungo la fune, senza gravità, a speed, per reel pixel al massimo, poi viene
-- mollato e cade dov'è. Da vicino arriva fin addosso a chi tira (Sergio 26
-- ottobre 2026: "ce lo dobbiamo tirare per bene"); da più lontano di reel resta
-- a metà strada: sopra il vuoto cade giù (scelta nostra, così "Giù dal bordo"
-- si fa col Rampino).
-- Il pavimento sotto non lo ferma (scivola e sale i gradini, game.hook_slide);
-- un muro alto o un altro robot in mezzo sì. Da sotto lo sollevi fino a te.
-- Chi tira si può muovere nel frattempo: la fune segue la mano.
-- Sul terreno: è chi tira che sale lungo la fune a climb_speed fino al punto
-- colpito e si mette in piedi sopra la piattaforma, se la sua cima è entro
-- climb pixel dal punto (il fianco di un muro alto no: resta lì e cade).
C.HOOK = { range = 400, shot_speed = 1500, reel = 220, speed = 300, climb_speed = 420, climb = 64 }
-- Bastione (attrezzo, uno a turno al posto del Rampino; scelto da Sergio il 29
-- ottobre): posa un blocco di terreno vero w x h pixel nel punto mirato, a
-- range pixel al massimo (la potenza della mira); se si mira più su o più giù
-- di 45 gradi il blocco è in piedi. Si scava come il resto della mappa. Al
-- massimo max blocchi a testa: posando il successivo crolla il più vecchio.
C.WALL = { w = 48, h = 12, range = 160, max = 2 }
-- Affondo: scatto nella direzione della mira a speed per ticks tick, passando
-- attraverso i robot (danno una volta a ognuno). Colpisce chi tocca col corpo
-- o con la lancia, lunga reach dal centro del corpo. Gradini e gobbe fino a
-- climb pixel li sale senza fermarsi; contro un ostacolo più alto scivola
-- lungo il terreno (resta solo la parte di scatto che passa) e si ferma solo
-- se non passa per niente. Alla fine resta keep della velocità: oltre un
-- bordo si vola.
C.LUNGE = { damage = 45, speed = 520, ticks = 18, keep = 0.35, reach = 40, climb = 16 }
-- Mantice (Sergio, 29 ottobre 2026: "una secondaria che sposta il nemico"): il
-- soffio della forgia. Istantaneo, a forma di ventaglio: colpisce ogni robot
-- (non chi soffia) col centro entro range pixel e entro cone radianti dalla
-- mira, se il terreno non è in mezzo. Fa poco danno e lo spinge lontano lungo
-- la mira a push (più lift verso l'alto, per staccarlo da terra), meno quanto
-- più è lontano (al bordo del ventaglio far della spinta). Chi soffia non si
-- muove. Lo scudo dimezza la spinta come per i colpi. Danno sulla scala della
-- vita 100 (#79): 10, un decimo
C.BELLOWS = { damage = 10, range = 170, cone = math.rad(35), push = 520, lift = 160, far = 0.6 }

-- Oggetti tattici: si usano in qualsiasi momento del proprio turno, anche nel
-- riposizionamento, e non contano come attacchi. Velocità in pixel al secondo.
-- Trappola: si posa ai piedi e si arma dal turno dopo; un avversario che ci
-- passa sopra viene lanciato in alto e lontano (per buttarlo fuori dalla mappa).
C.TRAP = { damage = 13, launch_vy = 220, push_vx = 160 }
-- Trampolino: si lancia come l'Uovo e resta dove cade (se cade su un robot, ai
-- suoi piedi). Qualsiasi cosa ci cada sopra rimbalza in alto: robot, colpi,
-- Uova, globi, casse e oggetti (la tavola è top pixel sopra la base). Restando
-- sopra ogni rimbalzo è più basso (decay) finché sotto min_vy ci si ferma (i
-- colpi allora toccano il terreno sotto, e il missile scoppia).
C.TRAMPOLINE = { half_w = 18, top = 7, launch_vy = 300, decay = 0.6, min_vy = 80 }
-- Scudo: assorbe hp danni e dimezza le spinte fino all'inizio del proprio turno dopo
C.SHIELD = { hp = 40, knockback = 0.5 }
-- Paracadute: nel proprio turno, in aria, un tocco lo apre (se ne hanno
-- stats.parachutes a partita) e un altro lo chiude. Aperto si scende al
-- massimo a fall_speed, ci si muove in orizzontale air_mul volte più veloci
-- (anche appena sbalzati) e l'atterraggio non fa danno. Veloce
-- perché è una risorsa da una volta a partita (Sergio, 26 ottobre 2026)
C.PARACHUTE = { fall_speed = 60, air_mul = 1.5 }
-- Cerchi di cura: all'inizio di un turno ogni every turni ne compare uno in un
-- punto a caso della superficie (al massimo max insieme). A fine turno, di
-- chiunque, ogni robot coi piedi dentro (raggio r) riprende hp di vita e, se
-- ha curato qualcuno, il cerchio sparisce
C.HEAL = { every = 2, max = 2, hp = 27, r = 26 }
-- trappole e trampolini in mappa al massimo, tutti insieme
C.MAX_PLACED = 8

-- Scelta d'inizio partita (sim/draft.lua): due ventagli uguali per tutti, uno
-- di DRAFT_OFFER primarie delle casse e uno delle secondarie (game.DRAFT_SECONDARIES).
-- Ognuno prende una primaria (ne ha DRAFT_SHOTS colpi) e una secondaria
-- (illimitata). Due compagni non possono prendere la stessa; nel tutti contro
-- tutti i doppioni vanno bene. Allo scadere di DRAFT_SECONDS chi non ha scelto
-- prende la prima arma libera di ogni ventaglio.
-- Sergio (24 ottobre 2026): 2 colpi, con 3 turni a testa uno solo si consuma
-- al primo turno utile.
C.DRAFT_SECONDS = 15
C.DRAFT_OFFER = 3
C.DRAFT_SHOTS = 2

-- Effetti di stato (strategia 9): durano fino alla fine del prossimo turno di
-- chi li subisce (stats.status_turns di chi colpisce) e si vedono sul robot.
-- Lo scudo li ferma: passano solo se il colpo arriva alla vita.
-- Bruciatura: danno all'inizio di ogni proprio turno. Rallentamento: corsa,
-- velocità in aria e salto ridotti. Armatura incrinata: si prende più danno.
C.STATUS = {
	burn = { damage = 17 },
	slow = { move = 0.6, jump = 0.8 },
	cracked = { damage = 1.25 },
}
-- Quale arma dà quale effetto (scelta nostra). La bruciatura viene dalle
-- Uova di chi ha stats.burning_blasts (il set Fornace).
C.WEAPON_STATUS = { shards = "slow", punch = "cracked" }

-- Statistiche di ogni robot che non sono fisica. Le modificano l'albero di
-- abilità e l'equipaggiamento (opts.players[i].stats in game.new);
-- corsa, salto e velocità in aria vengono dal profilo di fisica.
C.STATS = {
	-- 100: ogni danno è una percentuale della vita. Era 150 (23 ottobre, per i
	-- due attacchi a turno); Sergio, 29 ottobre 2026: "ci vogliono 5 turni per
	-- ammazzare qualcuno, tutto deve togliere di più in percentuale". Con le armi
	-- a 5/3 un colpo toglie 2,5 volte la parte di vita di prima: una vita dura
	-- circa 2 turni nemici nel 1 contro 1 (erano 4), di rado uno solo.
	-- Scudo, cure, pezzi e albero sono scesi a 2/3, la stessa parte di vita.
	max_hp = 100,
	teleports = 2,           -- globi del teletrasporto all'inizio (Sergio: 2); se ne guadagnano attaccando presto
	parachutes = 1,          -- paracadute per partita (Sergio, 24 ottobre 2026: uno)
	time_orbs = 1,           -- 1: i secondi avanzati diventano globi; 0 no (le lezioni che non parlano di globi)
	knockback_mul = 1,       -- quanto si viene spinti dai colpi
	fall_damage_mul = 1,     -- quanto fa male cadere
	trap_radius = 12,        -- quanto è larga la trappola posata
	air_jumps = 0,           -- salti in aria prima di toccare terra (ramo Mobilità, set Corvo)
	burning_blasts = 0,      -- 1: l'Uovo brucia chi colpisce (set Fornace)
	status_turns = 1,        -- per quanti turni dura un effetto di stato dato da questo robot
}

return C
