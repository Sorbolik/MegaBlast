#!/usr/bin/env python3
"""Bot che imparano a gradiente: la rete del bot (client/sim/rete.lua) impara
dalle partite che gioca a prevedere quanto renderà una posizione, e con quella
previsione sceglie le mosse. Giro dopo giro gioca meglio, e le partite nuove
le insegnano di più (come TD-Gammon e AlphaZero, in piccolo).

    python3 strumenti/arena/impara.py                  # senza fine (Ctrl+C), riprende da dove era
    python3 strumenti/arena/impara.py --partite 4000   # partite per giro
    python3 strumenti/arena/impara.py --nuova          # ricomincia da zero

Un giro:
  1. gioca --partite partite nell'arena (tutti i core): la rete di adesso (più
     copie, con un po' di esplorazione: ogni tanto sceglie apposta una mossa
     non migliore, così vede anche le altre), le reti dei giri passati come
     avversari e il bot di oggi come riferimento fisso;
  2. da ogni fine turno di ogni robot un esempio: le caratteristiche della
     posizione (bot.caratteristiche, le stesse che la rete guarda quando
     sceglie) e quanto la sua squadra ha guadagnato sulle altre da lì a fine
     partita (arena.lua --impara);
  3. la rete impara a gradiente (numpy, Adam) sugli esempi degli ultimi giri,
     partendo da dove era;
  4. esame: la rete nuova, senza esplorazione, contro il bot di oggi sempre
     sulle stesse partite (come evolvi.py).
Il giro 0 parte da una rete a caso: nessuna idea del gioco.

Risultati in simulazione/arena/impara/ (o --cartella): stato.json e rete_N.json
(per riprendere), storia.json, evoluzione.md, campioni.json (la rete di ogni
giro, da mettere in players[i].pesi).

Serve numpy (pip install numpy). Niente PyTorch: per una rete di poche
migliaia di pesi numpy basta ed è un'installazione leggera.
"""

import argparse
import json
import math
import shutil
from pathlib import Path

import numpy as np

import arena
import evolvi

CARATTERISTICHE = evolvi.CARATTERISTICHE


# La rete in numpy -------------------------------------------------------------------

def nuova(strati, rng):
    """Pesi a caso (He), scarti a zero."""
    return [(rng.normal(0, math.sqrt(2 / strati[k - 1]), (strati[k], strati[k - 1])), np.zeros(strati[k]))
            for k in range(1, len(strati))]


def avanti(rete, x):
    """Uscita della rete per le righe di x, e le attivazioni per il gradiente."""
    att = [x]
    for k, (w, b) in enumerate(rete):
        z = att[-1] @ w.T + b
        att.append(z if k == len(rete) - 1 else np.maximum(z, 0))
    return att


def impara(rete, x, y, args, rng):
    """Adam sull'errore di Huber (gli esiti lontani non tirano troppo), sulla
    rete (cambiata sul posto). Restituisce l'errore sugli esempi tenuti da parte."""
    n = len(x)
    idx = rng.permutation(n)
    prova, studio = idx[: n // 10], idx[n // 10:]
    par = [p for wb in rete for p in wb]  # w0, b0, w1, b1, ...
    m = [np.zeros_like(p) for p in par]
    v = [np.zeros_like(p) for p in par]
    b1, b2, eps, t = 0.9, 0.999, 1e-8, 0
    for _ in range(args.epoche):
        rng.shuffle(studio)
        for s in range(0, len(studio), args.lotto):
            j = studio[s:s + args.lotto]
            att = avanti(rete, x[j])
            g = np.clip(att[-1][:, 0] - y[j], -1, 1)[:, None] / len(j)  # Huber con soglia 1
            grad = [None] * len(par)
            for k in range(len(rete) - 1, -1, -1):
                w = rete[k][0]
                grad[2 * k] = g.T @ att[k] + args.l2 * w
                grad[2 * k + 1] = g.sum(0)
                if k > 0:
                    g = (g @ w) * (att[k] > 0)
            t += 1
            for q, p in enumerate(par):
                m[q] = b1 * m[q] + (1 - b1) * grad[q]
                v[q] = b2 * v[q] + (1 - b2) * grad[q] ** 2
                p -= args.lr * (m[q] / (1 - b1 ** t)) / (np.sqrt(v[q] / (1 - b2 ** t)) + eps)
    e = avanti(rete, x[prova])[-1][:, 0] - y[prova]
    var = float(np.var(y[prova])) or 1.0
    return {"errore": round(float(np.mean(e * e)), 4), "spiegata": round(1 - float(np.mean(e * e)) / var, 4)}


def per_lua(rete, strati, mu, sigma):
    """I pesi nell'ordine di sim/rete.lua (strato per strato: per ogni uscita i
    pesi d'ingresso, poi gli scarti). La normalizzazione degli ingressi
    ((x - mu) / sigma) entra nel primo strato, così in Lua non serve."""
    w0, b0 = rete[0]
    w0n = w0 / sigma
    b0n = b0 - w0n @ mu
    strati_lua = [(w0n, b0n)] + rete[1:]
    w = []
    for wk, bk in strati_lua:
        w += [round(float(a), 6) for a in wk.reshape(-1)]
        w += [round(float(a), 6) for a in bk]
    return {"rete": {"strati": strati, "w": w}}


def salva_rete(file, rete, mu, sigma):
    file.write_text(json.dumps({"strati": [[w.tolist(), b.tolist()] for w, b in rete],
                                "mu": mu.tolist(), "sigma": sigma.tolist()}))


def leggi_rete(file):
    d = json.loads(file.read_text())
    return [(np.array(w), np.array(b)) for w, b in d["strati"]], np.array(d["mu"]), np.array(d["sigma"])


# Il giro ------------------------------------------------------------------------------

def esempi(partite):
    xs, ys = [], []
    for m in partite:
        for e in m.get("esempi") or []:
            xs.append(e["x"])
            ys.append(e["y"])
    return np.array(xs, dtype=np.float64).reshape(-1, CARATTERISTICHE), np.array(ys, dtype=np.float64)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--giri", type=int, default=0, help="fino a questo giro (0: senza fine)")
    ap.add_argument("--partite", type=int, default=3000, help="partite per giro")
    ap.add_argument("--strati", default="32,16", help="neuroni degli strati nascosti")
    ap.add_argument("--copie", type=int, default=4, help="quante volte la rete di adesso sta nella popolazione")
    ap.add_argument("--passate", type=int, default=3, help="reti dei giri passati che giocano come avversari")
    ap.add_argument("--memoria", type=int, default=3, help="su quanti giri di esempi impara")
    ap.add_argument("--esplora", type=float, default=0.15)
    ap.add_argument("--epoche", type=int, default=6)
    ap.add_argument("--lotto", type=int, default=256)
    ap.add_argument("--lr", type=float, default=0.001)
    ap.add_argument("--l2", type=float, default=1e-5)
    ap.add_argument("--esame-partite", type=int, default=240)
    ap.add_argument("--livello", default="difficile")
    ap.add_argument("--modo", default="tutti")
    ap.add_argument("--mappa")
    ap.add_argument("--punteggio")
    ap.add_argument("--processi", type=int, default=None)
    ap.add_argument("--seme", type=int, default=1)
    ap.add_argument("--nuova", action="store_true", help="ricomincia da zero (cancella la cartella)")
    ap.add_argument("--cartella", default=str(arena.REPO / "simulazione" / "arena" / "impara"))
    args = ap.parse_args()

    radice = Path(args.cartella).resolve()
    if args.nuova and radice.exists():
        shutil.rmtree(radice)
    radice.mkdir(parents=True, exist_ok=True)
    file_stato = radice / "stato.json"
    if file_stato.exists():
        stato = json.loads(file_stato.read_text())
        print(f"riprendo dal giro {stato['giro'] + 1}")
    else:
        strati = [CARATTERISTICHE] + [int(x) for x in args.strati.split(",")] + [1]
        stato = {"giro": -1, "strati": strati, "storia": [], "esami": []}
    strati = stato["strati"]
    print(f"rete {strati}: {evolvi.quanti(strati)} pesi")

    while not args.giri or stato["giro"] < args.giri:
        giro = stato["giro"] + 1
        rng = np.random.default_rng(args.seme * 1000003 + giro)
        file_rete = radice / f"rete_{giro - 1}.json"
        if giro == 0:
            rete, mu, sigma = nuova(strati, rng), np.zeros(CARATTERISTICHE), np.ones(CARATTERISTICHE)
        else:
            rete, mu, sigma = leggi_rete(file_rete)
        adesso = per_lua(rete, strati, mu, sigma)
        # la popolazione: il bot di oggi, la rete di adesso (più copie, che esplora), reti passate
        passate = []
        for k in range(max(0, giro - args.passate), giro - 1):
            r, m_, s_ = leggi_rete(radice / f"rete_{k}.json")
            passate.append(per_lua(r, strati, m_, s_) | {"esplora": args.esplora})
        individui = [{}] + [adesso | {"esplora": args.esplora}] * args.copie + passate
        cartella = radice / f"giro_{giro}"
        cartella.mkdir(parents=True, exist_ok=True)
        file_pesi = evolvi.scrivi_pesi(cartella, individui)
        arena.USCITA = cartella
        ns = argparse.Namespace(partite=args.partite, da=1 + giro * 1000000 + args.seme * 10 ** 9,
                                processi=args.processi or arena.os.cpu_count() or 1, modo=args.modo,
                                livello=args.livello, mappa=args.mappa, punteggio=args.punteggio,
                                pesi=str(file_pesi), ritocchi=None, set=None, assegna=None, impara="1", luajit=None)
        partite = arena.leggi(arena.gioca(ns))
        x, y = esempi(partite)
        np.save(cartella / "x.npy", x)
        np.save(cartella / "y.npy", y)
        b = evolvi.misura(partite, len(individui))
        # come ha giocato la rete di adesso (tutte le sue copie insieme) e il bot di oggi
        tot = {"alto": 0.0, "volte": 0}
        for i in range(2, 2 + args.copie):
            tot["alto"] += b[i]["alto"] * b[i]["volte"]
            tot["volte"] += b[i]["volte"]
        for f in cartella.glob("parte_*.jsonl"):
            f.unlink()
        (cartella / "partite.jsonl").unlink(missing_ok=True)

        # impara sugli esempi degli ultimi giri
        xs, ys = [], []
        for k in range(max(0, giro - args.memoria + 1), giro + 1):
            xs.append(np.load(radice / f"giro_{k}" / "x.npy"))
            ys.append(np.load(radice / f"giro_{k}" / "y.npy"))
        X, Y = np.concatenate(xs), np.concatenate(ys)
        if giro == 0:
            mu, sigma = X.mean(0), X.std(0) + 1e-6
        Xn = (X - mu) / sigma
        studio = impara(rete, Xn, Y, args, rng)
        salva_rete(radice / f"rete_{giro}.json", rete, mu, sigma)
        nuova_lua = per_lua(rete, strati, mu, sigma)
        voce = {"giro": giro, "partite": len(partite), "esempi": len(y), "esempi_studiati": len(X),
                "bravura_rete": round(tot["alto"] / max(1, tot["volte"]), 4), "oggi": evolvi.comportamento(b[1]),
                "rete": evolvi.comportamento(b[2]), **studio}
        e = evolvi.esame(radice, giro, nuova_lua, args)
        e["giro"] = giro
        stato["esami"].append(e)
        stato["storia"].append(voce)
        stato["giro"] = giro
        print(f"giro {giro}: {len(y)} esempi nuovi, impara su {len(X)} (varianza spiegata {studio['spiegata']:.2f}); "
              f"esame: la rete arriva più in alto del bot di oggi nel {100 * e['vince']:.0f}% delle partite")

        file_stato.write_text(json.dumps(stato))
        (radice / "storia.json").write_text(json.dumps({"strati": strati, "storia": stato["storia"],
                                                        "esami": stato["esami"]}, indent=1, ensure_ascii=False))
        campioni = []
        for k in range(giro + 1):
            r, m_, s_ = leggi_rete(radice / f"rete_{k}.json")
            campioni.append(per_lua(r, strati, m_, s_) | {"giro": k})
        (radice / "campioni.json").write_text(json.dumps(campioni))
        (radice / "evoluzione.md").write_text(rapporto(stato, args))
        # gli esempi vecchi non servono più
        vecchio = radice / f"giro_{giro - args.memoria}"
        for f in ("x.npy", "y.npy"):
            (vecchio / f).unlink(missing_ok=True)


def rapporto(stato, args):
    out = ["# Bot che imparano a gradiente\n",
           f"Rete {stato['strati']} ({evolvi.quanti(stato['strati'])} pesi), {args.partite} partite per giro, "
           f"livello {args.livello}, modo {args.modo}.\n",
           "Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. "
           "Varianza spiegata: quanto la rete prevede l'esito (0 niente, 1 tutto) su esempi che non ha studiato.\n",
           "| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |",
           "|---|---|---|---|---|---|---|"]
    for v, e in zip(stato["storia"], stato["esami"]):
        out.append(f"| {v['giro']} | {100 * e['vince']:.0f}% | {v['spiegata']:.2f} | {v['esempi_studiati']} | "
                   f"{e['rete']['morti']:.2f} / {e['oggi']['morti']:.2f} | {e['rete']['danno']:.0f} / {e['oggi']['danno']:.0f} | "
                   f"{e['rete']['teletrasporti']:.2f} / {e['oggi']['teletrasporti']:.2f} |")
    if stato["esami"]:
        e = stato["esami"][-1]
        out += ["\n## Le mosse preferite dell'ultima rete all'esame\n"] + [f"- {f}: {n}" for f, n in e["rete"]["firme"]]
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    main()
