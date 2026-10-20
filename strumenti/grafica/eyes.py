import numpy as np
from PIL import Image
from scipy import ndimage as nd
m=np.load('eye_mask.npy'); ys,xs=np.where(m)
pad=30; y0,y1,x0,x1=ys.min()-pad,ys.max()+pad+1,xs.min()-pad,xs.max()+pad+1
E=m[y0:y1,x0:x1].astype(float); h,w=E.shape
cy,cx=[v.mean() for v in np.where(E>0)]
Y,X=np.mgrid[0:h,0:w]
sock=nd.binary_erosion(E>0,iterations=3)
def soft(mask,s=1.2): return np.clip(nd.gaussian_filter(mask.astype(float),s),0,1)
def hi(alpha,dx=-0.18,dy=-0.25,r=6):
    hy,hx=cy+dy*(np.ptp(ys)),cx+dx*(np.ptp(xs)); spot=((Y-hy)**2+(X-hx)**2)<r*r
    return np.maximum(alpha,soft(spot,1.5)*alpha.max())
eh=np.ptp(ys); ew=np.ptp(xs)
ex={}
ex['neutro']=hi(soft(sock)*0.85)
ex['mira']=soft(sock&(np.abs(Y-cy)<eh*0.14))
ex['paura']=hi(soft(((Y-cy)**2+(X-cx)**2)<(eh*0.42)**2)*0.9,r=5)
ang=np.deg2rad(-14); Yr=(Y-cy)*np.cos(ang)-(X-cx)*np.sin(ang)
ex['colpito']=soft(sock&(np.abs(Yr+eh*0.05)<eh*0.11))
ex['poca_vita']=soft(sock&(Y>cy-eh*0.05))*0.8
v=soft(nd.binary_dilation(sock,iterations=3))
ex['vittoria']=hi(np.clip(np.maximum(v,nd.gaussian_filter(v,9)*0.8),0,1))
for k,a in ex.items():
    Image.fromarray(np.dstack([np.full((h,w,3),255),a[...,None]*255]).astype(np.uint8),'RGBA').save(f'raw_occhio_{k}.png')
import json; json.dump({'offset_in_corpo':[int(x0),int(y0)]},open('eye_off.json','w')); print(x0,y0,w,h)
