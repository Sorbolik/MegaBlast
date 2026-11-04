"""Illustrazioni delle missioni (WB-015): dai PNG scelti in art/WB-015/ ai JPEG
del gioco in client/paintings/missions/: <id>.jpg a 1672 x 941 (la misura di Codex) per la cartolina dell'apertura
della missione, <id>_carta.jpg per la carta della bacheca della CAMPAGNA, <id>_finale.jpg per la striscia
del finale del capitolo (un pezzo di una tavola della storia). Le missioni con
l'illustrazione vanno anche in client/ui/illustrations.lua (M.MISSIONS).

Anche le tavole della storia (WB-012, WB-017): <id>.jpg in client/paintings/story/,
alla misura di Codex e con la loro forma (larghe o quadrate). Le tavole nuove vanno
anche in client/ui/story.lua (M.PANELS).

    python3 strumenti/grafica/illustrazioni.py
"""
import os
from PIL import Image

RADICE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ORIGINE = os.path.join(RADICE, "art", "WB-015")
META = os.path.join(RADICE, "client", "paintings", "missions")

# file di Codex -> id della missione (client/sim/campaign.lua)
MISSIONI = {
    "c1_stammi_dietro": "primi_passi",
    "c2_lanciarune": "lanciarune",
    "c3_a_turno": "turno",
    "c4_tempo": "tempo",
    "c5_in_cima": "spostano",
    "c6_burrone": "attrezzi",
}
# tavole della storia: cartella di Codex -> nomi (gli id nel gioco)
STORIA = {
    "WB-012": ["4_arrivo_a", "4_arrivo_b", "4_arrivo_c", "5_fabbro_a", "5_fabbro_c_1",
               "6_rapimento_a", "6_rapimento_b", "6_rapimento_c"],
    "WB-017": ["s_viaggio", "s_forgia_aperta", "s_regalo", "s_insieme", "s_ghiaccio"],
}
META_STORIA = os.path.join(RADICE, "client", "paintings", "story")
GRANDE = (1672, 941)  # la misura di Codex: niente ingrandimenti (Sergio, 4 nov: «sgranata»)
CARTA = (536, 302)  # sulla bacheca della CAMPAGNA a 268 x 151: il doppio per gli schermi grandi
# il finale del capitolo, la striscia larga sotto la bacheca: un pezzo di una tavola
# della storia (cartella, tavola, dove sta il centro della striscia in altezza, da 0 a 1)
FINALI = {
    "guidata": ("WB-012", "4_arrivo_c", 0.43),
    "battaglia_forgia": ("WB-017", "s_insieme", 0.42),
}
FINALE = (520, 88)  # a 260 x 44: il doppio


def a_misura(img, w, h):
    """Ritaglia al centro a w:h e ridimensiona, senza deformare."""
    sw, sh = img.size
    if sw * h > sh * w:
        nw = round(sh * w / h)
        img = img.crop(((sw - nw) // 2, 0, (sw - nw) // 2 + nw, sh))
    else:
        nh = round(sw * h / w)
        img = img.crop((0, (sh - nh) // 2, sw, (sh - nh) // 2 + nh))
    return img.resize((w, h), Image.LANCZOS)


def main():
    os.makedirs(META, exist_ok=True)
    for nome, mid in MISSIONI.items():
        src = os.path.join(ORIGINE, nome + ".png")
        if not os.path.exists(src):
            print("manca", src)
            continue
        img = Image.open(src).convert("RGB")
        a_misura(img, *GRANDE).save(os.path.join(META, mid + ".jpg"), quality=92, optimize=True)
        a_misura(img, *CARTA).save(os.path.join(META, mid + "_carta.jpg"), quality=88, optimize=True)
        print("scritto", mid)
    os.makedirs(META_STORIA, exist_ok=True)
    for cartella, nomi in STORIA.items():
        for nome in nomi:
            src = os.path.join(RADICE, "art", cartella, nome + ".png")
            if not os.path.exists(src):
                print("manca", src)
                continue
            Image.open(src).convert("RGB").save(os.path.join(META_STORIA, nome + ".jpg"), quality=90, optimize=True)
            print("scritta la tavola", nome)
    for mid, (cartella, nome, cy) in FINALI.items():
        src = os.path.join(RADICE, "art", cartella, nome + ".png")
        if not os.path.exists(src):
            print("manca", src)
            continue
        img = Image.open(src).convert("RGB")
        w, h = img.size
        sh = round(w * FINALE[1] / FINALE[0])
        top = min(max(0, round(cy * h - sh / 2)), h - sh)
        img.crop((0, top, w, top + sh)).resize(FINALE, Image.LANCZOS).save(
            os.path.join(META, mid + "_finale.jpg"), quality=88, optimize=True)
        print("scritto il finale", mid)


if __name__ == "__main__":
    main()
