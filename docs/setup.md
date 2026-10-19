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
- **Saltare**: freccia su, W o spazio, oppure il pulsante SALTA.
- **Sparare**: tieni premuto il mouse o il dito in un punto qualsiasi della mappa. La direzione dal robot al dito è la mira, la distanza è la potenza, e i puntini mostrano la traiettoria (senza vento). Rilascia per sparare. Se rilasci sopra il robot, lo sparo viene annullato.
- I due giocatori si alternano sullo stesso dispositivo, con 15 secondi per turno.
- A fine partita tocca lo schermo per ricominciare con una mappa nuova.

### Test della simulazione

La logica di gioco in `client/sim/` è Lua puro e si prova anche senza Defold. Con un interprete Lua 5.1 o LuaJIT installato, dalla radice del repository:

```bash
lua tests/sim_test.lua
```

## 4. Provarlo sul telefono Android

Ci sono due modi.

**Modo veloce (consigliato mentre sviluppi)**: installa sul telefono la *development app* di Defold. La trovi nella pagina delle release di Defold come `dmengine.apk`. Mettila sulla stessa rete Wi-Fi del PC e aprila. In Defold scegli **Project → Target** e seleziona il telefono. Da quel momento Ctrl+B avvia il gioco direttamente sul telefono, e le modifiche al codice si ricaricano senza reinstallare.

**APK vero**: in Defold scegli **Project → Bundle → Android Application…**, crea l'APK e installalo sul telefono. Per installarlo devi abilitare l'installazione da origini sconosciute.

Per iOS servono un Mac e un account Apple Developer, quindi lo lasciamo a più avanti.

## 5. Avviare il server (appena c'è)

```bash
cd server
go run .
```

Il server ascolta su `ws://localhost:8080`. Per collegarti dal telefono si usa l'indirizzo IP locale del PC, per esempio `ws://192.168.1.20:8080`.
