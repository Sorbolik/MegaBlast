# Cassa delle armi (Reliquiario): disegnata da codice finché non c'è un'immagine
# fatta con la bibbia. Pietra nera da Scoria, bordi e angoli d'ottone, una runa
# sul davanti che brilla (cassa_luce.png, bianca: il gioco la tinge di brace).
# Uso: python3 strumenti/grafica/cassa.py  ->  client/assets/casse/
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path

S = 4                      # si disegna 4 volte più grande e poi si riduce
W, H = 64, 56
out = Path(__file__).resolve().parents[2] / "client/assets/casse"
out.mkdir(parents=True, exist_ok=True)

base = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
d = ImageDraw.Draw(base)
def r(x0, y0, x1, y1, fill, rad=0):
    d.rounded_rectangle([x0 * S, y0 * S, x1 * S, y1 * S], rad * S, fill=fill)

PIETRA, PIETRA2 = (30, 27, 33, 255), (44, 39, 47, 255)
OTTONE, OTTONE_SCURO, OTTONE_LUCE = (176, 130, 62, 255), (110, 76, 34, 255), (226, 186, 112, 255)
# corpo e coperchio
r(4, 18, 60, 54, OTTONE_SCURO, 4)
r(6, 20, 58, 52, PIETRA, 3)
r(2, 8, 62, 22, OTTONE_SCURO, 4)
r(4, 10, 60, 20, PIETRA2, 3)
# venature della pietra
rng = np.random.default_rng(3)
for _ in range(14):
    x, y = rng.uniform(8, 56), rng.uniform(22, 50)
    d.line([x * S, y * S, (x + rng.uniform(-5, 5)) * S, (y + rng.uniform(2, 6)) * S], fill=(18, 16, 20, 255), width=S)
# fasce e angoli d'ottone
for x in (10, 50):
    r(x, 8, x + 4, 54, OTTONE)
    r(x + 1, 8, x + 2, 54, OTTONE_LUCE)
r(2, 20, 62, 23, OTTONE)
for x0, y0 in ((2, 8), (54, 8), (4, 46), (52, 46)):
    r(x0, y0, x0 + 8, y0 + 8, OTTONE, 2)
    r(x0 + 2, y0 + 2, x0 + 4, y0 + 4, OTTONE_LUCE, 1)
# serratura
r(27, 17, 37, 27, OTTONE, 2)
r(30, 20, 34, 25, (20, 16, 18, 255), 1)

# runa: un rombo con una croce, la luce sta in un livello a parte
luce = Image.new("L", (W * S, H * S), 0)
dl = ImageDraw.Draw(luce)
cx, cy = 32 * S, 40 * S
rombo = [(cx, cy - 9 * S), (cx + 8 * S, cy), (cx, cy + 9 * S), (cx - 8 * S, cy)]
dl.polygon(rombo, outline=255, width=2 * S)
dl.line([cx, cy - 5 * S, cx, cy + 5 * S], fill=255, width=2 * S)
dl.line([cx - 4 * S, cy, cx + 4 * S, cy], fill=255, width=2 * S)
dl.line([28 * S, 22 * S, 36 * S, 22 * S], fill=200, width=S)   # fessura del coperchio
d.polygon(rombo, outline=(60, 40, 30, 255), width=2 * S)       # incisione sotto la luce
alone = luce.filter(ImageFilter.GaussianBlur(3 * S))
luce = Image.fromarray(np.clip(np.asarray(luce, float) + np.asarray(alone, float) * 1.4, 0, 255).astype(np.uint8))
# l'alone resta dentro la cassa
luce = Image.fromarray((np.asarray(luce, float) * (np.asarray(base.split()[3], float) / 255)).astype(np.uint8))

base = base.resize((W, H), Image.LANCZOS)
luce = luce.resize((W, H), Image.LANCZOS)
bianco = Image.new("RGBA", (W, H), (255, 255, 255, 0))
bianco.putalpha(luce)
base.save(out / "cassa.png")
bianco.save(out / "cassa_luce.png")
print("scritte", out / "cassa.png", out / "cassa_luce.png")
