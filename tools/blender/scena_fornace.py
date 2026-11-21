"""Scena di Blender per animare la fornace del Fabbro (prova di Blender come editor delle animazioni).

Monta i pezzi PNG come piani ritagliati (immagini Codex così come sono: niente ridisegni,
niente bagliori fatti da noi), con i perni al posto giusto, una camera ortografica di fronte
e un'animazione di esempio ("la fornace dà l'oggetto") da cambiare a piacere.

Dal PC (Blender 4.2 o più nuovo):
    blender --python tools/blender/scena_fornace.py
oppure senza finestra, per salvare il file o fare l'anteprima:
    blender --background --python tools/blender/scena_fornace.py -- --salva simulazione/blender/fornace.blend
    blender --background --python tools/blender/scena_fornace.py -- --anteprima simulazione/blender/foto

Unità: 1 pixel della vignetta = 0,01 di Blender. Il gioco guarda la scena di fronte: X a destra,
Z in su. Ogni pezzo si muove (G), gira sul suo perno (R) e si allarga (S); la trasparenza
è il valore "Alpha" del Colore dell'oggetto (pannello Oggetto > Visualizzazione).
"""
import json
import math
import os
import sys

import bpy

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(os.path.dirname(QUI))
PEZZI = os.path.join(QUI, "pezzi_provvisori")
PX = 0.01            # un pixel in unità di Blender
FPS = 60
SFONDO = (245 / 255, 227 / 255, 195 / 255)   # il crema della vignetta di WB-012


def argomenti():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = {}
    for i, k in enumerate(a):
        if k.startswith("--"):
            out[k[2:]] = a[i + 1] if i + 1 < len(a) and not a[i + 1].startswith("--") else True
    return out


def srgb_lineare(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def pulisci():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for blocchi in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.actions, bpy.data.cameras):
        for b in list(blocchi):
            blocchi.remove(b)


def materiale(nome, immagine=None, colore=None):
    """Immagine (o colore pieno) che si vede così com'è, senza luci; Alpha = alpha
    dell'immagine per l'Alpha del Colore dell'oggetto, che si anima."""
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    if hasattr(m, "surface_render_method"):
        m.surface_render_method = "BLENDED"
    else:
        m.blend_method = "BLEND"
    n, l = m.node_tree.nodes, m.node_tree.links
    n.clear()
    uscita = n.new("ShaderNodeOutputMaterial")
    mix = n.new("ShaderNodeMixShader")
    trasp = n.new("ShaderNodeBsdfTransparent")
    luce = n.new("ShaderNodeEmission")
    info = n.new("ShaderNodeObjectInfo")
    per = n.new("ShaderNodeMath")
    per.operation = "MULTIPLY"
    if immagine:
        tex = n.new("ShaderNodeTexImage")
        tex.image = immagine
        tex.interpolation = "Linear"
        tex.extension = "CLIP"
        l.new(tex.outputs["Color"], luce.inputs["Color"])
        l.new(tex.outputs["Alpha"], per.inputs[0])
    else:
        luce.inputs["Color"].default_value = (*colore, 1)
        per.inputs[0].default_value = 1
    l.new(info.outputs["Alpha"], per.inputs[1])
    l.new(per.outputs[0], mix.inputs[0])
    l.new(trasp.outputs[0], mix.inputs[1])
    l.new(luce.outputs[0], mix.inputs[2])
    l.new(mix.outputs[0], uscita.inputs["Surface"])
    return m


def piano(nome, larghezza, altezza, perno, mat):
    """Un piano largo x alto pixel con l'origine nel perno (pixel dall'angolo in alto a
    sinistra dell'immagine)."""
    px, py = perno
    x0, x1 = -px * PX, (larghezza - px) * PX
    z0, z1 = (py - altezza) * PX, py * PX
    me = bpy.data.meshes.new(nome)
    me.from_pydata([(x0, 0, z0), (x1, 0, z0), (x1, 0, z1), (x0, 0, z1)], [], [(0, 1, 2, 3)])
    uv = me.uv_layers.new()
    for i, c in enumerate([(0, 0), (1, 0), (1, 1), (0, 1)]):
        uv.data[i].uv = c
    me.materials.append(mat)
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    o.rotation_mode = "XYZ"
    return o


def pezzo(nome, file, perno_vignetta, riquadro, profondita, padre=None, scala=1.0):
    """Un pezzo PNG messo dove stava nella vignetta: riquadro = (x0, y0) dell'immagine nella
    vignetta, perno in pixel della vignetta."""
    img = bpy.data.images.load(file, check_existing=True)
    img.alpha_mode = "STRAIGHT"
    w, h = img.size
    px, py = perno_vignetta
    o = piano(nome, w, h, ((px - riquadro[0]) / scala, (py - riquadro[1]) / scala), materiale(nome, img))
    o.scale = (scala, scala, scala)
    o.location = (px * PX, profondita, -py * PX)
    if padre:   # il padre a riposo non gira e non è scalato: basta togliere la sua posizione
        o.parent = padre
        o.location = o.location - padre.location
    o["perno_px"] = [px, py]
    o["riposo"] = list(o.location)      # da qui l'esportazione misura gli spostamenti
    o["scala_riposo"] = scala
    return o


def chiave(o, f, loc=None, rot=None, scala=None, alpha=None):
    if loc is not None:
        o.location = loc
        o.keyframe_insert("location", frame=f)
    if rot is not None:
        o.rotation_euler = rot
        o.keyframe_insert("rotation_euler", frame=f)
    if scala is not None:
        o.scale = scala
        o.keyframe_insert("scale", frame=f)
    if alpha is not None:
        o.color[3] = alpha
        o.keyframe_insert("color", index=3, frame=f)


def monta():
    pulisci()
    info = json.load(open(os.path.join(PEZZI, "pezzi.json")))
    sc = bpy.context.scene
    sc.render.fps = FPS
    sc.frame_start, sc.frame_end = 0, 150
    sc.render.resolution_x, sc.render.resolution_y = 640, 680
    try:
        sc.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    mondo = sc.world or bpy.data.worlds.new("Mondo")
    sc.world = mondo
    mondo.use_nodes = True
    bg = mondo.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (*[srgb_lineare(c) for c in SFONDO], 1)

    # i pezzi, dal fondo: interno (segnaposto), corpo, sportello, oggetto, fumo
    corpo = pezzo("corpo", os.path.join(PEZZI, "corpo.png"), (195, 392), info["corpo"], 0)
    sp = info["sportello"]
    interno = piano("interno_segnaposto", sp[2] - sp[0], sp[3] - sp[1], (0, 0),
                    materiale("interno_segnaposto", colore=(0.06, 0.02, 0.01)))
    interno.parent = corpo
    interno.location = (sp[0] * PX - corpo.location.x, 0.02, -sp[1] * PX - corpo.location.z)
    interno["riposo"] = list(interno.location)
    interno["perno_px"] = [sp[0], sp[1]]
    interno["segnaposto"] = "il buio dentro la fornace: lo sostituirà il pezzo di Codex"
    sportello = pezzo("sportello", os.path.join(PEZZI, "sportello.png"), (152, 186), sp, -0.02, corpo)
    icona = os.path.join(RADICE, "art/WB-043/ritagli/ic_fabbro_elmo_base.png")
    oggetto = pezzo("oggetto", icona, (208, 180), (208 - 173 * 0.22, 180 - 173 * 0.22), 0.01, corpo, scala=0.22)
    fumo = pezzo("fumo", os.path.join(PEZZI, "fumo.png"), (278, 58), info["fumo"], -0.01, corpo)

    cam_dati = bpy.data.cameras.new("camera")
    cam_dati.type = "ORTHO"
    cam_dati.ortho_scale = 4.4
    cam = bpy.data.objects.new("camera", cam_dati)
    bpy.context.collection.objects.link(cam)
    cam.location = (1.93, -10, -2.1)
    cam.rotation_euler = (math.pi / 2, 0, 0)
    sc.camera = cam

    esempio(corpo, sportello, oggetto, fumo)
    return corpo


def esempio(corpo, sportello, oggetto, fumo):
    """L'animazione di esempio, 150 fotogrammi a 60 al secondo (2,5 s): respiro, sbuffo,
    lo sportello si apre col rimbalzo, l'oggetto salta fuori ad arco, lo sportello si chiude."""
    c0, s0, o0, f0 = corpo.location.copy(), sportello.location.copy(), oggetto.location.copy(), fumo.location.copy()
    so = oggetto.scale[0]
    # corpo: carica (si abbassa) e spinge
    chiave(corpo, 0, scala=(1, 1, 1))
    chiave(corpo, 18, scala=(1.03, 1, 0.97))
    chiave(corpo, 30, scala=(0.98, 1, 1.03))
    chiave(corpo, 44, scala=(1, 1, 1))
    chiave(corpo, 150, scala=(1, 1, 1))
    # fumo: sbuffo che sale, cresce e sparisce, due volte
    for inizio in (0, 75):
        chiave(fumo, inizio, loc=f0, scala=(0.35, 0.35, 0.35), alpha=0)
        chiave(fumo, inizio + 6, alpha=1)
        chiave(fumo, inizio + 40, alpha=1)
        chiave(fumo, inizio + 70, loc=(f0.x + 0.15, f0.y, f0.z + 0.35), scala=(1.1, 1.1, 1.1), alpha=0)
    # sportello: si apre girando sul cardine (asse verticale), rimbalza, poi si richiude
    chiave(sportello, 0, rot=(0, 0, 0))
    chiave(sportello, 30, rot=(0, 0, 0))
    chiave(sportello, 40, rot=(0, 0, math.radians(-120)))
    chiave(sportello, 46, rot=(0, 0, math.radians(-100)))
    chiave(sportello, 52, rot=(0, 0, math.radians(-110)))
    chiave(sportello, 110, rot=(0, 0, math.radians(-110)))
    chiave(sportello, 124, rot=(0, 0, math.radians(4)))
    chiave(sportello, 130, rot=(0, 0, 0))
    # oggetto: nascosto dentro, salta fuori ad arco davanti e resta lì
    chiave(oggetto, 0, loc=o0, scala=(so * 0.3,) * 3, alpha=0)
    chiave(oggetto, 38, loc=o0, scala=(so * 0.3,) * 3, alpha=0)
    chiave(oggetto, 42, alpha=1)
    chiave(oggetto, 58, loc=(o0.x + 0.7, o0.y - 0.05, o0.z + 0.9), rot=(0, math.radians(-25), 0), scala=(so * 1.3,) * 3)
    chiave(oggetto, 76, loc=(o0.x + 1.05, o0.y - 0.05, o0.z - 1.5), rot=(0, math.radians(-360), 0), scala=(so * 1.6,) * 3)
    chiave(oggetto, 84, scala=(so * 1.8, so * 1.8, so * 1.4))
    chiave(oggetto, 92, scala=(so * 1.6,) * 3)
    chiave(oggetto, 150, loc=(o0.x + 1.05, o0.y - 0.05, o0.z - 1.5), rot=(0, math.radians(-360), 0), scala=(so * 1.6,) * 3)
    chiave(oggetto, 0, rot=(0, 0, 0))
    chiave(oggetto, 38, rot=(0, 0, 0))


def vista_materiale():
    """Nella finestra 3D si vedono i colori veri e si guarda dalla camera."""
    for schermo in bpy.data.screens:
        for area in schermo.areas:
            if area.type == "VIEW_3D":
                for sp in area.spaces:
                    if sp.type == "VIEW_3D":
                        sp.shading.type = "MATERIAL"
                        sp.region_3d.view_perspective = "CAMERA"


def anteprima(cartella):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 16
    sc.cycles.device = "CPU"
    sc.render.image_settings.file_format = "PNG"
    sc.render.filepath = os.path.join(os.path.abspath(cartella), "f_")
    bpy.ops.render.render(animation=True)


if __name__ == "__main__":
    arg = argomenti()
    monta()
    vista_materiale()
    if "salva" in arg:
        os.makedirs(os.path.dirname(os.path.abspath(arg["salva"])), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(arg["salva"]))
    if "anteprima" in arg:
        anteprima(arg["anteprima"])
