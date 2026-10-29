#!/usr/bin/env bash
# Build HTML5 (wasm) del client per provarlo nel browser del telefono (Safari su iPhone).
# Prepara in simulazione/web/ la cartella da pubblicare come Artifact di claude.ai:
# megablast.html è la pagina, il resto sono i file del motore e dell'archivio.
# Senza estensione WebSocket (si compila sul build server di Defold, che dal cloud
# non si raggiunge): l'online passa dalla WebSocket del browser (client/main/ws_browser.lua).
set -euo pipefail
QUI="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$QUI/../.." && pwd)"
CACHE="${MEGABLAST_CACHE:-$HOME/.cache/megablast}"
JAVA=/usr/lib/jvm/java-25-openjdk-amd64/bin/java
[ -f "$CACHE/bob.jar" ] && [ -x "$JAVA" ] || bash "$REPO/strumenti/simula/prepara.sh"

OUT="$REPO/simulazione/web"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
printf "[project]\ndependencies#0 =\n\n[native_extension]\napp_manifest =\n" > "$TMP/web.ini"
"$JAVA" -jar "$CACHE/bob.jar" --root "$REPO/client" --output build/web/default --settings "$TMP/web.ini" \
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
