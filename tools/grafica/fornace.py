# La Fornace del Fabbro (docs/commesse.md "La Fornace"): i pezzi del Banco degli Usurai
# (Sergio, 26 nov: la Fornace sta nel Sabbione del girone VII) dai disegni di Codex
# (art/WB-097: cielo 2, lontano 1, medio 1, argine e pinnacolo 2, bancone 1, mucchi e vetro 2;
# art/WB-098: borse aperte 1, borse chiuse 1, trave e corde 2, usuraio del banco 1) e quelli rimasti delle schede di prima (art/WB-092: goccia e schizzo;
# art/WB-093: mestolo 1; art/WB-094: fiammata 1, medaglia del jackpot 1; art/WB-095: le
# medaglie dei rintocchi).
#   python3 tools/grafica/fornace.py
# Scrive:
#   client/assets/fornace/*.png       le borse (6 colori, aperte e chiuse), la trave, la
#                                     corda e i cordini, l'usuraio del banco (3 facce), argine,
#                                     parete, sporgenza, il bancone e i mucchi,
#                                     il vaso e le perle di vetro, le falde di fuoco, i 4
#                                     fotogrammi della fiammata, le medaglie, goccia, schizzo
#   client/menu/fornace.atlas         l'atlante (fuori da /ui/: ha le mipmap, perché la
#                                     fucina si vede a tanti zoom)
#   client/menu/forge_pieces.lua      le misure in pixel di ogni pezzo (generato) e, per le
#                                     borse, la bocca (mx, my, mw), la corda (rx), il sigillo (sx, sy, sw)
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
A95 = os.path.join(RADICE, "art", "WB-095")
A97 = os.path.join(RADICE, "art", "WB-097")
A98 = os.path.join(RADICE, "art", "WB-098")
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


def fai_wb094():
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
        im = misura(tela, 3 * 78 * 2 * mezzo / alto)
        nome = f"fiammata_{q + 1}"
        im.save(os.path.join(OUT, nome + ".png"), optimize=True)
        MISURE[nome] = (im.width, im.height)
    # la medaglia del jackpot: grande al centro dello schermo (circa 200 px)
    md = ritaglia(os.path.join(A94, "medaglia_jackpot_1.png"))
    salva("medaglia_jackpot", md, 400 / PX)


def fai_wb095():
    # le medaglie dei rintocchi (medaglie_rintocchi_1: bronzo 6 a sinistra, argento 10 a
    # destra), grandi come quella del jackpot
    md = ritaglia(os.path.join(A95, "medaglie_rintocchi_1.png"))
    salva("medaglia_rintocchi_6", md.crop((0, 0, 760, md.height)), 400 / PX)
    salva("medaglia_rintocchi_10", md.crop((760, 0, md.width, md.height)), 400 / PX)


def fai_fucina():
    gs = ritaglia(os.path.join(A92, "goccia_e_secchio_1.png"))
    salva("goccia", gs.crop((136, 162, 356, 380)), 22)
    salva("schizzo", gs.crop((335, 500, 712, 747)), 70)


# Il Banco degli Usurai (art/WB-097 e WB-098, Sergio 26 nov) ---------------------------

# Le borse sulle corde (WB-098, Sergio 26 nov: gli usurai sul muro facevano confusione):
# una borsa aperta e una chiusa per colore, una sola misura (le piccole sono le grandi
# rimpicciolite, mai ingrandito un disegno). L'orlo è largo RIM_W dello stampo delle
# regole (forge.lua: le labbra a ±0,43 della larghezza, la presa a ±0,41)
COLORI = ["oro", "azzurro", "arancio", "verde", "viola", "ferro"]
BORSE_APERTE = [(164, 19, 480, 495), (610, 19, 926, 495), (1056, 19, 1372, 495),
                (164, 512, 480, 991), (610, 512, 926, 991), (1056, 512, 1372, 991)]
BORSE_CHIUSE = [(125, 16, 470, 476), (594, 16, 941, 477), (1065, 16, 1411, 477),
                (125, 519, 471, 980), (594, 519, 941, 980), (1065, 519, 1411, 980)]
RIM_W = 0.76
STAMPO = 78 * 1.06
BOCCHE = {}


def bocca_borsa(im):
    # la bocca: il buio dentro l'orlo (aperto per staccarlo dal contorno nero), poi
    # l'orlo a destra e a sinistra lungo la sua riga fino al contorno
    a = np.asarray(im).astype(float)
    al, lum = a[..., 3], a[..., :3].mean(2)
    h, w = al.shape
    buio = ndi.binary_opening((al > 250) & (lum < 45), iterations=6)
    lab, k = ndi.label(buio)
    best = None
    for i in range(1, k + 1):
        ys, xs = np.where(lab == i)
        if ys.mean() < h * 0.6 and (best is None or len(xs) > best[0]):
            best = (len(xs), xs.min(), xs.max(), ys.min(), ys.max())
    _, x0, x1, y0, y1 = best
    cy = (y0 + y1) // 2

    def esci(x, d):
        while 0 < x < w - 1 and lum[cy, x] < 60:
            x += d
        while 0 < x < w - 1 and lum[cy, x] >= 60 and al[cy, x] > 200:
            x += d
        return x
    sx, dx = esci(x0, -1), esci(x1, 1)
    return (sx + dx) / 2, cy, dx - sx


def pancia(im):
    # il fondo della borsa e la larghezza della pancia (la riga più larga della metà bassa)
    al = np.asarray(im)[..., 3] > 128
    ys = np.where(al.any(1))[0]
    basso = ys.max()
    righe = [(r, np.where(al[r])[0]) for r in range(al.shape[0] // 2, basso)]
    r, xs = max(righe, key=lambda q: q[1].max() - q[1].min() if len(q[1]) else 0)
    return basso, (xs.min() + xs.max()) / 2, xs.max() - xs.min()


def cima(im):
    # dove la corda esce in alto: il mezzo delle prime righe piene
    al = np.asarray(im)[..., 3] > 128
    ys = np.where(al.any(1))[0]
    xs = np.where(al[ys.min():ys.min() + 6].any(0))[0]
    return (xs.min() + xs.max()) / 2


def sigillo(im):
    # il mezzo della ceralacca: la macchia rossa più grande
    a = np.asarray(im).astype(int)
    rosso = (a[..., 0] > 100) & (a[..., 1] < a[..., 0] * 0.33) & (a[..., 2] < a[..., 0] * 0.33) & (a[..., 3] > 200)
    lab, k = ndi.label(rosso)
    s = ndi.sum(rosso, lab, range(1, k + 1))
    ys, xs = np.where(lab == int(np.argmax(s)) + 1)
    return xs.mean(), ys.mean(), xs.max() - xs.min()


def borsa(nome, im, k, extra):
    if k < 1:
        im = im.resize((round(im.width * k), max(1, round(im.height * k))), Image.LANCZOS)
    im.save(os.path.join(OUT, nome + ".png"), optimize=True)
    MISURE[nome] = (im.width, im.height)
    BOCCHE[nome] = {q: round(v * k, 1) for q, v in extra.items()}


def fai_borse():
    aperte = ritaglia(os.path.join(A98, "borse_aperte_1.png"))
    chiuse = ritaglia(os.path.join(A98, "borse_chiuse_1.png"))
    for c, ba, bc in zip(COLORI, BORSE_APERTE, BORSE_CHIUSE):
        a = stretto(aperte.crop(ba))
        mx, my, mw = bocca_borsa(a)
        k = min(1, STAMPO * RIM_W * a.width / mw * PX / a.width)
        fa, _, pa = pancia(a)
        borsa(f"borsa_{c}", a, k, {"mx": mx, "my": my, "mw": mw, "rx": cima(a)})
        # la chiusa: la stessa pancia, la bocca dove sarebbe quella dell'aperta
        b = stretto(chiuse.crop(bc))
        fb, xb, pb = pancia(b)
        q = pb / pa
        sx, sy, sw = sigillo(b)
        kb = k / q
        borsa(f"borsa_chiusa_{c}", b, min(1, kb), {"mx": xb, "my": fb - (fa - my) * q, "mw": mw * q, "rx": cima(b),
                                                    "sx": sx, "sy": sy, "sw": sw})


def fai_corde():
    # la trave dei conti, il piolo, la corda che si impila, i cordini annodati (trave_e_corde_2)
    tc = ritaglia(os.path.join(A98, "trave_e_corde_2.png"))
    salva("trave_sx", tc.crop((11, 277, 424, 420)), 200)
    salva("trave_dx", tc.crop((1112, 277, 1526, 420)), 200)
    # (il pezzo di mezzo si ripete: tagliato dentro il contorno a destra e a sinistra)
    tr = stretto(tc.crop((452, 317, 1085, 386)))
    salva("trave", tr.crop((8, 0, tr.width - 8, tr.height)), 280)
    co = stretto(tc.crop((505, 445, 537, 743)))
    salva("corda", co.crop((0, 6, co.width, co.height - 6)), 8)
    salva("piolo", tc.crop((327, 528, 382, 602)), 14)
    for nome, b in (("cordino_corto_rosso", (655, 453, 704, 620)), ("cordino_corto", (807, 453, 856, 620)),
                    ("cordino_lungo_rosso", (961, 445, 1011, 727)), ("cordino_lungo", (1104, 445, 1153, 727))):
        salva(nome, tc.crop(b), 18)


def fai_usuraio_banco():
    # l'usuraio seduto accanto al bancone: zitto, che parla, che paga
    ub = ritaglia(os.path.join(A98, "usuraio_del_banco_1.png"))
    for nome, b in (("usuraio_zitto", (40, 303, 424, 767)), ("usuraio_parla", (579, 295, 967, 767)),
                    ("usuraio_paga", (1064, 290, 1510, 767))):
        salva(nome, ub.crop(b), 240)


def fai_sabbione():
    # argine, sporgenza e parete (argine_e_pinnacolo_2)
    ap = ritaglia(os.path.join(A97, "argine_e_pinnacolo_2.png"))
    # l'argine si ripete: tagliato dentro il contorno a destra e a sinistra
    ar = stretto(ap.crop((23, 646, 1031, 897)))
    salva("argine", ar.crop((14, 0, ar.width - 14, ar.height)), 720)
    salva("sporgenza", ap.crop((37, 340, 306, 592)), 150)
    # (la parete si impila: tagliata dentro il contorno sopra e sotto)
    pa = stretto(ap.crop((1303, 129, 1510, 897)))
    salva("parete", pa.crop((0, 8, pa.width, pa.height - 8)), 160)
    # il bancone (bancone_1): le tre assi, il cavalletto, le due metà spezzate (solo la
    # loro punta, lunga come un'asse) e la crepa
    bc = ritaglia(os.path.join(A97, "bancone_1.png"))
    salva("asse_sx", bc.crop((23, 187, 507, 268)), 230)
    salva("asse", bc.crop((518, 190, 1020, 268)), 230)
    salva("asse_dx", bc.crop((1030, 187, 1513, 268)), 230)
    salva("cavalletto", bc.crop((638, 313, 899, 573)), 100)
    salva("asse_rotta_sx", bc.crop((270, 742, 760, 840)), 230)
    salva("asse_rotta_dx", bc.crop((780, 742, 1268, 840)), 230)
    salva("crepa", bc.crop((675, 600, 840, 712)), 60)
    # i mucchi del bottino, il vaso e le perle di vetro, la falda di fuoco
    mv = ritaglia(os.path.join(A97, "mucchi_e_vetro_2.png"))
    for i, b in enumerate([(57, 233, 285, 349), (337, 189, 716, 349), (765, 144, 1476, 349)]):
        salva(f"monete_{i + 1}", mv.crop(b), 220)
    for i, b in enumerate([(57, 463, 285, 567), (341, 426, 708, 567), (773, 381, 1460, 567)]):
        salva(f"cristalli_{i + 1}", mv.crop(b), 220)
    salva("falda", mv.crop((57, 665, 358, 820)), 60)
    salva("perla", mv.crop((470, 725, 560, 795)), 14)
    salva("vaso", mv.crop((717, 599, 912, 872)), 56)
    for i, b in enumerate([(1034, 717, 1084, 801), (1153, 675, 1232, 814), (1304, 627, 1418, 834)]):
        salva(f"fiocco_{i + 1}", mv.crop(b), 24)


def chiave_morbida(percorso):
    # i dipinti hanno foschia e bordi sfumati nel verde: l'alfa dalla quantità di verde,
    # e il colore liberato dal verde che c'era dietro (il verde di fondo misurato sul
    # foglio); dove è quasi trasparente il colore del pieno più vicino
    src = np.asarray(Image.open(percorso).convert("RGB")).astype(float)
    r, g, b = src[..., 0], src[..., 1], src[..., 2]
    m = g - np.maximum(r, b)
    fondo = src[m > 200].mean(0)
    mk = fondo[1] - max(fondo[0], fondo[2])
    a = np.clip(1 - (m - 4) / (mk * 0.55 - 4), 0, 1)
    o = np.empty_like(src)
    for c in range(3):
        o[..., c] = (src[..., c] - (1 - a) * fondo[c]) / np.maximum(a, 1e-3)
    o = np.clip(o, 0, 255)
    # niente verde rimasto (la foschia verdina sulla rupe): mai più verde della media di
    # rosso e blu
    o[..., 1] = np.minimum(o[..., 1], (o[..., 0] + o[..., 2]) / 2)
    pieno = a > 0.6
    idx = ndi.distance_transform_edt(~pieno, return_distances=False, return_indices=True)
    for c in range(3):
        o[..., c] = np.where(pieno, o[..., c], o[..., c][idx[0], idx[1]])
    a = np.where(a < 0.03, 0, a)
    return Image.fromarray(np.dstack([o, a * 255]).clip(0, 255).astype(np.uint8), "RGBA")


def fai_sfondi():
    os.makedirs(PAINT, exist_ok=True)
    Image.open(os.path.join(A97, "sabbione_cielo_2.png")).convert("RGB").save(os.path.join(PAINT, "cielo.jpg"), quality=88)
    for nome, src in (("lontano", "sabbione_lontano_1"), ("medio", "sabbione_medio_1")):
        chiave_morbida(os.path.join(A97, src + ".png")).save(os.path.join(PAINT, nome + ".png"), optimize=True)


def fai_wb097():
    fai_sabbione()


def fai_wb098():
    fai_borse()
    fai_corde()
    fai_usuraio_banco()

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
    fai_wb094()
    fai_wb095()
    fai_fucina()
    fai_wb097()
    fai_wb098()
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
            extra = "".join(f", {k} = {v}" for k, v in BOCCHE.get(n, {}).items())
            f.write(f"\t{n} = {{ w = {w}, h = {h}{extra} }},\n")
        f.write("}\n")
    print(len(nomi), "pezzi")


if __name__ == "__main__":
    main()
