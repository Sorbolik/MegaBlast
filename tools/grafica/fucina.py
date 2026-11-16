# I pezzi e gli sfondi dell'interfaccia "Fucina contro Abisso" (client/ui/kit.lua),
# dai disegni di Codex (art/WB-022, i pezzi piccoli di art/WB-029).
#   python3 tools/grafica/fucina.py
# Scrive:
#   client/assets/fucina/*.png          i pezzi senza il verde, per l'atlante fucina.
#       Un pezzo lungo (primario, piastre, scheggia, piastrina) e' in tre parti:
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
    if nome not in ("guscio", "barra_brace", "barra_gelo", "barra_chiara") and not nome.startswith("primario"):    # (sfumati, e il primario: la scritta la mette kit.action)
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
    # (il lingotto di WB-022 non c'e' piu': il pulsante primario e' quello di WB-052)
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


SCHERMATE = ["zaino", "armeria", "profilo", "eventi", "gioca_online", "campagna", "allenamento", "impostazioni"]


def fai_sfondi():
    """Gli sfondi dei menu: il posto della campagna a cui e' arrivato il giocatore,
    dietro a ogni schermata (Sergio, 13 nov; stile fumetto di WB-030, gli altri posti
    di WB-031). JPEG in client/paintings/backdrops/luogo_<posto>.jpg (il gioco ne carica
    uno alla volta). Scrive anche a che altezza e' il pavimento dipinto: il gioco lo
    mette sul filo."""
    out = os.path.join(RADICE, "client", "paintings", "backdrops")
    os.makedirs(out, exist_ok=True)
    righe = []
    for luogo in LUOGHI:
        nome = "sfondo_home_%s_fumetto.png" % luogo
        percorso = os.path.join(ART, "WB-030", nome)
        if not os.path.exists(percorso):
            percorso = os.path.join(ART, "WB-031", "sfondo_home_%s.png" % luogo)
        # alla risoluzione del disegno, senza rimpicciolire, e quasi senza perdita
        # (Sergio, 12 nov: «usa la massima risoluzione»)
        im = Image.open(percorso).convert("RGB")
        im.save(os.path.join(out, luogo + ".jpg"), quality=95, subsampling=0, optimize=True)
        a = np.asarray(im.convert("L")).astype(float)
        h, w = a.shape
        fascia = a[int(h * 0.72):int(h * 0.95), int(w * 0.25):int(w * 0.75)]
        y = int(h * 0.72) + int(np.abs(np.diff(fascia, axis=0)).mean(axis=1).argmax())
        righe.append((luogo, (h - y) / h))
    # lo sfondo di ogni schermata dei menu (WB-053, Sergio 15 nov): menu_<schermata>.jpg
    for schermata in SCHERMATE:
        im = Image.open(os.path.join(ART, "WB-053", "sfondo_menu_%s.png" % schermata)).convert("RGB")
        im.save(os.path.join(out, "menu_" + schermata + ".jpg"), quality=95, subsampling=0, optimize=True)
        a = np.asarray(im.convert("L")).astype(float)
        h, w = a.shape
        fascia = a[int(h * 0.72):int(h * 0.95), int(w * 0.25):int(w * 0.75)]
        y = int(h * 0.72) + int(np.abs(np.diff(fascia, axis=0)).mean(axis=1).argmax())
        righe.append(("menu_" + schermata, (h - y) / h))
    with open(os.path.join(RADICE, "client", "ui", "backdrops.lua"), "w") as f:
        f.write("-- Generated by tools/grafica/fucina.py: the painting of each place of the campaign\n")
        f.write("-- (/paintings/backdrops/<place>.jpg), behind the home and the menus without their own,\n")
        f.write("-- and of each screen that has its own (menu_<screen>.jpg); how high its painted\n")
        f.write("-- floor is, from the bottom, as a part of its height: the game puts it on the thread.\nreturn {\n")
        for nome, pav in righe:
            f.write("\t%s = %.3f,\n" % (nome, pav))
        f.write("}\n")


# I pezzi dei menu nuovi (Sergio, 14 nov: Figma «RIORGANIZZAZIONE MENU · 14 nov»), gia'
# ritagliati senza verde in art/WB-0xx/ritagli. Ognuno alto il doppio della misura piu'
# grande a cui lo mostra il Figma (1280 x 720), cosi' resta nitido fino a 2560 x 1440.
# (nome nell'atlante, file, altezza in pixel, cartella)
MENU_INTERI = [
    # la home: le porte (WB-046, a destra lo scudo verso il bordo), GIOCA, pedana e zainetto
    ("porta_campagna", "porta_campagna", 236, "WB-046"),
    ("porta_allenamento", "porta_allenamento", 226, "WB-046"),
    # lo striscione EVENTI: il nastro con la piega di WB-061 (Sergio, 15 nov; fra tre
    # idee), accorciato nel mezzo liscio per avere l'ingombro di quello di WB-046
    ("porta_eventi", "porta_eventi_piega", 236, "WB-061"),
    ("porta_armeria", "porta_armeria_dx", 226, "WB-046"),
    ("gioca_sigillo", "gioca_sigillo", 166, "WB-046"),
    ("pedana", "pedana_griglia_1", 266, "WB-050"),
    ("zainetto", "zaino_chiuso_1", 124, "WB-048"),
    # la transizione (WB-049): l'attacco dello scudo sul bordo e le schegge della scia
    ("attacco_scudo", "attacco_scudo_1", 170, "WB-049"),
    # caselle, livelli, segni (WB-044)
    ("casella", "casella", 324, "WB-044"),
    ("casella_scelta", "casella_scelta", 324, "WB-044"),
    ("casella_vuota", "casella_vuota", 324, "WB-044"),
    ("chiodo", "chiodo", 40, "WB-044"),
    ("livello_ferro", "livello_ferro", 80, "WB-044"),
    ("livello_oro", "livello_oro", 80, "WB-044"),
    ("spunta", "spunta", 56, "WB-044"),
    ("sconto", "sconto", 64, "WB-044"),
    ("cornice_argento", "cornice_argento", 208, "WB-044"),
    ("cornice_bronzo", "cornice_bronzo", 208, "WB-044"),
    ("podio_1", "podio_1", 420, "WB-044"),
    ("podio_2", "podio_2", 352, "WB-044"),
    ("podio_3", "podio_3", 304, "WB-044"),
    ("ic_2contro2", "ic_2contro2", 260, "WB-044"),
    ("ic_stanza", "ic_stanza", 120, "WB-044"),
    ("ic_calendario", "ic_calendario", 88, "WB-044"),
    # segni dei modi e dei badge (WB-047)
    ("ic_torneo", "ic_torneo", 128, "WB-047"),
    ("ic_maglio", "ic_maglio", 140, "WB-047"),
    ("ic_notte", "ic_notte", 108, "WB-047"),
    ("barrato", "barrato", 34, "WB-047"),
    ("sei_qui", "sei_qui", 48, "WB-047"),
    ("buono", "buono", 128, "WB-043"),
]
# dove si scrive sulle porte e su GIOCA: la striscia piena fra lo scudo (o il sigillo) e la
# punta, misurata sul disegno a quell'altezza (margini sinistra, alto, destra, basso). Le
# porte hanno sfumature e graffi apposta, e la misura automatica (spazio) non le trova.
SPAZI_MISURATI = {
    "porta_campagna": (240, 50, 189, 51),
    "porta_allenamento": (225, 44, 166, 37),
    "porta_eventi": (185, 52, 236, 58),
    "porta_armeria": (120, 50, 225, 56),
    "gioca_sigillo": (180, 28, 149, 48),
}
# i pezzi lunghi in tre parti (nome, file, altezza, capo, cartella): si allunga solo il mezzo
MENU_TRE = [
    ("riga_scura", "riga_scura", 140, 0.08, "WB-044"),
    ("pillola", "pillola", 104, 0.2, "WB-044"),
]
SCIE = ["brace", "scintilla", "fiamma", "ricciolo", "ferro", "cuoio", "paglia", "acciaio",
        "stella", "moneta", "nastro", "oro", "ghiaccio", "fiocco", "cristallo", "gelo"]
PORTE = ["campagna", "allenamento", "eventi", "armeria"]
FAMIGLIE = ["fabbro", "corvo", "fornace", "leviatano", "vuoto"]
POSTI = ["elmo", "corazza", "mantello", "stivali"]


def corpo(arr):
    """Il rettangolo del corpo di una scheda (senza la fiamma o i cristalli che escono):
    le righe e le colonne piene almeno a meta'. Torna x0, y0, x1, y1."""
    m = arr[..., 3] > 128
    righe, colonne = m.sum(axis=1), m.sum(axis=0)
    ys = np.where(righe > 0.5 * righe.max())[0]
    xs = np.where(colonne > 0.5 * colonne.max())[0]
    return xs[0], ys[0], xs[-1] + 1, ys[-1] + 1


def scheda(nome, arr, fregio=None):
    """Una scheda di WB-060 in nove parti (angoli interi, lati allungati in un verso,
    il mezzo piatto) piu' il suo fregio: l'angolo grande con la fiamma (in basso a
    sinistra) o coi cristalli (in alto a destra), che esce dal corpo e si disegna
    intero sopra. fregio = (dove, dentro in largo, dentro in alto) in pixel del disegno.
    Nelle misure del fregio, box dice di quanto esce dal corpo (sinistra, alto, destra, basso)."""
    x0, y0, x1, y1 = corpo(arr)
    im = Image.fromarray(arr, "RGBA")
    c = round((y1 - y0) * 0.24)
    xs = [(x0, x0 + c), (x0 + c, x1 - c), (x1 - c, x1)]
    ys = [(y0, y0 + c), (y0 + c, y1 - c), (y1 - c, y1)]
    # i lati accanto al fregio si prendono dove il fregio e' finito: il gioco li
    # allunga da li', cosi' la fiamma o i cristalli non finiscono stirati nel lato
    dove, dx, dy = fregio or (None, 0, 0)
    k = 1
    for r, (ya, yb) in enumerate(ys):
        for q, (xa, xb) in enumerate(xs):
            if dove == "fiamma" and (r, q) == (2, 1):
                xa = x0 + dx
            elif dove == "fiamma" and (r, q) == (1, 0):
                yb = y1 - dy
            elif dove == "cristalli" and (r, q) == (0, 1):
                xb = x1 - dx
            elif dove == "cristalli" and (r, q) == (1, 2):
                ya = y0 + dy
            p = im.crop((xa, ya, xb, yb))
            # il mezzo e' piatto: basta un quadratino
            if r == 1 and q == 1:
                p = p.crop((p.size[0] // 2 - 8, p.size[1] // 2 - 8, p.size[0] // 2 + 8, p.size[1] // 2 + 8))
            salva(p, "%s_%d" % (nome, k))
            k += 1
    MISURE[nome] = (x1 - x0, y1 - y0, c)
    if fregio:
        h, w = arr.shape[:2]
        if dove == "fiamma":
            taglio = (0, y1 - dy, x0 + dx, h)
            fuori = (x0, 0, 0, h - y1)
        else:
            taglio = (x1 - dx, 0, w, y0 + dy)
            fuori = (0, y0, w - x1, 0)
        p = im.crop(taglio)
        salva(p, nome + "_fregio")
        MISURE[nome + "_fregio"] = p.size
        SPAZI[nome + "_fregio"] = fuori


def fai_schede():
    """Le schede di GIOCA ONLINE (WB-060): brace, ferro, gelo e ferro spento, normali
    e scelte (col bordo acceso). Tenuti i fogli 1: china piu' pulita e lati piu' dritti."""
    p = os.path.join(ART, "WB-060")
    fregi = {"brace": ("fiamma", 235, 170), "gelo": ("cristalli", 200, 95), "gelo_scelta": ("cristalli", 250, 95)}
    for foglio, coda in (("schede_modalita_1", ""), ("schede_scelte_1", "_scelta")):
        cs = griglia(os.path.join(p, foglio + ".png"), [2, 2], 20000)
        # in ordine di lettura: brace e ferro sopra, gelo e spenta sotto
        for tipo, a in zip(["brace", "ferro", "gelo", "spenta"], cs):
            n = tipo + coda
            scheda("scheda_" + n, a, fregi.get(n) or fregi.get(tipo))


def fai_segni():
    """I segni di chi sale e chi scende (WB-061, foglio 1: piatto, senza il riflesso
    bianco): avorio, il gioco li tinge."""
    segni = griglia(os.path.join(ART, "WB-061", "segni_sale_scende_1.png"), [3], 20000)
    for nome, a in zip(["segno_sale", "segno_scende", "segno_uguale"], segni):
        intero(nome, a, 96)


def ritaglio(cartella, nome):
    return np.array(Image.open(os.path.join(ART, cartella, "ritagli", nome + ".png")).convert("RGBA"))


def fai_menu():
    for nome, f, h, d in MENU_INTERI:
        intero(nome, ritaglio(d, f), h)
        if nome in SPAZI_MISURATI:
            SPAZI[nome] = SPAZI_MISURATI[nome]
    for nome, f, h, c, d in MENU_TRE:
        tre(nome, ritaglio(d, f), h, c)
    for k in SCIE:
        intero("scia_" + k, ritaglio("WB-049", "scia_%s_1" % k), 84)
    # la banda del bordo: larga il doppio di come si vede (48), si ripete in alto
    for k in PORTE:
        a = ritaglio("WB-049", "banda_%s_1" % k)
        im = Image.fromarray(a, "RGBA")
        im = im.resize((96, round(im.size[1] * 96 / im.size[0])), Image.LANCZOS)
        salva(im, "banda_" + k)
        MISURE["banda_" + k] = im.size
    # la lama della tempra (WB-051): corpo, bordo rovente e bordo gelato, che si
    # ripetono in alto (e il corpo anche in largo); larghi il doppio di come si vedono
    for nome, w in (("lama_corpo", 180), ("lama_fuoco", 80), ("lama_gelo", 72)):
        im = Image.fromarray(ritaglio("WB-051", nome + "_1"), "RGBA")
        im = im.resize((w, round(im.size[1] * w / im.size[0])), Image.LANCZOS)
        salva(im, nome)
        MISURE[nome] = im.size
    # il pulsante primario dei menu: la gemma di brace di WB-054 (E, Sergio 15 nov),
    # acceso, premuto e spento, in tre parti (si allunga solo il mezzo). Alti come nel
    # disegno rispetto all'acceso: il premuto e' piu' basso apposta. PRIMARIO=tizzone,
    # crosta (le altre di WB-054) o brace (la C di WB-052) per rivederne un'altra
    scelta = os.environ.get("PRIMARIO", "gemma")
    if scelta == "brace":
        for stato, h in (("acceso", 200), ("premuto", 130), ("spento", 165)):
            tre("primario_" + stato, ritaglio("WB-052", "primario_%s_1" % stato), h, 0.3)
    else:
        acceso_h = ritaglio("WB-054", "primario_%s_acceso" % scelta).shape[0]
        for stato in ("acceso", "premuto", "spento"):
            r = ritaglio("WB-054", "primario_%s_%s" % (scelta, stato))
            tre("primario_" + stato, r, round(200 * r.shape[0] / acceso_h), 0.3)
    # le icone dei pezzi (WB-043): base e forgiata per famiglia e posto; il posto vuoto
    for f in FAMIGLIE:
        for p in POSTI:
            for g in ("base", "forgiato"):
                intero("ic_%s_%s_%s" % (f, p, g), ritaglio("WB-043", "ic_%s_%s_%s" % (f, p, g)), 240)
    for p in POSTI:
        intero("vuoto_" + p, ritaglio("WB-043", "vuoto_" + p), 240)


def trasparente(percorso):
    """Un foglio di Codex gia' trasparente (WB-062, WB-067): via l'alone di pixel
    mezzi trasparenti attorno ai pezzi (la china esterna e' piena)."""
    a = np.array(Image.open(percorso).convert("RGBA")).astype(float)
    al = a[..., 3]
    a[..., 3] = np.clip((al - 90) / 100, 0, 1) * 255
    return a.astype(np.uint8)


def griglia_trasparente(percorso, per_riga, minimo=1500):
    cs = sorted(pezzi(trasparente(percorso), minimo), key=lambda t: t[0])
    out = []
    for n in per_riga:
        out += sorted(cs[:n], key=lambda t: t[1])
        cs = cs[n:]
    return [t[2] for t in out]


def fai_bivio():
    """I Sigilli col bivio (WB-062, foglio 1, Sergio 15 nov): per acceso, spento e
    chiuso il binario dei punti (in tre parti, si allunga), il nodo del gradino, i
    rami su e giu', la piastra del potere (in nove parti). E le tacche dei punti,
    le fiammelle dei punti liberi, i pulsanti meno e piu' (foglio 1 delle tacche)."""
    p = os.path.join(ART, "WB-062")
    o = trasparente(os.path.join(p, "pezzi_bivio_1.png"))
    # i rami su e giu' a volte si toccano: un pezzo troppo alto si taglia nella riga
    # piu' vuota a meta' altezza
    tutti = []
    for y, x, a in pezzi(o, 3000):
        h = a.shape[0]
        if h > 250:
            piene = (a[..., 3] > 0).sum(axis=1)
            k = int(h * 0.35) + int(np.argmin(piene[int(h * 0.35):int(h * 0.65)]))
            tutti += [(y, x, a[:k]), (y + k, x, a[k:])]
        else:
            tutti.append((y, x, a))
    righe = {}
    for y, x, a in tutti:
        r = int((y + a.shape[0] / 2) / (o.shape[0] / 3))
        righe.setdefault(r, []).append((y, x, a))
    for r, stato in enumerate(("acceso", "spento", "chiuso")):
        riga = righe[r]
        # da sinistra: binario, nodo, i due rami (su sopra, giu' sotto), piastra
        riga.sort(key=lambda t: t[1])
        binario, nodo = riga[0][2], riga[1][2]
        rami = sorted(riga[2:4], key=lambda t: t[0])
        su, giu = rami[0][2], rami[1][2]
        piastra = riga[4][2]
        # i rami su e giu' li disegna il codice (quelli del foglio sono troppo larghi
        # per cinque gradini in una riga); binario e nodo chiusi non servono
        if stato != "chiuso":
            tre("bivio_binario_" + stato, binario, 40, 0.3)
            intero("bivio_nodo_" + stato, nodo, 96)
        scheda("bivio_piastra_" + stato, piastra)
    t = griglia_trasparente(os.path.join(p, "tacche_1.png"), [2, 2, 2, 4], 1500)
    # (le prime quattro del foglio, le tacche a rombo, non servono piu': Sergio, 16 nov)
    nomi = [None, None, None, None, "punto_libero", "punto_speso",
            "tasto_meno", "tasto_meno_spento", "tasto_piu", "tasto_piu_spento"]
    for nome, a in zip(nomi, t):
        if nome:
            intero(nome, a, 96 if nome.startswith("tasto") else 64)
    fai_tacca_sigillo()


def tondo_storto(w, h, raggi, n=24):
    """I punti di un rettangolo w x h con un raggio per angolo (alto sx, alto dx,
    basso dx, basso sx): la forma un po' storta dei pezzi."""
    centri = [(raggi[0], raggi[0], 180), (w - raggi[1], raggi[1], 270), (w - raggi[2], h - raggi[2], 0), (raggi[3], h - raggi[3], 90)]
    punti = []
    for (cx, cy, a0), r in zip(centri, raggi):
        for i in range(n + 1):
            a = np.radians(a0 + 90 * i / n)
            punti.append((cx + r * np.cos(a), cy + r * np.sin(a)))
    return punti


def fai_tacca_sigillo():
    """La tacca dei punti dei Sigilli (Sergio, 16 nov: stretta e alta come nella
    bozza approvata, 13 x 24 con gli angoli 5 3 6 3 e il bordo d'inchiostro):
    disegnata qui, bianca, il gioco la tinge del colore della via."""
    from PIL import ImageDraw
    k = 8 * 4  # quattro volte la misura sullo schermo, disegnata otto volte piu' grande
    w, h, bordo = 13 * k, 24 * k, 2 * k
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon(tondo_storto(w, h, [5 * k, 3 * k, 6 * k, 3 * k]), fill=(18, 11, 12, 255))
    dentro = tondo_storto(w - 2 * bordo, h - 2 * bordo, [3 * k, 1.5 * k, 4 * k, 1.5 * k])
    d.polygon([(x + bordo, y + bordo) for x, y in dentro], fill=(255, 255, 255, 255))
    im = im.resize((w // 8, h // 8), Image.LANCZOS)
    salva(im, "tacca_sigillo")
    MISURE["tacca_sigillo"] = im.size


def fai_profilo():
    """Il Profilo (WB-067, fogli 1): il nastro della vittoria (fiamma) e della
    sconfitta (schegge), in tre parti; il pulsante per rivedere, normale e premuto;
    le medaglie dei record, bronzo, argento, oro e il posto vuoto."""
    p = os.path.join(ART, "WB-067")
    n = griglia_trasparente(os.path.join(p, "nastri_e_rivedi_1.png"), [2, 2], 3000)
    tre("nastro_vittoria", n[0], 96, 0.3)
    intero("rivedi", n[1], 120)
    tre("nastro_sconfitta", n[2], 96, 0.3)
    intero("rivedi_premuto", n[3], 120)
    m = griglia_trasparente(os.path.join(p, "medaglie_1.png"), [4], 3000)
    for nome, a in zip(["medaglia_bronzo", "medaglia_argento", "medaglia_oro", "medaglia_vuota"], m):
        intero(nome, a, 80)


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
    fai_menu()
    fai_schede()
    fai_segni()
    fai_bivio()
    fai_profilo()
    fai_fette()
    fai_sfondi()
    fai_filo()
    fai_misure()
    fai_atlante()
    print("OK")
