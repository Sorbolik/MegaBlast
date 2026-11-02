# I gironi, seconda versione: 7-8 piani di sfondo che scorrono, mappe con 10-14 piattaforme.
from mondo import *

# ---------------------------------------------------------------- disposizioni
TORRI = [
    pendio(20, 520, 300, 60, 130, "dx"),
    fungo(370, 390, 180, 26, 210, 22),
    blocco(600, 570, 230, 80),
    arco(870, 480, 290, 190, 40, 50),
    mensola(1190, 300, 60, 330, 46, -1),
    scheggia(130, 300, 130, 50),
    scheggia(590, 250, 110, 44),
    blocco(960, 250, 140, 38),
    scheggia(700, 410, 100, 40),
    blocco(300, 180, 90, 28),
]
SCALE = [
    gradini(20, 640, 5, 70, 40, 90, 1),
    gradini(910, 640, 5, 70, 40, 90, -1),
    blocco(440, 520, 400, 150),
    fungo(520, 320, 240, 24, 200, 22),
    scheggia(70, 290, 130, 48),
    scheggia(1080, 290, 130, 48),
    blocco(300, 190, 110, 34),
    blocco(870, 190, 110, 34),
    scheggia(600, 170, 80, 34),
]
ARCIPELAGO = [
    blocco(30, 480, 180, 64),
    pendio(260, 550, 240, 40, 64, "dx"),
    blocco(560, 510, 160, 54),
    pendio(780, 570, 220, 40, 64, "sx"),
    blocco(1060, 480, 190, 64),
    scheggia(150, 340, 110, 40),
    scheggia(420, 390, 90, 36),
    blocco(630, 310, 140, 32),
    scheggia(880, 370, 100, 40),
    scheggia(1100, 310, 120, 44),
    blocco(330, 210, 90, 26),
    blocco(860, 210, 90, 26),
]
CAVERNA = [
    [(-20, -20), (1300, -20), (1300, 90), (1180, 90), (1140, 130), (980, 130), (950, 100), (700, 100), (660, 140), (560, 140),
     (530, 110), (300, 110), (260, 150), (120, 150), (80, 110), (-20, 110)],
    pendio(-20, 590, 420, 60, 160, "dx"),
    arco(420, 540, 380, 200, 40, 60),
    pendio(820, 590, 480, 60, 160, "sx"),
    scheggia(110, 370, 150, 52),
    blocco(530, 340, 170, 36),
    scheggia(920, 360, 150, 52),
    blocco(320, 260, 90, 28),
    blocco(860, 250, 90, 28),
]
PONTI = [
    arco(20, 500, 360, 240, 40, 60),
    arco(470, 570, 340, 170, 36, 56),
    arco(900, 490, 360, 250, 40, 60),
    fungo(370, 310, 120, 22, 190, 14),
    fungo(800, 290, 120, 22, 200, 14),
    scheggia(110, 320, 140, 46),
    blocco(570, 380, 140, 32),
    scheggia(1060, 300, 140, 46),
    blocco(590, 200, 100, 28),
]


def tronco(cx, y0, w, rami, t=22, fondo=780):
    """Un tronco morto con i rami come mensole: rami = [(y, "dx"|"sx", lunghezza)]."""
    h = w / 2
    p = [(cx - h, y0), (cx + h, y0)]
    for y, lato, l in sorted(r for r in rami if r[1] == "dx"):
        p += [(cx + h, y), (cx + h + l, y), (cx + h + l - t * .5, y + t), (cx + h, y + t)]
    p += [(cx + h, fondo), (cx - h, fondo)]
    for y, lato, l in sorted((r for r in rami if r[1] == "sx"), reverse=True):
        p += [(cx - h, y + t), (cx - h - l + t * .5, y + t), (cx - h - l, y), (cx - h, y)]
    return p


VORTICE = [   # Lussuria: schegge strappate dalla bufera, a spirale verso l'alto
    pendio(20, 600, 260, 50, 70, "dx"),
    scheggia(320, 540, 150, 70),
    pendio(500, 480, 220, 45, 64, "dx"),
    scheggia(760, 410, 160, 70),
    blocco(950, 340, 170, 50),
    scheggia(1130, 260, 130, 60),
    scheggia(1030, 610, 220, 80),
    blocco(760, 630, 180, 50),
    scheggia(110, 400, 130, 56),
    blocco(330, 320, 120, 36),
    scheggia(560, 240, 110, 50),
    blocco(820, 170, 100, 30),
    scheggia(220, 180, 100, 40),
]
PALUDE = [    # Ira: isolotti bassi a pelo d'acqua e palafitte alte
    blocco(10, 590, 200, 60),
    blocco(270, 615, 170, 50),
    blocco(520, 600, 240, 56),
    blocco(830, 615, 170, 50),
    blocco(1070, 590, 200, 60),
    fungo(150, 400, 160, 24, 250, 14),
    fungo(560, 360, 160, 24, 260, 14),
    fungo(970, 400, 160, 24, 250, 14),
    scheggia(370, 270, 110, 40),
    scheggia(800, 250, 110, 40),
    blocco(600, 170, 90, 26),
]
SEPOLCRI = [  # Eresia: necropoli di tombe di altezze diverse e un'arca aperta
    blocco(0, 560, 170, 200, 8),
    blocco(190, 600, 150, 160, 8),
    [(370, 520), (400, 520), (400, 570), (520, 570), (520, 520), (550, 520), (550, 760), (370, 760)],
    blocco(580, 580, 140, 180, 8),
    blocco(740, 540, 160, 220, 8),
    blocco(930, 610, 140, 150, 8),
    blocco(1090, 520, 190, 240, 8),
    blocco(120, 370, 140, 30),
    scheggia(420, 340, 120, 44),
    blocco(640, 290, 130, 30),
    scheggia(900, 360, 120, 44),
    blocco(1070, 300, 120, 30),
    blocco(320, 190, 90, 26),
    blocco(880, 170, 90, 26),
]
BOSCO = [     # Violenza: la selva dei suicidi, tronchi morti con i rami come appoggi
    pendio(-20, 600, 320, 50, 180, "dx"),
    pendio(980, 600, 320, 50, 180, "sx"),
    tronco(430, 240, 40, [(330, "dx", 110), (470, "sx", 120), (570, "dx", 90)]),
    tronco(850, 220, 40, [(320, "sx", 110), (450, "dx", 120), (570, "sx", 90)]),
    blocco(570, 520, 150, 40),
    scheggia(600, 370, 90, 36),
    scheggia(120, 380, 130, 48),
    scheggia(1030, 360, 130, 48),
    blocco(600, 180, 90, 26),
]
BOLGE = [     # Frode: il terreno spaccato da due fosse a V piene di pece
    [(-20, 520), (240, 520), (370, 650), (420, 650), (550, 520), (730, 520), (860, 650), (910, 650), (1040, 520), (1300, 520),
     (1300, 760), (-20, 760)],
    fungo(565, 330, 150, 22, 190, 14),
    blocco(80, 340, 140, 30),
    blocco(1060, 340, 140, 30),
    scheggia(330, 260, 120, 44),
    scheggia(830, 260, 120, 44),
    blocco(590, 160, 100, 26),
]
LASTRONI = [  # Tradimento: il lago gelato con colonne di ghiaccio e lastre sopra
    blocco(-20, 620, 1320, 140, 0),
    fungo(100, 450, 240, 30, 170, 40),
    fungo(500, 400, 280, 30, 220, 40),
    fungo(940, 450, 240, 30, 170, 40),
    scheggia(330, 300, 100, 80),
    scheggia(850, 300, 100, 80),
    blocco(120, 230, 120, 30),
    blocco(1040, 230, 120, 30),
    scheggia(590, 200, 100, 60),
]
MONTE = [     # Purgatorio: la montagna a cornici che si sale
    [(100, 620), (320, 620), (320, 520), (440, 520), (440, 410), (560, 410), (560, 300), (720, 300), (720, 410), (840, 410),
     (840, 520), (960, 520), (960, 620), (1180, 620), (1180, 760), (100, 760)],
    scheggia(20, 430, 110, 44),
    scheggia(1150, 430, 110, 44),
    blocco(170, 300, 110, 30),
    blocco(1000, 300, 110, 30),
    blocco(590, 160, 100, 26),
]
import math as _m
CERCHI = [blocco(530, 610, 220, 50)] + [   # Paradiso: le isole girano in cerchio attorno alla luce
    scheggia(640 + 330 * _m.cos(_m.radians(a)) - 60, 380 + 220 * _m.sin(_m.radians(a)), 120, 44)
    for a in (20, 50, 130, 160, 200, 250, 290, 340)] + [blocco(580, 370, 120, 30)]


def tinta(base, haze):
    return lambda t: mix(base, haze, t)


# ---------------------------------------------------------------- Prologo · la Forgia
c = tinta("#1a0b08", "#b0542c")
FORGIA = dict(id="forgia", stile="ferro", seme=3, verso=-1, cielo=("#1a0b08", "#5a2414"), luce=(980, 300, 460, "#ff7a1a", .45),
    piani=[
        ("nubi", lambda r, c=c: nubi(r, 10, "#120806", .35, (60, 220)), .04),
        ("lontano", lambda r, c=c: poligoni(creste(r, 360, 130, 150), c(.7)), .08),
        ("camini lontani", lambda r, c=c: poligoni(camini(r, 420, 10), c(.55)), .15),
        ("nebbia", lambda r, c=c: nebbia(380, 150, "#ff7a1a", .18), 0),
        ("medio", lambda r, c=c: poligoni(creste(r, 520, 110, 120), c(.4)), .25),
        ("camini", lambda r, c=c: poligoni(camini(r, 600, 6), c(.28)), .4),
        ("catene", lambda r, c=c: catene(r, 9, c(.32)), .5),
        ("vicino", lambda r, c=c: poligoni(creste(r, 690, 70, 90), "#0e0504"), .75),
    ],
    isole=TORRI, mat=mat("#4a2a20", "#7a4a2a", "#ffb35a", "#160a07", "#5b5560", "#c9c3cf", "mattoni"),
    travi=[(400, 140, 140, 16), (760, 330, 130, 16)],
    diavoli=[(140, 520, ROSSO), (700, 570, BLU)], particelle=("braci", 50, "#ffb03a"))

# ---------------------------------------------------------------- I · Limbo
c = tinta("#1d2522", "#b9c9c0")
LIMBO = dict(id="limbo", stile="rovina", seme=7, verso=-1, cielo=("#2c3833", "#7e9289"), luce=(640, -60, 560, "#f2ecd0", .5),
    piani=[
        ("nubi", lambda r, c=c: nubi(r, 16, "#e6eee8", .14, (60, 260)), .04),
        ("lontano", lambda r, c=c: poligoni(creste(r, 320, 70, 220, piatte=True), c(.7)), .07),
        ("castello", lambda r, c=c: poligoni(mura(r, 470, 110) + torri(r, 380, 7, (50, 70), (90, 170)), c(.55)), .13),
        ("nebbia", lambda r, c=c: nebbia(400, 150, "#d6e2dc", .32), 0),
        ("mura vicine", lambda r, c=c: poligoni(mura(r, 600, 60, 26) + torri(r, 560, 5, (40, 60), (60, 120)), c(.46)), .25),
        ("colonne", lambda r, c=c: poligoni(colonne(r, 720, 14, (80, 220)), c(.26)), .4),
        ("nebbia bassa", lambda r, c=c: nebbia(560, 140, "#d6e2dc", .25), 0),
        ("vicino", lambda r, c=c: poligoni(colonne(r, 760, 8, (120, 300)), mix("#1d2522", "#000", .3)), .75),
    ],
    isole=PONTI, mat=mat("#4e5a52", "#c9bd8e", "#f4ecc8", "#121815", "#3d4b55", "#a9bdc8", "lastre"),
    travi=[(250, 190, 110, 14), (950, 170, 110, 14)],
    sotto=lambda r, c=c: acqua(680, "#3f5b62", "#a9c6cc"),
    diavoli=[(150, 500, ROSSO), (1020, 490, BLU)], particelle=("polvere", 34, "#eef3ea"))

# ---------------------------------------------------------------- II · Lussuria
c = tinta("#120a1f", "#b9a4f0")


def bufera(r):
    return ('<polyline class="lampo" points="%s" fill="none" stroke="#f3e9ff" stroke-width="4"/>'
            '<g><rect x="1010" y="30" width="230" height="44" rx="10" fill="#000" opacity=".45"/>'
            '<text x="1030" y="60" font-size="18" fill="#f3e9ff" style="font-family:Lilita,\'Lilita One\',sans-serif">BUFERA</text>'
            '<polygon points="1120,40 1200,40 1200,30 1228,52 1200,74 1200,64 1120,64" fill="#e05fa8"/></g>'
            % pts([(760, 0), (730, 90), (770, 90), (720, 210)]))


LUSSURIA = dict(id="lussuria", stile="scoglio", seme=11, verso=1, cielo=("#120a1f", "#4b2d6b"), luce=(760, 120, 420, "#c9b8ff", .35),
    piani=[
        ("stelle", lambda r, c=c: stelle(r, 40, "#e8dcff"), .03),
        ("lontano", lambda r, c=c: poligoni(creste(r, 360, 180, 110), c(.62)), .08),
        ("scogli lontani", lambda r, c=c: poligoni(scogli(r, 12, (120, 380), (40, 110)), c(.5)), .15),
        ("scie", lambda r, c=c: scie(r, 10, "#e05fa8"), .6),
        ("nebbia", lambda r, c=c: nebbia(460, 130, "#c9b8ff", .2), 0),
        ("medio", lambda r, c=c: poligoni(creste(r, 540, 220, 90), c(.3)), .28),
        ("scogli", lambda r, c=c: poligoni(scogli(r, 8, (160, 460), (90, 170)), c(.24)), .45),
        ("vicino", lambda r, c=c: poligoni(creste(r, 700, 140, 70), "#0a0612"), .8),
    ],
    isole=VORTICE, mat=mat("#3d2f4f", "#6b4a86", "#e8c9ff", "#0e0816", "#5b5d6a", "#d0d2e0", "venature"),
    travi=[(500, 300, 90, 14), (1000, 520, 100, 14)],
    sopra=bufera,
    diavoli=[(70, 600, ROSSO), (1140, 610, BLU)], particelle=("petali", 44, "#e05fa8"))

# ---------------------------------------------------------------- III · Gola
c = tinta("#1a1d1a", "#c8ccc6")


def grandine(r):
    return "".join('<ellipse class="pulsa" cx="%d" cy="%d" rx="%d" ry="7" fill="#000" opacity=".5"/>' % (x, y, w)
                   for x, y, w in ((610, 340, 28), (230, 530, 30), (1010, 530, 30)))


GOLA = dict(id="gola", stile="fango", seme=13, verso=-1, cielo=("#1c201d", "#5d6158"),
    piani=[
        ("nubi", lambda r, c=c: nubi(r, 14, "#0e100e", .45, (20, 200)), .05),
        ("lontano", lambda r, c=c: poligoni(creste(r, 350, 50, 260, piatte=True), c(.6)), .08),
        ("pioggia lontana", lambda r, c=c: "".join('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#c8ccc6" stroke-width="1.5" opacity=".25"/>' % (x, y, x - 10, y + 40) for x, y in [(r.uniform(0, T), r.uniform(0, 600)) for _ in range(120)]), .12),
        ("nebbia", lambda r, c=c: nebbia(300, 200, "#d8dde0", .22), 0),
        ("colline", lambda r, c=c: poligoni(creste(r, 470, 90, 180, piatte=True), c(.4)), .25),
        ("stalattiti", lambda r, c=c: poligoni(stalattiti(r, 22, (40, 130), (24, 60), 40), c(.18)), .35),
        ("medio", lambda r, c=c: poligoni(creste(r, 600, 70, 140), c(.24)), .45),
        ("vicino", lambda r, c=c: poligoni(creste(r, 700, 50, 120, piatte=True), "#0c0e0c"), .75),
    ],
    isole=CAVERNA, mat=mat("#4a4931", "#6e6c45", "#a9b07a", "#121410", "#4d5660", "#b9c4cc", "fango", segni_op=.3),
    travi=[(700, 440, 100, 16)],
    sopra=grandine,
    diavoli=[(100, 590, ROSSO), (1180, 540, BLU)], particelle=("pioggia", 80, "#d8dde0"))

# ---------------------------------------------------------------- IV · Avarizia
c = tinta("#1a1208", "#d8a850")


def massi(r):
    s = ""
    for x, y in ((360, 480), (920, 480)):
        s += ('<g class="rotola"><polygon points="%s" fill="#8a6a3a" stroke="#120c06" stroke-width="4"/></g>'
              % pts([(x - 24, y - 4), (x - 12, y - 28), (x + 12, y - 32), (x + 26, y - 10), (x + 16, y), (x - 18, y)]))
    s += "".join('<rect x="%d" y="512" width="9" height="9" fill="#ffd25a" stroke="#5a3a10" stroke-width="2" transform="rotate(45 %d 516)"/>' % (x, x) for x in (480, 560, 700, 790))
    return s


AVARIZIA = dict(id="avarizia", stile="oro", seme=17, verso=1, cielo=("#1a1208", "#6e4a22"), luce=(640, 140, 460, "#e8b84a", .35),
    piani=[
        ("nubi", lambda r, c=c: nubi(r, 10, "#120c05", .35, (40, 200)), .04),
        ("lontano", lambda r, c=c: poligoni(creste(r, 330, 150, 200), c(.5)), .08),
        ("mucchi lontani", lambda r, c=c: poligoni(mucchi(r, 470, 10, (120, 240)), c(.5)), .15),
        ("nebbia", lambda r, c=c: nebbia(330, 160, "#e8b84a", .15), 0),
        ("medio", lambda r, c=c: poligoni(creste(r, 540, 120, 160), c(.36)), .25),
        ("mucchi", lambda r, c=c: poligoni(mucchi(r, 640, 8, (200, 360)), c(.26)) + "".join('<rect x="%d" y="%d" width="8" height="8" fill="#e8b84a" opacity=".45" transform="rotate(45 %d %d)"/>' % (x, y, x, y) for x, y in [(r.uniform(0, T), r.uniform(480, 640)) for _ in range(50)]), .4),
        ("catene", lambda r, c=c: catene(r, 7, c(.3)), .5),
        ("vicino", lambda r, c=c: poligoni(creste(r, 710, 50, 120), "#0e0904"), .75),
    ],
    isole=SCALE, mat=mat("#6e4a22", "#a7782d", "#ffd27a", "#160e05", "#5a5a64", "#d6d6e0", "lastre"),
    travi=[(590, 130, 100, 16)],
    sopra=massi,
    diavoli=[(60, 640, ROSSO), (640, 520, BLU)], particelle=("polvere", 34, "#ffd27a"))

# ---------------------------------------------------------------- V · Ira
c = tinta("#071012", "#5f9a98")


def fiaccole(r):
    s = ""
    for x, y in ((40, 590), (1240, 590)):
        s += '<rect x="%d" y="%d" width="10" height="34" fill="#23484a" stroke="#06100f" stroke-width="3"/>' % (x - 5, y - 34)
        s += '<path class="fiamma" d="M%d,%d l-8,-4 l8,-22 l8,22 Z" fill="#ff7a2a"/>' % (x, y - 36)
    return s


IRA = dict(id="ira", stile="palude", seme=19, verso=-1, cielo=("#071012", "#23484a"), luce=(640, 470, 560, "#e0532f", .2),
    piani=[
        ("stelle", lambda r, c=c: stelle(r, 30, "#9fc0c0"), .03),
        ("lontano", lambda r, c=c: poligoni(creste(r, 400, 40, 260, piatte=True), c(.55)), .07),
        ("Dite", lambda r, c=c: poligoni(mura(r, 470, 80, 14) + torri(r, 400, 9, (30, 46), (60, 150)), mix("#071012", "#e0532f", .3)), .12),
        ("nebbia", lambda r, c=c: nebbia(420, 150, "#4f8b8a", .35), 0),
        ("medio", lambda r, c=c: poligoni(creste(r, 560, 60, 200, piatte=True), c(.3)), .25),
        ("torri", lambda r, c=c: poligoni(torri(r, 640, 6, (30, 50), (120, 260), punta=False), c(.22)), .4),
        ("canne", lambda r, c=c: poligoni(canne(r, 690, 50), c(.12)), .6),
        ("vicino", lambda r, c=c: poligoni(canne(r, 760, 30), "#030807"), .85),
    ],
    isole=PALUDE, mat=mat("#2c4a44", "#4f6b4a", "#9fc0a0", "#050c0b", "#4a5560", "#c0ccd6"),
    travi=[(380, 470, 100, 14), (790, 460, 100, 14)],
    sotto=lambda r, c=c: acqua(640, "#16302f", "#4f8b8a"), sopra=fiaccole,
    diavoli=[(130, 590, ROSSO), (1150, 590, BLU)], particelle=("polvere", 24, "#9fc0a0"))

# ---------------------------------------------------------------- VI · Eresia
c = tinta("#0d0504", "#d0552a")


def arche(r):
    s = ""
    for x, y, aperta in ((240, 600, True), (620, 580, False), (790, 540, True)):
        s += '<rect x="%d" y="%d" width="64" height="30" fill="#3b1712" stroke="#0c0504" stroke-width="4"/>' % (x, y - 30)
        if aperta:
            s += '<polygon points="%s" fill="#5a2418" stroke="#0c0504" stroke-width="4"/>' % pts([(x - 6, y - 30), (x + 26, y - 62), (x + 36, y - 56), (x + 6, y - 26)])
            s += '<path class="fiamma" d="M%d,%d l12,-34 l12,34 Z" fill="#ffcc33"/>' % (x + 20, y - 30)
        else:
            s += '<rect x="%d" y="%d" width="76" height="10" fill="#5a2418" stroke="#0c0504" stroke-width="4"/>' % (x - 6, y - 40)
    return s


ERESIA = dict(id="eresia", stile="sepolcro", seme=23, verso=1, cielo=("#0d0504", "#3b1712"), luce=(640, 720, 680, "#ff5a1f", .3),
    piani=[
        ("braci lontane", lambda r, c=c: stelle(r, 40, "#ff8a3d"), .03),
        ("mura lontane", lambda r, c=c: poligoni(mura(r, 400, 120, 22) + torri(r, 290, 8, (40, 60), (80, 200)), c(.32)), .08),
        ("torri", lambda r, c=c: poligoni(torri(r, 470, 10, (30, 50), (100, 260)), c(.24)), .15),
        ("nebbia", lambda r, c=c: nebbia(380, 160, "#ff5a1f", .18), 0),
        ("tombe lontane", lambda r, c=c: poligoni(tombe(r, 560, 22), c(.2)) + "".join('<path d="M%d,552 l8,-22 l8,22 Z" fill="#ff5a1f" opacity=".3"/>' % r.uniform(0, T) for _ in range(16)), .25),
        ("catene", lambda r, c=c: catene(r, 10, c(.2)), .4),
        ("tombe", lambda r, c=c: poligoni(tombe(r, 650, 14), c(.12)), .5),
        ("vicino", lambda r, c=c: poligoni(creste(r, 700, 50, 100), "#060201"), .8),
    ],
    isole=SEPOLCRI, mat=mat("#2e1712", "#4e2418", "#ff8a4a", "#070302", "#55585e", "#e4e6ea", "mattoni", segni_op=.35),
    travi=[(260, 470, 110, 16), (780, 450, 110, 16)],
    sopra=arche,
    diavoli=[(70, 560, ROSSO), (1180, 520, BLU)], particelle=("braci", 50, "#ffcc33"))

# ---------------------------------------------------------------- VII · Violenza
c = tinta("#12060a", "#8a7e90")
VIOLENZA = dict(id="violenza", stile="spine", seme=29, verso=-1, cielo=("#12060a", "#4a1418"), luce=(1100, 60, 460, "#f2a65a", .35),
    piani=[
        ("pioggia di fuoco", lambda r, c=c: "".join('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#f2a65a" stroke-width="3" opacity=".35"/>' % (x, y, x - 8, y + 18) for x, y in [(r.uniform(0, T), r.uniform(0, 420)) for _ in range(50)]), .05),
        ("lontano", lambda r, c=c: poligoni(creste(r, 330, 110, 200), c(.6)), .08),
        ("selva lontana", lambda r, c=c: alberi(r, 470, 14, c(.45), 6), .15),
        ("nebbia", lambda r, c=c: nebbia(380, 160, "#f2a65a", .15), 0),
        ("medio", lambda r, c=c: poligoni(creste(r, 540, 90, 150), c(.32)), .25),
        ("selva", lambda r, c=c: alberi(r, 640, 10, c(.2), 10), .4),
        ("stalattiti", lambda r, c=c: poligoni(stalattiti(r, 16, (40, 150), (20, 50), 20), c(.16)), .5),
        ("vicino", lambda r, c=c: poligoni(creste(r, 720, 60, 110), "#08030a"), .8),
    ],
    isole=BOSCO, mat=mat("#5a4a52", "#8a7a7a", "#e0c8b0", "#0d0608", "#4a4c58", "#cfd2de", "venature"),
    travi=[(330, 170, 120, 16), (820, 150, 110, 16)],
    sotto=lambda r, c=c: acqua(660, "#5e1218", "#c8463a"),
    diavoli=[(70, 600, ROSSO), (1220, 600, BLU)], particelle=("braci", 36, "#f2a65a"))

# ---------------------------------------------------------------- VIII · Frode
c = tinta("#08090a", "#6a7a5a")


def crollo(r):
    pece = ""
    for d in (0, 490):
        pece += poly([(338 + d, 618), (452 + d, 618), (420 + d, 650), (370 + d, 650)], "#050505", 1, 'stroke="#2a3a10" stroke-width="2"')
        pece += '<line x1="%d" y1="619" x2="%d" y2="619" stroke="#9fbf3f" stroke-width="2" opacity=".5"/>' % (345 + d, 445 + d)
        pece += "".join('<circle class="pulsa" cx="%d" cy="%d" r="%d" fill="none" stroke="#9fbf3f" stroke-width="1.5" opacity=".7"/>' % (x + d, y, rr)
                        for x, y, rr in ((372, 628, 4), (400, 634, 3), (425, 626, 5)))
    return pece + ('<polyline points="%s" fill="none" stroke="#ff8a2a" stroke-width="3"/>'
            '<rect class="cade" style="animation-duration:2s" x="636" y="532" width="8" height="8" fill="#5a5e62"/>'
            % pts([(640, 522), (650, 540), (642, 560)]))


FRODE = dict(id="frode", stile="bolgia", seme=31, verso=1, cielo=("#08090a", "#25282b"), luce=(640, 760, 640, "#9fbf3f", .25),
    piani=[
        ("stelle", lambda r, c=c: stelle(r, 20, "#9fbf3f"), .03),
        ("archi lontani", lambda r, c=c: poligoni(archi(r, 720, 7, (260, 360), (380, 460)), c(.45)), .08),
        ("nebbia", lambda r, c=c: nebbia(380, 160, "#9fbf3f", .12), 0),
        ("archi", lambda r, c=c: poligoni(archi(r, 720, 10, (180, 240), (240, 320)), c(.3)), .2),
        ("catene", lambda r, c=c: catene(r, 12, c(.26)), .35),
        ("archi vicini", lambda r, c=c: poligoni(archi(r, 760, 6, (220, 300), (150, 220)), c(.16)), .5),
        ("vicino", lambda r, c=c: poligoni(stalattiti(r, 14, (60, 180), (30, 70), 10), "#030304"), .8),
    ],
    isole=BOLGE, mat=mat("#4a4e52", "#7a8086", "#e2e8ec", "#050506", "#6a5a3a", "#ffd27a", "lastre", segni_op=.3),
    travi=[(300, 170, 110, 14), (880, 170, 110, 14)],
    sotto=lambda r, c=c: acqua(615, "#0a0a08", "#2a2a20"), sopra=crollo,
    diavoli=[(90, 520, ROSSO), (1190, 520, BLU)], particelle=("polvere", 24, "#9fbf3f"))

# ---------------------------------------------------------------- IX · Tradimento
c = tinta("#050a14", "#9fd0f0")


def ghiaccio(r):
    return (acqua(650, "#0c2238", "#6fb6e0", onde=False) +
            '<g opacity=".25"><circle cx="300" cy="690" r="16" fill="#bfe9ff"/><circle cx="820" cy="700" r="16" fill="#bfe9ff"/></g>')


TRADIMENTO = dict(id="tradimento", stile="ghiaccio", seme=37, verso=-1, cielo=("#050a14", "#1f4e79"), luce=(640, 300, 500, "#bfe9ff", .25),
    piani=[
        ("stelle", lambda r, c=c: stelle(r, 70, "#e8f8ff"), .03),
        ("lontano", lambda r, c=c: poligoni(creste(r, 350, 190, 90), c(.55)), .07),
        ("giganti", lambda r, c=c: poligoni(giganti(r, 640, 4), c(.4)), .14),
        ("nebbia", lambda r, c=c: nebbia(400, 180, "#bfe9ff", .25), 0),
        ("medio", lambda r, c=c: poligoni(creste(r, 540, 150, 100), c(.3)), .25),
        ("cristalli", lambda r, c=c: poligoni(cristalli(r, 680, 20), c(.2)), .4),
        ("stalattiti", lambda r, c=c: poligoni(stalattiti(r, 26, (40, 160), (16, 40), 0), c(.24)), .5),
        ("vicino", lambda r, c=c: poligoni(cristalli(r, 760, 10, (120, 300)), "#02050c"), .8),
    ],
    isole=LASTRONI, mat=mat("#8fc6e6", "#dff4ff", "#ffffff", "#0a1a2c", "#4a5464", "#d6dee8", "ghiaccio", segni="#ffffff", segni_op=.5, crosta_h=8),
    travi=[(350, 520, 110, 14), (820, 520, 110, 14)],
    sotto=ghiaccio,
    diavoli=[(60, 620, ROSSO), (1220, 620, BLU)], particelle=("neve", 70, "#e8f8ff"))

# ---------------------------------------------------------------- Purgatorio e Paradiso
c = tinta("#f6b48a", "#5b8fb0")


def mare(r):
    return '<rect x="0" y="470" width="%d" height="300" fill="#5b8fb0"/>' % T + "".join(
        '<rect x="%d" y="%d" width="%d" height="3" fill="#cfe6f2" opacity=".6"/>' % (r.uniform(0, T - 100), r.uniform(480, 700), r.uniform(30, 90)) for _ in range(50))


def monte(r):
    return (poly([(600, 470), (1200, 60), (1300, 60), (1900, 470)], mix("#f4c9a0", "#7aa0b8", .5)) +
            "".join('<rect x="%d" y="%d" width="%d" height="6" fill="#fff4e0" opacity=".5"/>' % (1200 - 60 * i, 100 + 52 * i, 100 + 120 * i) for i in range(7)))


PURGATORIO = dict(id="purgatorio", stile="prato", seme=41, verso=-1, cielo=("#f6b48a", "#cfe3f2"), luce=(950, 120, 400, "#fff1c9", .7),
    piani=[
        ("nubi", lambda r, c=c: nubi(r, 12, "#ffffff", .4, (40, 260)), .04),
        ("mare", mare, .03),
        ("monte", monte, .06),
        ("nebbia", lambda r, c=c: nebbia(380, 140, "#ffffff", .3), 0),
        ("isole", lambda r, c=c: poligoni(creste(r, 560, 60, 260, piatte=True), "#6f9a8a"), .2),
        ("vicino", lambda r, c=c: poligoni(creste(r, 690, 50, 160), "#4a6b5a"), .6),
    ],
    isole=MONTE, mat=mat("#b8ad98", "#7fae5a", "#d9f0b0", "#3a3226", "#7a8290", "#eef2f8", "lastre", segni="#3a3226", segni_op=.25),
    travi=[(320, 410, 90, 14), (870, 410, 90, 14)],
    diavoli=[(150, 620, ROSSO), (200, 620, FAVILLA)], particelle=("polvere", 20, "#ffffff"))


def cerchi(r):
    return "".join('<circle cx="%d" cy="360" r="%d" fill="none" stroke="#fff3c4" stroke-width="%d" opacity="%.2f"/>' % (640 + T // 2 * j, 120 + 90 * i, 3 + i, .5 - .05 * i)
                   for i in range(8) for j in range(2))


PARADISO = dict(id="paradiso", stile="nuvola", seme=43, verso=1, cielo=("#1a1f5c", "#6a5fb0"), luce=(640, 360, 440, "#fff1a8", .6),
    piani=[
        ("cerchi", cerchi, .03),
        ("stelle", lambda r, c=c: stelle(r, 60, "#fff8dc"), .1),
        ("nebbia", lambda r, c=c: nebbia(500, 200, "#ffe6a0", .25), 0),
        ("isole di luce", lambda r, c=c: poligoni(scogli(r, 10, (200, 520), (60, 140)), "#8a80d0", .6), .3),
        ("nubi", lambda r, c=c: nubi(r, 10, "#fff3c4", .25, (420, 640)), .6),
    ],
    isole=CERCHI, mat=mat("#e8e2ff", "#fff6c8", "#ffffff", "#2a2460", "#b0a060", "#fff6c8", "ghiaccio", segni="#8a80d0", segni_op=.4, crosta_h=8),
    travi=[(380, 200, 100, 14), (800, 200, 100, 14)],
    diavoli=[(600, 610, ROSSO), (650, 610, FAVILLA)], particelle=("neve", 30, "#fff3c4"))

GIRONI = [FORGIA, LIMBO, LUSSURIA, GOLA, AVARIZIA, IRA, ERESIA, VIOLENZA, FRODE, TRADIMENTO]
