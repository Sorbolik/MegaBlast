"""Il globo del teletrasporto che arriva nel pulsante (client/assets/suoni/globo.ogg):
un "pling-ding" di vetro, due note a una quarta (come la moneta dei giochi
classici) con una salita veloce all'attacco e un luccichio di parziali
inarmoniche che si spegne prima della nota. Il gioco lo suona più acuto per
ogni globo dopo il primo (velocità, client/main/game.gui_script).

Sintetizzato qui, niente file presi da fuori: pesa pochi kB, si rifà uguale
e si ritocca cambiando i numeri. Serve ffmpeg (libvorbis) per l'ogg.

    python3 strumenti/suoni/globo.py
"""
import math
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

FREQ, DURATA = 22050, 0.42
F0 = 988.0                 # si5; la seconda nota è mi6 (una quarta sopra)
USCITA = Path(__file__).resolve().parents[2] / "client/assets/suoni/globo.ogg"

# (rapporto con la nota, ampiezza, tempo di spegnimento in s)
PARZIALI = [(1, 0.55, 0.22), (2, 0.22, 0.10), (3, 0.10, 0.06), (4.17, 0.07, 0.035), (5.43, 0.05, 0.025)]


SALITA = 0.025             # nei primi 25 ms la nota sale da 0,9 a 1: il globo "entra"


def fase(t, f):
    """fase della nota f al tempo t, con la salita integrata"""
    if t < SALITA:
        return 2 * math.pi * f * (0.9 * t + 0.1 * t * t / (2 * SALITA))
    return 2 * math.pi * f * (0.95 * SALITA + (t - SALITA))


def nota(t, f, inizio, forza):
    t = t - inizio
    if t < 0:
        return 0.0
    v = 0.0
    for r, a, dec in PARZIALI:
        ph = fase(t, f * r)
        # una copia appena stonata per il luccichio
        v += a * math.exp(-t / dec) * (math.sin(ph) + 0.35 * math.sin(ph * 1.004))
    return forza * min(1.0, t / 0.003) * v


campioni = []
for i in range(int(FREQ * DURATA)):
    t = i / FREQ
    v = nota(t, F0, 0.0, 0.6) + nota(t, F0 * 4 / 3, 0.065, 0.75)
    # coda morbida negli ultimi 40 ms
    v *= min(1.0, (DURATA - t) / 0.04)
    campioni.append(v)

picco = max(abs(v) for v in campioni)
dati = struct.pack("<%dh" % len(campioni), *(int(v / picco * 0.7 * 32767) for v in campioni))

with tempfile.TemporaryDirectory() as tmp:
    wav = Path(tmp) / "globo.wav"
    with wave.open(str(wav), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FREQ)
        w.writeframes(dati)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "4", str(USCITA)], check=True)
print(USCITA, len(campioni), "campioni,", USCITA.stat().st_size, "byte")
