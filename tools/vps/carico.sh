#!/usr/bin/env bash
# Prova di carico sul VPS: compila la prova di carico di server/load_test.go per
# il processore del VPS, la lancia lì (partite con giocatori finti che camminano,
# saltano e sparano, nello stesso processo del server: i numeri sono più bassi
# di quelli veri) e stampa il risultato. Il server vero resta acceso: da fare
# quando non gioca nessuno.
#
#   bash tools/vps/carico.sh root@IP [CHIAVE_SSH] [PARTITE] [DURATA] [MODO]
#   bash tools/vps/carico.sh root@IP chiave 60 30s 2v2
set -euo pipefail
DOVE=${1:?uso: carico.sh root@IP [CHIAVE_SSH] [PARTITE] [DURATA] [MODO]}
PARTITE=${3:-40}; DURATA=${4:-30s}; MODO=${5:-2v2}
SSH_OPZ=(-o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30)
[ -n "${2:-}" ] && SSH_OPZ+=(-i "$2")
cd "$(dirname "$0")/../.."
case "$(ssh "${SSH_OPZ[@]}" "$DOVE" uname -m)" in
  x86_64) ARCH=amd64 ;; aarch64) ARCH=arm64 ;; *) echo "processore sconosciuto"; exit 1 ;;
esac
FILE=$(mktemp)
CGO_ENABLED=0 GOOS=linux GOARCH=$ARCH go test -c -o "$FILE" ./server
scp "${SSH_OPZ[@]}" "$FILE" "$DOVE:/tmp/megablast-carico"
rm -f "$FILE"
for bot in "" "-bot"; do
  echo "== $PARTITE partite $MODO per $DURATA ${bot:+(una persona, il resto bot)}"
  ssh "${SSH_OPZ[@]}" "$DOVE" "cd /tmp && ./megablast-carico -test.run '^TestLoad\$' -test.v -carico $PARTITE -durata $DURATA -modo $MODO $bot 2>&1 | grep -v '^=== RUN'"
done
ssh "${SSH_OPZ[@]}" "$DOVE" "rm -f /tmp/megablast-carico"
