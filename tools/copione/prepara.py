#!/usr/bin/env python3
"""Prepara la pagina del Copione (la dashboard della campagna).

Mette dentro tools/copione/pagina.html i capitoli e i livelli di
client/sim/levels.lua (con esporta.lua), le mappe dipinte, i ritratti e le icone
delle armi, e scrive simulazione/copione/index.html. Con --gioco copia accanto,
in simulazione/copione/game/, la build web del gioco (tools/web/build.sh,
già fatta o da fare): serve al pulsante GIOCA.

Si pubblica come Artifact sempre allo stesso indirizzo (tools/copione/README.md).
Dalla radice:
    python3 tools/copione/prepara.py [--gioco]
"""
import argparse
import base64
import io
import json
import os
import shutil
import subprocess
import sys

from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
OUT = os.path.join(RADICE, "simulazione", "copione")


def data_uri(im, w, qualita=78):
    """L'immagine ridotta a larghezza w, in WebP (con la trasparenza), come data: URI."""
    if im.width > w:
        im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    b = io.BytesIO()
    im.save(b, "WEBP", quality=qualita, method=6)
    return "data:image/webp;base64," + base64.b64encode(b.getvalue()).decode()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gioco", action="store_true", help="copia la build web per GIOCA (la fa se manca)")
    args = ap.parse_args()

    dati = json.loads(subprocess.run(["luajit", "tools/copione/esporta.lua"], cwd=RADICE, check=True,
                                     capture_output=True, text=True).stdout)
    dipinti = os.path.join(RADICE, "client", "paintings", "maps")
    immagini = {"mappe": {}, "ritratti": {}, "armi": {}}
    # la mappa dipinta di ogni livello (le arene: missione_<id>) e delle mappe del gioco
    nomi = set(dati["catalogo"]["mappe"])
    for cap in dati["capitoli"]:
        for l in cap["livelli"]:
            nomi.add(l["mappa"] if "mappa" in l else "missione_" + l["id"])
    for nome in sorted(nomi):
        f = os.path.join(dipinti, nome + "_1.png")
        if os.path.exists(f):
            immagini["mappe"][nome] = data_uri(Image.open(f).convert("RGBA"), 960)
    ritratti = os.path.join(RADICE, "client", "assets", "portraits")
    for f in sorted(os.listdir(ritratti)):
        if f.endswith(".png"):
            immagini["ritratti"][f[:-4]] = data_uri(Image.open(os.path.join(ritratti, f)).convert("RGBA"), 160)
    armi = os.path.join(RADICE, "client", "assets", "weapons")
    for w in dati["catalogo"]["armi"]:
        f = os.path.join(armi, w + "_icona.png")
        if os.path.exists(f):
            immagini["armi"][w] = data_uri(Image.open(f).convert("RGBA"), 64, 85)
    cassa = os.path.join(RADICE, "client", "assets", "crates", "cassa.png")
    immagini["cassa"] = data_uri(Image.open(cassa).convert("RGBA"), 64, 85)

    pagina = open(os.path.join(QUI, "pagina.html"), encoding="utf-8").read()
    segno = "/*DATI*/"
    assert segno in pagina, "pagina.html senza /*DATI*/"
    js = "const DATI = %s;\nconst IMMAGINI = %s;\n" % (json.dumps(dati, ensure_ascii=False),
                                                       json.dumps(immagini))
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8") as f:
        f.write(pagina.replace(segno, js, 1))
    print("scritta", os.path.relpath(os.path.join(OUT, "index.html"), RADICE),
          "(%d KB)" % (os.path.getsize(os.path.join(OUT, "index.html")) // 1024))

    if args.gioco:
        web = os.path.join(RADICE, "simulazione", "web")
        if not os.path.exists(os.path.join(web, "megablast.html")):
            subprocess.run(["bash", "tools/web/build.sh"], cwd=RADICE, check=True)
        gioco = os.path.join(OUT, "game")
        shutil.rmtree(gioco, ignore_errors=True)
        shutil.copytree(web, gioco)
        # dentro l'Artifact è una pagina fra i file, servita senza lo scheletro: le serve il suo
        pagina_gioco = os.path.join(gioco, "megablast.html")
        testo = open(pagina_gioco, encoding="utf-8").read()
        if not testo.lstrip().lower().startswith("<!doctype"):
            testo = ('<!doctype html>\n<meta charset="utf-8">\n<meta name="viewport" '
                     'content="width=device-width,initial-scale=1,viewport-fit=cover">\n' + testo)
            open(pagina_gioco, "w", encoding="utf-8").write(testo)
        print("copiata la build web in", os.path.relpath(gioco, RADICE))


if __name__ == "__main__":
    sys.exit(main())
