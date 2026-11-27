"""Fabbro 3D, quinta versione: il pupazzo rifatto pezzo per pezzo sul disegno WB-085 (fabbro al banco)."""
import bpy, math, sys
from mathutils import Vector

S = '/tmp/claude-0/-home-user/67c1505c-c35c-547d-b0fe-d84ef68966b9/scratchpad'
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
col = bpy.context.collection
EX = {'busto': [], 'gd': [], 'gs': [], 'grata': [], 'bd': [], 'bs': [], 'polso': []}   # extra pieces for each joint of the rig


def lin(c):
    return tuple((v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4) for v in c)


def mat(name, rgb, glow=False, puntini=None, scala=26.0, soglia=0.6):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n, l = m.node_tree.nodes, m.node_tree.links
    n.clear()
    out = n.new('ShaderNodeOutputMaterial')
    c = lin([v / 255 for v in rgb])
    if glow:
        e = n.new('ShaderNodeEmission'); e.inputs[0].default_value = (*c, 1); e.inputs[1].default_value = 1.0
        l.new(e.outputs[0], out.inputs[0])
        return m
    toon = n.new('ShaderNodeBsdfToon'); toon.inputs['Color'].default_value = (*c, 1)
    toon.inputs['Size'].default_value = 0.55; toon.inputs['Smooth'].default_value = 0.03
    e = n.new('ShaderNodeEmission'); e.inputs[0].default_value = (*c, 1); e.inputs[1].default_value = 0.62
    if puntini:   # pitted iron, wood grain: darker specks like the ink drawing
        tc = n.new('ShaderNodeTexCoord'); no = n.new('ShaderNodeTexNoise'); no.inputs['Scale'].default_value = scala
        no.inputs['Detail'].default_value = 3.0
        ramp = n.new('ShaderNodeValToRGB'); ramp.color_ramp.interpolation = 'CONSTANT'
        ramp.color_ramp.elements[0].color = (*c, 1); ramp.color_ramp.elements[1].position = soglia
        ramp.color_ramp.elements[1].color = (*lin([v / 255 for v in puntini]), 1)
        l.new(tc.outputs['Object'], no.inputs['Vector']); l.new(no.outputs['Fac'], ramp.inputs[0])
        l.new(ramp.outputs[0], toon.inputs['Color']); l.new(ramp.outputs[0], e.inputs[0])
    add = n.new('ShaderNodeAddShader')
    l.new(toon.outputs[0], add.inputs[0]); l.new(e.outputs[0], add.inputs[1]); l.new(add.outputs[0], out.inputs[0])
    return m


def ink():
    m = bpy.data.materials.new('china')
    m.use_nodes = True
    n, l = m.node_tree.nodes, m.node_tree.links
    n.clear()
    out = n.new('ShaderNodeOutputMaterial'); geo = n.new('ShaderNodeNewGeometry')
    tr = n.new('ShaderNodeBsdfTransparent'); e = n.new('ShaderNodeEmission')
    e.inputs[0].default_value = (0.02, 0.012, 0.008, 1)
    mix = n.new('ShaderNodeMixShader')
    l.new(geo.outputs['Backfacing'], mix.inputs[0]); l.new(e.outputs[0], mix.inputs[1]); l.new(tr.outputs[0], mix.inputs[2])
    l.new(mix.outputs[0], out.inputs[0])
    return m


INK = ink()
BIANCO = None
M = {
    'pelle': mat('pelle', (208, 62, 38)), 'ferro': mat('ferro', (104, 90, 76), puntini=(66, 56, 48)),
    'ottone': mat('ottone', (220, 152, 62)), 'cuoio': mat('cuoio', (180, 106, 48), puntini=(150, 84, 38), scala=9, soglia=0.66),
    'cuoio_scuro': mat('cuoio_scuro', (124, 74, 40)), 'guanto': mat('guanto', (108, 72, 52), puntini=(82, 54, 40), scala=30, soglia=0.64),
    'corno': mat('corno', (204, 146, 80)), 'corno_scuro': mat('corno_scuro', (146, 92, 50)),
    'baffi': mat('baffi', (246, 234, 210)), 'fuoco': mat('fuoco', (255, 150, 30), True), 'fuoco2': mat('fuoco2', (255, 215, 80), True),
    'occhio': mat('occhio', (255, 214, 40), True), 'nero': mat('nero', (18, 12, 10), True),
    'legno': mat('legno', (190, 114, 52), puntini=(146, 82, 36), scala=14, soglia=0.62), 'scuro': mat('scuro', (58, 46, 40)),
}
M['fumo'] = mat('fumo', (206, 196, 176))

# ---- drawn textures: flat ink-drawing colours (light and shade tone), plus the marks of each material
from mathutils import Euler
LUCE = Euler((math.radians(55), math.radians(8), math.radians(-35))).to_matrix() @ Vector((0, 0, 1))


def dis(name, chiaro, ombra, segno=None, tipo=None, scala=14.0, zona=0.6, spesso=0.8, ruggine=None, taglio=0.42, rot=(0.0, 0.7, 0.5), dist=None):
    """tipo: 'tratti' = hatching strokes in the shade, 'fili' = strands/grain everywhere, 'punti' = pits everywhere."""
    m = bpy.data.materials.new(name); m.use_nodes = True
    n, l = m.node_tree.nodes, m.node_tree.links; n.clear()
    C = lambda c: (*lin([v / 255 for v in c]), 1)
    def ramp(pos, sotto, sopra, interp='CONSTANT', pos0=0.0):
        r = n.new('ShaderNodeValToRGB'); r.color_ramp.interpolation = interp
        r.color_ramp.elements[0].position = pos0; r.color_ramp.elements[0].color = sotto
        r.color_ramp.elements[1].position = pos; r.color_ramp.elements[1].color = sopra
        return r
    def mix(fac, a, b):
        x = n.new('ShaderNodeMix'); x.data_type = 'RGBA'
        l.new(fac, x.inputs[0]); l.new(a, x.inputs[6]); l.new(b, x.inputs[7])
        return x.outputs[2]
    def per(a, b):
        x = n.new('ShaderNodeMath'); x.operation = 'MULTIPLY'; l.new(a, x.inputs[0]); l.new(b, x.inputs[1]); return x.outputs[0]
    B, W = (0, 0, 0, 1), (1, 1, 1, 1)
    geo = n.new('ShaderNodeNewGeometry'); dot = n.new('ShaderNodeVectorMath'); dot.operation = 'DOT_PRODUCT'
    l.new(geo.outputs['Normal'], dot.inputs[0]); dot.inputs[1].default_value = tuple(LUCE)
    meta = n.new('ShaderNodeMath'); meta.operation = 'MULTIPLY_ADD'; meta.inputs[1].default_value = 0.5; meta.inputs[2].default_value = 0.5
    l.new(dot.outputs['Value'], meta.inputs[0])
    r1 = ramp(taglio, W, B); l.new(meta.outputs[0], r1.inputs[0])
    c1 = n.new('ShaderNodeRGB'); c1.outputs[0].default_value = C(chiaro)
    c2 = n.new('ShaderNodeRGB'); c2.outputs[0].default_value = C(ombra)
    colore = mix(r1.outputs[0], c1.outputs[0], c2.outputs[0])
    tc = n.new('ShaderNodeTexCoord')
    if ruggine:
        no = n.new('ShaderNodeTexNoise'); no.inputs['Scale'].default_value = 3.2; no.inputs['Detail'].default_value = 4.0
        l.new(tc.outputs['Object'], no.inputs['Vector'])
        rr = ramp(0.63, B, W, 'LINEAR', 0.55); l.new(no.outputs['Fac'], rr.inputs[0])
        c4 = n.new('ShaderNodeRGB'); c4.outputs[0].default_value = C(ruggine)
        colore = mix(rr.outputs[0], colore, c4.outputs[0])
    if tipo:
        c3 = n.new('ShaderNodeRGB'); c3.outputs[0].default_value = C(segno)
        if tipo == 'punti':
            no = n.new('ShaderNodeTexNoise'); no.inputs['Scale'].default_value = scala; no.inputs['Detail'].default_value = 3.0
            l.new(tc.outputs['Object'], no.inputs['Vector'])
            rp = ramp(spesso, B, W); l.new(no.outputs['Fac'], rp.inputs[0]); maschera = rp.outputs[0]
        else:
            mp = n.new('ShaderNodeMapping'); mp.inputs['Rotation'].default_value = rot; l.new(tc.outputs['Object'], mp.inputs[0])
            wv = n.new('ShaderNodeTexWave'); wv.wave_type = 'BANDS'; wv.inputs['Scale'].default_value = scala
            wv.inputs['Distortion'].default_value = dist if dist is not None else (1.6 if tipo == 'tratti' else 3.5); wv.inputs['Detail'].default_value = 2.0
            l.new(mp.outputs[0], wv.inputs['Vector'])
            rl = ramp(spesso, B, W); l.new(wv.outputs['Fac'], rl.inputs[0]); maschera = rl.outputs[0]
            no = n.new('ShaderNodeTexNoise'); no.inputs['Scale'].default_value = 2.6; l.new(tc.outputs['Object'], no.inputs['Vector'])
            rd = ramp(0.46, B, W); l.new(no.outputs['Fac'], rd.inputs[0]); maschera = per(maschera, rd.outputs[0])
            if tipo == 'tratti':
                rz = ramp(zona, W, B); l.new(meta.outputs[0], rz.inputs[0]); maschera = per(maschera, rz.outputs[0])
        colore = mix(maschera, colore, c3.outputs[0])
    e = n.new('ShaderNodeEmission'); l.new(colore, e.inputs[0]); e.inputs[1].default_value = 1.0
    out = n.new('ShaderNodeOutputMaterial'); l.new(e.outputs[0], out.inputs[0])
    return m


M.update({
    'pelle': dis('pelle', (206, 64, 38), (160, 40, 26), (98, 18, 12), 'tratti', scala=17, zona=0.74, taglio=0.5, spesso=0.76),
    'ferro': dis('ferro', (116, 100, 84), (76, 64, 54), (42, 34, 30), 'punti', scala=26, spesso=0.6, ruggine=(152, 88, 44)),
    'ottone': dis('ottone', (228, 162, 66), (174, 110, 40), (132, 78, 28), 'punti', scala=34, spesso=0.68),
    'cuoio': dis('cuoio', (190, 114, 52), (144, 80, 36), (100, 54, 24), 'tratti', scala=9, zona=0.75, spesso=0.84, ruggine=(164, 92, 40)),
    'cuoio_scuro': dis('cuoio_scuro', (130, 80, 44), (94, 56, 30), (60, 34, 18), 'tratti', scala=10, zona=0.7),
    'guanto': dis('guanto', (114, 78, 56), (78, 52, 38), (44, 28, 20), 'tratti', scala=18, zona=0.8, spesso=0.74),
    'corno': dis('corno', (210, 152, 86), (164, 108, 58), (120, 74, 38), 'fili', scala=5, spesso=0.86),
    'corno_scuro': dis('corno_scuro', (150, 96, 52), (110, 68, 38)),
    'baffi': dis('baffi', (250, 240, 218), (216, 200, 172), (170, 150, 124), 'fili', scala=11, spesso=0.86, rot=(0.0, 0.0, 1.5708), dist=1.0),
    'legno': dis('legno', (196, 120, 56), (152, 88, 40), (112, 62, 26), 'fili', scala=7, spesso=0.78, rot=(0.0, 1.5708, 0.0)),
    'scuro': dis('scuro', (66, 54, 48), (42, 34, 30), (26, 20, 18), 'punti', scala=22, spesso=0.66),
})
SENZA_CHINA = ('fuoco', 'fuoco2', 'occhio', 'nero')
ROOT = bpy.data.objects.new('Fabbro', None); col.objects.link(ROOT)


def finish(o, m, name, parent=None, outline=0.028):
    o.name = name
    if o.type == 'MESH':
        o.data.polygons.foreach_set('use_smooth', [True] * len(o.data.polygons))
    o.data.materials.clear(); o.data.materials.append(M[m])
    if outline and m not in SENZA_CHINA:
        o.data.materials.append(INK)
        s = o.modifiers.new('china', 'SOLIDIFY'); s.thickness = outline; s.offset = 1
        s.use_flip_normals = True; s.material_offset = 1; s.use_rim = False
    o.parent = parent or ROOT
    return o


def sph(name, m, loc, scale, parent=None, rot=(0, 0, 0), seg=40):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, location=loc, rotation=rot)
    o = bpy.context.object; o.scale = scale
    return finish(o, m, name, parent)


def cyl(name, m, loc, r, depth, rot=(0, 0, 0), parent=None, r2=None, scale=(1, 1, 1)):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=36, radius=r, depth=depth, location=loc, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=36, radius1=r, radius2=r2, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object; o.scale = scale
    o = finish(o, m, name, parent)
    o.data.polygons.foreach_set('use_smooth', [abs(p.normal.z) < 0.9 for p in o.data.polygons])
    return o


def tor(name, m, loc, R, r, rot=(0, 0, 0), scale=(1, 1, 1), parent=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=loc, rotation=rot, major_segments=48, minor_segments=12)
    o = bpy.context.object; o.scale = scale
    return finish(o, m, name, parent)


def box(name, m, loc, scale, rot=(0, 0, 0), parent=None, bevel=0.05):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.object; o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    b = o.modifiers.new('smusso', 'BEVEL'); b.width = bevel; b.segments = 3
    o = finish(o, m, name, parent)
    o.data.polygons.foreach_set('use_smooth', [False] * len(o.data.polygons))
    names = [x.name for x in o.modifiers]
    if names and names[0] == 'china':
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_move_to_index(modifier='smusso', index=0)
    return o


def sweep(name, m, pts, radii, parent=None, seg=14, n=10, ridges=0, m2=None, flat=1.0, largo=(0, 1, 0), outline=0.028):
    """A tube through the points (Catmull-Rom), tapered; ridges = rings along it (horns), flat = squashed section (straps)."""
    P = [Vector(p) for p in pts]
    if not isinstance(radii, (list, tuple)): radii = [radii] * len(P)
    def cr(i, t):
        p0, p1, p2, p3 = P[max(i - 1, 0)], P[i], P[i + 1], P[min(i + 2, len(P) - 1)]
        return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3)
    C, Rr = [], []
    for i in range(len(P) - 1):
        for k in range(n):
            t = k / n; C.append(cr(i, t)); Rr.append(radii[i] + (radii[i + 1] - radii[i]) * t)
    C.append(P[-1]); Rr.append(radii[-1])
    N = Vector(largo); verts, faces, solchi = [], [], []
    tot = len(C)
    for j, c in enumerate(C):
        T = (C[min(j + 1, tot - 1)] - C[max(j - 1, 0)]).normalized()
        N = (N - T * N.dot(T)).normalized(); B = T.cross(N)
        r = Rr[j]; onda = math.sin(2 * math.pi * ridges * j / tot) if ridges else 0
        r *= 1 + 0.07 * onda; solchi.append(onda < -0.35)
        for a in range(seg):
            an = 2 * math.pi * a / seg
            verts.append(c + N * (math.cos(an) * r) + B * (math.sin(an) * r * flat))
    for j in range(tot - 1):
        for a in range(seg):
            b = (a + 1) % seg
            faces.append((j * seg + a, j * seg + b, (j + 1) * seg + b, (j + 1) * seg + a))
    verts.append(C[0]); verts.append(C[-1]); i0, i1 = len(verts) - 2, len(verts) - 1
    for a in range(seg):
        b = (a + 1) % seg
        faces.append((i0, b, a)); faces.append((i1, (tot - 1) * seg + a, (tot - 1) * seg + b))
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    o = bpy.data.objects.new(name, me); col.objects.link(o)
    o = finish(o, m, name, parent, outline)
    if m2:
        o.data.materials.append(M[m2]); o.data.materials.append(INK)
        for j in range(tot - 1):
            if solchi[j]:
                for a in range(seg): o.data.polygons[j * seg + a].material_index = 2
    return o


def arco_pts(w, z0, z1, ztop, n=14):
    p = [(-w, z0), (-w, z1)]
    for k in range(1, n):
        a = math.pi - k * math.pi / n
        p.append((w * math.cos(a), z1 + (ztop - z1) * math.sin(a)))
    return p + [(w, z1), (w, z0)]


def arco_pieno(name, m, w, z0, z1, ztop, y0, y1, parent=None):
    return estruso(name, m, arco_pts(w, z0, z1, ztop), y0, y1, parent)


def estruso(name, m, p, y0, y1, parent=None, fy=lambda z: 0.0):
    import bmesh
    k = len(p)
    verts = [(x, y1 + fy(z), z) for x, z in p] + [(x, y0 + fy(z), z) for x, z in p]
    faces = [tuple(range(k - 1, -1, -1)), tuple(range(k, 2 * k))] + [(i, (i + 1) % k, (i + 1) % k + k, i + k) for i in range(k)]
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); col.objects.link(o)
    o = finish(o, m, name, parent)
    o.data.polygons.foreach_set('use_smooth', [False] * len(o.data.polygons))
    return o


NB = [0]
def borchie(pts, gruppo=None, parent=None, r=0.05, m='ottone'):
    for p in pts:
        NB[0] += 1; nm = 'borchia_%03d' % NB[0]
        sph(nm, m, p, (r, r, r), parent, seg=12)
        bpy.data.objects[nm].modifiers['china'].thickness = 0.014
        if gruppo: EX[gruppo].append(nm)


# ---- body
sph('pancia_corazza', 'ferro', (0, 0, 2.05), (1.18, 0.98, 1.08))
sph('petto', 'ferro', (0, 0.02, 2.98), (1.34, 0.86, 0.66))
tor('fascia_torace', 'ferro', (0, 0, 2.62), 1.12, 0.075, scale=(1, 0.84, 1)); EX['busto'].append('fascia_torace')
borchie([(1.16 * math.sin(a), -0.97 * math.cos(a), 2.62) for a in (-1.15, -0.85, 0.85, 1.15)], 'busto')
sph('pettorale', 'ferro', (0, -0.14, 3.04), (1.0, 0.8, 0.5)); EX['busto'].append('pettorale')
borchie([(x, -0.14 - 0.8 * math.sqrt(max(0.02, 1 - (x / 1.0) ** 2 - 0.36)) - 0.02, 2.74) for x in (-0.6, -0.36, -0.12, 0.12, 0.36, 0.6)], 'busto')
sph('scollo', 'pelle', (0, -0.52, 3.42), (0.44, 0.34, 0.24)); EX['busto'].append('scollo')
sph('collo_pelle', 'pelle', (0, -0.14, 3.55), (0.62, 0.54, 0.42)); EX['busto'].append('collo_pelle')
sph('bacino', 'cuoio_scuro', (0, 0.02, 1.2), (1.06, 0.86, 0.62))
tor('cintura', 'ottone', (0, 0, 1.5), 1.02, 0.09, scale=(1, 0.86, 1))
borchie([(1.04 * math.sin(a), -0.9 * math.cos(a), 1.5) for a in (-0.9, -0.3, 0.3, 0.9)], r=0.055)
def u_pts(w, ztop, zbot, r, n=6):
    p = []
    for k in range(n + 1):
        a = math.pi * 1.5 - k * (math.pi / 2) / n
        p.append((-(w - r) + r * math.cos(a), zbot + r + r * math.sin(a)))
    p += [(-w, ztop), (w, ztop)]
    for k in range(n + 1):
        a = 0 - k * (math.pi / 2) / n
        p.append(((w - r) + r * math.cos(a), zbot + r + r * math.sin(a)))
    return p
piega = lambda z: -(1.5 - z) * 0.11
estruso('grembiule', 'cuoio', u_pts(0.7, 1.5, 0.36, 0.3), -0.8, -0.89, fy=piega)
cu = [(x, -0.9 + piega(z), z) for x, z in u_pts(0.62, 1.44, 0.44, 0.24)]
sweep('cucitura', 'cuoio_scuro', cu[len(cu) // 2:] + cu[:len(cu) // 2], 0.018, seg=6, n=3, outline=0)
def y_petto(x, z): return 0.02 - 0.86 * math.sqrt(max(0.02, 1 - (x / 1.34) ** 2 - ((z - 2.98) / 0.66) ** 2))
for sx, n in ((-1, 'd'), (1, 's')):
    tor('anello_' + n, 'ottone', (0.5 * sx, -0.95, 1.34), 0.13, 0.036, rot=(math.radians(90), 0, 0))
    box('passante_' + n, 'ottone', (0.5 * sx, -0.92, 1.5), (0.13, 0.08, 0.2), bevel=0.02)
    box('falda_' + n, 'cuoio_scuro', (0.86 * sx, -0.5, 1.1), (0.5, 0.08, 0.7), rot=(0, 0, math.radians(32 * sx)), bevel=0.03)
    # shoulder strap: iron with brass edges and studs, from the chest over the shoulder
    via = [(0.68 * sx, -0.84, 2.66), (0.74 * sx, -0.9, 3.02), (0.82 * sx, -0.45, 3.56), (0.8 * sx, 0.42, 3.5), (0.7 * sx, 0.84, 2.8)]
    sweep('spallaccio_' + n, 'ferro', via, 0.23, flat=0.3, largo=(1, 0, 0))
    for k, dx in enumerate((-0.22, 0.22)):
        nm = 'orlo_spallaccio_%s%d' % (n, k)
        sweep(nm, 'ottone', [(x + dx, y - 0.03 if y < 0.5 else y + 0.03, z + 0.02) for x, y, z in via], 0.05, seg=8); EX['busto'].append(nm)
    borchie([(0.69 * sx, -0.92, 2.74), (0.72 * sx, -0.97, 2.94), (0.75 * sx, -0.93, 3.14), (0.78 * sx, -0.78, 3.34)], 'busto', r=0.055)
    tor('giro_spalla_' + n, 'ottone', (1.16 * sx, 0.0, 3.04), 0.58, 0.07, rot=(0, math.radians(68 * sx), 0), scale=(1, 0.9, 1))
    EX['busto'].append('giro_spalla_' + n)
    sph('calzone_' + n, 'pelle', (0.6 * sx, 0.0, 0.84), (0.52, 0.52, 0.4))
    borchie([(0.62 * sx + 0.47 * math.sin(t), -0.47 * math.cos(t), 0.58) for t in (-0.7, 0, 0.7)], r=0.045)
    cyl('gamba_' + n, 'pelle', (0.6 * sx, 0.02, 0.66), 0.42, 0.8)
    cyl('stivale_' + n, 'guanto', (0.62 * sx, 0, 0.36), 0.46, 0.5)
    tor('cavigliera_' + n, 'ferro', (0.62 * sx, 0, 0.58), 0.46, 0.08)
    sph('piede_' + n, 'guanto', (0.64 * sx, -0.3, 0.2), (0.5, 0.72, 0.26))
    sph('punta_' + n, 'guanto', (0.64 * sx, -0.8, 0.18), (0.42, 0.32, 0.22))

# ---- furnace on the belly: an arched iron box, embers at the back, a fixed rim, the barred door in front
arco_pieno('forno', 'ferro', 0.86, 1.4, 2.12, 2.74, -0.5, -1.0); EX['busto'].append('forno')
arco_pieno('fuoco', 'fuoco', 0.7, 1.5, 2.12, 2.6, -0.99, -1.025)
sph('fuoco_chiaro', 'fuoco2', (0, -1.035, 1.72), (0.42, 0.012, 0.16))
YR, YG = -1.06, -1.2
sweep('bocca_fornace', 'ferro', [(x, YR, z) for x, z in arco_pts(0.74, 1.5, 2.12, 2.64, 8)], 0.095, n=6)
cyl('soglia_forno', 'ferro', (0, YR, 1.5), 0.095, 1.58, rot=(0, math.radians(90), 0)); EX['busto'].append('soglia_forno')
borchie([(x, YR - 0.1, z) for x, z in arco_pts(0.74, 1.6, 2.12, 2.64, 9)], 'busto', r=0.045)
sweep('cornice_grata', 'ferro', [(x, YG, z) for x, z in arco_pts(0.63, 1.6, 2.12, 2.55, 8)], 0.06, n=6)
sweep('orlo_grata', 'ottone', [(x, YG - 0.05, z) for x, z in arco_pts(0.56, 1.66, 2.12, 2.48, 8)], 0.03, n=6, seg=8, outline=0.012); EX['grata'].append('orlo_grata')
cyl('soglia_grata', 'ferro', (0, YG, 1.6), 0.06, 1.32, rot=(0, math.radians(90), 0)); EX['grata'].append('soglia_grata')
for i, x in enumerate((-0.38, -0.127, 0.127, 0.38)):
    top = 2.12 + 0.43 * math.sqrt(1 - (x / 0.63) ** 2)
    cyl('sbarra_%d' % i, 'ferro', (x, YG, (1.6 + top) / 2), 0.05, top - 1.6)
for sx in (-1, 1):
    box('cerniera_%d' % sx, 'ottone', (0.74 * sx, YG + 0.03, 2.02), (0.26, 0.08, 0.17), bevel=0.02)
    borchie([(0.74 * sx, YG - 0.03, 2.02)], 'grata', r=0.04, m='ferro')

# ---- arms (right = viewer's left, holds the hammer)
def braccio(sx, n, mano):
    gr = 'gd' if n == 'd' else 'gs'
    sph('spalla_' + n, 'pelle', (1.45 * sx, 0.02, 3.0), (0.68, 0.64, 0.66))
    sph('bicipite_' + n, 'pelle', (1.72 * sx, 0, 2.52), (0.58, 0.58, 0.72), rot=(0, math.radians(-28 * sx), 0))
    g = Vector(mano); a = Vector((1.95 * sx, -0.05, 2.1)); d = g - a
    kb = 0.84 if n == 'd' else 1.0   # the fist needs room: shorter bracer on the hammer arm
    qq = d.to_track_quat('Z', 'Y'); q = qq.to_euler()
    sph('gomito_pelle_' + n, 'pelle', a, (0.46, 0.46, 0.46)); EX[gr].append('gomito_pelle_' + n)
    cyl('avambraccio_' + n, 'pelle', a + d * 0.45, 0.47, d.length * 0.9, rot=q, r2=0.4)
    cyl('bracciale_' + n, 'ferro', a + d * 0.68 * kb, 0.5, 0.4 * kb, rot=q)
    tor('bordo_bracciale_' + n, 'ottone', a + d * 0.48 * kb, 0.5, 0.055, rot=q)
    tor('bordo2_bracciale_' + n, 'ottone', a + d * 0.88 * kb, 0.5, 0.055, rot=q); EX[gr].append('bordo2_bracciale_' + n)
    u = qq @ Vector((1, 0, 0)); v = qq @ Vector((0, 1, 0))
    borchie([a + d * 0.68 * kb + (u * math.cos(t) + v * math.sin(t)) * 0.51 for t in [k * math.pi / 4 for k in range(8)]], gr, r=0.055)
    cyl('polsino_' + n, 'guanto', a + d * 0.95 * kb, 0.52 if n == 's' else 0.47, 0.2, rot=q, r2=0.44 if n == 's' else 0.36); EX[gr].append('polsino_' + n)
    if n == 'd':
        sph('polso_guanto_d', 'guanto', a + d * 0.91, (0.44, 0.44, 0.34), rot=q); EX[gr].append('polso_guanto_d')
    sph('guanto_' + n, 'guanto', g, (0.43, 0.41, 0.43))
    return g, d.normalized(), qq

g, dn, qq = braccio(1, 's', (2.05, -0.28, 1.25))
# open hand, palm towards the camera: flat palm, four jointed fingers with knuckles, thumb outwards
X = Vector((1, 0, 0)); F = Vector((0, -1, 0))
pal = bpy.data.objects['guanto_s']; pal.scale = (0.4, 0.21, 0.4); pal.rotation_euler = qq.to_euler()
for i, lung in enumerate((0.8, 0.97, 1.0, 0.9)):   # little finger ... index
    base = g + dn * 0.33 + X * ((i - 1.5) * 0.2) + F * 0.02
    nm = 'dito_s%d' % i
    sweep(nm, 'guanto', [base - dn * 0.08, base + dn * 0.2 * lung + F * 0.03, base + dn * 0.4 * lung + F * 0.12, base + dn * 0.54 * lung + F * 0.24],
          [0.105, 0.105, 0.095, 0.075], seg=12, n=6); EX['gs'].append(nm)
    sph('nocca_s%d' % i, 'guanto', base + F * 0.02, (0.115, 0.1, 0.1), seg=14); EX['gs'].append('nocca_s%d' % i)
p0 = g + X * 0.26 - dn * 0.1 + F * 0.06
sweep('pollice_s', 'guanto', [p0, p0 + X * 0.2 + dn * 0.12 + F * 0.08, p0 + X * 0.3 + dn * 0.3 + F * 0.18, p0 + X * 0.3 + dn * 0.44 + F * 0.3],
      [0.13, 0.12, 0.105, 0.08], seg=12, n=6); EX['gs'].append('pollice_s')
sph('monte_pollice_s', 'guanto', g + X * 0.22 - dn * 0.02 + F * 0.1, (0.17, 0.12, 0.2), seg=14); EX['gs'].append('monte_pollice_s')

g, dn, qq = braccio(-1, 'd', (-2.45, -0.35, 2.55))
# fist around the top of the handle: it belongs to the wrist, so the grip follows the hammer
pal = bpy.data.objects['guanto_d']; pal.scale = (0.36, 0.34, 0.44); pal.location = (g.x + 0.16, g.y + 0.05, g.z - 0.02)
def giro(z, r, a0, a1, dz=0.0, k=7):
    return [Vector((g.x + r * math.cos(math.radians(a0 + (a1 - a0) * j / (k - 1))), g.y - r * math.sin(math.radians(a0 + (a1 - a0) * j / (k - 1))), z + dz * j / (k - 1))) for j in range(k)]
for i in range(4):
    z = g.z - 0.3 + i * 0.185; nm = 'dito_d%d' % i
    sweep(nm, 'guanto', giro(z, 0.24, 0, 240), [0.125, 0.125, 0.125, 0.12, 0.115, 0.105, 0.085], seg=12, n=5); EX['polso'].append(nm)
    c = giro(z, 0.31, 75, 75, k=2)[0]
    sph('nocca_d%d' % i, 'guanto', c, (0.13, 0.11, 0.1), seg=14); EX['polso'].append('nocca_d%d' % i)
sweep('pollice_d', 'guanto', giro(g.z + 0.43, 0.2, -70, 150, dz=-0.12), [0.15, 0.145, 0.14, 0.13, 0.12, 0.11, 0.09], seg=12, n=5); EX['polso'].append('pollice_d')

# ---- head
T = bpy.data.objects.new('Testa', None); col.objects.link(T); T.parent = ROOT
sph('testa', 'pelle', (0, -0.18, 3.62), (0.58, 0.57, 0.6), T)
sph('arcata', 'pelle', (0, -0.6, 3.8), (0.5, 0.2, 0.11), T)
for sx in (-1, 1): sph('guancia_%d' % sx, 'pelle', (0.33 * sx, -0.6, 3.5), (0.21, 0.18, 0.17), T)
sph('mascella', 'pelle', (0, -0.3, 3.36), (0.52, 0.46, 0.36), T)
sph('naso', 'pelle', (0, -0.8, 3.52), (0.2, 0.2, 0.17), T)
sph('mento_barba', 'baffi', (0, -0.6, 3.08), (0.27, 0.19, 0.3), T)
for sx in (-1, 1):
    sweep('baffo_%d' % sx, 'baffi', [(0.04 * sx, -0.76, 3.4), (0.38 * sx, -0.84, 3.2), (0.8 * sx, -0.72, 3.02), (1.1 * sx, -0.58, 3.06),
                                    (1.22 * sx, -0.52, 3.28), (1.08 * sx, -0.52, 3.42), (0.98 * sx, -0.52, 3.3)],
          [0.13, 0.2, 0.19, 0.14, 0.09, 0.06, 0.03], T)
    sweep('sopracciglio_%d' % sx, 'baffi', [(0.07 * sx, -0.74, 3.8), (0.28 * sx, -0.72, 3.9), (0.5 * sx, -0.6, 3.93), (0.68 * sx, -0.46, 3.88)],
          [0.055, 0.105, 0.09, 0.03], T)
    sph('ciuffo_%d' % sx, 'baffi', (0.62 * sx, -0.5, 3.94), (0.12, 0.1, 0.07), T, rot=(0, math.radians(-25 * sx), 0), seg=16)
    tor('base_corno_%d' % sx, 'corno_scuro', (0.36 * sx, -0.1, 3.99), 0.215, 0.045, rot=(0, math.radians(78 * sx), 0), parent=T)
    sph('occhio_%d' % sx, 'occhio', (0.22 * sx, -0.7, 3.68), (0.11, 0.05, 0.07), T)
    sph('pupilla_%d' % sx, 'nero', (0.2 * sx, -0.75, 3.675), (0.035, 0.02, 0.045), T, seg=12)
    cyl('orecchio_%d' % sx, 'pelle', (0.74 * sx, -0.12, 3.64), 0.2, 0.78, rot=(0, math.radians(72 * sx), math.radians(-20 * sx)), parent=T, r2=0.01, scale=(1, 0.42, 1))
    sweep('corno_%d' % sx, 'corno', [(0.3 * sx, -0.1, 3.98), (0.72 * sx, -0.02, 4.06), (1.1 * sx, 0.14, 4.3), (1.2 * sx, 0.24, 4.72),
                                    (0.98 * sx, 0.14, 5.06), (0.76 * sx, -0.06, 5.28), (0.84 * sx, -0.22, 5.5)],
          [0.21, 0.2, 0.17, 0.14, 0.1, 0.06, 0.012], T, seg=18, n=14, ridges=13, m2='corno_scuro')

T.scale = (1.2, 1.2, 1.2); T.location = (0, 0.004, -0.63 + 0.52)   # bigger head, growing from the neck

# ---- chimney on the back
tor('base_comignolo', 'ferro', (0.76, 0.5, 3.36), 0.3, 0.07, rot=(math.radians(-8), math.radians(10), 0)); EX['busto'].append('base_comignolo')
cyl('comignolo', 'ferro', (0.87, 0.59, 3.95), 0.27, 1.45, rot=(math.radians(-8), math.radians(10), 0))
tor('bordo_comignolo', 'ottone', (0.99, 0.69, 4.64), 0.29, 0.06, rot=(math.radians(-8), math.radians(10), 0))

# ---- hammer in the right hand, resting on the ground
MA = bpy.data.objects.new('Martello', None); col.objects.link(MA); MA.parent = ROOT
cyl('manico', 'legno', (-1.75, -0.6, 1.46), 0.105, 2.08, parent=MA)
for k, z in enumerate([0.98 + 0.165 * k for k in range(8)]):
    tor('anello_manico_%d' % k, 'ottone', (-1.75, -0.6, z), 0.1, 0.03, parent=MA)
sph('pomo_manico', 'ottone', (-1.75, -0.6, 2.5), (0.14, 0.14, 0.1), MA)
cyl('testa_martello', 'ferro', (-1.75, -0.6, 0.42), 0.42, 1.0, rot=(0, math.radians(90), 0), parent=MA)
for dx in (-0.4, 0.4):
    cyl('fascia_martello_%d' % (dx > 0), 'ottone', (-1.75 + dx, -0.6, 0.42), 0.455, 0.17, rot=(0, math.radians(90), 0), parent=MA)
    borchie([(-1.75 + dx, -0.6 + 0.46 * math.cos(t), 0.42 + 0.46 * math.sin(t)) for t in [k * math.pi / 4 for k in range(8)]], parent=MA, r=0.045, m='ferro')

MA.location = (-0.7, 0.25, 0)

# ---- anvil in front-left
AN = bpy.data.objects.new('Incudine', None); col.objects.link(AN)
box('incudine_base', 'scuro', (2.9, -0.5, 0.14), (1.0, 0.64, 0.28), parent=AN)
box('incudine_collo', 'scuro', (2.9, -0.5, 0.52), (0.46, 0.42, 0.5), parent=AN)
box('incudine_piano', 'ferro', (2.9, -0.5, 0.93), (1.2, 0.62, 0.34), parent=AN)
cyl('incudine_corno', 'ferro', (3.85, -0.5, 0.95), 0.17, 0.75, rot=(0, math.radians(90), 0), parent=AN, r2=0.02)

# ---- light, world, camera
sun = bpy.data.objects.new('sole', bpy.data.lights.new('sole', 'SUN')); col.objects.link(sun)
sun.data.energy = 3.6; sun.data.angle = 0.02; sun.rotation_euler = (math.radians(55), math.radians(8), math.radians(-35))
w = bpy.data.worlds.new('mondo'); sc.world = w; w.use_nodes = True
w.node_tree.nodes['Background'].inputs[0].default_value = (*lin((245 / 255, 227 / 255, 195 / 255)), 1)
w.node_tree.nodes['Background'].inputs[1].default_value = 1.0
cd = bpy.data.cameras.new('camera'); cd.lens = 80
cam = bpy.data.objects.new('camera', cd); col.objects.link(cam); sc.camera = cam
piv = bpy.data.objects.new('giro', None); col.objects.link(piv); piv.location = (0.5, 0, 2.45)
cam.parent = piv; cam.location = (0, -20, 1.3)
cam.rotation_euler = (math.radians(86.4), 0, 0)
sc.render.engine = 'CYCLES'; sc.cycles.samples = 24; sc.cycles.device = 'CPU'
sc.cycles.transparent_max_bounces = 32; sc.cycles.max_bounces = 3
try:
    sc.view_settings.view_transform = 'Standard'
except TypeError:
    pass
sc.render.resolution_x = 900; sc.render.resolution_y = 900
sc.render.film_transparent = False

sun.data.energy = 2.6
bpy.ops.wm.save_as_mainfile(filepath=S + '/fabbro3d/fabbro_3d_v9_modello.blend')
mode = sys.argv[-1]
if mode == 'foto':
    piv.location = (-0.4, 0, 3.2); sc.render.resolution_x = 1000; sc.render.resolution_y = 1100; sc.cycles.samples = 32
    cd.lens = 70; sc.cycles.transparent_max_bounces = 64
    [setattr(o, 'hide_render', True) for o in bpy.data.objects if o.name.startswith('incudine')]
    for name, ang in (('fronte', 0), ('trequarti_s', -35), ('trequarti_d', 35)):
        piv.rotation_euler = (0, 0, math.radians(ang))
        sc.render.filepath = S + '/fabbro3d/m9_%s.png' % name
        bpy.ops.render.render(write_still=True)

if mode in ('anim', 'animfoto'):
    import random
    R = math.radians
    vl = bpy.context.view_layer; vl.update()

    def vuoto(name, loc, parent):
        e = bpy.data.objects.new(name, None); col.objects.link(e); e.location = loc; e.rotation_mode = 'XYZ'
        e.empty_display_size = 0.2
        vl.update()
        if parent:
            e.parent = parent; e.matrix_parent_inverse = parent.matrix_world.inverted()
        vl.update()
        return e

    def figlio(names, parent):
        for nm in names:
            o = bpy.data.objects[nm]; mw = o.matrix_world.copy()
            o.parent = parent; o.matrix_parent_inverse = parent.matrix_world.inverted(); o.matrix_world = mw
        vl.update()

    for o in bpy.data.objects:
        m_ = o.modifiers.get('china') if o.type == 'MESH' else None
        if m_: m_.thickness = 0.045 if max(o.dimensions) > 0.5 else (0.03 if max(o.dimensions) > 0.22 else 0.014)
    ROOT.rotation_mode = 'XYZ'
    busto = vuoto('busto', (0, 0, 1.45), ROOT)
    figlio(['pancia_corazza', 'petto', 'spallaccio_d', 'spallaccio_s', 'comignolo', 'bordo_comignolo', 'fuoco', 'fuoco_chiaro'], busto)
    # the head turns on the neck, not on the feet
    collo = vuoto('collo', (0, -0.02, 3.62), busto)
    figlio(['Testa'], collo)
    bd = vuoto('braccio_d', (-1.45, 0.02, 3.0), busto)
    figlio(['spalla_d', 'bicipite_d'], bd)
    gd = vuoto('gomito_d', (-1.95, -0.05, 2.1), bd)
    figlio(['avambraccio_d', 'bracciale_d', 'bordo_bracciale_d'], gd)
    polso = vuoto('polso_martello', (-2.45, -0.35, 2.55), gd)
    figlio(['Martello'], polso)
    bs = vuoto('braccio_s', (1.45, 0.02, 3.0), busto)
    figlio(['spalla_s', 'bicipite_s'], bs)
    gs = vuoto('gomito_s', (1.95, -0.05, 2.1), bs)
    figlio(['avambraccio_s', 'bracciale_s', 'bordo_bracciale_s', 'guanto_s'], gs)
    figlio(['bocca_fornace'], busto)
    grata = vuoto('grata', (-0.76, -1.2, 2.02), busto)
    figlio(['cornice_grata', 'sbarra_0', 'sbarra_1', 'sbarra_2', 'sbarra_3', 'cerniera_-1', 'cerniera_1'], grata)
    figlio(['guanto_d'] + EX['polso'], polso); figlio(EX['busto'], busto); figlio(EX['gd'], gd); figlio(EX['gs'], gs); figlio(EX['grata'], grata)
    AN.rotation_mode = 'XYZ'; AN.rotation_euler = (0, 0, math.pi); AN.location = (-0.37, -1.1, 0)
    vl.update()
    tm = bpy.data.objects['testa_martello']
    # absolute angles in the side plane: A upper arm, PHI forearm, TH hammer (0 = hanging, 90 = handle level, head outwards)
    def posa(A, PHI, TH, lean):
        busto.rotation_euler[1] = R(lean); bd.rotation_euler[1] = R(A - lean); gd.rotation_euler[1] = R(PHI - A)
        polso.rotation_euler[1] = R(TH - PHI); vl.update()
    LEAN_I, PHI_I, TH_I = -9.0, -80.0, 90.0
    lo, hi = -30.0, 70.0
    for _ in range(30):
        mid = (lo + hi) / 2; posa(mid, PHI_I, TH_I, LEAN_I)
        if tm.matrix_world.translation.z < 1.10 + 0.5 + 0.035: lo = mid
        else: hi = mid
    A_I = (lo + hi) / 2; posa(A_I, PHI_I, TH_I, LEAN_I); p = tm.matrix_world.translation.copy()
    posa(0, 0, 0, 0); z_terra = tm.matrix_world.translation.z
    # rest: the arm hangs down, the hand low, the hammer leans towards the camera with its head on the ground
    A_R, PHI_R = -19.0, -112.0
    polso.rotation_mode = 'XYZ'
    def riposo(th):
        busto.rotation_euler[1] = 0; bd.rotation_euler[1] = R(A_R); gd.rotation_euler[1] = R(PHI_R - A_R)
        polso.rotation_euler[1] = R(-PHI_R); polso.rotation_euler[0] = R(th); vl.update()
    lo, hi = -90.0, 0.0
    for _ in range(30):
        mid = (lo + hi) / 2; riposo(mid)
        if tm.matrix_world.translation.z < z_terra: hi = mid
        else: lo = mid
    RX_R = (lo + hi) / 2; print('RX_R', RX_R)
    polso.rotation_euler[0] = 0; posa(0, 0, 0, 0)
    # the anvil face right under the hammer face
    AN.location.x += p.x - (-3.27); AN.location.y += p.y - (-0.6); vl.update()
    perno_an = vuoto('incudine_perno', (p.x, p.y, 0), None)
    figlio(['Incudine'], perno_an)
    COLPO = Vector((p.x, p.y - 0.36, 1.1))
    print('A_I', A_I, p)

    # ---- fire: dark embers at the back, flame tongues in front
    brace = mat('brace', (214, 70, 18), True)
    f0 = bpy.data.objects['fuoco']; f0.data.materials.clear(); f0.data.materials.append(brace)
    f1 = bpy.data.objects['fuoco_chiaro']; f1.data.materials.clear(); f1.data.materials.append(M['fuoco'])
    random.seed(7)
    lingue = []
    def lingua(nm, m, x, y, z, r, h):
        o = cyl(nm, m, (x, y, z), r, h, r2=0.008, scale=(1, 0.32, 1))
        for v in o.data.vertices: v.co.z += h / 2
        o.rotation_mode = 'XYZ'
        figlio([nm], busto)
        lingue.append((o, tuple(o.scale), random.uniform(0, 6.28), random.uniform(0.7, 1.3)))
    for i, x in enumerate((-0.36, -0.18, 0.0, 0.18, 0.36)):
        lingua('fiamma_%d' % i, 'fuoco', x * 1.2, -1.045, 1.5, 0.17, (0.6, 0.8, 0.7, 0.86, 0.58)[i])
    for i, x in enumerate((-0.24, 0.02, 0.26)):
        lingua('fiamma_chiara_%d' % i, 'fuoco2', x * 1.3, -1.055, 1.5, 0.1, (0.46, 0.56, 0.44)[i])

    # the item: an icon plane inside the furnace
    img = bpy.data.images.load('/home/user/megablast/art/WB-043/ritagli/ic_fabbro_elmo_base.png')
    me = bpy.data.meshes.new('oggetto'); h = 0.5
    me.from_pydata([(-h, 0, -h), (h, 0, -h), (h, 0, h), (-h, 0, h)], [], [(0, 1, 2, 3)])
    uv = me.uv_layers.new()
    for i, c in enumerate([(0, 0), (1, 0), (1, 1), (0, 1)]): uv.data[i].uv = c
    mo = bpy.data.materials.new('oggetto'); mo.use_nodes = True; nt = mo.node_tree; nt.nodes.clear()
    o_ = nt.nodes.new('ShaderNodeOutputMaterial'); mx = nt.nodes.new('ShaderNodeMixShader'); tr = nt.nodes.new('ShaderNodeBsdfTransparent')
    em = nt.nodes.new('ShaderNodeEmission'); tx = nt.nodes.new('ShaderNodeTexImage'); tx.image = img
    nt.links.new(tx.outputs['Alpha'], mx.inputs[0]); nt.links.new(tr.outputs[0], mx.inputs[1]); nt.links.new(tx.outputs['Color'], em.inputs[0])
    nt.links.new(em.outputs[0], mx.inputs[2]); nt.links.new(mx.outputs[0], o_.inputs[0])
    me.materials.append(mo)
    ogg = bpy.data.objects.new('oggetto', me); col.objects.link(ogg); ogg.rotation_mode = 'XYZ'

    random.seed(4)
    scint = []
    for i in range(10):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.06, location=COLPO)
        s_ = bpy.context.object; s_.name = 'scintilla_%d' % i; s_.data.materials.append(M['fuoco2' if i % 2 else 'fuoco']); s_.scale = (0, 0, 0)
        scint.append((s_, random.uniform(-1, 1), random.uniform(0.4, 1.0), random.uniform(-0.6, -0.1)))
    fumi = []
    for i in range(3):
        f_ = sph('sbuffo_%d' % i, 'fumo', (1.02, 0.72, 4.85), (0.2, 0.2, 0.2), busto); f_.scale = (0, 0, 0); fumi.append(f_)

    def K(o, f, **kw):
        for k_, v in kw.items():
            if k_ == 'rx': o.rotation_euler[0] = R(v); o.keyframe_insert('rotation_euler', index=0, frame=f)
            elif k_ == 'ry': o.rotation_euler[1] = R(v); o.keyframe_insert('rotation_euler', index=1, frame=f)
            elif k_ == 'rz': o.rotation_euler[2] = R(v); o.keyframe_insert('rotation_euler', index=2, frame=f)
            elif k_ == 'loc': o.location = v; o.keyframe_insert('location', frame=f)
            elif k_ == 'sc':
                o.scale = v if isinstance(v, tuple) else (v, v, v); o.keyframe_insert('scale', frame=f)

    H = collo   # head: rx = nod towards the camera, rz = turn (negative = towards the anvil)
    base_cam = cam.location.copy()
    IMP = [68, 96, 124]
    FR, FC = 29, 52   # the hammer leaves the hand / comes back to it
    ed = bpy.context.preferences.edit

    def P(f, A, PHI, TH, lean, lin=False):
        ed.keyframe_new_interpolation_type = 'LINEAR' if lin else 'BEZIER'
        K(busto, f, ry=lean); K(bd, f, ry=A - lean); K(gd, f, ry=PHI - A); K(polso, f, ry=TH - PHI)
        ed.keyframe_new_interpolation_type = 'BEZIER'

    def mix(a, b, t): return a + (b - a) * t
    A_T, PHI_T, TH_T = 92.0, 50.0, 202.0
    P(0, A_R, PHI_R, 0, 0); P(9, A_R, PHI_R, 0, 0)
    K(polso, 0, rx=RX_R); K(polso, 9, rx=RX_R); K(polso, 13, rx=RX_R); K(polso, 17, rx=RX_R * 0.55); K(polso, 21, rx=0)
    K(busto, 0, rx=0); K(H, 0, rx=0, rz=0); K(ROOT, 0, sc=1.0); K(perno_an, 0, sc=1.0)
    K(bs, 0, rx=0, ry=0); K(gs, 0, rx=0, ry=0); K(grata, 0, rz=0); K(cam, 0, loc=tuple(base_cam))
    K(H, 8, rx=0, rz=0); K(H, 16, rx=4, rz=-22)
    for n, I in enumerate(IMP):
        forza = 1 + 0.15 * n
        s0 = 10 if n == 0 else IMP[n - 1] + 10
        if n == 0:
            P(13, A_R - 3, PHI_R - 3, 0, -3)   # a small dip before lifting
        # lift: the arm goes first, the heavy head trails behind, then hangs over the shoulder
        if n == 0:   # lift it off the ground, wind up, toss it spinning, wait, catch it high
            P(21, 28, 8, 4, 0)
            P(25, 8, -14, -24, -7)
            P(FR - 1, 62, 22, 96, 2, lin=True); P(FR, 82, 44, 128, 5, lin=True)
            P(FR + 3, 104, 78, 150, 7); P(FR + 9, 84, 52, 120, 3); P(FC - 7, 70, 36, 110, 0)
            P(FC - 2, 88, 30, 146, 3); P(FC, 92, 38, 152, 4)
            P(FC + 3, 78, 34, 126, -4); P(FC + 6, 86, 40, 140, 0)
            K(H, 25, rx=6, rz=-18); K(H, FR + 3, rx=-16, rz=-10); K(H, FC - 8, rx=-20, rz=-8); K(H, FC, rx=-12, rz=-14); K(H, FC + 3, rx=4, rz=-20)
            K(ROOT, 21, sc=1.0); K(ROOT, 25, sc=(1.035, 1.035, 0.955)); K(ROOT, FR, sc=(0.97, 0.97, 1.05)); K(ROOT, FR + 5, sc=1.0)
            K(ROOT, FC - 1, sc=1.0); K(ROOT, FC + 3, sc=(1.035, 1.035, 0.96)); K(ROOT, FC + 7, sc=1.0)
            K(bs, 21, ry=0); K(bs, 25, ry=6); K(bs, FR + 2, ry=-16); K(bs, FC - 6, ry=-8); K(bs, FC + 3, ry=4)
        else:
            P(I - 11, mix(A_I, A_T, 0.62), mix(PHI_I, PHI_T, 0.45), 118, 1)
        P(I - 7, A_T, PHI_T - 12, TH_T - 42, 5)
        P(I - 4, A_T + 4 * forza, PHI_T + 6, TH_T + 8 * forza, 7, lin=True)
        # fall: speeding up, the head whips last and lands flat
        P(I - 2, mix(A_T, A_I, 0.4), mix(PHI_T, PHI_I, 0.35), mix(TH_T, TH_I, 0.2), 1, lin=True)
        P(I - 1, mix(A_T, A_I, 0.75), mix(PHI_T, PHI_I, 0.7), mix(TH_T, TH_I, 0.58), -5, lin=True)
        P(I, A_I, PHI_I, TH_I, LEAN_I, lin=True)
        P(I + 1, A_I, PHI_I, TH_I, LEAN_I)
        # the head bounces off the iron
        P(I + 4, A_I + 3, PHI_I + 4, TH_I + 13 * forza, LEAN_I + 2)
        P(I + 7, A_I, PHI_I, TH_I, LEAN_I)
        P(I + 9, A_I + 1, PHI_I + 1, TH_I + 4, LEAN_I)
        P(I + 10, A_I, PHI_I, TH_I, LEAN_I)
        K(H, I - 6, rx=-9, rz=-22); K(H, I + 1, rx=11, rz=-22); K(H, I + 7, rx=3, rz=-22)
        K(bs, I - 6, ry=-10); K(bs, I + 1, ry=5); K(bs, I + 8, ry=0)
        K(ROOT, I - 5, sc=(0.985, 0.985, 1.03)); K(ROOT, I - 1, sc=1.0)
        K(ROOT, I + 1, sc=(1.02, 1.02, 0.975)); K(ROOT, I + 6, sc=1.0)
        K(perno_an, I - 1, sc=1.0); K(perno_an, I + 1, sc=(1.05, 1.05, 0.93)); K(perno_an, I + 5, sc=1.0)
        for j, (dx, dz) in enumerate([(0, 0), (0.035, -0.05), (-0.03, 0.035), (0.02, -0.02), (0, 0)]):
            K(cam, I - 1 + j, loc=(base_cam.x + dx * forza, base_cam.y, base_cam.z + dz * forza))
        for s_, dx, up, dy in scint:
            K(s_, I - 1, loc=tuple(COLPO), sc=0.0); K(s_, I, loc=(COLPO.x + dx * 0.45, COLPO.y, COLPO.z), sc=0.9 * forza)
            K(s_, I + 5, loc=(COLPO.x + dx * 1.1 * forza, COLPO.y + dy, COLPO.z + up * 1.3 * forza), sc=1.0)
            K(s_, I + 11, loc=(COLPO.x + dx * 1.9 * forza, COLPO.y + dy * 1.5, COLPO.z + up * 0.5), sc=0.0)
        f_ = fumi[n]
        K(f_, I, loc=tuple(f_.location), sc=0.0)
        l0 = f_.location.copy()
        K(f_, I + 4, loc=(l0.x + 0.05, l0.y, l0.z + 0.3), sc=0.24); K(f_, I + 16, loc=(l0.x + 0.2, l0.y, l0.z + 0.85), sc=0.36)
        K(f_, I + 26, loc=(l0.x + 0.3, l0.y, l0.z + 1.3), sc=0.0)
    L = IMP[-1]
    FINE = L + 84
    # ---- the toss: a free copy of the hammer flies between FR and FC, spinning twice around its heavy head
    def discendenti(o):
        out = [o]
        for c in o.children: out += discendenti(c)
        return out
    MAo = bpy.data.objects['Martello']; fissi = discendenti(MAo)
    sc.frame_set(FR); vl.update(); M_r = MAo.matrix_world.copy(); c_r = tm.matrix_world.translation.copy()
    sc.frame_set(FC); vl.update(); M_c = MAo.matrix_world.copy(); c_c = tm.matrix_world.translation.copy()
    loc_c = M_r.inverted() @ c_r    # heavy point, in hammer space
    volo = {}
    for o in fissi:
        n_ = o.copy(); n_.name = o.name + '_volo'; col.objects.link(n_); volo[o.name] = n_
    for o in fissi[1:]:
        volo[o.name].parent = volo[o.parent.name]; volo[o.name].matrix_parent_inverse = o.matrix_parent_inverse.copy()
    MV = volo['Martello']; MV.parent = None; MV.animation_data_clear(); MV.rotation_mode = 'QUATERNION'
    q_r = M_r.to_quaternion(); q_c = M_c.to_quaternion(); dq = q_c @ q_r.inverted()
    ang = 2 * math.atan2(dq.y, dq.w)
    while ang < 0: ang += 2 * math.pi
    tot = ang + 2 * math.pi if ang < math.pi else ang   # one turn
    print('volo', ang, c_r, c_c)
    from mathutils import Quaternion
    ALTO = 2.3; prev = None
    for f in range(FR, FC + 1):
        t = (f - FR) / (FC - FR)
        com = c_r.lerp(c_c, t); com.z += 4 * ALTO * t * (1 - t)
        q = Quaternion((0, 1, 0), tot * t) @ q_r
        if prev is not None and q.dot(prev) < 0: q.negate()
        prev = q.copy()
        MV.rotation_quaternion = q; MV.location = com - q @ loc_c; MV.scale = M_r.to_scale()
        MV.keyframe_insert('rotation_quaternion', frame=f); MV.keyframe_insert('location', frame=f)
    def vedi(objs, f, nascosto):
        for o in objs:
            o.hide_render = nascosto; o.hide_viewport = nascosto
            o.keyframe_insert('hide_render', frame=f); o.keyframe_insert('hide_viewport', frame=f)
    vedi(fissi, 0, False); vedi(fissi, FR + 1, True); vedi(fissi, FC, False)
    vedi(list(volo.values()), 0, True); vedi(list(volo.values()), FR + 1, False); vedi(list(volo.values()), FC, True)
    # after the last blow he puts the hammer down and stands straight
    P(L + 12, A_I, PHI_I, TH_I, LEAN_I); P(L + 17, 45, -60, 70, -3); P(L + 22, 25, -15, 15, 0); P(L + 30, A_R, PHI_R, 0, 0)
    K(polso, L + 22, rx=0); K(polso, L + 30, rx=RX_R)
    K(busto, L + 10, rx=0); K(busto, L + 20, rx=0)
    K(H, L + 10, rx=3, rz=-22); K(H, L + 20, rx=6, rz=0)
    # the belly swells, the grate bursts open, the item jumps out to the free hand held out in front
    K(ROOT, L + 16, sc=1.0); K(ROOT, L + 23, sc=(1.04, 1.04, 0.97)); K(ROOT, L + 27, sc=(0.975, 0.975, 1.035)); K(ROOT, L + 33, sc=1.0)
    K(busto, L + 23, rx=4); K(busto, L + 27, rx=-6); K(busto, L + 36, rx=0)
    K(grata, L + 23, rz=0); K(grata, L + 25, rz=6); K(grata, L + 30, rz=-135); K(grata, L + 34, rz=-112); K(grata, L + 38, rz=-122)
    K(H, L + 27, rx=-8, rz=0); K(H, L + 42, rx=9, rz=24); K(H, FINE - 12, rx=9, rz=24); K(H, FINE, rx=0, rz=0)
    # free arm: forward (towards the camera), forearm level, palm up
    K(bs, L + 24, rx=0, ry=0); K(gs, L + 24, rx=0, ry=0)
    K(bs, L + 38, rx=-26, ry=-13); K(gs, L + 40, rx=-72, ry=0)
    K(gs, L + 45, rx=-54); K(bs, L + 45, rx=-20); K(gs, L + 50, rx=-62); K(bs, L + 50, rx=-24)
    sc.frame_set(L + 50); vl.update()
    mano = bpy.data.objects['guanto_s'].matrix_world.translation.copy()
    print('mano', mano)
    arrivo = (mano.x + 0.03, mano.y - 0.18, mano.z + 0.8)
    dentro = (0, -0.75, 2.05)
    K(ogg, 0, loc=dentro, sc=0.0, ry=0); K(ogg, L + 26, loc=dentro, sc=0.0, ry=0)
    K(ogg, L + 29, loc=(0.1, -1.5, 2.4), sc=0.9); K(ogg, L + 36, loc=(arrivo[0] * 0.8, -1.8, 4.7), sc=1.4, ry=-200)
    K(ogg, L + 44, loc=(arrivo[0], arrivo[1], arrivo[2] - 0.12), sc=(1.7, 1.4, 1.15), ry=-360)
    K(ogg, L + 48, loc=(arrivo[0], arrivo[1], arrivo[2] + 0.08), sc=(1.3, 1.4, 1.6)); K(ogg, L + 53, loc=arrivo, sc=1.45)
    K(ogg, L + 65, loc=(arrivo[0], arrivo[1], arrivo[2] + 0.06)); K(ogg, FINE, loc=arrivo)
    K(grata, L + 62, rz=-122); K(grata, L + 72, rz=4); K(grata, L + 75, rz=0)
    # flames flicker all the time, leap out when the grate opens
    for o, s0, fase, vel in lingue:
        for f in range(0, FINE + 1, 3):
            g = 1.0
            for I in IMP:
                if 0 <= f - I < 9: g = 1.25
            if L + 24 <= f <= L + 40: g = 1.55
            elif L + 40 < f <= L + 62: g = 1.3
            k = g * (1 + 0.22 * math.sin(f * 0.9 * vel + fase))
            o.scale = (s0[0] * (1 + 0.1 * math.sin(f * 0.5 + fase)), s0[1], s0[2] * k); o.keyframe_insert('scale', frame=f)
            o.rotation_euler[1] = R(9 * math.sin(f * 0.6 * vel + fase * 2)); o.keyframe_insert('rotation_euler', index=1, frame=f)
    sc.frame_start = 0; sc.frame_end = FINE; sc.render.fps = 30
    piv.location = (-2.1, 0, 4.25); piv.rotation_euler = (0, 0, R(8)); cd.lens = 50
    sc.render.resolution_x = 1000; sc.render.resolution_y = 1000; sc.cycles.samples = 32; sc.cycles.transparent_max_bounces = 64
    bpy.ops.wm.save_as_mainfile(filepath=S + '/fabbro3d/fabbro_3d_martellata_v11.blend')
    if mode == 'animfoto':
        for f in (0, 13, 17, 21, 25, 29, 32, 36, 40, 44, 48, 52, 55, 61, 68, 160):
            sc.frame_set(f); sc.render.filepath = S + '/fabbro3d/af11_%03d.png' % f; bpy.ops.render.render(write_still=True)
    else:
        sc.render.filepath = S + '/fabbro3d/anim11/a_'; bpy.ops.render.render(animation=True)
