# Le icone dei tipi di livello (Sergio, 6 nov: sulle carte della CAMPAGNA e sulla cartolina,
# col colore del tipo; client/ui/level_types.lua): forme piene a vettori, bianche con i buchi
# trasparenti, il colore lo mette il codice (l'inchiostro scuro sull'etichetta colorata).
# Due misure per tipo, come la stella: tipo_<nome>.png a 128 px e tipo_<nome>_p.png a 48
# (l'atlas dell'interfaccia non ha mipmap: la grande rimpicciolita molto fa gli scalini).
# Serve cairosvg: pip install cairosvg
#
#   python3 tools/grafica/icone_tipi.py      (poi le immagini nuove vanno in client/ui/ui.atlas)
import io, os
import cairosvg
import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(QUI, "..", "..", "client", "assets", "ui")


def testa(cx, cy, r, f, b, staccata):
    """Una testa coi corni e le spalle; staccata: con un bordo del colore del fondo, per
    quando sta davanti a un'altra."""
    def corno(s, c):
        return (f'<path d="M{cx + s * .2 * r} {cy - .98 * r} Q{cx + s * .75 * r} {cy - 1.2 * r} {cx + s * r} {cy - 1.8 * r} '
                f'Q{cx + s * 1.08 * r} {cy - 1.05 * r} {cx + s * .8 * r} {cy - .6 * r} Z" fill="{c}"/>')

    def una(c):
        return (f'<path d="M{cx - 1.45 * r} {cy + 2.9 * r} Q{cx - 1.45 * r} {cy + 1.15 * r} {cx} {cy + 1.15 * r} '
                f'Q{cx + 1.45 * r} {cy + 1.15 * r} {cx + 1.45 * r} {cy + 2.9 * r} Z" fill="{c}"/>'
                + corno(-1, c) + corno(1, c) + f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{c}"/>')
    bordo = f'<g stroke="{b}" stroke-width="9" stroke-linejoin="round">{una(b)}</g>' if staccata else ""
    return bordo + una(f)


def lame(f, b):
    s = (f'<path d="M50 4 L57 14 L57 62 L43 62 L43 14 Z" fill="{f}"/><rect x="31" y="61" width="38" height="9" rx="4" fill="{f}"/>'
         f'<rect x="45.5" y="69" width="9" height="16" fill="{f}"/><circle cx="50" cy="90" r="6.5" fill="{f}"/>')
    return (f'<g transform="rotate(42 50 50)" stroke="{b}" stroke-width="3">{s}</g>'
            f'<g transform="rotate(-42 50 50)" stroke="{b}" stroke-width="3">{s}</g>')


# viewBox 100 x 100: f il colore pieno, b i buchi
ICONE = {
    "corsa": lambda f, b: (f'<rect x="22" y="10" width="9" height="82" rx="4" fill="{f}"/>'
                           f'<path d="M31 14 C46 6 58 22 80 13 L80 53 C58 62 46 46 31 54 Z" fill="{f}"/>'),
    "bersagli": lambda f, b: "".join(f'<circle cx="50" cy="50" r="{r}" fill="{c}"/>'
                                     for r, c in ((41, f), (31, b), (22, f), (12, b), (6, f))),
    "duello": lame,
    "squadra": lambda f, b: testa(66, 44, 14, f, b, False) + testa(36, 50, 15, f, b, True),
    "orda": lambda f, b: testa(22, 46, 11, f, b, False) + testa(78, 46, 11, f, b, False) + testa(50, 52, 14, f, b, True),
    "resistenza": lambda f, b: (f'<rect x="22" y="8" width="56" height="10" rx="4" fill="{f}"/>'
                                f'<rect x="22" y="82" width="56" height="10" rx="4" fill="{f}"/>'
                                f'<path d="M28 18 H72 C72 36 58 42 56 50 C58 58 72 64 72 82 H28 C28 64 42 58 44 50 C42 42 28 36 28 18 Z" fill="{f}"/>'
                                f'<path d="M36 25 H64 C63 34 54 40 50 45 C46 40 37 34 36 25 Z" fill="{b}"/>'),
    "bottino": lambda f, b: (f'<path d="M28 18 H72 L90 40 L50 90 L10 40 Z" fill="{f}"/>'
                             f'<path d="M10 40 H90 M28 18 L39 40 L50 18 L61 40 L72 18 M39 40 L50 90 L61 40" fill="none" '
                             f'stroke="{b}" stroke-width="3.5" stroke-linejoin="round"/>'),
    "custode": lambda f, b: (f'<path d="M30 34 C14 30 8 16 12 4 C20 16 30 20 40 22 Z" fill="{f}"/>'
                             f'<path d="M70 34 C86 30 92 16 88 4 C80 16 70 20 60 22 Z" fill="{f}"/>'
                             f'<circle cx="50" cy="46" r="28" fill="{f}"/><rect x="34" y="60" width="32" height="26" rx="7" fill="{f}"/>'
                             f'<ellipse cx="39" cy="46" rx="8" ry="9" fill="{b}"/><ellipse cx="61" cy="46" rx="8" ry="9" fill="{b}"/>'
                             f'<path d="M50 56 L45 65 H55 Z" fill="{b}"/>'
                             f'<path d="M42 76 V86 M50 76 V86 M58 76 V86" stroke="{b}" stroke-width="3.5"/>'),
}


def disegna(nome, lato):
    # bianco pieno, buchi neri; poi il nero diventa trasparente (bordi morbidi compresi)
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{lato}" height="{lato}" viewBox="0 0 100 100">'
           f'<svg x="0" y="0" width="100" height="100" viewBox="0 0 100 100" overflow="hidden">'
           f'{ICONE[nome]("#ffffff", "#000000")}</svg></svg>')
    im = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert("RGBA")
    a = np.asarray(im, dtype=float)
    alfa = a[..., 3] * a[..., 0] / 255
    out = np.zeros(a.shape, np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.round(alfa).astype(np.uint8)
    return Image.fromarray(out)


def main():
    for nome in ICONE:
        for lato, suffisso in ((128, ""), (48, "_p")):
            f = os.path.join(OUT, "tipo_%s%s.png" % (nome, suffisso))
            disegna(nome, lato).save(f, optimize=True)
            print("scritta", os.path.normpath(f))


if __name__ == "__main__":
    main()
