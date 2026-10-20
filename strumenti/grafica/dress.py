import sys, json, numpy as np
sys.path.insert(0,'..')
from PIL import Image, ImageFilter
import assemble as A
from tiers import tier
# armor fit: name -> (scale, origin in corpo coords at sheet scale)
F=json.load(open('fit.json'))
def build(team,t,setcolor):
    W,H=1400,1500; ox,oy=400,350
    can=Image.new('RGBA',(W,H),(0,0,0,0))
    def part(n):
        im=Image.open(f'../raw_{n}.png'); (px,py),(ax,ay)=A.P[n]; can.alpha_composite(im,(ox+ax-px,oy+ay-py))
    def arm(n):
        s,(x,y)=F[n]; im=tier(n,t,setcolor); im=im.resize((round(im.width*s),round(im.height*s)),Image.LANCZOS)
        pad=(Image.open(f'raw_{n}.png').width*s-im.width)/2 if False else 0
        if t==3:  # tier() adds no padding; aura is inside bounds
            pass
        can.alpha_composite(im,(ox+round(x),oy+round(y)))
    arm('mantello'); part('braccio_dietro'); part('gamba_dietro'); arm('gambale_dietro')
    can.alpha_composite(Image.open('../raw_corpo.png'),(ox,oy))
    glow=Image.new('RGBA',(W,H),(0,0,0,0)); glow.alpha_composite(Image.open('../raw_nucleo_luce.png'),(ox,oy))
    s_,(mx_,my_)=F['maschera']; mo=Image.open('raw_maschera_occhio.png'); mo=mo.resize((round(mo.width*s_),round(mo.height*s_)),Image.LANCZOS)
    g=np.asarray(glow).astype(float)[...,3:]/255; bl=np.asarray(glow.filter(ImageFilter.GaussianBlur(10))).astype(float)[...,3:]/255
    b=np.asarray(can).astype(float); c=np.array(team,float)
    rgb=b[...,:3]+(g*c+bl*c*0.6)*b[...,3:]/255+g*60
    can=Image.fromarray(np.dstack([np.clip(rgb,0,255),b[...,3:]]).astype(np.uint8),'RGBA')
    arm('corazza'); arm('maschera')
    eg=Image.new('RGBA',(W,H),(0,0,0,0)); eg.alpha_composite(mo,(ox+round(mx_),oy+round(my_)))
    g2=np.asarray(eg).astype(float)[...,3:]/255; b2=np.asarray(eg.filter(ImageFilter.GaussianBlur(8))).astype(float)[...,3:]/255
    bb=np.asarray(can).astype(float); rgb2=bb[...,:3]+(g2*c*0.9+b2*c*0.5)+g2*50
    can=Image.fromarray(np.dstack([np.clip(rgb2,0,255),np.maximum(bb[...,3:],b2*255*0.3)]).astype(np.uint8),'RGBA'); part('gamba_davanti'); arm('gambale_davanti'); part('braccio_davanti')
    return can.crop(can.getbbox())
if __name__=='__main__':
    ims=[build((255,59,78),t,(110,140,255)) for t in (1,2,3)]
    h=max(i.height for i in ims); sh=Image.new('RGBA',(sum(i.width for i in ims)+60*4,h+60),(18,19,26,255)); x=60
    for i in ims: sh.alpha_composite(i,(x,30)); x+=i.width+60
    sh.save('dressed.png'); print(sh.size)
