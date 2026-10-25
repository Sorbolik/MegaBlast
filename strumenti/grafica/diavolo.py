# Prepara il braccio del diavoletto di Gabriella per il gioco:
#   client/assets/diavolo/<pezzo>.png    il pezzo ritagliato, a RES pixel per unità
#   client/battaglia/scoria_pezzi.lua    centro e misura del pezzo, e i perni
# I pezzi d'origine sono i nove PNG 1024 x 1024 della cartella di Gabriella
# (disegni/2026-10-25_pezzi/1024/): stessa tela, già sovrapposti come livelli,
# sfondo trasparente.
# Unità del disegno come la vecchia Scoria: il corpo va da x 0 a 150 e da y 0
# a 200 (y verso il basso, piedi a 200); la cima della testa (senza corna) sta a 0.
# python3 strumenti/grafica/diavolo.py [cartella dei pezzi]
import os
import sys
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
SORGENTE = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/gabriella/disegni/2026-10-25_pezzi/1024"
OUT = os.path.join(QUI, "..", "..", "client", "assets", "diavolo")
LUA = os.path.join(QUI, "..", "..", "client", "battaglia", "scoria_pezzi.lua")
RES = 2       # pixel dell'immagine per unità del disegno
MARGINE = 2   # pixel trasparenti attorno a ogni pezzo

# dalla tela 1024 alle unità: piedi a y 941, cima della testa a y 240, centro a x 595
PIEDI, CIMA, CENTRO = 941, 240, 595
S = 200 / (PIEDI - CIMA)

# del personaggio a pezzi resta il braccio davanti, che tiene l'arma e gira con
# la mira sopra i fotogrammi (strumenti/grafica/fotogrammi.py)
PEZZI = ["braccio_davanti"]

# i perni, in pixel della tela 1024: dove ogni pezzo gira
PERNI = {
    "spalla": (530, 545),
    "mano": (522, 725),         # dove il braccio tiene l'arma
}


def u(x):
    return (x - CENTRO) * S + 75


def v(y):
    return (y - PIEDI) * S + 200


def main():
    os.makedirs(OUT, exist_ok=True)
    righe = []
    for nome in PEZZI:
        im = Image.open(os.path.join(SORGENTE, nome + ".png")).convert("RGBA")
        x0, y0, x1, y1 = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
        k = RES * S
        w, h = round((x1 - x0) * k) + 2 * MARGINE, round((y1 - y0) * k) + 2 * MARGINE
        # la tela ritagliata, allargata del margine, ridotta alla misura del gioco
        m = MARGINE / k
        box = (x0 - m, y0 - m, x1 + m, y1 + m)
        pezzo = im.resize((w, h), Image.LANCZOS, box=box)
        pezzo.save(os.path.join(OUT, nome + ".png"), optimize=True)
        cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
        righe.append("\t%s = { x = %.2f, y = %.2f, w = %.2f, h = %.2f }," % (nome, u(cx), v(cy), w / RES, h / RES))
    perni = ["\t\t%s = { %.2f, %.2f }," % (n, u(x), v(y)) for n, (x, y) in PERNI.items()]
    with open(LUA, "w") as f:
        f.write("-- Fatto da strumenti/grafica/diavolo.py, non modificare a mano.\n"
                "-- Per ogni pezzo del diavoletto: centro (x, y) e misura (w, h) dell'immagine,\n"
                "-- e i perni attorno a cui girano, in unità del disegno (corpo 150 x 200,\n"
                "-- y verso il basso, piedi a 200).\n"
                "return {\n" + "\n".join(righe) + "\n\tperni = {\n" + "\n".join(perni) + "\n\t},\n}\n")


main()
