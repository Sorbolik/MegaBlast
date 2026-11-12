# I pezzi e gli sfondi dell'interfaccia "Fucina contro Abisso" (client/ui/kit.lua),
# dai disegni di Codex (art/WB-022).
#   python3 tools/grafica/fucina.py
# Scrive:
#   client/assets/fucina/*.png          i pezzi senza il verde, per l'atlante fucina.
#       Un pezzo lungo (lingotto, piastre, scheggia, piastrina) e' in tre parti:
#       _sx e _dx interi, _cx la striscia in mezzo che il gioco allunga. Cosi' i
#       bordi non si deformano mai e restano al doppio della misura sullo schermo.
#       Il pannello e' in nove parti (angoli interi, lati allungati in un verso).
#   client/ui/pieces.lua                le misure di ogni pezzo (generato)
#   client/ui/fucina.atlas              l'atlante (generato)
# Servono numpy, scipy e Pillow.
import os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..", "..")
ART = os.path.join(RADICE, "art")
OUT = os.path.join(RADICE, "client", "assets", "fucina")


def senza_verde(percorso):
    a = np.array(Image.open(percorso).convert("RGB")).astype(float)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    m = np.maximum(r, b)
    ex = g - m
    alfa = 1 - np.clip((ex - 30) / 110, 0, 1)
    g2 = np.where(ex > 0, m, g)
    return np.dstack([r, g2, b, alfa * 255]).astype(np.uint8)


def pezzi(o, minimo=2000):
    lab, _ = ndi.label(ndi.binary_dilation(o[..., 3] > 40, iterations=3))
    res = []
    for i, sl in enumerate(ndi.find_objects(lab)):
        if (lab[sl] == i + 1).sum() < minimo:
            continue
        res.append((sl[0].start, sl[1].start, o[sl]))
    return res


def caldo(arr):
    a = arr.astype(float)
    lum = a[..., :3].mean(axis=2)
    tappe = [(0, (242, 100, 25)), (22, (242, 100, 25)), (38, (77, 33, 16)), (60, (92, 40, 18)), (110, (255, 183, 3)), (255, (255, 230, 150))]
    out = a.copy()
    for c in range(3):
        out[..., c] = np.interp(lum, [s[0] for s in tappe], [s[1][c] for s in tappe])
    return out.astype(np.uint8)


def alta(arr, h):
    im = Image.fromarray(arr, "RGBA")
    if im.size[1] > h:
        im = im.resize((round(im.size[0] * h / im.size[1]), h), Image.LANCZOS)
    return im


def salva(im, nome):
    im.save(os.path.join(OUT, nome + ".png"), optimize=True)


MISURE = {}


def intero(nome, arr, h):
    im = alta(arr, h)
    salva(im, nome)
    MISURE[nome] = (im.size[0], im.size[1])


def tre(nome, arr, h, capo=0.24):
    """Un pezzo lungo in tre parti: i due capi interi e la striscia in mezzo."""
    im = alta(arr, h)
    w = im.size[0]
    c = round(w * capo)
    salva(im.crop((0, 0, c, h)), nome + "_sx")
    salva(im.crop((w - c, 0, w, h)), nome + "_dx")
    # la striscia: 8 colonne nel punto piu' uniforme fra il 40% e il 60%
    a = np.asarray(im).astype(float)
    meglio, dove = None, w // 2
    for x in range(round(w * 0.4), round(w * 0.6)):
        v = np.abs(np.diff(a[:, x - 6:x + 6], axis=1)).sum()
        if meglio is None or v < meglio:
            meglio, dove = v, x
    col = im.crop((dove, 0, dove + 1, h)).resize((8, h), Image.NEAREST)
    salva(col, nome + "_cx")
    MISURE[nome] = (w, h, c)


def nove(nome, arr, lato, angolo=0.2):
    im = alta(arr, lato).resize((lato, lato), Image.LANCZOS)
    c = round(lato * angolo)
    xs = [(0, c), (c, lato - c), (lato - c, lato)]
    k = 1
    for (y0, y1) in xs:
        for (x0, x1) in xs:
            p = im.crop((x0, y0, x1, y1))
            if x1 - x0 > c:
                p = p.crop((p.size[0] // 2 - 4, 0, p.size[0] // 2 + 4, p.size[1])) if y1 - y0 == c else p
            if y1 - y0 > c:
                p = p.crop((0, p.size[1] // 2 - 4, p.size[0], p.size[1] // 2 + 4))
            salva(p, "%s_%d" % (nome, k))
            k += 1
    MISURE[nome] = (lato, lato, c)


def fai_pezzi():
    p = os.path.join(ART, "WB-022")
    tre("lingotto", pezzi(senza_verde(os.path.join(p, "pezzo_lingotto_1.png")))[0][2], 320, 0.2)
    tre("scheggia", pezzi(senza_verde(os.path.join(p, "pezzo_ghiaccio.png")))[0][2], 200, 0.2)
    nove("pannello", pezzi(senza_verde(os.path.join(p, "pezzo_pannello.png")))[0][2], 480)
    cs = sorted(pezzi(senza_verde(os.path.join(p, "pezzo_piastre.png"))), key=lambda t: t[0])
    for nome, t in zip(["piastra_freccia", "piastra_storta", "piastra_stendardo"], cs):
        tre(nome, t[2], 200)
    tre("piastra_calda", caldo(cs[1][2]), 200)
    tre("piastra_chiara", chiaro(cs[1][2]), 200)
    cs = pezzi(senza_verde(os.path.join(p, "pezzo_piccoli.png")), 800)
    ymid = np.mean([t[0] for t in cs])
    su = sorted([t for t in cs if t[0] < ymid], key=lambda t: t[1])
    giu = sorted([t for t in cs if t[0] >= ymid], key=lambda t: t[1])
    tre("piastrina", su[0][2], 120, 0.3)
    tre("piastrina_calda", caldo(su[0][2]), 120, 0.3)
    tre("piastrina_chiara", chiaro(su[0][2]), 120, 0.3)
    for nome, t in zip(["indietro", "brace", "fiamma"], su[1:]):
        intero(nome, t[2], 120)
    for nome, t in zip(["brace_spenta", "lucchetto", "scaglia", "gemma"], giu):
        intero(nome, t[2], 120)


def chiaro(arr):
    """La piastra chiara (il nome del giocatore, la scelta fatta): avorio, china fuori."""
    a = arr.astype(float)
    lum = a[..., :3].mean(axis=2)
    tappe = [(0, (10, 8, 11)), (22, (10, 8, 11)), (38, (201, 190, 174)), (60, (244, 236, 225)), (110, (255, 250, 240)), (255, (255, 255, 255))]
    out = a.copy()
    for c in range(3):
        out[..., c] = np.interp(lum, [s[0] for s in tappe], [s[1][c] for s in tappe])
    return out.astype(np.uint8)


def fai_filo():
    """Il filo: brace a sinistra, gelo a destra (il gioco lo allunga solo in largo)."""
    tappe = [(0, (242, 100, 25)), (0.3, (255, 183, 3)), (0.5, (255, 243, 176)), (0.7, (202, 240, 248)), (1, (56, 182, 255))]
    x = np.linspace(0, 1, 256)
    riga = np.stack([np.interp(x, [t[0] for t in tappe], [t[1][c] for t in tappe]) for c in range(3)], axis=1)
    im = np.zeros((4, 256, 4), np.uint8)
    im[..., :3] = riga[None, :, :]
    im[..., 3] = 255
    salva(Image.fromarray(im, "RGBA"), "filo")


def fai_atlante():
    nomi = sorted(f for f in os.listdir(OUT) if f.endswith(".png"))
    with open(os.path.join(RADICE, "client", "ui", "fucina.atlas"), "w") as f:
        for n in nomi:
            f.write('images {\n  image: "/assets/fucina/%s"\n}\n' % n)
        f.write("margin: 2\nextrude_borders: 2\ninner_padding: 0\n")


def fai_misure():
    with open(os.path.join(RADICE, "client", "ui", "pieces.lua"), "w") as f:
        f.write("-- Generated by tools/grafica/fucina.py: the size in pixels of every piece of the\n")
        f.write("-- fucina atlas (w, h and, for the pieces in three or nine parts, the cap c).\nreturn {\n")
        for k in sorted(MISURE):
            m = MISURE[k]
            f.write("\t%s = { w = %d, h = %d%s },\n" % (k, m[0], m[1], len(m) > 2 and ", c = %d" % m[2] or ""))
        f.write("}\n")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    fai_pezzi()
    fai_filo()
    fai_misure()
    fai_atlante()
    print("OK")
