# Dal video di un'animazione (fatto da Gabriella con un'IA video, fondo magenta,
# telecamera ferma) al foglio che legge fotogrammi.py: N fotogrammi consecutivi
# a partire da INIZIO, ritagliati tutti allo stesso riquadro (così il movimento
# resta quello del video) e messi in righe da 4 con spazio magenta tra uno e l'altro.
# Il ciclo (INIZIO e N) si sceglie guardando dove il video torna uguale.
# python3 strumenti/grafica/video.py video.mp4 INIZIO N foglio.png
import subprocess
import sys
import tempfile
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage as nd

video, inizio, n, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
COLONNE, SPAZIO = 4, 60
SCALA = 0.5   # i video sono grandi: a metà la testa misura come nei fogli di ChatGPT
MAGENTA = (255, 0, 255)

with tempfile.TemporaryDirectory() as tmp:
    subprocess.run(["ffmpeg", "-v", "error", "-i", video, f"{tmp}/f_%04d.png"], check=True)
    fr = [Image.open(f"{tmp}/f_{i:04d}.png").convert("RGB") for i in range(inizio, inizio + n)]
# il riquadro che contiene il personaggio in tutti i fotogrammi
box = None
for im in fr:
    a = np.asarray(im).astype(float)
    # non magenta (come la chiave di fotogrammi.py), senza i puntini del video compresso
    m = nd.binary_opening(((a[..., 0] + a[..., 2]) / 2 - a[..., 1]) < 130, iterations=3)
    ys, xs = np.nonzero(m)
    b = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
w, h = round((box[2] - box[0]) * SCALA), round((box[3] - box[1]) * SCALA)
righe = (n + COLONNE - 1) // COLONNE
foglio = Image.new("RGB", (COLONNE * (w + SPAZIO) + SPAZIO, righe * (h + SPAZIO) + SPAZIO), MAGENTA)
for i, im in enumerate(fr):
    foglio.paste(im.crop(box).resize((w, h), Image.LANCZOS), (SPAZIO + (i % COLONNE) * (w + SPAZIO), SPAZIO + (i // COLONNE) * (h + SPAZIO)))
Path(out).parent.mkdir(parents=True, exist_ok=True)
foglio.save(out)
print(out, foglio.size, "righe", righe)
