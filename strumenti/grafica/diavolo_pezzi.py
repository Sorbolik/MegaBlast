# Ritaglia il diavoletto a pezzi staccati dal disegno di Gabriella (Procreate,
# fondo già magenta) nei pezzi del gioco:
#   client/assets/diavolo_pezzi/<pezzo>.png    a RES pixel per unità
#   client/battaglia/diavolo_pezzi.lua         misura e posto di ogni pezzo
# Il disegno è su un livello solo: dove un pezzo copre l'altro, quello davanti
# si prende il contorno e quello dietro si chiude da solo (il corpo col suo
# guscio convesso, colorato col colore più vicino). Coi livelli separati di
# Procreate questo passo non servirà più.
# Unità del disegno come i fotogrammi: dalla cima della testa ai piedi sono 200,
# il punto d'appoggio è sotto i piedi, al centro del corpo.
# python3 strumenti/grafica/diavolo_pezzi.py [disegno]
import os
import sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd
from scipy.spatial import ConvexHull

QUI = os.path.dirname(os.path.abspath(__file__))
DISEGNO = sys.argv[1] if len(sys.argv) > 1 else \
    "/mnt/project-files/gabriella/disegni/2026-10-25_pezzi_staccati/disegno_gabriella_v1_magenta.png"
OUT = os.path.join(QUI, "..", "..", "client", "assets", "diavolo_pezzi")
LUA = os.path.join(QUI, "..", "..", "client", "battaglia", "diavolo_pezzi.lua")
RES = 1.0
MARGINE = 2
CIMA, PIEDI = 345, 1322          # cima della testa (senza corna) e piedi, nel disegno
S = 200 / (PIEDI - CIMA)         # unità per pixel del disegno

# nel blocco unico i pezzi si separano con delle forme disegnate sopra
# (pixel del disegno): la coda e l'ala come poligoni, i pugni come cerchi,
# la testa come ellisse (con corna e visiera sopra il corpo); il resto è corpo
CODA = [(35, 630), (80, 618), (115, 640), (165, 668), (210, 700), (232, 740), (236, 785),
        (218, 825), (206, 862), (204, 900), (222, 945), (236, 985), (222, 1002), (196, 990),
        (172, 935), (163, 870), (172, 818), (192, 772), (184, 738), (150, 705), (105, 692),
        (82, 705), (40, 655)]
ALA = [(204, 905), (230, 840), (262, 790), (300, 745), (340, 705), (362, 690), (372, 700),
       (372, 740), (350, 800), (320, 870), (300, 920), (262, 925), (232, 930), (210, 935)]
PUGNI = {"pugno_sx": (278, 992, 64), "pugno_dx": (752, 985, 62)}
TESTA = (517, 540, 224, 198)
SCURO = np.array([22, 16, 12])


def chiave(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    al = 1 - np.clip(((r + b) / 2 - g - 90) / 80, 0, 1)
    am = np.maximum(al, 1e-3)[..., None]
    rgb = np.clip((a - (1 - am) * np.array([255, 0, 255])) / am, 0, 255)
    return rgb, al


def vicino(maschera, punto):
    ys, xs = np.nonzero(maschera)
    i = np.argmin((xs - punto[0]) ** 2 + (ys - punto[1]) ** 2)
    return ys[i], xs[i]


def main():
    a = np.asarray(Image.open(DISEGNO).convert("RGB")).astype(float)
    rgb, al = chiave(a)
    fig = al > 0.05
    lab, n = nd.label(fig)
    sz = nd.sum(fig, lab, range(1, n + 1))
    blocco = lab == 1 + int(np.argmax(sz))
    pezzi = {}
    # fuori dal blocco: la fiammella (le gocce sopra la testa) e le scarpe
    altri = fig & ~blocco
    la, na = nd.label(altri)
    pezzi["fiammella"] = np.zeros_like(fig)
    for i, sl in enumerate(nd.find_objects(la)):
        m = la == i + 1
        if m.sum() < 30:
            continue
        cy = (sl[0].start + sl[0].stop) / 2
        cx = (sl[1].start + sl[1].stop) / 2
        if cy < CIMA:
            pezzi["fiammella"] |= m
        elif cy > 1150:
            pezzi["scarpa_sx" if cx < 500 else "scarpa_dx"] = m

    # nel blocco: forme da davanti a dietro, ognuna prende quello che resta
    yy, xx = np.mgrid[:fig.shape[0], :fig.shape[1]]
    resto = blocco.copy()

    def prendi(m):
        m = m & resto
        resto[m] = False
        return m

    def poligono(pts):
        g = Image.new("L", (fig.shape[1], fig.shape[0]), 0)
        ImageDraw.Draw(g).polygon(pts, fill=1)
        return np.asarray(g).astype(bool)

    for nome, (cx, cy, r) in PUGNI.items():
        pezzi[nome] = prendi((xx - cx) ** 2 + (yy - cy) ** 2 < r * r)
    cx, cy, rx, ry = TESTA
    rosso = a[..., 0] > a[..., 1] + 70
    # sotto il mento il rosso è già corpo, e il contorno subito sotto anche
    sotto = nd.binary_dilation(rosso & (yy > 690), iterations=6) & (yy > 690)
    pezzi["testa"] = prendi(((((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 < 1) & ~sotto) | (yy < 690) & ~poligono(CODA))
    pezzi["coda"] = prendi(poligono(CODA))
    # l'ala è dietro al corpo: dentro il poligono, solo quello che non è rosso
    pezzi["ala"] = prendi(poligono(ALA) & ~(rosso & (xx > 300)))
    # il corpo è il pezzo grande che resta; le briciole di contorno si buttano
    lr, nr = nd.label(resto)
    pezzi["corpo"] = lr == 1 + int(np.argmax(nd.sum(resto, lr, range(1, nr + 1))))
    pieno = blocco & (a.max(2) >= 50)
    # via le briciole staccate rimaste a un pezzo
    for nome in ["testa", "coda", "ala"] + list(PUGNI):
        lp, npz = nd.label(pezzi[nome])
        if npz > 1:
            sz = nd.sum(pezzi[nome], lp, range(1, npz + 1))
            pezzi[nome] = np.isin(lp, 1 + np.nonzero(sz > sz.max() * 0.02)[0])

    # il corpo dietro testa e pugno: si chiude col suo guscio convesso
    corpo = pezzi["corpo"]
    # il guscio si prende dal rosso della tuta (le briciole di contorno dei
    # pezzi vicini restano fuori), più lo spessore del contorno
    ys, xs = np.nonzero(corpo & rosso)
    pts = np.stack([xs, ys], 1)[::7]
    hull = pts[ConvexHull(pts).vertices]
    g = Image.new("L", (fig.shape[1], fig.shape[0]), 0)
    ImageDraw.Draw(g).polygon([tuple(p) for p in hull], fill=1)
    guscio = nd.binary_dilation(np.asarray(g).astype(bool), iterations=8)
    corpo = corpo & guscio
    # e senza i bordi chiari dei pugni rimasti fuori dai cerchi
    for cx, cy, r in PUGNI.values():
        vicino_pugno = (xx - cx) ** 2 + (yy - cy) ** 2 < (r + 16) ** 2
        corpo &= ~(vicino_pugno & ~rosso & (a.max(2) > 110))
    nascosto = guscio & ~corpo
    pieno_corpo = corpo & pieno
    _, (iy, ix) = nd.distance_transform_edt(~pieno_corpo, return_indices=True)
    # su una copia: sotto il corpo chiuso ci sono i pixel della testa e dei pugni
    rgb_corpo, al_corpo = rgb.copy(), al.copy()
    rgb_corpo[nascosto] = rgb[iy, ix][nascosto]
    bordo = nascosto & (nd.distance_transform_edt(guscio) < 8)
    rgb_corpo[bordo] = SCURO
    al_corpo[nascosto] = 1
    pezzi["corpo"] = corpo | nascosto

    # appoggio: x al centro del corpo, y sotto i piedi
    xs = np.nonzero(pezzi["corpo"].any(0))[0]
    ax = (xs[0] + xs[-1]) / 2
    os.makedirs(OUT, exist_ok=True)
    righe = []
    for nome in ["coda", "ala", "corpo", "scarpa_sx", "scarpa_dx", "testa", "fiammella", "pugno_sx", "pugno_dx"]:
        m = pezzi[nome]
        ys, xs = np.nonzero(m)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        c, l = (rgb_corpo, al_corpo) if nome == "corpo" else (rgb, al)
        alpha = np.where(m, l, 0)[y0:y1, x0:x1]
        img = np.dstack([c[y0:y1, x0:x1], alpha * 255]).astype(np.uint8)
        w, h = round((x1 - x0) * S * RES), round((y1 - y0) * S * RES)
        im = Image.fromarray(img, "RGBA").resize((w, h), Image.LANCZOS)
        tela = Image.new("RGBA", (w + 2 * MARGINE, h + 2 * MARGINE))
        tela.paste(im, (MARGINE, MARGINE))
        tela.save(os.path.join(OUT, nome + ".png"))
        cx = ((x0 + x1) / 2 - ax) * S
        cy = (PIEDI - (y0 + y1) / 2) * S
        righe.append('\t{ nome = "%s", w = %d, h = %d, x = %.1f, y = %.1f },' % (
            nome, tela.width / RES, tela.height / RES, cx, cy))
        print(nome, tela.size, round(cx, 1), round(cy, 1))
    with open(LUA, "w") as f:
        f.write("-- Generato da strumenti/grafica/diavolo_pezzi.py: non modificare a mano.\n")
        f.write("-- I pezzi del diavoletto, da dietro a davanti: misura e centro in unità\n")
        f.write("-- del disegno (200 dalla cima della testa ai piedi), dall'appoggio, y in su.\n")
        f.write("return {\n" + "\n".join(righe) + "\n}\n")


if __name__ == "__main__":
    main()
