import numpy as np
from PIL import Image
from scipy import ndimage as nd
m=np.asarray(Image.open('raw_maschera.png')).astype(float)
eye=np.asarray(Image.open('raw_maschera_occhio.png')).astype(float)[...,3]/255
A=m[...,3]/255
hole=nd.binary_dilation(eye>0.05,iterations=7)&(A<0.98)
hole=nd.binary_fill_holes(nd.binary_closing(hole,iterations=3))
ys,xs=np.where(hole); cy,cx=ys.mean(),xs.mean(); h=np.ptp(ys); w=np.ptp(xs); print('hole',hole.sum(),w,h)
Y,X=np.mgrid[0:A.shape[0],0:A.shape[1]]
shade=np.clip(1-(((Y-(cy-h*0.35))/h)**2+((X-(cx-w*0.25))/w)**2)*0.9,0,1)
base=np.array([20,16,28.]); hi=np.array([70,58,88.])
col=base+(hi-base)*shade[...,None]
fill=np.clip(nd.gaussian_filter(nd.binary_dilation(hole,iterations=1).astype(float),1.0)*1.3,0,1)
rgb=m[...,:3]*(1-fill[...,None])+col*fill[...,None]
newA=np.maximum(A,fill)
slit=(np.abs(X-cx)<max(3,w*0.06))&(np.abs(Y-cy)<h*0.40)
g=nd.gaussian_filter(slit.astype(float),2.0); rgb*=(1-0.6*g[...,None])
Image.fromarray(np.dstack([rgb,newA*255]).astype(np.uint8),'RGBA').save('raw_maschera.png')
sa=np.clip(nd.gaussian_filter(slit.astype(float),1.2)*1.4,0,1)
Image.fromarray(np.dstack([np.full(A.shape+(3,),255),sa[...,None]*255]).astype(np.uint8),'RGBA').save('raw_maschera_occhio.png')
