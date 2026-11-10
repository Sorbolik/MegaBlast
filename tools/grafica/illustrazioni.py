"""Le tavole della storia (WB-012, WB-017): dai PNG scelti in art/ ai JPEG del gioco,
<id>.jpg in client/paintings/story/, alla misura di Codex e con la loro forma (larghe o
quadrate). Le tavole nuove vanno anche in client/ui/story.lua (M.PANELS).

Le missioni della CAMPAGNA non hanno più illustrazioni dipinte (Sergio, 6 nov: troppa
lava anche nel cortile; i dipinti restano solo nella STORIA): le loro carte mostrano la
miniatura della mappa, che fa tools/grafica/miniature_missioni.py. I dipinti di
WB-015 restano in art/WB-015/.

    python3 tools/grafica/illustrazioni.py
"""
import os
from PIL import Image

RADICE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# tavole della storia: cartella di Codex -> nomi (gli id nel gioco)
STORIA = {
    "WB-012": ["4_arrivo_a", "4_arrivo_b", "4_arrivo_c", "5_fabbro_a", "5_fabbro_c_1",
               "6_rapimento_a", "6_rapimento_b", "6_rapimento_c"],
    "WB-017": ["s_viaggio", "s_forgia_aperta", "s_regalo", "s_insieme", "s_ghiaccio"],
}
META_STORIA = os.path.join(RADICE, "client", "paintings", "story")


def main():
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
