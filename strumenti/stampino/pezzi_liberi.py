#!/usr/bin/env python3
"""Un foglio di pezzi liberi (3 righe x 4) rimontato sullo stampino.

Per i fogli dei personaggi a tre quarti (maschio, femmina, Favilla): pezzi
staccati su magenta, in quest'ordine.

  riga 1: sagoma della testa, faccia (occhi e bocca), maglietta, pantaloncini o gonna
  riga 2: braccio davanti, braccio dietro, pugno davanti (grande), pugno dietro
  riga 3: gamba davanti, gamba dietro, scarpa davanti (grande), scarpa dietro

I pezzi si rimettono insieme come vuole lo stampino: la faccia sulla testa
(nello stesso punto del disegno a tre quarti, RIF), i pantaloncini sotto la
maglietta (busto), il pugno in fondo al braccio, la scarpa in fondo alla gamba.
Braccia e gambe si girano dritte in giù: la spalla e l'anca sono il capo più in
alto sul foglio. Il risultato è un foglio dello stampino su magenta da tagliare con

  python3 strumenti/stampino/taglia.py USCITA.png --nome NOME --categoria personaggio --allinea --senza ala,coda

  python3 strumenti/stampino/pezzi_liberi.py FOGLIO.jpg RIF.png USCITA.png
"""
import json
import os
import sys

import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
import taglia as TG  # noqa: E402

MAGENTA = (255, 0, 255, 255)


def rgba(a):
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def ritaglia(a):
    al = a[..., 3] > 128
    x0, y0, x1, y1 = TG.scatola(al)
    return a[y0:y1, x0:x1]


def pezzi(foglio):
    """I 12 pezzi del foglio, per riga e colonna (la faccia resta intera)."""
    a = TG.fondo_via(Image.open(foglio))
    al = a[..., 3] > 128
    # passo largo (in proporzione al foglio): occhi, ciglia e bocca della faccia stanno insieme
    ms = [m for m in TG.macchie(al, passo=max(8, round(8 * al.shape[1] / 1280))) if m.sum() > 0.0008 * al.size]
    if len(ms) != 12:
        sys.exit(f"{foglio}: trovati {len(ms)} pezzi, ne servono 12 (3 righe x 4)")
    centri = [(np.nonzero(m)[0].mean(), np.nonzero(m)[1].mean(), m) for m in ms]
    centri.sort(key=lambda c: c[0])
    righe = [sorted(centri[i * 4:(i + 1) * 4], key=lambda c: c[1]) for i in range(3)]
    out = []
    for riga in righe:
        r = []
        for _, _, m in riga:
            pz = a.copy()
            pz[~m, 3] = 0
            r.append(ritaglia(pz))
        out.append(r)
    return out


def bianchi_chiusi(a):
    """I bianchi chiusi dal nero (gli occhi), come maschera."""
    from collections import deque
    bianco = (a[..., :3].min(axis=2) > 170) & (a[..., 3] > 128)
    fuori = np.zeros(bianco.shape, bool)
    h, w = bianco.shape
    # il bianco che tocca il bordo o il trasparente è fondo, non occhio
    vuoto = a[..., 3] <= 128
    q = deque()
    for y, x in zip(*np.nonzero(vuoto)):
        fuori[y, x] = True
        q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if bianco[y, x] and not fuori[y, x]:
                fuori[y, x] = True
                q.append((y, x))
    for x in range(w):
        for y in (0, h - 1):
            if bianco[y, x] and not fuori[y, x]:
                fuori[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= yy < h and 0 <= xx < w and not fuori[yy, xx] and (bianco[yy, xx] or vuoto[yy, xx]):
                fuori[yy, xx] = True
                q.append((yy, xx))
    return bianco & ~fuori


def occhi(bianchi):
    """Gli occhi fra i bianchi chiusi: il più in alto e quelli alla sua altezza
    (i guanti e la gonna stanno più in basso)."""
    ms = [m for m in TG.macchie(bianchi, passo=2) if m.sum() > 0.002 * bianchi.sum()]
    info = []
    for m in ms:
        ys, _ = np.nonzero(m)
        info.append((ys.min(), ys.mean(), ys.max() - ys.min(), m))
    info.sort(key=lambda i: i[0])
    _, cy, h, _ = info[0]
    out = np.zeros_like(bianchi)
    for _, y, _, m in info:
        if abs(y - cy) < 0.5 * h:
            out |= m
    return out


def correla(grande, piccolo):
    """Lo spostamento (dy, dx) dove piccolo combacia meglio dentro grande (+1/-1)."""
    H, W = grande.shape
    h, w = piccolo.shape
    F = np.fft.rfft2(grande, (H + h, W + w))
    G = np.fft.rfft2(piccolo[::-1, ::-1], (H + h, W + w))
    c = np.fft.irfft2(F * G, (H + h, W + w))[h - 1:H, w - 1:W]
    dy, dx = np.unravel_index(np.argmax(c), c.shape)
    return dy, dx


def testa_con_faccia(testa, faccia, rif):
    """La faccia sulla sagoma della testa, dove sta nel disegno a tre quarti."""
    r = np.asarray(Image.open(rif).convert("RGBA")).astype(np.float32)
    # nel disegno: la figura è tutto ciò che non è il bianco del fondo
    figura = ~((r[..., :3].min(axis=2) > 170) & ~bianchi_chiusi(r))
    occhi_r = occhi(bianchi_chiusi(r))
    occhi_f = occhi(bianchi_chiusi(faccia))
    rx0, ry0, rx1, ry1 = TG.scatola(occhi_r)
    fx0, fy0, fx1, fy1 = TG.scatola(occhi_f)
    k = (rx1 - rx0) / (fx1 - fx0)              # dal foglio al disegno
    # la sagoma della testa nel disegno, alla stessa scala
    s = rgba(testa).resize((max(1, round(testa.shape[1] * k)), max(1, round(testa.shape[0] * k))), Image.LANCZOS)
    sm = (np.asarray(s)[..., 3] > 128).astype(np.float32)
    dy, dx = correla(np.where(figura, 1.0, -1.0), sm)
    # dov'è la faccia rispetto alla testa, nel disegno e poi nel foglio
    ox = (rx0 - dx) / k - fx0
    oy = (ry0 - dy) / k - fy0
    return incolla([(testa, 0, 0), (faccia, ox, oy)])


def incolla(lista):
    """Più pezzi in un'immagine sola (il primo sotto), ognuno a (x, y)."""
    x0 = min(x for _, x, _ in lista)
    y0 = min(y for _, _, y in lista)
    x1 = max(x + p.shape[1] for p, x, _ in lista)
    y1 = max(y + p.shape[0] for p, _, y in lista)
    tela = Image.new("RGBA", (int(np.ceil(x1 - x0)), int(np.ceil(y1 - y0))), (0, 0, 0, 0))
    for p, x, y in lista:
        im = rgba(p)
        tela.alpha_composite(im, (int(round(x - x0)), int(round(y - y0))))
    return np.asarray(tela).astype(np.float32)


def busto(maglia, sotto):
    """La maglietta sopra i pantaloncini (o la gonna), centrati."""
    hm, wm = maglia.shape[:2]
    hs, ws = sotto.shape[:2]
    giu = hm - 0.12 * hm                        # la maglietta copre l'orlo di sopra
    return incolla([(sotto, (wm - ws) / 2, giu), (maglia, 0, 0)])


def dritto(pz):
    """Un tubo (braccio o gamba) girato dritto in giù: il capo più in alto sul
    foglio diventa quello di sopra. Torna il pezzo e il capo di sotto (x, y)."""
    al = pz[..., 3] > 128
    ys, xs = np.nonzero(al)
    pts = np.stack([xs, ys], 1).astype(np.float64)
    c = pts.mean(0)
    _, _, v = np.linalg.svd(pts - c, full_matrices=False)
    asse = v[0]
    t = (pts - c) @ asse
    a, b = pts[t.argmin()], pts[t.argmax()]
    # i capi: la media dei punti nel 10% di ogni estremità
    a = pts[t < t.min() + 0.1 * (t.max() - t.min())].mean(0)
    b = pts[t > t.max() - 0.1 * (t.max() - t.min())].mean(0)
    su, giu = (a, b) if a[1] < b[1] or (a[1] == b[1] and a[0] < b[0]) else (b, a)
    d = giu - su
    # angolo da girare (PIL: antiorario, y in giù) perché d punti in giù
    ang = np.degrees(np.arctan2(d[0], d[1]))
    im = rgba(pz).rotate(-ang, resample=Image.BICUBIC, expand=True)
    out = np.asarray(im).astype(np.float32)
    out = ritaglia(out)
    al = out[..., 3] > 128
    ys, xs = np.nonzero(al)
    fondo = ys > ys.max() - 0.08 * (ys.max() - ys.min())
    return out, (xs[fondo].mean(), ys.max())


def braccio(tubo, pugno):
    t, (bx, by) = dritto(tubo)
    hp, wp = pugno.shape[:2]
    # il capo del braccio entra un terzo nel pugno
    return incolla([(t, 0, 0), (pugno, bx - wp / 2, by - 0.3 * hp)])


def gamba(tubo, scarpa):
    t, (bx, by) = dritto(tubo)
    hs, ws = scarpa.shape[:2]
    al = scarpa[..., 3] > 128
    ys, xs = np.nonzero(al)
    cima = ys < ys.min() + 0.15 * hs
    cx = xs[cima].mean()                        # la caviglia, in cima alla scarpa
    return incolla([(t, 0, 0), (scarpa, bx - cx, by - 0.45 * hs)])


def sullo_stampino(posti, uscita):
    """Ogni pezzo al centro della sua casella dello stampino, grande quanto ci sta."""
    with open(TG.ST.FOGLIO) as f:
        F = json.load(f)
    tela = Image.new("RGBA", (F["larghezza"], F["altezza"]), MAGENTA)
    for posto, pz in posti.items():
        x0, y0, x1, y1 = F["posti"][posto]["casella"]
        h, w = pz.shape[:2]
        k = 0.85 * min((x1 - x0) / w, (y1 - y0) / h)
        im = rgba(pz).resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS)
        tela.alpha_composite(im, (round((x0 + x1 - im.width) / 2), round((y0 + y1 - im.height) / 2)))
    tela.convert("RGB").save(uscita)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    foglio, rif, uscita = sys.argv[1:]
    (testa, faccia, maglia, sotto), (br, br2, pg, pg2), (gb, gb2, sc, sc2) = pezzi(foglio)
    sullo_stampino({
        "testa": testa_con_faccia(testa, faccia, rif),
        "busto": busto(maglia, sotto),
        "braccio": braccio(br, pg),
        "braccio_dietro": braccio(br2, pg2),
        "gamba": gamba(gb, sc),
        "gamba_dietro": gamba(gb2, sc2),
        "pugno": pg,
    }, uscita)
    print("OK:", uscita)


if __name__ == "__main__":
    main()
