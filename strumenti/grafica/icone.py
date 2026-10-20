# Ritaglia il foglio icone (griglia su sfondo magenta) in PNG quadrati 256 con alfa.
import numpy as np, os, sys
from PIL import Image
from scipy import ndimage as nd
src,cols,rows=sys.argv[1],5,4
OUT='/mnt/project-files/grafica/ui/icone'; os.makedirs(OUT,exist_ok=True)
names=['forgia','inventario','shop','classifica','impostazioni','posta','notifiche','indietro','piu','gemma',
'moneta','gioca','lucchetto','conferma','annulla','armatura','armi','missioni','tempo_turno','sconfitta']
a=np.asarray(Image.open(src).convert('RGB')).astype(float); H,W=a.shape[:2]
M=np.array([250,3,250.])
mag=np.minimum(a[...,0],a[...,2])-a[...,1]
alpha=np.clip((235-mag)/140,0,1)
prev=Image.new('RGBA',(cols*140,rows*140),(24,25,34,255))
# ogni pezzo staccato va all'icona della cella in cui cade il suo baricentro
m=alpha>0.5; lab,n=nd.label(m); sz=nd.sum(m,lab,range(1,n+1)); cm=nd.center_of_mass(m,lab,range(1,n+1))
cellof=np.zeros(n+1,int)-1
for i,(cy,cx) in enumerate(cm,1):
    if sz[i-1]>=40: cellof[i]=min(rows-1,int(cy*rows/H))*cols+min(cols-1,int(cx*cols/W))
owner=cellof[lab]
for k,name in enumerate(names):
    r,c=divmod(k,cols)
    sel=nd.binary_dilation(owner==k,iterations=3)
    ys,xs=np.where(sel); y0,y1,x0,x1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
    al=alpha[y0:y1,x0:x1]*sel[y0:y1,x0:x1]; p=a[y0:y1,x0:x1]
    col=np.clip((p-(1-al[...,None])*M)/np.maximum(al[...,None],1e-3),0,255)
    edge=nd.binary_dilation(al<0.98,iterations=3)
    for ch in (0,2): col[...,ch]=np.where(edge,np.minimum(col[...,ch],col[...,1]+22),col[...,ch])
    col[al<0.02]=0
    ys,xs=np.where(al>0.02); bb=(ys.min(),ys.max()+1,xs.min(),xs.max()+1)
    img=Image.fromarray(np.dstack([col,al*255]).astype(np.uint8)[bb[0]:bb[1],bb[2]:bb[3]],'RGBA')
    s=max(img.size); sq=Image.new('RGBA',(int(s*1.08),)*2,(0,0,0,0)); sq.paste(img,((sq.size[0]-img.size[0])//2,(sq.size[1]-img.size[1])//2))
    sq=sq.resize((256,256),Image.LANCZOS); sq.save(f'{OUT}/icona_{name}.png',optimize=True)
    prev.alpha_composite(sq.resize((128,128),Image.LANCZOS),(c*140+6,r*140+6))
prev.save(f'{OUT}/anteprima_icone.png')
