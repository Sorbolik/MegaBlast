#!/usr/bin/env python3
"""Confronto prima/dopo: le stesse partite di bot giocate su due versioni del
repository devono dare le stesse impronte, tick per tick (registra.lua).

Serve alle PR che non devono cambiare il gioco (pulizia, traduzione, rinomi):
se una sola partita diverge, dice quale e a che secondo, ed esce con 1.

Uso (dalla radice del repository):
  python3 tools/confronta/confronta.py                 200 partite + missioni, contro origin/main
  python3 tools/confronta/confronta.py --base HEAD~1   contro un'altra versione
  python3 tools/confronta/confronta.py --partite 20    più veloce, per provare

La versione di base si prende con git worktree in una cartella temporanea.
Ogni versione usa il suo registra.lua (se la base non ce l'ha, quello di qui):
così una traduzione che rinomina anche lo strumento si confronta lo stesso.
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

QUI = Path(__file__).resolve().parent
REPO = QUI.parents[1]
REGISTRA = QUI.relative_to(REPO) / "registra.lua"


def registra(radice, script, da, n, missioni, ogni):
    cmd = ["luajit", str(script), "--partite", str(n), "--da", str(da), "--ogni", str(ogni),
           "--missioni", "1" if missioni else "0"]
    r = subprocess.run(cmd, cwd=radice, text=True, capture_output=True)
    if r.returncode != 0:
        raise SystemExit(f"registra.lua è fallito in {radice}:\n{r.stderr}")
    return r.stdout.splitlines()


def gioca(radice, script, partite, ogni, lavori):
    """Le partite divise in pezzi, uno per core; le missioni nell'ultimo pezzo."""
    pezzi, passo = [], max(1, -(-partite // lavori))
    for da in range(1, partite + 1, passo):
        pezzi.append((da, min(passo, partite - da + 1), False))
    pezzi.append((1, 0, True))
    with ThreadPoolExecutor(lavori) as ex:
        uscite = ex.map(lambda p: registra(radice, script, p[0], p[1], p[2], ogni), pezzi)
    return [riga for u in uscite for riga in u]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base", default="origin/main", help="versione con cui confrontare (default origin/main)")
    ap.add_argument("--partite", type=int, default=200)
    ap.add_argument("--ogni", type=int, default=10, help="tick tra un'impronta e l'altra")
    ap.add_argument("--lavori", type=int, default=os.cpu_count() or 2)
    a = ap.parse_args()

    tmp = Path(tempfile.mkdtemp(prefix="confronta-"))
    base = tmp / "base"
    try:
        subprocess.run(["git", "worktree", "add", "--detach", "-q", str(base), a.base], cwd=REPO, check=True)
        script_base = REGISTRA
        if not (base / REGISTRA).exists():
            script_base = tmp / "registra.lua"
            shutil.copy(REPO / REGISTRA, script_base)
        # le due versioni insieme, metà dei core ciascuna
        lavori = max(1, a.lavori // 2)
        with ThreadPoolExecutor(2) as ex:
            fb = ex.submit(gioca, base, script_base, a.partite, a.ogni, lavori)
            fq = ex.submit(gioca, REPO, REGISTRA, a.partite, a.ogni, lavori)
            prima, dopo = fb.result(), fq.result()
    finally:
        subprocess.run(["git", "worktree", "remove", "--force", str(base)], cwd=REPO)
        shutil.rmtree(tmp, ignore_errors=True)

    diverse = 0
    if len(prima) != len(dopo):
        print(f"DIVERSO: {len(prima)} partite prima, {len(dopo)} dopo")
        diverse += 1
    for p, d in zip(prima, dopo):
        p, d = p.split(), d.split()
        if p == d:
            continue
        diverse += 1
        nome = " ".join(p[:2])
        i = next((k for k, (x, y) in enumerate(zip(p[2:], d[2:])) if x != y), min(len(p), len(d)) - 2)
        print(f"DIVERSO: {nome} dal secondo {i * a.ogni / 60:.1f} "
              f"({len(p) - 2} impronte prima, {len(d) - 2} dopo)")
    n = len(prima)
    if diverse:
        print(f"FALLITO: {diverse} partite diverse su {n}")
        sys.exit(1)
    print(f"OK: {n} partite identiche a {a.base} ({a.partite} di bot e {n - a.partite} missioni)")


if __name__ == "__main__":
    main()
