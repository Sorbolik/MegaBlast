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

-- Statistiche di ogni robot che non sono fisica. Le modificano l'albero di
-- abilità e l'equipaggiamento (opts.stats o opts.players[i].stats in game.new);
-- corsa, salto e velocità in aria vengono dal profilo di fisica.
C.STATS = {
	-- scelta nostra: 1,5 volte la vita di prima, perché con due attacchi per
	-- turno il danno può raddoppiare (il documento dice "la vita si alza")
	max_hp = 150,
	start_nucleo = 1,
	teleport_cost = 1,
	free_teleports = 0,      -- teletrasporti gratis per partita (albero, set Vuoto)
}

return C
