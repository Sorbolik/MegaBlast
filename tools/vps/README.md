# Server sul VPS

Il server di MegaBlast gira su un VPS Hetzner Cloud (Ubuntu 24.04, Germania,
nome `megablast-1`). Due script:

- `installa.sh` prepara il VPS, da root, e si può rilanciare: LuaJIT, utente
  `megablast` senza accesso né root, servizio systemd `megablast` (riparte da
  solo, aspetta la fine delle partite quando si spegne), Caddy davanti
  (WebSocket e TLS automatico col dominio), firewall con solo 22, 80 e 443, SSH
  solo con chiave, aggiornamenti di sicurezza automatici, copia dei dati ogni
  notte in `/var/backups/megablast` (14 giorni).
- `aggiorna.sh root@IP [CHIAVE]` compila il server per il processore del VPS
  (x86 o ARM), lo copia in `/opt/megablast`, riavvia il servizio e controlla
  `/health`; se non risponde torna al file di prima.

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
