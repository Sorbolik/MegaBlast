#!/bin/sh
# Build di Cloudflare per l'editor delle animazioni (repository collegato a
# Cloudflare, Path strumenti/animazioni/cloudflare, deploy npx wrangler deploy):
# prepara la pagina e la mette in dist/index.html; worker.js fa "Manda a Claude".
set -e
cd "$(dirname "$0")"
python3 ../prepara.py
mkdir -p dist
cp ../../../simulazione/animazioni/editor.html dist/index.html
