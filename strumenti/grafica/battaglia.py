# Prepara fx/bagliore.png: alone bianco per missile, mirino e scintille
import numpy as np
from PIL import Image
C = 64
yy, xx = np.mgrid[0:C, 0:C] + 0.5
d = np.hypot(xx - C / 2, yy - C / 2) / (C / 2)
a = np.clip(1 - d, 0, 1) ** 2.2
Image.fromarray(np.dstack([np.full((C, C, 3), 255), a * 255]).astype(np.uint8), 'RGBA').save('client/assets/fx/bagliore.png', optimize=True)
