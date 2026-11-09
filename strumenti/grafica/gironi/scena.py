# Disegno vettoriale delle scene di prova: cielo, piani di sfondo, piattaforme.
# Tutto in SVG a 1280x720 (una finestra di gioco). Coordinate in pixel di mondo.
import math, random

W, H = 1280, 720
# il terreno dipinto e la maschera hanno un margine per lato (pixel della scena): vi stanno le
# piattaforme che escono dai muri; sim/game.lua: MARGIN, 180 unità del mondo = 120 della scena
MARGINE = 120


def hx(c):
    c = c.lstrip("#")
    if len(c) == 3:
        c = "".join(ch * 2 for ch in c)
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    a, b = hx(a), hx(b)
    return "#%02x%02x%02x" % tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def pts(p):
    return " ".join("%.1f,%.1f" % q for q in p)


class Id:
    n = 0

    @classmethod
    def new(cls, s):
        cls.n += 1
        return "%s%d" % (s, cls.n)


# ---------------- sagome di sfondo (spigoli dritti, come le mappe) ----------------

def montagne(rng, y0, amp, passo, larg=W * 2):
    """Creste a spigoli: solo segmenti dritti, picchi a punta."""
    p = [(0, H)]
    x = 0
    y = y0
    p.append((0, y))
    while x < larg:
        dx = rng.uniform(passo * .5, passo * 1.4)
        y = y0 - rng.uniform(0, amp)
        x += dx
        p.append((x, y))
    p.append((larg, H))
    return p


def torri(rng, y0, n, larg=W * 2, w=(30, 70), h=(60, 200), punta=True):
    s = []
    for i in range(n):
        x = rng.uniform(0, larg)
        ww = rng.uniform(*w)
        hh = rng.uniform(*h)
        if punta:
            s.append([(x, y0), (x, y0 - hh), (x + ww / 2, y0 - hh - ww * .8), (x + ww, y0 - hh), (x + ww, y0)])
        else:
            s.append([(x, y0), (x, y0 - hh), (x + ww, y0 - hh), (x + ww, y0)])
    return s


def mura(rng, y0, alto, larg=W * 2, merlo=18):
    p = [(0, H), (0, y0 - alto)]
    x = 0
    while x < larg:
        p += [(x, y0 - alto), (x, y0 - alto - merlo), (x + merlo, y0 - alto - merlo), (x + merlo, y0 - alto)]
        x += merlo * 2
    p += [(larg, y0 - alto), (larg, H)]
    return p


def poly(p, fill, op=1, extra=""):
    return '<polygon points="%s" fill="%s" opacity="%.2f" %s/>' % (pts(p), fill, op, extra)


def strato(contenuto, vel, larg=W * 2, anima=True):
    """Un piano di sfondo: si ripete due volte per scorrere senza stacchi."""
    if not anima or vel == 0:
        return "<g>%s</g>" % contenuto
    dur = 240 / vel
    return ('<g class="scorre" style="animation-duration:%.0fs">%s<g transform="translate(%d,0)">%s</g></g>'
            % (dur, contenuto, larg, contenuto))


# ---------------- piattaforme ----------------

def isola(top, prof, smusso=None):
    """Poligono di un'isola: il profilo di sopra e un fondo smussato a 45 gradi."""
    x0, y0 = top[0]
    x1, y1 = top[-1]
    yb = max(y for _, y in top) + prof
    c = smusso if smusso is not None else min(prof * .6, (x1 - x0) / 4)
    giu = [(x1, y1), (x1, yb - c), (x1 - c, yb), (x0 + c, yb), (x0, yb - c), (x0, y0)]
    return list(top) + giu[1:-1]


def disegna_isole(isole, m, uid):
    """m: materiale. Corpo, motivo, ombra interna, crosta sul profilo di sopra, contorno."""
    out = []
    pat = Id.new("pat")
    grad = Id.new("ombra")
    out.append("<defs>%s<linearGradient id='%s' x1='0' y1='0' x2='0' y2='1'>"
               "<stop offset='0' stop-color='#000' stop-opacity='0'/>"
               "<stop offset='1' stop-color='#000' stop-opacity='.45'/></linearGradient></defs>"
               % (motivo(pat, m), grad))
    for top, prof in isole:
        p = isola(top, prof)
        out.append(poly(p, m["corpo"]))
        out.append(poly(p, "url(#%s)" % pat))
        out.append(poly(p, "url(#%s)" % grad))
        # crosta: una fascia che segue il profilo di sopra
        cr = m.get("crosta_h", 10)
        band = list(top) + [(x, y + cr) for x, y in reversed(top)]
        out.append(poly(band, m["crosta"]))
        out.append('<polyline points="%s" fill="none" stroke="%s" stroke-width="3" stroke-linejoin="miter"/>'
                   % (pts(top), m["luce"]))
        if m.get("ciuffi"):
            for i in range(len(top) - 1):
                (ax, ay), (bx, by) = top[i], top[i + 1]
                if abs(by - ay) < 1:
                    xx = ax + 14
                    while xx < bx - 14:
                        out.append('<polygon points="%s" fill="%s"/>' % (
                            pts([(xx - 5, ay + cr), (xx, ay + cr + 9), (xx + 5, ay + cr)]), m["crosta"]))
                        xx += 26
        out.append(poly(p, "none", 1, 'stroke="%s" stroke-width="%s" stroke-linejoin="miter"'
                        % (m["bordo"], m.get("bordo_w", 4))))
    return "".join(out)


def motivo(pid, m):
    t = m.get("motivo", "pietra")
    c = m.get("segni", "#000")
    o = m.get("segni_op", .25)
    if t == "mattoni":
        return ("<pattern id='%s' width='64' height='32' patternUnits='userSpaceOnUse'>"
                "<path d='M0,16 H64 M0,32 H64 M20,0 V16 M52,16 V32' stroke='%s' stroke-opacity='%s' stroke-width='3' fill='none'/></pattern>"
                % (pid, c, o))
    if t == "lastre":
        return ("<pattern id='%s' width='90' height='54' patternUnits='userSpaceOnUse'>"
                "<path d='M0,0 L40,0 L52,27 L40,54 M52,27 H90' stroke='%s' stroke-opacity='%s' stroke-width='3' fill='none'/></pattern>"
                % (pid, c, o))
    if t == "fango":
        return ("<pattern id='%s' width='70' height='40' patternUnits='userSpaceOnUse'>"
                "<path d='M6,12 h18 M40,30 h20 M30,6 h8' stroke='%s' stroke-opacity='%s' stroke-width='4' stroke-linecap='round'/></pattern>"
                % (pid, c, o))
    if t == "ghiaccio":
        return ("<pattern id='%s' width='120' height='80' patternUnits='userSpaceOnUse'>"
                "<path d='M0,80 L40,0 M40,0 L120,60 M70,80 L95,40' stroke='%s' stroke-opacity='%s' stroke-width='2' fill='none'/></pattern>"
                % (pid, c, o))
    if t == "venature":
        return ("<pattern id='%s' width='100' height='60' patternUnits='userSpaceOnUse'>"
                "<path d='M0,20 L30,26 L60,14 L100,22 M10,50 L50,44 L80,54' stroke='%s' stroke-opacity='%s' stroke-width='3' fill='none'/></pattern>"
                % (pid, c, o))
    # pietra: crepe a spigoli
    return ("<pattern id='%s' width='96' height='64' patternUnits='userSpaceOnUse'>"
            "<path d='M10,14 L30,22 L28,40 M60,8 L72,30 L94,34 M44,52 L64,58' stroke='%s' stroke-opacity='%s' stroke-width='3' fill='none'/></pattern>"
            % (pid, c, o))


def trave(x, y, w, h, m):
    """Acciaio indistruttibile: sempre lo stesso linguaggio (lamiera, bulloni, bordo chiaro)."""
    s = ['<rect x="%d" y="%d" width="%d" height="%d" fill="%s" stroke="%s" stroke-width="3"/>'
         % (x, y, w, h, m["acciaio"], m["bordo"])]
    s.append('<rect x="%d" y="%d" width="%d" height="3" fill="%s"/>' % (x + 2, y + 2, w - 4, m["acciaio_luce"]))
    step = 34
    xx = x + 12
    while xx < x + w - 6:
        s.append('<circle cx="%d" cy="%.1f" r="2.6" fill="%s"/>' % (xx, y + h / 2, m["acciaio_luce"]))
        xx += step
    return "".join(s)


def diavoletto(x, y, col, s=1.0):
    """Sagoma di misura (46 px di mondo dai piedi alla fiammella), non il disegno vero."""
    return ('<g transform="translate(%.1f,%.1f) scale(%.2f)">'
            '<ellipse cx="0" cy="0" rx="13" ry="4" fill="#000" opacity=".35"/>'
            '<rect x="-7" y="-16" width="14" height="16" rx="3" fill="%s"/>'
            '<circle cx="0" cy="-27" r="12" fill="%s" stroke="#111" stroke-width="2"/>'
            '<path d="M-9,-35 L-12,-44 L-4,-38 Z M9,-35 L12,-44 L4,-38 Z" fill="#3a120c"/>'
            '<rect x="-9" y="-31" width="18" height="6" rx="3" fill="#111"/>'
            '<circle cx="4" cy="-28" r="1.6" fill="#fff"/>'
            '<path d="M0,-40 C4,-44 3,-48 0,-52 C-3,-48 -4,-44 0,-40 Z" fill="#ffb03a" transform="translate(0,-2) scale(.9)"/>'
            '</g>' % (x, y, s, col, col))


def particelle(rng, n, tipo, col, area=(0, 0, W, H)):
    s = []
    x0, y0, x1, y1 = area
    for i in range(n):
        x = rng.uniform(x0, x1)
        y = rng.uniform(y0, y1)
        d = rng.uniform(6, 14)
        if tipo == "braci":
            r = rng.uniform(1.5, 3.2)
            s.append('<rect class="sale" style="animation-duration:%.1fs;animation-delay:-%.1fs" x="%.0f" y="%.0f" width="%.1f" height="%.1f" fill="%s" opacity="%.2f" transform="rotate(45 %.0f %.0f)"/>'
                     % (d, rng.uniform(0, d), x, y, r * 2, r * 2, col, rng.uniform(.5, 1), x, y))
        elif tipo == "neve":
            r = rng.uniform(1.2, 3)
            s.append('<circle class="cade" style="animation-duration:%.1fs;animation-delay:-%.1fs" cx="%.0f" cy="%.0f" r="%.1f" fill="%s" opacity="%.2f"/>'
                     % (d, rng.uniform(0, d), x, y, r, col, rng.uniform(.4, .9)))
        elif tipo == "pioggia":
            s.append('<line class="cade" style="animation-duration:%.1fs;animation-delay:-%.1fs" x1="%.0f" y1="%.0f" x2="%.0f" y2="%.0f" stroke="%s" stroke-width="2" opacity="%.2f"/>'
                     % (d / 4, rng.uniform(0, d), x, y, x - 6, y + 22, col, rng.uniform(.3, .6)))
        elif tipo == "petali":
            s.append('<polygon class="vola" style="animation-duration:%.1fs;animation-delay:-%.1fs" points="%s" fill="%s" opacity="%.2f"/>'
                     % (d, rng.uniform(0, d), pts([(x, y), (x + 6, y - 3), (x + 10, y + 2), (x + 4, y + 4)]), col, rng.uniform(.5, .9)))
        elif tipo == "polvere":
            r = rng.uniform(1, 2.4)
            s.append('<circle class="vola" style="animation-duration:%.1fs;animation-delay:-%.1fs" cx="%.0f" cy="%.0f" r="%.1f" fill="%s" opacity="%.2f"/>'
                     % (d * 2, rng.uniform(0, d), x, y, r, col, rng.uniform(.3, .7)))
    return "".join(s)


def acqua(y, col, cresta, h=None, onde=True):
    h = h or (H - y)
    s = ['<rect x="0" y="%d" width="%d" height="%d" fill="%s"/>' % (y, W, h, col)]
    if onde:
        d = "M0,%d " % y + " ".join("l20,-6 l20,6" for _ in range(70))
        s.append('<g class="onde"><path d="%s" fill="none" stroke="%s" stroke-width="3"/></g>' % (d, cresta))
        d2 = "M-20,%d " % (y + 18) + " ".join("l30,-4 l30,4" for _ in range(50))
        s.append('<path d="%s" fill="none" stroke="%s" stroke-width="2" opacity=".5"/>' % (d2, cresta))
    return "".join(s)


def bagliore(cx, cy, r, col, op=.6):
    gid = Id.new("bg")
    return ("<defs><radialGradient id='%s'><stop offset='0' stop-color='%s' stop-opacity='%.2f'/>"
            "<stop offset='1' stop-color='%s' stop-opacity='0'/></radialGradient></defs>"
            "<circle cx='%d' cy='%d' r='%d' fill='url(#%s)'/>" % (gid, col, op, col, cx, cy, r, gid))


def cielo(top, bot):
    gid = Id.new("cielo")
    return ("<defs><linearGradient id='%s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='%s'/>"
            "<stop offset='1' stop-color='%s'/></linearGradient></defs><rect width='%d' height='%d' fill='url(#%s)'/>"
            % (gid, top, bot, W, H, gid))


def nebbia(y, h, col, op=.5):
    gid = Id.new("neb")
    return ("<defs><linearGradient id='%s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='%s' stop-opacity='0'/>"
            "<stop offset='.5' stop-color='%s' stop-opacity='%.2f'/><stop offset='1' stop-color='%s' stop-opacity='0'/></linearGradient></defs>"
            "<rect x='0' y='%d' width='%d' height='%d' fill='url(#%s)'/>" % (gid, col, col, op, col, y, W, h, gid))


def svg(inner, w=W, h=H, extra=""):
    return ('<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg" %s>'
            '<defs><clipPath id="riquadro"><rect width="%d" height="%d"/></clipPath></defs>'
            '<g clip-path="url(#riquadro)">%s</g></svg>' % (W, H, extra, W, H, inner))
