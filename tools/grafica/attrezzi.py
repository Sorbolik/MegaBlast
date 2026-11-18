# Gli attrezzi in battaglia: a vettori (vettori.py) il cubo di ferro in cui cadono
# trappola, scudo e trampolino (sopra il gioco mette l'icona dell'attrezzo) e la bolla
# dello scudo addosso; di Codex, ricalcate in art/armi/, la tagliola posata e quella
# scattata, la Molla con la sua freccia (WB-065, WB-068) e le firme delle armi (WB-066).
# Le parti "luce" sono bianche: il gioco le tinge col colore della squadra.
# Scrive client/assets/fx/attrezzo_*.png e le firme fx_*.png (vanno in client/battle/battle.atlas).
#
# python3 tools/grafica/attrezzi.py   (serve cairosvg: pip install cairosvg)
import math
import os
import sys

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
RADICE = os.path.join(QUI, "..", "..")
OUT = os.path.join(RADICE, "client", "assets", "fx")

from vettori import COL, Disegno, rendi  # noqa: E402

PX = 6   # pixel per unità del mondo, come le armi
COL = dict(COL)


def cubo(d):
    # il cubo di ferro: una cassa d'acciaio scuro con gli spigoli rinforzati e
    # i chiodi; il centro è una lastra liscia dove il gioco mette l'icona
    s = 11
    d.rect(-s, 0, 2 * s, 2 * s, "ferro", r=1.6)
    d.rect(-s + 2.4, 2.4, 2 * s - 4.8, 2 * s - 4.8, "acciaio", r=1.0, contorno=False)
    d.rect(-s + 3.4, 3.4, 2 * s - 6.8, 2 * s - 6.8, "ferro", r=0.8, contorno=False)
    for x in (-s + 1.3, s - 1.3):
        for y in (1.3, 2 * s - 1.3):
            d.cerchio(x, y, 0.8, "ottone", contorno=False)
    d.riga(f"M{-s + 2.4},{2 * s - 2.4} L{s - 2.4},{2 * s - 2.4}", COL["acciaio"][2], 0.5)
    return (-s - 1.6, -1.6, s + 1.6, 2 * s + 1.6)


def bolla(d):
    # lo scudo addosso: una bolla bianca (si tinge col colore della squadra)
    # con le maglie esagonali e un riflesso in alto a sinistra
    r = 18
    d.cerchio(0, 0, r, "bianco", tinta=True, contorno=False)
    for k in range(6):
        a = math.radians(30 + k * 60)
        x, y = math.cos(a) * r * 0.55, math.sin(a) * r * 0.55
        pts = " L".join(f"{x + math.cos(math.radians(j * 60)) * 4.2:.2f},{y + math.sin(math.radians(j * 60)) * 4.2:.2f}"
                        for j in range(6))
        d.riga(f"M{pts} Z", "#ffffff", 0.45)
    d.riga(f"M{-r * 0.62},{r * 0.36} Q{-r * 0.5},{r * 0.66} {-r * 0.16},{r * 0.76}", "#ffffff", 1.6)
    return (-r - 1, -r - 1, r + 1, r + 1)


# la tagliola aperta disegnata da Codex (WB-065, art/armi/trap.png): larga come la
# forma a vettori; la luce del colore della squadra è il perno d'ottone
TAGLIOLA_RICALCO = os.path.join(RADICE, "art", "armi", "trap.png")
TAGLIOLA_LARGA = 24


def tagliola_ricalcata():
    import numpy as np
    from PIL import Image
    im = Image.open(TAGLIOLA_RICALCO).convert("RGBA")
    w = round(TAGLIOLA_LARGA * PX)
    h = round(w * im.height / im.width)
    a = np.array(im)
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    ottone = (abs(r - 0xD9) < 30) & (abs(g - 0xA4) < 30) & (abs(b - 0x41) < 40)
    luce = np.zeros_like(a)
    luce[ottone] = (255, 255, 255, 255)
    im.resize((w, h), Image.LANCZOS).save(os.path.join(OUT, "attrezzo_tagliola.png"), optimize=True)
    Image.fromarray(luce, "RGBA").resize((w, h), Image.LANCZOS).save(
        os.path.join(OUT, "attrezzo_tagliola_luce.png"), optimize=True)
    print("attrezzo_tagliola (ricalcata)", w, h, "misura nel mondo", TAGLIOLA_LARGA, round(h / PX, 1))


# la Molla larga e la tagliola chiusa di Codex (WB-068). Il triangolo verde sopra la
# piastra si stacca e si gira di lato: è la freccia del colore della squadra che il
# gioco specchia verso dove la Molla lancia (bianca col contorno nero, si tinge)
MOLLA_RICALCO = os.path.join(RADICE, "art", "armi", "molla.png")
CHIUSA_RICALCO = os.path.join(RADICE, "art", "armi", "tagliola_chiusa.png")
MOLLA_LARGA = 39.2   # TRAMPOLINE.half_w 18, più il bordo
FRECCIA_LARGA = 5.5  # nel gioco più grande che sul foglio, così si legge (ARROW_W di items.lua)
CHIUSA_LARGA = 18


def molla_ricalcata():
    import numpy as np
    from PIL import Image
    im = Image.open(MOLLA_RICALCO).convert("RGBA")
    a = np.array(im)
    larghe = np.nonzero((a[..., 3] > 0).sum(1) > im.width * 0.5)[0]
    taglio = int(larghe[0])  # la prima riga della piastra: sopra c'è solo il triangolo
    corpo = a[taglio:].copy()
    # quel che resta del verde sul bordo della piastra torna ottone
    r, g, b = corpo[..., 0].astype(int), corpo[..., 1].astype(int), corpo[..., 2].astype(int)
    corpo[(g > 140) & (r < 110) & (b < 110), :3] = (0xD9, 0xA4, 0x41)
    # la freccia: il triangolo, chiuso sotto da un contorno nero spesso come gli altri
    BASE = 16
    freccia = a[:taglio + BASE].copy()
    riga = np.nonzero(freccia[taglio - 1, :, 3] > 0)[0]
    freccia[taglio:, :, 3] = 0
    freccia[taglio:, riga.min():riga.max() + 1] = (0, 0, 0, 255)
    r, g, b = freccia[..., 0].astype(int), freccia[..., 1].astype(int), freccia[..., 2].astype(int)
    verde = (g > 140) & (r < 110) & (b < 110)
    freccia[verde, :3] = 255
    # il triangolo è attorno al verde (col suo contorno): fuori c'è solo qualche puntino
    vy, vx = np.nonzero(verde)
    m = 40
    x0, x1 = max(vx.min() - m, 0), vx.max() + m
    freccia = freccia[:, x0:x1]
    ys, xs = np.nonzero(freccia[..., 3] > 0)
    freccia = freccia[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    w = round(MOLLA_LARGA * PX)
    k = w / im.width
    h = round(corpo.shape[0] * k)
    Image.fromarray(corpo, "RGBA").resize((w, h), Image.LANCZOS).save(os.path.join(OUT, "attrezzo_molla.png"),
                                                                       optimize=True)
    f = Image.fromarray(freccia, "RGBA").rotate(-90, expand=True)  # punta a destra
    fw = round(FRECCIA_LARGA * PX * 2)
    fh = round(fw * f.height / f.width)
    assert fw <= f.width
    f.resize((fw, fh), Image.LANCZOS).save(os.path.join(OUT, "attrezzo_molla_freccia.png"), optimize=True)
    print("attrezzo_molla (ricalcata)", w, h, "misura nel mondo", MOLLA_LARGA, round(h / PX, 2),
          "freccia", FRECCIA_LARGA, round(FRECCIA_LARGA * fh / fw, 2))


def chiusa_ricalcata():
    from PIL import Image
    im = Image.open(CHIUSA_RICALCO).convert("RGBA")
    w = round(CHIUSA_LARGA * PX)
    h = round(w * im.height / im.width)
    im.resize((w, h), Image.LANCZOS).save(os.path.join(OUT, "attrezzo_tagliola_chiusa.png"), optimize=True)
    print("attrezzo_tagliola_chiusa (ricalcata)", w, h, "misura nel mondo", CHIUSA_LARGA, round(h / PX, 2))


def main():
    os.makedirs(OUT, exist_ok=True)
    for nome, fn, tinta in (("attrezzo_cubo", cubo, False),
                            ("attrezzo_bolla", bolla, False)):
        d = Disegno(col=COL)
        box = fn(d)
        w, h = round((box[2] - box[0]) * PX), round((box[3] - box[1]) * PX)
        rendi(d.svg(box, PX, tinta=tinta), w, h).save(os.path.join(OUT, nome + ".png"), optimize=True)
        print(nome, w, h, "misura nel mondo", round(box[2] - box[0], 1), round(box[3] - box[1], 1))
    tagliola_ricalcata()
    molla_ricalcata()
    chiusa_ricalcata()
    firme()


# le firme delle armi (WB-066, art/armi/fx_*.png): bianche col contorno nero, il gioco
# le tinge e le anima (client/battle/impact.lua, impact.sign); al massimo FIRMA_PX
# di lato, che è più di quanto si vedono anche con lo zoom più vicino
FIRMA_PX = 192
# quelle che il gioco usa (client/main/game.gui_script): fumo, crepa, cenere, fiamma e
# scintilla restano in art/armi/ per i segni degli stati
FIRME = ["fx_runa", "fx_stella", "fx_fendente", "fx_vento", "fx_anello_fumo", "fx_risucchio", "fx_bolla",
         "fx_guscio", "fx_coccio", "fx_gocce", "fx_coriandolo"]


def firme():
    from PIL import Image
    cartella = os.path.join(RADICE, "art", "armi")
    for nome in FIRME:
        im = Image.open(os.path.join(cartella, nome + ".png")).convert("RGBA")
        k = FIRMA_PX / max(im.size)
        im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS).save(os.path.join(OUT, nome + ".png"),
                                                                                 optimize=True)
        print(nome, "firma")


if __name__ == "__main__":
    main()
