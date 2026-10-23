# Disegna le levette della battaglia nello stile dell'interfaccia (client/ui/ui.lua:
# carbone col bordo chiaro, come la Scoria), senza immagini generate:
#   client/assets/ui/levette/levetta_base.png    disco scuro con cornice
#   client/assets/ui/levette/levetta_anello.png  anello bianco sfumato (additivo, si tinge dal codice)
#   client/assets/ui/levette/levetta_pomello.png pomello
# python3 strumenti/grafica/levette.py
import os
import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "client", "assets", "ui", "levette")
SS = 4  # sovracampionamento per bordi lisci


def griglia(n):
    c = (n * SS - 1) / 2
    yy, xx = np.mgrid[0:n * SS, 0:n * SS]
    return (xx - c) / SS, (yy - c) / SS


def salva(rgba, n, nome):
    a = np.clip(rgba, 0, 1)
    im = Image.fromarray((a * 255).astype(np.uint8), "RGBA").resize((n, n), Image.LANCZOS)
    im.save(os.path.join(OUT, nome + ".png"), optimize=True)


def liscio(d, w=0.75):
    return np.clip(0.5 - d / w, 0, 1)


LUCE = np.array([1, 0.886, 0.769])      # il contorno chiaro della Scoria
CARBONE = np.array([0.078, 0.071, 0.094])


def base(n=256):
    x, y = griglia(n)
    r = np.hypot(x, y)
    R = n / 2 - 3
    rgba = np.zeros(r.shape + (4,))
    # disco di carbone velato e un filo chiaro sul bordo
    rgba[..., :3] = CARBONE
    rgba[..., 3] = 0.45 * liscio(r - (R - 2))
    filo = liscio(np.abs(r - (R - 2)) - 1.5)
    rgba[..., :3] = rgba[..., :3] * (1 - filo[..., None]) + LUCE * filo[..., None]
    rgba[..., 3] = np.maximum(rgba[..., 3], 0.4 * filo)
    salva(rgba, n, "levetta_base")


def anello(n=256):
    x, y = griglia(n)
    r = np.hypot(x, y)
    R = n / 2 - 3
    a = np.exp(-((r - (R - 16)) / 6) ** 2) * 0.9 + np.exp(-((r - (R - 16)) / 2) ** 2) * 0.6
    rgba = np.ones(r.shape + (4,))
    rgba[..., 3] = np.clip(a, 0, 1)
    salva(rgba, n, "levetta_anello")


def pomello(n=128):
    # come una mano della Scoria: un cerchio di carbone col bordo chiaro
    x, y = griglia(n)
    r = np.hypot(x, y)
    R = n / 2 - 4
    rgba = np.zeros(r.shape + (4,))
    bordo = liscio(np.abs(r - (R - 4)) - 4)
    rgba[..., :3] = CARBONE * (1 - bordo[..., None]) + LUCE * bordo[..., None]
    rgba[..., 3] = liscio(r - R)
    salva(rgba, n, "levetta_pomello")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    base()
    anello()
    pomello()
