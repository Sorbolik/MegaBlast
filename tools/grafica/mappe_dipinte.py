# Le mappe dipinte della campagna, dagli SVG alle immagini del gioco (Sergio, 2 nov 2026:
# «partire dall'svg per creare la texture per ogni schermo»).
#
# Scrive, per ogni densità di schermo (1 = normale, 2 = alta, vedi DENSITA):
#   client/paintings/mappe/<mappa>_<d>.png      il terreno disegnato, 1920 x 1080 per d
#   client/paintings/sfondi/<girone>_*_<d>.png  il cielo e i tre gruppi di piani dello sfondo
#   client/battle/paintings.lua              misure e velocità che servono allo shader
#   tools/grafica/mappe/<mappa>.png       la maschera di collisione (bianco terra, rosso
#                                             acciaio), che mappa_in_lua.py porta in sim/mapdata.lua
# Le mappe: il pavimento e la fossa del Fabbro (documento delle mappe dell'apprendista, layout A
# e C, scelte di Sergio del 2 novembre), il cortile del Duello con Favilla (cortile.py) e le
# arene delle missioni, lette da sim/levels.lua con luajit: quelle del cortile dipinte come il
# cortile (cortile.py), le altre d'acciaio.
# I gironi (docs/campagna_gironi.md): una mappa e uno sfondo per girone, nella tinta di temi.py, divisi
# fra i suoi livelli come la Forgia: il Limbo, la Lussuria, la Gola, l'Avarizia, l'Ira, l'Eresia, la Violenza (il
# Flegetonte e il Sabbione), la Frode (le Malebolge), il Tradimento (il Cocito) e l'arena di Lucifero (layout qui sotto, scene
# di tavole.py). Il pericolo di ogni girone sta in client/sim/maps.lua e hazards.lua.
# Gli sfondi: la Forgia (tavole.py) e il cortile (cortile.py), con la stessa tinta.
#
#   python3 tools/grafica/mappe_dipinte.py      (dalla cartella del repository; serve node
#                                                    con playwright, che disegna gli SVG)
import json, os, random, subprocess, sys, tempfile
from PIL import Image, ImageDraw

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
sys.path.insert(0, os.path.join(QUI, "gironi"))
from tavole import FORGIA, LIMBO, LUSSURIA, GOLA, AVARIZIA, IRA, ERESIA, VIOLENZA, FRODE, TRADIMENTO, tronco   # noqa: E402
from mondo import blocco, scheggia, fungo, arco                # noqa: E402
from scena import acqua                                        # noqa: E402
from volume import forma, solido                               # noqa: E402
from scena import mix, W, H, MARGINE                                    # noqa: E402
from dipinto import piani, raggi, grade, DEFS, GRUPPI          # noqa: E402
from temi import TEMI                                          # noqa: E402
import cortile                                                 # noqa: E402
import sfondi as sfondi_gironi                                 # noqa: E402

OUT = os.path.join(RADICE, "client", "paintings")
MASCHERE = os.path.join(QUI, "mappe")
LUA = os.path.join(RADICE, "client", "battle", "paintings.lua")

# quanti pixel dell'immagine per pixel della scena (1280 x 720), per densità e per pezzo:
# i piani lontani sono morbidi e si vedono piccoli, bastano meno pixel. Il terreno è per il
# mondo (1920 x 1080 = scena x 1,5). Nessuna immagine più larga di 4096.
DENSITA = {
    1: dict(terreno=1.0, cielo=0.5, lontano=0.5, medio=0.75, vicino=1.0),
    2: dict(terreno=1.5, cielo=1.0, lontano=1.0, medio=1.2, vicino=1.6),
}
# i piani: quanto seguono la camera (0 fermi, 1 come la mappa) e la velocità dello scorrimento
# «calmo» del documento delle mappe: il piano più vicino a 20 pixel al secondo
QUANTO = dict(lontano=0.1, medio=0.3, vicino=0.6)
CALMO = 20 / 0.75

# ---------------------------------------------------------------- i layout (scena 1280 x 720)
# Niente muretti ai lati (Sergio, 11 nov): il suolo arriva al bordo e oltre si cade; i muri di lato
# restano solo nel cortile (cortile.py)
SUOLO = [(0, 560), (250, 560), (310, 500), (560, 500), (620, 560), (860, 560), (920, 500), (1280, 500),
         (1280, 760), (0, 760)]
SOPRA = [scheggia(110, 300, 130, 50), blocco(300, 180, 90, 28), fungo(380, 330, 180, 26, 170, 22),
         scheggia(590, 250, 110, 44), scheggia(690, 410, 100, 40), blocco(960, 230, 140, 38), arco(960, 370, 230, 130, 30, 40)]
TRAVI = [(400, 140, 140, 16), (740, 330, 130, 16)]
SX = [(0, 560), (250, 560), (310, 500), (560, 500), (620, 560), (680, 560), (680, 760), (0, 760)]
DX = [(790, 560), (860, 560), (920, 500), (1280, 500), (1280, 760), (790, 760)]



# Le mappe un po' più piccole (Sergio, 11 nov: «più piccola vuol dire che vediamo un po' meglio la
# mappa»): lo stesso disegno stretto attorno al centro del gioco, i personaggi restano grandi uguali;
# la camera inquadra il terreno (camera.from_terrain), quindi a zoom lontano lo mostra più grande.
# Il fondo del terreno (y >= 740) resta sotto il quadro. Gli stessi numeri in client/sim/maps.lua.
PICCOLA, PICCOLA_C = .8, (640, 500)


def stringi(ps):
    """Punti [(x, y)] della scena stretti di PICCOLA attorno a PICCOLA_C."""
    cx, cy = PICCOLA_C
    return [(cx + (x - cx) * PICCOLA, 760 if y >= 740 else cy + (y - cy) * PICCOLA) for x, y in ps]


def stringi_rett(x, y, w, h):
    (x0, y0), = stringi([(x, y)])
    return (x0, y0, w * PICCOLA, h * PICCOLA)


# ---------------------------------------------------------------- i gironi (scena 1280 x 720)
# I · Limbo, il castello dei sette muri: terrazza alta a sinistra, gradoni che scendono verso il centro
# con tre monconi di colonne spezzate, la riva bassa a destra che si rialza in fondo; rovine e colonne
# sospese (gravità ridotta: si salta il doppio). Nessun muro di lato.
LIMBO_SUOLO = [(0, 400), (140, 400), (200, 460), (290, 460), (350, 520), (440, 520), (440, 480), (480, 480), (480, 520),
               (560, 520), (620, 570), (700, 570), (700, 530), (760, 530), (760, 570), (860, 570), (900, 540),
               (980, 540), (1030, 500), (1090, 500), (1130, 440), (1160, 440), (1200, 480), (1280, 480),
               (1280, 760), (0, 760)]
LIMBO_SOPRA = [fungo(230, 330, 150, 24, 90, 22), fungo(800, 330, 150, 24, 90, 22), scheggia(520, 210, 170, 56),
               blocco(60, 250, 110, 26), blocco(1010, 300, 100, 26), scheggia(390, 400, 110, 40), scheggia(960, 170, 120, 40)]

# II · Lussuria, la bufera: due scogliere a zig-zag diverse (larga a sinistra, stretta e alta a destra)
# con la gola in mezzo (cadere è morire), schegge nel vuoto e spuntoni d'acciaio dove aggrapparsi col Rampino
LUSS_SX = [(0, 400), (110, 400), (170, 460), (300, 460), (340, 540), (430, 540), (470, 580), (500, 580), (500, 760), (0, 760)]
LUSS_DX = [(780, 760), (780, 610), (810, 610), (850, 570), (930, 570), (970, 520), (1040, 520), (1080, 440), (1150, 440),
           (1190, 380), (1280, 380), (1280, 760)]
LUSS_SOPRA = [scheggia(590, 470, 100, 42), scheggia(560, 320, 120, 46), scheggia(80, 280, 130, 48), scheggia(1090, 250, 130, 48)]
LUSS_SPUNTONI = [[(500, 610), (590, 622), (500, 640)], [(500, 675), (570, 685), (500, 700)],
                 [(780, 640), (700, 652), (780, 668)], [(780, 700), (710, 710), (780, 722)],
                 [(230, 460), (255, 408), (280, 460)], [(985, 520), (1010, 468), (1035, 520)]]

# III · Gola, la conca di fango: la sporgenza alta a sinistra, collinette, due pozze che rallentano
# (stessi numeri in client/sim/maps.lua: mud) e a destra un gradino che sale e un ripiano basso
GOLA_SUOLO = stringi([(0, 380), (250, 380), (330, 470), (400, 470), (440, 530), (540, 530), (580, 490),
              (700, 490), (740, 530), (840, 530), (880, 490), (950, 490), (1000, 430), (1090, 430), (1130, 500),
              (1280, 500), (1280, 760), (0, 760)])
GOLA_SOPRA = [stringi(p) for p in (scheggia(540, 330, 150, 52), blocco(950, 290, 130, 30), scheggia(330, 270, 110, 42), blocco(1110, 330, 100, 26))]
# x, y della superficie, larghezza (strette come la mappa: 480 e 720 a 524, larghe 80)
GOLA_POZZE = [(x, y, w * PICCOLA) for (x, y), w in ((stringi([(440, 530)])[0], 100), (stringi([(740, 530)])[0], 100))]
GOLA_TRAVI = [stringi_rett(700, 420, 100, 16)]


# Niente muretti di lato né sporgenze (Sergio, 11 nov: solo il cortile li tiene) e le mappe sono
# asimmetriche: dai bordi si cade e si muore.
# VII · Violenza. Il Flegetonte: una riva sinistra larga a gradoni e una destra alta e stretta, in mezzo il
# fiume di sangue (cadere è morire) con tre sassi per attraversare; tronchi morti che fermano i colpi
# finché non li spezzi, una pedana in alto a destra, due pozze di sangue che bruciano (stessi numeri
# in client/sim/maps.lua: blood)
FLEG_SX = [(60, 400), (190, 400), (250, 470), (330, 470), (380, 520), (500, 520), (500, 760), (60, 760)]
FLEG_DX = [(790, 760), (790, 560), (850, 560), (900, 500), (1000, 500), (1040, 440), (1140, 440), (1180, 380),
           (1240, 380), (1240, 760)]
FLEG_SOPRA = [blocco(525, 535, 65, 22), blocco(612, 520, 65, 22), blocco(700, 540, 60, 22),
              tronco(215, 360, 34, [(430, "dx", 60)], fondo=470),
              tronco(1090, 300, 34, [(380, "sx", 80)], fondo=440),
              blocco(880, 330, 100, 22), blocco(250, 300, 90, 22)]
FLEG_SANGUE = [(400, 520, 80), (800, 560, 50)]        # x, y della superficie, larghezza

# Il Sabbione: piatto, dune di altezze diverse, nessun riparo; sopra piove fuoco, ai lati il vuoto
SABBIA = stringi([(40, 500), (220, 500), (300, 450), (420, 450), (500, 520), (700, 520), (780, 560), (900, 560), (960, 500),
          (1100, 500), (1160, 440), (1240, 440), (1240, 760), (40, 760)])

# VIII · Frode, le Malebolge: tre terrazze a quote diverse e due fosse di pece larghe 54, ognuna con
# un ponte crepato che crolla (client/sim/maps.lua: bridges; stessi numeri qui)
BOLGE_PONTI = [(330, 470, 54, 12), (840, 540, 54, 12)]
BOLGE_SUOLO = [(60, 470), (330, 470), (340, 640), (374, 640), (384, 470), (700, 470), (760, 540), (840, 540), (850, 640),
               (884, 640), (894, 540), (1100, 540), (1150, 490), (1240, 490), (1240, 760), (60, 760)]
BOLGE_SOPRA = [scheggia(140, 330, 110, 40), blocco(560, 400, 90, 20), blocco(1000, 410, 100, 22)]

# IX · Tradimento, il Cocito: lastre di ghiaccio sottili sull'acqua gelata, a quote diverse, separate da
# crepe di 28, dove si scivola e le esplosioni bucano; sotto e di lato cadere è morire
COC_SOPRA = [stringi(p) for p in (blocco(60, 520, 340, 40), blocco(428, 490, 372, 40), blocco(828, 540, 172, 40), blocco(1028, 500, 212, 40),
             blocco(120, 370, 120, 26), scheggia(640, 320, 110, 50), blocco(1080, 390, 100, 24))]

# L'arena di Lucifero: il lago largo, il pozzo in mezzo (160) con due lastre per passarlo, rive a quote
# diverse e due piattaforme alte; le ali spingono ai bordi, che sono il vuoto
LUC_SX = [(60, 530), (560, 530), (560, 570), (60, 570)]
LUC_DX = [(720, 510), (1240, 510), (1240, 550), (720, 550)]
LUC_SOPRA = [blocco(582, 530, 44, 20), blocco(654, 520, 44, 20), blocco(150, 400, 150, 26), blocco(960, 380, 170, 26)]


def sangue(r):
    """Il sangue bollente delle pozze del Flegetonte: rosso scuro con un velo lucido e bolle."""
    s = ""
    for x, y, w in FLEG_SANGUE:
        s += ('<rect x="%g" y="%g" width="%g" height="14" rx="6" fill="#5a0f14"/><rect x="%g" y="%g" width="%g" height="4" rx="2" fill="#e0524a" opacity=".7"/>'
              % (x, y - 4, w, x + 8, y - 2, w - 16))
        for k in range(1, 4):
            s += '<circle class="pulsa" cx="%g" cy="%g" r="%g" fill="none" stroke="#ffb08a" stroke-width="1.5" opacity=".7"/>' % (x + k * w / 4, y + 1, 3 + k % 2)
    return s


def ponti_crepati(r):
    """Il legno scuro dei ponti che crollano, con le crepe, e la pece nelle fosse."""
    s = ""
    for x, y, w, h in BOLGE_PONTI:
        s += '<rect x="%g" y="%g" width="%g" height="%g" fill="#4a3d2c" stroke="#1a1208" stroke-width="2"/>' % (x, y, w, h)
        s += '<polyline points="%g,%g %g,%g %g,%g %g,%g" fill="none" stroke="#0d0a05" stroke-width="2"/>' % (
            x + w * .3, y, x + w * .38, y + h * .5, x + w * .3, y + h * .7, x + w * .42, y + h)
        s += '<polyline points="%g,%g %g,%g %g,%g" fill="none" stroke="#ffb03a" stroke-width="1.5" opacity=".8"/>' % (
            x + w * .7, y, x + w * .64, y + h * .5, x + w * .72, y + h)
        s += '<polygon points="%g,%d %g,%d %g,%d %g,%d" fill="#050505" stroke="#2a3a10" stroke-width="2"/>' % (
            x + 6, y + h, x + w - 6, y + h, x + w - 14, 636, x + 14, 636)
    return s


def pozze(r):
    """Fango scuro con un velo lucido, nelle pozze della Gola."""
    s = ""
    for x, y, w in GOLA_POZZE:
        s += ('<rect x="%g" y="%g" width="%g" height="14" rx="6" fill="#3b3623"/><rect x="%g" y="%g" width="%g" height="4" rx="2" fill="#8d8a5e" opacity=".7"/>'
              % (x, y - 4, w, x + 8, y - 2, w - 16))
        for k in range(1, 5):
            s += '<ellipse cx="%g" cy="%g" rx="7" ry="2.5" fill="#6e6a43" opacity=".55"/>' % (x + k * w / 5 + (k % 2) * 4, y + 3)
    return s


def spuntoni(g, P):
    """I spuntoni d'acciaio (indistruttibili) di una mappa, disegnati come il ferro del cortile."""
    m = {k: (grade(v, "materiale", P) if isinstance(v, str) and v.startswith("#") and len(v) == 7 else v) for k, v in g["mat"].items()}
    ferro = dict(m, corpo=mix(m["acciaio"], "#000000", .25), crosta=mix(m["acciaio"], m["acciaio_luce"], .35), motivo="venature")
    return solido(g["acciaio"], ferro, dict(g, ombra=0), random.Random(3))

# IV · Avarizia, la valle dei massi: un pendio lungo e alto a sinistra, uno corto a destra con un gradino, un
# piano in mezzo; in cima a ogni pendio parte un masso a fine giro (client/sim/maps.lua: rocks); monete d'oro
# sul piano. Niente muretti ai lati: i bordi sono mortali (Sergio, 11 nov)
AVAR_SUOLO = [(-100, 300), (120, 300), (380, 560), (760, 560), (900, 420), (1040, 420), (1100, 360), (1380, 360), (1380, 760), (-100, 760)]
AVAR_SOPRA = [blocco(520, 400, 180, 26), scheggia(230, 200, 130, 48), scheggia(1000, 200, 150, 48), blocco(700, 290, 140, 26)]
AVAR_TRAVI = [(600, 150, 140, 16)]


def monete(r):
    """Gemme d'oro sul piano della valle e un mucchietto contro il pendio corto."""
    s = "".join('<rect x="%d" y="%d" width="9" height="9" fill="#ffd25a" stroke="#5a3a10" stroke-width="2" transform="rotate(45 %d %d)"/>'
                % (x, 546, x, 550) for x in (420, 470, 540, 610, 680))
    s += '<polygon points="%s" fill="#a7782d" stroke="#2a1b08" stroke-width="3"/>' % " ".join("%g,%g" % p for p in [(700, 560), (715, 540), (740, 530), (760, 545), (775, 560)])
    return s


# V · Ira, la palude Stige: isolotti bassi di larghezze diverse che l'acqua sale a coprire (dipinta nel gioco,
# non qui: sim/hazards.lua water), il primo e l'ultimo oltre il bordo, e le palafitte alte dove si resta all'asciutto
IRA_ISOLE = ([blocco(-60, 600, 230, 140), blocco(250, 630, 140, 110), blocco(470, 590, 210, 150), blocco(740, 640, 120, 100),
              blocco(930, 600, 330, 140), fungo(60, 420, 170, 24, 250, 14), fungo(520, 340, 150, 24, 260, 14),
              fungo(1050, 380, 200, 24, 260, 14), scheggia(330, 260, 110, 40), blocco(760, 310, 100, 26),
              scheggia(900, 200, 120, 44), blocco(200, 190, 100, 26)])

# VI · Eresia, la città di Dite: un terrazzo a sinistra con una tomba, una rampa, il pavimento con tre tombe e
# un gradino in giù a destra (le tombe sono basse: si esce camminando; a giri alterni due sono aperte e
# bruciano: client/sim/maps.lua tombs); travi di ferro in alto
ERES_FONDO = 12                                                      # quanto sono profonde le tombe
ERES_TOMBE = [(150, 250, 470), (450, 550, 540), (640, 740, 540), (860, 960, 540)]   # x0, x1, pavimento sulla scena
_s = [(-100, 470)]
for _a, _b, _y in ERES_TOMBE[:1]:
    _s += [(_a, _y), (_a, _y + ERES_FONDO), (_b, _y + ERES_FONDO), (_b, _y)]
_s += [(300, 470), (370, 540)]
for _a, _b, _y in ERES_TOMBE[1:]:
    _s += [(_a, _y), (_a, _y + ERES_FONDO), (_b, _y + ERES_FONDO), (_b, _y)]
ERES_SUOLO = _s + [(1000, 540), (1060, 600), (1380, 600), (1380, 760), (-100, 760)]
ERES_SOPRA = [scheggia(380, 250, 140, 50), blocco(1080, 420, 160, 28), scheggia(700, 160, 120, 44)]
ERES_TRAVI = [(120, 350, 170, 16), (600, 380, 160, 16), (900, 300, 150, 16)]


def tombe(r):
    """Il vano scuro di ogni tomba, con la pietra del bordo; le fiamme e il coperchio sono nel gioco."""
    s = ""
    for a, b, y in ERES_TOMBE:
        s += ('<rect x="%g" y="%g" width="%g" height="%g" fill="#140605" stroke="#0c0504" stroke-width="3"/>'
              '<rect x="%g" y="%g" width="%g" height="3" fill="#7a2e1a" opacity=".8"/>'
              % (a, y + 1, b - a, ERES_FONDO + 6, a + 4, y + ERES_FONDO - 4, b - a - 8))
    return s


def lava(r):
    return ('<defs><linearGradient id="lava" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffc24a"/>'
            '<stop offset=".18" stop-color="#ff6a1f"/><stop offset="1" stop-color="#b8321a"/></linearGradient>'
            '<radialGradient id="lavaluce" cx=".5" cy="1" r=".6"><stop offset="0" stop-color="#ff7a1f" stop-opacity=".55"/>'
            '<stop offset="1" stop-color="#ff7a1f" stop-opacity="0"/></radialGradient></defs>'
            '<rect x="600" y="470" width="280" height="200" fill="url(#lavaluce)"/>'
            '<rect x="676" y="646" width="118" height="120" fill="url(#lava)"/>'
            + "".join('<polygon points="%d,%d %d,%d %d,%d" fill="#ffd27a" opacity=".8"/>'
                      % (x, 660 + (x * 7) % 30, x + 14, 656 + (x * 7) % 30, x + 26, 662 + (x * 7) % 30) for x in range(690, 780, 34)))


MAPPE = {
    "pavimento": dict(FORGIA, isole=[SUOLO] + SOPRA, travi=TRAVI),
    "fossa": dict(FORGIA, isole=[SX, DX] + SOPRA, travi=TRAVI, sotto=lava),
    "limbo": dict(LIMBO, isole=[LIMBO_SUOLO] + LIMBO_SOPRA, travi=[(250, 190, 110, 14), (920, 190, 110, 14)]),
    "lussuria": dict(LUSSURIA, isole=[LUSS_SX, LUSS_DX] + LUSS_SOPRA, travi=[], sopra=None, acciaio=LUSS_SPUNTONI),
    "gola": dict(GOLA, isole=[GOLA_SUOLO] + GOLA_SOPRA, travi=GOLA_TRAVI, sopra=pozze),
    "avarizia": dict(AVARIZIA, isole=[AVAR_SUOLO] + AVAR_SOPRA, travi=AVAR_TRAVI, sopra=monete),
    "ira": dict(IRA, isole=IRA_ISOLE, travi=[(380, 470, 100, 14), (790, 460, 100, 14)], sotto=None),
    "eresia": dict(ERESIA, isole=[ERES_SUOLO] + ERES_SOPRA, travi=ERES_TRAVI, sopra=tombe),
    "flegetonte": dict(VIOLENZA, isole=[FLEG_SX, FLEG_DX] + FLEG_SOPRA, travi=[], sopra=sangue),
    "sabbione": dict(VIOLENZA, isole=[SABBIA], travi=[], sotto=None),
    "malebolge": dict(FRODE, isole=[BOLGE_SUOLO] + BOLGE_SOPRA + [[(x, y), (x + w, y), (x + w, y + h), (x, y + h)] for x, y, w, h in BOLGE_PONTI],
                      travi=[], sopra=ponti_crepati),
    "cocito": dict(TRADIMENTO, isole=COC_SOPRA, travi=[], sopra=None),
    "lucifero": dict(TRADIMENTO, isole=[LUC_SX, LUC_DX] + LUC_SOPRA, travi=[], sopra=None),
}
# il tema (temi.py) di ogni mappa dei gironi: colori dello sfondo e del terreno; le altre hanno quello della Forgia
TEMA = {"limbo": "limbo", "lussuria": "lussuria", "gola": "gola", "avarizia": "avarizia", "ira": "ira", "eresia": "eresia",
        "flegetonte": "violenza", "sabbione": "violenza", "malebolge": "frode", "cocito": "tradimento", "lucifero": "tradimento"}
# le mappe disegnate a parte, col loro sfondo: terreno svg e maschera
ALTRE = {"cortile": (cortile.mappa, cortile.maschera, "cortile")}


# ---------------------------------------------------------------- le arene, tutte d'acciaio
def arene():
    """{id missione: [(x, y, w, h)]} in coordinate del mondo (y verso l'alto), da sim/levels.lua."""
    lua = ('package.path="client/?.lua;"..package.path local c=require("sim.campaign") '
           'for _,cap in ipairs(c.CAPITOLI) do for _,l in ipairs(cap.missioni) do if l.arena then '
           'local t={} for _,q in ipairs(l.arena) do t[#t+1]=string.format("[%g,%g,%g,%g]",q[1],q[2],q[3],q[4]) end '
           'print(l.id.." ["..table.concat(t,",").."]") end end end')
    out = subprocess.run(["luajit", "-e", lua], cwd=RADICE, capture_output=True, text=True, check=True).stdout
    return {r.split(" ", 1)[0]: json.loads(r.split(" ", 1)[1]) for r in out.strip().splitlines()}


def acciaio(x, y, w, h, m):
    """Un blocco d'acciaio nel mondo (SVG, y verso il basso): lamiera con la luce in alto, bordo scuro
    ma non nero, giunti con i bulloni, tratteggio in basso. Lo stesso acciaio delle travi."""
    gid = "acc%d_%d" % (x, y)
    corpo, luce, bordo = mix(m["acciaio"], "#000000", .22), m["acciaio_luce"], m["bordo"]
    # la luce solo nei primi 160 pixel, poi la lamiera scura: nelle arene i blocchi sono
    # grandi e chiari a tutta altezza rubavano l'occhio al personaggio (regola delle mappe)
    s = ['<defs><linearGradient id="%s" gradientUnits="userSpaceOnUse" x1="0" y1="%g" x2="0" y2="%g">'
         '<stop offset="0" stop-color="%s"/><stop offset=".3" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs>'
         % (gid, y, y + min(h, 160), mix(corpo, luce, .2), corpo, mix(corpo, "#000000", .45))]
    s.append('<rect x="%g" y="%g" width="%g" height="%g" fill="url(#%s)" stroke="%s" stroke-width="4"/>' % (x, y, w, h, gid, bordo))
    s.append('<rect x="%g" y="%g" width="%g" height="%g" fill="url(#tratteggio)" mask="url(#basso)"/>' % (x, y, w, h))
    s.append('<rect x="%g" y="%g" width="%g" height="4" fill="%s"/>' % (x + 3, y + 3, w - 6, luce))
    r, passo = 3.6, 48
    if h < 60:
        file = [y + h / 2 + 2]
    else:
        file = [y + 16, y + h - 14]
        # giunti fra le lastre, con una fila di bulloni da una parte e dall'altra
        n = max(1, round(w / 220))
        for i in range(1, n):
            gx = x + w * i / n
            s.append('<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="3"/>' % (gx, y + 6, gx, y + h - 3, bordo))
            s.append('<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="1.5" opacity=".5"/>' % (gx + 3, y + 8, gx + 3, y + h - 4, luce))
            for yy in range(int(y + 40), int(y + h - 30), passo):
                s.append('<circle cx="%g" cy="%g" r="%g" fill="%s"/>' % (gx - 12, yy, r, luce))
                s.append('<circle cx="%g" cy="%g" r="%g" fill="%s"/>' % (gx + 14, yy, r, luce))
    for fy in file:
        xx = x + 18
        while xx < x + w - 12:
            s.append('<circle cx="%g" cy="%g" r="%g" fill="%s"/><circle cx="%g" cy="%g" r="%g" fill="%s" opacity=".55"/>'
                     % (xx, fy + 1.4, r, bordo, xx, fy, r, luce))
            xx += passo
    return "".join(s)


# ---------------------------------------------------------------- disegno con il browser
RENDI = r"""
const {chromium} = require('playwright'); const fs = require('fs');
(async () => {
  const lavori = JSON.parse(fs.readFileSync(process.argv[2]));
  const b = await chromium.launch(); const p = await b.newPage();
  for (const l of lavori) {
    await p.setViewportSize({width: l.w, height: l.h});
    await p.setContent('<html><body style="margin:0;background:transparent">' + fs.readFileSync(l.svg, 'utf8') + '</body></html>');
    await p.screenshot({path: l.png, omitBackground: true, clip: {x: 0, y: 0, width: l.w, height: l.h}});
  }
  await b.close();
})();
"""


def svg(contenuto, vb, w, h):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%s" preserveAspectRatio="none" style="display:block">%s%s</svg>'
            % (w, h, " ".join("%g" % v for v in vb), DEFS, contenuto))


def rendi(lavori, tmp):
    js = os.path.join(tmp, "rendi.js")
    open(js, "w").write(RENDI)
    lista = []
    for i, (contenuto, png, w, h) in enumerate(lavori):
        f = os.path.join(tmp, "l%d.svg" % i)
        open(f, "w").write(contenuto)
        lista.append(dict(svg=f, png=png, w=w, h=h))
    open(os.path.join(tmp, "lavori.json"), "w").write(json.dumps(lista))
    # i moduli di Node si cercano anche fra quelli globali (npm root -g), così
    # basta un `npm install -g` dei pacchetti che servono; NODE_PATH, se c'è, viene prima
    env = os.environ.copy()
    try:
        globale = subprocess.run(["npm", "root", "-g"], capture_output=True, text=True, shell=os.name == "nt").stdout.strip()
    except OSError:
        globale = ""
    percorsi = [p for p in [env.get("NODE_PATH", ""), globale] if p and os.path.isdir(p)]
    if percorsi:
        env["NODE_PATH"] = os.pathsep.join(percorsi)
    subprocess.run(["node", js, os.path.join(tmp, "lavori.json")], env=env, check=True)


def maschera(g, nome, disegna=None):
    """760 x 360 celle (scena x 0,5, più il margine per lato): bianco la terra, rosso l'acciaio."""
    im = Image.new("RGB", (640 + MARGINE, 360), "black")
    o = MARGINE * .5
    if disegna:
        disegna(im)
    else:
        d = ImageDraw.Draw(im)
        for p in forma(g["isole"], g.get("stile")):
            d.polygon([(x * .5 + o, y * .5) for x, y in p], fill="white")
        for x, y, w, h in g.get("travi", []):
            d.rectangle([x * .5 + o, y * .5, (x + w) * .5 + o - 1, (y + h) * .5 - 1], fill="red")
        for p in g.get("acciaio", []):
            d.polygon([(x * .5 + o, y * .5) for x, y in p], fill="red")
    os.makedirs(MASCHERE, exist_ok=True)
    im.save(os.path.join(MASCHERE, nome + ".png"))


def sfondi():
    """{nome: (cielo svg, [(gruppo, svg largo un giro, velocità media)], scorre, scena, tema)}. Il cortile non
    scorre da solo: si muove solo con la camera (un muro che scivola di lato sembra strano)."""
    P = TEMI["forgia"]
    p = piani(FORGIA, P)
    c = cortile.sfondo()
    cielo_c = piani(dict(FORGIA, luce=c["luce"], piani=[], isole=[], travi=[]), P)["cielo"]
    out = {"forgia": (p["cielo"], p["gruppi"], True, FORGIA, P), "cortile": (cielo_c, c["gruppi"], False, FORGIA, P)}
    # i gironi: il cielo dal loro tema, i piani dalle scene fatte a mano (gironi/sfondi.py)
    for nome, tema in TEMA.items():
        if tema in out:
            continue
        sc = sfondi_gironi.sfondo(tema, TEMI[tema])
        g = dict(MAPPE[nome], luce=sc["luce"])
        q = piani(dict(g, piani=[], isole=[], travi=[]), TEMI[tema])
        out[tema] = (q["cielo"], sc["gruppi"], True, g, TEMI[tema])
    return out


def main():
    P = TEMI["forgia"]
    for sotto in ("maps", "backgrounds"):
        os.makedirs(os.path.join(OUT, sotto), exist_ok=True)
        for f in os.listdir(os.path.join(OUT, sotto)):
            os.remove(os.path.join(OUT, sotto, f))
    lavori, strisce = [], []
    # gli sfondi: il cielo (fermo, con il bagliore e i raggi) e i tre gruppi di piani
    SF = sfondi()
    for sf, (cielo, gruppi, scorre, scena, tema) in SF.items():
        for d, k in DENSITA.items():
            lavori.append((svg(cielo + '<g style="mix-blend-mode:screen">%s</g>' % raggi(scena, tema), (0, 0, W, H),
                               round(W * k["cielo"]), round(H * k["cielo"])),
                           os.path.join(OUT, "backgrounds", "%s_cielo_%d.png" % (sf, d)), round(W * k["cielo"]), round(H * k["cielo"])))
            for nome, contenuto, vel in gruppi:
                w = min(4096, round(2560 * k[nome]))
                lavori.append((svg(contenuto, (0, 0, 2560, H), w, round(H * w / 2560)),
                               os.path.join(OUT, "backgrounds", "%s_%s_%d.png" % (sf, nome, d)), w, round(H * w / 2560)))
        for nome, contenuto, vel in gruppi:
            strisce.append((sf, nome, vel if scorre else 0))
    sfondo_di = {}
    # il terreno delle mappe dipinte
    for nome, g in MAPPE.items():
        maschera(g, nome)
        sfondo_di[nome] = TEMA.get(nome, "forgia")
        Pm = TEMI[sfondo_di[nome]]
        gioco = piani(g, Pm)["gioco"] + (spuntoni(g, Pm) if g.get("acciaio") else "")
        for d, k in DENSITA.items():
            w, h = round((1920 + 3 * MARGINE) * k["terreno"]), round(1080 * k["terreno"])
            lavori.append((svg(gioco, (-MARGINE, 0, W + 2 * MARGINE, H), w, h), os.path.join(OUT, "maps", "%s_%d.png" % (nome, d)), w, h))
    for nome, (disegno, collisione, sf) in ALTRE.items():
        maschera(None, nome, collisione)
        sfondo_di[nome] = sf
        gioco = disegno()
        for d, k in DENSITA.items():
            w, h = round((1920 + 3 * MARGINE) * k["terreno"]), round(1080 * k["terreno"])
            lavori.append((svg(gioco, (-MARGINE, 0, W + 2 * MARGINE, H), w, h), os.path.join(OUT, "maps", "%s_%d.png" % (nome, d)), w, h))
    # le arene delle missioni: il cortile dipinto, le altre d'acciaio, in coordinate del mondo
    m = {c: grade(v, "materiale", P) for c, v in FORGIA["mat"].items() if isinstance(v, str) and v.startswith("#")}
    for mid, rett in arene().items():
        if mid in cortile.LEZIONI:
            corpo, vb, sfondo_di["missione_" + mid] = cortile.lezione(mid, rett), (-MARGINE, 0, W + 2 * MARGINE, H), "cortile"
        else:
            corpo = "".join(acciaio(x, 1080 - y - h, w, h, m) for x, y, w, h in rett)
            vb, sfondo_di["missione_" + mid] = (-1.5 * MARGINE, 0, 1920 + 3 * MARGINE, 1080), "forgia"
        for d, k in DENSITA.items():
            w, h = round((1920 + 3 * MARGINE) * k["terreno"]), round(1080 * k["terreno"])
            lavori.append((svg(corpo, vb, w, h), os.path.join(OUT, "maps", "missione_%s_%d.png" % (mid, d)), w, h))
    with tempfile.TemporaryDirectory() as tmp:
        rendi(lavori, tmp)
    # i gruppi dello sfondo: si tiene solo la fascia che ha qualcosa (misure nella scena)
    fasce = {}
    for sf, nome, vel in strisce:
        y0s, y1s = [], []
        for d in DENSITA:
            im = Image.open(os.path.join(OUT, "backgrounds", "%s_%s_%d.png" % (sf, nome, d)))
            box = im.getchannel("A").getbbox()
            sc = im.width / 2560
            y0s.append(box[1] / sc)
            y1s.append(box[3] / sc)
        y0, y1 = max(0, int(min(y0s)) - 2), min(H, int(max(y1s)) + 3)
        for d in DENSITA:
            f = os.path.join(OUT, "backgrounds", "%s_%s_%d.png" % (sf, nome, d))
            im = Image.open(f)
            sc = im.width / 2560
            im.crop((0, round(y0 * sc), im.width, round(y1 * sc))).save(f, optimize=True)
        fasce[sf, nome] = (y0, y1 - y0, vel)
    # i numeri per lo shader
    righe = ["-- Made by tools/grafica/mappe_dipinte.py, do not edit by hand.",
             "-- The painted images (client/paintings, one per screen density) and the background",
             "-- numbers: for each group of planes where it sits in the 1280 x 720 scene (y0 from",
             "-- the top, h), how much it follows the camera (parallax) and how many scene pixels",
             "-- it scrolls per second.",
             "return {",
             "\tdensities = { %s }," % ", ".join(str(d) for d in DENSITA),
             "\twrap = 2560,",
             "\tbackgrounds = {"]
    for sf in SF:
        righe += ["\t\t%s = {" % sf,
                  "\t\t\thaze = { %s }," % ", ".join("%.3f" % (v / 255) for v in Image.new("RGB", (1, 1), SF[sf][4]["foschia"]).getpixel((0, 0))),
                  "\t\t\tgroups = {"]
        for nome, _, _ in GRUPPI:
            y0, h, vel = fasce[sf, nome]
            righe.append('\t\t\t\t{ name = "%s", y0 = %d, h = %d, parallax = %g, scroll = %.1f },'
                         % (nome, y0, h, QUANTO[nome], CALMO * vel))
        righe += ["\t\t\t},", "\t\t},"]
    righe += ["\t},",
              "\t-- the maps with painted terrain and their background",
              "\tmaps = {"]
    for nome, sf in sfondo_di.items():
        righe.append('\t\t%s = "%s",' % (nome, sf))
    righe += ["\t},", "}", ""]
    open(LUA, "w").write("\n".join(righe))
    print("fatto:", len(lavori), "immagini")
    # le miniature delle missioni della CAMPAGNA si rifanno dai dipinti nuovi
    import miniature_missioni
    miniature_missioni.main()


if __name__ == "__main__":
    main()
