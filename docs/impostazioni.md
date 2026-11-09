# Impostazioni (scritte nella pietra)

Ogni impostazione che Sergio nomina finisce qui **il giorno stesso**, così
non sfugge niente (area 8 della [roadmap](roadmap.md)). La schermata c'è dal
30 ott (IMPOSTAZIONI, la rotellina in alto a destra della home,
`client/menu/settings.lua`): ci entrano via via le righe che si fanno. Per
ognuna: cosa fa, il valore di base, chi l'ha chiesta e quando, e dove sta oggi
nel codice (se c'è già un interruttore).

| Impostazione | Cosa fa | Di base | Chiesta | Oggi nel codice |
|---|---|---|---|---|
| Modo della mira | **Lancetta** (dritta dall'arma, si riempie con la potenza: chi comincia la capisce subito) o **mirino** (anellino che si riempie) | lancetta | Sergio, 29 ott | **c'è**: nelle IMPOSTAZIONI della home e nel pulsante MIRA della rotellina in partita, salvato nel profilo (`profilo.setting(p, "mira")`) |
| Vibrazione allo sgancio | Micro-vibrazione quando sulla levetta della mira il pollice esce dalla zona morta e il colpo diventa sganciabile | accesa | Sergio, 29 ott | sempre accesa (`aim_pad_drag` in `client/main/game.gui_script`) |
| Vibrazione della potenza | Micro-vibrazione a ogni tacca del 5% di potenza mentre si mira | spenta | Sergio, 29 ott | `mira.VIBRATE_TICKS` (`client/battle/aim.lua`) |
| Modalità delle vibrazioni della mira | Solo sgancio, solo potenza, tutte e due o nessuna (si combinano le due righe sopra) | solo sgancio | Sergio, 29 ott | — |
| Zona morta della levetta della mira | Toglierla: la mira si accende appena si tocca la levetta | c'è (20% della corsa) | Sergio, 29 ott | `levette.AIM_ON`, `levette.AIM_OFF` (`client/battle/sticks.lua`) |
| Vibrazione del salto | Micro-vibrazione quando il pollice entra nell'arco del salto | accesa | (da #83) | sempre accesa (`move_pad_drag`) |
| Vibrazione dello zoom | Micro-vibrazione a ogni scatto (24 su tutta la corsa) mentre si trascina il pulsante dello zoom | accesa | Sergio, 3 nov («vorrei che avesse un feedback di vibrazione granulare») | sempre accesa (`ZM.TICKS`, `ZM.trascina` in `client/main/game.gui_script`); quando ci sarà l'interruttore delle vibrazioni la spegne anche lui |
| Traiettoria intera nelle lezioni | Aiuto per imparare: nelle lezioni dell'Addestramento si vede tutta la traiettoria | accesa nelle lezioni, mai in partita | Sergio, 29 ott | sempre accesa nelle lezioni dell'Addestramento (`render` in `client/main/game.gui_script`) |
| Qualità grafica | Per i dispositivi più lenti: densità dei dipinti delle mappe, atlas del personaggio compresso o no (oggi sempre la qualità più alta, che è il minimo per Sergio: «non voglio scendere sotto questo requisito grafico ... dobbiamo ambire al massimo della resa») | la più alta | Sergio, 2 nov | — (`density()` in `client/battle/terrain.script`, profili in `client/texture_profiles.texture_profiles`) |
| Effetti ridotti | Transizioni ed effetti più leggeri | spenti | roadmap | — |
| Comandi | Mancino, levette, mira | — | roadmap (area 8) | — |
| Tasti del controller | Cambiare cosa fa ogni tasto del controller in battaglia (Sergio: "forse molta gente vorrà usare l'analogico destro per dosare la potenza") | la mappatura di Sergio ([controller.md](controller.md)) | Sergio, 30 ott | **c'è**: nelle IMPOSTAZIONI della home (`client/menu/settings.lua`), salvata nel profilo (`profilo.setting(p, "tasti")`); quale levetta muove si sceglie a parte |
| Sparo col controller | Il colpo parte **lasciando** il tasto di SPARA (premi per caricare) o **premendolo** | lasciando | Sergio, 30 ott ("la gente è abituata che quando prende la mira poi spara al rilascio") | **c'è**: IMPOSTAZIONI (`sparo`) |
| Potenza col controller | La potenza la dà la **levetta** destra (quanto la spingi) o il **grilletto** (quanto premi il tasto di SPARA; la levetta dà solo la direzione) | levetta | Sergio, 30 ott ("c'è un modo per gestire la potenza del colpo con il trigger?") | **c'è**: IMPOSTAZIONI (`potenza`) |
| Levetta che muove | Col controller quale levetta cammina e salta: la **destra** (e la sinistra mira) o la **sinistra** (e la destra mira) | destra | Sergio, 30 ott ("con il destro ti muovi e con il sinistro prendi la mira e lo metti come default") | **c'è**: IMPOSTAZIONI (`levette`) |
| Salto col controller su un tasto | SALTA su un tasto (per esempio A) invece della levetta sinistra in su; con un tasto la levetta non salta più | levetta in su | Sergio, 30 ott | **c'è**: la riga SALTA dei tasti del controller |
| Togliere un tasto | Un comando del controller resta senza tasto (Y sulla riga) | — | Sergio, 30 ott | **c'è**: IMPOSTAZIONI |
| Contatore FPS | In alto al centro FPS, frame peggiore, scatti dell'ultimo minuto e la loro causa; ogni scatto anche nella console ([prestazioni.md](prestazioni.md)) | spento | Sergio, 2 nov ("come facciamo a misurare gli FPS in maniera affidabile") | **c'è**: IMPOSTAZIONI (`fps`), `client/ui/frames.lua` |
| Segui sempre il mio personaggio | Anche allo zoom massimo la camera resta sul tuo personaggio invece di mostrare tutto lo spazio di gioco | spenta | proposta di Claude a Sergio, 3 nov (zoom continuo, scelta C1) | — (`TOWARD_SPACE` in `client/battle/camera.lua`) |
| Sblocca tutto (nascosta) | Apre subito tutti i pulsanti della home, per le prove di Sergio e per il simulatore; non si vede nella schermata delle impostazioni normale | spenta | Sergio, 5 nov («3 ok» alle proposte dello sblocco, [sblocco_online.md](sblocco_online.md)) | — (oggi la home non ha sblocchi) |
| HUD sistemabile | Il giocatore sposta i pulsanti della battaglia | predefiniti | Sergio, 29 ott ([interfaccia](decisioni/interfaccia.md)) | — |
| Vibrazione e suono del tuo turno | Quando inizia il tuo turno il telefono vibra e fa un tic (e VIA! dopo il conto 3-2-1) | accesa | Sergio, 9 nov («ho bisogno che ti faccia capire all'istante quando è il tuo turno») ([interfaccia](decisioni/interfaccia.md)) | — |

Non ci saranno (decisioni di Sergio): qualità grafica a livelli. (La rimappatura dei tasti ora c'è, per il controller: Sergio, 30 ott.)
