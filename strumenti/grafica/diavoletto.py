# Il diavoletto di Gabriella in pixel art: i fotogrammi dai fogli di Ludo
# (Sprite Generator, 6x6 su fondo trasparente, Use Pixel Grid).
#   client/assets/diavoletto/<azione>_<n>.png   n: il fotogramma nel foglio
#   client/battaglia/diavoletto.lua             misura, centro e fiammella di ognuno
# Ludo ricampiona i quadretti (bordi sfumati, passo non intero): si trova la
# griglia (passo e scarto per riga e colonna) e si prende il colore al centro di
# ogni quadretto. Ogni foglio parte dalla stessa immagine (il First Frame), quindi
# il suo primo fotogramma dà la misura e l'appoggio per tutti gli altri: così i
# fogli combaciano e il corpo non balla.
# python3 strumenti/grafica/diavoletto.py
import os
import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
FOGLI = "/mnt/project-files/gabriella/disegni/2026-10-25_pixel/ludo"
OUT = os.path.join(QUI, "..", "..", "client", "assets", "diavoletto")
LUA = os.path.join(QUI, "..", "..", "client", "battaglia", "diavoletto.lua")

# unità del disegno (200 dalla cima della testa ai piedi = ROBOT_H): il primo
# fotogramma, dalla fiammella ai piedi, è alto ALTO
ALTO = 256
# ogni pixel vero diventa PIXEL x PIXEL nella texture: rimpicciolendo resta netto
PIXEL = 4
# la spalla davanti nel primo fotogramma, dall'appoggio (unità, y in su): lì gira l'arma
SPALLA = (-12, 112)


def avanti_indietro(a):
    """a e poi a all'indietro, senza ripetere gli estremi: un giro che non scatta."""
    return a + a[-2:0:-1]


# azione -> (foglio, fotogrammi del foglio da 1, in ordine). Quanti sono e cosa
# fanno lo sa client/battaglia/scoria.lua (vedi i commenti lì)
AZIONI = {
    # respiro calmo 1-27 avanti e indietro; il sospiro (gli occhi si chiudono,
    # 28-36) parte ogni tanto dal 27 e torna all'1, come il giro di Ludo
    "riposo": ("diavoletto_riposo.png", avanti_indietro(list(range(1, 28)))),
    "sospiro": ("diavoletto_riposo.png", list(range(28, 37))),
    # un giro di passi: il foglio dove si somiglia di più a 11 fotogrammi dopo
    "corsa": ("diavoletto_corsa.png", list(range(19, 30))),
    "corsa_armata": ("diavoletto_corsa_armata.png", list(range(9, 20))),
    # 1-11 in aria (stacco, cima, caduta), 12-16 atterraggio fino in piedi
    "salto": ("diavoletto_salto.png", list(range(8, 19)) + [19, 21, 23, 25, 28]),
    # 1-7 respiro mirando (avanti e indietro), 8-12 rinculo
    "mira": ("diavoletto_mira.png", [2, 7, 12, 17, 22, 27, 32, 30, 26, 22, 18, 14]),
    "colpito": ("diavoletto_colpito.png", list(range(4, 12))),
    # dalla carica col braccio alzato al colpo in avanti (18-21 hanno la scia disegnata)
    "fendente": ("diavoletto_fendente.png", [8, 14, 17, 22, 25]),
    "lancio": ("diavoletto_lancio.png", [3, 5, 8, 11, 12, 13, 15, 18, 21, 23, 24, 26]),
    # 1-5 sparisce nella fiammella, 6-12 ricompare (31-36 Ludo l'ha ingrandito)
    "teletrasporto": ("diavoletto_teletrasporto.png", [2, 7, 9, 11, 13, 16, 19, 21, 23, 25, 26, 27]),
    "vittoria": ("diavoletto_vittoria.png", list(range(1, 37, 2))),
    "paracadute": ("diavoletto_paracadute.png", avanti_indietro(list(range(7, 31, 2)))),
}


def griglia(bordi, da, a):
    """Passo e scarto della griglia: dove cadono i bordi più forti."""
    meglio = (-1, 0, 0)
    for p in np.arange(da, a, 0.01):
        for o in np.arange(0, p, 0.25):
            s = bordi[np.round(np.arange(o, len(bordi) - 1, p)).astype(int)].mean()
            if s > meglio[0]:
                meglio = (s, p, o)
    return meglio[1:]


def pixel(cella):
    """I pixel veri (RGBA, 1 per quadretto), il passo e l'origine della griglia nella cella."""
    al = cella[..., 3] / 255
    a = cella[..., :3] * al[..., None]
    px, ox = griglia(np.abs(np.diff(a, axis=1)).sum((0, 2)), 5, 9)
    py, oy = griglia(np.abs(np.diff(a, axis=0)).sum((1, 2)), 5, 9)
    xs, ys = np.arange(ox + 1, a.shape[1] - px, px), np.arange(oy + 1, a.shape[0] - py, py)
    out = np.zeros((len(ys), len(xs), 4), np.uint8)
    for j, y in enumerate(ys):
        for i, x in enumerate(xs):
            # solo la metà centrale del quadretto: i bordi sono sfumati
            sy = slice(int(y + py / 4), int(y + py * 3 / 4) + 1)
            sx = slice(int(x + px / 4), int(x + px * 3 / 4) + 1)
            m = al[sy, sx] > 0.5
            if m.mean() >= 0.5:
                out[j, i, :3] = np.median(cella[sy, sx, :3][m], 0)
                out[j, i, 3] = 255
    return out, px, py, ox + 1, oy + 1


def fiamma(p):
    """Il centro dei pixel della fiammella (arancio, nel quinto più alto), in pixel veri."""
    h = max(1, p.shape[0] // 5)
    q = p[:h].astype(int)
    m = (q[..., 3] > 0) & (q[..., 0] > 200) & (q[..., 2] < 90) & (q[..., 1] < 200)
    ys, xs = np.nonzero(m)
    if len(ys) == 0:
        return None
    return xs.mean() + 0.5, ys.mean() + 0.5


def foglio(nome):
    """Le celle del foglio, rimesse sulla griglia, in un dizionario da 1 a 36."""
    a = np.asarray(Image.open(os.path.join(FOGLI, nome)).convert("RGBA")).astype(float)
    ch, cw = a.shape[0] / 6, a.shape[1] / 6
    return lambda n: pixel(a[int((n - 1) // 6 * ch):int(((n - 1) // 6 + 1) * ch),
                             int((n - 1) % 6 * cw):int(((n - 1) % 6 + 1) * cw)])


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        os.remove(os.path.join(OUT, f))
    righe, fatti = [], {}
    for azione, (nome, quali) in AZIONI.items():
        cella = foglio(nome)
        # misura e appoggio dal primo fotogramma del foglio: pixel della cella -> unità
        p, px, py, x0, y0 = cella(1)
        ys, xs = np.nonzero(p[..., 3])
        u = ALTO / ((ys.max() + 1 - ys.min()) * py)
        gx = np.nonzero(p[ys.max() - (ys.max() - ys.min()) // 4:ys.max() + 1, :, 3])[1]
        ax = x0 + (gx.min() + gx.max() + 1) / 2 * px
        ay = y0 + (ys.max() + 1) * py
        voci = []
        for n in quali:
            img = "%s_%d" % (nome[len("diavoletto_"):-4], n)
            if img not in fatti:
                p, px, py, x0, y0 = cella(n)
                ys, xs = np.nonzero(p[..., 3])
                r0, r1, c0, c1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
                p = p[r0:r1, c0:c1]
                h, w = p.shape[:2]
                Image.fromarray(p, "RGBA").resize((w * PIXEL, h * PIXEL), Image.NEAREST).save(
                    os.path.join(OUT, img + ".png"))
                # pixel veri -> unità, dall'appoggio con y in su
                X = lambda c: (x0 + (c0 + c) * px - ax) * u
                Y = lambda r: (ay - y0 - (r0 + r) * py) * u
                voce = 'img = "%s", w = %.1f, h = %.1f, x = %.1f, y = %.1f' % (
                    img, w * px * u, h * py * u, X(w / 2), Y(h / 2))
                fm = fiamma(p)
                if fm:
                    voce += ", fx = %.1f, fy = %.1f" % (X(fm[0]), Y(fm[1]))
                fatti[img] = "{ " + voce + " },"
            voci.append("\t\t" + fatti[img])
        righe.append("\t%s = {\n%s\n\t}," % (azione, "\n".join(voci)))
        print(azione, len(quali), "fotogrammi")
    print(len(fatti), "immagini")
    with open(LUA, "w") as f:
        f.write("-- Fatto da strumenti/grafica/diavoletto.py, non modificare a mano.\n")
        f.write("-- Per ogni azione i fotogrammi del diavoletto: immagine, misura (w, h) e\n")
        f.write("-- centro (x, y) dell'immagine e fiammella (fx, fy) dal punto d'appoggio\n")
        f.write("-- (ai piedi, al centro del corpo), in unità del disegno con y verso l'alto.\n")
        f.write("return {\n\tspalla = { %d, %d },\n%s\n}\n" % (SPALLA[0], SPALLA[1], "\n".join(righe)))


if __name__ == "__main__":
    main()
