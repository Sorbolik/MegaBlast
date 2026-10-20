import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd
a=np.asarray(Image.open('/mnt/project-files/grafica/concept/esplosione_v1.png').convert('RGB')).astype(float)
H,W,_=a.shape; print(a.shape)
r,g,b=a[...,0],a[...,1],a[...,2]; mx=a.max(2); mn=a.min(2); sat=(mx-mn)/np.maximum(mx,1)
# fire: warm & bright
fire=np.clip((r-b-50)/90,0,1)*np.clip((mx-90)/80,0,1)
fire=nd.gaussian_filter(fire,1.0)
fire_rgb=a*fire[...,None]                      # additive layer on black
# smoke+debris: alpha-blended, from non-black, minus fire
A=np.clip((mx-8)/38,0,1)*(1-fire*0.95)
col=np.clip(a/np.maximum(np.clip((mx-8)/38,0.05,1)[...,None],1e-3),0,255)
col=np.minimum(col,a*4+5)
S=Image.fromarray(np.dstack([col,A*255]).astype(np.uint8),'RGBA')
F=Image.fromarray(fire_rgb.astype(np.uint8),'RGB')
S.save('fumo_schegge.png'); F.save('fuoco_add.png')
# flipbook 12 frames 256
N=12; C=256
def ease(t): return 1-(1-t)**3
frames=[]
for i in range(N):
    t=i/(N-1)
    can=np.zeros((C,C,3)); alpha=np.zeros((C,C))
    # smoke layer: grows 0.55->1.05, alpha fades in quick then out late
    s_scale=0.55+0.5*ease(t); s_a=min(1,t*4)*(1-max(0,(t-0.55)/0.45))**1.3
    f_scale=0.25+0.85*ease(min(1,t*1.6)); f_a=(1-t)**1.6 if i>0 else 1
    def place(img,scale,rot):
        sz=max(2,int(C*scale)); im=img.rotate(rot,resample=Image.BICUBIC).resize((sz,sz),Image.LANCZOS)
        out=Image.new(img.mode,(C,C),(0,0,0,0) if img.mode=='RGBA' else (0,0,0))
        out.paste(im,((C-sz)//2,(C-sz)//2)); return np.asarray(out).astype(float)
    sm=place(S,s_scale,t*12); sa=sm[...,3:]/255*s_a
    darken=1-0.5*t
    smc=sm[...,:3]; gr=smc.mean(2,keepdims=True)*np.array([0.85,0.8,0.95]); k=min(1,t*1.3)
    smc=smc*(1-k)+gr*k
    can=smc*darken*sa; alpha=sa[...,0]
    fi=np.clip(place(F,f_scale,-t*8)*f_a*1.35,0,255)
    if i==0:  # white flash
        yy,xx=np.mgrid[0:C,0:C]; d=np.hypot(yy-C/2,xx-C/2); fl=np.clip(1-d/(C*0.22),0,1)**1.5
        fi=fi+fl[...,None]*255
    # premultiplied composite -> straight RGBA (fire added, makes alpha)
    rgb=can+fi; fa=np.clip(fi.max(2)/255,0,1)
    A2=np.clip(alpha+fa*(1-alpha),0,1)
    rgbS=np.clip(rgb/np.maximum(A2[...,None],1e-3),0,255)
    frames.append(np.dstack([rgbS,A2*255]).astype(np.uint8))
sheet=np.zeros((3*C,4*C,4),np.uint8)
for i,f in enumerate(frames): sheet[(i//4)*C:(i//4+1)*C,(i%4)*C:(i%4+1)*C]=f
Image.fromarray(sheet,'RGBA').save('/mnt/project-files/grafica/esplosioni/esplosione_base_12x256.png',optimize=True)
# separate layers for code-driven version
S.resize((512,512),Image.LANCZOS).save('/mnt/project-files/grafica/esplosioni/esplosione_fumo_schegge.png')
F.resize((512,512),Image.LANCZOS).save('/mnt/project-files/grafica/esplosioni/esplosione_fuoco_additivo.png')
# GIF preview over a dark scene
gif=[]
for f in frames+[frames[-1]]*2:
    bgc=Image.new('RGBA',(C,C),(18,19,26,255)); bgc.alpha_composite(Image.fromarray(f,'RGBA')); gif.append(bgc.convert('RGB').resize((384,384)))
gif[0].save('/mnt/project-files/grafica/esplosioni/anteprima_esplosione.gif',save_all=True,append_images=gif[1:],duration=50,loop=0)
strip=Image.new('RGB',(C*6,C*2),(18,19,26))
for i,f in enumerate(frames): strip.paste(Image.fromarray(f,'RGBA'),((i%6)*C,(i//6)*C),Image.fromarray(f,'RGBA'))
strip.save('strip.png')
