#!/usr/bin/env bash
# Porta il server di MegaBlast sul VPS: compila il Go per il processore del VPS,
# copia il file, riavvia il servizio e controlla /health. Lo usa il workflow
# "Server sul VPS" a ogni merge su main che tocca il server o la simulazione;
# si lancia anche a mano da un computer con ssh e Go (dalla radice del repo):
#
#   bash tools/vps/aggiorna.sh root@IP [CHIAVE_SSH]
#   INSTALLA=1 DOMINIO=… EVENTI=… bash tools/vps/aggiorna.sh root@IP CHIAVE   (prima rilancia installa.sh)
#
# Il riavvio aspetta la fine delle partite in corso (al più 10 minuti): chi è in
# coda riceve "draining" e torna appena il server riparte.
set -euo pipefail
DOVE=${1:?uso: aggiorna.sh root@IP [CHIAVE_SSH]}
SSH_OPZ=(-o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30)
[ -n "${2:-}" ] && SSH_OPZ+=(-i "$2")
cd "$(dirname "$0")/../.."
remoto() { ssh "${SSH_OPZ[@]}" "$DOVE" "$@"; }

# la prima volta (niente servizio sul VPS) l'installazione si fa da sola
remoto 'test -f /etc/systemd/system/megablast.service' || INSTALLA=1
if [ -n "${INSTALLA:-}" ]; then
  echo "== installa.sh sul VPS"
  scp "${SSH_OPZ[@]}" tools/vps/installa.sh "$DOVE:/root/installa.sh"
  remoto "DOMINIO='${DOMINIO:-}' EVENTI='${EVENTI:-}' NODO='${NODO:-}' bash /root/installa.sh"
fi

case "$(remoto uname -m)" in
  x86_64) ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  *) echo "processore del VPS sconosciuto"; exit 1 ;;
esac
echo "== compilo il server (linux/$ARCH)"
FILE=$(mktemp)
CGO_ENABLED=0 GOOS=linux GOARCH=$ARCH go build -trimpath -ldflags "-s -w" -o "$FILE" ./server

echo "== copio e riavvio"
scp "${SSH_OPZ[@]}" "$FILE" "$DOVE:/opt/megablast/megablast-server.nuovo"
rm -f "$FILE"
remoto 'set -e
cd /opt/megablast
chmod 755 megablast-server.nuovo
[ -f megablast-server ] && cp -p megablast-server megablast-server.prima
mv megablast-server.nuovo megablast-server
systemctl restart megablast.service'

echo "== controllo /health"
for i in $(seq 1 30); do
  if remoto 'curl -fsS -o /dev/null http://127.0.0.1:8080/health'; then
    remoto 'curl -fsS http://127.0.0.1:8080/stats'; echo
    echo "OK: server aggiornato"
    exit 0
  fi
  sleep 2
done
echo "il server non risponde: torno al file di prima"
remoto 'cd /opt/megablast && [ -f megablast-server.prima ] && mv megablast-server.prima megablast-server && systemctl restart megablast.service; journalctl -u megablast --no-pager -n 30'
exit 1
