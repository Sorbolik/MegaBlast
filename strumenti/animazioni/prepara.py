#!/usr/bin/env python3
"""Prepara l'editor delle animazioni del diavoletto in una pagina sola.

Mette dentro strumenti/animazioni/editor.html i pezzi veri del diavoletto
(client/assets/devil/*.png), i perni (client/battle/devil.lua), le
pelli disegnate sullo stampino (client/battle/skins.lua), le
animazioni di adesso (client/battle/animations.lua), l'altezza del disegno
(client/sim/game.lua), le hitbox (client/sim/body.lua), i perni spostati
(client/battle/pivots.lua), le armi in mano (client/battle/weapons.lua, immagini
in client/assets/weapons) con le loro impugnature (client/battle/grips.lua)
e i colori delle squadre (client/ui/ui.lua), e scrive
simulazione/animazioni/editor.html: si apre col doppio clic (Chrome o Edge
salvano direttamente in client/battle/animations.lua) e si pubblica com'è
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
    diavoletto = leggi("client/battle/devil.lua")
    # le immagini che i pezzi usano (img e tinta)
    nomi = sorted(set(re.findall(r'(?:img|tint) = "([a-z0-9_]+)"', diavoletto)))
    immagini = {}
    for n in nomi:
        dati = (REPO / "client/assets/devil" / (n + ".png")).read_bytes()
        immagini[n] = "data:image/png;base64," + base64.b64encode(dati).decode()
    # le pelli dello stampino (strumenti/stampino/taglia.py), coi loro pezzi
    pelli = leggi("client/battle/skins.lua")
    # in SVG quelle che ce l'hanno (strumenti/stampino/pelli/svg, da taglia.py --tavolozza):
    # nell'editor restano nitide con lo zoom
    for n in sorted(set(re.findall(r'(?:img|tint) = "([a-z0-9_]+)"', pelli))):
        svg = REPO / "strumenti/stampino/pelli/svg" / (n + ".svg")
        if svg.exists():
            immagini[n] = "data:image/svg+xml;base64," + base64.b64encode(svg.read_bytes()).decode()
            continue
        dati = (REPO / "client/assets/skins" / (n + ".png")).read_bytes()
        immagini[n] = "data:image/png;base64," + base64.b64encode(dati).decode()
    # le armi in mano (solo quelle, non i colpi), come armi/nome
    armi = leggi("client/battle/weapons.lua")
    in_mano = armi.split("shots = {")[0]
    for n in sorted(set(re.findall(r'(?:img|tint) = "([a-z0-9_]+)"', in_mano))):
        dati = (REPO / "client/assets/weapons" / (n + ".png")).read_bytes()
        immagini["armi/" + n] = "data:image/png;base64," + base64.b64encode(dati).decode()
    # gli angoli a riposo delle armi nella mano (battle/scoria.lua)
    scoria = leggi("client/battle/scoria.lua")
    blocco = re.search(r"local ARMI = \{(.*?)\n\}", scoria, re.S).group(1)
    # il personaggio di tutti nel gioco: l'editor parte con quello addosso
    personaggio = re.findall(r'"(\w+)"', re.search(r"M\.PERSONAGGIO = \{(.*?)\}", scoria).group(1))
    riposo = {n: float(v) for n, v in re.findall(r"(\w+) = (-?[0-9.]+)", blocco)}
    game = leggi("client/sim/game.lua")
    # il disegno è alto game.DISEGNO_H = REF_H * CORPO
    assert "M.DISEGNO_H = M.REF_H * M.CORPO" in game, "l'editor misura il diavoletto come sim/game.lua"
    misura = {k: float(re.search(r"M\.%s = ([0-9.]+)" % k, game).group(1)) for k in ("REF_H", "CORPO")}
    squadre = re.search(r"SQUADRA = \{(.*)\}", leggi("client/ui/ui.lua")).group(1)
    colori = [[float(x) for x in c.split(",")] for c in re.findall(r"c\(([^)]*)\)", squadre)]
    dati = {
        "diavoletto": diavoletto,
        "animazioni": leggi("client/battle/animations.lua"),
        "animazioni_favilla": leggi("client/battle/animations_favilla.lua"),
        "pelli": pelli,
        "perni": leggi("client/battle/pivots.lua"),
        "armi": armi,
        "impugnature": leggi("client/battle/grips.lua"),
        "armi_riposo": riposo,
        "personaggio": personaggio,
        "immagini": immagini,
        "disegno_h": misura["REF_H"] * misura["CORPO"],
        "corpo": leggi("client/sim/body.lua"),
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
