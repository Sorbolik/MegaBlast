# Seconda versione delle scene: sfondi a 7-8 piani che scorrono sempre nella stessa
# direzione (ogni piano alla sua velocità, a giro continuo senza stacchi) e mappe
# più ricche: tante piattaforme di forme diverse, a più altezze.
import math, random
from scena import (W, H, mix, pts, poly, Id, cielo, bagliore, nebbia, particelle, acqua,
                   trave, diavoletto, motivo, svg)

T = 2560          # larghezza di un giro di sfondo: si ripete identico
PASSO = 60        # pixel al secondo di un piano con velocità 1 (il piano di gioco)
ROSSO, BLU, FAVILLA = "#e0412b", "#3d7bff", "#ffb03a"
SCALA = .72       # la mappa intera in una finestra: personaggi un po' più piccoli


# ---------------------------------------------------------------- sagome periodiche
def avvolgi(polys):
    """Ripete a sinistra le sagome che escono dal giro, così il giro si chiude senza stacchi."""
    out = []
    for p in polys:
        out.append(p)
        if max(x for x, _ in p) > T:
            out.append([(x - T, y) for x, y in p])
    return out


def creste(rng, y0, amp, passo, piatte=False):
    """Montagne a spigoli che finiscono alla stessa altezza da cui partono."""
    n = max(4, int(T / passo))
    xs = sorted(rng.uniform(0, T) for _ in range(n - 1))
    p = [(0, H + 40), (0, y0)]
    for x in xs:
        y = y0 - rng.uniform(0, amp)
        if piatte:
            p += [(x - passo * .25, y), (x + passo * .25, y)]
        else:
            p.append((x, y))
    p += [(T, y0), (T, H + 40)]
    return [p]


def torri(rng, y0, n, w=(30, 70), h=(60, 200), punta=True):
    s = []
    for _ in range(n):
        x, ww, hh = rng.uniform(0, T), rng.uniform(*w), rng.uniform(*h)
        top = [(x, y0 - hh), (x + ww / 2, y0 - hh - ww * .9), (x + ww, y0 - hh)] if punta else [(x, y0 - hh), (x + ww, y0 - hh)]
        s.append([(x, H + 40)] + top + [(x + ww, H + 40)])
    return avvolgi(s)


def mura(rng, y0, alto, merlo=18):
    p = [(0, H + 40), (0, y0 - alto)]
    x = 0
    while x < T:
        p += [(x, y0 - alto), (x, y0 - alto - merlo), (x + merlo, y0 - alto - merlo), (x + merlo, y0 - alto)]
        x += merlo * 2
    p += [(T, y0 - alto), (T, H + 40)]
    return [p]


def archi(rng, y0, n, w=(220, 320), h=(200, 320)):
    s = []
    for i in range(n):
        x = i * T / n + rng.uniform(-30, 30)
        ww, hh = rng.uniform(*w), rng.uniform(*h)
        p = ww * .2
        s.append([(x, H + 40), (x, y0 - hh), (x + ww, y0 - hh), (x + ww, H + 40), (x + ww - p, H + 40),
                  (x + ww - p, y0 - hh + ww * .45), (x + ww - p - ww * .15, y0 - hh + ww * .3),
                  (x + p + ww * .15, y0 - hh + ww * .3), (x + p, y0 - hh + ww * .45), (x + p, H + 40)])
    return avvolgi(s)


def colonne(rng, y0, n, h=(60, 180)):
    s = []
    for _ in range(n):
        x, hh, w = rng.uniform(0, T), rng.uniform(*h), rng.uniform(18, 30)
        s.append([(x, H + 40), (x, y0 - hh), (x + w * .4, y0 - hh + 8), (x + w * .7, y0 - hh - 6), (x + w, y0 - hh + 4), (x + w, H + 40)])
    return avvolgi(s)


def stalattiti(rng, n, lung=(40, 180), larg=(20, 60), y0=0):
    s = []
    for _ in range(n):
        x, l, w = rng.uniform(0, T), rng.uniform(*lung), rng.uniform(*larg)
        s.append([(x, y0 - 10), (x + w, y0 - 10), (x + w * .55, y0 + l)])
    s.append([(0, -20), (T, -20), (T, y0), (0, y0)])
    return avvolgi(s)


def catene(rng, n, col):
    """Catene appese dall'alto: anelli a rombo. Restituisce svg, non poligoni."""
    out = ""
    for _ in range(n):
        x = rng.uniform(0, T)
        l = rng.uniform(120, 380)
        y = -10
        while y < l:
            out += poly([(x, y), (x + 6, y + 9), (x, y + 18), (x - 6, y + 9)], "none", 1, 'stroke="%s" stroke-width="3"' % col)
            y += 16
        out += poly([(x - 10, l), (x + 10, l), (x + 4, l + 22), (x - 4, l + 22)], col)
        if x > T - 20:
            pass
    return out


def tombe(rng, y0, n):
    s = []
    for _ in range(n):
        x = rng.uniform(0, T)
        s.append([(x, H + 40), (x, y0), (x + 8, y0 - 8), (x + 56, y0 - 8), (x + 64, y0), (x + 64, H + 40)])
    return avvolgi(s)


def alberi(rng, y0, n, col, sp=10):
    out = ""
    for _ in range(n):
        x, h = rng.uniform(0, T - 60), rng.uniform(140, 300)
        out += '<polyline points="%s" fill="none" stroke="%s" stroke-width="%d" stroke-linejoin="miter"/>' % (
            pts([(x, H + 40), (x, y0 - h), (x + 40, y0 - h - 40)]), col, sp)
        out += '<polyline points="%s" fill="none" stroke="%s" stroke-width="%d"/>' % (pts([(x, y0 - h * .55), (x - 46, y0 - h * .55 - 46)]), col, sp * .6)
        out += '<polyline points="%s" fill="none" stroke="%s" stroke-width="%d"/>' % (pts([(x, y0 - h * .8), (x + 30, y0 - h * .8 - 30)]), col, sp * .5)
    return out


def giganti(rng, y0, n):
    s = []
    for i in range(n):
        x = i * T / n + rng.uniform(0, 200)
        s.append([(x, H + 40), (x, y0 - 260), (x + 30, y0 - 310), (x + 50, y0 - 310), (x + 50, y0 - 360), (x + 110, y0 - 360),
                  (x + 110, y0 - 310), (x + 130, y0 - 310), (x + 160, y0 - 260), (x + 160, H + 40)])
    return avvolgi(s)


def cristalli(rng, y0, n, h=(60, 220)):
    s = []
    for _ in range(n):
        x, hh, w = rng.uniform(0, T), rng.uniform(*h), rng.uniform(26, 50)
        s.append([(x, H + 40), (x, y0 - hh * .6), (x + w * .5, y0 - hh), (x + w, y0 - hh * .6), (x + w, H + 40)])
    return avvolgi(s)


def mucchi(rng, y0, n, w=(160, 320)):
    s = []
    for _ in range(n):
        x, ww = rng.uniform(0, T), rng.uniform(*w)
        s.append([(x, H + 40), (x, y0), (x + ww / 2, y0 - ww / 2), (x + ww, y0), (x + ww, H + 40)])
    return avvolgi(s)


def canne(rng, y0, n):
    s = []
    for _ in range(n):
        x, h = rng.uniform(0, T), rng.uniform(40, 140)
        s.append([(x, H + 40), (x + 3, y0 - h), (x + 7, H + 40)])
    return avvolgi(s)


def camini(rng, y0, n):
    s = []
    for _ in range(n):
        x, w, h = rng.uniform(0, T), rng.uniform(34, 60), rng.uniform(160, 320)
        s.append([(x, H + 40), (x, y0 - h), (x - 8, y0 - h), (x - 8, y0 - h - 16), (x + w + 8, y0 - h - 16), (x + w + 8, y0 - h), (x + w, y0 - h), (x + w, H + 40)])
    return avvolgi(s)


def scogli(rng, n, y=(120, 420), w=(60, 160)):
    """Rocce sospese a mezz'aria (sfondo della Lussuria, del Paradiso)."""
    s = []
    for _ in range(n):
        x, yy, ww = rng.uniform(0, T), rng.uniform(*y), rng.uniform(*w)
        s.append([(x, yy), (x + ww, yy), (x + ww * .8, yy + ww * .3), (x + ww * .5, yy + ww * .55), (x + ww * .2, yy + ww * .3)])
    return avvolgi(s)


def nubi(rng, n, col, op, y=(80, 340), anima="vola"):
    return "".join('<rect class="%s" style="animation-duration:%ds" x="%d" y="%d" width="%d" height="%d" rx="%d" fill="%s" opacity="%.2f"/>'
                   % (anima, rng.randint(10, 22), rng.uniform(0, T - 200), rng.uniform(*y), rng.uniform(140, 320), h, h // 2, col, op)
                   for h in [rng.choice([8, 12, 18]) for _ in range(n)])


def stelle(rng, n, col):
    return "".join('<rect x="%.0f" y="%.0f" width="%.1f" height="%.1f" fill="%s" opacity="%.2f" transform="rotate(45 %.0f %.0f)"/>'
                   % (x, y, r, r, col, rng.uniform(.3, .9), x, y)
                   for x, y, r in [(rng.uniform(0, T), rng.uniform(0, 420), rng.uniform(1.5, 3.5)) for _ in range(n)])


def scie(rng, n, col):
    return "".join('<path d="M%d,%d q90,-40 180,0 t180,0 t180,0" stroke="%s" stroke-width="%d" fill="none" opacity="%.2f"/>'
                   % (rng.uniform(0, T - 540), rng.uniform(60, 460), col, rng.choice([3, 5, 8]), rng.uniform(.15, .45)) for _ in range(n))


LATO = [1]   # da che parte arriva la luce nel girone che si sta disegnando (-1 sinistra)


def poligoni(ps, col, op=1):
    from volume import poligoni3d
    return poligoni3d(ps, col, LATO[0], op)


# ---------------------------------------------------------------- piano che scorre
def piano_scorre(contenuto, vel, verso, anima=True):
    """Due giri uno accanto all'altro; la CSS li fa scorrere di un giro e ricomincia."""
    doppio = '%s<g transform="translate(%d,0)">%s</g>' % (contenuto, T, contenuto)
    if not anima or vel <= 0:
        return "<g>%s</g>" % doppio
    dur = T / (PASSO * vel)
    cls = "scorre-sx" if verso < 0 else "scorre-dx"
    return '<g class="%s" style="animation-duration:%.1fs">%s</g>' % (cls, dur, doppio)


# ---------------------------------------------------------------- piattaforme
def blocco(x, y, w, h, c=None):
    c = min(h * .6, w / 4) if c is None else c
    return [(x, y), (x + w, y), (x + w, y + h - c), (x + w - c, y + h), (x + c, y + h), (x, y + h - c)]


def pendio(x, y, w, salita, h, lato="dx"):
    """Piano con una rampa a 45 gradi: sale di 'salita' verso destra (o sinistra)."""
    s = salita
    if lato == "dx":
        top = [(x, y), (x + w * .4, y), (x + w * .4 + s, y - s), (x + w, y - s)]
    else:
        top = [(x, y - s), (x + w * .6 - s, y - s), (x + w * .6, y), (x + w, y)]
    yb = y + h
    c = min(h * .6, w / 5)
    return top + [(x + w, yb - c), (x + w - c, yb), (x + c, yb), (x, yb - c)]


def gradini(x, y, n, sw, sh, h, verso=1):
    """Scalinata di n gradini: sale verso destra (verso=1) o sinistra (-1)."""
    top = []
    if verso > 0:
        for i in range(n):
            top += [(x + i * sw, y - i * sh), (x + (i + 1) * sw, y - i * sh)]
        top = [top[0]] + [p for j, p in enumerate(top[1:], 1)]
        pts_ = []
        for i in range(n):
            pts_ += [(x + i * sw, y - i * sh), (x + (i + 1) * sw, y - i * sh)]
            if i < n - 1:
                pts_.append((x + (i + 1) * sw, y - (i + 1) * sh))
        w = n * sw
        yb = y + h
        return pts_ + [(x + w, yb - 30), (x + w - 30, yb), (x + 30, yb), (x, yb - 30)]
    pts_ = []
    for i in range(n):
        yy = y - (n - 1 - i) * sh
        pts_ += [(x + i * sw, yy), (x + (i + 1) * sw, yy)]
        if i < n - 1:
            pts_.append((x + (i + 1) * sw, yy + sh))
    w = n * sw
    yb = y + h
    return pts_ + [(x + w, yb - 30), (x + w - 30, yb), (x + 30, yb), (x, yb - 30)]


def fungo(x, y, w, t, h, s):
    """Una lastra larga in cima a un gambo stretto: si passa sotto."""
    cx = x + w / 2
    return [(x, y), (x + w, y), (x + w, y + t), (cx + s, y + t), (cx + s, y + h), (cx - s, y + h), (cx - s, y + t), (x, y + t)]


def arco(x, y, w, h, t, p):
    """Un ponte con l'arco sotto: si passa in mezzo."""
    c = p * .8
    return [(x, y), (x + w, y), (x + w, y + h), (x + w - p, y + h), (x + w - p, y + t + c), (x + w - p - c, y + t),
            (x + p + c, y + t), (x + p, y + t + c), (x + p, y + h), (x, y + h)]


def scheggia(x, y, w, h):
    """Isolotto piccolo con il fondo a punta."""
    return [(x, y), (x + w, y), (x + w - h * .5, y + h * .5), (x + w * .5, y + h), (x + h * .5, y + h * .5)]


def mensola(x, y, w, alto, sporge, verso=1):
    """Un muro alto con una sporgenza in cima che fa ombra."""
    if verso > 0:
        return [(x, y), (x + w + sporge, y), (x + w + sporge, y + 24), (x + w, y + 40), (x + w, y + alto), (x, y + alto)]
    return [(x - sporge, y), (x + w, y), (x + w, y + alto), (x, y + alto), (x, y + 40), (x - sporge, y + 24)]


def specchia(ps):
    return [list(reversed([(W - x, y) for x, y in p])) for p in ps]


def disegna(ps, m):
    """Poligoni in senso orario (y in giù): la crosta va sui lati che corrono verso destra."""
    out = []
    pat, grad = Id.new("pat"), Id.new("ombra")
    out.append("<defs>%s<linearGradient id='%s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#000' stop-opacity='0'/>"
               "<stop offset='1' stop-color='#000' stop-opacity='.5'/></linearGradient></defs>" % (motivo(pat, m), grad))
    cr = m.get("crosta_h", 10)
    for p in ps:
        out.append(poly(p, m["corpo"]))
        out.append(poly(p, "url(#%s)" % pat))
        out.append(poly(p, "url(#%s)" % grad))
        n = len(p)
        for i in range(n):
            (ax, ay), (bx, by) = p[i], p[(i + 1) % n]
            if bx - ax > .5:
                out.append(poly([(ax, ay), (bx, by), (bx, by + cr), (ax, ay + cr)], m["crosta"]))
                out.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="3"/>' % (ax, ay, bx, by, m["luce"]))
        out.append(poly(p, "none", 1, 'stroke="%s" stroke-width="%s" stroke-linejoin="miter"' % (m["bordo"], m.get("bordo_w", 4))))
    return "".join(out)


def appoggio(ps, x, y_vicino):
    """L'altezza della superficie calpestabile sotto x più vicina a y_vicino."""
    best = None
    for p in ps:
        n = len(p)
        for i in range(n):
            (ax, ay), (bx, by) = p[i], p[(i + 1) % n]
            if bx - ax > .5 and ax <= x <= bx:
                y = ay + (by - ay) * (x - ax) / (bx - ax)
                if best is None or abs(y - y_vicino) < abs(best - y_vicino):
                    best = y
    return best if best is not None else y_vicino


def mat(corpo, crosta, luce, bordo, acciaio, acciaio_luce, motivo="pietra", segni="#000", segni_op=.22, **k):
    d = dict(corpo=corpo, crosta=crosta, luce=luce, bordo=bordo, acciaio=acciaio, acciaio_luce=acciaio_luce,
             motivo=motivo, segni=segni, segni_op=segni_op)
    d.update(k)
    return d


# ---------------------------------------------------------------- la scena
SFOCA = "".join("<filter id='sfoca%d' x='-5%%' y='-5%%' width='110%%' height='110%%'><feGaussianBlur stdDeviation='%d'/></filter>" % (i, 7 - 2 * i) for i in (1, 2, 3))


def strati(g, anima=True, sfondo="sagome", piattaforme="contorno"):
    """[(nome, svg, velocità)] dal cielo al primo piano."""
    rng = random.Random(g["seme"])
    LATO[0] = -1 if (g.get("luce") or (640,))[0] < 640 else 1
    out = [("cielo", cielo(*g["cielo"]) + (bagliore(*g["luce"]) if g.get("luce") else ""), 0)]
    for nome, fare, vel in g["piani"]:
        contenuto = fare(rng)
        if nome == "nebbia":
            out.append(("nebbia", contenuto, 0))
            continue
        if sfondo == "tratto":
            import re
            contenuto = re.sub(r'<polygon points="([^"]*)" fill="(#[0-9a-f]{6})" opacity="([0-9.]*)"',
                               lambda m: '<polygon points="%s" fill="%s" stroke="%s" stroke-width="2.5" opacity="%s"' % (
                                   m.group(1), g["cielo"][1], mix(g["cielo"][1], "#ffffff", .35), m.group(3)), contenuto)
        if sfondo == "sfocato":
            contenuto = '<g filter="url(#sfoca%d)">%s</g>' % (min(3, int(vel * 4) + 1), contenuto)
        out.append((nome, piano_scorre(contenuto, vel, g["verso"], anima), vel))
    m = dict(g["mat"])
    if piattaforme == "morbido":
        m["bordo_w"] = 0
        m["segni_op"] = m["segni_op"] * .5
    gioco = g["sotto"](rng) if g.get("sotto") else ""
    from volume import solido, forma, trave3d
    isole = forma(g["isole"], g.get("stile"))
    gioco += solido(isole, m, g, random.Random(g["seme"] + 1), bordo=(piattaforme != "morbido"))
    gioco += "".join(trave3d(*t, m, g) + trave(*t, m) for t in g.get("travi", []))
    gioco += g["sopra"](rng) if g.get("sopra") else ""
    gioco += "".join(diavoletto(x, appoggio(isole, x, y), c, SCALA) for x, y, c in g.get("diavoli", []))
    out.append(("gioco", gioco, 1))
    if g.get("particelle"):
        tipo, n, col = g["particelle"]
        out.append(("particelle", particelle(rng, n, tipo, col), 1.2))
    return out


def scena(g, anima=True, **k):
    return svg("<defs>%s</defs>" % SFOCA + "".join(x for _, x, _ in strati(g, anima, **k)))
