#!/usr/bin/env python3
"""Controlli che fa l'editor di Defold ma bob (il compilatore a riga di comando) no.

bob compila anche file che l'editor segna come errore, quindi un problema può
passare la build automatica e comparire solo quando Sergio apre il progetto.
Qui ripetiamo quei controlli. Ogni regola cita da dove viene nell'editor.

In più una regola del gioco: niente nodi GUI stirati (ADJUST_STRETCH), che su
uno schermo non 16:9 diventano ovali (ui/schermo.lua).

Uso: python3 strumenti/simula/controlla.py [cartella del client]
Esce con 1 se trova errori.
"""
import json
import re
import sys
from pathlib import Path

# File di risorse in testo (protobuf) di cui controlliamo i riferimenti
RISORSE = {".collection", ".go", ".gui", ".mesh", ".material", ".atlas", ".tilesource",
           ".font", ".model", ".sprite", ".particlefx", ".label", ".render",
           ".texture_profiles", ".tilemap", ".collisionobject", ".sound", ".camera"}
PERCORSO = re.compile(r'"(/[A-Za-z0-9_./-]+\.[A-Za-z0-9_]+)\\?"')


def campo(testo, nome):
    """Valore di un campo stringa o enum di primo livello di un file protobuf in testo."""
    m = re.search(r'^%s:\s*"?([^"\n]*)"?\s*$' % nome, testo, re.M)
    return m.group(1).strip() if m else ""


def controlla_mesh(root, mesh, errori):
    # editor/src/clj/editor/mesh.clj (Defold 1.14), validate-stream-id:
    # con un materiale in vertex space WORLD i campi position_stream e
    # normal_stream devono essere indicati; se indicati, devono esistere nel buffer.
    testo = mesh.read_text(encoding="utf-8")
    nome = "/" + mesh.relative_to(root).as_posix()
    mat = campo(testo, "material")
    buf = campo(testo, "vertices")
    if not mat:
        errori.append(f"{nome}: manca il materiale")
        return
    if not buf:
        errori.append(f"{nome}: manca il buffer dei vertici (vertices)")
        return
    mat_file, buf_file = root / mat.lstrip("/"), root / buf.lstrip("/")
    if not mat_file.exists() or not buf_file.exists():
        return  # lo segnala già il controllo dei riferimenti
    world = campo(mat_file.read_text(encoding="utf-8"), "vertex_space") == "VERTEX_SPACE_WORLD"
    try:
        streams = [s.get("name", "") for s in json.loads(buf_file.read_text(encoding="utf-8"))]
    except (ValueError, AttributeError) as e:
        errori.append(f"{buf}: buffer non leggibile ({e})")
        return
    if not streams:
        return
    for prop, etichetta in (("position_stream", "Position Stream"), ("normal_stream", "Normal Stream")):
        valore = campo(testo, prop)
        if not valore:
            if world:
                errori.append(f"{nome}: {etichetta} must be specified when using a Material "
                              f"with world-space Vertex Space ({mat} ha vertex_space WORLD: "
                              f"aggiungi lo stream al buffer {buf} e indica {prop} nella mesh)")
        elif valore not in streams:
            errori.append(f"{nome}: lo stream '{valore}' di {prop} non c'è in {buf} "
                          f"(stream presenti: {', '.join(streams)})")


def controlla_riferimenti(root, f, errori):
    # Un riferimento a un file che non esiste è un errore anche nell'editor.
    nome = "/" + f.relative_to(root).as_posix()
    for p in PERCORSO.findall(f.read_text(encoding="utf-8", errors="replace")):
        if p.startswith("/builtins/"):
            continue
        dest = root / p.lstrip("/")
        # i file compilati (.collectionc, .texturec...) si riferiscono al sorgente senza la c
        if dest.exists() or (p.endswith("c") and (root / p[1:-1]).exists()):
            continue
        errori.append(f"{nome}: il file {p} non esiste")


STIRATO = re.compile(r"ADJUST_STRETCH|ADJUST_MODE_STRETCH")


def controlla_proporzioni(root, f, errori):
    # Sergio, 29 ott: niente deve mai diventare ovale. Tutto FIT (ui/schermo.lua).
    nome = "/" + f.relative_to(root).as_posix()
    for i, riga in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if STIRATO.search(riga) and not riga.lstrip().startswith("--"):
            errori.append(f"{nome}:{i}: nodo stirato (ADJUST_STRETCH) che si deforma sugli schermi "
                          f"non 16:9: usa gui.ADJUST_FIT e i bordi di ui/schermo.lua")


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parents[2] / "client")
    errori = []
    for f in sorted(root.rglob("*")):
        if any(part in ("build", ".internal") for part in f.relative_to(root).parts):
            continue
        if f.suffix in RISORSE:
            controlla_riferimenti(root, f, errori)
        if f.suffix == ".mesh":
            controlla_mesh(root, f, errori)
        if f.suffix in (".lua", ".gui_script", ".gui", ".script"):
            controlla_proporzioni(root, f, errori)
    for e in errori:
        print("ERRORE EDITOR:", e)
    if errori:
        print(f"{len(errori)} errori che l'editor di Defold segnalerebbe")
        return 1
    print("Controlli dell'editor: nessun errore")
    return 0


if __name__ == "__main__":
    sys.exit(main())
