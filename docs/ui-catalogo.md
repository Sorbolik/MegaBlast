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
- Quando la proposta sarà confermata, un controllo in `tools/controlli/tutti.sh` segnalerà i
  menù che disegnano un elemento fuori dal suo pezzo del kit (le righe ⚠️ qui sotto).

Colonne: **Pezzo** è la funzione di `client/ui/kit.lua` (o del modulo indicato) e i
disegni dell'atlante `fucina` che usa; **Dove** sono le schermate; **Oggi** dice se è
già allineato (✅) o se è da portare al pezzo giusto (⚠️).

Direzione (Sergio, 23 nov): tutto **lineare**, senza bump né sporcizie grafiche:
tasti, cornici, barre, linee.

---

## 1. Azione principale

Quello che la schermata fa partire (GIOCA, INDOSSA, COMPRA, CONSEGNA...). Uno per
schermata, sotto il filo a destra.

| Pezzo oggi | Dove |
|---|---|
| `kit.action`: la gemma `primario_acceso/premuto/spento` (WB-052) con la riga a sinistra | GIOCA ONLINE (queue), ALLENAMENTO, CAMPAGNA (forgia, addestramento, gironi), EVENTI, ZAINO (INDOSSA, SALVA nei sigilli), BOTTEGA BANCO (COMPRA), POTENZIA (bench), COMMESSE (CONSEGNA, CHIAMA, SCAMBIA, OK della consegna), scelta armi (PRONTO / GIOCA), schieramento (ARMI), podio (AVANTI), fine livello, storia (AVANTI), stanza privata (ENTRA, VIA), cartolina della missione, scena dello scatto, editor dell'HUD (FATTO), cartellino dell'arma in battaglia (OK), vignette (AVANTI / VAI) |
| `kit.sign("gioca_sigillo")`: il sigillo GIOCA ONLINE disegnato (WB-046) | HOME |

**Proposta (23 nov):** stesso formato del secondario (`Ferro liscio`, allineato in
verticale con lui), in un colore leggermente diverso (ferro rovente), con la sua
**icona grande a sinistra**. Stati: acceso, sotto il dito, al passaggio (mouse o
controller: sfumatura più chiara), spento. Pezzo unico: `kit.action`, disegnato a vettori in
`tools/grafica/fucina.py` come il secondario; le icone sono di Codex (WB-088).

## 2. Azione secondaria

Un'altra cosa che si può fare nella schermata, accanto all'azione principale.

| Pezzo oggi | Dove | Oggi |
|---|---|---|
| `kit.secondary`: `secondario_acceso/premuto/spento` (WB-071) + icona a sinistra | EVENTI (CALENDARIO), ZAINO (POTENZIA AL MASSIMO), BOTTEGA (COI FRAMMENTI, USA UN BUONO), POTENZIA (ACCENDI LA FIRMA, COI FRAMMENTI), COMMESSE (PROVA, CHIAMA UN CLIENTE, INDIETRO, CAMBIA, SCAMBIA, POTENZIA QUI), IMPOSTAZIONI (IL MIO PROFILO / TASTI, DISPOSIZIONE, NUOVO CODICE, HO UN PROFILO, ANNULLA, RECUPERA), editor dell'HUD (RIPRISTINA), conto dei punti (PIAZZA I PUNTI) | ✅ forma; ⚠️ metà senza icona |
| `kit.plate` (piastra storta) usato come pulsante | sala d'attesa: TORNA AI MENU · RESTI IN CODA | ⚠️ formato da togliere |
| `kit.plate` (`piastrina`, viola) | fine livello (RIPROVA, ELENCO), storia (SALTA), podio (ANCORA) | ⚠️ |
| `kit.plate` (`piastrina`) dopo i tab | CAMPAGNA (il capitolo dopo i tab) | ⚠️ |
| `kit.plate` (`piastrina`) in fondo | CAMPAGNA gironi: IL CORTILE ★, LA FORGIA ★ (i capitoli fatti) | ⚠️ |
| `ui.button` (sagoma vecchia del 23 ott) | scelta armi (ESCI), menu della rotellina in battaglia (RIPROVA, ESCI, MIRA, RILEGGI) | ⚠️ |

**Proposta:** tutti `kit.secondary`, sempre con l'icona grande a sinistra (icone WB-088).

## 3. Indietro

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.header`: la freccia `indietro` + dove porta, sotto il filo a sinistra | tutti i menù | ✅ |
| `kit.piece("ingranaggio")` | HOME (IMPOSTAZIONI al posto dell'indietro) | ✅ |
| testo «ESCI DALLA CODA» sotto la freccia | sala d'attesa | ✅ |

## 4. Porte della home

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.sign("porta_campagna" / "porta_allenamento" / "porta_eventi" / "porta_shop")` (WB-046, WB-080) | HOME | ✅ (pezzi disegnati, ognuno la sua forma: restano) |

## 5. Tab (le sezioni di una schermata)

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.tabs(..., tag = true)`: scritta incandescente, l'aperta oro con l'alone | ZAINO (INVENTARIO, SIGILLI), BOTTEGA (COMMESSE, BANCO), PROFILO (STATISTICHE, CRONOLOGIA PARTITE), EVENTI | ✅ |
| `kit.tabs(...)` senza tag: piastrine, l'aperta chiara | CAMPAGNA (ADDESTRAMENTO, LA FORGIA, LA STORIA) | ⚠️ → scritta incandescente |

## 6. Scelta (una fra poche opzioni)

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.choice`: piastrine in fila, la scelta chiara | ALLENAMENTO (CHI C'È, MODO, BOT), stanza privata (MODO), IMPOSTAZIONI (le opzioni) | ⚠️ piastre chiare (Sergio, 18 nov: mai) → scritta incandescente come i tab |
| `gear_ui.loadouts`: 1 2 3 su piastrine, l'attivo chiaro | ZAINO (ASSETTO) | ⚠️ → come le scelte |

## 7. Filtro

| Pezzo | Dove | Oggi |
|---|---|---|
| `gear_ui.chips`: piastrine, l'attivo caldo (`piastrina_calda`) | ZAINO (TUTTI e i tipi), PROFILO (TUTTE, 2V2, 1V1, TORNEO, CAMPAGNA) | ⚠️ piastre bombate → filtro lineare |

## 8. Card da scegliere (si tocca e si sceglie)

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.card`: `pannello` coi quattro chiodini, `pannello_caldo` attorno se scelta | ALLENAMENTO (mappe), CAMPAGNA (missioni, finale), scelta armi (armi, passi), stanza privata (posti), IMPOSTAZIONI (tasti del controller, codice), PROFILO (record, partite), ZAINO (sigilli), sala d'attesa (posti vuoti) | ⚠️ chiodini → card minimale |
| `kit.mode_card`: `scheda_brace/ferro/gelo/spenta` (WB-060) | GIOCA ONLINE (2 CONTRO 2, 1 CONTRO 1, STANZA PRIVATA, eventi) | ⚠️ chiodini su ferro → card minimale |
| caselle dei pezzi `casella/casella_scelta` (gear_ui) | ZAINO (griglia), BOTTEGA BANCO (pezzi del giorno) | ✅ (da rivedere coi bordi della card minimale) |
| `kit.drawn_plate("bivio_piastra_*")` (WB-062) | ZAINO SIGILLI (i poteri) | ✅ |

**Card minimale (proposta):** un filo sottile nella cornice e un punto in ogni angolo, a vettori
in `tools/grafica/fucina.py` (come il secondario). Il filo dice lo stato: ferro (riposo), oro con
l'alone (scelta, il tuo), gelo (evento), spento (chiusa).

## 9. Card da leggere (pannelli)

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.panel`: `pannello` coi quattro chiodini (`pannello_caldo` il tuo) | STATISTICHE (zaino, bottega), PROFILO (tu, danno per arma), EVENTI (evento, premi, calendario), IMPOSTAZIONI (pannelli), POTENZIA, SIGILLI, cartellino del giocatore (`ui/tag_card.lua`), conto (`ui/receipt.lua`), cartellino dell'arma in battaglia, storia | ⚠️ → card minimale |
| `kit.card` usato come pulsante | ZAINO e BOTTEGA (VEDI TUTTE sotto le statistiche) | ⚠️ → azione secondaria |
| `kit.paper`: il cartellino di carta col chiodo (WB-085) | COMMESSE, consegna | ✅ (è un oggetto del mondo del Fabbro) |
| `kit.plate(..., fill = SAND)` → `pannello_chiaro` | CAMPAGNA (ritratto del capitolo), storia (didascalie) | ⚠️ piastre chiare |
| `kit.plate` piastra calda | cartolina della missione, storia (la foto) | ⚠️ |
| `kit.plate(..., fill = SAND)` targhette dei giocatori | schieramento e scelta armi (ROSSO, BLU) | ⚠️ piastre chiare |
| `gear_ui` etichette dei pezzi indossati (`piastrina` col livello) | ZAINO (sul diavoletto) | ⚠️ → filo come i filtri |

## 10. Barra di progresso

| Pezzo | Dove | Oggi |
|---|---|---|
| solco dello `stendardo` + `barra_stendardo` (WB-075) | HOME (esperienza nel riquadro del profilo) | ✅ **il modello** |
| `kit.bar`: `guscio` coi rivetti + `barra_brace/gelo/chiara` | COMMESSE (avanzamento), scelta armi (tempo), editor dell'HUD (cursore) | ⚠️ |
| `riga_scura` + `barra_brace/gelo` | PROFILO (vittorie/sconfitte, danno per arma, legenda) | ⚠️ bombata |
| `gear_ui.bar`: barra a pezzi (base, livello, pezzi, sigilli) | STATISTICHE (zaino, bottega), cartellino del giocatore | ⚠️ → stesso solco, pezzi colorati piatti |
| `ui.bar` (rettangoli piatti, ottobre) | conto dei punti, cartellino del giocatore | ⚠️ |
| `ingots`: trenta perle sul filo (WB-074) | livello dei pezzi (ovunque) | ✅ (è un contatore, non una barra) |
| `kit.pips`: tacche | sala d'attesa, scelta armi (colpi) | ✅ (contatore) |
| binario dei sigilli `bivio_binario_*` | ZAINO SIGILLI | ✅ (è un percorso) |

**Proposta:** `kit.bar` unico = il solco e la striscia della home (tagliati da `art/WB-075`,
alla risoluzione piena), senza rivetti né bombature, in quattro colori (brace, gelo, menta, viola)
e a pezzi per le statistiche.

## 11. Valuta

| Pezzo | Dove | Oggi |
|---|---|---|
| `coins.wallet`: piastra + moneta (WB-072) | HOME, ZAINO, BOTTEGA, PROFILO, consegna | ⚠️ piastra bombata → lineare |
| `coins.vouchers`: piastra + buono | stessi | ⚠️ |

## 12. Stato della coda

| Pezzo | Dove | Oggi |
|---|---|---|
| `ui/pill.lua`: `guscio` + punto che respira + testo; posti `low` (home), `foot` (menù), `head` (podio), `top` (battaglia) | tutte le schermate mentre sei in coda | ⚠️ grafica nuova, stesso posto ovunque |
| `score.lua` PRONTO (`pillola`) | battaglia online | da allineare alla pillola |

## 13. Titoli e scritte di stato

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.title` (nome della schermata in alto a sinistra) | tutti i menù | ✅ |
| `kit.caption` (scritta incandescente al posto della piastra) | CAMPAGNA, schieramento, scelta armi, podio, fine livello, stanza privata, sala, lato del diavoletto | ✅ |
| `kit.heading` (titoletto di sezione) | EVENTI, COMMESSE | ✅ |
| `kit.foot_text` (la riga accanto all'azione) | tutti i menù | ✅ |
| `kit.label(..., backed)`: etichetta su `piastrina` | CAMPAGNA (BERSAGLI, DUELLO, 375), podio | ⚠️ piastrina bombata → etichetta lineare |

## 14. Regolatori

| Pezzo | Dove | Oggi |
|---|---|---|
| `kit.stepper`, `kit.round` (`tondo_ferro`) | stanza privata (livello dei bot, QUI) | ✅ |
| `tasto_piu/tasto_meno` | ZAINO SIGILLI | ✅ |

## 15. Linee

| Pezzo | Dove | Oggi |
|---|---|---|
| il filo di brace e la fascia sotto (`kit.THREAD`, `kit.BAND`) | tutti i menù | ✅ |
| `kit.line` | freccia dell'indietro | ✅ |

## 16. HUD della battaglia

| Pezzo | Dove | Oggi |
|---|---|---|
| caselle delle armi `slot_arma` + `badge` (`ui.panel`) | battaglia | da rivedere col restyle dell'HUD |
| anelli (`ui.ring_node`): mira, conto alla rovescia, zoom, levette | battaglia | ✅ |
| avvisi (`ui.panel`) | battaglia | ⚠️ |
| facce del punteggio | battaglia | ✅ |
