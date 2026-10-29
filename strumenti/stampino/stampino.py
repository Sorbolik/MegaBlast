#!/usr/bin/env python3
"""Lo stampino: il foglio su cui si disegnano i pezzi nuovi del diavoletto.

Ogni posto dello scheletro (testa e facce, busto, braccia, gambe, ala, coda,
pugno) ha una casella fissa con dentro il pezzo del diavoletto di base in grigio
(il manichino) e il perno nel punto in cui gira; i cerchi tratteggiati sono i
giunti dove si piega la coda.
Chi disegna un pezzo nuovo (una corazza, una testa, una maglia, delle ali) lo
disegna sopra il manichino, nella sua casella: taglia.py lo ritaglia, lo allinea
e lo mette nel gioco, dove si muove con le stesse animazioni.

Scrive in simulazione/stampino/:
  stampino.png       caselle, perni e nomi, per chi disegna (Procreate)
  stampino_ai.png    solo il manichino su magenta, da dare a ChatGPT
  manichino.png      il manichino montato, in piedi, su magenta
e strumenti/stampino/foglio.json (caselle e perni in pixel del foglio), che
legge taglia.py.

    python3 strumenti/stampino/stampino.py   (serve cairosvg: pip install cairosvg)
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
sys.path.insert(0, os.path.join(RADICE, "strumenti", "grafica"))
import diavoletto as DV  # noqa: E402
from vettori import gradienti, rendi  # noqa: E402

OUT = os.path.join(RADICE, "simulazione", "stampino")
FOGLIO = os.path.join(QUI, "foglio.json")

# il foglio: 3:2 come le immagini larghe di ChatGPT (1536 x 1024)
W, H = 3072, 2048
S = 3.5          # pixel del foglio per unità del disegno
MARGINE = 20     # spazio attorno al pezzo di base, per i pezzi più grandi
TITOLO = 44      # spazio per il nome sopra la casella
MAGENTA = (255, 0, 255, 255)

# I posti, in righe. Ogni posto ha il pezzo (o la coda montata) del diavoletto di
# base. Le versioni di dietro (braccio, gamba) taglia.py le fa da quelle
# davanti, più scure, se non si disegnano.
RIGHE = [
    ["testa", "testa_colpita", "testa_felice", "testa_ko"],
    ["busto", "ala", "coda"],
    ["braccio", "braccio_dietro", "gamba", "gamba_dietro", "pugno"],
]
NOMI = {
    "testa": "testa", "testa_colpita": "testa colpita", "testa_felice": "testa felice", "testa_ko": "testa KO",
    "busto": "busto", "ala": "ala", "coda": "coda",
    "braccio": "braccio", "braccio_dietro": "braccio dietro", "gamba": "gamba", "gamba_dietro": "gamba dietro",
    "pugno": "pugno",
}


def gruppi_coda():
    """La coda montata a riposo, dalla radice: prima i bordi, poi i colori, come
    la monta il gioco. Torna i gruppi SVG e la scatola attorno alla radice."""
    out, xs, ys = [], [], []
    for suff in ("_bordo", ""):
        x, y = 0.0, 0.0
        for i, a in enumerate(DV.CODA_RIPOSO):
            a = math.radians(a)
            d = DV.D()
            x0, y0, x1, y1 = DV.PEZZI[f"coda_{i + 1}{suff}"](d)
            out.append(d.gruppo(False, f"translate({x},{y}) rotate({math.degrees(a):.2f})"))
            for px, py in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
                xs.append(x + px * math.cos(a) - py * math.sin(a))
                ys.append(y + px * math.sin(a) + py * math.cos(a))
            x, y = x + DV.CODA[i][0] * math.cos(a), y + DV.CODA[i][0] * math.sin(a)
    return out, (min(xs), min(ys), max(xs), max(ys))


def pezzo(nome):
    """I gruppi SVG del pezzo di base attorno al suo perno e la sua scatola."""
    if nome == "coda":
        return gruppi_coda()
    d = DV.D()
    box = DV.PEZZI[nome](d)
    return [d.gruppo(False, "")], box


def disegna(gruppi, box, scala):
    """I gruppi in un'immagine: la scatola box (unità del disegno) a scala px."""
    x0, y0, x1, y1 = box
    w, h = round((x1 - x0) * scala), round((y1 - y0) * scala)
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}"><defs>{gradienti(DV.COL)}</defs>'
           f'<g transform="scale({scala},{-scala}) translate({-x0},{-y1})">{"".join(gruppi)}</g></svg>')
    return rendi(svg, w, h)


def grigio(im):
    """Il manichino: il pezzo in grigi chiari, il contorno grigio scuro."""
    l = im.convert("L").point(lambda v: round(120 + v * 0.45))
    g = Image.merge("RGBA", (l, l, l, im.getchannel("A")))
    return g


def font(n):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", n)
    except OSError:
        return ImageFont.load_default()


def main():
    os.makedirs(OUT, exist_ok=True)
    caselle = {}
    # le misure: ogni casella è il pezzo più il margine, le righe centrate
    pezzi = {n: pezzo(n) for riga in RIGHE for n in riga}
    alte = [max((pezzi[n][1][3] - pezzi[n][1][1] + 2 * MARGINE) * S for n in riga) + TITOLO for riga in RIGHE]
    spazio = (H - sum(alte)) / (len(RIGHE) + 1)
    assert spazio > 0, "lo stampino non ci sta nel foglio"
    guida = Image.new("RGBA", (W, H), (236, 238, 242, 255))
    ai = Image.new("RGBA", (W, H), MAGENTA)
    dg = ImageDraw.Draw(guida)
    y = spazio
    for riga, alta in zip(RIGHE, alte):
        larghe = [(pezzi[n][1][2] - pezzi[n][1][0] + 2 * MARGINE) * S for n in riga]
        gap = (W - sum(larghe)) / (len(riga) + 1)
        x = gap
        for n, larga in zip(riga, larghe):
            gruppi, (x0, y0, x1, y1) = pezzi[n]
            box = (x0 - MARGINE, y0 - MARGINE, x1 + MARGINE, y1 + MARGINE)
            im = grigio(disegna(gruppi, box, S))
            bx, by = round(x), round(y + TITOLO + (alta - TITOLO - im.height) / 2)
            guida.alpha_composite(im, (bx, by))
            ai.alpha_composite(im, (bx, by))
            # il perno: (0, 0) del pezzo
            px, py = bx + (0 - box[0]) * S, by + (box[3] - 0) * S
            caselle[n] = {"casella": [bx, by, bx + im.width, by + im.height], "perno": [round(px, 1), round(py, 1)]}
            dg.rectangle([bx, by, bx + im.width, by + im.height], outline=(70, 110, 200, 255), width=3)
            dg.text((bx + 6, by - TITOLO + 6), NOMI[n], fill=(30, 34, 44, 255), font=font(30))
            # i giunti da tenere tondi: lì i pezzi si piegano uno sull'altro
            for gx, gy, gr in giunti(n):
                cerchio(dg, px + gx * S, py - gy * S, gr * S)
            r = 14
            dg.line([px - r, py, px + r, py], fill=(225, 40, 40, 255), width=4)
            dg.line([px, py - r, px, py + r], fill=(225, 40, 40, 255), width=4)
            x += larga + gap
        y += alta + spazio
    legenda(dg, guida)
    guida.convert("RGB").save(os.path.join(OUT, "stampino.png"), optimize=True)
    ai.convert("RGB").save(os.path.join(OUT, "stampino_ai.png"), optimize=True)
    with open(FOGLIO, "w") as f:
        json.dump({"larghezza": W, "altezza": H, "scala": S, "posti": caselle}, f, indent=1)
        f.write("\n")
    manichino()
    print("OK:", os.path.relpath(OUT, RADICE), "e", os.path.relpath(FOGLIO, RADICE))


def giunti(nome):
    """I giunti dentro un posto (unità, dal perno) e il raggio del bordo lì: dove
    il pezzo si piega su quello dopo (i segmenti della coda)."""
    if nome == "coda":
        out, x, y = [], 0.0, 0.0
        for (L, w0, w1), a in zip(DV.CODA, DV.CODA_RIPOSO):
            a = math.radians(a)
            x, y = x + L * math.cos(a), y + L * math.sin(a)
            out.append((x, y, w1 / 2 + DV.BORDO_D))
        return out[:-1]
    return []


def cerchio(dg, x, y, r, n=24):
    """Un cerchio tratteggiato."""
    for i in range(0, n, 2):
        dg.arc([x - r, y - r, x + r, y + r], 360 * i / n, 360 * (i + 1) / n, fill=(40, 150, 90, 255), width=4)


def legenda(dg, guida):
    """Le regole in breve, a destra della coda."""
    x, y = 2700, 830
    dg.rectangle([x, y, x + 60, y + 60], fill=(0, 255, 0, 255), outline=(0, 0, 0, 255), width=4)
    righe = ["verde acceso:", "colore della", "squadra"]
    for i, t in enumerate(righe):
        dg.text((x + 76, y + 2 + i * 30), t, fill=(30, 34, 44, 255), font=font(24))
    y += 130
    cerchio(dg, x + 30, y + 30, 28)
    for i, t in enumerate(["giunto: tienilo", "tondo, ci si", "piega sopra"]):
        dg.text((x + 76, y + 2 + i * 30), t, fill=(30, 34, 44, 255), font=font(24))
    y += 130
    for i, t in enumerate(["contorno nero", "spesso come", "il manichino"]):
        dg.text((x, y + i * 30), t, fill=(30, 34, 44, 255), font=font(24))


def manichino():
    """Il manichino montato in piedi, come lo monta il gioco, su magenta: da
    allegare a ChatGPT per far capire come stanno insieme i pezzi."""
    gruppi = []

    def metti(nome, x, y):
        d = DV.D()
        DV.PEZZI[nome](d)
        gruppi.append(d.gruppo(False, f"translate({x},{y})"))

    cx, cy = DV.PUNTI["coda"]
    gruppi.append(f'<g transform="translate({cx},{cy})">{"".join(gruppi_coda()[0])}</g>')
    metti("ala", *DV.PUNTI["ala"])
    sx, sy = DV.PUNTI["spalle"]
    ax, ay = DV.PUNTI["anche"]
    metti("braccio_dietro", -sx, sy)
    metti("gamba_dietro", -ax, ay)
    metti("gamba", ax, ay)
    metti("busto", *DV.PUNTI["bacino"])
    metti("testa", *DV.PUNTI["collo"])
    metti("braccio", sx, sy)
    im = grigio(disegna(gruppi, (-110, -20, 110, 280), 1024 / 300))
    fondo = Image.new("RGBA", (1024, 1024), MAGENTA)
    fondo.alpha_composite(im, ((1024 - im.width) // 2, (1024 - im.height) // 2))
    fondo.convert("RGB").save(os.path.join(OUT, "manichino.png"), optimize=True)


if __name__ == "__main__":
    main()
