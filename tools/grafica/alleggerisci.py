# Alleggerisce i dipinti del gioco (client/paintings) senza perdita visibile: ogni PNG diventa a
# tavolozza (256 colori con la trasparenza, retinatura di libimagequant, come pngquant), tre-quattro
# volte più leggero. Serve perché l'APK resti sotto i 50 MB che Telegram accetta dai bot (11 nov: con
# gli sfondi dei gironi era arrivato oltre). Il gioco li legge uguale (image.load_buffer, stb_image).
# Un'immagine che a tavolozza cambierebbe troppo (colore premoltiplicato, 99,9° percentile della
# differenza oltre SOGLIA) resta com'è.
#
#   python3 tools/grafica/alleggerisci.py [file o cartelle...]   (di base tutto client/paintings)
#
# Serve il pacchetto imagequant (pip install imagequant); mappe_dipinte.py lo chiama da solo.
import io, os, sys
import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
DIPINTI = os.path.join(RADICE, "client", "paintings")
SOGLIA = 10


def _premoltiplicato(im):
    a = np.asarray(im.convert("RGBA"), np.float32)
    return np.concatenate([a[..., :3] * a[..., 3:] / 255, a[..., 3:]], -1)


def alleggerisci(path):
    """Riscrive path a tavolozza se viene più leggero e uguale a occhio. -> (prima, dopo) in byte."""
    import imagequant
    prima = os.path.getsize(path)
    im = Image.open(path)
    if im.mode == "P":
        return prima, prima
    im = im.convert("RGBA")
    q = imagequant.quantize_pil_image(im, dithering_level=1.0, max_colors=256)
    if np.percentile(np.abs(_premoltiplicato(im) - _premoltiplicato(q)), 99.9) > SOGLIA:
        return prima, prima
    b = io.BytesIO()
    q.save(b, "PNG", optimize=True)
    if b.tell() >= prima:
        return prima, prima
    with open(path, "wb") as f:
        f.write(b.getvalue())
    return prima, b.tell()


def tutti(percorsi):
    file = []
    for p in percorsi:
        if os.path.isdir(p):
            for d, _, nomi in os.walk(p):
                file += [os.path.join(d, n) for n in sorted(nomi) if n.endswith(".png")]
        else:
            file.append(p)
    tot0 = tot1 = 0
    for f in file:
        a, b = alleggerisci(f)
        tot0, tot1 = tot0 + a, tot1 + b
    print("alleggeriti %d dipinti: da %.1f a %.1f MB" % (len(file), tot0 / 1e6, tot1 / 1e6))


if __name__ == "__main__":
    tutti(sys.argv[1:] or [DIPINTI])
