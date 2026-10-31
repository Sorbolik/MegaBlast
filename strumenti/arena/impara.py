#!/usr/bin/env python3
"""Bot che imparano a gradiente: la rete del bot (client/sim/rete.lua) impara
dalle partite che gioca a prevedere quanto renderà una posizione, e con quella
previsione sceglie le mosse. Giro dopo giro gioca meglio, e le partite nuove
le insegnano di più (come TD-Gammon e AlphaZero, in piccolo). Sergio, 31
ottobre 2026: "voglio creare il bot supremo, voglio che impari tutte le
tecniche possibili e immaginabili".

    python strumenti/arena/impara.py                  # senza fine (Ctrl+C), riprende da dove era
    python strumenti/arena/impara.py --partite 4000   # partite per giro
    python strumenti/arena/impara.py --lega simulazione/arena/evolvi/migliori.json
    python strumenti/arena/impara.py --nuova          # ricomincia da zero

Un giro:
  1. gioca --partite partite nell'arena (tutti i core): la rete di adesso (più
     copie, con un po' di esplorazione: ogni tanto sceglie apposta una mossa
     non migliore, così vede anche le altre), le reti dei giri passati, il bot
     di oggi e (--lega) gli specialisti di evolvi.py come avversari fissi, così
     impara a battere tutti gli stili e non uno solo;
  2. da ogni fine turno di ogni robot un esempio: quello che la rete guarda
     quando sceglie (bot.caratteristiche: punti, vita, gli altri robot uno per
     uno, le armi, i globi e il terreno intorno) e quanto la sua squadra ha
     guadagnato sulle altre da lì a fine partita (arena.lua --impara);
  3. l'obiettivo di ogni esempio è il ritorno a passi (TD(λ), --lambda): quanto
     la squadra guadagna fino al turno dopo dello stesso robot più quanto la
     rete prevede da lì, mescolato con l'esito vero. Molto meno rumore
     dell'esito a fine partita, che dipende da tutti i turni che vengono dopo;
  4. la rete non parte da zero: il bot somma il giudizio di oggi (punti,
     vita, morti) e quello della rete, che impara solo la differenza fra il
     primo e l'esito (31 ottobre: partita da zero, dopo 4 giri la rete era
     ancora al 10% contro il bot di oggi);
     la rete impara a gradiente (PyTorch, AdamW, sulla scheda video se c'è)
     sugli esempi degli ultimi giri, partendo da dove era;
  5. esame: la rete nuova, senza esplorazione, contro il bot di oggi sempre
     sulle stesse partite (evolvi.esame). La rete con l'esame migliore resta
     in migliore.json.
Il giro 0 parte dal bot di oggi: la rete non aggiunge ancora niente.

Le mosse: la rete prova quelle del bot di oggi e anche i colpi a ventaglio che
non puntano nessuno (bot.lua, pesi.larga), così può scoprire mosse che nessuno
le ha insegnato. Costa circa il doppio del tempo a partita; --stretta lo toglie.

Risultati in simulazione/arena/impara/ (o --cartella): stato.json e rete_N.json
(per riprendere; rete_N è la rete del giro N), storia.json, evoluzione.md,
migliore.json (da mettere in players[i].pesi).

Serve PyTorch (pip install torch numpy; per la scheda video NVIDIA la versione
CUDA da download.pytorch.org). Scartati: numpy (andava per una rete da poche
migliaia di pesi, non per centinaia di migliaia), JAX e TensorFlow (più pesanti
da installare su Windows, nessun vantaggio per una rete così).
"""

import argparse
import json
import math
import shutil
from pathlib import Path

import numpy as np
import torch

import arena
import evolvi

CARATTERISTICHE = 137  # bot.CARATTERISTICHE


def quanti(strati):
    return sum(strati[k] * (strati[k - 1] + 1) for k in range(1, len(strati)))


# La rete in PyTorch ---------------------------------------------------------------

def dispositivo():
    return torch.device("cuda" if torch.cuda.is_available() else "cpu")


def nuova(strati, seme):
    """Pesi a caso (He), scarti e ultimo strato a zero."""
    torch.manual_seed(seme)
    strati_t = []
    for k in range(1, len(strati)):
        lin = torch.nn.Linear(strati[k - 1], strati[k])
        torch.nn.init.kaiming_normal_(lin.weight, nonlinearity="relu")
        torch.nn.init.zeros_(lin.bias)
        strati_t += [lin, torch.nn.ReLU()]
    # l'ultimo strato a zero: al giro 0 la rete non aggiunge niente e il bot
    # gioca come quello di oggi (col ventaglio), invece che a caso
    torch.nn.init.zeros_(strati_t[-2].weight)
    return torch.nn.Sequential(*strati_t[:-1]).to(dispositivo())


def avanti(rete, x):
    """Uscita della rete per le righe di x (numpy), in numpy."""
    with torch.no_grad():
        out = []
        for s in range(0, len(x), 65536):
            out.append(rete(torch.from_numpy(x[s:s + 65536]).float().to(dispositivo())).cpu().numpy()[:, 0])
        return np.concatenate(out) if out else np.zeros(0)


def impara(rete, x, y, args, rng):
    """Adam sull'errore di Huber (gli esiti lontani non tirano troppo), sulla
    rete (cambiata sul posto). Restituisce l'errore sugli esempi tenuti da parte."""
    dev = dispositivo()
    n = len(x)
    idx = rng.permutation(n)
    prova, studio = idx[: n // 10], idx[n // 10:]
    xs, ys = torch.from_numpy(x).float().to(dev), torch.from_numpy(y).float().to(dev)
    opt = torch.optim.AdamW(rete.parameters(), lr=args.lr, weight_decay=args.l2)
    perdita = torch.nn.HuberLoss(delta=1.0)
    studio_t = torch.from_numpy(studio).to(dev)
    for _ in range(args.epoche):
        ordine = studio_t[torch.randperm(len(studio_t), device=dev)]
        for s in range(0, len(ordine), args.lotto):
            j = ordine[s:s + args.lotto]
            opt.zero_grad()
            perdita(rete(xs[j])[:, 0], ys[j]).backward()
            opt.step()
    e = avanti(rete, x[prova]) - y[prova]
    var = float(np.var(y[prova])) or 1.0
    return {"errore": round(float(np.mean(e * e)), 4), "spiegata": round(1 - float(np.mean(e * e)) / var, 4)}


def matrici(rete):
    """[(w, b)] in numpy, strato per strato."""
    return [(m.weight.detach().cpu().numpy(), m.bias.detach().cpu().numpy())
            for m in rete if isinstance(m, torch.nn.Linear)]


def per_lua(rete, strati, mu, sigma):
    """I pesi nell'ordine di sim/rete.lua (strato per strato: per ogni uscita i
    pesi d'ingresso, poi gli scarti). La normalizzazione degli ingressi
    ((x - mu) / sigma) entra nel primo strato, così in Lua non serve."""
    mat = matrici(rete)
    w0, b0 = mat[0]
    w0n = w0 / sigma
    b0n = b0 - w0n @ mu
    w = []
    for wk, bk in [(w0n, b0n)] + mat[1:]:
        w += [round(float(a), 6) for a in wk.reshape(-1)]
        w += [round(float(a), 6) for a in bk]
    return {"rete": {"strati": strati, "w": w}}


def salva_rete(file, rete, mu, sigma):
    file.write_text(json.dumps({"strati": [[w.tolist(), b.tolist()] for w, b in matrici(rete)],
                                "mu": mu.tolist(), "sigma": sigma.tolist()}), encoding="utf-8")


def leggi_rete(file, strati):
    d = json.loads(file.read_text(encoding="utf-8"))
    rete = nuova(strati, 0)
    with torch.no_grad():
        for m, (w, b) in zip([m for m in rete if isinstance(m, torch.nn.Linear)], d["strati"]):
            m.weight.copy_(torch.tensor(w, dtype=torch.float32))
            m.bias.copy_(torch.tensor(b, dtype=torch.float32))
    return rete, np.array(d["mu"]), np.array(d["sigma"])


def lega(file):
    """Gli avversari fissi da un migliori.json di evolvi.py (gli specialisti):
    i pesi di ognuno, senza i numeri dell'esame."""
    if not file:
        return []
    d = json.loads(Path(file).read_text(encoding="utf-8"))
    return [{k: v for k, v in d[nome].items() if k not in ("gen", "vince")} for nome in sorted(d)]


# Il giro ------------------------------------------------------------------------------

def esempi(partite):
    """x, y (esito vero) e per il ritorno a passi: la catena di ogni robot
    (partita e robot) e il margine della squadra a inizio turno."""
    xs, ys, catene, ms = [], [], [], []
    for k, m in enumerate(partite):
        for e in m.get("esempi") or []:
            xs.append(e["x"])
            ys.append(e["y"])
            catene.append(k * 8 + e["c"])
            ms.append(e["m"])
    return (np.array(xs, dtype=np.float32).reshape(-1, CARATTERISTICHE), np.array(ys, dtype=np.float64),
            np.array(catene, dtype=np.int64), np.array(ms, dtype=np.float64))


def base(x):
    """Il giudizio del bot di oggi (bot.lua valore, con i pesi di bot.PESI) dalle
    caratteristiche grezze, in centinaia di punti: punti guadagnati dalla squadra
    meno quelli dei nemici, vita persa (0,6 la sua, 1 dei compagni), morti (60).
    La rete impara solo quello che manca a questo per arrivare all'esito."""
    return x[:, 0] + x[:, 1] - x[:, 2] - 0.6 * x[:, 3] - x[:, 4] - 0.6 * (x[:, 6] + x[:, 7])


def ritorni(rete, xn, b0, y, catene, ms, lam):
    """TD(λ) all'indietro lungo la catena di ogni robot: dopo l'ultimo turno
    l'esito vero, prima (m' - m) + (1 - λ) V(x') + λ G'. Con λ = 1 è l'esito vero.
    V è il giudizio di base b0 più quello della rete."""
    if lam >= 1:
        return y
    v = b0 + avanti(rete, xn)
    g = y.copy()
    ordine = np.argsort(catene, kind="stable")  # ogni catena di fila, i turni in ordine
    for a, b in zip(ordine[-2::-1], ordine[:0:-1]):
        if catene[a] == catene[b]:
            g[a] = ms[b] - ms[a] + (1 - lam) * v[b] + lam * g[b]
    return g


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--giri", type=int, default=0, help="fino a questo giro (0: senza fine)")
    ap.add_argument("--partite", type=int, default=3000, help="partite per giro")
    ap.add_argument("--strati", default="256,128", help="neuroni degli strati nascosti")
    ap.add_argument("--copie", type=int, default=4, help="quante volte la rete di adesso sta nella popolazione")
    ap.add_argument("--passate", type=int, default=3, help="reti dei giri passati che giocano come avversari")
    ap.add_argument("--memoria", type=int, default=5, help="su quanti giri di esempi impara")
    ap.add_argument("--lambda", dest="lam", type=float, default=0.7, help="TD(λ): 1 impara dall'esito vero")
    ap.add_argument("--esplora", type=float, default=0.15)
    ap.add_argument("--lega", help="migliori.json di evolvi.py: gli specialisti giocano come avversari fissi")
    ap.add_argument("--stretta", action="store_true", help="la rete prova solo le mosse del bot di oggi (niente ventaglio)")
    ap.add_argument("--epoche", type=int, default=6)
    ap.add_argument("--lotto", type=int, default=1024)
    ap.add_argument("--lr", type=float, default=0.001)
    ap.add_argument("--l2", type=float, default=1e-5)
    ap.add_argument("--esame-partite", type=int, default=480)
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
        stato = json.loads(file_stato.read_text(encoding="utf-8"))
        print(f"riprendo dal giro {stato['giro'] + 1}")
    else:
        strati = [CARATTERISTICHE] + [int(x) for x in args.strati.split(",")] + [1]
        stato = {"giro": -1, "strati": strati, "storia": [], "esami": []}
    strati = stato["strati"]
    print(f"rete {strati}: {quanti(strati)} pesi")

    while not args.giri or stato["giro"] < args.giri:
        giro = stato["giro"] + 1
        rng = np.random.default_rng(args.seme * 1000003 + giro)
        file_rete = radice / f"rete_{giro - 1}.json"
        if giro == 0:
            rete, mu, sigma = nuova(strati, args.seme), np.zeros(CARATTERISTICHE), np.ones(CARATTERISTICHE)
        else:
            rete, mu, sigma = leggi_rete(file_rete, strati)
        larga = {} if args.stretta else {"larga": True}
        adesso = per_lua(rete, strati, mu, sigma) | larga
        # la popolazione: il bot di oggi, la rete di adesso (più copie, che esplora),
        # reti passate e gli specialisti (la lega: deve battere tutti gli stili)
        passate = []
        for k in range(max(0, giro - args.passate), giro - 1):
            r, m_, s_ = leggi_rete(radice / f"rete_{k}.json", strati)
            passate.append(per_lua(r, strati, m_, s_) | larga | {"esplora": args.esplora})
        individui = [{}] + [adesso | {"esplora": args.esplora}] * args.copie + passate + lega(args.lega)
        cartella = radice / f"giro_{giro}"
        cartella.mkdir(parents=True, exist_ok=True)
        file_pesi = evolvi.scrivi_pesi(cartella, individui)
        arena.USCITA = cartella
        ns = argparse.Namespace(partite=args.partite, da=1 + giro * 1000000 + args.seme * 10 ** 9,
                                processi=args.processi or arena.os.cpu_count() or 1, modo=args.modo,
                                livello=args.livello, mappa=args.mappa, punteggio=args.punteggio,
                                pesi=str(file_pesi), ritocchi=None, set=None, assegna=None, impara="1", luajit=None)
        partite = arena.leggi(arena.gioca(ns))
        x, y, catene, ms = esempi(partite)
        catene += giro * 10 ** 9  # catene diverse fra i giri
        for nome, a in (("x", x), ("y", y), ("catene", catene), ("m", ms)):
            np.save(cartella / f"{nome}.npy", a)
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
        giri = range(max(0, giro - args.memoria + 1), giro + 1)
        X, Y, CAT, M = (np.concatenate([np.load(radice / f"giro_{k}" / f"{nome}.npy") for k in giri])
                        for nome in ("x", "y", "catene", "m"))
        if giro == 0:
            # una caratteristica quasi sempre uguale (le morti dei compagni) non deve
            # diventare un peso enorme quando cambia
            mu, sigma = X.mean(0), np.maximum(X.std(0), 0.1)
        Xn = ((X - mu) / sigma).astype(np.float32)
        # al giro 0 la rete è a caso: impara dall'esito vero
        B = base(X)
        G = ritorni(rete, Xn, B, Y, CAT, M, 1 if giro == 0 else args.lam)
        studio = impara(rete, Xn, (G - B).astype(np.float32), args, rng)
        salva_rete(radice / f"rete_{giro}.json", rete, mu, sigma)
        nuova_lua = per_lua(rete, strati, mu, sigma) | larga
        voce = {"giro": giro, "partite": len(partite), "esempi": len(y), "esempi_studiati": len(X),
                "bravura_rete": round(tot["alto"] / max(1, tot["volte"]), 4), "oggi": evolvi.comportamento(b[1]),
                "rete": evolvi.comportamento(b[2]), **studio}
        e = evolvi.esame(radice, giro, nuova_lua, args)
        e["giro"] = giro
        if not stato["esami"] or e["vince"] > max(v["vince"] for v in stato["esami"]):
            (radice / "migliore.json").write_text(json.dumps(nuova_lua | {"giro": giro}), encoding="utf-8")
        stato["esami"].append(e)
        stato["storia"].append(voce)
        stato["giro"] = giro
        print(f"giro {giro}: {len(y)} esempi nuovi, impara su {len(X)} (varianza spiegata {studio['spiegata']:.2f}); "
              f"esame: la rete arriva più in alto del bot di oggi nel {100 * e['vince']:.0f}% delle partite")

        file_stato.write_text(json.dumps(stato), encoding="utf-8")
        (radice / "storia.json").write_text(json.dumps({"strati": strati, "storia": stato["storia"],
                                                        "esami": stato["esami"]}, indent=1, ensure_ascii=False), encoding="utf-8")
        (radice / "evoluzione.md").write_text(rapporto(stato, args), encoding="utf-8")
        # il disco (sul PC di Sergio è poco): gli esempi vecchi e le popolazioni
        # (pesi.lua e pesi.json, megabyte con le reti grandi) non servono più;
        # le reti di ogni giro restano in rete_N.json (1,5 MB l'una)
        vecchio = radice / f"giro_{giro - args.memoria}"
        for f in ("x.npy", "y.npy", "catene.npy", "m.npy", "pesi.lua", "pesi.json"):
            (vecchio / f).unlink(missing_ok=True)
        for f in ("pesi.lua", "pesi.json"):
            (radice / f"esame_{giro}" / f).unlink(missing_ok=True)


def rapporto(stato, args):
    out = ["# Bot che imparano a gradiente\n",
           f"Rete {stato['strati']} ({quanti(stato['strati'])} pesi), {args.partite} partite per giro, "
           f"livello {args.livello}, modo {args.modo}, TD(λ) {args.lam}, memoria {args.memoria} giri.\n",
           "Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. "
           "Varianza spiegata: quanto la rete prevede il suo obiettivo (0 niente, 1 tutto) su esempi che non ha studiato. "
           "La rete con l'esame migliore è in migliore.json.\n",
           "| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |",
           "|---|---|---|---|---|---|---|"]
    for v, e in zip(stato["storia"], stato["esami"]):
        out.append(f"| {v['giro']} | {100 * e['vince']:.0f}% | {v['spiegata']:.2f} | {v['esempi_studiati']} | "
                   f"{e['lui']['morti']:.2f} / {e['oggi']['morti']:.2f} | {e['lui']['danno']:.0f} / {e['oggi']['danno']:.0f} | "
                   f"{e['lui']['teletrasporti']:.2f} / {e['oggi']['teletrasporti']:.2f} |")
    if stato["esami"]:
        e = stato["esami"][-1]
        out += ["\n## Le mosse preferite dell'ultima rete all'esame\n"] + [f"- {f}: {n}" for f, n in e["lui"]["firme"]]
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    main()
