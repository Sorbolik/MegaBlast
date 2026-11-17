#!/usr/bin/env bash
# Porta il gioco web (la build di tools/web/build.sh) sul VPS, in
# /opt/megablast/web: Caddy lo serve all'indirizzo del server (http://IP/), con
# la WebSocket del server sulla stessa origine. Lo usa il workflow "Gioco web
# sul VPS"; a mano, dalla radice del repo dopo la build:
#
#   bash tools/vps/web.sh root@IP [CHIAVE_SSH] [CARTELLA]   (CARTELLA: simulazione/web)
set -euo pipefail
DOVE=${1:?uso: web.sh root@IP [CHIAVE_SSH] [CARTELLA]}
SSH_OPZ=(-o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30)
[ -n "${2:-}" ] && SSH_OPZ+=(-i "$2")
cd "$(dirname "$0")/../.."
DIR=${3:-simulazione/web}
[ -f "$DIR/megablast.html" ] || { echo "manca la build in $DIR (bash tools/web/build.sh)"; exit 1; }
# la nuova accanto, poi uno scambio di nomi: chi sta scaricando non vede una cartella a metà
tar -C "$DIR" -cz . | ssh "${SSH_OPZ[@]}" "$DOVE" 'set -e
rm -rf /opt/megablast/web.nuovo && mkdir -p /opt/megablast/web.nuovo
tar -xz -C /opt/megablast/web.nuovo
cp /opt/megablast/web.nuovo/megablast.html /opt/megablast/web.nuovo/index.html
chmod -R a+rX /opt/megablast/web.nuovo
rm -rf /opt/megablast/web.prima
[ -d /opt/megablast/web ] && mv /opt/megablast/web /opt/megablast/web.prima
mv /opt/megablast/web.nuovo /opt/megablast/web
rm -rf /opt/megablast/web.prima
du -sh /opt/megablast/web'
