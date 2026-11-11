# Le mappe dipinte della campagna, dagli SVG alle immagini del gioco (Sergio, 2 nov 2026:
# «partire dall'svg per creare la texture per ogni schermo»).
#
# Scrive, per ogni densità di schermo (1 = normale, 2 = alta, vedi DENSITA):
#   client/paintings/mappe/<mappa>_<d>.png      il terreno disegnato, 1920 x 1080 per d
#   client/paintings/sfondi/<girone>_*_<d>.png  il cielo e i tre gruppi di piani dello sfondo
#   client/battle/paintings.lua              misure e velocità che servono allo shader
#   tools/grafica/mappe/<mappa>.png       la maschera di collisione (bianco terra, rosso
#                                             acciaio), che mappa_in_lua.py porta in sim/mapdata.lua
# Le mappe: il pavimento e la fossa del Fabbro (documento delle mappe dell'apprendista, layout A
# e C, scelte di Sergio del 2 novembre), il cortile del Duello con Favilla (cortile.py) e le
# arene delle missioni, lette da sim/levels.lua con luajit: quelle del cortile dipinte come il
# cortile (cortile.py), le altre d'acciaio.
# I gironi (docs/campagna_gironi.md): una mappa e uno sfondo per girone, nella tinta di temi.py, divisi
# fra i suoi livelli come la Forgia: per ora il Limbo, la Lussuria e la Gola (layout qui sotto, scene
# di tavole.py). Il pericolo di ogni girone sta in client/sim/maps.lua e hazards.lua.
# Gli sfondi: la Forgia (tavole.py) e il cortile (cortile.py), con la stessa tinta.
#
#   python3 tools/grafica/mappe_dipinte.py      (dalla cartella del repository; serve node
#                                                    con playwright, che disegna gli SVG)
import json, os, random, subprocess, sys, tempfile
from PIL import Image, ImageDraw

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
sys.path.insert(0, os.path.join(QUI, "gironi"))
from tavole import FORGIA, LIMBO, LUSSURIA, GOLA               # noqa: E402
from mondo import blocco, scheggia, fungo, arco                # noqa: E402
from scena import acqua                                        # noqa: E402
from volume import forma, solido                               # noqa: E402
from scena import mix, W, H, MARGINE                                    # noqa: E402
from dipinto import piani, raggi, grade, DEFS, GRUPPI          # noqa: E402
from temi import TEMI                                          # noqa: E402
import cortile                                                 # noqa: E402

OUT = os.path.join(RADICE, "client", "paintings")
MASCHERE = os.path.join(QUI, "mappe")
LUA = os.path.join(RADICE, "client", "battle", "paintings.lua")

# quanti pixel dell'immagine per pixel della scena (1280 x 720), per densità e per pezzo:
# i piani lontani sono morbidi e si vedono piccoli, bastano meno pixel. Il terreno è per il
# mondo (1920 x 1080 = scena x 1,5). Nessuna immagine più larga di 4096.
DENSITA = {
    1: dict(terreno=1.0, cielo=0.5, lontano=0.5, medio=0.75, vicino=1.0),
    2: dict(terreno=1.5, cielo=1.0, lontano=1.0, medio=1.2, vicino=1.6),
}
# i piani: quanto seguono la camera (0 fermi, 1 come la mappa) e la velocità dello scorrimento
# «calmo» del documento delle mappe: il piano più vicino a 20 pixel al secondo
QUANTO = dict(lontano=0.1, medio=0.3, vicino=0.6)
CALMO = 20 / 0.75

# ---------------------------------------------------------------- i layout (scena 1280 x 720)
# Una sporgenza per lato fuori dai muri, in pietra come i muri (Sergio, 9 nov): dove ci si salva
# dopo una caduta di lato o un teletrasporto sbagliato; sta nel margine della maschera e del dipinto
SUOLO = [(0, 330), (44, 330), (44, 560), (250, 560), (310, 500), (560, 500), (620, 560), (860, 560), (920, 500),
         (1236, 500), (1236, 330), (1280, 330), 
         (1280, 380), (1398, 380), (1398, 416), (1280, 416), (1280, 760), (0, 760), (0, 416), (-118, 416), (-118, 380), (0, 380)]
SOPRA = [scheggia(110, 300, 130, 50), blocco(300, 180, 90, 28), fungo(380, 330, 180, 26, 170, 22),
         scheggia(590, 250, 110, 44), scheggia(690, 410, 100, 40), blocco(960, 230, 140, 38), arco(960, 370, 230, 130, 30, 40)]
TRAVI = [(400, 140, 140, 16), (740, 330, 130, 16)]
SX = [(0, 330), (44, 330), (44, 560), (250, 560), (310, 500), (560, 500), (620, 560), (680, 560), (680, 760), (0, 760), (0, 416), (-118, 416), (-118, 380), (0, 380)]
DX = [(790, 560), (860, 560), (920, 500), (1236, 500), (1236, 330), (1280, 330), (1280, 380), (1398, 380), (1398, 416), (1280, 416), (1280, 760), (790, 760)]


# ---------------------------------------------------------------- i gironi (scena 1280 x 720)
SPORGE_SX = [(0, 416), (-118, 416), (-118, 380), (0, 380)]
SPORGE_DX = [(1280, 380), (1398, 380), (1398, 416), (1280, 416)]

# I · Limbo, il castello dei sette muri: cortile a gradoni quasi simmetrico, rampe a 45 gradi, tre
# monconi di colonne spezzate sul fondo, rovine e colonne sospese (gravità ridotta: si salta il doppio)
LIMBO_SUOLO = ([(0, 330), (44, 330), (44, 440), (190, 440), (250, 500), (330, 500), (390, 560),
                (470, 560), (470, 520), (510, 520), (510, 560), (610, 560), (610, 500), (670, 500), (670, 560),
                (770, 560), (770, 520), (810, 520), (810, 560),
                (890, 560), (950, 500), (1030, 500), (1090, 440), (1236, 440), (1236, 330), (1280, 330)]
               + SPORGE_DX + [(1280, 760), (0, 760)] + SPORGE_SX)
LIMBO_SOPRA = [fungo(250, 330, 170, 24, 100, 22), fungo(860, 330, 170, 24, 100, 22), scheggia(560, 230, 160, 56),
               blocco(80, 270, 110, 26), blocco(1090, 270, 110, 26), scheggia(420, 410, 110, 40), scheggia(750, 410, 110, 40)]

# II · Lussuria, la bufera: due scogliere a zig-zag con la gola in mezzo (cadere è morire), schegge
# nel vuoto e spuntoni d'acciaio dove aggrapparsi col Rampino
LUSS_SX = ([(0, 330), (44, 330), (44, 420), (150, 420), (210, 480), (300, 480), (340, 540), (430, 540), (470, 580),
            (500, 580), (500, 760), (0, 760)] + SPORGE_SX)
LUSS_DX = ([(780, 760), (780, 610), (810, 610), (850, 570), (940, 570), (980, 520), (1070, 520), (1110, 470), (1236, 470),
            (1236, 330), (1280, 330)] + SPORGE_DX + [(1280, 760)])
LUSS_SOPRA = [scheggia(590, 470, 100, 42), scheggia(580, 330, 120, 46), scheggia(110, 300, 130, 48), scheggia(1050, 300, 130, 48)]
LUSS_SPUNTONI = [[(500, 610), (590, 622), (500, 640)], [(500, 675), (570, 685), (500, 700)],
                 [(780, 640), (700, 652), (780, 668)], [(780, 700), (710, 710), (780, 722)],
                 [(250, 480), (275, 428), (300, 480)], [(1020, 520), (1045, 468), (1070, 520)]]

# III · Gola, la conca di fango: la sporgenza alta a sinistra, tre collinette, due pozze che rallentano
# (stessi numeri in client/sim/maps.lua: mud)
GOLA_SUOLO = ([(0, 330), (44, 330), (44, 380), (250, 380), (330, 470), (400, 470), (440, 530), (540, 530), (580, 490),
               (700, 490), (740, 530), (840, 530), (880, 490), (930, 490), (1010, 490), (1060, 440), (1236, 440),
               (1236, 330), (1280, 330)] + SPORGE_DX + [(1280, 760), (0, 760)] + SPORGE_SX)
GOLA_SOPRA = [scheggia(540, 330, 150, 52), blocco(950, 290, 130, 30), scheggia(330, 270, 110, 42), blocco(1100, 240, 100, 26)]
GOLA_POZZE = [(440, 530, 100), (740, 530, 100)]        # x, y della superficie, larghezza


def pozze(r):
    """Fango scuro con un velo lucido, nelle pozze della Gola."""
    s = ""
    for x, y, w in GOLA_POZZE:
        s += ('<rect x="%g" y="%g" width="%g" height="14" rx="6" fill="#3b3623"/><rect x="%g" y="%g" width="%g" height="4" rx="2" fill="#8d8a5e" opacity=".7"/>'
              % (x, y - 4, w, x + 8, y - 2, w - 16))
        for k in range(1, 5):
            s += '<ellipse cx="%g" cy="%g" rx="7" ry="2.5" fill="#6e6a43" opacity=".55"/>' % (x + k * w / 5 + (k % 2) * 4, y + 3)
    return s


def spuntoni(g, P):
    """I spuntoni d'acciaio (indistruttibili) di una mappa, disegnati come il ferro del cortile."""
    m = {k: (grade(v, "materiale", P) if isinstance(v, str) and v.startswith("#") and len(v) == 7 else v) for k, v in g["mat"].items()}
    ferro = dict(m, corpo=mix(m["acciaio"], "#000000", .25), crosta=mix(m["acciaio"], m["acciaio_luce"], .35), motivo="venature")
    return solido(g["acciaio"], ferro, dict(g, ombra=0), random.Random(3))

def lava(r):
    return ('<defs><linearGradient id="lava" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffc24a"/>'
            '<stop offset=".18" stop-color="#ff6a1f"/><stop offset="1" stop-color="#b8321a"/></linearGradient>'
            '<radialGradient id="lavaluce" cx=".5" cy="1" r=".6"><stop offset="0" stop-color="#ff7a1f" stop-opacity=".55"/>'
            '<stop offset="1" stop-color="#ff7a1f" stop-opacity="0"/></radialGradient></defs>'
            '<rect x="600" y="470" width="280" height="200" fill="url(#lavaluce)"/>'
            '<rect x="676" y="646" width="118" height="120" fill="url(#lava)"/>'
            + "".join('<polygon points="%d,%d %d,%d %d,%d" fill="#ffd27a" opacity=".8"/>'
                      % (x, 660 + (x * 7) % 30, x + 14, 656 + (x * 7) % 30, x + 26, 662 + (x * 7) % 30) for x in range(690, 780, 34)))


MAPPE = {
    "pavimento": dict(FORGIA, isole=[SUOLO] + SOPRA, travi=TRAVI),
    "fossa": dict(FORGIA, isole=[SX, DX] + SOPRA, travi=TRAVI, sotto=lava),
    "limbo": dict(LIMBO, isole=[LIMBO_SUOLO] + LIMBO_SOPRA, travi=[(250, 190, 110, 14), (920, 190, 110, 14)]),
    "lussuria": dict(LUSSURIA, isole=[LUSS_SX, LUSS_DX] + LUSS_SOPRA, travi=[], sopra=None, acciaio=LUSS_SPUNTONI),
    "gola": dict(GOLA, isole=[GOLA_SUOLO] + GOLA_SOPRA, travi=[(700, 420, 100, 16)], sopra=pozze),
}
# il tema (temi.py) di ogni mappa dei gironi: colori dello sfondo e del terreno; le altre hanno quello della Forgia
TEMA = {"limbo": "limbo", "lussuria": "lussuria", "gola": "gola"}
# le mappe disegnate a parte, col loro sfondo: terreno svg e maschera
ALTRE = {"cortile": (cortile.mappa, cortile.maschera, "cortile")}


# ---------------------------------------------------------------- le arene, tutte d'acciaio
def arene():
    """{id missione: [(x, y, w, h)]} in coordinate del mondo (y verso l'alto), da sim/levels.lua."""
    lua = ('package.path="client/?.lua;"..package.path local c=require("sim.campaign") '
           'for _,cap in ipairs(c.CAPITOLI) do for _,l in ipairs(cap.missioni) do if l.arena then '
           'local t={} for _,q in ipairs(l.arena) do t[#t+1]=string.format("[%g,%g,%g,%g]",q[1],q[2],q[3],q[4]) end '
           'print(l.id.." ["..table.concat(t,",").."]") end end end')
    out = subprocess.run(["luajit", "-e", lua], cwd=RADICE, capture_output=True, text=True, check=True).stdout
    return {r.split(" ", 1)[0]: json.loads(r.split(" ", 1)[1]) for r in out.strip().splitlines()}


def acciaio(x, y, w, h, m):
    """Un blocco d'acciaio nel mondo (SVG, y verso il basso): lamiera con la luce in alto, bordo scuro
    ma non nero, giunti con i bulloni, tratteggio in basso. Lo stesso acciaio delle travi."""
    gid = "acc%d_%d" % (x, y)
    corpo, luce, bordo = mix(m["acciaio"], "#000000", .22), m["acciaio_luce"], m["bordo"]
    # la luce solo nei primi 160 pixel, poi la lamiera scura: nelle arene i blocchi sono
    # grandi e chiari a tutta altezza rubavano l'occhio al personaggio (regola delle mappe)
    s = ['<defs><linearGradient id="%s" gradientUnits="userSpaceOnUse" x1="0" y1="%g" x2="0" y2="%g">'
         '<stop offset="0" stop-color="%s"/><stop offset=".3" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs>'
         % (gid, y, y + min(h, 160), mix(corpo, luce, .2), corpo, mix(corpo, "#000000", .45))]
    s.append('<rect x="%g" y="%g" width="%g" height="%g" fill="url(#%s)" stroke="%s" stroke-width="4"/>' % (x, y, w, h, gid, bordo))
    s.append('<rect x="%g" y="%g" width="%g" height="%g" fill="url(#tratteggio)" mask="url(#basso)"/>' % (x, y, w, h))
    s.append('<rect x="%g" y="%g" width="%g" height="4" fill="%s"/>' % (x + 3, y + 3, w - 6, luce))
    r, passo = 3.6, 48
    if h < 60:
        file = [y + h / 2 + 2]
    else:
        file = [y + 16, y + h - 14]
        # giunti fra le lastre, con una fila di bulloni da una parte e dall'altra
        n = max(1, round(w / 220))
        for i in range(1, n):
            gx = x + w * i / n
            s.append('<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="3"/>' % (gx, y + 6, gx, y + h - 3, bordo))
            s.append('<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="1.5" opacity=".5"/>' % (gx + 3, y + 8, gx + 3, y + h - 4, luce))
            for yy in range(int(y + 40), int(y + h - 30), passo):
                s.append('<circle cx="%g" cy="%g" r="%g" fill="%s"/>' % (gx - 12, yy, r, luce))
                s.append('<circle cx="%g" cy="%g" r="%g" fill="%s"/>' % (gx + 14, yy, r, luce))
    for fy in file:
        xx = x + 18
        while xx < x + w - 12:
            s.append('<circle cx="%g" cy="%g" r="%g" fill="%s"/><circle cx="%g" cy="%g" r="%g" fill="%s" opacity=".55"/>'
                     % (xx, fy + 1.4, r, bordo, xx, fy, r, luce))
            xx += passo
    return "".join(s)


# ---------------------------------------------------------------- disegno con il browser
RENDI = r"""
const {chromium} = require('playwright'); const fs = require('fs');
(async () => {
  const lavori = JSON.parse(fs.readFileSync(process.argv[2]));
  const b = await chromium.launch(); const p = await b.newPage();
  for (const l of lavori) {
    await p.setViewportSize({width: l.w, height: l.h});
    await p.setContent('<html><body style="margin:0;background:transparent">' + fs.readFileSync(l.svg, 'utf8') + '</body></html>');
    await p.screenshot({path: l.png, omitBackground: true, clip: {x: 0, y: 0, width: l.w, height: l.h}});
  }
  await b.close();
})();
"""


def svg(contenuto, vb, w, h):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%s" preserveAspectRatio="none" style="display:block">%s%s</svg>'
            % (w, h, " ".join("%g" % v for v in vb), DEFS, contenuto))


def rendi(lavori, tmp):
    js = os.path.join(tmp, "rendi.js")
    open(js, "w").write(RENDI)
    lista = []
    for i, (contenuto, png, w, h) in enumerate(lavori):
        f = os.path.join(tmp, "l%d.svg" % i)
        open(f, "w").write(contenuto)
        lista.append(dict(svg=f, png=png, w=w, h=h))
    open(os.path.join(tmp, "lavori.json"), "w").write(json.dumps(lista))
    # i moduli di Node si cercano anche fra quelli globali (npm root -g), così
    # basta un `npm install -g` dei pacchetti che servono; NODE_PATH, se c'è, viene prima
    env = os.environ.copy()
    try:
        globale = subprocess.run(["npm", "root", "-g"], capture_output=True, text=True, shell=os.name == "nt").stdout.strip()
    except OSError:
        globale = ""
    percorsi = [p for p in [env.get("NODE_PATH", ""), globale] if p and os.path.isdir(p)]
    if percorsi:
        env["NODE_PATH"] = os.pathsep.join(percorsi)
    subprocess.run(["node", js, os.path.join(tmp, "lavori.json")], env=env, check=True)


def maschera(g, nome, disegna=None):
    """760 x 360 celle (scena x 0,5, più il margine per lato): bianco la terra, rosso l'acciaio."""
    im = Image.new("RGB", (640 + MARGINE, 360), "black")
    o = MARGINE * .5
    if disegna:
        disegna(im)
    else:
        d = ImageDraw.Draw(im)
        for p in forma(g["isole"], g.get("stile")):
            d.polygon([(x * .5 + o, y * .5) for x, y in p], fill="white")
        for x, y, w, h in g.get("travi", []):
            d.rectangle([x * .5 + o, y * .5, (x + w) * .5 + o - 1, (y + h) * .5 - 1], fill="red")
        for p in g.get("acciaio", []):
            d.polygon([(x * .5 + o, y * .5) for x, y in p], fill="red")
    os.makedirs(MASCHERE, exist_ok=True)
    im.save(os.path.join(MASCHERE, nome + ".png"))


def sfondi():
    """{nome: (cielo svg, [(gruppo, svg largo un giro, velocità media)], scorre, scena, tema)}. Il cortile non
    scorre da solo: si muove solo con la camera (un muro che scivola di lato sembra strano)."""
    P = TEMI["forgia"]
    p = piani(FORGIA, P)
    c = cortile.sfondo()
    cielo_c = piani(dict(FORGIA, luce=c["luce"], piani=[], isole=[], travi=[]), P)["cielo"]
    out = {"forgia": (p["cielo"], p["gruppi"], True, FORGIA, P), "cortile": (cielo_c, c["gruppi"], False, FORGIA, P)}
    for nome, tema in TEMA.items():
        q = piani(MAPPE[nome], TEMI[tema])
        out[tema] = (q["cielo"], q["gruppi"], True, MAPPE[nome], TEMI[tema])
    return out


def main():
    P = TEMI["forgia"]
    for sotto in ("maps", "backgrounds"):
        os.makedirs(os.path.join(OUT, sotto), exist_ok=True)
        for f in os.listdir(os.path.join(OUT, sotto)):
            os.remove(os.path.join(OUT, sotto, f))
    lavori, strisce = [], []
    # gli sfondi: il cielo (fermo, con il bagliore e i raggi) e i tre gruppi di piani
    SF = sfondi()
    for sf, (cielo, gruppi, scorre, scena, tema) in SF.items():
        for d, k in DENSITA.items():
            lavori.append((svg(cielo + '<g style="mix-blend-mode:screen">%s</g>' % raggi(scena, tema), (0, 0, W, H),
                               round(W * k["cielo"]), round(H * k["cielo"])),
                           os.path.join(OUT, "backgrounds", "%s_cielo_%d.png" % (sf, d)), round(W * k["cielo"]), round(H * k["cielo"])))
            for nome, contenuto, vel in gruppi:
                w = min(4096, round(2560 * k[nome]))
                lavori.append((svg(contenuto, (0, 0, 2560, H), w, round(H * w / 2560)),
                               os.path.join(OUT, "backgrounds", "%s_%s_%d.png" % (sf, nome, d)), w, round(H * w / 2560)))
        for nome, contenuto, vel in gruppi:
            strisce.append((sf, nome, vel if scorre else 0))
    sfondo_di = {}
    # il terreno delle mappe dipinte
    for nome, g in MAPPE.items():
        maschera(g, nome)
        sfondo_di[nome] = TEMA.get(nome, "forgia")
        Pm = TEMI[sfondo_di[nome]]
        gioco = piani(g, Pm)["gioco"] + (spuntoni(g, Pm) if g.get("acciaio") else "")
        for d, k in DENSITA.items():
            w, h = round((1920 + 3 * MARGINE) * k["terreno"]), round(1080 * k["terreno"])
            lavori.append((svg(gioco, (-MARGINE, 0, W + 2 * MARGINE, H), w, h), os.path.join(OUT, "maps", "%s_%d.png" % (nome, d)), w, h))
    for nome, (disegno, collisione, sf) in ALTRE.items():
        maschera(None, nome, collisione)
        sfondo_di[nome] = sf
        gioco = disegno()
        for d, k in DENSITA.items():
            w, h = round((1920 + 3 * MARGINE) * k["terreno"]), round(1080 * k["terreno"])
            lavori.append((svg(gioco, (-MARGINE, 0, W + 2 * MARGINE, H), w, h), os.path.join(OUT, "maps", "%s_%d.png" % (nome, d)), w, h))
    # le arene delle missioni: il cortile dipinto, le altre d'acciaio, in coordinate del mondo
    m = {c: grade(v, "materiale", P) for c, v in FORGIA["mat"].items() if isinstance(v, str) and v.startswith("#")}
    for mid, rett in arene().items():
        if mid in cortile.LEZIONI:
            corpo, vb, sfondo_di["missione_" + mid] = cortile.lezione(mid, rett), (-MARGINE, 0, W + 2 * MARGINE, H), "cortile"
        else:
            corpo = "".join(acciaio(x, 1080 - y - h, w, h, m) for x, y, w, h in rett)
            vb, sfondo_di["missione_" + mid] = (-1.5 * MARGINE, 0, 1920 + 3 * MARGINE, 1080), "forgia"
        for d, k in DENSITA.items():
            w, h = round((1920 + 3 * MARGINE) * k["terreno"]), round(1080 * k["terreno"])
            lavori.append((svg(corpo, vb, w, h), os.path.join(OUT, "maps", "missione_%s_%d.png" % (mid, d)), w, h))
    with tempfile.TemporaryDirectory() as tmp:
        rendi(lavori, tmp)
    # i gruppi dello sfondo: si tiene solo la fascia che ha qualcosa (misure nella scena)
    fasce = {}
    for sf, nome, vel in strisce:
        y0s, y1s = [], []
        for d in DENSITA:
            im = Image.open(os.path.join(OUT, "backgrounds", "%s_%s_%d.png" % (sf, nome, d)))
            box = im.getchannel("A").getbbox()
            sc = im.width / 2560
            y0s.append(box[1] / sc)
            y1s.append(box[3] / sc)
        y0, y1 = max(0, int(min(y0s)) - 2), min(H, int(max(y1s)) + 3)
        for d in DENSITA:
            f = os.path.join(OUT, "backgrounds", "%s_%s_%d.png" % (sf, nome, d))
            im = Image.open(f)
            sc = im.width / 2560
            im.crop((0, round(y0 * sc), im.width, round(y1 * sc))).save(f, optimize=True)
        fasce[sf, nome] = (y0, y1 - y0, vel)
    # i numeri per lo shader
    righe = ["-- Made by tools/grafica/mappe_dipinte.py, do not edit by hand.",
             "-- The painted images (client/paintings, one per screen density) and the background",
             "-- numbers: for each group of planes where it sits in the 1280 x 720 scene (y0 from",
             "-- the top, h), how much it follows the camera (parallax) and how many scene pixels",
             "-- it scrolls per second.",
             "return {",
             "\tdensities = { %s }," % ", ".join(str(d) for d in DENSITA),
             "\twrap = 2560,",
             "\tbackgrounds = {"]
    for sf in SF:
        righe += ["\t\t%s = {" % sf,
                  "\t\t\thaze = { %s }," % ", ".join("%.3f" % (v / 255) for v in Image.new("RGB", (1, 1), SF[sf][4]["foschia"]).getpixel((0, 0))),
                  "\t\t\tgroups = {"]
        for nome, _, _ in GRUPPI:
            y0, h, vel = fasce[sf, nome]
            righe.append('\t\t\t\t{ name = "%s", y0 = %d, h = %d, parallax = %g, scroll = %.1f },'
                         % (nome, y0, h, QUANTO[nome], CALMO * vel))
        righe += ["\t\t\t},", "\t\t},"]
    righe += ["\t},",
              "\t-- the maps with painted terrain and their background",
              "\tmaps = {"]
    for nome, sf in sfondo_di.items():
        righe.append('\t\t%s = "%s",' % (nome, sf))
    righe += ["\t},", "}", ""]
    open(LUA, "w").write("\n".join(righe))
    print("fatto:", len(lavori), "immagini")
    # le miniature delle missioni della CAMPAGNA si rifanno dai dipinti nuovi
    import miniature_missioni
    miniature_missioni.main()


if __name__ == "__main__":
    main()
