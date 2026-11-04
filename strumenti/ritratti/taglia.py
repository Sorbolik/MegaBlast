"""Ritaglia i ritratti delle vignette dai fogli modello scelti di WB-012.

Ogni foglio è una griglia 3 x 3: in alto a sinistra la figura intera, poi otto
busti nell'ordine delle espressioni (scheda docs/handoff/WB-012_vignette_tutorial.md).
Scrive client/assets/portraits/<personaggio>_<espressione>.png, quadrati, e
l'atlante client/ui/portraits.atlas.

    python3 strumenti/ritratti/taglia.py
"""
import os
from PIL import Image

RADICE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FOGLI = os.path.join(RADICE, "art", "WB-012", "scelti")
USCITA = os.path.join(RADICE, "client", "assets", "portraits")
ATLANTE = os.path.join(RADICE, "client", "ui", "portraits.atlas")
PERSONAGGI = ["apprendista", "favilla", "fabbro"]
ESPRESSIONI = ["calma", "ride", "spiega", "sorpresa", "preoccupata", "arrabbiata", "fiera", "triste"]
LATO = 192
MARGINE = 24  # via il bordo della cella e il filo della griglia
# quanta parte della cella tiene il ritratto (il Fabbro è grande: si stringe sulla testa)
ZOOM = {"fabbro": 0.78}


def celle(im, zoom):
    w, h = im.size
    for r in range(3):
        for c in range(3):
            x0, x1 = c * w // 3 + MARGINE, (c + 1) * w // 3 - MARGINE
            y0, y1 = r * h // 3 + MARGINE, (r + 1) * h // 3 - MARGINE
            s = int(min(x1 - x0, y1 - y0) * zoom)
            x = x0 + (x1 - x0 - s) // 2
            yield im.crop((x, y0, x + s, y0 + s))


def main():
    os.makedirs(USCITA, exist_ok=True)
    nomi = []
    for p in PERSONAGGI:
        im = Image.open(os.path.join(FOGLI, p + ".png")).convert("RGB")
        busti = list(celle(im, ZOOM.get(p, 1)))[1:]
        for e, b in zip(ESPRESSIONI, busti):
            nome = p + "_" + e
            b.resize((LATO, LATO), Image.LANCZOS).save(os.path.join(USCITA, nome + ".png"), optimize=True)
            nomi.append(nome)
    with open(ATLANTE, "w") as f:
        for n in nomi:
            f.write('images {\n  image: "/assets/portraits/%s.png"\n}\n' % n)
        f.write("margin: 2\nextrude_borders: 2\ninner_padding: 0\n")
    print("OK", len(nomi), "ritratti")


if __name__ == "__main__":
    main()
