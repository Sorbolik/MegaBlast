import numpy as np
from PIL import Image
from scipy import ndimage as nd
a=np.asarray(Image.open('/mnt/project-files/grafica/concept/scoria_pezzi_v1.png').convert('RGB')).astype(float)
H,W,_=a.shape
# background model: quadratic fit on pixels close to typical bg
ref=np.array([44,48,59.])
d=np.linalg.norm(a-ref,axis=2)
cand=d<10
yy,xx=np.mgrid[0:H,0:W]/np.array([H,W]).reshape(2,1,1)
X=np.stack([np.ones(H*W),xx.ravel(),yy.ravel(),xx.ravel()**2,yy.ravel()**2,(xx*yy).ravel()],1)
bg=np.zeros_like(a)
for c in range(3):
    coef,*_=np.linalg.lstsq(X[cand.ravel()],a[...,c].ravel()[cand.ravel()],rcond=None)
    bg[...,c]=(X@coef).reshape(H,W)
dist=np.linalg.norm(a-bg,axis=2)
np.save('bg.npy',bg); np.save('dist.npy',dist)
fg=dist>14
fg=nd.binary_opening(fg,iterations=1)
fg=nd.binary_fill_holes(nd.binary_closing(fg,iterations=3))
lab,n=nd.label(fg)
sizes=nd.sum(fg,lab,range(1,n+1))
print('bg range',bg.min(axis=(0,1)),bg.max(axis=(0,1)))
for i,s in enumerate(sizes,1):
    if s>2000:
        sl=nd.find_objects((lab==i).astype(int))[0]
        print(i,int(s),'x',sl[1].start,sl[1].stop,'y',sl[0].start,sl[0].stop)
np.save('lab.npy',lab)
