# Le mappe dipinte della campagna, dagli SVG alle immagini del gioco (Sergio, 2 nov 2026:
# «partire dall'svg per creare la texture per ogni schermo»).
#
# Scrive, per ogni densità di schermo (1 = normale, 2 = alta, vedi DENSITA):
#   client/dipinti/mappe/<mappa>_<d>.png      il terreno disegnato, 1920 x 1080 per d
#   client/dipinti/sfondi/<girone>_*_<d>.png  il cielo e i tre gruppi di piani dello sfondo
#   client/dipinti/<mappa>_<d>.collection     una collezione per immagine (o per sfondo), che il
#                                             gioco carica solo quando serve (non compresse,
#                                             profilo Mappa di texture_profiles)
#   client/battaglia/dipinti.collection       le collection factory che le caricano
#   client/battaglia/dipinti.lua              misure e velocità che servono allo shader
#   strumenti/grafica/mappe/<mappa>.png       la maschera di collisione (bianco terra, rosso
#                                             acciaio), che mappa_in_lua.py porta in sim/mapdata.lua
# Le mappe: il pavimento e la fossa del Fabbro (documento delle mappe dell'apprendista, layout A
# e C, scelte di Sergio del 2 novembre) e le arene delle missioni, tutte d'acciaio, lette da
# sim/campaign.lua con luajit.
#
#   python3 strumenti/grafica/mappe_dipinte.py      (dalla cartella del repository; serve node
#                                                    con playwright, che disegna gli SVG)
import json, os, subprocess, sys, tempfile
from PIL import Image, ImageDraw

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
sys.path.insert(0, os.path.join(QUI, "gironi"))
from tavole import FORGIA                                      # noqa: E402
from mondo import blocco, scheggia, fungo, arco                # noqa: E402
from volume import forma                                       # noqa: E402
from scena import mix, W, H                                    # noqa: E402
from dipinto import piani, raggi, grade, DEFS, GRUPPI          # noqa: E402
from temi import TEMI                                          # noqa: E402

OUT = os.path.join(RADICE, "client", "dipinti")
MASCHERE = os.path.join(QUI, "mappe")
LUA = os.path.join(RADICE, "client", "battaglia", "dipinti.lua")

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
SUOLO = [(0, 330), (44, 330), (44, 560), (250, 560), (310, 500), (560, 500), (620, 560), (860, 560), (920, 500),
         (1236, 500), (1236, 330), (1280, 330), (1280, 760), (0, 760)]
SOPRA = [scheggia(110, 300, 130, 50), blocco(300, 180, 90, 28), fungo(380, 330, 180, 26, 170, 22),
         scheggia(590, 250, 110, 44), scheggia(690, 410, 100, 40), blocco(960, 230, 140, 38), arco(960, 370, 230, 130, 30, 40)]
TRAVI = [(400, 140, 140, 16), (740, 330, 130, 16)]
SX = [(0, 330), (44, 330), (44, 560), (250, 560), (310, 500), (560, 500), (620, 560), (680, 560), (680, 760), (0, 760)]
DX = [(790, 560), (860, 560), (920, 500), (1236, 500), (1236, 330), (1280, 330), (1280, 760), (790, 760)]


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
}


# ---------------------------------------------------------------- le arene, tutte d'acciaio
def arene():
    """{id missione: [(x, y, w, h)]} in coordinate del mondo (y verso l'alto), da sim/campaign.lua."""
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
    subprocess.run(["node", js, os.path.join(tmp, "lavori.json")], check=True)


def maschera(g, nome):
    """640 x 360 celle (scena x 0,5): bianco la terra, rosso l'acciaio."""
    im = Image.new("RGB", (640, 360), "black")
    d = ImageDraw.Draw(im)
    for p in forma(g["isole"], g.get("stile")):
        d.polygon([(x * .5, y * .5) for x, y in p], fill="white")
    for x, y, w, h in g.get("travi", []):
        d.rectangle([x * .5, y * .5, (x + w) * .5 - 1, (y + h) * .5 - 1], fill="red")
    os.makedirs(MASCHERE, exist_ok=True)
    im.save(os.path.join(MASCHERE, nome + ".png"))


# ---------------------------------------------------------------- le risorse di Defold
def collezione(nome, oggetto, righe):
    """Il testo di una collezione con un solo oggetto incorporato (righe: il suo .go)."""
    dati = "".join('  "%s\\n"\n' % r.replace('\\', '\\\\').replace('"', '\\"') for r in righe)
    return ('name: "%s"\nscale_along_z: 0\nembedded_instances {\n  id: "%s"\n  data: %s  ""\n'
            '  position {\n    x: 0.0\n    y: 0.0\n    z: 0.0\n  }\n'
            '  rotation {\n    x: 0.0\n    y: 0.0\n    z: 0.0\n    w: 1.0\n  }\n'
            '  scale3 {\n    x: 1.0\n    y: 1.0\n    z: 1.0\n  }\n}\n') % (nome, oggetto, dati.lstrip())


def scrivi_collezione(nome, script, proprieta):
    """Una collezione con un oggetto e lo script che manda al terreno le sue texture."""
    comp = ['components {', '  id: "dipinto"', '  component: "%s"' % script]
    for chi, png in [("nome", nome)] + proprieta:
        comp += ['  properties {', '    id: "%s"' % chi, '    value: "%s"' % png, '    type: PROPERTY_TYPE_HASH', '  }']
    comp.append('}')
    open(os.path.join(OUT, nome + ".collection"), "w").write(collezione(nome, "dipinto", comp))


def collezioni(mappe):
    """Una collezione per ogni immagine del terreno e per ogni sfondo, a ogni densità, e la
    collezione con le collection factory a caricamento dinamico: il gioco ne tiene in memoria solo una per tipo."""
    for f in os.listdir(OUT):
        if f.endswith(".collection"):
            os.remove(os.path.join(OUT, f))
    fabbriche = []
    for d in DENSITA:
        for m in mappe:
            nome = "%s_%d" % (m, d)
            scrivi_collezione(nome, "/dipinti/terreno.script", [("terreno", "/dipinti/mappe/%s.png" % nome)])
            fabbriche.append(nome)
        nome = "forgia_%d" % d
        scrivi_collezione(nome, "/dipinti/sfondo.script",
                          [(p, "/dipinti/sfondi/forgia_%s_%d.png" % (p, d)) for p in ("cielo", "lontano", "medio", "vicino")])
        fabbriche.append(nome)
    # una collezione e non un .go: go vet leggerebbe un .go come codice Go
    righe = []
    for nome in fabbriche:
        righe += ['embedded_components {', '  id: "%s"' % nome, '  type: "collectionfactory"',
                  '  data: "prototype: \\"/dipinti/%s.collection\\"\\n"' % nome, '  "load_dynamically: true\\n"',
                  '  ""', '}']
    open(os.path.join(RADICE, "client", "battaglia", "dipinti.collection"), "w").write(
        collezione("dipinti", "fabbriche", righe))


def main():
    P = TEMI["forgia"]
    for sotto in ("mappe", "sfondi"):
        os.makedirs(os.path.join(OUT, sotto), exist_ok=True)
        for f in os.listdir(os.path.join(OUT, sotto)):
            os.remove(os.path.join(OUT, sotto, f))
    lavori, strisce = [], []
    # lo sfondo della Forgia: il cielo (fermo, con il bagliore e i raggi) e i tre gruppi di piani
    p = piani(FORGIA, P)
    for d, k in DENSITA.items():
        lavori.append((svg(p["cielo"] + '<g style="mix-blend-mode:screen">%s</g>' % raggi(FORGIA, P), (0, 0, W, H),
                           round(W * k["cielo"]), round(H * k["cielo"])),
                       os.path.join(OUT, "sfondi", "forgia_cielo_%d.png" % d), round(W * k["cielo"]), round(H * k["cielo"])))
        for nome, contenuto, vel in p["gruppi"]:
            w = min(4096, round(2560 * k[nome]))
            lavori.append((svg(contenuto, (0, 0, 2560, H), w, round(H * w / 2560)),
                           os.path.join(OUT, "sfondi", "forgia_%s_%d.png" % (nome, d)), w, round(H * w / 2560)))
    for nome, contenuto, vel in p["gruppi"]:
        strisce.append((nome, vel))
    # il terreno delle mappe dipinte
    for nome, g in MAPPE.items():
        maschera(g, nome)
        gioco = piani(g, P)["gioco"]
        for d, k in DENSITA.items():
            w, h = round(1920 * k["terreno"]), round(1080 * k["terreno"])
            lavori.append((svg(gioco, (0, 0, W, H), w, h), os.path.join(OUT, "mappe", "%s_%d.png" % (nome, d)), w, h))
    # le arene delle missioni: acciaio, in coordinate del mondo
    m = {c: grade(v, "materiale", P) for c, v in FORGIA["mat"].items() if isinstance(v, str) and v.startswith("#")}
    for mid, rett in arene().items():
        corpo = "".join(acciaio(x, 1080 - y - h, w, h, m) for x, y, w, h in rett)
        for d, k in DENSITA.items():
            w, h = round(1920 * k["terreno"]), round(1080 * k["terreno"])
            lavori.append((svg(corpo, (0, 0, 1920, 1080), w, h), os.path.join(OUT, "mappe", "missione_%s_%d.png" % (mid, d)), w, h))
    with tempfile.TemporaryDirectory() as tmp:
        rendi(lavori, tmp)
    # i gruppi dello sfondo: si tiene solo la fascia che ha qualcosa (misure nella scena)
    fasce = {}
    for nome, vel in strisce:
        y0s, y1s = [], []
        for d in DENSITA:
            f = os.path.join(OUT, "sfondi", "forgia_%s_%d.png" % (nome, d))
            im = Image.open(f)
            box = im.getchannel("A").getbbox()
            sc = im.width / 2560
            y0s.append(box[1] / sc)
            y1s.append(box[3] / sc)
        y0, y1 = max(0, int(min(y0s)) - 2), min(H, int(max(y1s)) + 3)
        for d in DENSITA:
            f = os.path.join(OUT, "sfondi", "forgia_%s_%d.png" % (nome, d))
            im = Image.open(f)
            sc = im.width / 2560
            im.crop((0, round(y0 * sc), im.width, round(y1 * sc))).save(f, optimize=True)
        fasce[nome] = (y0, y1 - y0, vel)
    # i numeri per lo shader
    righe = ["-- Fatto da strumenti/grafica/mappe_dipinte.py, non modificare a mano.",
             "-- Le immagini dipinte (client/dipinti, una per densità dello schermo) e i numeri dello",
             "-- sfondo: per ogni gruppo di piani dove sta nella scena di 1280 x 720 (y0 dall'alto, h),",
             "-- quanto segue la camera e quanti pixel della scena scorre al secondo.",
             "return {",
             "\tdensita = { %s }," % ", ".join(str(d) for d in DENSITA),
             "\tgiro = 2560,",
             "\tsfondi = {",
             "\t\tforgia = {",
             "\t\t\tfoschia = { %s }," % ", ".join("%.3f" % (v / 255) for v in Image.new("RGB", (1, 1), P["foschia"]).getpixel((0, 0))),
             "\t\t\tgruppi = {"]
    for nome, _, _ in GRUPPI:
        y0, h, vel = fasce[nome]
        righe.append('\t\t\t\t{ nome = "%s", y0 = %d, h = %d, quanto = %g, scorre = %.1f },'
                     % (nome, y0, h, QUANTO[nome], CALMO * vel))
    righe += ["\t\t\t},", "\t\t},", "\t},",
              "\t-- le mappe con il terreno dipinto e il loro sfondo",
              "\tmappe = {"]
    for nome in MAPPE:
        righe.append('\t\t%s = "forgia",' % nome)
    for mid in arene():
        righe.append('\t\tmissione_%s = "forgia",' % mid)
    righe += ["\t},", "}", ""]
    open(LUA, "w").write("\n".join(righe))
    collezioni(list(MAPPE) + ["missione_" + mid for mid in arene()])
    print("fatto:", len(lavori), "immagini")


if __name__ == "__main__":
    main()
