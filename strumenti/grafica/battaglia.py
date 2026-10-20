# Prepara i file usati dalla battaglia a partire dai pezzi della mappa:
#   terreno.png    = superficie con sopra le ossa (un solo strato da mascherare)
#   interno_mezzo.png = parete dei crateri a metà risoluzione (è già sfocata)
#   fx/bagliore.png   = alone bianco per missile, mirino e scintille
import numpy as np
from PIL import Image
M = 'client/assets/mappe/isole_cimitero/'
sup = Image.open(M + 'superficie.png').convert('RGBA')
sup.alpha_composite(Image.open(M + 'ossa.png').convert('RGBA'))
sup.save(M + 'terreno.png', optimize=True)
i = Image.open(M + 'interno.png').convert('RGBA')
i.resize((i.width // 2, i.height // 2), Image.LANCZOS).save(M + 'interno_mezzo.png', optimize=True)
C = 64
yy, xx = np.mgrid[0:C, 0:C] + 0.5
d = np.hypot(xx - C / 2, yy - C / 2) / (C / 2)
a = np.clip(1 - d, 0, 1) ** 2.2
Image.fromarray(np.dstack([np.full((C, C, 3), 255), a * 255]).astype(np.uint8), 'RGBA').save('client/assets/fx/bagliore.png', optimize=True)
