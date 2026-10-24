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

-- Nucleo: i secondi rimasti al primo attacco del turno diventano Nucleo,
-- 1 ogni NUCLEO_SECONDS, senza superare NUCLEO_MAX.
-- Scelta nostra: il documento proponeva 1 ogni 2 s e 10 al massimo, ma con
-- turni da 25 s quasi tutti arriverebbero al massimo e la scelta "spendo o
-- tengo" sparirebbe. Così chi attacca con 20 s rimasti prende 4, chi ne
-- lascia 5 prende 1.
C.NUCLEO_SECONDS = 5
C.NUCLEO_MAX = 5
-- al primo turno di ogni robot si può fare un solo teletrasporto
C.FIRST_TURN_TELEPORTS = 1

-- Punti partita (strategia 7 del documento): oltre alle uccisioni contano il
-- danno, le uccisioni ambientali e i colpi a chi è primo. Vince la squadra con
-- più punti allo scadere. Scelta nostra sui valori.
C.SCORE = {
	damage = 1,       -- per ogni punto di vita tolto a un avversario
	kill = 50,        -- uccisione
	env_kill = 50,    -- in più se è ambientale (fuori dalla mappa o caduta)
	death = -20,      -- per chi muore
	leader = 1.5,     -- moltiplicatore se il colpito è il primo in classifica
}
-- l'uccisione va a chi ha colpito per ultimo, se è stato entro questi secondi
C.KILL_CREDIT_SECONDS = 10
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

-- Cecchino (arma delle casse): un colpo dritto e velocissimo che rimbalza sul
-- terreno fino a bounces volte e non scava. Chi è colpito prende damage e viene
-- sbalzato nella direzione del colpo a push pixel al secondo (più lift verso
-- l'alto, per staccarlo da terra). Con un trampolino sotto i piedi vola via.
C.SNIPER = { damage = 25, push = 280, lift = 80, bounces = 3 }

-- Oggetti tattici: si usano in qualsiasi momento del proprio turno, anche nel
-- riposizionamento, e non contano come attacchi. Velocità in pixel al secondo.
-- Trappola: si posa ai piedi e si arma dal turno dopo; un avversario che ci
-- passa sopra viene lanciato in alto e lontano (per buttarlo fuori dalla mappa).
C.TRAP = { damage = 8, launch_vy = 220, push_vx = 160 }
-- Trampolino: si lancia come l'Uovo e resta dove cade (se cade su un robot, ai
-- suoi piedi). Chiunque ci arrivi sopra rimbalza in alto, sempre; restando sopra
-- ogni rimbalzo è più basso (decay) finché sotto min_vy ci si ferma.
C.TRAMPOLINE = { half_w = 12, launch_vy = 300, decay = 0.6, min_vy = 80 }
-- Scudo: assorbe hp danni e dimezza le spinte fino all'inizio del proprio turno dopo
C.SHIELD = { hp = 60, knockback = 0.5 }
-- Paracadute: si prepara nel proprio turno (costa stats.parachute_cost Nucleo)
-- e si apre da solo cadendo più veloce di open_speed; poi si scende a
-- fall_speed e l'atterraggio non fa danno
C.PARACHUTE = { open_speed = 160, fall_speed = 60 }
-- Punti di ancoraggio della mappa (sim/maps.lua): chi ci sta sopra viene
-- spinto molto meno
C.ANCHOR_KNOCKBACK = 0.35
-- trappole e trampolini in mappa al massimo, tutti insieme
C.MAX_PLACED = 8

-- Scelta d'inizio partita (sim/draft.lua): un ventaglio di DRAFT_OFFER armi
-- delle casse, uguale per tutti; ognuno ne prende una e ne ha DRAFT_SHOTS
-- colpi. Due compagni non possono prendere la stessa; nel tutti contro tutti
-- i doppioni vanno bene. Allo scadere di DRAFT_SECONDS chi non ha scelto
-- prende la prima arma libera del ventaglio.
C.DRAFT_SECONDS = 15
C.DRAFT_OFFER = 3
C.DRAFT_SHOTS = 1

-- Effetti di stato (strategia 9): durano fino alla fine del prossimo turno di
-- chi li subisce (stats.status_turns di chi colpisce) e si vedono sul robot.
-- Lo scudo li ferma: passano solo se il colpo arriva alla vita.
-- Bruciatura: danno all'inizio di ogni proprio turno. Rallentamento: corsa,
-- velocità in aria e salto ridotti. Armatura incrinata: si prende più danno.
C.STATUS = {
	burn = { damage = 10 },
	slow = { move = 0.6, jump = 0.8 },
	cracked = { damage = 1.25 },
}
-- Quale arma dà quale effetto (scelta nostra). La bruciatura viene dalle
-- esplosioni di chi ha stats.burning_blasts (il set Fornace).
C.WEAPON_STATUS = { shards = "slow", punch = "cracked" }

-- Statistiche di ogni robot che non sono fisica. Le modificano l'albero di
-- abilità e l'equipaggiamento (opts.players[i].stats in game.new);
-- corsa, salto e velocità in aria vengono dal profilo di fisica.
C.STATS = {
	-- scelta nostra: 1,5 volte la vita di prima, perché con due attacchi per
	-- turno il danno può raddoppiare (il documento dice "la vita si alza")
	max_hp = 150,
	start_nucleo = 1,
	teleport_cost = 1,
	free_teleports = 0,      -- teletrasporti gratis per partita (albero, set Vuoto)
	parachute_cost = 1,
	free_parachutes = 0,     -- paracadute gratis per partita
	knockback_mul = 1,       -- quanto si viene spinti dai colpi
	fall_damage_mul = 1,     -- quanto fa male cadere
	trap_radius = 12,        -- quanto è larga la trappola posata
	shield_cost = 3,         -- Nucleo per uno scudo, quando non se ne ha uno delle casse
	air_jumps = 0,           -- salti in aria prima di toccare terra (ramo Mobilità, set Corvo)
	air_jump_cost = 1,       -- Nucleo per ogni salto in aria
	burning_blasts = 0,      -- 1: missile e Uovo bruciano chi colpiscono (set Fornace)
	status_turns = 1,        -- per quanti turni dura un effetto di stato dato da questo robot
}

return C
