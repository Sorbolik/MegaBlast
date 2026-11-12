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
e tools/stampino/foglio.json (caselle e perni in pixel del foglio), che
legge taglia.py.

    python3 tools/stampino/stampino.py   (serve cairosvg: pip install cairosvg)
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
sys.path.insert(0, os.path.join(RADICE, "tools", "grafica"))
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
    "pugno": "pugno", "mantello": "mantello",
}

# Il mantello (WB-019): un posto fuori dalle righe, nel vuoto fra busto e ala, così
# le caselle di prima restano dove sono. Si disegna intero, appeso dietro le
# spalle; taglia.py lo divide in tre strisce che nel gioco si muovono da sole
# (scoria.lua). Unità del disegno dal perno (ATTACCO, il centro dietro le spalle),
# y in su: il bordo in alto, quello in fondo, i tagli fra le strisce (in alto e in
# fondo) e il perno di ogni striscia (il centro del suo bordo in alto).
MANTELLO_CENTRO = (1078, 1150)          # pixel del foglio, centro della casella
MARGINE_MANTELLO = 12
ATTACCO = (-2, 116)                     # il perno del mantello nel diavoletto
MANTELLO_ALTO = (-24, 24, 0)            # da x a x, a quota y
MANTELLO_FONDO = (-58, 22, -82)
TAGLI = [(-8, -31.3), (8, -4.7)]        # x in alto e x in fondo di ogni taglio
STRISCE = [(-16, 0), (0, 0), (16, 0)]   # i perni delle tre strisce


def gruppi_mantello():
    """La sagoma del mantello (il manichino della sua casella) e la sua scatola."""
    a0, a1, ya = MANTELLO_ALTO
    f0, f1, yf = MANTELLO_FONDO
    d = (f"M{a0},{ya} Q0,{ya + 4} {a1},{ya} L{f1},{yf + 4} Q{f1},{yf} {f1 - 4},{yf} "
         f"Q{(f0 + f1) / 2},{yf - 5} {f0 + 4},{yf + 1} Q{f0},{yf + 2} {f0 + 1},{yf + 6} Z")
    g = (f'<path d="{d}" fill="#9a9aa2" stroke="#202024" stroke-width="{DV.BORDO_D}" '
         'stroke-linejoin="round"/>')
    return [g], (f0 - 2, yf - 6, f1 + 2, ya + 4)


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
    if nome == "mantello":
        return gruppi_mantello()
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


# Il manichino è il personaggio del gioco (scoria.PERSONAGGIO): dal 2 nov
# l'apprendista. I suoi pezzi (pelli/<nome>.json, disegni in pelli/svg) vanno
# nelle stesse caselle, sullo stesso perno; i posti che non ha (l'ala) restano
# col pezzo di base, il mantello con la sua sagoma.
PERSONAGGIO = "apprendista"
PELLI = os.path.join(QUI, "pelli")


def personaggio():
    try:
        with open(os.path.join(PELLI, PERSONAGGIO + ".json")) as f:
            pelle = json.load(f)
    except OSError:
        return None, None
    return pelle["pezzi"], pelle


def svg_pezzo(img, w, h):
    """Il disegno SVG di un pezzo di una pelle a w x h pixel (None se non c'è)."""
    f = os.path.join(PELLI, "svg", img + ".svg")
    if not os.path.exists(f):
        return None
    import io
    import cairosvg
    png = cairosvg.svg2png(url=f, output_width=max(1, round(w)), output_height=max(1, round(h)))
    return Image.open(io.BytesIO(png)).convert("RGBA")


def metti_pezzo(tela, p, px, py, scala, angolo=0.0, jx=0.0, jy=0.0):
    """Un pezzo della pelle (col suo strato del colore) sulla tela: il perno del
    posto in (px, py) pixel, il giunto (jx, jy) unità dal perno, girato di
    angolo radianti. Falso se il pezzo non ha disegno."""
    im = svg_pezzo(p["img"], p["w"] * scala, p["h"] * scala)
    if im is None or p["w"] < 1:
        return False
    if p.get("tinta"):
        t = svg_pezzo(p["tinta"], p["w"] * scala, p["h"] * scala)
        if t is not None:
            im.alpha_composite(t)
    c, sn = math.cos(angolo), math.sin(angolo)
    cx, cy = jx + p["x"] * c - p["y"] * sn, jy + p["x"] * sn + p["y"] * c
    if angolo:
        im = im.rotate(math.degrees(angolo), resample=Image.BICUBIC, expand=True)
    tela.alpha_composite(im, (round(px + cx * scala - im.width / 2), round(py - cy * scala - im.height / 2)))
    return True


def immagine(n):
    """Il manichino di un posto, in grigio, grande come la sua casella."""
    pz = pezzo(n)
    box = scatola(pz, n)
    w, h = round((box[2] - box[0]) * S), round((box[3] - box[1]) * S)
    px, py = (0 - box[0]) * S, box[3] * S
    pezzi, pelle = personaggio()
    tela = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fatto = False
    if pezzi and n == "coda" and "coda_1" in pezzi:
        # la coda del personaggio a riposo: i bordi, poi i colori
        for suff in ("_bordo", ""):
            x, y = 0.0, 0.0
            for i, a in enumerate(pelle["coda_riposo"]):
                q = pezzi.get(f"coda_{i + 1}{suff}")
                if q:
                    fatto = metti_pezzo(tela, q, px, py, S, a, x, y) or fatto
                x, y = x + pelle["coda"][i] * math.cos(a), y + pelle["coda"][i] * math.sin(a)
    elif pezzi and n in pezzi:
        fatto = metti_pezzo(tela, pezzi[n], px, py, S)
    if not fatto:
        tela = disegna(pz[0], box, S)
    return grigio(tela)


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
            im = immagine(n)
            casella(n, pezzi[n], im, round(x), round(y + TITOLO + (alta - TITOLO - im.height) / 2), guida, ai, dg, caselle)
            x += larga + gap
        y += alta + spazio
    # il mantello, fuori dalle righe
    m = pezzo("mantello")
    im = immagine("mantello")
    casella("mantello", m, im, round(MANTELLO_CENTRO[0] - im.width / 2), round(MANTELLO_CENTRO[1] - im.height / 2),
            guida, ai, dg, caselle)
    legenda(dg, guida)
    guida.convert("RGB").save(os.path.join(OUT, "stampino.png"), optimize=True)
    ai.convert("RGB").save(os.path.join(OUT, "stampino_ai.png"), optimize=True)
    with open(FOGLIO, "w") as f:
        json.dump({"larghezza": W, "altezza": H, "scala": S, "posti": caselle}, f, indent=1)
        f.write("\n")
    manichino()
    print("OK:", os.path.relpath(OUT, RADICE), "e", os.path.relpath(FOGLIO, RADICE))


def scatola(pz, n=None):
    """La casella di un pezzo, in unità dal perno: il pezzo più il margine (il
    mantello ne ha meno, per starci fra busto e ala)."""
    x0, y0, x1, y1 = pz[1]
    m = MARGINE_MANTELLO if n == "mantello" else MARGINE
    return (x0 - m, y0 - m, x1 + m, y1 + m)


def croce(dg, px, py, r=14):
    dg.line([px - r, py, px + r, py], fill=(225, 40, 40, 255), width=4)
    dg.line([px, py - r, px, py + r], fill=(225, 40, 40, 255), width=4)


def casella(n, pz, im, bx, by, guida, ai, dg, caselle):
    """Il manichino di un posto nella sua casella, col nome, il perno e i giunti."""
    box = scatola(pz, n)
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
    if n == "mantello":
        # i tagli fra le strisce (tratteggiati) e il perno di ognuna
        ya, yf = MANTELLO_ALTO[2], MANTELLO_FONDO[2]
        for xa, xf in TAGLI:
            for i in range(0, 12, 2):
                t0, t1 = i / 12, (i + 1) / 12
                dg.line([px + (xa + (xf - xa) * t0) * S, py - (ya + (yf - ya) * t0) * S,
                         px + (xa + (xf - xa) * t1) * S, py - (ya + (yf - ya) * t1) * S],
                        fill=(40, 150, 90, 255), width=4)
        for sx, sy in STRISCE:
            croce(dg, px + sx * S, py - sy * S, 10)
    else:
        croce(dg, px, py)


def giunti(nome):
    """I giunti dentro un posto (unità, dal perno) e il raggio del bordo lì: dove
    il pezzo si piega su quello dopo (i segmenti della coda)."""
    pezzi, pelle = personaggio()
    if nome == "coda" and pelle and "coda_riposo" in pelle:
        # quelli della coda del personaggio, grandi come i suoi segmenti lì
        out, x, y = [], 0.0, 0.0
        for i, (L, a) in enumerate(zip(pelle["coda"], pelle["coda_riposo"])):
            x, y = x + L * math.cos(a), y + L * math.sin(a)
            q = [pezzi[f"coda_{j}_bordo"]["h"] for j in (i + 1, i + 2) if f"coda_{j}_bordo" in pezzi]
            out.append((x, y, min(q) / 2 if q else 10))
        return out[:-1]
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
    pezzi, pelle = personaggio()
    if pezzi:
        # il personaggio del gioco: i suoi pezzi sui punti dello scheletro, come li
        # monta il gioco a riposo (i perni spostati non cambiano dove stanno)
        k = 1024 / 300
        tela = Image.new("RGBA", im.size, (0, 0, 0, 0))
        punto = lambda x, y: ((x + 110) * k, (280 - y) * k)
        cx, cy = DV.PUNTI["coda"]
        X, Y = 0.0, 0.0
        for suff in ("_bordo", ""):
            X, Y = 0.0, 0.0
            for i, a in enumerate(pelle.get("coda_riposo", [])):
                q = pezzi.get(f"coda_{i + 1}{suff}")
                if q:
                    metti_pezzo(tela, q, *punto(cx, cy), k, a, X, Y)
                X, Y = X + pelle["coda"][i] * math.cos(a), Y + pelle["coda"][i] * math.sin(a)
        sx, sy = DV.PUNTI["spalle"]
        ax, ay = DV.PUNTI["anche"]
        for posto, (x, y) in [("ala", DV.PUNTI["ala"]), ("braccio_dietro", (-sx, sy)), ("gamba_dietro", (-ax, ay)),
                              ("gamba", (ax, ay)), ("busto", DV.PUNTI["bacino"]), ("testa", DV.PUNTI["collo"]),
                              ("braccio", (sx, sy))]:
            if posto in pezzi:
                metti_pezzo(tela, pezzi[posto], *punto(x, y), k)
        im = grigio(tela)
    fondo = Image.new("RGBA", (1024, 1024), MAGENTA)
    fondo.alpha_composite(im, ((1024 - im.width) // 2, (1024 - im.height) // 2))
    fondo.convert("RGB").save(os.path.join(OUT, "manichino.png"), optimize=True)


if __name__ == "__main__":
    main()
