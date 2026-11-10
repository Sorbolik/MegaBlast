#!/usr/bin/env python3
"""Rinomina le funzioni dei moduli Lua col dizionario moduli.txt (modulo vecchio nuovo).

A differenza di rinomina.py tocca solo la forma qualificata: `alias.vecchio` e
`alias:vecchio` nei file che fanno `local alias = require "modulo"` (anche dentro
una tabella: `menu = { profile = require "menu.profile" }` dà l'alias
`menu.profile`), e `M.vecchio` / `M:vecchio` / `function M.vecchio` nel file del
modulo. Un campo dei dati con lo stesso nome (l.testo, r.stelle) resta com'è.
Le righe `@file TABELLA vecchio nuovo` rinominano `TABELLA.vecchio` solo in quel
file (le tabelle interne di game.gui_script). I metodi dichiarati `function M:x`,
e tutte le funzioni di un modulo che fa da metatabella (`__index`), si rinominano
anche come `:x(` ovunque (le istanze non hanno un alias).

    python3 strumenti/rinomina/rinomina_moduli.py --prova    dice cosa farebbe
    python3 strumenti/rinomina/rinomina_moduli.py            rinomina davvero
"""
import re
import sys
from pathlib import Path

QUI = Path(__file__).resolve().parent
REPO = QUI.parents[1]
LUA = (".lua", ".script", ".gui_script", ".render_script")
CARTELLE = ("client", "tests", "strumenti", "server")


def leggi_dizionario():
    moduli, interne = {}, {}
    for riga in (QUI / "moduli.txt").read_text(encoding="utf-8").splitlines():
        riga = riga.strip()
        if not riga or riga.startswith("#"):
            continue
        parti = riga.split()
        if parti[0].startswith("@"):
            file, tab, vecchio, nuovo = parti[0][1:], parti[1], parti[2], parti[3]
            interne.setdefault(file, {}).setdefault(tab, {})[vecchio] = nuovo
        else:
            modulo, vecchio, nuovo = parti
            moduli.setdefault(modulo, {})[vecchio] = nuovo
    return moduli, interne


def file_lua():
    for c in CARTELLE:
        for p in (REPO / c).rglob("*"):
            if p.suffix in LUA and "cloudflare/dist" not in str(p):
                yield p


def alias_di(src):
    """alias -> modulo, dai require del file (locali, globali e dentro le tabelle)."""
    out = {}
    for m in re.finditer(r"(?m)^(\s*)(local\s+)?([A-Za-z_]\w*)\s*=\s*require\s*\(?\s*[\"']([\w.]+)[\"']", src):
        indent, locale, nome, modulo = m.groups()
        if locale or not indent:
            out[nome] = modulo
        else:
            # dentro una tabella: l'ultima `local T = {` aperta prima
            prima = src[:m.start()]
            t = re.findall(r"local\s+([A-Za-z_]\w*)\s*=\s*\{", prima)
            if t:
                out[t[-1] + "." + nome] = modulo
    # la prima riga di una tabella: `local menu = { podium = require "menu.podium", ...`
    for m in re.finditer(r"local\s+([A-Za-z_]\w*)\s*=\s*\{([^\n]*)", src):
        tab, resto = m.groups()
        for e in re.finditer(r"([A-Za-z_]\w*)\s*=\s*require\s*\(?\s*[\"']([\w.]+)[\"']", resto):
            out[tab + "." + e.group(1)] = e.group(2)
    # su una riga sola, dentro una tabella aperta prima
    for m in re.finditer(r"(?m)^\s*(?:[A-Za-z_]\w*\s*=\s*require\s*\(?\s*[\"'][\w.]+[\"']\s*,\s*)+", src):
        prima = src[:m.start()]
        t = re.findall(r"local\s+([A-Za-z_]\w*)\s*=\s*\{", prima)
        if not t:
            continue
        for e in re.finditer(r"([A-Za-z_]\w*)\s*=\s*require\s*\(?\s*[\"']([\w.]+)[\"']", m.group(0)):
            out[t[-1] + "." + e.group(1)] = e.group(2)
    return out


def modulo_di(path):
    rel = path.relative_to(REPO)
    if rel.parts[0] == "client" and path.suffix == ".lua":
        return ".".join(rel.with_suffix("").parts[1:])
    return None


def main():
    prova = "--prova" in sys.argv
    moduli, interne = leggi_dizionario()
    metodi = {}  # vecchio -> nuovo per `function M:vecchio`
    for p in file_lua():
        mod = modulo_di(p)
        if mod in moduli:
            src = p.read_text(encoding="utf-8")
            for vecchio, nuovo in moduli[mod].items():
                # `function M:x`, o un modulo che fa da metatabella (`__index = M`): x è un metodo
                if re.search(r"function\s+M:" + vecchio + r"\b", src) or "__index" in src:
                    metodi[vecchio] = nuovo
    cambi = 0
    for p in file_lua():
        src = p.read_text(encoding="utf-8")
        nuovo_src = src
        mod = modulo_di(p)
        if mod in moduli:
            for vecchio, nuovo in moduli[mod].items():
                nuovo_src = re.sub(r"\bM([.:])" + vecchio + r"\b", r"M\1" + nuovo, nuovo_src)
        for alias, m in alias_di(src).items():
            if m not in moduli:
                continue
            for vecchio, nuovo in moduli[m].items():
                nuovo_src = re.sub(r"(?<![\w.])" + re.escape(alias) + r"([.:])" + vecchio + r"\b", lambda k: alias + k.group(1) + nuovo, nuovo_src)
        for vecchio, nuovo in metodi.items():
            nuovo_src = re.sub(r":" + vecchio + r"\b(?=\s*\()", ":" + nuovo, nuovo_src)
        rel = str(p.relative_to(REPO / "client")) if p.is_relative_to(REPO / "client") else None
        if rel in interne:
            for tab, coppie in interne[rel].items():
                for vecchio, nuovo in coppie.items():
                    nuovo_src = re.sub(r"\b" + tab + r"\." + vecchio + r"\b", tab + "." + nuovo, nuovo_src)
        if nuovo_src != src:
            n = sum(1 for a, b in zip(src.splitlines(), nuovo_src.splitlines()) if a != b)
            cambi += n
            print(f"{p.relative_to(REPO)}: {n} righe")
            if not prova:
                p.write_text(nuovo_src, encoding="utf-8")
    print(("farebbe" if prova else "fatte") + f" {cambi} righe")


if __name__ == "__main__":
    main()
