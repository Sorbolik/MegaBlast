# Il diavoletto a fotogrammi, dai fogli di Ludo.ai e dalle basi di ChatGPT
# (guida e sorgenti: /mnt/project-files/animazioni_ludo/diavoletto_2026-10-26/):
#   basi_chatgpt/A_con_braccia.png               il diavoletto fermo, con le braccia
#   basi_chatgpt/B_senza_braccia_senza_testa.png lo stesso, senza braccia né testa
#   basi_chatgpt/D_testa.png                     la testa da sola
#   fogli/<animazione>/frame_NNN.png             i fotogrammi di Ludo (Download all frames)
# Scrive:
#   client/assets/diavoletto/<animazione>_<n>.png, testa.png
#   client/battaglia/diavoletto.atlas
#   client/battaglia/diavoletto.lua   misure e punti in pixel delle immagini del
#                                     gioco, origine fra i piedi e y verso l'alto
#
# Ogni foglio parte dalla sua base (First Frame di Ludo): il primo fotogramma si
# allinea alla base con la stessa misura e i piedi nello stesso punto, poi tutti i
# fotogrammi del foglio si spostano insieme (la camera di Ludo è ferma).
# Misura: dai piedi alla cima della testa (la pelle sopra gli occhiali, corna
# escluse) il diavoletto è alto ALTEZZA pixel; nella base B, senza testa, al posto
# della testa c'è la cima del collo, che sta dove nella base A comincia la testa.
# Per ogni fotogramma si cercano sulla pelle la cima della testa (lì il gioco mette
# la fiammella) oppure, senza testa, il collo (lì mette la testa, che gira con la
# mira) e la spalla (lì girano pugni e arma).
#
# python3 strumenti/grafica/diavoletto.py [cartella dei sorgenti]
import os
import sys
import glob
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..", "..", "client")
OUT = os.path.join(RADICE, "assets", "diavoletto")
LUA = os.path.join(RADICE, "battaglia", "diavoletto.lua")
ATLAS = os.path.join(RADICE, "battaglia", "diavoletto.atlas")
SORGENTE = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/animazioni_ludo/diavoletto_2026-10-26"

# pixel dai piedi alla cima della testa nelle immagini del gioco: a zoom vicino su
# un telefono il diavoletto è alto più o meno così in pixel veri
ALTEZZA = 150

# Le animazioni: base, fotogrammi da usare (da 0, come nei nomi di Ludo), ogni
# quanti prenderne uno, fotogrammi al secondo di Ludo e se si ripete. "giro"
# cerca da solo il pezzo che si ripete meglio (la corsa). "foglio" prende i
# fotogrammi dal foglio di un'altra animazione. Un foglio che non c'è si salta: il gioco usa l'attesa. Nei salti Ludo alza il corpo nel fotogramma
# anche se gli si chiede di no: "ferma_spalla" (tutti i fotogrammi) e
# "ferma_cima" (quelli da..a, in aria, solo in altezza) tengono la spalla o la
# cima della testa dove stanno nel primo, così in aria il corpo non sale sopra
# la sua capsula e passando a terra o alla mira busto e testa non saltano.
# L'attesa è un fotogramma fermo: ogni tanto, a caso, il gioco fa una delle
# scenette (naso, sbadiglio, coda).
AZIONI = {
    "mira": dict(base="B", da=0, a=35, passo=1, giro=True),
    "attesa": dict(base="A", foglio="naso", da=0, a=0, passo=1, giro=True),
    "naso": dict(base="A", da=2, a=33, passo=2, giro=False),
    "sbadiglio": dict(base="A", da=6, a=33, passo=2, giro=False),
    "coda": dict(base="A", da=3, a=33, passo=2, giro=False),
    "sconfitta": dict(base="A", da=4, a=28, passo=2, giro=False),
    "corsa": dict(base="A", cerca=(5, 30, 8, 18), giro=True),
    "corsa_mira": dict(base="B", cerca=(5, 30, 8, 18), giro=True),
    "salto": dict(base="A", da=10, a=27, passo=1, giro=False, ferma_cima=(11, 19)),
    "colpito": dict(base="A", da=10, a=24, passo=2, giro=False),
    "vittoria": dict(base="A", da=0, a=35, passo=1, giro=True),
    "mira_aria": dict(base="B", da=7, a=21, passo=1, giro=False, ferma_spalla=True),
    "fiammella": dict(base=None, da=0, a=35, passo=2, giro=True),
}
FPS = 12   # Ludo: 36 fotogrammi in 3 s


def apri(path, corpo=True):
    """RGBA in float 0..1; un fondo magenta diventa trasparente. Nel corpo restano
    solo i pezzi grandi: via scintille ed effetti staccati."""
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255
    rgb, al = a[..., :3], a[..., 3]
    if al.min() > 0.99:
        r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
        al = 1 - np.clip((np.minimum(r, b) - g - 0.35) / 0.3, 0, 1)
        spill = np.clip(np.minimum(r, b) - g, 0, None) * (al < 0.99)
        rgb = np.stack([r - spill, g, b - spill], -1)
    # via i puntini staccati (rumore del generatore)
    lab, n = nd.label(al > 0.1)
    if n > 1:
        sz = nd.sum(al > 0.1, lab, range(1, n + 1))
        al = al * np.isin(lab, 1 + np.nonzero(sz > sz.max() * (0.03 if corpo else 0.002))[0])
    return np.dstack([np.clip(rgb, 0, 1), al])


def pelle(a):
    """Pezzi di pelle (testa, collo, braccia, spalle): bbox (y0, y1, x0, x1) e area,
    dal più grande."""
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    m = (r > 0.55) & (g > 0.48) & (b > 0.4) & (r - b > 0.04) & (r - b < 0.25) & (r - g < 0.15) & (al > 0.5)
    lab, n = nd.label(m)
    if n == 0:
        return []
    sz = nd.sum(m, lab, range(1, n + 1))
    objs = nd.find_objects(lab)
    out = [(int(sz[i]), objs[i][0].start, objs[i][0].stop, objs[i][1].start, objs[i][1].stop) for i in range(n)]
    return sorted(out, reverse=True)


def cima(a, soglia=0.15):
    """La cima della pelle: il pezzo grande più in alto (la testa sopra gli
    occhiali, o il collo se la testa non c'è; il collo nei salti di Ludo a volte
    è piccolo, per questo senza testa basta una soglia più bassa). Ritorna
    (x al centro, y in cima)."""
    pz = pelle(a)
    grandi = [p for p in pz if p[0] > pz[0][0] * soglia]
    p = min(grandi, key=lambda p: p[1])
    return (p[3] + p[4]) / 2, float(p[1]), p


def spalla(a):
    """Il centro del pezzo di pelle più grande (nella base B è la spalla tonda)."""
    p = pelle(a)[0]
    return (p[3] + p[4]) / 2, (p[1] + p[2]) / 2


def piedi(al):
    """Punto fra i piedi: il centro dei pixel pieni nella fascia più bassa."""
    ys, xs = np.nonzero(al > 0.5)
    fondo = ys.max()
    band = ys > fondo - 0.03 * (fondo - ys.min())
    return xs[band].mean(), float(fondo)


def scala(a, s):
    h, w = a.shape[:2]
    pm = np.dstack([a[..., :3] * a[..., 3:], a[..., 3:]])
    img = Image.fromarray((pm * 255).round().astype(np.uint8), "RGBA").resize(
        (max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    # un po' di nitidezza: la riduzione ammorbidisce i contorni
    img = img.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))
    b = np.asarray(img).astype(np.float32) / 255
    al = b[..., 3:]
    return np.dstack([np.clip(np.where(al > 0, b[..., :3] / np.maximum(al, 1e-6), 0), 0, 1), al])


def salva(a, s, nome):
    """Ritaglia, riduce di s e salva; ritorna il centro (pixel della sorgente) e la
    misura (pixel del gioco)."""
    ys, xs = np.nonzero(a[..., 3] > 0.02)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    c = scala(a[y0:y1, x0:x1], s)
    Image.fromarray((c * 255).round().astype(np.uint8), "RGBA").save(os.path.join(OUT, nome + ".png"), optimize=True)
    return (x0 + x1) / 2, (y0 + y1) / 2, c.shape[1], c.shape[0]


def maschera(a, k=4):
    return a[::k, ::k, 3] > 0.5


def n(v):
    return f"{v:.1f}"


def giro_migliore(fot, da, a, corto, lungo):
    """Il pezzo che si ripete meglio: i, j con il fotogramma j più simile all'i."""
    m = [maschera(f).astype(np.float32) for f in fot]
    best = None
    for i in range(da, a):
        for j in range(i + corto, min(i + lungo, a) + 1):
            d = np.abs(m[i] - m[j]).mean()
            if best is None or d < best[0]:
                best = (d, i, j)
    return best[1], best[2] - 1


def colori_di_ludo(sorgente, ludo):
    """Ludo schiarisce un po' i colori della sua base. Per ogni canale, la tabella
    che porta i colori della base (ChatGPT) a quelli dello stesso disegno rifatto
    da Ludo (il suo primo fotogramma): si confrontano i due istogrammi."""
    lut = []
    for c in range(3):
        a = sorgente[..., c][sorgente[..., 3] > 0.9]
        b = ludo[..., c][ludo[..., 3] > 0.9]
        q = np.linspace(0, 1, 257)
        lut.append((np.quantile(a, q), np.quantile(b, q)))
    return lut


def ricolora(a, lut):
    out = a.copy()
    for c, (x, y) in enumerate(lut):
        out[..., c] = np.interp(a[..., c], x, y)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in glob.glob(os.path.join(OUT, "*.png")):
        os.remove(f)

    basi = {"A": apri(os.path.join(SORGENTE, "basi_chatgpt", "A_con_braccia.png")),
            "B": apri(os.path.join(SORGENTE, "basi_chatgpt", "B_senza_braccia_senza_testa.png"))}
    # la base A dà la misura: dai piedi alla cima della testa
    ax, ay = piedi(basi["A"][..., 3])
    tx, ty, testa_a = cima(basi["A"])
    S = ALTEZZA / (ay - ty)          # pixel del gioco per pixel delle basi
    bx, by = piedi(basi["B"][..., 3])

    def gioco(x, y, ox, oy):
        """Da pixel delle basi (y in giù, piedi in ox, oy) al gioco."""
        return (x - ox) * S, (oy - y) * S

    righe = ["-- Fatto da strumenti/grafica/diavoletto.py, non modificare a mano.",
             "-- Il diavoletto in pixel delle immagini: origine fra i piedi, y verso l'alto.",
             "-- Per ogni fotogramma: immagine, centro (x, y) e misura (w, h); poi o la cima",
             "-- della testa (tx, ty, lì va la fiammella) o il collo (cx, cy, lì va la testa)",
             "-- e la spalla (sx, sy, lì girano pugni e arma).",
             "return {",
             f"\taltezza = {ALTEZZA},  -- dai piedi alla cima della testa"]
    immagini = []

    # la testa da sola: della misura della testa della base A, con il perno sul
    # collo; la cima della testa (per la fiammella) rispetto al perno
    d = apri(os.path.join(SORGENTE, "basi_chatgpt", "D_testa.png"))
    # la testa staccata ha i colori di ChatGPT: le diamo quelli di Ludo, come il
    # corpo della mira su cui sta
    ferma = sorted(glob.glob(os.path.join(SORGENTE, "fogli", AZIONI["attesa"]["foglio"], "*.png")))
    if ferma:
        d = ricolora(d, colori_di_ludo(basi["A"], apri(ferma[0])))
    dtx, dty, testa_d = cima(d)
    sd = (testa_a[4] - testa_a[3]) / (testa_d[4] - testa_d[3])   # dalla D alla A
    cx, cy, w, h = salva(d, S * sd, "testa")
    immagini.append("testa")
    # nella A il collo è sotto la testa, dove nella B comincia il collo
    nx, ny, _ = cima(basi["B"])
    # centro dell'immagine della testa nella A: allineata con la cima della testa
    hx, hy = tx + (cx - dtx) * sd, ty + (cy - dty) * sd
    righe.append(f"\ttesta = {{ img = \"testa\", w = {w}, h = {h}, "
                 f"x = {n((hx - nx) * S)}, y = {n((ny - hy) * S)}, "
                 f"tx = {n((tx - nx) * S)}, ty = {n((ny - ty) * S)} }},")

    righe.append("\tanimazioni = {")
    for nome, cfg in AZIONI.items():
        fogli = sorted(glob.glob(os.path.join(SORGENTE, "fogli", cfg.get("foglio", nome), "*.png")))
        if not fogli:
            continue
        fot = [apri(f, cfg["base"] is not None) for f in fogli]
        # il disegno che tocca il bordo del fotogramma è tagliato (di solito la coda)
        tagliati = [i for i, f in enumerate(fot)
                    if max(f[:, :2, 3].max(), f[:, -2:, 3].max(), f[:2, :, 3].max(), f[-2:, :, 3].max()) > 0.15]
        if tagliati:
            print(f"ATTENZIONE {nome}: {len(tagliati)} fotogrammi toccano il bordo (tagliati): {tagliati}")
        if cfg.get("cerca"):
            da, a = giro_migliore(fot, *cfg["cerca"])
            passo = 1
        else:
            da, a, passo = cfg["da"], min(cfg["a"], len(fot) - 1), cfg["passo"]
        scelti = list(range(da, a + 1, passo))
        righe.append(f"\t\t{nome} = {{ fps = {FPS / passo:.0f}, giro = {str(cfg['giro']).lower()},")

        if cfg["base"] is None:
            # la fiammella: tutta nella sua misura, centrata in basso
            f0 = fot[0]
            ys, xs = np.nonzero(f0[..., 3] > 0.5)
            s = 0.34 * ALTEZZA / np.ptp(ys)
            px, py = (xs.min() + xs.max()) / 2, ys.max()
            for k, i in enumerate(scelti, 1):
                nm = f"{nome}_{k}"
                cx, cy, w, h = salva(fot[i], s, nm)
                righe.append(f"\t\t\t{{ img = \"{nm}\", x = {n((cx - px) * s)}, y = {n((py - cy) * s)}, w = {w}, h = {h} }},")
                immagini.append(nm)
            righe.append("\t\t},")
            continue

        # allinea il foglio alla sua base con il primo fotogramma
        base = basi[cfg["base"]]
        ox, oy = (ax, ay) if cfg["base"] == "A" else (bx, by)
        _, cb, _ = cima(base)
        fx, fy = piedi(fot[0][..., 3])
        _, cf, _ = cima(fot[0])
        k = (oy - cb) / (fy - cf)      # dal foglio alla base
        for j, i in enumerate(scelti, 1):
            f = fot[i]
            nm = f"{nome}_{j}"
            cx, cy, w, h = salva(f, S * k, nm)
            # dal foglio alla base: stesso punto fra i piedi
            gx, gy = fx, fy
            if cfg.get("ferma_spalla"):
                (qx, qy), (q0x, q0y) = spalla(f), spalla(fot[0])
                gx, gy = fx + qx - q0x, fy + qy - q0y
            elif cfg.get("ferma_cima") and cfg["ferma_cima"][0] <= i <= cfg["ferma_cima"][1]:
                # solo in altezza: di lato Ludo sposta il corpo poco a poco
                gy = fy + cima(f)[1] - cima(fot[0])[1]

            def b(x, y):
                return gioco(ox + (x - gx) * k, oy + (y - gy) * k, ox, oy)
            x, y = b(cx, cy)
            riga = f"\t\t\t{{ img = \"{nm}\", x = {n(x)}, y = {n(y)}, w = {w}, h = {h}"
            if cfg["base"] == "A":
                px, py, _ = cima(f)
                px, py = b(px, py)
                riga += f", tx = {n(px)}, ty = {n(py)}"
            else:
                px, py, _ = cima(f, 0.08)
                qx, qy = spalla(f)
                px, py = b(px, py)
                qx, qy = b(qx, qy)
                riga += f", cx = {n(px)}, cy = {n(py)}, sx = {n(qx)}, sy = {n(qy)}"
            righe.append(riga + " },")
            immagini.append(nm)
        righe.append("\t\t},")
    righe += ["\t},", "}", ""]
    with open(LUA, "w") as f:
        f.write("\n".join(righe))

    with open(ATLAS, "w") as f:
        for nm in immagini:
            f.write(f'images {{\n  image: "/assets/diavoletto/{nm}.png"\n}}\n')
        f.write("margin: 0\nextrude_borders: 2\ninner_padding: 0\n")
    tot = sum(np.prod(Image.open(os.path.join(OUT, nm + ".png")).size) for nm in immagini)
    print(f"{len(immagini)} immagini, {tot * 4 / 1e6:.1f} MB in memoria")


if __name__ == "__main__":
    main()
