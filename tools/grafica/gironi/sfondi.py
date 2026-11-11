# Gli sfondi dei gironi fatti a mano, come quello del cortile (cortile.py): ogni girone ha il suo
# luogo riconoscibile a più piani, con le luci accese (finestre, fuochi, lampi, bagliori) e il buio
# che sale dal fondo, invece delle sole creste generiche di tavole.py (Sergio, 11 nov: «perché
# molte mappe non hanno il background a livelli e tutto?»).
#
#   sfondo(nome, P) -> {'luce': sorgente del cielo, 'gruppi': [(gruppo, svg largo un giro, velocità)]}
#
# Ogni piano è (velocità, sagome, luci, davanti): le sagome si colorano nella tinta del girone e
# sfumano verso la foschia (dipinto.sfuma_sagome), le luci restano accese nella tinta della luce,
# «davanti» sono i dettagli scuri sopra le luci (grate, rami, occhi). La velocità sceglie il gruppo
# dello shader (dipinto.GRUPPI): sotto .2 lontano, fino a .45 medio, oltre vicino.
# Il piano vicino ha solo il buio dal basso e poche cose appese dall'alto: un bordo netto sotto le
# piattaforme si confonde col terreno (Sergio, 6 nov, il cortile).
import math, random
from mondo import T, creste, torri, camini, nubi, poligoni, mura, colonne, stalattiti, catene, stelle, scie, \
    cristalli, mucchi, canne, scogli, giganti, LATO
from scena import W, H, mix, poly, nebbia, Id, pts
from dipinto import colora, sfuma_sagome, GRUPPI


# ---------------------------------------------------------------- pezzi comuni
def tinta(base, chiaro):
    return lambda t: mix(base, chiaro, t)


def luce_su(polys, col, op):
    """Aperture accese: la luce più forte in basso, come dietro una finestra o un portone."""
    if not polys:
        return ""
    gid = Id.new("acc")
    return ("<defs><linearGradient id='%s' x1='0' y1='1' x2='0' y2='0'><stop offset='0' stop-color='%s' stop-opacity='%.2f'/>"
            "<stop offset='1' stop-color='%s' stop-opacity='%.2f'/></linearGradient></defs>" % (gid, col, op, col, op * .25)
            + "".join(poly(p, "url(#%s)" % gid) for p in polys))


def accese(polys, col, op):
    return "".join(poly(p, col, op) for p in polys)


def alone(cx, cy, r, col, op):
    gid = Id.new("al")
    return ("<defs><radialGradient id='%s'><stop offset='0' stop-color='%s' stop-opacity='%.2f'/>"
            "<stop offset='1' stop-color='%s' stop-opacity='0'/></radialGradient></defs>"
            "<ellipse cx='%g' cy='%g' rx='%g' ry='%g' fill='url(#%s)'/>" % (gid, col, op, col, cx, cy, r, r * .7, gid))


def fiamma(x, y, s=1.0):
    """Una fiamma a punte sopra il punto (x, y)."""
    return [(x - 14 * s, y), (x - 9 * s, y - 22 * s), (x - 3 * s, y - 14 * s), (x + 1 * s, y - 34 * s),
            (x + 6 * s, y - 15 * s), (x + 11 * s, y - 25 * s), (x + 14 * s, y)]


def finestra(x, y, w, h):
    """Finestra ad arco acuto: x, y in basso a sinistra."""
    return [(x, y), (x, y - h + w * .6), (x + w / 2, y - h), (x + w, y - h + w * .6), (x + w, y)]


def buio(y0, col, op=.92, y1=H + 40):
    """Il buio che sale dal fondo, uguale su tutto il giro."""
    gid = Id.new("buio")
    return ("<defs><linearGradient id='%s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='%s' stop-opacity='0'/>"
            "<stop offset='1' stop-color='%s' stop-opacity='%.2f'/></linearGradient></defs>"
            '<rect x="0" y="%g" width="%g" height="%g" fill="url(#%s)"/>' % (gid, col, col, op, y0, T, y1 - y0, gid))


def due_volte(f):
    """Un disegno messo due volte nel giro (a 0 e a metà), così ogni schermo ne vede uno."""
    return [f(0), f(T / 2)]


def sposta(polys, dx, dy=0):
    return [[(x + dx, y + dy) for x, y in p] for p in polys]


def nebbia_giro(y, h, col, op):
    """La nebbia ferma, larga un giro (va col gruppo lontano)."""
    return '<g transform="scale(%g,1)">%s</g>' % (T / W, nebbia(y, h, col, op))


def raggiera(cx, cy, n, lung, col, op, rng, apertura=(.2, 2.9)):
    s = ""
    for _ in range(n):
        a, w = rng.uniform(*apertura), rng.uniform(.02, .06)
        s += poly([(cx, cy), (cx + math.cos(a - w) * lung, cy + math.sin(a - w) * lung),
                   (cx + math.cos(a + w) * lung, cy + math.sin(a + w) * lung)], col, rng.uniform(.04, .1))
    return s


# ---------------------------------------------------------------- I · Limbo
def limbo(P, rng):
    """Il nobile castello cinto sette volte d'alte mura, sul prato verde, col fiumicello davanti;
    colonne e archi in rovina sui fianchi, la luce chiara degli spiriti magni dalle finestre."""
    c = tinta("#1d2522", "#c9d6cc")
    L = P["luce"]

    def castello(x0):
        sag, fin = [], []
        # le sette cerchia: mura merlate sempre più strette e più alte verso il mastio
        for k in range(7):
            w, y = 900 - k * 110, 520 - k * 34
            a, b = x0 + 640 - w / 2, x0 + 640 + w / 2
            p = [(a, H + 40), (a, y)]
            x = a
            while x < b - 14:
                p += [(x, y), (x, y - 12), (x + 14, y - 12), (x + 14, y)]
                x += 28
            p += [(b, y), (b, H + 40)]
            sag.append(p)
            for sx in (a, b - 34):
                sag.append([(sx, H + 40), (sx, y - 40), (sx + 17, y - 78), (sx + 34, y - 40), (sx + 34, H + 40)])
                fin.append(finestra(sx + 12, y - 14, 10, 20))
            for j in range(3, int(w / 60) - 2):
                if j % 2 == 0:
                    fin.append(finestra(a + j * 60 + 20, y + 26, 12, 22))
        # il mastio con le torri a punta
        mx = x0 + 640
        sag.append([(mx - 70, H + 40), (mx - 70, 210), (mx - 90, 210), (mx - 90, 196), (mx + 90, 196), (mx + 90, 210),
                    (mx + 70, 210), (mx + 70, H + 40)])
        sag.append([(mx - 30, 200), (mx, 120), (mx + 30, 200)])
        for sx in (-110, 80):
            sag.append([(mx + sx, H + 40), (mx + sx, 250), (mx + sx + 15, 196), (mx + sx + 30, 250), (mx + sx + 30, H + 40)])
        fin += [finestra(mx - 12, 260, 24, 46), finestra(mx - 50, 300, 14, 26), finestra(mx + 36, 300, 14, 26)]
        # il portone con la luce
        fin.append(finestra(mx - 26, 520, 52, 70))
        return sag, fin

    sag, fin = [], []
    for x0 in (180, 180 + T / 2):
        s, f = castello(x0)
        sag += s
        fin += f
    # il fiumicello davanti al castello: una striscia lucida
    fiume = "".join('<rect x="%g" y="%g" width="%g" height="3" fill="%s" opacity="%.2f"/>' % (rng.uniform(0, T - 300), 560 + rng.uniform(0, 24),
                                                                                            rng.uniform(80, 300), L, rng.uniform(.15, .35)) for _ in range(26))
    archi_ = []
    for i in range(10):
        x = i * T / 10 + rng.uniform(-40, 40)
        w, h = rng.uniform(140, 200), rng.uniform(180, 260)
        p = w * .18
        rotto = rng.uniform(0, 1) < .5
        top = 600 - h
        archi_.append([(x, H + 40), (x, top), (x + w, top + (30 if rotto else 0)), (x + w, H + 40), (x + w - p, H + 40),
                       (x + w - p, top + w * .55), (x + w / 2, top + w * .25), (x + p, top + w * .55), (x + p, H + 40)])
    return dict(luce=(640, -60, 560, L, .5), nebbie=[(380, 170, P["foschia"], .35), (560, 140, P["foschia"], .3)], piani=[
        (.04, nubi(rng, 14, "#e6eee8", .14, (40, 220)), "", ""),
        (.07, poligoni(creste(rng, 380, 80, 260, piatte=True), c(.34)), "", ""),
        (.14, poligoni(sag, c(.26)), luce_su(fin, L, .75), fiume),
        (.3, poligoni(archi_, c(.17)) + poligoni(colonne(rng, 640, 12, (120, 280)), c(.15)), "", ""),
        (.7, buio(520, "#0c120f", .9), "", ""),
    ])


# ---------------------------------------------------------------- II · Lussuria
def lussuria(P, rng):
    """La bufera infernal che mai non resta: la scogliera della ruina, il turbine di anime a
    spirale nel cielo, lampi; schegge che volano lontano."""
    c = tinta("#120a1f", "#c4b0f4")
    L = P["luce"]

    def turbine(cx, cy):
        s = ""
        for k in range(26):
            r = 40 + k * 13
            a0 = k * .55
            d = "M%g,%g" % (cx + math.cos(a0) * r, cy + math.sin(a0) * r * .45)
            for j in range(1, 5):
                a = a0 + j * .28
                d += " L%g,%g" % (cx + math.cos(a) * (r + j * 3), cy + math.sin(a) * (r + j * 3) * .45 - j * 4)
            s += '<path d="%s" fill="none" stroke="%s" stroke-width="%g" stroke-linecap="round" opacity="%.2f"/>' % (
                d, L, rng.choice([2, 3, 4]), rng.uniform(.18, .5))
        # le anime: piccole sagome chiare trascinate
        for k in range(18):
            a, r = rng.uniform(0, 6.28), rng.uniform(60, 360)
            x, y = cx + math.cos(a) * r, cy + math.sin(a) * r * .45
            s += poly([(x, y), (x + 5, y - 10), (x + 10, y), (x + 22 * math.cos(a + 1.6), y + 4)], L, rng.uniform(.35, .7))
        return s

    def lampo(x, y):
        p = [(x, y)]
        for _ in range(6):
            x, y = x + rng.uniform(-30, 30), y + rng.uniform(40, 60)
            p.append((x, y))
        return '<polyline points="%s" fill="none" stroke="%s" stroke-width="4" opacity=".8"/>' % (pts(p), "#f3e9ff") + \
            '<polyline points="%s" fill="none" stroke="%s" stroke-width="12" opacity=".15"/>' % (pts(p), L)

    # la ruina: la scogliera spaccata con la frana
    rupi = []
    for x0 in (0, T / 2):
        rupi.append([(x0 + 60, H + 40), (x0 + 60, 470), (x0 + 160, 400), (x0 + 200, 420), (x0 + 270, 330), (x0 + 330, 360),
                     (x0 + 360, 300), (x0 + 450, 340), (x0 + 520, 470), (x0 + 600, 520), (x0 + 640, H + 40)])
        rupi.append([(x0 + 820, H + 40), (x0 + 860, 500), (x0 + 940, 450), (x0 + 1010, 470), (x0 + 1100, 380), (x0 + 1170, 430),
                     (x0 + 1240, 520), (x0 + 1280, H + 40)])
    frana = scogli(rng, 16, (300, 560), (30, 90))
    return dict(luce=(760, 120, 420, L, .4), nebbie=[(470, 150, P["foschia"], .25)], piani=[
        (.03, stelle(rng, 40, "#e8dcff"), "", ""),
        (.08, poligoni(creste(rng, 430, 110, 140), c(.29)), turbine(700, 200) + turbine(700 + T / 2, 230) + lampo(1180, 0) + lampo(2350, 20), ""),
        (.16, poligoni(scogli(rng, 14, (100, 380), (40, 120)), c(.23)), "", ""),
        (.3, poligoni(rupi, c(.05)) + poligoni(frana, c(.08)), scie(rng, 8, "#e05fa8"), ""),
        (.7, buio(500, "#0a0612", .92), scie(rng, 5, "#f3e9ff").replace('opacity="0.', 'opacity="0.0'), ""),
    ])


# ---------------------------------------------------------------- III · Gola
def gola(P, rng):
    """La piova etterna, maladetta, fredda e greve: la grotta di Cerbero che si apre nel monte con i
    suoi tre musi di roccia e gli occhi rossi, colline di fango, pioggia fitta e pozzanghere lucide."""
    c = tinta("#1a1d1a", "#cfd3c7")
    L = P["luce"]

    TESTA = [(-56, 170), (-36, 10), (-22, -30), (-30, -76), (-4, -38), (20, -42), (42, -28), (92, -16), (100, 2),
             (90, 14), (44, 16), (56, 30), (30, 50), (34, 170)]
    FAUCI = [(44, 8), (92, 6), (86, 14), (46, 22)]

    def cerbero(x0):
        sag, occhi, fauci = [], [], []
        # il corpo, una collina di roccia accucciata
        sag.append([(x0 + 180, H + 40), (x0 + 260, 420), (x0 + 380, 360), (x0 + 520, 340), (x0 + 700, 350), (x0 + 840, 390),
                    (x0 + 960, 440), (x0 + 1040, H + 40)])
        # tre teste di cane sui colli, quella in mezzo più alta, le altre girate in fuori
        for hx, hy, d, k in ((x0 + 450, 300, -1, .95), (x0 + 610, 230, 1, 1.15), (x0 + 780, 300, 1, .95)):
            tr = lambda p: [(hx + d * x * k, hy + y * k) for x, y in p]
            sag.append(tr(TESTA))
            occhi.append(tr([(18, -30), (34, -26), (22, -20)]))
            fauci.append(tr(FAUCI))
        return sag, occhi, fauci

    sag, occhi, fauci = [], [], []
    for x0 in (0, T / 2):
        s, o, fa = cerbero(x0)
        sag += s
        occhi += o
        fauci += fa
    def pioggia(n, op, l, sp):
        return "".join('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="%g" opacity="%.2f"/>'
                       % (x, y, x - l / 4, y + l, "#c8ccc6", sp, op * rng.uniform(.6, 1.2))
                       for x, y in [(rng.uniform(0, T), rng.uniform(-40, 700)) for _ in range(n)])
    pozze = "".join('<ellipse cx="%g" cy="%g" rx="%g" ry="4" fill="%s" opacity="%.2f"/>' % (
        rng.uniform(0, T), rng.uniform(600, 660), rng.uniform(40, 120), L, rng.uniform(.1, .22)) for _ in range(18))
    return dict(luce=(640, 140, 420, L, .3), nebbie=[(300, 200, P["foschia"], .25), (520, 160, P["foschia"], .2)], piani=[
        (.05, nubi(rng, 16, "#0e100e", .5, (10, 200)), "", ""),
        (.08, poligoni(creste(rng, 380, 60, 260, piatte=True), c(.28)), pioggia(140, .22, 30, 1.2), ""),
        (.18, poligoni(sag, c(.18)), accese(fauci, "#ff6a3a", .75) + accese(occhi, "#ff5a3a", .95)
         + "".join(alone(p[1][0], p[1][1], 40, "#ff5a3a", .3) for p in occhi), ""),
        (.32, poligoni(creste(rng, 610, 70, 160, piatte=True), c(.12)) + poligoni(stalattiti(rng, 22, (40, 140), (24, 60), 20), c(.08)),
         pozze + pioggia(120, .3, 44, 1.6), ""),
        (.7, buio(520, "#0b0d0b", .92), pioggia(60, .35, 70, 2.2), ""),
    ])


# ---------------------------------------------------------------- IV · Avarizia
def avarizia(P, rng):
    """I monti d'oro degli avari e dei prodighi: mucchi di monete che brillano, forzieri aperti, la
    grande bilancia storta di Pluto e i massi che rotolano giù per i pendii."""
    c = tinta("#1a1208", "#ddb060")
    L = P["luce"]

    def bilancia(x):
        sag = [[(x - 8, H + 40), (x - 8, 210), (x + 8, 210), (x + 8, H + 40)],
               [(x - 60, H + 40), (x - 30, 520), (x + 30, 520), (x + 60, H + 40)],
               [(x - 200, 230), (x + 200, 190), (x + 200, 200), (x - 200, 240)],
               [(x - 16, 210), (x, 186), (x + 16, 210)]]
        luci = []
        for sx, y in ((-200, 236), (200, 196)):
            px = x + sx
            dy = 150 if sx < 0 else 90
            sag.append([(px - 1, y), (px - 70, y + dy), (px - 68, y + dy), (px + 1, y + 4)])
            sag.append([(px + 1, y), (px + 70, y + dy), (px + 68, y + dy), (px - 1, y + 4)])
            sag.append([(px - 80, y + dy), (px + 80, y + dy), (px + 60, y + dy + 22), (px - 60, y + dy + 22)])
            luci.append([(px - 60, y + dy), (px - 30, y + dy - 26), (px, y + dy - 36), (px + 30, y + dy - 24), (px + 60, y + dy)])
        return sag, luci

    def forziere(x, y):
        return ([[(x, y), (x + 70, y), (x + 70, y - 40), (x, y - 40)], [(x - 4, y - 40), (x + 74, y - 40), (x + 64, y - 70), (x + 6, y - 74)]],
                [[(x + 6, y - 40), (x + 64, y - 40), (x + 50, y - 52), (x + 20, y - 54)]])

    sag, oro = [], []
    for x0 in (900, 900 + T / 2):
        s, l = bilancia(x0)
        sag += s
        oro += l
    forzieri, oro2 = [], []
    for x in (300, 1500, 2000):
        s, l = forziere(x, 610)
        forzieri += s
        oro2 += l
    monete = lambda n, y0, y1, op: "".join('<rect x="%.0f" y="%.0f" width="%.1f" height="%.1f" fill="%s" opacity="%.2f" transform="rotate(45 %.0f %.0f)"/>'
                                           % (x, y, r, r, L, rng.uniform(.4, .95) * op, x, y)
                                           for x, y, r in [(rng.uniform(0, T), rng.uniform(y0, y1), rng.uniform(3, 7)) for _ in range(n)])
    mu1, mu2 = mucchi(rng, 520, 12, (180, 340)), mucchi(rng, 680, 9, (240, 420))
    # i massi sui pendii lontani
    massi = [[(x - 26, y), (x - 14, y - 26), (x + 12, y - 30), (x + 28, y - 8), (x + 16, y + 2), (x - 18, y + 2)]
             for x, y in [(rng.uniform(0, T), rng.uniform(470, 520)) for _ in range(10)]]
    return dict(luce=(640, 140, 460, L, .4), nebbie=[(330, 160, L, .12), (560, 120, P["foschia"], .25)], piani=[
        (.04, nubi(rng, 10, "#120c05", .35, (40, 200)), "", ""),
        (.08, poligoni(creste(rng, 360, 160, 200), c(.24)), monete(40, 260, 360, .5), ""),
        (.16, poligoni(mu1 + sag, c(.19)) + poligoni(massi, c(.14)), luce_su(mu1, L, .3) + accese(oro, L, .55) + monete(90, 360, 520, .7), ""),
        (.32, poligoni(mu2 + forzieri, c(.12)), luce_su(mu2, L, .22) + accese(oro2, L, .8) + monete(70, 520, 680, .9)
         + "".join(alone(x + 35, 570, 90, L, .25) for x in (300, 1500, 2000)), catene(rng, 6, c(.14))),
        (.7, buio(540, "#0e0904", .92), "", ""),
    ])


# ---------------------------------------------------------------- V · Ira
def ira(P, rng):
    """La palude Stige: acqua scura e ferma, canne, tronchi morti, l'alta torre con le due
    fiammette del segnale, la barca di Flegiàs con la lanterna e lontano le mura rosse di Dite."""
    c = tinta("#071012", "#6fa8a4")
    L = P["luce"]

    def torre(x):
        sag = [[(x - 40, H + 40), (x - 30, 230), (x - 46, 230), (x - 46, 214), (x + 46, 214), (x + 46, 230), (x + 30, 230), (x + 40, H + 40)],
               [(x - 60, H + 40), (x - 50, 520), (x + 50, 520), (x + 60, H + 40)]]
        fin = [finestra(x - 8, 320, 16, 30), finestra(x - 8, 420, 16, 30)]
        fuochi = [fiamma(x - 20, 214, .9), fiamma(x + 20, 214, .9)]
        return sag, fin, fuochi

    sag, fin, fuochi = [], [], []
    for x in (520, 520 + T / 2):
        s, f, fu = torre(x)
        sag += s
        fin += f
        fuochi += fu
    # la barca di Flegiàs con la lanterna
    barche, lanterne = [], ""
    for x in (1400, 1400 + T / 2 - 300):
        y = 590
        barche += [[(x - 90, y), (x + 90, y), (x + 70, y + 18), (x - 70, y + 18)], [(x + 40, y), (x + 43, y - 70), (x + 46, y)],
                   [(x - 20, y), (x - 26, y - 46), (x - 14, y - 52), (x - 8, y)]]
        lanterne += alone(x + 43, y - 76, 50, "#ffb36a", .45) + poly([(x + 38, y - 82), (x + 48, y - 82), (x + 46, y - 70), (x + 40, y - 70)], "#ffd9a0", .95)
    # le mura di Dite lontane, rosse
    dite = mura(rng, 470, 26, 8) + torri(rng, 450, 16, (14, 26), (20, 80))
    riflessi = "".join('<rect x="%g" y="%g" width="%g" height="2" fill="%s" opacity="%.2f"/>' % (
        rng.uniform(0, T), rng.uniform(560, 700), rng.uniform(40, 200), L, rng.uniform(.08, .2)) for _ in range(50))
    tronchi = []
    for _ in range(8):
        x, h = rng.uniform(0, T), rng.uniform(140, 260)
        tronchi += [[(x, H + 40), (x + 4, 640 - h), (x + 12, 640 - h + 10), (x + 16, H + 40)],
                    [(x + 8, 640 - h * .6), (x + 50, 640 - h * .8), (x + 52, 640 - h * .78), (x + 12, 640 - h * .5)]]
    return dict(luce=(640, 470, 560, "#e0532f", .22), nebbie=[(470, 140, P["foschia"], .4), (590, 110, L, .14)], piani=[
        (.04, stelle(rng, 30, "#cfe8e4"), "", ""),
        (.07, poligoni(creste(rng, 440, 40, 260, piatte=True), c(.29)) + poligoni(dite, c(.23)),
         alone(1280, 420, 900, "#e0532f", .2) + luce_su([finestra(rng.uniform(0, T), 440, 4, 8) for _ in range(30)], "#ff7a4a", .8), ""),
        (.16, poligoni(sag, c(.17)), luce_su(fin, L, .7) + accese(fuochi, "#ff9a3a", .95)
         + alone(500, 200, 120, "#ff9a3a", .35) + alone(540, 200, 120, "#ff9a3a", .35)
         + alone(500 + T / 2, 200, 120, "#ff9a3a", .35) + alone(540 + T / 2, 200, 120, "#ff9a3a", .35), ""),
        (.3, poligoni([[(0, 590), (T, 590), (T, H + 40), (0, H + 40)]], c(.09)) + poligoni(barche + tronchi, c(.08)),
         riflessi + lanterne, poligoni(canne(rng, 640, 60), c(.06))),
        (.7, buio(540, "#050c0d", .92), "", ""),
    ])


# ---------------------------------------------------------------- VI · Eresia
def eresia(P, rng):
    """La città di Dite: le mura di ferro, le meschite vermiglie come uscite del fuoco, le torri
    con le Furie, e davanti la campagna di sepolcri aperti con le fiamme dentro."""
    c = tinta("#0d0505", "#b07a6a")
    F = "#ff6a2a"

    def citta(x0):
        sag, fin = [], []
        sag.append([(x0, H + 40), (x0, 360)] + [(x0 + i * 20 + d, 360 - 12 * (i % 2)) for i in range(0, 60) for d in (0, 20)][:-1]
                   + [(x0 + 1200, 360), (x0 + 1200, H + 40)])
        for k, (tx, th, tw) in enumerate(((120, 200, 80), (380, 260, 70), (600, 330, 110), (860, 240, 70), (1080, 190, 80))):
            x, top = x0 + tx, 360 - th
            sag.append([(x, H + 40), (x, top), (x - 10, top), (x + tw / 2, top - tw * .9), (x + tw + 10, top), (x + tw, top), (x + tw, H + 40)])
            for j in range(int(th / 60)):
                fin.append(finestra(x + tw / 2 - 7, top + 50 + j * 60, 14, 28))
            if k == 2:   # la torre delle Furie: tre sagome sulla cima
                for sx in (-28, 0, 28):
                    fx = x + tw / 2 + sx
                    sag.append([(fx - 8, top - tw * .9 + 30), (fx - 4, top - tw * .9 + 6), (fx, top - tw * .9 - 2), (fx + 4, top - tw * .9 + 6),
                                (fx + 8, top - tw * .9 + 30)])
        fin.append(finestra(x0 + 560, 470, 80, 110))
        # la città sta lontana, dietro il campo dei sepolcri: più piccola e più in basso
        k = lambda ps: [[(x0 + 200 + (x - x0) * .7, 500 + (y - 470) * .62) for x, y in p] for p in ps]
        return k(sag), k(fin)

    sag, fin = [], []
    for x0 in (300, 300 + T / 2):
        s, f = citta(x0)
        sag += s
        fin += f
    sepolcri, fuochi = [], []
    for i in range(14):
        x = i * T / 14 + rng.uniform(-30, 30)
        y = 500 + rng.uniform(-10, 40)
        sepolcri += [[(x, H + 40), (x, y), (x + 70, y), (x + 70, H + 40)], [(x + 54, y - 5), (x + 100, y - 24), (x + 103, y - 17), (x + 59, y + 3)]]
        fuochi += [fiamma(x + 17, y, .6), fiamma(x + 35, y, .85), fiamma(x + 54, y, .55)]
    return dict(luce=(640, 720, 680, F, .32), nebbie=[(330, 190, F, .1), (520, 160, P["foschia"], .3)], piani=[
        (.04, nubi(rng, 12, "#140504", .5, (20, 220)), "", ""),
        (.08, poligoni(creste(rng, 400, 70, 220) + torri(rng, 420, 22, (16, 34), (40, 160)), c(.26)),
         alone(640, 420, 900, F, .18) + alone(640 + T / 2, 420, 900, F, .18)
         + luce_su([finestra(rng.uniform(0, T), rng.uniform(330, 400), 5, 10) for _ in range(40)], F, .7), ""),
        (.16, poligoni(sag, c(.15)), luce_su(fin, F, .85), ""),
        (.32, poligoni(sepolcri, c(.09)), accese(fuochi, F, .9) + "".join(alone(p[3][0], p[3][1] + 20, 70, F, .35) for p in fuochi[1::3]), ""),
        (.7, buio(540, "#0a0303", .92), "", ""),
    ])


# ---------------------------------------------------------------- VII · Violenza
def ramo(rng, x, y, a, l, w, n, out, punte):
    """Un ramo storto che si divide: segmenti spessi (stroke), le punte dove si posano le Arpie."""
    ex, ey = x + math.cos(a) * l, y + math.sin(a) * l
    mx, my = (x + ex) / 2 + rng.uniform(-l, l) * .15, (y + ey) / 2 + rng.uniform(-l, l) * .15
    out.append((pts([(x, y), (mx, my), (ex, ey)]), w))
    if n == 0 or w < 2:
        punte.append((ex, ey))
        return
    for da in (rng.uniform(-.7, -.25), rng.uniform(.25, .7)):
        ramo(rng, ex, ey, a + da, l * rng.uniform(.6, .75), w * .62, n - 1, out, punte)


def bosco(rng, xs, y, h, w, col):
    """Alberi morti (il bosco dei suicidi): -> svg, punte."""
    segs, punte = [], []
    for x in xs:
        out = []
        ramo(rng, x, y + 40, -math.pi / 2 + rng.uniform(-.12, .12), h * .45, w, 3, out, punte)
        segs += out
    svg_ = "".join('<polyline points="%s" fill="none" stroke="%s" stroke-width="%.1f" stroke-linecap="round" stroke-linejoin="round"/>'
                   % (p, col, ww) for p, ww in segs)
    return svg_, punte


def violenza(P, rng):
    """Il bosco dei suicidi con le Arpie sui rami, il Flegetonte che bolle rosso in fondo alla valle
    e il sabbione dove piove fuoco lento."""
    c = tinta("#12060a", "#c09aa8")
    F = "#ff7a3a"
    lontani, _ = bosco(rng, [i * T / 18 + rng.uniform(-30, 30) for i in range(18)], 470, 200, 7, c(.3))
    vicini, punte = bosco(rng, [i * T / 8 + rng.uniform(-50, 50) for i in range(8)], 640, 380, 16, c(.12))
    arpie = []
    for ex, ey in punte[::9]:
        arpie.append([(ex - 22, ey - 6), (ex - 8, ey - 14), (ex, ey - 26), (ex + 8, ey - 14), (ex + 22, ey - 6), (ex + 6, ey - 4),
                      (ex, ey + 6), (ex - 6, ey - 4)])
    fiume = '<rect x="0" y="470" width="%d" height="18" fill="%s" opacity=".55"/>' % (T, "#b0222a") + "".join(
        '<rect x="%g" y="%g" width="%g" height="2" fill="%s" opacity="%.2f"/>' % (rng.uniform(0, T), 472 + rng.uniform(0, 12), rng.uniform(40, 160), F, rng.uniform(.3, .6))
        for _ in range(40))
    fuoco = "".join('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="%g" stroke-linecap="round" opacity="%.2f"/>'
                    % (x, y, x + 8, y + 36, F, rng.choice([2, 3]), rng.uniform(.3, .7))
                    for x, y in [(rng.uniform(0, T), rng.uniform(0, 400)) for _ in range(46)])
    return dict(luce=(1100, 60, 460, P["luce"], .35), nebbie=[(440, 120, "#b0222a", .16), (560, 130, P["foschia"], .3)], piani=[
        (.04, nubi(rng, 10, "#12060a", .45, (20, 200)), "", ""),
        (.08, poligoni(creste(rng, 470, 120, 200, piatte=True), c(.3)), fuoco + alone(1280, 480, 1000, "#b0222a", .2) + fiume, ""),
        (.16, "", "", lontani),
        (.32, poligoni(arpie, c(.1)), "".join(alone(p[2][0], p[2][1] + 8, 16, F, .8) for p in arpie), vicini),
        (.7, buio(540, "#0b0306", .92), "", ""),
    ])


# ---------------------------------------------------------------- VIII · Frode
def frode(P, rng):
    """Malebolge visto dall'orlo: dieci fosse ad anello una dentro l'altra che scendono verso il
    pozzo, i ponti di roccia che le scavalcano come raggi, la pece che bolle verde in fondo e le
    lanterne dei diavoli sui ponti."""
    c = tinta("#08090a", "#a8b49a")
    G = P["luce"]

    def bolge(cx, cy):
        sag, luci, sopra = [], "", ""
        n = 7
        for k in range(n):
            rx = 900 - k * 115
            ry = rx * .3
            y = cy - (n - k) * 6
            # un anello: l'orlo chiaro sopra, la fossa scura sotto
            p = [(cx + math.cos(a) * rx, y + math.sin(a) * ry) for a in [math.pi + i * math.pi / 30 for i in range(31)]]
            sag.append([(cx - rx, H + 40)] + p + [(cx + rx, H + 40)])
            sopra += '<polyline points="%s" fill="none" stroke="%s" stroke-width="%g" opacity=".55"/>' % (pts(p), "#c8d0b0", 3 - k * .3)
            for a in [math.pi + (i + .5) * math.pi / 9 for i in range(9)]:     # i gradoni della fossa
                x_, y_ = cx + math.cos(a) * rx, y + math.sin(a) * ry
                sopra += '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="2" opacity=".35"/>' % (x_, y_, x_ + (cx - x_) * .08, y_ + 40, "#000000")
        # i ponti: archi di roccia a raggiera dall'orlo verso il pozzo
        for a in (-.75, -.3, .15, .6):
            x1, y1 = cx + math.sin(a) * 900, cy - 40
            x2, y2 = cx + math.sin(a) * 160, cy + 30
            sopra += '<path d="M%g,%g Q%g,%g %g,%g" fill="none" stroke="%s" stroke-width="14" stroke-linecap="round"/>' % (
                x1, y1, (x1 + x2) / 2, min(y1, y2) - 40, x2, y2, "#3a3c36") + \
                '<path d="M%g,%g Q%g,%g %g,%g" fill="none" stroke="%s" stroke-width="3" opacity=".5"/>' % (x1, y1 - 6, (x1 + x2) / 2, min(y1, y2) - 46, x2, y2 - 6, "#8a8f7a")
            for t in (.3, .6):
                lx = x1 + (x2 - x1) * t
                ly = y1 + (y2 - y1) * t - 40 * 2 * t * (1 - t) * 2 - 8
                luci += alone(lx, ly, 26, "#ffb36a", .45) + poly([(lx - 3, ly + 4), (lx + 3, ly + 4), (lx + 2, ly - 6), (lx - 2, ly - 6)], "#ffd9a0", .9)
        luci += alone(cx, cy + 40, 260, G, .28)
        for i in range(10):
            bx = cx + rng.uniform(-120, 120)
            luci += '<circle cx="%g" cy="%g" r="%g" fill="none" stroke="%s" stroke-width="2" opacity="%.2f"/>' % (bx, cy + 30 + rng.uniform(0, 16), rng.uniform(3, 8), G, rng.uniform(.3, .6))
        return sag, luci, sopra

    sag, luci, sopra = [], "", ""
    for cx in (640, 640 + T / 2):
        s_, l_, so = bolge(cx, 400)
        sag += s_
        luci += l_
        sopra += so
    diavoli = []
    for x in (300, 980, 1580, 2240):
        y = 640
        diavoli.append([(x - 8, y), (x - 10, y - 30), (x - 14, y - 40), (x - 8, y - 36), (x, y - 44), (x + 8, y - 36), (x + 14, y - 40), (x + 10, y - 30), (x + 8, y)])
        diavoli.append([(x + 12, y - 10), (x + 30, y - 70), (x + 33, y - 70), (x + 16, y - 10)])
    return dict(luce=(640, 560, 640, G, .3), nebbie=[(430, 170, G, .08), (560, 150, P["foschia"], .3)], piani=[
        (.04, stelle(rng, 14, "#cfe0a0") + nubi(rng, 10, "#0b0c0b", .5, (10, 200)), "", ""),
        (.08, poligoni(creste(rng, 320, 60, 260, piatte=True), c(.3)), "", ""),
        (.18, "".join(poly(p, mix(c(.26), c(.04), k / 13)) for k, p in enumerate(sag)) + sopra, luci, ""),
        (.34, poligoni(diavoli + stalattiti(rng, 18, (60, 160), (24, 50), 10), c(.08)), "", ""),
        (.7, buio(540, "#050605", .92), "", ""),
    ])


# ---------------------------------------------------------------- IX · Tradimento
def tradimento(P, rng):
    """Cocito: il lago gelato senza fine e in fondo, gigantesco, Lucifero mezzo nel ghiaccio con le
    sei ali e gli occhi accesi; guglie di ghiaccio che riflettono la luce fredda, i dannati come
    ombre sotto la crosta."""
    c = tinta("#050a14", "#a9cde8")
    L = P["luce"]

    def lucifero(x):
        s = [[(x - 170, H + 40), (x - 160, 330), (x - 120, 280), (x - 62, 262), (x - 52, 205), (x - 74, 160), (x - 42, 128), (x, 148),
              (x + 42, 128), (x + 74, 160), (x + 52, 205), (x + 62, 262), (x + 120, 280), (x + 160, 330), (x + 170, H + 40)]]
        for sx in (-1, 1):
            for k, (ay, aw) in enumerate(((250, 470), (310, 420), (370, 350))):
                tip = x + sx * aw
                s.append([(x + sx * 90, ay), (x + sx * (aw * .5), ay - 150 + k * 30), (tip, ay - 60 + k * 30), (x + sx * aw * .8, ay - 10 + k * 20),
                          (x + sx * aw * .62, ay + 22 + k * 20), (x + sx * aw * .45, ay + 10 + k * 20), (x + sx * 100, ay + 60)])
            s.append([(x + sx * 30, 142), (x + sx * 64, 92), (x + sx * 48, 148)])
        occhi = [[(x - 28, 176), (x - 10, 182), (x - 24, 188)], [(x + 28, 176), (x + 10, 182), (x + 24, 188)]]
        return s, occhi

    sag, occhi = [], []
    for x in (640, 640 + T / 2):
        s_, o = lucifero(x)
        sag += s_
        occhi += o
    lago = '<rect x="0" y="560" width="%d" height="200" fill="%s" opacity=".18"/>' % (T, L) + "".join(
        '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="1.5" opacity="%.2f"/>' % (x, y, x + rng.uniform(-80, 80), y + rng.uniform(10, 40), L, rng.uniform(.2, .5))
        for x, y in [(rng.uniform(0, T), rng.uniform(570, 690)) for _ in range(60)])
    ombre = [[(x - 10, y), (x - 6, y - 16), (x, y - 20), (x + 6, y - 16), (x + 10, y)] for x, y in [(rng.uniform(0, T), rng.uniform(600, 680)) for _ in range(24)]]
    riflessi = "".join(poly([(x, 660), (x + w * .5, 660 - h), (x + w * .55, 660 - h + 20), (x + w * .2, 660)], L, .22)
                       for x, w, h in [(rng.uniform(0, T), rng.uniform(30, 50), rng.uniform(120, 260)) for _ in range(10)])
    return dict(luce=(640, 260, 520, L, .35), nebbie=[(440, 160, L, .14), (560, 150, P["foschia"], .3)], piani=[
        (.03, stelle(rng, 50, "#e6f6ff"), "", ""),
        (.06, poligoni(creste(rng, 500, 90, 180), c(.36)), alone(640, 230, 420, L, .3) + alone(640 + T / 2, 230, 420, L, .3), ""),
        (.1, poligoni(sag, c(.1)), accese(occhi, "#9fe4ff", .95) + "".join(alone(p[1][0], p[1][1], 30, "#9fe4ff", .5) for p in occhi), ""),
        (.18, poligoni(cristalli(rng, 560, 10, (80, 220)), c(.28)), "", ""),
        (.32, poligoni(cristalli(rng, 700, 8, (160, 340)), c(.16)), riflessi + lago, "".join(poly(p, c(.08), .6) for p in ombre)),
        (.7, buio(560, "#03060c", .9), "", ""),
    ])


SCENE = dict(limbo=limbo, lussuria=lussuria, gola=gola, avarizia=avarizia, ira=ira, eresia=eresia,
             violenza=violenza, frode=frode, tradimento=tradimento)
VERSO = dict(limbo=-1, lussuria=1, gola=-1, avarizia=1, ira=-1, eresia=1, violenza=-1, frode=1, tradimento=-1)


def sfondo(nome, P, seme=5):
    """I gruppi dello shader per lo sfondo del girone nome, nella tinta P (temi.py)."""
    rng = random.Random(seme * 97 + len(nome))
    LATO[0] = VERSO[nome]
    sc = SCENE[nome](P, rng)
    gruppi = {n: ([], []) for n, _, _ in GRUPPI}
    for y, h, col, op in sc["nebbie"]:
        gruppi["lontano"][0].append(nebbia_giro(y, h, col, op))
    for vel, s, acc, sopra in sc["piani"]:
        for n, a, b in GRUPPI:
            if a <= vel < b:
                gruppi[n][0].append(sfuma_sagome(colora(s, "sfondo", P), P) + acc + colora(sopra, "sfondo", P))
                gruppi[n][1].append(vel)
    return dict(luce=sc["luce"], gruppi=[(n, "".join(gruppi[n][0]), sum(gruppi[n][1]) / max(1, len(gruppi[n][1]))) for n, _, _ in GRUPPI])
