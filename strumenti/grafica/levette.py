# Disegna le levette della battaglia nello stile del kit (cornice di ferro
# scuro con borchie d'oro, come slot.png), senza immagini generate:
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


def base(n=256):
    x, y = griglia(n)
    r = np.hypot(x, y)
    R = n / 2 - 3
    rgba = np.zeros(r.shape + (4,))
    # disco interno: scuro, trasparente, un po' più chiaro verso il bordo
    k = r / R
    rgba[..., :3] = (np.array([0.07, 0.065, 0.08]) + 0.06 * k[..., None] ** 3)
    rgba[..., 3] = 0.42 * liscio(r - (R - 14))
    # cornice di ferro: luce in alto a sinistra, ombra in basso a destra
    ring = liscio(np.abs(r - (R - 7)) - 7)
    luce = 0.5 + 0.5 * (-(x + y) / np.maximum(r, 1) * 0.7071)
    ferro = np.array([0.20, 0.17, 0.20]) + np.array([0.20, 0.17, 0.21]) * luce[..., None]
    filo = liscio(np.abs(r - (R - 1)) - 1.2) + liscio(np.abs(r - (R - 13)) - 1.0)
    ferro = ferro * (1 - 0.6 * np.clip(filo, 0, 1)[..., None])
    rgba[..., :3] = rgba[..., :3] * (1 - ring[..., None]) + ferro * ring[..., None]
    rgba[..., 3] = np.maximum(rgba[..., 3], ring)
    # quattro borchie d'oro sulla cornice, in diagonale come negli slot
    for ang in (45, 135, 225, 315):
        cx, cy = (R - 7) * np.cos(np.radians(ang)), (R - 7) * np.sin(np.radians(ang))
        d = np.hypot(x - cx, y - cy)
        b = liscio(d - 5.5)
        hl = np.clip(1 - np.hypot(x - cx + 1.8, y - cy + 1.8) / 4, 0, 1)
        oro = np.array([0.55, 0.40, 0.16]) + np.array([0.45, 0.42, 0.30]) * hl[..., None]
        rgba[..., :3] = rgba[..., :3] * (1 - b[..., None]) + oro * b[..., None]
        rgba[..., 3] = np.maximum(rgba[..., 3], b)
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
    x, y = griglia(n)
    r = np.hypot(x, y)
    R = n / 2 - 4
    rgba = np.zeros(r.shape + (4,))
    # sfera scura con riflesso in alto a sinistra
    z = np.sqrt(np.clip(1 - (r / R) ** 2, 0, 1))
    nx, ny = x / R, y / R
    lam = np.clip(-0.45 * nx - 0.45 * ny + 0.77 * z, 0, 1)
    spec = np.clip(-0.45 * nx - 0.45 * ny + 0.77 * z, 0, 1) ** 24
    col = np.array([0.10, 0.09, 0.11]) + np.array([0.22, 0.19, 0.24]) * lam[..., None] + 0.55 * spec[..., None]
    corpo = liscio(r - R)
    # cornice d'oro sottile
    oro_m = liscio(np.abs(r - (R - 3)) - 2.5)
    luce = 0.5 + 0.5 * (-(x + y) / np.maximum(r, 1) * 0.7071)
    oro = np.array([0.45, 0.32, 0.12]) + np.array([0.5, 0.45, 0.3]) * luce[..., None]
    col = col * (1 - oro_m[..., None]) + oro * oro_m[..., None]
    # ombra morbida sotto
    ombra = np.clip(1 - np.hypot(x - 3, y - 4) / (R + 3), 0, 1) ** 0.6 * 0.5
    rgba[..., :3] = col
    rgba[..., 3] = np.maximum(corpo, ombra * (1 - corpo))
    rgba[..., :3] *= (corpo + (1 - corpo) * 0)[..., None]
    salva(rgba, n, "levetta_pomello")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    base()
    anello()
    pomello()
