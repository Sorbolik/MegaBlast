-- Regole della partita: tutti i numeri da bilanciare in un posto solo.
-- Lua puro, di sola lettura: lo leggono la simulazione (client e server) e
-- l'interfaccia. Le scelte vengono da docs/game_design_competitivo.md
-- ("Decisioni prese"); quelle prese senza Sergio sono segnate con "scelta nostra".
-- La fisica (gravità, armi, salto) resta nei profili di sim/game.lua.

local C = {}

-- Partita e turni, in secondi
C.MATCH_SECONDS = 5 * 60     -- durata della partita
C.TURN_SECONDS = 25          -- durata del turno (Blastron con più di due giocatori)
C.SECOND_ATTACK_SECONDS = 5  -- dopo il primo attacco, tempo per il secondo
C.REPOSITION_SECONDS = 5     -- dopo l'ultimo attacco, tempo per riposizionarsi

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
-- Alla morte si ricomincia a fine turno, con la vita piena, in un punto a caso
-- della superficie ad almeno questa distanza (in pixel) dagli altri robot
C.RESPAWN_DISTANCE = 160

-- Casse: cosa c'è dentro (nascosto finché non si apre), col peso: più è
-- alto, più spesso esce. Armi da 1 colpo e oggetti tattici.
C.CRATE_CONTENTS = {
	{ "grenade", 2 }, { "shards", 2 }, { "punch", 2 },
	{ "trap", 2 }, { "shield", 1 }, { "trampoline", 1 },
}

-- Oggetti tattici: si usano in qualsiasi momento del proprio turno, anche nel
-- riposizionamento, e non contano come attacchi. Velocità in pixel al secondo.
-- Trappola: si posa ai piedi e si arma dal turno dopo; un avversario che ci
-- passa sopra viene lanciato in alto e lontano (per buttarlo fuori dalla mappa).
C.TRAP = { damage = 8, launch_vy = 220, push_vx = 160 }
-- Trampolino: si posa ai piedi; chiunque ci passi sopra rimbalza in alto
C.TRAMPOLINE = { half_w = 12, launch_vy = 300 }
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
}

return C
