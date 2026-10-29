"""Il ticchettio dei punti (client/assets/suoni/punto.wav): un tic corto e chiaro,
due sinusoidi che si spengono in 45 ms. Il gioco lo suona sempre più acuto
(velocità) finché i punti salgono nel gettone (client/battaglia/punteggio.lua).

    python3 strumenti/suoni/punto.py
"""
import math
import struct
import wave
from pathlib import Path

FREQ, DURATA = 22050, 0.045
USCITA = Path(__file__).resolve().parents[2] / "client/assets/suoni/punto.wav"

campioni = []
for i in range(int(FREQ * DURATA)):
    t = i / FREQ
    attacco = min(1.0, t / 0.002)
    v = attacco * math.exp(-t / 0.012) * (0.7 * math.sin(2 * math.pi * 1760 * t) + 0.3 * math.sin(2 * math.pi * 2640 * t))
    campioni.append(int(max(-1, min(1, 0.5 * v)) * 32767))

with wave.open(str(USCITA), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(FREQ)
    w.writeframes(struct.pack("<%dh" % len(campioni), *campioni))
print(USCITA, len(campioni), "campioni")
