"""Il cielo del Limbo dietro la home (Sergio, 18 nov): la stellina e le nuvole
(«nuvole stilizzate carine che non spiccano», «contorni ben definiti», «più varianza»).

Scrive client/paintings/backdrops/stella.png, una stellina a quattro punte bianca (il
gioco la colora), e nuvola_<n>.png: sei nuvole a fumetto piatte, base
dritta coi capi tondi e gobbe tonde sopra, contorno netto un filo più chiaro del cielo,
corpo scuro, una fascia d'ombra sul fondo e un ricciolo dentro la gobba più grande.
Disegnate col campo delle distanze al doppio della misura a cui le mostra il gioco:
i bordi sono netti e lisci.

    python3 tools/grafica/cielo.py
"""
from pathlib import Path
import numpy as np
from PIL import Image

RADICE = Path(__file__).resolve().parents[2]
USCITA = RADICE / "client/paintings/backdrops"

SCALA = 2           # pixel dell'immagine per punto del gioco
TRATTO = 4          # contorno, in punti
OMBRA = 9           # fascia d'ombra sul fondo, in punti
CONTORNO, CORPO, FONDO = (0x2B, 0x27, 0x44), (0x1B, 0x19, 0x29), (0x16, 0x14, 0x22)

# (base: da x0 a x1, alta h; gobbe: (x, y del centro sopra la base, raggio)), in punti
NUVOLE = [
    ((-110, 110, 26), [(-70, 36, 34), (-20, 52, 46), (38, 44, 40), (84, 24, 26)]),
    ((-80, 80, 24), [(-44, 28, 30), (4, 46, 40), (50, 28, 28)]),
    ((-140, 140, 26), [(-108, 26, 24), (-66, 40, 36), (-12, 58, 46), (46, 48, 40), (100, 30, 30)]),
    ((-56, 56, 24), [(-22, 32, 30), (18, 46, 34)]),
    ((-150, 150, 24), [(-118, 26, 24), (-72, 34, 34), (-14, 42, 40), (44, 36, 34), (100, 26, 28)]),
    ((-100, 100, 24), [(-76, 26, 24), (-34, 42, 40), (20, 50, 36), (62, 30, 30)]),
]


def distanza(base, gobbe, x, y):
    """Distanza con segno dal bordo della nuvola (negativa dentro), in punti."""
    x0, x1, h = base
    r = h / 2
    # la base: un rettangolo coi capi tondi, da y 0 a h
    cx = np.clip(x, x0 + r, x1 - r)
    piede = np.hypot(x - cx, y - r) - r
    d = np.full_like(x, 1e9)
    for gx, gy, gr in gobbe:
        d = np.minimum(d, np.hypot(x - gx, y - gy) - gr)
    # le gobbe si saldano alla base con un raccordo tondo (niente tacche in basso);
    # fra loro restano le punte a V del fumetto
    k = 14
    t = np.clip(0.5 + 0.5 * (piede - d) / k, 0, 1)
    d = piede * (1 - t) + d * t - k * t * (1 - t)
    # il fondo dritto, con gli spigoli tondi
    a, b, k = -d, y, 3
    t = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
    return -(b * (1 - t) + a * t - k * t * (1 - t))


def ricciolo(gobbe, x, y):
    """Il ricciolo dentro la gobba più grande: un arco in alto a sinistra."""
    gx, gy, gr = max(gobbe, key=lambda g: g[2])
    cx, cy, ra = gx + 0.12 * gr, gy - 0.08 * gr, 0.56 * gr
    a = np.degrees(np.arctan2(y - cy, x - cx))
    anello = np.abs(np.hypot(x - cx, y - cy) - ra) - TRATTO / 2
    da, a_ = 105, 175
    dentro = (a >= da) & (a <= a_)
    capi = np.minimum(*(np.hypot(x - (cx + ra * np.cos(np.radians(t))), y - (cy + ra * np.sin(np.radians(t)))) - TRATTO / 2 for t in (da, a_)))
    return np.where(dentro, anello, capi)


def copertura(d):
    """Quanto un pixel è dentro, dalla distanza in punti (bordo liscio di un pixel)."""
    return np.clip(0.5 - d * SCALA, 0, 1)


def disegna(base, gobbe):
    x0, x1, _ = base
    x0 = min([x0] + [gx - gr for gx, _, gr in gobbe])
    x1 = max([x1] + [gx + gr for gx, _, gr in gobbe])
    alto = max(gy + gr for _, gy, gr in gobbe)
    m = TRATTO + 2
    w, h = int((x1 - x0) + 2 * m), int(alto + 2 * m)
    xs = (np.arange(w * SCALA) + 0.5) / SCALA + x0 - m
    ys = (np.arange(h * SCALA)[::-1] + 0.5) / SCALA - m
    x, y = np.meshgrid(xs, ys)
    d = distanza(base, gobbe, x, y)
    a_fuori = copertura(d)
    a_corpo = copertura(d + TRATTO)
    # l'ombra: una fascia dritta sul fondo
    a_ombra = a_corpo * np.clip(0.5 + (TRATTO + OMBRA - y) * SCALA, 0, 1)
    a_ricciolo = a_corpo * copertura(ricciolo(gobbe, x, y))
    col = np.empty(d.shape + (3,))
    col[:] = CONTORNO
    for colore, a in ((CORPO, a_corpo), (FONDO, a_ombra), (CONTORNO, a_ricciolo)):
        col = col + (np.array(colore) - col) * a[..., None]
    rgba = np.dstack([col, a_fuori * 255]).round().astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def stella(lato=64):
    """La stellina: quattro punte curve (|x|^0.5 + |y|^0.5 <= 1), bianca, bordo liscio."""
    k = 4
    n = lato * k
    v = (np.arange(n) + 0.5) / n * 2 - 1
    x, y = np.meshgrid(v, v)
    dentro = (np.sqrt(np.abs(x) / 0.94) + np.sqrt(np.abs(y) / 0.94)) <= 1
    a = dentro.reshape(lato, k, lato, k).mean(axis=(1, 3))
    # bianca: il colore lo dà il gioco al nodo
    rgba = np.dstack([np.full_like(a, 255)] * 3 + [a * 255]).round().astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def main():
    stella().save(USCITA / "stella.png", optimize=True)
    print("stella.png")
    for i, (base, gobbe) in enumerate(NUVOLE, 1):
        im = disegna(base, gobbe)
        im.save(USCITA / ("nuvola_%d.png" % i), optimize=True)
        print("nuvola_%d.png" % i, im.size)


if __name__ == "__main__":
    main()
