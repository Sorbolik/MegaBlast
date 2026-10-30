# Impostazioni (scritte nella pietra)

Ogni impostazione che Sergio nomina finisce qui **il giorno stesso**, così
non sfugge niente (area 8 della [roadmap](roadmap.md)). La schermata c'è dal
30 ott (IMPOSTAZIONI, la rotellina in alto a destra della home,
`client/menu/impostazioni.lua`): ci entrano via via le righe che si fanno. Per
ognuna: cosa fa, il valore di base, chi l'ha chiesta e quando, e dove sta oggi
nel codice (se c'è già un interruttore).

| Impostazione | Cosa fa | Di base | Chiesta | Oggi nel codice |
|---|---|---|---|---|
| Modo della mira | **Lancetta** (dritta dall'arma, si riempie con la potenza: chi comincia la capisce subito) o **mirino** (anellino che si riempie) | lancetta | Sergio, 29 ott | **c'è**: nelle IMPOSTAZIONI della home e nel pulsante MIRA della rotellina in partita, salvato nel profilo (`profilo.impostazione(p, "mira")`) |
| Vibrazione allo sgancio | Micro-vibrazione quando sulla levetta della mira il pollice esce dalla zona morta e il colpo diventa sganciabile | accesa | Sergio, 29 ott | sempre accesa (`aim_pad_drag` in `client/main/game.gui_script`) |
| Vibrazione della potenza | Micro-vibrazione a ogni tacca del 5% di potenza mentre si mira | spenta | Sergio, 29 ott | `mira.VIBRA_TACCHE` (`client/battaglia/mira.lua`) |
| Modalità delle vibrazioni della mira | Solo sgancio, solo potenza, tutte e due o nessuna (si combinano le due righe sopra) | solo sgancio | Sergio, 29 ott | — |
| Zona morta della levetta della mira | Toglierla: la mira si accende appena si tocca la levetta | c'è (20% della corsa) | Sergio, 29 ott | `levette.AIM_ON`, `levette.AIM_OFF` (`client/battaglia/levette.lua`) |
| Vibrazione del salto | Micro-vibrazione quando il pollice entra nell'arco del salto | accesa | (da #83) | sempre accesa (`move_pad_drag`) |
| Traiettoria intera nelle lezioni | Aiuto per imparare: nelle lezioni dell'Addestramento si vede tutta la traiettoria | accesa nelle lezioni, mai in partita | Sergio, 29 ott | sempre accesa nelle lezioni dell'Addestramento (`render` in `client/main/game.gui_script`) |
| Effetti ridotti | Transizioni ed effetti più leggeri | spenti | roadmap | — |
| Comandi | Mancino, levette, mira | — | roadmap (area 8) | — |
| Tasti del controller | Cambiare cosa fa ogni tasto del controller in battaglia (Sergio: "forse molta gente vorrà usare l'analogico destro per dosare la potenza") | la mappatura di Sergio ([controller.md](controller.md)) | Sergio, 30 ott | **c'è**: nelle IMPOSTAZIONI della home (`client/menu/impostazioni.lua`), salvata nel profilo (`profilo.impostazione(p, "tasti")`); le levette sono fisse |
| HUD sistemabile | Il giocatore sposta i pulsanti della battaglia | predefiniti | Sergio, 29 ott ([interfaccia](decisioni/interfaccia.md)) | — |

Non ci saranno (decisioni di Sergio): qualità grafica a livelli. (La rimappatura dei tasti ora c'è, per il controller: Sergio, 30 ott.)
