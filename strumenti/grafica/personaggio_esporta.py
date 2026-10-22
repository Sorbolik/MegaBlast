"""Esporta il personaggio per il gioco dai pezzi master e da personaggio_rig.json.

    python3 strumenti/grafica/personaggio_esporta.py

Scrive:
- client/assets/personaggio/pg_<pezzo>.png   battaglia, PX_BATTAGLIA pixel per unità del rig
- client/assets/menu/personaggio/pg_<pezzo>.png  home, PX_HOME pixel per unità
- client/battaglia/personaggio_rig.lua      perni, agganci e misure in unità del rig

Il rig è alto ALTEZZA unità dai piedi (punto a terra) alla punta delle corna,
nella posa di riposo.
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import personaggio_anteprima as A

RADICE = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT_B = os.path.join(RADICE, 'client/assets/personaggio/')
OUT_H = os.path.join(RADICE, 'client/assets/menu/personaggio/')
LUA = os.path.join(RADICE, 'client/battaglia/personaggio_rig.lua')
ALTEZZA = 128
PX_BATTAGLIA = 1
PX_HOME = 4


def bordo(img, p=2):
    w, h = img.size
    t = Image.new('RGBA', (w + 2 * p, h + 2 * p))
    t.paste(img, (p, p))
    return t


def salva(img, nome, k):
    """scala i pezzi master di k; restituisce la misura in unità del rig"""
    for out, px in ((OUT_B, PX_BATTAGLIA), (OUT_H, PX_HOME)):
        s = k * px
        w, h = max(2, round(img.width * s)), max(2, round(img.height * s))
        img.resize((w, h), Image.LANCZOS).save(out + 'pg_' + nome + '.png', optimize=True)


def main():
    os.makedirs(OUT_B, exist_ok=True)
    os.makedirs(OUT_H, exist_ok=True)
    rig, riposo = A.RIG, A.DATI['riposo']

    # misura della posa di riposo: il terreno è sotto i piedi
    S = 3000
    top, terra = 1e9, -1e9
    for n, l in A.strati(riposo, 'aperta', S):
        bb = l.getchannel('A').point(lambda v: 255 if v > 40 else 0).getbbox()
        if bb:
            top = min(top, bb[1] - S / 2)
            if n.startswith('caviglia'):
                terra = max(terra, bb[3] - S / 2)
    k = ALTEZZA / (terra - top)  # unità del rig per pixel master
    print('altezza master %.0f px, k = %.4f, bacino a %.1f unità da terra' % (terra - top, k, terra * k))

    M = A.MASTER
    def img(n): return Image.open(M + n + '.png').convert('RGBA')

    dati = {}
    for n, p in rig.items():
        d = {}
        if p['genitore']:
            d['genitore'] = p['genitore']
            d['aggancio'] = [v * k for v in p['aggancio']]
        if 'mani' in p:
            d['mani'] = {}
            for posa, m in p['mani'].items():
                im = img(m['img'])
                salva(im, m['img'], k)
                d['mani'][posa] = {'img': 'pg_' + m['img'], 'perno': [v * k for v in m['perno']],
                                   'size': [im.width * k, im.height * k]}
            # il perno della giuntura è il polso: quello della mano aperta
            d['perno'] = d['mani']['aperta']['perno']
        else:
            nome = p.get('img', n)
            im = img(nome)
            if n == 'nucleo':
                # il Nucleo bianco: si tinge col colore della squadra
                g = np.array(im).astype(float)
                lum = g[..., :3].mean(2)
                lum = np.clip((lum - lum[g[..., 3] > 0].min()) * 1.25 + 60, 0, 255)
                g[..., 0] = g[..., 1] = g[..., 2] = lum
                im = Image.fromarray(g.astype(np.uint8))
            salva(im, nome, k)
            d['img'] = 'pg_' + nome
            d['perno'] = [v * k for v in p['perno']]
            d['size'] = [im.width * k, im.height * k]
            if n.startswith('caviglia'):
                # suola: quanto sta sotto la caviglia il punto più basso del piede
                ys = np.nonzero(np.array(im)[..., 3].max(1) > 40)[0]
                d['suola'] = (ys.max() - p['perno'][1]) * k
        dati[n] = d

    # occhio: il buco della maschera, riempito di luce (bianco, si tinge e va in additivo)
    t = np.array(img('testa_maschera')).astype(int)
    scuro = (t[..., :3].mean(2) < 60) & (t[..., 3] > 200)
    # il buco è la componente scura più grande nel riquadro dell'occhio (fuori
    # dal riquadro il nero si attacca ai capelli)
    riq = np.zeros_like(scuro)
    riq[170:240, 240:292] = True
    lab, _ = nd.label(scuro & riq)
    ids, conta = np.unique(lab, return_counts=True)
    conta[ids == 0] = 0
    buco = lab == ids[conta.argmax()]
    ys, xs = np.nonzero(buco)
    x0, x1, y0, y1 = xs.min() - 6, xs.max() + 7, ys.min() - 6, ys.max() + 7
    m = Image.fromarray((buco[y0:y1, x0:x1] * 255).astype(np.uint8))
    # bordo morbido e centro più acceso
    centro = Image.fromarray((nd.binary_erosion(buco, iterations=7)[y0:y1, x0:x1] * 255).astype(np.uint8))
    a = np.maximum(np.array(m.filter(ImageFilter.GaussianBlur(2))) * 0.75,
                   np.array(centro.filter(ImageFilter.GaussianBlur(4))) * 1.0)
    occhio = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
    occhio[..., :3] = 255
    occhio[..., 3] = np.clip(a, 0, 255).astype(np.uint8)
    salva(Image.fromarray(occhio), 'occhio', k)
    occhio_c = [(x0 + x1) / 2 * k, (y0 + y1) / 2 * k]
    occhio_s = [(x1 - x0) * k, (y1 - y0) * k]

    with open(LUA, 'w') as f:
        f.write('-- Generato da strumenti/grafica/personaggio_esporta.py da personaggio_rig.json: non modificare a mano.\n')
        f.write('-- Unità del rig (alto %d dai piedi alle corna), y in giù nelle immagini.\n' % ALTEZZA)
        f.write('return {\n')
        f.write('\tbacino_y = %.2f, -- perno del bacino sopra i piedi, a riposo\n' % (terra * k))
        f.write('\tocchio = { pos = { %.2f, %.2f }, size = { %.2f, %.2f } }, -- nella testa\n' % (*occhio_c, *occhio_s))
        f.write('\triposo = { %s },\n' % ', '.join('%s = %g' % (a, b) for a, b in riposo.items()))
        f.write('\tordine = { %s },\n' % ', '.join('"%s"' % o for o in A.DATI['ordine']))
        f.write('\tpezzi = {\n')
        def v2(v): return '{ %.2f, %.2f }' % tuple(v)
        for n in A.DATI['ordine']:
            d = dati[n]
            parti = []
            if 'genitore' in d: parti.append('genitore = "%s"' % d['genitore'])
            if 'img' in d: parti.append('img = "%s"' % d['img'])
            parti.append('perno = ' + v2(d['perno']))
            if 'aggancio' in d: parti.append('aggancio = ' + v2(d['aggancio']))
            if 'size' in d: parti.append('size = ' + v2(d['size']))
            if 'suola' in d: parti.append('suola = %.2f' % d['suola'])
            if 'mani' in d:
                mm = ['%s = { img = "%s", perno = %s, size = %s }' % (pp, q['img'], v2(q['perno']), v2(q['size']))
                      for pp, q in d['mani'].items()]
                parti.append('mani = {\n\t\t\t' + ',\n\t\t\t'.join(mm) + ',\n\t\t}')
            f.write('\t\t%s = { %s },\n' % (n, ', '.join(parti)))
        f.write('\t},\n}\n')
    print('scritto', LUA)


if __name__ == '__main__':
    main()
