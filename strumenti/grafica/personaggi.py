# I personaggi nuovi di Gabriella (Brace, Ombra, Zolfo), interi come li ha
# disegnati, per la prova della designer: un'immagine ferma ciascuno, che il
# gioco muove copiando i movimenti dei fotogrammi del diavoletto.
#   client/assets/personaggi/<nome>.png    a 1 pixel per unità
#   client/battaglia/personaggi.lua        misura, centro dall'appoggio e fiammella
# I disegni sono tutti sulla stessa tela 1254 con la stessa scala del diavoletto
# (base_pezzi_1024 ingrandita), quindi una scala sola per tutti.
# python3 strumenti/grafica/personaggi.py
import os
import numpy as np
from PIL import Image
from scipy import ndimage as nd

QUI = os.path.dirname(os.path.abspath(__file__))

DIS = "/mnt/project-files/gabriella/disegni/2026-10-25_nuovi_diavoletti"
OUT = os.path.join(QUI, "..", "..", "client", "assets", "personaggi")
LUA = os.path.join(QUI, "..", "..", "client", "battaglia", "personaggi.lua")
NOMI = {"brace": "brace_v2.png", "ombra": "ombra_v1.png", "zolfo": "zolfo_v2.png"}
# unità per pixel: come la base (200 unità dalla cima della testa ai piedi = 701 px su 1024)
S = 200 / (941 - 240) * 1024 / 1254
MARGINE = 2


def chiave(p):
    """Toglie il fondo magenta (come fotogrammi.py)."""
    a = np.asarray(Image.open(p).convert("RGB")).astype(float)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    al = 1 - np.clip(((r + b) / 2 - g - 90) / 80, 0, 1)
    am = np.maximum(al, 1e-3)[..., None]
    rgb = np.clip((a - (1 - am) * np.array([255, 0, 255])) / am, 0, 255)
    return rgb, al


def main():
    os.makedirs(OUT, exist_ok=True)
    righe = []
    for nome, file in NOMI.items():
        rgb, al = chiave(os.path.join(DIS, file))
        m = al > 0.5
        l, n = nd.label(nd.binary_dilation(m, iterations=6))
        sz = nd.sum(m, l, range(1, n + 1))
        m = nd.binary_dilation(l == 1 + int(np.argmax(sz)), iterations=2) & (al > 0.02)
        ys, xs = np.nonzero(m)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        # appoggio: sotto i piedi, in x al centro delle gambe (ultimo quarto)
        gy, gx = np.nonzero(m[y1 - (y1 - y0) // 4:y1])
        ax = (gx.min() + gx.max()) / 2
        img = np.dstack([rgb, np.where(m, al, 0) * 255])[y0:y1, x0:x1].astype(np.uint8)
        w, h = round((x1 - x0) * S), round((y1 - y0) * S)
        im = Image.fromarray(img, "RGBA").resize((w, h), Image.LANCZOS)
        tela = Image.new("RGBA", (w + 2 * MARGINE, h + 2 * MARGINE))
        tela.paste(im, (MARGINE, MARGINE))
        tela.save(os.path.join(OUT, nome + ".png"))
        cx = ((x0 + x1) / 2 - ax) * S
        cy = (y1 - (y0 + y1) / 2) * S
        # la fiammella (o quello che ha in testa): in cima, al centro della parte alta
        ty, tx = np.nonzero(m[y0:y0 + (y1 - y0) // 10])
        fx, fy = (tx.mean() + x0 - ax) * S, (y1 - y0 - ty.mean()) * S - 10
        righe.append('\t%s = { img = "%s", w = %d, h = %d, x = %.1f, y = %.1f, fx = %.1f, fy = %.1f },' % (
            nome, nome, tela.width, tela.height, cx, cy, fx, fy))
        print(nome, tela.size, round(cx, 1), round(cy, 1))
    with open(LUA, "w") as f:
        f.write("-- Generato da strumenti/grafica/personaggi.py: non modificare a mano.\n")
        f.write("-- Misura e centro (unità, dall'appoggio, y in su) dei personaggi interi.\n")
        f.write("return {\n" + "\n".join(righe) + "\n}\n")


if __name__ == "__main__":
    main()
