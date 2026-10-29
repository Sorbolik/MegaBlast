# Lo stampino: pezzi nuovi per il diavoletto

Teste, corazze, maglie, ali, code, elmi o un personaggio intero si disegnano
sopra lo stesso foglio, lo **stampino**, e il gioco li monta sullo scheletro del
diavoletto: si muovono con le stesse animazioni (`client/battaglia/animazioni.lua`)
senza toccare il codice.

## Lo scheletro e i posti

Lo scheletro è quello del diavoletto a vettori (`strumenti/grafica/diavoletto.py`,
`PUNTI`): ogni posto è un pezzo che gira attorno a un perno. Sullo stampino ogni
posto ha una casella con dentro il pezzo di base in grigio (il **manichino**) e
il perno (croce rossa). Il pezzo nuovo si disegna sopra il manichino, nella sua
casella, con lo stesso perno: la spalla dove c'è la spalla, il collo dove c'è
il collo.

| Riga | Posti |
|---|---|
| 1 | `testa`, `testa_colpita`, `testa_felice`, `testa_ko` |
| 2 | `busto`, `ala`, `coda` (intera, a riposo) |
| 3 | `braccio`, `braccio_dietro`, `gamba`, `gamba_dietro`, `omero` e `avambraccio` (il braccio sull'arma), `pugno` |

Caselle e perni in pixel del foglio (3072 x 2048, 3,5 pixel per unità del
disegno; il diavoletto è alto 200 unità): `foglio.json`.

## Le regole

- **Una pelle, una categoria.** Le categorie che *sostituiscono* i pezzi di base:
  `personaggio`, `testa`, `corpo`, `ali`, `coda`. Quelle che vanno *sopra*, in
  quest'ordine: `pantaloni`, `maglia`, `corazza`, `guanti`, `elmo`. Il diavoletto
  porta al massimo una pelle per categoria.
- **Si disegnano solo le caselle che cambiano.** Le vuote restano come sono.
- **Le facce:** una testa nuova senza le altre facce le fa tutte (non cambia
  espressione). Un elmo disegnato sulla `testa` sta su tutte le facce.
- **I pezzi di dietro** (`braccio_dietro`, `gamba_dietro`, e dietro sull'arma)
  se mancano li fa `taglia.py` da quelli davanti, più scuri.
- **La coda si disegna intera**, nella posa che si vuole a riposo, con la
  radice (il capo più spesso) verso il corpo e il tridente in fondo: `taglia.py`
  la segue dalla radice alla punta e la divide in cinque segmenti in proporzione
  a quelli di base (il tridente tutto nell'ultimo), più un disco attorno a ogni
  giunto grande quanto è spessa la coda lì. La pelle si tiene lunghezze e angoli
  disegnati: a riposo la coda è com'è disegnata e ondeggia a segmenti come
  quella di base.
- **Giunti senza giunture.** I pezzi in catena (i segmenti della coda, braccio e
  avambraccio sull'arma) diventano due strati come quelli di base: il bordo (il
  pezzo intero) e il colore (lo stesso senza il contorno). Il gioco disegna prima
  tutti i bordi e poi tutti i colori, quindi piegati non mostrano la riga al
  gomito o fra i segmenti. Sullo stampino i cerchi verdi tratteggiati segnano
  questi giunti: lì il disegno deve restare tondo e pieno.
- **Il colore della squadra:** le parti dipinte di **verde acceso** (`#00ff00`,
  con le sue ombre) diventano del colore della squadra, come la fiammella. Il
  verde acceso non va usato per altro.
- **Il contorno** nero, spesso come quello del manichino.

## Come si fa

```bash
python3 strumenti/stampino/stampino.py      # rifà lo stampino (serve cairosvg)
```

Scrive in `simulazione/stampino/`: `stampino.png` (caselle, perni, giunti, nomi
e le regole in breve, per disegnare in Procreate), `stampino_ai.png` (il manichino su magenta, da dare a
ChatGPT), `manichino.png` (il manichino montato, per far capire come stanno
insieme i pezzi).

- **Procreate (consigliato):** `stampino.png` come livello di sotto, si
  disegna in un livello nuovo, si esporta solo quello in PNG trasparente.
  Per i pezzi che vanno sopra il manichino non serve ricopiarlo.
- **ChatGPT:** gli si dà `stampino_ai.png` e `manichino.png` e si chiede di
  ridisegnare i pezzi nelle stesse caselle, sullo stesso magenta. ChatGPT non
  rispetta mai le caselle: si taglia con `--allinea`. Per le categorie che
  sostituiscono, ogni pezzo staccato va al posto con la casella più vicina, si
  scala fino all'area del manichino (le facce con la scala della testa) e prende
  il perno nello stesso punto della sua scatola in cui il manichino ha il suo:
  basta che i pezzi siano nell'ordine dello stampino, uno per casella, staccati
  fra loro. Per quelle sopra ogni casella si sposta e si scala poco, finché
  combacia col manichino: meglio Procreate.

```bash
python3 strumenti/stampino/taglia.py elmo.png --nome elmo_corna --categoria elmo
python3 strumenti/stampino/taglia.py chatgpt.png --nome testa_drago --categoria testa --allinea
python3 strumenti/stampino/taglia.py --togli elmo_corna
python3 strumenti/stampino/taglia.py --ritocchi ritocchi.json   # i ritocchi fatti nell'editor delle animazioni
```

`taglia.py` ritaglia ogni casella cambiata, toglie il manichino (per quelle
sopra), allinea se serve, divide la coda, separa bordo e colore dei pezzi in
catena e il colore della squadra, e scrive `client/assets/pelli/<nome>_<posto>.png`,
`strumenti/stampino/pelli/<nome>.json`, `client/battaglia/pelli.lua` e l'atlante
del diavoletto, che contiene base e pelli insieme (si disegna in una volta).

## Nel gioco e nell'editor

`scoria.new(colore, { "elmo_corna", "testa_drago" })` veste il diavoletto. Per
provarle: `[megablast] prova_pelli elmo_corna,testa_drago` in `game.project` o
`imposta prova_pelli ...` in uno scenario di `strumenti/simula`. Nell'editor
delle animazioni (`strumenti/animazioni/prepara.py`) c'è una scelta per ogni
categoria che ha pelli.

Se cambia lo scheletro (un perno in `diavoletto.py`) si rifà lo stampino e i
pezzi già disegnati vanno ricontrollati.
