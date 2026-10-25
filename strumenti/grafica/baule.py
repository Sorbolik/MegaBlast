# Cassa delle armi: il baule di Gabriella (disegnato con ChatGPT, già scontornato).
#   client/assets/casse/cassa.png        il baule aperto, con i denti
#   client/assets/casse/cassa_luce.png   serratura e denti, bianchi:
#                                        il gioco li tinge di brace e li fa pulsare
# python3 strumenti/grafica/baule.py [baule_aperto.png]
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

SORGENTE = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/gabriella/disegni/2026-10-24_chatgpt/scontornati/baule_aperto.png"
OUT = Path(__file__).resolve().parents[2] / "client/assets/casse"
ALTO = 230   # pixel: circa la stessa densità dei fotogrammi del diavoletto

im = Image.open(SORGENTE).convert("RGBA")
im = im.crop(im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox())
im = im.resize((round(im.width * ALTO / im.height), ALTO), Image.LANCZOS)
im.save(OUT / "cassa.png", optimize=True)

# serratura e punte dei denti: il giallo, allargato e sfumato come un alone
a = np.asarray(im).astype(float)
r, g, b = a[..., 0], a[..., 1], a[..., 2]
oro = ((r > 200) & (g > 140) & (b < 90) & (a[..., 3] > 128)).astype("uint8") * 255
luce = Image.fromarray(oro).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(4))
bianco = Image.new("RGBA", im.size, (255, 255, 255, 0))
bianco.putalpha(luce)
bianco.save(OUT / "cassa_luce.png", optimize=True)
print(im.size)
