#!/bin/bash
# Nelle sessioni cloud di Claude installa gli strumenti per simulare il gioco
# (strumenti/simula/simula.py). Sul PC di Sergio non fa niente.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	exit 0
fi

bash "$CLAUDE_PROJECT_DIR/strumenti/simula/prepara.sh"
