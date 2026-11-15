# Le armi e gli oggetti del diavoletto, disegnati da Codex (WB-063...065) e ricalcati a
# vettori: tools/grafica/armi_ricalcate.py ne taglia i pezzi in art/armi/, e qui si
# mettono alla misura del gioco (solo rimpiccioliti) e si scrivono:
#   client/assets/weapons/<arma>.png         l'arma in mano (punta verso destra)
#   client/assets/weapons/<arma>_tinta.png   le parti col colore della squadra
#                                         (il verde del foglio, il gioco le tinge)
#   client/assets/weapons/<arma>_icona.png   l'icona della barra e della scelta
#   client/assets/weapons/<proiettile>.png   i colpi in volo
#   client/battle/weapons.atlas
#   client/battle/weapons.lua             misure in unità del mondo, origine
#                                         nella spalla, x avanti e y in su
#   simulazione/foto/armi_anteprima.png   tutte insieme, per guardarle
#
# Le misure (le scatole qui sotto) sono quelle delle armi di prima, fatte a codice: la
# bocca del Lanciarune e la lama per un robot alto 16 (nel gioco ×K = game.DISEGNO_H /
# game.CORPO / 16 = 1,75: la bocca torna a game.MUZZLE = 24,5); il Maglio e l'Affondo
# lunghi config.MALLET.reach e config.LUNGE.reach (lì la simulazione colpisce). Il
# disegno sta nella scatola: un'arma lunga tiene la punta sul bordo davanti.
# Solo l'icona dello scambio (il baratto) resta disegnata a vettori qui.
#
# python3 tools/grafica/armi.py   (serve cairosvg: pip install cairosvg)
import os
import re
import sys
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
RADICE = os.path.join(QUI, "..", "..")
OUT = os.path.join(RADICE, "client", "assets", "weapons")
LUA = os.path.join(RADICE, "client", "battle", "weapons.lua")
ATLAS = os.path.join(RADICE, "client", "battle", "weapons.atlas")
PRESE = os.path.join(RADICE, "client", "battle", "grips.lua")
ANTEPRIMA = os.path.join(RADICE, "simulazione", "foto", "armi_anteprima.png")
RICALCO = os.path.join(RADICE, "art", "armi")

# pixel delle immagini per unità del mondo: a zoom vicino su un telefono
# un'unità è 4-5 pixel veri.
PX = 6
ICONA = 128  # lato delle icone, in pixel
GRANDI = 1.6  # i colpi in volo, più grandi delle loro misure

from vettori import BORDO, COL, Disegno, rendi  # noqa: E402

# la punta del lanciarampino, dove sta l'uncino quando è in canna (HOOK_TIP di
# client/battle/scoria.lua)
PUNTA_RAMPINO = 15.2

# Le armi in mano: la scatola (x0, y0, x1, y1) nel mondo. x verso dove si mira, y in
# su. Il punto dove la mano le tiene non è qui: lo dice client/battle/grips.lua, fatto
# nell'editor delle animazioni (l'anteprima lo legge per disegnare il pugno).
ARMI = {
    "missile": (-11.5, -8, 16.5, 6.5),
    "sniper": (-9.5, -6.5, 22, 6.5),
    "grenade": (-0.5, -4.5, 9.5, 11),
    "shards": (-9.5, -7.5, 20.5, 7.5),
    "punch": (-3.5, -7, 13.5, 7),
    "sword": (-5, -7, 42.5, 7),
    "teleport": (-0.5, -4.5, 10.5, 7),
    "eagle": (-4, -8.5, 20.5, 6.5),
    # il lanciarampino senza l'uncino (è un pezzo a sé, vola via quando si spara): la
    # bocca a PUNTA_RAMPINO, la canna a y = 0
    "hook": (-6.0, -6.2, PUNTA_RAMPINO, 2.8),
    "mallet": (-6, -9.16, 46.5, 8.66),
    "lunge": (-9.5, -7.5, 42.5, 7.5),
    "bellows": (-8, -7.5, 20.5, 7.5),
    "boomerang": (-8.5, -4.5, 19.5, 11.5),
    "tar": (-1.5, -4.5, 10, 11),
    "drill": (-11.5, -8, 22.5, 6.5),
    "vortex": (-1.0, -4.5, 10, 9),
    "cannon": (-11.5, -8.5, 16, 6.5),
    "petard": (-1.5, -4.5, 10, 11),
}
# il lanciarampino si taglia dove finisce l'asta (il resto del foglio è l'uncino)
SENZA_PUNTA = {"hook": 0.75}
# pezzi che non si impugnano, grandi come in mano: l'uncino del Rampino (in canna e in
# volo, battle/rope.lua)
PEZZI = {
    "uncino": (-2, -8, 12.5, 8),
}
# i colpi in volo: nome -> (pezzo ricalcato, scatola)
COLPI = {
    "razzo": ("razzo", (-6.5, -4.5, 6.5, 4.5)),
    "palla": ("palla", (-4, -4, 4, 4)),
    "uovo": ("uovo_2", (-5.5, -7.5, 5.5, 7.5)),
    "scheggia": ("scheggia", (-4.5, -3, 5, 3)),
    "globo": ("teleport", (-5, -5, 5, 5)),
    "giano": ("janus", (-5, -5, 5, 5)),
    "falce": ("boomerang", (-6, -6, 6.5, 5)),
    "fiasco": ("tar", (-5.5, -7.5, 5.5, 7.5)),
    "punta": ("drill", (-6, -4.5, 8.5, 4.5)),
    "petardo_volo": ("petard", (-5.0, -5.5, 5.0, 6.5)),
    "voragine_volo": ("vortex", (-5, -5, 5, 5)),
}
# la punta del Trapano in volo è solo il corno: si taglia via l'impugnatura
TAGLIO = {"punta": 0.36}
# le icone dei pulsanti tondi degli oggetti (l'arma in mano non c'è)
ICONE = ["janus", "trap", "shield", "trampoline", "parachute"]


# ---------------------------------------------------------------------------
# L'icona dello scambio (il baratto), l'unica ancora a vettori. Il viola è il colore
# del movimento (teletrasporto e attrezzo, docs/decisioni/interfaccia.md).
COL_ICONE = dict(COL, viola=("#4b2d8a", "#9466ea", "#dcc8ff"))


def scambio(d):
    # scambio del secondo attacco con un teletrasporto: due frecce che si
    # inseguono in cerchio (come il cilindro magico), dal giallo del secondo
    # attacco al viola del teletrasporto
    import math
    r, t = 5.0, 1.9
    for a0, col in ((165, "ottone"), (345, "viola")):
        # la fascia va in senso orario da a0 per 120 gradi, poi la punta
        a1 = a0 - 120
        fuori, dentro = [], []
        for i in range(13):
            a = math.radians(a0 + (a1 - a0) * i / 12)
            fuori.append((round((r + t / 2) * math.cos(a), 2), round((r + t / 2) * math.sin(a), 2)))
            dentro.append((round((r - t / 2) * math.cos(a), 2), round((r - t / 2) * math.sin(a), 2)))
        b = math.radians(a1)
        cb, sb = math.cos(b), math.sin(b)
        # la punta: larga il doppio della fascia, punta 35 gradi più avanti
        p = math.radians(a1 - 35)
        punta = [((r + t * 1.2) * cb, (r + t * 1.2) * sb), (r * math.cos(p), r * math.sin(p)),
                 ((r - t * 1.2) * cb, (r - t * 1.2) * sb)]
        d.poli(fuori + punta + dentro[::-1], col)
    return dict(box=(-7.6, -7.6, 7.6, 7.6))


def icona(nome, d, box, rot, out):
    # il disegno ruotato, adattato al quadrato con un margine
    import math
    x0, y0, x1, y1 = box
    a = math.radians(rot)
    bw, bh = x1 - x0, y1 - y0
    rw = abs(bw * math.cos(a)) + abs(bh * math.sin(a))
    rh = abs(bw * math.sin(a)) + abs(bh * math.cos(a))
    scala = ICONA * 0.9 / max(rw, rh)
    svg = d.svg(box, scala, rot=rot, lato=ICONA)
    # nell'icona il bordo è più spesso: si legge anche piccola
    svg = svg.replace(f'stroke-width="{BORDO * 2}"', f'stroke-width="{BORDO * 2 * max(1, 14 / scala / 1.5)}"')
    im = rendi(svg, ICONA, ICONA)
    tin = None
    if any(t for _, _, t, _ in d.forme):
        tin = rendi(d.svg(box, scala, tinta=True, rot=rot, lato=ICONA), ICONA, ICONA)
    # nell'icona le parti tinte hanno il colore delle primarie (brace)
    if tin:
        brace = Image.new("RGBA", tin.size, (255, 150, 60, 255))
        from PIL import ImageChops
        col = ImageChops.multiply(tin, brace)
        col.putalpha(tin.getchannel("A"))
        im = Image.alpha_composite(im, col)
    im.save(os.path.join(OUT, nome + "_icona.png"), optimize=True)
    out.append(nome + "_icona")
    return im


# ---------------------------------------------------------------------------
# I pezzi ricalcati, alla misura del gioco.
def ricalcato(nome):
    return Image.open(os.path.join(RICALCO, nome + ".png")).convert("RGBA")


def verde(im):
    # le parti del colore della squadra sul foglio: verde pieno e la sua ombra
    import numpy as np
    a = np.array(im).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    pieno = (g > 200) & (r < 110) & (b < 110)
    ombra = (g > 140) & (g <= 200) & (r < 70) & (b < 70)
    return pieno, ombra


def da_ricalco(nome, im, box, px, out, sempre_tinta=True):
    import numpy as np
    w0, h0 = box[2] - box[0], box[3] - box[1]
    # la stessa lunghezza, ma mai più alto di un quarto oltre la forma di prima
    s = min(w0 / im.width, h0 * 1.25 / im.height)
    nw, nh = im.width * s, im.height * s
    cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
    if w0 > 1.6 * h0:
        # arma lunga: la punta resta dov'era (bocca, portata)
        nuovo = (box[2] - nw, cy - nh / 2, box[2], cy + nh / 2)
    else:
        nuovo = (cx - nw / 2, cy - nh / 2, cx + nw / 2, cy + nh / 2)
    W, H = max(1, round(nw * px)), max(1, round(nh * px))
    assert W <= im.width, f"{nome}: il pezzo ricalcato è troppo piccolo ({im.width} < {W})"
    pieno, ombra = verde(im)
    a = np.array(im)
    alfa = a[..., 3]
    # lo strato della squadra c'è sempre per armi e colpi (anche vuoto: il gioco lo
    # chiede a ogni colpo); per i pezzi solo se c'è il verde
    tin = None
    if sempre_tinta or pieno.any() or ombra.any():
        grigio = np.where(pieno, 255, np.where(ombra, 180, 0)).astype(np.uint8)
        t = np.dstack([grigio, grigio, grigio, np.where(pieno | ombra, alfa, 0)]).astype(np.uint8)
        a = a.copy()
        a[pieno | ombra, :3] = 128
        tin = Image.fromarray(t, "RGBA").resize((W, H), Image.LANCZOS)
    base = Image.fromarray(a, "RGBA").resize((W, H), Image.LANCZOS)
    base.save(os.path.join(OUT, nome + ".png"), optimize=True)
    out.append(nome)
    if tin:
        tin.save(os.path.join(OUT, nome + "_tinta.png"), optimize=True)
        out.append(nome + "_tinta")
    return base, tin, W, H, nuovo


def icona_ricalcata(nome, im, out):
    s = ICONA * 0.92 / max(im.width, im.height)
    pic = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    tela = Image.new("RGBA", (ICONA, ICONA), (0, 0, 0, 0))
    tela.alpha_composite(pic, ((ICONA - pic.width) // 2, (ICONA - pic.height) // 2))
    tela.save(os.path.join(OUT, nome + "_icona.png"), optimize=True)
    out.append(nome + "_icona")
    return tela


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith(".png"):
            os.remove(os.path.join(OUT, f))
    immagini = []
    lua = ["-- Made by tools/grafica/armi.py, do not edit by hand.",
           "-- The weapons in world units (shots from their center), x forward and",
           "-- y up. For each one: image (tint: the parts in the team color), center",
           "-- (x, y) and size (w, h). Where the hand holds them: battle/grips.lua.",
           "return {", "\tweapons = {"]
    foglio = []
    prese = impugnature()

    def riga(nome, tinta, box, k=1):
        cx, cy = (box[0] + box[2]) / 2 * k, (box[1] + box[3]) / 2 * k
        t = f'"{nome}_tinta"' if tinta else "nil"
        lua.append(f'\t\t{nome} = {{ img = "{nome}", tint = {t}, x = {cx:.2f}, y = {cy:.2f}, '
                   f'w = {(box[2] - box[0]) * k:.2f}, h = {(box[3] - box[1]) * k:.2f} }},')

    for nome, box in ARMI.items():
        pezzo = ricalcato(nome)
        if nome in SENZA_PUNTA:
            pezzo = pezzo.crop((0, 0, round(pezzo.width * SENZA_PUNTA[nome]), pezzo.height))
        base, tinta, w, h, box = da_ricalco(nome, pezzo, box, PX, immagini)
        ic = icona_ricalcata(nome, ricalcato(nome + "_icona"), immagini)
        riga(nome, tinta, box)
        foglio.append((nome, base, tinta, ic, box, prese.get(nome, [])))
    for nome in ICONE:
        icona_ricalcata(nome, ricalcato(nome + "_icona"), immagini)
    d = Disegno(col=COL_ICONE)
    icona("scambio", d, scambio(d)["box"], 0, immagini)
    lua.append("\t},")
    lua.append("\tpieces = {")
    for nome, box in PEZZI.items():
        base, tinta, w, h, box = da_ricalco(nome, ricalcato(nome), box, PX, immagini, sempre_tinta=False)
        riga(nome, tinta, box)
    lua.append("\t},")
    lua.append("\tshots = {")
    colpi = []
    for nome, (pz, box) in COLPI.items():
        # in volo si disegnano GRANDI volte: piccoli come in mano non si leggono
        pezzo = ricalcato(pz)
        if nome in TAGLIO:
            pezzo = pezzo.crop((round(pezzo.width * TAGLIO[nome]), 0, pezzo.width, pezzo.height))
        base, tinta, w, h, box = da_ricalco(nome, pezzo, box, PX * GRANDI, immagini)
        riga(nome, tinta, box, GRANDI)
        colpi.append((nome, base, tinta))
    lua.append("\t},")
    lua.append("}")
    with open(LUA, "w") as f:
        f.write("\n".join(lua) + "\n")
    with open(ATLAS, "w") as f:
        for n in immagini:
            f.write(f'images {{\n  image: "/assets/weapons/{n}.png"\n}}\n')
        f.write("margin: 0\nextrude_borders: 2\ninner_padding: 0\n")
    anteprima(foglio, colpi)


def impugnature():
    # battle/grips.lua: nome = { grip = { x, y }, ... }, la presa
    with open(PRESE) as f:
        return {n: [(float(x), float(y))] for n, x, y in
                re.findall(r"^\s*(\w+)\s*=\s*\{\s*grip\s*=\s*\{\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\}", f.read(), re.M)}


def tingi(im, rgb):
    from PIL import ImageChops
    col = ImageChops.multiply(im, Image.new("RGBA", im.size, rgb + (255,)))
    col.putalpha(im.getchannel("A"))
    return col


def anteprima(foglio, colpi):
    from PIL import ImageDraw
    squadre = [(230, 72, 77), (47, 191, 113), (245, 197, 24), (75, 107, 251)]
    righe = []
    for i, (nome, base, tinta, ic, box, mani) in enumerate(foglio):
        im = base.copy()
        if tinta:
            im = Image.alpha_composite(im, tingi(tinta, squadre[i % 4]))
        # i pugni, come li mette il gioco (pelle col contorno scuro)
        dr = ImageDraw.Draw(im)
        for x, y in mani:
            px, py = (x - box[0]) * PX, (box[3] - y) * PX
            r = 2.8 * PX * 0.5 * 1.0
            dr.ellipse([px - r - 3, py - r - 3, px + r + 3, py + r + 3], fill=(20, 18, 24, 255))
            dr.ellipse([px - r, py - r, px + r, py + r], fill=(194, 184, 163, 255))
        righe.append((nome, im, ic))
    K = 2
    larg = max(im.width for _, im, _ in righe) * K + ICONA + 60
    alt = sum(max(im.height * K, ICONA) + 16 for _, im, _ in righe) + 220
    sheet = Image.new("RGBA", (larg, alt), (122, 138, 128, 255))
    y = 10
    for nome, im, ic in righe:
        hh = max(im.height * K, ICONA)
        if ic:
            sheet.alpha_composite(ic, (10, y + (hh - ICONA) // 2))
        big = im.resize((im.width * K, im.height * K), Image.LANCZOS)
        sheet.alpha_composite(big, (ICONA + 40, y + (hh - big.height) // 2))
        y += hh + 16
    x = 10
    for i, (nome, base, tinta) in enumerate(colpi):
        im = base.copy()
        if tinta:
            im = Image.alpha_composite(im, tingi(tinta, squadre[i % 4]))
        big = im.resize((im.width * 2, im.height * 2), Image.LANCZOS)
        sheet.alpha_composite(big, (x, y + 10))
        x += big.width + 24
    os.makedirs(os.path.dirname(ANTEPRIMA), exist_ok=True)
    sheet.save(ANTEPRIMA)


if __name__ == "__main__":
    main()
