# I pezzi della targa sopra i personaggi (client/battle/plate.lua). Dal foglio di
# ChatGPT dello stile C della scheda WB-011 (art/WB-011/c_lama_foglio.png, sfondo
# magenta) taglia la Corona d'oro; la lama dello stesso foglio non si usa più
# (Sergio, 3 nov: la vita è una riga piena, più leggibile). Scrive in client/assets/fx/:
#   targa_corona.png  la Corona d'oro del primo (accanto al nome e sopra i punti)
#   targa_bianco.png  un quadratino bianco: la vita, i fondi e la punta a V, tinti
#                     dal gioco, così tutta la targa sta in una draw call con la Corona
# (vanno in battle.atlas).
#
# python3 tools/grafica/targa.py
import os

import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..", "..")
FOGLIO = os.path.join(RADICE, "art", "WB-011", "c_lama_foglio.png")
OUT = os.path.join(RADICE, "client", "assets", "fx")

CORONA = (432, 538, 1102, 907)  # la Corona nel foglio (pixel)
CORONA_W, CORONA_PX = 13.5, 8   # larga 13,5 unità della targa, 8 pixel per unità


# il colore senza il magenta (il foglio non è #FF00FF pieno) e quanto è coperto
def ritaglia(im):
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    alfa = 1 - np.clip((np.minimum(r, b) - g - 60) / 120, 0, 1)
    bg = np.array([253.0, 4.0, 251.0])
    rgb = np.clip((im - (1 - alfa)[..., None] * bg) / np.maximum(alfa, 1e-3)[..., None], 0, 255)
    alfa[alfa < 0.04] = 0
    rgb[alfa == 0] = 0
    return np.dstack([rgb, alfa * 255]).clip(0, 255).astype(np.uint8)


def main():
    foglio = np.asarray(Image.open(FOGLIO).convert("RGB")).astype(float)
    os.makedirs(OUT, exist_ok=True)

    x0, y0, x1, y1 = CORONA
    w = round(CORONA_W * CORONA_PX)
    h = round(w * (y1 - y0) / (x1 - x0))
    im = np.array(Image.fromarray(ritaglia(foglio[y0:y1, x0:x1]), "RGBA").resize((w, h), Image.LANCZOS))
    im[im[..., 3] < 8] = 0  # niente velo quasi trasparente attorno
    Image.fromarray(im, "RGBA").save(os.path.join(OUT, "targa_corona.png"))
    print("scritto targa_corona", w, "x", h)

    Image.new("RGBA", (8, 8), (255, 255, 255, 255)).save(os.path.join(OUT, "targa_bianco.png"))
    print("scritto targa_bianco 8 x 8")


if __name__ == "__main__":
    main()
