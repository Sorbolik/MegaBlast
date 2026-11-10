# Disegna le poche forme dell'interfaccia (client/assets/ui/), bianche: il colore
# lo mette il codice (client/ui/ui.lua). Niente immagini generate.
#   forma.png  rettangolo arrotondato pieno (9-slice, bordo 16)
#   bordo.png  solo il contorno dello stesso rettangolo, spesso 3 px (9-slice, bordo 16)
#   alone.png  alone morbido rotondo, da disegnare in additivo (il bagliore del Nucleo)
#   stella.png stella a cinque punte, piena (le stelle delle lezioni e della campagna)
#   ingranaggio.png  la rotellina delle impostazioni in partita
# e le sagome di ogni famiglia di comandi (stile "Sagoma tattica", rapporto
# UI-002 di Antigravity), forma piena e solo contorno:
#   eroe_*      il pulsante principale (GIOCA, AVANTI): smussi a 45 gradi in
#               alto a destra e in basso a sinistra (9-slice, bordo 16)
#   slot_arma_* le armi della barra: smussi in alto, sotto arrotondato (9-slice, bordo 16)
#   badge_*     la pillola dei colpi rimasti sullo slot (9-slice, bordo 12)
#   gettone_*   teletrasporto, Rampino e baratto: ottagono (intero, non 9-slice)
#   oggetto_*   paracadute, trappola, scudo, molla: esagono (intero)
# Le forme 9-slice sono a densita' 1 (un pixel dell'immagine per pixel del
# gioco nei bordi): in Defold il 9-slice usa gli stessi numeri per l'immagine e
# per il nodo, quindi un'immagine piu' grande non rende i bordi piu' fini.
# Ottagono ed esagono si scalano interi: sono a 128 px, nitidi anche a 1440p.
# python3 tools/grafica/ui.py
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
# px perché si disegna anche grande (la fine della lezione), 48 per le stelline
# delle carte (stella_p: senza mipmap la grande rimpicciolita fa gli scalini)
for n, nome in ((128, "stella.png"), (48, "stella_p.png")):
    x, y = griglia(n)
    r = np.hypot(x, y)
    ang = (np.arctan2(x, y) + np.pi / 5) % (2 * np.pi / 5) - np.pi / 5  # 0 sulla punta
    R, RI = n / 2 - 2 * n / 128, (n / 2 - 2 * n / 128) * 0.45
    # ogni spicchio: dentro se sta dalla parte del centro rispetto al lato che va
    # dalla punta (R, 0) al vertice interno
    px, py = r * np.cos(ang), np.abs(r * np.sin(ang))
    ax, ay = RI * np.cos(np.pi / 5), RI * np.sin(np.pi / 5)
    salva(((ax - R) * py - ay * (px - R) >= 0).astype(float), n, nome)

# ingranaggio: otto denti e il foro al centro
n = 64
x, y = griglia(n)
r = np.hypot(x, y)
dente = np.cos(np.arctan2(y, x) * 8) > 0.15
pieno = ((r <= n / 2 - 1.5) & dente) | (r <= n / 2 - 9)
salva((pieno & (r >= 8.5)).astype(float), n, "ingranaggio.png")

# lucchetto: corpo arrotondato, archetto e toppa trasparente (missioni e capitoli bloccati)
for n, coda in ((128, ""), (48, "_p")):
    x, y = griglia(n)
    s = n / 128.0
    w_corpo, y_bot, y_top, r_corpo = 34 * s, -52 * s, 4 * s, 10 * s
    dx = np.maximum(np.abs(x) - (w_corpo - r_corpo), 0)
    h_corpo, y_c = (y_top - y_bot) / 2, (y_top + y_bot) / 2
    dy = np.maximum(np.abs(y - y_c) - (h_corpo - r_corpo), 0)
    corpo = (np.hypot(dx, dy) - r_corpo) <= 0
    r_ext, r_int = 26 * s, 16 * s
    r_shackle = np.hypot(x, y - 4 * s)
    arco_sup = (y >= 4 * s) & (r_shackle <= r_ext) & (r_shackle >= r_int)
    gambe = (y < 4 * s) & (y >= -8 * s) & (np.abs(x) <= r_ext) & (np.abs(x) >= r_int)
    pieno = corpo | arco_sup | gambe
    y_toppa_c, r_toppa = -20 * s, 5.5 * s
    cerchio_toppa = np.hypot(x, y - y_toppa_c) <= r_toppa
    y_fess_top, y_fess_bot = -20 * s, -36 * s
    in_y_fess = (y >= y_fess_bot) & (y <= y_fess_top)
    t_fess = (y - y_fess_bot) / (y_fess_top - y_fess_bot + 1e-6)
    w_fess = (4.5 * (1 - t_fess) + 3.0 * t_fess) * s
    fessura = in_y_fess & (np.abs(x) <= w_fess)
    alfa = (pieno & (~(cerchio_toppa | fessura))).astype(float)
    salva(alfa, n, "lucchetto" + coda + ".png")


def coppia(d, n, linea, nome):
    # d: distanza con segno dal bordo (negativa dentro); forma piena e contorno
    salva((d <= -0.5).astype(float), n, nome + "_forma.png")
    salva(((d <= -0.5) & (d > -0.5 - linea)).astype(float), n, nome + "_bordo.png")


R2 = np.sqrt(2)
# pulsante principale: lo smusso sta tutto nell'angolo del 9-slice (16)
n = LATO
x, y = griglia(n)
h = n / 2
smusso = 13
d = np.maximum(np.maximum(np.abs(x), np.abs(y)) - h,
               np.maximum((x + y) / R2, (-x - y) / R2) - (2 * h - smusso) / R2)
coppia(d, n, LINEA, "eroe")
# slot delle armi: smussi in alto, angoli di sotto arrotondati
d = np.maximum(distanza_rettangolo(n, 9), np.maximum((x + y) / R2, (-x + y) / R2) - (2 * h - 11) / R2)
coppia(d, n, LINEA, "slot_arma")
# pillola della coda in testata: estremità a mezzo cerchio pieno (9-slice, bordo 24)
coppia(distanza_rettangolo(LATO, 24), LATO, LINEA, "pillola")
# pillola dei colpi: mezzo cerchio per lato
n = 24
coppia(distanza_rettangolo(n, 11), n, 2, "badge")
# gettone ottagonale e oggetto esagonale, interi: il contorno è spesso come
# i 3 px dei bottoni tondi di prima, alla misura in cui si disegnano (84 e 56)
n = 128
x, y = griglia(n)
r = n / 2 - 2
d = np.maximum(np.maximum(np.abs(x), np.abs(y)), (np.abs(x) + np.abs(y)) / R2) - r
coppia(d, n, 3 * n / 84, "gettone")
a = r * np.sqrt(3) / 2  # esagono con la punta in alto: lati dritti a destra e sinistra
d = np.maximum(np.abs(x), np.abs(x) / 2 + np.abs(y) * np.sqrt(3) / 2) - a
coppia(d, n, 3 * n / 56, "oggetto")


# Dischi e anelli sfumati per i nodi tondi (ui.disc, ui.ring in client/ui/ui.lua):
# un poligono senza antialiasing fa gli scalini, un'immagine sfumata no. Il bordo
# esterno sta a mezzo pixel dal margine, cosi' il poligono del nodo lo contiene
# tutto. Due misure: 256 px per i tondi grandi, 64 per quelli piccoli (sotto i 48
# px del gioco), perche' l'atlas dell'interfaccia non ha mipmap. Ogni anello ha
# lo spessore k volte il diametro (ANELLI, lo stesso elenco di ui.lua).
ANELLI = [0.014, 0.018, 0.023, 0.028, 0.034, 0.041, 0.05, 0.06, 0.071, 0.084,
          0.1, 0.12, 0.14, 0.165, 0.2, 0.25]
for n, coda in ((256, ""), (64, "_p")):
    x, y = griglia(n)
    r = np.hypot(x, y)
    R = n / 2 - 1
    salva((r <= R).astype(float), n, "disco" + coda + ".png")
    for k in ANELLI:
        salva(((r <= R) & (r > R - k * 2 * R)).astype(float), n, "anello_%03d%s.png" % (round(k * 1000), coda))
print("ok", OUT)
