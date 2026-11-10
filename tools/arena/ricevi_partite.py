#!/usr/bin/env python3
"""Riceve dal telefono (adb, Debug wireless) le ricette delle partite giocate.

L'APK coi log stampa ogni partita locale finita come righe
`RICETTA id parte/totale testo`; qui si rimettono insieme e si salvano in
simulazione/partite_sergio/<id>.json (la ricetta, come la scrive sim/replay.lua).

    adb pair IP:PORTA CODICE ; adb connect IP:PORTA        # una volta (docs/prestazioni.md)
    python3 tools/arena/ricevi_partite.py                  # lascia aperto mentre si gioca
    python3 tools/arena/ricevi_partite.py --adb C:\\percorso\\adb.exe
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

RIGA = re.compile(r"RICETTA (\S+) (\d+)/(\d+) (.*)$")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--adb", default="adb")
    ap.add_argument("--cartella", default=str(Path(__file__).resolve().parents[2] / "simulazione" / "partite_sergio"))
    args = ap.parse_args()
    cartella = Path(args.cartella)
    cartella.mkdir(parents=True, exist_ok=True)
    subprocess.run([args.adb, "logcat", "-c"], check=False)
    pezzi = {}
    proc = subprocess.Popen([args.adb, "logcat", "-s", "defold:*"], stdout=subprocess.PIPE, text=True, encoding="utf-8", errors="replace")
    print("in ascolto: gioca sul telefono (Ctrl+C per fermare)", flush=True)
    for riga in proc.stdout:
        m = RIGA.search(riga.rstrip("\n"))
        if not m:
            continue
        pid, k, tot, testo = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)
        p = pezzi.setdefault(pid, {})
        p[k] = testo
        if len(p) == tot:
            try:
                ricetta = json.loads("".join(p[i] for i in range(1, tot + 1)))
            except (KeyError, ValueError) as e:
                print(f"partita {pid}: ricetta rovinata ({e})", file=sys.stderr)
            else:
                (cartella / f"{pid}.json").write_text(json.dumps(ricetta), encoding="utf-8")
                print(f"partita {pid} salvata ({tot} righe)", flush=True)
            del pezzi[pid]


if __name__ == "__main__":
    main()
