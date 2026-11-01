# WB-006 · Pezzi dei personaggi di Sergio sullo stampino

- **Stato:** APPROVATA
- **Data:** 2026-11-01
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-006` (con Codex: `esegui WB-006`; oppure a mano in ChatGPT)

## Obiettivo

Animare il maschio, la femmina e Favilla come il diavoletto di prima: pezzi disegnati
**sullo stampino del gioco** (come WB-001), così si montano sullo stesso scheletro e si
muovono col codice vero (molle, braccia IK, clip dell'editor). Il foglio a 12 pezzi liberi
di P-007 è stato bocciato da Sergio una volta animato.

Lo stampino dice solo **dove** va ogni pezzo e quanto è grande. Com'è fatto lo dice il
personaggio di tre quarti approvato (R1) e il foglio delle sue espressioni (R4).

## Riferimenti da allegare

Un foglio per personaggio, in una chat nuova di ChatGPT per ciascuno. Allega i quattro
file in quest'ordine (pronti, già numerati, in
`/mnt/project-files/grafica/prompt/WB-006/<personaggio>/`).

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-006/riferimenti/R1_<personaggio>_tre_quarti.png` | il personaggio di tre quarti approvato: **il** modello |
| R2 | `art/WB-006/riferimenti/R2_stampino.png` | lo stampino: dove sta ogni pezzo (3072×2048) |
| R3 | `art/WB-006/riferimenti/R3_manichino.png` | come si attaccano i pezzi |
| R4 | `art/WB-006/riferimenti/R4_espressioni_<personaggio>.png` | le 9 espressioni approvate di quel personaggio |

## Immagini da generare

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `foglio_maschio` | `art/WB-006/riferimenti/R1_maschio_tre_quarti.png`, `art/WB-006/riferimenti/R2_stampino.png`, `art/WB-006/riferimenti/R3_manichino.png`, `art/WB-006/riferimenti/R4_espressioni_maschio.png` (in quest'ordine = immagini 1, 2, 3, 4) | 3:2 orizzontale, la più grande possibile (minimo 1536×1024) | 1 |
| `foglio_femmina` | `art/WB-006/riferimenti/R1_femmina_tre_quarti.png`, `art/WB-006/riferimenti/R2_stampino.png`, `art/WB-006/riferimenti/R3_manichino.png`, `art/WB-006/riferimenti/R4_espressioni_femmina.png` (in quest'ordine = immagini 1, 2, 3, 4) | come sopra | 1 |
| `foglio_favilla` | `art/WB-006/riferimenti/R1_favilla_tre_quarti.png`, `art/WB-006/riferimenti/R2_stampino.png`, `art/WB-006/riferimenti/R3_manichino.png`, `art/WB-006/riferimenti/R4_espressioni_favilla.png` (in quest'ordine = immagini 1, 2, 3, 4) | come sopra | 1 |

Sfondo **magenta pieno #FF00FF** come R2 (lo usa lo strumento di taglio). Le caselle
dell'ala e della coda restano **vuote**: questi personaggi non le hanno. Niente foglio
squadra per ora.

Le quattro teste dello stampino sono, nell'ordine: `testa` = felice, `testa_colpita` =
dolore appena colpito, `testa_felice` = vittoria, `testa_ko` = stordito (espressioni 1, 6,
8 e 7 dei fogli R4).

### `foglio_maschio`

```
Immagine 1 è il mio personaggio di tre quarti verso destra. È il modello ESATTO: copia le sue forme, le sue proporzioni e il suo stile, non reinterpretarlo. Bianco e nero puro: nero pieno, bianco pieno, contorno nero spesso, nessuna sfumatura, nessun grigio, nessun colore.

Immagine 2 è uno stampino: 14 posti grigi su sfondo magenta pieno (#FF00FF), in tre righe. Usala SOLO per sapere dove va ogni pezzo sul foglio, quanto è grande e dove si attacca. NON copiare le forme, le facce, le corna o lo stile dei pezzi grigi. Immagine 3 mostra come i pezzi grigi si attaccano fra loro. Immagine 4 sono le espressioni approvate della faccia del mio personaggio.

Fai il foglio dei pezzi del personaggio di immagine 1, smontato come una marionetta di carta: stessa tela di immagine 2, stesso sfondo magenta pieno #FF00FF, ogni pezzo messo sopra il suo posto grigio e grande più o meno come lui. Sul foglio non deve restare nient'altro: niente posti grigi, niente scritte, numeri o etichette, niente ombre sul magenta. Ogni pezzo è disegnato come appare in immagine 1 (tre quarti verso destra), intero anche nelle parti nascoste dagli altri pezzi, e chiuso tutto intorno dal contorno nero spesso.

I pezzi, da sinistra a destra:
Riga 1, quattro teste del personaggio di immagine 1, girate a destra come in immagine 1, ognuna con un corto moncherino di collo nero in basso. La sagoma della testa è sempre identica, cambiano solo occhi e bocca, copiati dalle facce di immagine 4: testa 1 felice; testa 2 dolore appena colpito (occhi strizzati a > <, bocca aperta a zigzag); testa 3 vittoria (occhi chiusi a mezzaluna, bocca grande aperta che ride); testa 4 stordito (pupille a spirale, bocca ondulata).
Riga 2: il busto da solo, cioè la maglietta nera CON i pantaloncini bianchi attaccati sotto, come in immagine 1, senza testa, senza braccia e senza gambe, con le spalle tonde e chiuse e il bordo in basso chiuso. Al posto dell'ala e della coda NON disegnare niente: quei due posti restano magenta vuoto.
Riga 3: il braccio davanti e il braccio dietro, ognuno un tubo nero dritto che pende giù da una spalla tonda e finisce con la mano APERTA nel guanto bianco di immagine 1 (dita aperte e rilassate, palmo verso di noi); la gamba davanti e la gamba dietro, ognuna un tubo nero dritto, tondo e chiuso in cima, che finisce con la scarpa nera tonda di immagine 1 con la punta verso destra; l'omero e l'avambraccio, due corti tubi neri con le estremità tonde e piene, così si sovrappongono al gomito senza far vedere la giuntura; un pugno chiuso col guanto bianco.

Non usare nessun colore: niente verde, niente rosso, niente grigio.
```

### `foglio_femmina`

```
Immagine 1 è la mia personaggia femmina di tre quarti verso destra. È il modello ESATTO: copia le sue forme, le sue proporzioni e il suo stile, non reinterpretarla. Bianco e nero puro: nero pieno, bianco pieno, contorno nero spesso, nessuna sfumatura, nessun grigio, nessun colore.

Immagine 2 è uno stampino: 14 posti grigi su sfondo magenta pieno (#FF00FF), in tre righe. Usala SOLO per sapere dove va ogni pezzo sul foglio, quanto è grande e dove si attacca. NON copiare le forme, le facce, le corna o lo stile dei pezzi grigi. Immagine 3 mostra come i pezzi grigi si attaccano fra loro. Immagine 4 sono le espressioni approvate della sua faccia.

Fai il foglio dei pezzi della personaggia di immagine 1, smontata come una marionetta di carta: stessa tela di immagine 2, stesso sfondo magenta pieno #FF00FF, ogni pezzo messo sopra il suo posto grigio e grande più o meno come lui. Sul foglio non deve restare nient'altro: niente posti grigi, niente scritte, numeri o etichette, niente ombre sul magenta. Ogni pezzo è disegnato come appare in immagine 1 (tre quarti verso destra), intero anche nelle parti nascoste dagli altri pezzi, e chiuso tutto intorno dal contorno nero spesso.

I pezzi, da sinistra a destra:
Riga 1, quattro teste della personaggia di immagine 1, girate a destra come in immagine 1, ognuna con un corto moncherino di collo nero in basso. La sagoma della testa e le ciglia sono sempre identiche, cambiano solo occhi e bocca, copiati dalle facce di immagine 4: testa 1 felice; testa 2 dolore appena colpita (occhi strizzati a > <, bocca aperta a zigzag); testa 3 vittoria (occhi chiusi a mezzaluna, bocca grande aperta che ride); testa 4 stordita (pupille a spirale, bocca ondulata).
Riga 2: il busto da solo, cioè la maglietta nera CON la gonnellina bianca attaccata sotto, come in immagine 1, senza testa, senza braccia e senza gambe, con le spalle tonde e chiuse e il bordo in basso chiuso. Al posto dell'ala e della coda NON disegnare niente: quei due posti restano magenta vuoto.
Riga 3: il braccio davanti e il braccio dietro, ognuno un tubo nero dritto che pende giù da una spalla tonda e finisce con la mano APERTA nel guanto bianco di immagine 1 (dita aperte e rilassate, palmo verso di noi); la gamba davanti e la gamba dietro, ognuna un tubo nero dritto, tondo e chiuso in cima, che finisce con la scarpa nera tonda di immagine 1 con la punta verso destra; l'omero e l'avambraccio, due corti tubi neri con le estremità tonde e piene, così si sovrappongono al gomito senza far vedere la giuntura; un pugno chiuso col guanto bianco.

Non usare nessun colore: niente verde, niente rosso, niente grigio.
```

### `foglio_favilla`

```
Immagine 1 è Favilla, la mia personaggia di tre quarti verso destra, con la testa a fiamma. È il modello ESATTO: copia le sue forme, le sue proporzioni e il suo stile, non reinterpretarla. Bianco e nero puro: nero pieno, bianco pieno, contorno nero spesso, nessuna sfumatura, nessun grigio, nessun colore.

Immagine 2 è uno stampino: 14 posti grigi su sfondo magenta pieno (#FF00FF), in tre righe. Usala SOLO per sapere dove va ogni pezzo sul foglio, quanto è grande e dove si attacca. NON copiare le forme, le facce, le corna o lo stile dei pezzi grigi. Immagine 3 mostra come i pezzi grigi si attaccano fra loro. Immagine 4 sono le espressioni approvate della sua faccia.

Fai il foglio dei pezzi di Favilla di immagine 1, smontata come una marionetta di carta: stessa tela di immagine 2, stesso sfondo magenta pieno #FF00FF, ogni pezzo messo sopra il suo posto grigio e grande più o meno come lui. Sul foglio non deve restare nient'altro: niente posti grigi, niente scritte, numeri o etichette, niente ombre sul magenta. Ogni pezzo è disegnato come appare in immagine 1 (tre quarti verso destra), intero anche nelle parti nascoste dagli altri pezzi, e chiuso tutto intorno dal contorno nero spesso.

I pezzi, da sinistra a destra:
Riga 1, quattro teste di Favilla, cioè la sua testa a fiamma nera col ricciolo in cima di immagine 1, girate a destra come in immagine 1, ognuna con un corto moncherino di collo nero in basso. La sagoma della testa e le ciglia sono sempre identiche, cambiano solo occhi e bocca, copiati dalle facce di immagine 4: testa 1 felice; testa 2 dolore appena colpita (occhi strizzati a > <, bocca aperta a zigzag); testa 3 vittoria (occhi chiusi a mezzaluna, bocca grande aperta che ride); testa 4 stordita (pupille a spirale, bocca ondulata).
Riga 2: il busto da solo, cioè la maglietta nera CON la gonnellina bianca attaccata sotto, come in immagine 1, senza testa, senza braccia e senza gambe, con le spalle tonde e chiuse e il bordo in basso chiuso. Al posto dell'ala e della coda NON disegnare niente: quei due posti restano magenta vuoto.
Riga 3: il braccio davanti e il braccio dietro, ognuno un tubo nero dritto che pende giù da una spalla tonda e finisce con la mano APERTA nel guanto bianco di immagine 1 (dita aperte e rilassate, palmo verso di noi); la gamba davanti e la gamba dietro, ognuna un tubo nero dritto, tondo e chiuso in cima, che finisce con la scarpa nera tonda di immagine 1 con la punta verso destra; l'omero e l'avambraccio, due corti tubi neri con le estremità tonde e piene, così si sovrappongono al gomito senza far vedere la giuntura; un pugno chiuso col guanto bianco.

Non usare nessun colore: niente verde, niente rosso, niente grigio.
```

## Criteri di accettazione

- [ ] ogni pezzo sembra tagliato dal personaggio di R1 (forme, proporzioni, stile), non dal manichino
- [ ] 12 pezzi sopra i posti di R2; i posti dell'ala e della coda vuoti; nessun manichino grigio rimasto
- [ ] sfondo magenta pieno, senza aloni o ombre
- [ ] solo bianco e nero, contorno nero spesso e chiuso su ogni pezzo
- [ ] quattro teste con la stessa sagoma, girate a destra, facce come in R4 (felice, colpita, vittoria, stordita)
- [ ] busto con pantaloncini (maschio) o gonnellina (femmina, Favilla) attaccati
- [ ] braccia che finiscono con la mano aperta nel guanto bianco, pugno chiuso a parte, gambe con la scarpa nera, omero e avambraccio con le estremità tonde e piene
- [ ] nessuna scritta

---

## Decisione

Approvata da Claude, 2026-11-01: scelta reversibile (sono solo immagini da generare, il gioco
non cambia finché non vengono tagliate). Richiesta dal thread delle animazioni dopo che Sergio
ha bocciato il montaggio dei pezzi liberi di P-007. Sergio genera i fogli in ChatGPT (Codex
non è installato sul PC) e li porta nel thread; li taglia il thread delle animazioni con
`strumenti/stampino/taglia.py --allinea`.

Aggiornata da Claude, 2026-11-01 14:15, su richiesta di Sergio ("le mani devono essere anche aperte"): le braccia appese finiscono con la mano aperta, il pugno chiuso resta nella sua casella. Così ci sono tutte e due.
