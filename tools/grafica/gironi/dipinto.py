# Le scene dei gironi «dipinte» per stare con l'apprendista (documento delle mappe
# dell'apprendista, 1-2 novembre 2026): ogni girone ha una tinta sola lontana dal
# rosso (temi.py), le sagome dello sfondo sfumano dalla luce alla foschia e hanno il
# tratteggio da incisione in basso, le piattaforme sono spente e senza nero (il nero
# è dei personaggi), il fuoco e la lava restano accesi perché sono pericoli.
#
#   piani(g, P) -> cielo, gruppi di piani dello sfondo e piano di gioco, già colorati
import colorsys, re
from scena import W, H, mix, hx, Id, trave, nebbia
from mondo import strati, T


def h2rgb(c):
    return [v / 255 for v in hx(c)]


def rgb2h(r, g, b):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v * 255))) for v in (r, g, b))


def grade(c, ruolo, P):
    """ruolo: sfondo / gioco / materiale / luce. P: tema del girone (temi.py)."""
    r, g, b = h2rgb(c)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    if ruolo == "sfondo":
        s = min(s * .5, P["sat_sfondo"])
        h = P["tinta"]
        l = P["l0"] + l * P["l1"]
    elif ruolo in ("gioco", "materiale"):
        if ruolo == "gioco" and s > .55 and l > .42 and (h < 60 / 360 or h > 330 / 360):
            pass                                    # fuoco, lava, braci: pericoli, restano accesi
        else:
            h = P["tinta_gioco"]
            s = min(s * .7, P["sat_gioco"])
            l = .06 + l * .94
    else:
        s = min(s, .62)
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return rgb2h(r, g, b)


def colora(svg, ruolo, P):
    return re.sub(r"#[0-9a-fA-F]{6}\b", lambda m: grade(m.group(0), ruolo, P), svg)


def sfuma_sagome(svg, P):
    """Ogni sagoma piena dello sfondo: sfumatura dall'alto (luce) al basso (foschia) e tratteggio in basso."""
    grads = {}

    def rep(m):
        pts_, col, op = m.group(1), m.group(2), m.group(3)
        if col not in grads:
            grads[col] = Id.new("sf")
        gid = grads[col]
        return ('<polygon points="%s" fill="url(#%s)" opacity="%s"/><polygon points="%s" fill="url(#tratteggio)" mask="url(#basso)" opacity="%s"/>'
                % (pts_, gid, op, pts_, op))
    out = re.sub(r'<polygon points="([^"]*)" fill="(#[0-9a-f]{6})" opacity="([0-9.]*)"\s*/>', rep, svg)
    defs = "".join("<linearGradient id='%s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='%s'/>"
                   "<stop offset='.55' stop-color='%s'/><stop offset='1' stop-color='%s'/></linearGradient>"
                   % (gid, mix(col, P["luce"], .12), col, mix(col, P["foschia"], .45)) for col, gid in grads.items())
    return "<defs>%s</defs>%s" % (defs, out)


# il tratteggio da incisione e la maschera che lo tiene nella parte bassa di ogni sagoma
DEFS = """<defs>
<pattern id="tratteggio" width="7" height="7" patternUnits="userSpaceOnUse" patternTransform="rotate(-35)">
 <line x1="0" y1="0" x2="0" y2="7" stroke="#000" stroke-width="1.3" opacity=".55"/></pattern>
<linearGradient id="gbasso" x1="0" y1="0" x2="0" y2="1"><stop offset=".35" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity=".75"/></linearGradient>
<mask id="basso" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#gbasso)"/></mask>
</defs>"""

# i piani dello sfondo, raccolti in tre gruppi per velocità: nel gioco ognuno è
# un'immagine che si ripete in orizzontale (largo un giro, T)
GRUPPI = (("lontano", 0, .2), ("medio", .2, .45), ("vicino", .45, 9))


def piani(g, P):
    """{'cielo': svg 1280x720, 'gruppi': [(nome, svg largo T, velocità media)], 'gioco': svg 1280x720}."""
    g = dict(g)
    g["dipinto"] = True
    if g.get("luce"):
        l_ = list(g["luce"]); l_[3] = P["luce"]; g["luce"] = tuple(l_)
    g["mat"] = {k: (grade(v, "materiale", P) if isinstance(v, str) and v.startswith("#") and len(v) == 7 else v)
                for k, v in g["mat"].items()}
    g.pop("diavoli", None)
    travi = g.pop("travi", [])
    cielo, gioco, gruppi = "", "", {n: ([], []) for n, _, _ in GRUPPI}
    for nome, s, vel in strati(g, anima=False):
        if nome == "cielo":
            s = re.sub(r"<radialGradient.*?</radialGradient>", lambda m: colora(m.group(0), "luce", P), s)
            cielo = re.sub(r"<linearGradient.*?</linearGradient>", lambda m: colora(m.group(0), "sfondo", P), s)
        elif nome == "gioco":
            gs = colora(s, "gioco", P)
            # l'ombra sullo sfondo la fa lo shader del gioco
            gs = re.sub(r'<g filter="url\(#om\d+\)" opacity="[0-9.]+">.*?</g>', "", gs, count=1)
            gioco = gs + "".join(trave(*t, g["mat"]) for t in travi)
        elif nome == "particelle":
            pass                                    # le braci le fa lo shader
        elif nome.startswith("nebbia"):
            # la nebbia è ferma e uguale in orizzontale: va col gruppo lontano, larga un giro
            gruppi["lontano"][0].append('<g transform="scale(%g,1)">%s</g>' % (T / W, colora(s, "luce", P)))
        else:
            for n, a, b in GRUPPI:
                if a <= vel < b:
                    gruppi[n][0].append(sfuma_sagome(colora(s, "sfondo", P), P))
                    gruppi[n][1].append(vel)
    out = [(n, "".join(gruppi[n][0]), sum(gruppi[n][1]) / max(1, len(gruppi[n][1]))) for n, _, _ in GRUPPI]
    return dict(cielo=cielo, gruppi=out, gioco=gioco)


def raggi(g, P, n=7):
    """I raggi di luce leggeri dalla sorgente del girone (vanno nel cielo, fermi)."""
    import random
    if not g.get("luce"):
        return ""
    lx, ly = g["luce"][0], g["luce"][1]
    rng = random.Random(g["seme"])
    rg = ""
    for _ in range(n):
        a, w = rng.uniform(-.9, .9), rng.uniform(30, 90)
        rg += '<polygon points="%d,%d %d,%d %d,%d" fill="%s" opacity="%.2f"/>' % (
            lx, ly, lx + 900 * a - w, ly + 900, lx + 900 * a + w, ly + 900, P["luce"], rng.uniform(.03, .07))
    return rg
