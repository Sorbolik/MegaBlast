#!/bin/bash
# Duels between all the weapons, on all cores: bash strumenti/banco/duelli.sh [COPPIE] [ARMA ...]
# Writes simulazione/banco/duelli.txt (one line per pair) and duelli.md (the table).
set -e
cd "$(dirname "$0")/../.."
N=${1:-10}; shift || true
if [ $# -gt 0 ]; then W=("$@"); else mapfile -t W < <(luajit strumenti/banco/duelli.lua); fi
mkdir -p simulazione/banco
for ((i = 0; i < ${#W[@]}; i++)); do for ((j = i + 1; j < ${#W[@]}; j++)); do echo "${W[i]} ${W[j]}"; done; done |
	xargs -P "$(nproc)" -L 1 sh -c 'luajit strumenti/banco/duelli.lua "$0" "$1" --coppie '"$N" > simulazione/banco/duelli.txt
luajit strumenti/banco/duelli.lua --tabella simulazione/banco/duelli.txt | tee simulazione/banco/duelli.md
