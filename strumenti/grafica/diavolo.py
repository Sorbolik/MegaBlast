# Il diavoletto a fotogrammi, dai disegni di Ludo e ChatGPT
# (guida: /mnt/project-files/animazioni_ludo/prompt_ludo_armato.md):
#   base_senza_braccia.png    il diavoletto fermo, senza braccia, su magenta
#   braccia.png               sopra il braccio davanti, dritto, col pugno chiuso
#   punti.json                i punti di spalle, testa e fiammella (sotto)
#   fogli/<animazione>.png    i fogli di Ludo (griglia di celle, trasparenti o magenta)
# Scrive:
#   client/assets/diavolo/<animazione>_<n>.png, braccio.png, braccio_dietro.png
#   client/battaglia/diavolo.lua   misure e punti, in pixel della base con
#                                  l'origine fra i piedi e y verso l'alto
# e aggiorna l'elenco delle immagini del diavoletto in battaglia.atlas.
#
# Ogni foglio si allinea alla base col suo primo fotogramma, che in Ludo è la
# base stessa (First Frame): stessa misura e piedi nello stesso punto. Poi i
# fotogrammi restano come li ha disegnati Ludo, con la camera ferma, così i piedi
# appoggiati non tremano. Le spalle seguono il corpo: il baricentro del rosso
# della canottiera, fotogramma per fotogramma.
#
# python3 strumenti/grafica/diavolo.py [cartella dei disegni]
import os
import sys
import glob
import json
import re
import numpy as np
from PIL import Image
from scipy import ndimage as nd

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..", "..", "client")
OUT = os.path.join(RADICE, "assets", "diavolo")
LUA = os.path.join(RADICE, "battaglia", "diavolo.lua")
ATLAS = os.path.join(RADICE, "battaglia", "battaglia.atlas")
SORGENTE = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/animazioni_ludo/base"

RES = 0.27          # pixel delle immagini del gioco per pixel della base
# I punti del personaggio, in punti.json accanto ai disegni (pixel delle
# immagini, y verso il basso): cima della testa (senza corna) "testa_y", spalle
# "spalla_davanti" e "spalla_dietro" e "fiammella" nella base; nel foglio delle
# braccia il centro della spalla "braccio_spalla", la presa del pugno
# "braccio_presa" e "braccio_scala", da quel foglio alla base. Così ogni
# personaggio porta i suoi e lo strumento resta lo stesso.
with open(os.path.join(SORGENTE, "punti.json")) as f:
    P = json.load(f)
TESTA_Y = P["testa_y"]
SPALLA_DAVANTI, SPALLA_DIETRO, FIAMMELLA = P["spalla_davanti"], P["spalla_dietro"], P["fiammella"]
BRACCIO_SPALLA, BRACCIO_PRESA, BRACCIO_SCALA = P["braccio_spalla"], P["braccio_presa"], P["braccio_scala"]
SCURO = 0.62            # il braccio dietro è quello davanti più scuro

# Le animazioni: celle per lato del foglio, se si ripete, fotogrammi al secondo
# quando vanno a tempo, primo e ultimo fotogramma da tenere (da 1) e ogni quanti
# prenderne uno. Senza foglio l'animazione non c'è e il gioco usa la guardia.
AZIONI = {
    "guardia": dict(griglia=6, giro=True, fps=12),
    "corsa": dict(griglia=6, giro=True, fps=12),
    "salto": dict(griglia=6, giro=False, fps=12),
    "colpito": dict(griglia=6, giro=False, fps=12),
    "fendente": dict(griglia=6, giro=False, fps=12),
    "lancio": dict(griglia=6, giro=False, fps=12),
    "teletrasporto": dict(griglia=6, giro=False, fps=12),
    "sconfitta": dict(griglia=6, giro=False, fps=12),
    "vittoria": dict(griglia=6, giro=True, fps=12),
    "paracadute": dict(griglia=6, giro=True, fps=12),
}


def apri(path):
    """RGBA in float 0..1; lo sfondo magenta diventa trasparente e i bordi
    perdono la sfumatura magenta."""
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255
    rgb, al = a[..., :3], a[..., 3]
    if al.min() > 0.99:
        r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
        # quanto è magenta: rosso e blu alti, verde basso
        m = np.clip((np.minimum(r, b) - g - 0.35) / 0.3, 0, 1)
        al = 1 - m
    # via il magenta che sfuma nei bordi
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    spill = np.clip(np.minimum(r, b) - g, 0, None) * (al < 0.99)
    rgb = np.stack([r - spill, g, b - spill], -1)
    # via le macchie che toccano il bordo dell'immagine (cornici, rumore)
    lab, _ = nd.label(nd.binary_dilation(al > 0.1, iterations=2))
    bordo = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    al = al * ~np.isin(lab, bordo[bordo > 0]) * (al > 0.1)
    return np.dstack([np.clip(rgb, 0, 1), al])


def piedi(al):
    """Punto fra i piedi: il centro dei pixel pieni nella fascia più bassa."""
    ys, xs = np.nonzero(al > 0.5)
    fondo = ys.max()
    band = ys > fondo - 0.03 * (fondo - ys.min())
    return xs[band].mean(), float(fondo)


def busto(a):
    """Baricentro del rosso della canottiera e dei pantaloni (per le spalle)."""
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    m = (al > 0.5) & (r > 0.55) & (g < 0.4) & (b < 0.35)
    ys, xs = np.nonzero(m)
    return (xs.mean(), ys.mean()) if len(xs) else (0.0, 0.0)


def salva(a, nome):
    """Ritaglia, riduce a RES e salva; ritorna centro e misura in pixel della
    sorgente (y verso il basso)."""
    ys, xs = np.nonzero(a[..., 3] > 0.02)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    c = a[y0:y1, x0:x1]
    # alfa premoltiplicata per ridurre senza aloni scuri o chiari
    pm = np.dstack([c[..., :3] * c[..., 3:], c[..., 3:]])
    img = Image.fromarray((pm * 255).round().astype(np.uint8), "RGBA")
    w, h = max(1, round((x1 - x0) * RES)), max(1, round((y1 - y0) * RES))
    img = np.asarray(img.resize((w, h), Image.LANCZOS)).astype(np.float32) / 255
    al = np.clip(img[..., 3:], 0, 1)
    rgb = np.where(al > 0, img[..., :3] / np.maximum(al, 1e-6), 0)
    out = np.dstack([np.clip(rgb, 0, 1), al])
    Image.fromarray((out * 255).round().astype(np.uint8), "RGBA").save(os.path.join(OUT, nome + ".png"), optimize=True)
    return (x0 + x1) / 2, (y0 + y1) / 2, x1 - x0, y1 - y0


def scala(a, s):
    if s == 1:
        return a
    h, w = a.shape[:2]
    pm = np.dstack([a[..., :3] * a[..., 3:], a[..., 3:]])
    img = Image.fromarray((pm * 255).round().astype(np.uint8), "RGBA").resize((round(w * s), round(h * s)), Image.LANCZOS)
    b = np.asarray(img).astype(np.float32) / 255
    al = b[..., 3:]
    return np.dstack([np.where(al > 0, b[..., :3] / np.maximum(al, 1e-6), 0), al])


def celle(a, n):
    h, w = a.shape[:2]
    return [a[round(r * h / n):round((r + 1) * h / n), round(c * w / n):round((c + 1) * w / n)]
            for r in range(n) for c in range(n)]


def n(v):
    return f"{v:.1f}"


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in glob.glob(os.path.join(OUT, "*.png")):
        os.remove(f)

    base = apri(os.path.join(SORGENTE, "base_senza_braccia.png"))
    fx, fy = piedi(base[..., 3])
    alto = fy - TESTA_Y
    bh = np.ptp(np.nonzero(base[..., 3] > 0.5)[0])
    bx0, by0 = busto(base)

    def gioco(x, y):
        """Dalla base (y in giù) al disegno del gioco (origine fra i piedi, y in su)."""
        return x - fx, fy - y

    righe = ["-- Fatto da strumenti/grafica/diavolo.py, non modificare a mano.",
             "-- Il diavoletto in pixel della base: origine fra i piedi, y verso l'alto.",
             "-- Per ogni fotogramma: immagine, centro (x, y) e misura (w, h); dx, dy",
             "-- è quanto si è spostato il busto rispetto alla base (le spalle lo seguono).",
             "return {",
             f"\taltezza = {n(alto)},  -- dalla cima della testa ai piedi",
             f"\tspalla = {{ {n(gioco(*SPALLA_DAVANTI)[0])}, {n(gioco(*SPALLA_DAVANTI)[1])} }},",
             f"\tspalla_dietro = {{ {n(gioco(*SPALLA_DIETRO)[0])}, {n(gioco(*SPALLA_DIETRO)[1])} }},",
             f"\tfiammella = {{ {n(gioco(*FIAMMELLA)[0])}, {n(gioco(*FIAMMELLA)[1])} }},"]

    # il braccio: la spalla è il perno, il pugno la presa
    br = apri(os.path.join(SORGENTE, "braccia.png"))
    br = br[:br.shape[0] // 2].copy()
    # "braccio_fine", se c'è: oltre questa x il foglio ha solo cose da togliere
    if "braccio_fine" in P:
        br[:, P["braccio_fine"]:, 3] = 0
    br = scala(br, BRACCIO_SCALA)
    cx, cy, w, h = salva(br, "braccio")
    scuro = br.copy()
    scuro[..., :3] *= SCURO
    salva(scuro, "braccio_dietro")
    S = BRACCIO_SCALA
    px, py = BRACCIO_SPALLA[0] * S, BRACCIO_SPALLA[1] * S
    righe.append(f"\tbraccio = {{ w = {n(w)}, h = {n(h)}, x = {n(cx - px)}, y = {n(py - cy)}, "
                 f"presa = {n((BRACCIO_PRESA[0] - BRACCIO_SPALLA[0]) * S)} }},")

    immagini = ["braccio", "braccio_dietro"]
    righe.append("\tanimazioni = {")
    for nome, cfg in AZIONI.items():
        path = os.path.join(SORGENTE, "fogli", nome + ".png")
        if os.path.exists(path):
            fogli = celle(apri(path), cfg["griglia"])
            fogli = [c for c in fogli if c[..., 3].max() > 0.5]
            # allinea il foglio alla base col primo fotogramma
            s = bh / np.ptp(np.nonzero(fogli[0][..., 3] > 0.5)[0])
            fogli = [scala(c, s) for c in fogli]
            px0, py0 = piedi(fogli[0][..., 3])
            ox, oy = fx - px0, fy - py0
            b0 = busto(fogli[0])
            da, a, passo = cfg.get("da", 1), cfg.get("a", len(fogli)), cfg.get("passo", 1)
            # un giro: l'ultimo fotogramma è il primo, non lo ripetiamo
            if cfg["giro"] and a == len(fogli) and len(fogli) > 1:
                a -= 1
            scelti = fogli[da - 1:a:passo]
        elif nome == "guardia":
            scelti, ox, oy, b0 = [base], 0, 0, (bx0, by0)
        else:
            continue
        righe.append(f"\t\t{nome} = {{ fps = {cfg['fps'] / cfg.get('passo', 1):.0f}, giro = {str(cfg['giro']).lower()},")
        for i, c in enumerate(scelti, 1):
            nm = f"{nome}_{i}"
            cx, cy, w, h = salva(c, nm)
            x, y = gioco(cx + ox, cy + oy)
            bx, by = busto(c)
            righe.append(f"\t\t\t{{ img = \"{nm}\", x = {n(x)}, y = {n(y)}, w = {n(w)}, h = {n(h)}, "
                         f"dx = {n(bx - b0[0])}, dy = {n(b0[1] - by)} }},")
            immagini.append(nm)
        righe.append("\t\t},")
    righe += ["\t},", "}", ""]
    with open(LUA, "w") as f:
        f.write("\n".join(righe))

    # l'elenco delle immagini del diavoletto nell'atlas, dopo le altre
    with open(ATLAS) as f:
        testo = re.sub(r'images \{\n  image: "/assets/diavolo/[^"]+"\n\}\n', "", f.read())
    fine = testo.rindex("images {")
    fine = testo.index("}\n", fine) + 2
    nuovi = "".join(f'images {{\n  image: "/assets/diavolo/{nm}.png"\n}}\n' for nm in immagini)
    with open(ATLAS, "w") as f:
        f.write(testo[:fine] + nuovi + testo[fine:])
    print(f"{len(immagini)} immagini, altezza {alto:.0f} px della base")


if __name__ == "__main__":
    main()
