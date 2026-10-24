import numpy as np
from PIL import Image
from scipy import ndimage as nd
a=np.asarray(Image.open('/mnt/project-files/grafica/concept/armi_v1.png').convert('RGB')).astype(float)
H,W,_=a.shape; ref=a[5,5]
d=np.linalg.norm(a-ref,axis=2); cand=d<10
yy,xx=np.mgrid[0:H,0:W]/np.array([H,W]).reshape(2,1,1)
X=np.stack([np.ones(H*W),xx.ravel(),yy.ravel(),xx.ravel()**2,yy.ravel()**2,(xx*yy).ravel()],1)
bg=np.zeros_like(a)
for c in range(3):
    coef,*_=np.linalg.lstsq(X[cand.ravel()],a[...,c].ravel()[cand.ravel()],rcond=None); bg[...,c]=(X@coef).reshape(H,W)
dist=np.linalg.norm(a-bg,axis=2)
mx=a.max(2); mn=a.min(2); sat=(mx-mn)/np.maximum(mx,1); lum=a.mean(2)
r,g,b=a[...,0],a[...,1],a[...,2]
cells={'lanciarune':(0,1,0),'uovo_di_fiamma':(1,1,0),'sciame_di_schegge':(2,1,0),'pugno_del_titano':(0,1,1)}
for n,(cx,_,cy) in cells.items():
    x0,x1=cx*W//3,(cx+1)*W//3; y0,y1=cy*H//2,(cy+1)*H//2
    sub=dist[y0:y1,x0:x1]
    alpha=np.clip((sub-6)/16,0,1)
    lb,kb=nd.label(nd.binary_dilation(sub>14,iterations=4))
    edge=set(np.unique(np.concatenate([lb[0],lb[-1],lb[:,0],lb[:,-1]])))-{0}
    for e in edge:
        if (lb==e).sum()<20000: alpha[lb==e]=0
    core=nd.binary_fill_holes(nd.binary_closing(sub>14,iterations=3))
    if n != 'sciame_di_schegge':
        l,k=nd.label(core); sz=nd.sum(core,l,range(1,k+1)); keep=l==(np.argmax(sz)+1)
        keep=nd.binary_dilation(keep,iterations=3); alpha*=keep
        alpha[nd.binary_erosion(nd.binary_fill_holes(l==(np.argmax(sz)+1)),iterations=2)]=1
    ys,xs=np.where(alpha>0.03); Y0,Y1,X0,X1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
    A=alpha[Y0:Y1,X0:X1]; C=a[y0:y1,x0:x1][Y0:Y1,X0:X1]; B=bg[y0:y1,x0:x1][Y0:Y1,X0:X1]
    col=np.clip((C-(1-A[...,None])*B)/np.maximum(A[...,None],1e-3),0,255); col[A<0.02]=0
    s=(sat[y0:y1,x0:x1][Y0:Y1,X0:X1]); L=lum[y0:y1,x0:x1][Y0:Y1,X0:X1]; R=r[y0:y1,x0:x1][Y0:Y1,X0:X1]; G=g[y0:y1,x0:x1][Y0:Y1,X0:X1]
    glow=np.maximum(np.clip((L-170)/60,0,1)*(s<0.25), np.clip((R-G-70)/80,0,1))
    glow*=A
    # base: remove the emissive color so team tint works
    base=col.copy(); gg=glow[...,None]; base=base*(1-gg)+np.array([30,26,34.])*gg
    redcast=(np.clip((base[...,0]-base[...,1]-40)/40,0,1)*(np.abs(base[...,1]-base[...,2])<30))[...,None]
    gray=base.mean(2,keepdims=True)*np.array([0.9,0.88,1.0])
    base=base*(1-redcast)+gray*redcast
    Image.fromarray(np.dstack([base,A*255]).astype(np.uint8),'RGBA').save(f'raw_{n}.png')
    Image.fromarray(np.dstack([np.full(A.shape+(3,),255),glow[...,None]*255]).astype(np.uint8),'RGBA').save(f'raw_{n}_luce.png')
    print(n,A.shape)
