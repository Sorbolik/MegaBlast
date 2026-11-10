# Interfaccia ripensata da zero (10 nov)

Proposta di Claude su richiesta di Sergio: navigazione, menu e componenti ridisegnati
partendo solo dall'inventario dei contenuti, poi confrontati con le schermate di oggi.
**Non è ancora nel gioco**: questo file dice cosa si è scelto e in che ordine farlo.

- Figma «MegaBlast · Interfaccia», pagina 3: sezione **«Da zero»** (la proposta pura, 27
  schermate) e sezione **«Proposta finale»** (il meglio delle due, 20 schermate e la tabella
  del confronto). https://www.figma.com/design/i7CjXyRO8X6NQOk7ntONZh
- Lavagna FigJam: sezione «INTERFACCIA · MAPPA NUOVA», accanto alla mappa di oggi.
  https://www.figma.com/board/IZ5dnV76izRNgRs9SJFUF5

## La direzione (approvata da Sergio il 10 nov)

1. **Home con poche porte.** GIOCA (solo online), ALLENAMENTO, CAMPAGNA, EVENTI, il
   diavoletto e l'ingranaggio. ALLENAMENTO contiene CONTRO I BOT e STESSO TELEFONO: è il
   posto di quello che si gioca senza rete (Sergio: online e resto vanno distinti, perché si
   gioca anche offline e ci si riallinea col server dopo). Senza rete GIOCA ed EVENTI si
   spengono e dicono SENZA RETE.
2. **Un solo posto per il diavoletto.** PROFILO e ARMERIA diventano IL TUO DIAVOLETTO con
   PEZZI, SIGILLI, STATISTICHE, PARTITE. L'assetto 1 2 3 sta sempre in alto a destra.
3. **Uno scheletro per ogni menu.** Testata: indietro e titolo, posto della pillola,
   portafoglio. In basso a destra l'unica azione principale; in basso a sinistra le
   secondarie.
4. **Elenco a sinistra, dettaglio a destra** dove c'è da scegliere una voce e leggerla
   (GIOCA ONLINE, PEZZI, PARTITE, EVENTI). Niente schermate di passaggio.
5. **Dalla sala al podio** lo stesso modello; podio e fine missione hanno esito, guadagni
   e azione negli stessi posti.

L'HUD in partita resta quello di oggi.

## Cosa resta di oggi dopo il confronto

- La griglia della CAMPAGNA con le miniature, le tre vie dei SIGILLI con le soglie, il podio
  coi gradini, schieramento, scelta delle armi, HUD, storia, cartellino.
- Le forme già approvate: bottone principale col Nucleo, Bottone, Pannello, tab di
  navigazione, pillola della coda, sfondi di `client/ui/backdrop.lua`.

La riga «cosa prendo da dove e perché» di ogni schermata è nella tabella della sezione
«Proposta finale».

## Componenti e funzioni

| Componente | Nel codice | Note |
|---|---|---|
| Testata | `ui.header` | in più il portafoglio a destra in ogni menu |
| Bottone principale | `ui.button(..., { main = true })` | 340 x 88, solo in basso a destra: `x1 - 30 - 340`, `y0 + 30` |
| Bottone | `ui.button` | alto 56; secondarie in basso a sinistra |
| Tab di navigazione | `ui.tab`, `ui.header_tabs` | cambia sezione, sotto la testata, alta 48 |
| Scelta | nuova: `ui.choice(list, x, y, labels, active, action)` | pillola piena `LIGHT` con testo `BOTTOM` su quella scelta; per modo, bot, mira, assetto. Raggio `pillola/raggio` |
| Riga | nuova: `ui.row(list, x, y, w, title, value, action, opt)` | alta 64, distanza 8; scelta: fondo `PANEL` e bordo `BRACE` |
| Porta | `ui.button` con `opt.state` (testo a destra) | 340 x 88, nella colonna del bottone principale |
| Portafoglio | nuova: `ui.wallet(list, parent)` | la pillola di oggi, spostata nella testata |

Stati uguali per tutti: riposo (bordo `LINE`), luce del controller (bordo `LIGHT` pieno),
premuto (fondo `BOTTOM`), spento (testo `OFF`, col motivo scritto: MANCANO 40, SENZA RETE).
Nessun colore nuovo. Testo mai sotto 14.

## Misure: telefono e desktop

Stessi componenti, due serie di misure scelte all'avvio (tabella in `ui.lua`). Il piano
Figma del file permette una sola modalità, quindi quelle da desktop stanno solo qui.

| Misura | Telefono | Desktop |
|---|---|---|
| Riga | 64 | 48 |
| Bottone | 56 | 44 |
| Bottone principale | 340 x 88 | 300 x 64 |
| Larghezza dell'elenco | 480 | 400 |

Testata e barra delle azioni si attaccano ai bordi veri (`schermo.x0`, `x1`, `y0`, `y1`); il
contenuto resta nei 1280 al centro, sotto la testata. Varianti 1600 x 720 e 4:3 in Figma.

## Controller

La luce parte dal bottone principale quando c'è, altrimenti dalla prima riga o tab. Su e giù
scorrono l'elenco, destra entra nel dettaglio, sinistra torna all'elenco, LB e RB cambiano
tab di navigazione, B torna indietro. Nella home la luce parte da GIOCA e sale per la
colonna; sinistra va al diavoletto.

## Testi nuovi (`client/lang/it.lua`)

| Chiave | Testo |
|---|---|
| `home.offline` | SENZA RETE |
| `queue_pick.title` | GIOCA ONLINE |
| `training.vs_bots` | CONTRO I BOT |
| `training.same_phone` | STESSO TELEFONO |
| `profile.title` | IL TUO DIAVOLETTO |
| `profile.tabs.pieces` | PEZZI |
| `profile.change_set` | CAMBIA SET |
| `settings.tabs.game` | GIOCO |
| `settings.tabs.keys` | TASTI DEL CONTROLLER |
| `wheel.resume` | TORNA A GIOCARE |

I nomi dei gruppi vanno allineati a quelli che ci sono già quando si scrive la PR.

## Piano a PR piccole

Ognuna gira `tutti.sh` e `simula.py` con le foto (anche `--schermo 1600x720` e `960x720`) e
aggiorna la pagina 2 del Figma.

1. **Scheletro**: `ui.wallet` nella testata di ogni menu, bottone principale nel posto fisso
   (allenamento, podio, fine missione, eventi), misure in tabella.
2. **Scelta e Riga**: `ui.choice` e `ui.row`; l'assetto 1 2 3 passa a `ui.choice` in alto a
   destra in profilo, sigilli e armeria.
3. **Home**: quattro porte, STESSO TELEFONO via dalla home, stato SENZA RETE.
4. **Allenamento**: una pagina sola con CONTRO I BOT, STESSO TELEFONO e le carte delle mappe.
5. **GIOCA ONLINE**: elenco e dettaglio al posto delle carte di DOVE GIOCHI?.
6. **IL TUO DIAVOLETTO**: PEZZI al posto di SCHEDA e ARMERIA (cartellino, tacche, CAMBIA
   SET); si toglie `client/menu` dell'armeria come schermata a parte.
7. **Sigilli, statistiche, partite**: scheletro nuovo, PORTA QUI nel posto fisso.
8. **Eventi**: tab ORA e PROSSIMI, dettaglio a destra.
9. **Impostazioni**: due tab, una riga per impostazione.
10. **Sala d'attesa, privata, rotellina**: indietro che resta in coda, MIRA come scelta.

## Scelte aperte per Sergio

1. Il podio resta coi gradini (raccomandato) o passa ai cartellini fermi nei posti della sala.
2. La CAMPAGNA resta a griglia (raccomandato) o passa a elenco e cartolina a destra.
3. Bottone principale 340 x 88 (raccomandato: lascia posto al dettaglio) o 340 x 108 come oggi.
4. Il nome della porta senza rete: ALLENAMENTO (raccomandato) o un nome nuovo.
