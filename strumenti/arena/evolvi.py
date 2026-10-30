#!/usr/bin/env python3
"""Specialisti del bot del gioco: i pesi del bot euristico (client/sim/bot.lua,
bot.PESI: quanto teme di perdere vita o di morire, quando prova il globo,
quanto gli piace buttare nel vuoto, quali armi preferisce...) evolvono giocando
nell'arena (arena.py, tutti i core). Il bot resta quello del gioco: cambiano solo
i suoi numeri, quindi uno specialista si mette nel gioco così com'è.

Cinque specialisti, ognuno con la sua popolazione e il suo mestiere (SPECIALISTI):
spingitore (uccisioni nel vuoto), acrobata (globi e Rampino), cecchino (danno da
lontano), picchiatore (danno da vicino), sopravvissuto (muore poco). Giocano
tutti insieme, col bot di oggi. Ognuno si giudica sulla bravura (quanto in alto
arriva in classifica, da tutte le partite giocate), ma perde molto se fa il suo
mestiere meno della sua soglia; la soglia parte dal bot di oggi e sale da sola
verso il campione finché il campione resta bravo quasi quanto il bot di oggi:
diventano sempre più estremi senza diventare scarsi. Ogni --esame generazioni il
campione di ogni specialista gioca contro il bot di oggi a coppie (le stesse
partite con i posti scambiati); i migliori sono in migliori.json.

Quando uno specialista non migliora (nessun esame meglio del suo migliore per
--stallo esami di fila) cambia da solo, a giro: muta di più, metà della sua
popolazione rinasce a caso. Ogni cambio è scritto nel rapporto con il motivo.
Quando migliora torna come all'inizio.

    python3 strumenti/arena/evolvi.py                   # senza fine (Ctrl+C), riprende da dove era
    python3 strumenti/arena/evolvi.py --generazioni 40  # fino alla generazione 40
    python3 strumenti/arena/evolvi.py --nuova           # ricomincia (da rifare quando cambiano le regole)

Ogni generazione usa semi nuovi. I punti di partenza vengono dal gioco di adesso
(bot.PESI e config.SCORE letti con luajit). Risultati in simulazione/arena/evolvi/
(o --cartella): stato.json (per riprendere), storia.json, evoluzione.md,
specialisti.json (campione e soglia di ognuno), migliori.json (i pesi da dare ai
bot del gioco) e trovate.jsonl: in ogni generazione i turni rari che fanno tanti
punti, con la ricetta e i pesi per rigiocarli (strumenti/arena/trovate.py ne fa
i video).
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
    ("vicino", 0.5, 3, True, "gusto per le armi da vicino"),
    ("lontano", 0.5, 3, True, "gusto per le armi da lontano"),
    ("spinta", 0.5, 3, True, "gusto per il Mantice"),
]
PUNTEGGIO = {"vuoto": "env_kill", "uccisione": "kill", "danno": "damage"}
# i gusti per le armi (bot.PESI.armi): moltiplicano i colpi che rendono e
# guidano la scelta d'inizio partita
VICINO = ("punch", "mallet", "lunge", "sword")
LONTANO = ("sniper", "missile", "grenade", "shards", "eagle")
GUSTI = {"vicino": VICINO, "lontano": LONTANO, "spinta": ("bellows",)}


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
    p = {g[0]: ind[g[0]] for g in GENI if g[0] not in PUNTEGGIO and g[0] not in GUSTI}
    armi = {w: ind[k] for k, ws in GUSTI.items() if abs(ind[k] - 1) > 1e-9 for w in ws}
    if armi:
        p["armi"] = armi
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
    danno, uccisioni, morti, cadute, teletrasporti a partita, armi usate, danno
    per arma e le firme dei turni (la sequenza di mosse)."""
    s = defaultdict(lambda: {"alto": 0.0, "vinte": 0, "volte": 0, "punti": 0, "danno": 0, "uccisioni": 0,
                             "ambientali": 0, "morti": 0, "cadute": 0, "teletrasporti": 0,
                             "uso": Counter(), "danno_arma": Counter(), "firme": Counter()})
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
            x["danno_arma"].update(r.get("danno_arma") or {})
        for t in m.get("turni", []):
            i = chi.get(t["chi"])
            if i and t["firma"]:
                s[i]["firme"][t["firma"]] += 1
    out = {}
    for i in range(1, n + 1):
        x = s[i]
        v = max(1, x["volte"])
        out[i] = {k: (x[k] / v if k not in ("volte", "uso", "danno_arma", "firme") else x[k]) for k in x}
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
            "danno_armi": quote(b["danno_arma"]), "firme": b["firme"].most_common(6)}


def gioca(cartella, file_pesi, partite, da, args, assegna=None):
    arena.USCITA = cartella
    ns = argparse.Namespace(partite=partite, da=da, processi=args.processi or arena.os.cpu_count() or 1,
                            modo=args.modo, livello=args.livello, mappa=args.mappa, punteggio=args.punteggio,
                            pesi=str(file_pesi), ritocchi=None, set=None, assegna=assegna, luajit=getattr(args, "luajit", None))
    return arena.leggi(arena.gioca(ns))


def esame(radice, gen, campione, args):
    """Il campione contro il bot di oggi, a coppie (le stesse partite con i
    posti scambiati): in quante arriva più in alto lui."""
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
            "lui": comportamento(b[2]), "oggi": comportamento(b[1])}


# gli specialisti: nome, cosa fa, il mestiere misurato sulle partite
# (misura) e la scala per la penalità (quanto sotto la soglia fa perdere 0,1
# di bravura)
def _quota(b, armi):
    tot = sum(b["danno_arma"].values()) or 1
    return sum(b["danno_arma"].get(w, 0) for w in armi) / tot


SPECIALISTI = [
    ("spingitore", "uccisioni nel vuoto a partita", lambda b: b["ambientali"], 0.1),
    ("acrobata", "globi e Rampino a partita", lambda b: b["teletrasporti"] + b["uso"].get("hook", 0) / max(1, b["volte"]), 0.5),
    ("cecchino", "quota del danno fatto da lontano", lambda b: _quota(b, LONTANO), 0.04),
    ("picchiatore", "quota del danno fatto da vicino", lambda b: _quota(b, VICINO), 0.04),
    ("sopravvissuto", "morti a partita, al contrario", lambda b: -b["morti"], 0.2),
]
NOMI = [s[0] for s in SPECIALISTI]
# quanto della distanza fra la soglia e il campione sale la soglia a ogni
# generazione, e quanto meno del bot di oggi può valere il campione perché salga
SALITA, MARGINE = 0.25, 0.02


STIMA = 300


def stima(ind):
    """Quanto è bravo un bot da tutte le partite giocate, tirato verso 0,5 se ne ha giocate poche."""
    return round((ind.get("_alto", 0.5) * ind.get("_n", 0) + 0.5 * STIMA) / (ind.get("_n", 0) + STIMA), 4)


def somma(ind, b, tratto):
    """Aggiunge le partite di una generazione a quelle che il bot ha già giocato
    (bravura e mestiere)."""
    n0, n1 = ind.get("_n", 0), b["volte"]
    if n0 + n1:
        ind["_alto"] = round((ind.get("_alto", 0.5) * n0 + b["alto"] * n1) / (n0 + n1), 4)
        ind["_tratto"] = round((ind.get("_tratto", 0) * n0 + tratto * n1) / (n0 + n1), 4)
        ind["_n"] = n0 + n1


def valore(ind, sp, soglia):
    """La bravura, meno 0,1 per ogni scala sotto la soglia del mestiere."""
    return stima(ind) - 0.1 * max(0.0, soglia - ind.get("_tratto", soglia)) / sp[3]


def sblocca(s, nome, gen, args, rng):
    """Una scelta da sola quando uno specialista non migliora più: a giro più
    mutazione o metà della sua popolazione nuova a caso."""
    passo = s["stalli"] % 2
    s["stalli"] += 1
    if passo == 0:
        s["forza"] = min(0.4, s["forza"] * 2)
        cosa = f"{nome}: muta di più (forza {s['forza']:.2f})"
    else:
        pop = s["pop"]
        for k in range(len(pop) // 2, len(pop)):
            pop[k] = a_caso(rng)
        cosa = f"{nome}: metà popolazione ({len(pop) - len(pop) // 2}) rinasce a caso"
    meglio = max(e["vince"] for e in s["esami"])
    print(f"  stallo: {cosa}")
    return {"gen": gen, "cosa": cosa, "perché": f"{args.stallo} esami di fila sotto il suo migliore ({100 * meglio:.0f}%)"}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--generazioni", type=int, default=0, help="fino a questa generazione (0: senza fine)")
    ap.add_argument("--popolazione", type=int, default=8, help="bot di ogni specialista")
    ap.add_argument("--partite", type=int, default=2000, help="partite per generazione")
    ap.add_argument("--forza", type=float, default=0.08, help="quanto mutano i geni (frazione del loro intervallo)")
    ap.add_argument("--esame", type=int, default=5, help="ogni quante generazioni l'esame contro il bot di oggi")
    ap.add_argument("--esame-partite", type=int, default=400)
    ap.add_argument("--stallo", type=int, default=3, help="esami di fila senza migliorare prima di cambiare")
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
        if "specialisti" not in stato:
            raise SystemExit("la cartella è di una corsa per stili, di prima degli specialisti: rilancia con --nuova")
        print(f"riprendo dalla generazione {stato['gen'] + 1}")
    else:
        gioco = dal_gioco(args.luajit)
        rng = random.Random(args.seme)
        oggi = di_oggi(gioco)
        # ogni specialista: il bot di oggi, metà vicino a lui e il resto a caso
        specialisti = {}
        for nome in NOMI:
            pop = [dict(oggi)] + [muta(oggi, rng, args.forza) for _ in range(args.popolazione // 2 - 1)]
            pop += [a_caso(rng) for _ in range(args.popolazione - len(pop))]
            specialisti[nome] = {"pop": pop, "soglia": None, "forza": args.forza, "esami": [], "stalli": 0,
                                 "senza_meglio": 0, "campione": None}
        stato = {"gen": 0, "gioco": gioco, "specialisti": specialisti, "storia": [], "decisioni": []}
    gioco = stato["gioco"]

    while not args.generazioni or stato["gen"] < args.generazioni:
        gen = stato["gen"] + 1
        rng = random.Random(args.seme * 1000003 + gen)
        sp = stato["specialisti"]
        # individuo 1: il bot di oggi; poi le popolazioni degli specialisti, in fila
        chi = [(nome, k) for nome in NOMI for k in range(len(sp[nome]["pop"]))]
        individui = [{}] + [pesi_bot(sp[n]["pop"][k], gioco) for n, k in chi]
        cartella = radice / f"generazione_{gen}"
        cartella.mkdir(parents=True, exist_ok=True)
        scrivi_pesi(cartella, individui)
        partite = gioca(cartella, cartella / "pesi.lua", args.partite, 1 + gen * 100000 + args.seme * 10 ** 9, args)
        b = misura(partite, len(individui))
        oggi_alto = b[1]["alto"]

        voce = {"gen": gen, "partite": len(partite), "oggi": comportamento(b[1]), "specialisti": {}}
        for nome, spec in zip(NOMI, SPECIALISTI):
            s = sp[nome]
            numeri = [2 + i for i, (n, _) in enumerate(chi) if n == nome]
            for k, i in enumerate(numeri):
                somma(s["pop"][k], b[i], spec[2](b[i]))
            if s["soglia"] is None:
                # si parte dal mestiere del bot di oggi
                s["soglia"] = round(spec[2](b[1]), 4)
            ordine = sorted(range(len(numeri)), key=lambda k: (-valore(s["pop"][k], spec, s["soglia"]), k))
            campione = s["pop"][ordine[0]]
            s["campione"] = dict(campione)
            # la soglia sale verso il campione se fa il mestiere più della soglia
            # ed è bravo quasi quanto il bot di oggi
            if campione["_tratto"] > s["soglia"] and stima(campione) >= oggi_alto - MARGINE:
                s["soglia"] = round(s["soglia"] + SALITA * (campione["_tratto"] - s["soglia"]), 4)
            voce["specialisti"][nome] = comportamento(b[numeri[ordine[0]]]) | {
                "geni": campione, "stima": stima(campione), "tratto": campione["_tratto"], "soglia": s["soglia"]}
            # la generazione dopo: i migliori restano; i figli dai migliori, ogni
            # tanto incrociati col campione di un altro specialista
            tenuti = [s["pop"][k] for k in ordine[: max(2, len(ordine) // 4)]]
            genitori = [s["pop"][k] for k in ordine[: max(2, len(ordine) // 2)]]
            altri = [sp[n]["campione"] for n in NOMI if n != nome and sp[n]["campione"]]
            nuovi = list(tenuti)
            while len(nuovi) < len(s["pop"]):
                a = genitori[min(rng.sample(range(len(genitori)), min(3, len(genitori))))]
                if rng.random() < 0.3:
                    c = rng.choice(altri) if altri and rng.random() < 0.3 else rng.choice(genitori)
                    a = incrocia(a, c, rng)
                nuovi.append(muta(a, rng, s["forza"]))
            s["pop"] = nuovi
        stato["storia"].append(voce)
        print(f"generazione {gen}: bot di oggi {oggi_alto:.3f}; " + ", ".join(
            f"{n} {voce['specialisti'][n]['stima']:.3f} ({voce['specialisti'][n]['tratto']:.2f}/{sp[n]['soglia']:.2f})"
            for n in NOMI) + f" ({len(partite)} partite)")

        # le trovate di questa generazione, col nome dello specialista
        with (radice / "trovate.jsonl").open("a", encoding="utf-8") as f:
            for t in trovate.candidati(partite, individui, 4, conta=lambda ind: ind and ind > 1):
                t["gen"] = gen
                t["chi_nome"] = f"generazione {gen}, {chi[t['individuo'] - 2][0]}"
                f.write(json.dumps(t, ensure_ascii=False) + "\n")
        stato["gen"] = gen

        if args.esame and gen % args.esame == 0:
            migliori = json.loads((radice / "migliori.json").read_text(encoding="utf-8")) if (radice / "migliori.json").exists() else {}
            for nome in NOMI:
                s = sp[nome]
                e = esame(radice, f"{gen}_{nome}", pesi_bot(s["campione"], gioco), args)
                e["gen"] = gen
                e["geni"] = s["campione"]
                prima = max((x["vince"] for x in s["esami"]), default=0)
                s["esami"].append(e)
                print(f"  esame: {nome} della generazione {gen} arriva più in alto del bot di oggi "
                      f"nel {100 * e['vince']:.0f}% delle partite")
                if e["vince"] > prima:
                    migliori[nome] = pesi_bot(s["campione"], gioco) | {"gen": gen, "vince": e["vince"]}
                if e["vince"] > prima + 0.01:
                    s.update(senza_meglio=0, forza=args.forza)
                else:
                    s["senza_meglio"] += 1
                    if s["senza_meglio"] >= args.stallo:
                        s["senza_meglio"] = 0
                        stato["decisioni"].append(sblocca(s, nome, gen, args, rng))
            (radice / "migliori.json").write_text(json.dumps(migliori, indent=1), encoding="utf-8")

        for f in cartella.glob("parte_*.jsonl"):
            f.unlink()
        (cartella / "partite.jsonl").unlink(missing_ok=True)
        # salva tutto a ogni generazione: si può fermare quando si vuole
        file_stato.write_text(json.dumps(stato), encoding="utf-8")
        (radice / "storia.json").write_text(json.dumps({k: stato[k] for k in ("gioco", "storia", "decisioni")} | {
            "esami": {n: sp[n]["esami"] for n in NOMI}}, indent=1, ensure_ascii=False), encoding="utf-8")
        (radice / "specialisti.json").write_text(json.dumps(
            {n: {"soglia": sp[n]["soglia"], "campione": sp[n]["campione"], "pesi": pesi_bot(sp[n]["campione"], gioco)}
             for n in NOMI}, indent=1, ensure_ascii=False), encoding="utf-8")
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
    sp = stato["specialisti"]
    out = ["# Specialisti del bot del gioco\n",
           f"{len(sp)} specialisti da {len(next(iter(sp.values()))['pop'])} bot, livello {args.livello}, modo {args.modo}. "
           "Bravura: quanto in alto arriva in classifica, da 0 (ultimo) a 1 (primo), da tutte le partite giocate. "
           "Mestiere: quanto fa la sua specialità; la soglia sale finché il campione resta bravo. Esame: in quante "
           "partite a coppie il campione arriva più in alto del bot di oggi (50% vuol dire uguale).\n",
           "## Gli specialisti\n", "| specialista | mestiere | campione / soglia | bravura | esami | armi principali | cosa cambia |",
           "|---|---|---|---|---|---|---|"]
    ultima = stato["storia"][-1]["specialisti"] if stato["storia"] else {}
    for nome, cosa, _, _ in SPECIALISTI:
        s, v = sp[nome], ultima.get(nome)
        if not v:
            continue
        esami = " ".join(f"{100 * e['vince']:.0f}%" for e in s["esami"]) or "-"
        armi = ", ".join(f"{k} {100 * q:.0f}%" for k, q in sorted(v["danno_armi"].items(), key=lambda x: -x[1])[:3])
        out.append(f"| {nome} | {cosa} | {v['tratto']:.2f} / {s['soglia']:.2f} | {v['stima']:.3f} | {esami} | {armi} | "
                   f"{geni_in_parole(s['campione'], gioco)} |")
    if stato["decisioni"]:
        out += ["\n## Scelte prese da sola quando non migliorava\n"]
        out += [f"- generazione {d['gen']}: {d['cosa']}, perché {d['perché']}" for d in stato["decisioni"]]
    out += ["\n## Generazioni\n", "Per ogni specialista: bravura del campione e mestiere / soglia.\n",
            "| gen | bot di oggi | " + " | ".join(NOMI) + " |", "|---|---|" + "---|" * len(NOMI)]
    for v in stato["storia"]:
        out.append(f"| {v['gen']} | {v['oggi']['bravura']:.3f} | " + " | ".join(
            f"{v['specialisti'][n]['stima']:.3f} ({v['specialisti'][n]['tratto']:.2f} / {v['specialisti'][n]['soglia']:.2f})"
            for n in NOMI) + " |")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    main()
