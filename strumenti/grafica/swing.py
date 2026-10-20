import sys, json, math, numpy as np
sys.path.insert(0,'..')
from PIL import Image, ImageFilter, ImageDraw
import assemble as A
K=1/5.5; team=np.array((255,59,78),float)
def sc(im): return im.resize((max(1,round(im.width*K)),max(1,round(im.height*K))),Image.LANCZOS)
parts={n:sc(Image.open(f'../raw_{n}.png')) for n in A.P}
corpo=sc(Image.open('../raw_corpo.png')); nucleo=sc(Image.open('../raw_nucleo_luce.png'))
eo=json.load(open('../eye_off.json'))['offset_in_corpo']; occhio=sc(Image.open('../raw_occhio_mira.png'))
px,py,sw,sh=map(int,open('pivot.txt').read().split())
SL=1.5*1049/sw   # sword scale relative to sheet
sword=Image.open('raw_spadone.png'); sl=Image.open('raw_spadone_luce.png')
def tint(b,l):
    ga=np.asarray(l).astype(float)[...,3:]/255; bl=np.asarray(l.filter(ImageFilter.GaussianBlur(3))).astype(float)[...,3:]/255
    bb=np.asarray(b).astype(float); rgb=bb[...,:3]*(1-ga)+(ga*(team*0.9+90)) ; Aa=np.maximum(bb[...,3:],np.maximum(ga,bl*0.6)*255)
    rgb=rgb+bl*team*0.4
    return Image.fromarray(np.dstack([np.clip(rgb,0,255),Aa]).astype(np.uint8),'RGBA')
swordT=tint(sword,sl); swordT=swordT.resize((round(sw*SL*K),round(sh*SL*K)),Image.LANCZOS); spx,spy=px*SL*K,py*SL*K
Wc,Hc=900,700; ox,oy=370,330   # corpo origin
def glowed(base):
    g=Image.new('RGBA',base.size); g.alpha_composite(nucleo,(ox,oy)); g.alpha_composite(occhio,(ox+round(eo[0]*K),oy+round(eo[1]*K)))
    ga=np.asarray(g).astype(float)[...,3:]/255; b=np.asarray(base).astype(float)
    rgb=b[...,:3]+ga*team*b[...,3:]/255+ga*50; return Image.fromarray(np.dstack([np.clip(rgb,0,255),b[...,3:]]).astype(np.uint8),'RGBA')
sh_=A.P['braccio_davanti'][1]; SX,SY=ox+sh_[0]*K,oy+sh_[1]*K    # shoulder
REACH=430*K; ARM0=-56
def frame(theta,trail):
    can=Image.new('RGBA',(Wc,Hc),(18,19,26,255))
    for n in ['braccio_dietro','gamba_dietro','corna_dietro']:
        (ppx,ppy),(ax,ay)=A.P[n]; can.alpha_composite(parts[n],(round(ox+(ax-ppx)*K),round(oy+(ay-ppy)*K)))
    can.alpha_composite(corpo,(ox,oy)); can=glowed(can)
    for n in ['gamba_davanti','corna_davanti']:
        (ppx,ppy),(ax,ay)=A.P[n]; can.alpha_composite(parts[n],(round(ox+(ax-ppx)*K),round(oy+(ay-ppy)*K)))
    # trail arc
    if trail:
        t=Image.new('RGBA',(Wc,Hc)); d=ImageDraw.Draw(t)
        r=REACH+ (sw-px)*SL*K*0.95
        for i in range(len(trail)-1):
            a0,a1=trail[i],trail[i+1]; w=int(10+26*i/len(trail)); al=int(30+150*i/len(trail))
            pts=[(SX+r*math.cos(math.radians(a)),SY-r*math.sin(math.radians(a))) for a in np.linspace(a0,a1,6)]
            d.line(pts,fill=(int(team[0]),int(team[1]+60),int(team[2]+60),al),width=w)
        t=t.filter(ImageFilter.GaussianBlur(2)); can.alpha_composite(t)
    # arm rotated around shoulder
    arm=parts['braccio_davanti']; (apx,apy),_=A.P['braccio_davanti']
    layer=Image.new('RGBA',(Wc,Hc)); layer.alpha_composite(arm,(round(SX-apx*K),round(SY-apy*K)))
    layer=layer.rotate(theta-ARM0,center=(SX,SY),resample=Image.BICUBIC)
    # sword at hand
    hx,hy=SX+REACH*math.cos(math.radians(theta)),SY-REACH*math.sin(math.radians(theta))
    sl_=Image.new('RGBA',(Wc,Hc)); sl_.alpha_composite(swordT,(round(hx-spx),round(hy-spy)))
    sl_=sl_.rotate(theta,center=(hx,hy),resample=Image.BICUBIC)
    behind = 100<theta<260
    if behind: can.alpha_composite(sl_); can.alpha_composite(layer)
    else: can.alpha_composite(layer); can.alpha_composite(sl_)
    return can.convert('RGB')
angs=[]
angs+= [ -60+ (205+60)*e for e in np.linspace(0,1,6)**0.7 ]       # wind-up to behind the back
angs+= [205]*3
sweep=[205-240*(0.5-0.5*math.cos(math.pi*t)) for t in np.linspace(0,1,9)]
angs+=sweep+[-35]*4+[ -35+(-60+35)*t for t in np.linspace(0,1,4)]
frames=[]; hist=[]
for a in angs:
    if a in sweep: hist.append(a)
    tr=hist[-6:] if len(hist)>1 and a in sweep else []
    frames.append(frame(a,tr))
frames[0].save('/mnt/project-files/grafica/armi/anteprima_fendente.gif',save_all=True,append_images=frames[1:],duration=[70]*len(frames),loop=0)
strip=Image.new("RGB",(Wc*4//2,Hc//2))
for i,f in enumerate([frames[k] for k in (8,11,13,16)]): strip.paste(f.resize((Wc//2,Hc//2)),((i%4)*Wc//2,0))
strip.save('strip.png'); print(len(frames))
