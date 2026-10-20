import numpy as np
from PIL import Image, ImageFilter
def tier(name,t,color=(110,140,255)):
    base=Image.open(f'raw_{name}.png').copy()
    if t>=2: base.alpha_composite(Image.open(f'raw_{name}_finiture.png'))
    if t>=3:
        g=Image.open(f'raw_{name}_luce.png'); ga=np.asarray(g).astype(float)[...,3:]/255
        bl=np.asarray(g.filter(ImageFilter.GaussianBlur(6))).astype(float)[...,3:]/255
        b=np.asarray(base).astype(float); c=np.array(color,float)
        rgb=b[...,:3]+(ga*c*0.9+bl*c*0.5)*(b[...,3:]/255)
        rgb=rgb*(1-ga*0.5)+ga*0.5*c*1.2
        base=Image.fromarray(np.dstack([np.clip(rgb,0,255),b[...,3:]]).astype(np.uint8),'RGBA')
        aura=np.asarray(base.filter(ImageFilter.GaussianBlur(14))).astype(float)[...,3:]/255
        halo=Image.fromarray(np.dstack([np.broadcast_to(c,aura.shape[:2]+(3,)),aura*110]).astype(np.uint8),'RGBA')
        halo.alpha_composite(base); base=halo
    return base
if __name__=='__main__':
    names=['maschera','corazza','mantello','gambale_davanti']
    rows=[]
    for t in (1,2,3):
        ims=[tier(n,t) for n in names]; rows.append(ims)
    W=sum(i.width for i in rows[0])+40*5; H=sum(max(i.height for i in r) for r in rows)+40*4
    can=Image.new('RGBA',(W,H),(18,19,26,255)); y=40
    for r in rows:
        x=40
        for i in r: can.alpha_composite(i,(x,y)); x+=i.width+40
        y+=max(i.height for i in r)+40
    can=can.resize((W//2,H//2)); can.save('tiers.png')
