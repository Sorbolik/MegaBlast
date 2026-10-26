# Ritaglia i pezzi del diavoletto dalle immagini fatte con ChatGPT
# (strumenti/grafica/diavoletto/: testa, busto con ala e coda, una gamba, fiammella)
# e li mette in scala sulle unità del disegno:
#   client/assets/scoria/<pezzo>.png          il pezzo a colori
#   client/assets/scoria/<pezzo>_sagoma.png   la sua sagoma bianca, per il lampo del colpo
#   client/assets/scoria/<pezzo>_bordo.png    la sagoma allargata, per il contorno chiaro
#   client/battaglia/scoria_pezzi.lua         centro, misura e perno di ogni pezzo
# Unità del disegno: il corpo che colpisce va da x 0 a 150 e da y 0 a 200 (y verso
# il basso, piedi a 200). Le tre immagini di un pezzo hanno la stessa tela.
# La coda viene staccata dal busto e tagliata in segmenti lungo la sua linea, così
# il gioco la fa ondeggiare; la radice, dietro l'ala, resta sul busto, ferma.
# python3 strumenti/grafica/scoria.py
import os
import numpy as np
from PIL import Image
from scipy import ndimage as nd

QUI = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(QUI, "diavoletto")
OUT = os.path.join(QUI, "..", "..", "client", "assets", "scoria")
LUA = os.path.join(QUI, "..", "..", "client", "battaglia", "scoria_pezzi.lua")
RES = 2.5   # pixel dell'immagine per unità del disegno
BORDO = 2.5   # spessore del contorno chiaro, in unità del disegno

# Ogni pezzo: scala (unità per pixel dell'immagine sorgente, una o x e y) e perno, cioè il
# punto dell'immagine sorgente attorno a cui gira e dove va nel disegno.
# Le scale vengono dalle proporzioni del diavoletto intero di Gabriella
# (gabriella/disegni/2026-10-25_nuovi_diavoletti/originale_senza_braccia.png).
PEZZI = {
    "testa": dict(scala=0.101, perno=(615, 1115), dove=(69, 97)),
    "busto": dict(scala=0.1125, perno=(832, 950), dove=(69, 155.7)),
    # la gamba di ChatGPT è un tubo lungo e stretto: la allarghiamo e la accorciamo come
    # i pantaloni larghi del diavoletto intero
    "gamba": dict(scala=(0.068, 0.0505), perno=(535, 360), dove=(0, 0)),
    "fiammella": dict(scala=0.054, perno=(630, 974), dove=(72, 13)),
}
# la linea della coda nel busto sorgente, dalla radice alla punta
CODA = [(625, 890), (540, 930), (470, 935), (380, 905), (320, 840), (290, 750),
        (300, 660), (345, 590), (390, 520), (395, 450), (360, 400), (320, 360)]
SEGMENTI = 5
SOVRAPPOSTO = 18   # pixel sorgente di ogni segmento che finiscono sotto il precedente


def carica(nome):
    return np.asarray(Image.open(os.path.join(SRC, nome + ".png")).convert("RGBA")).astype(np.float32)


def senza_bordo_bianco(im):
    """Toglie il bordo chiaro "da adesivo" attorno al pezzo: tutto ciò che è chiaro
    e tocca il fondo, fino al contorno scuro."""
    a = im[..., 3]
    lum = im[..., :3].mean(-1)
    passabile = (a < 250) | (lum > 140)
    fuori, _ = nd.label(passabile)
    fondo = np.unique(fuori[a < 10])
    via = np.isin(fuori, fondo[fondo > 0])
    im = im.copy()
    im[via, 3] = 0
    return im


def maschera_coda(im):
    h, w = im.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    return (((xx < 640) & (yy > 860)) | ((xx < 434) & (yy <= 860))) & (im[..., 3] > 0)


def lungo_la_linea(punti, h, w):
    """Per ogni pixel: la distanza lungo la linea del punto più vicino."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    meglio = np.full((h, w), np.inf, np.float32)
    t = np.zeros((h, w), np.float32)
    fatto = 0.0
    for (x0, y0), (x1, y1) in zip(punti, punti[1:]):
        dx, dy = x1 - x0, y1 - y0
        L = (dx * dx + dy * dy) ** 0.5
        u = np.clip(((xx - x0) * dx + (yy - y0) * dy) / (L * L), 0, 1)
        d = (xx - x0 - u * dx) ** 2 + (yy - y0 - u * dy) ** 2
        m = d < meglio
        meglio[m] = d[m]
        t[m] = fatto + u[m] * L
        fatto += L
    return t, fatto


def punto_a(punti, s):
    for (x0, y0), (x1, y1) in zip(punti, punti[1:]):
        L = ((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5
        if s <= L:
            return (x0 + (x1 - x0) * s / L, y0 + (y1 - y0) * s / L)
        s -= L
    return punti[-1]


def esporta(nome, im, scala, perno, dove):
    """Scala il pezzo a RES pixel per unità e salva le tre immagini; rende centro e
    misura della tela (unità del disegno) e il perno nel disegno."""
    sx, sy = scala if isinstance(scala, tuple) else (scala, scala)
    # i puntini quasi trasparenti lasciati dal generatore non contano
    im = im.copy()
    im[im[..., 3] < 8, 3] = 0
    ys, xs = np.nonzero(im[..., 3] > 0)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    crop = im[y0:y1, x0:x1]
    # margine trasparente perché il bordo allargato non tocchi la tela
    pad = int(np.ceil((BORDO + 2) / min(sx, sy)))
    crop = np.pad(crop, ((pad, pad), (pad, pad), (0, 0)))
    x0, y0 = x0 - pad, y0 - pad
    W, H = max(1, round(crop.shape[1] * sx * RES)), max(1, round(crop.shape[0] * sy * RES))
    # colori premoltiplicati per ridurre senza aloni scuri sui bordi
    pm = crop.copy()
    pm[..., :3] *= pm[..., 3:4] / 255
    pic = Image.fromarray(pm.clip(0, 255).astype(np.uint8), "RGBA").resize((W, H), Image.LANCZOS)
    p = np.asarray(pic).astype(np.float32)
    al = p[..., 3:4]
    p[..., :3] = np.where(al > 0, p[..., :3] * 255 / np.maximum(al, 1), 0)
    Image.fromarray(p.clip(0, 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, nome + ".png"), optimize=True)
    alfa = p[..., 3]
    bianco = Image.new("L", (W, H), 255)
    Image.merge("RGBA", (bianco,) * 3 + (Image.fromarray(alfa.astype(np.uint8)),)).save(
        os.path.join(OUT, nome + "_sagoma.png"), optimize=True)
    # il bordo: la sagoma allargata di BORDO unità
    dist = nd.distance_transform_edt(alfa < 128)
    largo = np.clip((BORDO * RES + 0.5 - dist) * 255, 0, 255)
    Image.merge("RGBA", (bianco,) * 3 + (Image.fromarray(largo.astype(np.uint8)),)).save(
        os.path.join(OUT, nome + "_bordo.png"), optimize=True)
    # centro della tela rispetto al perno, in unità
    cx = dove[0] + ((x0 + crop.shape[1] / 2) - perno[0]) * sx
    cy = dove[1] + ((y0 + crop.shape[0] / 2) - perno[1]) * sy
    return dict(x=cx, y=cy, w=W / RES, h=H / RES, px=dove[0], py=dove[1])


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith(".png"):
            os.remove(os.path.join(OUT, f))
    righe, fatti = [], {}
    pezzi = {n: carica(n) for n in PEZZI}
    pezzi["testa"] = senza_bordo_bianco(pezzi["testa"])

    # la coda: via dal busto e tagliata in segmenti lungo la linea
    busto = pezzi["busto"]
    coda = maschera_coda(busto)
    t, lunga = lungo_la_linea(CODA, *busto.shape[:2])
    b = PEZZI["busto"]
    segmenti = []
    tagli = [lunga * i / SEGMENTI for i in range(SEGMENTI)] + [np.inf]
    for i in range(SEGMENTI):
        da, a = tagli[i], tagli[i + 1]
        dentro = coda & (t >= max(0, da - (SOVRAPPOSTO if i else 0))) & (t < a)
        im = busto.copy()
        im[~dentro, 3] = 0
        perno = punto_a(CODA, da)
        dove = (b["dove"][0] + (perno[0] - b["perno"][0]) * b["scala"],
                b["dove"][1] + (perno[1] - b["perno"][1]) * b["scala"])
        segmenti.append(esporta(f"coda{i + 1}", im, b["scala"], perno, dove))
    busto = busto.copy()
    busto[coda, 3] = 0
    pezzi["busto"] = busto

    for nome, p in PEZZI.items():
        fatti[nome] = esporta(nome, pezzi[nome], p["scala"], p["perno"], p["dove"])

    def riga(nome, d):
        return (f"\t{nome} = {{ x = {d['x']:.2f}, y = {d['y']:.2f}, w = {d['w']:.2f}, h = {d['h']:.2f},"
                f" px = {d['px']:.2f}, py = {d['py']:.2f} }},")
    for nome, d in fatti.items():
        righe.append(riga(nome, d))
    righe.append("\tcoda = {")
    for i, d in enumerate(segmenti):
        righe.append("\t" + riga(f"[{i + 1}]", d))
    righe.append("\t},")
    with open(LUA, "w", encoding="utf-8") as f:
        f.write("-- Fatto da strumenti/grafica/scoria.py, non modificare a mano.\n"
                "-- Per ogni pezzo del diavoletto: centro (x, y) e misura (w, h) dell'immagine e\n"
                "-- perno (px, py) attorno a cui gira, in unità del disegno (corpo 150 x 200, y verso\n"
                "-- il basso, piedi a 200). La gamba ha il perno in (0, 0): la mette il codice sulle anche.\n"
                "-- La coda è una catena: ogni segmento gira attorno al proprio perno.\n"
                "return {\n" + "\n".join(righe) + "\n}\n")
    print("\n".join(righe))


main()
