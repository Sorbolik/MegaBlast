# Disegna i pezzi della Scoria (fase 4 della roadmap, sagoma "Corona del Titano
# con le gambe") dai tracciati della pagina delle sagome:
#   client/assets/scoria/<pezzo>.png         sagoma bianca, il colore lo dà il codice
#   client/assets/scoria/<pezzo>_bordo.png   la stessa sagoma allargata, per il bordo chiaro
#   client/battaglia/scoria_pezzi.lua        centro e misura di ogni pezzo
# Unità del disegno: la capsula del corpo va da x 0 a 150 e da y 0 a 200 (y verso
# il basso, piedi a 200), come nella pagina. Le due immagini di un pezzo hanno la
# stessa tela, così i due nodi si sovrappongono esattamente.
# python3 strumenti/grafica/scoria.py
import os
import re
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd

QUI = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(QUI, "..", "..", "client", "assets", "scoria")
LUA = os.path.join(QUI, "..", "..", "client", "battaglia", "scoria_pezzi.lua")
RES = 1.5   # pixel dell'immagine per unità del disegno
SS = 4      # sovracampionamento per bordi lisci
BORDO = 6   # spessore del bordo chiaro, in unità del disegno

PEZZI = {
    # testa tonda con tre corna: le due esterne lunghe, quella centrale corta
    "testa": "M78 8 C110 8 132 32 132 60 C132 88 110 108 78 108 C46 108 24 88 24 60 C24 32 46 8 78 8 Z "
             "M38 32 L28 -38 L62 14 Z M68 12 L78 -10 L88 12 Z M94 14 L128 -38 L118 32 Z",
    # mantello strappato, corto quanto basta per far uscire le gambe
    "mantello": "M32 105 C26 135 22 160 18 182 L36 172 L54 185 L75 173 L96 185 L114 172 L132 182 "
                "C128 160 124 135 118 105 Z",
    # una gamba (servono due nodi con la stessa immagine): il fondo è arrotondato
    "gamba": "M48 170 L63 170 L63 196 C63 200 60 202 57 202 L54 202 C51 202 48 200 48 196 Z",
}


def punti(d):
    """Sottotracciati del path (solo M, L, C, Z assoluti) come liste di punti."""
    t = re.findall(r"[MLCZ]|-?\d+(?:\.\d+)?", d)
    forme, cur, i, p = [], [], 0, (0, 0)
    while i < len(t):
        c = t[i]
        if c == "M":
            if cur:
                forme.append(cur)
            p = (float(t[i + 1]), float(t[i + 2]))
            cur, i = [p], i + 3
        elif c == "L":
            p = (float(t[i + 1]), float(t[i + 2]))
            cur.append(p)
            i += 3
        elif c == "C":
            a, b, e = [(float(t[i + j]), float(t[i + j + 1])) for j in (1, 3, 5)]
            for s in np.linspace(0, 1, 24)[1:]:
                u = 1 - s
                cur.append(tuple(u ** 3 * np.array(p) + 3 * u * u * s * np.array(a)
                                 + 3 * u * s * s * np.array(b) + s ** 3 * np.array(e)))
            p, i = e, i + 7
        else:  # Z
            i += 1
    if cur:
        forme.append(cur)
    return forme


def disegna(nome, d):
    forme = punti(d)
    tutti = np.array([q for f in forme for q in f])
    x0, y0 = tutti.min(0) - BORDO - 2
    x1, y1 = tutti.max(0) + BORDO + 2
    w, h = int(np.ceil((x1 - x0) * RES)), int(np.ceil((y1 - y0) * RES))
    im = Image.new("L", (w * SS, h * SS), 0)
    g = ImageDraw.Draw(im)
    for f in forme:
        g.polygon([((x - x0) * RES * SS, (y - y0) * RES * SS) for x, y in f], fill=255)
    pieno = np.asarray(im) > 127
    # il bordo: la sagoma allargata di BORDO unità
    dist = nd.distance_transform_edt(~pieno)
    largo = dist <= BORDO * RES * SS
    for suffisso, m in (("", pieno), ("_bordo", largo)):
        a = Image.fromarray((m * 255).astype(np.uint8)).resize((w, h), Image.LANCZOS)
        rgba = Image.merge("RGBA", (Image.new("L", (w, h), 255),) * 3 + (a,))
        rgba.save(os.path.join(OUT, nome + suffisso + ".png"), optimize=True)
    # centro e misura della tela, in unità del disegno
    return (x0 + w / RES / 2, y0 + h / RES / 2, w / RES, h / RES)


def main():
    os.makedirs(OUT, exist_ok=True)
    righe = []
    for nome, d in PEZZI.items():
        cx, cy, w, h = disegna(nome, d)
        righe.append(f"\t{nome} = {{ x = {cx:.2f}, y = {cy:.2f}, w = {w:.2f}, h = {h:.2f} }},")
    with open(LUA, "w", encoding="utf-8") as f:
        f.write("-- Fatto da strumenti/grafica/scoria.py, non modificare a mano.\n"
                "-- Per ogni pezzo della Scoria: centro (x, y) e misura (w, h) dell'immagine,\n"
                "-- in unità del disegno (corpo 150 x 200, y verso il basso, piedi a 200).\n"
                "return {\n" + "\n".join(righe) + "\n}\n")
    print("\n".join(righe))


main()
