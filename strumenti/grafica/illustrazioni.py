"""Illustrazioni delle missioni (WB-015): dai PNG scelti in art/WB-015/ ai JPEG
del gioco in client/paintings/missions/: <id>.jpg a 1672 x 941 (la misura di Codex) per la cartolina dell'apertura
della missione, <id>_carta.jpg per la carta della CAMPAGNA. Le missioni con
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
CARTA = (320, 180)  # disegnata a 148 x 83: il doppio per gli schermi grandi


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


if __name__ == "__main__":
    main()
