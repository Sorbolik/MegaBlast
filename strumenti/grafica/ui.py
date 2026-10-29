# Disegna le poche forme dell'interfaccia (client/assets/ui/), bianche: il colore
# lo mette il codice (client/ui/ui.lua). Niente immagini generate.
#   forma.png  rettangolo arrotondato pieno (9-slice, bordo 16)
#   bordo.png  solo il contorno dello stesso rettangolo, spesso 3 px (9-slice, bordo 16)
#   alone.png  alone morbido rotondo, da disegnare in additivo (il bagliore del Nucleo)
#   stella.png stella a cinque punte, piena (le stelle delle lezioni e della campagna)
#   ingranaggio.png  la rotellina delle impostazioni in partita
# python3 strumenti/grafica/ui.py
import os
import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "client", "assets", "ui")
SS = 4  # sovracampionamento per bordi lisci
LATO, RAGGIO, LINEA = 48, 14, 3


def distanza_rettangolo(n, r):
    # distanza con segno dal bordo di un rettangolo n x n con angoli di raggio r
    c = (n * SS - 1) / 2
    yy, xx = np.mgrid[0:n * SS, 0:n * SS]
    x, y = np.abs(xx - c) / SS, np.abs(yy - c) / SS
    qx, qy = x - (n / 2 - r), y - (n / 2 - r)
    fuori = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0))
    return fuori + np.minimum(np.maximum(qx, qy), 0) - r


def salva(alfa, n, nome):
    a = alfa.reshape(n, SS, n, SS).mean(axis=(1, 3))
    im = np.zeros((n, n, 4), np.uint8)
    im[..., :3] = 255
    im[..., 3] = np.round(np.clip(a, 0, 1) * 255)
    Image.fromarray(im).save(os.path.join(OUT, nome), optimize=True)


os.makedirs(OUT, exist_ok=True)
d = distanza_rettangolo(LATO, RAGGIO)
salva((d <= -0.5).astype(float), LATO, "forma.png")
salva(((d <= -0.5) & (d > -0.5 - LINEA)).astype(float), LATO, "bordo.png")
n = 64
yy, xx = np.mgrid[0:n * SS, 0:n * SS]
r = np.hypot(xx - (n * SS - 1) / 2, yy - (n * SS - 1) / 2) / (n * SS / 2)
salva(np.clip(1 - r, 0, 1) ** 2, n, "alone.png")



def griglia(n):
    # coordinate dal centro, in pixel, con la y in alto
    c = (n * SS - 1) / 2
    yy, xx = np.mgrid[0:n * SS, 0:n * SS]
    return (xx - c) / SS, (c - yy) / SS


# stella a cinque punte (raggio interno 0,45 dell'esterno), la punta in alto; 128
# px perché si disegna anche grande (la fine della lezione)
n = 128
x, y = griglia(n)
r = np.hypot(x, y)
ang = (np.arctan2(x, y) + np.pi / 5) % (2 * np.pi / 5) - np.pi / 5  # 0 sulla punta
R, RI = n / 2 - 2, (n / 2 - 2) * 0.45
# ogni spicchio: dentro se sta dalla parte del centro rispetto al lato che va
# dalla punta (R, 0) al vertice interno
px, py = r * np.cos(ang), np.abs(r * np.sin(ang))
ax, ay = RI * np.cos(np.pi / 5), RI * np.sin(np.pi / 5)
salva(((ax - R) * py - ay * (px - R) >= 0).astype(float), n, "stella.png")

# ingranaggio: otto denti e il foro al centro
n = 64
x, y = griglia(n)
r = np.hypot(x, y)
dente = np.cos(np.arctan2(y, x) * 8) > 0.15
pieno = ((r <= n / 2 - 1.5) & dente) | (r <= n / 2 - 9)
salva((pieno & (r >= 8.5)).astype(float), n, "ingranaggio.png")
print("ok", OUT)
