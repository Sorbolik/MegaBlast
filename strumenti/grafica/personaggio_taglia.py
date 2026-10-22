# Ritaglia i pezzi del personaggio dai fogli (grafica/concept/personaggio_pezzi_v1.png
# per busto, testa e braccia, personaggio_gambe_v1.png per le gambe) in
# grafica/personaggio/master/<nome>.png, a piena risoluzione, con un bordo di 4 px.
import sys, numpy as np
from PIL import Image
from scipy import ndimage as nd
CONCEPT = '/mnt/project-files/grafica/concept/'
OUT = '/mnt/project-files/grafica/personaggio/master/'
# numero del pezzo (ordine di scipy.find_objects, area > 500) -> nome
NOMI = {1: 'testa_maschera', 2: 'testa', 3: 'busto', 4: 'collo', 5: 'nucleo',
        10: 'spallaccio_dietro', 11: 'spallaccio_davanti', 7: 'braccio_dietro', 6: 'braccio_davanti',
        8: 'avambraccio_dietro', 9: 'avambraccio_davanti',
        12: 'mano_aperta_dietro', 14: 'mano_aperta_davanti', 13: 'mano_artigli_dietro', 15: 'mano_artigli_davanti',
        16: 'pugno_dietro', 17: 'pugno_davanti'}
# le gambe: i pezzi "_sx" guardano a sinistra, nel rig si specchiano
GAMBE = {1: 'coscia_a', 2: 'coscia_b', 3: 'bacino', 4: 'stinco_a', 5: 'stinco_b', 6: 'piede', 7: 'piede_sx'}


def taglia(src, nomi):
    a = np.array(Image.open(CONCEPT + src).convert('RGBA'))
    lab, n = nd.label(nd.binary_closing(a[..., 3] > 20, iterations=2))
    k = 0
    for i, (ys, xs) in enumerate(nd.find_objects(lab)):
        if (lab[ys, xs] == i + 1).sum() < 500: continue
        k += 1
        if k not in nomi: continue
        P = 4
        y0, y1, x0, x1 = max(0, ys.start - P), ys.stop + P, max(0, xs.start - P), xs.stop + P
        part = a[y0:y1, x0:x1].copy()
        # solo il pezzo: via i pixel degli altri pezzi che cadono nel rettangolo
        own = nd.binary_dilation(lab[y0:y1, x0:x1] == i + 1, iterations=3)
        part[..., 3] = np.where(own, part[..., 3], 0)
        Image.fromarray(part).save(OUT + nomi[k] + '.png', optimize=True)
        print(nomi[k], part.shape[1], part.shape[0])


taglia('personaggio_pezzi_v1.png', NOMI)
taglia('personaggio_gambe_v1.png', GAMBE)
