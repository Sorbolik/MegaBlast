import numpy as np, json, sys
from PIL import Image, ImageFilter
# pivots in local part coords; anchors in corpo coords (sheet scale)
P={'corna_davanti':((250,150),(330,108)),'corna_dietro':((120,165),(212,66)),
   'braccio_davanti':((60,40),(115,365)),'braccio_dietro':((50,45),(420,330)),
   'gamba_davanti':((110,60),(215,690)),'gamba_dietro':((80,55),(395,690))}
order_back=['braccio_dietro','gamba_dietro','corna_dietro']; order_front=['gamba_davanti','corna_davanti','braccio_davanti']
eo=json.load(open('eye_off.json'))['offset_in_corpo']
def build(color,eye='neutro',scale=1.0):
    W,H=1000,1200; ox,oy=200,250   # corpo origin on canvas
    can=Image.new('RGBA',(W,H),(0,0,0,0))
    def put(n):
        im=Image.open(f'raw_{n}.png'); (px,py),(ax,ay)=P[n]; can.alpha_composite(im,(ox+ax-px,oy+ay-py))
    for n in order_back: put(n)
    can.alpha_composite(Image.open('raw_corpo.png'),(ox,oy))
    glow=Image.new('RGBA',(W,H),(0,0,0,0))
    glow.alpha_composite(Image.open('raw_nucleo_luce.png'),(ox,oy))
    glow.alpha_composite(Image.open(f'raw_occhio_{eye}.png'),(ox+eo[0],oy+eo[1]))
    g=np.asarray(glow).astype(float)[...,3:]/255
    bloom=np.asarray(glow.filter(ImageFilter.GaussianBlur(10))).astype(float)[...,3:]/255
    base=np.asarray(can).astype(float)
    c=np.array(color,float)
    rgb=base[...,:3]+ (g*c + bloom*c*0.6)*base[...,3:]/255 + g*60
    out=np.dstack([np.clip(rgb,0,255),base[...,3:]]).astype(np.uint8)
    can=Image.fromarray(out,'RGBA')
    for n in order_front: put_im=None
    for n in order_front:
        im=Image.open(f'raw_{n}.png'); (px,py),(ax,ay)=P[n]; can.alpha_composite(im,(ox+ax-px,oy+ay-py))
    bb=can.getbbox(); return can.crop(bb)
if __name__=='__main__':
    cols={'cremisi':(255,59,78),'giada':(46,230,166),'ambra':(255,176,32),'cobalto':(61,123,255)}
    ims=[build(c) for c in cols.values()]
    h=max(i.height for i in ims); sh=Image.new('RGBA',(sum(i.width for i in ims)+60*5,h+60),(18,19,26,255)); x=60
    for i in ims: sh.alpha_composite(i,(x,30)); x+=i.width+60
    sh.save('preview_team.png'); print(ims[0].size)
