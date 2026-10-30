#!/usr/bin/env python3
"""Le trovate dei bot: i turni in cui un bot fa tanti punti con una
combinazione di mosse che quasi nessuno fa. Da migliaia di partite ne sceglie
poche, tutte diverse, ne fa il video col simulatore e una pagina da guardare
(galleria.html, con un video per trovata e cosa ha fatto in parole).

    python3 strumenti/arena/trovate.py CARTELLA                # partite.jsonl dell'arena (e pesi.json)
    python3 strumenti/arena/trovate.py CARTELLA --quante 16
    python3 strumenti/arena/trovate.py CARTELLA --nomi "bot di oggi,codardo,..."   # chi è ogni individuo
    python3 strumenti/arena/trovate.py CARTELLA --senza-video  # solo la scelta (trovate.json)

CARTELLA può essere quella di una partita dell'arena (partite.jsonl, con
pesi.json se ha giocato con --pesi) o quella di evolvi.py (trovate.jsonl:
le trovate di ogni generazione, già con la ricetta e i pesi). I video si fanno
col simulatore (solo Linux) e con lo stesso codice che ha giocato le partite:
la ricetta rigiocata con regole diverse non torna. Esce CARTELLA/galleria/; i
video già fatti restano (rilanciando si rifanno solo quelli mancati): per
rifarli tutti, cancella la cartella.
"""

import argparse
import html
import json
import math
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path

import arena

NOMI = {"missile": "Lanciarune", "grenade": "Uovo", "shards": "Schegge", "sniper": "Cecchino",
        "punch": "Pugno", "sword": "Lama", "eagle": "Tonante", "mallet": "Maglio", "lunge": "Affondo",
        "bellows": "Mantice", "hook": "Rampino", "wall": "Bastione", "teleport": "globo",
        "parachute": "paracadute", "shield": "scudo"}
MINIMO = 60     # punti in un turno perché sia una trovata
RARA = 0.01     # la sua combinazione in meno di un turno su cento


def turni_con_punti(p):
    """I turni di una partita con i punti fatti da chi giocava, dall'inizio del
    turno all'inizio di quello dopo."""
    turni = p["turni"]
    out = []
    for k, t in enumerate(turni):
        fine = turni[k + 1]["t"] if k + 1 < len(turni) else 10 ** 9
        punti = sum(e["punti"] for e in p["punti"] if e["chi"] == t["chi"] and t["t"] <= e["t"] < fine)
        out.append(t | {"punti": punti, "fine": fine})
    return out


def candidati(partite, individui=None, quante=12, conta=None):
    """Le trovate: punti del turno per quanto è rara la sua combinazione, una
    per combinazione e una per partita. individui: i pesi della popolazione
    (per rimetterli nella ricetta); conta(individuo): se un individuo conta
    (per evolvi.py, solo quelli che evolvono)."""
    firme = Counter(t["firma"] for p in partite for t in p["turni"])
    totale = sum(firme.values()) or 1
    scelti = []
    for k, p in enumerate(partite):
        robot = p["ricetta"]["opzioni"]["players"]
        for t in turni_con_punti(p):
            ind = robot[t["chi"] - 1].get("individuo")
            if conta and not conta(ind):
                continue
            if t["punti"] < MINIMO or not t["firma"] or firme[t["firma"]] / totale > RARA:
                continue
            voto = t["punti"] * (1 + math.log(totale / firme[t["firma"]]) / 3)
            scelti.append((voto, k, t, ind))
    scelti.sort(key=lambda x: (-x[0], x[1], x[2]["t"]))
    out, viste, partite_viste = [], set(), set()
    for voto, k, t, ind in scelti:
        if t["firma"] in viste or k in partite_viste:
            continue
        viste.add(t["firma"])
        partite_viste.add(k)
        p = partite[k]
        ricetta = json.loads(json.dumps(p["ricetta"]))
        if individui:
            for pl in ricetta["opzioni"]["players"]:
                if pl.get("individuo"):
                    pl["pesi"] = individui[pl["individuo"] - 1]
        out.append({"voto": round(voto, 1), "firma": t["firma"], "punti": t["punti"], "volte": firme[t["firma"]],
                    "totale": totale, "danno": t["danno"], "uccisioni": t["uccisioni"], "ambientali": t["ambientali"],
                    "tick": t["t"], "durata": min(t["fine"], p.get("durata", 10 ** 9)) - t["t"], "chi": t["chi"],
                    "individuo": ind, "modo": p["modo"], "mappa": p["mappa"], "ricetta": ricetta})
        if len(out) >= quante:
            break
    return out


def descrivi(t):
    """Cosa ha fatto, in parole: "globo, poi Affondo: due uccisioni, una nel vuoto"."""
    mosse = [NOMI.get(m, m) for m in t["firma"].split("+")[0].split(">") if m]
    # le mosse uguali di fila una volta sola, col numero
    gruppi = []
    for m in mosse:
        if gruppi and gruppi[-1][0] == m:
            gruppi[-1][1] += 1
        else:
            gruppi.append([m, 1])
    testo = ", poi ".join(m if n == 1 else f"{m} ×{n}" for m, n in gruppi)
    esito = []
    if t["uccisioni"] >= 2:
        esito.append(f"{t['uccisioni']} uccisioni")
    elif t["uccisioni"] == 1:
        esito.append("uccisione")
    if t["ambientali"]:
        esito.append("nel vuoto" if t["ambientali"] == 1 else f"{t['ambientali']} nel vuoto")
    if t["danno"] and not t["uccisioni"]:
        esito.append(f"{t['danno']:.0f} di danno")
    return testo[:1].upper() + testo[1:] + (": " + ", ".join(esito) if esito else "")


def video(t, cartella, n):
    """Il video del turno: il simulatore rigioca la ricetta da un secondo prima
    e registra fino alla fine del turno (al massimo 26 secondi)."""
    dest = cartella / f"trovata_{n}.mp4"
    if dest.exists():
        return dest.name  # già fatto (si rilancia per rifare solo quelli mancati)
    ricetta = cartella / f"ricetta_{n}.json"
    ricetta.write_text(json.dumps(t["ricetta"]), encoding="utf-8")
    secondi = max(6, min(26, math.ceil(t["durata"] / 60) + 2))
    scenario = cartella / f"trovata_{n}.txt"
    scenario.write_text(
        f"# trovata {n}: {t['firma']} ({t['modo']}, {t['mappa']}, tick {t['tick']})\n"
        f"imposta ricetta {ricetta}\nimposta ricetta_da {max(0, t['tick'] - 60)}\nimposta zoom 1\n"
        f"aspetta_stato modo=local 20\naspetta 1\nfoto inizio\naspetta {secondi}\nfoto fine\n", encoding="utf-8")
    # una seconda prova: a volte lo schermo finto (Xvfb) non parte
    for _ in range(2):
        r = subprocess.run([sys.executable, str(arena.REPO / "strumenti/simula/simula.py"), "-s", str(scenario)],
                           cwd=arena.REPO, capture_output=True, text=True)
        if r.returncode == 0:
            break
    if r.returncode != 0:
        print(f"trovata {n}: la simulazione è fallita\n{r.stdout[-800:]}{r.stderr[-800:]}")
        return None
    # più piccolo per la pagina: 854x480, senza audio
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(arena.REPO / "simulazione" / "video.mp4"),
                    "-vf", "scale=854:-2", "-c:v", "libx264", "-crf", "30", "-preset", "veryfast", "-an",
                    "-movflags", "+faststart", str(dest)], check=True)
    ricetta.unlink()
    scenario.unlink()
    return dest.name


def pagina(trovate, titolo, sotto):
    schede = []
    for k, t in enumerate(trovate, 1):
        su = t["totale"] / max(1, t["volte"])
        vid = (f'<video src="{t["video"]}" autoplay muted loop playsinline preload="metadata"></video>'
               if t.get("video") else '<div class="vuoto">video non riuscito</div>')
        schede.append(
            f'<article>{vid}<div class="testo"><span class="n">{k}</span>'
            f'<h2>{html.escape(t["descrizione"])}</h2>'
            f'<p>{html.escape(t.get("chi_nome") or "")}{" · " if t.get("chi_nome") else ""}'
            f'<b>{t["punti"]:.0f} punti</b> in un turno · una volta ogni {su:.0f} turni · '
            f'{html.escape(t["modo"])}, {html.escape(t["mappa"])}</p></div></article>')
    # la pagina per l'Artifact: senza doctype, html, head e body (li mette la pubblicazione)
    return f"""<title>{html.escape(titolo)}</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Lilita+One&family=Nunito+Sans:wght@400;700&display=swap">
<style>
/* griglia di clip come una bacheca di replay; il giallo della Corona come unico accento */
:root{{--sfondo:#eef0f6;--carta:#ffffff;--testo:#1b1e2b;--piano:#5a6074;--accento:#b7791f;--bordo:#d9dce8;
 --titolo:"Lilita One","Arial Rounded MT Bold",system-ui,sans-serif;--corpo:"Nunito Sans",system-ui,-apple-system,"Segoe UI",sans-serif}}
@media (prefers-color-scheme:dark){{:root:not([data-theme="light"]){{--sfondo:#12141d;--carta:#1c1f2c;--testo:#eef0f7;--piano:#a3a9bf;--accento:#f2c14e;--bordo:#2b2f40;color-scheme:dark}}}}
:root[data-theme="dark"]{{--sfondo:#12141d;--carta:#1c1f2c;--testo:#eef0f7;--piano:#a3a9bf;--accento:#f2c14e;--bordo:#2b2f40;color-scheme:dark}}
*{{box-sizing:border-box}}
body{{background:var(--sfondo);color:var(--testo);font:16px/1.45 var(--corpo)}}
main{{max-width:1180px;margin:0 auto;padding-block:28px 48px;padding-left:max(16px,env(safe-area-inset-left,0px));
 padding-right:max(16px,env(safe-area-inset-right,0px))}}
h1{{font:400 34px/1.1 var(--titolo);margin:0 0 8px;letter-spacing:.01em;text-wrap:balance}}
.sotto{{color:var(--piano);margin:0 0 24px;max-width:68ch}}
.griglia{{display:grid;grid-template-columns:repeat(auto-fill,minmax(min(100%,340px),1fr));gap:18px}}
article{{background:var(--carta);border:1px solid var(--bordo);border-radius:10px;overflow:hidden;min-width:0}}
video,.vuoto{{display:block;width:100%;max-width:100%;aspect-ratio:16/9;background:#000;color:#999;object-fit:cover}}
.vuoto{{display:grid;place-items:center}}
.testo{{padding:12px 14px 14px;display:grid;grid-template-columns:auto 1fr;gap:4px 10px;align-items:baseline}}
.n{{font:400 22px/1 var(--titolo);color:var(--accento);font-variant-numeric:tabular-nums}}
h2{{font-size:17px;margin:0;text-wrap:balance}}
p{{grid-column:2;margin:0;color:var(--piano);font-size:14px}}
p b{{color:var(--testo)}}
</style>
<main>
<h1>{html.escape(titolo)}</h1><p class="sotto">{html.escape(sotto)}</p>
<div class="griglia">{"".join(schede)}</div></main>
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cartella")
    ap.add_argument("--quante", type=int, default=12)
    ap.add_argument("--nomi", help="i nomi degli individui di pesi.json, separati da virgole")
    ap.add_argument("--titolo", default="Le trovate dei bot")
    ap.add_argument("--senza-video", action="store_true")
    args = ap.parse_args()

    cartella = Path(args.cartella).resolve()
    nomi = args.nomi.split(",") if args.nomi else None
    if (cartella / "trovate.jsonl").exists():
        # evolvi.py: le trovate di tutte le generazioni, si rifà solo la scelta
        tutte = [json.loads(r) for r in (cartella / "trovate.jsonl").read_text(encoding="utf-8").splitlines() if r]
        tutte.sort(key=lambda t: (-t["voto"], t["gen"], t["tick"]))
        trovate, viste = [], set()
        for t in tutte:
            if t["firma"] not in viste:
                viste.add(t["firma"])
                trovate.append(t)
        trovate = trovate[:args.quante]
        partite = None
    else:
        partite = arena.leggi(cartella / "partite.jsonl")
        individui = None
        if (cartella / "pesi.json").exists():
            individui = json.loads((cartella / "pesi.json").read_text(encoding="utf-8"))
        trovate = candidati(partite, individui, args.quante)
        for t in trovate:
            if nomi and t["individuo"]:
                t["chi_nome"] = nomi[t["individuo"] - 1]
    for t in trovate:
        t["descrizione"] = descrivi(t)
    uscita = cartella / "galleria"
    uscita.mkdir(exist_ok=True)
    for k, t in enumerate(trovate, 1):
        print(f"{k}. {t['descrizione']} ({t['punti']:.0f} punti, {t['volte']} su {t['totale']} turni)")
        if not args.senza_video:
            t["video"] = video(t, uscita, k)
    (uscita / "trovate.json").write_text(json.dumps(trovate, indent=1, ensure_ascii=False), encoding="utf-8")
    if partite is not None:
        da_dove = f"fra {trovate[0]['totale'] if trovate else 0} turni di {len(partite)} partite"
    else:
        gen = {t["gen"] for t in tutte}
        da_dove = f"dalle {len(gen)} generazioni dei bot (circa {trovate[0]['totale'] if trovate else 0} turni l'una)"
    sotto = (f"I turni più rari che fanno più punti, scelti {da_dove}: ognuno è una combinazione di mosse che "
             "quasi nessun bot fa. I video rigiocano la partita vera dal secondo prima del turno.")
    (uscita / "galleria.html").write_text(pagina(trovate, args.titolo, sotto), encoding="utf-8")
    print(f"galleria: {uscita / 'galleria.html'}")


if __name__ == "__main__":
    main()
