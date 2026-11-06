# Il cortile della Forgia, dove l'apprendista si allena con Favilla (Sergio, 6 nov 2026, le
# proposte consigliate della pagina https://claude.ai/artifact/AFGXCuDsQt2mXpXd5zi19w):
#   - lo sfondo «cortile»: il muro del portone, con la tinta e la luce della Forgia;
#   - le lezioni del cortile dipinte sulla loro forma (rettangoli d'acciaio, non cambiano);
#   - la mappa «cortile» del Duello con Favilla: l'incudine appesa.
# Lo usa mappe_dipinte.py, che scrive le immagini: qui solo i disegni (SVG nella scena 1280 x 720).
import math, random
from PIL import ImageDraw
from mondo import T, creste, torri, camini, nubi, poligoni, blocco, mat, LATO
from scena import W, H, mix, poly, nebbia, Id, trave
from dipinto import colora, sfuma_sagome, grade, GRUPPI
from volume import solido
from tavole import FORGIA, tinta
from temi import TEMI

P = TEMI["forgia"]                       # la stessa tinta della Forgia: il cortile ne è una parte
c = tinta("#1a0b08", "#b0542c")


# ---------------------------------------------------------------- le sagome dello sfondo
def arco_pieno(x, y, w, h):
    """Apertura ad arco a tutto sesto: x, y in basso a sinistra."""
    r = w / 2
    p = [(x, y), (x, y - h + r)]
    for i in range(1, 12):
        a = math.pi - math.pi * i / 12
        p.append((x + r + r * math.cos(a), y - h + r - r * math.sin(a)))
    return p + [(x + w, y - h + r), (x + w, y)]


def stendardo(x, y, w, h):
    return [(x, y), (x + w, y), (x + w, y + h), (x + w / 2, y + h - w * .45), (x, y + h)]


def incudine(x, y, k=1.0):
    """Un'incudine appoggiata a y, centrata in x."""
    return [(x - 70 * k, y - 62 * k), (x + 46 * k, y - 62 * k), (x + 56 * k, y - 50 * k), (x + 22 * k, y - 46 * k),
            (x + 14 * k, y - 22 * k), (x + 34 * k, y - 10 * k), (x + 34 * k, y), (x - 34 * k, y), (x - 34 * k, y - 10 * k),
            (x - 14 * k, y - 22 * k), (x - 22 * k, y - 46 * k), (x - 40 * k, y - 50 * k)]


def braciere(x, y, alto):
    """Palo con la coppa (sagome) e la sua fiamma."""
    s = [[(x - 5, y), (x - 5, y - alto), (x - 24, y - alto - 4), (x - 18, y - alto - 20), (x + 18, y - alto - 20),
          (x + 24, y - alto - 4), (x + 5, y - alto), (x + 5, y)],
         [(x - 16, y), (x + 16, y), (x + 8, y - 10), (x - 8, y - 10)]]
    f = [(x - 16, y - alto - 20), (x - 10, y - alto - 44), (x - 4, y - alto - 34), (x + 2, y - alto - 58),
         (x + 8, y - alto - 36), (x + 13, y - alto - 46), (x + 16, y - alto - 20)]
    return s, f


def rastrelliera(x, y):
    s = [[(x, y), (x, y - 70), (x + 6, y - 70), (x + 6, y)], [(x + 80, y), (x + 80, y - 70), (x + 86, y - 70), (x + 86, y)],
         [(x - 4, y - 60), (x + 90, y - 60), (x + 90, y - 54), (x - 4, y - 54)]]
    for i in range(5):
        xx, d = x + 12 + i * 15, (i % 2) * 10
        s.append([(xx, y - 4), (xx, y - 92 - d), (xx + 3, y - 100 - d), (xx + 6, y - 92 - d), (xx + 6, y - 4)])
    return s


def corna(gx, hy):
    """Il teschio con le corna sopra il portone (come nelle tavole): sagome e occhi."""
    sag = []
    for sx in (-1, 1):
        fuori = []
        for i in range(9):
            t = i / 8
            a = math.radians(200 - 130 * t) if sx < 0 else math.radians(-20 + 130 * t)
            r = 46 + 20 * t
            fuori.append((gx + sx * 30 + math.cos(a) * r, hy - 30 - math.sin(a) * r * .9))
        dentro = [(gx + sx * 30 + (x - gx - sx * 30) * (.72 + .28 * i / 8), hy - 30 + (y - hy + 30) * (.72 + .28 * i / 8))
                  for i, (x, y) in enumerate(fuori)]
        sag.append(fuori + list(reversed(dentro)))
    sag.append([(gx - 34, hy - 52), (gx + 34, hy - 52), (gx + 40, hy - 20), (gx + 22, hy + 6), (gx + 14, hy + 30),
                (gx - 14, hy + 30), (gx - 22, hy + 6), (gx - 40, hy - 20)])
    occhi = [[(gx - 22, hy - 26), (gx - 6, hy - 22), (gx - 10, hy - 10), (gx - 24, hy - 14)],
             [(gx + 22, hy - 26), (gx + 6, hy - 22), (gx + 10, hy - 10), (gx + 24, hy - 14)]]
    return sag, occhi


def muro(y_cima, y_base, portoni=2, L=T, fondo=H + 40):
    """Il muro del cortile in un giro: merli, due ordini di arcate, il ballatoio con la
    balaustra, i portoni con la grata, le torrette coi bracieri, il teschio e gli stendardi.
    L: quanto è largo (il giro, prima della scala); fondo: dove finisce in basso.
    -> sagome, aperture accese, fiamme, parti scure davanti (grata, occhi), stendardi"""
    sag, aperture, fiamme, scuro, stendardi = [], [], [], [], []
    p = [(0, fondo), (0, y_cima)]
    for x in range(0, int(L) + 44, 44):
        p += [(x, y_cima), (x, y_cima - 16), (x + 22, y_cima - 16), (x + 22, y_cima)]
    sag.append(p + [(L, y_cima), (L, fondo)])
    passo = L / portoni
    for k in range(portoni):
        gx = k * passo + passo * .5
        for j in (-3, -2, -1, 1, 2, 3):
            ax = gx + j * 150 - 45
            aperture.append(arco_pieno(ax, y_base, 90, 150))
            aperture.append(arco_pieno(ax + 20, y_cima + 110, 50, 70))
        # il ballatoio sopra le arcate grandi, con la balaustra
        sag.append([(gx - 560, y_base - 176), (gx + 560, y_base - 176), (gx + 560, y_base - 164), (gx - 560, y_base - 164)])
        for j in range(-36, 37):
            xx = gx + j * 15
            if abs(xx - gx) > 150:
                sag.append([(xx, y_base - 176), (xx, y_base - 200), (xx + 4, y_base - 200), (xx + 4, y_base - 176)])
        sag.append([(gx - 560, y_base - 203), (gx + 560, y_base - 203), (gx + 560, y_base - 198), (gx - 560, y_base - 198)])
        # la torre del portone e le due torrette coi bracieri accesi e gli stendardi
        sag.append([(gx - 150, fondo), (gx - 150, y_cima - 110), (gx + 150, y_cima - 110), (gx + 150, fondo)])
        for sx in (-1, 1):
            tx = gx + sx * 160 - 40
            sag.append([(tx, fondo), (tx, y_cima - 150), (tx - 8, y_cima - 150), (tx - 8, y_cima - 170), (tx + 88, y_cima - 170),
                        (tx + 88, y_cima - 150), (tx + 80, y_cima - 150), (tx + 80, fondo)])
            s, f = braciere(tx + 40, y_cima - 170, 6)
            sag += s
            fiamme.append(f)
            stendardi.append(stendardo(tx + 18, y_cima - 120, 44, 150))
        s, o = corna(gx, y_cima - 110)
        sag += s
        scuro += o
        # il portone: la luce della Forgia dietro la grata
        aperture.append(arco_pieno(gx - 95, y_base, 190, 300))
        for i in range(8):
            xx = gx - 85 + i * 24
            scuro.append([(xx, y_base), (xx, y_base - 290), (xx + 6, y_base - 290), (xx + 6, y_base)])
            scuro.append([(xx - 2, y_base), (xx + 3, y_base + 10), (xx + 8, y_base)])
        for j in range(5):
            yy = y_base - 40 - j * 52
            scuro.append([(gx - 95, yy), (gx + 95, yy), (gx + 95, yy + 6), (gx - 95, yy + 6)])
        for j in (-2, 2):
            stendardi.append(stendardo(gx + j * 150 + 52, y_cima + 18, 40, 120))
    return sag, aperture, fiamme, scuro, stendardi


def emblemi(stendardi):
    """L'incudine sugli stendardi."""
    s = []
    for p in stendardi:
        x, y = p[0]
        cx, cy = x + (p[1][0] - x) / 2, y + 52
        s.append([(cx - 13, cy - 8), (cx + 9, cy - 8), (cx + 12, cy - 5), (cx + 4, cy - 4), (cx + 3, cy + 2), (cx + 7, cy + 6),
                  (cx - 7, cy + 6), (cx - 3, cy + 2), (cx - 4, cy - 4), (cx - 8, cy - 5)])
    return s


def attrezzi(rng, y0):
    """Il primo piano in controluce: incudini sui ceppi, bracieri spenti, rastrelliere, muretti.
    Spenti: una fiamma accesa così in basso sembrava fuoco sul terreno (un pericolo)."""
    sag, x, i = [], 40, 0
    while x < T - 120:
        k = i % 4
        if k == 0:
            sag.append([(x - 60, H + 40), (x - 60, y0 - 30), (x + 60, y0 - 30), (x + 60, H + 40)])
            sag.append(incudine(x, y0 - 30, 1.1))
        elif k == 1:
            sag += braciere(x, y0, 150)[0]
        elif k == 2:
            sag += rastrelliera(x - 40, y0)
        else:
            sag.append([(x - 90, H + 40), (x - 90, y0 - 20), (x + 90, y0 - 20), (x + 90, H + 40)])
            sag += braciere(x + 50, y0 - 20, 30)[0]
        x += rng.uniform(260, 420)
        i += 1
    return sag + [[(0, H + 40), (0, y0), (T, y0), (T, H + 40)]]


# il muro dello sfondo in scala, e dove poggia; il cortile basso sotto, coi suoi attrezzi
K_MURO, BASE, Y_ATTREZZI = .72, 470, 700


# il portone non al centro del quadro ma un po' a sinistra: al centro, dietro la lava
# delle lezioni, era triste (Sergio, 6 nov)
SPOSTA = -320


def sposta(svg):
    """Il disegno spostato di lato, ripetuto un giro più in là perché il giro resti pieno."""
    return "".join('<g transform="translate(%g,0)">%s</g>' % (dx, svg) for dx in (SPOSTA, SPOSTA + T))


def cortile_basso():
    """Il selciato del cortile basso, dalla base del muro fino sotto il quadro."""
    return [[(0, BASE - 2), (T, BASE - 2), (T, H + 40), (0, H + 40)]]


def fughe():
    """Le file del selciato, più fitte in alto (lontano) e più rade in basso, e il buio che sale
    dal fondo: sotto il quadro lo shader continua l'ultima riga, che così è tutta uguale."""
    s, y, k = "", BASE + 6, 7
    while y < H - 20:
        s += '<rect x="0" y="%g" width="%g" height="%g" fill="%s" opacity=".8"/>' % (y, T, 1 + k / 10, c(.12))
        y += k
        k *= 1.35
    # le giunte che scappano verso il portone (il punto di fuga sta in alto, dietro il muro)
    for gx in (T / 4, T * 3 / 4):
        for i in range(-16, 17):
            x0 = gx + i * 40
            s += '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="1.6" opacity=".6"/>' % (
                x0, BASE, gx + i * 40 * 4.2, H + 40, c(.12))
    gid = Id.new("buio")
    s += ("<defs><linearGradient id='%s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='%s' stop-opacity='0'/>"
          "<stop offset='1' stop-color='%s' stop-opacity='.95'/></linearGradient></defs>"
          '<rect x="0" y="%g" width="%g" height="%g" fill="url(#%s)"/><rect x="0" y="%g" width="%g" height="60" fill="%s" opacity=".95"/>'
          % (gid, c(.08), c(.08), BASE + 20, T, H - BASE - 20, gid, H, T, c(.08)))
    return colora(s, "sfondo", P)


def riflessi():
    """La luce delle arcate e del portone che cade sul selciato davanti al muro."""
    s, passo = "", T / 2
    for k in range(2):
        gx = k * passo + passo * .5
        for j, w, op in [(0, 150, .35)] + [(j, 70, .16) for j in (-3, -2, -1, 1, 2, 3)]:
            x = gx + j * 150 * K_MURO
            s += poly([(x - w * .4, BASE), (x + w * .4, BASE), (x + w * .75, BASE + 70), (x - w * .75, BASE + 70)], P["luce"], op * .5)
    return s


def luce(polys, op, dal_basso=False):
    """La luce della Forgia (arcate, portone, fiamme): nella tinta della luce, non delle ombre."""
    if not dal_basso:
        return "".join(poly(p, P["luce"], op) for p in polys)
    gid = Id.new("acc")
    return ("<defs><linearGradient id='%s' x1='0' y1='1' x2='0' y2='0'><stop offset='0' stop-color='%s' stop-opacity='%.2f'/>"
            "<stop offset='1' stop-color='%s' stop-opacity='%.2f'/></linearGradient></defs>" % (gid, P["luce"], op, P["luce"], op * .15)
            + "".join(poly(p, "url(#%s)" % gid) for p in polys))


def sfondo():
    """{'luce': la sorgente per il cielo, 'gruppi': [(nome, svg largo un giro, velocità media)]}:
    i piani del cortile messi nei tre gruppi dello shader, già colorati nella tinta della Forgia."""
    rng = random.Random(11)
    LATO[0] = 1
    # il muro più piccolo e più in alto (Sergio, 6 nov: sotto le piattaforme si vedeva la base
    # del muro): sotto c'è il cortile basso, il selciato visto dall'alto che scende nel buio
    sag, aperture, fiamme, scuro, stendardi = muro(300, 640, L=T / K_MURO, fondo=650)
    in_scala = lambda svg: sposta('<g transform="translate(0,%g) scale(%g)">%s</g>' % (BASE - 640 * K_MURO, K_MURO, svg))
    piani = [   # (velocità, sagome da sfumare, luce, parti scure davanti)
        (.04, nubi(rng, 10, "#120806", .35, (40, 200)), "", ""),
        (.08, poligoni(torri(rng, 330, 9, (40, 90), (80, 240)), c(.7)) + poligoni(creste(rng, 330, 60, 160), c(.7)), "", ""),
        (.15, poligoni(camini(rng, 360, 8), c(.58)), "", ""),
        (.25, poligoni(cortile_basso(), c(.24)) + in_scala(poligoni(sag, c(.3)) + "".join(poly(p, c(.42)) for p in stendardi)
                                                         + "".join(poly(p, c(.2)) for p in emblemi(stendardi))),
         in_scala(luce(aperture, .5, True) + luce(fiamme, .85)) + sposta(riflessi()),
         in_scala("".join(poly(p, c(.2)) for p in scuro)) + fughe()),
        (.75, poligoni(attrezzi(rng, Y_ATTREZZI), "#0e0504"), "", ""),
    ]
    gruppi = {n: ([], []) for n, _, _ in GRUPPI}
    # la foschia calda dietro il muro: ferma, va col gruppo lontano (come in dipinto.piani)
    gruppi["lontano"][0].append('<g transform="scale(%g,1)">%s</g>' % (T / W, colora(nebbia(330, 160, "#ff7a1a", .2), "luce", P)))
    for vel, s, acc, sopra in piani:
        for n, a, b in GRUPPI:
            if a <= vel < b:
                gruppi[n][0].append(sfuma_sagome(colora(s, "sfondo", P), P) + acc + colora(sopra, "sfondo", P))
                gruppi[n][1].append(vel)
    return dict(luce=(900, 520, 520, "#ff7a1a", .5),
                gruppi=[(n, "".join(gruppi[n][0]), sum(gruppi[n][1]) / max(1, len(gruppi[n][1]))) for n, _, _ in GRUPPI])


# ---------------------------------------------------------------- i materiali del terreno
M = {k: (grade(v, "materiale", P) if isinstance(v, str) and v.startswith("#") else v)
     for k, v in mat("#4a2a20", "#7a4a2a", "#ffb35a", "#160a07", "#5b5560", "#c9c3cf", "mattoni").items()}
FERRO = dict(M, corpo=mix(M["acciaio"], "#000", .25), crosta=mix(M["acciaio"], M["acciaio_luce"], .35), motivo="venature")
CATENA = mix(M["bordo"], M["acciaio"], .4)


def g_dipinto(**k):
    g = dict(FORGIA, dipinto=True, stile="", luce=(980, 300, 460, P["luce"], .45))
    g.update(k)
    return g


def legno(x, y, w, h):
    """Legno (ballatoi, assi appese): assi in cima, montanti e croci dentro la sagoma."""
    corpo, asse = mix(M["corpo"], "#000", .2), mix(M["crosta"], M["luce"], .15)
    s = ['<rect x="%g" y="%g" width="%g" height="%g" fill="%s"/>' % (x, y, w, h, corpo),
         '<rect x="%g" y="%g" width="%g" height="%g" fill="url(#tratteggio)" mask="url(#basso)"/>' % (x, y, w, h),
         '<rect x="%g" y="%g" width="%g" height="14" fill="%s"/>' % (x, y, w, asse)]
    xx = x
    while xx < x + w:
        s.append('<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="2"/>' % (xx, y, xx, y + 14, M["bordo"]))
        xx += 34
    s.append('<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="3"/>' % (x, y + 1.5, x + w, y + 1.5, M["luce"]))
    n = max(1, round(w / 90))
    for i in range(n + 1):
        px = x + 4 + (w - 18) * i / n
        s.append('<rect x="%g" y="%g" width="10" height="%g" fill="%s"/>' % (px, y + 14, h - 14, mix(asse, "#000", .35)))
        if i < n and h > 40:
            qx = x + 4 + (w - 18) * (i + 1) / n
            for a, b in ((y + 18, y + h - 4), (y + h - 4, y + 18)):
                s.append('<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="6"/>' % (px + 10, a, qx, b, mix(asse, "#000", .45)))
    s.append('<rect x="%g" y="%g" width="%g" height="%g" fill="none" stroke="%s" stroke-width="4"/>' % (x, y, w, h, M["bordo"]))
    return "".join(s)


def selciato(x, y, w, rng):
    """La fila di lastre sulla cima della pietra."""
    s, xx = [], x
    while xx < x + w - 10:
        e = min(xx + rng.uniform(40, 80), x + w)
        s.append('<rect x="%g" y="%g" width="%g" height="12" fill="%s" stroke="%s" stroke-width="2"/>'
                 % (xx + 1, y + 2, e - xx - 2, mix(M["crosta"], M["luce"], rng.uniform(.05, .2)), mix(M["bordo"], M["corpo"], .3)))
        xx = e
    return "".join(s)


def catena(x, y0, y1):
    s, y = "", y0
    while y < y1:
        s += poly([(x, y), (x + 5, y + 8), (x, y + 16), (x - 5, y + 8)], "none", 1, 'stroke="%s" stroke-width="3"' % CATENA)
        y += 14
    return s


def rune(x, y, w, h):
    col = mix(P["luce"], "#cdbcff", .6)
    return "".join('<path d="M%g,%g l8,10 l-8,10 l-8,-10 z M%g,%g v20" stroke="%s" stroke-width="2.5" fill="none" opacity=".7"/>'
                   % (x + 30 + i * 60, y + h / 2 - 10, x + 30 + i * 60, y + h / 2 - 10, col) for i in range(int(w / 60)))


def base(x0, x1):
    """La base sotto il blocco della lezione: una fascia di pietra più scura e un po' più
    larga, col bordo tutt'intorno, che chiude il blocco sul fondo del quadro."""
    return ('<rect x="%g" y="704" width="%g" height="14" fill="%s" stroke="%s" stroke-width="3"/>'
            '<line x1="%g" y1="705.5" x2="%g" y2="705.5" stroke="%s" stroke-width="2"/>'
            % (x0 - 8, x1 - x0 + 16, mix(M["corpo"], "#000", .35), M["bordo"],
               x0 - 6, x1 + 6, mix(M["crosta"], M["luce"], .15)))


def lava(x0, x1):
    """La lava in fondo al burrone: cadere è il pericolo, quindi resta accesa."""
    return ('<defs><linearGradient id="lavac" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffc24a"/>'
            '<stop offset=".18" stop-color="#ff6a1f"/><stop offset="1" stop-color="#b8321a"/></linearGradient>'
            '<radialGradient id="lavacl" cx=".5" cy="1" r=".6"><stop offset="0" stop-color="#ff7a1f" stop-opacity=".55"/>'
            '<stop offset="1" stop-color="#ff7a1f" stop-opacity="0"/></radialGradient></defs>'
            '<rect x="%g" y="560" width="%g" height="200" fill="url(#lavacl)"/>'
            '<rect x="%g" y="690" width="%g" height="40" fill="url(#lavac)"/>' % (x0 - 60, x1 - x0 + 120, x0, x1 - x0))


# ---------------------------------------------------------------- le lezioni del cortile
# che cosa è ogni rettangolo dell'arena (sim/campaign.lua), nell'ordine dell'arena
LEZIONI = {
    "primi_passi": ["selciato", "selciato"],                                  # il pavimento, il gradino
    "lanciarune": ["selciato", "legno"],                                      # il ballatoio
    "turno": ["selciato"],
    "tempo": ["selciato", "appesa"],                                          # l'isola delle rune sulle catene
    "spostano": ["selciato", "pilastro", "pilastro", "legno", "legno"],       # la corsia di Favilla è di legno
    "attrezzi": ["selciato", "legno", "selciato"],                            # le due rive e la piattaforma
}


def lezione(mid, arena):
    """Il terreno di una lezione: arena = [(x, y, w, h)] nel mondo (y in su)."""
    rng = random.Random(5)
    rett = [(x / 1.5, 720 - (y + h) / 1.5, w / 1.5, h / 1.5) for x, y, w, h in arena]
    ruoli = LEZIONI[mid]
    out = ""
    rive = sorted(r for r, ru in zip(rett, ruoli) if ru == "selciato")
    # la lezione è un blocco solo (Sergio, 6 nov: si vede tutto sullo schermo, niente che
    # s'interrompa di netto): fra due rive in fondo la lava sta in una vasca di pietra, e
    # sotto tutto il blocco c'è la base, col suo bordo
    vasche = []
    for a, b in zip(rive, rive[1:]):
        if b[0] - (a[0] + a[2]) > 40 and a[1] + a[3] >= 700 and b[1] + b[3] >= 700:
            # la parete di fondo della vasca, in ombra: il blocco resta pieno anche sopra la lava
            x0, x1, y0 = a[0] + a[2], b[0], max(a[1], b[1])
            out += '<rect x="%g" y="%g" width="%g" height="%g" fill="%s"/>' % (x0 - 1, y0, x1 - x0 + 2, 712 - y0, mix(M["corpo"], "#000", .55))
            out += "".join('<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="2" opacity=".6"/>' % (
                x0, yy, x1, yy, mix(M["bordo"], "#000", .3)) for yy in range(int(y0) + 22, 690, 22))
            out += lava(x0, x1)
            vasche.append((a[0] + a[2] - 1, 706, b[0] - a[0] - a[2] + 2, 14))
    pietra = [blocco(*r, c=0) for r, ru in zip(rett, ruoli) if ru in ("selciato", "pilastro", "appesa")]
    out += solido(pietra + [blocco(*v, c=0) for v in vasche], dict(M), g_dipinto(), rng)
    a_terra = [r for r, ru in zip(rett, ruoli) if ru == "selciato" and r[1] + r[3] >= 700] + vasche
    if a_terra:
        out += base(min(r[0] for r in a_terra), max(r[0] + r[2] for r in a_terra))
    for (x, y, w, h), ru in zip(rett, ruoli):
        if ru == "selciato":
            out += selciato(x, y, w, rng)
        elif ru == "pilastro":
            out += '<rect x="%g" y="%g" width="%g" height="10" fill="%s" stroke="%s" stroke-width="3"/>' % (
                x - 2, y, w + 4, mix(M["crosta"], M["luce"], .3), M["bordo"])
            for k in range(1, int(h / 40)):
                out += '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="5" opacity=".5"/>' % (
                    x + 2, y + k * 40, x + w - 2, y + k * 40, M["bordo"])
        elif ru == "appesa":
            out += rune(x, y, w, h) + catena(x + 14, 0, y) + catena(x + w - 14, 0, y)
        elif ru == "legno":
            out += legno(x, y, w, h)
    return out


# ---------------------------------------------------------------- la mappa del Duello
def assi_appese(*assi, h=22):
    """Assi di legno appese a due catene: [(x, y, w)] -> rettangoli, catene."""
    return [(x, y, w, h) for x, y, w in assi], [q for x, y, w in assi for q in ((x + 12, 0, y), (x + w - 12, 0, y))]


_assi, _catene = assi_appese((250, 410, 110), (920, 410, 110), (380, 230, 100), (800, 230, 100))
# L'incudine appesa: terrazze ai muri con le rampe, il cortile piatto, al centro l'incudine di
# ferro sulle catene (ci si passa sotto: 147 di mondo, il diavoletto è alto 39), ballatoi di
# legno ai muri, assi appese, una trave in cima. Niente buchi: è la prima partita.
CORTILE = dict(
    pietra=[[(0, 300), (50, 300), (50, 500), (230, 500), (290, 560), (990, 560), (1050, 500), (1230, 500), (1230, 300),
             (1280, 300), (1280, 760), (0, 760)]],
    ferro=[[(450, 362), (780, 362), (780, 380), (744, 396), (700, 404), (690, 440), (722, 462), (558, 462), (590, 440),
            (580, 404), (520, 392)]],
    legni=[(50, 330, 130, 24), (1100, 330, 130, 24)] + _assi,
    travi=[(580, 140, 120, 16)],
    catene=[(500, 0, 362), (730, 0, 362), (640, 0, 140)] + _catene,
)


def mappa(L=CORTILE):
    """Il terreno disegnato della mappa del cortile."""
    rng = random.Random(7)
    g = g_dipinto(travi=L["travi"])
    out = solido(L["pietra"], dict(M), g, rng)
    for p in L["pietra"]:
        out += "".join(selciato(a[0], a[1], b[0] - a[0], rng) for a, b in zip(p, p[1:] + p[:1]) if b[0] - a[0] > 20 and a[1] == b[1])
    out += solido(L["ferro"], FERRO, g, rng)
    out += "".join(legno(*r) for r in L["legni"]) + "".join(trave(*t, M) for t in L["travi"])
    return out + "".join(catena(*q) for q in L["catene"])


def maschera(im, L=CORTILE):
    """Disegna la collisione su im (640 x 360): bianco la pietra e il legno, rosso il ferro."""
    d = ImageDraw.Draw(im)
    for p in L["pietra"]:
        d.polygon([(x * .5, y * .5) for x, y in p], fill="white")
    for x, y, w, h in L["legni"]:
        d.rectangle([x * .5, y * .5, (x + w) * .5 - 1, (y + h) * .5 - 1], fill="white")
    for p in L["ferro"]:
        d.polygon([(x * .5, y * .5) for x, y in p], fill="red")
    for x, y, w, h in L["travi"]:
        d.rectangle([x * .5, y * .5, (x + w) * .5 - 1, (y + h) * .5 - 1], fill="red")
