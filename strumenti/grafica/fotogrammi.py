# Ritaglia i fogli di animazione del diavoletto (fatti da Gabriella con ChatGPT)
# nei fotogrammi del gioco:
#   client/assets/diavolo/<azione>_<n>.png     un fotogramma, a RES pixel per unità
#   client/battaglia/diavolo_fotogrammi.lua    misure, punto d'appoggio e fiammella
# I fogli stanno in gabriella/disegni/2026-10-25_animazioni/fogli/<azione>.png:
# fondo magenta, fotogrammi separati da spazio vuoto, in una o più righe uguali. ChatGPT disegna ogni foglio a una scala sua: la testa, che è la parte
# che cambia meno da una posa all'altra, riporta tutti alla misura della base.
# Unità del disegno come i pezzi: dalla cima della testa ai piedi sono 200.
# python3 strumenti/grafica/fotogrammi.py [cartella dei fogli]
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage as nd

QUI = os.path.dirname(os.path.abspath(__file__))
FOGLI = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/gabriella/disegni/2026-10-25_animazioni/fogli"
BASE = "/mnt/project-files/gabriella/disegni/2026-10-24_chatgpt/base_pezzi_1024.png"
OUT = os.path.join(QUI, "..", "..", "client", "assets", "diavolo")
LUA = os.path.join(QUI, "..", "..", "client", "battaglia", "diavolo_fotogrammi.lua")
RES = 1.0     # pixel dell'immagine per unità del disegno
MARGINE = 2   # pixel trasparenti attorno a ogni fotogramma

# nella base (tela 1024): piedi a y 941, cima della testa a y 240
S = 200 / (941 - 240)

# azione: (righe del foglio, larghezza della testa in pixel del foglio).
# La testa si misura come la corsa orizzontale più lunga nella parte alta della
# figura (testa più visiera); nei fotogrammi con le braccia alzate la misura le
# comprende, quindi il valore è quello delle pose senza braccia vicino alla testa
AZIONI = {
    "riposo": (1, 230), "camminata": (2, 180), "corsa": (2, 213), "salto": (1, 229), "mira": (1, 238),
    "fendente": (1, 222), "lancio": (1, 232), "colpito": (1, 246), "sconfitta": (1, 176),
    "teletrasporto": (1, 229), "vittoria": (1, 205), "paracadute": (1, 230),
}


def chiave(p):
    a = np.asarray(Image.open(p).convert("RGB")).astype(float)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    al = 1 - np.clip(((r + b) / 2 - g - 90) / 80, 0, 1)
    # il magenta mescolato nei bordi: si toglie il fondo dal colore
    am = np.maximum(al, 1e-3)[..., None]
    rgb = np.clip((a - (1 - am) * np.array([255, 0, 255])) / am, 0, 255)
    return rgb, al


def testa(m):
    """La corsa orizzontale più lunga nella parte alta della figura."""
    ys = np.nonzero(m.any(1))[0]
    best = 0
    for y in range(ys[0], ys[0] + int((ys[-1] - ys[0]) * 0.6)):
        d = np.diff(np.concatenate([[0], m[y].astype(int), [0]]))
        s, e = np.nonzero(d == 1)[0], np.nonzero(d == -1)[0]
        if len(s):
            best = max(best, (e - s).max())
    return best


def appoggio(rgb, m):
    """Il punto d'appoggio: in basso ai piedi, in x al centro della tuta rossa."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    tuta = m & (r > 190) & (g < 110) & (b < 90)
    ys, xs = np.nonzero(m)
    if tuta.sum() > 200:
        x = np.nonzero(tuta)[1].mean()
    else:
        x = (xs.min() + xs.max()) / 2
    return x, ys.max() + 1


def fiammella(rgb, m):
    """Il centro della fiammella (arancio e giallo), se c'è."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    f = m & (r > 220) & (g > 120) & (b < 110)
    if f.sum() < 30:
        return None
    ys, xs = np.nonzero(f)
    # solo la parte più alta: la fiammella sta sopra la testa
    alto = ys < ys.min() + (ys.max() - ys.min()) * 0.5 + 40
    return xs[alto].mean(), ys[alto].mean()


def fotogrammi(p, righe):
    rgb, al = chiave(p)
    m = al > 0.5
    l, n = nd.label(nd.binary_dilation(m, iterations=8))
    objs = nd.find_objects(l)
    sz = nd.sum(m, l, range(1, n + 1))
    grandi = [i for i in range(n) if sz[i] > 3000]
    lab = np.zeros(m.shape, int)
    for k, i in enumerate(grandi):
        lab[l == i + 1] = k + 1
    # i pezzetti staccati (gocce di fiamma, scintille) vanno al fotogramma sotto
    # cui stanno, o al più vicino
    for i in range(n):
        if i in grandi:
            continue
        sl = objs[i]
        x, y = (sl[1].start + sl[1].stop) / 2, (sl[0].start + sl[0].stop) / 2

        def dist(k):
            g = objs[grandi[k]]
            dentro = g[1].start - 20 <= x <= g[1].stop + 20
            return (0 if dentro else 1e6) + abs(x - (g[1].start + g[1].stop) / 2) + 0.1 * abs(y - (g[0].start + g[0].stop) / 2)
        lab[l == i + 1] = min(range(len(grandi)), key=dist) + 1
    # le righe dividono il foglio in fasce uguali; dentro una riga, da sinistra
    alta = m.shape[0] / righe

    def ordine(k):
        g = objs[grandi[k - 1]]
        return int((g[0].start + g[0].stop) / 2 // alta), g[1].start
    for k in sorted(range(1, len(grandi) + 1), key=ordine):
        mm = lab == k
        ys, xs = np.nonzero(mm & (al > 0.02))
        sl = (slice(ys.min(), ys.max() + 1), slice(xs.min(), xs.max() + 1))
        a = np.where(mm[sl], al[sl], 0)
        yield rgb[sl], a


def main():
    os.makedirs(OUT, exist_ok=True)
    # la base: misura della testa e punto d'appoggio, per i perni del braccio
    brgb, bal = chiave(BASE)
    bm = bal > 0.5
    testa_base = testa(bm)
    bx, by = appoggio(brgb, bm)
    righe = []
    area = 0
    for azione, (nrighe, larga) in AZIONI.items():
        k = testa_base / larga * S * RES   # pixel del foglio -> pixel del gioco
        righe.append("\t%s = {" % azione)
        for i, (rgb, a) in enumerate(fotogrammi(os.path.join(FOGLI, azione + ".png"), nrighe)):
            m = a > 0.5
            ax, ay = appoggio(rgb, m)
            f = fiammella(rgb, m)
            h, w = a.shape
            W, H = round(w * k) + 2 * MARGINE, round(h * k) + 2 * MARGINE
            im = Image.fromarray(np.dstack([rgb, a * 255]).astype("uint8"), "RGBA")
            im = im.resize((W - 2 * MARGINE, H - 2 * MARGINE), Image.LANCZOS)
            tela = Image.new("RGBA", (W, H))
            tela.paste(im, (MARGINE, MARGINE))
            nome = "%s_%d" % (azione, i + 1)
            tela.save(os.path.join(OUT, nome + ".png"), optimize=True)
            area += W * H
            # in unità, y verso l'alto, dal punto d'appoggio: centro dell'immagine e fiammella
            u = 1 / RES
            cx = ((w / 2 - ax) * k) * u
            cy = ((ay - h / 2) * k) * u
            riga = "\t\t{ img = \"%s\", w = %.1f, h = %.1f, x = %.1f, y = %.1f" % (nome, W * u, H * u, cx, cy)
            if f:
                riga += ", fx = %.1f, fy = %.1f" % ((f[0] - ax) * k * u, (ay - f[1]) * k * u)
            righe.append(riga + " },")
        righe.append("\t},")
    # la spalla del braccio davanti nella base, dal punto d'appoggio
    sx, sy = (530 - bx) * S, (by - 545) * S
    with open(LUA, "w") as fp:
        fp.write("-- Fatto da strumenti/grafica/fotogrammi.py, non modificare a mano.\n"
                 "-- Per ogni azione i fotogrammi del diavoletto: immagine, misura (w, h) e\n"
                 "-- centro (x, y) dell'immagine e fiammella (fx, fy) dal punto d'appoggio\n"
                 "-- (ai piedi, al centro del corpo), in unità del disegno con y verso l'alto.\n"
                 "return {\n\tspalla = { %.1f, %.1f },\n" % (sx, sy) + "\n".join(righe) + "\n}\n")
    print("fotogrammi: %d pixel in tutto" % area)


main()
