# I quattro diavoletti di Gabriella in pixel art (ChatGPT), interi, per la
# prova della designer: un'immagine ferma ciascuno, che il gioco muove copiando
# i movimenti dei fotogrammi del diavoletto dipinto.
#   client/assets/personaggi/<nome>.png    i pixel veri, ingranditi PIXEL volte
#   client/battaglia/personaggi.lua        misura, centro dall'appoggio e fiammella
# ChatGPT disegna pixel "finti" (quadretti di 11-13 px non tutti uguali): si
# trova la griglia (passo e scarto per riga e colonna) e si prende il colore al
# centro di ogni quadretto. I disegni sono sulla stessa tela 1254 con la scala
# del diavoletto dipinto (base_pezzi_1024 ingrandita), quindi una scala sola.
# I fogli di Ludo (6x6 su fondo trasparente, Use Pixel Grid) danno i fotogrammi
# propri di un personaggio: stessa griglia, alla misura della sua immagine ferma
# e con l'appoggio del primo fotogramma, così il corpo non balla.
#   client/assets/personaggi/<nome>_<azione>_<i>.png
# python3 strumenti/grafica/personaggi.py
import os
import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))

DIS = "/mnt/project-files/gabriella/disegni/2026-10-25_pixel/originali_chatgpt"
OUT = os.path.join(QUI, "..", "..", "client", "assets", "personaggi")
LUA = os.path.join(QUI, "..", "..", "client", "battaglia", "personaggi.lua")
_CALMO = list(range(30, 37)) + list(range(1, 11))
RIPOSO_CALMO = _CALMO + _CALMO[-2:0:-1]
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
LUDO = "/mnt/project-files/gabriella/disegni/2026-10-25_pixel/ludo"
# i fotogrammi propri: personaggio -> azione -> (foglio, fotogrammi del foglio da 1, in ordine)
# riposo: Ludo ci ha messo un sospiro (11-28, con la coda fuori dal riquadro):
# resta il respiro calmo 30-36 e 1-10 (36 -> 1 è il giro di Ludo), avanti e
# indietro: così non c'è un punto in cui scatta
FOGLI = {
    "diavoletto": {"riposo": ("diavoletto_riposo_v1.png", RIPOSO_CALMO)},
}
# ogni pixel vero diventa PIXEL x PIXEL nella texture: rimpicciolendo resta netto
PIXEL = 4


def chiave(a):
    """Quanto è figura e non fondo magenta (come fotogrammi.py)."""
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    return 1 - np.clip(((r + b) / 2 - g - 90) / 80, 0, 1)


def griglia(bordi, da, a):
    """Passo e scarto della griglia: dove cadono i bordi più forti."""
    meglio = (-1, 0, 0)
    for p in np.arange(da, a, 0.01):
        for o in np.arange(0, p, 0.25):
            s = bordi[np.round(np.arange(o, len(bordi) - 1, p)).astype(int)].mean()
            if s > meglio[0]:
                meglio = (s, p, o)
    return meglio[1:]


def pixel(a, al=None, passi=(10.5, 14.5)):
    """I pixel veri (RGBA, 1 per quadretto) e la misura del quadretto sulla tela."""
    px, ox = griglia(np.abs(np.diff(a, axis=1)).sum((0, 2)), *passi)
    py, oy = griglia(np.abs(np.diff(a, axis=0)).sum((1, 2)), *passi)
    al = chiave(a) if al is None else al
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


def fiamma(nome, p, m, ax, h, ux, uy):
    """Il centro dei pixel della fiammella, dall'appoggio, in unità."""
    colore, fin = FIAMMA[nome]
    q = p[:int(h * fin)].astype(int)
    ty, tx = np.nonzero(m[:int(h * fin)] & colore(q[..., 0], q[..., 1], q[..., 2]))
    return (tx.mean() + 0.5 - ax) * ux, (h - ty.mean()) * uy - 10


def fotogrammi(nome, azione, foglio, quali, alto):
    """Le righe Lua dei fotogrammi di un foglio Ludo 6x6; alto: unità della figura ferma."""
    a = np.asarray(Image.open(os.path.join(LUDO, foglio)).convert("RGBA")).astype(float)
    ch, cw = a.shape[0] / 6, a.shape[1] / 6
    celle, fatte = [], {}
    for n in quali:
        if n in fatte:
            celle.append(fatte[n])
            continue
        r, c = divmod(n - 1, 6)
        cella = a[int(r * ch):int((r + 1) * ch), int(c * cw):int((c + 1) * cw)]
        al = cella[..., 3] / 255
        p, px, py, x0, y0 = pixel(cella[..., :3] * al[..., None], al, (5, 9))
        fatte[n] = (p, px, py, x0, y0)
        celle.append(fatte[n])
    # la misura e l'appoggio dal primo: pixel della cella -> unità
    p, px, py, x0, y0 = celle[0]
    ys, xs = np.nonzero(p[..., 3])
    u = alto / ((ys.max() + 1 - ys.min()) * py)
    gx = np.nonzero(p[ys.max() - (ys.max() - ys.min()) // 4:ys.max() + 1, :, 3])[1]
    ax = x0 + (gx.min() + gx.max() + 1) / 2 * px
    ay = y0 + (ys.max() + 1) * py
    righe = []
    for n, (p, px, py, x0, y0) in zip(quali, celle):
        ys, xs = np.nonzero(p[..., 3])
        r0, r1, c0, c1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        p = p[r0:r1, c0:c1]
        h, w = p.shape[:2]
        img = "%s_%s_%d" % (nome, azione, n)   # il numero nel foglio: uno per disegno
        Image.fromarray(p, "RGBA").resize((w * PIXEL, h * PIXEL), Image.NEAREST).save(
            os.path.join(OUT, img + ".png"))
        cx = (x0 + (c0 + w / 2) * px - ax) * u
        cy = (ay - y0 - (r0 + h / 2) * py) * u
        fx, fy = fiamma(nome, p, p[..., 3] > 0, (ax - x0) / px - c0, h, px * u, py * u)
        fy += (ay - y0 - r1 * py) * u   # fiamma() misura dal fondo della figura
        righe.append('{ img = "%s", w = %.1f, h = %.1f, x = %.1f, y = %.1f, fx = %.1f, fy = %.1f },' % (
            img, w * px * u, h * py * u, cx, cy, fx, fy))
    print(nome, azione, len(righe), "fotogrammi,", len(fatte), "disegni")
    return righe


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
        fx, fy = fiamma(nome, p, m, ax, h, ux, uy)
        foto = "".join("\n\t\t%s = {%s\n\t\t}," % (az, "".join(
            "\n\t\t\t" + r for r in fotogrammi(nome, az, foglio, quali, h * uy)))
            for az, (foglio, quali) in FOGLI.get(nome, {}).items())
        righe.append('\t%s = { img = "%s", w = %.1f, h = %.1f, x = %.1f, y = %.1f, fx = %.1f, fy = %.1f,%s },' % (
            nome, nome, w * ux, h * uy, cx, cy, fx, fy, foto and " foto = {" + foto + "\n\t}" or ""))
        print(nome, (w, h), round(px, 2), round(py, 2))
    with open(LUA, "w") as f:
        f.write("-- Generato da strumenti/grafica/personaggi.py: non modificare a mano.\n")
        f.write("-- Misura e centro (unità, dall'appoggio, y in su) dei personaggi interi.\n")
        f.write("return {\n" + "\n".join(righe) + "\n}\n")


if __name__ == "__main__":
    main()
