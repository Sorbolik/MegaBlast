# Ritaglia il logo su magenta: logo.png (colore + alfa) e logo_luce.png (bagliore bianco da tingere/pulsare).
import numpy as np, os
from PIL import Image
from scipy import ndimage as nd
OUT='/mnt/project-files/grafica/ui'
a=np.asarray(Image.open('logo_src.png').convert('RGB')).astype(float)
M=np.array([250,3,250.])
mag=np.minimum(a[...,0],a[...,2])-a[...,1]
al=np.clip((235-mag)/140,0,1)
m=al>0.5; lab,n=nd.label(m); sz=nd.sum(m,lab,range(1,n+1)); keep=np.isin(lab,1+np.where(sz>=40)[0])
al*=nd.binary_dilation(keep,iterations=3)
c=np.clip((a-(1-al[...,None])*M)/np.maximum(al[...,None],1e-3),0,255)
edge=nd.binary_dilation(al<0.98,iterations=3)
for k in (0,2): c[...,k]=np.where(edge,np.minimum(c[...,k],c[...,1]+22),c[...,k])
c[al<0.02]=0
ys,xs=np.where(al>0.02); y0,y1,x0,x1=max(0,ys.min()-8),ys.max()+9,max(0,xs.min()-8),xs.max()+9
img=np.dstack([c,al*255]).astype(np.uint8)[y0:y1,x0:x1]
Image.fromarray(img,'RGBA').save(f'{OUT}/logo.png',optimize=True)
# luce: parti emissive (lama bianca, crepe arancio, gemme)
cc=c[y0:y1,x0:x1]; aa=al[y0:y1,x0:x1]
mx=cc.max(2); mn=cc.min(2); sat=(mx-mn)/np.maximum(mx,1)
glow=np.clip((mx-170)/70,0,1)*np.clip(((cc[...,0]-cc[...,2])>60)|(mn>200),0,1)
glow=nd.gaussian_filter(glow,1.0)*aa
L=np.dstack([np.full(glow.shape+(3,),255.),glow*255]).astype(np.uint8)
Image.fromarray(L,'RGBA').save(f'{OUT}/logo_luce.png',optimize=True)
bg=Image.open('/mnt/project-files/grafica/ui/sfondi/caricamento.png').convert('RGBA')
lg=Image.fromarray(img,'RGBA'); s=bg.size[0]*0.62/lg.size[0]; lg=lg.resize((int(lg.size[0]*s),int(lg.size[1]*s)),Image.LANCZOS)
bg.alpha_composite(lg,((bg.size[0]-lg.size[0])//2,int(bg.size[1]*0.12)))
bg.convert('RGB').resize((1280,int(1280*bg.size[1]/bg.size[0]))).save(f'{OUT}/anteprima_caricamento.png')
print(img.shape)
