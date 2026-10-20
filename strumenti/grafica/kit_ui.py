# Ritaglia il foglio del kit UI su sfondo magenta in pezzi PNG con alfa + bordi 9-slice.
import numpy as np, json, os, sys
from PIL import Image
from scipy import ndimage as nd
src=sys.argv[1] if len(sys.argv)>1 else 'src.png'
OUT=sys.argv[2] if len(sys.argv)>2 else '/mnt/project-files/grafica/ui/kit'; os.makedirs(OUT,exist_ok=True)
a=np.asarray(Image.open(src).convert('RGB')).astype(float)
M=np.array([250,3,250.])
mag=np.minimum(a[...,0],a[...,2])-a[...,1]
alpha=np.clip((235-mag)/140,0,1)
fg=nd.binary_opening(mag<120,iterations=1)
l,n=nd.label(fg); sl=nd.find_objects(l)
names={1:'bottone_principale',2:'bottone_principale_premuto',3:'bottone_principale_disattivato',
4:'bottone_secondario',5:'bottone_secondario_premuto',6:'barra_valuta',7:'carta_selezionata',8:'carta',
9:'slot',10:'slot_bloccato',11:'pannello',12:'barra_progresso',13:'barra_progresso_pieno',14:'badge_livello',
15:'schede_prima_attiva',16:'bottone_indietro',17:'schede',18:'notifica',19:'divisore'}
if len(sys.argv)>3: names={int(k):v for k,v in json.loads(sys.argv[3]).items()}
info={}
for i,s in enumerate(sl,1):
    if i not in names: continue
    y0,y1,x0,x1=max(0,s[0].start-4),s[0].stop+4,max(0,s[1].start-4),s[1].stop+4
    reg=(nd.binary_dilation(l==i,iterations=4))[y0:y1,x0:x1]
    al=alpha[y0:y1,x0:x1]*reg
    p=a[y0:y1,x0:x1]
    c=(p-(1-al[...,None])*M)/np.maximum(al[...,None],1e-3)
    c=np.clip(c,0,255)
    edge=nd.binary_dilation(al<0.98,iterations=3)          # bordo: togli l'alone magenta
    for k in (0,2): c[...,k]=np.where(edge,np.minimum(c[...,k],c[...,1]+22),c[...,k])
    c[al<0.02]=0
    img=np.dstack([c,al*255]).astype(np.uint8)
    Image.fromarray(img,'RGBA').save(f'{OUT}/{names[i]}.png',optimize=True)
    h,w=img.shape[:2]; b=int(min(h,w)*0.28)
    info[names[i]]={'w':w,'h':h,'bordo_9slice':[b,b,b,b]}
json.dump(info,open(f'{OUT}/kit_ui.json','w'),indent=1)
# anteprima su sfondo scuro
W=1843;H=853; prev=Image.new('RGBA',(W,H),(24,25,34,255)); 
for i,s in enumerate(sl,1):
    if i in names: prev.alpha_composite(Image.open(f'{OUT}/{names[i]}.png'),(max(0,s[1].start-4),max(0,s[0].start-4)))
prev.convert('RGB').save(f'{OUT}/anteprima_kit.png')
print(len(info))
