"""Il logo di Favilla in vettoriale: ricalca il disegno di Sergio, senza ridisegnarlo.

Legge art/personaggi/favilla.png (2328 x 2328, bianco e nero), lo passa a potrace e
scrive art/personaggi/favilla.svg: le macchie nere del disegno su un foglio bianco.
L'SVG è il file madre del logo: da lì si esportano tutte le misure (ingresso.py fa
il disco dell'ingresso, della pillola e dell'attesa). Serve potrace
(apt install potrace, o https://potrace.sourceforge.net per Windows).

    python3 strumenti/grafica/logo.py
"""
import os
import re
import subprocess
import tempfile
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.normpath(os.path.join(QUI, "..", ".."))
ORIGINE = os.path.join(RADICE, "art", "personaggi", "favilla.png")
USCITA = os.path.join(RADICE, "art", "personaggi", "favilla.svg")

im = Image.open(ORIGINE).convert("L")
with tempfile.TemporaryDirectory() as tmp:
    pbm = os.path.join(tmp, "f.pbm")
    svg = os.path.join(tmp, "f.svg")
    im.point(lambda v: 0 if v < 128 else 255).convert("1").save(pbm)
    # -t 4: toglie le macchioline sotto 4 px; -O 0.2: curve fedeli al tratto
    subprocess.run(["potrace", pbm, "-s", "-t", "4", "-O", "0.2", "-o", svg], check=True)
    testo = open(svg, encoding="utf-8").read()

w, h = im.size
corpo = testo[testo.index("<g "):testo.rindex("</svg>")]
corpo = re.sub(r"\s+", " ", corpo).replace("> <", ">\n<")
out = (
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n'
    f'<!-- Favilla, disegno di Sergio, ricalcato da strumenti/grafica/logo.py -->\n'
    f'<rect width="{w}" height="{h}" fill="#ffffff"/>\n{corpo}</svg>\n'
)
open(USCITA, "w", encoding="utf-8").write(out)
print(USCITA)
