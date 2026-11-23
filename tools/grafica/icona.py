"""L'icona del gioco su Android: la testa di Favilla nel disco di carta della
schermata d'ingresso (client/ui/entry.lua) sul fondo scuro della Forgia.

Dal disegno di Sergio (art/personaggi/favilla.png, 2328 x 2328), come
tools/grafica/ingresso.py, ma ritagliato a ogni misura direttamente dal
disegno grande (mai ingrandito):
- icona adattiva (Android 8+): primo piano 432 x 432 (il disco nella zona
  sicura, fuori trasparente), sfondo 432 x 432 pieno, monocromo (solo la sagoma
  di Favilla, per le icone a tema) nella risorsa dell'estensione client/vibra;
- icona classica (telefoni vecchi) da 36 a 192 px: fondo a quadrato arrotondato
  col disco sopra, in client/assets/icona/ (game.project, [android] app_icon_*);
- avvio (Sergio, 23 nov: far capire che il gioco è orizzontale): su Android 12+
  il disco si sdraia di 90 gradi nella schermata di avvio del telefono
  (avvio_giro_*.png, 288 dp con il disco da 160 dp, res/drawable/avvio_giro.xml);
  poi, e sui telefoni vecchi da subito, il fondo della finestra del gioco
  (avvio_disco.png, il disco dritto: la finestra è già orizzontale, quindi col
  telefono ancora in verticale Favilla si vede sdraiata).

    python3 tools/grafica/icona.py               # scrive i file del gioco
    python3 tools/grafica/icona.py --in CARTELLA # solo i PNG, in CARTELLA
"""
import argparse
import os
from PIL import Image, ImageDraw

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.normpath(os.path.join(QUI, "..", ".."))
ORIGINE = os.path.join(RADICE, "art", "personaggi", "favilla.png")
RES = os.path.join(RADICE, "client", "vibra", "res", "android", "res")
CLASSICA = os.path.join(RADICE, "client", "assets", "icona")

# il fondo: il colore medio della schermata d'ingresso (Sergio, 23 nov: "Ruggine")
FONDO = (0x54, 0x2c, 0x1b)
# la carta del disco: il bianco tinto come in entry.lua (CARD 0.94, 0.9, 0.82)
CARTA = (240, 230, 209)
# il disco occupa questa parte del lato (108 dp): 66 dp è la zona sicura
DISCO_ADATTIVA = 66 / 108
DISCO_CLASSICA = 0.80
MISURE_CLASSICHE = (36, 48, 72, 96, 144, 192)
# avvio, a xxxhdpi (4 px per dp): tela dell'icona animata 288 dp, disco 160 dp
AVVIO_TELA = 288 * 4
AVVIO_DISCO = 160 * 4
AVVIO_FOTOGRAMMI = 10        # dal dritto (0) allo sdraiato (90 gradi, orario)


def disegno():
    """Il disco di Favilla al massimo della risoluzione: (carta tinta, sagoma)."""
    im = Image.open(ORIGINE).convert("RGB")
    s = im.width / 1932          # le misure sono sul disegno a 1932 px (ingresso.py)
    d = ImageDraw.Draw(im)
    bianco = (255, 255, 255)
    d.rectangle([0, int(915 * s), int(760 * s), im.height], fill=bianco)
    d.rectangle([int(1195 * s), int(925 * s), im.width, im.height], fill=bianco)
    d.rectangle([0, int(1080 * s), im.width, im.height], fill=bianco)
    cx, cy, r = 1048 * s, 690 * s, 520 * s
    disco = im.crop((int(cx - r), int(cy - r), int(cx + r), int(cy + r)))
    # inchiostro = quanto è scuro il pixel; la carta prende il colore CARTA
    inchiostro = disco.convert("L").point(lambda v: 255 - v)
    carta = Image.new("RGB", disco.size, CARTA)
    nero = Image.new("RGB", disco.size, (0, 0, 0))
    tinto = Image.composite(nero, carta, inchiostro)
    return tinto, inchiostro


def cerchio(lato):
    m = Image.new("L", (lato * 4, lato * 4), 0)
    ImageDraw.Draw(m).ellipse([2, 2, lato * 4 - 3, lato * 4 - 3], fill=255)
    return m.resize((lato, lato), Image.LANCZOS)


def disco_a(tinto, lato):
    out = tinto.resize((lato, lato), Image.LANCZOS).convert("RGBA")
    out.putalpha(cerchio(lato))
    return out


def al_centro(pezzo, lato, fondo=(0, 0, 0, 0)):
    tela = Image.new("RGBA", (lato, lato), fondo)
    o = (lato - pezzo.width) // 2
    tela.alpha_composite(pezzo, (o, o))
    return tela


def adattiva(tinto, inchiostro, lato=432):
    d = round(lato * DISCO_ADATTIVA)
    primo = al_centro(disco_a(tinto, d), lato)
    sfondo = Image.new("RGBA", (lato, lato), FONDO + (255,))
    # monocromo: solo l'inchiostro dentro il disco (il telefono lo colora)
    sagoma = inchiostro.resize((d, d), Image.LANCZOS)
    sagoma = Image.composite(sagoma, Image.new("L", (d, d), 0), cerchio(d))
    mono = Image.new("RGBA", (d, d), (255, 255, 255, 0))
    mono.putalpha(sagoma)
    return primo, sfondo, al_centro(mono, lato)


def classica(tinto, lato):
    k = 4
    big = lato * k
    m = Image.new("L", (big, big), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, big - 1, big - 1], radius=int(big * 0.22), fill=255)
    tela = Image.new("RGBA", (lato, lato), FONDO + (255,))
    tela.putalpha(m.resize((lato, lato), Image.LANCZOS))
    tela.alpha_composite(disco_a(tinto, round(lato * DISCO_CLASSICA)),
                         ((lato - round(lato * DISCO_CLASSICA)) // 2,) * 2)
    return tela


def avvio(tinto):
    """I fotogrammi del disco che si sdraia e il disco dritto per la finestra."""
    grande = disco_a(tinto, round(tinto.width))   # alla misura del disegno, poi giù
    giro = []
    for i in range(AVVIO_FOTOGRAMMI + 1):
        t = i / AVVIO_FOTOGRAMMI
        ang = 90 * t * t * (3 - 2 * t)
        ruotato = grande.rotate(-ang, resample=Image.BICUBIC)
        giro.append(al_centro(ruotato.resize((AVVIO_DISCO,) * 2, Image.LANCZOS), AVVIO_TELA))
    return giro, disco_a(tinto, AVVIO_DISCO)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="cartella")
    ap.add_argument("--fondo", help="colore del fondo, es. 542c1b")
    a = ap.parse_args()
    global FONDO
    if a.fondo:
        FONDO = tuple(int(a.fondo[i:i + 2], 16) for i in (0, 2, 4))
    tinto, inchiostro = disegno()
    primo, sfondo, mono = adattiva(tinto, inchiostro)
    if a.cartella:
        uscite = {n: os.path.join(a.cartella, n) for n in
                  ("icon_primo_piano.png", "icon_sfondo.png", "icon_monocromo.png")}
        cla = a.cartella
    else:
        x = os.path.join(RES, "drawable-xxxhdpi")
        uscite = {n: os.path.join(x, n) for n in
                  ("icon_primo_piano.png", "icon_sfondo.png", "icon_monocromo.png")}
        cla = CLASSICA
    for p in list(uscite.values()) + [cla]:
        os.makedirs(os.path.dirname(p) if p.endswith(".png") else p, exist_ok=True)
    primo.save(uscite["icon_primo_piano.png"], optimize=True)
    sfondo.save(uscite["icon_sfondo.png"], optimize=True)
    mono.save(uscite["icon_monocromo.png"], optimize=True)
    for lato in MISURE_CLASSICHE:
        classica(tinto, lato).save(os.path.join(cla, "icona_%d.png" % lato), optimize=True)
    giro, dritto = avvio(tinto)
    cartella = a.cartella or os.path.join(RES, "drawable-xxxhdpi")
    for i, f in enumerate(giro):
        f.save(os.path.join(cartella, "avvio_giro_%02d.png" % i), optimize=True)
    dritto.save(os.path.join(cartella, "avvio_disco.png"), optimize=True)
    print("ok")


if __name__ == "__main__":
    main()
