import numpy as np, json, sys
from PIL import Image
from scipy import ndimage as nd
SRC=sys.argv[1]; NAMES=json.loads(sys.argv[2]); HOLES=json.loads(sys.argv[3]); GLOW=sys.argv[4]
a=np.asarray(Image.open(SRC).convert('RGB')).astype(float)
bg=np.load('bg.npy'); dist=np.load('dist.npy'); lab=np.load('lab.npy')
mx=a.max(2); mn=a.min(2); sat=(mx-mn)/np.maximum(mx,1); lum=a.mean(2)
r,g,b=a[...,0],a[...,1],a[...,2]
brass=(r>g)&(g>b)&(sat>0.5)&(mx>60)
brass=nd.binary_opening(brass,iterations=1)
l,n=nd.label(brass); sz=nd.sum(brass,l,range(1,n+1))
for k,v in enumerate(sz,1):
    if v<120: brass[l==k]=False
brass_s=np.clip(nd.gaussian_filter(brass.astype(float),0.8)*1.3,0,1)
# tier I: brass -> dark iron (keep shading)
iron=np.stack([lum*0.55+8,lum*0.53+8,lum*0.6+12],2)
t1=a*(1-brass_s[...,None])+iron*brass_s[...,None]
# glow (tier III): bright, low-saturation, non-brass material edges
L=nd.gaussian_filter(lum,1)
edge=np.clip((L-nd.grey_opening(L,size=(11,11))-10)/25,0,1)
bright=np.clip((lum-120)/90,0,1)*(sat<0.45)
glow=np.clip(np.maximum(edge*0.6,bright*0.2)*(1-brass_s),0,1)
info={}
for sid,name in NAMES.items():
    i=int(sid); comp=lab==i
    alpha=np.clip((dist-6)/16,0,1)*nd.binary_dilation(comp,iterations=3)
    alpha[nd.binary_erosion(nd.binary_fill_holes(comp),iterations=2)]=1
    for (y0,y1,x0,x1) in HOLES.get(name,[]):
        hole=np.zeros_like(comp); hole[y0:y1,x0:x1]=True; hole&=(lum<24)&comp
        hole=nd.binary_closing(hole,iterations=4); hole=nd.binary_fill_holes(hole)
        l_,n_=nd.label(hole)
        if n_>1:
            sz_=nd.sum(hole,l_,range(1,n_+1)); hole=l_==(np.argmax(sz_)+1)
        hole=nd.binary_opening(hole,iterations=3)
        hs=nd.gaussian_filter(nd.binary_dilation(hole,iterations=2).astype(float),1.2)
        alpha=alpha*(1-np.clip(hs*1.5,0,1))
        holes_all=holes_all|hole if 'holes_all' in dir() else hole
    ys,xs=np.where(alpha>0.02); Y0,Y1,X0,X1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
    A=alpha[Y0:Y1,X0:X1]; B=bg[Y0:Y1,X0:X1]
    def rgba(C,AA):
        col=np.clip((C-(1-AA[...,None])*B)/np.maximum(AA[...,None],1e-3),0,255); col[AA<0.02]=0
        return Image.fromarray(np.dstack([col,AA*255]).astype(np.uint8),'RGBA')
    rgba(t1[Y0:Y1,X0:X1],A).save(f'raw_{name}.png')
    fA=A*brass_s[Y0:Y1,X0:X1]
    col=np.clip((a[Y0:Y1,X0:X1]-(1-A[...,None])*B)/np.maximum(A[...,None],1e-3),0,255)
    Image.fromarray(np.dstack([col,fA*255]).astype(np.uint8),'RGBA').save(f'raw_{name}_finiture.png')
    solid=nd.binary_fill_holes(A>0.5); inner=nd.binary_erosion(solid,iterations=7)
    rim=np.clip(nd.gaussian_filter((solid&~inner).astype(float),2)*1.6,0,1)
    if name=='corazza': rim[:int(rim.shape[0]*0.3)]=0
    gA=np.clip(A*np.maximum(glow[Y0:Y1,X0:X1],rim*(1-brass_s[Y0:Y1,X0:X1])),0,1)
    Image.fromarray(np.dstack([np.full(A.shape+(3,),255),gA*255]).astype(np.uint8),'RGBA').save(f'raw_{name}_luce.png')
    if name=='maschera' and 'holes_all' in dir():
        h=nd.binary_erosion(holes_all[Y0:Y1,X0:X1],iterations=4)
        ha=np.clip(nd.gaussian_filter(h.astype(float),1.5)*1.2,0,1)
        Image.fromarray(np.dstack([np.full(ha.shape+(3,),255),ha[...,None]*255]).astype(np.uint8),'RGBA').save('raw_maschera_occhio.png')
    if 'holes_all' in dir(): del holes_all
    info[name]=[int(X0),int(Y0),int(X1-X0),int(Y1-Y0)]
json.dump(info,open('info.json','w')); print(info)
