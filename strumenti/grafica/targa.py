# La targa sopra i personaggi nello stile C della scheda WB-011 ("lama incisa",
# scelta di Sergio del 3 nov, con la sua Corona). Taglia dal foglio di ChatGPT
# (art/WB-011/c_lama_foglio.png, sfondo magenta):
#   targa_lama.png    la lama d'acciaio con la scanalatura scura, accorciata: il
#                     manico, un pezzetto di mezzo pulito e la punta. Il gioco la
#                     allunga solo nel mezzo (slice9), così niente si deforma
#   targa_corona.png  la Corona d'oro del primo in classifica
#   targa_bianco.png  un quadratino bianco: la vita nella scanalatura (tinta col
#                     colore della squadra), la scia e il fondo delle battute, così
#                     tutta la targa sta in una draw call con la lama e la Corona
# Il gioco (client/battaglia/targa.lua) usa le misure che questo script stampa.
# Scrive client/assets/fx/targa_*.png (vanno in battaglia.atlas).
#
# python3 strumenti/grafica/targa.py
import os

import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..", "..")
FOGLIO = os.path.join(RADICE, "art", "WB-011", "c_lama_foglio.png")
OUT = os.path.join(RADICE, "client", "assets", "fx")

# la lama nel foglio (pixel): dal contorno a sinistra alla punta, dal bordo alto al basso
LAMA = (35, 174, 1504, 254)
# i tre pezzi: il manico con l'inizio della scanalatura, un pezzetto di mezzo senza
# graffi (si allunga), la punta con i suoi graffi
MANICO, MEZZO, PUNTA = (35, 140), (600, 608), (1300, 1504)
# la scanalatura dritta, dove scorre la vita: da x a x, da y a y (copre quasi tutto
# il suo contorno nero, ne resta un filo sopra e sotto)
SCANALATURA = (110, 199, 1392, 222)
CORONA = (432, 538, 1102, 907)

ALTA = 9.0          # la lama è alta 9 unità della targa
PX = 4              # pixel per unità nell'immagine (sullo schermo ne servono circa 1,6)
CORONA_W, CORONA_PX = 13.5, 8


# il colore senza il magenta (il foglio non è #FF00FF pieno) e quanto è coperto
def ritaglia(im):
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    alfa = 1 - np.clip((np.minimum(r, b) - g - 60) / 120, 0, 1)
    bg = np.array([253.0, 4.0, 251.0])
    rgb = np.clip((im - (1 - alfa)[..., None] * bg) / np.maximum(alfa, 1e-3)[..., None], 0, 255)
    alfa[alfa < 0.04] = 0
    rgb[alfa == 0] = 0
    return np.dstack([rgb, alfa * 255]).clip(0, 255).astype(np.uint8)


def salva(nome, px, w, h):
    im = np.array(Image.fromarray(px, "RGBA").resize((w, h), Image.LANCZOS))
    im[im[..., 3] < 8] = 0  # niente velo quasi trasparente attorno
    Image.fromarray(im, "RGBA").save(os.path.join(OUT, nome + ".png"))
    print("scritto", nome, w, "x", h)


def main():
    foglio = np.asarray(Image.open(FOGLIO).convert("RGB")).astype(float)
    os.makedirs(OUT, exist_ok=True)

    x0, y0, x1, y1 = LAMA
    lama = ritaglia(foglio[y0:y1, :])
    pezzi = [lama[:, a:b] for a, b in (MANICO, MEZZO, PUNTA)]
    k = ALTA * PX / (y1 - y0)  # da pixel del foglio a pixel dell'immagine
    u = ALTA / (y1 - y0)       # da pixel del foglio a unità della targa
    salva("targa_lama", np.hstack(pezzi), round(sum(p.shape[1] for p in pezzi) * k), round(ALTA * PX))

    cx0, cy0, cx1, cy1 = CORONA
    corona = ritaglia(foglio[cy0:cy1, cx0:cx1])
    cw = round(CORONA_W * CORONA_PX)
    salva("targa_corona", corona, cw, round(cw * (cy1 - cy0) / (cx1 - cx0)))

    Image.new("RGBA", (8, 8), (255, 255, 255, 255)).save(os.path.join(OUT, "targa_bianco.png"))
    print("scritto targa_bianco 8 x 8")

    sx0, sy0, sx1, sy1 = SCANALATURA
    print("\nmisure per client/battaglia/targa.lua (unità della targa):")
    print("LAMA_H =", ALTA, " LAMA_PX =", PX)
    print("LAMA_BORDI (px dell'immagine, sinistra e destra) =",
          round((MANICO[1] - MANICO[0]) * k), round((PUNTA[1] - PUNTA[0]) * k))
    print("PRIMA (dal bordo sinistro della lama alla vita) = %.2f" % ((sx0 - x0) * u))
    print("DOPO (dalla fine della vita alla punta) = %.2f" % ((x1 - sx1) * u))
    print("H (alta la vita) = %.2f" % ((sy1 - sy0) * u))
    print("SU (centro della vita sopra il centro della lama) = %.2f" % (((y0 + y1) / 2 - (sy0 + sy1) / 2) * u))


if __name__ == "__main__":
    main()
