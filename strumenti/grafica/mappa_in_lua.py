import numpy as np
from PIL import Image
m=np.asarray(Image.open('/mnt/project-files/grafica/mappe/mappa_isole_cimitero/maschera.png').convert('RGB'))
cell=np.zeros(m.shape[:2],np.uint8); cell[(m[...,0]>127)&(m[...,1]>127)]=1; cell[(m[...,0]>127)&(m[...,1]<128)]=2
ch='.ds'; rows=[]
for cy in range(360):
    row=cell[359-cy]; s=[]; i=0
    while i<640:
        j=i
        while j<640 and row[j]==row[i]: j+=1
        s.append(f'{ch[row[i]]}{j-i}'); i=j
    rows.append(''.join(s))
body='\n'.join(f'\t"{r}",' for r in rows)
open('client/sim/mapdata.lua','w').write(f'''-- Dati delle mappe disegnate a mano: la maschera di collisione 640 x 360 celle,
-- una stringa per riga dal basso verso l'alto. Ogni tratto è un carattere
-- (. vuoto, d terra, s acciaio/ossa) seguito da quante celle dura.
-- Generato da grafica/strumenti/ a partire da maschera.png della mappa: non modificare a mano.

local M = {{}}

-- grafica/mappe/mappa_isole_cimitero/maschera.png
M.cimitero = {{
{body}
}}

return M
''')
print(sum(len(r) for r in rows))
