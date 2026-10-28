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
- **La coda nuova è un pezzo solo**, disegnata come il manichino: gira col
  primo segmento (non ondeggia a segmenti come quella di base).
- **Il braccio sull'arma nuovo** (`omero`, `avambraccio`) non ha il bordo a parte
  come quello di base: al gomito si può vedere la giuntura. Meglio disegnare il
  gomito tondo.
- **Il contorno** nero, spesso come quello del manichino.
- Il colore della squadra resta sulla fiammella, sul paracadute e sulle armi:
  le pelli non si tingono.

## Come si fa

```bash
python3 strumenti/stampino/stampino.py      # rifà lo stampino (serve cairosvg)
```

Scrive in `simulazione/stampino/`: `stampino.png` (caselle, perni e nomi, per
disegnare in Procreate), `stampino_ai.png` (il manichino su magenta, da dare a
ChatGPT), `manichino.png` (il manichino montato, per far capire come stanno
insieme i pezzi).

- **Procreate (consigliato):** `stampino.png` come livello di sotto, si
  disegna in un livello nuovo, si esporta solo quello in PNG trasparente.
  Per i pezzi che vanno sopra il manichino non serve ricopiarlo.
- **ChatGPT:** gli si dà `stampino_ai.png` e `manichino.png` e si chiede di
  ridisegnare i pezzi nelle stesse caselle, sullo stesso magenta. ChatGPT non
  rispetta mai le caselle al pixel: si taglia con `--allinea`, e conviene usare
  le categorie che sostituiscono (pezzo intero), non quelle sopra.

```bash
python3 strumenti/stampino/taglia.py elmo.png --nome elmo_corna --categoria elmo
python3 strumenti/stampino/taglia.py chatgpt.png --nome testa_drago --categoria testa --allinea
python3 strumenti/stampino/taglia.py --togli elmo_corna
```

`taglia.py` ritaglia ogni casella cambiata, toglie il manichino (per quelle
sopra), allinea se serve e scrive `client/assets/pelli/<nome>_<posto>.png`,
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
