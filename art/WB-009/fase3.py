#!/usr/bin/env python3
"""WB-009: taglio, ricalco potrace a tavolozza fissa, PNG da SVG ed editor.

python3 art/WB-009/fase3.py
Richiede numpy, scipy, Pillow, cairosvg e potrace nel PATH.
Scrive soltanto art/WB-009/fase3/. Non modifica il gioco o gli strumenti comuni.
"""
import base64
import importlib.util
import inspect
import json
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

import cairosvg
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = Path(__file__).resolve().parent
OUT = ART / 'fase3'
sys.path.insert(0, str(ROOT / 'strumenti/stampino'))
import taglia as TG

PALETTE = ['#000000', '#B8432A', '#8E2F1C', '#F1DFB0', '#D6BC86',
           '#EFE3C8', '#C9B48E', '#F2C45A', '#FFFFFF', '#5A1A10',
           '#E0605A', '#00FF00', '#00B400']
RGB = np.array([[int(c[i:i+2], 16) for i in (1, 3, 5)] for c in PALETTE], np.float32)
EXTRA = ['testa_mira', 'testa_arrabbiata', 'testa_sconfitta', 'testa_paura', 'testa_provocazione']
CHECKS = []


def check_svg(svg):
    """Fail closed: solo path/gruppi, niente raster, CSS o colori impliciti."""
    root = ET.fromstring(svg)
    paths = 0
    for el in root.iter():
        tag = el.tag.split('}')[-1]
        if tag not in ('svg', 'g', 'path'):
            raise ValueError('Elemento SVG non ammesso: ' + tag)
        if 'style' in el.attrib:
            raise ValueError('CSS non ammesso')
        for attr in ('fill', 'stroke'):
            if attr in el.attrib and el.attrib[attr].upper() not in PALETTE + ['NONE']:
                raise ValueError('Colore fuori tavolozza: ' + el.attrib[attr])
        if tag == 'path':
            paths += 1
    return paths


def trace(mask, color, opacity=1):
    if not mask.any():
        return ''
    with tempfile.TemporaryDirectory() as tmp:
        pbm, svg = Path(tmp)/'m.pbm', Path(tmp)/'m.svg'
        Image.fromarray(np.where(mask, 0, 255).astype('uint8')).convert('1').save(pbm)
        subprocess.run(['potrace', str(pbm), '-s', '-o', str(svg), '--turdsize', '1',
                        '--alphamax', '1.0', '--opttolerance', '0.2'], check=True)
        doc = ET.parse(svg).getroot()
        g = doc.find('{http://www.w3.org/2000/svg}g')
        d = ''.join('<path d="'+p.attrib['d']+'"/>' for p in g)
        return f'<g transform="{g.attrib["transform"]}" fill="{color}" stroke="none" opacity="{opacity}">{d}</g>'


def vector(a, width, height, tint=False):
    alpha = a[..., 3] > 128
    h, w = alpha.shape
    if tint:
        # Il livello squadra usa bianco con opacità: il fill resta nella tavolozza.
        bright = a[..., :3].max(axis=2)
        groups = ''.join(trace(alpha & (np.abs(bright-v) < np.abs(bright-other)), '#FFFFFF', v/255)
                         for v, other in [(255, 180), (180, 255)])
    else:
        # Distanza RGB al codice esatto, a blocchi per limitare la memoria.
        labels = np.zeros((h, w), np.uint8)
        for y in range(0, h, 128):
            dist = ((a[y:y+128, :, None, :3] - RGB[None, None]) ** 2).sum(axis=-1)
            labels[y:y+128] = dist.argmin(axis=2)
        from scipy.ndimage import uniform_filter, binary_dilation
        # Voto locale 3x3: elimina isole dovute alle leggere sfumature dell'IA.
        votes = np.stack([uniform_filter((labels == i).astype(np.float32), size=3)
                          for i in range(len(PALETTE))])
        labels = votes.argmax(axis=0)
        groups = trace(alpha, '#000000')
        # Un pixel di sovrapposizione fra colori evita fessure nere dopo il ricalco.
        groups += ''.join(trace(alpha & binary_dilation(labels == i), c)
                          for i, c in enumerate(PALETTE) if i)
        groups += trace(alpha & (labels == 0), '#000000')
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {w} {h}">{groups}</svg>\n'
    check_svg(svg)
    return svg


def save(pz, nome, posto, px0, py0, scala, px, scatola=None):
    al = (pz if scatola is None else scatola)[..., 3]
    ys, xs = np.nonzero(al > 8)
    if not len(xs):
        x0, y0, x1, y1 = 0, 0, pz.shape[1], pz.shape[0]
    else:
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max()+1, ys.max()+1
    crop = pz[y0:y1, x0:x1].copy()
    w, h = (x1-x0)/scala, (y1-y0)/scala
    name = f'{nome}_{posto}'
    width, height = max(1, round(w*px)), max(1, round(h*px))
    svg = vector(crop, width, height, tint=posto.endswith('_tinta'))
    (OUT/'svg'/f'{name}.svg').write_text(svg)
    for density in (1, 2, 3):
        cairosvg.svg2png(bytestring=svg.encode(), write_to=str(OUT/f'png/{density}x/{name}.png'),
                        output_width=width*density, output_height=height*density)
    CHECKS.append({'file': f'svg/{name}.svg', 'paths': check_svg(svg), 'size_1x': [width, height]})
    return {'img': name, 'x': round(((x0+x1)/2-px0)/scala, 1),
            'y': round((py0-(y0+y1)/2)/scala, 1), 'w': round(w, 1), 'h': round(h, 1)}


def team(pz):
    base, tint = TG_TINTA(pz)
    if tint is not None:
        # Il livello squadra copre il nero di base; non introduce grigi fuori tavolozza.
        base[tint[..., 3] > 8, :3] = 0
    return base, tint


TG_TINTA = TG.tinta


def build_editor():
    spec = importlib.util.spec_from_file_location('prepara_wb009', ROOT/'strumenti/animazioni/prepara.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    # Riusa la lettura dei dati del generatore, senza chiamarne la scrittura.
    source = inspect.getsource(mod.main)
    source = source[:source.index('    testo = json.dumps')] + '    return dati\n'
    namespace = dict(mod.__dict__)
    exec(compile(source, str(ROOT/'strumenti/animazioni/prepara.py'), 'exec'), namespace)
    data = namespace['main']()
    data['pelli'] = (OUT/'pelli.lua').read_text()
    data['personaggio'] = ['apprendista']
    # Facce extra disponibili nello schema della sola anteprima, con fallback testa.
    definitions = ''.join(f'\n\t\t{n} = {{ img = "apprendista_{n}", x = 0, y = 0, w = 1, h = 1 }},' for n in EXTRA)
    data['diavoletto'] = data['diavoletto'].replace('pezzi = {', 'pezzi = {'+definitions, 1)
    for p in (OUT/'png/2x').glob('*.png'):
        data['immagini'][p.stem] = 'data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
    template = (ROOT/'strumenti/animazioni/editor.html').read_text()
    template = re.sub(r'<link rel="stylesheet" href="https://fonts.googleapis.com/[^>]+>', '', template)
    template = template.replace('<title>Animazioni del diavoletto</title>', '<title>WB-009 · prova apprendista</title>')
    template = template.replace('<h1>MegaBlast · <span>animazioni</span></h1>', '<h1>WB-009 · <span>prova apprendista</span></h1>')
    template = re.sub(r'<link rel="preconnect"[^>]+>', '', template)
    template = template.replace('/*DATI*/', json.dumps(data, ensure_ascii=False).replace('</', '<\\/'))
    (OUT/'editor.html').write_text(template)


def main():
    for d in ['svg', 'png/1x', 'png/2x', 'png/3x', 'pelli']:
        (OUT/d).mkdir(parents=True, exist_ok=True)
    TG.ASSETS, TG.JSON, TG.LUA = str(OUT/'png/1x'), str(OUT/'pelli'), str(OUT/'pelli.lua')
    TG.salva, TG.tinta = save, team
    # Nessuna riscrittura dell'atlante del gioco.
    TG.ST.DV.scrivi_atlante = lambda: None
    TG.taglia(str(ART/'4_foglio_pezzi.png'), 'apprendista', 'personaggio', False, True, ['ala'])
    skin_path = OUT/'pelli/apprendista.json'
    skin = json.loads(skin_path.read_text())
    F = json.loads(Path(TG.ST.FOGLIO).read_text())
    # Le cinque teste sono in una fila, non nelle caselle dello stampino.
    a = TG.fondo_via(Image.open(ART/'5_teste_extra.png'))
    from scipy.ndimage import label
    labels, count = label(a[..., 3] > 128)
    masks = [labels == i for i in range(1, count+1) if (labels == i).sum() > a.shape[0]*a.shape[1]*.001]
    masks.sort(key=lambda m: np.nonzero(m)[1].mean())
    if len(masks) != 5:
        raise ValueError(f'Attese cinque teste extra, trovate {len(masks)}')
    for name, mask in zip(EXTRA, masks):
        ys, xs = np.nonzero(mask)
        pz = a[ys.min():ys.max()+1, xs.min():xs.max()+1].copy()
        pz[~mask[ys.min():ys.max()+1, xs.min():xs.max()+1], 3] = 0
        pz, perno, _ = TG.monta(pz, 'testa', F)
        TG.metti(skin['pezzi'], pz, 'apprendista', name, perno, F['scala'], TG.leggi_diavoletto()['px'], False)
    skin_path.write_text(json.dumps(skin, indent=2)+'\n')
    # Anche l'ala vuota deriva dall'SVG, alle tre densità.
    empty = np.zeros((2, 2, 4), np.float32)
    save(empty, 'apprendista', 'ala', 0, 0, 1, 1)
    TG.rifai()
    for p in (OUT/'svg').glob('*.svg'):
        check_svg(p.read_text())
    (OUT/'controlli.json').write_text(json.dumps({'palette': PALETTE, 'svg': CHECKS}, indent=2)+'\n')
    build_editor()
    print('OK: SVG verificati, PNG 1x/2x/3x ed editor in', OUT)


if __name__ == '__main__':
    main()
