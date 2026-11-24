"""Il cielo del Limbo dietro la home (Sergio, 18 nov): la stellina e le nuvole
(«nuvole stilizzate carine che non spiccano», «contorni ben definiti», «più varianza»),
e dal 24 nov il cielo che cambia con l'ora (mattina, mezzogiorno, pomeriggio, sera,
notte: ui/limbo_sky.lua) con sole, luna e quello che passa in aria di giorno.

Scrive in client/paintings/backdrops/: stella.png, una stellina a quattro punte bianca (il
gioco la colora); le sei nuvole a fumetto piatte (base dritta coi capi tondi e gobbe
tonde sopra, contorno netto, corpo, una fascia d'ombra sul fondo e un ricciolo dentro la
gobba più grande) in tre strati bianchi che il gioco colora coi colori dell'ora:
nuvola_<n>_bordo/_corpo/_ombra.png; allo stesso modo il sole (sole_bordo/_corpo/_fascia)
e la falce di luna (luna_bordo/_corpo); e a colori fissi gli uccelli (tre pose delle ali,
bianchi), la foschia, il seme di soffione, il pulviscolo, la mongolfiera, le foglie,
l'aquilone e il suo fiocco.
Disegnate col campo delle distanze (o in grande e rimpicciolite) al doppio della misura a
cui le mostra il gioco: i bordi sono netti e lisci.

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
    """I tre strati bianchi di una nuvola: bordo (tutta la sagoma), corpo (dentro il
    contorno, senza il ricciolo) e ombra (la fascia sul fondo, senza il ricciolo). Il gioco
    li mette uno sopra l'altro coi colori dell'ora: è la stessa nuvola di prima."""
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
    resto = 1 - a_corpo * copertura(ricciolo(gobbe, x, y))
    return [bianco(a) for a in (a_fuori, a_corpo * resto, a_ombra * resto)]


def bianco(a):
    """Un'immagine bianca con questa copertura: il colore lo dà il gioco al nodo."""
    return Image.fromarray(np.dstack([np.full_like(a, 255)] * 3 + [a * 255]).round().astype(np.uint8), "RGBA")


def griglia_punti(r):
    """Le coordinate (in punti, y in su) di un quadrato di lato 2r attorno al centro."""
    n = int(round(2 * r * SCALA))
    v = (np.arange(n) + 0.5) / SCALA - r
    return np.meshgrid(v, -v)


SOLE = 48           # raggio del sole, in punti
LUNA = 40


def sole():
    """Il sole: un disco piatto, il bordo, il corpo e la fascia d'ombra in basso, come le nuvole."""
    x, y = griglia_punti(SOLE + 2)
    d = np.hypot(x, y) - SOLE
    corpo = copertura(d + TRATTO)
    fascia = corpo * np.clip(0.5 + (-(SOLE - 15) - y) * SCALA, 0, 1)
    return [bianco(copertura(d)), bianco(corpo), bianco(fascia)]


def luna():
    """La falce di luna: il disco meno un disco spostato in alto a destra; bordo e corpo."""
    x, y = griglia_punti(LUNA + 2)
    d = np.maximum(np.hypot(x, y) - LUNA, -(np.hypot(x - LUNA * 0.45, y - LUNA * 0.25) - LUNA * 0.95))
    return [bianco(copertura(d)), bianco(copertura(d + TRATTO))]


GRANDE = 4          # le figure a colori fissi: disegnate GRANDE volte più grandi, poi rimpicciolite


def tela(w, h):
    from PIL import ImageDraw
    k = SCALA * GRANDE
    im = Image.new("RGBA", (int(w * k), int(h * k)), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im), k


def finita(im):
    return im.resize((im.size[0] // GRANDE, im.size[1] // GRANDE), Image.LANCZOS)


def tratto(dr, punti, spessore, colore, k):
    """Una linea spessa coi capi e gli angoli tondi."""
    pp = [(px * k, py * k) for px, py in punti]
    dr.line(pp, fill=colore, width=int(spessore * k))
    r = spessore * k / 2
    for px, py in pp:
        dr.ellipse((px - r, py - r, px + r, py + r), fill=colore)


def curva(a, c, b, n=24):
    return [((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * c[0] + t * t * b[0],
             (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * c[1] + t * t * b[1]) for t in np.linspace(0, 1, n)]


def uccello(su):
    """Un uccellino lontano: due ali piegate, bianco (il gioco lo colora). su: ali in su (0.55), piatte, giù."""
    s, w, h = 13, 34, 30
    im, dr, k = tela(w, h)
    cx, cy = w / 2, h / 2 + 2
    p = curva((cx - s, cy - s * su), (cx - s * 0.45, cy - s * (0.35 + su * 0.4)), (cx, cy))
    p += curva((cx, cy), (cx + s * 0.45, cy - s * (0.35 + su * 0.4)), (cx + s, cy - s * su))[1:]
    tratto(dr, p, 3, (255, 255, 255, 255), k)
    return finita(im)


def foschia(w):
    """Una striscia di foschia: una pillola, il filo in alto più chiaro (bianco pieno sul
    corpo grigio chiaro: il gioco la colora)."""
    h = 20
    im, dr, k = tela(w + 2, h + 2)
    dr.rounded_rectangle((k, k, (w + 1) * k, (h + 1) * k), radius=h / 2 * k, fill=(184, 184, 184, 255))
    dr.rounded_rectangle(((1 + h / 2) * k, k, (w + 1 - h / 2) * k, (1 + 3) * k), radius=1.5 * k, fill=(255, 255, 255, 255))
    return finita(im)


def seme():
    """Il seme di soffione: il gambo, cinque peli a ventaglio e il seme in fondo."""
    im, dr, k = tela(20, 24)
    c = (236, 226, 238, 255)
    cx, cy = 10, 9
    tratto(dr, [(cx, cy), (cx, cy + 9)], 1.6, c, k)
    for j in range(-2, 3):
        tratto(dr, [(cx, cy), (cx + j * 3.2, cy - 6 + abs(j) * 1.2)], 1.6, c, k)
    dr.ellipse(((cx - 2) * k, (cy + 8) * k, (cx + 2) * k, (cy + 12) * k), fill=c)
    return finita(im)


def punto():
    im, dr, k = tela(6, 6)
    dr.ellipse((k, k, 5 * k, 5 * k), fill=(255, 255, 255, 255))
    return finita(im)


def mongolfiera():
    """La mongolfiera di mezzogiorno: a spicchi ruggine e crema, il bordo del colore del
    contorno delle nuvole a mezzogiorno, la cesta sotto."""
    from PIL import ImageDraw
    bordo, a, b, cesta = (134, 162, 192, 255), (200, 106, 74, 255), (230, 207, 168, 255), (150, 96, 64, 255)
    r, w, h = 30, 80, 112
    im, dr, k = tela(w, h)
    cx, cy = w / 2, 36
    # le corde e la cesta
    tratto(dr, [(cx - 12, cy + r * 0.9), (cx - 7, cy + r + 22)], 2, bordo, k)
    tratto(dr, [(cx + 12, cy + r * 0.9), (cx + 7, cy + r + 22)], 2, bordo, k)
    dr.rounded_rectangle(((cx - 11) * k, (cy + r + 20) * k, (cx + 11) * k, (cy + r + 34) * k), radius=3 * k, fill=bordo)
    dr.rounded_rectangle(((cx - 8) * k, (cy + r + 23) * k, (cx + 8) * k, (cy + r + 31) * k), radius=2 * k, fill=cesta)

    def pallone(rr, dy=0):
        t = np.linspace(np.pi * 0.85, np.pi * 2.15, 60)
        pts = [(cx + rr * np.cos(a_), cy - rr * np.sin(-a_) * -1 + dy) for a_ in t]
        pts = [(cx + rr * np.cos(a_), cy + rr * np.sin(a_) * -1) for a_ in np.linspace(np.pi * 1.15, -np.pi * 0.15, 60)]
        pts += curva((cx + rr * 0.89, cy + rr * 0.47), (cx + rr * 0.55, cy + rr * 0.9), (cx + 12 * rr / r, cy + rr * 1.05))
        pts += curva((cx - 12 * rr / r, cy + rr * 1.05), (cx - rr * 0.55, cy + rr * 0.9), (cx - rr * 0.89, cy + rr * 0.47))
        return [(px * k, py * k) for px, py in pts]
    dr.polygon(pallone(r + 3), fill=bordo)
    m = Image.new("L", im.size, 0)
    ImageDraw.Draw(m).polygon(pallone(r), fill=255)
    spicchi = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ds = ImageDraw.Draw(spicchi)
    for i in range(5):
        ds.rectangle(((cx - r + i * 2 * r / 5) * k, 0, (cx - r + (i + 1) * 2 * r / 5 + 1) * k, h * k), fill=(a, b)[i % 2])
    ds.rectangle(((cx - r) * k, (cy + r * 0.62) * k, (cx + r) * k, h * k), fill=(int(a[0] * .8), int(a[1] * .8), int(a[2] * .8), 255))
    # la fascia scura in basso: ogni spicchio un po' più scuro
    for i in range(5):
        c = (a, b)[i % 2]
        ds.rectangle(((cx - r + i * 2 * r / 5) * k, (cy + r * 0.62) * k, (cx - r + (i + 1) * 2 * r / 5 + 1) * k, h * k), fill=(int(c[0] * .8), int(c[1] * .8), int(c[2] * .8), 255))
    im.paste(spicchi, (0, 0), Image.composite(spicchi, Image.new("RGBA", im.size), m).split()[3])
    return finita(im)


def foglia(colore):
    """Una foglia del pomeriggio: una mandorla col bordo del contorno delle nuvole al
    pomeriggio e la nervatura."""
    bordo = (168, 108, 80, 255)
    im, dr, k = tela(32, 22)
    cx, cy = 16, 11

    def mandorla(s):
        p = curva((cx - s, cy), (cx, cy - s * 0.8), (cx + s, cy)) + curva((cx + s, cy), (cx, cy + s * 0.8), (cx - s, cy))
        return [(px * k, py * k) for px, py in p]
    dr.polygon(mandorla(14), fill=bordo)
    dr.polygon(mandorla(11), fill=colore)
    tratto(dr, [(cx - 9, cy), (cx + 9, cy)], 1.6, bordo, k)
    return finita(im)


def aquilone():
    """L'aquilone del pomeriggio: un rombo arancio a quattro spicchi, la croce, il bordo."""
    from PIL import ImageDraw
    bordo, a, b = (168, 108, 80, 255), (224, 138, 62, 255), (242, 178, 98, 255)
    w, h = 60, 84
    im, dr, k = tela(w, h)
    cx, cy = w / 2, h / 2

    def rombo(s):
        return [(cx * k, (cy - s * 1.15) * k), ((cx + s * 0.8) * k, cy * k), (cx * k, (cy + s * 1.15) * k), ((cx - s * 0.8) * k, cy * k)]
    dr.polygon(rombo(34), fill=bordo)
    dr.polygon(rombo(29), fill=a)
    m = Image.new("L", im.size, 0)
    ImageDraw.Draw(m).polygon(rombo(29), fill=255)
    chiaro = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dc = ImageDraw.Draw(chiaro)
    dc.rectangle(((cx - 30) * k, (cy - 40) * k, cx * k, cy * k), fill=b)
    dc.rectangle((cx * k, cy * k, (cx + 30) * k, (cy + 40) * k), fill=b)
    im.paste(chiaro, (0, 0), Image.composite(chiaro, Image.new("RGBA", im.size), m).split()[3])
    tratto(dr, [(cx, cy - 33), (cx, cy + 33)], 2.2, bordo, k)
    tratto(dr, [(cx - 23, cy), (cx + 23, cy)], 2.2, bordo, k)
    return finita(im)


def fiocco():
    """Un fiocco della coda dell'aquilone: due triangoli che si toccano."""
    im, dr, k = tela(18, 12)
    c = (242, 178, 98, 255)
    dr.polygon([(2 * k, 2 * k), (16 * k, 10 * k), (16 * k, 2 * k), (2 * k, 10 * k)], fill=c)
    return finita(im)


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
    def salva(im, nome):
        im.save(USCITA / (nome + ".png"), optimize=True)
        print(nome + ".png", im.size)
    salva(stella(), "stella")
    for i, (base, gobbe) in enumerate(NUVOLE, 1):
        for strato, im in zip(("bordo", "corpo", "ombra"), disegna(base, gobbe)):
            salva(im, "nuvola_%d_%s" % (i, strato))
    for strato, im in zip(("bordo", "corpo", "fascia"), sole()):
        salva(im, "sole_" + strato)
    for strato, im in zip(("bordo", "corpo"), luna()):
        salva(im, "luna_" + strato)
    for i, su in enumerate((0.55, 0.05, -0.45), 1):
        salva(uccello(su), "uccello_%d" % i)
    salva(foschia(360), "foschia_1")
    salva(foschia(520), "foschia_2")
    salva(seme(), "seme")
    salva(punto(), "punto")
    salva(mongolfiera(), "mongolfiera")
    for i, c in enumerate(((217, 120, 62, 255), (224, 162, 74, 255), (184, 90, 54, 255)), 1):
        salva(foglia(c), "foglia_%d" % i)
    salva(aquilone(), "aquilone")
    salva(fiocco(), "fiocco")


if __name__ == "__main__":
    main()
