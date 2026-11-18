# Server sul VPS

Il server di MegaBlast gira su un VPS Hetzner Cloud (Ubuntu 24.04, Germania,
nome `megablast-1`). Due script:

- `installa.sh` prepara il VPS, da root, e si può rilanciare: LuaJIT, utente
  `megablast` senza accesso né root, servizio systemd `megablast` (riparte da
  solo, aspetta la fine delle partite quando si spegne), Caddy davanti
  (WebSocket e TLS automatico col dominio), firewall con solo 22, 80 e 443, SSH
  solo con chiave, aggiornamenti di sicurezza automatici, copia dei dati ogni
  notte in `/var/backups/megablast` (14 giorni), coi database SQLite (i profili
  ospite, `megablast.db`) anche su Cloudflare R2 quando ci sono i segreti
  `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT` e la variabile
  `R2_BUCKET` (lì 30 giorni; `aggiorna.sh` scrive le chiavi in `/etc/megablast/r2.env`).
- `web.sh root@IP [CHIAVE]` porta il gioco web (la build di `tools/web/build.sh`) in `/opt/megablast/web`.
- `aggiorna.sh root@IP [CHIAVE]` compila il server per il processore del VPS
  (x86 o ARM), lo copia in `/opt/megablast`, riavvia il servizio e controlla
  `/health`; se non risponde torna al file di prima. Rilancia prima `installa.sh` se sul VPS manca il servizio o se lo script è cambiato.

Il workflow **Server sul VPS** (`.github/workflows/server.yml`) lancia
`aggiorna.sh` a ogni merge su main che tocca `server/`, `client/sim/` o questa
cartella; a mano, con "installa", rilancia prima `installa.sh`. Gli servono, in
GitHub > Settings > Secrets and variables > Actions:

| Nome | Tipo | Cosa |
|---|---|---|
| `VPS_SSH_KEY` | segreto | la chiave privata del deploy (la pubblica è sul VPS, messa alla creazione) |
| `VPS_HOST` | variabile | l'IP del VPS (poi il dominio) |
| `VPS_DOMINIO` | variabile, facoltativa | il dominio: Caddy prende il certificato e il gioco usa `wss://DOMINIO/ws` |
| `VPS_EVENTI` | variabile, facoltativa | il calendario del pannello, `https://megablast-eventi.….workers.dev/eventi.json` |
| `SERVER_URL` | variabile | dove lo cerca l'APK: `ws://IP/ws`, poi `wss://DOMINIO/ws` |

**Gioco web**: Caddy serve anche la build HTML5 del gioco (`tools/web/build.sh`)
all'indirizzo del server, `http://IP/` (poi `https://DOMINIO/`), e passa al
server solo `/ws`, `/health`, `/stats` ed `/eventi`. La porta lì `web.sh`, dal
workflow **Gioco web sul VPS** a ogni merge su main che tocca il client.

**Log da lontano**: il workflow **Log del server** (a mano, `log.yml`) stampa le
righe di `journalctl -u megablast` che contengono un testo (di base `ricetta da`)
da un momento (`-1h`, `today`, `2026-11-18 06:00`) a un altro: così lo leggono
anche i thread di Claude, che non raggiungono il VPS. Con "prova" fa anche un
POST di prova a `/ricetta` (da fuori e dal VPS) e mostra il Caddyfile, gli errori
di Caddy e le richieste a `/ricetta` del log di accesso di Caddy
(`/var/log/caddy/megablast.log`, al più 5 file da 10 MB).

Sul VPS: impostazioni in `/etc/megablast/server.env` (nodo, eventi), log con
`journalctl -u megablast -f`, stato con `curl localhost:8080/stats`.

Senza dominio Caddy risponde sulla porta 80 dell'IP, senza TLS: va bene per la
prima prova, non per giocare davvero (le password e i salvataggi che verranno
viaggerebbero in chiaro).

Il gioco in casa non cambia: `client/game.project` resta su `127.0.0.1` (editor,
simulatore, build web servita dal PC), l'APK prende `SERVER_URL`; un APK di
prova verso il PC si chiede a mano da Actions > APK su Telegram con
`server_url` = `ws://192.168.1.9:8080/ws`.

Prova di carico sul VPS: `bash tools/vps/carico.sh root@IP CHIAVE 40 30s 2v2` (o il
workflow a mano con "carico"): compila la prova di carico di `server/load_test.go`,
la lancia sul VPS con persone finte e poi con una persona e i bot, e stampa i numeri.
