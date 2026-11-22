"""Rigioca il file esportato da Blender (simulazione/blender/fornace.lua) come farebbe il gioco:
ogni pezzo è la sua immagine, spostata, girata e scalata sul perno, figlio del suo padre. Serve
a controllare che l'esportazione rifaccia quello che si vede in Blender, prima di toccare il gioco.

    python3 tools/blender/rigioca.py simulazione/blender/fornace.lua simulazione/blender/rigioca
scrive un PNG per fotogramma (60 al secondo) con la stessa inquadratura della camera della scena.
"""
import math
import os
import re
import sys

from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(os.path.dirname(QUI))
CARTELLE = [os.path.join(QUI, "pezzi_provvisori"), os.path.join(RADICE, "art/WB-043/ritagli")]
SFONDO = (245, 227, 195, 255)
LARGO, ALTO, CENTRO, VISTA = 640, 680, (193, 210), 440   # come la camera di scena_fornace.py
FPS = 60


def leggi(file):
    testo = open(file, encoding="utf-8").read()
    durata = float(re.search(r"duration = ([\d.]+)", testo).group(1))
    pezzi = []
    for riga in re.findall(r"\{ (name = .*?) \},\n", testo):
        p = {"name": re.search(r'name = "(.*?)"', riga).group(1)}
        for k in ("image", "parent"):
            m = re.search(k + r' = "(.*?)"', riga)
            p[k] = m and m.group(1)
        for k in ("pivot", "anchor", "size"):
            m = re.search(k + r" = \{ ([-\d.]+), ([-\d.]+) \}", riga)
            p[k] = (float(m.group(1)), float(m.group(2))) if m else None
        p["depth"] = float(re.search(r"depth = ([-\d.]+)", riga).group(1))
        m = re.search(r"scale = ([-\d.]+)", riga)
        p["scale"] = float(m.group(1)) if m else 1.0
        pezzi.append(p)
    tracce = {}
    for nome, valori in re.findall(r"\t\t(\w+) = \{ ([-\d., ]+) \},", testo):
        n = [float(x) for x in valori.split(",")]
        tracce[nome] = [(n[i], n[i + 1]) for i in range(0, len(n), 3)]
    return durata, pezzi, tracce


def valore(tracce, nome, t, neutro):
    k = tracce.get(nome)
    if not k:
        return neutro
    if t <= k[0][0]:
        return k[0][1]
    for (t0, v0), (t1, v1) in zip(k, k[1:]):
        if t <= t1:
            return v0 + (v1 - v0) * (t - t0) / (t1 - t0)
    return k[-1][1]


def per(a, b):   # matrici 2D affini (a, b, c, d, e, f): x' = a x + c y + e, y' = b x + d y + f
    return (a[0] * b[0] + a[2] * b[1], a[1] * b[0] + a[3] * b[1],
            a[0] * b[2] + a[2] * b[3], a[1] * b[2] + a[3] * b[3],
            a[0] * b[4] + a[2] * b[5] + a[4], a[1] * b[4] + a[3] * b[5] + a[5])


def inversa(m):
    a, b, c, d, e, f = m
    det = a * d - b * c
    return (d / det, -b / det, -c / det, a / det, (c * f - d * e) / det, (b * e - a * f) / det)


def immagine(p):
    if not p["image"]:   # il segnaposto: un rettangolo scuro grande come lo sportello
        return Image.new("RGBA", (int(p["size"][0]), int(p["size"][1])), (69, 39, 25, 255))
    for c in CARTELLE:
        f = os.path.join(c, p["image"])
        if os.path.exists(f):
            return Image.open(f).convert("RGBA")
    raise SystemExit("immagine mancante: " + p["image"])


def rigioca(file, cartella):
    durata, pezzi, tracce = leggi(file)
    per_nome = {p["name"]: p for p in pezzi}
    img = {p["name"]: immagine(p) for p in pezzi}
    z = max(LARGO, ALTO) / VISTA   # come Blender: la vista ortografica copre il lato più lungo
    # dallo schermo (y in giù) al disegno (y in su)
    camera = (z, 0, 0, -z, LARGO / 2 - CENTRO[0] * z, ALTO / 2 + (-CENTRO[1]) * z)
    os.makedirs(cartella, exist_ok=True)
    for f in range(int(round(durata * FPS)) + 1):
        t = f / FPS
        quadro = Image.new("RGBA", (LARGO, ALTO), SFONDO)
        mondo = {}

        def profondita(p):
            return p["depth"]

        def matrice(p):
            if p["name"] in mondo:
                return mondo[p["name"]]
            n = p["name"]
            px, py = p["pivot"] or (0, 0)
            x = px + valore(tracce, n + "_x", t, 0)
            y = -py + valore(tracce, n + "_y", t, 0)
            padre = per_nome.get(p["parent"]) if p["parent"] else None
            if padre:
                ppx, ppy = padre["pivot"]
                x, y = x - ppx, y + ppy
            r = valore(tracce, n + "_rot", t, 0)
            sx = valore(tracce, n + "_scale_x", t, 1) * p["scale"]
            sy = valore(tracce, n + "_scale_y", t, 1) * p["scale"]
            c, s = math.cos(r), math.sin(r)
            m = (c * sx, s * sx, -s * sy, c * sy, x, y)
            if padre:
                pm = matrice(padre)
                # il padre passa posizione, rotazione e scala, non la sua scala di riposo
                m = per(pm, m)
            mondo[n] = m
            return m

        ordine = sorted(range(len(pezzi)), key=lambda i: (valore(tracce, pezzi[i]["name"] + "_z", t, 0) + profondita(pezzi[i]), i))
        for p in (pezzi[i] for i in ordine):
            a = valore(tracce, p["name"] + "_alpha", t, 1)
            if a <= 0.002:
                continue
            m = matrice(p)
            ax, ay = p["anchor"]
            # dall'immagine (pixel, y in giù) al pezzo (perno in 0, y in su)
            dentro = (1, 0, 0, -1, -ax, ay)
            totale = per(camera, per(m, dentro))
            pezzo = img[p["name"]]
            if a < 1:
                pezzo = pezzo.copy()
                pezzo.putalpha(pezzo.getchannel("A").point(lambda v: int(v * a)))
            a_, b_, c_, d_, e_, f_ = inversa(totale)   # PIL vuole (a, c, e, b, d, f)
            strato = pezzo.transform((LARGO, ALTO), Image.AFFINE, (a_, c_, e_, b_, d_, f_), Image.BILINEAR)
            quadro.alpha_composite(strato)
        quadro.convert("RGB").save(os.path.join(cartella, "f_%04d.png" % f))
    print("rigiocati %d fotogrammi in %s" % (f + 1, cartella))


if __name__ == "__main__":
    rigioca(sys.argv[1], sys.argv[2])
