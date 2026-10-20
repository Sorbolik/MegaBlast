import numpy as np
from PIL import Image
from scipy import ndimage as nd
src=Image.open('/mnt/project-files/grafica/concept/mappa_isole_cimitero_v1.png').convert('RGB').resize((2560,1440),Image.LANCZOS)
a=np.asarray(src).astype(float); mx=a.max(2); mn=a.min(2); sat=(mx-mn)/np.maximum(mx,1); lum=a.mean(2)
r,g,b=a[...,0],a[...,1],a[...,2]
alpha=np.clip((mx-14)/30,0,1)
solid0=nd.binary_closing(nd.binary_opening(mx>16,iterations=2),iterations=2)
holes=nd.binary_fill_holes(solid0)&~solid0; hl,hn=nd.label(holes); hs=nd.sum(holes,hl,range(1,hn+1))
solid=solid0|np.isin(hl,1+np.where(hs<3000)[0])
l,n=nd.label(solid); sz=nd.sum(solid,l,range(1,n+1))
big=np.isin(l,1+np.where(sz>6000)[0])
bone=(lum>135)&(sat<0.35)&(r>=b)
red=(r>90)&(r>g*1.7)&(r>b*1.5)
chain=(sat>0.35)&(r>g)&(g>b)&(lum>45)&(lum<140)&~red
hard=nd.binary_closing(bone|red|chain,iterations=3)&big
hard=nd.binary_opening(hard,iterations=3)
hl2,hn2=nd.label(hard); hs2=nd.sum(hard,hl2,range(1,hn2+1)); hard=np.isin(hl2,1+np.where(hs2>2500)[0])
hard=nd.binary_closing(hard,iterations=4)&big
hard=hard|hard[:,::-1]
dig=big&~hard
# 640x360 mask by area majority
def down(m): return m.reshape(360,4,640,4).mean((1,3))
D=down(dig.astype(float)); Hh=down(hard.astype(float))
cell=np.zeros((360,640),np.uint8); cell[D>0.5]=1; cell[(Hh>0.45)]=2
cell=np.maximum(cell,cell[:,::-1])
out=np.zeros((360,640,3),np.uint8); out[cell==1]=(255,255,255); out[cell==2]=(255,0,0)
Image.fromarray(out).save('maschera.png')
big_m=np.zeros((1440,2560,3),np.uint8); big_m[dig]=(255,255,255); big_m[hard]=(255,0,0)
Image.fromarray(big_m).save('maschera_2560.png')
ov=Image.blend(src,Image.fromarray(big_m),0.45); ov.resize((1280,720)).save('overlay2.png')
print('cells dig',(cell==1).sum(),'hard',(cell==2).sum())
np.save('cell.npy',cell)
