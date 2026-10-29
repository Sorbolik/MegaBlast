#!/usr/bin/env python3
"""Generazioni del bot del gioco: i pesi del bot euristico (client/sim/bot.lua,
bot.PESI: quanto teme di perdere vita o di morire, quando prova il globo,
quanto gli piace buttare nel vuoto...) evolvono giocando nell'arena (arena.py,
tutti i core). Il bot resta quello del gioco: cambiano solo i suoi numeri, quindi
un campione si mette nel gioco così com'è.

Due obiettivi insieme:
  - battere il bot di oggi: ogni --esame generazioni il campione gioca contro di
    lui sempre sulle stesse partite, a turno (alla pari); il migliore di sempre è
    in migliore.json;
  - uno stile per nicchia: per ogni stile (quanto butta nel vuoto per quanto si
    sposta) resta il bot più bravo che gioca così (archivio.json). Gli stili danno
    i genitori a metà dei figli e giocano da avversari: le strategie strane non
    si perdono anche se all'inizio rendono meno.

Quando non migliora (nessun esame meglio del migliore per --stallo esami di
fila) cambia da solo, a giro: mutano di più, metà popolazione rinasce a caso,
giocano contro tutti gli stili con più partite. Ogni cambio è scritto nel
rapporto con il motivo. Quando migliora torna come all'inizio.

    python3 strumenti/arena/evolvi.py                   # senza fine (Ctrl+C), riprende da dove era
    python3 strumenti/arena/evolvi.py --generazioni 40  # fino alla generazione 40
    python3 strumenti/arena/evolvi.py --nuova           # ricomincia (da rifare quando cambiano le regole)

Ogni generazione usa semi nuovi. I punti di partenza vengono dal gioco di adesso
(bot.PESI e config.SCORE letti con luajit). Risultati in simulazione/arena/evolvi/
(o --cartella): stato.json (per riprendere), storia.json, evoluzione.md,
archivio.json (gli stili), migliore.json (i pesi da mettere in bot.PESI) e
trovate.jsonl: in ogni generazione i turni rari che fanno tanti punti, con la
ricetta e i pesi per rigiocarli (strumenti/arena/trovate.py ne fa i video).
"""

import argparse
import json
import math
import random
import shutil
import subprocess
from collections import Counter, defaultdict
from pathlib import Path

import arena
import trovate

# i geni: nome, minimo, massimo, se muta in scala logaritmica e cosa vuol dire.
# vuoto, uccisione e danno moltiplicano i punti con cui il bot giudica le mosse
# (bot.PESI.punteggio, partendo da config.SCORE): uccisione nel vuoto, uccisione e danno
GENI = [
    ("vita_mia", 0.05, 5, True, "paura di perdere vita"),
    ("vita_compagno", 0.1, 5, True, "cura del compagno"),
    ("morte", 5, 400, True, "paura di morire"),
    ("strada", 0.001, 0.1, True, "fatica a camminare"),
    ("teletrasporto", 0, 400, False, "voglia di globo"),
    ("globo_riparo", -20, 40, False, "riparo a piedi più che col globo"),
    ("vuoto", 0.5, 4, True, "voglia di buttare nel vuoto"),
    ("uccisione", 0.5, 3, True, "voglia di uccidere"),
    ("danno", 0.5, 2, True, "voglia di fare danno"),
]
PUNTEGGIO = {"vuoto": "env_kill", "uccisione": "kill", "danno": "damage"}


def dal_gioco(luajit):
    """bot.PESI e config.SCORE di adesso."""
    codice = ('package.path="client/?.lua;"..package.path local b=require"sim.bot" local C=require"sim.config" '
              'local function t(x) local o={} for k,v in pairs(x) do if type(v)=="number" then o[#o+1]=string.format("%q:%.17g",k,v) end end '
              'return "{"..table.concat(o,",").."}" end io.write([[{"pesi":]],t(b.PESI),[[,"score":]],t(C.SCORE),"}")')
    r = subprocess.run([luajit or shutil.which("luajit") or "luajit", "-e", codice], cwd=arena.REPO,
                       capture_output=True, text=True, check=True)
    return json.loads(r.stdout)


def a_u(g, x):
    """Il valore di un gene fra 0 e 1."""
    _, lo, hi, log, _ = g
    x = min(hi, max(lo, x))
    return (math.log(x) - math.log(lo)) / (math.log(hi) - math.log(lo)) if log else (x - lo) / (hi - lo)


def da_u(g, u):
    _, lo, hi, log, _ = g
    u = min(1.0, max(0.0, u))
    x = math.exp(math.log(lo) + u * (math.log(hi) - math.log(lo))) if log else lo + u * (hi - lo)
    return round(x, 5)


def di_oggi(gioco):
    return {g[0]: gioco["pesi"].get(g[0], 1.0) for g in GENI}


def a_caso(rng):
    return {g[0]: da_u(g, rng.random()) for g in GENI}


def muta(ind, rng, forza):
    """Ogni gene si sposta un poco (forza: in frazioni del suo intervallo); uno su dieci ricomincia da capo."""
    out = {}
    for g in GENI:
        u = rng.random() if rng.random() < 0.1 else a_u(g, ind[g[0]]) + rng.gauss(0, forza)
        out[g[0]] = da_u(g, u)
    return out


def incrocia(a, b, rng):
    return {g[0]: (a if rng.random() < 0.5 else b)[g[0]] for g in GENI}


def pesi_bot(ind, gioco):
    """I pesi del bot (players[i].pesi) per un individuo."""
    p = {g[0]: ind[g[0]] for g in GENI if g[0] not in PUNTEGGIO}
    if any(abs(ind[k] - 1) > 1e-9 for k in PUNTEGGIO):
        sc = dict(gioco["score"])
        for k, v in PUNTEGGIO.items():
            sc[v] = round(sc[v] * ind[k], 5)
        p["punteggio"] = sc
    return p


def lua_val(v):
    if isinstance(v, dict):
        return "{ " + ", ".join(f"{k} = {lua_val(x)}" for k, x in v.items()) + " }"
    if isinstance(v, list):
        return "{ " + ", ".join(lua_val(x) for x in v) + " }"
    if isinstance(v, bool):
        return "true" if v else "false"
    return repr(v)


def scrivi_pesi(cartella, individui):
    """pesi.lua per l'arena e pesi.json per i video (arena.py li rimette nelle ricette)."""
    (cartella / "pesi.lua").write_text("return {\n" + "".join(f"\t{lua_val(p)},\n" for p in individui) + "}\n", encoding="utf-8")
    (cartella / "pesi.json").write_text(json.dumps(individui), encoding="utf-8")
    return cartella / "pesi.lua"


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
                            pesi=str(file_pesi), ritocchi=None, set=None, assegna=assegna, luajit=getattr(args, "luajit", None))
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


# gli stili: quanto butta nel vuoto (uccisioni nel vuoto su tutte) per quanto
# si sposta (globi e Rampino a partita)
VUOTO = ((0.2, "colpisce"), (0.45, "misto"), (9, "butta nel vuoto"))
MOTO = ((2, "fermo"), (5, "si sposta"), (999, "sempre in volo"))


def nicchia(b):
    v = b["ambientali"] / b["uccisioni"] if b["uccisioni"] > 0.2 else 0
    m = b["teletrasporti"] + b["uso"].get("hook", 0) / max(1, b["volte"])
    return next(n for s, n in VUOTO if v < s) + " · " + next(n for s, n in MOTO if m < s)


def sblocca(stato, gen, args, rng):
    """Una scelta da sola quando non migliora più: a giro più mutazione,
    metà popolazione nuova a caso, tutti gli stili come avversari e più partite."""
    passo = stato["stalli"] % 3
    stato["stalli"] += 1
    if passo == 0:
        stato["forza"] = min(0.4, stato["forza"] * 2)
        cosa = f"mutano di più (forza {stato['forza']:.2f})"
    elif passo == 1:
        pop = stato["pop"]
        for k in range(len(pop) // 2, len(pop)):
            pop[k] = a_caso(rng)
        cosa = f"metà popolazione ({len(pop) - len(pop) // 2}) rinasce a caso"
    else:
        stato["tutti_gli_stili"] = True
        stato["partite"] = int(args.partite * 1.5)
        cosa = f"giocano contro tutti gli stili, {stato['partite']} partite a generazione"
    meglio = max(e["vince"] for e in stato["esami"])
    stato["decisioni"].append({"gen": gen, "cosa": cosa,
                               "perché": f"{args.stallo} esami di fila sotto il migliore ({100 * meglio:.0f}%)"})
    print(f"  stallo: {cosa}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--generazioni", type=int, default=0, help="fino a questa generazione (0: senza fine)")
    ap.add_argument("--popolazione", type=int, default=24, help="bot che evolvono")
    ap.add_argument("--stili", type=int, default=3, help="stili dell'archivio che giocano da avversari")
    ap.add_argument("--partite", type=int, default=1500, help="partite per generazione")
    ap.add_argument("--forza", type=float, default=0.08, help="quanto mutano i geni (frazione del loro intervallo)")
    ap.add_argument("--esame", type=int, default=3, help="ogni quante generazioni l'esame contro il bot di oggi")
    ap.add_argument("--esame-partite", type=int, default=600)
    ap.add_argument("--stallo", type=int, default=4, help="esami di fila senza migliorare prima di cambiare")
    ap.add_argument("--livello", default="difficile")
    ap.add_argument("--modo", default="tutti")
    ap.add_argument("--mappa")
    ap.add_argument("--punteggio")
    ap.add_argument("--processi", type=int, default=None)
    ap.add_argument("--luajit")
    ap.add_argument("--seme", type=int, default=1)
    ap.add_argument("--nuova", action="store_true", help="ricomincia da zero (cancella la cartella)")
    ap.add_argument("--cartella", default=str(arena.REPO / "simulazione" / "arena" / "evolvi"))
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
        gioco = dal_gioco(args.luajit)
        rng = random.Random(args.seme)
        oggi = di_oggi(gioco)
        # un terzo vicino al bot di oggi, il resto a caso: si parte da quello che
        # funziona ma si cercano anche stili lontani
        pop = [oggi] + [muta(oggi, rng, args.forza) for _ in range(args.popolazione // 3 - 1)]
        pop += [a_caso(rng) for _ in range(args.popolazione - len(pop))]
        stato = {"gen": 0, "gioco": gioco, "pop": pop, "archivio": {}, "storia": [], "esami": [],
                 "decisioni": [], "forza": args.forza, "partite": args.partite, "stalli": 0,
                 "senza_meglio": 0, "tutti_gli_stili": False}
    gioco = stato["gioco"]

    while not args.generazioni or stato["gen"] < args.generazioni:
        gen = stato["gen"] + 1
        rng = random.Random(args.seme * 1000003 + gen)
        pop = stato["pop"]
        stili = sorted(stato["archivio"])
        if not stato["tutti_gli_stili"]:
            rng.shuffle(stili)
            stili = sorted(stili[:args.stili])
        individui = [{}] + [pesi_bot(stato["archivio"][s]["ind"], gioco) for s in stili] + [pesi_bot(x, gioco) for x in pop]
        primo = 2 + len(stili)  # numero del primo bot che evolve
        cartella = radice / f"generazione_{gen}"
        cartella.mkdir(parents=True, exist_ok=True)
        scrivi_pesi(cartella, individui)
        partite = gioca(cartella, cartella / "pesi.lua", stato["partite"], 1 + gen * 100000 + args.seme * 10 ** 9, args)
        b = misura(partite, len(individui))

        # gli stili che hanno giocato: la bravura è la media di tutte le volte (meno fortuna)
        for k, s in enumerate(stili):
            a = stato["archivio"][s]
            n = a.get("prove", 1)
            a["bravura"] = round((a["bravura"] * n + b[2 + k]["alto"]) / (n + 1), 4)
            a["prove"] = n + 1
        # i bot che evolvono entrano nell'archivio se sono i più bravi del loro stile
        for i in range(primo, len(individui) + 1):
            if b[i]["volte"] < 20:
                continue
            s = nicchia(b[i])
            a = stato["archivio"].get(s)
            if not a or b[i]["alto"] > a["bravura"]:
                stato["archivio"][s] = {"ind": pop[i - primo], "bravura": round(b[i]["alto"], 4), "gen": gen,
                                        "prove": 1, "come": comportamento(b[i])}

        ordine = sorted(range(primo, len(individui) + 1), key=lambda i: (-b[i]["alto"], i))
        migliore = ordine[0]
        campione = pop[migliore - primo]
        voce = {"gen": gen, "campione": comportamento(b[migliore]) | {"geni": campione, "stile": nicchia(b[migliore])},
                "oggi": comportamento(b[1]), "media": round(sum(b[i]["alto"] for i in ordine) / len(ordine), 4),
                "partite": len(partite), "forza": stato["forza"], "stili": len(stato["archivio"])}
        stato["storia"].append(voce)
        print(f"generazione {gen}: campione {b[migliore]['alto']:.3f} ({voce['campione']['stile']}), media "
              f"{voce['media']:.3f}, bot di oggi {b[1]['alto']:.3f}, {len(stato['archivio'])} stili ({len(partite)} partite)")

        # le trovate di questa generazione: dei bot che evolvono e degli stili
        nomi = {1: "bot di oggi"} | {2 + k: s for k, s in enumerate(stili)}
        with (radice / "trovate.jsonl").open("a", encoding="utf-8") as f:
            for t in trovate.candidati(partite, individui, 4, conta=lambda ind: ind and ind > 1):
                t["gen"] = gen
                t["chi_nome"] = f"generazione {gen}, " + (nomi.get(t["individuo"]) or nicchia(b[t["individuo"]]))
                f.write(json.dumps(t, ensure_ascii=False) + "\n")

        # la generazione dopo: i migliori restano; metà figli dei migliori, metà degli stili
        tenuti = [pop[i - primo] for i in ordine[: max(2, len(pop) // 4)]]
        genitori = [pop[i - primo] for i in ordine[: max(2, len(pop) // 2)]]
        archivio = [stato["archivio"][s]["ind"] for s in sorted(stato["archivio"])]

        def scegli():
            if archivio and rng.random() < 0.5:
                return rng.choice(archivio)
            return genitori[min(rng.sample(range(len(genitori)), min(3, len(genitori))))]

        nuovi = list(tenuti)
        while len(nuovi) < len(pop):
            a = scegli()
            if rng.random() < 0.3:
                a = incrocia(a, scegli(), rng)
            nuovi.append(muta(a, rng, stato["forza"]))
        stato["pop"] = nuovi
        stato["gen"] = gen

        if args.esame and gen % args.esame == 0:
            e = esame(radice, gen, pesi_bot(campione, gioco), args)
            e["gen"] = gen
            e["geni"] = campione
            prima = max((x["vince"] for x in stato["esami"]), default=0)
            stato["esami"].append(e)
            print(f"  esame: il campione della generazione {gen} arriva più in alto del bot di oggi "
                  f"nel {100 * e['vince']:.0f}% delle partite")
            if e["vince"] > prima:
                (radice / "migliore.json").write_text(json.dumps(pesi_bot(campione, gioco) | {"gen": gen, "vince": e["vince"]}),
                                                      encoding="utf-8")
            if e["vince"] > prima + 0.01:
                # migliora: si torna come all'inizio
                stato.update(senza_meglio=0, forza=args.forza, partite=args.partite, tutti_gli_stili=False)
            else:
                stato["senza_meglio"] += 1
                if stato["senza_meglio"] >= args.stallo:
                    stato["senza_meglio"] = 0
                    sblocca(stato, gen, args, rng)

        for f in cartella.glob("parte_*.jsonl"):
            f.unlink()
        (cartella / "partite.jsonl").unlink(missing_ok=True)
        # salva tutto a ogni generazione: si può fermare quando si vuole
        file_stato.write_text(json.dumps(stato), encoding="utf-8")
        (radice / "storia.json").write_text(json.dumps({k: stato[k] for k in ("gioco", "storia", "esami", "decisioni")},
                                                       indent=1, ensure_ascii=False), encoding="utf-8")
        (radice / "archivio.json").write_text(json.dumps(
            {s: a | {"pesi": pesi_bot(a["ind"], gioco)} for s, a in sorted(stato["archivio"].items())},
            indent=1, ensure_ascii=False), encoding="utf-8")
        (radice / "evoluzione.md").write_text(rapporto(stato, args), encoding="utf-8")


def geni_in_parole(ind, gioco):
    """Cosa cambia rispetto al bot di oggi, solo i geni lontani almeno un po'."""
    oggi = di_oggi(gioco)
    out = []
    for g in GENI:
        x, o = ind[g[0]], oggi[g[0]]
        if g[3]:
            r = x / o if o else 1
            if r >= 1.5 or r <= 0.67:
                out.append(f"{g[4]} ×{r:.1f}" if r >= 1 else f"{g[4]} ÷{1 / r:.1f}")
        elif abs(a_u(g, x) - a_u(g, o)) >= 0.1:
            out.append(f"{g[4]} {x:.0f} (oggi {o:.0f})")
    return ", ".join(out) or "come il bot di oggi"


def rapporto(stato, args):
    gioco = stato["gioco"]
    out = ["# Generazioni del bot del gioco\n",
           f"{len(stato['pop'])} bot per generazione, livello {args.livello}, modo {args.modo}. Bravura: quanto in alto "
           "arriva in classifica, da 0 (ultimo) a 1 (primo). Esame: in quante delle stesse partite il campione arriva più "
           "in alto del bot di oggi (50% vuol dire uguale). Il migliore è in migliore.json.\n"]
    if stato["esami"]:
        out += ["## Esami\n", "| gen | contro il bot di oggi | morti (lui / oggi) | globi (lui / oggi) | cosa cambia |",
                "|---|---|---|---|---|"]
        for e in stato["esami"]:
            out.append(f"| {e['gen']} | {100 * e['vince']:.0f}% | {e['rete']['morti']:.2f} / {e['oggi']['morti']:.2f} | "
                       f"{e['rete']['teletrasporti']:.2f} / {e['oggi']['teletrasporti']:.2f} | {geni_in_parole(e['geni'], gioco)} |")
    if stato["archivio"]:
        out += ["\n## Gli stili (il più bravo di ognuno)\n", "| stile | bravura | gen | morti | nel vuoto | cosa cambia |",
                "|---|---|---|---|---|---|"]
        for s, a in sorted(stato["archivio"].items(), key=lambda x: -x[1]["bravura"]):
            c = a["come"]
            out.append(f"| {s} | {a['bravura']:.3f} | {a['gen']} | {c['morti']:.2f} | {c['ambientali']:.2f} | "
                       f"{geni_in_parole(a['ind'], gioco)} |")
    if stato["decisioni"]:
        out += ["\n## Scelte prese da sola quando non migliorava\n"]
        out += [f"- generazione {d['gen']}: {d['cosa']}, perché {d['perché']}" for d in stato["decisioni"]]
    out += ["\n## Generazioni\n", "| gen | campione | stile | media | bot di oggi | morti | danno | armi principali |",
            "|---|---|---|---|---|---|---|---|"]
    for v in stato["storia"]:
        c = v["campione"]
        armi = ", ".join(f"{k} {100 * q:.0f}%" for k, q in sorted(c["armi"].items(), key=lambda x: -x[1])[:3])
        out.append(f"| {v['gen']} | {c['bravura']:.3f} | {c['stile']} | {v['media']:.3f} | {v['oggi']['bravura']:.3f} | "
                   f"{c['morti']:.2f} | {c['danno']:.0f} | {armi} |")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    main()
