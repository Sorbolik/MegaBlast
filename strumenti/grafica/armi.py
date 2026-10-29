# Le armi del diavoletto, disegnate a vettori (SVG) e convertite in PNG.
# Stile del diavoletto: contorno nero spesso (come il diavoletto), colori pieni con una
# sfumatura semplice (scuro sotto, chiaro sopra) e qualche riga interna.
# Scrive:
#   client/assets/armi/<arma>.png         l'arma in mano (punta verso destra)
#   client/assets/armi/<arma>_tinta.png   le parti col colore della squadra
#                                         (bianche e grigie, il gioco le tinge)
#   client/assets/armi/<arma>_icona.png   l'icona della barra e della scelta
#   client/assets/armi/<proiettile>.png   i colpi in volo (razzo, palla del
#                                         Cecchino, uovo, scheggia, globo)
#   client/battaglia/armi.atlas
#   client/battaglia/armi.lua             misure in unità del mondo, origine
#                                         nella spalla, x avanti e y in su
#   simulazione/foto/armi_anteprima.png   tutte insieme, per guardarle
#
# Le misure sono quelle del mondo (non del corpo, che è BLASTRON_CORPO volte più
# grande): la bocca del Lanciarune a game.MUZZLE, la lama lunga
# game.SWORD_REACH, il Maglio e l'Affondo lunghi config.MALLET.reach e
# config.LUNGE.reach (lì la simulazione colpisce).
#
# python3 strumenti/grafica/armi.py   (serve cairosvg: pip install cairosvg)
import os
import re
import sys
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
RADICE = os.path.join(QUI, "..", "..")
OUT = os.path.join(RADICE, "client", "assets", "armi")
LUA = os.path.join(RADICE, "client", "battaglia", "armi.lua")
ATLAS = os.path.join(RADICE, "client", "battaglia", "armi.atlas")
PRESE = os.path.join(RADICE, "client", "battaglia", "impugnature.lua")
ANTEPRIMA = os.path.join(RADICE, "simulazione", "foto", "armi_anteprima.png")

# pixel delle immagini per unità del mondo: a zoom vicino su un telefono
# un'unità è 4-5 pixel veri. Si disegna al doppio e si rimpicciolisce.
PX = 6
ICONA = 128  # lato delle icone, in pixel
GRANDI = 1.6  # i colpi in volo, più grandi delle loro misure

# misure della simulazione (sim/game.lua, sim/config.lua)
MUZZLE = 14
SWORD_REACH = 40
MALLET_REACH = 44
LUNGE_REACH = 40
H = 28  # altezza del corpo nel mondo, senza BLASTRON_CORPO

from vettori import BORDO, RIGA, INK, COL, Disegno, rendi  # noqa: E402

# ---------------------------------------------------------------------------
# Le armi. Origine nella spalla, x verso dove si mira, y in su. Dove vanno i
# pugni non è qui: lo dice client/battaglia/impugnature.lua, fatto nell'editor
# delle animazioni (l'anteprima lo legge per disegnarli).


def lanciarune(d):
    # tubo rosso da spalla con fasce d'ottone, bocca svasata e rune accese
    L = MUZZLE
    d.poli([(-7.5, -2.2), (-9.5, -3.2), (-9.5, 3.2), (-7.5, 2.2)], "ferro")          # scarico
    d.rect(-7.5, -2.8, L - 2 + 7.5, 5.6, "rosso", r=1.2)                            # tubo
    d.poli([(L - 3, -2.8), (L + 0.6, -4.0), (L + 0.6, 4.0), (L - 3, 2.8)], "ottone")  # bocca
    d.ellisse(L + 0.4, 0, 0.9, 3.2, "ferro", contorno=False)
    d.rect(-6.2, -3.2, 1.6, 6.4, "ottone", r=0.5)                                   # fasce
    d.rect(4.6, -3.2, 1.6, 6.4, "ottone", r=0.5)
    d.rect(-4.0, -1.0, 8.0, 2.0, "bianco", r=1.0, tinta=True)                        # rune
    d.rect(-1.5, 2.8, 3.2, 1.6, "ferro", r=0.4)                                      # mirino
    d.poli([(1.0, -2.8), (3.6, -2.8), (2.6, -6.2), (0.6, -6.0)], "cuoio")            # impugnatura
    d.riga("M-2.8,-0.55 L-1.8,0.55 M-0.6,-0.55 L0.4,0.55 M1.6,-0.55 L2.6,0.55", INK, 0.28)
    d.riga(f"M-7,2 L{L - 3.5},2", COL["rosso"][2], 0.5)
    return dict(box=(-11.5, -8, L + 2.5, 6.5))


def cecchino(d):
    # fucile lungo: calcio di legno, canna d'acciaio, cannocchiale con la lente tinta
    L = MUZZLE + 6
    d.path("M-7,-3.6 L-7,1.4 L0,1.2 L4,1.2 L4,-1.2 L0,-1.6 Z", "legno")               # calcio
    d.rect(2, -1.5, 8, 3.0, "ferro", r=0.6)                                          # castello
    d.rect(9, -0.8, L - 9, 1.6, "acciaio", r=0.4)                                    # canna
    d.rect(L - 1.4, -1.2, 1.6, 2.4, "ferro", r=0.3)                                  # volata
    d.rect(1.5, 2.0, 8, 2.2, "ferro", r=1.0)                                         # cannocchiale
    d.cerchio(9.7, 3.1, 1.4, "bianco", tinta=True)
    d.rect(4.6, 1.2, 1.2, 1.0, "ferro", contorno=False)
    d.poli([(3.6, -1.5), (5.2, -1.5), (4.6, -4.2), (3.2, -4.0)], "legno")           # impugnatura
    d.riga("M-6.2,-0.8 L-1,-0.6", COL["legno"][0], 0.35)
    d.riga(f"M10,0.5 L{L - 1.6},0.5", COL["acciaio"][2], 0.35)
    return dict(box=(-9.5, -6.5, L + 2, 6.5))


def uovo(d, cx=0.0, cy=0.0):
    # uovo di drago rosso con le crepe di fuoco (tinte) e una miccia
    d.ellisse(cx, cy, 3.4, 4.2, "rosso")
    d.path(f"M{cx - 2.6},{cy + 0.8} L{cx - 1.2},{cy - 0.4} L{cx - 0.2},{cy + 1.2} L{cx + 1.2},{cy - 0.2} "
           f"L{cx + 2.7},{cy + 1.0} L{cx + 2.4},{cy - 0.6} L{cx + 1.2},{cy - 1.8} L{cx - 0.2},{cy - 0.4} "
           f"L{cx - 1.2},{cy - 1.9} L{cx - 2.5},{cy - 0.7} Z", "bianco", tinta=True, contorno=False)
    d.rect(cx - 1.3, cy + 3.6, 2.6, 1.3, "ottone", r=0.3)
    d.path(f"M{cx},{cy + 4.9} Q{cx + 1.4},{cy + 6.2} {cx + 0.6},{cy + 7.0}", "fuoco", contorno=False)
    d.riga(f"M{cx},{cy + 4.9} Q{cx + 1.2},{cy + 5.8} {cx + 0.8},{cy + 6.6}", INK, 0.45)
    d.cerchio(cx + 0.8, cy + 6.8, 0.75, "fuoco")
    d.riga(f"M{cx - 2.2},{cy + 2.4} Q{cx - 1.6},{cy + 3.4} {cx - 0.4},{cy + 3.7}", COL["rosso"][2], 0.55)


def uovo_in_mano(d):
    uovo(d, 4.4, 1.6)
    return dict(box=(-0.5, -4.5, 9.5, 11))


def sciame(d):
    # trombone di legno con la bocca a campana piena di schegge di cristallo
    d.path("M-7,-3.4 L-7,1.0 L-1,1.6 L-1,-1.6 Z", "legno")                           # calcio
    d.rect(-1.5, -1.9, 10, 3.8, "legno", r=0.8)                                      # corpo
    d.poli([(8, -1.9), (17.5, -4.6), (17.5, 4.6), (8, 1.9)], "ottone")              # campana
    d.ellisse(17.3, 0, 1.0, 4.2, "ferro", contorno=False)
    for (x, y, a) in [(16.6, 2.4, 30), (17.4, -0.4, 0), (16.4, -2.8, -30)]:          # schegge
        d.poli([(x - 1.2, y - 0.8), (x + 2.6, y + 0.0), (x - 1.2, y + 0.8)], "bianco", tinta=True)
    d.rect(1.8, -2.3, 1.4, 4.6, "ottone", r=0.4)
    d.rect(6.2, -2.3, 1.4, 4.6, "ottone", r=0.4)
    d.poli([(2.2, -1.9), (4.0, -1.9), (3.4, -4.8), (1.8, -4.6)], "cuoio")
    d.riga("M8.5,1.2 L17,3.6", COL["ottone"][2], 0.5)
    return dict(box=(-9.5, -7.5, 20.5, 7.5))


def pugno(d):
    # guanto da titano: un pugno corazzato rosso con le nocche d'ottone
    d.rect(-1.0, -3.4, 4.4, 6.8, "cuoio", r=1.2)                                     # polsino
    d.rect(1.8, -4.4, 8.6, 8.8, "rosso", r=3.4)                                      # pugno
    d.rect(8.0, -4.0, 3.2, 8.0, "ottone", r=1.4)                                     # nocche
    d.cerchio(4.8, 0.0, 1.5, "bianco", tinta=True)                                   # gemma
    d.riga("M8.6,1.35 L10.8,1.35 M8.6,-1.35 L10.8,-1.35", COL["ottone"][0], 0.4)
    d.riga("M3,-4.0 Q5.5,-2.5 8,-4.0", COL["rosso"][0], 0.45)
    d.riga("M3.6,3.4 L7.6,3.4", COL["rosso"][2], 0.6)
    return dict(box=(-3.5, -7, 13.5, 7))


def lama(d):
    # spadone: lama larga d'acciaio col filo chiaro, elsa d'ottone a corna,
    # impugnatura rossa e la gemma tinta
    L = SWORD_REACH
    g = 6.0                                                                          # elsa
    d.rect(-1.6, -1.0, g + 0.6, 2.0, "cuoio", r=0.6)                                 # manico
    d.cerchio(-2.0, 0, 1.5, "ottone")                                                # pomo
    d.path(f"M{g},-1.9 L{L - 4.5},-1.9 L{L},0 L{L - 4.5},1.9 L{g},1.9 Z", "acciaio")  # lama
    d.path(f"M{g + 0.5},0.15 L{L - 4.8},0.15 L{L - 1.2},0.15", "acciaio", contorno=False)
    d.path(f"M{g - 1.2},-4.6 Q{g - 0.2},-2.2 {g - 0.6},0 Q{g - 0.2},2.2 {g - 1.2},4.6 "
           f"L{g + 0.2},4.2 Q{g + 1.3},2.2 {g + 1.2},0 Q{g + 1.3},-2.2 {g + 0.2},-4.2 Z", "ottone")
    d.cerchio(g + 0.1, 0, 1.1, "bianco", tinta=True)
    d.riga(f"M{g + 2},0.9 L{L - 5},0.9", COL["acciaio"][2], 0.55)
    d.riga(f"M{g + 2},-0.2 L{L - 6},-0.2", COL["acciaio"][0], 0.3)
    d.riga("M-0.6,-1 L0.6,1 M1.2,-1 L2.4,1 M3,-1 L4.2,1", COL["cuoio"][0], 0.3)
    return dict(box=(-5, -7, L + 2.5, 7))


def globo(d, cx=0.0, cy=0.0, r=4.2):
    # globo del teletrasporto: vetro scuro con il vortice acceso (tinto)
    d.cerchio(cx, cy, r, "ferro")
    d.path(f"M{cx - r * 0.55},{cy} A{r * 0.55},{r * 0.55} 0 1 1 {cx + r * 0.2},{cy + r * 0.5} "
           f"A{r * 0.3},{r * 0.3} 0 1 0 {cx - r * 0.1},{cy - r * 0.1} Z", "bianco", tinta=True, contorno=False)
    d.cerchio(cx, cy, r * 0.22, "bianco", tinta=True, contorno=False)
    d.riga(f"M{cx - r * 0.6},{cy + r * 0.45} Q{cx - r * 0.2},{cy + r * 0.8} {cx + r * 0.3},{cy + r * 0.72}",
           "#ffffff", r * 0.14)


def globo_in_mano(d):
    globo(d, 4.8, 1.2, 4.2)
    return dict(box=(-0.5, -4.5, 10.5, 7))


def tonante(d):
    # pistolone: canna grossa d'acciaio, tamburo d'ottone, cane a corno, calcio rosso
    d.path("M0.4,-1.0 L3.6,-1.0 L2.6,-6.2 L-0.6,-5.8 Z", "rosso")                    # calcio
    d.rect(0, -1.6, 7.0, 4.2, "ferro", r=0.8)                                        # castello
    d.rect(6.2, -0.2, 11.5, 2.8, "acciaio", r=0.5)                                   # canna
    d.rect(16.6, -0.5, 1.6, 3.4, "ferro", r=0.4)                                     # volata
    d.rect(3.4, -1.2, 3.6, 3.4, "ottone", r=1.0)                                     # tamburo
    d.path("M0.6,2.4 Q-0.6,4.2 -1.8,4.4 Q-0.6,3.0 -0.4,1.6 Z", "osso")              # cane a corno
    d.cerchio(1.6, -3.4, 0.7, "bianco", tinta=True)
    d.riga("M3.9,0.1 L6.5,0.1 M3.9,1.0 L6.5,1.0", COL["ottone"][0], 0.3)
    d.riga("M7,1.9 L16.4,1.9", COL["acciaio"][2], 0.45)
    d.riga("M2.8,-1.6 Q3.6,-3.0 2.6,-3.2", INK, 0.35)
    return dict(box=(-4, -8.5, 20.5, 6.5))


def rampino(d):
    # lanciarampino: tubo di ferro, verricello d'ottone e l'uncino a tre punte
    d.rect(-2.5, -1.5, 15, 3.0, "ferro", r=0.7)
    d.cerchio(2.2, -1.2, 2.2, "ottone")                                              # verricello
    d.cerchio(2.2, -1.2, 0.8, "ferro", contorno=False)
    d.poli([(4.6, -1.4), (6.2, -1.4), (5.6, -4.6), (4.2, -4.4)], "cuoio")
    d.rect(12.5, -0.5, 3.2, 1.0, "acciaio")                                          # asta
    d.path("M15.4,0 L20.6,0 M18.6,0 Q21.6,2.8 19.0,4.4 M18.6,0 Q21.6,-2.8 19.0,-4.4", "acciaio",
           contorno=False)
    d.path("M15.2,-0.7 L19.6,-0.7 Q22.8,-1.5 19.6,-4.8 L18.2,-4.6 Q20.6,-2.4 18.6,-1.9 L18.6,1.9 "
           "Q20.6,2.4 18.2,4.6 L19.6,4.8 Q22.8,1.5 19.6,0.7 L15.2,0.7 Z", "acciaio")
    d.poli([(19.8, -0.6), (22.4, 0), (19.8, 0.6)], "acciaio")
    d.rect(7.5, -0.6, 3.8, 1.2, "bianco", r=0.6, tinta=True)
    d.riga("M-2,0.7 L12,0.7", COL["ferro"][2], 0.4)
    return dict(box=(-5, -7.5, 25, 7.5))


def bastione(d):
    # Bastione: il concio che si posa, pietra scura cerchiata d'ottone come i
    # blocchi in mappa (terreno.fp), retto davanti con le due mani (impugnature.lua)
    d.rect(1.0, -3.4, 11.0, 6.8, "pietra", r=0.8)
    d.rect(0.6, 2.0, 11.8, 1.8, "ottone", r=0.5)                                     # bordo sopra
    d.rect(0.6, -3.8, 11.8, 1.6, "ottone", r=0.5)                                    # bordo sotto
    d.riga("M1.4,-0.2 L11.6,-0.2 M4.6,-2.2 L4.6,-0.2 M8.4,-0.2 L8.4,2.0", COL["pietra"][0], 0.45)
    d.cerchio(6.5, 0.9, 0.8, "bianco", tinta=True)
    return dict(box=(-1, -6, 14, 6))


def maglio(d):
    # Maglio: manico di legno lungo, testa di pietra cerchiata d'ottone; la
    # faccia che batte è sul lato -y (quello che va avanti quando cala)
    R = MALLET_REACH
    T = H * 0.3
    A = H * 0.44
    d.rect(-3, -0.9, R - T + 3.5, 1.8, "legno", r=0.8)                                # manico
    d.rect(-3.6, -1.3, 2.6, 2.6, "ferro", r=0.6)                                     # pomo
    d.rect(R - T, -A / 2, T, A, "pietra", r=1.4)                                     # testa
    d.rect(R - T - 0.3, -A / 2 + 2.0, T + 0.6, 1.4, "ottone", r=0.4)
    d.rect(R - T - 0.3, A / 2 - 3.4, T + 0.6, 1.4, "ottone", r=0.4)
    d.rect(R - T + 0.6, -A / 2 - 0.6, T - 1.2, 1.4, "acciaio", r=0.4)               # faccia che batte
    d.cerchio(R - T / 2, 0, 1.3, "bianco", tinta=True)
    d.rect(4, -1.2, 5, 2.4, "cuoio", r=0.6)                                           # fasciatura
    d.riga("M5,-1 L5.8,1 M6.6,-1 L7.4,1 M8.2,-1 L9,1", COL["cuoio"][0], 0.3)
    d.riga(f"M{R - T + 1},{A / 2 - 1} L{R - 1},{A / 2 - 1}", COL["pietra"][2], 0.5)
    d.riga(f"M{R - T + 2.2},-1.8 L{R - T + 3.6},-0.6 L{R - T + 3},0.8", COL["pietra"][0], 0.35)
    return dict(box=(-6, -A / 2 - 3, R + 2.5, A / 2 + 2.5))


def affondo(d):
    # Affondo: il forcone del diavolo, asta di legno scuro e tre punte rosse
    # come la coda; la punta centrale arriva a config.LUNGE.reach
    R = LUNGE_REACH
    d.rect(-7, -0.8, R - 6 + 7, 1.6, "legno", r=0.7)                                 # asta
    d.rect(R - 10.8, -1.2, 2.4, 2.4, "ottone", r=0.4)                                 # ghiera
    d.path(f"M{R - 7},-4.6 Q{R - 7.4},0 {R - 7},4.6 L{R - 5.2},4.6 Q{R - 5.6},0 {R - 5.2},-4.6 Z", "rosso")  # traversa
    d.poli([(R - 5.6, -1.0), (R, 0), (R - 5.6, 1.0)], "rosso")                        # punta
    d.path(f"M{R - 6.4},3.2 Q{R - 3},3.4 {R - 1.2},5.2 Q{R - 3.4},5.4 {R - 6.4},4.8 Z", "rosso")
    d.path(f"M{R - 6.4},-3.2 Q{R - 3},-3.4 {R - 1.2},-5.2 Q{R - 3.4},-5.4 {R - 6.4},-4.8 Z", "rosso")
    d.cerchio(R - 9.6, 0, 0.75, "bianco", tinta=True, contorno=False)
    d.riga(f"M-6,0.45 L{R - 9},0.45", COL["legno"][2], 0.35)
    return dict(box=(-9.5, -7.5, R + 2.5, 7.5))


# I colpi in volo: origine nel centro, x nel verso in cui vanno

def razzo(d):
    d.poli([(-4.4, -2.4), (-2.2, -1.0), (-2.2, 1.0), (-4.4, 2.4)], "ottone")         # alette
    d.rect(-3.2, -1.3, 6.0, 2.6, "rosso", r=1.2)
    d.path("M2.4,-1.3 Q5.4,0 2.4,1.3 Z", "ottone")
    d.rect(-1.0, -0.5, 2.2, 1.0, "bianco", r=0.5, tinta=True)
    return dict(box=(-6.5, -4.5, 6.5, 4.5))


def palla(d):
    # la palla del Cecchino: rimbalza, la allunga il gioco
    d.cerchio(0, 0, 2.2, "acciaio")
    d.rect(-2.2, -0.45, 4.4, 0.9, "bianco", tinta=True, contorno=False)
    d.riga("M-1.1,1.2 Q0,1.8 1.0,1.3", "#ffffff", 0.45)
    return dict(box=(-4, -4, 4, 4))


def uovo_volo(d):
    uovo(d, 0, -1.4)
    return dict(box=(-5.5, -7.5, 5.5, 7.5))


def scheggia(d):
    d.poli([(-2.6, -1.1), (3.2, 0), (-2.6, 1.1), (-1.6, 0)], "bianco", tinta=True)
    return dict(box=(-4.5, -3, 5, 3))


def globo_volo(d):
    globo(d, 0, 0, 3.2)
    return dict(box=(-5, -5, 5, 5))


# nome nel gioco: disegno, angolo dell'icona (gradi, verso l'alto a destra;
# None: senza icona)
ARMI = {
    "missile": (lanciarune, 35),
    "sniper": (cecchino, 35),
    "grenade": (uovo_in_mano, 0),
    "shards": (sciame, 35),
    "punch": (pugno, 20),
    "sword": (lama, 45),
    "teleport": (globo_in_mano, None),  # il pulsante usa il globo in volo
    "eagle": (tonante, 25),
    "hook": (rampino, 35),
    "wall": (bastione, 0),
    "mallet": (maglio, 45),
    "lunge": (affondo, 45),
}
COLPI = {
    "razzo": razzo,
    "palla": palla,
    "uovo": uovo_volo,
    "scheggia": scheggia,
    "globo": globo_volo,
}


def esporta(nome, d, box, out, px=PX):
    w = round((box[2] - box[0]) * px)
    h = round((box[3] - box[1]) * px)
    base = rendi(d.svg(box, px), w, h)
    base.save(os.path.join(OUT, nome + ".png"), optimize=True)
    out.append(nome)
    tinta = None
    if any(t for _, _, t, _ in d.forme):
        tinta = rendi(d.svg(box, px, tinta=True), w, h)
        tinta.save(os.path.join(OUT, nome + "_tinta.png"), optimize=True)
        out.append(nome + "_tinta")
    return base, tinta, w, h


def icona(nome, d, box, rot, out):
    # l'arma ruotata, adattata al quadrato con un margine
    import math
    x0, y0, x1, y1 = box
    a = math.radians(rot)
    bw, bh = x1 - x0, y1 - y0
    rw = abs(bw * math.cos(a)) + abs(bh * math.sin(a))
    rh = abs(bw * math.sin(a)) + abs(bh * math.cos(a))
    scala = ICONA * 0.9 / max(rw, rh)
    svg = d.svg(box, scala, rot=rot, lato=ICONA)
    # nell'icona il bordo è più spesso: si legge anche piccola
    svg = svg.replace(f'stroke-width="{BORDO * 2}"', f'stroke-width="{BORDO * 2 * max(1, 14 / scala / 1.5)}"')
    im = rendi(svg, ICONA, ICONA)
    tin = None
    if any(t for _, _, t, _ in d.forme):
        tin = rendi(d.svg(box, scala, tinta=True, rot=rot, lato=ICONA), ICONA, ICONA)
    # nell'icona le parti tinte hanno il colore delle primarie (brace)
    if tin:
        brace = Image.new("RGBA", tin.size, (255, 150, 60, 255))
        from PIL import ImageChops
        col = ImageChops.multiply(tin, brace)
        col.putalpha(tin.getchannel("A"))
        im = Image.alpha_composite(im, col)
    im.save(os.path.join(OUT, nome + "_icona.png"), optimize=True)
    out.append(nome + "_icona")
    return im


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith(".png"):
            os.remove(os.path.join(OUT, f))
    immagini = []
    lua = ["-- Fatto da strumenti/grafica/armi.py, non modificare a mano.",
           "-- Le armi in unità del mondo: origine nella spalla (i colpi nel centro),",
           "-- x avanti e y in su. Per ogni arma: immagine (tinta: le parti col colore",
           "-- della squadra), centro (x, y) e misura (w, h). Dove vanno i pugni:",
           "-- battaglia/impugnature.lua.",
           "return {", "\tarmi = {"]
    foglio = []
    prese = impugnature()
    for nome, (fn, rot) in ARMI.items():
        d = Disegno()
        info = fn(d)
        box = info["box"]
        base, tinta, w, h = esporta(nome, d, box, immagini)
        ic = icona(nome, d, box, rot, immagini) if rot is not None else None
        cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
        t = f'"{nome}_tinta"' if tinta else "nil"
        lua.append(f'\t\t{nome} = {{ img = "{nome}", tinta = {t}, x = {cx:.2f}, y = {cy:.2f}, '
                   f'w = {box[2] - box[0]:.2f}, h = {box[3] - box[1]:.2f} }},')
        foglio.append((nome, base, tinta, ic, box, prese.get(nome, [])))
    lua.append("\t},")
    lua.append("\tcolpi = {")
    colpi = []
    for nome, fn in COLPI.items():
        d = Disegno()
        info = fn(d)
        box = info["box"]
        # in volo si disegnano GRANDI volte: piccoli come in mano non si leggono
        base, tinta, w, h = esporta(nome, d, box, immagini, PX * GRANDI)
        cx, cy = (box[0] + box[2]) / 2 * GRANDI, (box[1] + box[3]) / 2 * GRANDI
        t = f'"{nome}_tinta"' if tinta else "nil"
        lua.append(f'\t\t{nome} = {{ img = "{nome}", tinta = {t}, x = {cx:.2f}, y = {cy:.2f}, '
                   f'w = {(box[2] - box[0]) * GRANDI:.2f}, h = {(box[3] - box[1]) * GRANDI:.2f} }},')
        colpi.append((nome, base, tinta))
    lua.append("\t},")
    lua.append("}")
    with open(LUA, "w") as f:
        f.write("\n".join(lua) + "\n")
    with open(ATLAS, "w") as f:
        for n in immagini:
            f.write(f'images {{\n  image: "/assets/armi/{n}.png"\n}}\n')
        f.write("margin: 0\nextrude_borders: 2\ninner_padding: 0\n")
    anteprima(foglio, colpi)


def impugnature():
    # battaglia/impugnature.lua: nome = { { x, y }, ... }
    prese = {}
    with open(PRESE) as f:
        for nome, punti in re.findall(r"^\s*(\w+)\s*=\s*\{(.*)\},?\s*$", f.read(), re.M):
            prese[nome] = [(float(x), float(y)) for x, y in re.findall(r"\{\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\}", punti)]
    return prese


def tingi(im, rgb):
    from PIL import ImageChops
    col = ImageChops.multiply(im, Image.new("RGBA", im.size, rgb + (255,)))
    col.putalpha(im.getchannel("A"))
    return col


def anteprima(foglio, colpi):
    from PIL import ImageDraw
    squadre = [(230, 72, 77), (47, 191, 113), (245, 197, 24), (75, 107, 251)]
    righe = []
    for i, (nome, base, tinta, ic, box, mani) in enumerate(foglio):
        im = base.copy()
        if tinta:
            im = Image.alpha_composite(im, tingi(tinta, squadre[i % 4]))
        # i pugni, come li mette il gioco (pelle col contorno scuro)
        dr = ImageDraw.Draw(im)
        for x, y in mani:
            px, py = (x - box[0]) * PX, (box[3] - y) * PX
            r = 2.8 * PX * 0.5 * 1.0
            dr.ellipse([px - r - 3, py - r - 3, px + r + 3, py + r + 3], fill=(20, 18, 24, 255))
            dr.ellipse([px - r, py - r, px + r, py + r], fill=(194, 184, 163, 255))
        righe.append((nome, im, ic))
    K = 2
    larg = max(im.width for _, im, _ in righe) * K + ICONA + 60
    alt = sum(max(im.height * K, ICONA) + 16 for _, im, _ in righe) + 220
    sheet = Image.new("RGBA", (larg, alt), (122, 138, 128, 255))
    y = 10
    for nome, im, ic in righe:
        hh = max(im.height * K, ICONA)
        if ic:
            sheet.alpha_composite(ic, (10, y + (hh - ICONA) // 2))
        big = im.resize((im.width * K, im.height * K), Image.LANCZOS)
        sheet.alpha_composite(big, (ICONA + 40, y + (hh - big.height) // 2))
        y += hh + 16
    x = 10
    for i, (nome, base, tinta) in enumerate(colpi):
        im = base.copy()
        if tinta:
            im = Image.alpha_composite(im, tingi(tinta, squadre[i % 4]))
        big = im.resize((im.width * 2, im.height * 2), Image.LANCZOS)
        sheet.alpha_composite(big, (x, y + 10))
        x += big.width + 24
    os.makedirs(os.path.dirname(ANTEPRIMA), exist_ok=True)
    sheet.save(ANTEPRIMA)


if __name__ == "__main__":
    main()
