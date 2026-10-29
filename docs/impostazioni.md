# Impostazioni (da fare, scritte nella pietra)

Ogni impostazione che Sergio nomina finisce qui **il giorno stesso**, così
quando si farà la schermata (area 8 della [roadmap](roadmap.md)) non sfugge
niente. Per ognuna: cosa fa, il valore di base, chi l'ha chiesta e quando, e
dove sta oggi nel codice (se c'è già un interruttore).

| Impostazione | Cosa fa | Di base | Chiesta | Oggi nel codice |
|---|---|---|---|---|
| Vibrazione allo sgancio | Micro-vibrazione quando sulla levetta della mira il pollice esce dalla zona morta e il colpo diventa sganciabile | accesa | Sergio, 29 ott | sempre accesa (`aim_pad_drag` in `client/main/game.gui_script`) |
| Vibrazione della potenza | Micro-vibrazione a ogni tacca del 5% di potenza mentre si mira | spenta | Sergio, 29 ott | `mira.VIBRA_TACCHE` (`client/battaglia/mira.lua`) |
| Modalità delle vibrazioni della mira | Solo sgancio, solo potenza, tutte e due o nessuna (si combinano le due righe sopra) | solo sgancio | Sergio, 29 ott | — |
| Zona morta della levetta della mira | Toglierla: la mira si accende appena si tocca la levetta | c'è (20% della corsa) | Sergio, 29 ott | `levette.AIM_ON`, `levette.AIM_OFF` (`client/battaglia/levette.lua`) |
| Vibrazione del salto | Micro-vibrazione quando il pollice entra nell'arco del salto | accesa | (da #83) | sempre accesa (`move_pad_drag`) |
| Traiettoria intera nelle lezioni | Aiuto per imparare: nelle lezioni dell'Addestramento si vede tutta la traiettoria | accesa nelle lezioni, mai in partita | Sergio, 29 ott | — (in arrivo con la mira nuova) |
| Effetti ridotti | Transizioni ed effetti più leggeri | spenti | roadmap | — |
| Comandi | Mancino, levette, mira | — | roadmap (area 8) | — |
| HUD sistemabile | Il giocatore sposta i pulsanti della battaglia | predefiniti | Sergio, 29 ott ([interfaccia](decisioni/interfaccia.md)) | — |

Non ci saranno (decisioni di Sergio): qualità grafica a livelli, rimappatura dei tasti.
