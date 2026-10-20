import json, os, sys
from PIL import Image
SET=sys.argv[1]; H=1049
F=json.load(open('fit.json')); out='/mnt/project-files/grafica/set'; os.makedirs(out+'/master',exist_ok=True)
slot={'maschera':'maschera','corazza':'corazza','mantello':'mantello','gambale_davanti':'gambali_davanti','gambale_dietro':'gambali_dietro'}
rig={}
for n,(s,(x,y)) in F.items():
    for suf in ['','_finiture','_luce']:
        im=Image.open(f'raw_{n}{suf}.png')
        for k,dst in [(512/H,out+'/master'),(128/H,out)]:
            w,h=round(im.width*s*k),round(im.height*s*k)
            im.resize((max(w,1),max(h,1)),Image.LANCZOS).save(f'{dst}/{SET}_{slot[n]}{suf}.png',optimize=True)
    k=128/H; rig[slot[n]]={'posizione_nel_corpo':[round(x*k,1),round(y*k,1)]}
    # icon 256
    im=Image.open(f'raw_{n}.png').copy(); im.alpha_composite(Image.open(f'raw_{n}_finiture.png'))
    bb=im.getbbox(); im=im.crop(bb); im.thumbnail((220,220),Image.LANCZOS)
    ic=Image.new('RGBA',(256,256),(0,0,0,0)); ic.alpha_composite(im,((256-im.width)//2,(256-im.height)//2)); ic.save(f'{out}/{SET}_{slot[n]}_icona.png')
rf=f'{out}/set_rig.json'; allr=json.load(open(rf)) if os.path.exists(rf) else {'note':'posizione = angolo in alto a sinistra del pezzo, nelle coordinate di scoria_corpo.png (export 128). Ordine: mantello dietro a tutto; gambali_dietro dopo gamba_dietro; corazza e maschera sopra il corpo e la luce; gambali_davanti dopo gamba_davanti. Con la maschera si nascondono le corna della Scoria.'}
allr[SET]=rig; json.dump(allr,open(rf,'w'),indent=1,ensure_ascii=False); print(SET,'ok')
