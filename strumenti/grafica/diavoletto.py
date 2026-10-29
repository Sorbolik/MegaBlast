# Il diavoletto a pezzi, disegnato a vettori (SVG) come le armi (vettori.py):
# contorno nero spesso, colori pieni con una sfumatura semplice. Il gioco monta
# i pezzi e li anima nel codice (client/battaglia/scoria.lua): niente fogli di
# fotogrammi, l'atlante è piccolo e il movimento è fluido a qualsiasi frequenza.
# Scrive:
#   client/assets/diavoletto/<pezzo>.png        un pezzo (guarda a destra)
#   client/assets/diavoletto/<pezzo>_tinta.png  le parti col colore della
#                                               squadra (bianche e grigie, tinte nel codice)
#   client/battaglia/diavoletto.atlas
#   client/battaglia/diavoletto.lua             misure di ogni pezzo rispetto al suo
#                                               perno e i punti dove si attaccano
#   simulazione/foto/diavoletto_anteprima.png   il diavoletto montato, per guardarlo
#
# Unità del disegno: il diavoletto fermo è alto ALTEZZA (200) dai piedi (y 0)
# alla cima della testa (corna, coda e fiammella escono), x 0 in mezzo ai piedi,
# guarda a destra, y verso l'alto. Ogni pezzo è disegnato attorno al suo perno
# (il punto in cui gira) e i PUNTI dicono dove va il perno nel diavoletto fermo.
# Il gioco lo scala in modo che ALTEZZA sia ROBOT_H, il corpo della simulazione.
# Il contorno è spesso come quello delle armi sullo schermo.
#
# python3 strumenti/grafica/diavoletto.py   (serve cairosvg: pip install cairosvg)
import math
import os
import re
import sys
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
RADICE = os.path.join(QUI, "..", "..")
OUT = os.path.join(RADICE, "client", "assets", "diavoletto")
LUA = os.path.join(RADICE, "client", "battaglia", "diavoletto.lua")
ATLAS = os.path.join(RADICE, "client", "battaglia", "diavoletto.atlas")
ANTEPRIMA = os.path.join(RADICE, "simulazione", "foto", "diavoletto_anteprima.png")

from vettori import BORDO, RIGA, INK, COL, Disegno, rendi, gradienti  # noqa: E402

ALTEZZA = 200
# il corpo nel mondo (sim/game.lua: BLASTRON_ROBOT_H * BLASTRON_CORPO), per
# dare al contorno lo stesso spessore delle armi sullo schermo
CORPO_MONDO = 28 * 1.4
U = ALTEZZA / CORPO_MONDO          # unità del disegno per unità del mondo
BORDO_D = round(BORDO * U, 1)      # 7.7
RIGA_D = round(RIGA * U, 1)
# pixel per unità del disegno: come le armi (6 px per unità del mondo)
PX = round(6 / U, 2)               # 1.18

# i colori del diavoletto (scuro, base, chiaro), oltre a quelli delle armi
COL = dict(COL)
COL.update({
    "pelle": ("#a58f70", "#cdb896", "#eadcc0"),
    "pelle_dietro": ("#8a7658", "#a9967a", "#c4b398"),   # braccio e gamba di dietro, in ombra
    "corno": ("#4f1e12", "#8a3a26", "#b8613f"),
    "canotta": ("#a52c10", "#e4461c", "#ff7a4a"),
    "braghe": ("#b03a16", "#e8602a", "#ff9a5c"),
    "braghe_dietro": ("#8e2e10", "#c04c20", "#d87a44"),
    "scarpa_dietro": ("#2a160c", "#50301c", "#78482c"),
    "scarpa": ("#3a2012", "#6a3b24", "#9a5f3c"),
    "ala": ("#1c1b22", "#36353f", "#5a5966"),
    "coda": ("#d8401c", "#d8401c", "#d8401c"),   # piatto: i segmenti si fondono
    "nero": (INK, INK, INK),
    "cinta": ("#2a2a2e", "#46464d", "#6b6b74"),
    "occhio": ("#f2d98a", "#fff3cc", "#ffffff"),
    "fiamma": ("#8a8a8a", "#d2d2d2", "#ffffff"),   # tinta col colore della squadra
    "bocca": ("#3a1a16", "#5a2a24", "#7a3a30"),
})

# Dove vanno i perni dei pezzi nel diavoletto fermo (dal centro dei piedi).
PUNTI = {
    "collo": (0, 122),        # la testa gira qui
    "bacino": (0, 76),        # il busto
    "anche": (12, 76),        # le gambe: davanti a +x, dietro a -x
    "spalle": (32, 110),      # le braccia: davanti a +x, dietro a -x
    "ala": (-16, 116),
    "coda": (-10, 70),
    "cima": (0, 82),          # la cima della testa, dal collo: lì va la fiammella
}
# la coda: segmenti dalla radice alla punta, lunghezza e larghezza all'inizio
# e alla fine; la punta ha il tridente. Angoli di riposo (gradi) per l'anteprima.
CODA = [(26, 11, 9.5), (26, 9.5, 8), (26, 8, 7), (26, 7, 6), (24, 6, 5)]
CODA_RIPOSO = (200, 160, 120, 90, 65)
# il perno del paracadute (dove convergono le funi), dai piedi: sopra la fiammella
PARACADUTE_Y = 262


def D():
    return Disegno(bordo=BORDO_D, col=COL)


# ---------------------------------------------------------------------------
# I pezzi, attorno al loro perno (0, 0). Ognuno torna la scatola
# (x0, y0, x1, y1) che lo contiene col contorno.


def testa(d, faccia="normale"):
    cx, cy, r = 3, 40, 43
    # collo (sotto la testa) e corna, che spuntano da dietro, curve in fuori
    d.rect(-9, -12, 18, 22, "pelle", r=4)
    d.path("M-24,74 Q-50,86 -42,124 Q-32,100 -6,84 Z", "corno")
    d.path("M26,76 Q52,88 46,126 Q38,102 10,86 Z", "corno")
    d.riga("M-42,104 Q-42,110 -41,116", COL["corno"][0], RIGA_D)
    d.riga("M46,106 Q46,112 45,118", COL["corno"][0], RIGA_D)
    d.cerchio(cx, cy, r, "pelle")
    # sopracciglia
    d.riga("M-14,58 Q-4,64 6,58", COL["pelle"][0], RIGA_D * 1.3)
    d.riga("M20,59 Q30,64 38,58", COL["pelle"][0], RIGA_D * 1.3)
    # occhiali: una visiera nera che sporge davanti, con gli occhi accesi
    d.path("M-38,42 Q-40,30 -26,28 L46,24 Q56,24 56,34 Q56,48 46,50 L-26,54 Q-38,54 -38,42 Z", "ferro")
    if faccia == "ko":
        # occhi chiusi: due righe
        d.riga("M-12,38 L0,36 M20,36 L34,34", COL["occhio"][0], RIGA_D * 1.6)
    else:
        w, h = (9, 20) if faccia == "colpito" else (7, 16)
        d.ellisse(-6, 39, w / 2, h / 2, "occhio", contorno=False, rot=-6)
        d.ellisse(27, 37, w / 2, h / 2, "occhio", contorno=False, rot=-6)
    # bocca
    if faccia == "colpito":
        d.ellisse(24, 12, 6, 8, "bocca", contorno=False)
    elif faccia == "felice":
        d.path("M10,16 Q24,-2 38,14 Q24,10 10,16 Z", "bocca", contorno=False)
    elif faccia == "ko":
        d.riga("M12,12 Q18,8 24,12 Q30,16 36,12", COL["bocca"][1], RIGA_D * 1.4)
    else:
        d.riga("M16,14 Q26,8 36,15", COL["bocca"][1], RIGA_D * 1.4)
    return (-58, -14, 66, 134)


def busto(d):
    # la canotta rossa con le spalle di pelle che sporgono, la cintura con la
    # fibbia e la linguetta che pende; perno nel bacino
    d.cerchio(-24, 38, 9, "pelle")
    d.cerchio(24, 38, 9, "pelle")
    d.path("M-26,44 Q-28,20 -24,-2 L24,-2 Q28,20 26,44 Q20,50 14,46 Q6,36 -4,40 Q-14,48 -26,44 Z", "canotta")
    d.riga("M-18,22 Q-20,12 -16,4", COL["canotta"][0], RIGA_D)
    d.riga("M10,24 Q12,14 14,6", COL["canotta"][2], RIGA_D)
    d.rect(-27, -8, 54, 12, "cinta", r=3)
    d.rect(8, -26, 7, 20, "cinta", r=2)
    d.rect(4, -10, 12, 16, "ottone", r=2)
    d.riga("M7,-4 L13,-4", COL["ottone"][0], RIGA_D)
    return (-42, -36, 42, 58)


def gamba(d, dietro=False):
    # un pantalone largo con il risvolto e la scarpa marrone, perno nell'anca;
    # quella di dietro è in ombra
    b, sc = ("braghe_dietro", "scarpa_dietro") if dietro else ("braghe", "scarpa")
    d.path("M-12,4 L12,4 L14,-32 Q11,-54 10,-58 L-10,-58 Q-13,-54 -14,-32 Z", b)
    d.rect(-11, -62, 22, 9, b, r=2)
    d.riga("M-8,-16 Q-6,-32 -7,-46", COL[b][0], RIGA_D)
    d.path("M-13,-60 Q-16,-74 -4,-74 L16,-74 Q24,-74 22,-66 Q20,-60 10,-60 Z", sc)
    d.riga("M-8,-70 L18,-70", COL[sc][0], RIGA_D)
    return (-26, -84, 34, 14)


def braccio(d, dietro=False):
    # il braccio che pende, un po' piegato, col pugno; perno nella spalla
    p = "pelle_dietro" if dietro else "pelle"
    d.path("M-7,2 L7,2 Q9,-16 10,-32 Q10,-40 3,-40 Q-5,-40 -5,-32 Q-6,-16 -7,2 Z", p)
    d.riga("M1,-12 Q2,-22 2,-30", COL[p][0], RIGA_D)
    d.cerchio(3, -42, 7.5, p)
    d.riga("M-2,-39 L8,-39", COL[p][0], RIGA_D)
    return (-18, -60, 22, 12)


def pugno(d):
    # il pugno da solo, per le manine staccate
    d.cerchio(0, 0, 7.2, "pelle")
    d.riga("M-4,2.5 L5,2.5", COL["pelle"][0], RIGA_D)
    return (-16, -16, 16, 16)


def ala(d):
    # l'ala da pipistrello, perno dove si attacca alla schiena, aperta all'indietro
    d.path("M0,4 L-4,7 L-31,21 Q-38,22 -39,20 Q-32,13 -38,4 Q-31,-1 -29,-13 Q-20,-7 -8,-10 Q-1,-4 0,-4 Z", "ala")
    d.riga("M-4,6 L-35,15 M-4,4 L-35,0 M-4,1 L-27,-10", COL["ala"][0], RIGA_D * 1.2)
    return (-50, -24, 10, 32)


def segmento_coda(i, d, bordo):
    # un segmento della coda, un tubo che si assottiglia; in due versioni, il
    # bordo (più largo) e il colore, così il gioco disegna prima tutti i bordi e
    # poi tutti i colori e i segmenti si fondono in una coda sola
    L, w0, w1 = CODA[i]
    r0, r1 = w0 / 2, w1 / 2
    b = BORDO_D if bordo else 0
    r0, r1 = r0 + b, r1 + b
    col = "nero" if bordo else "coda"
    d.path(f"M0,{r0} L{L},{r1} A{r1},{r1} 0 0 0 {L},{-r1} L0,{-r0} A{r0},{r0} 0 0 0 0,{r0} Z",
           col, contorno=False)
    if i == len(CODA) - 1:
        # la punta a tridente: una lancia in mezzo e due rebbi ricurvi
        p = L
        d.path(f"M{p - 2 - b},{0} L{p + 4},{5 + b} L{p + 20 + b},{0} L{p + 4},{-5 - b} Z", col, contorno=False)
        d.path(f"M{p - 4 - b},{2} Q{p - 6 - b},{10 + b} {p + 4 + b},{14 + b} Q{p + 2},{8} {p + 4},{3} Z", col,
               contorno=False)
        d.path(f"M{p - 4 - b},{-2} Q{p - 6 - b},{-10 - b} {p + 4 + b},{-14 - b} Q{p + 2},{-8} {p + 4},{-3} Z",
               col, contorno=False)
    return (-12, -28, L + 32, 28)


# La fiammella: un disegno solo (art/fiammella/fiammella.png, bianco e grigio
# col contorno nero, da un'immagine di Sergio), non a vettori. Il gioco tinge il
# bianco e il grigio col colore della squadra e la anima con la sua clip.
# Perno alla base: la punta della fiamma grande sta sopra la testa.
FIAMMA = os.path.join(RADICE, "art", "fiammella", "fiammella.png")
FIAMMA_H = 76      # altezza in unità del disegno
FIAMMA_SOTTO = 8   # quanto scende sotto il perno


class Immagine:
    """Un pezzo disegnato a mano: l'immagine e lo strato da tingere, con lo
    stesso gruppo SVG dei pezzi a vettori per l'anteprima."""

    def __init__(self, base, tinta, box):
        self.base, self.tinta, self.box = base, tinta, box

    def gruppo(self, tinta=False, transform=""):
        import base64
        import io
        x0, y0, x1, y1 = self.box
        b = io.BytesIO()
        (self.tinta if tinta else self.base).save(b, "PNG")
        dati = base64.b64encode(b.getvalue()).decode()
        return (f'<g transform="{transform}"><image href="data:image/png;base64,{dati}" x="{x0}" y="{-y1}" '
                f'width="{x1 - x0}" height="{y1 - y0}" transform="scale(1,-1)"/></g>')


def fiammella_immagine():
    im = Image.open(FIAMMA).convert("RGBA")
    h = FIAMMA_H
    w = round(h * im.width / im.height, 1)
    box = (-w / 2, -FIAMMA_SOTTO, w / 2, h - FIAMMA_SOTTO)
    im = im.resize((round(w * PX), round(h * PX)), Image.LANCZOS)
    # lo strato da tingere: il bianco e il grigio dentro il contorno, in grigio
    lum = im.convert("L")
    dentro = lum.point(lambda v: max(0, min(255, (v - 64) * 255 // 51)))
    from PIL import ImageChops
    tinta = Image.merge("RGBA", (lum, lum, lum, ImageChops.multiply(dentro, im.getchannel("A"))))
    return Immagine(im, tinta, box)


def paracadute(d):
    # la calotta a spicchi (quelli chiari sono del colore della squadra), le
    # funi che convergono sopra la fiammella (il perno) e le due cinghie che
    # scendono alle spalle, dietro la testa
    sx, sy = PUNTI["spalle"][0], PUNTI["spalle"][1] - PARACADUTE_Y
    d.riga(f"M{sx},{sy} L0,0 L{-sx},{sy}", INK, 3.2)
    for x in (-82, -44, 0, 44, 82):
        d.riga(f"M0,0 L{x},92", INK, 2.6)
    # la calotta: un arco con l'orlo a festoni
    d.path("M-88,92 Q-90,150 0,152 Q90,150 88,92 Q78,84 66,92 Q55,84 44,92 Q33,84 22,92 Q11,84 0,92 "
           "Q-11,84 -22,92 Q-33,84 -44,92 Q-55,84 -66,92 Q-78,84 -88,92 Z", "osso")
    # gli spicchi tinti
    d.path("M-66,92 Q-70,128 -44,146 Q-30,120 -44,92 Q-55,84 -66,92 Z", "fiamma", tinta=True, contorno=False)
    d.path("M-22,92 Q-28,128 0,150 Q28,128 22,92 Q11,84 0,92 Q-11,84 -22,92 Z", "fiamma", tinta=True, contorno=False)
    d.path("M44,92 Q30,120 44,146 Q70,128 66,92 Q55,84 44,92 Z", "fiamma", tinta=True, contorno=False)
    d.riga("M-66,92 Q-70,128 -44,146 M-44,92 Q-30,120 -44,146 M-22,92 Q-28,128 0,150 "
           "M22,92 Q28,128 0,150 M44,92 Q30,120 44,146 M66,92 Q70,128 44,146", INK, RIGA_D)
    return (-100, sy - 8, 100, 164)


PEZZI = {
    "testa": lambda d: testa(d),
    "testa_colpita": lambda d: testa(d, "colpito"),
    "testa_felice": lambda d: testa(d, "felice"),
    "testa_ko": lambda d: testa(d, "ko"),
    "busto": busto,
    "gamba": gamba,
    "gamba_dietro": lambda d: gamba(d, True),
    "braccio": braccio,
    "braccio_dietro": lambda d: braccio(d, True),
    "pugno": pugno,
    "ala": ala,
    "paracadute": paracadute,
}
for i in range(len(CODA)):
    PEZZI[f"coda_{i + 1}"] = (lambda i: lambda d: segmento_coda(i, d, False))(i)
    PEZZI[f"coda_{i + 1}_bordo"] = (lambda i: lambda d: segmento_coda(i, d, True))(i)


def esporta(nome, fn, immagini):
    d = D()
    x0, y0, x1, y1 = fn(d)
    w, h = round((x1 - x0) * PX), round((y1 - y0) * PX)
    rendi(d.svg((x0, y0, x1, y1), PX), w, h).save(os.path.join(OUT, nome + ".png"), optimize=True)
    immagini.append(nome)
    tinta = any(t for _, _, t, _ in d.forme)
    if tinta:
        rendi(d.svg((x0, y0, x1, y1), PX, tinta=True), w, h).save(os.path.join(OUT, nome + "_tinta.png"),
                                                                  optimize=True)
        immagini.append(nome + "_tinta")
    return dict(d=d, tinta=tinta, x=(x0 + x1) / 2, y=(y0 + y1) / 2, w=x1 - x0, h=y1 - y0)


def esporta_immagine(nome, im, immagini):
    im.base.save(os.path.join(OUT, nome + ".png"), optimize=True)
    im.tinta.save(os.path.join(OUT, nome + "_tinta.png"), optimize=True)
    immagini += [nome, nome + "_tinta"]
    x0, y0, x1, y1 = im.box
    return dict(d=im, tinta=True, x=(x0 + x1) / 2, y=(y0 + y1) / 2, w=x1 - x0, h=y1 - y0)


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith(".png"):
            os.remove(os.path.join(OUT, f))
    immagini, pezzi = [], {}
    for nome, fn in PEZZI.items():
        pezzi[nome] = esporta(nome, fn, immagini)
    pezzi["fiammella"] = esporta_immagine("fiammella", fiammella_immagine(), immagini)
    lua = ["-- Fatto da strumenti/grafica/diavoletto.py, non modificare a mano.",
           "-- Il diavoletto a pezzi, in unità del disegno (ALTEZZA dai piedi alla cima",
           "-- della testa, y verso l'alto, guarda a destra). Per ogni pezzo: immagine",
           "-- (tinta: la parte col colore della squadra), centro (x, y) rispetto al suo",
           "-- perno e misura (w, h). I punti dicono dove vanno i perni, dal centro dei",
           "-- piedi (la cima dal collo).",
           "return {", f"\taltezza = {ALTEZZA},", f"\tpx = {PX},  -- pixel delle immagini per unità",
           f"\tbordo = {BORDO_D},  -- spessore del contorno",
           "\tpezzi = {"]
    for nome, p in pezzi.items():
        t = f'"{nome}_tinta"' if p["tinta"] else "nil"
        lua.append(f'\t\t{nome} = {{ img = "{nome}", tinta = {t}, x = {p["x"]:.1f}, y = {p["y"]:.1f}, '
                   f'w = {p["w"]}, h = {p["h"]} }},')
    lua.append("\t},")
    lua.append("\tpunti = {")
    for nome, (x, y) in PUNTI.items():
        lua.append(f"\t\t{nome} = {{ {x}, {y} }},")
    lua.append("\t},")
    lua.append("\tcoda = { " + ", ".join(str(L) for L, _, _ in CODA) + " },  -- lunghezza dei segmenti")
    lua.append("\tcoda_riposo = { " + ", ".join(f"{math.radians(a):.3f}" for a in CODA_RIPOSO) + " },  -- angoli a riposo")
    lua.append(f"\tparacadute_y = {PARACADUTE_Y},  -- il perno del paracadute, dai piedi")
    lua.append("}")
    with open(LUA, "w") as f:
        f.write("\n".join(lua) + "\n")
    scrivi_atlante(immagini)
    anteprima(pezzi)


def scrivi_atlante(immagini=None):
    """L'atlante del diavoletto: i pezzi di base (immagini; se manca, quelli che
    ci sono già) e le pelli dello stampino (client/assets/pelli, le taglia
    strumenti/stampino/taglia.py). Tutto in un atlante solo, così il diavoletto
    si disegna in una volta anche vestito."""
    if immagini is None:
        with open(ATLAS) as f:
            immagini = re.findall(r'"/assets/diavoletto/([a-z0-9_]+)\.png"', f.read())
    pelli = os.path.join(RADICE, "client", "assets", "pelli")
    righe = [f"/assets/diavoletto/{n}.png" for n in immagini]
    if os.path.isdir(pelli):
        righe += [f"/assets/pelli/{n}" for n in sorted(os.listdir(pelli)) if n.endswith(".png")]
    with open(ATLAS, "w") as f:
        for r in righe:
            f.write(f'images {{\n  image: "{r}"\n}}\n')
        f.write("margin: 0\nextrude_borders: 2\ninner_padding: 0\n")


def anteprima(pezzi):
    """Il diavoletto fermo montato come lo monta il gioco (stesso ordine dei
    pezzi) in un solo SVG; a destra, col paracadute. Le parti tinte prendono il
    rosso di una squadra."""
    squadra = ("#8c1e22", "#e6484d", "#ff8a8e")
    W, H, K = 320, 440, 2.2
    gruppi = []

    def metti(nome, x, y, ang=0, ox=0):
        tr = f"translate({x + ox},{y}) rotate({math.degrees(ang):.1f})"
        gruppi.append(pezzi[nome]["d"].gruppo(False, tr))

    for ox in (0, W):
        para = ox > 0
        if para:
            metti("paracadute", 0, PARACADUTE_Y, ox=ox)
        x, y = PUNTI["coda"]
        for suff in ("_bordo", ""):
            x, y = PUNTI["coda"]
            for i, a in enumerate(CODA_RIPOSO):
                a = math.radians(a)
                metti(f"coda_{i + 1}{suff}", x, y, a, ox=ox)
                x, y = x + CODA[i][0] * math.cos(a), y + CODA[i][0] * math.sin(a)
        metti("ala", *PUNTI["ala"], ox=ox)
        sx, sy = PUNTI["spalle"]
        metti("braccio_dietro", -sx, sy, math.radians(168) if para else 0.15, ox=ox)
        ax, ay = PUNTI["anche"]
        metti("gamba_dietro", -ax, ay, 0.12 if para else 0, ox=ox)
        metti("gamba", ax, ay, 0.12 if para else 0, ox=ox)
        metti("busto", *PUNTI["bacino"], ox=ox)
        metti("braccio", sx, sy, math.radians(192) if para else -0.15, ox=ox)
        metti("testa", *PUNTI["collo"], ox=ox)
        cx, cy = PUNTI["collo"]
        metti("fiammella", cx + PUNTI["cima"][0], cy + PUNTI["cima"][1], ox=ox)
    col = dict(COL)
    col["fiamma"] = squadra
    col["bianco"] = ("#ff8a8e", "#ffc0c2", "#ffffff")
    tr = f"scale({K},{-K}) translate({W / 2},{-H + 10})"
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W * 2 * K:.0f}" height="{H * K:.0f}">'
           f'<rect width="100%" height="100%" fill="#7a8a80"/><defs>{gradienti(col)}</defs>'
           f'<g transform="{tr}">{"".join(gruppi)}</g></svg>')
    os.makedirs(os.path.dirname(ANTEPRIMA), exist_ok=True)
    rendi(svg, round(W * 2 * K), round(H * K)).save(ANTEPRIMA)


if __name__ == "__main__":
    main()
