#!/usr/bin/env bash
# Prepara un VPS Ubuntu (24.04 o più nuovo) per il server di MegaBlast. Si lancia da root sul
# VPS e si può rilanciare quante volte si vuole: rifà solo quello che manca.
#
#   sudo DOMINIO=gioco.esempio.it EVENTI=https://…/eventi.json bash installa.sh
#
# Senza DOMINIO Caddy risponde sulla porta 80 dell'IP senza TLS (ws://IP/ws),
# solo per la prima prova. Con DOMINIO (un record A verso l'IP del VPS) Caddy
# prende da solo il certificato e il gioco usa wss://DOMINIO/ws.
# Il file del server lo porta aggiorna.sh (dalle Actions o dal PC): qui solo
# il posto, l'utente e il servizio. Spiegazioni in tools/vps/README.md.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "da lanciare come root"; exit 1; }

UTENTE=megablast
CASA=/opt/megablast          # il file del server (megablast-server)
DATI=/var/lib/megablast      # i dati che restano (domani SQLite)
CONF=/etc/megablast/server.env
export DEBIAN_FRONTEND=noninteractive

echo "== pacchetti"
apt-get update -q
apt-get install -y -q --no-install-recommends luajit caddy ufw sqlite3 curl ca-certificates unattended-upgrades
echo "sistema: $(. /etc/os-release; echo "$PRETTY_NAME"), processore $(uname -m)"
apt-get -y -q upgrade

echo "== utente $UTENTE (senza accesso, senza root)"
id "$UTENTE" >/dev/null 2>&1 || useradd --system --home-dir "$DATI" --shell /usr/sbin/nologin "$UTENTE"
install -d -o root -g root -m 755 "$CASA"
install -d -o "$UTENTE" -g "$UTENTE" -m 750 "$DATI"
install -d -m 755 /etc/megablast

# le impostazioni del server: si scrivono la prima volta, poi si cambiano a mano
# (o rilanciando con EVENTI=… / NODO=…)
if [ ! -f "$CONF" ] || [ -n "${EVENTI:-}${NODO:-}" ]; then
  vecchio_eventi=$(sed -n 's/^EVENTI=//p' "$CONF" 2>/dev/null || true)
  vecchio_nodo=$(sed -n 's/^NODO=//p' "$CONF" 2>/dev/null || true)
  cat > "$CONF" <<CONF
# Impostazioni del server di MegaBlast (tools/vps/installa.sh)
# NODO: nome del nodo, entra nei gettoni di riconnessione
NODO=${NODO:-${vecchio_nodo:-eu1}}
# EVENTI: calendario degli eventi (https://megablast-eventi.….workers.dev/eventi.json), vuoto = nessuno
EVENTI=${EVENTI:-$vecchio_eventi}
CONF
fi

echo "== servizio systemd"
cat > /etc/systemd/system/megablast.service <<UNIT
[Unit]
Description=Server di MegaBlast
After=network-online.target
Wants=network-online.target

[Service]
User=$UTENTE
Group=$UTENTE
EnvironmentFile=$CONF
WorkingDirectory=$DATI
ExecStart=$CASA/megablast-server -addr 127.0.0.1:8080 -node \${NODO} -eventi "\${EVENTI}" -luajit /usr/bin/luajit
Restart=always
RestartSec=2
# Lo spegnimento aspetta la fine delle partite (main.go, al più 10 minuti).
# KillMode=mixed: il SIGTERM va solo al Go, non ai processi luajit che fanno
# girare le partite in corso.
KillMode=mixed
TimeoutStopSec=11min
LimitNOFILE=65536
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$DATI

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable megablast.service >/dev/null
# parte solo quando c'è il file del server
[ -x "$CASA/megablast-server" ] && systemctl restart megablast.service

echo "== Caddy (proxy davanti al server, TLS se c'è il dominio)"
if [ -n "${DOMINIO:-}" ]; then INDIRIZZO="$DOMINIO"; else INDIRIZZO=":80"; fi
cat > /etc/caddy/Caddyfile <<CADDY
# tools/vps/installa.sh: tutto al server di MegaBlast, WebSocket compresa
$INDIRIZZO {
	encode gzip
	reverse_proxy 127.0.0.1:8080
}
CADDY
systemctl enable caddy >/dev/null
systemctl reload caddy 2>/dev/null || systemctl restart caddy

echo "== firewall: solo 22, 80, 443"
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
ufw allow 22/tcp >/dev/null
ufw allow 80/tcp >/dev/null
ufw allow 443/tcp >/dev/null
ufw --force enable >/dev/null

echo "== SSH solo con la chiave"
cat > /etc/ssh/sshd_config.d/10-megablast.conf <<SSH
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
SSH
# controlla la configurazione prima; su Ubuntu 24.04 ssh parte a richiesta (ssh.socket):
# se il servizio è fermo la nuova configurazione vale già dalla prossima connessione
sshd -t
systemctl try-reload-or-restart ssh.service 2>/dev/null || systemctl try-reload-or-restart sshd.service 2>/dev/null || true

echo "== aggiornamenti di sicurezza automatici"
cat > /etc/apt/apt.conf.d/20auto-upgrades <<APT
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT
# i riavvii del sistema no: li decide Sergio (le partite in corso cadrebbero)

echo "== copia dei dati ogni notte (14 giorni)"
cat > /usr/local/sbin/megablast-copia <<'COPIA'
#!/usr/bin/env bash
# Copia di /var/lib/megablast in /var/backups/megablast: i database SQLite con
# .backup (copia coerente anche col server acceso), il resto così com'è.
set -euo pipefail
quando=$(date +%Y-%m-%d)
dest=/var/backups/megablast/$quando
mkdir -p "$dest"
cd /var/lib/megablast
find . -type f ! -name '*.db' ! -name '*.db-wal' ! -name '*.db-shm' -exec cp --parents {} "$dest" \;
for db in $(find . -name '*.db'); do
  mkdir -p "$dest/$(dirname "$db")"
  sqlite3 "$db" ".backup '$dest/$db'"
done
cp /etc/megablast/server.env "$dest/"
find /var/backups/megablast -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} +
COPIA
chmod 755 /usr/local/sbin/megablast-copia
cat > /etc/systemd/system/megablast-copia.service <<UNIT
[Unit]
Description=Copia dei dati di MegaBlast
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/megablast-copia
UNIT
cat > /etc/systemd/system/megablast-copia.timer <<UNIT
[Unit]
Description=Copia dei dati di MegaBlast ogni notte
[Timer]
OnCalendar=*-*-* 04:30
Persistent=true
[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable --now megablast-copia.timer >/dev/null

echo "== fatto"
if [ -x "$CASA/megablast-server" ]; then
  systemctl --no-pager --lines=3 status megablast.service || true
else
  echo "manca il file del server: lancia tools/vps/aggiorna.sh (o il workflow Server sul VPS)"
fi
