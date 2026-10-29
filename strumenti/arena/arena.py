#!/usr/bin/env python3
"""Arena dei bot su tutti i core: lancia arena.lua (luajit) in parallelo, un
processo per core, mette insieme le partite e scrive il rapporto per il
bilanciamento e gli highlight (i turni più rari e spettacolari).

    python3 strumenti/arena/arena.py --partite 400
    python3 strumenti/arena/arena.py --partite 2000 --livello misto --processi 16
    python3 strumenti/arena/arena.py --rapporto simulazione/arena/partite.jsonl   # solo il rapporto
    python3 strumenti/arena/arena.py --video 3       # il video del 3° highlight (simulatore)
    python3 strumenti/arena/arena.py --partite 10000 --cartella simulazione/arena/base   # prove separate

Risultati in simulazione/arena/ (ignorata da git): partite.jsonl (una riga per
partita, con la ricetta per rigiocarla), rapporto.md, highlight.json.
Serve luajit nel PATH (o --luajit percorso). Solo libreria standard di Python.
"""

import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
USCITA = REPO / "simulazione" / "arena"


# Partite in parallelo ------------------------------------------------------------

def gioca(args):
    luajit = args.luajit or shutil.which("luajit")
    if not luajit:
        sys.exit("manca luajit: installalo o passa --luajit percorso")
    USCITA.mkdir(parents=True, exist_ok=True)
    n, p = args.partite, max(1, min(args.processi, args.partite))
    # semi consecutivi divisi in blocchi, uno per processo
    blocchi, da = [], args.da
    for k in range(p):
        q = n // p + (1 if k < n % p else 0)
        blocchi.append((da, q))
        da += q
    extra = []
    for chiave in ("modo", "livello", "mappa", "punteggio", "pesi", "komi", "giro_finale", "serpente", "rotazione", "ritocchi", "set"):
        v = getattr(args, chiave, None)
        if v:
            extra += [f"--{chiave}", str(Path(v).resolve()) if chiave in ("punteggio", "pesi", "ritocchi") else v]
    t0 = time.time()
    processi = []
    for k, (da, q) in enumerate(blocchi):
        parte = USCITA / f"parte_{k}.jsonl"
        cmd = [luajit, "strumenti/arena/arena.lua", "--partite", str(q), "--da", str(da), "--uscita", str(parte)] + extra
        processi.append((subprocess.Popen(cmd, cwd=REPO, stderr=subprocess.PIPE, text=True), parte))
    tutte = USCITA / "partite.jsonl"
    with tutte.open("w") as out:
        for pr, parte in processi:
            _, err = pr.communicate()
            if pr.returncode != 0:
                sys.exit(f"arena.lua fallita:\n{err}")
            out.write(parte.read_text())
            parte.unlink()
    dt = time.time() - t0
    print(f"{n} partite in {dt:.0f} s con {p} processi ({n / dt * 3600:.0f} all'ora)")
    return tutte


# Rapporto ------------------------------------------------------------------------

def leggi(file):
    with open(file) as f:
        return [json.loads(r) for r in f if r.strip()]


def z_vittorie(v, n, p0):
    """Quanto la quota di vittorie v/n si scosta da p0, in deviazioni standard."""
    if n == 0 or p0 <= 0 or p0 >= 1:
        return 0.0
    return (v / n - p0) / math.sqrt(p0 * (1 - p0) / n)


def tabella(titolo, intestazione, righe):
    s = [f"\n## {titolo}\n", "| " + " | ".join(intestazione) + " |", "|" + "---|" * len(intestazione)]
    s += ["| " + " | ".join(str(c) for c in r) + " |" for r in righe]
    return "\n".join(s) + "\n"


def per_scelta(partite, campo):
    """Vittorie, punti e danno per arma scelta (primaria o secondaria), modo per modo."""
    righe, avvisi = [], []
    for modo in ("1v1", "2v2", "ffa"):
        dati = defaultdict(lambda: [0, 0, 0.0, 0.0])
        base = 0.0
        for p in partite:
            if p["modo"] != modo:
                continue
            for r in p["robot"]:
                d = dati[r.get(campo) or "nessuno"]
                d[0] += 1
                d[1] += 1 if r["posto"] == 1 else 0
                d[2] += r["punti"]
                d[3] += r["danno"]
        tot = sum(d[0] for d in dati.values())
        if not tot:
            continue
        p0 = sum(d[1] for d in dati.values()) / tot
        for arma, (n, v, pt, dn) in sorted(dati.items()):
            z = z_vittorie(v, n, p0)
            segno = " ⚠" if abs(z) >= 2 and n >= 30 else ""
            righe.append((modo, arma, n, f"{100 * v / n:.0f}%{segno}", f"{z:+.1f}", f"{pt / n:.0f}", f"{dn / n:.0f}"))
            if segno:
                avvisi.append(f"{modo}: **{arma}** vince il {100 * v / n:.0f}% contro una media del {100 * p0:.0f}% ({n} robot, z {z:+.1f})")
    return righe, avvisi


def rapporto(partite):
    out = [f"# Arena dei bot: rapporto\n\n{len(partite)} partite, "
           + ", ".join(f"{k} {v}" for k, v in sorted(Counter(p['modo'] for p in partite).items()))
           + ", mappe " + ", ".join(f"{k} {v}" for k, v in sorted(Counter(p['mappa'] for p in partite).items())) + ".\n"]
    avvisi = []

    # chi comincia: nel 1 contro 1 vince più spesso?
    uno = [p for p in partite if p["modo"] == "1v1"]
    if uno:
        v1 = sum(1 for p in uno if p["vincitore"] == 1)
        pari = sum(1 for p in uno if p["vincitore"] == 0)
        z = z_vittorie(v1, len(uno) - pari, 0.5)
        out.append(f"\n**Chi gioca per primo (1 contro 1)** vince {v1} partite su {len(uno)} ({pari} pari), z {z:+.1f}.\n")
        if abs(z) >= 2:
            avvisi.append(f"chi gioca per primo nel 1 contro 1 vince {100 * v1 / max(1, len(uno) - pari):.0f}% (z {z:+.1f})")

    scelte = [("secondaria", "Secondarie scelte"), ("primaria", "Primarie scelte (dalla scelta d'inizio partita)")]
    if any(r.get("set") for p in partite for r in p["robot"]):
        scelte.append(("set", "Set completi (--set misto)"))
    for campo, nome in scelte:
        righe, a = per_scelta(partite, campo)
        avvisi += a
        out.append(tabella(nome + ": vittorie, punti e danno medi", ["modo", "arma", "robot", "vittorie", "z", "punti", "danno"], righe))

    # le armi in partita: usi, danno e uccisioni
    uso, danno, ucc = Counter(), Counter(), Counter()
    for p in partite:
        for r in p["robot"]:
            uso.update(r["uso"])
            danno.update(r["danno_arma"])
            ucc.update(r["uccisioni_arma"])
    tot_danno = sum(danno.values()) or 1
    righe = []
    for arma in sorted(set(uso) | set(danno), key=lambda a: -danno[a]):
        u = uso[arma]
        righe.append((arma, u, danno[arma], f"{100 * danno[arma] / tot_danno:.0f}%", f"{danno[arma] / u:.1f}" if u else "-", ucc[arma]))
    out.append(tabella("Armi e oggetti in partita", ["arma", "usi", "danno", "quota", "danno per uso", "uccisioni"], righe))

    # i punti per categoria e per motivo
    cat, mot = Counter(), Counter()
    for p in partite:
        for e in p.get("punti", []):
            if e["punti"] > 0:
                cat[e["cat"]] += e["punti"]
                mot[e["motivo"]] += e["punti"]
    tot = sum(cat.values()) or 1
    out.append(tabella("Punti guadagnati per categoria d'arma", ["categoria", "punti", "quota"],
                       [(k, f"{v:.0f}", f"{100 * v / tot:.0f}%") for k, v in cat.most_common()]))
    out.append(tabella("Punti guadagnati per motivo", ["motivo", "punti", "quota"],
                       [(k, f"{v:.0f}", f"{100 * v / tot:.0f}%") for k, v in mot.most_common()]))

    # mappe
    righe = []
    for mappa in sorted(set(p["mappa"] for p in partite)):
        ps = [p for p in partite if p["mappa"] == mappa]
        rb = [r for p in ps for r in p["robot"]]
        righe.append((mappa, len(ps), f"{sum(r['danno'] for r in rb) / len(ps):.0f}",
                      f"{sum(r['morti'] for r in rb) / len(ps):.1f}", f"{sum(r['cadute'] for r in rb) / len(ps):.1f}",
                      f"{sum(r['teletrasporti'] for r in rb) / len(ps):.1f}"))
    out.append(tabella("Mappe (per partita)", ["mappa", "partite", "danno", "morti", "cadute fuori", "teletrasporti"], righe))

    # livelli dei bot, se mescolati
    liv = defaultdict(lambda: [0, 0])
    for p in partite:
        for r in p["robot"]:
            liv[r["livello"]][0] += 1
            liv[r["livello"]][1] += 1 if r["posto"] == 1 else 0
    if len(liv) > 1:
        out.append(tabella("Livelli dei bot", ["livello", "robot", "vittorie"],
                           [(k, n, f"{100 * v / n:.0f}%") for k, (n, v) in sorted(liv.items())]))

    testa = "\n## Da guardare\n\n" + ("\n".join(f"- {a}" for a in avvisi) if avvisi else "Niente fuori misura (|z| < 2).") + "\n"
    return out[0] + testa + "".join(out[1:])


# Highlight -----------------------------------------------------------------------

def highlight(partite, quanti=10):
    """I turni più spettacolari e più rari: danno, uccisioni (fuori mappa di più),
    combinazioni di mosse, pesati per quanto è rara la loro firma."""
    firme = Counter(t["firma"] for p in partite for t in p["turni"])
    totale = sum(firme.values()) or 1
    scelti = []
    for k, p in enumerate(partite):
        for t in p["turni"]:
            base = t["danno"] / 10 + 8 * t["uccisioni"] + 12 * t["ambientali"] + 3 * max(0, len(t["firma"].split(">")) - 2)
            if base < 8:
                continue
            rarita = math.log(totale / firme[t["firma"]])
            scelti.append({"punteggio": round(base * (1 + rarita / 3), 1), "firma": t["firma"], "volte": firme[t["firma"]],
                           "partita": k, "seme": p["ricetta"]["seme"], "modo": p["modo"], "mappa": p["mappa"],
                           "tick": t["t"], "chi": t["chi"], "danno": t["danno"], "uccisioni": t["uccisioni"]})
    scelti.sort(key=lambda h: -h["punteggio"])
    # al massimo uno per partita, così sono tutti diversi
    out, viste = [], set()
    for h in scelti:
        if h["partita"] not in viste:
            viste.add(h["partita"])
            out.append(h)
        if len(out) >= quanti:
            break
    return out


def video(n, file):
    """Il video dell'highlight n (da 1): il simulatore rigioca la ricetta dal
    turno dell'highlight (megablast.ricetta) e registra lo schermo."""
    hs = json.loads((USCITA / "highlight.json").read_text())
    h = hs[n - 1]
    p = leggi(file)[h["partita"]]
    ricetta = USCITA / f"ricetta_{n}.json"
    ricetta.write_text(json.dumps(p["ricetta"]))
    scenario = USCITA / f"highlight_{n}.txt"
    scenario.write_text(
        f"# highlight {n}: {h['firma']} ({h['modo']}, {h['mappa']}, seme {h['seme']}, tick {h['tick']})\n"
        f"imposta ricetta {ricetta}\nimposta ricetta_da {max(0, h['tick'] - 60)}\nimposta zoom 1\n"
        "aspetta_stato modo=local 20\naspetta 1\nfoto inizio\naspetta 26\nfoto fine\n")
    r = subprocess.run([sys.executable, str(REPO / "strumenti/simula/simula.py"), "-s", str(scenario)], cwd=REPO)
    if r.returncode != 0:
        sys.exit("la simulazione del video è fallita")
    dest = USCITA / f"highlight_{n}.mp4"
    shutil.copy(REPO / "simulazione" / "video.mp4", dest)
    print(f"video: {dest}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--partite", type=int, default=100)
    ap.add_argument("--da", type=int, default=1, help="primo seme")
    ap.add_argument("--processi", type=int, default=os.cpu_count() or 1)
    ap.add_argument("--modo", help="1v1, 2v2, ffa o tutti (a turno)")
    ap.add_argument("--livello", help="facile, normale, difficile o misto")
    ap.add_argument("--mappa")
    ap.add_argument("--punteggio", help="file Lua con una tabella come config.SCORE")
    ap.add_argument("--pesi", help="file Lua con una lista di pesi del bot (bot.PESI), uno a caso per robot")
    ap.add_argument("--ritocchi", help="file Lua: function(config, game) che cambia i numeri delle armi (prova)")
    ap.add_argument("--set", help="misto: ogni robot un set completo a caso (o nessuno)")
    ap.add_argument("--serpente", help="si: a ogni giro l'ordine dei turni si rovescia (prova)")
    ap.add_argument("--rotazione", help="si: a ogni giro apre il secondo del giro prima (prova)")
    ap.add_argument("--komi", help="punti di partenza di chi apre (prova)")
    ap.add_argument("--giro_finale", help="si: un giro in più dopo il tempo, chi è avanti gioca per primo (prova)")
    ap.add_argument("--luajit")
    ap.add_argument("--rapporto", help="solo il rapporto da un partite.jsonl già fatto")
    ap.add_argument("--video", type=int, help="il video dell'highlight N")
    ap.add_argument("--cartella", help="dove scrivere (normale simulazione/arena), per tenere separate più prove")
    args = ap.parse_args()
    global USCITA
    if args.cartella:
        USCITA = Path(args.cartella).resolve()
    if args.video:
        video(args.video, args.rapporto or USCITA / "partite.jsonl")
        return
    file = Path(args.rapporto) if args.rapporto else gioca(args)
    partite = leggi(file)
    USCITA.mkdir(parents=True, exist_ok=True)
    (USCITA / "rapporto.md").write_text(rapporto(partite))
    hs = highlight(partite)
    (USCITA / "highlight.json").write_text(json.dumps(hs, indent=1, ensure_ascii=False))
    print(f"rapporto: {USCITA / 'rapporto.md'}")
    for k, h in enumerate(hs, 1):
        print(f"highlight {k}: {h['firma']} ({h['punteggio']}, visto {h['volte']} volte) seme {h['seme']} tick {h['tick']}")


if __name__ == "__main__":
    main()
