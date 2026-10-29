#!/usr/bin/env python3
"""Evoluzione dei pesi del bot (client/sim/bot.lua, bot.PESI): il primo passo
dell'apprendimento. Una popolazione di pesi gioca nell'arena (arena.py, tutti
i core); i migliori restano, gli altri si rifanno mutando i migliori. Il
numero 1 è sempre il bot di oggi, come riferimento. Le strategie che vincono
dicono cosa conviene con queste regole: quelle che vincono troppo sono da
correggere nel gioco, non nel bot.

    python3 strumenti/arena/evolvi.py --generazioni 8 --popolazione 12 --partite 400
    python3 strumenti/arena/evolvi.py --punteggio variante.lua   # con un altro punteggio

Ogni generazione usa semi nuovi (niente pesi buoni solo per quelle partite).
Risultati in simulazione/arena/evolvi/ (o --cartella): una cartella per
generazione con le sue partite e evoluzione.md, con i pesi migliori e come
giocano rispetto al bot di oggi.
"""

import argparse
import json
import math
import random
from collections import Counter, defaultdict
from pathlib import Path

import arena

# I pesi che evolvono, con il valore di oggi (bot.PESI) e i limiti
PESI = {
    "vita_mia": (0.6, 0.0, 5.0),
    "vita_compagno": (1.0, 0.0, 5.0),
    "morte": (60.0, 0.0, 300.0),
    "strada": (0.01, 0.0, 0.2),
    "teletrasporto": (20.0, -20.0, 150.0),
}


def muta(p, rng, forza):
    """Una copia di p con ogni peso spostato a caso (in proporzione, così i
    pesi piccoli e quelli grandi si muovono allo stesso modo)."""
    q = {}
    for k, (base, lo, hi) in PESI.items():
        v = p[k] * math.exp(rng.gauss(0, forza)) + rng.gauss(0, forza) * 0.05 * (hi - lo)
        q[k] = round(min(hi, max(lo, v)), 4)
    return q


def lua(popolazione):
    righe = ["return {"]
    for p in popolazione:
        campi = ", ".join(f"{k} = {v!r}" for k, v in p.items())
        righe.append(f"\t{{ {campi} }},")
    righe.append("}")
    return "\n".join(righe) + "\n"


def bravura(partite, n):
    """Per ogni individuo (da 1): quanto è arrivato in alto (1 primo, 0 ultimo),
    vittorie, punti medi, quante volte ha giocato e le armi che usa."""
    s = defaultdict(lambda: {"alto": 0.0, "vinte": 0, "punti": 0, "volte": 0, "uso": Counter()})
    for m in partite:
        posti = [r["posto"] for r in m["robot"] if r.get("posto")]
        ultimo = max(posti) if posti else 1
        for r in m["robot"]:
            i = r.get("individuo")
            if not i:
                continue
            x = s[i]
            x["volte"] += 1
            x["alto"] += (ultimo - r["posto"]) / (ultimo - 1) if ultimo > 1 else 0.5
            x["vinte"] += r["posto"] == 1
            x["punti"] += r["punti"]
            x["uso"].update(r["uso"])
    out = {}
    for i in range(1, n + 1):
        x = s[i]
        v = max(1, x["volte"])
        out[i] = {"alto": x["alto"] / v, "vinte": x["vinte"] / v, "punti": x["punti"] / v, "volte": x["volte"],
                  "uso": x["uso"]}
    return out


def quote(uso):
    tot = sum(uso.values()) or 1
    return {k: v / tot for k, v in uso.items()}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--generazioni", type=int, default=8)
    ap.add_argument("--popolazione", type=int, default=12)
    ap.add_argument("--partite", type=int, default=400, help="partite per generazione")
    ap.add_argument("--livello", default="difficile")
    ap.add_argument("--modo", default="tutti")
    ap.add_argument("--mappa")
    ap.add_argument("--punteggio")
    ap.add_argument("--processi", type=int, default=None)
    ap.add_argument("--forza", type=float, default=0.35, help="quanto mutano i pesi")
    ap.add_argument("--seme", type=int, default=1)
    ap.add_argument("--cartella", default=str(arena.REPO / "simulazione" / "arena" / "evolvi"))
    args = ap.parse_args()

    rng = random.Random(args.seme)
    base = {k: v[0] for k, v in PESI.items()}
    pop = [base] + [muta(base, rng, args.forza) for _ in range(args.popolazione - 1)]
    radice = Path(args.cartella).resolve()
    radice.mkdir(parents=True, exist_ok=True)
    storia = []
    for gen in range(1, args.generazioni + 1):
        cartella = radice / f"generazione_{gen}"
        cartella.mkdir(parents=True, exist_ok=True)
        file_pesi = cartella / "pesi.lua"
        file_pesi.write_text(lua(pop))
        arena.USCITA = cartella
        ns = argparse.Namespace(partite=args.partite, da=1 + (gen - 1) * args.partite + 1000000 * args.seme,
                                processi=args.processi or arena.os.cpu_count() or 1, modo=args.modo,
                                livello=args.livello, mappa=args.mappa, punteggio=args.punteggio,
                                pesi=str(file_pesi), luajit=None)
        partite = arena.leggi(arena.gioca(ns))
        b = bravura(partite, len(pop))
        ordine = sorted(range(1, len(pop) + 1), key=lambda i: (-b[i]["alto"], i))
        storia.append({"gen": gen, "pop": pop, "b": b, "ordine": ordine})
        migliore = ordine[0]
        print(f"generazione {gen}: migliore #{migliore} {b[migliore]['alto']:.3f}, "
              f"bot di oggi {b[1]['alto']:.3f}  {pop[migliore - 1]}")
        # i migliori restano (e il bot di oggi, come riferimento), gli altri si rifanno
        tenuti = [pop[i - 1] for i in ordine[: max(2, len(pop) // 3)]]
        nuovi = [base] + [p for p in tenuti if p != base]
        while len(nuovi) < len(pop):
            nuovi.append(muta(rng.choice(tenuti), rng, args.forza))
        pop = nuovi

    (radice / "evoluzione.md").write_text(rapporto(storia, args))
    (radice / "storia.json").write_text(json.dumps(
        [{"gen": s["gen"], "pop": s["pop"], "ordine": s["ordine"],
          "bravura": {i: {k: v for k, v in x.items() if k != "uso"} for i, x in s["b"].items()}} for s in storia],
        indent=1))
    print(f"rapporto: {radice / 'evoluzione.md'}")


def rapporto(storia, args):
    out = ["# Evoluzione dei pesi del bot\n",
           f"{args.generazioni} generazioni da {args.popolazione} pesi, {args.partite} partite l'una, "
           f"livello {args.livello}, modo {args.modo}"
           + (f", punteggio {args.punteggio}" if args.punteggio else "") + ".\n",
           "Bravura: quanto in alto arriva in classifica, da 0 (ultimo) a 1 (primo). Il #1 è sempre il bot di oggi.\n",
           "| gen | migliore | bravura | bot di oggi | " + " | ".join(PESI) + " |",
           "|---|---|---|---|" + "---|" * len(PESI)]
    for s in storia:
        i = s["ordine"][0]
        p = s["pop"][i - 1]
        out.append(f"| {s['gen']} | #{i} | {s['b'][i]['alto']:.3f} | {s['b'][1]['alto']:.3f} | "
                   + " | ".join(f"{p[k]:g}" for k in PESI) + " |")
    # come gioca il migliore dell'ultima generazione rispetto al bot di oggi
    s = storia[-1]
    i = s["ordine"][0]
    qm, qo = quote(s["b"][i]["uso"]), quote(s["b"][1]["uso"])
    out += ["\n## Come gioca il migliore rispetto al bot di oggi (ultima generazione)\n",
            f"Vittorie {100 * s['b'][i]['vinte']:.0f}% contro {100 * s['b'][1]['vinte']:.0f}%, "
            f"punti medi {s['b'][i]['punti']:.0f} contro {s['b'][1]['punti']:.0f}.\n",
            "| arma | quota del migliore | quota del bot di oggi | differenza |", "|---|---|---|---|"]
    for k in sorted(set(qm) | set(qo), key=lambda k: -abs(qm.get(k, 0) - qo.get(k, 0))):
        out.append(f"| {k} | {100 * qm.get(k, 0):.1f}% | {100 * qo.get(k, 0):.1f}% | "
                   f"{100 * (qm.get(k, 0) - qo.get(k, 0)):+.1f} |")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    main()
