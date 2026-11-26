#!/usr/bin/env python3
"""La simulazione deve dare sempre la stessa partita, su ogni telefono, sul
server e su ogni PC: online telefoni e server giocano la stessa partita in
lockstep, e confronta.py serve solo se due giri uguali danno lo stesso risultato.

Due controlli (Sergio, 26 nov: su Windows registra.lua dava partite diverse
cambiando solo i fine riga di bot.lua):
1. in client/sim niente ^ (potenza): LuaJIT la calcola con pow() nell'interprete e
   moltiplicando nel codice compilato (le versioni vecchie), e l'ultima cifra può
   cambiare. Si usa game.ipow (intero) o x * x; una potenza che resta (esponente
   non intero, calcolata una volta) si segna con "-- pow ok".
2. le stesse partite di registra.lua giocate tre volte: normale, senza JIT
   (-joff) e con l'ordine di pairs rimescolato e la memoria spostata (caos.lua).
   Le impronte devono essere identiche.

  python3 tools/confronta/identica.py               4 partite e le missioni (in tutti.sh)
  python3 tools/confronta/identica.py --partite 40  più partite
"""
import argparse
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def potenze():
    """Le righe di client/sim con ^ fuori da testi e commenti"""
    trovate = []
    for f in sorted((REPO / "client" / "sim").glob("*.lua")):
        for n, riga in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            if "-- pow ok" in riga:
                continue
            codice = re.sub(r'"(\\.|[^"\\])*"|\'(\\.|[^\'\\])*\'', '""', riga)
            codice = re.sub(r"\[(=*)\[.*?\]\1\]", "", codice).split("--")[0]
            if "^" in codice:
                trovate.append(f"{f.relative_to(REPO)}:{n}: {riga.strip()}")
    return trovate


def gioca(prima, partite, missioni):
    cmd = ["luajit", *prima, "--partite", str(partite), "--da", "1", "--missioni", "1" if missioni else "0"]
    r = subprocess.run(cmd, cwd=REPO, text=True, capture_output=True)
    if r.returncode != 0:
        raise SystemExit(f"{' '.join(cmd)} è fallito:\n{r.stderr}")
    return r.stdout.splitlines()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--partite", type=int, default=4)
    ap.add_argument("--missioni", type=int, default=1)
    a = ap.parse_args()

    male = 0
    for riga in potenze():
        print("potenza con ^ nella simulazione (usa game.ipow o x * x):", riga)
        male += 1

    registra = "tools/confronta/registra.lua"
    giri = {
        "normale": [registra],
        "senza JIT": ["-joff", registra],
        "pairs a caso": ["tools/confronta/caos.lua", "17"],
    }
    pezzi = [(nome, prima, m) for nome, prima in giri.items() for m in (False, True)
             if m or a.partite > 0 if not m or a.missioni]
    with ThreadPoolExecutor(len(pezzi)) as ex:
        uscite = list(ex.map(lambda p: gioca(p[1], a.partite if not p[2] else 0, p[2]), pezzi))
    righe = {nome: [] for nome in giri}
    for (nome, _, _), u in zip(pezzi, uscite):
        righe[nome] += u
    base = righe["normale"]
    for nome, altre in righe.items():
        for x, y in zip(base, altre):
            if x != y:
                xs, ys = x.split(), y.split()
                i = next(i for i, (p, q) in enumerate(zip(xs, ys)) if p != q)
                print(f"DIVERSO ({nome}): {' '.join(xs[:2])}, dall'impronta {i - 2}")
                male += 1
        if len(altre) != len(base):
            print(f"DIVERSO ({nome}): {len(altre)} partite invece di {len(base)}")
            male += 1
    if male:
        sys.exit(1)
    print(f"OK: {len(base)} partite identiche normali, senza JIT e con pairs a caso")


if __name__ == "__main__":
    main()
