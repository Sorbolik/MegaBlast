# Prepara la grafica della home (client/assets/menu/) dai pezzi già pronti.
# Uso: python3 strumenti/grafica/menu.py [cartella grafica con i master]
#  - kit UI e logo rimpiccioliti alla misura in cui si vedono (atlante piccolo)
#  - sfondo della home largo 2048 px: riempie da solo una texture 2048 x 1024
#  - Scoria e armi in mano dai master (4x): nella home la Scoria è grande
import os, sys, shutil, json
from PIL import Image
R = os.path.join(os.path.dirname(__file__), '..', '..')
UI = os.path.join(R, 'client/assets/ui')
OUT = os.path.join(R, 'client/assets/menu')
MASTER = sys.argv[1] if len(sys.argv) > 1 else '/mnt/project-files/grafica'
KIT = 0.6   # i bottoni si vedono a circa 0.4 della misura del kit su 1280 x 720, x1.5 per gli schermi densi
KIT_PEZZI = ['bottone_principale', 'bottone_principale_premuto', 'bottone_secondario',
	'bottone_secondario_premuto', 'slot', 'slot_bloccato', 'notifica', 'divisore', 'pannello']
ICONE = ['armatura', 'armi', 'forgia', 'shop', 'inventario', 'classifica', 'missioni',
	'impostazioni', 'gioca', 'lucchetto']

def scala(src, dst, k=None, w=None):
	im = Image.open(src).convert('RGBA')
	if w: k = w / im.width
	im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
	im.save(dst, optimize=True)
	return im.size

for d in ('kit', 'icone'): os.makedirs(f'{OUT}/{d}', exist_ok=True)
kit = json.load(open(f'{UI}/kit/kit_ui.json'))
info = {}
for p in KIT_PEZZI:
	w, h = scala(f'{UI}/kit/{p}.png', f'{OUT}/kit/{p}.png', KIT)
	info[p] = {'w': w, 'h': h, 'bordo_9slice': [round(b * KIT) for b in kit[p]['bordo_9slice']]}
json.dump(info, open(f'{OUT}/kit/kit_menu.json', 'w'), indent=1)
for i in ICONE: scala(f'{UI}/icone/icona_{i}.png', f'{OUT}/icone/icona_{i}.png', w=96)
for p in ('logo', 'logo_luce'): scala(f'{UI}/{p}.png', f'{OUT}/{p}.png', w=720)
scala(f'{UI}/sfondi/home_sfondo.png', f'{OUT}/home_sfondo.png', w=2048)
print('ok', OUT)
