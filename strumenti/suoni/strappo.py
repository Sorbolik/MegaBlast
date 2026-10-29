"""La fune del Rampino che si spezza (client/assets/suoni/strappo.ogg): quando il
nemico tirato resta appeso perché la fune è tutta riavvolta, uno schiocco secco
come una frusta, il "twang" basso della fune che si allenta di colpo e il
fruscio del filo che ricade. Il gioco lo suona all'evento hook_end con snap
(client/main/game.gui_script).

Sintetizzato qui come globo.py: pochi kB, si rifà uguale (rumore con seme
fisso) e si ritocca cambiando i numeri. Serve ffmpeg (libvorbis) per l'ogg.

    python3 strumenti/suoni/strappo.py
"""
import math
import random
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

FREQ, DURATA = 22050, 0.5
USCITA = Path(__file__).resolve().parents[2] / "client/assets/suoni/strappo.ogg"

caso = random.Random(7)
rumore = [caso.uniform(-1, 1) for _ in range(int(FREQ * DURATA))]

# lo schiocco: rumore acuto (differenza di campioni vicini) che muore in 9 ms
SCHIOCCO = 0.009
# il twang: da 190 Hz scende a 70 in 120 ms, si spegne in 0,16 s
TWANG_DA, TWANG_A, TWANG_SCENDE, TWANG_SPEGNE = 190.0, 70.0, 0.12, 0.16
# il fruscio del filo: rumore scuro che entra a 20 ms e si spegne in 0,12 s
FRUSCIO_DA, FRUSCIO_SPEGNE = 0.02, 0.12

campioni = []
fase, scuro = 0.0, 0.0
for i in range(int(FREQ * DURATA)):
    t = i / FREQ
    # schiocco
    acuto = rumore[i] - (rumore[i - 1] if i else 0.0)
    v = 1.0 * math.exp(-t / SCHIOCCO) * acuto
    # twang: la nota cala e trema un poco, con due armoniche che fanno "corda"
    f = TWANG_A + (TWANG_DA - TWANG_A) * math.exp(-t / TWANG_SCENDE * 3)
    f *= 1 + 0.02 * math.sin(2 * math.pi * 23 * t)
    fase += 2 * math.pi * f / FREQ
    corda = math.sin(fase) + 0.45 * math.sin(2 * fase) + 0.2 * math.sin(3 * fase + 0.5)
    v += 0.55 * min(1.0, t / 0.002) * math.exp(-t / TWANG_SPEGNE) * corda
    # fruscio: rumore filtrato (media mobile), solo dopo lo schiocco
    scuro += (rumore[i] - scuro) * 0.18
    if t > FRUSCIO_DA:
        u = t - FRUSCIO_DA
        v += 0.5 * min(1.0, u / 0.015) * math.exp(-u / FRUSCIO_SPEGNE) * scuro
    # coda morbida negli ultimi 40 ms
    v *= min(1.0, (DURATA - t) / 0.04)
    campioni.append(v)

picco = max(abs(v) for v in campioni)
dati = struct.pack("<%dh" % len(campioni), *(int(v / picco * 0.85 * 32767) for v in campioni))

with tempfile.TemporaryDirectory() as tmp:
    wav = Path(tmp) / "strappo.wav"
    with wave.open(str(wav), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FREQ)
        w.writeframes(dati)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "4", str(USCITA)], check=True)
print(USCITA, len(campioni), "campioni,", USCITA.stat().st_size, "byte")
