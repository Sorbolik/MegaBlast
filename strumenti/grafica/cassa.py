# Cassa delle armi: il baule aperto con i denti disegnato da Gabriella (ChatGPT,
# già scontornato). Toglie il bordo chiaro da adesivo attorno al disegno (il
# contorno scuro resta) e lo riduce a ALTO pixel, quanto serve sullo schermo.
#   client/assets/casse/cassa.png        il baule
#   client/assets/casse/cassa_luce.png   serratura e punte dei denti, bianche:
#                                        il gioco le tinge di brace e le fa pulsare
# Uso: python3 strumenti/grafica/cassa.py [baule_aperto.png]
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SORGENTE = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/gabriella/disegni/2026-10-24_chatgpt/scontornati/baule_aperto.png"
OUT = Path(__file__).resolve().parents[2] / "client/assets/casse"
# in gioco è alta 22,4 unità: alla camera vicina (2,2) su un telefono sono ~80
# pixel veri, 96 lascia margine senza pesare
ALTO = 96

a = np.asarray(Image.open(SORGENTE).convert("RGBA")).astype(float)
rgb, al = a[..., :3], a[..., 3]
# bordo da adesivo: pixel chiari (o i resti rosa dello sfondo) collegati al
# trasparente di fuori; il contorno scuro del disegno li ferma
chiaro = (rgb.min(axis=2) > 60) | ((rgb[..., 0] > 200) & (rgb[..., 2] > 200))
fuori = (al < 128) | chiaro
m = Image.fromarray(np.pad(fuori, 1, constant_values=True).astype("uint8") * 255).copy()
ImageDraw.floodfill(m, (0, 0), 128)
al[np.asarray(m)[1:-1, 1:-1] == 128] = 0
# un pixel di sfumatura sul contorno, così riducendo non resta un alone chiaro
dentro = np.asarray(Image.fromarray((al > 0).astype("uint8") * 255).filter(ImageFilter.MinFilter(3))) > 0
al = np.where(dentro, al, np.minimum(al, 128))
a[..., 3] = al
im = Image.fromarray(a.astype("uint8"))
im = im.crop(im.getchannel("A").getbbox())
im = im.convert("RGBa").resize((round(im.width * ALTO / im.height), ALTO), Image.LANCZOS).convert("RGBA")
# il colore sotto i pixel trasparenti è quello del contorno: la GPU filtrando
# non tira dentro il rosa dello sfondo
p = np.asarray(im).copy()
p[p[..., 3] == 0, :3] = (40, 12, 8)
im = Image.fromarray(p)
im.save(OUT / "cassa.png", optimize=True)

# serratura e punte dei denti: il giallo, allargato e sfumato come un alone
p = np.asarray(im).astype(float)
oro = ((p[..., 0] > 200) & (p[..., 1] > 140) & (p[..., 2] < 90) & (p[..., 3] > 128)).astype("uint8") * 255
luce = Image.fromarray(oro).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(1.5))
bianco = Image.new("RGBA", im.size, (255, 255, 255, 0))
bianco.putalpha(luce)
bianco.save(OUT / "cassa_luce.png", optimize=True)
print("scritte", OUT / "cassa.png", OUT / "cassa_luce.png", im.size)
