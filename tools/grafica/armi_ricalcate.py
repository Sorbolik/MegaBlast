# Ritaglia le armi, gli oggetti e gli effetti disegnati da Codex (WB-063...066, WB-068) dai fogli già ricalcati a
# vettori e le salva una per una in art/armi/<nome>.png (trasparenti, alla misura
# del ricalco: il gioco le rimpicciolisce, non le ingrandisce mai).
#
# Prima si ricalca ogni foglio con la tavolozza delle armi:
#   python3 tools/stampino/vettoriale.py --tavolozza tools/stampino/tavolozze/armi.json \
#       art/WB-063/primarie_lunghe_1.png FOGLIO.svg FOGLIO.png --senza ...
# poi:
#   python3 tools/grafica/armi_ricalcate.py CARTELLA_DEI_RICALCHI
# e infine python3 tools/grafica/armi.py, che usa questi pezzi al posto delle forme
# disegnate a codice (stesse misure in battle/weapons.lua).
#
# I pezzi di ogni foglio si leggono come un testo: righe dall'alto in basso, in ogni
# riga da sinistra a destra. Le parti verdi (#00FF00) restano verdi: armi.py ne fa
# lo strato del colore della squadra.
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..", "..")
OUT = os.path.join(RADICE, "art", "armi")

# foglio ricalcato -> i nomi dei pezzi, in ordine di lettura
FOGLI = {
    "primarie_lunghe_1": ["missile", "sniper", "drill", "shards"],
    "primarie_corte_1": ["grenade", "punch", "boomerang", "tar"],
    "primarie_colpi_1": ["razzo", "palla", "scheggia", "uovo_1", "uovo_2", "uovo_3"],
    "primarie_icone_1": ["missile_icona", "grenade_icona", "shards_icona", "punch_icona",
                         "sniper_icona", "boomerang_icona", "tar_icona", "drill_icona"],
    "secondarie_lunghe_1": ["sword", "lunge", "mallet", "eagle"],
    "secondarie_corte_2": ["bellows", "vortex", "cannon", "petard"],
    "secondarie_icone_2": ["sword_icona", "eagle_icona", "mallet_icona", "lunge_icona",
                           "bellows_icona", "vortex_icona", "cannon_icona", "petard_icona"],
    "oggetti_pezzi_2": ["hook", "janus", "teleport", "parachute", "trampoline", "trap",
                        "shield", "uncino"],
    "oggetti_icone_1": ["hook_icona", "janus_icona", "teleport_icona", "parachute_icona",
                        "trampoline_icona", "trap_icona", "shield_icona"],
    "molla_e_tagliola_1": ["molla", "tagliola_chiusa"],
    "effetti_1": ["fx_runa", "fx_stella", "fx_fendente", "fx_vento",
                  "fx_fumo", "fx_anello_fumo", "fx_risucchio", "fx_bolla",
                  "fx_guscio", "fx_coccio", "fx_gocce", "fx_coriandolo",
                  "fx_crepa", "fx_cenere", "fx_fiamma", "fx_scintilla"],
}
MARGINE = 6
# fogli a griglia (colonne, righe): ogni cella è un pezzo, anche se fatto di più parti
# staccate (le gocce, i fiocchi sopra la cenere)
GRIGLIA = {"effetti_1": (4, 4)}


def sfondo(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (r > 200) & (b > 200) & (g < 80)


def celle(png, nomi, colonne, righe):
    # ogni parte staccata va nella cella dove cade il suo centro
    a = np.array(Image.open(png).convert("RGB"))
    fuori = sfondo(a)
    alfa = (~fuori).astype(np.uint8) * 255
    lab, n = ndimage.label(ndimage.binary_dilation(~fuori, iterations=2))
    ch, cw = a.shape[0] / righe, a.shape[1] / colonne
    gruppi = [[] for _ in nomi]
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        cy, cx = (sl[0].start + sl[0].stop) / 2, (sl[1].start + sl[1].stop) / 2
        k = int(cy // ch) * colonne + int(cx // cw)
        if k < len(nomi):
            gruppi[k].append((sl, i))
    for gruppo, nome in zip(gruppi, nomi):
        y0 = max(min(sl[0].start for sl, _ in gruppo) - MARGINE, 0)
        y1 = min(max(sl[0].stop for sl, _ in gruppo) + MARGINE, a.shape[0])
        x0 = max(min(sl[1].start for sl, _ in gruppo) - MARGINE, 0)
        x1 = min(max(sl[1].stop for sl, _ in gruppo) + MARGINE, a.shape[1])
        dentro = np.isin(lab[y0:y1, x0:x1], [i for _, i in gruppo])
        rgba = np.dstack([a[y0:y1, x0:x1], np.where(dentro, alfa[y0:y1, x0:x1], 0)]).astype(np.uint8)
        Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, nome + ".png"), optimize=True)
        print(nome, x1 - x0, "x", y1 - y0)


def pezzi(png, nomi):
    a = np.array(Image.open(png).convert("RGB"))
    fuori = sfondo(a)
    pieno = ndimage.binary_dilation(~fuori, iterations=8)
    lab, n = ndimage.label(pieno)
    zone = []
    minimo = a.shape[0] * a.shape[1] * 0.002
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        area = (lab[sl] == i).sum()
        if area >= minimo:
            zone.append((sl, i))
    if len(zone) != len(nomi):
        raise SystemExit(f"{png}: {len(zone)} pezzi, attesi {len(nomi)}")
    # righe: pezzi il cui centro in verticale cade dentro l'altezza di un altro
    zone.sort(key=lambda z: (z[0][0].start + z[0][0].stop) / 2)
    righe = []
    for z in zone:
        cy = (z[0][0].start + z[0][0].stop) / 2
        if righe and righe[-1][0][0][0].start <= cy <= righe[-1][0][0][0].stop:
            righe[-1].append(z)
        else:
            righe.append([z])
    ordine = [z for riga in righe for z in sorted(riga, key=lambda z: z[0][1].start)]
    alfa = (~fuori).astype(np.uint8) * 255
    for (sl, i), nome in zip(ordine, nomi):
        y0 = max(sl[0].start - MARGINE, 0)
        y1 = min(sl[0].stop + MARGINE, a.shape[0])
        x0 = max(sl[1].start - MARGINE, 0)
        x1 = min(sl[1].stop + MARGINE, a.shape[1])
        dentro = lab[y0:y1, x0:x1] == i
        rgba = np.dstack([a[y0:y1, x0:x1], np.where(dentro, alfa[y0:y1, x0:x1], 0)]).astype(np.uint8)
        Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, nome + ".png"), optimize=True)
        print(nome, x1 - x0, "x", y1 - y0)


def main():
    cartella = sys.argv[1]
    os.makedirs(OUT, exist_ok=True)
    for foglio, nomi in FOGLI.items():
        png = os.path.join(cartella, foglio + ".png")
        if os.path.exists(png) and foglio in GRIGLIA:
            celle(png, nomi, *GRIGLIA[foglio])
        elif os.path.exists(png):
            pezzi(png, nomi)
        else:
            print("manca", png)


if __name__ == "__main__":
    main()
