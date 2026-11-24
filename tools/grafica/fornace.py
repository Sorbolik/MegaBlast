# La Fornace del Fabbro (docs/commesse.md "La Fornace"): i pezzi della fucina dai
# disegni di Codex scelti da Sergio (art/WB-092: cielo 1, lontano 1, medio 2, sporgenza 1,
# goccia e secchio 1; art/WB-093: mestolo 1 e gli stampi vuoti 1; art/WB-094: coperchi 1,
# fiammata 1, medaglia del jackpot 1).
#   python3 tools/grafica/fornace.py
# Scrive:
#   client/assets/fornace/*.png       stampi vuoti (6 colori x grande/piccolo), coperchi,
#                                     i 4 fotogrammi della fiammata, la medaglia del jackpot,
#                                     goccia, schizzo, secchio, catena, sporgenza, pavimento
#   client/menu/fornace.atlas         l'atlante (fuori da /ui/: ha le mipmap, perché la
#                                     fucina si vede a tanti zoom)
#   client/menu/forge_pieces.lua      le misure in pixel di ogni pezzo (generato)
#   client/paintings/fornace/*.png|jpg   cielo, lontano e medio: grandi, caricati solo
#                                     quando la Fornace è aperta
#   art/armi/mestolo.png, mestolo_icona.png   il Mestolo per tools/grafica/armi.py
# Il ritaglio dal verde: lo sfondo è solo il verde attaccato al bordo (e i buchi chiusi di
# verde pieno, dentro gli anelli), così le placche verde mare e il vapore chiaro restano.
# Ogni pezzo è al doppio della misura più grande sullo schermo (zoom 1,6 della fucina)
# o, se il disegno è più piccolo, alla sua misura: mai ingrandito.
# Servono numpy, scipy e Pillow.
import os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..", "..")
A92 = os.path.join(RADICE, "art", "WB-092")
A93 = os.path.join(RADICE, "art", "WB-093")
A94 = os.path.join(RADICE, "art", "WB-094")
OUT = os.path.join(RADICE, "client", "assets", "fornace")
ATLAS = os.path.join(RADICE, "client", "menu", "fornace.atlas")
LUA = os.path.join(RADICE, "client", "menu", "forge_pieces.lua")
PAINT = os.path.join(RADICE, "client", "paintings", "fornace")
ARMI = os.path.join(RADICE, "art", "armi")

# pixel per unità del mondo della fucina: lo zoom più vicino (1,6) per due
PX = 3.2


def ritaglia(percorso):
    src = np.asarray(Image.open(percorso).convert("RGB")).astype(float)
    r, g, b = src[..., 0], src[..., 1], src[..., 2]
    m = g - np.maximum(r, b)
    cand = m > 60
    lab, _ = ndi.label(cand)
    bordo = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    fondo = np.isin(lab, list(bordo))
    pieno = (r < 70) & (b < 70) & (g > 190)
    buchi = cand & ~fondo
    lab2, k2 = ndi.label(buchi)
    if k2:
        idx = range(1, k2 + 1)
        frac = ndi.mean(pieno, lab2, idx)
        mm = ndi.mean(m, lab2, idx)
        nb = ndi.mean((b < 90) & (r < 90), lab2, idx)
        buoni = [i + 1 for i, (f, q, z) in enumerate(zip(frac, mm, nb)) if f > 0.3 or q > 110 or z > 0.7]
        fondo |= np.isin(lab2, buoni)
    fascia = ndi.binary_dilation(fondo, iterations=2) & ~fondo
    a = np.where(fondo, 0.0, 255.0)
    morbido = np.clip(1 - (m - 20) / 120, 0, 1) * 255
    a = np.where(fascia, np.minimum(255, morbido), a)
    a = np.minimum(a, ndi.grey_erosion(a, size=(3, 3)) * 0.5 + a * 0.5)
    a[a < 12] = 0
    lab3, k3 = ndi.label(a > 40)
    if k3:
        s = ndi.sum(np.ones_like(lab3), lab3, range(1, k3 + 1))
        for i, v in enumerate(s):
            if v < 60:
                a[lab3 == i + 1] = 0
    o = src.copy()
    chiaro = (r > 140) & (b > 140) & (g > np.maximum(r, b))
    o[..., 1] = np.where(chiaro, np.maximum(r, b), g)
    dentro = (a >= 255) & ~ndi.binary_dilation(fondo, iterations=3)
    idx = ndi.distance_transform_edt(~dentro, return_distances=False, return_indices=True)
    for c in range(3):
        o[..., c] = np.where(dentro, o[..., c], o[..., c][idx[0], idx[1]])
    return Image.fromarray(np.dstack([o, a]).clip(0, 255).astype(np.uint8), "RGBA")


def stretto(im):
    box = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    return im.crop(box) if box else im


def misura(im, larghezza_mondo):
    # alla misura dello zoom più vicino per due, mai più grande del disegno
    w = min(im.width, round(larghezza_mondo * PX))
    if w >= im.width:
        return im
    return im.resize((w, max(1, round(im.height * w / im.width))), Image.LANCZOS)


MISURE = {}


def salva(nome, im, larghezza_mondo):
    im = misura(stretto(im), larghezza_mondo)
    im.save(os.path.join(OUT, nome + ".png"), optimize=True)
    MISURE[nome] = (im.width, im.height)


# gli stampi: le scatole sui fogli ritagliati, per colore (riga sopra: oro, azzurro,
# arancio; sotto: verde mare, viola, ferro)
COLORI = ["oro", "azzurro", "arancio", "verde", "viola", "ferro"]
SCATOLE = {
    "stampi_grandi_vuoti_1": [(69, 32, 456, 433), (574, 32, 962, 433), (1079, 32, 1466, 433),
                              (69, 546, 456, 946), (574, 546, 962, 946), (1079, 546, 1466, 946)],
    "stampi_piccoli_vuoti_1": [(112, 96, 465, 450), (591, 96, 945, 450), (1072, 96, 1424, 450),
                               (112, 578, 465, 932), (591, 578, 945, 932), (1072, 578, 1424, 931)],
}
# (lo stampo pieno di metallo di WB-093 non si usa più: la goccia rimbalza come una palla,
# lo stampo preso lo chiude il coperchio di WB-094; Sergio, 24 nov)
# larghezza nel mondo (forge.lua: grandi 78, piccoli 52; il pieno ha la colata che sborda)
LARGO = {"grandi": 78, "piccoli": 52}


def fai_stampi():
    for foglio, scatole in SCATOLE.items():
        im = ritaglia(os.path.join(A93, foglio + ".png"))
        _, misura_, stato, _ = foglio.split("_")
        for col, box in zip(COLORI, scatole):
            salva(f"stampo_{misura_}_{stato}_{col}", im.crop(box), LARGO[misura_] * 1.05)


def fai_wb094():
    # i coperchi dello stampo preso (larghi come l'orlo dello stampo più un poco)
    cp = ritaglia(os.path.join(A94, "coperchi_1.png"))
    salva("coperchio_grandi", cp.crop((87, 326, 732, 703)), LARGO["grandi"] * 1.0)
    salva("coperchio_piccoli", cp.crop((948, 368, 1438, 677)), LARGO["piccoli"] * 1.0)
    # i 4 fotogrammi della fiammata, tutti sulla stessa tela con la bocca in basso al
    # centro: ogni fotogramma tiene solo i pixel del suo quarto del foglio
    fi = ritaglia(os.path.join(A94, "fiammata_1.png"))
    a = np.asarray(fi)
    alto, mezzo = 945, 180
    for q in range(4):
        tutto = a.copy()
        tutto[:, : q * 384, 3] = 0
        tutto[:, (q + 1) * 384:, 3] = 0
        quarto = tutto[:, q * 384:(q + 1) * 384, 3] > 40
        fondo = np.where(quarto.any(1))[0].max()
        base = np.where(quarto[fondo - 3])[0]
        cx = q * 384 + (base.min() + base.max()) // 2
        tela = Image.fromarray(tutto).crop((cx - mezzo, fondo + 3 - alto, cx + mezzo, fondo + 3))
        # alta tre stampi grandi: larga così nel mondo
        im = misura(tela, 3 * LARGO["grandi"] * 2 * mezzo / alto)
        nome = f"fiammata_{q + 1}"
        im.save(os.path.join(OUT, nome + ".png"), optimize=True)
        MISURE[nome] = (im.width, im.height)
    # la medaglia del jackpot: grande al centro dello schermo (circa 200 px)
    md = ritaglia(os.path.join(A94, "medaglia_jackpot_1.png"))
    salva("medaglia_jackpot", md, 400 / PX)


def fai_fucina():
    gs = ritaglia(os.path.join(A92, "goccia_e_secchio_1.png"))
    salva("goccia", gs.crop((136, 162, 356, 380)), 22)
    salva("secchio", gs.crop((780, 428, 1232, 881)), 120)
    salva("schizzo", gs.crop((335, 500, 712, 747)), 70)
    salva("catena", gs.crop((1331, 113, 1423, 911)), 14)
    sp = ritaglia(os.path.join(A92, "sporgenza_1.png"))
    salva("sporgenza", sp.crop((23, 331, 387, 705)), 150)
    salva("pavimento", sp.crop((418, 568, 1511, 705)), 560)


def fai_sfondi():
    os.makedirs(PAINT, exist_ok=True)
    Image.open(os.path.join(A92, "fucina_cielo_1.png")).convert("RGB").save(os.path.join(PAINT, "cielo.jpg"), quality=88)
    for nome, src in (("lontano", "fucina_lontano_1"), ("medio", "fucina_medio_2")):
        ritaglia(os.path.join(A92, src + ".png")).save(os.path.join(PAINT, nome + ".png"), optimize=True)


def fai_mestolo():
    # il mestolo vuoto, dritto, la coppa a destra: per tools/grafica/armi.py (che lo mette
    # alla misura dell'arma in mano) e la sua icona
    im = ritaglia(os.path.join(A93, "mestolo_1.png"))
    vuoto = stretto(im.crop((115, 290, 1422, 484)))
    # in mano è capovolto (Sergio, 24 nov): l'apprendista lo tiene all'indietro sopra la
    # spalla e la bocca della coppa guarda i premi, poi la frustata lo porta avanti
    vuoto.transpose(Image.FLIP_TOP_BOTTOM).save(os.path.join(ARMI, "mestolo.png"), optimize=True)
    lato = max(vuoto.width, vuoto.height)
    tela = Image.new("RGBA", (lato, lato), (0, 0, 0, 0))
    tela.alpha_composite(vuoto, (0, (lato - vuoto.height) // 2))
    tela.rotate(35, resample=Image.BICUBIC).save(os.path.join(ARMI, "mestolo_icona.png"), optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith(".png"):
            os.remove(os.path.join(OUT, f))
    fai_stampi()
    fai_wb094()
    fai_fucina()
    fai_sfondi()
    fai_mestolo()
    nomi = sorted(MISURE)
    with open(ATLAS, "w") as f:
        for n in nomi:
            f.write(f'images {{\n  image: "/assets/fornace/{n}.png"\n}}\n')
        f.write("margin: 0\nextrude_borders: 2\ninner_padding: 0\n")
    with open(LUA, "w") as f:
        f.write("-- Generated by tools/grafica/fornace.py: the size in pixels of every piece of the\n"
                "-- Forge's atlas (client/menu/fornace.atlas).\nreturn {\n")
        for n in nomi:
            w, h = MISURE[n]
            f.write(f"\t{n} = {{ w = {w}, h = {h} }},\n")
        f.write("}\n")
    print(len(nomi), "pezzi")


if __name__ == "__main__":
    main()
