"""La parete della voragine dietro la mappa dei gironi (Sergio, 18 nov: bozza G3).

Scrive client/paintings/backdrops/piatto_voragine.png: la parete di sinistra, a forme
piatte (due toni scuri), trasparente intorno. Il gioco la mette sul bordo vero di
sinistra e la sua copia specchiata a destra (client/ui/flat_backdrops.lua).
Disegnata a 4x e ridotta a 2x: i bordi sono lisci, i colori restano pieni.

    python3 tools/grafica/voragine.py
"""
from pathlib import Path
from PIL import Image, ImageDraw

RADICE = Path(__file__).resolve().parents[2]
USCITA = RADICE / "client/paintings/backdrops/piatto_voragine.png"

# misure in punti del gioco (quadro 1280 x 720): la parete va dalla riga arancione
# (612 dall'alto) fino a 360 sopra il quadro, per gli schermi alti
LARGO, SOPRA, RIGA = 300, 360, 612
PARETE, SPIGOLO = (0x1C, 0x13, 0x15), (0x21, 0x16, 0x18)
# i punti dall'alto del quadro: il bordo frastagliato della parete e quello davanti
FUORI = [(0, -SOPRA), (260, -SOPRA), (260, 0), (210, 90), (300, 160), (190, 260), (280, 340), (170, 430), (250, 520), (150, RIGA), (0, RIGA)]
DAVANTI = [(0, -SOPRA), (150, -SOPRA), (150, 120), (90, 220), (170, 300), (80, 400), (140, 480), (60, 560), (0, RIGA)]


def disegna(scala_finale=2, sovra=4):
    k = scala_finale * sovra
    im = Image.new("RGBA", (LARGO * k, (RIGA + SOPRA) * k), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for punti, colore in ((FUORI, PARETE), (DAVANTI, SPIGOLO)):
        d.polygon([(x * k, (y + SOPRA) * k) for x, y in punti], fill=colore + (255,))
    im = im.resize((LARGO * scala_finale, (RIGA + SOPRA) * scala_finale), Image.LANCZOS)
    # i colori restano pieni: solo l'alfa dei bordi è sfumata dalla riduzione
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a:
                colore = SPIGOLO if (r, g, b) != PARETE and abs(r - SPIGOLO[0]) <= abs(r - PARETE[0]) else PARETE
                px[x, y] = colore + (a,)
    return im


if __name__ == "__main__":
    disegna().save(USCITA, optimize=True)
    print(USCITA.relative_to(RADICE))
