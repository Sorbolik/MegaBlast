# Gli attrezzi in battaglia, disegnati a vettori come le armi (vettori.py):
# il cubo di ferro in cui cadono trappola, scudo e trampolino (sopra il gioco
# mette l'icona dell'attrezzo), la tagliola posata (aperta) e scattata
# (chiusa), il trampolino (la Molla) e la bolla dello scudo addosso.
# Le parti "luce" sono bianche: il gioco le tinge col colore della squadra.
# Scrive client/assets/fx/attrezzo_*.png (vanno in client/battle/battle.atlas).
#
# python3 tools/grafica/attrezzi.py   (serve cairosvg: pip install cairosvg)
import math
import os
import sys

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
RADICE = os.path.join(QUI, "..", "..")
OUT = os.path.join(RADICE, "client", "assets", "fx")

from vettori import COL, INK, Disegno, rendi  # noqa: E402

PX = 6   # pixel per unità del mondo, come le armi
COL = dict(COL)
COL.update({
    "ruggine": ("#5a2e1c", "#8a4a2a", "#b8743f"),
    "telo": ("#8f2a12", "#d9451c", "#ff8a55"),
})


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


def tagliola_aperta(d):
    # la tagliola posata, vista di lato: la piastra a terra e le due ganasce
    # aperte e distese coi denti in su; la placca al centro si accende
    d.rect(-12, 0, 24, 2.2, "ferro", r=1.0)
    for lato in (-1, 1):
        x0 = lato * 2.2
        d.path(f"M{x0},1.2 L{lato * 12.6},1.2 L{lato * 12.0},3.4 L{x0},3.0 Z", "acciaio")
        for i in range(4):
            x = lato * (4.2 + i * 2.2)
            d.poli([(x - 0.8, 3.0), (x, 5.4), (x + 0.8, 3.0)], "osso")
    d.rect(-2.6, 1.6, 5.2, 1.8, "bianco", r=0.6, tinta=True)
    d.cerchio(0, 1.2, 1.0, "ottone")
    return (-14, -1.6, 14, 7)


def tagliola_chiusa(d):
    # scattata: le ganasce si chiudono in alto, i denti si incastrano
    d.rect(-6, 0, 12, 2.2, "ferro", r=1.0)
    for lato in (-1, 1):
        d.path(f"M{lato * 5.4},1.4 Q{lato * 8.4},9.0 0,13.2 L0,11.0 Q{lato * 5.8},8.0 {lato * 3.6},1.4 Z", "acciaio")
    for i in range(4):
        y = 4.6 + i * 2.0
        d.poli([(-0.2, y - 0.8), (1.4, y), (-0.2, y + 0.8)], "osso", contorno=False)
        d.poli([(0.2, y + 0.2), (-1.4, y + 1.0), (0.2, y + 1.8)], "osso", contorno=False)
    d.cerchio(0, 1.2, 1.0, "ottone")
    return (-10.4, -1.6, 10.4, 15)


def molla(d):
    # la Molla: una tavola imbottita su una molla a spirale e una base di
    # ferro, larga come nella simulazione (TRAMPOLINE.half_w 18)
    d.rect(-14, 0, 28, 2.6, "ferro", r=1.2)
    for i in range(4):
        d.ellisse(0, 3.6 + i * 1.5, 5.6 - i * 0.3, 1.0, "ottone")
    d.rect(-18, 8.6, 36, 3.6, "telo", r=1.8)
    d.riga("M-15,11.2 L15,11.2", COL["telo"][2], 0.6)
    return (-19.6, -1.6, 19.6, 13.8)


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


def main():
    os.makedirs(OUT, exist_ok=True)
    for nome, fn, tinta in (("attrezzo_cubo", cubo, False), ("attrezzo_tagliola", tagliola_aperta, False),
                            ("attrezzo_tagliola_luce", tagliola_aperta, True),
                            ("attrezzo_tagliola_chiusa", tagliola_chiusa, False), ("attrezzo_molla", molla, False),
                            ("attrezzo_bolla", bolla, False)):
        d = Disegno(col=COL)
        box = fn(d)
        w, h = round((box[2] - box[0]) * PX), round((box[3] - box[1]) * PX)
        rendi(d.svg(box, PX, tinta=tinta), w, h).save(os.path.join(OUT, nome + ".png"), optimize=True)
        print(nome, w, h, "misura nel mondo", round(box[2] - box[0], 1), round(box[3] - box[1], 1))


if __name__ == "__main__":
    main()
