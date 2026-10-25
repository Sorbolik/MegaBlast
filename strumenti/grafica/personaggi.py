# I quattro diavoletti di Gabriella in pixel art (ChatGPT), interi, per la
# prova della designer: un'immagine ferma ciascuno, che il gioco muove copiando
# i movimenti dei fotogrammi del diavoletto dipinto.
#   client/assets/personaggi/<nome>.png    i pixel veri, ingranditi PIXEL volte
#   client/battaglia/personaggi.lua        misura, centro dall'appoggio e fiammella
# ChatGPT disegna pixel "finti" (quadretti di 11-13 px non tutti uguali): si
# trova la griglia (passo e scarto per riga e colonna) e si prende il colore al
# centro di ogni quadretto. I disegni sono sulla stessa tela 1254 con la scala
# del diavoletto dipinto (base_pezzi_1024 ingrandita), quindi una scala sola.
# python3 strumenti/grafica/personaggi.py
import os
import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))

DIS = "/mnt/project-files/gabriella/disegni/2026-10-25_pixel/originali_chatgpt"
OUT = os.path.join(QUI, "..", "..", "client", "assets", "personaggi")
LUA = os.path.join(QUI, "..", "..", "client", "battaglia", "personaggi.lua")
NOMI = ("diavoletto", "brace", "ombra", "zolfo")
# la fiammella (o quello che ha in testa) di ciascuno: colore e fin dove sta, dall'alto
FIAMMA = {
    "diavoletto": (lambda r, g, b: (r > 200) & (b < 90) & (g < 200), 0.2),
    "brace": (lambda r, g, b: (r > 200) & (b < 90), 0.15),
    "ombra": (lambda r, g, b: (g > 150) & (b > 150) & (r < 160), 0.2),
    "zolfo": (lambda r, g, b: (r > 200) & (g > 200) & (b < 120), 0.12),
}
# unità per pixel della tela: come la base (200 unità dalla cima della testa ai piedi = 701 px su 1024)
S = 200 / (941 - 240) * 1024 / 1254
# ogni pixel vero diventa PIXEL x PIXEL nella texture: rimpicciolendo resta netto
PIXEL = 4


def chiave(a):
    """Quanto è figura e non fondo magenta (come fotogrammi.py)."""
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    return 1 - np.clip(((r + b) / 2 - g - 90) / 80, 0, 1)


def griglia(bordi):
    """Passo e scarto della griglia: dove cadono i bordi più forti."""
    meglio = (-1, 0, 0)
    for p in np.arange(10.5, 14.5, 0.01):
        for o in np.arange(0, p, 0.25):
            s = bordi[np.round(np.arange(o, len(bordi) - 1, p)).astype(int)].mean()
            if s > meglio[0]:
                meglio = (s, p, o)
    return meglio[1:]


def pixel(a):
    """I pixel veri (RGBA, 1 per quadretto) e la misura del quadretto sulla tela."""
    px, ox = griglia(np.abs(np.diff(a, axis=1)).sum((0, 2)))
    py, oy = griglia(np.abs(np.diff(a, axis=0)).sum((1, 2)))
    al = chiave(a)
    xs, ys = np.arange(ox + 1, a.shape[1] - px, px), np.arange(oy + 1, a.shape[0] - py, py)
    out = np.zeros((len(ys), len(xs), 4), np.uint8)
    for j, y in enumerate(ys):
        for i, x in enumerate(xs):
            # solo la metà centrale del quadretto: i bordi sono sfumati
            sy = slice(int(y + py / 4), int(y + py * 3 / 4) + 1)
            sx = slice(int(x + px / 4), int(x + px * 3 / 4) + 1)
            m = al[sy, sx] > 0.5
            if m.mean() >= 0.5:
                out[j, i, :3] = np.median(a[sy, sx][m], 0)
                out[j, i, 3] = 255
    return out, px, py, ox + 1, oy + 1


def main():
    os.makedirs(OUT, exist_ok=True)
    righe = []
    for nome in NOMI:
        a = np.asarray(Image.open(os.path.join(DIS, nome + "_pixel.png")).convert("RGB")).astype(float)
        p, px, py, x0, y0 = pixel(a)
        m = p[..., 3] > 0
        ys, xs = np.nonzero(m)
        r0, r1, c0, c1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        p, m = p[r0:r1, c0:c1], m[r0:r1, c0:c1]
        h, w = m.shape
        Image.fromarray(p, "RGBA").resize((w * PIXEL, h * PIXEL), Image.NEAREST).save(
            os.path.join(OUT, nome + ".png"))
        ux, uy = px * S, py * S   # unità per pixel vero
        # appoggio: sotto i piedi, in x al centro delle gambe (ultimo quarto)
        gx = np.nonzero(m[h - h // 4:])[1]
        ax = (gx.min() + gx.max() + 1) / 2
        cx, cy = (w / 2 - ax) * ux, h / 2 * uy
        # la fiammella: il centro dei suoi pixel
        colore, fin = FIAMMA[nome]
        q = p[:int(h * fin)].astype(int)
        ty, tx = np.nonzero(m[:int(h * fin)] & colore(q[..., 0], q[..., 1], q[..., 2]))
        fx, fy = (tx.mean() + 0.5 - ax) * ux, (h - ty.mean()) * uy - 10
        righe.append('\t%s = { img = "%s", w = %.1f, h = %.1f, x = %.1f, y = %.1f, fx = %.1f, fy = %.1f },' % (
            nome, nome, w * ux, h * uy, cx, cy, fx, fy))
        print(nome, (w, h), round(px, 2), round(py, 2))
    with open(LUA, "w") as f:
        f.write("-- Generato da strumenti/grafica/personaggi.py: non modificare a mano.\n")
        f.write("-- Misura e centro (unità, dall'appoggio, y in su) dei personaggi interi.\n")
        f.write("return {\n" + "\n".join(righe) + "\n}\n")


if __name__ == "__main__":
    main()
