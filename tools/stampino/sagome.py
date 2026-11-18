#!/usr/bin/env python3
"""Le sagome dei pezzi dell'equipaggiamento, per il contorno acceso nei menu.

Nello zaino e nell'armeria ogni posto (elmo con le corna, corazza con le spalline,
i due stivali, i guanti) ha un solo contorno esterno acceso (client/menu/outline.lua).
Per farlo il gioco deve sapere dove sta il pezzo e dove no:

  - uno stivale e una corazza sono disegnati insieme alla gamba e al busto (pezzi
    "replace"): la sagoma è il disegno senza la pelle, col tratto nero dell'orlo;
  - un pezzo con un buco dentro (un cappuccio aperto) lo ha chiuso: il contorno
    è solo quello di fuori.

Per gli altri pezzi la sagoma è il disegno stesso e qui non si scrive niente.

  python3 tools/stampino/sagome.py            # rifà client/assets/sagome e l'atlante
  python3 tools/stampino/sagome.py --prova DIR  # in più le sagome sopra i disegni, da guardare

Va rilanciato dopo addosso.py o taglia.py quando cambiano i pezzi delle pelli
(tools/controlli lo controlla: le sagome devono essere in pari).
"""
import argparse
import os
import re
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(os.path.dirname(QUI))
PELLI = os.path.join(RADICE, "client", "assets", "skins")
SAGOME = os.path.join(RADICE, "client", "assets", "sagome")
LUA = os.path.join(RADICE, "client", "battle", "skins.lua")
ATLANTE = os.path.join(RADICE, "client", "battle", "outlines.atlas")
ELENCO = os.path.join(RADICE, "client", "battle", "outlines.lua")

# le categorie che hanno un posto nell'equipaggiamento
CATEGORIE = ("elmo", "corna", "corazza", "stivali", "guanti")
# la pelle dell'apprendista: rosso, la sua ombra, il crema della pancia e degli zoccoli
PELLE = np.array([[0xB8, 0x43, 0x2A], [0x8E, 0x2F, 0x1C], [0xF1, 0xDF, 0xB0], [0xD6, 0xBC, 0x86],
                  [0xEF, 0xE3, 0xC8], [0xC9, 0xB4, 0x8E]], np.float32)
TRATTO = 9      # quanto è largo il tratto nero, in pixel del disegno


def pezzi():
    """Le immagini dei pezzi dell'equipaggiamento in skins.lua: nome -> "replace" o "over"."""
    out, categoria = {}, None
    for riga in open(LUA, encoding="utf-8"):
        m = re.search(r'=\s*\{\s*category = "(\w+)"', riga)
        if m:
            categoria = m.group(1)
        m = re.search(r'img = "(\w+)".*mode = "(\w+)"', riga)
        if m and categoria in CATEGORIE:
            out[m.group(1)] = m.group(2)
    return out


def di_pelle(rgb, tratto):
    """Dove il colore è la pelle; accanto al tratto nero anche scurita verso il nero
    (i bordi sfumati). Lontano dal tratto no: un grigio non è un crema scurito."""
    v = rgb.astype(np.float32)
    bordo = ndimage.binary_dilation(tratto, iterations=3)
    out = np.zeros(v.shape[:2], bool)
    for c in PELLE:
        t = np.clip((v @ c) / (c @ c), 0.0, 1.0)
        out |= (np.linalg.norm(v - t[..., None] * c, axis=-1) < 20) & (t > np.where(bordo, 0.3, 0.92))
    return out


def disco(r):
    y, x = np.ogrid[-r:r + 1, -r:r + 1]
    return x * x + y * y <= r * r


def sagoma(im, modo):
    """L'alfa della sagoma di un pezzo (float 0-1), o None se è il disegno stesso."""
    a = np.asarray(im.convert("RGBA")).astype(np.float32)
    alfa = a[..., 3] / 255.0
    pieno = alfa > 0.5
    if modo == "replace":
        rgb = a[..., :3]
        tratto = pieno & (rgb.max(-1) < 40)
        pelle = pieno & ~tratto & di_pelle(rgb, tratto)
        # un granello rossiccio sul bordo sfumato del tratto non è pelle
        lab, n = ndimage.label(pelle)
        if n:
            aree = ndimage.sum(pelle, lab, range(1, n + 1))
            pelle = np.isin(lab, np.nonzero(aree >= 60)[0] + 1)
        pezzo = pieno & ~tratto & ~pelle
        # i granelli (un bordo sfumato fra pelle e tratto) non sono del pezzo
        lab, n = ndimage.label(pezzo)
        if n:
            aree = ndimage.sum(pezzo, lab, range(1, n + 1))
            pezzo = np.isin(lab, np.nonzero(aree >= 60)[0] + 1)
        # il tratto nero attorno al pezzo è suo (anche l'orlo sulla pelle)
        dal_pezzo = ndimage.distance_transform_edt(~pezzo)
        dalla_pelle = ndimage.distance_transform_edt(~pelle)
        vicino = dal_pezzo <= TRATTO + 2
        m = pezzo | (tratto & vicino) | (pieno & ~pelle & ~tratto & vicino)
        # dove il bordo del pezzo è anche il bordo del corpo il tratto è più largo:
        # è del pezzo fin dove il pezzo è più vicino della pelle
        m |= tratto & (dal_pezzo < dalla_pelle) & (dal_pezzo <= 3 * TRATTO)
        # e il tratto che continua da lì lontano dalla pelle (la punta di una pinna)
        lontano = dalla_pelle > TRATTO + 4
        m = ndimage.binary_propagation(m, mask=m | (tratto & lontano))
        m = ndimage.binary_fill_holes(m)
        # ma non il moncone del tratto della pelle che parte dall'orlo (il bordo della
        # gamba sopra lo stivale): è sottile quanto il tratto e sta accanto alla pelle
        aperto = ndimage.binary_opening(m, disco(TRATTO // 2 + 1))
        accanto = dalla_pelle <= TRATTO + 4
        m &= ~(~aperto & accanto & ~pezzo)
        # tolti i monconi, restano solo le parti attaccate al pezzo
        lab, n = ndimage.label(m)
        if n:
            m = np.isin(lab, np.unique(lab[pezzo & m]))
        m = ndimage.binary_fill_holes(m)
        # il bordo sfumato del tratto verso la pelle (scuro, rossiccio) resta col tratto
        m |= ndimage.binary_dilation(m, iterations=2) & pieno & (rgb.max(-1) < 135)
    else:
        m = ndimage.binary_fill_holes(pieno)
        if (m & ~pieno).sum() < 40:
            return None
    # il bordo di fuori resta quello sfumato del disegno, i tagli nuovi si ammorbidiscono
    dentro = ndimage.gaussian_filter(m.astype(np.float32), 0.8)
    orlo = ndimage.binary_dilation(m, iterations=2)
    return np.where(m, np.maximum(alfa, dentro), np.where(orlo, np.minimum(alfa, dentro), 0.0))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--prova", help="cartella dove mettere le sagome sopra i disegni, da guardare")
    ar = ap.parse_args()
    os.makedirs(SAGOME, exist_ok=True)
    if ar.prova:
        os.makedirs(ar.prova, exist_ok=True)
    fatte = []
    for nome, modo in sorted(pezzi().items()):
        im = Image.open(os.path.join(PELLI, nome + ".png"))
        m = sagoma(im, modo)
        if m is None:
            continue
        fatte.append(nome)
        out = np.zeros(m.shape + (4,), np.uint8)
        out[..., :3] = 255
        out[..., 3] = np.clip(m * 255 + 0.5, 0, 255)
        Image.fromarray(out, "RGBA").save(os.path.join(SAGOME, nome + ".png"), optimize=True)
        if ar.prova:
            base = np.asarray(im.convert("RGBA")).astype(np.float32)
            fondo = np.full(base.shape[:2] + (3,), (70.0, 110.0, 70.0), np.float32)
            al = base[..., 3:] / 255
            vista = fondo * (1 - al) + base[..., :3] * al
            vista = vista * (1 - 0.55 * m[..., None]) + np.array([255.0, 255.0, 0.0]) * 0.55 * m[..., None]
            Image.fromarray(vista.astype(np.uint8)).save(os.path.join(ar.prova, nome + ".png"))
    for f in os.listdir(SAGOME):
        if f.endswith(".png") and f[:-4] not in fatte:
            os.remove(os.path.join(SAGOME, f))
    with open(ATLANTE, "w", encoding="utf-8", newline="\n") as f:
        for nome in fatte:
            f.write(f'images {{\n  image: "/assets/sagome/{nome}.png"\n}}\n')
        f.write("margin: 2\nextrude_borders: 2\ninner_padding: 0\n")
    with open(ELENCO, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- Made by tools/stampino/sagome.py, do not edit by hand.\n")
        f.write("-- The gear pieces that have their own silhouette image (atlas battle/outlines.atlas,\n")
        f.write("-- same name as the piece's image): the piece without the skin drawn with it, or\n")
        f.write("-- with its holes closed. The others are their own silhouette. See menu/outline.lua.\n")
        f.write("return {\n")
        for nome in fatte:
            f.write(f"\t{nome} = true,\n")
        f.write("}\n")
    print(f"{len(fatte)} sagome in client/assets/sagome")
    return 0


if __name__ == "__main__":
    sys.exit(main())
