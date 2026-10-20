#!/usr/bin/env bash
# Installa quello che serve a strumenti/simula/simula.py su Ubuntu/Debian (le
# sessioni cloud di Claude): Java 25 per bob.jar, bob.jar di Defold 1.14.0,
# Xvfb (schermo virtuale), xdotool (mouse e tastiera finti), ffmpeg (foto e
# video), luajit (test della simulazione) e le librerie OpenGL software.
# Se è già tutto installato non fa niente, quindi si può lanciare a ogni avvio.
set -euo pipefail

DEFOLD=1.14.0
CACHE="${MEGABLAST_CACHE:-$HOME/.cache/megablast}"
JAVA=/usr/lib/jvm/java-25-openjdk-amd64/bin/java
PACCHETTI="openjdk-25-jre-headless xvfb xdotool x11-utils ffmpeg luajit libglu1-mesa libgl1-mesa-dri"

manca=""
for p in $PACCHETTI; do
	dpkg -s "$p" >/dev/null 2>&1 || manca="$manca $p"
done
if [ -n "$manca" ]; then
	SUDO=""
	[ "$(id -u)" -ne 0 ] && SUDO="sudo"
	echo "[prepara] installo:$manca"
	$SUDO apt-get update -qq
	DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq $manca >/dev/null
fi

mkdir -p "$CACHE"
if [ ! -s "$CACHE/bob.jar" ] || [ "$(cat "$CACHE/bob.version" 2>/dev/null)" != "$DEFOLD" ]; then
	echo "[prepara] scarico bob.jar $DEFOLD"
	curl -fsSL --retry 4 -o "$CACHE/bob.jar.tmp" "https://github.com/defold/defold/releases/download/$DEFOLD/bob.jar"
	mv "$CACHE/bob.jar.tmp" "$CACHE/bob.jar"
	echo "$DEFOLD" > "$CACHE/bob.version"
fi

"$JAVA" -version >/dev/null 2>&1
echo "[prepara] pronto: bob $DEFOLD, $("$JAVA" -version 2>&1 | grep -m1 version)"
