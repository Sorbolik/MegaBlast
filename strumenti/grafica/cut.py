import numpy as np, json
from PIL import Image
from scipy import ndimage as nd
a=np.asarray(Image.open('/mnt/project-files/grafica/concept/scoria_pezzi_v1.png').convert('RGB')).astype(float)
bg=np.load('bg.npy'); dist=np.load('dist.npy'); lab=np.load('lab.npy')
names={3:'corpo',1:'corna_davanti',2:'corna_dietro',5:'braccio_davanti',4:'braccio_dietro',6:'gamba_davanti',7:'gamba_dietro'}
red=a[...,0]-np.maximum(a[...,1],a[...,2])
body=lab==3
# glow masks (body only)
def region(seed,thr):
    m=(red>thr)&body
    l,_=nd.label(nd.binary_closing(m,iterations=2))
    r=l==l[seed]
    return nd.binary_fill_holes(nd.binary_closing(r,iterations=4))
eye=region((295,470),12)
from PIL import ImageDraw
pm=Image.new('L',(a.shape[1],a.shape[0]),0); ImageDraw.Draw(pm).polygon([(452,459),(516,561),(464,638),(387,546)],fill=1)
core=np.asarray(pm).astype(bool)
print('eye px',eye.sum(),'core px',core.sum())
th=red-nd.grey_opening(red,size=(9,9)); cr=np.clip((th-6)/14,0,1)*body*(red>10); cr[nd.binary_dilation(eye|core,iterations=3)]=0
cr[:116+215,:]=0
cl_,n_=nd.label(cr>0.1); sz=nd.sum(cr>0.1,cl_,range(1,n_+1))
for k,v in enumerate(sz,1):
    if v<50: cr[cl_==k]=0
# cleaned color: remove red cast
c=a.copy(); c[...,0]=np.minimum(c[...,0],np.maximum(c[...,1],c[...,2])+1)
# eye socket & core: dark flat
lum=c.mean(2,keepdims=True)
for m,k in((eye,.55),(core,.8)):
    c[m]=np.clip(np.array([27,25,31.])*(0.6+0.8*(lum[m]/max(lum[m].mean(),1))),0,255)*k/ k
out={}
for i,n in names.items():
    comp=lab==i
    grow=nd.binary_dilation(comp,iterations=3)
    alpha=np.clip((dist-6)/16,0,1)*grow
    inner=nd.binary_erosion(nd.binary_fill_holes(comp),iterations=2)
    alpha[inner]=1
    ys,xs=np.where(alpha>0.02); y0,y1,x0,x1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
    A=alpha[y0:y1,x0:x1]; C=c[y0:y1,x0:x1]; B=bg[y0:y1,x0:x1]
    col=np.clip((C-(1-A[...,None])*B)/np.maximum(A[...,None],1e-3),0,255)
    col[A<0.02]=0
    rgba=np.dstack([col,A*255]).astype(np.uint8)
    Image.fromarray(rgba,'RGBA').save(f'raw_{n}.png')
    out[n]=[int(x0),int(y0)]
    if n=='corpo':
        def glow(m,soft=1.5):
            g=nd.gaussian_filter(m.astype(float),soft)
            return np.clip(g,0,1)
        # core: facets from luminance
        L=a.mean(2); cl=core*np.clip(0.55+0.45*(L-L[core].min())/(np.ptp(L[core])+1),0,1)
        cl=np.maximum(glow(core,1.0)*0.7,cl)
        luce=np.clip(np.maximum(cl,cr),0,1)[y0:y1,x0:x1]
        Image.fromarray(np.dstack([np.full(luce.shape+(3,),255),luce[...,None]*255]).astype(np.uint8),'RGBA').save('raw_nucleo_luce.png')
        np.save('eye_mask.npy',eye[y0:y1,x0:x1])
json.dump(out,open('origins.json','w'))
print(out)
