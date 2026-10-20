import numpy as np, shutil, os
from PIL import Image, ImageFilter
from scipy import ndimage as nd
OUT='/mnt/project-files/grafica/mappe/mappa_isole_cimitero'; os.makedirs(OUT,exist_ok=True)
art=np.asarray(Image.open('/mnt/project-files/grafica/concept/mappa_isole_cimitero_v1.png').convert('RGB').resize((2560,1440),Image.LANCZOS)).astype(float)
cell=np.load('cell.npy')
up=lambda m: np.kron(m,np.ones((4,4),bool)).astype(bool)
dig=up(cell==1); hard=up(cell==2); solid=dig|hard
mx=art.max(2)
artA=np.clip((mx-14)/30,0,1)                 # alpha from black background
def soft(m,px): return np.clip(nd.distance_transform_edt(~m)<=px,0,1).astype(float)
def save(rgb,a,name):
    o=np.dstack([rgb,np.clip(a,0,1)*255]).astype(np.uint8); Image.fromarray(o,'RGBA').save(f'{OUT}/{name}',optimize=True)
# superficie: art 8px beyond the white mask edge, transparent elsewhere; ossa: art on red cells
sup_a=artA*soft(dig,8)*(~hard | ~nd.binary_erosion(hard,iterations=2))
save(art,sup_a,'superficie.png')
ossa_a=artA*soft(hard,3)
save(art,ossa_a,'ossa.png')
# interno: darker, blurred, desaturated rock seen inside craters, filled everywhere solid
blur=np.asarray(Image.fromarray(art.astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))).astype(float)
g=blur.mean(2,keepdims=True); intr=(0.55*g+0.45*blur)*0.62+18
intr=intr*np.array([1.0,0.92,1.08])           # cool charcoal tint
save(np.clip(intr,0,255),soft(solid,8),'interno.png')
# maschera 640x360 pure colours
m=np.zeros((360,640,3),np.uint8); m[cell==1]=255; m[cell==2]=(255,0,0)
Image.fromarray(m).save(f'{OUT}/maschera.png')
# sfondo_lontano from Sergio's mist image
bg=Image.open('/root/.claude/uploads/4897a37b-c06a-572c-833d-7abcb0dc1f2e/136c5d17-image.png').convert('RGB')
shutil.copy('/root/.claude/uploads/4897a37b-c06a-572c-833d-7abcb0dc1f2e/136c5d17-image.png','/mnt/project-files/grafica/concept/sfondo_cimitero_nebbia_v1.png')
bgw=bg.resize((2560,1440),Image.LANCZOS); bgw.save(f'{OUT}/sfondo_lontano.png',optimize=True)
open(f'{OUT}/colori.txt','w').write('brace #FF7A1A\nbrace_chiara #FFC46B\ninterno #1B1A21\nnebbia #6E6880\n')
# composite preview
comp=bgw.convert('RGBA')
for n in ['interno.png','superficie.png','ossa.png']:
    if n=='interno.png': continue
    comp=Image.alpha_composite(comp,Image.open(f'{OUT}/{n}'))
comp.convert('RGB').resize((400,225),Image.LANCZOS).save(f'{OUT}/anteprima.png')
comp.convert('RGB').resize((1280,720),Image.LANCZOS).save('composito.png')
# crater demo: carve a few round holes, show interno + ember rim
demo=bgw.convert('RGBA'); 
yy,xx=np.mgrid[0:1440,0:2560]; holes=np.zeros((1440,2560),bool)
for cx,cy,r in [(640,1180,110),(1280,880,90),(1900,1160,120),(1280,250,70)]:
    holes|=(xx-cx)**2+(yy-cy)**2<r*r
holes&=~hard
I=np.asarray(Image.open(f'{OUT}/interno.png')).astype(float); S=np.asarray(Image.open(f'{OUT}/superficie.png')).astype(float); O=np.asarray(Image.open(f'{OUT}/ossa.png'))
d=nd.distance_transform_edt(holes)                       # distance inside hole
rim=(holes)&(d<10)&solid
S2=S.copy(); S2[holes,3]=0
I2=I.copy(); I2[~(holes&solid&(d<22)),3]=0
demo=Image.alpha_composite(demo,Image.fromarray(I2.astype(np.uint8)))
demo=Image.alpha_composite(demo,Image.fromarray(S2.astype(np.uint8)))
E=np.zeros((1440,2560,4)); E[...,:3]=(255,122,26); E[...,3]=np.where(rim,np.clip(1-d/10,0,1)*230,0)
demo=Image.alpha_composite(demo,Image.fromarray(E.astype(np.uint8)))
demo=Image.alpha_composite(demo,Image.fromarray(O))
demo.convert('RGB').resize((1280,720),Image.LANCZOS).save(f'{OUT}/anteprima_crateri.png')
ov=Image.blend(comp.convert('RGB'),Image.fromarray(np.kron(m,np.ones((4,4,1),np.uint8))),0.4)
ov.resize((1280,720),Image.LANCZOS).save(f'{OUT}/anteprima_collisione.png')
print(os.listdir(OUT))
