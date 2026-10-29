#!/usr/bin/env bash
# Scrive la didascalia dell'APK per Telegram: commit corto e cosa è entrato in
# main dalla build precedente (titoli delle PR, uno per riga).
# Uso: novita.sh [COMMIT_PRIMA]   (vuoto o assente: solo l'ultimo commit)
set -euo pipefail
prima="${1:-}"
if [[ -n "$prima" && ! "$prima" =~ ^0+$ ]] && git cat-file -e "$prima^{commit}" 2>/dev/null; then
	giro="$prima..HEAD"
else
	giro="HEAD~1..HEAD"
fi
righe=()
while read -r h; do
	titolo="$(git log -1 --format=%s "$h")"
	# "Merge pull request #73 from ...": il titolo vero della PR è la prima riga del corpo
	if [[ "$titolo" =~ ^Merge\ pull\ request\ (#[0-9]+) ]]; then
		numero="${BASH_REMATCH[1]}"
		titolo="$(git log -1 --format=%b "$h" | sed '/^\s*$/d' | head -1) ($numero)"
	fi
	righe+=("• $titolo")
done < <(git log --first-parent --format=%H "$giro")
testo="MegaBlast $(git log -1 --format=%h) ($(date -u +%d/%m))"$'\n'"Novità:"
for r in "${righe[@]}"; do testo+=$'\n'"$r"; done
# Telegram accetta didascalie fino a 1024 caratteri
if (( ${#testo} > 1000 )); then testo="${testo:0:990}"$'\n'"…"; fi
printf '%s\n' "$testo"
