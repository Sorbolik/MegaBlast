"""Pezzi PROVVISORI del Fabbro per provare Blender: ritagliati dalla figura intera del foglio
scelto di WB-012 (art/WB-012/scelti/fabbro.png, prima vignetta), senza ridisegnare, ingrandire
o ridurre i colori. Servono solo a provare il flusso: i pezzi veri (sportello aperto, interno
della fornace, comignolo, fumo, braccia) li disegnerà Codex con una scheda.

    python3 tools/blender/taglia_fabbro.py
scrive tools/blender/pezzi_provvisori/{corpo,sportello,fumo}.png e pezzi.json (dove sta
ognuno nella vignetta, in pixel).
"""
import sys, colorsys
from PIL import Image, ImageDraw
from collections import deque
import json, os
qui = os.path.dirname(os.path.abspath(__file__))
radice = os.path.dirname(os.path.dirname(qui))
out = os.path.join(qui, 'pezzi_provvisori')
im = Image.open(os.path.join(radice, 'art/WB-012/scelti/fabbro.png')).convert('RGB').crop((14, 14, 400, 424)).convert('RGBA'); W, H = im.size; px = im.load()
bg = (245, 227, 195)
def near(p, t=38): return sum((a-b)**2 for a, b in zip(p[:3], bg)) < t*t
seen = bytearray(W*H); q = deque()
for x in range(W):
    q.append((x, 0)); q.append((x, H-1))
for y in range(H):
    q.append((0, y)); q.append((W-1, y))
while q:
    x, y = q.popleft()
    if x < 0 or y < 0 or x >= W or y >= H or seen[y*W+x]: continue
    if not near(px[x, y]): continue
    seen[y*W+x] = 1; px[x, y] = (0, 0, 0, 0)
    q.extend(((x+1, y), (x-1, y), (x, y+1), (x, y-1)))
def sat_val(p):
    h, s, v = colorsys.rgb_to_hsv(p[0]/255, p[1]/255, p[2]/255); return s, v*255
# sfondo chiuso (fra martello e gamba, fra le gambe): zone grandi color crema sotto la faccia
seen2 = bytearray(W*H)
for sy in range(H):
    for sx in range(W):
        if seen2[sy*W+sx] or px[sx, sy][3] == 0 or not near(px[sx, sy], 30): continue
        comp = []; q = deque([(sx, sy)])
        while q:
            x, y = q.popleft()
            if x < 0 or y < 0 or x >= W or y >= H or seen2[y*W+x]: continue
            if px[x, y][3] == 0 or not near(px[x, y], 30): continue
            seen2[y*W+x] = 1; comp.append((x, y))
            q.extend(((x+1, y), (x-1, y), (x, y+1), (x, y-1)))
        cx = sum(p[0] for p in comp) / len(comp); cy = sum(p[1] for p in comp) / len(comp)
        if len(comp) > 120 and cy > 150:
            for x, y in comp: px[x, y] = (0, 0, 0, 0)
# fumo: lo sbuffo a destra diventa un pezzo, quello dietro il corno si toglie
fumo = Image.new('RGBA', (W, H)); fp = fumo.load()
for y in range(0, 63):
    for x in range(228, W):
        p = px[x, y]
        if p[3] == 0: continue
        s, v = sat_val(p)
        if x >= 268 and s < 0.45 and v > 60:
            fp[x, y] = p; px[x, y] = (0, 0, 0, 0)
        elif x < 268 and s < 0.45 and v > 105:
            px[x, y] = (0, 0, 0, 0)   # lo sbuffo dietro il corno: via, il corno tiene il contorno
for y in range(0, 52):
    for x in range(290, W): px[x, y] = (0, 0, 0, 0)
# nel fumo resta solo lo sbuffo (il pezzo più grande): via i resti del contorno del corno
vis = bytearray(W*H); parti = []
for sy in range(H):
    for sx in range(W):
        if vis[sy*W+sx] or fp[sx, sy][3] == 0: continue
        comp = []; q = deque([(sx, sy)])
        while q:
            x, y = q.popleft()
            if x < 0 or y < 0 or x >= W or y >= H or vis[y*W+x] or fp[x, y][3] == 0: continue
            vis[y*W+x] = 1; comp.append((x, y))
            q.extend(((x+1, y), (x-1, y), (x, y+1), (x, y-1)))
        parti.append(comp)
parti.sort(key=len)
for comp in parti[:-1]:
    for x, y in comp: fp[x, y] = (0, 0, 0, 0)
# ombra sotto i piedi
for y in range(388, H):
    for x in range(W):
        p = px[x, y]
        if p[3] and sat_val(p)[0] < 0.22 and sat_val(p)[1] > 120: px[x, y] = (0, 0, 0, 0)
# puntini rimasti del contorno del fumo: si tolgono le isole piccole
seen3 = bytearray(W*H)
for sy in range(70):
    for sx in range(W):
        if seen3[sy*W+sx] or px[sx, sy][3] == 0: continue
        comp = []; q = deque([(sx, sy)])
        while q:
            x, y = q.popleft()
            if x < 0 or y < 0 or x >= W or y >= H or seen3[y*W+x] or px[x, y][3] == 0: continue
            seen3[y*W+x] = 1; comp.append((x, y))
            q.extend(((x+1, y), (x-1, y), (x, y+1), (x, y-1), (x+1, y+1), (x-1, y-1), (x+1, y-1), (x-1, y+1)))
        if len(comp) < 60:
            for x, y in comp: px[x, y] = (0, 0, 0, 0)
# sportello: l'arco della grata
mask = Image.new('L', (W, H)); d = ImageDraw.Draw(mask)
x0, y0, x1, y1, r = 151, 134, 265, 214, 34
d.rectangle((x0, y0+r, x1, y1), fill=255); d.ellipse((x0, y0, x1, y0+2*r+20), fill=255)
porta = Image.new('RGBA', (W, H)); porta.paste(im, (0, 0), mask)
corpo = im.copy(); hole = Image.new('RGBA', (W, H)); corpo.paste(hole, (0, 0), mask)
os.makedirs(out, exist_ok=True)
pezzi = {'vignetta': [W, H]}
for name, piece in (('corpo', corpo), ('sportello', porta), ('fumo', fumo)):
    bb = piece.getbbox(); piece.crop(bb).save(f'{out}/{name}.png')
    pezzi[name] = list(bb)
    print(name, bb)
json.dump(pezzi, open(os.path.join(out, 'pezzi.json'), 'w'), indent=1)
