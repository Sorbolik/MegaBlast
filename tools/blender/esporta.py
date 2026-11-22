"""Esporta l'animazione della scena di Blender in un file Lua che il gioco può leggere: per ogni
pezzo i canali x, y, rotazione, scala e trasparenza, nel formato delle clip del diavoletto
(client/battle/pose.lua: { t, valore, curva, ... }, curva 1 = lineare).

    blender --background simulazione/blender/fornace.blend --python tools/blender/esporta.py -- --uscita simulazione/blender/fornace.lua

Si campiona ogni fotogramma (quello che si vede in Blender è quello che si avrà nel gioco,
anche le curve Rimbalzo, Elastico, Indietro del menu di Blender) e si tolgono le chiavi che una
linea dritta rifà a meno di un quarto di pixel: il file resta piccolo e il gioco gira i pezzi
con le sue trasformazioni, a qualunque frequenza (120 FPS compresi).

Ogni pezzo dice la sua immagine (image), il padre, il perno nella vignetta (pivot, pixel con y
in giù), il perno dentro l'immagine (anchor) e la grandezza (size).

Unità: pixel della vignetta, y in su; angoli in radianti, in senso antiorario. Girare un pezzo
sull'asse verticale (lo sportello che si apre) diventa scala_x = cos(angolo): è lo stesso
effetto visto di fronte. Se un pezzo va avanti o indietro (la profondità, Y di Blender) esce il
canale z: si disegna in ordine di depth + z (davanti chi ha il numero più alto). I pezzi con la proprietà "segnaposto" escono con segnaposto = true.
"""
import math
import os
import sys

import bpy

PX = 0.01
TOLLERANZA = {"z": 0.25, "x": 0.25, "y": 0.25, "rot": 0.003, "scale_x": 0.003, "scale_y": 0.003, "alpha": 0.004}
NEUTRO = {"z": 0, "x": 0, "y": 0, "rot": 0, "scale_x": 1, "scale_y": 1, "alpha": 1}


def argomenti():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    return {a[i][2:]: a[i + 1] for i in range(len(a) - 1) if a[i].startswith("--")}


def semplifica(punti, toll):
    """Ramer-Douglas-Peucker sui punti (t, v): tiene le chiavi che servono alla linea."""
    if len(punti) <= 2:
        return punti
    (t0, v0), (t1, v1) = punti[0], punti[-1]
    peggio, i_peggio = -1, 0
    for i in range(1, len(punti) - 1):
        t, v = punti[i]
        atteso = v0 + (v1 - v0) * (t - t0) / (t1 - t0) if t1 != t0 else v0
        d = abs(v - atteso)
        if d > peggio:
            peggio, i_peggio = d, i
    if peggio <= toll:
        return [punti[0], punti[-1]]
    a = semplifica(punti[:i_peggio + 1], toll)
    return a[:-1] + semplifica(punti[i_peggio:], toll)


def numero(v):
    s = ("%.4f" % v).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def esporta(uscita):
    sc = bpy.context.scene
    fps = sc.render.fps / sc.render.fps_base
    pezzi = [o for o in sc.objects if o.type == "MESH" and o.visible_get()]
    pezzi.sort(key=lambda o: (-o.matrix_world.translation.y, o.name))   # dal fondo
    riposo, profondita = {}, {}
    sc.frame_set(sc.frame_start)
    for o in pezzi:
        riposo[o.name] = tuple(o.get("riposo", tuple(o.location)))
        profondita[o.name] = -(o.matrix_world.translation.y - o.location.y + riposo[o.name][1]) / PX
    serie = {o.name: {k: [] for k in NEUTRO} for o in pezzi}
    for f in range(sc.frame_start, sc.frame_end + 1):
        sc.frame_set(f)
        t = (f - sc.frame_start) / fps
        for o in pezzi:
            r = riposo[o.name]
            sr = o.get("scala_riposo", 1.0)
            rx, ry, rz = o.rotation_euler
            v = {
                "z": (r[1] - o.location.y) / PX,
                "x": (o.location.x - r[0]) / PX,
                "y": (o.location.z - r[2]) / PX,
                "rot": -ry,
                "scale_x": o.scale.x / sr * math.cos(rz),
                "scale_y": o.scale.z / sr * math.cos(rx),
                "alpha": o.color[3],
            }
            for k, x in v.items():
                serie[o.name][k].append((t, x))
    righe = ["-- Written by tools/blender/esporta.py from %s: don't edit by hand, change the"
             % os.path.basename(bpy.data.filepath or "la scena"),
             "-- scene in Blender and export again. Units: drawing pixels, y up, radians counterclockwise.",
             "return {",
             "\tduration = %s, loop = false," % numero((sc.frame_end - sc.frame_start) / fps),
             "\tpieces = {   -- from the back"]
    for o in pezzi:
        img = None
        for slot in o.material_slots:
            if slot.material and slot.material.node_tree:
                for n in slot.material.node_tree.nodes:
                    if n.type == "TEX_IMAGE" and n.image:
                        img = os.path.basename(n.image.filepath)
        perno = o.get("perno_px")
        campi = ['name = "%s"' % o.name]
        if img:
            campi.append('image = "%s"' % img)
        if o.parent:
            campi.append('parent = "%s"' % o.parent.name)
        if perno:
            campi.append("pivot = { %s, %s }" % (numero(perno[0]), numero(perno[1])))
        xs = [v.co.x for v in o.data.vertices]
        zs = [v.co.z for v in o.data.vertices]
        campi.append("depth = %s" % numero(profondita[o.name]))
        campi.append("anchor = { %s, %s }" % (numero(-min(xs) / PX), numero(max(zs) / PX)))
        campi.append("size = { %s, %s }" % (numero((max(xs) - min(xs)) / PX), numero((max(zs) - min(zs)) / PX)))
        if "scala_riposo" in o:
            campi.append("scale = %s" % numero(o["scala_riposo"]))
        if "segnaposto" in o:
            campi.append("placeholder = true")
        righe.append("\t\t{ " + ", ".join(campi) + " },")
    righe += ["\t},", "\ttracks = {"]
    chiavi = 0
    for o in pezzi:
        for k, punti in serie[o.name].items():
            if all(abs(v - NEUTRO[k]) <= TOLLERANZA[k] for _, v in punti):
                continue
            tenuti = semplifica(punti, TOLLERANZA[k])
            chiavi += len(tenuti)
            valori = ", ".join("%s, %s, 1" % (numero(t), numero(v)) for t, v in tenuti)
            righe.append("\t\t%s_%s = { %s }," % (o.name, k, valori))
    righe += ["\t},", "}", ""]
    os.makedirs(os.path.dirname(os.path.abspath(uscita)), exist_ok=True)
    open(uscita, "w", encoding="utf-8").write("\n".join(righe))
    print("esportato %s: %d pezzi, %d chiavi" % (uscita, len(pezzi), chiavi))


if __name__ == "__main__":
    esporta(argomenti().get("uscita", "simulazione/blender/fornace.lua"))
