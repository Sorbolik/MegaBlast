# Preparare il PC per sviluppare MegaBlast

Bastano quattro programmi, tutti gratuiti.

| Cosa | A cosa serve | Dove si scarica |
|---|---|---|
| **Git** | scaricare e aggiornare il repository | https://git-scm.com/downloads |
| **Defold** | editor e motore del client (include tutto: compilatore, debugger, export Android) | https://defold.com/download/ |
| **Go** | compilare ed eseguire il server | https://go.dev/dl/ |
| **VS Code** (facoltativo) | editor di testo per Lua e Go | https://code.visualstudio.com/ |

L'editor di Defold ha già un editor di codice integrato, quindi VS Code serve solo se lo preferisci. In quel caso installa le estensioni **Lua** (sumneko) e **Go**.

Non servono Android Studio né l'SDK Android: Defold crea l'APK da solo.

## 1. Scarica il repository

```bash
git clone https://github.com/Sorbolik/MegaBlast.git
cd MegaBlast
```

## 2. Verifica le installazioni

```bash
git --version
go version
```

Defold si avvia come un normale programma e non richiede configurazione.

## 3. Avviare il prototipo

1. Apri Defold e scegli **Open From Disk…**, poi seleziona `client/game.project`.
2. Premi **Ctrl+B** (su Mac **Cmd+B**) per avviare il gioco in una finestra sul PC.

### Comandi

- **Muoversi**: frecce o A/D, oppure i pulsanti `<` e `>` in basso a sinistra.
- **Saltare**: freccia su, W o spazio, oppure il pulsante SALTA. Senza direzione il salto va dritto in alto; in aria puoi spostarti a destra e a sinistra.
- **Sparare**: tieni premuto il mouse o il dito in un punto qualsiasi della mappa. La direzione dal robot al dito è la mira, la distanza è la potenza, e i puntini mostrano la traiettoria. Rilascia per sparare. Se rilasci sopra il robot, lo sparo viene annullato.
- Dopo lo sparo hai 3 secondi per muoverti e metterti al riparo.
- I due giocatori si alternano sullo stesso dispositivo, con 15 secondi per turno.
- A fine partita tocca lo schermo per tornare al menu.

### Test della simulazione

La logica di gioco in `client/sim/` è Lua puro e si prova anche senza Defold. Con un interprete Lua 5.1 o LuaJIT installato, dalla radice del repository:

```bash
lua tests/sim_test.lua
```

### Simulazione automatica (Linux)

Claude prova il gioco da solo, senza Defold: compila, lo avvia su uno schermo virtuale, gioca uno scenario e salva foto e video. Vedi [strumenti/simula/README.md](../strumenti/simula/README.md).

## 4. Provarlo sul telefono Android

Ci sono due modi.

**Modo veloce (consigliato mentre sviluppi)**: installa sul telefono la *development app* di Defold. La trovi nella pagina delle release di Defold come `dmengine.apk`. Mettila sulla stessa rete Wi-Fi del PC e aprila. In Defold scegli **Project → Target** e seleziona il telefono. Da quel momento Ctrl+B avvia il gioco direttamente sul telefono, e le modifiche al codice si ricaricano senza reinstallare.

**APK vero**: in Defold scegli **Project → Bundle → Android Application…**, crea l'APK e installalo sul telefono. Per installarlo devi abilitare l'installazione da origini sconosciute.

**APK su Telegram (automatico)**: a ogni push su `main`, GitHub Actions ([.github/workflows/apk.yml](../.github/workflows/apk.yml)) costruisce l'APK con l'online, lo firma con la tua chiave e il bot **@ultrablastbot** te lo manda su Telegram e subito dopo un messaggio con le novità: per ogni PR entrata su main dalla build precedente titolo, numero, ramo e la sezione **Per Telegram** del corpo della PR (`strumenti/apk/novita.py`) (qualche minuto di Actions, dentro i minuti gratuiti del piano). Si lancia anche a mano: **Actions → APK su Telegram → Run workflow**. Servono, una volta sola, i segreti del repository (**Settings → Secrets and variables → Actions**): `ANDROID_KEYSTORE` (la chiave `client/debug.keystore` in base64: in PowerShell `[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\Sviluppo\MegaBlast\client\debug.keystore")) | Set-Clipboard`), `ANDROID_KEYSTORE_PASS` (la password della chiave, cioè il contenuto del file `.pass.txt` accanto), `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`. La variabile `SERVER_URL` (scheda **Variables**) dice all'APK dove sta il server, per esempio `ws://192.168.1.20:8080/ws`; senza resta quella di `game.project`. Le sessioni cloud di Claude hanno gli stessi token di Telegram nell'ambiente e possono mandarti file con `sendDocument` (massimo 50 MB).

Per iOS servono un Mac e un account Apple Developer, quindi lo lasciamo a più avanti.

## 5. Giocare online

Il server gira sul tuo PC e i telefoni si collegano a lui tramite il Wi-Fi di casa.

1. Dalla radice del repository avvia il server:

   ```bash
   go run ./server
   ```

   Si mette in ascolto sulla porta 8080. La prima volta Windows ti chiede se consentire l'accesso alla rete: rispondi **Consenti** per le reti private.

2. Trova l'indirizzo IP del PC: in PowerShell scrivi `ipconfig` e cerca "Indirizzo IPv4", per esempio `192.168.1.20`.
3. In Defold apri `client/game.project` e, in fondo, cambia `server_url` con l'IP del PC, per esempio `ws://192.168.1.20:8080/ws`.
4. Crea l'APK (vedi il punto 4) e installalo su due telefoni collegati allo stesso Wi-Fi. In alternativa usa un telefono e il gioco lanciato dal PC con Ctrl+B.
5. Su entrambi premi **ONLINE**: il primo resta in attesa e appena arriva il secondo la partita parte.

**Prima volta**: per il gioco online serve l'estensione WebSocket indicata in `game.project`. In Defold usa **Project → Fetch Libraries** e poi Ctrl+B. Il primo avvio è più lento, perché Defold compila il motore con l'estensione sul suo build server e serve internet.

### Test del server

```bash
go test ./server/
```
