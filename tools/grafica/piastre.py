# Le forme delle piastre dell'interfaccia "Raggi" (client/ui/kit.lua), bianche:
# il colore lo mette il codice. Una piastra e' un parallelogramma dritto: un
# rettangolo in mezzo e due tagli (triangoli rettangoli) ai lati, che si
# allargano e si alzano quanto serve restando triangoli.
#   taglio_sx.png        triangolo con l'angolo retto in basso a destra (il lato sinistro)
#   taglio_dx.png        triangolo con l'angolo retto in alto a sinistra (il lato destro)
#   taglio_*_sfuma.png   gli stessi, pieni in alto e trasparenti in basso
#   sfuma.png            striscia piena in alto e trasparente in basso (la sfumatura delle piastre)
# python3 tools/grafica/piastre.py
import os
import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "client", "assets", "ui")
N, SS = 128, 4


def salva(alfa, nome):
    h, w = alfa.shape[0] // SS, alfa.shape[1] // SS
    a = alfa.reshape(h, SS, w, SS).mean(axis=(1, 3))
    im = np.zeros((h, w, 4), np.uint8)
    im[..., :3] = 255
    im[..., 3] = np.round(np.clip(a, 0, 1) * 255)
    Image.fromarray(im).save(os.path.join(OUT, nome), optimize=True)


yy, xx = np.mgrid[0:N * SS, 0:N * SS]
x, y = (xx + 0.5) / (N * SS), (yy + 0.5) / (N * SS)   # y dall'alto
sx = (x + y >= 1).astype(float)
dx = (x + y <= 1).astype(float)
giu = 1 - y
salva(sx, "taglio_sx.png")
salva(dx, "taglio_dx.png")
salva(sx * giu, "taglio_sx_sfuma.png")
salva(dx * giu, "taglio_dx_sfuma.png")
salva(np.repeat(giu[:, :8 * SS], 1, axis=1), "sfuma.png")
