#!/usr/bin/env python3
"""Maestro e allievo: il bot impara da chi gioca le mosse fino in fondo.

Un altro modo di allenare i bot, non più numeri a caso giudicati sulle partite
intere (evolvi.py: il caso delle partite copre differenze di qualche punto).
Ogni ciclo, per la notte sul PC di Sergio:

1. Il Maestro (tools/arena/maestro.lua) gioca contro il bot di oggi: per le
   mosse migliori che il bot trova gioca avanti il resto del giro più volte
   (rollout) e prende quella che rende di più. Le sue vittorie dicono quanto
   rende pensare meglio (il tetto di bravura, mappa per mappa).
2. L'allievo impara dalle scelte del Maestro una correzione della posizione
   dopo la mossa, per l'attacco (pesi.correzione) e per il riparo
   (pesi.riparo): venti numeri ciascuna, sulle caratteristiche di
   bot.caratteristiche (regressione ridge dentro ogni scelta: cosa distingue
   la mossa che il Maestro ha visto rendere di più dalle altre).
3. Esame: l'allievo (il bot del gioco con la correzione, niente rollout)
   contro il bot di oggi a coppie. Se batte il miglior allievo finora diventa
   il nuovo, e il ciclo dopo il Maestro usa lui per scegliere le candidate e
   per giocare avanti: impara da un maestro che migliora (expert iteration).

   python tools/arena/maestro.py                      # cicli senza fine (Ctrl+C, riparte da dov'era)
   python tools/arena/maestro.py --cicli 1 --partite 32 --esame 96   # una prova breve
   python tools/arena/maestro.py --solo-esame allievo.lua           # esamina un file di pesi
   python tools/arena/maestro.py --nuova                             # da capo

Esce simulazione/arena/maestro/: maestro.md (il rapporto), stato.json,
migliore.lua (il miglior allievo: pesi.correzione e pesi.riparo da dare al bot),
ciclo_N/ con partite, scelte ed esami. Serve numpy e luajit.
"""
import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parents[2]
NF = 20  # bot.CARATTERISTICHE


def luajit(args):
    return args.luajit or shutil.which("luajit") or "luajit"


def lancia(args, uscita, partite, extra, dati=False):
    """Gioca le partite 0..partite-1 su tutti i processi (a coppie intere) e unisce i file."""
    uscita.mkdir(parents=True, exist_ok=True)
    proc = max(1, args.processi)
    coppie = partite // 2
    per = [coppie // proc + (1 if i < coppie % proc else 0) for i in range(proc)]
    procs, pezzi, da = [], [], 0
    for i, n in enumerate(per):
        if n == 0:
            continue
        f = uscita / f"partite_{i}.jsonl"
        d = uscita / f"scelte_{i}.jsonl"
        cmd = [luajit(args), "tools/arena/maestro.lua", "--partite", str(2 * n), "--da", str(da),
               "--uscita", str(f)] + extra
        if dati:
            cmd += ["--dati", str(d)]
        procs.append(subprocess.Popen(cmd, cwd=REPO))
        pezzi.append((f, d))
        da += 2 * n
    for p in procs:
        if p.wait() != 0:
            raise SystemExit("maestro.lua è uscito con un errore")
    righe, scelte = [], []
    for f, d in pezzi:
        righe += [json.loads(r) for r in f.read_text(encoding="utf-8").splitlines() if r.strip()]
        f.unlink()
        if dati and d.exists():
            scelte += [json.loads(r) for r in d.read_text(encoding="utf-8").splitlines() if r.strip()]
            d.unlink()
    righe.sort(key=lambda r: r["numero"])
    with open(uscita / "partite.jsonl", "w", encoding="utf-8") as fo:
        for r in righe:
            fo.write(json.dumps(r) + "\n")
    if dati:
        with open(uscita / "scelte.jsonl", "w", encoding="utf-8") as fo:
            for s in scelte:
                fo.write(json.dumps(s) + "\n")
    return righe, scelte


def esito(righe):
    """Vittorie della squadra provata (pareggi a metà), errore standard sulle coppie, margine medio."""
    if not righe:
        return {"partite": 0}
    v = [1.0 if r["vincitore"] == r["squadra_maestro"] else 0.5 if r["vincitore"] == 0 else 0.0 for r in righe]
    m = [r["margine"] for r in righe]
    coppie = {}
    for r, x, y in zip(righe, v, m):
        c = coppie.setdefault(r["numero"] // 2, [0, 0, 0])
        c[0] += x
        c[1] += y
        c[2] += 1
    pv = [c[0] / c[2] for c in coppie.values()]
    se = float(np.std(pv) / math.sqrt(len(pv))) if len(pv) > 1 else 0.5
    mappe = {}
    for r, x in zip(righe, v):
        a = mappe.setdefault(r["mappa"], [0, 0])
        a[0] += x
        a[1] += 1
    return {"partite": len(righe), "vittorie": float(np.mean(v)), "errore": se, "margine": float(np.mean(m)),
            "mappe": {k: [a[0] / a[1], a[1]] for k, a in sorted(mappe.items())},
            "secondi": float(np.mean([r["secondi"] for r in righe]))}


def impara(scelte, lam, tipo, peso_vecchie=None):
    """Correzione c tale che punti + c·x somigli a q dentro ogni scelta (ridge sugli scarti dalla media)."""
    X, Y, W = [], [], []
    for s in scelte:
        if s["tipo"] != tipo:
            continue
        q, p, xs = s["q"], s["punti"], s["x"]
        ok = [k for k in range(len(q)) if k < len(xs) and xs[k] and len(xs[k]) == NF]
        if len(ok) < 2:
            continue
        y = np.array([q[k] - p[k] for k in ok], dtype=float)
        x = np.array([xs[k] for k in ok], dtype=float)
        y = np.clip(y - y.mean(), -300, 300)
        x = x - x.mean(axis=0)
        X.append(x)
        Y.append(y)
        W.append(np.full(len(ok), s.get("_peso", 1.0)))
    if not X:
        return None, 0
    X, Y, W = np.vstack(X), np.concatenate(Y), np.concatenate(W)
    # le caratteristiche in scala (deviazione standard 1), poi ridge
    sd = X.std(axis=0)
    sd[sd < 1e-6] = 1.0
    Xs = X / sd
    A = (Xs * W[:, None]).T @ Xs + lam * np.eye(NF)
    b = (Xs * W[:, None]).T @ Y
    c = np.linalg.solve(A, b) / sd
    return c, len(Y)


def scrivi_pesi(path, corr, rip):
    righe = ["-- l'allievo del Maestro (tools/arena/maestro.py): si aggiunge a bot.PESI", "return {"]
    if corr is not None:
        righe.append("\tcorrezione = { " + ", ".join(f"{v:.5f}" for v in corr) + " },")
    if rip is not None:
        righe.append("\triparo = { " + ", ".join(f"{v:.5f}" for v in rip) + " },")
    righe.append("}")
    Path(path).write_text("\n".join(righe) + "\n", encoding="utf-8")


NOMI = ["punti miei", "punti compagno", "punti nemici", "vita persa mia", "vita persa compagno",
        "vita persa nemici", "muoio", "muore il compagno", "muoiono nemici", "vita dopo", "nemico più vicino",
        "distanza media nemici", "nemici più in basso", "bordo del vuoto", "nemici a tiro di mischia",
        "nemici che mi vedono", "distanza dal bordo della mappa", "altezza", "vantaggio squadra", "tempo rimasto"]


def pct(x):
    return f"{100 * x:.1f}%"


def rapporto(cartella, stato):
    r = ["# Maestro e allievo", "",
         "Il Maestro sceglie fra le mosse migliori del bot giocandole avanti più volte; l'allievo è il bot del",
         "gioco con la correzione imparata dalle scelte del Maestro. Tutti contro il bot di oggi "
         f"(grado {stato['grado']}, {stato['modo']}), a coppie; ± è l'errore standard.", ""]
    b = stato.get("base")
    if b:
        r += [f"Base (bot di oggi contro sé stesso, deve fare 50%): {pct(b['vittorie'])} ± {pct(b['errore'])} su {b['partite']}", ""]
    r += ["| ciclo | Maestro | partite | margine | allievo all'esame | partite | margine | scelte imparate | tenuto |",
          "|---|---|---|---|---|---|---|---|---|"]
    for c in stato["cicli"]:
        m, e = c.get("maestro", {}), c.get("esame", {})
        r.append(f"| {c['n']} | {pct(m.get('vittorie', 0))} ± {pct(m.get('errore', 0))} | {m.get('partite', 0)} | "
                 f"{m.get('margine', 0):+.0f} | {pct(e.get('vittorie', 0))} ± {pct(e.get('errore', 0))} | {e.get('partite', 0)} | "
                 f"{e.get('margine', 0):+.0f} | {c.get('esempi', 0)} | {'sì' if c.get('tenuto') else 'no'} |")
    # il tetto di bravura mappa per mappa: tutte le partite del Maestro insieme
    mappe = {}
    for c in stato["cicli"]:
        for k, (v, n) in c.get("maestro", {}).get("mappe", {}).items():
            a = mappe.setdefault(k, [0, 0])
            a[0] += v * n
            a[1] += n
    if mappe:
        r += ["", "## Quanto rende pensare meglio, mappa per mappa", "",
              "Vittorie del Maestro contro il bot di oggi, tutti i cicli insieme. Dove resta vicino al 50%",
              "giocare meglio non conta: decide il caso (utile al thread delle meccaniche).", "",
              "| mappa | Maestro | partite |", "|---|---|---|"]
        for k, (s, n) in sorted(mappe.items(), key=lambda kv: -kv[1][0] / kv[1][1]):
            r.append(f"| {k} | {pct(s / n)} | {n} |")
    fr = stato.get("frontiera")
    if fr:
        r += ["", "## La frontiera: quanto resta forte spendendo meno", "",
              "Secondi di calcolo a scelta su un core del PC (il bot di oggi ne usa qualche centesimo).", "",
              "| prova | Maestro | partite | margine | secondi a scelta |", "|---|---|---|---|---|"]
        for nome, e in fr.items():
            r.append(f"| {nome} | {pct(e['vittorie'])} ± {pct(e['errore'])} | {e['partite']} | {e['margine']:+.0f} | "
                     f"{e['secondi_scelta']:.1f} |")
    mig = stato.get("migliore")
    if mig:
        r += ["", f"## Il miglior allievo (ciclo {mig['ciclo']}, {pct(mig['vittorie'])} all'esame)", "",
              "Quanto conta ogni caratteristica della posizione dopo la mossa, in punti partita per una unità:", "",
              "| caratteristica | attacco | riparo |", "|---|---|---|"]
        for k in range(NF):
            a = mig["correzione"][k] if mig.get("correzione") else 0
            b2 = mig["riparo"][k] if mig.get("riparo") else 0
            r.append(f"| {NOMI[k]} | {a:+.1f} | {b2:+.1f} |")
    (cartella / "maestro.md").write_text("\n".join(r) + "\n", encoding="utf-8")


# La frontiera: quanto resta forte il Maestro spendendo meno (per portarlo nel gioco)
# e se vince anche quando crede che gli avversari siano un altro bot (--modello)
FRONTIERA = [
    ("pieno: 5 candidate, 4 semi, un giro", ["--candidate", "5", "--semi", "4", "--turni", "0"]),
    ("3 candidate, 2 semi, fino alla risposta", ["--candidate", "3", "--semi", "2", "--turni", "2"]),
    ("2 candidate, 1 seme, fino alla risposta", ["--candidate", "2", "--semi", "1", "--turni", "2"]),
    ("3 candidate, 1 seme, risposta, rollout leggeri", ["--candidate", "3", "--semi", "1", "--turni", "2", "--leggero", "1"]),
    ("solo attacco, 3 candidate, 2 semi, risposta", ["--candidate", "3", "--semi", "2", "--turni", "2", "--solo", "attacco"]),
    ("crede che gli avversari siano il grado 9", ["--candidate", "3", "--semi", "2", "--turni", "2", "--modello", "9"]),
    ("1 contro 1, 3 candidate, 2 semi, risposta", ["--candidate", "3", "--semi", "2", "--turni", "2", "--modo", "1v1"]),
]


def frontiera(args, cartella, comuni):
    fs = cartella / "frontiera.json"
    fatte = json.loads(fs.read_text(encoding="utf-8")) if fs.exists() else {}
    for k, (nome, extra) in enumerate(FRONTIERA):
        if nome in fatte:
            continue
        t0 = time.time()
        print(f"frontiera: {nome}", flush=True)
        # l'ultimo --modo vince: quello della prova
        righe, _ = lancia(args, cartella / f"frontiera_{k}", args.frontiera, comuni + ["--maestro", "1"] + extra)
        e = esito(righe)
        tot = sum(r["secondi"] for r in righe)
        e["secondi_scelta"] = tot / max(1, sum(r["scelte"] for r in righe))
        fatte[nome] = e
        fs.write_text(json.dumps(fatte, indent=1), encoding="utf-8")
        print(f"  {pct(e['vittorie'])} ± {pct(e['errore'])}, {e['secondi_scelta']:.1f} s a scelta, {time.time() - t0:.0f} s", flush=True)
    return fatte


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--cicli", type=int, default=0, help="quanti cicli (0: senza fine)")
    ap.add_argument("--partite", type=int, default=96, help="partite del Maestro per ciclo")
    ap.add_argument("--esame", type=int, default=960, help="partite dell'esame per ciclo")
    ap.add_argument("--base", type=int, default=480, help="partite della base (bot contro sé stesso), una volta")
    ap.add_argument("--modo", default="2v2")
    ap.add_argument("--grado", type=int, default=10)
    ap.add_argument("--candidate", type=int, default=5)
    ap.add_argument("--semi", type=int, default=4)
    ap.add_argument("--turni", type=int, default=0, help="orizzonte dei rollout in turni (0: un giro intero)")
    ap.add_argument("--vita", type=float, default=0.5)
    ap.add_argument("--ridge", type=float, default=30.0)
    ap.add_argument("--solo-attacco", action="store_true", help="impara solo la correzione dell'attacco")
    ap.add_argument("--processi", type=int, default=max(1, (os.cpu_count() or 2) - 1))
    ap.add_argument("--cartella", default="simulazione/arena/maestro")
    ap.add_argument("--luajit")
    ap.add_argument("--nuova", action="store_true")
    ap.add_argument("--solo-esame", help="esamina questo file di pesi e basta")
    ap.add_argument("--frontiera", type=int, default=48, help="partite per ogni prova della frontiera (0: niente)")
    args = ap.parse_args()

    cartella = REPO / args.cartella
    comuni = ["--modo", args.modo, "--grado", str(args.grado)]
    if args.solo_esame:
        righe, _ = lancia(args, cartella / "esame_file", args.esame,
                          comuni + ["--maestro", "0", "--allievo", str(Path(args.solo_esame).resolve())])
        e = esito(righe)
        print(f"{args.solo_esame}: {pct(e['vittorie'])} ± {pct(e['errore'])} su {e['partite']}, margine {e['margine']:+.0f}")
        return

    if args.nuova and cartella.exists():
        shutil.rmtree(cartella)
    cartella.mkdir(parents=True, exist_ok=True)
    fs = cartella / "stato.json"
    stato = json.loads(fs.read_text(encoding="utf-8")) if fs.exists() else {
        "grado": args.grado, "modo": args.modo, "cicli": [], "migliore": None}

    def salva():
        fs.write_text(json.dumps(stato, indent=1), encoding="utf-8")
        rapporto(cartella, stato)

    if not stato.get("base") and args.base > 0:
        print(f"base: {args.base} partite del bot di oggi contro sé stesso", flush=True)
        righe, _ = lancia(args, cartella / "base", args.base, comuni + ["--maestro", "0"])
        stato["base"] = esito(righe)
        salva()
        print(f"  {pct(stato['base']['vittorie'])} ± {pct(stato['base']['errore'])}", flush=True)

    if args.frontiera > 0:
        stato["frontiera"] = frontiera(args, cartella, comuni)
        salva()

    fatti = 0
    while args.cicli == 0 or fatti < args.cicli:
        n = len(stato["cicli"])
        cc = cartella / f"ciclo_{n}"
        mig = stato.get("migliore")
        allievo = cartella / "migliore.lua" if mig else None
        extra = comuni + ["--candidate", str(args.candidate), "--semi", str(args.semi), "--turni", str(args.turni),
                          "--vita", str(args.vita)]
        if allievo:
            extra += ["--allievo", str(allievo)]
        t0 = time.time()
        print(f"ciclo {n}: {args.partite} partite del Maestro" + (f" (allievo del ciclo {mig['ciclo']})" if mig else ""), flush=True)
        righe, scelte = lancia(args, cc, args.partite, extra + ["--maestro", "1"], dati=True)
        ciclo = {"n": n, "maestro": esito(righe)}
        print(f"  Maestro {pct(ciclo['maestro']['vittorie'])} ± {pct(ciclo['maestro']['errore'])}, "
              f"{len(scelte)} scelte, {time.time() - t0:.0f} s", flush=True)

        # tutte le scelte dei cicli fatti, le più vecchie contano meno
        tutte = []
        for k in range(n + 1):
            f = cartella / f"ciclo_{k}" / "scelte.jsonl"
            if f.exists():
                for riga in f.read_text(encoding="utf-8").splitlines():
                    if riga.strip():
                        s = json.loads(riga)
                        s["_peso"] = 0.7 ** (n - k)
                        tutte.append(s)
        corr, na = impara(tutte, args.ridge, "attacco")
        rip, nr = (None, 0) if args.solo_attacco else impara(tutte, args.ridge, "riparo")
        ciclo["esempi"] = na + nr
        prova = cc / "allievo.lua"
        scrivi_pesi(prova, corr, rip)
        t1 = time.time()
        righe, _ = lancia(args, cc / "esame", args.esame, comuni + ["--maestro", "0", "--allievo", str(prova)])
        ciclo["esame"] = esito(righe)
        e = ciclo["esame"]
        print(f"  allievo {pct(e['vittorie'])} ± {pct(e['errore'])} all'esame, {time.time() - t1:.0f} s", flush=True)
        # tenuto se fa meglio del migliore di prima (che all'inizio è il bot di oggi, 50%)
        soglia = mig["vittorie"] if mig else 0.5
        ciclo["tenuto"] = e["vittorie"] > soglia
        if ciclo["tenuto"]:
            shutil.copy(prova, cartella / "migliore.lua")
            stato["migliore"] = {"ciclo": n, "vittorie": e["vittorie"], "errore": e["errore"],
                                 "correzione": None if corr is None else [float(v) for v in corr],
                                 "riparo": None if rip is None else [float(v) for v in rip]}
        stato["cicli"].append(ciclo)
        salva()
        fatti += 1


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit("fermato: riparte dal ciclo dopo l'ultimo finito")
