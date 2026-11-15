#!/usr/bin/env python3
"""Le palpebre dell'apprendista per il battito degli occhi (WB-040).

Codex ha ridisegnato il foglio delle nove teste senza corna (R1 di WB-040) con
gli occhi socchiusi e chiusi. Il foglio non è identico al pixel, quindi non si
prende la testa intera: si prende solo la zona degli occhi, ricalcata in
vettoriale e messa sulla testa del gioco, e diventa un pezzo che il gioco
disegna sopra la testa (sotto l'elmo) durante il battito (battle/scoria.lua).

Per ogni faccia con gli occhi aperti:
1. si trova come sta la testa di R1 sulla testa del gioco (scala e posizione con
   la minima differenza di colore), e come sta la testa di Codex su quella di R1
   (fuori dagli occhi);
2. la zona degli occhi è il giallo degli occhi della testa del gioco, riempito e
   allargato di un po' più del contorno;
3. la testa di Codex si ricalca in SVG coi colori della tavolozza (vettoriale.py)
   e si disegna già alla misura del gioco: il PNG non è mai ingrandito;
4. si tiene solo la zona degli occhi, sfumata ai bordi, ritagliata.

  python3 tools/stampino/palpebre.py [--socchiusi FOGLIO] [--chiusi FOGLIO] [--prova CARTELLA]

Scrive client/assets/skins/palpebre_<immagine della testa>_<stato>.png e
client/battle/eyelids.lua (dove sta ogni palpebra, in frazioni dell'immagine
della testa: se l'editor sposta o ingrandisce la testa, la palpebra la segue).
Poi `python3 tools/stampino/taglia.py --rifai` mette i PNG nell'atlante.
--prova scrive anche i confronti (testa, testa con le palpebre) in CARTELLA.
"""
import argparse
import io
import os
import re
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
import vettoriale as VT  # noqa: E402

RADICE = os.path.dirname(os.path.dirname(QUI))
ART = os.path.join(RADICE, "art", "WB-040")
R1 = os.path.join(ART, "riferimenti", "R1_teste_senza_corna.png")
ASSETS = os.path.join(RADICE, "client", "assets", "skins")
LUA = os.path.join(RADICE, "client", "battle", "eyelids.lua")
TAVOLOZZA = os.path.join(QUI, "tavolozze", "apprendista.json")
PELLE = "apprendista_nuovo"
# le nove teste del foglio, da sinistra e dall'alto (come taglia.py --teste)
FACCE = ["testa", "testa_colpita", "testa_felice", "testa_ko", "testa_mira", "testa_arrabbiata",
         "testa_sconfitta", "testa_paura", "testa_provocazione"]
# quelle con gli occhi aperti (colpita e felice li hanno strizzati, ko a spirale)
APERTI = ["testa", "testa_mira", "testa_arrabbiata", "testa_sconfitta", "testa_paura", "testa_provocazione"]
STATI = {"socchiusi": "occhi_socchiusi_1.png", "chiusi": "occhi_chiusi_1.png"}
INGRANDE = 4        # la testa del foglio si ingrandisce così prima del ricalco (come il foglio a 3072)
ALLARGA = 0.024     # quanto si allarga la zona degli occhi oltre il giallo (della larghezza della testa)
PICCOLO = 0.015     # un occhio è piccolo sotto questa parte della testa
PICCOLO_IN_PIU = 0.015
SFUMA = 0.004       # quanto è sfumato il bordo della zona


def teste(percorso):
    """Le nove teste del foglio: (RGB, maschera) di ognuna, nell'ordine di FACCE."""
    a = np.asarray(Image.open(percorso).convert("RGB").resize((1024, 1024), Image.LANCZOS)).astype(np.float32)
    fondo = (a[..., 0] > 190) & (a[..., 1] < 100) & (a[..., 2] > 190)
    dentro = ndimage.binary_opening(~fondo, iterations=1)
    cc, n = ndimage.label(dentro)
    aree = ndimage.sum(dentro, cc, range(1, n + 1))
    scelte = np.argsort(-aree)[:len(FACCE)] + 1
    scatole = ndimage.find_objects(cc)
    out = []
    for k in scelte:
        sl = scatole[k - 1]
        y0, y1, x0, x1 = sl[0].start - 4, sl[0].stop + 4, sl[1].start - 4, sl[1].stop + 4
        m = ndimage.binary_fill_holes(cc[y0:y1, x0:x1] == k)
        out.append(((y0 + y1) / 2, x0, a[y0:y1, x0:x1], m))
    out.sort(key=lambda t: (int(t[0] // 341), t[1]))
    return [(rgb, m) for _, _, rgb, m in out]


def sposta(img, s, dx, dy, forma):
    """img vista con scala s e spostata di (dx, dy): il pixel (y, x) di uscita
    prende quello in ((y - dy) / s, (x - dx) / s)."""
    out = []
    canali = img[..., None] if img.ndim == 2 else img
    for c in range(canali.shape[2]):
        out.append(ndimage.affine_transform(canali[..., c], [1 / s, 1 / s], [-dy / s, -dx / s],
                                            output_shape=forma, order=1, cval=255.0 if img.ndim == 3 else 0.0))
    return np.stack(out, -1) if img.ndim == 3 else out[0]


def registra(src, src_m, dst, dst_m, s0, d0, fuori=None, passi=((0.03, 4.0), (0.008, 1.0), (0.002, 0.25))):
    """Scala e spostamento che mettono src su dst con la minima differenza di
    colore (dentro la sagoma di dst, fuori dalla maschera fuori), da grossolana a fine."""
    peso = dst_m.astype(np.float32)
    if fuori is not None:
        peso[fuori] = 0
    best = (s0, d0[0], d0[1])
    for ds, dd in passi:
        s_, x_, y_ = best
        err_best = None
        for s in np.linspace(s_ - ds, s_ + ds, 5):
            for dx in np.linspace(x_ - dd, x_ + dd, 5):
                for dy in np.linspace(y_ - dd, y_ + dd, 5):
                    w = sposta(src, s, dx, dy, dst.shape[:2])
                    wm = sposta(src_m.astype(np.float32), s, dx, dy, dst.shape[:2])
                    err = ((np.abs(w - dst).mean(-1)) * peso).sum() / peso.sum() + 60 * np.abs(wm - dst_m).mean()
                    if err_best is None or err < err_best:
                        err_best, best = err, (s, dx, dy)
    return best


def occhi(g):
    """La zona degli occhi della testa del gioco (RGBA): il giallo, riempito
    (pupille e luci dentro) e allargato oltre il contorno."""
    r, gg, b = g[..., 0].astype(np.float32), g[..., 1].astype(np.float32), g[..., 2].astype(np.float32)
    gial = (g[..., 3] > 128) & VT.giallo(r, gg, b)
    cc, n = ndimage.label(gial)
    if not n:
        return None
    area = ndimage.sum(gial, cc, range(1, n + 1))
    gial = np.isin(cc, np.nonzero(area >= 0.0001 * gial.size)[0] + 1)
    largo = g.shape[1]
    # le pupille (nere, con la luce bianca) arrivano fin sul contorno: ogni occhio
    # è l'involucro convesso del suo giallo, che le comprende
    from PIL import ImageDraw
    from scipy.spatial import ConvexHull
    # con la luce bianca della pupilla, che negli occhi stretti esce dal giallo
    vicino = ndimage.binary_dilation(gial, iterations=max(1, round(0.02 * largo)))
    luce = (g[..., 3] > 128) & (r > 235) & (gg > 235) & (b > 235) & vicino
    # e il suo bordo chiaro (la luce sfuma nel crema)
    luce |= ((g[..., 3] > 128) & (r > 170) & (gg > 150) & (b > 100)
             & ndimage.binary_dilation(luce, iterations=max(1, round(0.015 * largo))))
    cc, n = ndimage.label(ndimage.binary_dilation(gial | luce, iterations=max(1, round(0.01 * largo))))
    cc = np.where(gial | luce, cc, 0)
    z = np.zeros(gial.shape, bool)
    for k in range(1, n + 1):
        ys, xs = np.nonzero(cc == k)
        pts = np.stack([xs, ys], 1)
        if len(pts) < 3:
            continue
        tela = Image.new("1", (largo, g.shape[0]), 0)
        h = ConvexHull(pts)
        ImageDraw.Draw(tela).polygon([tuple(map(float, pts[v])) for v in h.vertices], fill=1)
        m = np.asarray(tela) | (cc == k)
        # negli occhi piccoli (stretti, di lato) la pupilla esce di più dal giallo
        r_ = ALLARGA + (PICCOLO_IN_PIU if m.sum() < PICCOLO * m.size else 0)
        z |= ndimage.distance_transform_edt(~m) <= r_ * largo
    return z


def ricalca(rgb, m, tav, misura):
    """La testa del foglio (RGB e sagoma) in SVG coi colori della tavolozza, alla misura in pixel."""
    a = np.concatenate([rgb, (m * 255.0)[..., None]], -1)
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    im = im.resize((im.width * INGRANDE, im.height * INGRANDE), Image.LANCZOS)
    big = np.asarray(im).astype(np.float32)
    base, _ = VT.svg_pezzo(big, tav, misura)
    return base


def disegna(svg, larghezza, altezza, s, dx, dy, w_src, h_src):
    """L'SVG della testa del foglio (w_src x h_src px del foglio) disegnato sulla
    tela della testa del gioco con scala s e spostamento (dx, dy)."""
    import cairosvg
    interno = re.sub(r'<svg([^>]*) width="\d+" height="\d+"',
                     f'<svg\\1 x="{dx:.3f}" y="{dy:.3f}" width="{w_src * s:.3f}" height="{h_src * s:.3f}"', svg, count=1)
    fuori = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{larghezza}" height="{altezza}" '
             f'viewBox="0 0 {larghezza} {altezza}">\n{interno}</svg>\n')
    png = cairosvg.svg2png(bytestring=fuori.encode(), output_width=larghezza, output_height=altezza)
    return np.asarray(Image.open(io.BytesIO(png)).convert("RGBA")).astype(np.float32)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--socchiusi", default=os.path.join(ART, STATI["socchiusi"]))
    ap.add_argument("--chiusi", default=os.path.join(ART, STATI["chiusi"]))
    ap.add_argument("--prova")
    a = ap.parse_args()
    tav = VT.leggi_tavolozza(TAVOLOZZA)
    rif = teste(R1)
    fogli = {"socchiusi": teste(a.socchiusi), "chiusi": teste(a.chiusi)}
    righe = {}
    for f in APERTI:
        i = FACCE.index(f)
        nome = f"{PELLE}_{f}_1"
        g = np.asarray(Image.open(os.path.join(ASSETS, nome + ".png")).convert("RGBA")).astype(np.float32)
        H, W = g.shape[:2]
        zona = occhi(g.astype(np.uint8))
        if zona is None:
            sys.exit(f"{nome}: niente occhi gialli")
        # R1 sulla testa del gioco, a una misura piccola (la testa del gioco rimpicciolita)
        r_rgb, r_m = rif[i]
        ys, xs = np.nonzero(g[..., 3] > 128)
        s0 = (xs.max() - xs.min() + 1) / (np.ptp(np.nonzero(r_m.any(0))[0]) + 1)
        k = 1 / s0 * 2           # la testa del gioco al doppio di quella del foglio
        gp = Image.fromarray(g.astype(np.uint8)).resize((round(W * k), round(H * k)), Image.LANCZOS)
        gp = np.asarray(gp).astype(np.float32)
        gp_rgb = gp[..., :3] * (gp[..., 3:] / 255) + 255 * (1 - gp[..., 3:] / 255)
        gp_m = gp[..., 3] > 128
        rx0, ry0 = np.nonzero(r_m.any(0))[0].min(), np.nonzero(r_m.any(1))[0].min()
        d0 = (xs.min() * k - rx0 * 2, ys.min() * k - ry0 * 2)
        r_bianco = np.where(r_m[..., None], r_rgb, 255.0)
        s1, dx1, dy1 = registra(r_bianco, r_m, gp_rgb, gp_m, 2.0, d0)
        # da foglio a gioco
        S, DX, DY = s1 / k, dx1 / k, dy1 / k
        for stato, fs in fogli.items():
            v_rgb, v_m = fs[i]
            v_bianco = np.where(v_m[..., None], v_rgb, 255.0)
            # la testa di Codex su R1, fuori dagli occhi (che sono cambiati)
            zona_r = sposta(zona.astype(np.float32), 1 / S, -DX / S, -DY / S, r_m.shape) > 0.5
            vy0 = (v_m.shape[0] - r_m.shape[0]) / 2
            vx0 = (v_m.shape[1] - r_m.shape[1]) / 2
            s2, dx2, dy2 = registra(v_bianco, v_m, r_bianco, r_m, 1.0, (-vx0, -vy0), fuori=zona_r)
            # da Codex a gioco: prima su R1, poi R1 sul gioco
            s, dx, dy = s2 * S, dx2 * S + DX, dy2 * S + DY
            svg = ricalca(v_rgb, v_m, tav, (round(v_m.shape[1] * s), round(v_m.shape[0] * s)))
            tela = disegna(svg, W, H, s, dx, dy, v_m.shape[1], v_m.shape[0])
            # solo la zona degli occhi, sfumata, dentro la sagoma della testa
            alfa = ndimage.gaussian_filter(zona.astype(np.float32), SFUMA * W)
            alfa = np.minimum(alfa * 2, 1) * (g[..., 3] / 255)
            tela[..., 3] = tela[..., 3] * alfa
            ys2, xs2 = np.nonzero(tela[..., 3] > 2)
            x0, x1, y0, y1 = xs2.min(), xs2.max() + 1, ys2.min(), ys2.max() + 1
            pezzo = Image.fromarray(np.clip(tela[y0:y1, x0:x1], 0, 255).astype(np.uint8), "RGBA")
            img = f"palpebre_{nome}_{stato}"
            pezzo.save(os.path.join(ASSETS, img + ".png"), optimize=True)
            righe.setdefault(nome, {})[stato] = (img, (x0 + x1) / 2 / W, (y0 + y1) / 2 / H, (x1 - x0) / W, (y1 - y0) / H)
            print(f"{nome} {stato}: scala {s:.3f}, {x1 - x0}x{y1 - y0} px")
            if a.prova:
                os.makedirs(a.prova, exist_ok=True)
                sopra = Image.fromarray(g.astype(np.uint8), "RGBA")
                sopra.alpha_composite(pezzo, (int(x0), int(y0)))
                fianco = Image.new("RGBA", (W * 2, H), (255, 255, 255, 255))
                fianco.alpha_composite(Image.fromarray(g.astype(np.uint8), "RGBA"), (0, 0))
                fianco.alpha_composite(sopra, (W, 0))
                fianco.convert("RGB").resize((W // 2, H // 4)).save(os.path.join(a.prova, f"{f}_{stato}.png"))
    lua = ["-- Made by tools/stampino/palpebre.py, do not edit by hand.",
           "-- The eyelids for the blink (WB-040), per head image: half shut and shut,",
           "-- drawn over the head and under the helmet. Center and size are fractions",
           "-- of the head image (x from the left, y from the top), so they follow the",
           "-- head wherever the skin or the editor puts it.",
           "return {"]
    for nome in sorted(righe):
        parti = []
        for stato, chiave in (("socchiusi", "half"), ("chiusi", "shut")):
            img, cx, cy, w, h = righe[nome][stato]
            parti.append(f'{chiave} = {{ img = "{img}", x = {cx:.4f}, y = {cy:.4f}, w = {w:.4f}, h = {h:.4f} }}')
        lua.append(f"\t{nome} = {{ {', '.join(parti)} }},")
    lua.append("}")
    with open(LUA, "w") as fh:
        fh.write("\n".join(lua) + "\n")
    print("OK:", os.path.relpath(LUA, RADICE))


if __name__ == "__main__":
    main()
