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
#   client/paintings/clients/*.jpg     i busti dei clienti delle Commesse (WB-086, WB-087)
#   client/ui/pieces.lua                le misure di ogni pezzo (generato)
#   client/ui/fucina.atlas              l'atlante (generato)
# Servono numpy, scipy e Pillow.
import os
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter
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
BUSTI = os.path.join(RADICE, "client", "paintings", "clients")


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
    if nome not in ("guscio", "barra_brace", "barra_gelo", "barra_chiara", "barra_stendardo") and not nome.startswith("primario"):    # (sfumati, e il primario: il suo spazio e' misurato, SPAZI_PRIMARIO)
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
    cs = pezzi(senza_verde(os.path.join(p, "pezzo_piccoli.png")), 800)
    ymid = np.mean([t[0] for t in cs])
    su = sorted([t for t in cs if t[0] < ymid], key=lambda t: t[1])
    giu = sorted([t for t in cs if t[0] >= ymid], key=lambda t: t[1])
    tre("piastrina", su[0][2], 120, 0.3)
    tre("piastrina_calda", caldo(su[0][2]), 120, 0.3)
    tre("piastrina_chiara", chiaro(su[0][2]), 120, 0.3)
    for nome, t in zip(["indietro", "brace", "fiamma"], su[1:]):
        intero(nome, t[2], 120)
    # (la scaglia e la gemma di questo foglio sono state rifatte con WB-072: fai_monete)
    for nome, t in zip(["brace_spenta", "lucchetto"], giu):
        intero(nome, t[2], 120)


def fai_monete():
    """Le monete e il buono del Fabbro di WB-072 (Sergio, 18 nov): l'Ossidiana del primo giro
    (monete_2: la gemma sfaccettata nera e viola col filo magenta), la Scaglia e il buono del
    secondo giro (scavate_2: fiammella e martello scavati dentro), tutti alti uguali."""
    p = os.path.join(ART, "WB-072")
    primo = sorted(pezzi(senza_verde(os.path.join(p, "monete_2.png"))), key=lambda t: t[1])
    secondo = sorted(pezzi(senza_verde(os.path.join(p, "scavate_2.png"))), key=lambda t: t[1])
    intero("gemma", primo[0][2], 120)
    intero("scaglia", secondo[0][2], 120)
    intero("buono", secondo[1][2], 120)


def fai_commesse():
    """I frammenti di famiglia e i materiali delle Commesse (WB-084, 23 nov): frammenti_1
    (fabbro, corvo, fornace, leviatano, vuoto), materiali_a_1 (due file da tre) e materiali_b_2.
    Il verde si toglie solo fuori dalla china (l'Acqua dello Stige e il Leviatano sono verdi
    dentro). Ognuno al centro di un quadrato, cosi' in una griglia hanno tutti lo stesso
    ingombro: 192 px, il doppio della misura piu' grande sullo schermo (96)."""
    p = os.path.join(ART, "WB-084")

    def fuori(percorso):
        rgb = np.array(Image.open(percorso).convert("RGB"))
        o = senza_verde(percorso)
        lab, _ = ndi.label(o[..., 3] < 255)
        bordo = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
        sfondo = np.isin(lab, bordo[bordo > 0])
        o[~sfondo, :3] = rgb[~sfondo]
        o[~sfondo, 3] = 255
        return o

    def quadrato(nome, arr, lato=192):
        im = Image.fromarray(arr, "RGBA")
        k = (lato - 4) / max(im.size)
        im = im.resize((round(im.size[0] * k), round(im.size[1] * k)), Image.LANCZOS)
        q = Image.new("RGBA", (lato, lato), (0, 0, 0, 0))
        q.paste(im, ((lato - im.size[0]) // 2, (lato - im.size[1]) // 2))
        salva(q, nome)
        MISURE[nome] = (lato, lato)

    fr = sorted(pezzi(fuori(os.path.join(p, "frammenti_1.png"))), key=lambda t: t[1])
    assert len(fr) == 5, len(fr)
    for nome, t in zip(FAMIGLIE, fr):
        quadrato("frammento_" + nome, t[2])
    a = pezzi(fuori(os.path.join(p, "materiali_a_1.png")))
    assert len(a) == 6, len(a)
    ymid = np.mean([t[0] for t in a])
    a = sorted([t for t in a if t[0] < ymid], key=lambda t: t[1]) + sorted([t for t in a if t[0] >= ymid], key=lambda t: t[1])
    b = sorted(pezzi(fuori(os.path.join(p, "materiali_b_2.png"))), key=lambda t: t[1])
    assert len(b) == 5, len(b)
    nomi = ["scoria", "piuma", "vento", "grandine", "scheggia", "stige", "tomba", "sangue", "sabbia", "pece", "ghiaccio"]
    for nome, t in zip(nomi, a + b):
        quadrato("materiale_" + nome, t[2])


def fai_bottega():
    """La carta dei cartellini e il Fabbro al banco delle Commesse (WB-085, 23 nov).
    Il cartellino e' il foglio largo di cartellino_1 in nove parti, con gli angoli quadrati
    presi alla misura di Codex (100 px: sullo schermo 34, il doppio e' 68) cosi' la china
    e l'orecchia non si deformano; il lato alto viene dal tratto liscio prima del rinforzo
    del foro, e il rinforzo e' un pezzo a parte (cartellino_foro) che il gioco mette al
    centro, sotto il chiodo. Il Fabbro e' la variante 1, senza la pergamena del fondo
    (tolta solo dove tocca il bordo del foglio: i baffi hanno quasi lo stesso colore),
    alto 1000: sullo schermo 500."""
    p = os.path.join(ART, "WB-085")
    o = senza_verde(os.path.join(p, "cartellino_1.png"))
    x0, y0, x1, y1, c = 799, 302, 1430, 718, 100
    xs = [(x0, x0 + c), (x0 + c, 1060), (x1 - c, x1)]
    ys = [(y0, y0 + c), (y0 + c, y1 - c), (y1 - c, y1)]
    k = 1
    for r, (ya, yb) in enumerate(ys):
        for q, (xa, xb) in enumerate(xs):
            # (sotto e in mezzo il tratto intero: solo in alto c'e' il rinforzo da saltare)
            if q == 1 and r > 0:
                xb = x1 - c
            salva(Image.fromarray(o[ya:yb, xa:xb], "RGBA"), "cartellino_%d" % k)
            k += 1
    MISURE["cartellino"] = (x1 - x0, y1 - y0, c)
    foro = Image.fromarray(o[y0:372, 1064:1176], "RGBA")
    salva(foro, "cartellino_foro")
    MISURE["cartellino_foro"] = foro.size

    rgb = np.array(Image.open(os.path.join(p, "fabbro_al_banco_1.png")).convert("RGB")).astype(float)
    fondo = np.median(np.concatenate([rgb[:8].reshape(-1, 3), rgb[-8:].reshape(-1, 3)]), axis=0)
    dist = np.abs(rgb - fondo).sum(axis=2)
    lab, _ = ndi.label(dist < 60)
    bordo = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    # (e la pergamena chiusa fra il braccio destro e il fianco)
    fuori = np.isin(lab, bordo[bordo > 0]) | (lab == lab[895, 746])
    # il contorno: i pixel fra pergamena e china, sfumati e ripuliti dal colore del fondo
    vicino = ndi.binary_dilation(fuori, iterations=3) & ~fuori
    alfa = np.where(fuori, 0.0, 1.0)
    alfa[vicino] = np.clip((255 - rgb[vicino].mean(axis=1)) / 200, 0, 1)
    col = rgb.copy()
    m = vicino & (alfa > 0.02)
    col[m] = np.clip((rgb[m] - (1 - alfa[m])[:, None] * fondo) / alfa[m][:, None], 0, 255)
    arr = np.dstack([col, alfa * 255]).astype(np.uint8)
    ys_, xs_ = np.where(arr[..., 3] > 20)
    intero("fabbro_al_banco", arr[ys_.min():ys_.max() + 1, xs_.min():xs_.max() + 1], 1000)

    # i busti dei clienti (WB-086: Caronte, variante 2 scelta da Sergio il 23 nov): chiede,
    # contento, fiero; dentro la cornice di china (il gioco la ridisegna), alla misura di
    # Codex (366 x 485: il ritratto piu' grande sullo schermo e' 180 x 240)
    # e gli altri sette (WB-087, 23 nov): le varianti consigliate da Claude, da confermare
    # con Sergio. I riquadri dei busti stanno sempre da x 390, 773, 1156 (373 di larghezza);
    # l'alto della cornice si cerca (la riga di china piu' lunga), poi 485 in giu': stessa
    # misura per tutti, il taglio sotto e' il petto
    fogli = {"caronte": ("WB-086", 2), "minosse": ("WB-087", 2), "cerbero": ("WB-087", 1),
             "plutone": ("WB-087", 1), "flegias": ("WB-087", 1), "medusa": ("WB-087", 1),
             "minotauro": ("WB-087", 1), "malacoda": ("WB-087", 2)}
    for cliente, (scheda, variante) in fogli.items():
        cs = Image.open(os.path.join(ART, scheda, "%s_%d.png" % (cliente, variante))).convert("RGBA")
        scuro = np.asarray(cs.convert("RGB")).astype(int).sum(axis=2) < 360
        righe = np.where(scuro[:, 400:750].sum(axis=1) > 245)[0]
        alto = int(righe.min()) + 4
        # chiede (i cartellini), contento e fiero (la scena della consegna, 23 nov): non
        # nell'atlante (sarebbe salito a 8192) ma JPEG in client/paintings/clients/, caricati
        # solo quando si vedono (ui/illustrations.lua): il fondo del busto e' carta piena
        for nome, x in (("chiede", 394), ("contento", 777), ("fiero", 1160)):
            im = cs.crop((x, alto, x + 366, alto + 485)).convert("RGB")
            im.save(os.path.join(BUSTI, "%s_%s.jpg" % (cliente, nome)), quality=92)


def fai_badge_clienti():
    """Il badge di ogni cliente a 10 perle (Sergio, 23 nov): come il cerchietto del profilo,
    la testa parte dalla base del cerchio e sopra (e di lato) puo' uscire. Il busto chiede
    ritagliato dalla carta (la carta che tocca i bordi e le macchie grandi chiuse), messo
    con la testa al centro del disco; sotto la linea di mezzo si taglia col cerchio, sopra
    no. Il disco e l'anello del colore del filo li disegna il gioco (ui/tag_card.lua):
    qui il disco e' D = 128 (2x il badge piu' grande, 64 nel profilo), centro a (CX, CY)."""
    from scipy import ndimage
    D, W, H = 128, 360, 208
    CX, CY = W // 2, H - D // 2 - 4
    # dove sta la testa nel busto (366 x 485): centro x, y e larghezza, a occhio
    teste = {"caronte": (150, 175, 170), "minosse": (172, 150, 190), "cerbero": (183, 125, 260),
             "plutone": (165, 135, 190), "flegias": (150, 160, 200), "medusa": (170, 140, 170),
             "minotauro": (195, 170, 230), "malacoda": (115, 150, 150)}
    for cliente, (hx, hy, hw) in teste.items():
        im = np.asarray(Image.open(os.path.join(BUSTI, cliente + "_chiede.jpg")).convert("RGB")).astype(int)
        fondo = np.median(np.concatenate([im[0], im[:, 0], im[:, -1]]), axis=0)
        carta = np.abs(im - fondo).sum(axis=2) < 60
        lab, n = ndimage.label(carta)
        bordo = set(np.unique(np.concatenate([lab[0], lab[:, 0], lab[:, -1]]))) - {0}
        grandi = {i + 1 for i, k in enumerate(ndimage.sum(carta, lab, range(1, n + 1))) if k > 400}
        fuori = np.isin(lab, list(bordo | grandi))
        figura = ndimage.binary_opening(~fuori, iterations=1)
        lab2, n2 = ndimage.label(figura)
        figura = lab2 == (np.argmax(ndimage.sum(figura, lab2, range(1, n2 + 1))) + 1)
        alfa = Image.fromarray((figura * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
        busto = Image.fromarray(np.dstack([im.astype(np.uint8), np.asarray(alfa)]), "RGBA")
        k = D * 0.95 / hw
        busto = busto.resize((round(busto.size[0] * k), round(busto.size[1] * k)), Image.LANCZOS)
        tela = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        tela.alpha_composite(busto, (round(CX - hx * k), round(CY - D * 0.12 - hy * k)))
        a = np.asarray(tela).copy()
        yy, xx = np.mgrid[0:H, 0:W]
        dentro = (xx - CX + 0.5) ** 2 + (yy - CY + 0.5) ** 2 <= (D / 2) ** 2
        # fuori dal cerchio resta solo la testa (sopra la linea di mezzo, attaccata al
        # centro della testa): non il remo o la lancia che spuntano di lato
        sopra = (yy < CY) & (a[..., 3] > 40) & ~dentro | (yy < CY) & dentro & (a[..., 3] > 40)
        lab3, _ = ndimage.label(sopra, structure=np.ones((3, 3)))
        testa = lab3 == lab3[round(CY - D * 0.12), CX]
        a[..., 3] = np.where(dentro | testa, a[..., 3], 0)
        ys, xs = np.where(a[..., 3] > 0)
        x0, x1 = xs.min(), xs.max() + 1
        # il pezzo si ritaglia ai bordi veri; il centro del disco il gioco lo legge
        # dal box (sinistra e alto = dove sta il centro, destra e basso il resto)
        y0 = ys.min()
        out = Image.fromarray(a[y0:, x0:x1], "RGBA")
        salva(out, "badge_" + cliente)
        MISURE["badge_" + cliente] = (out.size[0], out.size[1])
        SPAZI["badge_" + cliente] = (CX - x0, CY - y0, x1 - CX, H - CY)


def fai_perle():
    """Le perle del livello e lo slot della firma di WB-074 (Sergio, 18 nov: il modo ufficiale
    di mostrare gli upgrade). Dal foglio perle_2: sopra le tre perline (vuota, piena grigia che
    il gioco colora del grado, prossima in brace), sotto i tre slot (vuoto, acceso, rovente)."""
    tutti = pezzi(senza_verde(os.path.join(ART, "WB-074", "perle_2.png")))
    ymid = np.mean([t[0] for t in tutti])
    su = sorted([t for t in tutti if t[0] < ymid], key=lambda t: t[1])
    giu = sorted([t for t in tutti if t[0] >= ymid], key=lambda t: t[1])
    for nome, t in zip(["perla_vuota", "perla_piena", "perla_prossima"], su):
        intero(nome, t[2], 64)
    for nome, t in zip(["slot_vuoto", "slot_acceso", "slot_rovente"], giu):
        intero(nome, t[2], 128)


def fai_stendardo():
    """Il riquadro del profilo in home (WB-075, Sergio 18 nov: «facciamo la d1»): anello e
    stendardo in un pezzo solo (stendardo_1), con l'incavo della barra e la moneta del livello
    forgiati dentro; il riempimento della barra e' quello dritto di barra_2, senza la punta
    (Sergio: «o metti bene la capocchia, oppure lasci senza»). Capi corti: con poca esperienza
    la barra resta corta."""
    p = os.path.join(ART, "WB-075")
    st = max(pezzi(senza_verde(os.path.join(p, "stendardo_1.png"))), key=lambda t: t[2].size)
    intero("stendardo", st[2], 224)
    barra = sorted(pezzi(senza_verde(os.path.join(p, "barra_2.png"))), key=lambda t: t[0])
    tre("barra_stendardo", barra[1][2], 16, 0.03)


def fai_secondario():
    """Il pulsante secondario (Sergio, 18 nov, «Ferro liscio» della pagina delle proposte:
    quello di Codex di WB-071 sembrava un primario): ferro scuro piatto, contorno
    d'inchiostro dritto, una luce piatta in alto e lo spessore sotto; nel capo sinistro
    niente incavo: la moneta o l'icona sporge dal capo sinistro, grande e
    un po' storta (Sergio, 18 nov, «moneta che sporge»). Disegnato qui in vettori (quattro volte piu' grande, poi
    ridotto), in tre parti come gli altri pezzi lunghi. Premuto: la faccia scende e lo
    spessore sparisce; spento: ferro freddo grigio-blu."""
    S = 4                       # il disegno a quattro volte, ridotto: bordi lisci
    W, FACE, R, INK = 520, 108, 30, 7
    stati = {
        # nome: (altezza in tutto, ferro, luce)
        "acceso": (120, (0x3A, 0x33, 0x40), (0x50, 0x48, 0x5A)),
        "premuto": (114, (0x33, 0x2D, 0x39), (0x44, 0x3D, 0x4C)),
        "spento": (120, (0x4A, 0x55, 0x60), (0x5C, 0x67, 0x72)),
    }
    nero = (0x0A, 0x08, 0x0B, 255)
    for stato, (h, ferro, luce) in stati.items():
        im = Image.new("RGBA", (W * S, h * S), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        top = 0                 # la faccia in alto, sotto lo spessore (12, premuto 6)
        # lo spessore: l'inchiostro sotto la faccia
        d.rounded_rectangle((0, top * S + 8 * S, W * S - 1, h * S - 1), R * S, fill=nero)
        # la faccia: contorno, ferro, la luce in alto (solo dentro il ferro)
        d.rounded_rectangle((0, top * S, W * S - 1, (top + FACE) * S - 1), R * S, fill=nero)
        dentro = (INK * S, (top + INK) * S, (W - INK) * S - 1, (top + FACE - INK) * S - 1)
        d.rounded_rectangle(dentro, (R - INK) * S, fill=ferro + (255,))
        maschera = Image.new("L", im.size, 0)
        ImageDraw.Draw(maschera).rounded_rectangle(dentro, (R - INK) * S, fill=255)
        banda = Image.new("L", im.size, 0)
        ImageDraw.Draw(banda).rectangle((0, 0, W * S, (top + INK + (FACE - 2 * INK) * 0.34) * S), fill=255)
        im.paste(Image.new("RGBA", im.size, luce + (255,)), (0, 0), ImageChops.multiply(maschera, banda))
        im = im.resize((W, h), Image.LANCZOS)
        tre("secondario_" + stato, np.asarray(im), h, 0.26)
    # le scritte dopo la moneta, lontano dai bordi
    SPAZI["secondario_acceso"] = (118, 14, 26, 24)
    # (le monete del foglio monete_* non sono piaciute a Sergio: si rifanno con WB-072)


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
    # (alto il doppio: la targa del profilo della home lo disegna a 76, Sergio 17 nov)
    tre("guscio", barre[0], 128, 0.12)
    tre("barra_brace", barre[1], 44, 0.1)
    tre("barra_gelo", barre[2], 44, 0.1)
    tre("barra_chiara", neutro(barre[1]), 44, 0.1)
    intero("tacca", barre[3], 72)
    tondi = griglia(os.path.join(p, "pezzo_tondi_1.png"), [2, 2])
    for nome, a in zip(["tondo_ferro", "tondo_oro"], tondi):
        intero(nome, a, 200)
    # (la linguetta e la linguetta chiara non si usano piu': le linguette dei menu sono solo scritte)


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
    with open(os.path.join(RADICE, "client", "ui", "backdrops.lua"), "w") as f:
        f.write("-- Generated by tools/grafica/fucina.py: the painting of each place of the campaign\n")
        f.write("-- (/paintings/backdrops/<place>.jpg), behind the screens that ask for the place reached;\n")
        f.write("-- how high its painted floor is, from the bottom, as a part of its height: the game puts it on the thread.\nreturn {\n")
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
    # lo SHOP al posto di ARMERIA (WB-080, Sergio 18 nov: il banco col tendone), accorciato
    # nel mezzo liscio per avere l'ingombro della porta di ARMERIA di WB-046
    ("porta_shop", "porta_shop", 226, "WB-080"),
    ("gioca_sigillo", "gioca_sigillo", 166, "WB-046"),
    ("pedana", "pedana_griglia_1", 266, "WB-050"),
    ("zainetto", "zaino_chiuso_1", 124, "WB-048"),
    # le caselle dei pezzi, dritte (WB-078, Sergio 18 nov: al posto di quelle di WB-044 in
    # ogni posto): la cornice, la linguetta del tipo in alto a sinistra col suo simbolo,
    # la fascia INDOSSATO in basso; i simboli rifatti in WB-079 dalle icone dei nostri pezzi
    ("casella", "cornice", 324, "WB-078"),
    ("casella_scelta", "cornice_scelta", 324, "WB-078"),
    ("casella_vuota", "cornice_vuota", 324, "WB-078"),
    ("linguetta", "linguetta", 112, "WB-078"),
    ("fascia_indossato", "fascia_indossato", 64, "WB-078"),
    ("tipo_elmo", "tipo_elmo", 80, "WB-079"),
    ("tipo_corazza", "tipo_corazza", 80, "WB-079"),
    ("tipo_mantello", "tipo_mantello", 80, "WB-079"),
    ("tipo_stivali", "tipo_stivali", 80, "WB-079"),
    ("tipo_guanti", "tipo_guanti", 80, "WB-079"),
    # livelli, segni (WB-044)
    ("chiodo", "chiodo", 40, "WB-044"),
    ("livello_ferro", "livello_ferro", 80, "WB-044"),
    ("livello_oro", "livello_oro", 80, "WB-044"),
    ("sconto", "sconto", 64, "WB-044"),
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
    # il cartello ARMERIA che scende dal taglio delle schede dello zaino (WB-080)
    ("cartello_armeria", "cartello_armeria", 180, "WB-080"),
]
# dove si scrive sulle porte e su GIOCA: la striscia piena fra lo scudo (o il sigillo) e la
# punta, misurata sul disegno a quell'altezza (margini sinistra, alto, destra, basso). Le
# porte hanno sfumature e graffi apposta, e la misura automatica (spazio) non le trova.
SPAZI_MISURATI = {
    "porta_campagna": (240, 50, 189, 51),
    "porta_allenamento": (225, 44, 166, 37),
    "porta_eventi": (185, 52, 252, 58),   # (a destra 12 px dal medaglione, come ARMERIA)
    "porta_shop": (214, 52, 240, 58),
    "gioca_sigillo": (180, 28, 149, 48),
}
# dove si scrive sul pulsante primario (la gemma di WB-054): la faccia piena davanti, senza
# la fiamma a sinistra e i cristalli a destra; sullo spento solo la parte grigia, prima del
# ghiaccio (Sergio, 17 nov: la scritta mai sopra i disegni del tasto). Misurati con spazio()
# sul disegno intero, con la tinta presa dalla faccia.
SPAZI_PRIMARIO = {
    "primario_acceso": (99, 79, 79, 48),
    "primario_premuto": (71, 62, 78, 33),
    "primario_spento": (59, 78, 178, 39),
}
# i pezzi lunghi in tre parti (nome, file, altezza, capo, cartella): si allunga solo il mezzo
MENU_TRE = [
    ("riga_scura", "riga_scura", 140, 0.08, "WB-044"),
    ("pillola", "pillola", 104, 0.2, "WB-044"),
]
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
    for nome, a in zip(["segno_sale", "segno_scende"], segni):
        intero(nome, a, 96)


def ritaglio(cartella, nome):
    return np.array(Image.open(os.path.join(ART, cartella, "ritagli", nome + ".png")).convert("RGBA"))


def verde(arr):
    """La stessa spunta, verde: chi ha premuto PRONTO nella scelta delle armi
    (Sergio, 16 nov). Gira solo la tinta: luci, ombre e contorno restano."""
    hsv = np.array(Image.fromarray(arr[..., :3], "RGB").convert("HSV"))
    hsv[..., 0] = 82  # da oro a verde (tinta 0..255)
    out = arr.copy()
    out[..., :3] = np.array(Image.fromarray(hsv, "HSV").convert("RGB"))
    return out


def fai_menu():
    for nome, f, h, d in MENU_INTERI:
        intero(nome, ritaglio(d, f), h)
        if nome in SPAZI_MISURATI:
            SPAZI[nome] = SPAZI_MISURATI[nome]
    intero("spunta_verde", verde(ritaglio("WB-044", "spunta")), 56)
    for nome, f, h, c, d in MENU_TRE:
        tre(nome, ritaglio(d, f), h, c)
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
            SPAZI["primario_" + stato] = SPAZI_PRIMARIO["primario_" + stato]
    # le icone dei pezzi (WB-043): base e forgiata per famiglia e posto; il posto vuoto
    for f in FAMIGLIE:
        for p in POSTI:
            for g in ("base", "forgiato"):
                intero("ic_%s_%s_%s" % (f, p, g), ritaglio("WB-043", "ic_%s_%s_%s" % (f, p, g)), 240)
    for p in POSTI:
        intero("vuoto_" + p, ritaglio("WB-043", "vuoto_" + p), 240)
    # i guanti, quinto posto (WB-076, Sergio 19 nov); la sagoma vuota da WB-070
    for f in FAMIGLIE:
        for g in ("base", "forgiato"):
            intero("ic_%s_guanti_%s" % (f, g), ritaglio("WB-076", "ic_%s_guanti_%s" % (f, g)), 240)
    intero("vuoto_guanti", ritaglio("WB-076", "vuoto_guanti"), 240)


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
    fai_record()


# le icone dei record, nell'ordine del foglio (gli id di client/menu/milestones.lua)
RECORD = ["nel_vuoto", "abbattuti", "a_segno", "danno", "globi", "colpo_lungo", "casse", "vinte", "cadute"]
LATO_RECORD = 96


def fai_record():
    """Le nove icone dei record (WB-069, foglio 1): una griglia 3 x 3. Ogni icona
    e' fatta di piu' pezzi staccati (la scintilla del martello, i punti dell'arco),
    quindi si taglia a caselle e non a pezzi; ognuna va al centro di un quadrato,
    cosi' nel gioco hanno tutte lo stesso ingombro. Delle cadute resta solo il
    diavoletto: le lineette di movimento sono nere e sul ferro scuro non si vedono."""
    a = trasparente(os.path.join(ART, "WB-069", "icone_record_1.png"))
    pieno = a[..., 3] > 40
    ys, xs = np.where(pieno)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    for i, nome in enumerate(RECORD):
        r, c = divmod(i, 3)
        cy0, cy1 = y0 + (y1 - y0) * r // 3, y0 + (y1 - y0) * (r + 1) // 3
        cx0, cx1 = x0 + (x1 - x0) * c // 3, x0 + (x1 - x0) * (c + 1) // 3
        casella = a[cy0:cy1, cx0:cx1].copy()
        if nome == "cadute":
            lab, n = ndi.label(casella[..., 3] > 40)
            grande = 1 + int(np.argmax(ndi.sum(casella[..., 3] > 40, lab, range(1, n + 1))))
            casella[lab != grande] = 0
        ky, kx = np.where(casella[..., 3] > 40)
        im = Image.fromarray(casella[ky.min():ky.max() + 1, kx.min():kx.max() + 1], "RGBA")
        k = (LATO_RECORD - 4) / max(im.size)
        im = im.resize((round(im.size[0] * k), round(im.size[1] * k)), Image.LANCZOS)
        tela = Image.new("RGBA", (LATO_RECORD, LATO_RECORD), (0, 0, 0, 0))
        tela.alpha_composite(im, ((LATO_RECORD - im.size[0]) // 2, (LATO_RECORD - im.size[1]) // 2))
        salva(tela, "record_" + nome)
        MISURE["record_" + nome] = (LATO_RECORD, LATO_RECORD)


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
    os.makedirs(BUSTI, exist_ok=True)
    fai_pezzi()
    fai_monete()
    fai_commesse()
    fai_bottega()
    fai_perle()
    fai_stendardo()
    fai_secondario()
    fai_piccoli()
    fai_menu()
    fai_schede()
    fai_segni()
    fai_bivio()
    fai_profilo()
    fai_fette()
    fai_sfondi()
    fai_filo()
    fai_badge_clienti()
    fai_misure()
    fai_atlante()
    print("OK")
