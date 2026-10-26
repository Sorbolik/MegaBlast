# Mappa "Il Crogiolo": la forma di collisione a poligoni dritti (solo 0°, 45° e
# 90°) e il disegno finito, montato con i materiali della Forgia (pietra, crosta,
# travi, cratere di grafica/mappe/mappa_forgia/chat/), la pietra virata sul
# bronzo bruciato perché si distingua dalla Forgia.
#
# Si disegna sulla griglia della Forgia (1280 x 720, celle da 2 px, y verso
# l'alto); nel gioco le celle sono da 3 px, quindi il mondo è 1920 x 1080 e
# tutto è 1,5 volte più grande. Misure su questa griglia (diavoletto alto 26,
# largo 20, salto alto 27 e lungo 33): gradini <= 20, gallerie >= 50, terra >= 20.
#
# Scrive in /mnt/project-files/grafica/mappe/mappa_crogiolo/:
#   maschera.png      640 x 360 celle: bianco terra, rosso acciaio (indistruttibile)
#   gioco/            terreno.png 1920x1080 (alfa) e interno_mezzo.png 960x540,
#                     da copiare in client/assets/mappe/crogiolo/; poi
#                     strumenti/grafica/mappa_in_lua.py riscrive sim/mapdata.lua
#   anteprima.png     il disegno con i diavoletti (39 x 29 px) sui punti di partenza
# python3 strumenti/grafica/mappa_crogiolo.py
import os
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd

D = '/mnt/project-files/grafica/mappe/'
OUT = D + 'mappa_crogiolo/'
CHAT = D + 'mappa_forgia/chat/'
W, H = 1280, 720
DY = 40                       # tutto più in alto di DY: sotto resta il baratro

terra, acciaio, buchi = [], [], []

def rect(lst, x0, y0, x1, y1):
    lst.append([(x0, y0), (x1, y0), (x1, y1), (x0, y1)])

def lato(m):
    """Metà sinistra; m specchia le x per la destra."""
    T, S, B = [], [], []
    # altopiano sul bordo; sotto, una grotta alta 50 che si apre verso il centro
    # e scende a 45° sul fondo
    T.append([(40, 60), (640, 60), (640, 100), (300, 100), (270, 130), (96, 130),
              (96, 180), (220, 180), (220, 290), (40, 290)])
    # piastra d'acciaio sull'altopiano: riparo per chi parte lassù
    rect(S, 46, 290, 74, 318)
    # ponte d'acciaio dall'altopiano al bordo del crogiolo
    rect(S, 220, 278, 486, 290)
    # trave d'acciaio sotto il fondo
    rect(S, 300, 48, 640, 60)
    # mestolo sospeso a metà altezza, con il bordo d'acciaio sotto
    T.append([(250, 410), (380, 410), (380, 426), (370, 436), (260, 436), (250, 426)])
    rect(S, 262, 404, 368, 410)
    mir = lambda pts: [(W - x if m else x, y) for x, y in pts]
    return [mir(p) for p in T], [mir(p) for p in S], [mir(p) for p in B]

for m in (False, True):
    T, S, B = lato(m)
    terra += T; acciaio += S; buchi += B

# il crogiolo: una conca a 45° appoggiata su un gambo; sotto, il tetto della
# galleria che passa da un lato all'altro sul fondo
terra.append([(486, 290), (514, 290), (574, 230), (706, 230), (766, 290), (794, 290),
              (714, 210), (680, 210), (680, 170), (720, 170), (720, 150),
              (560, 150), (560, 170), (600, 170), (600, 210), (566, 210)])
# la galleria sotto: alta 50, il fondo la attraversa
rect(buchi, 560, 100, 720, 150)
# trave d'acciaio in cima, sopra il crogiolo
rect(acciaio, 570, 540, 710, 552)

def raster(scale):
    im = Image.new('RGB', (W * scale, H * scale), (0, 0, 0))
    d = ImageDraw.Draw(im)
    f = lambda pts: [(x * scale, (H - y - DY) * scale) for x, y in pts]
    for p in terra: d.polygon(f(p), fill=(255, 255, 255))
    for p in buchi: d.polygon(f(p), fill=(0, 0, 0))
    for p in acciaio: d.polygon(f(p), fill=(255, 0, 0))
    return im

# Punti di partenza in coordinate del gioco (1920 x 1080), come in sim/maps.lua:
# 1 e 3 a sinistra, 2 e 4 a destra. from: altezza da cui si cerca il terreno.
SPAWNS = [(195, 1080), (1725, 1080), (630, 300), (1290, 300)]

# --- disegno ---------------------------------------------------------------

SC = 2                        # si disegna a 2560x1440, poi si riduce a 1920x1080
S_PIETRA, S_CROSTA, S_CRATERE = 0.3 * SC, 0.22 * SC, 0.09

def carica(n):
    return Image.open(CHAT + n).convert('RGB')

def bronzo(a):
    """Vira la pietra della Forgia verso un bronzo bruciato (stessa luce)."""
    l = a.mean(-1, keepdims=True)
    tinta = np.array([1.3, 0.9, 0.62])
    return np.clip(l * tinta * 0.75 + a * 0.25, 0, 255)

def tile(img, s, w, h):
    t = np.asarray(img.resize((int(img.width * s),) * 2, Image.LANCZOS)).astype(float)
    return np.tile(t, (h // t.shape[0] + 2, w // t.shape[1] + 2, 1))[:h, :w]

def scala(a, w, h):
    return np.asarray(Image.fromarray(a).resize((max(1, w), max(1, h)), Image.LANCZOS)).astype(float)

def disegna():
    Wp, Hp = W * SC, H * SC
    m = np.asarray(raster(SC)).astype(int)
    dirt = (m[..., 0] > 128) & (m[..., 1] > 128)
    steel = (m[..., 0] > 128) & (m[..., 1] < 64)
    solid = dirt | steel

    # pietra, più scura vicino ai bordi
    dd = nd.distance_transform_edt(dirt)
    out = bronzo(tile(carica('1_pietra.png'), S_PIETRA, Wp, Hp))
    out *= np.clip(0.55 + 0.45 * np.minimum(dd, 10 * SC) / (10 * SC), 0, 1)[..., None]

    # crosta: la riga alta della striscia sul bordo di ogni piano calpestabile
    c = np.asarray(carica('2_crosta.png')).astype(float)
    mag = (c[..., 0] > 180) & (c[..., 2] > 180) & (c[..., 1] < 90)
    ci = Image.fromarray(c[int(np.argmax(mag.mean(1) < 0.5)):].astype(np.uint8))
    c = np.asarray(ci.resize((int(ci.width * S_CROSTA), int(ci.height * S_CROSTA)), Image.LANCZOS)).astype(float)
    CH, FADE = int(150 * S_CROSTA), int(40 * S_CROSTA)
    depth = np.full((Hp, Wp), 10 ** 6)
    for x in range(Wp):
        col, d = dirt[:, x], 10 ** 6
        sopra = np.r_[False, dirt[:-1, x]]  # sotto l'acciaio la crosta continua
        for y in np.nonzero(col)[0]:
            d = 0 if not sopra[y] else (d + 1 if dirt[y - 1, x] else 10 ** 6)
            depth[y, x] = d
    ys, xs = np.nonzero(dirt & (depth < CH + FADE))
    cy = depth[ys, xs]
    a = np.clip((CH + FADE - cy) / FADE, 0, 1)[:, None]
    out[ys, xs] = c[cy, xs % c.shape[1]] * a + out[ys, xs] * (1 - a)

    # acciaio: kit delle travi sui pezzi rossi
    k = np.asarray(carica('3_travi.png'))
    TRAVE, PIASTRA = k[42:180, 55:1329], k[263:415, 251:402]

    def trave(w, h):
        src = TRAVE[:34] if h < 10 * SC else TRAVE  # bordino sottile: solo i rivetti
        f = h / src.shape[0]
        a = scala(src, int(src.shape[1] * f), h)
        L, R = int(406 * f), int((1274 - 409) * f)
        mid = a[:, L:L + int(457 * f)]
        if w <= L + R:
            return np.concatenate([a[:, :w // 2], a[:, a.shape[1] - (w - w // 2):]], 1)
        n = w - L - R
        return np.concatenate([a[:, :L], np.tile(mid, (1, n // mid.shape[1] + 1, 1))[:, :n], a[:, a.shape[1] - R:]], 1)

    def piastre(w, h):
        n = max(1, round(w / h))
        p = scala(PIASTRA, w // n, h)
        return np.concatenate([p] * n + [p[:, :w - p.shape[1] * n]], 1)

    lab, _ = nd.label(steel)
    for sl in nd.find_objects(lab):
        h, w = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        out[sl] = trave(w, h) if w >= 3 * h else piastre(w, h)

    rgba = np.dstack([np.clip(out, 0, 255), solid * 255.0]).astype(np.uint8)
    return Image.fromarray(rgba, 'RGBA').resize((1920, 1080), Image.LANCZOS)

def anteprima(ter, cells):
    """Il disegno su un fondo scuro, con i diavoletti sui punti di partenza."""
    prev = Image.new('RGBA', (1920, 1080), (34, 30, 44, 255))
    prev = Image.alpha_composite(prev, ter).convert('RGB')
    solid = np.kron(np.asarray(cells.convert('L')) > 0, np.ones((3, 3), bool))
    d = ImageDraw.Draw(prev)
    for x, top in SPAWNS:
        Y = 1080 - top
        Y += int(np.argmax(solid[Y:, x]))
        d.rectangle([x - 14, Y - 39, x + 14, Y - 1], fill=(200, 40, 40), outline=(255, 230, 200))
    return prev

if __name__ == '__main__':
    os.makedirs(OUT + 'gioco/', exist_ok=True)
    cells = raster(2).resize((W // 2, H // 2), Image.NEAREST)  # il colore al centro di ogni cella
    cells.save(OUT + 'maschera.png')
    ter = disegna()
    ter.save(OUT + 'gioco/terreno.png', optimize=True)
    cr = tile(carica('4_cratere.png'), S_CRATERE, 960, 540)
    Image.fromarray(bronzo(cr).astype(np.uint8)).convert('RGBA').save(OUT + 'gioco/interno_mezzo.png', optimize=True)
    anteprima(ter, cells).save(OUT + 'anteprima.png')
    print('ok', OUT)
