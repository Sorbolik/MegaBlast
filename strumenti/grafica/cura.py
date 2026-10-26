# Il cerchio di cura, disegnato a vettori come le armi e il diavoletto
# (vettori.py): un anello di pietra a terra con le rune accese, un cuore che
# galleggia sopra e una scintilla che sale. Il gioco (battaglia/oggetti.lua)
# li anima: l'anello pulsa, il cuore dondola, le scintille salgono.
# Scrive client/assets/fx/cura_*.png (vanno in client/battaglia/battaglia.atlas).
#
# python3 strumenti/grafica/cura.py   (serve cairosvg: pip install cairosvg)
import os
import sys

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
RADICE = os.path.join(QUI, "..", "..")
OUT = os.path.join(RADICE, "client", "assets", "fx")

from vettori import COL, INK, RIGA, Disegno, rendi  # noqa: E402

PX = 6   # pixel per unità del mondo, come le armi
R = 26   # raggio del cerchio nella simulazione (sim/config.lua, HEAL.r)
SCHIACCIA = 0.32  # l'anello visto di taglio

COL = dict(COL)
COL.update({
    "verde": ("#1f8a4c", "#46d27a", "#a8ffc8"),
    "verde_scuro": ("#0e4a2a", "#1c7a44", "#2fa85e"),
    "cuore": ("#1f8a4c", "#5ae08c", "#c8ffdc"),
})


def anello(d):
    # la pietra: un anello d'ellisse con il fossato verde acceso in mezzo
    ry = R * SCHIACCIA
    d.ellisse(0, 0, R, ry, "pietra")
    d.ellisse(0, 0, R * 0.8, ry * 0.8, "verde", contorno=False)
    d.ellisse(0, 0, R * 0.62, ry * 0.62, "pietra", contorno=False)
    d.ellisse(0, 0, R * 0.52, ry * 0.52, "verde_scuro", contorno=False)
    # le rune: tacche chiare sul fossato
    for i in range(8):
        import math
        a = i / 8 * 2 * math.pi + 0.3
        x, y = math.cos(a) * R * 0.71, math.sin(a) * ry * 0.71
        d.riga(f"M{x - 0.9},{y} L{x + 0.9},{y}", COL["verde"][2], RIGA * 2)
    return (-R - 2, -ry - 2, R + 2, ry + 2)


def cuore(d):
    d.path("M0,-6 C-7,0 -8,5 -5,8 C-3,10 -1,9 0,7 C1,9 3,10 5,8 C8,5 7,0 0,-6 Z", "cuore")
    d.riga("M-4,5 Q-5,3 -4,1", COL["cuore"][2], RIGA * 1.6)
    return (-10, -9, 10, 12)


def scintilla(d):
    d.path("M0,-3 Q0.6,-0.6 3,0 Q0.6,0.6 0,3 Q-0.6,0.6 -3,0 Q-0.6,-0.6 0,-3 Z", "cuore", contorno=False)
    return (-4, -4, 4, 4)


def main():
    os.makedirs(OUT, exist_ok=True)
    for nome, fn in (("cura_anello", anello), ("cura_cuore", cuore), ("cura_scintilla", scintilla)):
        d = Disegno(col=COL)
        box = fn(d)
        w, h = round((box[2] - box[0]) * PX), round((box[3] - box[1]) * PX)
        rendi(d.svg(box, PX), w, h).save(os.path.join(OUT, nome + ".png"), optimize=True)
        print(nome, w, h, "misura nel mondo", box[2] - box[0], box[3] - box[1])


if __name__ == "__main__":
    main()
