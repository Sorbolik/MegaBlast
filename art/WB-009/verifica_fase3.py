#!/usr/bin/env python3
"""Controlli ripetibili sugli artefatti WB-009, inclusi casi SVG non validi."""
import io
import json
from pathlib import Path

import cairosvg
import numpy as np
from PIL import Image

from fase3 import OUT, check_svg


def main():
    for invalid in [
        '<svg xmlns="http://www.w3.org/2000/svg"><path fill="#123456"/></svg>',
        '<svg xmlns="http://www.w3.org/2000/svg"><image href="source.png"/></svg>',
        '<svg xmlns="http://www.w3.org/2000/svg"><path style="fill:red"/></svg>',
    ]:
        try:
            check_svg(invalid)
        except ValueError:
            pass
        else:
            raise AssertionError('Accettato SVG fuori tavolozza o raster')
    files = sorted((OUT/'svg').glob('*.svg'))
    assert len(files) == 27, len(files)
    for p in files:
        check_svg(p.read_text())
        base = Image.open(OUT/'png/1x'/f'{p.stem}.png')
        for density in (1, 2, 3):
            png = Image.open(OUT/f'png/{density}x'/f'{p.stem}.png').convert('RGBA')
            assert png.size == (base.width*density, base.height*density), p
            expected = Image.open(io.BytesIO(cairosvg.svg2png(url=str(p), output_width=png.width,
                                                           output_height=png.height))).convert('RGBA')
            assert np.array_equal(np.asarray(png), np.asarray(expected)), p
    skin = json.loads((OUT/'pelli/apprendista.json').read_text())
    assert len([p for p in skin['pezzi'] if p.startswith('testa')]) == 9
    assert len(skin['coda']) == 5 and all(v > 0 for v in skin['coda'])
    assert len(skin['coda_riposo']) == 5
    assert Image.open(OUT/'png/1x/apprendista_ala.png').getextrema()[-1] == (0, 0)
    for piece in skin['pezzi'].values():
        assert (OUT/'png/1x'/f'{piece["img"]}.png').exists()
        if piece.get('tinta'):
            assert (OUT/'png/1x'/f'{piece["tinta"]}.png').exists()
    print('OK: 27 SVG, 81 PNG identici al rendering SVG, nove teste, coda e ala vuota.')


if __name__ == '__main__':
    main()
