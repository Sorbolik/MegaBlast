# Le miniature delle missioni della CAMPAGNA (Sergio, 6 nov: al posto delle illustrazioni
# dipinte, una rappresentazione minimale della mappa vera del livello, coi suoi colori).
# Per ogni missione di client/sim/campaign.lua:
#   terreno = la forma delle collisioni del livello (la griglia del gioco), lisciata e riempita
#             coi colori del suo terreno dipinto ridotti a 6 macchie piatte, col filo chiaro
#             sulle superfici dove si cammina
#   lava    = i pixel di lava del terreno dipinto, un arancio piatto
#   sfondo  = il cielo ridotto a 5 colori e i piani lontani (parallasse sotto 0,5) come sagome
#             appena sfocate, ognuno coi suoi 5 colori (Sergio, 6 nov: più sfocato il castello
#             del cortile era «un ammasso di colori a caso»)
# Le arene piccole delle lezioni si avvicinano (ritaglio sulla loro forma), le mappe intere
# restano intere. Ogni missione ha la sua miniatura in client/paintings/missions/:
#   <id>.jpg         la cartolina prima della missione (client/ui/postcard.lua)
#   <id>_carta.jpg   la carta sulla bacheca della CAMPAGNA (client/menu/campaign.lua)
#   <id>_finale.jpg  la striscia del finale del capitolo (solo l'ultima missione)
# Si rifà da sola alla fine di mappe_dipinte.py (quando si ridipinge); se cambia una mappa
# o un'arena senza ridipingere, il controllo veloce (tutti.sh, --controlla) dice di rilanciarla.
#
#   python3 strumenti/grafica/miniature_missioni.py               (dalla cartella del repository)
#   python3 strumenti/grafica/miniature_missioni.py --controlla    (solo il controllo)
import hashlib, json, os, subprocess, sys
# il controllo (--controlla) gira anche dove non ci sono numpy e Pillow (GitHub)
if "--controlla" not in sys.argv:
    import numpy as np
    from PIL import Image, ImageFilter

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
DIPINTI = os.path.join(RADICE, "client", "paintings")
OUT = os.path.join(DIPINTI, "missions")

# la scena si disegna a 1920 x 1080 (il mondo, 3 pixel per cella della griglia 640 x 360)
SW, SH, CELLA = 1920, 1080, 3
SCENA_W, SCENA_H = 1280, 720
# le misure nel gioco (al doppio, per gli schermi grandi): la cartolina 880 x 495
# (ui/postcard.lua POST), la finestra della carta 260 x 135 e quella del finale 340 x 66
# (menu/campaign.lua)
FORMATI = {"": (1760, 990), "_carta": (520, 270), "_finale": (680, 132)}
LAVA = (255, 122, 42)
# quello che conta è la forma del livello (Sergio, 6 nov): lo sfondo sta dietro un velo
# scuro (VELO, da 0 a 1), il terreno ha un bordo scuro tutto intorno e il filo chiaro
# sulle superfici, spesso FILO pixel della scena e acceso (FILO_LUCE, da 0 a 1)
VELO, VELO_COL = 0.5, (24, 20, 30)
BORDO = 6
FILO, FILO_LUCE = 9, 0.8

LUA = r"""
package.path = "client/?.lua;" .. package.path
local campaign = require "sim.campaign"
require "sim.missions"
local maps = require "sim.maps"
local terrain = require "sim.terrain"
local dipinti = require "battle.paintings"
local function q(s) return string.format("%q", s) end
local out = {}
for _, cap in ipairs(campaign.CAPITOLI) do
  for i, l in ipairs(cap.missioni) do
    local id = l.mappa or ("missione_" .. l.id)
    local t = terrain.new(640, 360, 3)
    maps.get(id).build(t)
    local rows = {}
    for cy = 359, 0, -1 do
      local r = {}
      for cx = 0, 639 do r[#r + 1] = t:get(cx, cy) > 0 and "1" or "0" end
      rows[#rows + 1] = q(table.concat(r))
    end
    local bg = dipinti.maps[id]
    local groups = {}
    for _, g in ipairs(bg and dipinti.backgrounds[bg].groups or {}) do
      groups[#groups + 1] = string.format('{"name":%s,"y0":%d,"h":%d,"parallax":%s}', q(g.name), g.y0, g.h, g.parallax)
    end
    out[#out + 1] = string.format('{"id":%s,"mappa":%s,"sfondo":%s,"finale":%s,"gruppi":[%s],"rows":[%s]}',
      q(l.id), q(id), bg and q(bg) or "null", tostring(i == #cap.missioni and #cap.missioni > 1),
      table.concat(groups, ","), table.concat(rows, ","))
  end
end
print("[" .. table.concat(out, ",") .. "]")
"""


def leggi():
    out = subprocess.run(["luajit", "-e", LUA], cwd=RADICE, capture_output=True, text=True, check=True).stdout
    return json.loads(out)


def media(img):
    a = np.asarray(img.convert("RGBA"), dtype=float)
    w = a[..., 3] / 255
    s = w.sum() or 1
    return tuple(int((a[..., i] * w).sum() / s) for i in range(3))


def semplifica(alpha, raggio, soglia=0.5):
    # sfoca e taglia: via i dettagli, resta la sagoma, coi bordi lisci
    a = np.asarray(alpha.filter(ImageFilter.GaussianBlur(raggio)), dtype=float) / 255
    a = np.clip((a - soglia) * 6 + 0.5, 0, 1)
    return Image.fromarray((a * 255).astype(np.uint8))


def piatto(col, mask):
    lay = Image.new("RGBA", mask.size, col + (255,))
    lay.putalpha(mask)
    return lay


def poster(img, raggio, n):
    # i colori veri del dipinto ridotti a n macchie piatte: sfocato, poi sulla sua tavolozza
    rgb = img.convert("RGB").filter(ImageFilter.GaussianBlur(raggio))
    q = rgb.quantize(colors=n, method=Image.Quantize.MEDIANCUT).convert("RGB")
    return q.filter(ImageFilter.ModeFilter(5))


def mischia(c, d, k):
    return tuple(int(c[i] * (1 - k) + d[i] * k) for i in range(3))


def scena(m):
    """La scena intera a 1920 x 1080 e la griglia delle celle piene."""
    sfondo = m["sfondo"]
    if sfondo:
        cielo = Image.open(os.path.join(DIPINTI, "backgrounds", "%s_cielo_1.png" % sfondo))
        out = poster(cielo.resize((SW, SH)), 10, 5).convert("RGBA")
        lontani = [g for g in m["gruppi"] if g["parallax"] < 0.5]
        for i, g in enumerate(lontani):
            pl = Image.open(os.path.join(DIPINTI, "backgrounds", "%s_%s_1.png" % (sfondo, g["name"]))).convert("RGBA")
            w = round(pl.width * g["h"] / pl.height)
            pl = pl.resize((w, g["h"])).crop((0, 0, SCENA_W, g["h"]))
            forma = Image.new("L", (SCENA_W, SCENA_H))
            forma.paste(pl.getchannel("A"), (0, g["y0"]))
            # i piani più lontani più lisci
            maschera = semplifica(forma.resize((SW, SH)), 8 + 5 * (len(lontani) - 1 - i), 0.55)
            colori = Image.new("RGB", (SCENA_W, SCENA_H), media(pl))
            colori.paste(pl.convert("RGB"), (0, g["y0"]), pl)
            lay = poster(colori.resize((SW, SH)), 5, 5).convert("RGBA")
            lay.putalpha(maschera)
            out.alpha_composite(lay)
    else:
        out = Image.new("RGBA", (SW, SH), (61, 58, 74, 255))
    if VELO > 0:
        out.alpha_composite(Image.new("RGBA", (SW, SH), VELO_COL + (round(VELO * 255),)))
    griglia = np.array([[c == "1" for c in r] for r in m["rows"]], dtype=np.uint8)
    pieno = Image.fromarray(griglia * 255).resize((SW, SH), Image.BILINEAR)
    pieno = semplifica(pieno, 1.5)
    if BORDO > 0:
        out.alpha_composite(piatto((14, 10, 12), pieno.filter(ImageFilter.MaxFilter(2 * BORDO + 1))))
    f = os.path.join(DIPINTI, "maps", "%s_1.png" % m["mappa"])
    terreno = Image.open(f).convert("RGBA") if os.path.exists(f) else None
    base = media(terreno) if terreno else (92, 84, 88)
    if terreno:
        tb = Image.new("RGB", terreno.size, base)
        tb.paste(terreno.convert("RGB"), (0, 0), terreno)
        lay = poster(tb.resize((SW, SH)), 3, 6).convert("RGBA")
        lay.putalpha(pieno)
        out.alpha_composite(lay)
    else:
        out.alpha_composite(piatto(base, pieno))
    # il filo chiaro dove sopra c'è vuoto (le superfici su cui si cammina)
    s = np.asarray(pieno, dtype=float) / 255
    sopra = np.roll(s, FILO, axis=0)
    sopra[:FILO] = 0
    filo = np.clip(s - sopra, 0, 1)
    out.alpha_composite(piatto(mischia(base, (245, 238, 225), FILO_LUCE), Image.fromarray((filo * 255).astype(np.uint8))))
    if terreno:
        t = np.asarray(terreno.resize((SW, SH)), dtype=float)
        r, g, b, a = (t[..., i] for i in range(4))
        lava = (a > 128) & (r > 200) & (g > 60) & (g < 190) & (b < 90)
        lm = semplifica(Image.fromarray((lava * 255).astype(np.uint8)), 2, 0.35)
        out.alpha_composite(piatto(LAVA, lm))
    return out.convert("RGB"), griglia


def ritaglio(griglia, w, h):
    """Il riquadro della scena da mostrare in una finestra w x h: le arene piccole avvicinate
    (la loro forma, un po' d'aria e il cielo sopra), le mappe intere a tutta larghezza.
    Le finestre molto larghe (il finale) prendono la fascia attorno alle superfici."""
    ys, xs = np.nonzero(griglia)
    x0, x1 = xs.min() * CELLA, (xs.max() + 1) * CELLA
    ytop = ys.min() * CELLA
    bw = (x1 - x0) * 1.14
    bh = max((SH - ytop) * 1.6, bw * h / w)
    bw = min(bh * w / h, SW)
    bh = bw * h / w
    cx = (x0 + x1) / 2
    left = max(0, min(SW - bw, cx - bw / 2))
    top = SH - bh
    if w / h > 3:
        # la fascia centrata sulle superfici (la riga più alta piena di ogni colonna)
        alti = [np.argmax(griglia[:, c]) for c in range(griglia.shape[1]) if griglia[:, c].any()]
        cy = np.median(alti) * CELLA + bh * 0.12
        top = max(0, min(SH - bh, cy - bh / 2))
    return (int(left), int(top), int(left + bw), int(top + bh))


# Le impronte di quello che fa ogni miniatura (la forma del livello, i dipinti che usa e
# questo strumento): se cambia una mappa, un'arena o un dipinto e le miniature no, il
# controllo veloce (strumenti/controlli/tutti.sh) lo dice
IMPRONTE = os.path.join(QUI, "miniature_missioni.impronte.json")


def impronta(m):
    h = hashlib.sha1()
    h.update(open(os.path.abspath(__file__), "rb").read())
    h.update(json.dumps({k: m[k] for k in ("id", "mappa", "sfondo", "finale", "gruppi", "rows")}, sort_keys=True).encode())
    file = [os.path.join(DIPINTI, "maps", "%s_1.png" % m["mappa"])]
    if m["sfondo"]:
        file.append(os.path.join(DIPINTI, "backgrounds", "%s_cielo_1.png" % m["sfondo"]))
        file += [os.path.join(DIPINTI, "backgrounds", "%s_%s_1.png" % (m["sfondo"], g["name"])) for g in m["gruppi"]]
    for f in file:
        if os.path.exists(f):
            h.update(open(f, "rb").read())
    return h.hexdigest()


def controlla():
    """Il controllo veloce: le miniature sono quelle della mappa di oggi?"""
    vecchie = json.load(open(IMPRONTE)) if os.path.exists(IMPRONTE) else {}
    da_rifare = [m["id"] for m in leggi() if vecchie.get(m["id"]) != impronta(m)]
    if da_rifare:
        print("miniature delle missioni da rifare (%s): python3 strumenti/grafica/miniature_missioni.py"
              % ", ".join(da_rifare))
        return False
    print("miniature delle missioni in pari con mappe e dipinti")
    return True


def main():
    os.makedirs(OUT, exist_ok=True)
    impronte = {}
    for m in leggi():
        im, griglia = scena(m)
        for suffisso, (w, h) in FORMATI.items():
            if suffisso == "_finale" and not m["finale"]:
                continue
            f = os.path.join(OUT, m["id"] + suffisso + ".jpg")
            im.crop(ritaglio(griglia, w, h)).resize((w, h), Image.LANCZOS).save(f, quality=88, optimize=True)
            print("scritta", os.path.relpath(f, RADICE))
        impronte[m["id"]] = impronta(m)
    with open(IMPRONTE, "w") as f:
        json.dump(impronte, f, indent=1, sort_keys=True)
        f.write("\n")


if __name__ == "__main__":
    if "--controlla" in sys.argv:
        sys.exit(0 if controlla() else 1)
    main()
