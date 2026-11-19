"""I suoni dello scatto di un pezzo (livelli 10, 20, 30), gli stessi della pagina
"Proposte zaino e scatto" approvata da Sergio (18 nov): là li faceva il browser
con tre oscillatori e un rumore, qui si rifanno uguali e si salvano in ogg.

    scatto_carica  il tocco e il ronzio che sale mentre il pezzo si carica
    scatto_colpo1..3  i tre colpi, ognuno più acuto
    scatto_boom    l'esplosione
    scatto_titolo  SCATTO! che sbatte
    scatto_riga    ogni riga di novità (il gioco la suona più acuta per la seconda e la terza)

Il ronzio dura quanto la carica di client/ui/step_scene.lua: se cambiano i tempi,
cambia DRONE qui sotto e rifai i file.

    python3 tools/suoni/scatto.py
"""
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

SR = 44100
OUT = Path(__file__).resolve().parents[2] / "client/assets/sounds"
CARICA, DRONE = 0.70, 2.75   # quando parte il ronzio nella scena e quanto dura
rng = np.random.default_rng(7)


def tone(f, d, kind="square", v=0.2, slide=0.0):
    """come tone() della pagina: volume e (se c'è) tono che scendono/salgono in esponenziale"""
    t = np.arange(int(SR * d)) / SR
    if slide:
        k = np.log(slide / f) / d
        ph = f * (np.exp(k * t) - 1) / k
    else:
        ph = f * t
    x = ph % 1.0
    if kind == "square":
        w = np.where(x < 0.5, 1.0, -1.0)
    elif kind == "sawtooth":
        w = 2 * x - 1
    else:
        w = 1 - 4 * np.abs(x - 0.5)
    return w * v * (0.001 / v) ** (t / d)


def noise(d, v=0.3):
    n = int(SR * d)
    return (rng.random(n) * 2 - 1) * (1 - np.arange(n) / n) ** 2 * v


def mix(*parts):
    """parts: (inizio in s, campioni)"""
    n = max(int(SR * at) + len(p) for at, p in parts)
    out = np.zeros(n)
    for at, p in parts:
        i = int(SR * at)
        out[i:i + len(p)] += p
    return out


SUONI = {
    "scatto_carica": mix((0, tone(300, .08, "square", .1)), (CARICA, tone(55, DRONE, "sawtooth", .06, 90))),
    "scatto_boom": mix((0, noise(.9, .5)), (0, tone(110, .9, "sawtooth", .25, 40)), (0, tone(880, .6, "triangle", .15, 1760))),
    "scatto_titolo": mix((0, tone(80, .3, "square", .25, 50)), (0, noise(.2, .3))),
    "scatto_riga": tone(660, .12, "triangle", .12),
}
for k in range(3):
    SUONI["scatto_colpo%d" % (k + 1)] = mix((0, tone(700 + k * 260, .35, "triangle", .25)),
                                            (0, tone(1400 + k * 400, .2, "square", .06)), (0, noise(.15, .25)))

# lo stesso volume fra loro, come nella pagina; il più forte arriva a 0,95
picco = max(np.abs(s).max() for s in SUONI.values())
with tempfile.TemporaryDirectory() as tmp:
    for nome, s in SUONI.items():
        wav = Path(tmp) / (nome + ".wav")
        with wave.open(str(wav), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((s / picco * 0.95 * 32767).astype("<i2").tobytes())
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "4",
                        str(OUT / (nome + ".ogg"))], check=True)
        print(nome)
