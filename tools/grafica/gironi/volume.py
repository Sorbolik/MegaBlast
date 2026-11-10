# Terza versione: piattaforme con volume vero e forme diverse per ogni girone.
# - Ogni piattaforma è un solido: la faccia davanti è la sagoma su cui si cammina (il bordo
#   davanti è la collisione), dietro c'è uno spessore che fugge verso un punto di fuga.
#   Sotto l'orizzonte si vede la faccia di sopra, sopra l'orizzonte si vede la pancia.
# - Le facce prendono luce dalla sorgente del girone (fuoco, luna, lava...).
# - Ombra portata sullo sfondo, luce di taglio sugli spigoli verso la luce.
# - Ogni girone ha un suo "stile": cambia la sagoma (denti, gradoni, ghiaccioli, spine)
#   e i segni sulla faccia (fasce di ferro, crepe che pulsano, monete, sfaccettature).
import math, random
from scena import mix, pts, poly, Id, motivo


def _nrm(x, y):
    l = math.hypot(x, y) or 1
    return x / l, y / l


# ---------------------------------------------------------------- sagome per stile
def _sotto(p, fare):
    """Sostituisce i lati di sotto (orizzontali, che corrono verso sinistra) con 'fare'."""
    out = []
    n = len(p)
    for i in range(n):
        a, b = p[i], p[(i + 1) % n]
        out.append(a)
        if b[0] - a[0] < -40 and abs(b[1] - a[1]) < .5:
            out += fare(a[0], b[0], a[1])
    return out


def denti(passo, prof, ogni=1):
    """Denti a 45 gradi (stalattiti, ghiaccioli, spine) sotto i lati di sotto."""
    return lambda xa, xb, y: _dentini(xa, xb, y, passo, prof, ogni)


def _dentini(xa, xb, y, passo, prof, ogni):
    l = xa - xb
    k = max(1, int(l // passo))
    w = l / k
    r = []
    for j in range(k):
        x0 = xa - j * w
        if j % ogni:
            continue
        d = min(prof * (1.5 if j % 3 == 1 else (.7 if j % 3 == 2 else 1)), w / 2)
        r += [(x0 - (w / 2 - d), y), (x0 - w / 2, y + d), (x0 - (w / 2 + d), y)]
    return r


def gradoni(passo, alto, volte=2):
    """Mensole a gradini sotto (rovine, sepolcri): si stringe di 'passo' a ogni gradino."""
    def f(xa, xb, y):
        out = []
        for j in range(1, volte + 1):
            if xa - xb - 2 * j * passo < 40:
                break
            out += [(xa - j * passo, y + (j - 1) * alto), (xa - j * passo, y + j * alto)]
        back = [(xa + xb - x, yy) for x, yy in reversed(out)]
        return out + back
    return f


def chiglia(prof):
    """Fondo a carena: una punta larga a 45 gradi al centro (scogli sospesi)."""
    def f(xa, xb, y):
        l = xa - xb
        d = min(prof, l / 2 - 4)
        m = (xa + xb) / 2
        return [(m + d, y), (m, y + d), (m - d, y)] if d > 10 else []
    return f


def forma(isole, stile):
    fz = STILI.get(stile, {}).get("sagoma")
    if not fz:
        return isole
    return [_sotto(p, fz) for p in isole]


# ---------------------------------------------------------------- segni sulla faccia
def _bbox(p):
    xs, ys = [x for x, _ in p], [y for _, y in p]
    return min(xs), min(ys), max(xs), max(ys)


def segni(stile, p, m, rng):
    x0, y0, x1, y1 = _bbox(p)
    t = STILI.get(stile, {}).get("segni")
    s = []
    if t == "fasce":          # Forgia: fasce di ferro chiodate
        y = y0 + 28
        while y < y1 - 10:
            s.append('<rect x="%.0f" y="%.0f" width="%.0f" height="9" fill="#2a2228" opacity=".85"/>' % (x0, y, x1 - x0))
            s.append('<rect x="%.0f" y="%.0f" width="%.0f" height="2" fill="#8a8290" opacity=".7"/>' % (x0, y, x1 - x0))
            xx = x0 + 10
            while xx < x1:
                s.append('<circle cx="%.0f" cy="%.0f" r="2" fill="#b8b0c0"/>' % (xx, y + 4.5))
                xx += 26
            y += 70
    elif t == "muschio":      # Limbo: muschio che cola dal bordo
        for (ax, ay), (bx, by) in _lati_sopra(p):
            xx = ax + rng.uniform(4, 20)
            while xx < bx - 8:
                l = rng.uniform(6, 22)
                yy = ay + (by - ay) * (xx - ax) / (bx - ax)
                s.append(poly([(xx, yy), (xx + 10, yy), (xx + 5, yy + l)], "#7f9a6a", .85))
                xx += rng.uniform(14, 34)
    elif t == "vene":         # Lussuria: vene di cristallo che pulsano
        for _ in range(max(1, int((x1 - x0) / 70))):
            x = rng.uniform(x0 + 10, x1 - 10)
            y = rng.uniform(y0 + 14, y1 - 6)
            q = [(x, y)]
            for _ in range(3):
                x += rng.choice((-1, 1)) * rng.uniform(10, 22)
                y += rng.uniform(6, 16)
                q.append((x, y))
            s.append('<polyline class="pulsa" points="%s" fill="none" stroke="%s" stroke-width="3" opacity=".9"/>' % (pts(q), m["luce"]))
    elif t == "pozze":        # Gola: pozze di fango lucide sulla faccia
        for _ in range(max(1, int((x1 - x0) / 90))):
            x, y = rng.uniform(x0 + 16, x1 - 30), rng.uniform(y0 + 18, y1 - 14)
            w = rng.uniform(14, 34)
            s.append(poly([(x, y), (x + w, y), (x + w - 5, y + 6), (x + 5, y + 6)], "#1a1a10", .6))
            s.append('<line x1="%.0f" y1="%.0f" x2="%.0f" y2="%.0f" stroke="#c8cc98" stroke-width="1.5" opacity=".6"/>' % (x + 3, y + 1, x + w * .5, y + 1))
    elif t == "monete":       # Avarizia: monete incastrate nella roccia
        for _ in range(max(2, int((x1 - x0) * (y1 - y0) / 2600))):
            x, y = rng.uniform(x0 + 8, x1 - 8), rng.uniform(y0 + 16, y1 - 8)
            r = rng.uniform(3.5, 7)
            s.append('<ellipse cx="%.0f" cy="%.0f" rx="%.1f" ry="%.1f" fill="#ffcf5a" stroke="#6e4a12" stroke-width="1.5"/>' % (x, y, r, r * .8))
    elif t == "radici":       # Ira: radici che pendono sotto, nel fango
        pass
    elif t == "crepe":        # Eresia: crepe di brace che pulsano
        for _ in range(max(1, int((x1 - x0) / 80))):
            x, y = rng.uniform(x0 + 10, x1 - 10), y0 + rng.uniform(16, 40)
            q = [(x, y)]
            while y < y1 - 10:
                x += rng.choice((-1, 1)) * rng.uniform(4, 12)
                y += rng.uniform(8, 18)
                q.append((x, y))
            s.append('<polyline class="pulsa" points="%s" fill="none" stroke="%s" stroke-width="2.5"/>' % (pts(q), "#ff8a3a"))
    elif t == "ossa":         # Violenza: ossa e spine nella pietra
        for _ in range(max(1, int((x1 - x0) / 80))):
            x, y = rng.uniform(x0 + 14, x1 - 30), rng.uniform(y0 + 20, y1 - 10)
            a = rng.uniform(-.5, .5)
            dx, dy = 20 * math.cos(a), 20 * math.sin(a)
            s.append('<line x1="%.0f" y1="%.0f" x2="%.0f" y2="%.0f" stroke="#e8dccb" stroke-width="4" stroke-linecap="round" opacity=".55"/>' % (x, y, x + dx, y + dy))
    elif t == "pece":         # Frode: pece nera che cola dal bordo
        for (ax, ay), (bx, by) in _lati_sopra(p):
            xx = ax + rng.uniform(6, 30)
            while xx < bx - 10:
                l = rng.uniform(10, 34)
                yy = ay + (by - ay) * (xx - ax) / (bx - ax)
                s.append(poly([(xx, yy), (xx + 9, yy), (xx + 9, yy + l - 4), (xx + 4.5, yy + l), (xx, yy + l - 4)], "#060606", .9))
                xx += rng.uniform(22, 60)
    elif t == "faccette":     # Tradimento e Paradiso: ghiaccio sfaccettato
        for _ in range(max(2, int((x1 - x0) / 40))):
            x, y = rng.uniform(x0, x1), rng.uniform(y0 + 10, y1)
            w = rng.uniform(18, 40)
            s.append(poly([(x, y), (x + w, y - w * .5), (x + w * .7, y + w * .6)], "#ffffff", rng.uniform(.08, .28)))
    elif t == "erba":         # Purgatorio: ciuffi d'erba che pendono dal bordo
        for (ax, ay), (bx, by) in _lati_sopra(p):
            xx = ax + 4
            while xx < bx - 6:
                yy = ay + (by - ay) * (xx - ax) / (bx - ax)
                s.append(poly([(xx, yy), (xx + 8, yy), (xx + 4, yy + rng.uniform(5, 14))], "#5f8f3f", .9))
                xx += rng.uniform(8, 18)
    return "".join(s)


def _lati_sopra(p):
    n = len(p)
    return [(p[i], p[(i + 1) % n]) for i in range(n) if p[(i + 1) % n][0] - p[i][0] > 12]


def appesi(stile, p, m, rng):
    """Cose sottili che pendono sotto (radici, catene, gocce): non sono terreno."""
    t = STILI.get(stile, {}).get("appesi")
    if not t:
        return ""
    s = []
    n = len(p)
    for i in range(n):
        (ax, ay), (bx, by) = p[i], p[(i + 1) % n]
        if not (ax - bx > 30 and abs(ay - by) < .5):
            continue
        xx = bx + rng.uniform(6, 20)
        while xx < ax - 6:
            if t == "radici":
                l = rng.uniform(18, 60)
                q = [(xx, ay), (xx + rng.uniform(-6, 6), ay + l * .5), (xx + rng.uniform(-10, 10), ay + l)]
                s.append('<polyline points="%s" fill="none" stroke="#1a2a22" stroke-width="%.1f" stroke-linecap="round"/>' % (pts(q), rng.uniform(2, 4)))
            elif t == "gocce":
                l = rng.uniform(8, 24)
                s.append('<line class="pulsa" x1="%.0f" y1="%.0f" x2="%.0f" y2="%.0f" stroke="%s" stroke-width="3" stroke-linecap="round"/>' % (xx, ay, xx, ay + l, m.get("goccia", "#c8463a")))
            elif t == "catenelle":
                l = rng.uniform(16, 40)
                s.append('<line x1="%.0f" y1="%.0f" x2="%.0f" y2="%.0f" stroke="#2a2228" stroke-width="3" stroke-dasharray="5 3"/>' % (xx, ay, xx, ay + l))
            xx += rng.uniform(18, 46)
    return "".join(s)


# ---------------------------------------------------------------- il solido
def solido(isole, m, g, rng, bordo=True):
    """Disegna tutte le piattaforme come solidi illuminati."""
    vp = g.get("fuga", (640, 330))
    k = g.get("profondita", 0)   # 0 = piattaforme piatte (scelta di Sergio 1/11); .075 = con spessore
    lx, ly = (g["luce"][0], g["luce"][1]) if g.get("luce") else (640, -200)
    stile = g.get("stile", "")
    luce_col = g["luce"][3] if g.get("luce") else "#ffffff"
    out = []
    pat, ao, ombra = Id.new("pat"), Id.new("ao"), Id.new("om")
    out.append("<defs>%s<linearGradient id='%s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#000' stop-opacity='0'/>"
               "<stop offset='.55' stop-color='#000' stop-opacity='.15'/><stop offset='1' stop-color='#000' stop-opacity='.6'/></linearGradient>"
               "<filter id='%s' x='-20%%' y='-20%%' width='140%%' height='140%%'><feGaussianBlur stdDeviation='10'/></filter></defs>"
               % (motivo(pat, m), ao, ombra))

    def dietro(q):
        return (q[0] + (vp[0] - q[0]) * k, q[1] + (vp[1] - q[1]) * k)

    # 1. ombra portata sullo sfondo, lontano dalla luce
    ox, oy = _nrm(640 - lx, 360 - ly)
    sh = "".join(poly([(x + ox * 26, y + oy * 26 + 10) for x, y in p], "#000") for p in isole)
    out.append('<g filter="url(#%s)" opacity="%.2f">%s</g>' % (ombra, g.get("ombra", .45), sh))

    # 2. le facce di spessore (tutte prima delle facce davanti)
    facce = []
    for p in (isole if k else []):
        n = len(p)
        for i in range(n):
            a, b = p[i], p[(i + 1) % n]
            dx, dy = b[0] - a[0], b[1] - a[1]
            if abs(dx) + abs(dy) < 1:
                continue
            nx, ny = _nrm(dy, -dx)                 # normale verso fuori
            mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
            fx, fy = vp[0] - mx, vp[1] - my         # verso il punto di fuga
            if nx * fx + ny * fy <= 0:
                continue                            # faccia girata: non si vede
            q = [a, b, dietro(b), dietro(a)]
            vx, vy = _nrm(lx - mx, ly - my)
            lum = max(0, nx * vx + ny * vy)
            if ny < -.5:                            # faccia di sopra: crosta che fugge
                col = mix(mix(m["crosta"], "#000", .25), m["luce"], .25 * lum)
            elif ny > .5:                           # pancia
                col = mix(m["corpo"], "#000", .55)
            else:                                   # fianco
                col = mix(mix(m["corpo"], "#000", .35), luce_col, .22 * lum)
            d = math.hypot(fx, fy)
            facce.append((-d, q, col, ny < -.5))
    facce.sort(key=lambda f: f[0])
    for _, q, col, sopra in facce:
        out.append(poly(q, col, 1, 'stroke="%s" stroke-width="1" stroke-linejoin="round"' % col))
        if sopra:  # righe di profondità sulla crosta
            out.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="2" opacity=".35"/>'
                       % (q[3][0], q[3][1], q[2][0], q[2][1], m["luce"]))
    if bordo:
        for _, q, col, _s in facce:
            out.append('<polyline points="%s" fill="none" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>'
                       % (pts([q[1], q[2], q[3], q[0]]), m["bordo"]))

    # 3. le facce davanti
    for p in isole:
        cid = Id.new("cl")
        x0, y0, x1, y1 = _bbox(p)
        gl = Id.new("gl")
        vx, vy = _nrm(lx - (x0 + x1) / 2, ly - (y0 + y1) / 2)
        out.append("<defs><clipPath id='%s'>%s</clipPath><linearGradient id='%s' x1='%.2f' y1='%.2f' x2='%.2f' y2='%.2f'>"
                   "<stop offset='0' stop-color='%s' stop-opacity='.28'/><stop offset='1' stop-color='#000' stop-opacity='.25'/></linearGradient></defs>"
                   % (cid, poly(p, "#fff"), gl, .5 + vx * .5, .5 + vy * .5, .5 - vx * .5, .5 - vy * .5, luce_col))
        out.append(poly(p, m["corpo"]))
        out.append('<g clip-path="url(#%s)">' % cid)
        out.append(poly(p, "url(#%s)" % pat))
        out.append(segni(stile, p, m, rng))
        out.append(poly(p, "url(#%s)" % gl))
        out.append(poly(p, "url(#%s)" % ao))
        if g.get("dipinto"):   # tratteggio da incisione nella parte bassa della piattaforma
            out.append(poly(p, "url(#tratteggio)", 1, 'mask="url(#basso)"'))
        # smusso: luce sugli spigoli verso la sorgente, buio sugli altri
        n = len(p)
        cr = m.get("crosta_h", 10)
        for i in range(n):
            a, b = p[i], p[(i + 1) % n]
            dx, dy = b[0] - a[0], b[1] - a[1]
            if abs(dx) + abs(dy) < 1:
                continue
            nx, ny = _nrm(dy, -dx)
            if dx > .5:
                out.append(poly([a, b, (b[0], b[1] + cr), (a[0], a[1] + cr)], m["crosta"]))
                out.append(poly([(a[0], a[1] + cr), (b[0], b[1] + cr), (b[0], b[1] + cr + 4), (a[0], a[1] + cr + 4)], "#000", .3))
                out.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="3"/>' % (a[0], a[1] + 1.5, b[0], b[1] + 1.5, m["luce"]))
            else:
                mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
                vx2, vy2 = _nrm(lx - mx, ly - my)
                lum = nx * vx2 + ny * vy2
                if lum > .15:
                    out.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="5" opacity="%.2f"/>'
                               % (a[0], a[1], b[0], b[1], luce_col, .25 + .4 * lum))
                else:
                    out.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#000" stroke-width="8" opacity=".3"/>' % (a[0], a[1], b[0], b[1]))
        out.append("</g>")
        out.append(appesi(stile, p, m, rng))
        if bordo:
            out.append(poly(p, "none", 1, 'stroke="%s" stroke-width="%s" stroke-linejoin="miter"' % (m["bordo"], m.get("bordo_w", 4))))
    return "".join(out)


def trave3d(x, y, w, h, m, g):
    """Acciaio: stesso linguaggio di sempre, con lo spessore verso il punto di fuga."""
    vp = g.get("fuga", (640, 330))
    k = g.get("profondita", 0)   # 0 = piattaforme piatte (scelta di Sergio 1/11); .075 = con spessore
    d = lambda q: (q[0] + (vp[0] - q[0]) * k, q[1] + (vp[1] - q[1]) * k)
    if not k:
        return ""
    s = []
    a, b, c, e = (x, y), (x + w, y), (x + w, y + h), (x, y + h)
    if y + h < vp[1]:
        s.append(poly([e, c, d(c), d(e)], mix(m["acciaio"], "#000", .5), 1, 'stroke="%s" stroke-width="2"' % m["bordo"]))
    else:
        s.append(poly([a, b, d(b), d(a)], mix(m["acciaio"], m["acciaio_luce"], .35), 1, 'stroke="%s" stroke-width="2"' % m["bordo"]))
    side = (b, c) if x + w < vp[0] else (a, e)
    s.append(poly([side[0], side[1], d(side[1]), d(side[0])], mix(m["acciaio"], "#000", .3), 1, 'stroke="%s" stroke-width="2"' % m["bordo"]))
    return "".join(s)


# ---------------------------------------------------------------- gli stili dei gironi
STILI = {
    "ferro":     dict(sagoma=gradoni(18, 14, 1), segni="fasce", appesi="catenelle"),
    "rovina":    dict(sagoma=gradoni(22, 16, 2), segni="muschio"),
    "scoglio":   dict(sagoma=chiglia(70), segni="vene"),
    "fango":     dict(sagoma=denti(26, 10), segni="pozze", appesi="gocce"),
    "oro":       dict(sagoma=gradoni(16, 12, 2), segni="monete"),
    "palude":    dict(sagoma=chiglia(28), appesi="radici"),
    "sepolcro":  dict(sagoma=gradoni(14, 10, 2), segni="crepe"),
    "spine":     dict(sagoma=denti(22, 18), segni="ossa", appesi="gocce"),
    "bolgia":    dict(sagoma=gradoni(20, 14, 1), segni="pece"),
    "ghiaccio":  dict(sagoma=denti(34, 30), segni="faccette"),
    "prato":     dict(sagoma=chiglia(40), segni="erba"),
    "nuvola":    dict(sagoma=chiglia(30), segni="faccette"),
}


# ---------------------------------------------------------------- sfondo con volume
def poligoni3d(ps, col, lato=1, op=1):
    """Sagome dello sfondo con due toni: la parte verso la luce un po' più chiara (sembrano
    blocchi e torri con un lato in ombra) e la cima che prende luce."""
    out = []
    gid, vid = Id.new("lt"), Id.new("vt")
    chiaro, scuro = mix(col, "#ffffff", .1), mix(col, "#000000", .22)
    a, b = (chiaro, scuro) if lato < 0 else (scuro, chiaro)
    out.append("<defs><linearGradient id='%s' x1='0' x2='1' y1='0' y2='0'>"
               "<stop offset='0' stop-color='%s'/><stop offset='.5' stop-color='%s'/><stop offset='.5' stop-color='%s'/>"
               "<stop offset='1' stop-color='%s'/></linearGradient>"
               "<linearGradient id='%s' x1='0' x2='0' y1='0' y2='1'><stop offset='0' stop-color='#fff' stop-opacity='.12'/>"
               "<stop offset='.25' stop-color='#fff' stop-opacity='0'/><stop offset='1' stop-color='#000' stop-opacity='.18'/></linearGradient></defs>"
               % (gid, a, a, b, b, vid))
    for p in ps:
        xs = [x for x, _ in p]
        larg = max(xs) - min(xs)
        if larg < 260:
            out.append(poly(p, "url(#%s)" % gid, op))
        else:
            out.append(poly(p, col, op))
        out.append(poly(p, "url(#%s)" % vid, op))
    return "".join(out)
