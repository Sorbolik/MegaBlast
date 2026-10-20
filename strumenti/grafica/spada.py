import numpy as np
from PIL import Image
from scipy import ndimage as nd
a=np.asarray(Image.open('/mnt/project-files/grafica/concept/spadone_v1.png').convert('RGB')).astype(float)
H,W,_=a.shape; ref=a[5,5]
d=np.linalg.norm(a-ref,axis=2); cand=d<10
yy,xx=np.mgrid[0:H,0:W]/np.array([H,W]).reshape(2,1,1)
X=np.stack([np.ones(H*W),xx.ravel(),yy.ravel(),xx.ravel()**2,yy.ravel()**2,(xx*yy).ravel()],1)
bg=np.zeros_like(a)
for c in range(3):
    coef,*_=np.linalg.lstsq(X[cand.ravel()],a[...,c].ravel()[cand.ravel()],rcond=None); bg[...,c]=(X@coef).reshape(H,W)
dist=np.linalg.norm(a-bg,axis=2)
alpha=np.clip((dist-6)/18,0,1)
fg=nd.binary_fill_holes(nd.binary_closing(dist>14,iterations=3)); l,n=nd.label(fg); sz=nd.sum(fg,l,range(1,n+1))
keep=np.zeros_like(fg)
for k,v in enumerate(sz,1):
    if v>3000: keep|=l==k
alpha*=nd.binary_dilation(keep,iterations=4)
mx=a.max(2); mn=a.min(2); sat=(mx-mn)/np.maximum(mx,1); lum=a.mean(2)
glow=np.clip((lum-150)/70,0,1)*(sat<0.18)*alpha
ys,xs=np.where(alpha>0.03); Y0,Y1,X0,X1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
A=alpha[Y0:Y1,X0:X1]; C=a[Y0:Y1,X0:X1]; Bg=bg[Y0:Y1,X0:X1]; G=glow[Y0:Y1,X0:X1]
col=np.clip((C-(1-A[...,None])*Bg)/np.maximum(A[...,None],1e-3),0,255)
base=col*(1-G[...,None])+np.array([40,36,48.])*G[...,None]
# blade base: keep a faint body so blade still reads before tint
Image.fromarray(np.dstack([base,A*(1-G*0.6)*255]).astype(np.uint8),'RGBA').save('raw_spadone.png')
Image.fromarray(np.dstack([np.full(A.shape+(3,),255),G*255]).astype(np.uint8),'RGBA').save('raw_spadone_luce.png')
# grip pivot: middle of the handle (x ~ 330 in source)
piv=(330-X0, 400-Y0); print('size',A.shape,'pivot',piv)
open('pivot.txt','w').write(f'{piv[0]} {piv[1]} {A.shape[1]} {A.shape[0]}')
