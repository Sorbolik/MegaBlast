# Simulare il gioco senza Defold

`simula.py` compila il client e lo fa giocare da solo su uno schermo virtuale,
così gli errori si vedono prima di aprire Defold. Serve soprattutto a Claude
nelle sessioni cloud, ma gira su qualsiasi Linux (Ubuntu/Debian).

```bash
bash strumenti/simula/prepara.sh          # una volta: Java 25, bob.jar 1.14.0, Xvfb, xdotool, ffmpeg, luajit
python3 strumenti/simula/simula.py        # controlli, test, build e partita con lo scenario base
python3 strumenti/simula/simula.py -s strumenti/simula/scenari/mio.txt
python3 strumenti/simula/simula.py --solo-build    # senza avviare il gioco
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
| `zoom NOME` | foto ingrandita 2x attorno al robot di turno |
| `tocca X Y` | tocco breve (pulsanti, menu) |
| `tieni TASTO S` | tiene premuto un tasto: `sinistra`, `destra`, `salta`, o un nome di xdotool |
| `premi TASTO` | pressione breve |
| `trascina X1 Y1 X2 Y2 [S]` | trascina il dito |
| `mira DX DY [S] [FOTO]` | tiene il dito a (DX, DY) dal robot di turno per S secondi (la mira), facoltativamente scatta FOTO, poi lascia: spara con l'arma scelta |
| `aspetta_evento TIPO [S]` | aspetta un evento della simulazione (`fire`, `explosion`, `swing`, `sword_hit`, `orb`, `teleport`, `damage`, `turn`, `over`...) |
| `aspetta_stato chiave=valore ... [S]` | aspetta uno stato, per esempio `turno=2 fase=aim` (chiavi: `modo`, `turno`, `fase`, `x`, `y`) |

Pulsanti della battaglia: arma (MISSILE/SPADA) `1190 210`, TELE `1040 80`,
SALTA `1190 80`, `<` `80 80`, `>` `210 80`. Menu: STESSO TELEFONO `640 390`.

Per guidare il robot il gioco, solo in questa build, scrive nel log righe
`SIMULA evento ...` e `SIMULA stato ...` (impostazione `megablast.simula = 1`
in `client/main/game.gui_script`). Nella build normale è spento.

## Cosa non vede

Solo Sergio può giudicare la sensazione sul telefono vero: fluidità a 60-120 Hz,
risposta al tocco, prestazioni sui telefoni deboli. Qui il rendering è software,
quindi il frame rate non dice niente sulla GPU di un telefono. Non si provano
neanche il gioco online e l'audio.
