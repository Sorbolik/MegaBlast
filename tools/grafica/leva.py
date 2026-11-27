# La leva del Limbo (WB-099, foglio leva_e_chiave_1 di Codex): taglia dal verde la piastra col perno,
# il manico e la chiave, e scrive
#   client/assets/fx/leva_piastra.png   la piastra d'acciaio, larga 30 nel mondo (la borchia)
#   client/assets/fx/leva_manico.png    il manico, dall'occhiello al pomo d'oro
#   art/WB-099/chiave.png               la chiave (per il livello 2, non ancora nel gioco)
# e stampa le misure che usa client/battle/hazards.lua (LEVER_ART): il manico gira attorno al centro
# dell'occhiello; dal perno al centro del pomo c'è LEVER.out di sim/config.lua, che si tiene uguale.
#   python3 tools/grafica/leva.py     (dalla cartella del repository)
import os, sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
sys.path.insert(0, QUI)
from fornace import ritaglia, stretto   # noqa: E402

FOGLIO = os.path.join(RADICE, "art", "WB-099", "leva_e_chiave_1.png")
FX = os.path.join(RADICE, "client", "assets", "fx")
PX = 3.2          # pixel per unità del mondo: lo zoom più vicino per due (come la Fornace)
PIASTRA = 30      # larga come la borchia
MANICO = 45       # lungo una volta e mezza la piastra (la scheda: 60 e 90 pixel allo zoom più vicino)


def pezzi(im):
    """I tre oggetti da sinistra a destra, ognuno ritagliato stretto."""
    a = np.asarray(im.getchannel("A")) > 40
    lab, k = ndi.label(ndi.binary_dilation(a, iterations=6))
    box = sorted(ndi.find_objects(lab), key=lambda s: s[1].start)
    out = []
    for s in box:
        p = im.crop((s[1].start, s[0].start, s[1].stop, s[0].stop))
        out.append(stretto(p))
    return out


def rimpicciolisci(im, k):
    w = round(im.width * k)
    return im if w >= im.width else im.resize((w, round(im.height * k)), Image.LANCZOS)


def main():
    piastra, manico, chiave = pezzi(ritaglia(FOGLIO))[:3]
    # il manico: l'occhiello è il cerchio a sinistra (alto quanto la colonna più a sinistra piena),
    # il pomo il cerchio a destra (alto quanto il manico)
    a = np.asarray(manico.getchannel("A")) > 128
    occhio_h = 0
    for x in range(a.shape[1] // 4):
        ys = np.where(a[:, x])[0]
        if len(ys):
            occhio_h = max(occhio_h, ys.max() - ys.min() + 1)
    eye_x, eye_y = occhio_h / 2, (np.where(a[:, round(occhio_h / 2)])[0].min() + np.where(a[:, round(occhio_h / 2)])[0].max()) / 2
    knob_x, knob_y = manico.width - manico.height / 2, manico.height / 2
    k_mondo = MANICO / manico.width             # unità del mondo per pixel del foglio
    kp = PIASTRA / piastra.width
    px = PX * k_mondo
    rimpicciolisci(piastra, PX * kp).save(os.path.join(FX, "leva_piastra.png"), optimize=True)
    rimpicciolisci(manico, px).save(os.path.join(FX, "leva_manico.png"), optimize=True)
    chiave.save(os.path.join(RADICE, "art", "WB-099", "chiave.png"), optimize=True)
    print("piastra: %.1f x %.1f mondo" % (PIASTRA, piastra.height * kp))
    print("dal perno al pomo (LEVER.out): %.1f" % ((knob_x - eye_x) * k_mondo))
    print("manico: %.1f x %.1f mondo, occhiello a (%.1f, %.1f) dall'angolo in alto a sinistra"
          % (manico.width * k_mondo, manico.height * k_mondo, eye_x * k_mondo, eye_y * k_mondo))


main()
