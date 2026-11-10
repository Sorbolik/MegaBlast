#!/usr/bin/env python3
"""Controllo del codice Lua: ogni file deve compilare, e niente variabili
globali sconosciute.

Una globale letta che non esiste è quasi sempre un nome sbagliato (vale nil e
il gioco si rompe solo quando ci passa); una globale scritta è quasi sempre un
`local` dimenticato, che nella simulazione può far divergere una partita
dall'altra. Per saperlo basta il bytecode di LuaJIT
(`luajit -bl`, istruzioni GGET e GSET): nessun programma in più da installare.

Uso: python3 tools/controlli/globali.py     (dalla radice del repository)
Esce con 1 se trova errori.
"""
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
ESTENSIONI = {".lua", ".script", ".gui_script", ".render_script"}
CARTELLE = ("client", "server", "tests", "tools")

LUA = set("""assert collectgarbage dofile error getfenv getmetatable ipairs load loadfile
loadstring module next pairs pcall print rawequal rawget rawset require select setfenv
setmetatable tonumber tostring type unpack xpcall _G _VERSION
coroutine debug io math os package string table bit jit ffi arg""".split())

# I moduli di Defold (defold.com/ref) e quelli delle nostre estensioni
DEFOLD = set("""go gui msg vmath sys hash hash_to_hex pprint timer sound window render resource
buffer json http socket crash profiler image zlib html5 label sprite physics factory
collectionfactory particlefx tilemap model camera collectionproxy b2d liveupdate graphics
font iac iap push webview websocket vibra""".split())

# Le funzioni che Defold chiama in un .script / .gui_script / .render_script
CICLO = set("init final update fixed_update late_update on_message on_input on_reload".split())

ISTRUZIONE = re.compile(r'\b(GGET|GSET)\b.*; "([^"]+)"')


def file_lua():
    out = subprocess.run(["git", "ls-files", *CARTELLE], cwd=REPO, text=True, capture_output=True, check=True)
    return [REPO / p for p in out.stdout.splitlines() if Path(p).suffix in ESTENSIONI]


def controlla(f, errori):
    rel = f.relative_to(REPO).as_posix()
    r = subprocess.run(["luajit", "-bl", str(f)], text=True, capture_output=True, errors="replace")
    if r.returncode != 0:
        errori.append(f"{rel}: non compila: {r.stderr.strip()}")
        return
    lette = LUA | DEFOLD
    scritte = set()
    if f.suffix != ".lua":
        lette |= CICLO
        scritte |= CICLO
    if rel.startswith("tests/"):
        # i test fingono i moduli di Defold (vmath, gui, hash...) per provare il client
        scritte |= DEFOLD
    visti = set()
    for riga in r.stdout.splitlines():
        m = ISTRUZIONE.search(riga)
        if not m:
            continue
        op, nome = m.groups()
        ok = nome in (scritte if op == "GSET" else lette | scritte)
        if not ok and (op, nome) not in visti:
            visti.add((op, nome))
            if op == "GSET":
                errori.append(f"{rel}: scrive la globale '{nome}' (manca un local?)")
            else:
                errori.append(f"{rel}: legge la globale sconosciuta '{nome}' (nome sbagliato o manca un local?)")


def main():
    errori = []
    files = file_lua()
    for f in files:
        controlla(f, errori)
    for e in errori:
        print(e)
    if errori:
        print(f"Globali: {len(errori)} errori in {len(files)} file")
        sys.exit(1)
    print(f"Globali: nessun errore in {len(files)} file")


if __name__ == "__main__":
    main()
