#!/usr/bin/env python3
"""Mette addosso all'apprendista i pezzi di una famiglia disegnati da Codex sui
suoi fogli (WB-041, WB-042, WB-055): cuffia o cappuccio sulle teste, corazza,
spalline e stivali sul foglio del corpo, spalline sulle braccia col pugno.

Niente a occhio: ogni pezzo del gioco (`client/assets/skins/apprendista_nuovo_*.png`)
si confronta con la sua sagoma sul foglio di riferimento (quello senza i pezzi) e
si cercano scala e spostamento che le sovrappongono meglio. Il pezzo nuovo passa
dalla stessa trasformazione. Si disegna dall'SVG ricalcato, alla misura che serve,
e si rimpicciolisce soltanto: mai ingrandito.

  python3 tools/stampino/addosso.py tools/stampino/addosso/vuoto.json
  python3 tools/stampino/addosso.py tools/stampino/addosso/vuoto.json --prova CARTELLA

Scrive le immagini in `client/assets/skins/` e le pelli in `tools/stampino/pelli/`
(con --prova tutto nella cartella, senza toccare il gioco, più `anteprima.png`).
Poi: `python3 tools/stampino/taglia.py --rifai`. Il mantello non passa di qui: si
taglia con `taglia.py --mantello-px` (README).

La ricetta della famiglia (JSON, percorsi dalla radice del repository):

  { "tavolozza": "tools/stampino/tavolozze/apprendista_vuoto.json",
    "colori": ["#2B2147", "#1A1430", "#00FFFF"],        i colori del pezzo
    "senza_corpo": ["lingua", "bocca", "corna", "corna_ombra", "occhi"],   colori che il corpo non ha
    "senza_teste": [],                                  e quelli che non hanno le teste
    "riferimenti": { "teste": FOGLIO, "corpo": FOGLIO, "pugni": FOGLIO },
    "pelli": { "elmo": "cappuccio_vuoto", "corazza": "corazza_vuoto", "stivali": "stivali_vuoto" },
    "forme": { "": { "teste": FOGLIO, "corpo": FOGLIO, "pugni": FOGLIO },
               "_forgiato": { ... } } }

Serve potrace, cairosvg e scipy (come vettoriale.py).
"""
import io
import json
import os
import re
import sys

import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.signal import fftconvolve

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(os.path.dirname(QUI))
sys.path.insert(0, QUI)
import taglia as TG          # noqa: E402
import vettoriale as VT      # noqa: E402

PELLI = os.path.join(RADICE, "client", "assets", "skins")
BASE = "apprendista_nuovo"
# la pelle dell'apprendista: non fa mai parte di un pezzo messo sopra
PELLE = np.array([[0xB8, 0x43, 0x2A], [0x8E, 0x2F, 0x1C]])
# pezzo del gioco -> (foglio, categoria della pelle, modo, nome nell'immagine)
PEZZI = [
    ("testa_1", "teste", "elmo", "sopra", "testa"),
    ("busto_1", "corpo", "corazza", "sostituisce", "busto"),
    ("braccio_1", "corpo", "corazza", "sopra", "spallina_braccio_1"),
    ("braccio_dietro_1", "corpo", "corazza", "sopra", "spallina_braccio_dietro_1"),
    ("braccio_2", "pugni", "corazza", "sopra", "spallina_braccio_2"),
    ("braccio_dietro_2", "pugni", "corazza", "sopra", "spallina_braccio_dietro_2"),
    ("gamba_1", "corpo", "stivali", "sostituisce", "gamba"),
    ("gamba_dietro_1", "corpo", "stivali", "sostituisce", "gamba_dietro"),
]


def non_magenta(a):
    return ~((a[..., 0] > 170) & (a[..., 1] < 100) & (a[..., 2] > 170))


def vicino(v, colori, soglia):
    return np.sqrt(((v[..., None, :] - colori[None, None]) ** 2).sum(-1)).min(-1) < soglia


def grandi(m, area):
    lab, n = ndimage.label(m)
    if n:
        a = ndimage.sum(m, lab, range(1, n + 1))
        m = np.isin(lab, np.nonzero(a >= area)[0] + 1)
    return m


def _prova_scale(rm, g, scale):
    gs = g.sum()
    H, W = g.shape
    meglio = None
    for s in scale:
        w, h = max(1, round(rm.shape[1] * s)), max(1, round(rm.shape[0] * s))
        r = (np.asarray(Image.fromarray(rm).resize((w, h), Image.BILINEAR)) > 128).astype(np.float32)
        largo = np.zeros((H + 2 * h, W + 2 * w), np.float32)
        largo[h:h + H, w:w + W] = g
        dentro = fftconvolve(largo, r[::-1, ::-1], mode="valid")
        iou = dentro / (r.sum() + gs - dentro)
        k = np.unravel_index(np.argmax(iou), iou.shape)
        if meglio is None or iou[k] > meglio[0]:
            meglio = (float(iou[k]), float(s), k[1] - w, k[0] - h)
    return meglio


def sovrapponi(sagoma, alfa):
    """Scala e spostamento che portano la sagoma del foglio sul pezzo del gioco
    (pixel del gioco = s * pixel del foglio + o), con la sovrapposizione migliore
    (intersezione su unione). Prima in piccolo su tante scale, poi alla misura vera
    intorno alla migliore."""
    ys, xs = np.nonzero(sagoma)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    rm = sagoma[y0:y1, x0:x1].astype(np.uint8) * 255
    ya = np.nonzero(alfa.any(1))[0]
    s0 = (ya.max() - ya.min() + 1) / (y1 - y0)
    q = max(1, int(np.ceil(max(alfa.shape) / 320)))       # in piccolo: lato fino a 320
    piccolo = np.asarray(Image.fromarray(alfa).resize((alfa.shape[1] // q, alfa.shape[0] // q), Image.BILINEAR))
    _, s, _, _ = _prova_scale(rm, piccolo.astype(np.float32), np.arange(s0 * 0.85, s0 * 1.15, s0 * 0.01) / q)
    s *= q
    iou, s, ox, oy = _prova_scale(rm, alfa.astype(np.float32), np.arange(s * 0.985, s * 1.0151, s * 0.0025))
    return iou, s, ox - s * x0, oy - s * y0


def disegna(svg, x0, y0, x1, y1, k):
    """Il rettangolo del foglio (pixel del foglio largo LATO) dall'SVG, k volte più grande."""
    w, h = x1 - x0, y1 - y0
    testa = re.search(r'<svg[^>]*>', svg).group(0)
    nuova = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{round(w * k)}" height="{round(h * k)}" '
             f'viewBox="{2 * x0} {2 * y0} {2 * w} {2 * h}">')
    import cairosvg
    png = cairosvg.svg2png(bytestring=svg.replace(testa, nuova, 1).encode())
    return np.asarray(Image.open(io.BytesIO(png)).convert("RGBA")).astype(np.float32)


def solo_pezzo(v, colori, k, cambiato, diverso):
    """Di un disegno resta solo il pezzo: i suoi colori dove il foglio è cambiato,
    i buchi chiusi (tranne il più grande, l'apertura del viso) e il contorno nero intorno."""
    vv = v[..., :3].astype(np.int32)
    pieno = v[..., 3] > 0
    # il foglio ricalcato ha i colori esatti della tavolozza: soglia stretta, perché
    # un cuoio può stare vicino all'ombra della pelle
    g = vicino(vv, colori, 14) & pieno & cambiato
    # una macchia dei colori del pezzo che sul riferimento era già quasi di quel colore
    # (un occhio ridisegnato, giallo come le lenti) non è del pezzo
    lab, n = ndimage.label(g)
    if n:
        nuovo = ndimage.mean(diverso, lab, range(1, n + 1))
        g &= ~np.isin(lab, np.nonzero(nuovo < 0.5)[0] + 1)
    # restano le macchie grandi e quelle piccole che stanno loro attaccate (una
    # borchia dentro il suo contorno), non i granelli lontani
    lab, n = ndimage.label(g)
    if n:
        vicine = ndimage.binary_dilation(grandi(g, int(1500 * k * k)), iterations=max(1, round(16 * k)))
        g = np.isin(lab, np.unique(lab[vicine & g]))
    g = ndimage.binary_closing(g, iterations=max(1, round(4 * k)))
    buchi = ndimage.binary_fill_holes(g) & ~g
    lab, n = ndimage.label(buchi)
    dentro = np.zeros_like(g)
    if n:
        aree = ndimage.sum(buchi, lab, range(1, n + 1))
        # un buco grande come una faccia resta aperto, gli altri (un emblema) si chiudono
        chiusi = np.nonzero((aree < aree.max()) | (aree < 0.15 * g.sum()))[0] + 1
        dentro = np.isin(lab, chiusi)
        g |= dentro
    intorno = ndimage.binary_dilation(g, iterations=max(1, round(16 * k)))
    return intorno & (~vicino(vv, PELLE, 14) | dentro) & pieno


def posa(sopra, s, ox, oy, forma):
    """Il disegno passa dalla trasformazione del pezzo e si ritaglia sul suo bordo.
    Dice anche di quanto il centro del ritaglio sta dal centro del pezzo del gioco."""
    assert s <= 1.001, f"il pezzo verrebbe ingrandito ({s:.2f})"
    H0, W0 = forma
    px, py = W0 // 2, H0 // 2
    W, H = W0 + 2 * px, H0 + 2 * py
    ox, oy = ox + px, oy + py
    mg = int(max(W, H) / s) + 16
    o = np.pad(sopra, ((mg, mg), (mg, mg), (0, 0)))
    o[..., :3] *= o[..., 3:] / 255.0
    box = (-ox / s + mg, -oy / s + mg, (W - ox) / s + mg, (H - oy) / s + mg)
    ch = [np.asarray(Image.fromarray(np.clip(o[..., c], 0, 255).astype(np.uint8))
                     .resize((W, H), Image.LANCZOS, box=box)).astype(np.float32) for c in range(4)]
    out = np.stack(ch, -1)
    al = out[..., 3:] / 255.0
    out[..., :3] = np.where(al > 0.003, out[..., :3] / np.maximum(al, 1e-3), 0)
    ys, xs = np.nonzero(out[..., 3] > 2)
    x0, x1, y0, y1 = xs.min() - 2, xs.max() + 3, ys.min() - 2, ys.max() + 3
    assert x0 >= 0 and y0 >= 0 and x1 <= W and y1 <= H, "il pezzo esce dal foglio di lavoro"
    out = out[y0:y1, x0:x1]
    dove = dict(dcx=(x0 + x1) / 2 - (px + W0 / 2), dcy=(y0 + y1) / 2 - (py + H0 / 2),
                W0=W0, H0=H0, Wn=int(x1 - x0), Hn=int(y1 - y0))
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA"), dove


class Foglio:
    """Un foglio consegnato: ricalcato in SVG, col suo riferimento alla stessa misura."""

    def __init__(self, foglio, riferimento, tavolozza, senza, lavoro):
        nome = os.path.splitext(os.path.basename(foglio))[0]
        self.svg_f = os.path.join(lavoro, nome + ".svg")
        png = os.path.join(lavoro, nome + ".png")
        if not os.path.exists(self.svg_f) or os.path.getmtime(self.svg_f) < os.path.getmtime(foglio):
            # il fondo è il magenta, anche se il file ha un canale alfa (un foglio
            # rimpicciolito da Codex): senza, il ricalco prende il fondo per un colore
            piatto = os.path.join(lavoro, nome + "_foglio.png")
            Image.open(foglio).convert("RGB").save(piatto)
            VT.main_colori(tavolozza, piatto, self.svg_f, png, senza=tuple(senza))
        self.svg = open(self.svg_f).read()
        self.v = TG.fondo_via(Image.open(png))
        h, w = self.v.shape[:2]
        rif = Image.open(riferimento).convert("RGB")
        r = np.asarray(rif.resize((w, h), Image.NEAREST)).astype(np.int32)
        lab, n = ndimage.label(non_magenta(r))
        self.sagome = [lab == i for i in range(1, n + 1) if (lab == i).sum() > 20000]
        self.pezzi, _ = ndimage.label(self.v[..., 3] > 20)
        # dove il foglio consegnato è diverso dal riferimento (alla misura del riferimento)
        nuovo = np.asarray(Image.open(foglio).convert("RGB").resize(rif.size, Image.LANCZOS)).astype(np.int32)
        d = np.sqrt(((nuovo - np.asarray(rif).astype(np.int32)) ** 2).sum(-1)) > 48   # un cuoio sulla pelle cambia poco; un occhio ridisegnato ancora meno
        # pixel per pixel, senza allargare: per dire se una macchia è nuova davvero
        self.diverso = np.asarray(Image.fromarray(d).resize((w, h), Image.NEAREST))
        d = ndimage.binary_dilation(grandi(ndimage.binary_opening(d), 100), iterations=6)
        self.cambiato = np.asarray(Image.fromarray(d).resize((w, h), Image.NEAREST))


def taglia_pezzo(f, posto, modo, colori, prese):
    """Il pezzo del foglio che veste `posto`: immagine pronta e dove va."""
    G = np.asarray(Image.open(os.path.join(PELLI, f"{BASE}_{posto}.png")))
    alfa = G[..., 3] > 128
    forma_g = G.shape[0] / G.shape[1]
    meglio = None
    for i, c in enumerate(f.sagome):
        if (id(f), i) in prese:
            continue
        ys, xs = np.nonzero(c)
        h, w = ys.max() - ys.min() + 1, xs.max() - xs.min() + 1
        if not 0.6 < (h / w) / forma_g < 1.7:      # tutt'altra forma: non è lui
            continue
        r = sovrapponi(c, alfa)
        if meglio is None or r[0] > meglio[0][0]:
            meglio = (r, i)
    assert meglio, f"{posto}: nessuna sagoma del riferimento gli somiglia"
    (iou, s, ox, oy), i = meglio
    # il busto del gioco ha anche il fazzoletto, che sul foglio è un pezzo a parte
    soglia = 0.75 if posto.startswith("busto") else 0.93
    assert iou > soglia, f"{posto}: la sagoma migliore combacia solo al {iou:.2f}"
    prese.add((id(f), i))
    # i pezzi del disegno consegnato che toccano quella sagoma
    ids = np.unique(f.pezzi[ndimage.binary_dilation(f.sagome[i], iterations=5)])
    zona = np.isin(f.pezzi, ids[ids > 0])
    ys, xs = np.nonzero(zona)
    m = 24
    x0, y0 = max(0, xs.min() - m), max(0, ys.min() - m)
    x1, y1 = min(zona.shape[1], xs.max() + m), min(zona.shape[0], ys.max() + m)
    k = max(1.0, np.ceil(s * 1.15 * 2) / 2)        # mai ingrandito: si disegna più grande
    v = disegna(f.svg, x0, y0, x1, y1, k)
    hk, wk = v.shape[:2]

    def grande(mask):
        return np.asarray(Image.fromarray(mask[y0:y1, x0:x1]).resize((wk, hk), Image.NEAREST))
    tiene = grande(zona).copy()
    if modo == "sopra":
        tiene &= solo_pezzo(v, colori, k, grande(f.cambiato), grande(f.diverso))
    v[~tiene, 3] = 0
    assert (v[..., 3] > 128).sum() > 400 * k * k, f"{posto}: sul foglio non c'è nessun pezzo nuovo"
    im, dove = posa(v, s / k, s * x0 + ox, s * y0 + oy, G.shape[:2])
    print(f"  {posto}: combacia al {iou:.3f}, scala {s:.2f} (disegnato a {k:g}), {im.width}x{im.height}")
    return im, dove


def voce(img, dove, b, modo):
    ux, uy = b["w"] / dove["W0"], b["h"] / dove["H0"]
    return {"img": img, "x": round(b["x"] + dove["dcx"] * ux, 1), "y": round(b["y"] - dove["dcy"] * uy, 1),
            "w": round(dove["Wn"] * ux, 1), "h": round(dove["Hn"] * uy, 1), "modo": modo}


def anteprima(righe, uscita):
    """I pezzi nuovi sopra quelli del gioco, una riga per forma: per guardarli prima di montarli."""
    tessere = []
    for riga in righe:
        t = []
        for posto, im, dove, modo in riga:
            g = Image.open(os.path.join(PELLI, f"{BASE}_{posto}.png")).convert("RGBA")
            p = max(g.size) // 3
            c = Image.new("RGBA", (g.width + 2 * p, g.height + 2 * p), (200, 200, 200, 255))
            if modo == "sopra":
                c.alpha_composite(g, (p, p))
            c.alpha_composite(im, (round(p + g.width / 2 + dove["dcx"] - im.width / 2),
                                   round(p + g.height / 2 + dove["dcy"] - im.height / 2)))
            c = c.convert("RGB")
            c.thumbnail((420, 420))
            t.append(c)
        tessere.append(t)
    W = max(sum(c.width for c in t) for t in tessere)
    H = max(c.height for t in tessere for c in t)
    out = Image.new("RGB", (W, H * len(tessere)), "white")
    for j, t in enumerate(tessere):
        x = 0
        for c in t:
            out.paste(c, (x, j * H))
            x += c.width
    out.save(uscita)


def main():
    args = sys.argv[1:]
    prova = None
    if "--prova" in args:
        i = args.index("--prova")
        prova = args[i + 1]
        del args[i:i + 2]
    if len(args) != 1:
        sys.exit(__doc__)
    ric = json.load(open(args[0]))
    famiglia = os.path.splitext(os.path.basename(args[0]))[0]

    def qui(p):
        return os.path.join(RADICE, p)
    lavoro = os.path.join(RADICE, "simulazione", "addosso", famiglia)
    os.makedirs(lavoro, exist_ok=True)
    dir_img = prova or PELLI
    dir_pelli = prova or os.path.join(QUI, "pelli")
    os.makedirs(dir_img, exist_ok=True)
    colori = np.array([[int(c[i:i + 2], 16) for i in (1, 3, 5)] for c in ric["colori"]])
    base = json.load(open(os.path.join(QUI, "pelli", BASE + ".json")))["pezzi"]
    righe = []
    for suffisso, fogli in ric["forme"].items():
        print(f"{famiglia}{suffisso}:")
        aperti, prese, pelli, riga = {}, set(), {}, []
        for posto, quale, categoria, modo, nome in PEZZI:
            if quale not in fogli or categoria not in ric["pelli"]:
                continue
            if quale not in aperti:
                senza = ric.get("senza_teste" if quale == "teste" else "senza_corpo", [])
                aperti[quale] = Foglio(qui(fogli[quale]), qui(ric["riferimenti"][quale]),
                                       qui(ric["tavolozza"]), senza, lavoro)
            im, dove = taglia_pezzo(aperti[quale], posto, modo, colori, prese)
            pelle = ric["pelli"][categoria] + suffisso
            img = f"{pelle}_{nome}"
            im.save(os.path.join(dir_img, img + ".png"))
            riga.append((posto, im, dove, modo))
            voci = pelli.setdefault(pelle, {"nome": pelle, "categoria": categoria, "pezzi": {}})["pezzi"]
            # un elmo sta sopra tutte le espressioni; gli altri sui posti che usano quell'immagine
            for chiave, b in base.items():
                if chiave.startswith("testa") if posto == "testa_1" else b["img"] == f"{BASE}_{posto}":
                    voci[chiave] = voce(img, dove, b, modo)
        for pelle, dati in pelli.items():
            with open(os.path.join(dir_pelli, pelle + ".json"), "w") as f:
                json.dump(dati, f, indent=1, ensure_ascii=False)
        righe.append(riga)
    if prova:
        anteprima(righe, os.path.join(prova, "anteprima.png"))
        print("OK: prova in", prova, "(guarda anteprima.png)")
    else:
        print("OK: ora python3 tools/stampino/taglia.py --rifai")


if __name__ == "__main__":
    main()
