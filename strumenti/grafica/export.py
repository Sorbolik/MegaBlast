import json, os
from PIL import Image
import assemble as A
out='/mnt/project-files/grafica/scoria'; os.makedirs(out+'/master',exist_ok=True)
full=A.build((255,255,255)); H=full.height
# canvas offsets: compute the bbox origin same way as build
files={'corpo':'raw_corpo.png','nucleo_luce':'raw_nucleo_luce.png'}
for n in A.P: files[n]=f'raw_{n}.png'
for e in ['neutro','mira','paura','colpito','poca_vita','vittoria']: files['occhio_'+e]=f'raw_occhio_{e}.png'
rig={'note':'coordinate in pixel del file export (128 px di altezza totale); perno = punto di rotazione nel pezzo; aggancio = dove va il perno, nel sistema del corpo (origine in alto a sinistra di scoria_corpo.png)','pezzi':{}}
for scale,dst,key in [(512/H,out+'/master','master_512'),(128/H,out,'export_128')]:
    for n,f in files.items():
        im=Image.open(f); w,h=max(1,round(im.width*scale)),max(1,round(im.height*scale))
        im.resize((w,h),Image.LANCZOS).save(f'{dst}/scoria_{n}.png',optimize=True)
s=128/H
for n,((px,py),(ax,ay)) in A.P.items():
    rig['pezzi'][n]={'perno':[round(px*s,1),round(py*s,1)],'aggancio':[round(ax*s,1),round(ay*s,1)]}
eo=json.load(open('eye_off.json'))['offset_in_corpo']
rig['pezzi']['occhio']={'posizione':[round(eo[0]*s,1),round(eo[1]*s,1)],'note':'angolo in alto a sinistra di scoria_occhio_*.png; disegno additivo, tinta = colore squadra'}
rig['pezzi']['nucleo_luce']={'posizione':[0,0],'note':'stessa tela del corpo; disegno additivo, tinta = colore squadra'}
rig['ordine']=['braccio_dietro','gamba_dietro','corna_dietro','corpo','nucleo_luce','occhio','gamba_davanti','corna_davanti','braccio_davanti']
json.dump(rig,open(out+'/scoria_rig.json','w'),indent=1,ensure_ascii=False)
print(H, s)
