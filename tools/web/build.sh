#!/usr/bin/env bash
# Build HTML5 (wasm) del client per provarlo nel browser del telefono (Safari su iPhone).
# Prepara in simulazione/web/ la cartella da pubblicare come Artifact di claude.ai:
# megablast.html è la pagina, il resto sono i file del motore e dell'archivio.
# Senza estensione WebSocket (si compila sul build server di Defold, che dal cloud
# non si raggiunge): l'online passa dalla WebSocket del browser (client/main/ws_browser.lua).
# La stessa build la serve anche il VPS (tools/vps/web.sh, workflow "Gioco web sul VPS").
set -euo pipefail
QUI="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$QUI/../.." && pwd)"
CACHE="${MEGABLAST_CACHE:-$HOME/.cache/megablast}"
JAVA="${JAVA:-/usr/lib/jvm/java-25-openjdk-amd64/bin/java}"
[ -f "$CACHE/bob.jar" ] && [ -x "$JAVA" ] || bash "$REPO/tools/simula/prepara.sh"

OUT="$REPO/simulazione/web"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# e senza le estensioni native del client (client/vibra): si compila una copia
python3 "$REPO/tools/simula/senza_estensioni.py" "$REPO/simulazione/web_client"
# senza i dipinti HD dei PC (client/paintings_hd): la pagina li caricherebbe tutti
CR="$(grep '^custom_resources' "$REPO/client/game.project" | sed 's#,/paintings_hd##')"
printf "[project]\ndependencies#0 =\n%s\n\n[native_extension]\napp_manifest =\n" "$CR" > "$TMP/web.ini"
# il codice della versione (si vede nelle IMPOSTAZIONI del gioco); PROVA fuori da main
RAMO="${GITHUB_REF_NAME:-$(git -C "$REPO" branch --show-current)}"
printf "\n[megablast]\nversion = %s\ntest = %s\n" "$(git -C "$REPO" log -1 --format=%h)" "$([ "$RAMO" = main ] && echo 0 || echo 1)" >> "$TMP/web.ini"
# l'impronta della simulazione (server/simtree.go): la sua, se client/sim non ha modifiche da salvare
git -C "$REPO" diff --quiet HEAD -- client/sim && printf "sim = %s\n" "$(git -C "$REPO" rev-parse HEAD:client/sim)" >> "$TMP/web.ini"
# SERVER_URL=ws://… : il server di questa build (quella sul VPS); senza, quello di game.project
[ -n "${SERVER_URL:-}" ] && printf "server_url = %s\n" "$SERVER_URL" >> "$TMP/web.ini"
"$JAVA" -jar "$CACHE/bob.jar" --root "$REPO/simulazione/web_client" --output build/web/default --settings "$TMP/web.ini" \
	--platform wasm-web --architectures wasm-web --variant release --archive --texture-compression true \
	--bundle-output "$TMP/bundle" build bundle > "$TMP/build.txt" 2>&1 || { tail -40 "$TMP/build.txt"; exit 1; }

rm -rf "$OUT" && mkdir -p "$OUT"
B="$TMP/bundle/MegaBlast"
cp -r "$B/MegaBlast.wasm" "$B/MegaBlast_wasm.js" "$B/dmloader.js" "$B/archive" "$OUT/"
cp "$QUI/megablast.html" "$OUT/"
# Gli Artifact servono solo tipi web: i pezzi dell'archivio prendono l'estensione .wasm
# (il motore li legge come byte qualsiasi) e archive_files.json li chiama così.
for f in "$OUT"/archive/game*; do mv "$f" "$f.wasm"; done
sed -i -E 's/"(game[0-9]+\.(arcd|arci|dmanifest|projectc))"/"\1.wasm"/g' "$OUT/archive/archive_files.json"
echo "OK: $OUT"
