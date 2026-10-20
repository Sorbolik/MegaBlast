import numpy as np
from PIL import Image, ImageFilter
names=['lanciarune','uovo_di_fiamma','sciame_di_schegge','pugno_del_titano','passo_ombra']
def tinted(n,c):
    b=Image.open(f'raw_{n}.png'); g=Image.open(f'raw_{n}_luce.png')
    ga=np.asarray(g).astype(float)[...,3:]/255; bl=np.asarray(g.filter(ImageFilter.GaussianBlur(6))).astype(float)[...,3:]/255
    bb=np.asarray(b).astype(float); c=np.array(c,float)
    rgb=bb[...,:3]+ga*c+bl*c*0.5+ga*50; A=np.maximum(bb[...,3:],bl*255*0.5)
    return Image.fromarray(np.dstack([np.clip(rgb,0,255),A]).astype(np.uint8),'RGBA')
rows=[[tinted(n,c) for n in names] for c in [(255,59,78),(61,123,255)]]
W=sum(i.width for i in rows[0])+30*6; H=max(i.height for r in rows for i in r)*2+90
can=Image.new('RGBA',(W,H),(18,19,26,255)); y=30
for r in rows:
    x=30
    for i in r: can.alpha_composite(i,(x,y)); x+=i.width+30
    y+=max(i.height for i in r)+30
can.convert('RGB').resize((W//2,H//2)).save('prev.png')
