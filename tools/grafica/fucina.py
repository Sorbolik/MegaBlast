# I pezzi e gli sfondi dell'interfaccia "Fucina contro Abisso" (client/ui/kit.lua),
# dai disegni di Codex (art/WB-022, i pezzi piccoli di art/WB-029).
#   python3 tools/grafica/fucina.py
# Scrive:
#   client/assets/fucina/*.png          i pezzi senza il verde, per l'atlante fucina.
#       Un pezzo lungo (lingotto, piastre, scheggia, piastrina) e' in tre parti:
#       _sx e _dx interi, _cx il mezzo, che il gioco allunga solo in largo. Cosi' i
#       bordi non si deformano mai e restano al doppio della misura sullo schermo.
#       Il pannello e' in nove parti (angoli interi, lati allungati in un verso).
#   client/assets/fette/*.png, client/ui/fette.atlas, client/ui/slices.lua   le nove fette
#       dei gironi (art/WB-026)
#   client/paintings/backdrops/*.jpg, client/ui/backdrops.lua   gli sfondi dei menu
#       (art/WB-028 e la campagna di art/WB-027)
#   client/ui/pieces.lua                le misure di ogni pezzo (generato)
#   client/ui/fucina.atlas              l'atlante (generato)
# Servono numpy, scipy e Pillow.
import os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..", "..")
ART = os.path.join(RADICE, "art")
OUT = os.path.join(RADICE, "client", "assets", "fucina")


def senza_verde(percorso):
    a = np.array(Image.open(percorso).convert("RGB")).astype(float)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    m = np.maximum(r, b)
    ex = g - m
    alfa = 1 - np.clip((ex - 30) / 110, 0, 1)
    g2 = np.where(ex > 0, m, g)
    return np.dstack([r, g2, b, alfa * 255]).astype(np.uint8)


def pezzi(o, minimo=2000):
    lab, _ = ndi.label(ndi.binary_dilation(o[..., 3] > 40, iterations=3))
    res = []
    for i, sl in enumerate(ndi.find_objects(lab)):
        if (lab[sl] == i + 1).sum() < minimo:
            continue
        res.append((sl[0].start, sl[1].start, o[sl]))
    return res


def caldo(arr):
    a = arr.astype(float)
    lum = a[..., :3].mean(axis=2)
    tappe = [(0, (242, 100, 25)), (22, (242, 100, 25)), (38, (77, 33, 16)), (60, (92, 40, 18)), (110, (255, 183, 3)), (255, (255, 230, 150))]
    out = a.copy()
    for c in range(3):
        out[..., c] = np.interp(lum, [s[0] for s in tappe], [s[1][c] for s in tappe])
    return out.astype(np.uint8)


def alta(arr, h):
    im = Image.fromarray(arr, "RGBA")
    if im.size[1] > h:
        im = im.resize((round(im.size[0] * h / im.size[1]), h), Image.LANCZOS)
    return im


def salva(im, nome):
    im.save(os.path.join(OUT, nome + ".png"), optimize=True)


MISURE = {}


def intero(nome, arr, h):
    im = alta(arr, h)
    salva(im, nome)
    MISURE[nome] = (im.size[0], im.size[1])


def tre(nome, arr, h, capo=0.24):
    """Un pezzo lungo in tre parti: i due capi interi e la striscia in mezzo."""
    im = alta(arr, h)
    w = im.size[0]
    c = round(w * capo)
    salva(im.crop((0, 0, c, h)), nome + "_sx")
    salva(im.crop((w - c, 0, w, h)), nome + "_dx")
    # il mezzo intero, non una colonna ripetuta: i pezzi sono storti apposta, e solo
    # cosi' i bordi continuano senza scalini dove un capo finisce (Sergio, 12 nov)
    salva(im.crop((c, 0, w - c, h)), nome + "_cx")
    MISURE[nome] = (w, h, c)
    if nome not in ("lingotto", "guscio", "barra_brace", "barra_gelo", "barra_chiara"):    # (sfumato: la sua scritta la mette kit.action)
        SPAZI[nome] = spazio(im)


SPAZI = {}


def spazio(im):
    """Dove c'e' piu' spazio per scrivere su un pezzo lungo: il rettangolo piu' grande
    di tinta piena, lontano da bordo, borchie e graffi (Sergio, 12 nov: le scritte
    dove c'e' piu' spazio, mai sui bordi). Torna i margini (sinistra, alto, destra, basso)."""
    a = np.asarray(im).astype(float)
    h, w = a.shape[:2]
    tinta = np.median(a[int(h * 0.4):int(h * 0.6), int(w * 0.35):int(w * 0.65), :3].reshape(-1, 3), axis=0)
    piena = (a[..., 3] > 250) & (np.abs(a[..., :3] - tinta).sum(axis=2) < 36)
    piena = ndi.binary_erosion(piena, iterations=max(2, h // 40))
    meglio, dove = 0, (0, 0, w, h)
    alte = np.zeros(w, int)
    for y in range(h):
        alte = np.where(piena[y], alte + 1, 0)
        pila = []
        for x in range(w + 1):
            v = alte[x] if x < w else 0
            da = x
            while pila and pila[-1][1] >= v:
                da, alt = pila.pop()
                # alto almeno il 42% del pezzo: ci stanno un nome e la sua riga
                if alt >= h * 0.42 and alt * (x - da) > meglio:
                    meglio, dove = alt * (x - da), (da, y - alt + 1, x, y + 1)
            pila.append((da, v))
    return (dove[0], dove[1], w - dove[2], h - dove[3])


def nove(nome, arr, lato, angolo=0.2):
    im = alta(arr, lato).resize((lato, lato), Image.LANCZOS)
    c = round(lato * angolo)
    xs = [(0, c), (c, lato - c), (lato - c, lato)]
    k = 1
    for (y0, y1) in xs:
        for (x0, x1) in xs:
            p = im.crop((x0, y0, x1, y1))
            salva(p, "%s_%d" % (nome, k))
            k += 1
    MISURE[nome] = (lato, lato, c)


def fai_pezzi():
    p = os.path.join(ART, "WB-022")
    tre("lingotto", pezzi(senza_verde(os.path.join(p, "pezzo_lingotto_1.png")))[0][2], 320, 0.2)
    tre("scheggia", pezzi(senza_verde(os.path.join(p, "pezzo_ghiaccio.png")))[0][2], 200, 0.2)
    pan = pezzi(senza_verde(os.path.join(p, "pezzo_pannello.png")))[0][2]
    nove("pannello", pan, 480)
    # il bordo caldo di una carta scelta e la targa chiara alta (un ritratto)
    nove("pannello_caldo", caldo(pan), 480)
    # (il pannello e' piu' scuro delle piastre: schiarito prima, cosi' viene avorio)
    su = pan.astype(float)
    su[..., :3] = np.where(su[..., :3].mean(axis=2, keepdims=True) > 18, su[..., :3] + 30, su[..., :3])
    nove("pannello_chiaro", chiaro(np.clip(su, 0, 255).astype(np.uint8)), 480)
    cs = sorted(pezzi(senza_verde(os.path.join(p, "pezzo_piastre.png"))), key=lambda t: t[0])
    for nome, t in zip(["piastra_freccia", "piastra_storta", "piastra_stendardo"], cs):
        tre(nome, t[2], 200)
    tre("piastra_calda", caldo(cs[1][2]), 200)
    tre("piastra_chiara", chiaro(cs[1][2]), 200)
    cs = pezzi(senza_verde(os.path.join(p, "pezzo_piccoli.png")), 800)
    ymid = np.mean([t[0] for t in cs])
    su = sorted([t for t in cs if t[0] < ymid], key=lambda t: t[1])
    giu = sorted([t for t in cs if t[0] >= ymid], key=lambda t: t[1])
    tre("piastrina", su[0][2], 120, 0.3)
    tre("piastrina_calda", caldo(su[0][2]), 120, 0.3)
    tre("piastrina_chiara", chiaro(su[0][2]), 120, 0.3)
    for nome, t in zip(["indietro", "brace", "fiamma"], su[1:]):
        intero(nome, t[2], 120)
    for nome, t in zip(["brace_spenta", "lucchetto", "scaglia", "gemma"], giu):
        intero(nome, t[2], 120)


def griglia(percorso, per_riga, minimo=1500):
    """I pezzi di un foglio in ordine di lettura: righe dall'alto, in ogni riga da sinistra."""
    cs = sorted(pezzi(senza_verde(percorso), minimo), key=lambda t: t[0])
    out = []
    for n in per_riga:
        out += sorted(cs[:n], key=lambda t: t[1])
        cs = cs[n:]
    return [t[2] for t in out]


def neutro(arr):
    """Un pezzo colorato fatto chiaro e senza tinta (la china resta): il gioco gli da' il colore."""
    a = arr.astype(float)
    lum = a[..., :3].max(axis=2)
    v = np.interp(lum, [0, 40, 150, 255], [10, 10, 225, 255])
    out = a.copy()
    for c in range(3):
        out[..., c] = v
    return out.astype(np.uint8)


def fai_piccoli():
    """I pezzi piccoli di WB-029: segni, barre e tacche, cornici tonde, linguetta."""
    p = os.path.join(ART, "WB-029")
    segni = griglia(os.path.join(p, "pezzo_segni_1.png"), [3, 3])
    for nome, a in zip(["stella", "stella_spenta", "medaglia", "ingranaggio", "corona", "freccia"], segni):
        intero(nome, a, 128)
    barre = griglia(os.path.join(p, "pezzo_barre_1.png"), [1, 1, 1, 1, 1], 600)
    tre("guscio", barre[0], 64, 0.12)
    tre("barra_brace", barre[1], 44, 0.1)
    tre("barra_gelo", barre[2], 44, 0.1)
    tre("barra_chiara", neutro(barre[1]), 44, 0.1)
    intero("tacca", barre[3], 72)
    tondi = griglia(os.path.join(p, "pezzo_tondi_1.png"), [2, 2])
    for nome, a in zip(["tondo_ferro", "tondo_oro", "tondo_gelo"], tondi):
        intero(nome, a, 200)
    tre("linguetta", tondi[3], 120, 0.3)
    tre("linguetta_chiara", chiaro(tondi[3]), 120, 0.3)


def chiaro(arr):
    """La piastra chiara (il nome del giocatore, la scelta fatta): avorio, china fuori."""
    a = arr.astype(float)
    lum = a[..., :3].mean(axis=2)
    tappe = [(0, (10, 8, 11)), (22, (10, 8, 11)), (38, (201, 190, 174)), (60, (244, 236, 225)), (110, (255, 250, 240)), (255, (255, 255, 255))]
    out = a.copy()
    for c in range(3):
        out[..., c] = np.interp(lum, [s[0] for s in tappe], [s[1][c] for s in tappe])
    return out.astype(np.uint8)


def fai_filo():
    """Il filo: brace a sinistra, gelo a destra (il gioco lo allunga solo in largo)."""
    tappe = [(0, (242, 100, 25)), (0.3, (255, 183, 3)), (0.5, (255, 243, 176)), (0.7, (202, 240, 248)), (1, (56, 182, 255))]
    x = np.linspace(0, 1, 256)
    riga = np.stack([np.interp(x, [t[0] for t in tappe], [t[1][c] for t in tappe]) for c in range(3)], axis=1)
    im = np.zeros((4, 256, 4), np.uint8)
    im[..., :3] = riga[None, :, :]
    im[..., 3] = 255
    salva(Image.fromarray(im, "RGBA"), "filo")


FETTE = ["limbo", "lussuria", "gola", "avarizia", "ira", "eresia", "violenza", "frode", "tradimento"]
# quanto e' larga una fetta nell'atlante: il doppio di come il gioco la mostra
# da vicino (client/menu/campaign.lua, SLICE_W), tre per riga in 4096
FETTA_W = 1340


def fai_fette():
    """Le nove fette dei gironi (WB-026): senza verde, tagliate al disegno, in un atlante loro."""
    out = os.path.join(RADICE, "client", "assets", "fette")
    os.makedirs(out, exist_ok=True)
    righe = []
    for nome in FETTE:
        o = senza_verde(os.path.join(ART, "WB-026", "fetta_%s.png" % nome))
        ys, xs = np.where(o[..., 3] > 40)
        im = Image.fromarray(o[ys.min():ys.max() + 1, xs.min():xs.max() + 1], "RGBA")
        im = im.resize((FETTA_W, round(im.size[1] * FETTA_W / im.size[0])), Image.LANCZOS)
        # colori piatti: 256 colori bastano e la fetta pesa un terzo (l'APK ha il tetto a 50 MB)
        im.quantize(256, method=Image.FASTOCTREE, dither=Image.NONE).save(os.path.join(out, "fetta_%s.png" % nome), optimize=True)
        righe.append((nome, im.size))
    with open(os.path.join(RADICE, "client", "ui", "fette.atlas"), "w") as f:
        for nome, _ in righe:
            f.write('images {\n  image: "/assets/fette/fetta_%s.png"\n}\n' % nome)
        f.write("margin: 2\nextrude_borders: 2\ninner_padding: 0\n")
    with open(os.path.join(RADICE, "client", "ui", "slices.lua"), "w") as f:
        f.write("-- Generated by tools/grafica/fucina.py: the slices of the circles (atlas fette),\n")
        f.write("-- from the first down: the image and its size in pixels.\nreturn {\n")
        for nome, (w, h) in righe:
            f.write('\t{ image = "fetta_%s", w = %d, h = %d },\n' % (nome, w, h))
        f.write("}\n")


LUOGHI = ["cortile", "forgia", "limbo", "lussuria", "gola", "avarizia", "ira", "eresia", "violenza", "frode", "tradimento"]
SFONDI = ["home", "armeria", "allenamento", "eventi", "gioca", "diavoletto", "impostazioni", "podio"]


def fai_sfondi():
    """Gli sfondi dei menu (WB-028, e la campagna di WB-027): un dipinto 16:9 per
    schermata, JPEG in client/paintings/backdrops (il gioco ne carica uno alla volta).
    Scrive anche a che altezza e' il pavimento dipinto: il gioco lo mette sul filo."""
    out = os.path.join(RADICE, "client", "paintings", "backdrops")
    os.makedirs(out, exist_ok=True)
    fogli = [(n, os.path.join(ART, "WB-028", "sfondo_%s.png" % n)) for n in SFONDI]
    fogli.append(("campagna", os.path.join(ART, "WB-027", "sfondo_campagna_A.png")))
    # il posto della campagna a cui e' arrivato il giocatore, dietro a ogni schermata
    # (Sergio, 13 nov; stile fumetto di WB-030, gli altri di WB-031): solo quelli consegnati
    for luogo in LUOGHI:
        for wb in ("WB-030", "WB-031"):
            percorso = os.path.join(ART, wb, "sfondo_home_%s%s.png" % (luogo, "_fumetto" if wb == "WB-030" else ""))
            if os.path.exists(percorso):
                fogli.append(("luogo_" + luogo, percorso))
                break
    righe = []
    for nome, percorso in fogli:
        # alla risoluzione del disegno, senza rimpicciolire, e quasi senza perdita
        # (Sergio, 12 nov: «usa la massima risoluzione»)
        im = Image.open(percorso).convert("RGB")
        im.save(os.path.join(out, nome + ".jpg"), quality=95, subsampling=0, optimize=True)
        a = np.asarray(im.convert("L")).astype(float)
        h, w = a.shape
        fascia = a[int(h * 0.72):int(h * 0.95), int(w * 0.25):int(w * 0.75)]
        y = int(h * 0.72) + int(np.abs(np.diff(fascia, axis=0)).mean(axis=1).argmax())
        righe.append((nome, (h - y) / h))
    with open(os.path.join(RADICE, "client", "ui", "backdrops.lua"), "w") as f:
        f.write("-- Generated by tools/grafica/fucina.py: the painted backdrop of each menu\n")
        f.write("-- (/paintings/backdrops/<name>.jpg) and how high its painted floor is, from the\n")
        f.write("-- bottom, as a part of its height: the game puts it on the thread.\nreturn {\n")
        for nome, pav in righe:
            f.write("\t%s = %.3f,\n" % (nome, pav))
        f.write("}\n")


def fai_atlante():
    nomi = sorted(f for f in os.listdir(OUT) if f.endswith(".png"))
    with open(os.path.join(RADICE, "client", "ui", "fucina.atlas"), "w") as f:
        for n in nomi:
            f.write('images {\n  image: "/assets/fucina/%s"\n}\n' % n)
        f.write("margin: 2\nextrude_borders: 2\ninner_padding: 0\n")


def fai_misure():
    with open(os.path.join(RADICE, "client", "ui", "pieces.lua"), "w") as f:
        f.write("-- Generated by tools/grafica/fucina.py: the size in pixels of every piece of the\n")
        f.write("-- fucina atlas (w, h and, for the pieces in three or nine parts, the cap c;\n-- box: the margins left, top, right, bottom of the room to write in).\nreturn {\n")
        for k in sorted(MISURE):
            m = MISURE[k]
            box = k in SPAZI and ", box = { %d, %d, %d, %d }" % SPAZI[k] or ""
            f.write("\t%s = { w = %d, h = %d%s%s },\n" % (k, m[0], m[1], len(m) > 2 and ", c = %d" % m[2] or "", box))
        f.write("}\n")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    fai_pezzi()
    fai_piccoli()
    fai_fette()
    fai_sfondi()
    fai_filo()
    fai_misure()
    fai_atlante()
    print("OK")
