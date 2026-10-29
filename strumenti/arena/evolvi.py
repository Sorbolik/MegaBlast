#!/usr/bin/env python3
"""Bot che imparano da soli: reti neurali (client/sim/rete.lua) che evolvono
giocando nell'arena (arena.py, tutti i core). Partono da zero (pesi a caso,
nessuna regola nostra): ogni generazione gioca, le reti che arrivano più in
alto in classifica restano, le altre si rifanno mutando e incrociando le
migliori. La rete giudica ogni mossa che il bot prova (dove andare, cosa
sparare, dove ripararsi) guardando la posizione che ne esce (bot.caratteristiche).
Insieme alla rete evolve la soglia del teletrasporto (bot.PESI.teletrasporto:
sotto quel valore della mossa migliore a piedi il bot prova il teletrasporto),
che altrimenti resterebbe tarata sul bot di oggi.

    python3 strumenti/arena/evolvi.py                   # senza fine (Ctrl+C), riprende da dove era
    python3 strumenti/arena/evolvi.py --generazioni 40  # fino alla generazione 40
    python3 strumenti/arena/evolvi.py --nuova           # ricomincia da zero

In ogni generazione giocano insieme:
  #1            il bot di oggi (euristico, bot.PESI): il riferimento fisso
  #2..          i campioni delle generazioni passate (fermi, come avversari,
                così le reti non dimenticano come si batte chi già battevano)
  gli altri     le reti che evolvono
Ogni generazione usa semi nuovi (niente reti brave solo in quelle partite).
Ogni --esame generazioni il campione gioca contro il bot di oggi sempre sulle
stesse partite (a turno, alla pari): è la misura dei progressi.

Risultati in simulazione/arena/reti/ (o --cartella): stato.json (per
riprendere), storia.json (tutte le generazioni), evoluzione.md, campioni.json
(la rete migliore di ogni generazione) e una cartella per generazione.
"""

import argparse
import json
import math
import random
import shutil
from collections import Counter, defaultdict
from pathlib import Path

import arena

CARATTERISTICHE = 20  # bot.CARATTERISTICHE


def quanti(strati):
    return sum(strati[k] * (strati[k - 1] + 1) for k in range(1, len(strati)))


TELE = (-50.0, 200.0)  # limiti della soglia del teletrasporto


def individuo(x):
    """Una rete che evolve: pesi (w) e soglia del teletrasporto (tele). Gli stati
    salvati prima della soglia hanno solo i pesi: prendono quella di oggi."""
    return x if isinstance(x, dict) else {"w": x, "tele": 20.0}


def nuova_rete(strati, rng):
    """Pesi a caso (He: varianza 2/ingressi), scarti a zero, soglia a caso: nessuna idea del gioco."""
    return {"w": pesi_a_caso(strati, rng), "tele": round(rng.uniform(*TELE), 2)}


def pesi_a_caso(strati, rng):
    w = []
    for k in range(1, len(strati)):
        nin, nout = strati[k - 1], strati[k]
        s = math.sqrt(2 / nin)
        for _ in range(nout):
            w += [round(rng.gauss(0, s), 5) for _ in range(nin)]
        w += [0.0] * nout
    return w


def muta(ind, rng, forza):
    """Ogni peso si sposta un poco; uno su cinquanta ricomincia da capo."""
    out = []
    for x in ind["w"]:
        if rng.random() < 0.02:
            x = rng.gauss(0, 0.5)
        else:
            x += rng.gauss(0, forza)
        out.append(round(x, 5))
    tele = min(TELE[1], max(TELE[0], ind["tele"] + rng.gauss(0, forza * 100)))
    return {"w": out, "tele": round(tele, 2)}


def incrocia(ia, ib, strati, rng):
    """Figlio di due reti: ogni neurone (i suoi pesi d'ingresso e lo scarto)
    viene tutto da uno dei due genitori, così non si spezzano le idee."""
    a, b = ia["w"], ib["w"]
    out, p = [], 0
    for k in range(1, len(strati)):
        nin, nout = strati[k - 1], strati[k]
        da = [rng.random() < 0.5 for _ in range(nout)]
        for o in range(nout):
            src = a if da[o] else b
            out += src[p:p + nin]
            p += nin
        for o in range(nout):
            out.append((a if da[o] else b)[p])
            p += 1
    return {"w": out, "tele": ia["tele"] if rng.random() < 0.5 else ib["tele"]}


def lua_val(v):
    if isinstance(v, dict):
        return "{ " + ", ".join(f"{k} = {lua_val(x)}" for k, x in v.items()) + " }"
    if isinstance(v, list):
        return "{ " + ", ".join(lua_val(x) for x in v) + " }"
    return repr(v)


def scrivi_pesi(cartella, individui):
    """pesi.lua per l'arena e pesi.json per i video (arena.py li rimette nelle ricette)."""
    (cartella / "pesi.lua").write_text("return {\n" + "".join(f"\t{lua_val(p)},\n" for p in individui) + "}\n", encoding="utf-8")
    (cartella / "pesi.json").write_text(json.dumps(individui), encoding="utf-8")
    return cartella / "pesi.lua"


def pesi_rete(strati, ind):
    """I pesi del bot (players[i].pesi) per una rete che evolve."""
    ind = individuo(ind)
    return {"rete": {"strati": strati, "w": ind["w"]}, "teletrasporto": ind["tele"]}


def misura(partite, n):
    """Per ogni individuo (da 1): bravura (1 primo, 0 ultimo), vittorie, punti,
    danno, uccisioni, morti, cadute, teletrasporti a partita, armi usate e le
    firme dei turni (la sequenza di mosse)."""
    s = defaultdict(lambda: {"alto": 0.0, "vinte": 0, "volte": 0, "punti": 0, "danno": 0, "uccisioni": 0,
                             "ambientali": 0, "morti": 0, "cadute": 0, "teletrasporti": 0,
                             "uso": Counter(), "firme": Counter()})
    for m in partite:
        posti = [r["posto"] for r in m["robot"] if r.get("posto")]
        ultimo = max(posti) if posti else 1
        chi = {}
        for k, r in enumerate(m["robot"], 1):
            i = r.get("individuo")
            if not i:
                continue
            chi[k] = i
            x = s[i]
            x["volte"] += 1
            x["alto"] += (ultimo - r["posto"]) / (ultimo - 1) if ultimo > 1 else 0.5
            x["vinte"] += r["posto"] == 1
            for c in ("punti", "danno", "uccisioni", "ambientali", "morti", "cadute", "teletrasporti"):
                x[c] += r.get(c) or 0
            x["uso"].update(r["uso"])
        for t in m.get("turni", []):
            i = chi.get(t["chi"])
            if i and t["firma"]:
                s[i]["firme"][t["firma"]] += 1
    out = {}
    for i in range(1, n + 1):
        x = s[i]
        v = max(1, x["volte"])
        out[i] = {k: (x[k] / v if k not in ("volte", "uso", "firme") else x[k]) for k in x}
    return out


def quote(uso):
    tot = sum(uso.values()) or 1
    return {k: round(v / tot, 4) for k, v in sorted(uso.items())}


def comportamento(b):
    """Come gioca un individuo, per la storia: numeri a partita, armi, firme."""
    return {"bravura": round(b["alto"], 4), "vinte": round(b["vinte"], 4), "partite": b["volte"],
            "punti": round(b["punti"], 1), "danno": round(b["danno"], 1), "uccisioni": round(b["uccisioni"], 2),
            "ambientali": round(b["ambientali"], 2), "morti": round(b["morti"], 2), "cadute": round(b["cadute"], 2),
            "teletrasporti": round(b["teletrasporti"], 2), "armi": quote(b["uso"]),
            "firme": b["firme"].most_common(6)}


def gioca(cartella, file_pesi, partite, da, args, assegna=None):
    arena.USCITA = cartella
    ns = argparse.Namespace(partite=partite, da=da, processi=args.processi or arena.os.cpu_count() or 1,
                            modo=args.modo, livello=args.livello, mappa=args.mappa, punteggio=args.punteggio,
                            pesi=str(file_pesi), ritocchi=None, set=None, assegna=assegna, luajit=None)
    return arena.leggi(arena.gioca(ns))


def esame(radice, gen, campione, args):
    """Il campione contro il bot di oggi, sempre sulle stesse partite, a turno:
    in quante arriva più in alto lui."""
    cartella = radice / f"esame_{gen}"
    cartella.mkdir(parents=True, exist_ok=True)
    file_pesi = scrivi_pesi(cartella, [{}, campione])
    partite = gioca(cartella, file_pesi, args.esame_partite, 10 ** 8, args, assegna="turno")
    meglio = pari = 0
    for m in partite:
        migliore = {}
        for r in m["robot"]:
            i = r.get("individuo")
            if i:
                migliore[i] = min(migliore.get(i, 99), r["posto"])
        if 1 in migliore and 2 in migliore:
            if migliore[2] < migliore[1]:
                meglio += 1
            elif migliore[2] == migliore[1]:
                pari += 1
    b = misura(partite, 2)
    (cartella / "partite.jsonl").unlink(missing_ok=True)
    return {"vince": round((meglio + pari / 2) / max(1, len(partite)), 4), "partite": len(partite),
            "rete": comportamento(b[2]), "oggi": comportamento(b[1])}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--generazioni", type=int, default=0, help="fino a questa generazione (0: senza fine)")
    ap.add_argument("--popolazione", type=int, default=24, help="reti che evolvono")
    ap.add_argument("--campioni", type=int, default=3, help="campioni passati che giocano come avversari")
    ap.add_argument("--partite", type=int, default=480, help="partite per generazione")
    ap.add_argument("--strati", default="16,8", help="neuroni degli strati nascosti")
    ap.add_argument("--forza", type=float, default=0.08, help="quanto mutano i pesi")
    ap.add_argument("--esame", type=int, default=5, help="ogni quante generazioni l'esame contro il bot di oggi")
    ap.add_argument("--esame-partite", type=int, default=240)
    ap.add_argument("--tieni", type=int, default=10, help="tiene le partite di una generazione ogni tante (per i video)")
    ap.add_argument("--livello", default="difficile")
    ap.add_argument("--modo", default="tutti")
    ap.add_argument("--mappa")
    ap.add_argument("--punteggio")
    ap.add_argument("--processi", type=int, default=None)
    ap.add_argument("--seme", type=int, default=1)
    ap.add_argument("--nuova", action="store_true", help="ricomincia da zero (cancella la cartella)")
    ap.add_argument("--cartella", default=str(arena.REPO / "simulazione" / "arena" / "reti"))
    args = ap.parse_args()

    radice = Path(args.cartella).resolve()
    if args.nuova and radice.exists():
        shutil.rmtree(radice)
    radice.mkdir(parents=True, exist_ok=True)
    file_stato = radice / "stato.json"
    if file_stato.exists():
        stato = json.loads(file_stato.read_text(encoding="utf-8"))
        print(f"riprendo dalla generazione {stato['gen'] + 1}")
    else:
        strati = [CARATTERISTICHE] + [int(x) for x in args.strati.split(",")] + [1]
        rng = random.Random(args.seme)
        stato = {"gen": 0, "strati": strati, "pop": [nuova_rete(strati, rng) for _ in range(args.popolazione)],
                 "campioni": [], "storia": [], "esami": []}
    strati = stato["strati"]
    stato["pop"] = [individuo(x) for x in stato["pop"]]
    for c in stato["campioni"]:
        if "w" in c:
            c["ind"] = individuo(c.pop("w"))
    print(f"rete {strati}: {quanti(strati)} pesi, {len(stato['pop'])} reti")

    while not args.generazioni or stato["gen"] < args.generazioni:
        gen = stato["gen"] + 1
        rng = random.Random(args.seme * 1000003 + gen)
        pop = stato["pop"]
        # gli avversari fissi: il bot di oggi e alcuni campioni passati (l'ultimo e altri a caso)
        passati = stato["campioni"]
        scelti = []
        if passati:
            scelti.append(passati[-1])
            altri = passati[:-1]
            rng.shuffle(altri)
            scelti += altri[: args.campioni - 1]
        individui = [{}] + [pesi_rete(strati, c["ind"]) for c in scelti] + [pesi_rete(strati, x) for x in pop]
        primo = 2 + len(scelti)  # numero della prima rete che evolve
        cartella = radice / f"generazione_{gen}"
        cartella.mkdir(parents=True, exist_ok=True)
        file_pesi = scrivi_pesi(cartella, individui)
        partite = gioca(cartella, file_pesi, args.partite, 1 + gen * 100000 + args.seme * 10 ** 9, args)
        b = misura(partite, len(individui))

        ordine = sorted(range(primo, len(individui) + 1), key=lambda i: (-b[i]["alto"], i))
        migliore = ordine[0]
        campione = {"gen": gen, "ind": pop[migliore - primo]}
        stato["campioni"].append(campione)
        voce = {"gen": gen, "campione": comportamento(b[migliore]) | {"teletrasporto": campione["ind"]["tele"]},
                "oggi": comportamento(b[1]),
                "media_reti": round(sum(b[i]["alto"] for i in ordine) / len(ordine), 4),
                "peggiore": round(b[ordine[-1]]["alto"], 4),
                "avversari": {f"gen {c['gen']}": round(b[2 + k]["alto"], 4) for k, c in enumerate(scelti)}}
        stato["storia"].append(voce)
        print(f"generazione {gen}: campione {b[migliore]['alto']:.3f}, media reti {voce['media_reti']:.3f}, "
              f"bot di oggi {b[1]['alto']:.3f} ({len(partite)} partite)")

        # la generazione dopo: i migliori restano, gli altri figli dei migliori
        tenuti = [pop[i - primo] for i in ordine[: max(2, len(pop) // 4)]]
        genitori = [pop[i - primo] for i in ordine[: max(2, len(pop) // 2)]]

        def torneo():
            return min(rng.sample(range(len(genitori)), min(3, len(genitori))))

        nuovi = list(tenuti)
        while len(nuovi) < len(pop):
            a = genitori[torneo()]
            if rng.random() < 0.25:
                a = incrocia(a, genitori[torneo()], strati, rng)
            nuovi.append(muta(a, rng, args.forza))
        stato["pop"] = nuovi
        stato["gen"] = gen

        if args.esame and gen % args.esame == 0:
            e = esame(radice, gen, pesi_rete(strati, campione["ind"]), args)
            e["gen"] = gen
            stato["esami"].append(e)
            print(f"  esame: il campione della generazione {gen} arriva più in alto del bot di oggi "
                  f"nel {100 * e['vince']:.0f}% delle partite")

        if gen % args.tieni != 0:
            (cartella / "partite.jsonl").unlink(missing_ok=True)
        for f in cartella.glob("parte_*.jsonl"):
            f.unlink()
        # salva tutto a ogni generazione: si può fermare quando si vuole
        file_stato.write_text(json.dumps(stato), encoding="utf-8")
        (radice / "storia.json").write_text(json.dumps({"strati": strati, "storia": stato["storia"],
                                                        "esami": stato["esami"]}, indent=1, ensure_ascii=False), encoding="utf-8")
        (radice / "campioni.json").write_text(json.dumps(
            [pesi_rete(strati, c["ind"]) | {"gen": c["gen"]} for c in stato["campioni"]]), encoding="utf-8")
        (radice / "evoluzione.md").write_text(rapporto(stato, args), encoding="utf-8")


def rapporto(stato, args):
    st = stato["storia"]
    out = ["# Bot che imparano da soli: le generazioni\n",
           f"Rete {stato['strati']} ({quanti(stato['strati'])} pesi), {len(stato['pop'])} reti per generazione, "
           f"{args.partite} partite l'una, livello {args.livello}, modo {args.modo}.\n",
           "Bravura: quanto in alto arriva in classifica, da 0 (ultimo) a 1 (primo), nelle partite della "
           "generazione (con il bot di oggi e i campioni passati).\n",
           "| gen | campione | media reti | bot di oggi | morti | cadute | danno | armi principali |",
           "|---|---|---|---|---|---|---|---|"]
    for v in st:
        c = v["campione"]
        armi = ", ".join(f"{k} {100 * q:.0f}%" for k, q in sorted(c["armi"].items(), key=lambda x: -x[1])[:3])
        out.append(f"| {v['gen']} | {c['bravura']:.3f} | {v['media_reti']:.3f} | {v['oggi']['bravura']:.3f} | "
                   f"{c['morti']:.2f} | {c['cadute']:.2f} | {c['danno']:.0f} | {armi} |")
    if stato["esami"]:
        out += ["\n## Esami: il campione contro il bot di oggi, sempre sulle stesse partite\n",
                "| gen | più in alto del bot di oggi | morti (rete / oggi) | danno (rete / oggi) |", "|---|---|---|---|"]
        for e in stato["esami"]:
            out.append(f"| {e['gen']} | {100 * e['vince']:.0f}% | {e['rete']['morti']:.2f} / {e['oggi']['morti']:.2f} | "
                       f"{e['rete']['danno']:.0f} / {e['oggi']['danno']:.0f} |")
    if st:
        c = st[-1]["campione"]
        out += ["\n## Le mosse preferite dell'ultimo campione\n"] + [f"- {f}: {n}" for f, n in c["firme"]]
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    main()
