# Simulare il gioco senza Defold

`simula.py` compila il client e lo fa giocare da solo su uno schermo virtuale,
così gli errori si vedono prima di aprire Defold. Serve soprattutto a Claude
nelle sessioni cloud, ma gira su qualsiasi Linux (Ubuntu/Debian).

```bash
bash strumenti/simula/prepara.sh          # una volta: Java 25, bob.jar 1.14.0, Xvfb, xdotool, ffmpeg, luajit
python3 strumenti/simula/simula.py        # controlli, test, build e partita con lo scenario base
python3 strumenti/simula/simula.py -s strumenti/simula/scenari/mio.txt
python3 strumenti/simula/simula.py --solo-build    # senza avviare il gioco
python3 strumenti/simula/simula.py --scala 2 -s strumenti/simula/scenari/diavoletto.txt   # schermo 2560 x 1440, personaggio da vicino
```

Nelle sessioni cloud `prepara.sh` parte da solo all'avvio
(`.claude/hooks/session-start.sh`). Se manca qualcosa, `simula.py` lo lancia comunque.

## Cosa controlla

1. **Controlli dell'editor** (`controlla.py`): errori che l'editor di Defold
   segnala ma `bob.jar` no, quindi la build automatica non li vede. Oggi:
   - mesh con un materiale in vertex space WORLD senza `position_stream` o
     `normal_stream`, o con uno stream che non c'è nel buffer
     (è l'errore "Normal Stream must be specified..." di `terreno.mesh`);
   - riferimenti a file che non esistono nei file di risorse.

   Se l'editor segnala un nuovo tipo di errore che sfugge, aggiungi la regola qui.
2. **Test della simulazione** (`tests/sim_test.lua` con luajit).
3. **Build con bob** 1.14.0 per Linux, variante debug. L'estensione WebSocket
   viene tolta solo in questa build (si compila sul build server di Defold, che
   dal cloud non si raggiunge), quindi il gioco online non si prova.
4. **Partita** su Xvfb con mouse e tastiera finti (xdotool). Fallisce se nel log
   del motore compare un `ERROR:` (errori Lua compresi), se il gioco si chiude da
   solo o se un `aspetta_*` scade. Gli errori dell'audio si ignorano: nel
   container non c'è una scheda audio.

Il risultato è `OK` o `FALLITO` (codice di uscita 1) con il motivo.

## Risultati

Tutto in `simulazione/` (ignorata da git):

- `foto/*.png` le foto dello scenario, `foto/riepilogo.png` tutte in una
  griglia, `foto/errore.png` lo schermo al momento dell'errore
- `video.mp4` la partita intera (30 fps)
- `log.txt` il log del motore, `build.txt` quello di bob

## Scenari

Un comando per riga, `#` per i commenti. Coordinate del gioco: 1280 x 720 con
(0, 0) in basso a sinistra, come nel codice.

| Comando | Cosa fa |
|---|---|
| `aspetta S` | aspetta S secondi |
| `foto NOME` | salva `foto/NOME.png` |
| `zoom NOME [Z]` | foto ingrandita Z volte (2 se non si dice) attorno al robot di turno, contando lo zoom che la camera del gioco ha già (con la camera a 2,2 uno zoom 4 ingrandisce la foto di 1,8) |
| `tocca X Y` | tocco breve (pulsanti, menu) |
| `tieni TASTO S [ZOOM] [Z]` | tiene premuto un tasto: `sinistra`, `destra`, `salta`, o un nome di xdotool; facoltativamente fa lo zoom ZOOM prima di lasciarlo |
| `premi TASTO` | pressione breve |
| `trascina X1 Y1 X2 Y2 [S]` | trascina il dito |
| `mira DX DY [S] [FOTO] [Z]` | tiene il dito a (DX, DY) pixel dello schermo dal robot di turno (la potenza dipende dai pixel dello schermo, a ogni zoom) per S secondi (la mira), facoltativamente scatta FOTO (con Z, uno zoom Z volte invece della foto intera), poi lascia: spara con l'arma scelta |
| `levetta DX DY S [FOTO]` | comandi del telefono (`imposta comandi telefono`): appoggia il dito sulla levetta del movimento (`115 117`), lo sposta di (DX, DY) e lo tiene S secondi: di lato cammina, in alto salta (e risalta), facoltativamente scatta FOTO prima di lasciare |
| `levetta_mira DX DY S [FOTO]` | come `levetta`, ma sulla levetta della mira (`1165 117`): oltre il 20% della corsa (19 px) si accende e lasciando spara; sotto il 10% si spegne |
| `annulla DX DY [FOTO]` | mira a (DX, DY) dal robot col sinistro, preme il destro (annulla), facoltativamente scatta FOTO, poi lascia il sinistro |
| `niente_evento TIPO [S]` | fallisce se nei prossimi S secondi succede l'evento TIPO (per esempio un colpo annullato che parte lo stesso) |
| `aspetta_evento TIPO [S]` | aspetta un evento della simulazione (`fire`, `explosion`, `swing`, `sword_hit`, `orb`, `teleport`, `grenade`, `shards`, `punch`, `punch_hit`, `sniper`, `sniper_bounce`, `sniper_hit`, `eagle`, `hook`, `hook_end`, `mallet`, `mallet_hit`, `lunge`, `lunge_hit`, `place`, `bounce`, `respawn`, `overtime`, `crate`, `crate_pick`, `damage`, `turn`, `over`...) |
| `aspetta_stato chiave=valore ... [S]` | aspetta uno stato, per esempio `turno=2 fase=aim` (chiavi: `modo`, `turno`, `fase`, `x`, `y` nel mondo, `sx`, `sy` il centro del robot sullo schermo, `zoom` della camera) |
| `imposta CHIAVE VALORE` | impostazione `[megablast]` della build, letta prima di compilare. Solo per le prove: `prova_armi N` dà N colpi di ogni arma e oggetto delle casse a tutti, `prova_casse N` fa cadere una cassa ogni N turni invece di 3, `prova_secondaria eagle` (o `mallet`, `lunge`) dà a tutti quella secondaria oltre alla Lama (scenario `scenari/secondarie.txt`), `prova_vita N` fa partire tutti con N punti di vita (scenario `scenari/colpi.txt`), `prova_durata N` fa durare la partita N secondi (scenario `scenari/podio.txt`), `prova_scelta 1` fa partire lo stesso telefono con la scelta delle armi (senza, negli scenari si salta; scenario `scenari/scelta.txt`), `tutorial 1` fa aprire il tutorial a STESSO TELEFONO (scenario `scenari/tutorial.txt`; vale anche fuori dagli scenari finché la home non ha il pulsante), `prova_stati 1` fa partire tutti bruciati, rallentati e con l'armatura incrinata (scenario `scenari/stati.txt`), `prova_vicino N` mette il secondo robot N pixel a destra del primo (a sinistra se negativo), a terra (scenario `scenari/rampino_nemico.txt`), `zoom 3` fa partire la camera con tutta la mappa (1 vicino, 2 medio; scenario `scenari/camera.txt`), `prova_mappa crogiolo` gioca sul Crogiolo (negli scenari la mappa è fissa, forgia se non si dice; scenario `scenari/crogiolo.txt`) |

Comandi: sul computer (il predefinito qui) tastiera e mouse, zoom col pulsante `1210 686`, il tasto `z` o la rotella, TELE `1180 62` o
il tasto `t`, armi coi tasti `1`-`9`. Con `imposta comandi telefono` ci sono le
due levette (corsa 94 px) e TELE sta a `1208 257`.
La barra delle armi sta in basso al centro (`y = 62`) e mostra solo le armi che
il robot ha, centrate, in tre gruppi (primarie color brace, secondarie color
acciaio, oggetti; Rampino sempre, paracadute finché ne resta uno):
Lanciarune `479`, Lama di Nucleo `593`, Rampino `707`, Paracadute `801`; con
una secondaria scelta (`prova_secondaria`) `432`, `546`, `660`, `754`, `848`.
Con `prova_armi` le posizioni sono nei commenti di `scenari/oggetti.txt`.
Home: GIOCA (online) `1075 102`, STESSO TELEFONO `1075 235`, ARMERIA `168 108`.
Scenario della home: `scenari/home.txt`. Turno con due attacchi (barra gialla e blu, teletrasporti guadagnati): `scenari/turno.txt`. 2 contro 2: `scenari/squadre.txt` (`imposta giocatori 2v2`, o `ffa` per tutti contro tutti). Oggetti tattici (trappola, scudo, trampolino, paracadute): `scenari/oggetti.txt`; su un trampolino rimbalza tutto (l'Uovo): `scenari/trampolino.txt`. Effetti di stato: `scenari/stati.txt`. Scelta delle armi d'inizio partita (primaria e secondaria): `scenari/scelta.txt`. Secondarie e Tonante: `scenari/secondarie.txt`; Maglio: `scenari/maglio.txt`; Affondo: `scenari/affondo.txt`; Rampino (oggetto, uno a turno, sale sulla piattaforma colpita): `scenari/rampino.txt`; Rampino che trascina un nemico a terra: `scenari/rampino_nemico.txt`; Cecchino: `scenari/cecchino.txt`. Le skin di tutte le armi in mano e dei colpi in volo: `scenari/armi.txt`.
Fine partita, podio, armeria e albero di abilità: `scenari/podio.txt`.

Per guidare il robot il gioco, solo in questa build, scrive nel log righe
`SIMULA evento ...` e `SIMULA stato ...` (impostazione `megablast.simula = 1`
in `client/main/game.gui_script`). Nella build normale è spento.

## Cosa non vede

Solo Sergio può giudicare la sensazione sul telefono vero: fluidità a 60-120 Hz,
risposta al tocco, prestazioni sui telefoni deboli. Qui il rendering è software,
quindi il frame rate non dice niente sulla GPU di un telefono. Non si provano
neanche il gioco online e l'audio.
