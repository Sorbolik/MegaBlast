# La freccia di ferro battuto sopra il nome di chi è di turno (scheda WB-010,
# scelta di Sergio del 2 nov). Taglia un fotogramma dal foglio di ChatGPT
# (art/WB-010/p2_freccia_foglio.png, sfondo magenta, riga blu sopra) e lo
# divide in tre strati, così la brace prende il colore di ogni squadra (sono
# quattro, il foglio ne ha due):
#   freccia_ferro.png  il ferro con la fessura spenta (scura)
#   freccia_brace.png  la brace in bianco con le sue venature: il gioco la tinge
#                      col colore della squadra e la fa pulsare
#   freccia_cuore.png  il cuore bianco della brace, che si accende al massimo
# Il gioco (battaglia/freccia.lua) li mette uno sopra l'altro e fa dondolare la
# freccia. Scrive client/assets/fx/freccia_*.png (vanno in battaglia.atlas).
#
# python3 strumenti/grafica/freccia.py
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..", "..")
FOGLIO = os.path.join(RADICE, "art", "WB-010", "p2_freccia_foglio.png")
OUT = os.path.join(RADICE, "client", "assets", "fx")

# il terzo fotogramma della riga blu: il più acceso, con la fessura più piena
RITAGLIO = (814, 183, 1092, 447)
LARGO = 128          # pixel della freccia nel gioco (larga 28 unità nella targa)
SPENTA = np.array([34.0, 26.0, 26.0])  # la fessura senza brace: carbone


def filtro(m, f):
    return np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(f)).astype(float) / 255


# i buchi di una maschera riempiti: quello che non si raggiunge dal bordo
def riempi(m):
    im = Image.fromarray(np.pad(m, 1).astype(np.uint8) * 255).copy()
    ImageDraw.floodfill(im, (0, 0), 128)
    return (np.asarray(im)[1:-1, 1:-1] != 128).astype(float)


def main():
    im = np.asarray(Image.open(FOGLIO).convert("RGB").crop(RITAGLIO)).astype(float)
    r, g, b = im[..., 0], im[..., 1], im[..., 2]

    # lo sfondo: quanto il pixel è magenta (il foglio non è #FF00FF pieno). Il
    # bordo è scuro: dove si mescola al magenta lo si toglie e resta il contorno
    magenta = np.clip((np.minimum(r, b) - g - 60) / 120, 0, 1)
    alfa = 1 - magenta
    bg = np.array([253.0, 4.0, 251.0])
    a3 = np.maximum(alfa, 1e-3)[..., None]
    rgb = np.clip((im - (1 - alfa)[..., None] * bg) / a3, 0, 255)
    rgb[alfa < 0.02] = 0

    # la brace: dov'è blu (b più di r: anche l'azzurro quasi bianco; il ferro è un grigio caldo). La fessura è la zona blu piena (chiusa e un po'
    # allargata, così ci sta anche il cuore quasi bianco); fuori resta l'alone
    blu = np.clip((b - r - 10) / 80, 0, 1) * alfa
    fessura = filtro(riempi(filtro(blu > 0.7, ImageFilter.MaxFilter(3)) > 0.5), ImageFilter.MinFilter(3))
    fessura = filtro(fessura, ImageFilter.GaussianBlur(1.0))
    luce = (0.3 * r + 0.55 * g + 0.15 * b) / 255

    # brace in bianco: dentro la fessura la luce (le venature restano scure),
    # fuori l'alone blu, più leggero
    brace = np.clip(np.maximum(fessura * np.clip(0.35 + luce * 1.1, 0, 1), blu * 0.7), 0, 1)
    # il cuore: i punti quasi bianchi in fondo alla fessura
    cuore = fessura * np.clip((np.minimum(r, g) - 110) / 110, 0, 1)

    # il ferro: la fessura spenta, l'alone sul ferro tolto (il pixel torna grigio)
    grigio = (0.3 * r + 0.55 * g + 0.15 * b)[..., None] * np.ones(3)
    ferro = rgb * (1 - blu[..., None]) + grigio * blu[..., None]
    ferro = ferro * (1 - fessura[..., None]) + SPENTA * fessura[..., None]

    h = round(LARGO * im.shape[0] / im.shape[1])
    os.makedirs(OUT, exist_ok=True)

    def salva(nome, colore, a):
        px = np.dstack([colore, a * 255]).clip(0, 255).astype(np.uint8)
        Image.fromarray(px, "RGBA").resize((LARGO, h), Image.LANCZOS).save(os.path.join(OUT, nome + ".png"))
        print("scritto", nome, LARGO, "x", h)

    bianco = np.full(im.shape, 255.0)
    salva("freccia_ferro", ferro, alfa)
    salva("freccia_brace", bianco, brace * alfa)
    salva("freccia_cuore", bianco, cuore * alfa)


if __name__ == "__main__":
    main()
