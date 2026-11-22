# La palla della Cannonata di Codex (WB-083) ritagliata per il gioco: toglie il magenta
# (fondo e feritoia, che resta vuota: dietro il gioco disegna la testa del personaggio) e
# scrive in art/armi/ la palla e i due gusci nello stesso riquadro della palla (nel gioco
# partono da dove sta lei: il guscio di sopra in alto, quello di sotto in basso).
# Poi tools/grafica/armi.py li mette alla misura del gioco.
#
# python3 tools/grafica/palla_cannonata.py
import os
import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..", "..")
ART = os.path.join(RADICE, "art", "WB-083")
OUT = os.path.join(RADICE, "art", "armi")
# la variante scelta da Codex (feritoia più regolare)
PALLA = "palla_feritoia_2.png"


def senza_magenta(im):
    # il magenta (anche quello sfumato sul bordo nero) diventa trasparente; i bordi
    # restano neri con la loro trasparenza
    a = np.array(im.convert("RGB")).astype(float)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    lo = np.minimum(r, b)
    magenta = (g < 0.55 * lo) & (np.abs(r - b) < 0.35 * np.maximum(r, b) + 8) & (lo > 20)
    alfa = np.where(magenta, 1 - lo / 255, 1.0)
    rgb = np.where(magenta[..., None], 0, a)
    out = np.dstack([rgb, alfa * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def ritaglia(im):
    return im.crop(im.getbbox())


def main():
    palla = ritaglia(senza_magenta(Image.open(os.path.join(ART, PALLA))))
    palla.save(os.path.join(OUT, "palla_cannonata.png"), optimize=True)
    W, H = palla.size
    gusci = senza_magenta(Image.open(os.path.join(ART, "palla_gusci.png")))
    meta = gusci.width // 2
    su = ritaglia(gusci.crop((0, 0, meta, gusci.height)))
    giu = ritaglia(gusci.crop((meta, 0, gusci.width, gusci.height)))
    # i gusci alla larghezza della palla, nel suo riquadro
    for pezzo, nome, alto in ((su, "guscio_su", True), (giu, "guscio_giu", False)):
        k = W / pezzo.width
        pezzo = pezzo.resize((W, round(pezzo.height * k)), Image.LANCZOS)
        tela = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        tela.alpha_composite(pezzo, (0, 0 if alto else H - pezzo.height))
        tela.save(os.path.join(OUT, nome + ".png"), optimize=True)


if __name__ == "__main__":
    main()
