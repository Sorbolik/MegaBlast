#!/usr/bin/env python3
"""Taglia un foglio disegnato sullo stampino nei pezzi di una pelle del gioco.

Una pelle è un pezzo d'equipaggiamento (un elmo, una corazza, una maglia, delle
ali...) o un personaggio intero: un'immagine per ogni posto dello scheletro che
cambia. Il foglio è lo stampino (stampino.py) con i pezzi nuovi disegnati nelle
caselle: un PNG trasparente (il livello di Procreate) o un'immagine su magenta
(ChatGPT). Le caselle vuote o uguali al manichino non cambiano niente.

  python3 tools/stampino/taglia.py FOGLIO.png --nome elmo_corna --categoria elmo [--allinea]
  python3 tools/stampino/taglia.py --rifai        # solo skins.lua e l'atlante
  python3 tools/stampino/taglia.py --togli NOME   # toglie una pelle
  python3 tools/stampino/taglia.py --ritocchi tools/stampino/ritocchi.json
  python3 tools/stampino/taglia.py FOGLIO.png --nome maschio_1 --categoria personaggio --allinea --senza ala,coda

Scrive client/assets/skins/<nome>_<posto>.png, tools/stampino/pelli/<nome>.json
(com'è fatta la pelle), e rifà client/battle/skins.lua da tutte le pelli e
l'atlante del diavoletto, che le contiene insieme ai pezzi di base. --allinea sposta e scala ogni pezzo finché combacia col manichino: per
i disegni di ChatGPT, che non rispetta mai al pixel le caselle. --ritocchi mette
nelle pelli i pezzi spostati e ingranditi con gli strumenti dell'editor delle
animazioni (una lista di { pelle, posto, x, y, w, h }).
"""
import argparse
import glob
import json
import os
import re
import sys

import numpy as np
from PIL import Image, ImageFilter

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
sys.path.insert(0, QUI)
import stampino as ST  # noqa: E402

ASSETS = os.path.join(RADICE, "client", "assets", "skins")
JSON = os.path.join(QUI, "pelli")
LUA = os.path.join(RADICE, "client", "battle", "skins.lua")

# Le categorie: una pelle per categoria addosso. Le prime sostituiscono i pezzi
# del diavoletto, le altre si disegnano sopra, in quest'ordine.
SOSTITUISCE = ["personaggio", "testa", "corpo", "ali", "coda"]
SOPRA = ["pantaloni", "stivali", "maglia", "corazza", "guanti", "elmo", "mantello"]
# Il mantello (WB-019): si disegna intero nella sua casella e resta intero: il
# gioco lo piega lungo una catena simulata (battle/cloth.lua, battle/cape.fp).
# Non va nell'atlante: un'immagine a parte in client/assets/capes, più fitta
# dei pezzi (pixel per unità), perché lo shader la stira.
CAPES = os.path.join(RADICE, "client", "assets", "capes")
PX_MANTELLO = 3.0
# quanto il mantello è più grande della casella: con la casella dello stampino
# sull'apprendista restava quasi tutto dietro il corpo (WB-019 Vuoto, 13 nov)
GRANDE_MANTELLO = 1.35
CATEGORIE = SOSTITUISCE + SOPRA
# i pezzi di dietro, fatti da quelli davanti un po' più scuri se mancano
DIETRO = {"braccio_dietro": "braccio", "gamba_dietro": "gamba"}
# le nove facce del foglio delle teste (--teste, 3 x 3, da sinistra e dall'alto): quelle
# senza casella nello stampino vanno sul perno della testa, con la sua scala
FACCE = ["testa", "testa_colpita", "testa_felice", "testa_ko", "testa_mira", "testa_arrabbiata", "testa_sconfitta",
         "testa_paura", "testa_provocazione"]
SCURO = 0.78
# I pezzi in catena (i segmenti della coda): come
# quelli di base, in due strati. Il bordo è il pezzo intero, il colore lo stesso
# senza il contorno: il gioco disegna prima i bordi e poi i colori, così fra i
# segmenti non si vede la giuntura anche piegati.
CATENA = [f"coda_{i + 1}" for i in range(len(ST.DV.CODA))]
# lo spessore del contorno (unità del disegno), quanto si toglie al colore
BORDO = ST.DV.BORDO_D
# il colore della squadra: le parti dipinte di verde acceso (#00ff00) diventano
# del colore della squadra, con le loro ombre
TINTA_H = (85, 155)     # tinta (gradi) del verde chiave
TINTA_S = 0.55          # saturazione minima


def fondo_via(im):
    """Alfa del disegno: la trasparenza se c'è, altrimenti tutto tranne il magenta."""
    a = np.asarray(im.convert("RGBA")).astype(np.float32)
    if a[..., 3].min() < 250:
        return a
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    m = np.minimum(r, b) - g                  # quanto è magenta
    alfa = np.clip((150 - m) / 90, 0, 1)      # 150 e oltre: fondo
    # il bordo che sfuma nel magenta: si toglie il magenta mescolato, resta il colore
    k = np.maximum(alfa, 0.05)[..., None]
    a[..., :3] = np.clip((a[..., :3] - (1 - k) * np.array([255, 0, 255])) / k, 0, 255)
    a[..., 3] = alfa * 255
    return a


def manichino(posto):
    """Il manichino in grigio nella sua casella, come nello stampino (i pezzi del
    personaggio del gioco)."""
    return np.asarray(ST.immagine(posto)).astype(np.float32)


def allinea(pezzo, base):
    """Sposta e scala il pezzo (RGBA, grande come la casella) finché la sua sagoma
    combacia di più con quella del manichino. Torna il pezzo spostato."""
    h, w = base.shape[:2]
    mb = (base[..., 3] > 128).astype(np.float32)
    meglio, risultato = -1, pezzo
    im = Image.fromarray(pezzo.astype(np.uint8), "RGBA")
    for s in np.arange(0.88, 1.13, 0.03):
        sw, sh = round(w * s), round(h * s)
        sc = np.asarray(im.resize((sw, sh), Image.LANCZOS)).astype(np.float32)
        # al centro di una tela grande come la casella
        tela = np.zeros((h, w, 4), np.float32)
        ox, oy = (w - sw) // 2, (h - sh) // 2
        sx0, sy0 = max(0, -ox), max(0, -oy)
        tx0, ty0 = max(0, ox), max(0, oy)
        cw, ch = min(sw - sx0, w - tx0), min(sh - sy0, h - ty0)
        tela[ty0:ty0 + ch, tx0:tx0 + cw] = sc[sy0:sy0 + ch, sx0:sx0 + cw]
        mp = (tela[..., 3] > 128).astype(np.float32)
        # la correlazione per tutti gli spostamenti in una volta (FFT)
        c = np.real(np.fft.ifft2(np.fft.fft2(mb) * np.conj(np.fft.fft2(mp))))
        dy, dx = np.unravel_index(np.argmax(c), c.shape)
        dy = dy - h if dy > h // 2 else dy
        dx = dx - w if dx > w // 2 else dx
        if abs(dx) > w * 0.2 or abs(dy) > h * 0.2:
            continue
        inter = c.max()
        iou = inter / (mb.sum() + mp.sum() - inter + 1e-6)
        if iou > meglio:
            meglio, risultato = iou, np.roll(np.roll(tela, dy, 0), dx, 1)
    return risultato


def lontani(mask, r):
    """Dove la sagoma mask (0/1) è più lontana di r pixel dal fuori: la sagoma
    ristretta di r, con un disco (convoluzione con la FFT)."""
    r = max(1, int(round(r)))
    h, w = mask.shape
    H, W = h + 2 * r + 2, w + 2 * r + 2
    fuori = np.ones((H, W), np.float32)
    fuori[r + 1:r + 1 + h, r + 1:r + 1 + w] = 1 - mask
    yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
    disco = np.zeros((H, W), np.float32)
    disco[:2 * r + 1, :2 * r + 1] = (xx * xx + yy * yy <= r * r)
    c = np.real(np.fft.ifft2(np.fft.fft2(fuori) * np.fft.fft2(disco)))
    c = np.roll(np.roll(c, -r, 0), -r, 1)[r + 1:r + 1 + h, r + 1:r + 1 + w]
    return (c < 0.5) & (mask > 0)


def senza_contorno(al, scala):
    """La maschera al senza il contorno: ristretta dello spessore del contorno del
    manichino, o meno se il pezzo è più sottile (col contorno più sottile)."""
    r = BORDO * scala
    dentro = lontani(al.astype(np.float32), r)
    while dentro.sum() < 0.15 * al.sum() and r > 2:
        r *= 0.75
        dentro = lontani(al.astype(np.float32), r)
    return dentro


def colore(pz, scala):
    """Lo strato del colore di un pezzo in catena: senza il contorno."""
    al = pz[..., 3] > 128
    via = ~senza_contorno(al, scala)
    c = pz.copy()
    c[via, 3] = 0
    return c


def macchie(al, passo=4):
    """Le macchie del disegno (pezzi staccati) sul foglio: per ognuna la maschera
    a piena misura. Si cercano su una griglia passo volte più rada, allargata di
    una cella, così un pezzo con una riga sottile staccata resta intero."""
    from collections import deque
    h, w = al.shape
    g = al[:h - h % passo, :w - w % passo].reshape(h // passo, passo, w // passo, passo).max(axis=(1, 3))
    gg = g.copy()
    gg[1:] |= g[:-1]
    gg[:-1] |= g[1:]
    gg[:, 1:] |= g[:, :-1]
    gg[:, :-1] |= g[:, 1:]
    H, W = gg.shape
    lab = np.zeros((H, W), np.int32)
    n = 0
    for y0, x0 in zip(*np.nonzero(gg)):
        if lab[y0, x0]:
            continue
        n += 1
        lab[y0, x0] = n
        coda = deque([(y0, x0)])
        while coda:
            y, x = coda.popleft()
            for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if 0 <= yy < H and 0 <= xx < W and gg[yy, xx] and not lab[yy, xx]:
                    lab[yy, xx] = n
                    coda.append((yy, xx))
    grande = np.zeros((h, w), np.int32)
    grande[:H * passo, :W * passo] = np.repeat(np.repeat(lab, passo, 0), passo, 1)
    return [(grande == i) & al for i in range(1, n + 1)]


def trova(a, F):
    """I pezzi di un foglio che non rispetta le caselle (ChatGPT): ogni macchia va
    al posto con la casella più vicina. Torna per posto il pezzo ritagliato."""
    al = a[..., 3] > 128
    minimo = 0.0004 * al.size
    posti = {}
    # il mantello no: è una pelle a parte, non un pezzo del personaggio
    candidati = [p for p in F["posti"] if p != "mantello"]
    for m in macchie(al):
        if m.sum() < minimo:
            continue
        ys, xs = np.nonzero(m)
        cx, cy = xs.mean(), ys.mean()
        posto = min(candidati, key=lambda p: (cx - sum(F["posti"][p]["casella"][0::2]) / 2) ** 2 +
                    (cy - sum(F["posti"][p]["casella"][1::2]) / 2) ** 2)
        posti[posto] = posti[posto] | m if posto in posti else m
    out = {}
    for posto, m in posti.items():
        ys, xs = np.nonzero(m)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        pz = a[y0:y1, x0:x1].copy()
        pz[~m[y0:y1, x0:x1], 3] = 0
        out[posto] = pz
    return out


def scatola(al):
    ys, xs = np.nonzero(al)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def monta(pz, posto, F, s=None):
    """Un pezzo libero sullo scheletro: scalato (s, o quanto serve per avere l'area
    della scatola del manichino) e col perno nello stesso punto della sua scatola
    in cui il manichino ha il suo. Torna il pezzo, il perno e la scala."""
    c = F["posti"][posto]
    m = manichino(posto)
    mx0, my0, mx1, my1 = scatola(m[..., 3] > 128)
    px, py = c["perno"][0] - c["casella"][0], c["perno"][1] - c["casella"][1]
    dx0, dy0, dx1, dy1 = scatola(pz[..., 3] > 128)
    pz = pz[dy0:dy1, dx0:dx1]
    if s is None:
        s = ((mx1 - mx0) * (my1 - my0) / ((dx1 - dx0) * (dy1 - dy0))) ** 0.5
    w, h = max(1, round((dx1 - dx0) * s)), max(1, round((dy1 - dy0) * s))
    im = Image.fromarray(np.clip(pz, 0, 255).astype(np.uint8), "RGBA").resize((w, h), Image.LANCZOS)
    fx, fy = (px - mx0) / (mx1 - mx0), (py - my0) / (my1 - my0)
    return np.asarray(im).astype(np.float32), (fx * w, fy * h), s


def geodetica(m, da):
    """La distanza dentro la maschera m (passi di griglia) da un punto."""
    from collections import deque
    d = np.full(m.shape, -1, np.int32)
    d[da] = 0
    coda = deque([da])
    H, W = m.shape
    while coda:
        y, x = coda.popleft()
        for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= yy < H and 0 <= xx < W and m[yy, xx] and d[yy, xx] < 0:
                d[yy, xx] = d[y, x] + 1
                coda.append((yy, xx))
    return d


def dividi_coda(pz, scala, passo=3):
    """La coda disegnata (in qualunque posa e misura) nei segmenti della coda di
    base. Segue la coda dalla radice alla punta (la distanza dentro il disegno: la
    radice è il capo più spesso, dall'altro c'è il tridente), la taglia in cinque
    parti in proporzione ai segmenti di base (il tridente tutto nell'ultima: inizia
    dove la coda si allarga) e rimette ogni parte nel suo verso, lungo +x dal suo
    giunto. Lunghezze e angoli dei segmenti (la posa a riposo com'è disegnata)
    vanno nella pelle: il gioco la monta così e la muove con gli stessi
    angoli in più della coda di base, senza piegarla in un'altra posa. Ogni segmento si
    prende anche un disco attorno ai suoi due giunti, grande quanto è spessa la
    coda lì, così piegata resta tonda. Il colore senza contorno si toglie dalla
    coda intera (non dal segmento: ai tagli non c'è contorno). Torna per segmento
    il pezzo, il suo colore e il perno, e lunghezze e angoli dei segmenti."""
    import math
    al = pz[..., 3] > 128
    h, w = al.shape
    g = al[:h - h % passo, :w - w % passo].reshape(h // passo, passo, w // passo, passo).any(axis=(1, 3))
    ys, xs = np.nonzero(g)
    d0 = geodetica(g, (ys[0], xs[0]))
    a_ = np.unravel_index(np.argmax(d0), g.shape)
    da = geodetica(g, a_)
    b_ = np.unravel_index(np.argmax(da), g.shape)
    db = geodetica(g, b_)
    L = da.max()
    fy, fx = np.nonzero(~g)

    def spessore(dd):
        sel = (dd >= 0.03 * L) & (dd <= 0.08 * L)
        if not sel.any() or not len(fx):
            return 0
        y, x = np.nonzero(sel)
        return float(np.min(np.hypot(fx - x.mean(), fy - y.mean())))
    # la radice è il capo più spesso (dall'altro ci sono le punte del tridente)
    d = da if spessore(da) > spessore(db) else db
    # a piena misura: ogni pixel prende la distanza della sua cella (in pixel)
    D = np.full((h, w), -1.0, np.float32)
    D[:g.shape[0] * passo, :g.shape[1] * passo] = np.repeat(np.repeat(d, passo, 0), passo, 1) * passo
    D[~al] = -1
    lung = [Ls for Ls, _, _ in ST.DV.CODA]
    cum = np.cumsum([0] + lung)
    Dmax = D.max()
    # dove inizia il tridente: dopo metà coda, dove la coda diventa larga il
    # doppio di com'è a metà (senza tridente, dove finirebbe quella di base)
    quanti = np.bincount(d[d >= 0].ravel(), minlength=int(L) + 1).astype(np.float32)
    quanti = np.convolve(quanti, np.ones(5) / 5, mode="same")
    tipico = np.median(quanti[int(0.2 * L):int(0.7 * L)])
    larghi = [t for t in range(int(0.5 * L), int(L)) if quanti[t] > 1.8 * tipico]
    forca = (larghi[0] if larghi else L * cum[-1] / (cum[-1] + 20)) * passo
    confini = [c / cum[-1] * forca for c in cum]   # dove stanno i giunti lungo la coda
    yy, xx = np.mgrid[0:h, 0:w]

    def punto(t, fascia):
        sel = (D >= t - fascia) & (D <= t + fascia)
        if not sel.any():
            sel = D >= 0
        return xx[sel].mean(), yy[sel].mean()

    fascia = max(2 * passo, 0.02 * Dmax)
    J = [punto(max(t, fascia), fascia) for t in confini]
    J[0] = punto(fascia, fascia)
    corde = sum(math.hypot(J[i + 1][0] - J[i][0], J[i + 1][1] - J[i][1]) for i in range(len(lung)))
    k = scala * sum(lung) / max(corde, 1)        # pixel dello stampino per pixel del disegno
    fy, fx = np.nonzero(~al)
    raggio = [float(np.min(np.hypot(fx - x, fy - y))) if len(fx) else 0 for x, y in J]
    interno = senza_contorno(al, scala / k)
    out, lunghezze, angoli = [], [], []
    for i in range(len(lung)):
        lunghezze.append(round(math.hypot(J[i + 1][0] - J[i][0], J[i + 1][1] - J[i][1]) * k / scala, 1))
        angoli.append(math.atan2(-(J[i + 1][1] - J[i][1]), J[i + 1][0] - J[i][0]))
        dentro = (D >= confini[i]) & (D >= 0)
        if i < len(lung) - 1:
            dentro &= D < confini[i + 1]
        for j in (i, i + 1):
            dentro |= np.hypot(xx - J[j][0], yy - J[j][1]) <= raggio[j]
        dentro &= al
        if not dentro.any():
            out.append(None)
            continue
        (jx, jy), (kx, ky) = J[i], J[i + 1]
        n = math.hypot(kx - jx, ky - jy) or 1
        ex, ey = (kx - jx) / n, (ky - jy) / n
        sy, sx = np.nonzero(dentro)
        u = (k / scala) * ((sx - jx) * ex + (sy - jy) * ey)
        v = (k / scala) * ((sx - jx) * ey - (sy - jy) * ex)
        u0, u1, v0, v1 = u.min() - 2, u.max() + 2, v.min() - 2, v.max() + 2
        Wd, Hd = int(math.ceil((u1 - u0) * scala)), int(math.ceil((v1 - v0) * scala))
        X0 = jx + (scala / k) * (u0 * ex + v1 * ey)
        Y0 = jy + (scala / k) * (u0 * ey - v1 * ex)
        strati = []
        for m in (dentro, dentro & interno):
            seg = pz.copy()
            seg[~m, 3] = 0
            im = Image.fromarray(np.clip(seg, 0, 255).astype(np.uint8), "RGBA")
            im = im.transform((Wd, Hd), Image.AFFINE, (ex / k, -ey / k, X0, ey / k, ex / k, Y0), Image.BICUBIC)
            strati.append(np.asarray(im).astype(np.float32))
        out.append((strati[0], strati[1], (-u0 * scala, v1 * scala)))
    # angoli senza salti di un giro, il primo vicino a quello di base
    angoli = np.unwrap(angoli)
    angoli += 2 * math.pi * round((math.radians(ST.DV.CODA_RIPOSO[0]) - angoli[0]) / (2 * math.pi))
    return out, lunghezze, [round(float(a), 3) for a in angoli]


def tinta(pz):
    """Le parti verde acceso (il colore della squadra) in uno strato a parte, in
    grigi: il gioco lo colora con la squadra. Torna (pezzo, strato) o (pezzo, None)."""
    rgb = pz[..., :3] / 255
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    g = (rgb[..., 1] >= mx - 1e-6)
    hue = np.where(g, 120 + 60 * (rgb[..., 2] - rgb[..., 0]) / np.maximum(mx - mn, 1e-6), 0)
    chiave = g & (s >= TINTA_S) & (hue >= TINTA_H[0]) & (hue <= TINTA_H[1]) & (mx > 0.2) & (pz[..., 3] > 8)
    if chiave.sum() < 20:
        return pz, None
    t = np.zeros_like(pz)
    t[..., :3] = (mx * 255)[..., None]
    t[..., 3] = np.where(chiave, pz[..., 3], 0)
    pz = pz.copy()
    pz[chiave, :3] = (mx[chiave] * 255 * 0.5)[..., None]
    return pz, t


def vuoti(pezzi, nome, senza):
    """I posti che il personaggio non ha (ala, coda): un pezzo trasparente al
    posto di quello di base, così non si vede."""
    posti = []
    for p in senza:
        posti += [q for c in CATENA for q in (c, c + "_bordo")] if p == "coda" else [p]
    for posto in posti:
        img = f"{nome}_{posto}"
        Image.new("RGBA", (2, 2), (0, 0, 0, 0)).save(os.path.join(ASSETS, img + ".png"))
        pezzi[posto] = {"img": img, "x": 0.0, "y": 0.0, "w": 0.1, "h": 0.1, "modo": "sostituisce"}


def alla_misura(foglio, F):
    """Il foglio alla misura dello stampino (ChatGPT dà 1536 x 1024, Procreate
    quella giusta), senza il fondo."""
    im = Image.open(foglio).convert("RGBA")
    if im.size != (F["larghezza"], F["altezza"]):
        k = min(F["larghezza"] / im.width, F["altezza"] / im.height)
        im2 = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
        im = Image.new("RGBA", (F["larghezza"], F["altezza"]), (255, 0, 255, 255))
        im.paste(im2, (0, 0))
    return fondo_via(im)


def teste(foglio, F):
    """Le nove teste del foglio delle teste (3 x 3, nell'ordine di FACCE): le
    macchie più grandi, per righe e poi da sinistra."""
    a = alla_misura(foglio, F)
    al = a[..., 3] > 128
    ms = sorted(macchie(al, passo=1), key=lambda m: -m.sum())[:len(FACCE)]
    if len(ms) < len(FACCE):
        sys.exit(f"nel foglio delle teste servono {len(FACCE)} teste staccate")
    alta = max(scatola(m)[3] - scatola(m)[1] for m in ms)
    out = []
    for m in sorted(ms, key=lambda m: (round(np.nonzero(m)[0].mean() / alta), np.nonzero(m)[1].mean())):
        x0, y0, x1, y1 = scatola(m)
        pz = a[y0:y1, x0:x1].copy()
        pz[~m[y0:y1, x0:x1], 3] = 0
        out.append(pz)
    return out


# le braccia col pugno chiuso (--pugni): versioni in più delle braccia, per le
# impugnature; si scelgono nell'editor, il posto resta al braccio aperto
PUGNI = ("braccio", "braccio_dietro")


def pugni(foglio, F):
    """Le due braccia col pugno del foglio (--pugni), da sinistra: davanti e dietro."""
    a = alla_misura(foglio, F)
    ms = sorted(macchie(a[..., 3] > 128, passo=1), key=lambda m: -m.sum())[:2]
    if len(ms) < 2:
        sys.exit("nel foglio dei pugni servono due braccia staccate")
    out = []
    for m in sorted(ms, key=lambda m: np.nonzero(m)[1].mean()):
        x0, y0, x1, y1 = scatola(m)
        pz = a[y0:y1, x0:x1].copy()
        pz[~m[y0:y1, x0:x1], 3] = 0
        out.append(pz)
    return out


def versione(pezzi, posto):
    """Il nome della prossima versione di un posto (busto_1, busto_2...): ogni
    disegno resta nella pelle e nell'editor si sceglie quale va in scena."""
    n = [int(m.group(1)) for k in pezzi for m in [re.fullmatch(re.escape(posto) + r"_(\d+)", k)] if m]
    return f"{posto}_{max(n, default=0) + 1}"


def file_della_pelle(nome):
    """I PNG e gli SVG della pelle, non quelli di un'altra che comincia col suo nome
    (favilla e favilla_1)."""
    altre = [os.path.basename(f)[:-5] for f in glob.glob(os.path.join(JSON, nome + "_*.json"))]
    fuori = tuple(n + "_" for n in altre)
    return [f for f in glob.glob(os.path.join(ASSETS, nome + "_*.png")) + glob.glob(os.path.join(SVG, nome + "_*.svg"))
            + glob.glob(os.path.join(CAPES, nome + "_*.png"))
            if not os.path.basename(f).startswith(fuori)]


def taglia(foglio, nome, categoria, sopra, allinea_pezzi, senza=(), foglio_teste=None, foglio_pugni=None, aggiungi=False):
    with open(ST.FOGLIO) as f:
        F = json.load(f)
    D = leggi_diavoletto()
    px = D["px"]
    os.makedirs(ASSETS, exist_ok=True)
    pezzi, forma = {}, {}
    if aggiungi:
        # i pezzi nuovi si aggiungono alla pelle come versioni in più
        with open(os.path.join(JSON, nome + ".json")) as f:
            vecchia = json.load(f)
        pezzi = vecchia["pezzi"]
        forma = {k: vecchia[k] for k in ("coda", "coda_riposo", "coda_radice", "mantello") if k in vecchia}
    else:
        for f in file_della_pelle(nome):
            os.remove(f)
    if allinea_pezzi and not sopra:
        # ChatGPT: pezzi liberi, ognuno montato sullo scheletro; le facce con la scala della testa
        liberi = trova(alla_misura(foglio, F), F) if foglio else {}
        if foglio_teste:
            liberi = {p: v for p, v in liberi.items() if not p.startswith("testa")}
            for i, pz in enumerate(teste(foglio_teste, F)):
                liberi[FACCE[i]] = pz
        if foglio_pugni:
            for posto, pz in zip(PUGNI, pugni(foglio_pugni, F)):
                liberi[posto + "/pugno"] = pz
        s_testa, scale = None, {}
        alto = lambda im: scatola(im[..., 3] > 128)[3] - scatola(im[..., 3] > 128)[1]
        for chiave in sorted(liberi, key=lambda p: (p != "testa", "/" in p)):
            pz = liberi[chiave]
            if chiave == "coda":
                forma = metti_coda(pezzi, pz, nome, F["scala"], px, sopra)
                continue
            posto, pugno = chiave.split("/")[0], "/" in chiave
            faccia = posto.startswith("testa")
            s = None
            if faccia and s_testa:
                # le facce alte quanto la testa (ChatGPT le disegna di misure un po' diverse)
                s = s_testa * alta / alto(pz)
            elif pugno:
                # il braccio col pugno: alto quanto il braccio aperto di questa pelle
                if posto not in pezzi:
                    sys.exit(f"--pugni vuole prima {posto} nella pelle")
                s = pezzi[posto]["h"] * F["scala"] / alto(pz)
            pz, perno, s = monta(pz, "testa" if faccia else posto, F, s)
            if posto == "testa":
                s_testa, alta = s, alto(liberi["testa"])
            # ogni disegno è una versione numerata; il posto prende l'ultima (i pugni no)
            v = versione(pezzi, posto)
            metti(pezzi, pz, nome, v, perno, F["scala"], px, sopra)
            if not pugno:
                pezzi[posto] = dict(pezzi[v])
    elif foglio_teste or foglio_pugni or aggiungi:
        sys.exit("--teste, --pugni e --aggiungi solo con --allinea, per i personaggi")
    else:
        a = alla_misura(foglio, F)
        for posto, c in F["posti"].items():
            if (posto == "mantello") != (categoria == "mantello"):
                continue
            x0, y0, x1, y1 = c["casella"]
            pz = a[y0:y1, x0:x1].copy()
            base = manichino(posto)
            if sopra:
                # via quello che è ancora il manichino: resta solo il disegno nuovo
                uguale = (np.abs(pz[..., :3] - base[..., :3]).max(axis=2) < 24) & (base[..., 3] > 200)
                pz[uguale, 3] = 0
            if (pz[..., 3] > 128).sum() < 0.004 * pz.shape[0] * pz.shape[1]:
                continue
            if allinea_pezzi:
                pz = allinea(pz, base)
            if posto == "coda":
                forma = metti_coda(pezzi, pz, nome, F["scala"], px, sopra)
            elif posto == "mantello":
                forma = metti_mantello(pezzi, pz, nome, F["scala"], px, (c["perno"][0] - x0, c["perno"][1] - y0))
            else:
                metti(pezzi, pz, nome, posto, (c["perno"][0] - x0, c["perno"][1] - y0), F["scala"], px, sopra)
    if not pezzi and "mantello" not in forma:
        sys.exit("nessun pezzo disegnato nello stampino")
    if senza:
        if sopra:
            sys.exit("--senza solo per le pelli che sostituiscono")
        vuoti(pezzi, nome, senza)
    # le versioni di dietro, se mancano: più scure (il colore della squadra no)
    for dietro, davanti in DIETRO.items():
        if davanti in pezzi and dietro not in pezzi:
            p = dict(pezzi[davanti])
            img = Image.open(os.path.join(ASSETS, p["img"] + ".png"))
            r, g, b, al = img.split()
            img = Image.merge("RGBA", [ch.point(lambda v: round(v * SCURO)) for ch in (r, g, b)] + [al])
            p["img"] = f"{nome}_{dietro}"
            img.save(os.path.join(ASSETS, p["img"] + ".png"), optimize=True)
            if p.get("tinta"):
                t = Image.open(os.path.join(ASSETS, p["tinta"] + ".png"))
                p["tinta"] = f"{nome}_{dietro}_tinta"
                t.save(os.path.join(ASSETS, p["tinta"] + ".png"), optimize=True)
            pezzi[dietro] = p
    modo = "sopra" if sopra else "sostituisce"
    os.makedirs(JSON, exist_ok=True)
    with open(os.path.join(JSON, nome + ".json"), "w") as f:
        json.dump({"nome": nome, "categoria": categoria, **forma, "pezzi": pezzi}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print(f"{nome} ({categoria}, {modo}): {', '.join(sorted(pezzi))}")


def metti_coda(pezzi, pz, nome, scala, px, sopra):
    if sopra:
        sys.exit("la coda si cambia solo intera (categoria coda o personaggio), non sopra")
    segmenti, lunghezze, angoli = dividi_coda(pz, scala)
    for i, seg in enumerate(segmenti):
        if seg:
            metti(pezzi, seg[0], nome, f"coda_{i + 1}", seg[2], scala, px, sopra, seg[1])
    return {"coda": lunghezze, "coda_riposo": angoli}


def metti(pezzi, pz, nome, posto, perno, scala, px, sopra, col=None):
    """Il pezzo di un posto, col suo strato del colore della squadra; quelli in
    catena che sostituiscono la base anche col bordo a parte. Con la tavolozza
    (TAVOLOZZA) anche il pezzo in SVG, ricalcato dal disegno grande (in catena
    ogni strato)."""
    if TAVOLOZZA and posto not in CATENA:
        disegno_svg(pz, f"{nome}_{posto}", scala, px)
    pz, t = tinta(pz)
    modo = "sopra" if sopra else "sostituisce"
    strati = [(posto, pz)]
    if posto in CATENA and not sopra:
        if col is None:
            col = colore(pz, scala)
        else:
            col = col.copy()
            col[..., :3] = pz[..., :3]   # col ha il verde: prende i colori già tolti a pz
        strati = [(posto + "_bordo", pz), (posto, col)]
    for p, im in strati:
        if TAVOLOZZA and posto in CATENA:
            disegno_svg(im, f"{nome}_{p}", scala, px)   # i segmenti della coda: bordo e colore
        pezzi[p] = salva(im, nome, p, perno[0], perno[1], scala, px)
        pezzi[p]["modo"] = modo
        if t is not None:
            st = t.copy()
            st[im[..., 3] <= 8, 3] = 0
            pezzi[p]["tinta"] = salva(st, nome, p + "_tinta", perno[0], perno[1], scala, px, scatola=im)["img"]


TAVOLOZZA = None    # la tavolozza (vettoriale.py) dei personaggi: allora anche gli SVG
SVG = os.path.join(JSON, "svg")


def disegno_svg(pz, nome_img, scala, px):
    """Il pezzo in SVG (e lo strato del colore della squadra, se c'è), alla stessa
    misura in pixel del PNG del gioco: tools/stampino/pelli/svg/<img>.svg."""
    import vettoriale as VT
    ys, xs = np.nonzero(pz[..., 3] > 8)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    w, h = (x1 - x0) / scala, (y1 - y0) / scala
    misura = (max(1, round(w * px)), max(1, round(h * px)))
    os.makedirs(SVG, exist_ok=True)
    base, squadra = VT.svg_pezzo(pz[y0:y1, x0:x1], TAVOLOZZA, misura)
    with open(os.path.join(SVG, nome_img + ".svg"), "w") as f:
        f.write(base)
    if squadra:
        with open(os.path.join(SVG, nome_img + "_tinta.svg"), "w") as f:
            f.write(squadra)


def salva(pz, nome, posto, px0, py0, scala, px, scatola=None):
    """Il pezzo ritagliato alla sua sagoma, rimpicciolito ai pixel del gioco; torna
    centro e misura rispetto al perno, in unità del disegno."""
    # scatola: il pezzo di cui questo è lo strato del colore, con la stessa misura
    al = (pz if scatola is None else scatola)[..., 3]
    ys, xs = np.nonzero(al > 8)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    img = Image.fromarray(np.clip(pz[y0:y1, x0:x1], 0, 255).astype(np.uint8), "RGBA")
    w, h = (x1 - x0) / scala, (y1 - y0) / scala
    img = img.resize((max(1, round(w * px)), max(1, round(h * px))), Image.LANCZOS)
    img = img.filter(ImageFilter.UnsharpMask(1, 40, 2))
    nome_img = f"{nome}_{posto}"
    img.save(os.path.join(ASSETS, nome_img + ".png"), optimize=True)
    cx, cy = ((x0 + x1) / 2 - px0) / scala, (py0 - (y0 + y1) / 2) / scala
    return {"img": nome_img, "x": round(cx, 1), "y": round(cy, 1), "w": round(w, 1), "h": round(h, 1)}


def metti_mantello(pezzi, pz, nome, scala, px, perno):
    """Il mantello intero: un'immagine a parte (CAPES), con un bordo vuoto di un
    pixel e nell'angolo in alto a sinistra un pixel quasi trasparente, che dice
    allo shader dov'è l'alto. Torna dov'è rispetto all'attacco (unità) e dove
    è attaccato nel diavoletto."""
    os.makedirs(CAPES, exist_ok=True)
    al = pz[..., 3]
    ys, xs = np.nonzero(al > 8)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    g = GRANDE_MANTELLO
    w, h = (x1 - x0) / scala * g, (y1 - y0) / scala * g
    img = Image.fromarray(np.clip(pz[y0:y1, x0:x1], 0, 255).astype(np.uint8), "RGBA")
    pw, ph = max(1, round(w * PX_MANTELLO)), max(1, round(h * PX_MANTELLO))
    img = img.resize((pw, ph), Image.LANCZOS)
    tela = Image.new("RGBA", (pw + 2, ph + 2), (0, 0, 0, 0))
    tela.paste(img, (1, 1))
    tela.putpixel((0, 0), (0, 0, 0, 6))
    nome_img = f"{nome}_mantello"
    tela.save(os.path.join(CAPES, nome_img + ".png"), optimize=True)
    # il bordo vuoto conta nella misura
    w, h = (pw + 2) / PX_MANTELLO, (ph + 2) / PX_MANTELLO
    cx, cy = ((x0 + x1) / 2 - perno[0]) / scala * g, (perno[1] - (y0 + y1) / 2) / scala * g
    return {"mantello": {"img": nome_img, "x": round(cx, 1), "y": round(cy, 1), "w": round(w, 1), "h": round(h, 1),
                         "attacco": list(ST.ATTACCO)}}


def leggi_diavoletto():
    """px dal diavoletto di base (battle/devil.lua): i pezzi nuovi hanno la
    stessa densità."""
    with open(os.path.join(RADICE, "client", "battle", "devil.lua")) as f:
        for riga in f:
            riga = riga.strip()
            if riga.startswith("px ="):
                return {"px": float(riga.split("=")[1].split(",")[0])}
    raise SystemExit("px non trovato in devil.lua")


def rifai():
    """client/battle/skins.lua e l'atlante del diavoletto da tutte le pelli."""
    pelli = []
    for f in sorted(glob.glob(os.path.join(JSON, "*.json"))):
        with open(f) as fh:
            pelli.append(json.load(fh))
    lua = ["-- Made by tools/stampino/taglia.py, do not edit by hand.",
           "-- The skins: the devil's new pieces drawn on the stencil. Each piece goes",
           "-- in a slot of the skeleton (like the pieces of battle/devil.lua: image,",
           "-- center relative to the pivot, size) and replaces the base piece or is",
           "-- drawn over it. One skin per category; the \"over\" ones in order. A new",
           "-- tail has its own lengths, its rest angles (radians) and, if the editor",
           "-- moved it, how far its root is moved (tail_root). A cape: its drawing",
           "-- (client/assets/capes), its center and size from where it is attached",
           "-- (drawing units) and where it is attached in the devil (at).",
           "return {",
           "\treplace = { " + ", ".join(f'"{c}"' for c in SOSTITUISCE) + " },",
           "\tover = { " + ", ".join(f'"{c}"' for c in SOPRA) + " },",
           "\tskins = {"]
    # the skin JSON files (tools/stampino/pelli) keep the tool's names
    forme = {"coda": "tail", "coda_riposo": "tail_rest", "coda_radice": "tail_root"}
    modi = {"sostituisce": "replace", "sopra": "over"}
    for p in pelli:
        forma = "".join(f'{forme[k]} = {{ {", ".join(str(v) for v in p[k])} }}, ' for k in forme if k in p)
        if "mantello" in p:
            m = p["mantello"]
            forma += (f'cape = {{ img = "{m["img"]}", x = {m["x"]}, y = {m["y"]}, w = {m["w"]}, h = {m["h"]}, '
                      f'at = {{ {m["attacco"][0]}, {m["attacco"][1]} }} }}, ')
        lua.append(f'\t\t{p["nome"]} = {{ category = "{p["categoria"]}", {forma}pieces = {{')
        for posto in sorted(p["pezzi"]):
            z = p["pezzi"][posto]
            t = f'"{z["tinta"]}"' if z.get("tinta") else "nil"
            lua.append(f'\t\t\t{posto} = {{ img = "{z["img"]}", tint = {t}, x = {z["x"]}, y = {z["y"]}, '
                       f'w = {z["w"]}, h = {z["h"]}, mode = "{modi[z["modo"]]}" }},')
        lua.append("\t\t} },")
    lua += ["\t},", "}"]
    with open(LUA, "w") as f:
        f.write("\n".join(lua) + "\n")
    ST.DV.scrivi_atlante()
    print("OK:", len(pelli), "pelli in", os.path.relpath(LUA, RADICE))


def specchia(img, nuovo):
    """La copia girata di un'immagine di una pelle (PNG del gioco e SVG, se c'è)."""
    if img == nuovo:
        return img
    Image.open(os.path.join(ASSETS, img + ".png")).transpose(Image.FLIP_LEFT_RIGHT).save(os.path.join(ASSETS, nuovo + ".png"), optimize=True)
    svg = os.path.join(SVG, img + ".svg")
    if os.path.exists(svg):
        t = open(svg).read()
        vb = [float(v) for v in re.search(r'viewBox="([^"]*)"', t).group(1).split()]
        a = t.index(">", t.index("<svg")) + 1
        b = t.rindex("</svg>")
        with open(os.path.join(SVG, nuovo + ".svg"), "w") as f:
            f.write(t[:a] + f'<g transform="translate({vb[2]:g} 0) scale(-1 1)">' + t[a:b] + "</g>\n" + t[b:])
    return nuovo


def ritocca(file):
    """I ritocchi dell'editor delle animazioni: centro e misura nuovi dei pezzi."""
    with open(file) as f:
        ritocchi = json.load(f)
    for r in ritocchi:
        percorso = os.path.join(JSON, r["pelle"] + ".json")
        with open(percorso) as f:
            pelle = json.load(f)
        if r["posto"] == "coda":
            # la coda intera: le lunghezze nuove dei segmenti (i pezzi si ingrandiscono
            # in proporzione) e dove sta la radice
            s = sum(r["coda"]) / sum(pelle["coda"])
            s = 1 if abs(s - 1) < 0.005 else s
            pelle["coda"] = [round(float(v), 1) for v in r["coda"]]
            for c in CATENA:
                for q in (c, c + "_bordo"):
                    for k in ("x", "y", "w", "h"):
                        pelle["pezzi"][q][k] = round(pelle["pezzi"][q][k] * s, 1)
            pelle.pop("coda_radice", None)
            if any(r["radice"]):
                pelle["coda_radice"] = [round(float(v), 1) for v in r["radice"]]
            with open(percorso, "w") as f:
                json.dump(pelle, f, indent=1, ensure_ascii=False)
                f.write("\n")
            continue
        pz = pelle["pezzi"][r["posto"]]
        if r.get("da") or r.get("specchio"):
            # un altro disegno della pelle in questo posto (lo stesso PNG, ripetibile)
            # o specchiato attorno al perno: allora una copia girata
            fonte = dict(pelle["pezzi"][r.get("da") or r["posto"]])
            for k in ("img", "tinta"):
                if fonte.get(k) and r.get("specchio"):
                    fonte[k] = specchia(fonte[k], f'{r["pelle"]}_{r["posto"]}_specchio' + ("_tinta" if k == "tinta" else ""))
            pz = pelle["pezzi"][r["posto"]] = {**fonte, "modo": pz["modo"]}
        for k in ("x", "y", "w", "h"):
            pz[k] = round(float(r[k]), 1)
        with open(percorso, "w") as f:
            json.dump(pelle, f, indent=1, ensure_ascii=False)
            f.write("\n")
    print("OK:", len(ritocchi), "pezzi ritoccati")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("foglio", nargs="?")
    ap.add_argument("--nome")
    ap.add_argument("--categoria", choices=CATEGORIE)
    ap.add_argument("--sopra", action="store_true", help="i pezzi vanno sopra quelli di base (default per la categoria)")
    ap.add_argument("--sostituisce", action="store_true", help="i pezzi prendono il posto di quelli di base")
    ap.add_argument("--allinea", action="store_true", help="allinea ogni pezzo al manichino (disegni di ChatGPT)")
    ap.add_argument("--senza", default="", help="posti che il personaggio non ha, tolti (ala,coda)")
    ap.add_argument("--teste", help="foglio con le nove teste senza collo, 3 x 3 (furbo, colpita, felice, ko, mira, arrabbiata, sconfitta, paura, provocazione): prendono il posto di quelle del foglio")
    ap.add_argument("--pugni", help="foglio con le due braccia col pugno chiuso (davanti, dietro): versioni in più delle braccia, per le impugnature")
    ap.add_argument("--aggiungi", action="store_true", help="aggiunge i pezzi alla pelle che c'è già, come versioni in più (busto_2...)")
    ap.add_argument("--tavolozza", help="la tavolozza del personaggio (tools/stampino/tavolozze): fa anche gli SVG dei pezzi")
    ap.add_argument("--rifai", action="store_true")
    ap.add_argument("--togli")
    ap.add_argument("--ritocchi", help="i ritocchi dell'editor delle animazioni (ritocchi.json)")
    a = ap.parse_args()
    if a.ritocchi:
        ritocca(a.ritocchi)
    elif a.togli:
        for f in file_della_pelle(a.togli) + [os.path.join(JSON, a.togli + ".json")]:
            if os.path.exists(f):
                os.remove(f)
    elif not a.rifai:
        if not ((a.foglio or (a.aggiungi and (a.teste or a.pugni))) and a.nome and a.categoria):
            ap.error("servono FOGLIO, --nome e --categoria")
        if not re.fullmatch(r"[a-z][a-z0-9_]*", a.nome) or a.nome in ST.DV.PEZZI:
            ap.error("il nome: lettere minuscole, cifre e _, diverso dai pezzi di base")
        sopra = a.sopra or (a.categoria in SOPRA and not a.sostituisce)
        senza = [p for p in a.senza.split(",") if p]
        for p in senza:
            if p not in ("ala", "coda"):
                ap.error("--senza: solo ala e coda")
        global TAVOLOZZA
        if a.tavolozza:
            import vettoriale as VT
            TAVOLOZZA = VT.leggi_tavolozza(a.tavolozza)
        taglia(a.foglio, a.nome, a.categoria, sopra, a.allinea, senza, a.teste, a.pugni, a.aggiungi)
    rifai()


if __name__ == "__main__":
    main()
