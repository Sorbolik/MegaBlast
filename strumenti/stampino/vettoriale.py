#!/usr/bin/env python3
"""Un foglio di pezzi in bianco e nero ricalcato in vettoriale (potrace).

Il disegno si divide in due strati: la sagoma intera (tutto ciò che non è il
fondo magenta) in bianco, e sopra il nero. Ognuno si ricalca con potrace in
curve, e il foglio vettoriale si riscrive in SVG e in PNG su magenta (rifatto
dall'SVG con cairosvg, al doppio della misura): il PNG si dà a pezzi_liberi.py
come il foglio originale.

  python3 strumenti/stampino/vettoriale.py FOGLIO.jpg USCITA.svg USCITA.png

Serve potrace (apt install potrace) e cairosvg.
"""
import os
import re
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
import taglia as TG  # noqa: E402

SCALA = 2           # il PNG rifatto è il doppio del foglio
NERO = 110          # sotto questa luminosità è nero


def liscia(valori, soglia):
    """Una maschera dal foglio raddoppiato e sfocato appena: i bordi della jpg
    (scalini e sbavature) non diventano curve storte."""
    from PIL import ImageFilter
    im = Image.fromarray(np.clip(valori, 0, 255).astype(np.uint8))
    im = im.resize((im.width * 2, im.height * 2), Image.LANCZOS).filter(ImageFilter.GaussianBlur(2.5))
    return np.asarray(im) > soglia


def ricalca(maschera, colore):
    """Una maschera in curve: i <path> di potrace dentro un gruppo del colore."""
    with tempfile.TemporaryDirectory() as d:
        pbm = os.path.join(d, "m.pbm")
        svg = os.path.join(d, "m.svg")
        Image.fromarray(np.where(maschera, 0, 255).astype(np.uint8)).convert("1").save(pbm)
        subprocess.run(["potrace", pbm, "-s", "-o", svg, "--turdsize", "6",
                        "--alphamax", "1.0", "--opttolerance", "0.2", "--unit", "1"], check=True)
        testo = open(svg).read()
    g = re.search(r"<g transform=\"([^\"]*)\"[^>]*>(.*?)</g>", testo, re.S)
    return f'<g transform="{g.group(1)}" fill="{colore}" stroke="none">{g.group(2)}</g>'


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    foglio, uscita_svg, uscita_png = sys.argv[1:]
    a = TG.fondo_via(Image.open(foglio))
    h, w = a.shape[:2]
    lum = a[..., :3].mean(axis=2)
    sagoma = liscia(a[..., 3], 128)
    # nero: la sagoma meno il bianco, così non resta un filo bianco fuori dal contorno
    bianco = liscia(np.where(a[..., 3] > 128, lum, 0), NERO + 30)
    nero = sagoma & ~bianco
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {2 * w} {2 * h}">\n'
           + ricalca(sagoma, "#ffffff") + "\n" + ricalca(nero, "#000000") + "\n</svg>\n")
    with open(uscita_svg, "w") as f:
        f.write(svg)
    import cairosvg
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=w * SCALA, output_height=h * SCALA)
    import io
    im = Image.open(io.BytesIO(png)).convert("RGBA")
    fondo = Image.new("RGBA", im.size, (255, 0, 255, 255))
    fondo.alpha_composite(im)
    fondo.convert("RGB").save(uscita_png)
    print("OK:", uscita_svg, uscita_png)


if __name__ == "__main__":
    main()
