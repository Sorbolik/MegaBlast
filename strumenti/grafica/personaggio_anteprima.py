"""Anteprima del rig del personaggio: monta i pezzi master con le rotazioni date.

    python3 personaggio_anteprima.py out.png [giuntura=gradi ...] [mani=pugno] [--perni] [--zero]

Gli angoli sono in gradi, positivi in senso antiorario (come gui.set_euler) e si
sommano alla posa di riposo del rig (--zero parte da tutti gli angoli a 0).
"""
import json, math, os, sys
from PIL import Image, ImageDraw

QUI = os.path.dirname(os.path.abspath(__file__))
MASTER = '/mnt/project-files/grafica/personaggio/master/'
DATI = json.load(open(os.path.join(QUI, 'personaggio_rig.json')))
RIG, ORDINE = DATI['pezzi'], DATI['ordine']


def mat(a, tx, ty):
    # rotazione antioraria a schermo (y in giù)
    c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
    return (c, s, -s, c, tx, ty)


def mul(A, B):
    a, b, c, d, e, f = A
    g, h, i, j, k, l = B
    return (a * g + b * i, a * h + b * j, c * g + d * i, c * h + d * j, a * k + b * l + e, c * k + d * l + f)


def ap(M, x, y):
    return (M[0] * x + M[1] * y + M[4], M[2] * x + M[3] * y + M[5])


def perno(p, mani):
    if 'mani' in p: return p['mani'][mani]['perno'], p['mani'][mani]['img']
    return p.get('perno', [0, 0]), p.get('img')


def monta(angoli, mani='aperta'):
    """matrice per giuntura: da coordinate del pezzo (origine nel perno) al mondo"""
    W = {}
    def m(n):
        if n in W: return W[n]
        p = RIG[n]
        a = angoli.get(n, 0)
        if p['genitore'] is None:
            M = mat(a, 0, 0)
        else:
            gp, _ = perno(RIG[p['genitore']], mani)
            M = mul(m(p['genitore']), mat(a, p['aggancio'][0] - gp[0], p['aggancio'][1] - gp[1]))
        W[n] = M
        return M
    for n in RIG: m(n)
    return W


def strati(angoli, mani='aperta', S=1400, O=None):
    """(nome, immagine trasformata sulla tela S x S con origine al centro)"""
    W = monta(angoli, mani)
    O = O or (S / 2, S / 2)
    for n in ORDINE:
        p = RIG[n]
        (px, py), img = perno(p, mani)
        img = Image.open(MASTER + (img or n) + '.png')
        a, b, c, d, e, f = W[n]
        det = a * d - b * c
        ia, ib, ic, id_ = d / det, -b / det, -c / det, a / det
        tx, ty = -O[0] - e, -O[1] - f
        coeff = (ia, ib, ia * tx + ib * ty + px, ic, id_, ic * tx + id_ * ty + py)
        yield n, img.transform((S, S), Image.AFFINE, coeff, resample=Image.BILINEAR)


def angoli_da(argv, zero=False):
    ang = {} if zero else dict(DATI['riposo'])
    for a in argv:
        if '=' in a and not a.startswith('mani='):
            k, v = a.split('='); ang[k] = ang.get(k, 0) + float(v)
    return ang


if __name__ == '__main__':
    out, args = sys.argv[1], sys.argv[2:]
    mani = next((a[5:] for a in args if a.startswith('mani=')), 'aperta')
    ang = angoli_da(args, '--zero' in args)
    S = 2200
    O = (S / 2, S * 0.42)
    tela = Image.new('RGBA', (S, S), (150, 150, 165, 255))
    for _, l in strati(ang, mani, S, O): tela.alpha_composite(l)
    if '--perni' in args:
        dr = ImageDraw.Draw(tela)
        for n, M in monta(ang, mani).items():
            x, y = ap(M, 0, 0); x += O[0]; y += O[1]
            dr.ellipse([x - 6, y - 6, x + 6, y + 6], outline=(255, 0, 0), width=3)
            dr.text((x + 8, y - 6), n, fill=(120, 0, 0))
    tela.resize((S // 3, S // 3), Image.LANCZOS).save(out)
