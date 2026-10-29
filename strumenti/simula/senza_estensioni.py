#!/usr/bin/env python3
"""Copia del client senza le estensioni native (le cartelle con ext.manifest).

Le estensioni native (client/vibra) si compilano sul build server di Defold, che
dal cloud non si raggiunge: simulazione e build web compilano questa copia.
La cartella build/ della copia resta, così bob non ricompila tutto ogni volta.

Uso: python3 strumenti/simula/senza_estensioni.py DESTINAZIONE
"""
import shutil
import sys
from pathlib import Path

CLIENT = Path(__file__).resolve().parents[2] / "client"


def copia(dest, client=CLIENT):
    dest = Path(dest)
    dest.mkdir(parents=True, exist_ok=True)
    for e in dest.iterdir():
        if e.name == "build":
            continue
        if e.is_dir() and not e.is_symlink():
            shutil.rmtree(e)
        else:
            e.unlink()
    for e in client.iterdir():
        if e.name == "build" or (e.is_dir() and (e / "ext.manifest").exists()):
            continue
        if e.is_dir():
            shutil.copytree(e, dest / e.name)  # copy2: tiene le date, bob riusa la cache
        else:
            shutil.copy2(e, dest / e.name)
    return dest


if __name__ == "__main__":
    copia(sys.argv[1])
