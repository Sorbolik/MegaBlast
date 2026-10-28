#!/usr/bin/env python3
"""Taglia un foglio disegnato sullo stampino nei pezzi di una pelle del gioco.

Una pelle è un pezzo d'equipaggiamento (un elmo, una corazza, una maglia, delle
ali...) o un personaggio intero: un'immagine per ogni posto dello scheletro che
cambia. Il foglio è lo stampino (stampino.py) con i pezzi nuovi disegnati nelle
caselle: un PNG trasparente (il livello di Procreate) o un'immagine su magenta
(ChatGPT). Le caselle vuote o uguali al manichino non cambiano niente.

  python3 strumenti/stampino/taglia.py FOGLIO.png --nome elmo_corna --categoria elmo [--allinea]
  python3 strumenti/stampino/taglia.py --rifai        # solo pelli.lua e pelli.atlas
  python3 strumenti/stampino/taglia.py --togli NOME   # toglie una pelle

Scrive client/assets/pelli/<nome>_<posto>.png, strumenti/stampino/pelli/<nome>.json
(com'è fatta la pelle), e rifà client/battaglia/pelli.lua da tutte le pelli e
l'atlante del diavoletto, che le contiene insieme ai pezzi di base. --allinea sposta e scala ogni pezzo finché combacia col manichino: per
i disegni di ChatGPT, che non rispetta mai al pixel le caselle.
"""
import argparse
import glob
import json
import os
import re
import sys

import numpy as np
from PIL import Image, ImageFilter

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.abspath(os.path.join(QUI, "..", ".."))
sys.path.insert(0, QUI)
import stampino as ST  # noqa: E402

ASSETS = os.path.join(RADICE, "client", "assets", "pelli")
JSON = os.path.join(QUI, "pelli")
LUA = os.path.join(RADICE, "client", "battaglia", "pelli.lua")

# Le categorie: una pelle per categoria addosso. Le prime sostituiscono i pezzi
# del diavoletto, le altre si disegnano sopra, in quest'ordine.
SOSTITUISCE = ["personaggio", "testa", "corpo", "ali", "coda"]
SOPRA = ["pantaloni", "maglia", "corazza", "guanti", "elmo"]
CATEGORIE = SOSTITUISCE + SOPRA
# i pezzi di dietro, fatti da quelli davanti un po' più scuri se mancano
DIETRO = {"braccio_dietro": "braccio", "gamba_dietro": "gamba",
          "omero_dietro": "omero", "avambraccio_dietro": "avambraccio"}
SCURO = 0.78


def fondo_via(im):
    """Alfa del disegno: la trasparenza se c'è, altrimenti tutto tranne il magenta."""
    a = np.asarray(im.convert("RGBA")).astype(np.float32)
    if a[..., 3].min() < 250:
        return a
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    m = np.minimum(r, b) - g                  # quanto è magenta
    alfa = np.clip((150 - m) / 90, 0, 1)      # 150 e oltre: fondo
    # il bordo che sfuma nel magenta: si toglie il magenta mescolato, resta il colore
    k = np.maximum(alfa, 0.05)[..., None]
    a[..., :3] = np.clip((a[..., :3] - (1 - k) * np.array([255, 0, 255])) / k, 0, 255)
    a[..., 3] = alfa * 255
    return a


def manichino(posto):
    """Il pezzo di base in grigio nella sua casella (come nello stampino)."""
    gruppi, (x0, y0, x1, y1) = ST.pezzo(posto)
    box = (x0 - ST.MARGINE, y0 - ST.MARGINE, x1 + ST.MARGINE, y1 + ST.MARGINE)
    return np.asarray(ST.grigio(ST.disegna(gruppi, box, ST.S))).astype(np.float32)


def allinea(pezzo, base):
    """Sposta e scala il pezzo (RGBA, grande come la casella) finché la sua sagoma
    combacia di più con quella del manichino. Torna il pezzo spostato."""
    h, w = base.shape[:2]
    mb = (base[..., 3] > 128).astype(np.float32)
    meglio, risultato = -1, pezzo
    im = Image.fromarray(pezzo.astype(np.uint8), "RGBA")
    for s in np.arange(0.88, 1.13, 0.03):
        sw, sh = round(w * s), round(h * s)
        sc = np.asarray(im.resize((sw, sh), Image.LANCZOS)).astype(np.float32)
        # al centro di una tela grande come la casella
        tela = np.zeros((h, w, 4), np.float32)
        ox, oy = (w - sw) // 2, (h - sh) // 2
        sx0, sy0 = max(0, -ox), max(0, -oy)
        tx0, ty0 = max(0, ox), max(0, oy)
        cw, ch = min(sw - sx0, w - tx0), min(sh - sy0, h - ty0)
        tela[ty0:ty0 + ch, tx0:tx0 + cw] = sc[sy0:sy0 + ch, sx0:sx0 + cw]
        mp = (tela[..., 3] > 128).astype(np.float32)
        # la correlazione per tutti gli spostamenti in una volta (FFT)
        c = np.real(np.fft.ifft2(np.fft.fft2(mb) * np.conj(np.fft.fft2(mp))))
        dy, dx = np.unravel_index(np.argmax(c), c.shape)
        dy = dy - h if dy > h // 2 else dy
        dx = dx - w if dx > w // 2 else dx
        if abs(dx) > w * 0.2 or abs(dy) > h * 0.2:
            continue
        inter = c.max()
        iou = inter / (mb.sum() + mp.sum() - inter + 1e-6)
        if iou > meglio:
            meglio, risultato = iou, np.roll(np.roll(tela, dy, 0), dx, 1)
    return risultato


def taglia(foglio, nome, categoria, sopra, allinea_pezzi):
    with open(ST.FOGLIO) as f:
        F = json.load(f)
    im = Image.open(foglio).convert("RGBA")
    # alla misura dello stampino (ChatGPT dà 1536 x 1024, Procreate quella giusta)
    if im.size != (F["larghezza"], F["altezza"]):
        k = min(F["larghezza"] / im.width, F["altezza"] / im.height)
        im2 = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
        im = Image.new("RGBA", (F["larghezza"], F["altezza"]), (255, 0, 255, 255))
        im.paste(im2, (0, 0))
    a = fondo_via(im)
    D = leggi_diavoletto()
    px = D["px"]
    os.makedirs(ASSETS, exist_ok=True)
    for f in glob.glob(os.path.join(ASSETS, nome + "_*.png")):
        os.remove(f)
    pezzi = {}
    for posto, c in F["posti"].items():
        x0, y0, x1, y1 = c["casella"]
        pz = a[y0:y1, x0:x1].copy()
        base = manichino(posto)
        if sopra:
            # via quello che è ancora il manichino: resta solo il disegno nuovo
            uguale = (np.abs(pz[..., :3] - base[..., :3]).max(axis=2) < 24) & (base[..., 3] > 200)
            pz[uguale, 3] = 0
        if (pz[..., 3] > 128).sum() < 0.004 * pz.shape[0] * pz.shape[1]:
            continue
        if allinea_pezzi:
            pz = allinea(pz, base)
        pezzi[posto] = salva(pz, nome, posto, c["perno"][0] - x0, c["perno"][1] - y0, F["scala"], px)
    if not pezzi:
        sys.exit("nessun pezzo disegnato nello stampino")
    # le versioni di dietro, se mancano
    for dietro, davanti in DIETRO.items():
        if davanti in pezzi and dietro not in pezzi:
            p = dict(pezzi[davanti])
            img = Image.open(os.path.join(ASSETS, p["img"] + ".png"))
            r, g, b, al = img.split()
            img = Image.merge("RGBA", [ch.point(lambda v: round(v * SCURO)) for ch in (r, g, b)] + [al])
            p["img"] = f"{nome}_{dietro}"
            img.save(os.path.join(ASSETS, p["img"] + ".png"), optimize=True)
            pezzi[dietro] = p
    modo = "sopra" if sopra else "sostituisce"
    for p in pezzi.values():
        p["modo"] = modo
    os.makedirs(JSON, exist_ok=True)
    with open(os.path.join(JSON, nome + ".json"), "w") as f:
        json.dump({"nome": nome, "categoria": categoria, "pezzi": pezzi}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print(f"{nome} ({categoria}, {modo}): {', '.join(sorted(pezzi))}")


def salva(pz, nome, posto, px0, py0, scala, px):
    """Il pezzo ritagliato alla sua sagoma, rimpicciolito ai pixel del gioco; torna
    centro e misura rispetto al perno, in unità del disegno."""
    al = pz[..., 3]
    ys, xs = np.nonzero(al > 8)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    img = Image.fromarray(np.clip(pz[y0:y1, x0:x1], 0, 255).astype(np.uint8), "RGBA")
    w, h = (x1 - x0) / scala, (y1 - y0) / scala
    img = img.resize((max(1, round(w * px)), max(1, round(h * px))), Image.LANCZOS)
    img = img.filter(ImageFilter.UnsharpMask(1, 40, 2))
    nome_img = f"{nome}_{posto}"
    img.save(os.path.join(ASSETS, nome_img + ".png"), optimize=True)
    cx, cy = ((x0 + x1) / 2 - px0) / scala, (py0 - (y0 + y1) / 2) / scala
    return {"img": nome_img, "x": round(cx, 1), "y": round(cy, 1), "w": round(w, 1), "h": round(h, 1)}


def leggi_diavoletto():
    """px dal diavoletto di base (battaglia/diavoletto.lua): i pezzi nuovi hanno la
    stessa densità."""
    with open(os.path.join(RADICE, "client", "battaglia", "diavoletto.lua")) as f:
        for riga in f:
            riga = riga.strip()
            if riga.startswith("px ="):
                return {"px": float(riga.split("=")[1].split(",")[0])}
    raise SystemExit("px non trovato in diavoletto.lua")


def rifai():
    """client/battaglia/pelli.lua e l'atlante del diavoletto da tutte le pelli."""
    pelli = []
    for f in sorted(glob.glob(os.path.join(JSON, "*.json"))):
        with open(f) as fh:
            pelli.append(json.load(fh))
    lua = ["-- Fatto da strumenti/stampino/taglia.py, non modificare a mano.",
           "-- Le pelli: i pezzi nuovi del diavoletto disegnati sullo stampino. Ogni pezzo",
           "-- va in un posto dello scheletro (come i pezzi di battaglia/diavoletto.lua:",
           "-- immagine, centro rispetto al perno, misura) e sostituisce il pezzo di base",
           "-- o si disegna sopra. Una pelle per categoria; quelle sopra in ordine.",
           "return {",
           "\tsostituisce = { " + ", ".join(f'"{c}"' for c in SOSTITUISCE) + " },",
           "\tsopra = { " + ", ".join(f'"{c}"' for c in SOPRA) + " },",
           "\tpelli = {"]
    for p in pelli:
        lua.append(f'\t\t{p["nome"]} = {{ categoria = "{p["categoria"]}", pezzi = {{')
        for posto in sorted(p["pezzi"]):
            z = p["pezzi"][posto]
            lua.append(f'\t\t\t{posto} = {{ img = "{z["img"]}", x = {z["x"]}, y = {z["y"]}, w = {z["w"]}, '
                       f'h = {z["h"]}, modo = "{z["modo"]}" }},')
        lua.append("\t\t} },")
    lua += ["\t},", "}"]
    with open(LUA, "w") as f:
        f.write("\n".join(lua) + "\n")
    ST.DV.scrivi_atlante()
    print("OK:", len(pelli), "pelli in", os.path.relpath(LUA, RADICE))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("foglio", nargs="?")
    ap.add_argument("--nome")
    ap.add_argument("--categoria", choices=CATEGORIE)
    ap.add_argument("--sopra", action="store_true", help="i pezzi vanno sopra quelli di base (default per la categoria)")
    ap.add_argument("--sostituisce", action="store_true", help="i pezzi prendono il posto di quelli di base")
    ap.add_argument("--allinea", action="store_true", help="allinea ogni pezzo al manichino (disegni di ChatGPT)")
    ap.add_argument("--rifai", action="store_true")
    ap.add_argument("--togli")
    a = ap.parse_args()
    if a.togli:
        for f in glob.glob(os.path.join(ASSETS, a.togli + "_*.png")) + [os.path.join(JSON, a.togli + ".json")]:
            if os.path.exists(f):
                os.remove(f)
    elif not a.rifai:
        if not (a.foglio and a.nome and a.categoria):
            ap.error("servono FOGLIO, --nome e --categoria")
        if not re.fullmatch(r"[a-z][a-z0-9_]*", a.nome) or a.nome in ST.DV.PEZZI:
            ap.error("il nome: lettere minuscole, cifre e _, diverso dai pezzi di base")
        sopra = a.sopra or (a.categoria in SOPRA and not a.sostituisce)
        taglia(a.foglio, a.nome, a.categoria, sopra, a.allinea)
    rifai()


if __name__ == "__main__":
    main()
