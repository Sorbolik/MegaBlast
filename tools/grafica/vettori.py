# Disegni a vettori (SVG) convertiti in PNG, nello stile del gioco: contorno nero
# spesso, colori pieni con una sfumatura semplice (scuro sotto, chiaro sopra) e
# qualche riga interna. Lo usano armi.py (le armi) e diavoletto.py (il
# personaggio). Serve cairosvg: pip install cairosvg
import io
import cairosvg
from PIL import Image

SUPER = 2   # si disegna al doppio e si rimpicciolisce, per i bordi morbidi

# contorno (metà fuori dalla forma) e righe interne, in unità del mondo
BORDO = 1.5
RIGA = 0.32

INK = "#000000"
# colore: (scuro, base, chiaro)
COL = {
    "rosso": ("#a3300f", "#e2531f", "#ff8d55"),
    "acciaio": ("#5f6570", "#9aa1ab", "#dde2e8"),
    "ferro": ("#2f3138", "#4c505b", "#757b88"),
    "ottone": ("#93611a", "#d79c36", "#f8d47c"),
    "legno": ("#5a361b", "#8a5a32", "#b47f4c"),
    "osso": ("#b9a684", "#efe3c8", "#fffaf0"),
    "cuoio": ("#4a2516", "#7a3d22", "#a65b34"),
    "pietra": ("#4e4752", "#776e7c", "#a39aa6"),
    "fuoco": ("#d2410f", "#ff9a1f", "#ffe36b"),
    "bianco": ("#8c8c8c", "#cfcfcf", "#ffffff"),  # le parti tinte
}


def gradienti(col=COL):
    s = []
    for nome, (d, b, l) in col.items():
        # in user space dopo il ribaltamento: y1=1 è sotto
        s.append(f'<linearGradient id="g_{nome}" x1="0" y1="1" x2="0" y2="0">'
                 f'<stop offset="0" stop-color="{d}"/><stop offset="0.42" stop-color="{b}"/>'
                 f'<stop offset="0.8" stop-color="{b}"/><stop offset="1" stop-color="{l}"/></linearGradient>')
    return "".join(s)


class Disegno:
    """Forme in unità del mondo, y in su. Ogni forma ha un colore; quelle
    "tinta" vanno anche nell'immagine da tingere. Le righe sono interne."""

    def __init__(self, bordo=BORDO, col=COL):
        self.forme = []   # (svg senza fill, colore, tinta, contorno)
        self.righe = []   # (svg path d, colore, spessore)
        self.bordo = bordo   # spessore del contorno, nelle unità del disegno
        self.col = col       # i colori che si possono usare

    def _add(self, el, col, tinta, contorno):
        self.forme.append((el, col, tinta, contorno))

    def rect(self, x, y, w, h, col, r=0, tinta=False, contorno=True):
        self._add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" ry="{r}"', col, tinta, contorno)

    def cerchio(self, x, y, r, col, tinta=False, contorno=True):
        self._add(f'<circle cx="{x}" cy="{y}" r="{r}"', col, tinta, contorno)

    def ellisse(self, x, y, rx, ry, col, tinta=False, contorno=True, rot=0):
        self._add(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" transform="rotate({rot} {x} {y})"',
                  col, tinta, contorno)

    def poli(self, pts, col, tinta=False, contorno=True):
        p = " ".join(f"{x},{y}" for x, y in pts)
        self._add(f'<polygon points="{p}"', col, tinta, contorno)

    def path(self, d, col, tinta=False, contorno=True):
        self._add(f'<path d="{d}"', col, tinta, contorno)

    def riga(self, d, col=INK, w=RIGA):
        self.righe.append((d, col, w))

    def gruppo(self, tinta=False, transform=""):
        """Le forme come un gruppo SVG: contorno (tutte le forme col bordo
        scuro), poi i colori sopra, poi le righe; con tinta solo le parti da
        tingere, bianche e grigie."""
        out = [f'<g transform="{transform}">']
        if not tinta:
            for el, col, t, c in self.forme:
                if c:
                    out.append(f'{el} fill="{INK}" stroke="{INK}" stroke-width="{self.bordo * 2}" '
                               f'stroke-linejoin="round"/>')
            for el, col, t, c in self.forme:
                out.append(f'{el} fill="url(#g_{col})"/>')
            for d, col, w in self.righe:
                out.append(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{w}" '
                           f'stroke-linecap="round" stroke-linejoin="round"/>')
        else:
            for el, col, t, c in self.forme:
                if t:
                    out.append(f'{el} fill="url(#g_bianco)"/>')
        out.append("</g>")
        return "".join(out)

    def svg(self, box, scala, tinta=False, rot=0, lato=None):
        x0, y0, x1, y1 = box
        if lato:
            W = Hh = lato
            # l'icona: ruotata attorno al centro e adattata al quadrato
            cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
            tr = (f'translate({lato / 2},{lato / 2}) scale({scala},{-scala}) rotate({rot}) '
                  f'translate({-cx},{-cy})')
        else:
            W, Hh = (x1 - x0) * scala, (y1 - y0) * scala
            tr = f'scale({scala},{-scala}) translate({-x0},{-y1})'
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W:.0f}" height="{Hh:.0f}">'
                f"<defs>{gradienti(self.col)}</defs>{self.gruppo(tinta, tr)}</svg>")


def rendi(svg, w, h):
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=w * SUPER, output_height=h * SUPER)
    im = Image.open(io.BytesIO(png)).convert("RGBA")
    return im.resize((w, h), Image.LANCZOS)
