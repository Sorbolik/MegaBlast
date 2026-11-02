#!/usr/bin/env python3
"""Rinomina nomi e file del codice con un dizionario (vecchio -> nuovo).

Serve alla traduzione in inglese a ondate: ogni ondata ha la sua cartella di
file da toccare (--dentro) e lo stesso dizionario si può passare su un ramo
aperto (per esempio quello del bot con la rete) per togliere i conflitti.

    python3 strumenti/rinomina/rinomina.py --prova       dice cosa farebbe
    python3 strumenti/rinomina/rinomina.py               rinomina davvero

Cosa fa, con i dizionari di questa cartella:
- file.txt: sposta i file (git mv) e aggiorna i percorsi e i require
  ("sim.campagna" -> "sim.campaign") in tutti i file di testo del repository;
- nomi_lua.txt / nomi_go.txt: rinomina i nomi (variabili, funzioni, campi)
  nei file Lua / Go dell'ondata. Le parole nei commenti e nelle stringhe non si
  toccano, tranne nel Lua una stringa che è esattamente un nome rinominato (per
  esempio conta = "mancati" che indica il campo st.conta.mancati): quelle le
  elenca. Nel Go le stringhe restano: sono chiavi JSON e nomi dei flag.

Nel Lua le variabili locali (e i parametri) si rinominano sempre: valgono
solo dentro il loro file. Un campo (t.nome, t:nome(), { nome = ... }) invece
NON si rinomina se compare anche in un file Lua fuori dall'ondata, o come
stringa fuori dall'ondata, o in chiavi_fisse.txt: vuol dire che lo usa qualcun
altro (il client, il bot, gli strumenti, i dati salvati) e va tradotto
nell'ondata di chi lo usa. Si ferma se in un file il nome nuovo c'è già.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

QUI = Path(__file__).resolve().parent
REPO = QUI.parents[1]

LUA = (".lua", ".script", ".gui_script", ".render_script")
TESTO = (".lua", ".script", ".gui_script", ".render_script", ".go", ".py", ".sh", ".yml",
         ".yaml", ".md", ".js", ".mjs", ".html", ".json", ".jsonc", ".txt", ".collection", ".go_",
         ".gui", ".project", ".input_binding", ".settings")


def tokens_lua(src):
    """(tipo, testo): tipo è name, str, comment o other. Ricompone src esatto."""
    i, n = 0, len(src)
    nome = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
    numero = re.compile(r"0[xX][0-9a-fA-F]+|\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+")
    while i < n:
        c = src[i]
        if src.startswith("--", i):
            m = re.match(r"--\[(=*)\[", src[i:i + 20])
            if m:
                j = src.find("]" + m.group(1) + "]", i)
                j = n if j < 0 else j + len(m.group(1)) + 2
            else:
                j = src.find("\n", i)
                j = n if j < 0 else j
            yield "comment", src[i:j]
            i = j
            continue
        m = re.match(r"\[(=*)\[", src[i:i + 20])
        if m:
            j = src.find("]" + m.group(1) + "]", i) + len(m.group(1)) + 2
            yield "str", src[i:j]
            i = j
            continue
        if c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                j += 2 if src[j] == "\\" else 1
            yield "str", src[i:j + 1]
            i = j + 1
            continue
        m = nome.match(src, i)
        if m:
            yield "name", m.group(0)
            i = m.end()
            continue
        m = numero.match(src, i)
        if m:
            yield "other", m.group(0)
            i = m.end()
            continue
        yield "other", c
        i += 1


def tokens_go(src):
    i, n = 0, len(src)
    nome = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
    while i < n:
        c = src[i]
        if src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            yield "comment", src[i:j]
            i = j
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i) + 2
            yield "comment", src[i:j]
            i = j
            continue
        if c == "`":
            j = src.find("`", i + 1) + 1
            yield "str", src[i:j]
            i = j
            continue
        if c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                j += 2 if src[j] == "\\" else 1
            yield "str", src[i:j + 1]
            i = j + 1
            continue
        m = nome.match(src, i)
        if m:
            yield "name", m.group(0)
            i = m.end()
            continue
        yield "other", c
        i += 1


def leggi_dizionario(nome):
    d = {}
    p = QUI / nome
    if not p.exists():
        return d
    for riga in p.read_text().splitlines():
        riga = riga.split("#")[0].strip()
        if not riga:
            continue
        vecchio, nuovo = riga.split()
        assert vecchio not in d, f"{nome}: {vecchio} due volte"
        d[vecchio] = nuovo
    nuovi = list(d.values())
    doppi = {x for x in nuovi if nuovi.count(x) > 1}
    assert not doppi, f"{nome}: nomi nuovi ripetuti {sorted(doppi)}"
    return d


def leggi_dizionario_lista(nome):
    p = QUI / nome
    if not p.exists():
        return []
    return [r.split("#")[0].strip() for r in p.read_text().splitlines() if r.split("#")[0].strip()]


def campi_lua(toks):
    """Per ogni token: True se è un campo (dopo . o :, o chiave in { k = v })."""
    sig = [i for i, (k, t) in enumerate(toks) if k != "comment" and not t.isspace()]
    pos = {i: n for n, i in enumerate(sig)}
    campo = [False] * len(toks)
    pila = []
    for n, i in enumerate(sig):
        k, t = toks[i]
        if t in "({[":
            pila.append(t)
        elif t in ")}]":
            if pila:
                pila.pop()
        if k != "name":
            continue
        prima = toks[sig[n - 1]][1] if n > 0 else ""
        dopo = toks[sig[n + 1]][1] if n + 1 < len(sig) else ""
        dopo2 = toks[sig[n + 2]][1] if n + 2 < len(sig) else ""
        if prima in (".", ":") and not (n > 1 and toks[sig[n - 2]][1] == "."):
            campo[i] = True
        elif pila and pila[-1] == "{" and prima in ("{", ",", ";") and dopo == "=" and dopo2 != "=":
            campo[i] = True
    return campo


def git_files():
    out = subprocess.run(["git", "ls-files"], cwd=REPO, text=True, capture_output=True, check=True)
    return out.stdout.split()


def nell_ondata(f, dentro, fuori):
    return any(f == d or f.startswith(d.rstrip("/") + "/") for d in dentro) and not any(
        f == x or f.startswith(x.rstrip("/") + "/") for x in fuori)


def stringa(t):
    return t[1:-1] if len(t) >= 2 and t[0] in "\"'`" and t[-1] == t[0] else None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dentro", nargs="+", default=["client/sim", "server", "tests/sim_test.lua",
                    "tests/campagna_test.lua", "tests/eventi_test.lua", "tests/assetto_test.lua"],
                    help="file e cartelle dell'ondata")
    ap.add_argument("--fuori", nargs="*", default=["client/sim/bot.lua", "client/sim/rete.lua",
                    "client/sim/corpo.lua"], help="file da lasciare fuori dall'ondata")
    ap.add_argument("--prova", action="store_true", help="dice cosa farebbe, senza cambiare niente")
    a = ap.parse_args()

    files = git_files()
    ondata = [f for f in files if nell_ondata(f, a.dentro, a.fuori)]
    nomi = {".lua": leggi_dizionario("nomi_lua.txt"), ".go": leggi_dizionario("nomi_go.txt")}
    sposta = leggi_dizionario("file.txt")

    # chi usa i nomi fuori dall'ondata: lì non si rinominano
    usati_fuori, stringhe_fuori = set(), set()
    for f in files:
        if f in ondata or not f.endswith(LUA):
            continue
        for k, t in tokens_lua((REPO / f).read_text(errors="replace")):
            if k == "name":
                usati_fuori.add(t)
            elif k == "str" and stringa(t):
                stringhe_fuori.add(stringa(t))
    fissi = set(leggi_dizionario_lista("chiavi_fisse.txt"))
    tenuti = sorted(n for n in nomi[".lua"] if n in usati_fuori or n in stringhe_fuori or n in fissi)
    for n in tenuti:
        print(f"campo tenuto (usato fuori dall'ondata): {n}")
    campi = {".lua": {k: v for k, v in nomi[".lua"].items() if k not in tenuti}, ".go": nomi[".go"]}

    errori, cambiati = [], 0
    for f in ondata:
        ext = ".go" if f.endswith(".go") else ".lua" if f.endswith(LUA) else None
        if not ext or not nomi[ext]:
            continue
        tutti, d = nomi[ext], campi[ext]
        src = (REPO / f).read_text()
        toks = list((tokens_go if ext == ".go" else tokens_lua)(src))
        presenti = {t for k, t in toks if k == "name"}
        campo = campi_lua(toks) if ext == ".lua" else [True] * len(toks)
        da_rinominare = {t for i, (k, t) in enumerate(toks)
                         if k == "name" and t in tutti and (ext == ".go" or not campo[i] or t in d)}
        for vecchio in da_rinominare:
            if tutti[vecchio] in presenti:
                errori.append(f"{f}: '{tutti[vecchio]}' c'è già, non posso rinominare '{vecchio}'")
        out = []
        for i, (k, t) in enumerate(toks):
            if k == "name" and t in tutti and (ext == ".go" or not campo[i] or t in d):
                t = tutti[t]
            elif k == "str" and ext == ".lua" and stringa(t) in d:
                print(f"{f}: stringa {t} -> \"{d[stringa(t)]}\"")
                t = t[0] + d[stringa(t)] + t[-1]
            out.append(t)
        nuovo_src = "".join(out)
        if nuovo_src != src:
            cambiati += 1
            if not a.prova:
                (REPO / f).write_text(nuovo_src)
    if errori:
        print("\n".join(errori))
        sys.exit(1)

    # file spostati: git mv e percorsi in tutti i file di testo
    if sposta:
        sostituzioni = []
        for vecchio, nuovo in sposta.items():
            sostituzioni.append((vecchio, nuovo))
            if vecchio.startswith("client/") and vecchio.endswith(".lua"):
                mod_v = vecchio[len("client/"):-4]
                mod_n = nuovo[len("client/"):-4]
                sostituzioni.append((mod_v, mod_n))                                   # sim/campagna
                sostituzioni.append((mod_v.replace("/", "."), mod_n.replace("/", ".")))  # sim.campagna
            elif "/" in vecchio:
                sostituzioni.append((vecchio.split("/", 1)[1], nuovo.split("/", 1)[1]))
        for f in files:
            if not f.endswith(TESTO) or f.startswith("strumenti/rinomina/"):
                continue
            p = REPO / f
            src = p.read_text(errors="replace")
            nuovo_src = src
            for v, n in sostituzioni:
                nuovo_src = re.sub(r"(?<![A-Za-z0-9_])" + re.escape(v) + r"(?![A-Za-z0-9_])", n, nuovo_src)
            if nuovo_src != src:
                cambiati += 1
                if not a.prova:
                    p.write_text(nuovo_src)
        for vecchio, nuovo in sposta.items():
            if not (REPO / vecchio).exists():
                continue
            print(f"sposta {vecchio} -> {nuovo}")
            if not a.prova:
                subprocess.run(["git", "mv", vecchio, nuovo], cwd=REPO, check=True)
    print(f"{'cambierebbe' if a.prova else 'cambiati'} {cambiati} file")


if __name__ == "__main__":
    main()
