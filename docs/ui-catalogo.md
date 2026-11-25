# Catalogo dell'interfaccia (per scopo)

Ogni elemento grafico dei menù e dell'HUD, ordinato per **scopo** (Sergio, 23 nov:
«devono essere catalogati tutti gli elementi grafici in base allo scopo che hanno»).
La regola: **uno scopo = un pezzo del kit = un aspetto**. Un restyle cambia un posto solo.

- Il catalogo grafico (immagini vere di ogni pezzo e delle proposte) è su Figma,
  pagina «1 · Fondamenta e componenti», riquadro «CATALOGO UI · per scopo»:
  https://www.figma.com/design/i7CjXyRO8X6NQOk7ntONZh/?node-id=193-3
- Anteprime della proposta (23 nov), oggi e proposta affiancati: https://claude.ai/artifact/1Q194msz5CffxCcFgec87c
- Ogni PR che aggiunge o cambia un elemento dei menù aggiorna questo file e la pagina
  di Figma nella stessa PR.
- La proposta è approvata (Sergio, 23 nov: «mi piace tutto») e fatta. `tools/controlli/controlla_kit.py`
  (in `tutti.sh`) segnala nel client i pulsanti, le barre e le piastre fuori dal kit; una riga
  che deve restare così porta il commento `kit: eccezione` col perché.
- Regola dei pezzi disegnati da noi (Claude, 23 nov): a vettori in `tools/grafica/fucina.py`,
  identici al «Ferro liscio» (contorno d'inchiostro, colori pieni, nessun alone né sfumatura
  nostra accanto ai disegni di Codex). L'unico alone è quello della parola accesa (tab e scelte).

Colonne: **Pezzo** è la funzione di `client/ui/kit.lua` (o del modulo indicato) e i
disegni dell'atlante `fucina` che usa; **Dove** sono le schermate; **Oggi** dice se è
già allineato (✅) o se è da portare al pezzo giusto (⚠️).

Direzione (Sergio, 23 nov): tutto **lineare**, senza bump né sporcizie grafiche:
tasti, cornici, barre, linee.

---

## 1. Azione principale

Quello che la schermata fa partire (GIOCA, INDOSSA, COMPRA, CONSEGNA...). Una per schermata,
sotto il filo a destra (`kit.action`, posto fisso 948, 640, 308 × 62).

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.action`: la lastra del secondario in ferro rovente (`principale_acceso/chiaro/premuto/spento`) con l'icona grande a sinistra (`az_*`, WB-088) | tutte le schermate con un'azione (COLA e TIRA della FORNACE con la gemma), la HOME compresa (GIOCA al posto del sigillo), le vignette e il cartellino dell'arma in battaglia | ✅ |

Stati: acceso, chiaro (mouse o luce del controller sopra: `ui.lua`, `on_light`), premuto, spento.

## 2. Azione secondaria

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.secondary`: `secondario_acceso/chiaro/premuto/spento` + icona a sinistra; le scritte a `kit.BUTTON_PAD` (0,4 × altezza) dal bordo e `kit.BUTTON_GAP` (0,2) dopo l'icona, uguale per tutti; in verticale il blocco di scritte (altezza delle maiuscole, `kit.CAP`) sta al centro della faccia della lastra, con la stessa aria sopra e sotto | accanto all'azione in ogni menù (POTENZIA, PROVA, CHIAMA UN CLIENTE, CAMBIA, SCAMBIA, CALENDARIO, COI FRAMMENTI, FONDI I FRAMMENTI, FONDINE, USA UN BUONO, ACCENDI LA FIRMA, RIPROVA, ELENCO, SALTA, RIVEDI, RILEGGI, TORNA AI MENU · RESTI IN CODA, RIPRISTINA, IMPOSTAZIONI, CREA, i tasti del codice della stanza privata) | ✅ |
| `kit.button_at`: lo stesso, al centro di un nodo | menu della rotellina in battaglia (RIPROVA, ESCI, MIRA, RILEGGI), scelta armi (ESCI) | ✅ |
| `kit.plate` (`piastrina`) in fondo | CAMPAGNA gironi: i capitoli fatti | ⚠️ |
| `kit.card` usato come pulsante | ZAINO e BOTTEGA (VEDI TUTTE sotto le statistiche) | ⚠️ |

Icone (`az_*`, scelte fra le due varianti di WB-088): gioca, indossa, potenzia, consegna, pronto,
salva, torna, esci, chiama, scambia, cambia, prova, riprova, elenco, salta, vedi, mira, rileggi,
tasti, profilo, annulla, ripristina, uno_contro_uno, via.

## 3. Indietro

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.header`: la piastra `indietro` con la `freccina` bianca (a vettori, la punta unita) + dove porta | tutti i menù | ✅ |
| `kit.piece("ingranaggio")` | HOME (IMPOSTAZIONI al posto dell'indietro) | ✅ |

## 4. Porte della home

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.secondary` con `kind = "porta_<id>_"` e `door`: il Ferro liscio tinto del colore del posto (`fai_porte` in `fucina.py`), l'icona grande di WB-089 senza cornice sul capo verso il bordo, le scritte contro l'altro capo; tutte larghe uguali | HOME (CAMPAGNA, ALLENAMENTO, EVENTI, BOTTEGA) | ✅ (la bancarella aspetta WB-091, per ora i buchi chiusi di legno scuro) |
| il piedistallo dell'apprendista: la roccia del Limbo coi due sassolini (`piedistallo`, WB-090 2B; via la grata di WB-050 e lo zainetto di WB-048) | HOME | ✅ |
| il cielo della home all'ora del telefono (`ui/limbo_sky.lua`: mattina, mezzogiorno, pomeriggio, sera, notte; strati bianchi colorati dal gioco, da `tools/grafica/cielo.py`) | HOME | ✅ |

## 5. Tab (le sezioni di una schermata)

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.tabs`: la scritta incandescente, l'aperta oro con l'alone (sempre: le piastrine non ci sono più) | ZAINO, BOTTEGA (COMMESSE, FORNACE, BANCO), PROFILO, EVENTI, CAMPAGNA (ADDESTRAMENTO, LA FORGIA, LA STORIA), ALLENAMENTO (i modi, accanto al titolo) | ✅ |

## 6. Scelta (una fra poche opzioni)

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.choice`: le parole in fila, la prima allineata alla sua etichetta, una colonna larga `w` ciascuna; la scelta incandescente (`kit.hot_word`) | ALLENAMENTO (DIFFICOLTÀ), stanza privata, IMPOSTAZIONI | ✅ |
| `gear_ui.loadouts`: 1 2 3 come parole (`kit.hot_word`) | ZAINO (ASSETTO) | ✅ |

## 7. Filtro ed etichetta

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.thread_chip`: un filo sottile intorno (`filo_fondo` + `filo_bordo` tinto), oro l'attivo | filtri di ZAINO e PROFILO (`gear_ui.chips`) | ✅ |
| `kit.label(..., backed)`: la parola in un filo del suo colore | CAMPAGNA (BERSAGLI, DUELLO, RECORD), podio | ✅ |
| etichette dei pezzi indossati sul diavoletto | ZAINO | ⚠️ |

## 8. Card da scegliere e 9. card da leggere

| Pezzo | Dove | Oggi |
|---|---|---|
| card minimale (`pannello`, a vettori in `fai_card_filo`): fondo scuro, un filo nella cornice, un punto in ogni angolo. Il filo dice lo stato: ferro (riposo), oro `pannello_caldo` (scelta, il tuo), gelo, brace, spento | `kit.card`, `kit.panel`, `kit.mode_card` (GIOCA ONLINE): la cornice del muro e SUL MURO della FORNACE, le famiglie da fondere, mappe (ALLENAMENTO: grandi, in una fila che scorre col dito, la rotella o la luce del controller, senza frecce), missioni, armi, posti, record, partite, statistiche, eventi, impostazioni, cartellini dei giocatori (il tuo in oro), conto | ✅ |
| caselle dei pezzi `casella/casella_scelta` | ZAINO, BOTTEGA BANCO | ✅ (oggetti) |
| `kit.drawn_plate("bivio_piastra_*")` (WB-062) | ZAINO SIGILLI | ✅ |
| `kit.paper`: il cartellino di carta col chiodo (WB-085) | COMMESSE, FORNACE (la regola della colata) | ✅ (oggetto del Fabbro) |
| `kit.plate(..., fill = SAND)` → `pannello_chiaro` | CAMPAGNA (ritratto), storia (didascalie), targhette ROSSO / BLU | ⚠️ piastre chiare |
| `kit.plate` piastra calda | cartolina della missione, storia (la foto) | ⚠️ |

## 10. Barra di progresso

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.bar`: il `solco` (a vettori, l'incavo dello stendardo) + `barra_stendardo` (brace, com'è disegnata) o `barra_stendardo_chiara` tinta | HOME (esperienza), COMMESSE, PROFILO (danno per arma, legenda), scelta armi, editor dell'HUD, conto dei punti | ✅ |
| `kit.bar_parts`: lo stesso, a pezzi colorati | STATISTICHE (zaino, bottega, cartellino), PROFILO (vittorie e sconfitte) | ✅ |
| `ingots`: trenta perle sul filo (WB-074) | livello dei pezzi | ✅ (contatore) |
| `kit.pips`, binario dei sigilli | sala, scelta armi, SIGILLI | ✅ (contatori, percorsi) |

## 11. Valuta

| Pezzo | Dove | Oggi |
|---|---|---|
| `coins.wallet`, `coins.vouchers`: piastra + moneta | HOME, ZAINO, BOTTEGA, PROFILO, i tiri della FORNACE (le gemme partono da qui) | ⚠️ piastra bombata |

## 12. Stato della coda

| Pezzo | Dove | Oggi |
|---|---|---|
| `ui/pill.lua`: un filo oro intorno, il punto che respira piatto; **infilata sul filo al centro** in ogni menù (`low` e `foot`), in alto nel podio (`head`) e in battaglia (`top`) | mentre sei in coda | ✅ |
| `score.lua` PRONTO (`pillola`) | battaglia online | ⚠️ |

## 13. Titoli e scritte di stato

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.title`, `kit.caption`, `kit.heading`, `kit.foot_text` | tutti i menù | ✅ |

## 14. Regolatori

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.stepper`, `kit.round` (`tondo_ferro`), `tasto_piu/tasto_meno` | stanza privata, SIGILLI | ✅ |

## 15. Linee

| Pezzo | Dove | Oggi |
|---|---|---|
| il filo di brace e la fascia sotto (`kit.THREAD`, `kit.BAND`) | tutti i menù | ✅ |

## 16. HUD della battaglia

| Pezzo | Dove | Oggi |
|---|---|---|
| caselle delle armi, anelli, facce del punteggio | battaglia | ✅ (restyle dell'HUD a parte) |
| avvisi (`ui.panel`) | battaglia | ⚠️ |

## 17. La fucina della FORNACE

Il minigioco della Fornace (`client/menu/forge_ui.lua`, docs/commesse.md «La Fornace»): un mondo suo
sotto una cornice a stampo (in vetrina la cornice del muro, mentre si tira tutto lo schermo).

| Pezzo | Dove | Oggi |
|---|---|---|
| i disegni di Codex WB-092 e WB-093 nell'atlante `fornace` (`client/menu/fornace.atlas`, con le mipmap: si vede a tanti zoom) e i dipinti `client/paintings/fornace/` (`tools/grafica/fornace.py`; da vicino, nella colata, i dipinti si avvicinano solo fino ai loro pixel: mai ingranditi) | FORNACE | ✅ |
| il cartellino del premio sopra lo stampo: l'icona (scaglia o frammento della famiglia) e il numero, sempre grandi uguali sullo schermo; lo stampo fortunato col numero oro e DOPPIO | FORNACE | ✅ |
| i TIRI in alto a sinistra: una goccia per tiro, quelle usate spente | FORNACE | ✅ |
| la mira: la stessa della battaglia, disegno e conti (`battle/aim.lua`: lancetta, numeri, dal dito ad angolo e forza; col controller la levetta di mira e SPARA di `battle/sticks.lua`) più i puntini del primo tratto del volo | FORNACE | ✅ |
| la levetta di mira del telefono: lo stesso pezzo della battaglia (`battle/stick_pad.lua`, disco velato col bordo azzurro, rosso quando lasciando si tira), in basso a destra | FORNACE, BATTAGLIA | ✅ |
| il coperchio dello stampo preso (Codex WB-094, grande e piccolo): scende rimbalzando sulla bocca dopo la fiammata, l'icona del premio preso sul cerchio al centro | FORNACE | ✅ |
| la fiammata quando la goccia entra (come la pagina delle animazioni scelta da Sergio): velo scuro e lampo caldo sullo schermo, i quattro fotogrammi di Codex WB-094 (alta tre stampi) che salgono, bruciano e ricadono, scintille tonde d'oro, magenta e viola, l'anello d'oro dell'onda d'urto, lo stampo incandescente (il suo disegno ripetuto in somma, color brace) che trema, «CENTRO!» grande in alto | FORNACE | ✅ |
| il jackpot del muro pieno: gli stampi accesi uno dopo l'altro (incandescenti che pulsano, luce d'oro sul coperchio), lampo, scossa, «JACKPOT!» enorme che ondeggia (la scritta grande di `shout`), «MURO PIENO», pioggia di Scaglie e frammenti che cade su tutto lo schermo | FORNACE | ✅ |
| la sponda in fondo al muro, dove la goccia rimbalza col «toc» (Codex WB-095): il piede e i tratti di cuscino e cinghia impilati fino in cima, la gomma sulla riga del rimbalzo | FORNACE | ✅ |
| le medaglie dei rintocchi (Codex WB-095: 6 bronzo, 10 argento; WB-096: 8 acciaio): saltano fuori sotto la scritta la prima volta, una riga nel riepilogo; nel PROFILO sono badge come quella del jackpot (atlante `fucina`, 128 px); da cinque badge in su, due righe dentro la card | FORNACE, PROFILO | ✅ |
| le scritte che saltano fuori (CENTRO!, DOPPIO!, 3 SU 3!, 6 RINTOCCHI!, JACKPOT!): una sola funzione (`shout`), testo incandescente con l'ombra di china, misura per importanza | FORNACE | ✅ |
| la medaglia «Jackpot della Fornace» (Codex WB-094): salta fuori al centro al primo jackpot, ed è l'icona della sua riga nel riepilogo; nel PROFILO è un badge (atlante `fucina`, 128 px), dopo quelli dei clienti, e si mette accanto al nome | FORNACE, PROFILO | ✅ |
| il riepilogo della colata: `kit.card` sul velo, titolo incandescente, una riga per premio (icona, nome, numero) che entra una alla volta, COLA ANCORA (`kit.secondary` con la gemma) e CHIUDI (`kit.secondary`) | FORNACE | ✅ |
| le scritte che saltano (3 SU 3!, DOPPIO!, NEL SECCHIO): parola incandescente con l'ombra d'inchiostro | FORNACE | ✅ |
