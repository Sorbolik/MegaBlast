# Scrive client/sim/mapdata.lua dalle maschere delle mappe disegnate (640 x 360:
# bianco terra, rosso acciaio). Lanciare dalla cartella del repository.
import numpy as np
from PIL import Image
MAPPE = [
    ('cimitero', 'grafica/mappe/mappa_isole_cimitero/maschera.png'),
    ('forgia', 'grafica/mappe/mappa_forgia/maschera.png'),
    ('crogiolo', 'grafica/mappe/mappa_crogiolo/maschera.png'),
]

def righe(path):
    m = np.asarray(Image.open('/mnt/project-files/' + path).convert('RGB')).astype(int)
    cell = np.zeros(m.shape[:2], np.uint8)
    cell[(m[..., 0] > 127) & (m[..., 1] > 127)] = 1
    cell[(m[..., 0] > 127) & (m[..., 1] < 128)] = 2
    ch, rows = '.ds', []
    for cy in range(360):
        row, s, i = cell[359 - cy], [], 0
        while i < 640:
            j = i
            while j < 640 and row[j] == row[i]: j += 1
            s.append(f'{ch[row[i]]}{j - i}'); i = j
        rows.append(''.join(s))
    return rows

parti = []
for nome, path in MAPPE:
    body = '\n'.join(f'\t"{r}",' for r in righe(path))
    parti.append(f'-- {path}\nM.{nome} = {{\n{body}\n}}\n')
open('client/sim/mapdata.lua', 'w').write('''-- Dati delle mappe disegnate a mano: la maschera di collisione 640 x 360 celle,
-- una stringa per riga dal basso verso l'alto. Ogni tratto è un carattere
-- (. vuoto, d terra, s acciaio/ossa) seguito da quante celle dura.
-- Generato da grafica/strumenti/mappa_in_lua.py a partire da maschera.png della mappa: non modificare a mano.

local M = {}

''' + '\n'.join(parti) + '\nreturn M\n')
