# Il Copione

Il formato dei livelli è in [docs/copione.md](../../docs/copione.md).

La dashboard della campagna (Sergio, 6 nov 2026; proposta
https://claude.ai/artifact/2EPgEANUbEMLYJhG2iaGBi): tutti i capitoli e i loro
livelli, e per ogni livello un editor grafico (mappa da scorrere, spawn,
piattaforme, casse e trigger da trascinare, vignette agganciate ai trigger),
GIOCA per provarlo nella build web e "Manda a Claude".

Si fa in tre PR:

1. **Livelli come dati** (fatta): `client/sim/levels.lua` contiene solo dati, i
   trigger sono i verbi di `client/sim/missions.lua` e la vignetta grande si
   scrive nella riga (`mostra = "grande"`). Il controllo:

   ```bash
   luajit strumenti/copione/controlla.lua
   ```

   Gira in `strumenti/controlli/tutti.sh`: niente funzioni, passi, eventi, armi,
   comandi, facce e segnaposto che esistono, disegno per ogni vignetta grande,
   punti dentro la mappa.
2. **La pagina**: cruscotto, editor del livello, GIOCA, "Manda a Claude".
3. **Il ritorno**: Claude scrive `levels.lua` da quello che arriva, rifà
   dipinti e miniature se è cambiata una mappa, gira la simulazione del livello.
