"""La testa di Favilla nel disco della schermata d'ingresso (client/ui/entry.lua).

Dal disegno di Sergio (art/personaggi/favilla.png, 2328 x 2328): toglie pugni e
vestito, ritaglia un cerchio attorno alla testa e lo salva a 400 x 400 con il
bordo morbido in client/assets/ui/favilla.png. Il bianco del foglio resta: è
la carta del disco (il gioco lo tinge appena).

    python3 tools/grafica/ingresso.py
"""
import os
from PIL import Image, ImageDraw

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.normpath(os.path.join(QUI, "..", ".."))
ORIGINE = os.path.join(RADICE, "art", "personaggi", "favilla.png")
USCITA = os.path.join(RADICE, "client", "assets", "ui", "favilla.png")
LATO = 400

im = Image.open(ORIGINE).convert("RGB")
s = im.width / 1932          # le misure sotto sono sul disegno a 1932 px
d = ImageDraw.Draw(im)
BIANCO = (255, 255, 255)
d.rectangle([0, int(915 * s), int(760 * s), im.height], fill=BIANCO)            # pugno sinistro
d.rectangle([int(1195 * s), int(925 * s), im.width, im.height], fill=BIANCO)    # pugno destro
d.rectangle([0, int(1080 * s), im.width, im.height], fill=BIANCO)               # vestito
cx, cy, r = 1048 * s, 690 * s, 520 * s
disco = im.crop((int(cx - r), int(cy - r), int(cx + r), int(cy + r))).resize((LATO, LATO), Image.LANCZOS)
maschera = Image.new("L", (LATO * 4, LATO * 4), 0)
ImageDraw.Draw(maschera).ellipse([2, 2, LATO * 4 - 3, LATO * 4 - 3], fill=255)
out = disco.convert("RGBA")
out.putalpha(maschera.resize((LATO, LATO), Image.LANCZOS))
out.save(USCITA, optimize=True)
print(USCITA)
# la stessa testa piccola, per dove si disegna sotto i 48 px (la pillola della
# coda, le medaglie delle carte): l'atlas dell'interfaccia non ha mipmap e la
# grande rimpicciolita dieci volte fa gli scalini
PICCOLA = 96
grande = im.crop((int(cx - r), int(cy - r), int(cx + r), int(cy + r))).convert("RGBA")
alfa = Image.new("L", (PICCOLA * 8, PICCOLA * 8), 0)
ImageDraw.Draw(alfa).ellipse([4, 4, PICCOLA * 8 - 5, PICCOLA * 8 - 5], fill=255)
piccola = grande.resize((PICCOLA, PICCOLA), Image.LANCZOS)
piccola.putalpha(alfa.resize((PICCOLA, PICCOLA), Image.LANCZOS))
piccola.save(USCITA.replace(".png", "_p.png"), optimize=True)
