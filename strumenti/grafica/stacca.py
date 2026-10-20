# Sfondo e terreno "alla Blastron": quello con cui si gioca deve staccare
# dallo sfondo (blastron_analisi/blastron_grafica.md).
# - sfondo: sfocato, poco contrasto, poco saturo, schiarito verso la nebbia;
# - terreno: un po' più contrastato, saturo e scuro.
# Il contorno scuro e il bordo chiaro del terreno li fa lo shader
# (battaglia/terreno.fp), così valgono anche attorno ai crateri.
#   python3 strumenti/grafica/stacca.py [cartella della mappa]
# Legge sfondo_lontano.png e terreno.png, scrive sfondo_spento.png e
# terreno_staccato.png (quelli usati da battaglia/terreno.mesh).
import os
import sys
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter

DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(__file__), "..", "..", "client", "assets", "mappe", "isole_cimitero")
NEBBIA = (140, 144, 172)

bg = Image.open(os.path.join(DIR, "sfondo_lontano.png")).convert("RGB")
k = bg.width / 1280
b = bg.filter(ImageFilter.GaussianBlur(3 * k))
b = ImageEnhance.Contrast(b).enhance(0.7)
b = ImageEnhance.Color(b).enhance(0.6)
b = Image.blend(b, Image.new("RGB", b.size, NEBBIA), 0.5)
b.save(os.path.join(DIR, "sfondo_spento.png"), optimize=True)

t = Image.open(os.path.join(DIR, "terreno.png")).convert("RGBA")
a = t.split()[3]
rgb = ImageEnhance.Contrast(t.convert("RGB")).enhance(1.25)
rgb = ImageEnhance.Color(rgb).enhance(1.3)
rgb = ImageEnhance.Brightness(rgb).enhance(0.85)
# i pixel trasparenti restano neri, come prima (alfa premoltiplicato dopo)
out = Image.merge("RGBA", (*rgb.split(), a))
out.save(os.path.join(DIR, "terreno_staccato.png"), optimize=True)


def misura(im, alpha=None):
    x = np.asarray(im.convert("RGB")).astype(float) / 255
    lum = x.mean(2)
    sat = (x.max(2) - x.min(2)) / np.maximum(x.max(2), 1e-3)
    det = np.abs(np.diff(lum, axis=1))[:, :]
    w = np.ones_like(lum) if alpha is None else np.asarray(alpha).astype(float) / 255
    wd = w[:, 1:] * w[:, :-1]
    return (lum * w).sum() / w.sum(), (sat * w).sum() / w.sum(), (det * wd).sum() / wd.sum()


print("sfondo   prima  luce %.2f  saturazione %.2f  dettaglio %.3f" % misura(bg))
print("sfondo   dopo   luce %.2f  saturazione %.2f  dettaglio %.3f" % misura(b))
print("terreno  dopo   luce %.2f  saturazione %.2f  dettaglio %.3f" % misura(rgb, a))
