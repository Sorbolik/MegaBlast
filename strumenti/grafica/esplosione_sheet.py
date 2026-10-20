import numpy as np
from PIL import Image
from scipy import ndimage as nd
a=np.asarray(Image.open('/mnt/project-files/grafica/concept/esplosione_12_v1.png').convert('RGB')).astype(float)
H,W,_=a.shape; cw,ch=W/4,H/3; print(a.shape,cw,ch)
C=256; frames=[]
# global center estimate per frame via weighted centroid, then use median offset to keep all aligned
cells=[]
for i in range(12):
    r,c=divmod(i,4); x0,y0=int(c*cw),int(r*ch); cell=a[y0:y0+int(ch),x0:x0+int(cw)]
    cells.append(cell)
for i,cell in enumerate(cells):
    mx=cell.max(2)
    A=np.clip((mx-6)/50,0,1)
    col=np.clip(cell/np.maximum(A[...,None],1e-3),0,255); col=np.minimum(col,cell*6+4)
    s=min(cell.shape[:2])
    cy,cx=cell.shape[0]//2,cell.shape[1]//2; h=s//2
    rgba=np.dstack([col,A*255])[cy-h:cy+h,cx-h:cx+h].astype(np.uint8)
    frames.append(Image.fromarray(rgba,'RGBA').resize((C,C),Image.LANCZOS))
sheet=Image.new('RGBA',(4*C,3*C))
for i,f in enumerate(frames): sheet.paste(f,((i%4)*C,(i//4)*C))
out='/mnt/project-files/grafica/esplosioni'
sheet.save(out+'/esplosione_base_12x256.png',optimize=True)
gif=[]
for f in frames+[frames[-1]]:
    bg=Image.new('RGBA',(C,C),(18,19,26,255)); bg.alpha_composite(f); gif.append(bg.convert('RGB').resize((384,384)))
gif[0].save(out+'/anteprima_esplosione.gif',save_all=True,append_images=gif[1:],duration=60,loop=0)
strip=Image.new('RGB',(C*6,C*2),(18,19,26))
for i,f in enumerate(frames): strip.paste(f,((i%6)*C,(i//6)*C),f)
strip.save('strip2.png')
