#!/bin/sh
# Build di Cloudflare Pages per l'editor delle animazioni (repository collegato a
# Cloudflare, Root directory strumenti/animazioni/cloudflare, Build output dist):
# prepara la pagina e la mette in dist/index.html; functions/ fa "Manda a Claude".
set -e
cd "$(dirname "$0")"
python3 ../prepara.py
mkdir -p dist
cp ../../../simulazione/animazioni/editor.html dist/index.html
