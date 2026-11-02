#!/usr/bin/env bash
# Tutti i controlli che non hanno bisogno di Defold, gli stessi che GitHub fa
# su ogni PR (.github/workflows/controlli.yml). Dalla radice del repository:
#   bash strumenti/controlli/tutti.sh
# Servono luajit, python3 e go. Finisce con OK o con l'elenco di cosa è fallito.
cd "$(dirname "$0")/../.."
falliti=()

passo() {
	local nome="$1"; shift
	echo "== $nome"
	if ! "$@"; then falliti+=("$nome"); fi
}

# un file di test fallisce se esce con errore o se stampa una riga FAIL
test_lua() {
	local out
	out=$(luajit "$1" 2>&1)
	local esito=$?
	if [ $esito -ne 0 ] || grep -q '^FAIL' <<<"$out"; then
		grep -E '^FAIL|rror|traceback' <<<"$out" | head -40
		return 1
	fi
	echo "$(grep -c '^ok' <<<"$out") controlli ok"
}

passo "globali e sintassi Lua" python3 strumenti/controlli/globali.py
passo "controlli dell'editor di Defold" python3 strumenti/simula/controlla.py client
for f in tests/*_test.lua; do
	passo "$f" test_lua "$f"
done
passo "go vet" go vet ./...
passo "gofmt" bash -c 'f=$(gofmt -l server simfs.go); [ -z "$f" ] || { echo "da formattare con gofmt -w: $f"; false; }'
passo "go test ./server/" go test ./server/

if [ ${#falliti[@]} -gt 0 ]; then
	echo "FALLITO: ${falliti[*]}"
	exit 1
fi
echo "OK"
