#!/usr/bin/env python3
"""Prepara l'editor delle animazioni del diavoletto in una pagina sola.

Mette dentro strumenti/animazioni/editor.html i pezzi veri del diavoletto
(client/assets/diavoletto/*.png), i perni (client/battaglia/diavoletto.lua), le
pelli disegnate sullo stampino (client/battaglia/pelli.lua), le
animazioni di adesso (client/battaglia/animazioni.lua), l'altezza del disegno
(client/sim/game.lua), le hitbox (client/sim/corpo.lua) e i colori delle squadre (client/ui/ui.lua), e scrive
simulazione/animazioni/editor.html: si apre col doppio clic (Chrome o Edge
salvano direttamente in client/battaglia/animazioni.lua) e si pubblica com'è
come Artifact di claude.ai.

    python3 strumenti/animazioni/prepara.py
"""
import base64
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
QUI = Path(__file__).resolve().parent


def leggi(p):
    return (REPO / p).read_text(encoding="utf-8")


def main():
    diavoletto = leggi("client/battaglia/diavoletto.lua")
    # le immagini che i pezzi usano (img e tinta)
    nomi = sorted(set(re.findall(r'(?:img|tinta) = "([a-z0-9_]+)"', diavoletto)))
    immagini = {}
    for n in nomi:
        dati = (REPO / "client/assets/diavoletto" / (n + ".png")).read_bytes()
        immagini[n] = "data:image/png;base64," + base64.b64encode(dati).decode()
    # le pelli dello stampino (strumenti/stampino/taglia.py), coi loro pezzi
    pelli = leggi("client/battaglia/pelli.lua")
    for n in sorted(set(re.findall(r'(?:img|tinta) = "([a-z0-9_]+)"', pelli))):
        dati = (REPO / "client/assets/pelli" / (n + ".png")).read_bytes()
        immagini[n] = "data:image/png;base64," + base64.b64encode(dati).decode()
    game = leggi("client/sim/game.lua")
    # il disegno è alto game.DISEGNO_H nel profilo blastron, quello del gioco
    assert 'M.DEFAULT_PHYSICS = "blastron"' in game, "l'editor misura il diavoletto sul profilo blastron"
    misura = {k: float(re.search(r"M\.%s = ([0-9.]+)" % k, game).group(1)) for k in ("BLASTRON_ROBOT_H", "BLASTRON_CORPO")}
    squadre = re.search(r"SQUADRA = \{(.*)\}", leggi("client/ui/ui.lua")).group(1)
    colori = [[float(x) for x in c.split(",")] for c in re.findall(r"c\(([^)]*)\)", squadre)]
    dati = {
        "diavoletto": diavoletto,
        "animazioni": leggi("client/battaglia/animazioni.lua"),
        "pelli": pelli,
        "immagini": immagini,
        "disegno_h": misura["BLASTRON_ROBOT_H"] * misura["BLASTRON_CORPO"],
        "corpo": leggi("client/sim/corpo.lua"),
        "squadre": colori,
    }
    testo = json.dumps(dati, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    pagina = (QUI / "editor.html").read_text(encoding="utf-8")
    assert pagina.count("/*DATI*/") == 1
    pagina = pagina.replace("/*DATI*/", testo)
    uscita = REPO / "simulazione/animazioni/editor.html"
    uscita.parent.mkdir(parents=True, exist_ok=True)
    uscita.write_text(pagina, encoding="utf-8")
    print("OK: %s (%d KB)" % (uscita.relative_to(REPO), uscita.stat().st_size // 1024))


if __name__ == "__main__":
    main()
