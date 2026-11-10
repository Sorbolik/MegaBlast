# Disegna le due monete (Scaglie e Ossidiana, pagina "Scaglie e Ossidiana" del 10 nov)
# come strati bianchi in client/assets/ui/: il colore di ogni strato lo mette il
# codice (client/ui/coins.lua), come per le altre forme dell'interfaccia. Due misure
# per strato, come la stella: moneta_<nome>_<strato>.png a 128 px e _p a 48 (l'atlas
# non ha mipmap). Le forme sono quelle disegnate nella pagina (viewBox -16..16).
#   scaglia:   sagoma, faccia, luce, segno (la botta del martello)
#   ossidiana: filo (il bordo rosa), corpo, taglio_a, taglio_b, luce
# python3 strumenti/grafica/monete.py
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "client", "assets", "ui")
SS = 4

SCAGLIA_FUORI = [(-13, -5), (-6, -13), (7, -12), (14, -3), (11, 10), (-2, 14), (-12, 8)]
OSSIDIANA = [(0, -15), (10, -4), (7, 12), (-4, 15), (-10, 1)]

STRATI = {
    "scaglia": [
        ("sagoma", "poligono", SCAGLIA_FUORI, 1.4),
        ("faccia", "poligono", [(-9, -4), (-4, -9), (6, -8), (10, -2), (8, 7), (-2, 10), (-8, 5)], 0),
        ("luce", "poligono", [(-6, -5), (1, -7), (-2, -1)], 0),
        ("segno", "linea", [(1, 3), (6, 1)], 1.6),
    ],
    "ossidiana": [
        ("filo", "poligono", OSSIDIANA, 3.2),
        ("corpo", "poligono", OSSIDIANA, 0),
        ("taglio_a", "poligono", [(0, -15), (10, -4), (2, 0)], 0),
        ("taglio_b", "poligono", [(2, 0), (7, 12), (-4, 15)], 0),
        ("luce", "linea", [(-7, -1), (-2, -10)], 1.6),
    ],
}


def disegna(tipo, punti, spessore, n):
    m = n * SS
    k = m / 34.0  # il viewBox (32) con un pixel d'aria per lato
    pts = [((x + 17) * k, (y + 17) * k) for x, y in punti]
    im = Image.new("L", (m, m), 0)
    d = ImageDraw.Draw(im)
    if tipo == "poligono":
        d.polygon(pts, fill=255)
        if spessore:
            w = max(1, round(spessore * k))
            d.line(pts + [pts[0]], fill=255, width=w, joint="curve")
            for x, y in pts:
                r = w / 2
                d.ellipse((x - r, y - r, x + r, y + r), fill=255)
    else:
        w = max(1, round(spessore * k))
        d.line(pts, fill=255, width=w)
        for x, y in (pts[0], pts[-1]):
            r = w / 2
            d.ellipse((x - r, y - r, x + r, y + r), fill=255)
    a = im.resize((n, n), Image.LANCZOS)
    out = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    out.putalpha(a)
    return out


for nome, strati in STRATI.items():
    for strato, tipo, punti, spessore in strati:
        for n, coda in ((128, ""), (48, "_p")):
            disegna(tipo, punti, spessore, n).save(
                os.path.join(OUT, "moneta_%s_%s%s.png" % (nome, strato, coda)), optimize=True)
