#!/bin/sh
# Prepara dist/ per il Worker del Copione: la pagina (con la sua intestazione,
# che su claude.ai mette l'Artifact) e accanto la build web del gioco per GIOCA.
# Serve quello che serve a prepara.py --gioco: luajit, Python con Pillow, Java 25
# e bob.jar (tools/web/build.sh). Lo lancia .github/workflows/copione.yml.
set -e
cd "$(dirname "$0")"
python3 ../prepara.py --gioco
rm -rf dist
mkdir -p dist
cp -r ../../../simulazione/copione/game dist/game
{
	printf '<!doctype html>\n<html lang="it">\n<head>\n<meta charset="utf-8">\n'
	printf '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n'
	printf '<style>[hidden]{display:none!important}body{margin:0}</style>\n</head>\n<body>\n'
	cat ../../../simulazione/copione/index.html
	printf '\n</body>\n</html>\n'
} > dist/index.html
echo "OK: dist"
