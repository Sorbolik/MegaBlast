#!/usr/bin/env python3
"""Un foglio di pezzi in bianco e nero ricalcato in vettoriale (potrace).

Il disegno si divide in due strati: la sagoma intera (tutto ciò che non è il
fondo magenta) in bianco, e sopra il nero. Ognuno si ricalca con potrace in
curve, e il foglio vettoriale si riscrive in SVG e in PNG su magenta (rifatto
dall'SVG con cairosvg, al doppio della misura): il PNG si dà a pezzi_liberi.py
come il foglio originale.

  python3 tools/stampino/vettoriale.py FOGLIO.jpg USCITA.svg USCITA.png

A colori, con una tavolozza (tools/stampino/tavolozze/<nome>.json): ogni
pixel va al colore più vicino della tavolozza, ogni colore diventa uno strato
ricalcato, dal basso (il primo colore riempie tutta la sagoma) al nero del
contorno, sopra a tutto. Nell'SVG ci sono solo i colori della tavolozza, al
codice esatto: lo controlla, e si ferma se ne trova un altro. Il PNG (su
magenta, alla misura dello stampino) si dà a taglia.py.

  python3 tools/stampino/vettoriale.py --tavolozza TAVOLOZZA.json FOGLIO.png USCITA.svg USCITA.png [RITOCCHI.json] [--senza colore,colore]

--senza toglie dei colori della tavolozza per quel foglio (in un foglio di teste
non c'è la camicia: i toni del muso non ci finiscono dentro).
  python3 tools/stampino/vettoriale.py --controlla TAVOLOZZA.json FILE.svg...

Serve potrace (apt install potrace), cairosvg e scipy.
"""
import os
import re
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
import taglia as TG  # noqa: E402

SCALA = 2           # il PNG rifatto è il doppio del foglio
NERO = 110          # sotto questa luminosità è nero


def liscia(valori, soglia):
    """Una maschera dal foglio raddoppiato e sfocato appena: i bordi della jpg
    (scalini e sbavature) non diventano curve storte."""
    from PIL import ImageFilter
    im = Image.fromarray(np.clip(valori, 0, 255).astype(np.uint8))
    im = im.resize((im.width * 2, im.height * 2), Image.LANCZOS).filter(ImageFilter.GaussianBlur(2.5))
    return np.asarray(im) > soglia


def ricalca(maschera, colore):
    """Una maschera in curve: i <path> di potrace dentro un gruppo del colore."""
    with tempfile.TemporaryDirectory() as d:
        pbm = os.path.join(d, "m.pbm")
        svg = os.path.join(d, "m.svg")
        Image.fromarray(np.where(maschera, 0, 255).astype(np.uint8)).convert("1").save(pbm)
        subprocess.run(["potrace", pbm, "-s", "-o", svg, "--turdsize", "6",
                        "--alphamax", "1.0", "--opttolerance", "0.2", "--unit", "1"], check=True)
        testo = open(svg).read()
    g = re.search(r"<g transform=\"([^\"]*)\"[^>]*>(.*?)</g>", testo, re.S)
    return f'<g transform="{g.group(1)}" fill="{colore}" stroke="none">{g.group(2)}</g>'


LATO = 3072         # il foglio a colori esce largo quanto lo stampino


class Tavolozza(list):
    """I colori (nome, codice) e l'area minima delle macchie, se c'è."""
    macchie = 0         # area minima di una macchia di colore ("macchie_min")
    macchie_ombra = 0   # e di un'ombra ("macchie_ombra_min")
    righe = 110         # sotto questo canale più forte un pixel scuro può essere riga


def leggi_tavolozza(f):
    import json
    with open(f) as fh:
        d = json.load(fh)
    tav = Tavolozza((n, c.upper()) for n, c in d["colori"])
    tav.macchie = d.get("macchie_min", 0)
    tav.macchie_ombra = d.get("macchie_ombra_min", tav.macchie)
    tav.righe = d.get("righe_max", 110)
    return tav


def rgb(c):
    return np.array([int(c[i:i + 2], 16) for i in (1, 3, 5)], np.float32)


def giallo(r, g, b):
    """Il giallo saturo degli occhi (anche più scuro, in ombra)."""
    return (r > 180) & (g > 0.72 * r) & (b < 0.45 * r)


def classi(a, tav):
    """Per ogni pixel della sagoma l'indice del colore della tavolozza (-1 fuori)."""
    from scipy import ndimage
    nomi = [n for n, _ in tav]
    cols = np.stack([rgb(c) for _, c in tav])
    dentro = a[..., 3] > 128
    px = a[..., :3]
    # distanza pesata come l'occhio (verde conta di più)
    w = np.array([0.30, 0.59, 0.11], np.float32) * 3
    d = (((px[:, :, None, :] - cols[None, None]) ** 2) * w).sum(-1)
    lab = d.argmin(-1)
    # crema e corna quasi uguali: decide la macchia intera. Il muso e la pancia
    # stanno dentro la pelle, corna e unghie sporgono (intorno hanno contorno e fondo)
    fam = {"crema": ("crema", "crema_ombra"), "corna": ("corna", "corna_ombra")}
    if all(n in nomi for f in fam.values() for n in f):
        ids = [nomi.index(n) for f in fam.values() for n in f]
        pelle = np.isin(lab, [nomi.index("pelle"), nomi.index("pelle_ombra")]) if "pelle_ombra" in nomi else lab == 0
        m = np.isin(lab, ids) & dentro
        cc, n = ndimage.label(m)
        for k, sl in enumerate(ndimage.find_objects(cc), 1):
            y0, y1 = max(0, sl[0].start - 6), sl[0].stop + 6
            x0, x1 = max(0, sl[1].start - 6), sl[1].stop + 6
            r = cc[y0:y1, x0:x1] == k
            bordo = ndimage.binary_dilation(r, iterations=6) & ~r
            f = fam["crema"] if pelle[y0:y1, x0:x1][bordo].mean() > 0.25 else fam["corna"]
            chiaro, ombra = nomi.index(f[0]), nomi.index(f[1])
            p_ = px[y0:y1, x0:x1][r]
            dc = (((p_ - cols[chiaro]) ** 2) * w).sum(-1)
            do = (((p_ - cols[ombra]) ** 2) * w).sum(-1)
            sub = lab[y0:y1, x0:x1]
            sub[r] = np.where(dc <= do, chiaro, ombra)
    nero = nomi.index("nero")
    # gli occhi: il giallo saturo (anche quello più scuro dell'ombra in alto) è
    # occhio, non crema né corna
    if "occhi" in nomi:
        r_, g_, b_ = px[..., 0], px[..., 1], px[..., 2]
        gial = dentro & giallo(r_, g_, b_)
        # un altro giallo della tavolozza (i bottoni, le punte della fiamma) resta suo
        altri = [i for i, (n, c) in enumerate(tav) if n != "occhi" and giallo(*rgb(c))]
        gial &= ~np.isin(lab, altri)
        # solo le macchie grandi: i bordi sfumati fra crema e pelle non sono occhi
        cc, n = ndimage.label(gial)
        if n:
            area = ndimage.sum(gial, cc, range(1, n + 1))
            gial &= np.isin(cc, np.nonzero(area >= 400)[0] + 1)
        occhi = nomi.index("occhi")
        # fuori dagli occhi niente giallo: l'ombra della pancia va al colore più vicino dopo
        d2 = d.copy()
        d2[..., occhi] = np.inf
        lab = np.where((lab == occhi) & ~gial, d2.argmin(-1), lab)
        lab[gial] = occhi
    # le righe sottili (rughe, sopracciglia, naso, righe delle corna): i pixel
    # scuri, anche quelli sfumati ai lati della riga, che non fanno una macchia
    # grande (la bocca) sono riga nera; restano anche dopo la moda qui sotto
    # (scuro: quasi nero, non un colore scuro come l'ombra della pelle o la bocca)
    lum = px @ np.array([0.30, 0.59, 0.11], np.float32)
    scuro = dentro & (lum < 115) & (px.max(-1) < getattr(tav, "righe", 110))
    # i colori scuri della tavolozza (stivali, ombra delle bretelle) non sono righe;
    # la bocca sì, ai bordi (come per l'apprendista)
    veri = [i for i, (n, c) in enumerate(tav) if n not in ("nero", "bocca")
            and rgb(c).max() < 110 and rgb(c) @ np.array([0.30, 0.59, 0.11], np.float32) < 115]
    scuro &= ~np.isin(lab, veri)
    pieno = ndimage.binary_opening(scuro, iterations=3)
    riga = scuro & ~pieno & (lab != nero)
    riga |= lab == nero
    # via i puntini isolati (meno di 12 pixel)
    cc, n = ndimage.label(riga)
    if n:
        area = ndimage.sum(riga, cc, range(1, n + 1))
        riga &= np.isin(cc, np.nonzero(area >= 12)[0] + 1)
    lab[riga] = nero
    # i fili di un colore (meno di 5 pixel di spessore) prendono il colore vicino
    via = np.zeros_like(dentro)
    for i in range(1, len(tav)):
        if i == nero:
            continue
        m = lab == i
        via |= m & ~ndimage.binary_opening(m, iterations=2)
    if via.any():
        _, (iy, ix) = ndimage.distance_transform_edt(via, return_indices=True)
        lab = lab[iy, ix]
    # le macchioline (meno di "macchie_min" pixel, se la tavolozza lo chiede):
    # sfumature e granelli di ChatGPT, prendono il colore intorno. Non il nero e
    # il bianco, che fanno righe e lucine piccole apposta
    if getattr(tav, "macchie", 0):
        via = np.zeros_like(dentro)
        for i, n in enumerate(nomi):
            if n in ("nero", "bianco"):
                continue
            cc, k = ndimage.label(lab == i)
            if k:
                area = ndimage.sum(lab == i, cc, range(1, k + 1))
                minimo = tav.macchie_ombra if n.endswith("_ombra") else tav.macchie
                via |= np.isin(cc, np.nonzero(area < minimo)[0] + 1)
        via &= dentro
        if via.any():
            # il colore più vicino che non è contorno: una macchiolina fra due righe
            # non diventa nera
            _, (iy, ix) = ndimage.distance_transform_edt(via | (lab == nero) | ~dentro, return_indices=True)
            lab = np.where(via, lab[iy, ix], lab)
    # moda su 5x5: via i pixel sparsi ai bordi fra due colori
    uno = np.stack([ndimage.uniform_filter((lab == i).astype(np.float32), 5) for i in range(len(tav))], -1)
    lab = uno.argmax(-1)
    lab[riga] = nero
    lab[~dentro] = -1
    return lab


def ritocca(lab, nomi, file):
    """I ritocchi a mano di un foglio (JSON accanto all'SVG): dentro ogni poligono
    (pixel del foglio largo LATO) il colore "da" diventa "a". Servono dove ChatGPT
    sbaglia una regola, per esempio il contorno nero sulle spalle del busto."""
    import json
    from PIL import ImageDraw
    with open(file) as f:
        rr = json.load(f)["ritocchi"]
    for r in rr:
        m = Image.new("1", (lab.shape[1], lab.shape[0]), 0)
        ImageDraw.Draw(m).polygon([tuple(p) for p in r["poligono"]], fill=1)
        m = np.asarray(m)
        for da in r["da"]:
            lab[m & (lab == nomi.index(da))] = nomi.index(r["a"])


SQUADRA = {"squadra": "#FFFFFF", "squadra_ombra": "#B4B4B4"}   # lo strato che il gioco tinge


def fai_strati(a, lab, tav, senza=()):
    """Gli strati ricalcati, dal basso: la sagoma del primo colore, un colore per
    strato (un filo più grandi, così fra due colori non resta la riga di quello
    sotto), il nero sopra a tutto."""
    from scipy import ndimage
    nomi = [n for n, _ in tav]
    nero = nomi.index("nero")
    sagoma = liscia(a[..., 3], 128)
    strati = [ricalca(sagoma, tav[0][1])]
    for i, (n, c) in enumerate(tav[1:], 1):
        if i == nero or n in senza:
            continue
        m = lab == i
        if m.sum() < 30:
            continue
        m = ndimage.binary_dilation(m, iterations=2) & (a[..., 3] > 128)
        strati.append(ricalca(liscia(m * 255.0, 128), c))
    if (lab == nero).any():
        strati.append(ricalca(sagoma & liscia((lab == nero) * 255.0, 128), tav[nero][1]))
    return strati


def svg_pezzo(a, tav, misura):
    """Un pezzo ritagliato (RGBA, grande) in SVG alla misura in pixel del gioco.
    Torna l'SVG del pezzo (senza il colore della squadra) e quello dello strato
    della squadra in grigi (bianco e ombra, come il PNG _tinta), o None."""
    lab = classi(a, tav)
    h, w = a.shape[:2]
    testa = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{misura[0]}" height="{misura[1]}" '
             f'viewBox="0 0 {2 * w} {2 * h}" preserveAspectRatio="none">\n')
    base = testa + "\n".join(fai_strati(a, lab, tav, senza=SQUADRA)) + "\n</svg>\n"
    controlla(base, tav, "pezzo")
    nomi = [n for n, _ in tav]
    nero = lab == nomi.index("nero")
    squadra = []
    for n, c in SQUADRA.items():
        if n in nomi and (lab == nomi.index(n)).sum() >= 30:
            squadra.append(ricalca(liscia(((lab == nomi.index(n)) & ~nero) * 255.0, 128), c))
    return base, (testa + "\n".join(squadra) + "\n</svg>\n") if squadra else None


def main_colori(tavolozza, foglio, uscita_svg, uscita_png, ritocchi=None, senza=()):
    tav = leggi_tavolozza(tavolozza)
    tav[:] = [c for c in tav if c[0] not in senza]
    im = Image.open(foglio).convert("RGBA")
    k = LATO / im.width
    im = im.resize((LATO, round(im.height * k)), Image.LANCZOS)
    a = TG.fondo_via(im)
    h, w = a.shape[:2]
    lab = classi(a, tav)
    nomi = [n for n, _ in tav]
    if ritocchi:
        ritocca(lab, nomi, ritocchi)
    strati = fai_strati(a, lab, tav)
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {2 * w} {2 * h}">\n'
           + "\n".join(strati) + "\n</svg>\n")
    controlla(svg, tav, uscita_svg)
    with open(uscita_svg, "w") as f:
        f.write(svg)
    import cairosvg
    import io
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=w, output_height=h)
    im = Image.open(io.BytesIO(png)).convert("RGBA")
    fondo = Image.new("RGBA", im.size, (255, 0, 255, 255))
    fondo.alpha_composite(im)
    fondo.convert("RGB").save(uscita_png)
    print("OK:", uscita_svg, uscita_png, f"({len(strati)} strati, solo colori della tavolozza)")


def controlla(svg, tav, nome):
    """Ogni riempimento e ogni tratto dell'SVG è un colore della tavolozza, al codice esatto."""
    ammessi = {c for _, c in tav} | {"NONE"}
    fuori = sorted({c.upper() for c in re.findall(r'(?:fill|stroke)="([^"]*)"', svg)} - ammessi)
    fuori += sorted({c.upper() for c in re.findall(r'(?:fill|stroke)\s*:\s*([^;"]+)', svg)} - ammessi)
    if fuori:
        sys.exit(f"{nome}: colori fuori dalla tavolozza: {', '.join(fuori)}")


def main():
    if len(sys.argv) >= 3 and sys.argv[1] == "--controlla":
        tav = leggi_tavolozza(sys.argv[2])
        for f in sys.argv[3:]:
            controlla(open(f).read(), tav, f)
        print("OK: solo colori della tavolozza in", len(sys.argv) - 3, "file")
        return
    args = sys.argv[1:]
    senza = ()
    if "--senza" in args:
        i = args.index("--senza")
        senza = tuple(args[i + 1].split(","))
        del args[i:i + 2]
    if len(args) in (5, 6) and args[0] == "--tavolozza":
        main_colori(*args[1:], senza=senza)
        return
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    foglio, uscita_svg, uscita_png = sys.argv[1:]
    a = TG.fondo_via(Image.open(foglio))
    h, w = a.shape[:2]
    lum = a[..., :3].mean(axis=2)
    sagoma = liscia(a[..., 3], 128)
    # nero: la sagoma meno il bianco, così non resta un filo bianco fuori dal contorno
    bianco = liscia(np.where(a[..., 3] > 128, lum, 0), NERO + 30)
    nero = sagoma & ~bianco
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {2 * w} {2 * h}">\n'
           + ricalca(sagoma, "#ffffff") + "\n" + ricalca(nero, "#000000") + "\n</svg>\n")
    with open(uscita_svg, "w") as f:
        f.write(svg)
    import cairosvg
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=w * SCALA, output_height=h * SCALA)
    import io
    im = Image.open(io.BytesIO(png)).convert("RGBA")
    fondo = Image.new("RGBA", im.size, (255, 0, 255, 255))
    fondo.alpha_composite(im)
    fondo.convert("RGB").save(uscita_png)
    print("OK:", uscita_svg, uscita_png)


if __name__ == "__main__":
    main()
