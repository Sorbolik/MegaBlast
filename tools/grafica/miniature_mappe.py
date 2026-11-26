# Le cartoline delle mappe per la scelta della mappa in ALLENAMENTO (client/menu/training.lua):
# per ogni mappa dipinta della campagna, il cielo, i tre gruppi di piani dello sfondo e il
# terreno, messi insieme come li vede la camera a mappa intera, e rimpiccioliti.
#
# Scrive client/assets/maps/miniature/<mappa>.png e client/ui/maps.atlas (la texture "mappe"
# di client/main/game.gui). Le mappe sono quelle dell'Addestramento e dei gironi di client/sim/levels.lua (non le
# arene delle missioni), come le elenca training.lua, che hanno un'immagine in client/paintings/mappe/.
#
#   python3 tools/grafica/miniature_mappe.py      (dalla cartella del repository, dopo
#                                                      mappe_dipinte.py)
#   python3 tools/grafica/miniature_mappe.py --controlla    (solo il controllo, in tutti.sh:
#                     dice se una mappa è stata ridipinta e la sua cartolina no; Sergio, 26 nov)
import hashlib, json, os, subprocess, sys
# il controllo (--controlla) gira anche dove non c'è Pillow (GitHub)
if "--controlla" not in sys.argv:
    from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
DIPINTI = os.path.join(RADICE, "client", "paintings")
OUT = os.path.join(RADICE, "client", "assets", "maps", "miniature")
ATLAS = os.path.join(RADICE, "client", "ui", "maps.atlas")

# la cartolina sta in una carta di 378 x 212 della scena (1280 x 720): un po' di più per gli
# schermi fitti, ma due stanno ancora in una texture di 512 x 1024
W, H = 504, 284
SCENA_W, SCENA_H = 1280, 720

LUA = r"""
package.path = "client/?.lua;" .. package.path
local campaign = require "sim.campaign"
local sim_maps = require "sim.maps"
local dipinti = require "battle.paintings"
local function enc(v)
  if type(v) == "table" then
    local out, list = {}, #v > 0
    if list then for _, x in ipairs(v) do out[#out + 1] = enc(x) end return "[" .. table.concat(out, ",") .. "]" end
    for k, x in pairs(v) do out[#out + 1] = string.format("%q:%s", k, enc(x)) end
    return "{" .. table.concat(out, ",") .. "}"
  elseif type(v) == "string" then return string.format("%q", v) end
  return tostring(v)
end
local maps, seen = {}, {}
for _, cap in ipairs(campaign.CAPITOLI) do
  for _, l in ipairs((cap.id == "addestramento" or cap.id:match("^girone_")) and cap.missioni or {}) do
    if l.mappa and not l.arena and not seen[l.mappa] and dipinti.maps[l.mappa] then
      seen[l.mappa] = true
      maps[#maps + 1] = { id = l.mappa, sfondo = dipinti.maps[l.mappa] }
    end
  end
end
-- i gironi che la campagna non gioca ancora (sim/maps.lua CIRCLES), come in training.lua
for _, id in ipairs(sim_maps.CIRCLES) do
  if not seen[id] and dipinti.maps[id] then
    seen[id] = true
    maps[#maps + 1] = { id = id, sfondo = dipinti.maps[id] }
  end
end
print(enc({ mappe = maps, sfondi = dipinti.backgrounds }))
"""


def leggi():
    out = subprocess.run(["luajit", "-e", LUA], cwd=RADICE, capture_output=True, text=True, check=True).stdout
    return json.loads(out)


def cartolina(mappa, sfondo):
    im = Image.open(os.path.join(DIPINTI, "backgrounds", "%s_cielo_1.png" % mappa["sfondo"])).convert("RGBA")
    im = im.resize((SCENA_W, SCENA_H), Image.LANCZOS)
    for g in sfondo["groups"]:
        piano = Image.open(os.path.join(DIPINTI, "backgrounds", "%s_%s_1.png" % (mappa["sfondo"], g["name"]))).convert("RGBA")
        w = round(piano.width * g["h"] / piano.height)
        piano = piano.resize((w, g["h"]), Image.LANCZOS).crop((0, 0, min(w, SCENA_W), g["h"]))
        im.alpha_composite(piano, (0, g["y0"]))
    terreno = Image.open(os.path.join(DIPINTI, "maps", "%s_1.png" % mappa["id"])).convert("RGBA")
    im.alpha_composite(terreno.resize((SCENA_W, SCENA_H), Image.LANCZOS))
    return im.resize((W, H), Image.LANCZOS)


# Le impronte di quello che fa ogni cartolina (i dipinti che usa e questo strumento): se una
# mappa viene ridipinta e la cartolina no, il controllo veloce lo dice
IMPRONTE = os.path.join(QUI, "miniature_mappe.impronte.json")


def impronta(mappa, sfondo):
    h = hashlib.sha1()
    h.update(open(os.path.abspath(__file__), "rb").read())
    h.update(json.dumps(sfondo, sort_keys=True).encode())
    file = [os.path.join(DIPINTI, "maps", "%s_1.png" % mappa["id"]),
            os.path.join(DIPINTI, "backgrounds", "%s_cielo_1.png" % mappa["sfondo"])]
    file += [os.path.join(DIPINTI, "backgrounds", "%s_%s_1.png" % (mappa["sfondo"], g["name"])) for g in sfondo["groups"]]
    for f in file:
        h.update(open(f, "rb").read())
    return h.hexdigest()


def controlla():
    """Il controllo veloce: le cartoline sono quelle delle mappe di oggi?"""
    dati = leggi()
    vecchie = json.load(open(IMPRONTE)) if os.path.exists(IMPRONTE) else {}
    da_rifare = [m["id"] for m in dati["mappe"] if vecchie.get(m["id"]) != impronta(m, dati["sfondi"][m["sfondo"]])]
    if da_rifare:
        print("cartoline delle mappe da rifare (%s): python3 tools/grafica/miniature_mappe.py" % ", ".join(da_rifare))
        return False
    print("cartoline delle mappe in pari con i dipinti")
    return True


def main():
    dati = leggi()
    os.makedirs(OUT, exist_ok=True)
    righe, impronte = [], {}
    for m in dati["mappe"]:
        f = os.path.join(OUT, m["id"] + ".png")
        cartolina(m, dati["sfondi"][m["sfondo"]]).convert("RGB").save(f, optimize=True)
        righe.append('images {\n  image: "/assets/maps/miniature/%s.png"\n}\n' % m["id"])
        impronte[m["id"]] = impronta(m, dati["sfondi"][m["sfondo"]])
        print("scritta", os.path.relpath(f, RADICE))
    with open(ATLAS, "w") as a:
        a.write("".join(righe) + "margin: 2\nextrude_borders: 2\ninner_padding: 0\n")
    print("scritto", os.path.relpath(ATLAS, RADICE))
    with open(IMPRONTE, "w") as f:
        json.dump(impronte, f, indent=1, sort_keys=True)
        f.write("\n")


if __name__ == "__main__":
    if "--controlla" in sys.argv:
        sys.exit(0 if controlla() else 1)
    main()
